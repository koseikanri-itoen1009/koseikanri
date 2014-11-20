CREATE OR REPLACE PACKAGE BODY XXCMN810004C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCMN810004C(body)
 * Description      : CSV�A�b�v���[�h����i�ڃ}�X�^���ꊇ�o�^���܂��B
 * MD.050           : �i�ڃ}�X�^�ꊇ�A�b�v���[�h T_MD050_BPO_810
 * Version          : Issue1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  chk_exists_category    �J�e�S�����݃`�F�b�N
 *  chk_exists_lookup      LOOKUP�\���݃`�F�b�N
 *  proc_comp              �I������ (D-8)
 *  ins_data               �f�[�^�o�^ (D-5)
 *  proc_disc_categ_ref    Disc�i�ڃJ�e�S������ (D-7)
 *  get_disc_item_data     Disc�i�ڏ��擾 (D-6)
 *                            �Eproc_disc_categ_ref
 *  validate_item          �i�ڃ}�X�^�ꊇ�A�b�v���[�h���[�N�f�[�^�Ó����`�F�b�N (D-4)
 *                            �Echk_exists_lookup
 *                            �Echk_exists_category
 *  loop_main              �i�ڃ}�X�^�ꊇ�A�b�v���[�h���[�N�f�[�^�擾 (D-3)
 *                            �Evalidate_item
 *                            �Eins_data
 *                            �Eget_disc_item_data
 *  get_if_data            �t�@�C���A�b�v���[�hIF�f�[�^�擾 (D-2)
 *  proc_init              �������� (D-1)
 *  submain                ���C�������v���V�[�W��
 *                            �Eproc_init
 *                            �Eget_if_data
 *                            �Eloop_main
 *                            �Eproc_comp
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                            �Esubmain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/11/20    1.0   K.Boku           main�V�K�쐬
 *  2013/04/18    1.1   S.Niki           [E_�{�ғ�_10588]  �q�ɕi�ڃ`�F�b�N�A�ݒ�l�C��
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := '0'; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := '1'; --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := '2'; --�ُ�:2
  cv_sts_cd_normal          CONSTANT VARCHAR2(1) := 'C';
  cv_sts_cd_warn            CONSTANT VARCHAR2(1) := 'G';
  cv_sts_cd_error           CONSTANT VARCHAR2(1) := 'E';
  --WHO�J����
  gn_created_by             CONSTANT NUMBER  := fnd_global.user_id;         --CREATED_BY
  gd_creation_date          CONSTANT DATE    := SYSDATE;                    --CREATION_DATE
  gn_last_updated_by        CONSTANT NUMBER  := fnd_global.user_id;         --LAST_UPDATED_BY
  gd_last_update_date       CONSTANT DATE    := SYSDATE;                    --LAST_UPDATE_DATE
  gn_last_update_login      CONSTANT NUMBER  := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  gn_request_id             CONSTANT NUMBER  := fnd_global.conc_request_id; --REQUEST_ID
  gn_program_application_id CONSTANT NUMBER  := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  gn_program_id             CONSTANT NUMBER  := fnd_global.conc_program_id; --PROGRAM_ID
  gd_program_update_date    CONSTANT DATE    := SYSDATE;                    --PROGRAM_UPDATE_DATE
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
  lock_expt                EXCEPTION;      -- ���b�N�擾��O
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name              CONSTANT VARCHAR2(100) := 'XXCMN810004C';     -- �p�b�P�[�W��
--
  -- ���b�Z�[�W
  cv_msg_xxcmn_10002       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10002';  -- �v���t�@�C���G���[
  cv_msg_xxcmn_10617       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10617';  -- �}�X�^���݃`�F�b�N�G���[
  cv_msg_xxcmn_10618       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10618';  -- �i�ڏd���G���[
  cv_msg_xxcmn_10619       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10619';  -- �i��7���K�{�G���[
  cv_msg_xxcmn_10620       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10620';  -- �q�ɕi��7���K�{�G���[
  cv_msg_xxcmn_10621       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10621';  -- ��P�ʃG���[
  cv_msg_xxcmn_10622       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10622';  -- �f�[�^���o�G���[
  cv_msg_xxcmn_10623       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10623';  -- �K�{�G���[
  cv_msg_xxcmn_10624       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10624';  -- �o�׊��Z�P�ʃ`�F�b�N�G���[
  cv_msg_xxcmn_10625       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10625';  -- ���͐����`�F�b�N�G���[
  cv_msg_xxcmn_10626       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10626';  -- �f�[�^�o�^�G���[
  cv_msg_xxcmn_10627       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10627';  -- OPM�i�ڃg���K�[�N���m�[�g
  cv_msg_xxcmn_10628       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10628';  -- �Ɩ����t�擾���s�G���[
  cv_msg_xxcmn_10629       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10629';  -- ���o�Ɋ��Z�P�ʃG���[
  cv_msg_xxcmn_10630       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10630';  -- �f�[�^�폜�G���[
  cv_msg_xxcmn_10631       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10631';  -- �t�@�C���A�b�v���[�h���̃m�[�g
  cv_msg_xxcmn_10632       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10632';  -- CSV�t�@�C�����m�[�g
  cv_msg_xxcmn_10633       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10633';  -- FILE_ID�m�[�g
  cv_msg_xxcmn_10634       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10634';  -- �t�H�[�}�b�g�p�^�[���m�[�g
  cv_msg_xxcmn_10635       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10635';  -- ���̓p�����[�^NULL�G���[
  cv_msg_xxcmn_10636       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10636';  -- �f�[�^���o�G���[
  cv_msg_xxcmn_10637       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10637';  -- ���b�N�G���[
  cv_msg_xxcmn_10638       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10638';  -- ���ڐ��G���[
  cv_msg_xxcmn_10639       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10639';  -- �t�@�C�����ڃ`�F�b�N�G���[
  cv_msg_xxcmn_10640       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10640';  -- BLOB�f�[�^�ϊ��G���[
-- Ver.1.1 S.Niki ADD START
  cv_msg_xxcmn_10641       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10641';  -- �q�ɕi�ڃR�[�h���݃`�F�b�N�G���[
-- Ver.1.1 S.Niki ADD END
--
  -- �g�[�N��
  cv_tkn_value             CONSTANT VARCHAR2(20)  := 'VALUE';            -- �l
  cv_tkn_table             CONSTANT VARCHAR2(20)  := 'TABLE';            -- �e�[�u����
  cv_tkn_errmsg            CONSTANT VARCHAR2(20)  := 'ERR_MSG';          -- �G���[���e
  cv_tkn_input_item_code   CONSTANT VARCHAR2(20)  := 'INPUT_ITEM_CODE';  -- WK�̕i�ڃR�[�h
  cv_tkn_item_um           CONSTANT VARCHAR2(20)  := 'ITEM_UM';          -- ��P��
  cv_tkn_msg               CONSTANT VARCHAR2(20)  := 'MSG';              -- �R���J�����g�I�����b�Z�[�W
  cv_tkn_col_name          CONSTANT VARCHAR2(20)  := 'INPUT_COL_NAME';   -- ���ږ�
  cv_tkn_req_id            CONSTANT VARCHAR2(20)  := 'REQ_ID';           -- �v��ID
  cv_tkn_up_name           CONSTANT VARCHAR2(20)  := 'UPLOAD_NAME';      -- �t�@�C���A�b�v���[�h����
  cv_tkn_file_id           CONSTANT VARCHAR2(20)  := 'FILE_ID';          -- �t�@�C��ID
  cv_tkn_file_format       CONSTANT VARCHAR2(20)  := 'FORMAT';           -- �t�H�[�}�b�g
  cv_tkn_file_name         CONSTANT VARCHAR2(20)  := 'FILE_NAME';        -- �t�@�C����
  cv_tkn_count             CONSTANT VARCHAR2(20)  := 'COUNT';            -- ��������
  cv_tkn_ng_profile        CONSTANT VARCHAR2(20)  := 'NG_PROFILE';       -- �v���t�@�C��NG
  cv_tkn_input_line_no     CONSTANT VARCHAR2(20)  := 'INPUT_LINE_NO';    -- �s�ԍ�
--
  -- �A�v���P�[�V�����Z�k��
  cv_appl_name_xxcmn       CONSTANT VARCHAR2(5)   := 'XXCMN';            -- XXCMN
--
  -- �v���t�@�C��
  cv_prf_item_num          CONSTANT VARCHAR2(60)  := 'XXCMN_ITEM_NUM';                 -- �A�b�v���[�h���ڐ�
  cv_prf_ctg_item_prod     CONSTANT VARCHAR2(60)  := 'XXCMN_PRODUCT_DIV_CODE';         -- ���i���i�敪
  cv_prf_ctg_hon_prod      CONSTANT VARCHAR2(60)  := 'XXCMN_ARTI_DIV_CODE';            -- �{�Џ��i�敪
  cv_prf_ctg_mark_pg       CONSTANT VARCHAR2(60)  := 'XXCMN_MARKE_CROWD_CODE';         -- �}�[�P�p�Q�R�[�h
  cv_prf_ctg_gun_code      CONSTANT VARCHAR2(60)  := 'XXCMN_CATEGORY_NAME_OTGUN';      -- �Q�R�[�h
  cv_prf_ctg_item_div      CONSTANT VARCHAR2(60)  := 'XXCMN_ITEM_CLASS';               -- �i�ڋ敪
  cv_prf_ctg_inout_class   CONSTANT VARCHAR2(60)  := 'XXCMN_IN_OUT_CLASS';             -- ���O�敪
  cv_prf_ctg_fact_pg       CONSTANT VARCHAR2(60)  := 'XXCMN_CATEGORY_NAME_KJGUN';      -- �H��Q�R�[�h
  cv_prf_ctg_acnt_pg       CONSTANT VARCHAR2(60)  := 'XXCMN_ACNT_CROWD_CODE';          -- �o�����p�Q�R�[�h
  cv_prf_ctg_seisakugun    CONSTANT VARCHAR2(60)  := 'XXCMN_POLICY_GROUP_CODE';        -- ����Q�R�[�h
  cv_prf_ctg_baracha_class CONSTANT VARCHAR2(60)  := 'XXCMN_DIV_TEA_CODE';             -- �o�����敪
  cv_prf_ctg_product_div   CONSTANT VARCHAR2(60)  := 'XXCMN_PROD_CLASS';               -- ���i�敪
  cv_prf_ctg_quality_class CONSTANT VARCHAR2(60)  := 'XXCMN_QUALITY_CLASS';            -- �i���敪
  cv_prf_mst_org_code      CONSTANT VARCHAR2(60)  := 'XXCMN_MST_ORG_CODE';             -- �}�X�^�݌ɑg�D�R�[�h
--
  -- LOOKUP
  cv_lookup_need_test      CONSTANT VARCHAR2(30)  := 'XXCMN_NEED_TEST';                -- �����L���敪
  cv_lookup_type           CONSTANT VARCHAR2(30)  := 'XXCMN_D01';                      -- �^���
  cv_lookup_product_class  CONSTANT VARCHAR2(30)  := 'XXCMN_D02';                      -- ���i����
  cv_lookup_uom_class      CONSTANT VARCHAR2(30)  := 'XXCMN_UOM_CLASS';                -- �P�ʋ敪
  cv_lookup_trace_class    CONSTANT VARCHAR2(30)  := 'XXCMN_TRACE_CLASS';              -- �g���[�X�敪
  cv_lookup_rate           CONSTANT VARCHAR2(30)  := 'XXCMN_RATE';                     -- ���敪
  cv_lookup_item_def       CONSTANT VARCHAR2(30)  := 'XXCMN_ITEM_DEF';                 -- �o�^���ڒ�`
  cv_lookup_product_type   CONSTANT VARCHAR2(30)  := 'XXCMN_D03';                      -- ���i���
  cv_lookup_bottle_class   CONSTANT VARCHAR2(30)  := 'XXCMN_BOTTLE_CLASS';             -- �e��敪
  cv_lookup_inventory_chk_class
                           CONSTANT VARCHAR2(30)  := 'XXCMN_INVENTORY_CHK_CLASS';      -- �I���敪
  cv_lookup_we_ca_class    CONSTANT VARCHAR2(30)  := 'XXCMN_WEIGHT_CAPACITY_CLASS';    -- �d�ʗe�ϋ敪
  cv_lookup_vendor_deriday_ty
                           CONSTANT VARCHAR2(30)  := 'XXCMN_VENDOR_PRICE_DERI_DAY_TY'; -- ���o���^�C�v
  cv_lookup_shelf_life_class
                           CONSTANT VARCHAR2(30)  := 'XXCMN_SHELF_LIFE_CLASS';         -- �ܖ����ԋ敪
  cv_lookup_destination_diy
                           CONSTANT VARCHAR2(30)  := 'XXCMN_DESTINATION_DIV';          -- �d���敪
  cv_lookup_cost_management
                           CONSTANT VARCHAR2(30)  := 'XXCMN_COST_MANAGEMENT';          -- �����Ǘ��敪
--
  -- �e�[�u����
  cv_table_flv             CONSTANT VARCHAR2(30)  := 'LOOKUP�\';
  cv_table_mcv             CONSTANT VARCHAR2(30)  := '�J�e�S��';
  cv_table_iimb            CONSTANT VARCHAR2(30)  := 'OPM�i�ڃ}�X�^';
  cv_table_ximb            CONSTANT VARCHAR2(30)  := 'OPM�i�ڃA�h�I��';
  cv_table_mic             CONSTANT VARCHAR2(30)  := 'Disc�i�ڃJ�e�S������';
  cv_table_xwibr           CONSTANT VARCHAR2(60)  := '�i�ڃ}�X�^�ꊇ�A�b�v���[�h���[�N';
  cv_table_xmfui           CONSTANT VARCHAR2(60)  := '�t�@�C���A�b�v���[�hIF';
  cv_table_def             CONSTANT VARCHAR2(60)  := '�i�ڃ}�X�^�ꊇ�A�b�v���[�h���[�N��`���';
  -- �t�H�[�}�b�g
  cv_file_id               CONSTANT VARCHAR2(20)  := 'FILE_ID';                     -- �t�@�C��ID
  cv_format_check          CONSTANT VARCHAR2(20)  := '�t�H�[�}�b�g�p�^�[��';        -- �t�H�[�}�b�g
  cv_upload_name           CONSTANT VARCHAR2(30)  := '�i�ڃ}�X�^�ꊇ�A�b�v���[�h';  -- �I�u�W�F�N�g
--
  -- ����
  cv_judge_times_num       CONSTANT VARCHAR2(30)  := '�����';
  cv_order_judge_times_num CONSTANT VARCHAR2(30)  := '�����\�����';
  cv_inspection_lt         CONSTANT VARCHAR2(30)  := '����L/T';
  cv_item_batch_regist     CONSTANT VARCHAR2(30)  := '�i�ڃ}�X�^�ꊇ�A�b�v���[�h'; 
  cv_mst_org_id            CONSTANT VARCHAR2(30)  := '�}�X�^�݌ɑg�DID'; 
  cv_null_ok               CONSTANT VARCHAR2(10)  := 'NULL_OK';           -- �C�Ӎ���
  cv_null_ng               CONSTANT VARCHAR2(10)  := 'NULL_NG';           -- �K�{����
  cv_varchar               CONSTANT VARCHAR2(10)  := 'VARCHAR2';          -- ������
  cv_number                CONSTANT VARCHAR2(10)  := 'NUMBER';            -- ���l
  cv_date                  CONSTANT VARCHAR2(10)  := 'DATE';              -- ���t
  cv_varchar_cd            CONSTANT VARCHAR2(1)   := '0';                 -- �����񍀖�
  cv_number_cd             CONSTANT VARCHAR2(1)   := '1';                 -- ���l����
  cv_date_cd               CONSTANT VARCHAR2(1)   := '2';                 -- ���t����
  cv_not_null              CONSTANT VARCHAR2(1)   := '1';                 -- �K�{
  cv_msg_comma             CONSTANT VARCHAR2(1)   := ',';                 -- �J���}
  cv_msg_comma_double      CONSTANT VARCHAR2(2)   := '�A';                -- �J���}(�S�p)
--
  cv_yes                   CONSTANT VARCHAR2(1)   := 'Y';                 -- YES
  cv_0                     CONSTANT VARCHAR2(1)   := '0';                 -- 0
  cv_max_date              CONSTANT VARCHAR2(10)  := '9999/12/31';        -- MAX���t
  cv_date_fmt_std          CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';        -- ���t
--
  -- �X�e�[�^�X
  cv_status_val_normal     CONSTANT VARCHAR2(10)  := '����';              -- ����:0
  cv_status_val_warn       CONSTANT VARCHAR2(10)  := '�x��';              -- �x��:1
  cv_status_val_error      CONSTANT VARCHAR2(10)  := '�G���[';            -- �G���[:2
--
  cv_prog_opmitem_trigger  CONSTANT VARCHAR2(20)  := 'XXCMN810003C';      -- OPM�i�ڃg���K�[�N��
--
-- Ver.1.1 S.Niki ADD START
  -- �i�ڃR�[�h����
  cn_item_code_length      CONSTANT NUMBER        := 7;     -- �i�ڃR�[�h����
-- Ver.1.1 S.Niki ADD END
  -- ��P��
  cv_item_um_0             CONSTANT VARCHAR2(2)   := '0';   -- ��P�ʃ`�F�b�N����
  cv_item_um_space         CONSTANT VARCHAR2(2)   := ' ';   -- ��P�ʃ`�F�b�N����
  -- �d�ʗe�ϋ敪
  cv_weight                CONSTANT VARCHAR2(1)   := '1';   -- �d��
  cv_volume                CONSTANT VARCHAR2(1)   := '2';   -- �e��
  -- �����L���敪
  cv_exam_class_0          CONSTANT NUMBER        := '0';   -- �u���v
  cv_exam_class_1          CONSTANT NUMBER        := '1';   -- �u�L�v
  -- ���b�g�Ǘ��敪
  cv_lot_ctl_class_yes     CONSTANT VARCHAR2(3)   := '1';   -- �L
  cv_lot_ctl_class_no      CONSTANT VARCHAR2(3)   := '0';   -- ��
  -- �������b�g�̔ԗL��
  cv_autolot_active_indicate_1
                           CONSTANT VARCHAR2(1)   := '1';   -- �L
  cv_autolot_active_indicate_0   
                           CONSTANT VARCHAR2(1)   := '0';   -- ��
  -- ���b�g�E�T�t�B�b�N�X
  cv_lot_suffix_0          CONSTANT VARCHAR2(1)   := '0';
  -- �����
  cn_judge_times_num_1     CONSTANT VARCHAR2(1)   := 1;   -- 1��
  cn_judge_times_num_2     CONSTANT VARCHAR2(1)   := 2;   -- 2��
  cn_judge_times_num_3     CONSTANT VARCHAR2(1)   := 3;   -- 3��
  -- ��d�Ǘ�
  cv_dualum                CONSTANT VARCHAR2(1)   := '0';   -- ���d
  -- �ۊǏꏊ
  cv_loct_ctl              CONSTANT VARCHAR2(1)   := '1';   -- ���؍ς�
  -- �ƍ�
  cv_match_type            CONSTANT VARCHAR2(1)   := '3';   -- �������w���I�[�_�[���
  -- �o�׋敪
  cv_shipping_class        CONSTANT VARCHAR2(1)   := '0';   -- �o�וs��
  -- �i�ڋ敪
  cv_item_class            CONSTANT VARCHAR2(1)   := '2';   -- ����
  -- ���o�Ɋ��Z�P��
  cv_mtl_units_of_measure
                           CONSTANT VARCHAR2(2)   := 'CS';  -- CS
  -- �p�~�敪
  cv_inactive_class        CONSTANT VARCHAR2(1)   := '0';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���ڒ�`
  TYPE g_item_def_rtype    IS RECORD                                    -- ���R�[�h�^��錾
      (item_name             VARCHAR2(100)                              -- ���ږ�
      ,item_attribute        VARCHAR2(100)                              -- ���ڑ���
      ,item_essential        VARCHAR2(100)                              -- �K�{�t���O
      ,item_length           NUMBER                                     -- ���ڂ̒���(��������)
      ,decim                 NUMBER                                     -- ���ڂ̒���(�����_�ȉ�)
      );
  -- �J�e�S�����
  TYPE g_item_ctg_rtype    IS RECORD                                    -- ���R�[�h�^��錾
      (segment1              xxcmn_categories_v.segment1%TYPE           -- segment1
      ,category_set_name     xxcmn_categories_v.category_set_name%TYPE  -- �J�e�S���Z�b�g��
      ,category_val          VARCHAR2(240)                              -- �J�e�S���Z�b�g�l
      ,item_code             VARCHAR2(240)                              -- �i�ڃR�[�h
      ,ssk_category_id       mtl_categories_b.category_id%TYPE          -- �J�e�S��ID(���i���i�敪)
      ,ssk_category_set_id   mtl_category_sets_b.category_set_id%TYPE   -- �J�e�S���Z�b�gID(���i���i�敪)
      ,hsk_category_id       mtl_categories_b.category_id%TYPE          -- �J�e�S��ID(�{�Џ��i�敪)
      ,hsk_category_set_id   mtl_category_sets_b.category_set_id%TYPE   -- �J�e�S���Z�b�gID(�{�Џ��i�敪)
      ,sg_category_id        mtl_categories_b.category_id%TYPE          -- �J�e�S��ID(����Q)
      ,sg_category_set_id    mtl_category_sets_b.category_set_id%TYPE   -- �J�e�S���Z�b�gID(����Q)
      ,bd_category_id        mtl_categories_b.category_id%TYPE          -- �J�e�S��ID(�o�����敪)
      ,bd_category_set_id    mtl_category_sets_b.category_set_id%TYPE   -- �J�e�S���Z�b�gID(�o�����敪)
      ,mgc_category_id       mtl_categories_b.category_id%TYPE          -- �J�e�S��ID(�}�[�P�p�Q�R�[�h)
      ,mgc_category_set_id   mtl_category_sets_b.category_set_id%TYPE   -- �J�e�S���Z�b�gID(�}�[�P�p�Q�R�[�h)
      ,pg_category_id        mtl_categories_b.category_id%TYPE          -- �J�e�S��ID(�Q�R�[�h)
      ,pg_category_set_id    mtl_category_sets_b.category_set_id%TYPE   -- �J�e�S���Z�b�gID(�Q�R�[�h)
      ,itd_category_id       mtl_categories_b.category_id%TYPE          -- �J�e�S��ID(�i�ڋ敪)
      ,itd_category_set_id   mtl_category_sets_b.category_set_id%TYPE   -- �J�e�S���Z�b�gID(�i�ڋ敪)
      ,ind_category_id       mtl_categories_b.category_id%TYPE          -- �J�e�S��ID(���O�敪)
      ,ind_category_set_id   mtl_category_sets_b.category_set_id%TYPE   -- �J�e�S���Z�b�gID(���O�敪)
      ,pd_category_id        mtl_categories_b.category_id%TYPE          -- �J�e�S��ID(���i�敪)
      ,pd_category_set_id    mtl_category_sets_b.category_set_id%TYPE   -- �J�e�S���Z�b�gID(���i�敪)
      ,qd_category_id        mtl_categories_b.category_id%TYPE          -- �J�e�S��ID(�i���敪)
      ,qd_category_set_id    mtl_category_sets_b.category_set_id%TYPE   -- �J�e�S���Z�b�gID(�i���敪)
      ,fpg_category_id       mtl_categories_b.category_id%TYPE          -- �J�e�S��ID(�H��Q�R�[�h)
      ,fpg_category_set_id   mtl_category_sets_b.category_set_id%TYPE   -- �J�e�S���Z�b�gID(�H��Q�R�[�h)
      ,apg_category_id       mtl_categories_b.category_id%TYPE          -- �J�e�S��ID(�o�����p�Q�R�[�h)
      ,apg_category_set_id   mtl_category_sets_b.category_set_id%TYPE   -- �J�e�S���Z�b�gID(�o�����p�Q�R�[�h)
      );
  -- Disc�i�ڏ��
  TYPE g_disc_item_rtype IS RECORD                                      -- ���R�[�h�^��錾
      (item_id               ic_item_mst_b.item_id%TYPE                 -- OPM�i��ID
      ,item_no               ic_item_mst_b.item_no%TYPE                 -- �i�ڃR�[�h
      ,inventory_item_id     mtl_system_items_b.inventory_item_id%TYPE  -- Disc�i��ID
      ,line_no               xxcmn_wk_item_batch_regist.line_no%TYPE    -- �s�ԍ�
      );
  -- �R���J�����g�p�����[�^ ���R�[�h�^�C�v
  TYPE g_conc_argument_rtype IS RECORD
  ( argument                 VARCHAR2(100)
  );
  -- �`�F�b�N�p���
  TYPE g_check_data_ttype IS TABLE OF VARCHAR2(4000)     INDEX BY BINARY_INTEGER;
  -- �R���J�����g�p�����[�^ �e�[�u���^�C�v
  TYPE g_conc_argument_ttype   IS TABLE OF g_conc_argument_rtype   INDEX BY BINARY_INTEGER;
  -- ���ڒ�`���  
  TYPE g_item_def_ttype   IS TABLE OF g_item_def_rtype      INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date       DATE;                                                 -- �Ɩ����t
  gd_apply_date         DATE;                                                 -- �K�p�J�n���F���t�^�ϊ���
  gn_file_id            NUMBER;                                               -- �p�����[�^�i�[�p�ϐ�
  gn_item_num           NUMBER;                                               -- �i�ڃ}�X�^�ꊇ�A�b�v���[�h�f�[�^���ڐ��i�[�p
  -- �i�ڃJ�e�S�����
  gt_ctg_item_prod      fnd_profile_option_values.profile_option_value%TYPE;  -- ���i���i�敪
  gt_ctg_hon_prod       fnd_profile_option_values.profile_option_value%TYPE;  -- �{�Џ��i�敪
  gt_ctg_mark_pg        fnd_profile_option_values.profile_option_value%TYPE;  -- �}�[�P�p�Q�R�[�h
  gt_ctg_gun_code       fnd_profile_option_values.profile_option_value%TYPE;  -- �Q�R�[�h
  gt_ctg_item_class     fnd_profile_option_values.profile_option_value%TYPE;  -- �i�ڋ敪
  gt_ctg_inout_class    fnd_profile_option_values.profile_option_value%TYPE;  -- ���O�敪
  gt_ctg_fact_pg        fnd_profile_option_values.profile_option_value%TYPE;  -- �H��Q�R�[�h
  gt_ctg_acnt_pg        fnd_profile_option_values.profile_option_value%TYPE;  -- �o�����p�Q�R�[�h
  gt_ctg_seisakugun     fnd_profile_option_values.profile_option_value%TYPE;  -- ����Q�R�[�h
  gt_ctg_baracha_class  fnd_profile_option_values.profile_option_value%TYPE;  -- �o�����敪
  gt_ctg_product_div    fnd_profile_option_values.profile_option_value%TYPE;  -- ���i�敪
  gt_ctg_quality_class  fnd_profile_option_values.profile_option_value%TYPE;  -- �i���敪
  gt_master_org_code    fnd_profile_option_values.profile_option_value%TYPE;  -- �}�X�^�[�݌ɑg�D�R�[�h
  --
  gn_master_org_id      mtl_parameters.master_organization_id%TYPE;           -- �}�X�^�[�݌ɑg�DID
  g_item_def_tab        g_item_def_ttype;                                     -- �e�[�u���^�ϐ��̐錾
  gv_format             VARCHAR2(100);                                        -- �p�����[�^�i�[�p�ϐ�
-- Ver.1.1 S.Niki ADD START
  gt_whse_item_id       ic_item_mst_b.whse_item_id%TYPE;                      -- �q�ɕi��ID
-- Ver.1.1 S.Niki ADD END
--
  -- ���������J�E���g�p
  gn_get_normal_cnt     NUMBER;                                               -- �^/�T�C�Y/�K�{�`�F�b�NOK����
  gn_get_error_cnt      NUMBER;                                               -- �^/�T�C�Y/�K�{�`�F�b�NNG����
  gn_val_normal_cnt     NUMBER;                                               -- �Ó����`�F�b�NOK����
  gn_val_error_cnt      NUMBER;                                               -- �Ó����`�F�b�NNG����
  gn_ins_normal_cnt     NUMBER;                                               -- �f�[�^�o�^OK����
  gn_ins_error_cnt      NUMBER;                                               -- �f�[�^�o�^NG����
--
  -- ===============================
  -- ���[�U�[��`�J�[�\���^
  -- ===============================
  -- �i�ڃ}�X�^�ꊇ�A�b�v���[�h�f�[�^�擾�J�[�\��
  CURSOR get_data_cur
  IS
    SELECT   xwibr.file_id                            AS file_id                  -- �t�@�C��ID
            ,xwibr.file_seq                           AS file_seq                 -- �t�@�C��SEQ
            ,xwibr.line_no                            AS line_no                  -- �s�ԍ�
            ,TRIM(xwibr.item_no)                      AS item_no                  -- �i��
            ,TRIM(xwibr.item_desc)                    AS item_desc                -- �E�v
            ,TRIM(xwibr.item_short_name)              AS item_short_name          -- ����
            ,TRIM(xwibr.item_name_alt)                AS item_name_alt            -- �J�i��
            ,TRIM(xwibr.warehouse_item)               AS warehouse_item           -- �q�ɕi��
            ,TRIM(xwibr.item_um)                      AS item_um                  -- �P�ʁi�݌ɒP�ʁj
            ,TRIM(xwibr.old_crowd)                    AS old_crowd                -- ���Q�R�[�h
            ,TRIM(xwibr.new_crowd)                    AS new_crowd                -- �V�Q�R�[�h
            ,TRIM(xwibr.crowd_start_date)             AS crowd_start_date         -- �Q�R�[�h�K�p�J�n��
            ,TRIM(xwibr.old_price)                    AS old_price                -- ���E�艿
            ,TRIM(xwibr.new_price)                    AS new_price                -- �V�E�艿
            ,TRIM(xwibr.price_start_date)             AS price_start_date         -- �艿�K�p�J�n��
            ,TRIM(xwibr.old_business_cost)            AS old_business_cost        -- ���E�c�ƌ��� 
            ,TRIM(xwibr.new_business_cost)            AS new_business_cost        -- �V�E�c�ƌ��� 
            ,TRIM(xwibr.business_start_date)          AS business_start_date      -- �c�ƌ����J�n�� 
            ,TRIM(xwibr.sale_start_date)              AS sale_start_date          -- �����J�n��
            ,TRIM(xwibr.jan_code)                     AS jan_code                 -- JAN�R�[�h
            ,TRIM(xwibr.itf_code)                     AS itf_code                 -- ITF�R�[�h
            ,TRIM(xwibr.case_num)                     AS case_num                 -- �P�[�X����
            ,TRIM(xwibr.net)                          AS net                      -- NET
            ,TRIM(xwibr.weight_volume_class)          AS weight_volume_class      -- �d�ʗe�ϋ敪
            ,TRIM(xwibr.weight)                       AS weight                   -- �d��
            ,TRIM(xwibr.volume)                       AS volume                   -- �e��
            ,TRIM(xwibr.destination_class)            AS destination_class        -- �d���敪
            ,TRIM(xwibr.cost_management_class)        AS cost_management_class    -- �����Ǘ��敪
            ,TRIM(xwibr.vendor_price_deriday_ty)      AS vendor_price_deriday_ty  -- �P�����o���^�C�v
            ,TRIM(xwibr.represent_num)                AS represent_num            -- ��\����
            ,TRIM(xwibr.mtl_units_of_measure_tl)      AS mtl_units_of_measure_tl  -- ���o�Ɋ��Z�P��
            ,TRIM(xwibr.need_test_class)              AS need_test_class          -- �����L���敪
            ,TRIM(xwibr.inspection_lt)                AS inspection_lt            -- ����L/T
            ,TRIM(xwibr.judgment_times_num)           AS judgment_times_num       -- �����
            ,TRIM(xwibr.order_judge_times_num)        AS order_judge_times_num    -- �����\�����
            ,TRIM(xwibr.crowd_code)                   AS crowd_code               -- �Q�R�[�h
            ,TRIM(xwibr.policy_group_code)            AS policy_group_code        -- ����Q�R�[�h
            ,TRIM(xwibr.mark_crowd_code)              AS mark_crowd_code          -- �}�[�P�p�Q�R�[�h
            ,TRIM(xwibr.acnt_crowd_code)              AS acnt_crowd_code          -- �o�����p�Q�R�[�h
            ,TRIM(xwibr.item_product_class)           AS item_product_class       -- ���i���i�敪
            ,TRIM(xwibr.hon_product_class)            AS hon_product_class        -- �{�Џ��i�敪
            ,TRIM(xwibr.product_div)                  AS product_div              -- ���i�敪
            ,TRIM(xwibr.item_class)                   AS item_class               -- �i�ڋ敪
            ,TRIM(xwibr.inout_class)                  AS inout_class              -- ���O�敪
            ,TRIM(xwibr.baracha_class)                AS baracha_class            -- �o�����敪
            ,TRIM(xwibr.quality_class)                AS quality_class            -- �i���敪
            ,TRIM(xwibr.fact_crowd_code)              AS fact_crowd_code          -- �H��Q�R�[�h
            ,TRIM(xwibr.start_date_active)            AS start_date_active        -- �K�p�J�n��
            ,TRIM(xwibr.expiration_day_class)         AS expiration_day_class     -- �ܖ����ԋ敪
            ,TRIM(xwibr.expiration_day)               AS expiration_day           -- �ܖ�����
            ,TRIM(xwibr.shelf_life)                   AS shelf_life               -- �������
            ,TRIM(xwibr.delivery_lead_time)           AS delivery_lead_time       -- �[������
            ,TRIM(xwibr.case_weight_volume)           AS case_weight_volume       -- �P�[�X�d�ʗe��
            ,TRIM(xwibr.raw_material_consumpe)        AS raw_material_consumpe    -- �����g�p��
            ,TRIM(xwibr.standard_yield)               AS standard_yield           -- �W������
            ,TRIM(xwibr.model_type)                   AS model_type               -- �^���
            ,TRIM(xwibr.product_class)                AS product_class            -- ���i����
            ,TRIM(xwibr.product_type)                 AS product_type             -- ���i���
            ,TRIM(xwibr.shipping_cs_unit_qty)         AS shipping_cs_unit_qty     -- �o�ד���
            ,TRIM(xwibr.palette_max_cs_qty)           AS palette_max_cs_qty       -- �p���z��
            ,TRIM(xwibr.palette_max_step_qty)         AS palette_max_step_qty     -- �p���i��
            ,TRIM(xwibr.palette_step_qty)             AS palette_step_qty         -- �p���b�g�i
            ,TRIM(xwibr.bottle_class)                 AS bottle_class             -- �e��敪
            ,TRIM(xwibr.uom_class)                    AS uom_class                -- �P�ʋ敪
            ,TRIM(xwibr.inventory_chk_class)          AS inventory_chk_class      -- �I���敪
            ,TRIM(xwibr.trace_class)                  AS trace_class              -- �g���[�X�敪
            ,TRIM(xwibr.rate_class)                   AS rate_class               -- ���敪
            ,TRIM(xwibr.shipping_end_date)            AS shipping_end_date        -- �o�ג�~��
            ,xwibr.created_by                         AS created_by               -- �쐬��
            ,xwibr.creation_date                      AS creation_date            -- �쐬��
            ,xwibr.last_updated_by                    AS last_updated_by          -- �ŏI�X�V��
            ,xwibr.last_update_date                   AS last_update_date         -- �ŏI�X�V��
            ,xwibr.last_update_login                  AS last_update_login        -- �ŏI���O�C��ID
            ,xwibr.request_id                         AS request_id               -- �v��ID
            ,xwibr.program_application_id             AS program_application_id   -- �A�v���P�[�V����ID
            ,xwibr.program_id                         AS program_id               -- �v���O����ID
            ,xwibr.program_update_date                AS program_update_date      -- �X�V��
    FROM     xxcmn_wk_item_batch_regist  xwibr                                    -- �i�ڃ}�X�^�ꊇ�A�b�v���[�h���[�N
    WHERE    xwibr.request_id = gn_request_id                                     -- �v��ID
    ORDER BY file_seq                                                             -- �t�@�C��SEQ
    ;
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --*** ���b�N�G���[��O ***
  global_check_lock_expt     EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : chk_exists_category
   * Description      : �J�e�S�����݃`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_exists_category(
    iv_category_set_name IN  VARCHAR2          -- �J�e�S���Z�b�g��
   ,iv_category_val      IN  VARCHAR2          -- �J�e�S���l
   ,iv_item_code         IN  VARCHAR2          -- �i�ڃR�[�h
   ,on_catregory_id      OUT NUMBER            -- �J�e�S��ID
   ,on_catregory_set_id  OUT NUMBER            -- �J�e�S���Z�b�gID
   ,ov_errbuf            OUT VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode           OUT VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg            OUT VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_exists_category'; -- �v���O������
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
    lv_sqlerrm                VARCHAR2(5000);                     -- SQLERRM�ϐ��ޔ�p
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
    get_data_expt             EXCEPTION;                          -- �f�[�^���o�G���[
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
    -- �J�e�S��VIEW���݃`�F�b�N
    --==============================================================
    BEGIN
      SELECT xcv.category_id      AS category_id      -- �J�e�S��ID
            ,xcv.category_set_id  AS category_set_id  -- �J�e�S���Z�b�gID
      INTO   on_catregory_id
            ,on_catregory_set_id
      FROM   xxcmn_categories_v xcv  -- �J�e�S��VIEW
      WHERE  xcv.category_set_name = iv_category_set_name  -- �J�e�S���Z�b�g��
      AND    xcv.segment1          = iv_category_val       -- �J�e�S���l
      ;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_sqlerrm := SQLERRM;
        RAISE get_data_expt;
      WHEN OTHERS THEN
        lv_sqlerrm := SQLERRM;
        RAISE get_data_expt;
    END;
--
  EXCEPTION
    -- *** �f�[�^���o��O�n���h�� ***
    WHEN get_data_expt THEN
      -- �f�[�^���o�G���[
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmn_10622            -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_table_mcv
                                        || '(' || iv_category_set_name || ')'
                                                                      -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_input_item_code        -- �g�[�N���R�[�h2
                    ,iv_token_value2 => iv_item_code                  -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_errmsg                 -- �g�[�N���R�[�h3
                    ,iv_token_value3 => lv_sqlerrm                    -- �g�[�N���l3
                   );
      ov_errmsg  := lv_errmsg;
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
  END chk_exists_category;
--
  /**********************************************************************************
   * Procedure Name   : chk_exists_lookup
   * Description      : LOOKUP�\���݃`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_exists_lookup(
    iv_lookup_type   IN  VARCHAR2  -- �Q�ƃ^�C�v
   ,iv_lookup_code   IN  VARCHAR2  -- �Q�ƃ^�C�v�R�[�h
   ,iv_item_code     IN  VARCHAR2  -- �i�ڃR�[�h
   ,ov_errbuf        OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode       OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg        OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_exists_lookup'; -- �v���O������
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
    lt_lookup_code            fnd_lookup_values.lookup_code%TYPE; -- ���oLOOKUP_CODE
    lv_sqlerrm                VARCHAR2(5000);                     -- SQLERRM�ϐ��ޔ�p
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
    get_data_expt             EXCEPTION;                          -- �f�[�^���o�G���[
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
    -- LOOKUP�\���݃`�F�b�N
    BEGIN
      SELECT xlvv.lookup_code  AS lookup_code
      INTO   lt_lookup_code
      FROM   xxcmn_lookup_values_v xlvv  -- �N�C�b�N�R�[�h���VIEW
      WHERE  xlvv.lookup_type  = iv_lookup_type
      AND    xlvv.lookup_code  = iv_lookup_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_sqlerrm := SQLERRM;
        RAISE get_data_expt;
      WHEN OTHERS THEN
        lv_sqlerrm := SQLERRM;
        RAISE get_data_expt;
    END;
--
  EXCEPTION
    -- *** �f�[�^���o��O�n���h�� ***
    WHEN get_data_expt THEN
      -- �f�[�^���o�G���[
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmn_10622            -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_table_flv
                                        || '(' || iv_lookup_type || ')'
                                                                      -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_input_item_code        -- �g�[�N���R�[�h2
                    ,iv_token_value2 => iv_item_code                  -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_errmsg                 -- �g�[�N���R�[�h3
                    ,iv_token_value3 => lv_sqlerrm                    -- �g�[�N���l3
                   );
      ov_errmsg  := lv_errmsg;
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
  END chk_exists_lookup;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_comp
   * Description      : �I������ (D-8)
   ***********************************************************************************/
  PROCEDURE proc_comp(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_comp'; -- �v���O������
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
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
    --
--##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  �Œ蕔 END   ############################
    --
    --==============================================================
    -- D-8.1 �i�ڃ}�X�^�ꊇ�A�b�v���[�h�f�[�^�폜
    --==============================================================
    BEGIN
      DELETE
      FROM  xxcmn_wk_item_batch_regist  xwibr
      ;
      --
    EXCEPTION
      -- *** �f�[�^�폜��O�n���h�� ***
      WHEN OTHERS THEN
        --
        lv_errmsg  := xxcmn_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmn         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmn_10630         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_xwibr             -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_errmsg              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                    -- �g�[�N���l2
                      );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
        --
        ov_retcode := cv_status_error;
    END;
    --
    --==============================================================
    -- D-8.2 �t�@�C���A�b�v���[�hIF�e�[�u���f�[�^�폜
    --==============================================================
    BEGIN
      DELETE
      FROM  xxinv_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id = gn_file_id
      ;
      --
    EXCEPTION
      -- *** �f�[�^�폜��O�n���h�� ***
      WHEN OTHERS THEN
        --
        lv_errmsg  := xxcmn_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmn         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmn_10630         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_xmfui             -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_errmsg              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                    -- �g�[�N���l2
                      );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
        --
        ov_retcode := cv_status_error;
    END;
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
  END proc_comp;
--
  /**********************************************************************************
   * Procedure Name   : ins_data
   * Description      : �f�[�^�o�^ (D-5)
   ***********************************************************************************/
  PROCEDURE ins_data(
    i_wk_item_rec  IN  get_data_cur%ROWTYPE      -- �i�ڃ}�X�^�ꊇ�A�b�v���[�h���
   ,i_item_ctg_rec IN  g_item_ctg_rtype          -- �J�e�S�����
   ,ov_errbuf      OUT VARCHAR2                  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT VARCHAR2                  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT VARCHAR2                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_data'; -- �v���O������
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
    ln_conc_cnt               NUMBER;           -- �s�J�E���^(�R���J�����g)
    --
    l_opm_item_rec            ic_item_mst_b%ROWTYPE;
    l_opm_category_rec        xxcmm_004common_pkg.opmitem_category_rtype;  -- OPM�i�ڃJ�e�S�������o�^�p
    ln_item_id                ic_item_mst_b.item_id%TYPE;                  -- �V�[�P���XGET�p�i��ID
    lv_tkn_table              VARCHAR2(60);
-- Ver.1.1 S.Niki ADD START
    lt_whse_item_id           ic_item_mst_b.whse_item_id%TYPE;             -- �q�ɕi��ID
-- Ver.1.1 S.Niki ADD END
--
    -- *** ���[�J���E�J�[�\�� ***
    --
    -- *** ���[�J���E���R�[�h ***
    --
    -- *** ���[�J�����[�U�[��`��O ***
    ins_err_expt              EXCEPTION;                              -- �f�[�^�o�^�G���[
    concurrent_expt           EXCEPTION;                              -- �R���J�����g���s�G���[
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- D-5.1 OPM�i��ID�擾
    --==============================================================
    -- ������
    l_opm_item_rec := NULL;
    --
    SELECT gem5_item_id_s.NEXTVAL  AS item_id
    INTO   ln_item_id
    FROM   DUAL
    ;
-- Ver.1.1 S.Niki ADD START
    --==============================================================
    -- �q�ɕi��ID�擾
    --==============================================================
    -- �i�ڃR�[�h�Ƒq�ɕi�ڂ̒l���قȂ�ꍇ
    IF ( i_wk_item_rec.item_no <> i_wk_item_rec.warehouse_item ) THEN
      -- D-4�Ŏ擾�����q�ɕi��ID���Z�b�g
      lt_whse_item_id := gt_whse_item_id;
    ELSE
      -- ��L�Ŏ擾����OPM�i��ID���Z�b�g
      lt_whse_item_id := ln_item_id;
    END IF;
-- Ver.1.1 S.Niki ADD END
    --
    --==============================================================
    -- D-5.2 OPM�i�ڃ}�X�^�o�^�p�̒l��ݒ�
    --==============================================================
    l_opm_item_rec.item_id                  := ln_item_id;                               -- �i��ID
    l_opm_item_rec.item_no                  := i_wk_item_rec.item_no;                    -- �i�ڃR�[�h
    l_opm_item_rec.item_desc1               := i_wk_item_rec.item_desc;                  -- �E�v
    l_opm_item_rec.item_um                  := i_wk_item_rec.item_um;                    -- ��P��
    l_opm_item_rec.dualum_ind               := cv_dualum;                                -- ��d�Ǘ�
    l_opm_item_rec.deviation_lo             := cv_0;                                     -- �΍��W��-
    l_opm_item_rec.deviation_hi             := cv_0;                                     -- �΍��W��+
    -- �i�ڋ敪���u2�F���ށv�̏ꍇ�A�uNo�v��ݒ�B����ȊO�̏ꍇ�A�uYes�v��ݒ�
    IF ( i_wk_item_rec.item_class = cv_item_class ) THEN
      l_opm_item_rec.lot_ctl                := cv_lot_ctl_class_no;                      -- ���b�g�Ǘ��敪
    ELSE
      l_opm_item_rec.lot_ctl                := cv_lot_ctl_class_yes;                     -- ���b�g�Ǘ��敪
    END IF;
    l_opm_item_rec.lot_indivisible          := cv_0;                                     -- �����s��
    l_opm_item_rec.sublot_ctl               := cv_0;                                     -- �T�u���b�g
    l_opm_item_rec.loct_ctl                 := cv_loct_ctl;                              -- �ۊǏꏊ
    l_opm_item_rec.noninv_ind               := cv_0;                                     -- ��݌�
    l_opm_item_rec.match_type               := cv_match_type;                            -- �ƍ�
    l_opm_item_rec.inactive_ind             := cv_0;                                     -- �����敪
    l_opm_item_rec.shelf_life               := i_wk_item_rec.expiration_day;             -- �ۑ�����
    l_opm_item_rec.retest_interval          := cv_0;                                     -- �ăe�X�g�Ԋu
    l_opm_item_rec.grade_ctl                := cv_0;                                     -- �O���[�h
    l_opm_item_rec.status_ctl               := cv_0;                                     -- �X�e�[�^�X
    l_opm_item_rec.fill_qty                 := cv_0;                                     --
    l_opm_item_rec.expaction_interval       := cv_0;                                     --
    l_opm_item_rec.phantom_type             := cv_0;                                     --
-- Ver.1.1 S.Niki MOD START
--    l_opm_item_rec.whse_item_id             := l_opm_item_rec.item_id;                   --
    l_opm_item_rec.whse_item_id             := lt_whse_item_id;                          -- �q�ɕi��
-- Ver.1.1 S.Niki MOD END
    l_opm_item_rec.experimental_ind         := cv_0;                                     -- ����
    l_opm_item_rec.exported_date            := gd_process_date;                          --
    l_opm_item_rec.delete_mark              := cv_0;                                     --
    l_opm_item_rec.attribute1               := i_wk_item_rec.old_crowd;                  -- ���Q�R�[�h
    l_opm_item_rec.attribute2               := i_wk_item_rec.new_crowd;                  -- �V�Q�R�[�h
    l_opm_item_rec.attribute3               := i_wk_item_rec.crowd_start_date;           -- �Q�R�[�h�J�n��
    l_opm_item_rec.attribute4               := i_wk_item_rec.old_price;                  -- ���E�艿
    l_opm_item_rec.attribute5               := i_wk_item_rec.new_price;                  -- �V�E�艿
    l_opm_item_rec.attribute6               := i_wk_item_rec.price_start_date;           -- �艿�J�n��
    l_opm_item_rec.attribute7               := i_wk_item_rec.old_business_cost;          -- ���E�c�ƌ��� 
    l_opm_item_rec.attribute8               := i_wk_item_rec.new_business_cost;          -- �V�E�c�ƌ��� 
    l_opm_item_rec.attribute9               := i_wk_item_rec.business_start_date;        -- �c�ƌ����J�n��
    l_opm_item_rec.attribute10              := i_wk_item_rec.weight_volume_class;        -- �d�ʗe�ϋ敪
    l_opm_item_rec.attribute11              := i_wk_item_rec.case_num;                   -- �P�[�X����
    l_opm_item_rec.attribute12              := i_wk_item_rec.net;                        -- NET
    l_opm_item_rec.attribute13              := i_wk_item_rec.sale_start_date;            -- �����i�����j�J�n��
    l_opm_item_rec.attribute14              := i_wk_item_rec.inspection_lt;              -- ����L/T
    l_opm_item_rec.attribute15              := i_wk_item_rec.cost_management_class;      -- �����Ǘ��敪
    l_opm_item_rec.attribute16              := i_wk_item_rec.volume;                     -- �e��
    l_opm_item_rec.attribute17              := i_wk_item_rec.represent_num;              -- ��\����
    l_opm_item_rec.attribute18              := cv_shipping_class;                        -- �o�׋敪
    l_opm_item_rec.attribute20              := i_wk_item_rec.vendor_price_deriday_ty;    -- ���o���^�C�v
    l_opm_item_rec.attribute21              := i_wk_item_rec.jan_code;                   -- JAN�R�[�h
    l_opm_item_rec.attribute22              := i_wk_item_rec.itf_code;                   -- ITF�R�[�h
    l_opm_item_rec.attribute23              := i_wk_item_rec.need_test_class;            -- �����L���敪
    l_opm_item_rec.attribute24              := i_wk_item_rec.mtl_units_of_measure_tl;    -- ���o�Ɋ��Z�P��
    l_opm_item_rec.attribute25              := i_wk_item_rec.weight;                     -- �d��
    l_opm_item_rec.attribute26              := cv_0;                                     -- ����Ώۋ敪
    l_opm_item_rec.attribute27              := i_wk_item_rec.judgment_times_num;         -- �����
    l_opm_item_rec.attribute28              := i_wk_item_rec.destination_class;          -- �d���敪
    l_opm_item_rec.attribute29              := i_wk_item_rec.order_judge_times_num;      -- �����\�����
    --���b�g�Ǘ��敪���u�L�v�̏ꍇ�A�������b�g�̔ԗL���Ɂu1�v��ݒ�B��L�ȊO�̏ꍇ�́u0�v��ݒ�
    --���b�g�Ǘ��敪���u�L�v�̏ꍇ�A���b�g�E�T�t�B�b�N�X�Ɂu0�v��ݒ�B
    IF ( l_opm_item_rec.lot_ctl = cv_lot_ctl_class_yes ) THEN
      l_opm_item_rec.autolot_active_indicator   := cv_autolot_active_indicate_1;         -- �������b�g�̔ԗL��
      l_opm_item_rec.lot_suffix                 := cv_lot_suffix_0;                      -- ���b�g�E�T�t�B�b�N�X
    ELSE
      l_opm_item_rec.autolot_active_indicator   := cv_autolot_active_indicate_0;         -- �������b�g�̔ԗL��
    END IF;
    l_opm_item_rec.created_by               := gn_created_by;                            -- �쐬��
    l_opm_item_rec.creation_date            := gd_creation_date;                         -- �쐬��
    l_opm_item_rec.last_updated_by          := gn_last_updated_by;                       -- �ŏI�X�V��
    l_opm_item_rec.last_update_date         := gd_last_update_date;                      -- �ŏI�X�V��
    l_opm_item_rec.last_update_login        := gn_last_update_login;                     -- ���O�C��ID
    l_opm_item_rec.request_id               := gn_request_id;                            -- �v��ID
    l_opm_item_rec.program_application_id   := gn_program_application_id;                -- �A�v���P�[�V����
    l_opm_item_rec.program_id               := gn_program_id;                            -- �v���O����ID
    l_opm_item_rec.program_update_date      := gd_program_update_date;                   -- �X�V��
    --
    --==============================================================
    -- D-5.3 OPM�i�ڃ}�X�^�o�^
    --==============================================================
    xxcmm_004common_pkg.ins_opm_item(
      i_opm_item_rec => l_opm_item_rec
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_iimb;
      RAISE ins_err_expt;     -- �f�[�^�o�^��O
    END IF;
    --
    --==============================================================
    -- D-5.4 OPM�i�ڃA�h�I���}�X�^�o�^
    --==============================================================
    BEGIN
      INSERT INTO xxcmn_item_mst_b(
        item_id                                                      -- �i��ID
       ,start_date_active                                            -- �K�p�J�n��
       ,end_date_active                                              -- �K�p�I����
       ,active_flag                                                  -- �K�p�σt���O
       ,item_name                                                    -- ������
       ,item_short_name                                              -- ����
       ,item_name_alt                                                -- �J�i��
       ,parent_item_id                                               -- �e�i��ID
       ,obsolete_class                                               -- �p�~�敪
       ,obsolete_date                                                -- �p�~���i�������~���j
       ,model_type                                                   -- �^���
       ,product_class                                                -- ���i���� 
       ,product_type                                                 -- ���i���
       ,expiration_day                                               -- �ܖ�����
       ,delivery_lead_time                                           -- �[������
       ,whse_county_code                                             -- �H��Q�R�[�h
       ,standard_yield                                               -- �W������
       ,shipping_end_date                                            -- �o�ג�~��
       ,rate_class                                                   -- ���敪
       ,shelf_life                                                   -- �������
       ,shelf_life_class                                             -- �ܖ����ԋ敪
       ,bottle_class                                                 -- �e��敪
       ,uom_class                                                    -- �P�ʋ敪
       ,inventory_chk_class                                          -- �I���敪
       ,trace_class                                                  -- �g���[�X�敪
       ,shipping_cs_unit_qty                                         -- �o�ד���
       ,palette_max_cs_qty                                           -- �z��
       ,palette_max_step_qty                                         -- �p���b�g����ő�i��
       ,palette_step_qty                                             -- �p���b�g�i
       ,cs_weigth_or_capacity                                        -- �P�[�X�d�ʗe��
       ,raw_material_consumption                                     -- �����g�p��
       ,attribute1                                                   -- �\���P
       ,attribute2                                                   -- �\���Q
       ,attribute3                                                   -- �\���R
       ,attribute4                                                   -- �\���S
       ,attribute5                                                   -- �\���T
       ,created_by                                                   -- �쐬��
       ,creation_date                                                -- �쐬��
       ,last_updated_by                                              -- �ŏI�X�V��
       ,last_update_date                                             -- �ŏI�X�V��
       ,last_update_login                                            -- �ŏI�X�V���O�C��
       ,request_id                                                   -- �v��ID
       ,program_application_id                                       -- �A�v���P�[�V����ID
       ,program_id                                                   -- �v���O����ID
       ,program_update_date                                          -- �v���O�����ɂ��X�V��
      ) VALUES (
        ln_item_id                                                   -- �i��ID
       ,TO_DATE(i_wk_item_rec.start_date_active, cv_date_fmt_std)    -- �K�p�J�n��
       ,TO_DATE(cv_max_date, cv_date_fmt_std)                        -- �K�p�I����
       ,cv_yes                                                       -- �K�p�σt���O
       ,i_wk_item_rec.item_desc                                      -- ������
       ,i_wk_item_rec.item_short_name                                -- ����
       ,i_wk_item_rec.item_name_alt                                  -- �J�i��
       ,ln_item_id                                                   -- �e�i��ID
       ,cv_inactive_class                                            -- �p�~�敪
       ,NULL                                                         -- �p�~���i�������~���j
       ,i_wk_item_rec.model_type                                     -- �^���
       ,i_wk_item_rec.product_class                                  -- ���i���� 
       ,i_wk_item_rec.product_type                                   -- ���i���
       ,i_wk_item_rec.expiration_day                                 -- �ܖ�����
       ,i_wk_item_rec.delivery_lead_time                             -- �[������
       ,i_wk_item_rec.fact_crowd_code                                -- �H��Q�R�[�h
       ,i_wk_item_rec.standard_yield                                 -- �W������
       ,TO_DATE(i_wk_item_rec.shipping_end_date, cv_date_fmt_std)    -- �o�ג�~��
       ,i_wk_item_rec.rate_class                                     -- ���敪
       ,i_wk_item_rec.shelf_life                                     -- �������
       ,i_wk_item_rec.expiration_day_class                           -- �ܖ����ԋ敪
       ,i_wk_item_rec.bottle_class                                   -- �e��敪
       ,i_wk_item_rec.uom_class                                      -- �P�ʋ敪
       ,i_wk_item_rec.inventory_chk_class                            -- �I���敪
       ,i_wk_item_rec.trace_class                                    -- �g���[�X�敪
       ,i_wk_item_rec.shipping_cs_unit_qty                           -- �o�ד���
       ,i_wk_item_rec.palette_max_cs_qty                             -- �z��
       ,i_wk_item_rec.palette_max_step_qty                           -- �p���b�g����ő�i��
       ,i_wk_item_rec.palette_step_qty                               -- �p���b�g�i
       ,i_wk_item_rec.case_weight_volume                             -- �P�[�X�d�ʗe��
       ,i_wk_item_rec.raw_material_consumpe                          -- �����g�p��
       ,NULL                                                         -- �\���P
       ,NULL                                                         -- �\���Q
       ,NULL                                                         -- �\���R
       ,NULL                                                         -- �\���S
       ,NULL                                                         -- �\���T
       ,gn_created_by                                                -- �쐬��
       ,gd_creation_date                                             -- �쐬��
       ,gn_last_updated_by                                           -- �ŏI�X�V��
       ,gd_last_update_date                                          -- �ŏI�X�V��
       ,gn_last_update_login                                         -- �ŏI�X�V���O�C��
       ,gn_request_id                                                -- �v��ID
       ,gn_program_application_id                                    -- �A�v���P�[�V����ID
       ,gn_program_id                                                -- �v���O����ID
       ,gd_program_update_date                                       -- �v���O�����ɂ��X�V��
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf    := SQLERRM;
        lv_tkn_table := cv_table_ximb;
        RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END;
    --
    --==============================================================
    -- D-5.5 OPM�i�ڃJ�e�S������(���i���i�敪)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.ssk_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.ssk_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_item_prod;
      RAISE ins_err_expt;     -- �f�[�^�o�^��O
    END IF;
    --
    --==============================================================
    -- D-5.6 OPM�i�ڃJ�e�S������(�{�Џ��i�敪)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.hsk_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.hsk_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_hon_prod;
      RAISE ins_err_expt;     -- �f�[�^�o�^��O
    END IF;
    --
    --
    --==============================================================
    -- D-5.7 OPM�i�ڃJ�e�S������(����Q�R�[�h)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.sg_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.sg_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_seisakugun;
      RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END IF;
    --
    --==============================================================
    -- D-5.8 OPM�i�ڃJ�e�S������(�o�����敪)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.bd_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.bd_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_baracha_class;
      RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END IF;
    --
    --==============================================================
    -- D-5.9 OPM�i�ڃJ�e�S������(�}�[�P�p�Q�R�[�h)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.mgc_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.mgc_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_mark_pg;
      RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END IF;
    --
    --==============================================================
    -- D-5.10 OPM�i�ڃJ�e�S������(�Q�R�[�h)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.pg_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.pg_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_gun_code;
      RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END IF;
    --
    --==============================================================
    -- D-5.11 OPM�i�ڃJ�e�S������(�i�ڋ敪)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.itd_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.itd_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_item_class;
      RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END IF;
    --
    --==============================================================
    -- D-5.12 OPM�i�ڃJ�e�S������(���O�敪)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.ind_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.ind_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_inout_class;
      RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END IF;
    --
    --==============================================================
    -- D-5.13 OPM�i�ڃJ�e�S������(���i�敪)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.pd_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.pd_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_product_div;
      RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END IF;
    --
    --==============================================================
    -- D-5.14 OPM�i�ڃJ�e�S������(�i���敪)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.qd_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.qd_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_quality_class;
      RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END IF;
    --
    --==============================================================
    -- D-5.15 OPM�i�ڃJ�e�S������(�H��Q�R�[�h)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.fpg_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.fpg_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_fact_pg;
      RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END IF;
    --
    --==============================================================
    -- D-5.16 OPM�i�ڃJ�e�S������(�o�����p�Q�R�[�h)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.apg_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.apg_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_acnt_pg;
      RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END IF;
  --
  EXCEPTION
    -- *** �f�[�^�o�^��O�n���h�� ***
    WHEN ins_err_expt THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn         -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmn_10626         -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_table               -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_table               -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_input_line_no       -- �g�[�N���R�[�h2
                    ,iv_token_value2 => i_wk_item_rec.line_no      -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_input_item_code     -- �g�[�N���R�[�h3
                    ,iv_token_value3 => i_wk_item_rec.item_no      -- �g�[�N���l3
                    ,iv_token_name4  => cv_tkn_errmsg              -- �g�[�N���R�[�h4
                    ,iv_token_value4 => lv_errbuf                  -- �g�[�N���l4
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      --
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
  END ins_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_disc_categ_ref
   * Description      : Disc�i�ڃJ�e�S������ (D-7)
   ***********************************************************************************/
  PROCEDURE proc_disc_categ_ref(
    i_disc_item_rec  IN  g_disc_item_rtype  -- 1.Disc�i�ڏ��
   ,ov_errbuf        OUT VARCHAR2           -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode       OUT VARCHAR2           -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg        OUT VARCHAR2)          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_disc_categ_ref'; -- �v���O������
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
    lv_tkn_table          VARCHAR2(30);    -- ���b�Z�[�W�g�[�N���p
--
    -- *** ���[�J���E���R�[�h ***
    l_disc_category_rec   xxcmm_004common_pkg.discitem_category_rtype;
                                                                      -- �i�ڃJ�e�S�������o�^�p
--
    -- *** ���[�J���J�[�\�� ***
--
    -- OPM�i�ڃJ�e�S�������擾�J�[�\��
    CURSOR opm_item_categ_cur
    IS
      SELECT gic.category_set_id   AS category_set_id  -- �J�e�S���Z�b�gID
            ,gic.category_id       AS category_id      -- �J�e�S��ID
      FROM   gmi_item_categories   gic      -- OPM�i�ڃJ�e�S������
            ,mtl_category_sets_vl  mcs      -- �J�e�S���Z�b�g
      WHERE  gic.item_id           = i_disc_item_rec.item_id         -- �i��ID
      AND    gic.category_set_id   = mcs.category_set_id
      AND    mcs.category_set_name IN ( gt_ctg_item_prod       -- ���i���i�敪
                                      , gt_ctg_hon_prod        -- �{�Џ��i�敪
                                      , gt_ctg_mark_pg         -- �}�[�P�Q�R�[�h
                                      , gt_ctg_gun_code        -- �Q�R�[�h
                                      , gt_ctg_item_class      -- �i�ڋ敪
                                      , gt_ctg_inout_class     -- ���O�敪
                                      , gt_ctg_fact_pg         -- �H��Q�R�[�h
                                      , gt_ctg_acnt_pg         -- �o�����p�Q�R�[�h
                                      , gt_ctg_seisakugun      -- ����Q�R�[�h
                                      , gt_ctg_baracha_class   -- �o�����敪
                                      , gt_ctg_product_div     -- ���i�敪
                                      , gt_ctg_quality_class   -- �i���敪
                                      )
      ;
    -- OPM�i�ڃJ�e�S�������擾�J�[�\�����R�[�h�^
    opm_item_categ_rec   opm_item_categ_cur%ROWTYPE;
--
    -- *** ���[�J�����[�U�[��`��O ***
    ins_err_expt              EXCEPTION;                              -- �f�[�^�o�^�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- D-7.1 OPM�i�ڃJ�e�S���������擾
    --==============================================================
    OPEN opm_item_categ_cur;
    LOOP
      FETCH opm_item_categ_cur INTO opm_item_categ_rec;
      IF (opm_item_categ_cur%NOTFOUND) THEN
        CLOSE opm_item_categ_cur;
        EXIT;
      END IF;
--
      -- �擾�����J�e�S�����ɐݒ�
      l_disc_category_rec                   := NULL;
      l_disc_category_rec.inventory_item_id := i_disc_item_rec.inventory_item_id;    -- Disc�i��ID
      l_disc_category_rec.category_set_id   := opm_item_categ_rec.category_set_id;   -- �J�e�S���Z�b�gID
      l_disc_category_rec.category_id       := opm_item_categ_rec.category_id;       -- �J�e�S��ID
--
      --==============================================================
      -- D-7.2 Disc�i�ڃJ�e�S������
      --==============================================================
      xxcmm_004common_pkg.proc_discitem_categ_ref(
        i_item_category_rec => l_disc_category_rec  -- �i�ڃJ�e�S���������R�[�h�^�C�v
       ,ov_errbuf           => lv_errbuf
       ,ov_retcode          => lv_retcode
       ,ov_errmsg           => lv_errmsg
      );
      -- �������ʃ`�F�b�N
      IF ( lv_retcode <> cv_status_normal ) THEN
        CLOSE opm_item_categ_cur;
        lv_tkn_table := cv_table_mic;
        RAISE ins_err_expt;
      END IF;
    END LOOP disc_categ_loop;
--
  EXCEPTION
    -- *** �f�[�^�o�^��O�n���h�� ***
    WHEN ins_err_expt THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn         -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmn_10626         -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_table               -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_table               -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_input_line_no       -- �g�[�N���R�[�h2
                    ,iv_token_value2 => i_disc_item_rec.line_no    -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_input_item_code     -- �g�[�N���R�[�h3
                    ,iv_token_value3 => i_disc_item_rec.item_no    -- �g�[�N���l3
                    ,iv_token_name4  => cv_tkn_errmsg              -- �g�[�N���R�[�h4
                    ,iv_token_value4 => lv_errbuf                  -- �g�[�N���l4
                   );
      --
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      --
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
  END proc_disc_categ_ref;
--
  /**********************************************************************************
   * Procedure Name   : get_disc_item_data
   * Description      : Disc�i�ڏ��擾 (D-6)
   ***********************************************************************************/
  PROCEDURE get_disc_item_data(
    ov_errbuf            OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode           OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg            OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_disc_item_data'; -- �v���O������
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
    -- *** ���[�J���E�J�[�\�� ***
--
    -- Disc�i�ڏ��擾�J�[�\��
    CURSOR get_disc_item_cur
    IS
      SELECT iimb.item_id            AS item_id            -- �i��ID
            ,iimb.item_no            AS item_no            -- �i�ڃR�[�h
            ,msib.inventory_item_id  AS inventory_item_id  -- Disc�i��ID
            ,xwibr.line_no           AS line_no            -- �s�ԍ�
      FROM   xxcmn_wk_item_batch_regist xwibr  -- �i�ڃ}�X�^�ꊇ�A�b�v���[�h���[�N
            ,ic_item_mst_b              iimb   -- OPM�i�ڃ}�X�^
            ,mtl_system_items_b         msib   -- Disc�i�ڃ}�X�^
      WHERE  xwibr.item_no         = iimb.item_no
      AND    iimb.item_no          = msib.segment1
      AND    msib.organization_id  = gn_master_org_id
      ORDER BY xwibr.line_no
      ;
    -- Disc�i�ڏ��擾�J�[�\�����R�[�h�^
    get_disc_item_rec   get_disc_item_cur%ROWTYPE;
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
    --==============================================================
    -- D-6 Disc�i�ڏ��擾
    --==============================================================
    <<disc_item_loop>>
    FOR get_disc_item_rec IN get_disc_item_cur LOOP
      --==============================================================
      -- D-7 Disc�i�ڃJ�e�S������
      --==============================================================
      proc_disc_categ_ref(
        i_disc_item_rec  => get_disc_item_rec        -- Disc�i�ڏ��
       ,ov_errbuf        => lv_errbuf                -- �G���[�E���b�Z�[�W
       ,ov_retcode       => lv_retcode               -- ���^�[���E�R�[�h
       ,ov_errmsg        => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- �������ʃ`�F�b�N
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
    END LOOP disc_item_loop;
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
  END get_disc_item_data;
--
  /**********************************************************************************
   * Procedure Name   : validate_item
   * Description      : �i�ڃ}�X�^�ꊇ�A�b�v���[�h�f�[�^�Ó����`�F�b�N (D-4)
   ***********************************************************************************/
  PROCEDURE validate_item(
    i_wk_item_rec  IN  get_data_cur%ROWTYPE    -- �i�ڃ}�X�^�C���^�t�F�[�X���
   ,o_item_ctg_rec OUT g_item_ctg_rtype        -- �J�e�S�����
   ,ov_errbuf      OUT VARCHAR2                -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT VARCHAR2                -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_item';              -- �v���O������
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
    lv_tkn_value              VARCHAR2(100);           -- �g�[�N���l
    ln_cnt                    NUMBER;                  -- �J�E���g�p
    lv_val_check_flag         VARCHAR2(1);             -- �`�F�b�N�t���O
    l_validate_item_tab       g_check_data_ttype;      -- �`�F�b�N�p�ϐ�
    l_item_ctg_rec            g_item_ctg_rtype;        -- �J�e�S�����
    ln_dummy_cat_id           NUMBER;                  -- �_�~�[�J�e�S��ID
    ln_dummy_cat_set_id       NUMBER;                  -- �_�~�[�J�e�S���Z�b�gID
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �`�F�b�N�t���O�̏�����
    lv_val_check_flag  := cv_status_normal;
    --
    -- �J�e�S����񏉊���
    l_item_ctg_rec := NULL;
    --
    -- �Ɩ����t�̃t�H�[�}�b�g�ϊ�
    gd_apply_date  := TO_DATE(i_wk_item_rec.start_date_active, cv_date_fmt_std);
--
    --==============================================================
    -- D-4.1 �i�ڃR�[�h���݃`�F�b�N
    --==============================================================
    SELECT  COUNT(1)  AS cnt
    INTO    ln_cnt
    FROM    ic_item_mst_b iimb
    WHERE   iimb.item_no = i_wk_item_rec.item_no  -- �i�ڃR�[�h
    AND     ROWNUM       = 1
    ;
    -- �������ʃ`�F�b�N
    IF ( ln_cnt > 0 ) THEN
      -- �}�X�^���݃`�F�b�N�G���[
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn          -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmn_10617          -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_input_item_code      -- �g�[�N���R�[�h1
                    ,iv_token_value1 => i_wk_item_rec.item_no       -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_input_line_no        -- �g�[�N���R�[�h2
                    ,iv_token_value2 => i_wk_item_rec.line_no       -- �g�[�N���l2
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.2 �i�ڃR�[�h�d���`�F�b�N
    --==============================================================
    SELECT COUNT(1)  AS cnt
    INTO   ln_cnt
    FROM   xxcmn_wk_item_batch_regist xwibr
    WHERE  xwibr.item_no    = i_wk_item_rec.item_no  -- �i�ڃR�[�h
    AND    xwibr.request_id = gn_request_id
    ;
    -- �������ʃ`�F�b�N
    IF ( ln_cnt > 1 ) THEN
      -- �i�ڏd���G���[
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn             -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmn_10618             -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_input_line_no           -- �g�[�N���R�[�h1
                    ,iv_token_value1 => i_wk_item_rec.line_no          -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_input_item_code         -- �g�[�N���R�[�h2
                    ,iv_token_value2 => i_wk_item_rec.item_no          -- �g�[�N���l2
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.3 �i�ڃR�[�h7���`�F�b�N
    --==============================================================
    -- �i�ڃR�[�h7���`�F�b�N
-- Ver.1.1 S.Niki MOD START
--    IF ( LENGTHB( i_wk_item_rec.item_no ) <> 7 ) THEN
    IF ( LENGTHB( i_wk_item_rec.item_no ) <> cn_item_code_length ) THEN
-- Ver.1.1 S.Niki ADD END
      -- �i�ڃR�[�h7���K�{�G���[
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn             -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmn_10619             -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_input_line_no           -- �g�[�N���R�[�h1
                    ,iv_token_value1 => i_wk_item_rec.line_no          -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_input_item_code         -- �g�[�N���R�[�h2
                    ,iv_token_value2 => i_wk_item_rec.item_no          -- �g�[�N���l2
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
-- Ver.1.1 S.Niki MOD START
--    --==============================================================
--    -- D-4.4 �q�ɕi�ڃR�[�h7���`�F�b�N
--    --==============================================================
--    -- �q�ɕi�ڃR�[�h7���`�F�b�N
--    IF ( LENGTHB( i_wk_item_rec.warehouse_item ) <> 7 ) THEN
--
    --==============================================================
    -- D-4.4 �q�ɕi�ڃ`�F�b�N
    --==============================================================
    IF ( LENGTHB( i_wk_item_rec.warehouse_item ) <> cn_item_code_length ) THEN
-- Ver.1.1 S.Niki MOD END
      -- �q�ɕi��7���K�{�G���[
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn             -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmn_10620             -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_input_line_no           -- �g�[�N���R�[�h1
                    ,iv_token_value1 => i_wk_item_rec.line_no          -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_input_item_code         -- �g�[�N���R�[�h2
                    ,iv_token_value2 => i_wk_item_rec.warehouse_item   -- �g�[�N���l2
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
-- Ver.1.1 S.Niki ADD START
    -- �i�ڃR�[�h����ёq�ɕi�ڂƂ���7�����A�l���قȂ�ꍇ
    ELSIF ( ( LENGTHB( i_wk_item_rec.item_no )        = cn_item_code_length )
      AND   ( LENGTHB( i_wk_item_rec.warehouse_item ) = cn_item_code_length )
      AND   ( i_wk_item_rec.item_no <> i_wk_item_rec.warehouse_item ) ) THEN
        BEGIN
          -- �q�ɕi�ڑ��݃`�F�b�N
          SELECT  item_id            AS whse_item_id
          INTO    gt_whse_item_id
          FROM    ic_item_mst_b iimb
          WHERE   iimb.item_no = i_wk_item_rec.warehouse_item  -- �q�ɕi��
          ;
        EXCEPTION
          -- �擾�G���[��
          WHEN NO_DATA_FOUND THEN
            -- �q�ɕi�ڃR�[�h���݃`�F�b�N�G���[
            lv_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmn             -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_xxcmn_10641             -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_input_line_no           -- �g�[�N���R�[�h1
                          ,iv_token_value1 => i_wk_item_rec.line_no          -- �g�[�N���l1
                          ,iv_token_name2  => cv_tkn_input_item_code         -- �g�[�N���R�[�h2
                          ,iv_token_value2 => i_wk_item_rec.warehouse_item   -- �g�[�N���l2
                         );
            -- ���b�Z�[�W�o��
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
            FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
            lv_val_check_flag := cv_status_error;
        END;
-- Ver.1.1 S.Niki ADD END
    END IF;
    --==============================================================
    -- D-4.5 �P�ʁi�݌ɒP�ʁj�`�F�b�N
    --==============================================================
    SELECT COUNT(1)  AS cnt
    INTO   ln_cnt
    FROM   sy_uoms_mst sum
    WHERE  sum.delete_mark = cv_item_um_0
    AND    sum.um_code     > cv_item_um_space
    AND    sum.um_code     = i_wk_item_rec.item_um  -- �P�ʁi�݌ɒP�ʁj
    ;
    -- ��P�ʂ����݂��Ȃ��ꍇ
    IF ( ln_cnt = 0 ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn             -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmn_10621             -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_item_um                 -- �g�[�N���R�[�h1
                    ,iv_token_value1 => i_wk_item_rec.item_um          -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_input_line_no           -- �g�[�N���R�[�h2
                    ,iv_token_value2 => i_wk_item_rec.line_no          -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_input_item_code         -- �g�[�N���R�[�h3
                    ,iv_token_value3 => i_wk_item_rec.item_no          -- �g�[�N���l3
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.6 ���Q�R�[�h�`�F�b�N
    --==============================================================
    IF ( i_wk_item_rec.old_crowd IS NOT NULL ) THEN
      -- �J�e�S�����݃`�F�b�N
      chk_exists_category(
        iv_category_set_name => gt_ctg_gun_code
       ,iv_category_val      => i_wk_item_rec.old_crowd  -- ���Q�R�[�h
       ,iv_item_code         => i_wk_item_rec.item_no
       ,on_catregory_id      => ln_dummy_cat_id
       ,on_catregory_set_id  => ln_dummy_cat_set_id
       ,ov_errbuf            => lv_errbuf
       ,ov_retcode           => lv_retcode
       ,ov_errmsg            => lv_errmsg
      ) ;
      -- �������ʃ`�F�b�N
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
        lv_val_check_flag := cv_status_error;
      END IF;
    END IF;
    --
    --==============================================================
    -- D-4.7 �V�Q�R�[�h�`�F�b�N
    --==============================================================
    -- �J�e�S�����݃`�F�b�N
    chk_exists_category(
      iv_category_set_name => gt_ctg_gun_code
     ,iv_category_val      => i_wk_item_rec.new_crowd  -- �V�Q�R�[�h
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => ln_dummy_cat_id
     ,on_catregory_set_id  => ln_dummy_cat_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.8 �d�ʗe�ϋ敪�`�F�b�N
    --==============================================================
    -- LOOKUP�\���݃`�F�b�N
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_we_ca_class
     ,iv_lookup_code => i_wk_item_rec.weight_volume_class  -- �d�ʗe�ϋ敪
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.9 �d���敪�`�F�b�N
    --==============================================================
    -- LOOKUP�\���݃`�F�b�N
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_destination_diy
     ,iv_lookup_code => i_wk_item_rec.destination_class  -- �d���敪
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.10 �����Ǘ��敪�`�F�b�N
    --==============================================================
    -- LOOKUP�\���݃`�F�b�N
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_cost_management
     ,iv_lookup_code => i_wk_item_rec.cost_management_class -- �����Ǘ��敪
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.11 �d���P�����o���^�C�v�`�F�b�N
    --==============================================================
    -- LOOKUP�\���݃`�F�b�N
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_vendor_deriday_ty
     ,iv_lookup_code => i_wk_item_rec.vendor_price_deriday_ty  -- �d���P�����o��
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.12 ���o�Ɋ��Z�P�ʃ`�F�b�N
    --==============================================================
    -- ���o�Ɋ��Z�P�ʃ`�F�b�N
    IF ( i_wk_item_rec.mtl_units_of_measure_tl IS NOT NULL )
      AND ( i_wk_item_rec.mtl_units_of_measure_tl <> cv_mtl_units_of_measure ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn             -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmn_10629             -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_input_line_no           -- �g�[�N���R�[�h1
                    ,iv_token_value1 => i_wk_item_rec.line_no          -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_input_item_code         -- �g�[�N���R�[�h2
                    ,iv_token_value2 => i_wk_item_rec.item_no          -- �g�[�N���l2
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.13 �����L���敪�`�F�b�N
    --==============================================================
    -- LOOKUP�\���݃`�F�b�N
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_need_test
     ,iv_lookup_code => i_wk_item_rec.need_test_class -- �����L���敪
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.14 ����L/T�`�F�b�N
    --==============================================================
    -- �����L���敪���u1�F�L�v�̏ꍇ�͕K�{
    IF ( i_wk_item_rec.need_test_class = cv_exam_class_1 )
      AND ( i_wk_item_rec.inspection_lt IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn           -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmn_10623           -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_col_name              -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_inspection_lt             -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_input_line_no         -- �g�[�N���R�[�h2
                    ,iv_token_value2 => i_wk_item_rec.line_no        -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_input_item_code       -- �g�[�N���R�[�h3
                    ,iv_token_value3 => i_wk_item_rec.item_no        -- �g�[�N���l3
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.15 ����񐔃`�F�b�N
    --==============================================================
    -- �����L���敪���u1�F�L�v�̏ꍇ�͕K�{
    IF ( i_wk_item_rec.need_test_class = cv_exam_class_1 )
      AND ( i_wk_item_rec.judgment_times_num IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn           -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmn_10623           -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_col_name              -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_judge_times_num           -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_input_line_no         -- �g�[�N���R�[�h2
                    ,iv_token_value2 => i_wk_item_rec.line_no        -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_input_item_code       -- �g�[�N���R�[�h3
                    ,iv_token_value3 => i_wk_item_rec.item_no        -- �g�[�N���l3
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.16 �����\����񐔃`�F�b�N
    --==============================================================
    -- �����L���敪���u1�F�L�v�̏ꍇ�͕K�{
    IF ( i_wk_item_rec.need_test_class = cv_exam_class_1 )
      AND ( i_wk_item_rec.order_judge_times_num IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn                    -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmn_10623                    -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_col_name                       -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_order_judge_times_num              -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h2
                    ,iv_token_value2 => i_wk_item_rec.line_no                 -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_input_item_code                -- �g�[�N���R�[�h3
                    ,iv_token_value3 => i_wk_item_rec.item_no                 -- �g�[�N���l3
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.17 �Q�R�[�h�`�F�b�N
    --==============================================================
    -- �J�e�S�����݃`�F�b�N
    chk_exists_category(
      iv_category_set_name => gt_ctg_gun_code
     ,iv_category_val      => i_wk_item_rec.crowd_code  -- �Q�R�[�h
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.pg_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.pg_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.18 ����Q�R�[�h�`�F�b�N
    --==============================================================
    -- �J�e�S�����݃`�F�b�N
    chk_exists_category(
      iv_category_set_name => gt_ctg_seisakugun
     ,iv_category_val      => i_wk_item_rec.policy_group_code  -- ����Q�R�[�h
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.sg_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.sg_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.19 �}�[�P�p�Q�R�[�h�`�F�b�N
    --==============================================================
    -- �J�e�S�����݃`�F�b�N
    chk_exists_category(
      iv_category_set_name => gt_ctg_mark_pg
     ,iv_category_val      => i_wk_item_rec.mark_crowd_code  -- �}�[�P�p�Q�R�[�h
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.mgc_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.mgc_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.20 �o�����p�Q�R�[�h�`�F�b�N
    --==============================================================
    -- �J�e�S�����݃`�F�b�N
    chk_exists_category(
      iv_category_set_name => gt_ctg_acnt_pg
     ,iv_category_val      => i_wk_item_rec.acnt_crowd_code  -- �o�����p�Q�R�[�h
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.apg_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.apg_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.21 ���i���i�敪�`�F�b�N
    --==============================================================
    -- �J�e�S�����݃`�F�b�N
    chk_exists_category(
      iv_category_set_name => gt_ctg_item_prod
     ,iv_category_val      => i_wk_item_rec.item_product_class  -- ���i���i�敪
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.ssk_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.ssk_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.22 �{�Џ��i�敪�`�F�b�N
    --==============================================================
    -- �J�e�S�����݃`�F�b�N
    chk_exists_category(
      iv_category_set_name => gt_ctg_hon_prod
     ,iv_category_val      => i_wk_item_rec.hon_product_class  -- �{�Џ��i�敪
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.hsk_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.hsk_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.23 ���i�敪�`�F�b�N
    --==============================================================
    -- �J�e�S�����݃`�F�b�N
    chk_exists_category(
      iv_category_set_name => gt_ctg_product_div
     ,iv_category_val      => i_wk_item_rec.product_div  -- ���i�敪
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.pd_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.pd_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.24 �i�ڋ敪�`�F�b�N
    --==============================================================
    -- �J�e�S�����݃`�F�b�N
    chk_exists_category(
      iv_category_set_name => gt_ctg_item_class
     ,iv_category_val      => i_wk_item_rec.item_class  -- �i�ڋ敪
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.itd_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.itd_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.25 ���O�敪�`�F�b�N
    --==============================================================
    -- �J�e�S�����݃`�F�b�N
    chk_exists_category(
      iv_category_set_name => gt_ctg_inout_class
     ,iv_category_val      => i_wk_item_rec.inout_class  -- ���O�敪
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.ind_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.ind_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.26 �o�����敪�`�F�b�N
    --==============================================================
    -- �J�e�S�����݃`�F�b�N
    chk_exists_category(
      iv_category_set_name => gt_ctg_baracha_class
     ,iv_category_val      => i_wk_item_rec.baracha_class  -- �o�����敪
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.bd_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.bd_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.27 �i���敪�`�F�b�N
    --==============================================================
    -- �J�e�S�����݃`�F�b�N
    chk_exists_category(
      iv_category_set_name => gt_ctg_quality_class
     ,iv_category_val      => i_wk_item_rec.quality_class  -- �i���敪
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.qd_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.qd_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.28 �H��Q�R�[�h�`�F�b�N
    --==============================================================
    -- �J�e�S�����݃`�F�b�N
    chk_exists_category(
      iv_category_set_name => gt_ctg_fact_pg
     ,iv_category_val      => i_wk_item_rec.fact_crowd_code  -- �H��Q�R�[�h
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.fpg_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.fpg_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.29 �ܖ����ԋ敪�`�F�b�N
    --==============================================================
    -- LOOKUP�\���݃`�F�b�N
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_shelf_life_class
     ,iv_lookup_code => i_wk_item_rec.expiration_day_class  -- �ܖ����ԋ敪
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.30 �^��ʃ`�F�b�N
    --==============================================================
    -- LOOKUP�\���݃`�F�b�N
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_type
     ,iv_lookup_code => i_wk_item_rec.model_type  -- �^���
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.31 ���i���ރ`�F�b�N
    --==============================================================
    -- LOOKUP�\���݃`�F�b�N
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_product_class
     ,iv_lookup_code => i_wk_item_rec.product_class  -- ���i����
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.32 ���i��ʃ`�F�b�N
    --==============================================================
    -- LOOKUP�\���݃`�F�b�N
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_product_type
     ,iv_lookup_code => i_wk_item_rec.product_type  -- ���i���
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.33 �e��敪�`�F�b�N
    --==============================================================
    -- LOOKUP�\���݃`�F�b�N
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_bottle_class
     ,iv_lookup_code => i_wk_item_rec.bottle_class  -- �e��敪
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.34 �P�ʋ敪�`�F�b�N
    --==============================================================
    -- LOOKUP�\���݃`�F�b�N
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_uom_class
     ,iv_lookup_code => i_wk_item_rec.uom_class  -- �P�ʋ敪
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.35 �I���敪�`�F�b�N
    --==============================================================
    -- LOOKUP�\���݃`�F�b�N
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_inventory_chk_class
     ,iv_lookup_code => i_wk_item_rec.inventory_chk_class  -- �I���敪
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.36 �g���[�X�敪�`�F�b�N
    --==============================================================
    -- LOOKUP�\���݃`�F�b�N
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_trace_class
     ,iv_lookup_code => i_wk_item_rec.trace_class  -- �g���[�X�敪
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.37 ���敪�`�F�b�N
    --==============================================================
    -- LOOKUP�\���݃`�F�b�N
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_rate
     ,iv_lookup_code => i_wk_item_rec.rate_class  -- ���敪
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.38 �o�׊��Z�P�ʃ`�F�b�N
    --==============================================================
    -- �o�׊��Z�P�ʂ��ݒ肳��Ă���ꍇ�A�P�[�X������1�ȏ�
    IF ( i_wk_item_rec.mtl_units_of_measure_tl IS NOT NULL )
      AND ( NVL( i_wk_item_rec.case_num ,0 ) <= 0 ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn          -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmn_10624          -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_input_line_no        -- �g�[�N���R�[�h1
                    ,iv_token_value1 => i_wk_item_rec.line_no       -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_input_item_code      -- �g�[�N���R�[�h2
                    ,iv_token_value2 => i_wk_item_rec.item_no       -- �g�[�N���l2
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.39 �����\����񐔓��͐����`�F�b�N
    --==============================================================
    -- �����L���敪���u1�F�L�v�̏ꍇ�́u1�v�u2�v�u3�v�̂����ꂩ�ݒ�
    IF ( i_wk_item_rec.need_test_class = cv_exam_class_1 )
      AND ( i_wk_item_rec.order_judge_times_num NOT IN ( cn_judge_times_num_1
                                                       , cn_judge_times_num_2
                                                       , cn_judge_times_num_3 )
         ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn          -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmn_10625          -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_input_line_no        -- �g�[�N���R�[�h1
                    ,iv_token_value1 => i_wk_item_rec.line_no       -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_input_item_code      -- �g�[�N���R�[�h2
                    ,iv_token_value2 => i_wk_item_rec.item_no       -- �g�[�N���l2
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    -- �J�e�S������߂��܂�
    o_item_ctg_rec := l_item_ctg_rec;
    -- �`�F�b�N�t���O�̒l��ԋp
    ov_retcode := lv_val_check_flag;
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
  END validate_item;
--
  /**********************************************************************************
   * Procedure Name   : loop_main
   * Description      : �i�ڃ}�X�^�ꊇ�A�b�v���[�h���[�N�f�[�^�擾 (D-3)
   *                    �i�ڃ}�X�^�ꊇ�A�b�v���[�h���[�N�f�[�^�Ó����`�F�b�N(D-4)
   *                    �f�[�^�o�^(D-5)
   ***********************************************************************************/
  PROCEDURE loop_main(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'loop_main'; -- �v���O������
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
    ln_line_cnt               NUMBER;                  -- �s�J�E���^
    lv_check_flag             VARCHAR2(1);             -- �`�F�b�N�t���O
    lv_val_check_flag         VARCHAR2(1);             -- D-4�Ó����`�F�b�N�t���O
    lv_ins_check_flag         VARCHAR2(1);             -- D-5.16�܂ł̓o�^�`�F�b�N�t���O
    lv_conc_check_flag        VARCHAR2(1);             -- D-5.17�o�^�`�F�b�N�t���O
    l_item_code_tab           g_check_data_ttype;      -- �e�[�u���^�ϐ���錾(�i�ڃR�[�h�ێ�)
    ln_request_id             NUMBER;                  -- �v��ID
    l_conc_argument_tab       xxcmm_004common_pkg.conc_argument_ttype;
                                                       -- �R���J�����g(argument)
    l_item_ctg_rec            g_item_ctg_rtype;        -- �J�e�S�����
    lv_status_val             VARCHAR2(5000);          -- �X�e�[�^�X�l
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
    --
--##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  �Œ蕔 END   ############################
    --
    -- �`�F�b�N�t���O������
    lv_check_flag      := cv_status_normal;
    lv_val_check_flag  := cv_status_normal;
    lv_ins_check_flag  := cv_status_normal;
    lv_conc_check_flag := cv_status_normal;
    --
    --==============================================================
    -- D-3  �i�ڃ}�X�^�ꊇ�A�b�v���[�h���[�N�f�[�^�擾
    --==============================================================
    -- �s�J�E���^�A�b�v
    ln_line_cnt   := 0;
    --
    <<main_loop>>
    FOR get_data_rec IN get_data_cur LOOP
      -- �s�J�E���^�A�b�v
      ln_line_cnt  := ln_line_cnt + 1;
      --
      --==============================================================
      -- D-4  �i�ڃ}�X�^�ꊇ�A�b�v���[�h���[�N�f�[�^�Ó����`�F�b�N
      --==============================================================
      validate_item(
        i_wk_item_rec  => get_data_rec             -- �i�ڃ}�X�^�ꊇ�A�b�v���[�h���
       ,o_item_ctg_rec => l_item_ctg_rec           -- �J�e�S�����
       ,ov_errbuf      => lv_errbuf                -- �G���[�E���b�Z�[�W
       ,ov_retcode     => lv_retcode               -- ���^�[���E�R�[�h
       ,ov_errmsg      => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- �������ʃ`�F�b�N
      IF ( lv_retcode = cv_status_normal ) THEN
        -- ���팏�����Z
        gn_val_normal_cnt := gn_val_normal_cnt + 1;
      ELSE
        -- �G���[�������Z
        gn_val_error_cnt  := gn_val_error_cnt + 1;
        lv_val_check_flag := cv_status_error;
        lv_check_flag     := cv_status_error;
      END IF;
      --
      -- D-4�������ʃ`�F�b�N
      IF ( lv_retcode = cv_status_normal ) THEN
        --==============================================================
        -- D-5  �f�[�^�o�^
        --==============================================================
        ins_data(
          i_wk_item_rec  => get_data_rec           -- �i�ڃ}�X�^�ꊇ�A�b�v���[�h���
         ,i_item_ctg_rec => l_item_ctg_rec         -- �J�e�S�����
         ,ov_errbuf      => lv_errbuf              -- �G���[�E���b�Z�[�W
         ,ov_retcode     => lv_retcode             -- ���^�[���E�R�[�h
         ,ov_errmsg      => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        -- �������ʃ`�F�b�N
        IF ( lv_retcode = cv_status_normal ) THEN
          gn_ins_normal_cnt := gn_ins_normal_cnt + 1;
          -- D-5.17�ɂĎg�p����i�ڃR�[�h���i�[
          l_item_code_tab(ln_line_cnt) := get_data_rec.item_no;
        ELSE
          gn_ins_error_cnt  := gn_ins_error_cnt + 1;
          lv_ins_check_flag := cv_status_error;
          lv_check_flag     := cv_status_error;
        END IF;
      END IF;
    --
    END LOOP main_loop;
    --
    -- �������ʃ`�F�b�N
    IF ( lv_val_check_flag = cv_status_error ) THEN
      -- D-4�̏������ʂ��Z�b�g
      gn_normal_cnt := gn_val_normal_cnt;
      gn_error_cnt  := gn_val_error_cnt;
    ELSE
      -- D-5�̏������ʂ��Z�b�g
      gn_normal_cnt := gn_ins_normal_cnt;
      gn_error_cnt  := gn_ins_error_cnt;
    END IF;
    --
    -- D-5.16�܂ł̏������ʃ`�F�b�N
    IF ( lv_check_flag = cv_status_normal ) THEN
      --==============================================================
      -- D-5.17 Disc�i�ڃ}�X�^�o�^
      -- �S�Ă̓o�^����������������i�ڃ}�X�^�ꊇ�A�b�v���[�h���[�N�̃��R�[�h���A
      -- �R���J�����g���N�����܂��B
      --==============================================================
      COMMIT;
      --
      -- Disc�i�ړo�^LOOP
      <<loop_conc>>
      FOR ln_conc_cnt IN 1..l_item_code_tab.COUNT LOOP
        -- ������
        lv_status_val := cv_status_val_normal;
        -- argument�ݒ�
        l_conc_argument_tab(1).argument := l_item_code_tab(ln_conc_cnt);
        <<loop_arg>>
        FOR ln_cnt IN 2..100 LOOP
          l_conc_argument_tab(ln_cnt).argument := CHR(0);
        END LOOP loop_arg;
        --
        -- OPM�i�ڃg���K�[�N���R���J�����g���s
        xxcmm_004common_pkg.proc_conc_request(
          iv_appl_short_name => cv_appl_name_xxcmn
         ,iv_program         => cv_prog_opmitem_trigger  -- OPM�i�ڃg���K�[�N���R���J�����g
         ,iv_description     => NULL
         ,iv_start_time      => NULL
         ,ib_sub_request     => FALSE
         ,i_argument_tab     => l_conc_argument_tab
         ,iv_wait_flag       => cv_yes
         ,on_request_id      => ln_request_id
         ,ov_errbuf          => lv_errbuf
         ,ov_retcode         => lv_retcode
         ,ov_errmsg          => lv_errmsg
        );
        --==============================================================
        -- XXCMM_004_�i�ڋ��ʊ֐�����̕ԋp�l(lv_errmsg)
        --==============================================================
        -- �R���J�����g�N���G���[�� �� "�R���J�����g�̋N���Ɏ��s���܂����B"
        -- �R���J�����g�ҋ@�G���[�� �� "�R���J�����g�̑ҋ@�����Ɏ��s���܂����B"
        -- �R���J�����g�����G���[�� �� "�R���J�����g�����̓G���[�I�����܂����B[�t�F�[�Y�A�X�e�[�^�X]"
        --
        -- �������ʃ`�F�b�N
        IF ( lv_retcode = cv_status_normal ) THEN
          -- OPM�i�ڃg���K�[�N���R���J�����g���u����v�ŕԋp
          lv_status_val      := cv_status_val_normal;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          -- OPM�i�ڃg���K�[�N���R���J�����g���u�x���v�ŕԋp
          lv_status_val      := SUBSTRB(cv_status_val_warn  || cv_msg_part || lv_errmsg, 1, 5000);
          lv_conc_check_flag := cv_status_error;
          lv_check_flag      := cv_status_error;
        ELSE
          -- OPM�i�ڃg���K�[�N���R���J�����g���u�G���[�v�ŕԋp
          lv_status_val      := SUBSTRB(cv_status_val_error || cv_msg_part || lv_errmsg, 1, 5000);
          lv_conc_check_flag := cv_status_error;
          lv_check_flag      := cv_status_error;
        END IF;
        --
        lv_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmn             -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmn_10627             -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_req_id                  -- �g�[�N���R�[�h1
                      ,iv_token_value1 => ln_request_id                  -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_input_item_code         -- �g�[�N���R�[�h2
                      ,iv_token_value2 => l_item_code_tab(ln_conc_cnt)   -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_msg                     -- �g�[�N���R�[�h3
                      ,iv_token_value3 => lv_status_val                  -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      END LOOP loop_conc;
    END IF;
    --
    -- D-5.17�������ʃ`�F�b�N
    IF ( lv_check_flag = cv_status_normal ) THEN
      --==============================================================
      -- D-6  Disc�i�ڏ��擾
      -- D-7  Disc�i�ڃJ�e�S������
      -- Disc�i�ړo�^����������������ADisc�i�ڃJ�e�S���������s�Ȃ��܂��B
      --==============================================================
      get_disc_item_data(
        ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
       ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
       ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF ( lv_retcode = cv_status_error ) THEN
        lv_check_flag := cv_status_error;
      END IF;
    END IF;
    -- �`�F�b�N�t���O�̒l��ԋp
    ov_retcode := lv_check_flag;
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
  END loop_main;
--
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^�擾(D-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_if_data';     -- �v���O������
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
    lv_step                   VARCHAR2(10);                       -- �X�e�b�v
    lv_check_flag             VARCHAR2(1);                        -- �`�F�b�N�t���O
    lv_get_check_flag         VARCHAR2(1);                        -- STEP�`�F�b�N�t���O
    --
    ln_line_cnt               NUMBER;                             -- �s�J�E���^
    ln_item_num               NUMBER;                             -- ���ڐ�
    ln_item_cnt               NUMBER;                             -- ���ڐ��J�E���^
    lv_file_name              VARCHAR2(100);                      -- �t�@�C�����i�[�p
    ln_ins_item_cnt           NUMBER;                             -- �o�^�����J�E���^
--
    lt_wk_item_tab            g_check_data_ttype;                 --  �e�[�u���^�ϐ���錾(���ڕ���)
    lt_if_data_tab            xxcmn_common3_pkg.g_file_data_tbl;  --  �e�[�u���^�ϐ���錾
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
    blob_expt                 EXCEPTION;                          -- BLOB�f�[�^�ϊ��G���[
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ������
    ln_ins_item_cnt := 0;
    --
    --==============================================================
    -- D-2.1 �t�@�C���A�b�v���[�hIF�f�[�^�擾
    --==============================================================
    xxcmn_common3_pkg.blob_to_varchar2(    -- BLOB�f�[�^�ϊ����ʊ֐�
      in_file_id   => gn_file_id           -- �t�@�C���h�c
     ,ov_file_data => lt_if_data_tab       -- �ϊ���VARCHAR2�f�[�^
     ,ov_errbuf    => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- �G���[�������J�E���g
      gn_error_cnt := 1;
      RAISE blob_expt;
    END IF;
    --
    -- �`�F�b�N�t���O�̏�����
    lv_check_flag     := cv_status_normal;
    --
    -- ���[�N�e�[�u���o�^LOOP
    <<ins_wk_loop>>
    FOR ln_line_cnt IN 1..lt_if_data_tab.COUNT LOOP
      -- STEP�`�F�b�N�t���O�̏�����
      lv_get_check_flag := cv_status_normal;
      --
      --==============================================================
      -- D-2.2 ���ڐ��̃`�F�b�N
      --==============================================================
      -- �Ώی����擾
      gn_target_cnt := gn_target_cnt + 1;
      -- �f�[�^���ڐ����i�[
      ln_item_num := ( LENGTHB(lt_if_data_tab(ln_line_cnt))
                   - ( LENGTHB(REPLACE(lt_if_data_tab(ln_line_cnt), cv_msg_comma, '') ) )
                   + 1 );
      -- ���ڐ�����v���Ȃ��ꍇ
      IF ( gn_item_num <> ln_item_num ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmn            -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmn_10638            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_item_batch_regist          -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_count                  -- �g�[�N���R�[�h2
                      ,iv_token_value2 => ln_item_num                   -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no          -- �g�[�N���R�[�h2
                      ,iv_token_value3 => ln_line_cnt                   -- �g�[�N���l2
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
        --
        lv_get_check_flag := cv_status_error;
        lv_check_flag     := cv_status_error;
        --
      ELSE
        --
        --==============================================================
        -- D-2.3 �Ώۃf�[�^�̕���
        --==============================================================
        <<get_column_loop>>
        FOR ln_item_cnt IN 1..gn_item_num LOOP
          -- �ϐ��ɍ��ڂ̒l���i�[
          lt_wk_item_tab(ln_item_cnt) := xxccp_common_pkg.char_delim_partition(
                                          iv_char     => lt_if_data_tab(ln_line_cnt)  -- ������������
                                         ,iv_delim    => cv_msg_comma                 -- �f���~�^����
                                         ,in_part_num => ln_item_cnt                  -- �ԋp�Ώ�INDEX
                                        );
          --==============================================================
          -- D-2.4 �K�{/�^/�T�C�Y�`�F�b�N
          --==============================================================
          xxccp_common_pkg2.upload_item_check(
            iv_item_name    => g_item_def_tab(ln_item_cnt).item_name          -- ���ږ���
           ,iv_item_value   => lt_wk_item_tab(ln_item_cnt)                    -- ���ڂ̒l
           ,in_item_len     => g_item_def_tab(ln_item_cnt).item_length        -- ���ڂ̒���(��������)
           ,in_item_decimal => g_item_def_tab(ln_item_cnt).decim              -- ���ڂ̒����i�����_�ȉ��j
           ,iv_item_nullflg => g_item_def_tab(ln_item_cnt).item_essential     -- �K�{�t���O
           ,iv_item_attr    => g_item_def_tab(ln_item_cnt).item_attribute     -- ���ڂ̑���
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          -- �������ʃ`�F�b�N
          IF ( lv_retcode <> cv_status_normal ) THEN                          -- �߂�l������ȊO�̏ꍇ
            lv_errmsg  := xxcmn_common_pkg.get_msg(
                            iv_application   =>  cv_appl_name_xxcmn          -- �A�v���P�[�V�����Z�k��
                           ,iv_name          =>  cv_msg_xxcmn_10639          -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1   =>  cv_tkn_input_line_no        -- �g�[�N���R�[�h1
                           ,iv_token_value1  =>  ln_line_cnt                 -- �g�[�N���l1
                           ,iv_token_name2   =>  cv_tkn_errmsg               -- �g�[�N���R�[�h2
                           ,iv_token_value2  =>  LTRIM(lv_errmsg)            -- �g�[�N���l2
                          );
            -- ���b�Z�[�W�o��
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
            FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
            --
            lv_get_check_flag := cv_status_error;
            lv_check_flag     := cv_status_error;
            --
          END IF;
        END LOOP get_column_loop;
        --==============================================================
        -- D-2.5 �i�ڃ}�X�^�ꊇ�A�b�v���[�h���[�N�o�^
        --==============================================================
        -- ��L�܂ł�STEP�`�F�b�N������̏ꍇ
        IF ( lv_get_check_flag = cv_status_normal ) THEN 
          BEGIN
            ln_ins_item_cnt := ln_ins_item_cnt + 1;
            --
            INSERT INTO xxcmn_wk_item_batch_regist(
                file_id                     -- �t�@�C��ID
              , file_seq                    -- �t�@�C���V�[�P���X
              , line_no                     -- �s�ԍ�
              , item_no                     -- �i��
              , item_desc                   -- �E�v
              , item_short_name             -- ����
              , item_name_alt               -- �J�i��
              , warehouse_item              -- �q�ɕi��
              , item_um                     -- �P�ʁi�݌ɒP�ʁj
              , old_crowd                   -- ���Q�R�[�h
              , new_crowd                   -- �V�Q�R�[�h
              , crowd_start_date            -- �Q�R�[�h�K�p�J�n��
              , old_price                   -- ���E�艿
              , new_price                   -- �V�E�艿
              , price_start_date            -- �艿�K�p�J�n��
              , old_business_cost           -- ���E�c�ƌ��� 
              , new_business_cost           -- �V�E�c�ƌ��� 
              , business_start_date         -- �c�ƌ����K�p�J�n�� 
              , sale_start_date             -- �����J�n���i�����J�n���j
              , jan_code                    -- JAN�R�[�h
              , itf_code                    -- ITF�R�[�h
              , case_num                    -- �P�[�X����
              , net                         -- NET
              , weight_volume_class         -- �d�ʗe�ϋ敪
              , weight                      -- �d��
              , volume                      -- �e��
              , destination_class           -- �d���敪
              , cost_management_class       -- �����Ǘ��敪
              , vendor_price_deriday_ty     -- �d���P�����o���^�C�v
              , represent_num               -- ��\����
              , mtl_units_of_measure_tl     -- ���o�Ɋ��Z�P��
              , need_test_class             -- �����L���敪
              , inspection_lt               -- ����L/T
              , judgment_times_num          -- �����
              , order_judge_times_num       -- �����\�����
              , crowd_code                  -- �Q�R�[�h
              , policy_group_code           -- ����Q�R�[�h
              , mark_crowd_code             -- �}�[�P�p�Q�R�[�h
              , acnt_crowd_code             -- �o�����p�Q�R�[�h
              , item_product_class          -- ���i���i�敪
              , hon_product_class           -- �{�Џ��i�敪
              , product_div                 -- ���i�敪
              , item_class                  -- �i�ڋ敪
              , inout_class                 -- ���O�敪
              , baracha_class               -- �o�����敪
              , quality_class               -- �i���敪
              , fact_crowd_code             -- �H��Q�R�[�h
              , start_date_active           -- �K�p�J�n��
              , expiration_day_class        -- �ܖ����ԋ敪
              , expiration_day              -- �ܖ�����
              , shelf_life                  -- �������
              , delivery_lead_time          -- �[������
              , case_weight_volume          -- �P�[�X�d�ʗe��
              , raw_material_consumpe       -- �����g�p��
              , standard_yield              -- �W������
              , model_type                  -- �^���
              , product_class               -- ���i����
              , product_type                -- ���i���
              , shipping_cs_unit_qty        -- �o�ד���
              , palette_max_cs_qty          -- �p���z��
              , palette_max_step_qty        -- �p���i��
              , palette_step_qty            -- �p���b�g�i
              , bottle_class                -- �e��敪
              , uom_class                   -- �P�ʋ敪
              , inventory_chk_class         -- �I���敪
              , trace_class                 -- �g���[�X�敪
              , rate_class                  -- ���敪
              , shipping_end_date           -- �o�ג�~��
              , created_by                  -- �쐬��
              , creation_date               -- �쐬��
              , last_updated_by             -- �ŏI�X�V��
              , last_update_date            -- �ŏI�X�V��
              , last_update_login           -- �ŏI�X�V���O�C��
              , request_id                  -- �v��ID
              , program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              , program_id                  -- �R���J�����g�E�v���O����ID
              , program_update_date         -- �v���O�����X�V��
             ) VALUES (
               gn_file_id                   -- �t�@�C��ID
             , ln_ins_item_cnt              -- �t�@�C���V�[�P���X
             , lt_wk_item_tab(1)            -- �s�ԍ�
             , lt_wk_item_tab(2)            -- �i��
             , lt_wk_item_tab(3)            -- �E�v
             , lt_wk_item_tab(4)            -- ����
             , lt_wk_item_tab(5)            -- �J�i��
             , lt_wk_item_tab(6)            -- �q�ɕi��
             , lt_wk_item_tab(7)            -- �P�ʁi�݌ɒP�ʁj
             , lt_wk_item_tab(8)            -- ���Q�R�[�h
             , lt_wk_item_tab(9)            -- �V�Q�R�[�h
             , lt_wk_item_tab(10)           -- �Q�R�[�h�K�p�J�n��
             , lt_wk_item_tab(11)           -- ���E�艿
             , lt_wk_item_tab(12)           -- �V�E�艿
             , lt_wk_item_tab(13)           -- �艿�K�p�J�n��
             , lt_wk_item_tab(14)           -- ���E�c�ƌ��� 
             , lt_wk_item_tab(15)           -- �V�E�c�ƌ��� 
             , lt_wk_item_tab(16)           -- �c�ƌ����K�p�J�n�� 
             , lt_wk_item_tab(17)           -- �����J�n���i�����J�n���j
             , lt_wk_item_tab(18)           -- JAN�R�[�h
             , lt_wk_item_tab(19)           -- ITF�R�[�h
             , lt_wk_item_tab(20)           -- �P�[�X����
             , lt_wk_item_tab(21)           -- NET
             , lt_wk_item_tab(22)           -- �d�ʗe�ϋ敪
             , lt_wk_item_tab(23)           -- �d��
             , lt_wk_item_tab(24)           -- �e��
             , lt_wk_item_tab(25)           -- �d���敪
             , lt_wk_item_tab(26)           -- �����Ǘ��敪
             , lt_wk_item_tab(27)           -- �d���P�����o���^�C�v
             , lt_wk_item_tab(28)           -- ��\����
             , lt_wk_item_tab(29)           -- ���o�Ɋ��Z�P��
             , lt_wk_item_tab(30)           -- �����L���敪
             , lt_wk_item_tab(31)           -- ����L/T
             , lt_wk_item_tab(32)           -- �����
             , lt_wk_item_tab(33)           -- �����\�����
             , lt_wk_item_tab(34)           -- �Q�R�[�h
             , lt_wk_item_tab(35)           -- ����Q�R�[�h
             , lt_wk_item_tab(36)           -- �}�[�P�p�Q�R�[�h
             , lt_wk_item_tab(37)           -- �o�����p�Q�R�[�h
             , lt_wk_item_tab(38)           -- ���i���i�敪
             , lt_wk_item_tab(39)           -- �{�Џ��i�敪
             , lt_wk_item_tab(40)           -- ���i�敪
             , lt_wk_item_tab(41)           -- �i�ڋ敪
             , lt_wk_item_tab(42)           -- ���O�敪
             , lt_wk_item_tab(43)           -- �o�����敪
             , lt_wk_item_tab(44)           -- �i���敪
             , lt_wk_item_tab(45)           -- �H��Q�R�[�h
             , lt_wk_item_tab(46)           -- �K�p�J�n��
             , lt_wk_item_tab(47)           -- �ܖ����ԋ敪
             , lt_wk_item_tab(48)           -- �ܖ�����
             , lt_wk_item_tab(49)           -- �������
             , lt_wk_item_tab(50)           -- �[������
             , lt_wk_item_tab(51)           -- �P�[�X�d�ʗe��
             , lt_wk_item_tab(52)           -- �����g�p��
             , lt_wk_item_tab(53)           -- �W������
             , lt_wk_item_tab(54)           -- �^���
             , lt_wk_item_tab(55)           -- ���i����
             , lt_wk_item_tab(56)           -- ���i���
             , lt_wk_item_tab(57)           -- �o�ד���
             , lt_wk_item_tab(58)           -- �p���z��
             , lt_wk_item_tab(59)           -- �p���i��
             , lt_wk_item_tab(60)           -- �p���b�g�i
             , lt_wk_item_tab(61)           -- �e��敪
             , lt_wk_item_tab(62)           -- �P�ʋ敪
             , lt_wk_item_tab(63)           -- �I���敪
             , lt_wk_item_tab(64)           -- �g���[�X�敪
             , lt_wk_item_tab(65)           -- ���敪
             , lt_wk_item_tab(66)           -- �o�ג�~��
             , gn_created_by                -- �쐬��
             , gd_creation_date             -- �쐬��
             , gn_last_updated_by           -- �ŏI�X�V��
             , gd_last_update_date          -- �ŏI�X�V��
             , gn_last_update_login         -- �ŏI�X�V���O�C��ID
             , gn_request_id                -- �v��ID
             , gn_program_application_id    -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
             , gn_program_id                -- �R���J�����g�E�v���O����ID
             , gd_program_update_date       -- �v���O�����ɂ��X�V��
            );
          --
          EXCEPTION
            -- *** �f�[�^�o�^��O�n���h�� ***
            WHEN OTHERS THEN
              lv_errmsg  := xxcmn_common_pkg.get_msg(
                              iv_application  => cv_appl_name_xxcmn       -- �A�v���P�[�V�����Z�k��
                             ,iv_name         => cv_msg_xxcmn_10626       -- ���b�Z�[�W�R�[�h
                             ,iv_token_name1  => cv_tkn_table             -- �g�[�N���R�[�h1
                             ,iv_token_value1 => cv_table_xwibr           -- �g�[�N���l1
                             ,iv_token_name2  => cv_tkn_input_line_no     -- �g�[�N���R�[�h2
                             ,iv_token_value2 => lt_wk_item_tab(1)        -- �g�[�N���l2
                             ,iv_token_name3  => cv_tkn_input_item_code   -- �g�[�N���R�[�h3
                             ,iv_token_value3 => lt_wk_item_tab(2)        -- �g�[�N���l3
                             ,iv_token_name4  => cv_tkn_errmsg            -- �g�[�N���R�[�h4
                             ,iv_token_value4 => SQLERRM                  -- �g�[�N���l4
                            );
              -- �G���[�������Z
              gn_get_error_cnt := gn_get_error_cnt + 1;
              lv_errbuf  := lv_errmsg;
              RAISE global_api_expt;
          END;
        END IF;
      END IF;
      --
      -- STEP�`�F�b�N����
      IF ( lv_get_check_flag = cv_status_normal ) THEN
        -- ���팏�����Z
        gn_get_normal_cnt := gn_get_normal_cnt + 1;
      ELSE
        -- �G���[�������Z
        gn_get_error_cnt  := gn_get_error_cnt + 1;
      END IF;
    END LOOP ins_wk_loop;
--
  -- �`�F�b�N�t���O�̒l��ԋp
  ov_retcode := lv_check_flag;
  --
  EXCEPTION
    -- *** BLOB�f�[�^�ϊ��G���[��O�n���h�� ***
    WHEN blob_expt THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmn_10640            -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_file_id                -- �g�[�N���R�[�h1
                    ,iv_token_value1 => gn_file_id                    -- �g�[�N���l1
                   );
      RAISE global_api_expt;
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
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : ��������(D-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    iv_file_id    IN  VARCHAR2          -- 1.�t�@�C��ID
   ,iv_format     IN  VARCHAR2          -- 2.�t�H�[�}�b�g
   ,ov_errbuf     OUT VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init';              -- �v���O������
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
    lv_tkn_value              VARCHAR2(100);   -- �g�[�N���l
    lv_sqlerrm                VARCHAR2(5000);  -- SQLERRM��ޔ�
    --
    lv_up_name                VARCHAR2(1000);  -- �A�b�v���[�h���̏o�͗p
    lv_file_id                VARCHAR2(1000);  -- �t�@�C��ID�o�͗p
    lv_file_format            VARCHAR2(1000);  -- �t�H�[�}�b�g�o�͗p
    lv_file_name              VARCHAR2(1000);  -- �t�@�C�����o�͗p
    lv_value_name             VARCHAR2(1000);  -- ���ږ�
    lv_table_name             VARCHAR2(1000);  -- �e�[�u����
    ln_cnt                    NUMBER;          -- �J�E���^
    lv_csv_file_name          xxinv_mrp_file_ul_interface.file_name%TYPE;      -- �t�@�C�����i�[�p
    ln_created_by             xxinv_mrp_file_ul_interface.created_by%TYPE;     -- �쐬�Ҋi�[�p
    ld_creation_date          xxinv_mrp_file_ul_interface.creation_date%TYPE;  -- �쐬���i�[�p
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �f�[�^���ڒ�`�擾�p�J�[�\��
    CURSOR     get_def_info_cur
    IS
      SELECT   xlvv.meaning                     AS item_name       -- ���e
              ,DECODE(xlvv.attribute1, cv_varchar, cv_varchar_cd
                                     , cv_number , cv_number_cd
                                     , cv_date_cd
                     )                          AS item_attribute  -- ���ڑ���
              ,DECODE(xlvv.attribute2, cv_not_null, cv_null_ng
                                                  , cv_null_ok
                     )                          AS item_essential  -- �K�{�t���O
              ,TO_NUMBER(xlvv.attribute3)       AS item_length     -- ����(����)
              ,TO_NUMBER(xlvv.attribute4)       AS decim           -- ����(�����_�ȉ�)
      FROM     xxcmn_lookup_values_v  xlvv  -- �N�C�b�N�R�[�hVIEW
      WHERE    xlvv.lookup_type        = cv_lookup_item_def
      ORDER BY xlvv.lookup_code
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
    get_param_expt            EXCEPTION;       -- �p�����[�^NULL�G���[
    get_profile_expt          EXCEPTION;       -- �v���t�@�C���擾��O
    get_process_date_expt     EXCEPTION;       -- �Ɩ����t�擾���s�G���[
    get_data_expt             EXCEPTION;       -- �f�[�^�擾�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- D-1.1 ���̓p�����[�^�iFILE_ID�A�t�H�[�}�b�g�j��NULL�`�F�b�N
    --==============================================================
    IF ( iv_file_id IS NULL ) THEN
      lv_tkn_value := cv_file_id;
      RAISE get_param_expt;
    END IF;
    IF ( iv_format IS NULL ) THEN
      lv_tkn_value := cv_format_check;
      RAISE get_param_expt;
    END IF;
    --
    -- IN�p�����[�^���i�[
    gn_file_id := TO_NUMBER(iv_file_id);
    gv_format  := iv_format;
    --
    --==============================================================
    -- D-1.2 �Ɩ����t�擾
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- NULL�`�F�b�N
    IF ( gd_process_date IS NULL ) THEN
      RAISE get_process_date_expt;
    END IF;
    --
    --==============================================================
    -- D-1.3 �v���t�@�C���l�擾
    --==============================================================
    -- �i�ڃ}�X�^�ꊇ�A�b�v���[�h���ڐ��̎擾
    gn_item_num := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_item_num));
    -- �擾�G���[��
    IF ( gn_item_num IS NULL ) THEN
      lv_tkn_value := cv_prf_item_num;
      RAISE get_profile_expt;
    END IF;
    --
    -- �i�ڃJ�e�S���Z�b�g���i���i���i�敪�j�̎擾
    gt_ctg_item_prod := FND_PROFILE.VALUE(cv_prf_ctg_item_prod);
    -- �擾�G���[��
    IF ( gt_ctg_item_prod IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_item_prod;
      RAISE get_profile_expt;
    END IF;
    --
    -- �i�ڃJ�e�S���Z�b�g���i�{�Џ��i�敪�j�̎擾
    gt_ctg_hon_prod := FND_PROFILE.VALUE(cv_prf_ctg_hon_prod);
    -- �擾�G���[��
    IF ( gt_ctg_hon_prod IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_hon_prod;
      RAISE get_profile_expt;
    END IF;
    --
    -- �i�ڃJ�e�S���Z�b�g���i�}�[�P�Q�R�[�h�j�̎擾
    gt_ctg_mark_pg := FND_PROFILE.VALUE(cv_prf_ctg_mark_pg);
    -- �擾�G���[��
    IF ( gt_ctg_mark_pg IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_mark_pg;
      RAISE get_profile_expt;
    END IF;
    --
    -- �i�ڃJ�e�S���Z�b�g���i�Q�R�[�h�j�̎擾
    gt_ctg_gun_code := FND_PROFILE.VALUE(cv_prf_ctg_gun_code);
    -- �擾�G���[��
    IF ( gt_ctg_gun_code IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_gun_code;
      RAISE get_profile_expt;
    END IF;
    --
    -- �i�ڃJ�e�S���Z�b�g���i�i�ڋ敪�j�̎擾
    gt_ctg_item_class := FND_PROFILE.VALUE(cv_prf_ctg_item_div);
    -- �擾�G���[��
    IF ( gt_ctg_item_class IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_item_div;
      RAISE get_profile_expt;
    END IF;
    --
    -- �i�ڃJ�e�S���Z�b�g���i���O�敪�j�̎擾
    gt_ctg_inout_class := FND_PROFILE.VALUE(cv_prf_ctg_inout_class);
    -- �擾�G���[��
    IF ( gt_ctg_inout_class IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_inout_class;
      RAISE get_profile_expt;
    END IF;
    --
    -- �i�ڃJ�e�S���Z�b�g���i�H��Q�R�[�h�j�̎擾
    gt_ctg_fact_pg := FND_PROFILE.VALUE(cv_prf_ctg_fact_pg);
    -- �擾�G���[��
    IF ( gt_ctg_fact_pg IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_fact_pg;
      RAISE get_profile_expt;
    END IF;
    --
    -- �i�ڃJ�e�S���Z�b�g���i�o�����p�Q�R�[�h�j�̎擾
    gt_ctg_acnt_pg := FND_PROFILE.VALUE(cv_prf_ctg_acnt_pg);
    -- �擾�G���[��
    IF ( gt_ctg_acnt_pg IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_acnt_pg;
      RAISE get_profile_expt;
    END IF;
    --
    -- �i�ڃJ�e�S���Z�b�g���i����Q�R�[�h�j�̎擾
    gt_ctg_seisakugun := FND_PROFILE.VALUE(cv_prf_ctg_seisakugun);
    -- �擾�G���[��
    IF ( gt_ctg_seisakugun IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_seisakugun;
      RAISE get_profile_expt;
    END IF;
    --
    -- �i�ڃJ�e�S���Z�b�g���i�o�����敪�j�̎擾
    gt_ctg_baracha_class := FND_PROFILE.VALUE(cv_prf_ctg_baracha_class);
    -- �擾�G���[��
    IF ( gt_ctg_baracha_class IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_baracha_class;
      RAISE get_profile_expt;
    END IF;
    --
    -- �i�ڃJ�e�S���Z�b�g���i���i�敪�j�̎擾
    gt_ctg_product_div := FND_PROFILE.VALUE(cv_prf_ctg_product_div);
    -- �擾�G���[��
    IF ( gt_ctg_product_div IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_product_div;
      RAISE get_profile_expt;
    END IF;
    --
    -- �i�ڃJ�e�S���Z�b�g���i�i���敪�j�̎擾
    gt_ctg_quality_class := FND_PROFILE.VALUE(cv_prf_ctg_quality_class);
    -- �擾�G���[��
    IF ( gt_ctg_quality_class IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_quality_class;
      RAISE get_profile_expt;
    END IF;
    --
    -- �}�X�^�݌ɑg�D�R�[�h�̎擾
    gt_master_org_code := FND_PROFILE.VALUE(cv_prf_mst_org_code);
    -- �擾�G���[��
    IF ( gt_master_org_code IS NULL ) THEN
      lv_tkn_value := cv_prf_mst_org_code;
      RAISE get_profile_expt;
    END IF;
    --
    --==============================================================
    -- D-1.4 �}�X�^�݌ɑg�DID�擾
    --==============================================================
    BEGIN
      SELECT  mp.organization_id  AS master_org_id       -- �}�X�^�݌ɑg�DID
      INTO    gn_master_org_id
      FROM    mtl_parameters  mp  -- �g�D�p�����[�^
      WHERE   mp.organization_code = gt_master_org_code  -- ��L�Ŏ擾�����}�X�^�݌ɑg�D�R�[�h
      ;
    --
    EXCEPTION
      -- �擾�G���[��
      WHEN NO_DATA_FOUND THEN
        lv_value_name := cv_mst_org_id;
        RAISE get_data_expt;
    END;
    --
    --==============================================================
    -- D-1.5 �t�@�C���A�b�v���[�hIF�f�[�^�擾
    --==============================================================
    BEGIN
      SELECT  fui.file_name          AS file_name           -- �t�@�C����
             ,fui.created_by         AS created_by          -- �쐬��
             ,fui.creation_date      AS creation_date       -- �쐬��
      INTO    lv_csv_file_name
             ,ln_created_by
             ,ld_creation_date
      FROM    xxinv_mrp_file_ul_interface  fui              -- �t�@�C���A�b�v���[�hIF�e�[�u��
      WHERE   fui.file_id = gn_file_id                      -- �t�@�C��ID
      FOR UPDATE NOWAIT
      ;
    --
    EXCEPTION
      -- �擾�G���[��
      WHEN NO_DATA_FOUND THEN
        lv_value_name := cv_table_xmfui;
        RAISE get_data_expt;
      -- ���b�N�擾�G���[��
      WHEN global_check_lock_expt THEN
        lv_table_name := cv_table_xmfui;
        RAISE global_check_lock_expt;
    END;
    --
    --==============================================================
    -- D-1.6 �i�ڃ}�X�^�ꊇ�A�b�v���[�h���[�N��`���̎擾
    --==============================================================
    -- �ϐ��̏�����
    ln_cnt := 0;
    -- �e�[�u����`�擾LOOP
    <<def_info_loop>>
    FOR get_def_info_rec IN get_def_info_cur LOOP
      ln_cnt := ln_cnt + 1;
      g_item_def_tab(ln_cnt).item_name       := get_def_info_rec.item_name;       -- ���ږ�
      g_item_def_tab(ln_cnt).item_attribute  := get_def_info_rec.item_attribute;  -- ���ڑ���
      g_item_def_tab(ln_cnt).item_essential  := get_def_info_rec.item_essential;  -- �K�{�t���O
      g_item_def_tab(ln_cnt).item_length     := get_def_info_rec.item_length;     -- ����(��������)
      g_item_def_tab(ln_cnt).decim           := get_def_info_rec.decim;           -- ����(�����_�ȉ�)
    END LOOP def_info_loop;
    -- ��`��񂪎擾�ł��Ȃ��ꍇ�̓G���[
    IF ( ln_cnt = 0 ) THEN
      lv_value_name := cv_table_def;
      RAISE get_data_expt;
    END IF;
    --
    --==============================================================
    -- D-1.7 IN�p�����[�^�̏o��
    --==============================================================
    lv_up_name     := xxcmn_common_pkg.get_msg(                -- �A�b�v���[�h���̂̏o��
                        iv_application  => cv_appl_name_xxcmn  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmn_10631  -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_up_name      -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_upload_name      -- �g�[�N���l1
                      );
    lv_file_name   := xxcmn_common_pkg.get_msg(                -- �t�@�C��ID�̏o��
                        iv_application  => cv_appl_name_xxcmn  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmn_10632  -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_file_name    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_csv_file_name    -- �g�[�N���l1
                      );
    lv_file_id     := xxcmn_common_pkg.get_msg(                -- �t�@�C��ID�̏o��
                        iv_application  => cv_appl_name_xxcmn  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmn_10633  -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_file_id      -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(gn_file_id) -- �g�[�N���l1
                      );
    lv_file_format := xxcmn_common_pkg.get_msg(                -- �t�H�[�}�b�g�̏o��
                       iv_application  => cv_appl_name_xxcmn   -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmn_10634   -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_file_format   -- �g�[�N���R�[�h1
                      ,iv_token_value1 => gv_format            -- �g�[�N���l1
                      );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT                -- �o�͂ɕ\��
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
                                );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG                   -- ���O�ɕ\��
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
                                );
--
  EXCEPTION
    --*** �Ɩ����t�擾���s�G���[ ***
    WHEN get_process_date_expt THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmn_10628            -- ���b�Z�[�W
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                        --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                  --# �C�� #
    --*** �p�����[�^NULL�G���[ ***
    WHEN get_param_expt THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmn_10635            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_value                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                  -- �g�[�N���l1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                        --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                  --# �C�� #
    --
    --*** �v���t�@�C���擾�G���[ ***
    WHEN get_profile_expt THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmn_10002            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_ng_profile             -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                  -- �g�[�N���l1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                        --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                  --# �C�� #
    --
    --*** �f�[�^�擾�G���[ ***
    WHEN get_data_expt THEN
      lv_errmsg   := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmn            -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmn_10636            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_value
                      ,iv_token_value1 => lv_value_name
                     );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                        --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                  --# �C�� #
    --
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_check_lock_expt THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmn_10637            -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_table
                    ,iv_token_value1 => lv_table_name
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                        --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                  --# �C�� #
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
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id    IN  VARCHAR2          -- 1.�t�@�C��ID
   ,iv_format     IN  VARCHAR2          -- 2.�t�H�[�}�b�g
   ,ov_errbuf     OUT VARCHAR2          -- �G���[�E���b�Z�[�W         --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          -- ���^�[���E�R�[�h           --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_loop_errbuf   VARCHAR2(5000);    -- D-2�`D-7���̃G���[�E���b�Z�[�W
    lv_loop_retcode  VARCHAR2(1);       -- D-2�`D-7���̃��^�[���E�R�[�h
    lv_loop_errmsg   VARCHAR2(5000);    -- D-2�`D-7���̃��[�U�[�E�G���[�E���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
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
    gn_target_cnt     := 0;
    gn_normal_cnt     := 0;
    gn_error_cnt      := 0;
    gn_warn_cnt       := 0;
    --
    gn_get_normal_cnt := 0;  -- �^/�T�C�Y/�K�{�`�F�b�NOK����
    gn_get_error_cnt  := 0;  -- �^/�T�C�Y/�K�{�`�F�b�NNG����
    gn_val_normal_cnt := 0;  -- �Ó����`�F�b�NOK����
    gn_val_error_cnt  := 0;  -- �Ó����`�F�b�NNG����
    gn_ins_normal_cnt := 0;  -- �f�[�^�o�^OK����
    gn_ins_error_cnt  := 0;  -- �f�[�^�o�^NG����
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    --==============================================================
    -- D-1.  ��������
    --==============================================================
    proc_init(
      iv_file_id => iv_file_id          -- �t�@�C��ID
     ,iv_format  => iv_format           -- �t�H�[�}�b�g
     ,ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode = cv_status_normal ) THEN
      --==============================================================
      -- D-2.  �t�@�C���A�b�v���[�hIF�f�[�^�擾
      --==============================================================
      get_if_data(
        ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
       ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
       ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- �������ʃ`�F�b�N
      IF ( lv_retcode = cv_status_normal ) THEN
        --==============================================================
        --  D-3  �i�ڃ}�X�^�ꊇ�A�b�v���[�h���[�N�f�[�^�擾
        --  D-4  �i�ڃ}�X�^�ꊇ�A�b�v���[�h���[�N�f�[�^�Ó����`�F�b�N
        --  D-5  �f�[�^�o�^
        --  D-6  Disc�i�ڏ��擾
        --  D-7  Disc�i�ڃJ�e�S������
        --==============================================================
        loop_main(
          ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
         ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
         ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        -- �������ʃ`�F�b�N
        IF ( lv_retcode = cv_status_error ) THEN
          ROLLBACK;
        END IF;
      ELSE
        -- D-2�ŃG���[�̏ꍇ�AD-2�̏������ʂ��Z�b�g
        gn_normal_cnt := gn_get_normal_cnt;
        gn_error_cnt  := gn_get_error_cnt;
      END IF;
    ELSE
      -- D-1�ŃG���[�̏ꍇ�A�G���[1�����Z�b�g
      gn_error_cnt := 1;
    END IF;
--
    -- D-1�`D-7�̏������ʂ�ݒ�
    lv_loop_errbuf  := lv_errbuf;
    lv_loop_retcode := lv_retcode;
    lv_loop_errmsg  := lv_errmsg;
--
    --==============================================================
    -- D-8  �I������
    --==============================================================
    proc_comp(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    -- D-1�`D-7�̏����ŃG���[���������Ă���ꍇ
    IF ( lv_loop_retcode = cv_status_error ) THEN
      ov_errmsg  := lv_loop_errmsg;
      ov_errbuf  := lv_loop_errbuf;
      ov_retcode := cv_status_error;
    END IF;
    --
    -- �������ʃ`�F�b�N
    IF ( lv_retcode = cv_status_normal ) THEN
      COMMIT;
    ELSE
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
    errbuf        OUT    VARCHAR2       --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode       OUT    VARCHAR2       --   �G���[�R�[�h     #�Œ�#
   ,iv_file_id    IN     VARCHAR2       --   �t�@�C��ID
   ,iv_format     IN     VARCHAR2       --   �t�H�[�}�b�g
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- �v���O������
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
--###########################  �Œ蕔 START   #################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
--
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name  AS conc_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1
    ;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_file_id => iv_file_id          -- �t�@�C��ID
     ,iv_format  => iv_format           -- �t�H�[�}�b�g
     ,ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = cv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning  AS conc_status
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type
                                                                    , flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode
                                          , cv_status_normal ,cv_sts_cd_normal
                                          , cv_status_warn   ,cv_sts_cd_warn
                                          , cv_sts_cd_error)
    AND    ROWNUM                  = 1
    ;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCMN810004C;
/
