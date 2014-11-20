create or replace PACKAGE BODY xxinv520003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv520003c(body)
 * Description      : �i�ڐU��
 * MD.050           : �i�ڐU�� T_MD050_BPO_520
 * MD.070           : �i�ڐU�� T_MD070_BPO_52C
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init_proc              �����������s���v���V�[�W��                 (A-0)
 *  chk_param_new          �K�{�`�F�b�N���s���v���V�[�W��(�V�K)       (A-1-1)
 *  chk_param_upd          �K�{�`�F�b�N���s���v���V�[�W��(�X�V�E�폜) (A-1-2)
 *  chk_routing            �H���L���`�F�b�N���s���v���V�[�W��         (A-2)
 *  chk_formula            �t�H�[�~�����L���`�F�b�N���s���v���V�[�W�� (A-3)
 *  ins_formula            �t�H�[�~�����o�^���s���v���V�[�W��         (A-4)
 *  chk_recipe             ���V�s�L���`�F�b�N���s���v���V�[�W��       (A-5)
 *  ins_recipe             ���V�s�o�^���s���v���V�[�W��               (A-6)
 *  chk_lot                ���b�g�L���`�F�b�N���s���v���V�[�W��       (A-7)
 *  create_lot             ���b�g�쐬���s���v���V�[�W��               (A-8)
 *  create_batch           �o�b�`�쐬���s���v���V�[�W��               (A-9)
 *  input_lot_ins          ���̓��b�g�����ǉ����s���v���V�[�W��       (A-10)
 *  output_lot_ins         �o�̓��b�g�����ǉ����s���v���V�[�W��       (A-11)
 *  cmpt_batch             �o�b�`�������s���v���V�[�W��               (A-12)
 *  close_batch            �o�b�`�N���[�Y���s���v���V�[�W��           (A-13)
 *  save_batch             �o�b�`�ۑ����s���v���V�[�W��               (A-14)
 *  cancel_batch           �o�b�`������s���v���V�[�W��               (A-15)
 *  reschedule_batch       �o�b�`�ăX�P�W���[�����s���v���V�[�W��     (A-16)
 *  input_lot_upd          ���̓��b�g�����X�V���s���v���V�[�W��       (A-17)
 *  output_lot_upd         �o�̓��b�g�����X�V���s���v���V�[�W��       (A-18)
 *  input_lot_del          ���̓��b�g�����폜���s���v���V�[�W��       (A-19)
 *  output_lot_del         �o�̓��b�g�����폜���s���v���V�[�W��       (A-20)
 *  get_validity_rule_id   �Ó������[��ID���擾����v���V�[�W��       (A-21)
 *  chk_mst_data           �}�X�^���݃`�F�b�N���s���v���V�[�W��       (A-22)
 *  chk_close_period       �݌ɃN���[�Y�`�F�b�N���s���v���V�[�W��     (A-23)
 *  chk_qty_over_plan      �����\�����߃`�F�b�N(�\��)���s���v���V�[�W�� (A-24)
 *  chk_qty_over_actual    �����\�����߃`�F�b�N(����)���s���v���V�[�W��(A-25)
 *  get_batch_data         �o�b�`�f�[�^�擾���s���v���V�[�W��         (A-26)
 *  get_item_data          �i�ڃf�[�^�擾���s���v���V�[�W��           (A-27)
 *  chk_and_ins_formula    �t�H�[�~�����L���`�F�b�N �o�^����          (A-28)
 *  chk_and_ins_recipe     ���V�s�L���`�F�b�N �o�^����                (A-29)
 *  chk_and_ins_to_lot     �U�֐惍�b�g�L���`�F�b�N �o�^����          (A-30)
 *  input_lot_upd_ind      ���̓��b�g�����X�V(����)���s���v���V�[�W�� (A-31)
 *  output_lot_upd_ind     �o�̓��b�g�����X�V(����)���s���v���V�[�W�� (A-32)
 *  release_batch          �����[�X�o�b�`���s���v���V�[�W��           (A-33)
 *  chk_future_date        �������`�F�b�N���s���v���V�[�W��           (A-34)
 *  chk_qty_short_plan     �����\�݌ɕs���`�F�b�N(�\��)���s���v���V�[�W�� (A-35)
 *  chk_location           �ۊǑq�Ƀ`�F�b�N���s���v���V�[�W��(A-36)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------- -------------------------------------------------
 *  Date          Ver.  Editor              Description
 * ------------- ----- ------------------- -------------------------------------------------
 *  2008/11/11    1.0  Oracle ��r ���    ����쐬
 *  2009/01/15    1.1  SCS    �ɓ� �ЂƂ�  �w�E2,7�Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_ret_sts_success    CONSTANT VARCHAR2(1)    := 'S';            -- ����
  gv_pkg_name           CONSTANT VARCHAR2(100)  := 'xxinv520003c'; -- �p�b�P�[�W��
  gv_msg_kbn_cmn        CONSTANT VARCHAR2(5)    := 'XXCMN';
  gv_msg_kbn_inv        CONSTANT VARCHAR2(5)    := 'XXINV';
  gv_yyyymmdd           CONSTANT VARCHAR2(100)  := 'YYYY/MM/DD';
--
  -- ���b�Z�[�W�ԍ�
  gv_msg_52a_02         CONSTANT VARCHAR2(15)   := 'APP-XXCMN-10002'; -- �v���t�@�C���擾�G���[
--
  gv_msg_52a_00         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10000'; -- API�G���[
  gv_msg_52a_03         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10003'; -- �J�����_�N���[�Y���b�Z�[�W
  gv_msg_52a_11         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10011'; -- �f�[�^�擾�G���[���b�Z�[�W
  gv_msg_52a_15         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10015'; -- �p�����[�^�G���[
  gv_msg_52a_17         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10017'; -- �p�����[�^�U�֌����b�gNo�G���[
  gv_msg_52a_20         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10020'; -- �p�����[�^���ʃG���[
  gv_msg_xxinv_10066    CONSTANT VARCHAR2(15)   := 'APP-XXINV-10066'; -- �������G���[
  gv_msg_52a_71         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10071'; -- �p�����[�^�E�v�T�C�Y�G���[
  gv_msg_52a_72         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10072'; -- ���̓p�����[�^�K�{�G���[
--
  gv_msg_52a_77         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10177'; -- �i�ڐU��_�����敪
  gv_msg_52a_45         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10145'; -- �i�ڐU��_�ۊǑq��
  gv_msg_52a_46         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10146'; -- �i�ڐU��_�U�֌��i��
  gv_msg_52a_47         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10147'; -- �i�ڐU��_�U�֌����b�gNo
  gv_msg_52a_48         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10148'; -- �i�ڐU��_�U�֐�i��
  gv_msg_52a_49         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10149'; -- �i�ڐU��_����
  gv_msg_52a_50         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10150'; -- �i�ڐU��_�i�ڐU�֓�
  gv_msg_52a_51         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10151'; -- �i�ڐU��_�E�v
  gv_msg_52a_57         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10157'; -- �i�ڐU��_�i�ڐU�֖ړI
  gv_msg_52a_52         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10152'; -- �i�ڐU��_���Y�o�b�`No
  gv_msg_52a_66         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10166'; -- �X�e�[�^�X�G���[(�t�H�[�~����)
  gv_msg_52a_67         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10167'; -- �X�e�[�^�X�G���[(���V�s)
  gv_msg_52a_69         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10169'; -- �X�e�[�^�X�G���[(�Ó������[��)
  gv_msg_52a_78         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10178'; -- �H�����o�^�G���[
  gv_msg_52a_79         CONSTANT VARCHAR2(15)   := 'APP-XXINV-10179'; -- �t�H�[�~���������o�^�G���[
-- 2009/01/15 H.Itou Add Start �w�E2,7�Ή�
  gv_msg_xxinv_10183    CONSTANT VARCHAR2(15)   := 'APP-XXINV-10183'; -- �ۊǑq�ɕs��v�G���[���b�Z�[�W
  gv_msg_xxinv_10184    CONSTANT VARCHAR2(15)   := 'APP-XXINV-10184'; -- �����\�݌ɕs���G���[���b�Z�[�W
  gv_msg_xxinv_10185    CONSTANT VARCHAR2(15)   := 'APP-XXINV-10185'; -- �����\�݌ɐ����߃G���[���b�Z�[�W
-- 2009/01/15 H.Itou Add End
--
  -- �g�[�N��
  gv_tkn_parameter      CONSTANT VARCHAR2(15)   := 'PARAMETER';
  gv_tkn_value          CONSTANT VARCHAR2(15)   := 'VALUE';
  gv_tkn_value1         CONSTANT VARCHAR2(15)   := 'VALUE1';
  gv_tkn_value2         CONSTANT VARCHAR2(15)   := 'VALUE2';
  gv_tkn_api_name       CONSTANT VARCHAR2(15)   := 'API_NAME';
  gv_tkn_err_msg        CONSTANT VARCHAR2(15)   := 'ERR_MSG';
  gv_tkn_ng_profile     CONSTANT VARCHAR2(15)   := 'NG_PROFILE';
  gv_tkn_formula        CONSTANT VARCHAR2(15)   := 'FORMULA_NO';
  gv_tkn_recipe         CONSTANT VARCHAR2(15)   := 'RECIPE_NO';
  gv_tkn_ship_date      CONSTANT VARCHAR2(15)   := 'SHIP_DATE';
-- 2009/01/15 H.Itou Add Start �w�E2�Ή�
  gv_tkn_location       CONSTANT VARCHAR2(15)   := 'LOCATION';
  gv_tkn_item           CONSTANT VARCHAR2(15)   := 'ITEM';
  gv_tkn_lot            CONSTANT VARCHAR2(15)   := 'LOT';
  gv_tkn_standard_date  CONSTANT VARCHAR2(15)   := 'STANDARD_DATE';
-- 2009/01/15 H.Itou Add End
--
  -- �g�[�N���l
  gv_tkn_inv_loc        CONSTANT VARCHAR2(20)   := '�ۊǑq��';
  gv_tkn_from_item      CONSTANT VARCHAR2(20)   := '�U�֌��i��';
  gv_tkn_to_item        CONSTANT VARCHAR2(20)   := '�U�֐�i��';
  gv_tkn_item_date      CONSTANT VARCHAR2(20)   := '�i�ڐU�֓�';
  gv_tkn_item_aim       CONSTANT VARCHAR2(20)   := '�i�ڐU�֖ړI';
  gv_tkn_ins_formula    CONSTANT VARCHAR2(20)   := '�t�H�[�~�����o�^';
  gv_tkn_ins_recipe     CONSTANT VARCHAR2(20)   := '���V�s�o�^';
  gv_tkn_create_lot     CONSTANT VARCHAR2(20)   := '���b�g�쐬';
  gv_tkn_create_bat     CONSTANT VARCHAR2(20)   := '�o�b�`�쐬';
  gv_tkn_input_lot_ins  CONSTANT VARCHAR2(20)   := '���̓��b�g�����ǉ�';
  gv_tkn_output_lot_ins CONSTANT VARCHAR2(20)   := '�o�̓��b�g�����ǉ�';
  gv_tkn_input_lot_upd  CONSTANT VARCHAR2(20)   := '���̓��b�g�����X�V';
  gv_tkn_output_lot_upd CONSTANT VARCHAR2(20)   := '�o�̓��b�g�����X�V';
  gv_tkn_input_lot_del  CONSTANT VARCHAR2(20)   := '���̓��b�g�����폜';
  gv_tkn_output_lot_del  CONSTANT VARCHAR2(20)   := '�o�̓��b�g�����폜';
  gv_tkn_input_lot_upd_ind  CONSTANT VARCHAR2(50)   := '���̓��b�g�����X�V(����)';
  gv_tkn_output_lot_upd_ind CONSTANT VARCHAR2(50)   := '�o�̓��b�g�����X�V(����)';
  gv_tkn_release_batch  CONSTANT VARCHAR2(50)   := '�����[�X�o�b�`';
  gv_tkn_cmpt_bat       CONSTANT VARCHAR2(20)   := '�o�b�`����';
  gv_tkn_close_bat      CONSTANT VARCHAR2(20)   := '�o�b�`�N���[�Y';
  gv_tkn_save_bat       CONSTANT VARCHAR2(20)   := '�o�b�`�ۑ�';
  gv_tkn_cancel_bat     CONSTANT VARCHAR2(20)   := '�o�b�`���';
  gv_tkn_resche__bat    CONSTANT VARCHAR2(20)   := '�o�b�`�ăX�P�W���[��';
  gv_tkn_plan_batch_no  CONSTANT VARCHAR2(20)   := '���Y�o�b�`No';
  gv_tkn_process_type   CONSTANT VARCHAR2(20)   := '�����敪';
  gv_tkn_lot_no         CONSTANT VARCHAR2(20)   := '���b�gNo';
  gv_tkn_qty            CONSTANT VARCHAR2(20)   := '����';
  gv_tkn_start_date     CONSTANT VARCHAR2(50)   := 'XXINV:�Ó������[���J�n��';
--
  -- ���b�N�A�b�v
  gv_lt_item_tran_cls   CONSTANT VARCHAR2(30)   := 'XXINV_ITEM_TRANS_CLASS';
--
  -- �v���t�@�C��
  gv_pro_start_date     CONSTANT VARCHAR2(100)  := 'XXINV_VALID_RULE_DEFAULT_START_DATE'; -- XXINV:�Ó������[���J�n��
--
  -- �i�ڋ敪
  gv_material           CONSTANT VARCHAR2(1)    := '1';    -- ����
  gv_half_material      CONSTANT VARCHAR2(1)    := '4';    -- �����i
--
  -- �t�H�[�~�����o�^�^�C�v
  gv_record_type        CONSTANT VARCHAR2(1)    := 'I';    -- �}��
  -- �t�H�[�~�����X�e�[�^�X
  gv_fml_sts_new        CONSTANT VARCHAR2(3)    := '100';  -- �V�K
  gv_fml_sts_appr       CONSTANT VARCHAR2(3)    := '700';  -- ��ʎg�p�̏��F
  gv_fml_sts_abo        CONSTANT VARCHAR2(4)    := '1000'; -- �p�~/�A�[�J�C�u��
  -- �t�H�[�~�����E�o�[�W����
  gn_fml_vers           CONSTANT NUMBER         := 1;
  -- ���V�s�E�o�[�W����
  gn_rcp_vers           CONSTANT NUMBER         := 1;
  -- �H���敪
  gv_routing_class_70   CONSTANT VARCHAR2(2)    := '70';   -- �i�ڐU��
--
  -- ���׃^�C�v
  gn_line_type_p        CONSTANT NUMBER         := 1;      -- ���i
  gn_line_type_i        CONSTANT NUMBER         := -1;     -- ����
--
  gn_remarks_max        CONSTANT NUMBER         := 240;    -- �E�v�`�F�b�N�p�ő�o�C�g��
--
  gn_bat_type_batch     CONSTANT NUMBER         := 0;      -- 0:batch, 10:firm
--
  -- �����^�C�v
  gv_doc_type_code_prod CONSTANT VARCHAR2(2)    := '40';   -- ���Y
--
  -- ���R�[�h�^�C�v
  gv_rec_type_code_plan CONSTANT VARCHAR2(2)    := '10';   -- �w��
--
  -- �\��敪
  gv_plan_type_4        CONSTANT VARCHAR2(2)    := '4';    --
--
  -- �H��No�Œ�l
  gv_routing_no_hdr     CONSTANT VARCHAR2(2)    := '9';
--
  -- �o�b�`�X�e�[�^�X
  gn_batch_del          CONSTANT NUMBER         := -1;     -- ���
  gn_batch_comp         CONSTANT NUMBER         := 4;      -- ����
--
  -- �����敪
  gv_plan_new           CONSTANT VARCHAR2(1)    := '1';    -- �\��
  gv_plan_change        CONSTANT VARCHAR2(1)    := '2';    -- �\�����
  gv_plan_cancel        CONSTANT VARCHAR2(1)    := '3';    -- �\����
  gv_actual             CONSTANT VARCHAR2(1)    := '4';    -- ����(���Y�o�b�`No�w�莞)
  gv_actual_new         CONSTANT VARCHAR2(1)    := '5';    -- ����(���Y�o�b�`No�w��Ȃ���)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_plan_batch_no               VARCHAR2(10);             -- ���Y�o�b�`No(�\��)
  gd_start_date                  DATE;                     -- �Ó������[���J�n��
--
  -- �e�}�X�^�ւ̔��f�����ɕK�v�ȃf�[�^���i�[���郌�R�[�h
  TYPE masters_rec IS RECORD(
    -- �t�H�[�~�����}�X�^
    formula_no              fm_form_mst_b.formula_no%TYPE     -- �t�H�[�~�����ԍ�
  , formula_type            fm_form_mst_b.formula_type%TYPE   -- �t�H�[�~�����^�C�v
  , inactive_ind            fm_form_mst_b.inactive_ind%TYPE   -- (�K�{����)
  , orgn_code               fm_form_mst_b.orgn_code%TYPE      -- �g�D(�v�����g)�R�[�h
  , formula_status          fm_form_mst_b.formula_status%TYPE -- �X�e�[�^�X
  , formula_id              fm_form_mst_b.formula_id%TYPE     -- �t�H�[�~����ID
  , scale_type_hdr          fm_form_mst_b.scale_type%TYPE     -- �X�P�[�����O��
  , delete_mark             fm_form_mst_b.delete_mark%TYPE    -- (�K�{����)
    -- �t�H�[�~�������׃}�X�^
  , formulaline_id          fm_matl_dtl.formulaline_id%TYPE   -- ����ID
  , line_type               fm_matl_dtl.line_type%TYPE        -- ���׃^�C�v
  , line_no                 fm_matl_dtl.line_no%TYPE          -- ���הԍ�
  , qty                     fm_matl_dtl.qty%TYPE              -- ����
  , release_type            fm_matl_dtl.release_type%TYPE     -- ���v�^�C�v/����^�C�v
  , scrap_factor            fm_matl_dtl.scrap_factor%TYPE     -- �p���W��
  , scale_type_dtl          fm_matl_dtl.scale_type%TYPE       -- �X�P�[���^�C�v
  , phantom_type            fm_matl_dtl.phantom_type%TYPE     -- �t�@���g���^�C�v
  , rework_type             fm_matl_dtl.rework_type%TYPE      -- (�K�{����)
    -- ���V�s�}�X�^
  , recipe_id               gmd_recipes_b.recipe_id%TYPE      -- ���V�sID
  , recipe_no               gmd_recipes_b.recipe_no%TYPE      -- ���V�sNo
  , recipe_version          gmd_recipes_b.recipe_version%TYPE -- ���V�s�o�[�W����
  , recipe_status           gmd_recipes_b.recipe_status%TYPE  -- ���V�s�X�e�[�^�X
  , calculate_step_quantity gmd_recipes_b.calculate_step_quantity%TYPE -- �X�e�b�v���ʂ̌v�Z
    -- ���V�s�Ó������[���e�[�u��
  , recipe_validity_rule_id gmd_recipe_validity_rules.recipe_validity_rule_id%TYPE -- �Ó������[��
    -- �H���}�X�^
  , routing_id              gmd_routings_b.routing_id%TYPE    -- �H��ID
  , routing_no              gmd_routings_b.routing_no%TYPE    -- �H��No
  , routing_version         gmd_routings_b.routing_vers%TYPE  -- �H���o�[�W����
    -- OPM�ۊǑq�Ƀ}�X�^
  , inventory_location_id   mtl_item_locations.inventory_location_id%TYPE -- �ۊǑq��ID
  , inventory_location_code mtl_item_locations.segment1%TYPE              -- �ۊǑq�ɃR�[�h
    -- OPM�q�Ƀ}�X�^
  , whse_code               ic_whse_mst.whse_code%TYPE        -- �q�ɃR�[�h
    -- OPM�i�ڃ}�X�^
  , from_item_id            ic_item_mst_b.item_id%TYPE        -- �U�֌��i��ID
  , from_item_no            ic_item_mst_b.item_no%TYPE        -- �U�֌��i��No
  , from_item_um            ic_item_mst_b.item_um%TYPE        -- �U�֌��P��
  , to_item_id              ic_item_mst_b.item_id%TYPE        -- �U�֐�i��ID
  , to_item_no              ic_item_mst_b.item_no%TYPE        -- �U�֐�i��No
  , to_item_um              ic_item_mst_b.item_um%TYPE        -- �U�֐�P��
    -- OPM���b�g�}�X�^
  , from_lot_id             ic_lots_mst.lot_id%TYPE           -- �U�֌����b�gID
  , to_lot_id               ic_lots_mst.lot_id%TYPE           -- �U�֐惍�b�gID
  , lot_no                  ic_lots_mst.lot_no%TYPE           -- ���b�gNo
  , lot_desc                ic_lots_mst.lot_desc%TYPE         -- �E�v
  , lot_attribute1          ic_lots_mst.attribute1%TYPE       -- �����N����
  , lot_attribute2          ic_lots_mst.attribute2%TYPE       -- �ŗL�L��
  , lot_attribute3          ic_lots_mst.attribute3%TYPE       -- �ܖ�����
  , lot_attribute4          ic_lots_mst.attribute4%TYPE       -- �[����(����)
  , lot_attribute5          ic_lots_mst.attribute5%TYPE       -- �[����(�ŏI)
  , lot_attribute6          ic_lots_mst.attribute6%TYPE       -- �݌ɓ���
  , lot_attribute7          ic_lots_mst.attribute7%TYPE       -- �݌ɒP��
  , lot_attribute8          ic_lots_mst.attribute8%TYPE       -- �����
  , lot_attribute9          ic_lots_mst.attribute9%TYPE       -- �d���`��
  , lot_attribute10         ic_lots_mst.attribute10%TYPE      -- �����敪
  , lot_attribute11         ic_lots_mst.attribute11%TYPE      -- �N�x
  , lot_attribute12         ic_lots_mst.attribute12%TYPE      -- �Y�n
  , lot_attribute13         ic_lots_mst.attribute13%TYPE      -- �^�C�v
  , lot_attribute14         ic_lots_mst.attribute14%TYPE      -- �����N�P
  , lot_attribute15         ic_lots_mst.attribute15%TYPE      -- �����N�Q
  , lot_attribute16         ic_lots_mst.attribute16%TYPE      -- ���Y�`�[�敪
  , lot_attribute17         ic_lots_mst.attribute17%TYPE      -- ���C��No
  , lot_attribute18         ic_lots_mst.attribute18%TYPE      -- �E�v
  , lot_attribute19         ic_lots_mst.attribute19%TYPE      -- �����N�R
  , lot_attribute20         ic_lots_mst.attribute20%TYPE      -- ���������H��
  , lot_attribute21         ic_lots_mst.attribute21%TYPE      -- �������������b�g�ԍ�
  , lot_attribute22         ic_lots_mst.attribute22%TYPE      -- �����˗�No
  , lot_attribute23         ic_lots_mst.attribute23%TYPE      -- ���b�g�X�e�[�^�X
  , lot_attribute24         ic_lots_mst.attribute24%TYPE      -- �쐬�敪
  , lot_attribute25         ic_lots_mst.attribute25%TYPE      --
  , lot_attribute26         ic_lots_mst.attribute26%TYPE      --
  , lot_attribute27         ic_lots_mst.attribute27%TYPE      --
  , lot_attribute28         ic_lots_mst.attribute28%TYPE      --
  , lot_attribute29         ic_lots_mst.attribute29%TYPE      --
  , lot_attribute30         ic_lots_mst.attribute30%TYPE      --
--
    -- ���Y�o�b�`�w�b�_
  , batch_id                gme_batch_header.batch_id%TYPE        -- �o�b�`ID
  , batch_no                gme_batch_header.batch_no%TYPE        -- �o�b�`No
  , plan_start_date         gme_batch_header.plan_start_date%TYPE -- ���Y�\���
--
    -- ���Y�����ڍ�
  , from_material_detail_id gme_material_details.material_detail_id%TYPE  -- ���Y�����ڍ�ID(�U�֌�)
  , to_material_detail_id   gme_material_details.material_detail_id%TYPE  -- ���Y�����ڍ�ID(�U�֐�)
--
    -- �ۗ��݌Ƀg�����U�N�V����
  , from_trans_id           ic_tran_pnd.trans_id%TYPE             -- �g�����U�N�V����ID(�U�֌�)
  , to_trans_id             ic_tran_pnd.trans_id%TYPE             -- �g�����U�N�V����ID(�U�֐�)
  , trans_qty               ic_tran_pnd.trans_qty%TYPE            -- �g�����U�N�V��������
--
    -- �ړ����b�g�ڍ�
  , from_mov_lot_dtl_id     xxinv_mov_lot_details.mov_lot_dtl_id%TYPE -- �ړ����b�g�ڍ�ID(�U�֌�)
--
    -- ���Y�����ڍ׃A�h�I��
  , from_mtl_dtl_addon_id   xxwip_material_detail.mtl_detail_addon_id%TYPE  -- ���Y�����ڍ׃A�h�I��ID(�U�֌�)
--
  , item_sysdate            DATE                              -- �i�ڐU�֓�
  , remarks                 VARCHAR2(240)                     -- �E�v
  , item_chg_aim            VARCHAR2(1)                       -- �i�ڐU�֖ړI
  , is_info_flg             BOOLEAN                           -- ���L���t���O
  , process_type            VARCHAR2(1)                       -- �����敪
  , plan_batch_id           gme_batch_header.batch_id%TYPE    -- �o�b�`ID(�\��)
  );
  gr_gme_batch_header  gme_batch_header%ROWTYPE;   -- �X�V�p���Y�o�b�`���R�[�h
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : ��������
   ***********************************************************************************/
  PROCEDURE init_proc(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.�����Ώۃ��R�[�h
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================
    -- �v���t�@�C���I�v�V�����擾
    -- ====================================
    -- XXINV:�Ó������[���J�n��
    gd_start_date := TO_DATE(FND_PROFILE.VALUE(gv_pro_start_date), gv_yyyymmdd);
--
    -- XXINV:�Ó������[���J�n����NULL�̏ꍇ�A�G���[
    IF (gd_start_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn
                                           ,gv_msg_52a_02
                                           ,gv_tkn_ng_profile
                                           ,gv_tkn_start_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ====================================
    -- �H���R�[�h���Z�b�g (�Œ�l'9'+�ۊǑq�ɃR�[�h)
    -- ====================================
    ir_masters_rec.routing_no := gv_routing_no_hdr || ir_masters_rec.inventory_location_code;
--
    -- ====================================
    -- �g�����U�N�V�������ʏ�����
    -- ====================================
    ir_masters_rec.trans_qty := 0;

--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : chk_param_new
   * Description      : �K�{�`�F�b�N(�V�K)(A-1-1)
   ***********************************************************************************/
  PROCEDURE chk_param_new(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.�`�F�b�N�Ώۃ��R�[�h
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param_new'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==================================
    -- �ۊǑq�ɃR�[�h�K�{�`�F�b�N
    -- ==================================
    IF ( ir_masters_rec.inventory_location_code IS NULL ) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_72
                                          , gv_tkn_parameter
                                          , gv_tkn_inv_loc);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- �U�֌��i��No�K�{�`�F�b�N
    -- ==================================
    IF ( ir_masters_rec.from_item_no IS NULL ) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_72
                                          , gv_tkn_parameter
                                          , gv_tkn_from_item);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- ���b�gNo�K�{�`�F�b�N
    -- ==================================
    IF ( ir_masters_rec.lot_no IS NULL ) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_72
                                          , gv_tkn_parameter
                                          , gv_tkn_lot_no);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- �U�֐�i��No�K�{�`�F�b�N
    -- ==================================
    IF ( ir_masters_rec.to_item_no IS NULL ) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_72
                                          , gv_tkn_parameter
                                          , gv_tkn_to_item);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- ���ʕK�{�`�F�b�N
    -- ==================================
    IF ( ir_masters_rec.qty IS NULL ) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_72
                                          , gv_tkn_parameter
                                          , gv_tkn_qty);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- �i�ڐU�֓��K�{�`�F�b�N
    -- ==================================
    IF ( ir_masters_rec.item_sysdate IS NULL ) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_72
                                          , gv_tkn_parameter
                                          , gv_tkn_item_date);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- �i�ڐU�֖ړI�K�{�`�F�b�N
    -- ==================================
    IF ( ir_masters_rec.item_chg_aim IS NULL ) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_72
                                          , gv_tkn_parameter
                                          , gv_tkn_item_aim);
      -- ���ʊ֐���O�n���h��
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_param_new;
--
  /**********************************************************************************
   * Procedure Name   : chk_param_upd
   * Description      : �K�{�`�F�b�N(�X�V�E�폜)(A-1-2)
   ***********************************************************************************/
  PROCEDURE chk_param_upd(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.�`�F�b�N�Ώۃ��R�[�h
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param_upd'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==================================
    -- ���Y�o�b�`No(�\��)�̕K�{�`�F�b�N
    -- ==================================
    IF ( ir_masters_rec.plan_batch_id IS NULL ) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_72
                                          , gv_tkn_parameter
                                          , gv_tkn_plan_batch_no);
      -- ���ʊ֐���O�n���h��
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_param_upd;
--
  /**********************************************************************************
   * Procedure Name   : chk_mst_data
   * Description      : �}�X�^���݃`�F�b�N(A-22)
   ***********************************************************************************/
  PROCEDURE chk_mst_data(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.�`�F�b�N�Ώۃ��R�[�h
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_mst_data'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==================================
    -- �ۊǑq�ɑ��݃`�F�b�N
    -- ==================================
    BEGIN
      -- ==================================
      -- �v�����g�R�[�h�A�ۊǑq��ID�A�q�ɃR�[�h�̎擾
      -- ==================================
      SELECT xilv.orgn_code              orgn_code                  -- �v�����g�R�[�h
           , xilv.inventory_location_id  inventory_location_id      -- �ۊǑq��ID
           , xilv.whse_code              whse_code                  -- �q�ɃR�[�h
      INTO   ir_masters_rec.orgn_code                               -- �v�����g�R�[�h
           , ir_masters_rec.inventory_location_id                   -- �ۊǑq��ID
           , ir_masters_rec.whse_code                               -- �q�ɃR�[�h
      FROM   xxcmn_item_locations_v xilv                            -- OPM�ۊǏꏊ���VIEW
      WHERE  xilv.segment1 = ir_masters_rec.inventory_location_code -- �p�����[�^.�ۊǏꏊ
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �G���[���b�Z�[�W���擾
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_15
                                            , gv_tkn_parameter
                                            , gv_tkn_inv_loc
                                            , gv_tkn_value
                                            , ir_masters_rec.inventory_location_code);
        -- ���ʊ֐���O�n���h��
        RAISE global_api_expt;
    END;
--
    -- ==================================
    -- �U�֌��i�ڑ��݃`�F�b�N
    -- ==================================
    BEGIN
      -- ==================================
      -- �U�֌�No��蓱�o�������̎擾
      -- ==================================
      SELECT ximv.item_id             item_id   -- �i��ID
           , ximv.item_um             item_um   -- �P��
      INTO   ir_masters_rec.from_item_id        -- �i��ID(�U�֌�)
           , ir_masters_rec.from_item_um        -- �P��(�U�֌�)
      FROM   xxcmn_item_mst_v         ximv      -- OPM�i�ڃ}�X�^���VIEW
           , xxcmn_item_categories5_v xicv      -- OPM�i�ڃJ�e�S�����VIEW5
      WHERE  xicv.item_id         = ximv.item_id
      AND    ximv.item_no         = ir_masters_rec.from_item_no
      AND    xicv.item_class_code IN (gv_material, gv_half_material) -- �����A�����i
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �G���[���b�Z�[�W���擾
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_15
                                            , gv_tkn_parameter
                                            , gv_tkn_from_item
                                            , gv_tkn_value
                                            , ir_masters_rec.from_item_no);
        -- ���ʊ֐���O�n���h��
        RAISE global_api_expt;
    END;
--
    -- ==================================
    -- �U�֌����b�gNo���݃`�F�b�N
    -- ==================================
    BEGIN
      -- ==================================
      -- �U�֌����b�gID�̎擾
      -- ==================================
      SELECT ilm.lot_id  lot_id          -- ���b�gID
      INTO   ir_masters_rec.from_lot_id  -- ���b�gID(�U�֌�)
      FROM   ic_lots_mst ilm             -- OPM���b�g�}�X�^
      WHERE  ilm.lot_no  = ir_masters_rec.lot_no
      AND    ilm.item_id = ir_masters_rec.from_item_id
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �G���[���b�Z�[�W���擾
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_17);
        -- ���ʊ֐���O�n���h��
        RAISE global_api_expt;
    END;
--
    -- ==================================
    -- �U�֐�i�ڑ��݃`�F�b�N
    -- ==================================
    BEGIN
      -- ==================================
      -- �U�֐�i��No��蓱�o�������̎擾
      -- ==================================
      SELECT ximv.item_id             item_id   -- �i��ID
           , ximv.item_um             item_um   -- �P��
      INTO   ir_masters_rec.to_item_id          -- �i��ID(�U�֐�)
           , ir_masters_rec.to_item_um          -- �P��(�U�֐�)
      FROM   xxcmn_item_mst_v         ximv      -- OPM�i�ڃ}�X�^���VIEW
           , xxcmn_item_categories5_v xicv      -- OPM�i�ڃJ�e�S�����VIEW5
      WHERE  xicv.item_id         = ximv.item_id
      AND    ximv.item_no         = ir_masters_rec.to_item_no
      AND    xicv.item_class_code IN (gv_material, gv_half_material) -- �����A�����i
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �G���[���b�Z�[�W���擾
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_15
                                            , gv_tkn_parameter
                                            , gv_tkn_to_item
                                            , gv_tkn_value
                                            , ir_masters_rec.to_item_no);
        -- ���ʊ֐���O�n���h��
        RAISE global_api_expt;
    END;
--
    -- ==================================
    -- �E�v�������`�F�b�N
    -- ==================================
    IF ( LENGTHB(ir_masters_rec.remarks) > gn_remarks_max ) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_71);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- �i�ڐU�֖ړI���݃`�F�b�N
    -- ==================================
    BEGIN
      -- �N�C�b�N�R�[�h�ɑ��݂��Ă��邩���m�F
      SELECT flvv.lookup_code      lookup_code -- �N�C�b�N�R�[�h
      INTO   ir_masters_rec.item_chg_aim
      FROM   xxcmn_lookup_values_v flvv        -- �N�C�b�N�R�[�hVIEW
      WHERE  flvv.lookup_type  = gv_lt_item_tran_cls
      AND    flvv.lookup_code  = ir_masters_rec.item_chg_aim
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �G���[���b�Z�[�W���o��
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_15
                                            , gv_tkn_parameter
                                            , gv_tkn_item_aim
                                            , gv_tkn_value
                                            , ir_masters_rec.item_chg_aim);
        -- ���ʊ֐���O�n���h��
        RAISE global_api_expt;
    END;--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_mst_data;
--
  /**********************************************************************************
   * Procedure Name   : get_batch_data
   * Description      : �o�b�`�f�[�^�擾(A-26)
   ***********************************************************************************/
  PROCEDURE get_batch_data(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.�`�F�b�N�Ώۃ��R�[�h
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_batch_data'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
      -- ==================================
      -- �o�b�`No�A�o�b�`ID�A���Y�\����A�ۊǑq�ɃR�[�h�̎擾
      -- ==================================
      SELECT gbh.batch_no                batch_no               -- ���Y�o�b�`No
           , gbh.batch_id                batch_id               -- �o�b�`ID
           , gbh.plan_start_date         plan_start_date        -- ���Y�\���
           , xilv.inventory_location_id  inventory_location_id  -- �ۊǑq��ID
           , grb.attribute9              location_code          -- �ۊǑq�ɃR�[�h
           , xilv.orgn_code              orgn_code              -- �v�����g�R�[�h
           , xilv.whse_code              whse_code              -- �q�ɃR�[�h
      INTO   ir_masters_rec.batch_no                            -- ���Y�o�b�`No
           , ir_masters_rec.batch_id                            -- �o�b�`ID
           , ir_masters_rec.plan_start_date                     -- ���Y�\���
           , ir_masters_rec.inventory_location_id               -- �ۊǑq��ID
           , ir_masters_rec.inventory_location_code             -- �ۊǑq�ɃR�[�h
           , ir_masters_rec.orgn_code                           -- �v�����g�R�[�h
           , ir_masters_rec.whse_code                           -- �q�ɃR�[�h
      FROM   gme_batch_header        gbh                        -- ���Y�o�b�`�w�b�_
           , gmd_routings_b          grb                        -- �H���}�X�^
           , xxcmn_item_locations_v  xilv                       -- OPM�ۊǏꏊ���VIEW
      WHERE  gbh.routing_id    = grb.routing_id                 -- ��������(���Y�o�b�`�w�b�_ = �H���}�X�^)
      AND    grb.attribute9    = xilv.segment1                  -- ��������(���Y�o�b�`�w�b�_ = OPM�ۊǏꏊ���VIEW)
      AND    grb.routing_class = gv_routing_class_70            -- �H��[70:�i�ڐU��]
      AND    gbh.batch_status  NOT IN (gn_batch_del , gn_batch_comp)     -- �o�b�`�X�e�[�^�X��-1�F������A4�F�����łȂ�����
      AND    gbh.batch_id      = ir_masters_rec.plan_batch_id   -- �o�b�`ID
      ;
      -- ���Y�o�b�`No��ێ�
      gv_plan_batch_no := ir_masters_rec.batch_no;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �G���[���b�Z�[�W���擾
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_11);
        -- ���ʊ֐���O�n���h��
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_batch_data;
--
  /**********************************************************************************
   * Procedure Name   : get_item_data
   * Description      : �i�ڃf�[�^�擾(A-27)
   ***********************************************************************************/
  PROCEDURE get_item_data(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.�`�F�b�N�Ώۃ��R�[�h
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_data'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
      -- ==================================
      -- �U�֌��i�ڂ̏��擾
      -- ==================================
      SELECT gmd.material_detail_id  from_material_detail_id  -- ���Y�����ڍ�ID
           , itp.trans_id            from_trans_id            -- �g�����U�N�V����ID
           , itp.lot_id              from_lot_id              -- ���b�gID
           , ximv.item_id            from_item_id             -- �i��ID
           , ximv.item_no            from_item_no             -- �i�ڃR�[�h
           , ximv.item_um            from_item_um             -- �P��
      INTO   ir_masters_rec.from_material_detail_id           -- ���Y�����ڍ�ID(�U�֌�)
           , ir_masters_rec.from_trans_id                     -- �g�����U�N�V����ID(�U�֌�)
           , ir_masters_rec.from_lot_id                       -- ���b�gID(�U�֌�)
           , ir_masters_rec.from_item_id                      -- �i��ID(�U�֌�)
           , ir_masters_rec.from_item_no                      -- �i�ڃR�[�h(�U�֌�)
           , ir_masters_rec.from_item_um                      -- �P��(�U�֌�)
      FROM   gme_material_details gmd                         -- ���Y�����ڍ�
           , ic_tran_pnd          itp                         -- OPM�ۗ��݌Ƀg�����U�N�V����
           , xxcmn_item_mst_v     ximv                        -- OPM�i�ڏ��VIEW
      WHERE  itp.line_id     = gmd.material_detail_id         -- ��������(���Y�����ڍ�                = OPM�ۗ��݌Ƀg�����U�N�V����)
      AND    gmd.item_id     = ximv.item_id                   -- ��������(���Y�����ڍ�                = OPM�i�ڏ��VIEW)
      AND    itp.item_id     = ximv.item_id                   -- ��������(OPM�ۗ��݌Ƀg�����U�N�V���� = OPM�i�ڏ��VIEW)
      AND    gmd.batch_id    = ir_masters_rec.batch_id        -- �p�����[�^.�o�b�`ID
      AND    itp.doc_type    = 'PROD'                         --
      AND    itp.delete_mark = 0                              -- �폜�ςłȂ�
      AND    itp.lot_id     <> 0                              -- DEFAULTLOT�łȂ�
      AND    itp.reverse_id  IS NULL                          --
      AND    itp.line_type   = gn_line_type_i                 -- ���C���^�C�v������
      AND    gmd.line_type   = gn_line_type_i                 -- ���C���^�C�v������
      ;
--
      -- ==================================
      -- �U�֐�i�ڂ̏��擾
      -- ==================================
      SELECT gmd.material_detail_id  to_material_detail_id    -- ���Y�����ڍ�ID
           , itp.trans_id            to_trans_id              -- �g�����U�N�V����ID
           , itp.trans_qty           trans_qty                -- �g�����U�N�V��������
           , itp.lot_id              to_lot_id                -- ���b�gID
           , ilm.lot_no              lot_no                   -- ���b�gNo
           , ximv.item_id            to_item_id               -- �i��ID
           , ximv.item_no            to_item_no               -- �i�ڃR�[�h
           , ximv.item_um            to_item_um               -- �P��
      INTO   ir_masters_rec.to_material_detail_id             -- ���Y�����ڍ�ID(�U�֐�)
           , ir_masters_rec.to_trans_id                       -- �g�����U�N�V����ID(�U�֐�)
           , ir_masters_rec.trans_qty                         -- �g�����U�N�V��������
           , ir_masters_rec.to_lot_id                         -- ���b�gID(�U�֐�)
           , ir_masters_rec.lot_no                            -- ���b�gNo
           , ir_masters_rec.to_item_id                        -- �i��ID(�U�֐�)
           , ir_masters_rec.to_item_no                        -- �i�ڃR�[�h(�U�֐�)
           , ir_masters_rec.to_item_um                        -- �P��(�U�֐�)
      FROM   gme_material_details gmd                         -- ���Y�����ڍ�
           , ic_tran_pnd          itp                         -- OPM�ۗ��݌Ƀg�����U�N�V����
           , xxcmn_item_mst_v     ximv                        -- OPM�i�ڏ��VIEW
           , ic_lots_mst          ilm                         -- OPM���b�g�}�X�^
      WHERE  itp.line_id     = gmd.material_detail_id         -- ��������(���Y�����ڍ�                = OPM�ۗ��݌Ƀg�����U�N�V����)
      AND    gmd.item_id     = ximv.item_id                   -- ��������(���Y�����ڍ�                = OPM�i�ڏ��VIEW)
      AND    itp.item_id     = ximv.item_id                   -- ��������(OPM�ۗ��݌Ƀg�����U�N�V���� = OPM�i�ڏ��VIEW)
      AND    itp.item_id     = ilm.item_id                    -- ��������(OPM�ۗ��݌Ƀg�����U�N�V���� = OPM���b�g�}�X�^)
      AND    itp.lot_id      = ilm.lot_id                     -- ��������(OPM�ۗ��݌Ƀg�����U�N�V���� = OPM���b�g�}�X�^)
      AND    gmd.batch_id    = ir_masters_rec.batch_id        -- �p�����[�^.�o�b�`ID
      AND    itp.doc_type    = 'PROD'                         --
      AND    itp.delete_mark = 0                              -- �폜�ςłȂ�
      AND    itp.lot_id     <> 0                              -- DEFAULTLOT�łȂ�
      AND    itp.reverse_id  IS NULL                          --
      AND    itp.line_type   = gn_line_type_p                 -- ���C���^�C�v�����i
      AND    gmd.line_type   = gn_line_type_p                 -- ���C���^�C�v�����i
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �G���[���b�Z�[�W���擾
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_11);
        -- ���ʊ֐���O�n���h��
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_item_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_close_period
   * Description      : �݌ɃN���[�Y�`�F�b�N(A-23)
   ***********************************************************************************/
  PROCEDURE chk_close_period(
    id_date        IN            DATE        -- �`�F�b�N
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_close_period'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �i�ڐU�֓����݌ɃJ�����_�[�̃I�[�v���łȂ��ꍇ
    IF ( id_date <=
         TRUNC(LAST_DAY(FND_DATE.STRING_TO_DATE(xxcmn_common_pkg.get_opminv_close_period(), 'YYYY/MM'))) ) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_03
                                          , gv_tkn_err_msg
                                          , TO_CHAR(id_date, gv_yyyymmdd));
      -- ���ʊ֐���O�n���h��
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_close_period;
--
  /**********************************************************************************
   * Procedure Name   : chk_qty_over_actual
   * Description      : �����\�����߃`�F�b�N(����)(A-25)
   ***********************************************************************************/
  PROCEDURE chk_qty_over_actual(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.�`�F�b�N�Ώۃ��R�[�h
-- 2009/01/15 H.Itou Add Start �w�E8�Ή�
  , id_standard_date IN DATE                   -- 2.�L�����t
  , in_qty           IN NUMBER                 -- 3.���ѐ���
-- 2009/01/15 H.Itou Add End
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_qty_over_actual'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    ln_onhand_stk_qty  NUMBER;  -- �莝�݌ɐ��ʊi�[�p
    ln_fin_stk_qty     NUMBER;  -- �����ύ݌ɐ��ʊi�[�p
    ln_can_enc_qty     NUMBER;  -- �����\��
    ln_lot_ship_qty    NUMBER;  -- ���ʊi�[�p<���і��v��̏o�׈˗�>
    ln_lot_provide_qty NUMBER;  -- ���ʊi�[�p<���і��v��̎x���w��>
    ln_lot_inv_out_qty NUMBER;  -- ���ʊi�[�p<���і��v��̈ړ��w��>
    ln_lot_inv_in_qty  NUMBER;  -- ���ʊi�[�p<���ьv��ς̈ړ����Ɏ���>
    ln_lot_produce_qty NUMBER;  -- ���ʊi�[�p<���і��v��̐��Y�����\��>
    ln_lot_order_qty   NUMBER;  -- ���ʊi�[�p<���і��v��̑����q�ɔ������ɗ\��>
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �莝�݌ɐ��ʂ̎擾
    ln_onhand_stk_qty := xxcmn_common_pkg.get_stock_qty(
                                     ir_masters_rec.inventory_location_id     -- 1.�ۊǑq��ID
                                   , ir_masters_rec.from_item_id              -- 2.�i��ID
                                   , ir_masters_rec.from_lot_id);             -- 3.���b�gID
--
    -- ���ʂ̎擾<���і��v��̏o�׈˗�>
    xxcmn_common2_pkg.get_dem_lot_ship_qty(
                                     ir_masters_rec.inventory_location_id     -- 1.�ۊǑq��ID
                                   , ir_masters_rec.from_item_id              -- 2.�i��ID
                                   , ir_masters_rec.from_lot_id               -- 3.���b�gID
-- 2009/01/15 H.Itou Mod Start �w�E8�Ή�
--                                   , ir_masters_rec.item_sysdate              -- 4.�L�����t
                                   , id_standard_date                         -- 4.�L�����t
-- 2009/01/15 H.Itou Mod End
                                   , ln_lot_ship_qty                          -- 5.����
                                   , lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
                                   , lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
                                   , lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- ���ʂ̎擾<���і��v��̎x���w��>
    xxcmn_common2_pkg.get_dem_lot_provide_qty(
                                     ir_masters_rec.inventory_location_id     -- 1.�ۊǑq��ID
                                   , ir_masters_rec.from_item_id              -- 2.�i��ID
                                   , ir_masters_rec.from_lot_id               -- 3.���b�gID
-- 2009/01/15 H.Itou Mod Start �w�E8�Ή�
--                                   , ir_masters_rec.item_sysdate              -- 4.�L�����t
                                   , id_standard_date                         -- 4.�L�����t
-- 2009/01/15 H.Itou Mod End
                                   , ln_lot_provide_qty                       -- 5.����
                                   , lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
                                   , lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
                                   , lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- ���ʂ̎擾<���і��v��̈ړ��w��>
    xxcmn_common2_pkg.get_dem_lot_inv_out_qty(
                                     ir_masters_rec.inventory_location_id     -- 1.�ۊǑq��ID
                                   , ir_masters_rec.from_item_id              -- 2.�i��ID
                                   , ir_masters_rec.from_lot_id               -- 3.���b�gID
-- 2009/01/15 H.Itou Mod Start �w�E8�Ή�
--                                   , ir_masters_rec.item_sysdate              -- 4.�L�����t
                                   , id_standard_date                         -- 4.�L�����t
-- 2009/01/15 H.Itou Mod End
                                   , ln_lot_inv_out_qty                       -- 5.����
                                   , lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
                                   , lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
                                   , lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- ���ʂ̎擾<���ьv��ς̈ړ����Ɏ���>
    xxcmn_common2_pkg.get_dem_lot_inv_in_qty(
                                     ir_masters_rec.inventory_location_id     -- 1.�ۊǑq��ID
                                   , ir_masters_rec.from_item_id              -- 2.�i��ID
                                   , ir_masters_rec.from_lot_id               -- 3.���b�gID
-- 2009/01/15 H.Itou Mod Start �w�E8�Ή�
--                                   , ir_masters_rec.item_sysdate              -- 4.�L�����t
                                   , id_standard_date                         -- 4.�L�����t
-- 2009/01/15 H.Itou Mod End
                                   , ln_lot_inv_in_qty                        -- 5.����
                                   , lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
                                   , lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
                                   , lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- ���ʂ̎擾<���і��v��̐��Y�����\��>
    xxcmn_common2_pkg.get_dem_lot_produce_qty(
                                     ir_masters_rec.inventory_location_code   -- 1.�ۊǑq�ɃR�[�h
                                   , ir_masters_rec.from_item_id              -- 2.�i��ID
                                   , ir_masters_rec.from_lot_id               -- 3.���b�gID
-- 2009/01/15 H.Itou Mod Start �w�E8�Ή�
--                                   , ir_masters_rec.item_sysdate              -- 4.�L�����t
                                   , id_standard_date                         -- 4.�L�����t
-- 2009/01/15 H.Itou Mod End
                                   , ln_lot_produce_qty                       -- 5.����
                                   , lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
                                   , lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
                                   , lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- ���ʂ̎擾<���і��v��̑����q�ɔ������ɗ\��>
    xxcmn_common2_pkg.get_dem_lot_order_qty(
                                     ir_masters_rec.inventory_location_code   -- 1.�ۊǑq�ɃR�[�h
                                   , ir_masters_rec.from_item_no              -- 2.�i�ڃR�[�h
                                   , ir_masters_rec.from_lot_id               -- 3.���b�gID
-- 2009/01/15 H.Itou Mod Start �w�E8�Ή�
--                                   , ir_masters_rec.item_sysdate              -- 4.�L�����t
                                   , id_standard_date                         -- 4.�L�����t
-- 2009/01/15 H.Itou Mod End
                                   , ln_lot_order_qty                         -- 5.����
                                   , lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
                                   , lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
                                   , lv_errmsg);  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �����ύ݌ɐ��ʂ̎Z�o
    ln_fin_stk_qty := ln_lot_ship_qty
                    + ln_lot_provide_qty
                    + ln_lot_inv_out_qty
                    + ln_lot_inv_in_qty
                    + ln_lot_produce_qty
                    + ln_lot_order_qty;
--
    -- �����\���̎Z�o
    ln_can_enc_qty := ln_onhand_stk_qty
                    - ln_fin_stk_qty;
--
    -- �����\�����傫���ꍇ
-- 2009/01/15 H.Itou Mod Start �w�E8�Ή�
--    IF ( ir_masters_rec.qty -ir_masters_rec.trans_qty > ln_can_enc_qty ) THEN
    IF ( ln_can_enc_qty - in_qty < 0 ) THEN
-- 2009/01/15 H.Itou Mod End
      -- �G���[���b�Z�[�W���擾
-- 2009/01/15 H.Itou Mod Start �w�E2�Ή�
--      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
--                                          , gv_msg_52a_20);
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_xxinv_10185
                                          , gv_tkn_location      , ir_masters_rec.inventory_location_code
                                          , gv_tkn_item          , ir_masters_rec.from_item_no
                                          , gv_tkn_lot           , ir_masters_rec.lot_no
                                          , gv_tkn_standard_date , TO_CHAR(id_standard_date, gv_yyyymmdd));
-- 2009/01/15 H.Itou Mod End
      -- ���ʊ֐���O�n���h��
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_qty_over_actual;
--
  /**********************************************************************************
   * Procedure Name   : chk_qty_over_plan
   * Description      : �����\�����߃`�F�b�N(�\��)(A-24)
   ***********************************************************************************/
  PROCEDURE chk_qty_over_plan(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.�`�F�b�N�Ώۃ��R�[�h
-- 2009/01/15 H.Itou Add Start �w�E2�Ή�
  , id_standard_date         IN DATE                               -- 3.�L�����t
  , in_before_qty            IN NUMBER                             -- 4.�X�V�O����
  , in_after_qty             IN NUMBER                             -- 5.�o�^����
-- 2009/01/15 H.Itou Add End
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_qty_over_plan'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    ln_can_enc_qty     NUMBER;  -- �����\��
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �L�����x�[�X�����\��
    ln_can_enc_qty := xxcmn_common_pkg.get_can_enc_in_time_qty(
                         ir_masters_rec.inventory_location_id     -- 1.�ۊǑq��ID
                       , ir_masters_rec.from_item_id              -- 2.�i��ID
                       , ir_masters_rec.from_lot_id               -- 3.���b�gID
-- 2009/01/15 H.Itou Mod Start �w�E2�Ή�
--                       , ir_masters_rec.item_sysdate);            -- 4.�L�����t
                       , id_standard_date);                       -- 4.�L�����t
-- 2009/01/15 H.Itou Mod Start �w�E2�Ή�
--
    -- �����\�����傫���ꍇ
-- 2009/01/15 H.Itou Mod Start �w�E2�Ή�
--    IF ( ir_masters_rec.qty - ir_masters_rec.trans_qty > ln_can_enc_qty ) THEN
    IF ( ln_can_enc_qty + in_before_qty - in_after_qty < 0) THEN
-- 2009/01/15 H.Itou Mod End
      -- �G���[���b�Z�[�W���擾
-- 2009/01/15 H.Itou Mod Start �w�E2�Ή�
--      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
--                                          , gv_msg_52a_20);
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_xxinv_10185
                                          , gv_tkn_location      , ir_masters_rec.inventory_location_code
                                          , gv_tkn_item          , ir_masters_rec.from_item_no
                                          , gv_tkn_lot           , ir_masters_rec.lot_no
                                          , gv_tkn_standard_date , TO_CHAR(id_standard_date, gv_yyyymmdd));
-- 2009/01/15 H.Itou Mod End
      -- ���ʊ֐���O�n���h��
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_qty_over_plan;
--
  /**********************************************************************************
   * Procedure Name   : chk_routing
   * Description      : �H���L���`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE chk_routing(
    ir_masters_rec IN OUT NOCOPY masters_rec  -- 1.�`�F�b�N�Ώۃ��R�[�h
  , ov_errbuf      OUT    NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode     OUT    NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_routing'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==================================
    -- �H�����̎擾
    -- ==================================
    SELECT  grv.routing_id             routing_id   -- �H��ID
          , grv.routing_vers           routing_vers -- �H���o�[�W����
    INTO    ir_masters_rec.routing_id               -- �H��ID
          , ir_masters_rec.routing_version          -- �H���o�[�W����
    FROM    gmd_routings_vl            grv          -- �H���}�X�^VIEW
    WHERE   grv.routing_no     = ir_masters_rec.routing_no -- �H��No
    AND     grv.routing_status = gv_fml_sts_appr           -- ��ʎg�p�̏��F
    AND     grv.routing_class  = gv_routing_class_70       -- �i�ڐU��
    ;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                           , gv_msg_52a_78
                                           , gv_tkn_value
                                           , ir_masters_rec.routing_no);
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_routing;
--
  /**********************************************************************************
   * Procedure Name   : chk_formula
   * Description      : �t�H�[�~�����L���`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE chk_formula(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.�`�F�b�N�Ώۃ��R�[�h
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_formula'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    lv_formula_status   fm_form_mst_b.formula_status%TYPE;
    lv_return_status    VARCHAR2(2);
    ln_message_count    NUMBER;
    lv_msg_date         VARCHAR2(2000);
    lv_msg_list         VARCHAR2(2000);
    l_data              VARCHAR2(2000);
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���L���t���O�̏�����
    ir_masters_rec.is_info_flg := TRUE;
--
    -- ======================================
    -- �U�֌��i�ڂ̃t�H�[�~����ID�L���`�F�b�N
    -- ======================================
--
    -- �t�H�[�~����ID�̎擾
    SELECT ffmb.formula_id            formula_id     -- �t�H�[�~����ID
         , ffmb.formula_status        formula_status -- �t�H�[�~�����X�e�[�^�X
    INTO   ir_masters_rec.formula_id                 -- �t�H�[�~����ID
         , lv_formula_status                         -- �t�H�[�~�����X�e�[�^�X
    FROM   fm_form_mst_b              ffmb           -- �t�H�[�~�����}�X�^
         , fm_matl_dtl                fmd1           -- �t�H�[�~�����}�X�^����(�U�֌�)
         , fm_matl_dtl                fmd2           -- �t�H�[�~�����}�X�^����(�U�֐�)
    WHERE  ffmb.formula_id      = fmd1.formula_id    -- ��������(�t�H�[�~�����}�X�^ = �t�H�[�~�����}�X�^����(�U�֌�))
    AND    ffmb.formula_id      = fmd2.formula_id    -- ��������(�t�H�[�~�����}�X�^ = �t�H�[�~�����}�X�^����(�U�֌�))
    AND    fmd1.item_id         = ir_masters_rec.from_item_id -- �U�֌��̕i��ID
    AND    fmd1.line_type       = gn_line_type_i              -- ���C���^�C�v������
    AND    fmd2.item_id         = ir_masters_rec.to_item_id   -- �U�֐�̕i��ID
    AND    fmd2.line_type       = gn_line_type_p              -- ���C���^�C�v�����i
    AND    ffmb.formula_status <> gv_fml_sts_abo              -- �X�e�[�^�X���p�~�łȂ�
    AND    SUBSTRB(ffmb.formula_no, 9, 1)
                                = gv_routing_no_hdr           -- �i�ڐU�֗p�t�H�[�~����
    AND    EXISTS ( SELECT 1                                  -- ���������i��1:1�̃t�H�[�~����
                    FROM   fm_matl_dtl fmd
                    WHERE  fmd.formula_id = ffmb.formula_id
                    GROUP BY fmd.formula_id
                    HAVING COUNT(1) = 2 )
    ;
--
    -- �X�e�[�^�X���u��ʎg�p�̏��F�v�̏ꍇ
    IF ( lv_formula_status = gv_fml_sts_appr ) THEN
      NULL;
    -- �X�e�[�^�X���u�V�K�v�̏ꍇ
    ELSIF ( lv_formula_status = gv_fml_sts_new ) THEN
      -- �X�e�[�^�X�ύX(EBS�W��API)
      GMD_STATUS_PUB.MODIFY_STATUS(
            p_api_version    => 1.0                       -- API�o�[�W�����ԍ�
          , p_init_msg_list  => TRUE                      -- ���b�Z�[�W�������t���O
          , p_entity_name    => 'FORMULA'                 -- �t�H�[�~������
          , p_entity_id      => ir_masters_rec.formula_id -- �t�H�[�~����ID
          , p_entity_no      => NULL                      -- �ԍ�(NULL�Œ�)
          , p_entity_version => NULL                      -- �o�[�W����(NULL�Œ�)
          , p_to_status      => gv_fml_sts_appr           -- �X�e�[�^�X�ύX�l
          , p_ignore_flag    => FALSE                     --
          , x_message_count  => ln_message_count          -- �G���[���b�Z�[�W����
          , x_message_list   => lv_msg_list               -- �G���[���b�Z�[�W
          , x_return_status  => lv_return_status          -- �v���Z�X�I���X�e�[�^�X
            );
--
      -- �X�e�[�^�X�ύX�����������łȂ��ꍇ
      IF ( lv_return_status <> gv_ret_sts_success ) THEN
        -- �G���[���b�Z�[�W���O�o��
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
        xxcmn_common_pkg.put_api_log(
          ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
         ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
         ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
        );
--
        -- �G���[���b�Z�[�W���擾
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_00
                                            , gv_tkn_api_name
                                            , gv_tkn_ins_formula);
--
        -- ���ʊ֐���O�n���h��
        RAISE global_api_expt;
--
      -- �X�e�[�^�X�ύX�����������̏ꍇ
      ELSIF ( lv_return_status = gv_ret_sts_success ) THEN
        -- �m�菈��
        COMMIT;
      END IF;
--
    -- �X�e�[�^�X����L�ȊO�̏ꍇ
    ELSE
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_66
                                          , gv_tkn_formula
                                          , ir_masters_rec.formula_no);
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN   -- �����Ώۃ��R�[�h��1�����Ȃ������ꍇ
      ir_masters_rec.is_info_flg := FALSE;
--
    WHEN TOO_MANY_ROWS THEN   -- �����Ώۃ��R�[�h�������������ꍇ
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                           , gv_msg_52a_79
                                           , gv_tkn_value1
                                           , ir_masters_rec.from_item_no
                                           , gv_tkn_value2
                                           , ir_masters_rec.to_item_no);
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_formula;
--
  /**********************************************************************************
   * Procedure Name   : ins_formula
   * Description      : �t�H�[�~�����o�^(A-4)
   ***********************************************************************************/
  PROCEDURE ins_formula(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.�����Ώۃ��R�[�h
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_formula'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- INSERT_FORMULA API�p�ϐ�
    lv_return_status      VARCHAR2(2);
    ln_message_count      NUMBER;
    lv_msg_date           VARCHAR2(2000);
    -- MODIFY_STATUS API�p�ϐ�
    lv_msg_list           VARCHAR2(2000);
--
    -- �t�H�[�~�����e�[�u���^�ϐ�
    lt_formula_header_tbl gmd_formula_pub.formula_insert_hdr_tbl_type;
--
    l_data                VARCHAR2(2000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �t�H�[�~����No�̎擾
    ir_masters_rec.formula_no := xxinv_common_pkg.xxinv_get_formula_no(ir_masters_rec.to_item_no);
    -- �t�H�[�~����No���擾�ł��Ȃ��ꍇ
    IF ( ir_masters_rec.formula_no IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_11);
      RAISE global_api_expt;
    END IF;
--
    -- �o�^�����Z�b�g(�e�i��:���i)
    lt_formula_header_tbl(1).formula_no     := ir_masters_rec.formula_no; -- �ԍ�
    lt_formula_header_tbl(1).formula_vers   := gn_fml_vers;               -- �o�[�W����
    lt_formula_header_tbl(1).formula_desc1  := ir_masters_rec.formula_no; -- �E�v
    lt_formula_header_tbl(1).formula_status := gv_fml_sts_new;            -- �X�e�[�^�X
    lt_formula_header_tbl(1).orgn_code      := ir_masters_rec.orgn_code;  -- �g�D
    lt_formula_header_tbl(1).line_no        := 1;                         -- ���הԍ�
    lt_formula_header_tbl(1).line_type      := gn_line_type_p;            -- ���׃^�C�v
    lt_formula_header_tbl(1).item_no        := ir_masters_rec.to_item_no; -- �i��No
    lt_formula_header_tbl(1).qty            := ir_masters_rec.qty;        -- ����
    lt_formula_header_tbl(1).item_um        := ir_masters_rec.to_item_um; -- �P��
    lt_formula_header_tbl(1).user_name      := FND_GLOBAL.USER_NAME;      -- ���[�U�[
    lt_formula_header_tbl(1).release_type   := 1;                         -- �����^�C�v(1:�蓮)
--
    -- �o�^�����Z�b�g(�\���i��:����)
    lt_formula_header_tbl(2).formula_no     := ir_masters_rec.formula_no;   -- �ԍ�
    lt_formula_header_tbl(2).formula_vers   := gn_fml_vers;                 -- �o�[�W����
    lt_formula_header_tbl(2).formula_desc1  := ir_masters_rec.formula_no;   -- �E�v
    lt_formula_header_tbl(2).formula_status := gv_fml_sts_new;              -- �X�e�[�^�X
    lt_formula_header_tbl(2).orgn_code      := ir_masters_rec.orgn_code;    -- �g�D
    lt_formula_header_tbl(2).line_no        := 1;                           -- ���הԍ�
    lt_formula_header_tbl(2).line_type      := gn_line_type_i;              -- ���׃^�C�v
    lt_formula_header_tbl(2).item_no        := ir_masters_rec.from_item_no; -- �i��No
    lt_formula_header_tbl(2).qty            := ir_masters_rec.qty;          -- ����
    lt_formula_header_tbl(2).item_um        := ir_masters_rec.from_item_um; -- �P��
    lt_formula_header_tbl(2).user_name      := FND_GLOBAL.USER_NAME;        -- ���[�U�[
    lt_formula_header_tbl(2).release_type   := 1;                           -- �����^�C�v(1:�蓮)
--
    -- �t�H�[�~�����o�^(EBS�W��API)
    GMD_FORMULA_PUB.INSERT_FORMULA(
          p_api_version        => 1.0                   -- API�o�[�W�����ԍ�
        , p_init_msg_list      => FND_API.G_FALSE       -- ���b�Z�[�W�������t���O
        , p_commit             => FND_API.G_TRUE        -- �����R�~�b�g�t���O
        , p_called_from_forms  => 'NO'
        , x_return_status      => lv_return_status      -- �v���Z�X�I���X�e�[�^�X
        , x_msg_count          => ln_message_count      -- �G���[���b�Z�[�W����
        , x_msg_data           => lv_msg_date           -- �G���[���b�Z�[�W
        , p_formula_header_tbl => lt_formula_header_tbl
        , p_allow_zero_ing_qty => 'FALSE'
          );
    -- �o�^�����������łȂ��ꍇ
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- �G���[���b�Z�[�W���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_ins_formula);
--
      RAISE global_api_expt;
--
    -- �o�^�����������̏ꍇ
    ELSIF ( lv_return_status = gv_ret_sts_success ) THEN
      -- �t�H�[�~����ID�̎擾
      SELECT ffmb.formula_id   formula_id                  -- �t�H�[�~����ID
      INTO   ir_masters_rec.formula_id                     -- �t�H�[�~����ID
      FROM   fm_form_mst_b     ffmb                        -- �t�H�[�~�����}�X�^
           , fm_matl_dtl       fmd1                        -- �t�H�[�~�����}�X�^����(�U�֌�)
           , fm_matl_dtl       fmd2                        -- �t�H�[�~�����}�X�^����(�U�֐�)
      WHERE  ffmb.formula_id = fmd1.formula_id             -- ��������(�t�H�[�~�����}�X�^ = �t�H�[�~�����}�X�^����(�U�֌�))
      AND    ffmb.formula_id = fmd2.formula_id             -- ��������(�t�H�[�~�����}�X�^ = �t�H�[�~�����}�X�^����(�U�֐�))
      AND    fmd1.item_id    = ir_masters_rec.from_item_id -- �U�֌��̕i��ID
      AND    fmd2.item_id    = ir_masters_rec.to_item_id   -- �U�֐�̕i��ID
      AND    ffmb.formula_no = ir_masters_rec.formula_no   -- �t�H�[�~����No
      ;
    END IF;
--
    -- �X�e�[�^�X�ύX(EBS�W��API)
    GMD_STATUS_PUB.MODIFY_STATUS(
            p_api_version    => 1.0                       -- API�o�[�W�����ԍ�
          , p_init_msg_list  => TRUE                      -- ���b�Z�[�W�������t���O
          , p_entity_name    => 'FORMULA'                 -- �t�H�[�~������
          , p_entity_id      => ir_masters_rec.formula_id -- �t�H�[�~����ID
          , p_entity_no      => NULL                      -- �ԍ�(NULL�Œ�)
          , p_entity_version => NULL                      -- �o�[�W����(NULL�Œ�)
          , p_to_status      => gv_fml_sts_appr           -- �X�e�[�^�X�ύX�l
          , p_ignore_flag    => FALSE                     --
          , x_message_count  => ln_message_count          -- �G���[���b�Z�[�W����
          , x_message_list   => lv_msg_list               -- �G���[���b�Z�[�W
          , x_return_status  => lv_return_status          -- �v���Z�X�I���X�e�[�^�X
            );
--
    -- �X�e�[�^�X�ύX�����������łȂ��ꍇ
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_ins_formula);
      RAISE global_api_expt;
--
    -- �X�e�[�^�X�ύX�����������̏ꍇ
    ELSIF ( lv_return_status = gv_ret_sts_success ) THEN
      -- �m�菈��
      COMMIT;
    END IF;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                           , gv_msg_52a_11);
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_formula;
--
  /**********************************************************************************
   * Procedure Name   : chk_recipe
   * Description      : ���V�s�L���`�F�b�N(A-5)
   ***********************************************************************************/
  PROCEDURE chk_recipe(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.�`�F�b�N�Ώۃ��R�[�h
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_recipe'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    lv_recipe_status                gmd_recipes_b.recipe_status%TYPE;
    lv_recipe_no                    gmd_recipes_b.recipe_no%TYPE;
    ln_recipe_validity_rule_id      gmd_recipe_validity_rules.recipe_validity_rule_id%TYPE;
    lv_validity_rule_status         gmd_recipe_validity_rules.validity_rule_status%TYPE;
    lv_return_status                VARCHAR2(2);
    ln_message_count                NUMBER;
    lv_msg_date                     VARCHAR2(4000);
    lv_msg_list                     VARCHAR2(2000);
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���L���t���O�̏�����
    ir_masters_rec.is_info_flg := TRUE;
--
    -- ���V�sID�̎擾
    SELECT greb.recipe_id       recipe_id                 -- ���V�sID
         , greb.recipe_status   recipe_status             -- ���V�s�X�e�[�^�X
         , greb.recipe_no       recipe_no                 -- ���V�sNo
    INTO   ir_masters_rec.recipe_id                       -- ���V�sID
         , lv_recipe_status                               -- ���V�s�X�e�[�^�X
         , lv_recipe_no                                   -- ���V�sNo
    FROM   gmd_recipes_b        greb                      -- ���V�s�}�X�^
         , gmd_routings_b       grob                      -- �H���}�X�^
    WHERE  greb.routing_id    = grob.routing_id           -- ��������(���V�s�}�X�^ = �H���}�X�^)
    AND    greb.formula_id    = ir_masters_rec.formula_id -- �t�H�[�~����ID
    AND    grob.routing_no    = ir_masters_rec.routing_no -- �H��No
    AND    grob.routing_class = gv_routing_class_70       -- �H��70�F�i�ڐU��
    ;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN   -- �����Ώۃ��R�[�h��1�����Ȃ������ꍇ
      ir_masters_rec.is_info_flg := FALSE;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_recipe;
--
  /**********************************************************************************
   * Procedure Name   : ins_recipe
   * Description      : ���V�s�o�^(A-6)
   ***********************************************************************************/
  PROCEDURE ins_recipe(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.�����Ώۃ��R�[�h
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_recipe'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- API�p�ϐ�
    lv_return_status      VARCHAR2(2);
    ln_message_count      NUMBER;
    lv_msg_date           VARCHAR2(4000);
    -- MODIFY_STATUS API�p�ϐ�
    lv_msg_list           VARCHAR2(2000);
--
    -- ���V�s�e�[�u���^�ϐ�
    lt_recipe_hdr_tbl     gmd_recipe_header.recipe_tbl;
    lt_recipe_hdr_flex    gmd_recipe_header.recipe_flex;
    lt_recipe_vr_tbl      gmd_recipe_detail.recipe_vr_tbl;
    lt_recipe_vr_flex     gmd_recipe_detail.recipe_flex;
--
    l_data            VARCHAR2(2000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���V�s�o�[�W�������Z�b�g
    ir_masters_rec.recipe_version := 1;  -- �Œ�l
    -- ���V�sNo�̎擾
    ir_masters_rec.recipe_no := xxinv_common_pkg.xxinv_get_recipe_no(ir_masters_rec.to_item_no);
    -- ���V�sNo���擾�ł��Ȃ��ꍇ
    IF ( ir_masters_rec.recipe_no IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_11);
      RAISE global_api_expt;
    END IF;
    -- ===============================
    -- �o�^�����Z�b�g
    -- ===============================
--
    -- ���L�҃R�[�h
    lt_recipe_hdr_tbl(1).owner_orgn_code    := ir_masters_rec.orgn_code;
    -- �쐬�g�D�R�[�h
    lt_recipe_hdr_tbl(1).creation_orgn_code := ir_masters_rec.orgn_code;
    -- �t�H�[�~����ID
    lt_recipe_hdr_tbl(1).formula_id         := ir_masters_rec.formula_id;
    -- �H��ID
    lt_recipe_hdr_tbl(1).routing_id         := ir_masters_rec.routing_id;
    -- ���V�s�o�[�W����
    lt_recipe_hdr_tbl(1).recipe_version     := ir_masters_rec.recipe_version;
    -- ���V�sNo
    lt_recipe_hdr_tbl(1).recipe_no          := ir_masters_rec.recipe_no;
    -- �X�e�b�v���ʂ̌v�Z
    lt_recipe_hdr_tbl(1).calculate_step_quantity := 0;
    -- �E�v
    lt_recipe_hdr_tbl(1).recipe_description := ir_masters_rec.recipe_no;
--
    -- ���V�s�o�^(EBS�W��API)
    GMD_RECIPE_HEADER.CREATE_RECIPE_HEADER(
            p_api_version        => 1.0                   -- API�o�[�W�����ԍ�
          , p_init_msg_list      => FND_API.G_FALSE       -- ���b�Z�[�W�������t���O
          , p_commit             => FND_API.G_FALSE       -- �����R�~�b�g�t���O
          , p_called_from_forms  => 'NO'                  --
          , x_return_status      => lv_return_status      -- �v���Z�X�I���X�e�[�^�X
          , x_msg_count          => ln_message_count      -- �G���[���b�Z�[�W����
          , x_msg_data           => lv_msg_date           -- �G���[���b�Z�[�W
          , p_recipe_header_tbl  => lt_recipe_hdr_tbl     --
          , p_recipe_header_flex => lt_recipe_hdr_flex    --
            );
    -- �o�^�����������łȂ��ꍇ
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- �G���[���b�Z�[�W���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_ins_recipe);
      RAISE global_api_expt;
--
    -- �o�^�����������̏ꍇ
    ELSIF ( lv_return_status = gv_ret_sts_success ) THEN
--
      -- ���V�sID�̎擾
      SELECT greb.recipe_id            recipe_id                -- ���V�sID
      INTO   ir_masters_rec.recipe_id                           -- ���V�sID
      FROM   gmd_recipes_b             greb                     -- ���V�s�}�X�^
           , gmd_routings_b            grob                     -- �H���}�X�^
      WHERE  greb.routing_id      = grob.routing_id             -- ��������(���V�s�}�X�^ = �H���}�X�^)
      AND    greb.formula_id      = ir_masters_rec.formula_id   -- �t�H�[�~����ID
      AND    grob.routing_no      = ir_masters_rec.routing_no   -- �H��No
      AND    grob.routing_class   = gv_routing_class_70         -- �H��70�F�i�ڐU��
      ;
--
      -- ���V�s�X�e�[�^�X�ύX(EBS�W��API)
      GMD_STATUS_PUB.MODIFY_STATUS(
            p_api_version    => 1.0
          , p_init_msg_list  => TRUE
          , p_entity_name    => 'RECIPE'
          , p_entity_id      => ir_masters_rec.recipe_id
          , p_entity_no      => NULL            -- (NULL�Œ�)
          , p_entity_version => NULL            -- (NULL�Œ�)
          , p_to_status      => gv_fml_sts_appr
          , p_ignore_flag    => FALSE
          , x_message_count  => ln_message_count
          , x_message_list   => lv_msg_list
          , x_return_status  => lv_return_status
            );
--
      -- �X�e�[�^�X�ύX�����������łȂ��ꍇ
      IF ( lv_return_status <> gv_ret_sts_success ) THEN
        -- �G���[���b�Z�[�W���O�o��
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
        xxcmn_common_pkg.put_api_log(
          ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
         ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
         ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
        );
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_00
                                            , gv_tkn_api_name
                                            , gv_tkn_ins_recipe);
        RAISE global_api_expt;
      END IF;
--
      -- ���V�s�e�[�u���^�ϐ�������
      lt_recipe_vr_tbl.DELETE;
      -- ===============================
      -- �o�^�����Z�b�g
      -- ===============================
      -- ���V�s�ԍ�
      lt_recipe_vr_tbl(1).recipe_no            := ir_masters_rec.recipe_no;
      -- ���V�s�o�[�W����
      lt_recipe_vr_tbl(1).recipe_version       := ir_masters_rec.recipe_version;
      -- �i��
      lt_recipe_vr_tbl(1).item_id              := ir_masters_rec.to_item_id;
      -- �W������
      lt_recipe_vr_tbl(1).std_qty              := ir_masters_rec.qty;
      -- �P��
      lt_recipe_vr_tbl(1).item_um              := ir_masters_rec.to_item_um;
      -- �Ó������[���X�e�[�^�X
      lt_recipe_vr_tbl(1).validity_rule_status := gv_fml_sts_new;
      -- �L����
      lt_recipe_vr_tbl(1).start_date           := gd_start_date;
--
      -- �Ó������[���o�^(EBS�W��API)
      GMD_RECIPE_DETAIL.CREATE_RECIPE_VR(
            p_api_version        => 1.0                   -- API�o�[�W�����ԍ�
          , p_init_msg_list      => FND_API.G_FALSE       -- ���b�Z�[�W�������t���O
          , p_commit             => FND_API.G_FALSE       -- �����R�~�b�g�t���O
          , p_called_from_forms  => 'NO'                  --
          , x_return_status      => lv_return_status      -- �v���Z�X�I���X�e�[�^�X
          , x_msg_count          => ln_message_count      -- �G���[���b�Z�[�W����
          , x_msg_data           => lv_msg_date           -- �G���[���b�Z�[�W
          , p_recipe_vr_tbl      => lt_recipe_vr_tbl      --
          , p_recipe_vr_flex     => lt_recipe_vr_flex     --
            );
--
      -- �Ó������[���o�^�������łȂ��ꍇ
      IF ( lv_return_status <> gv_ret_sts_success ) THEN
        -- �G���[���b�Z�[�W���O�o��
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
        xxcmn_common_pkg.put_api_log(
          ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
         ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
         ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
        );
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_00
                                            , gv_tkn_api_name
                                            , gv_tkn_ins_recipe);
--
        RAISE global_api_expt;
--
      -- �Ó������[���o�^�������̏ꍇ
      ELSIF ( lv_return_status = gv_ret_sts_success ) THEN
--
        -- �Ó������[��ID�̎擾
        SELECT grvr.recipe_validity_rule_id   recipe_validity_rule_id  -- �Ó������[��ID
        INTO   ir_masters_rec.recipe_validity_rule_id                  -- �Ó������[��ID
        FROM   gmd_recipe_validity_rules      grvr                     -- ���V�s�Ó������[���}�X�^
        WHERE  grvr.recipe_id = ir_masters_rec.recipe_id               -- ���V�sID
        ;
--
        -- �Ó������[���X�e�[�^�X�ύX(EBS�W��API)
        GMD_STATUS_PUB.MODIFY_STATUS(
            p_api_version    => 1.0
          , p_init_msg_list  => TRUE
          , p_entity_name    => 'VALIDITY'
          , p_entity_id      => ir_masters_rec.recipe_validity_rule_id
          , p_entity_no      => NULL            -- (NULL�Œ�)
          , p_entity_version => NULL            -- (NULL�Œ�)
          , p_to_status      => gv_fml_sts_appr
          , p_ignore_flag    => FALSE
          , x_message_count  => ln_message_count
          , x_message_list   => lv_msg_list
          , x_return_status  => lv_return_status
            );
--
        -- �X�e�[�^�X�ύX�����������łȂ��ꍇ
        IF (lv_return_status <> gv_ret_sts_success) THEN
          -- �G���[���b�Z�[�W���O�o��
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
          xxcmn_common_pkg.put_api_log(
            ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
           ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
           ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
          );
--
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                              , gv_msg_52a_00
                                              , gv_tkn_api_name
                                              , gv_tkn_ins_recipe);
          RAISE global_api_expt;
--
        -- �X�e�[�^�X�ύX�����������̏ꍇ
        ELSIF (lv_return_status = gv_ret_sts_success) THEN
          -- �m�菈��
          COMMIT;
--
        END IF;
      END IF;
    END IF;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                           , gv_msg_52a_11);
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_recipe;
--
  /**********************************************************************************
   * Procedure Name   : chk_lot
   * Description      : ���b�g�L���`�F�b�N(A-7)
   ***********************************************************************************/
  PROCEDURE chk_lot(
    ir_masters_rec  IN OUT NOCOPY masters_rec -- 1.�`�F�b�N�Ώۃ��R�[�h
  , it_lot_no       IN            ic_lots_mst.lot_no %TYPE -- 2.���b�gNo
  , it_item_id      IN            ic_lots_mst.item_id%TYPE -- 3.�i��ID
  , it_lot_id       OUT    NOCOPY ic_lots_mst.lot_id %TYPE -- 3.���b�gID
  , ov_errbuf       OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode      OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_lot'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���L���t���O�̏�����
    ir_masters_rec.is_info_flg := TRUE;
--
    -- ======================================
    -- ���b�gID�L���`�F�b�N
    -- ======================================
    -- ���b�g���̎擾
    SELECT ilm.lot_id        -- ���b�gID
         , ilm.lot_desc      -- �E�v
         , ilm.attribute1    -- �����N����
         , ilm.attribute2    -- �ŗL�L��
         , ilm.attribute3    -- �ܖ�����
         , ilm.attribute4    -- �[����(����)
         , ilm.attribute5    -- �[����(�ŏI)
         , ilm.attribute6    -- �݌ɓ���
         , ilm.attribute7    -- �݌ɒP��
         , ilm.attribute8    -- �����
         , ilm.attribute9    -- �d���`��
         , ilm.attribute10   -- �����敪
         , ilm.attribute11   -- �N�x
         , ilm.attribute12   -- �Y�n
         , ilm.attribute13   -- �^�C�v
         , ilm.attribute14   -- �����N�P
         , ilm.attribute15   -- �����N�Q
         , ilm.attribute16   -- ���Y�`�[�敪
         , ilm.attribute17   -- ���C��No
         , ilm.attribute18   -- �E�v
         , ilm.attribute19   -- �����N�R
         , ilm.attribute20   -- ���������H��
         , ilm.attribute21   -- �������������b�g�ԍ�
         , ilm.attribute22   -- �����˗�No
         , ilm.attribute23   -- ���b�g�X�e�[�^�X
         , ilm.attribute24   -- �쐬�敪
         , ilm.attribute25   -- ����25
         , ilm.attribute26   -- ����26
         , ilm.attribute27   -- ����27
         , ilm.attribute28   -- ����28
         , ilm.attribute29   -- ����29
         , ilm.attribute30   -- ����30
    INTO   it_lot_id
         , ir_masters_rec.lot_desc
         , ir_masters_rec.lot_attribute1
         , ir_masters_rec.lot_attribute2
         , ir_masters_rec.lot_attribute3
         , ir_masters_rec.lot_attribute4
         , ir_masters_rec.lot_attribute5
         , ir_masters_rec.lot_attribute6
         , ir_masters_rec.lot_attribute7
         , ir_masters_rec.lot_attribute8
         , ir_masters_rec.lot_attribute9
         , ir_masters_rec.lot_attribute10
         , ir_masters_rec.lot_attribute11
         , ir_masters_rec.lot_attribute12
         , ir_masters_rec.lot_attribute13
         , ir_masters_rec.lot_attribute14
         , ir_masters_rec.lot_attribute15
         , ir_masters_rec.lot_attribute16
         , ir_masters_rec.lot_attribute17
         , ir_masters_rec.lot_attribute18
         , ir_masters_rec.lot_attribute19
         , ir_masters_rec.lot_attribute20
         , ir_masters_rec.lot_attribute21
         , ir_masters_rec.lot_attribute22
         , ir_masters_rec.lot_attribute23
         , ir_masters_rec.lot_attribute24
         , ir_masters_rec.lot_attribute25
         , ir_masters_rec.lot_attribute26
         , ir_masters_rec.lot_attribute27
         , ir_masters_rec.lot_attribute28
         , ir_masters_rec.lot_attribute29
         , ir_masters_rec.lot_attribute30
    FROM   ic_lots_mst  ilm   -- OPM���b�g�}�X�^
    WHERE  ilm.lot_no  = it_lot_no
    AND    ilm.item_id = it_item_id
    ;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN   -- �����Ώۃ��R�[�h��1�����Ȃ������ꍇ
      ir_masters_rec.is_info_flg := FALSE;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_lot;
--
  /**********************************************************************************
   * Procedure Name   : create_lot
   * Description      : ���b�g�쐬(A-8)
   ***********************************************************************************/
  PROCEDURE create_lot(
    ir_masters_rec  IN OUT NOCOPY masters_rec -- 1.�����Ώۃ��R�[�h
  , ov_errbuf       OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode      OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_lot'; -- �v���O������
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
    lv_return_status  VARCHAR2(2);     -- ���^�[���X�e�[�^�X
    ln_message_count  NUMBER;          -- ���b�Z�[�W�J�E���g
    lv_msg_date       VARCHAR2(10000); -- ���b�Z�[�W
    lb_return_status  BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_lot_rec        gmigapi.lot_rec_typ;
    lr_ic_lots_cpg    ic_lots_cpg%ROWTYPE;
    lr_lot_mst        ic_lots_mst%ROWTYPE;
    l_data            VARCHAR2(2000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lb_return_status := GMIGUTL.SETUP(FND_GLOBAL.USER_NAME()); -- CREATE_LOT API_VERSION�⏕(�K�{)
--
        -- ���b�g���̎擾
    SELECT lot_desc          -- �E�v
         , ilm.attribute1    -- �����N����
         , ilm.attribute2    -- �ŗL�L��
         , ilm.attribute3    -- �ܖ�����
         , ilm.attribute4    -- �[����(����)
         , ilm.attribute5    -- �[����(�ŏI)
         , ilm.attribute6    -- �݌ɓ���
         , ilm.attribute7    -- �݌ɒP��
         , ilm.attribute8    -- �����
         , ilm.attribute9    -- �d���`��
         , ilm.attribute10   -- �����敪
         , ilm.attribute11   -- �N�x
         , ilm.attribute12   -- �Y�n
         , ilm.attribute13   -- �^�C�v
         , ilm.attribute14   -- �����N�P
         , ilm.attribute15   -- �����N�Q
         , ilm.attribute16   -- ���Y�`�[�敪
         , ilm.attribute17   -- ���C��No
         , ilm.attribute18   -- �E�v
         , ilm.attribute19   -- �����N�R
         , ilm.attribute20   -- ���������H��
         , ilm.attribute21   -- �������������b�g�ԍ�
         , ilm.attribute22   -- �����˗�No
         , ilm.attribute23   -- ���b�g�X�e�[�^�X
         , ilm.attribute24   -- �쐬�敪
         , ilm.attribute25   -- ����25
         , ilm.attribute26   -- ����26
         , ilm.attribute27   -- ����27
         , ilm.attribute28   -- ����28
         , ilm.attribute29   -- ����29
         , ilm.attribute30   -- ����30
    INTO   ir_masters_rec.lot_desc
        ,  ir_masters_rec.lot_attribute1
        ,  ir_masters_rec.lot_attribute2
        ,  ir_masters_rec.lot_attribute3
        ,  ir_masters_rec.lot_attribute4
        ,  ir_masters_rec.lot_attribute5
        ,  ir_masters_rec.lot_attribute6
        ,  ir_masters_rec.lot_attribute7
        ,  ir_masters_rec.lot_attribute8
        ,  ir_masters_rec.lot_attribute9
        ,  ir_masters_rec.lot_attribute10
        ,  ir_masters_rec.lot_attribute11
        ,  ir_masters_rec.lot_attribute12
        ,  ir_masters_rec.lot_attribute13
        ,  ir_masters_rec.lot_attribute14
        ,  ir_masters_rec.lot_attribute15
        ,  ir_masters_rec.lot_attribute16
        ,  ir_masters_rec.lot_attribute17
        ,  ir_masters_rec.lot_attribute18
        ,  ir_masters_rec.lot_attribute19
        ,  ir_masters_rec.lot_attribute20
        ,  ir_masters_rec.lot_attribute21
        ,  ir_masters_rec.lot_attribute22
        ,  ir_masters_rec.lot_attribute23
        ,  ir_masters_rec.lot_attribute24
        ,  ir_masters_rec.lot_attribute25
        ,  ir_masters_rec.lot_attribute26
        ,  ir_masters_rec.lot_attribute27
        ,  ir_masters_rec.lot_attribute28
        ,  ir_masters_rec.lot_attribute29
        ,  ir_masters_rec.lot_attribute30
    FROM   ic_lots_mst  ilm   -- OPM���b�g�}�X�^
    WHERE  ilm.lot_no  = ir_masters_rec.lot_no
    AND    ilm.item_id = ir_masters_rec.from_item_id
    ;
--
    -- ======================================
    -- ���b�g��V�K�ɍ쐬
    -- ======================================
    lr_lot_rec.item_no          := ir_masters_rec.to_item_no;      -- 1.�i��No
    lr_lot_rec.lot_no           := ir_masters_rec.lot_no;          -- 2.���b�gNo
    lr_lot_rec.attribute1       := ir_masters_rec.lot_attribute1;  -- 3.����1
    lr_lot_rec.attribute2       := ir_masters_rec.lot_attribute2;  -- 3.����2
    lr_lot_rec.attribute3       := ir_masters_rec.lot_attribute3;  -- 3.����3
    lr_lot_rec.attribute4       := ir_masters_rec.lot_attribute4;  -- 3.����4
    lr_lot_rec.attribute5       := ir_masters_rec.lot_attribute5;  -- 3.����5
    lr_lot_rec.attribute6       := ir_masters_rec.lot_attribute6;  -- 3.����6
    lr_lot_rec.attribute7       := ir_masters_rec.lot_attribute7;  -- 3.����7
    lr_lot_rec.attribute8       := ir_masters_rec.lot_attribute8;  -- 3.����8
    lr_lot_rec.attribute9       := ir_masters_rec.lot_attribute9;  -- 3.����9
    lr_lot_rec.attribute10      := ir_masters_rec.lot_attribute10; -- 3.����10
    lr_lot_rec.attribute11      := ir_masters_rec.lot_attribute11; -- 3.����11
    lr_lot_rec.attribute12      := ir_masters_rec.lot_attribute12; -- 3.����12
    lr_lot_rec.attribute13      := ir_masters_rec.lot_attribute13; -- 3.����13
    lr_lot_rec.attribute14      := ir_masters_rec.lot_attribute14; -- 3.����14
    lr_lot_rec.attribute15      := ir_masters_rec.lot_attribute15; -- 3.����15
    lr_lot_rec.attribute16      := ir_masters_rec.lot_attribute16; -- 3.����16
    lr_lot_rec.attribute17      := ir_masters_rec.lot_attribute17; -- 3.����17
    lr_lot_rec.attribute18      := ir_masters_rec.lot_attribute18; -- 3.����18
    lr_lot_rec.attribute19      := ir_masters_rec.lot_attribute19; -- 3.����19
    lr_lot_rec.attribute20      := ir_masters_rec.lot_attribute20; -- 3.����20
    lr_lot_rec.attribute21      := ir_masters_rec.lot_attribute21; -- 3.����21
    lr_lot_rec.attribute22      := ir_masters_rec.lot_attribute22; -- 3.����22
    lr_lot_rec.attribute23      := ir_masters_rec.lot_attribute23; -- 3.����23
    lr_lot_rec.attribute24      := ir_masters_rec.lot_attribute24; -- 3.����24
    lr_lot_rec.attribute25      := ir_masters_rec.lot_attribute25; -- 3.����25
    lr_lot_rec.attribute26      := ir_masters_rec.lot_attribute26; -- 3.����26
    lr_lot_rec.attribute27      := ir_masters_rec.lot_attribute27; -- 3.����27
    lr_lot_rec.attribute28      := ir_masters_rec.lot_attribute28; -- 3.����28
    lr_lot_rec.attribute29      := ir_masters_rec.lot_attribute29; -- 3.����29
    lr_lot_rec.attribute30      := ir_masters_rec.lot_attribute30; -- 3.����30
    lr_lot_rec.expaction_date   := FND_DATE.STRING_TO_DATE('2099/12/31', gv_yyyymmdd);
    lr_lot_rec.expire_date      := FND_DATE.STRING_TO_DATE('2099/12/31', gv_yyyymmdd);
    lr_lot_rec.sublot_no        := NULL;
    lr_lot_rec.lot_desc         := ir_masters_rec.lot_desc;        -- �E�v
    lr_lot_rec.user_name        := FND_GLOBAL.USER_NAME;
    lr_lot_rec.lot_created      := SYSDATE;
--
    -- ���b�Z�[�W������API
    FND_MSG_PUB.INITIALIZE();
--
    -- ==========================================
    -- ���b�g�쐬API
    -- ==========================================
    GMIPAPI.CREATE_LOT(
          p_api_version      => 3.0                        -- API�o�[�W�����ԍ�
        , p_init_msg_list    => FND_API.G_FALSE            -- ���b�Z�[�W�������t���O
        , p_commit           => FND_API.G_TRUE             -- �����R�~�b�g�t���O
        , p_validation_level => FND_API.G_VALID_LEVEL_FULL -- ���؃��x��
        , p_lot_rec          => lr_lot_rec
        , x_ic_lots_mst_row  => lr_lot_mst
        , x_ic_lots_cpg_row  => lr_ic_lots_cpg
        , x_return_status    => lv_return_status           -- �v���Z�X�I���X�e�[�^�X
        , x_msg_count        => ln_message_count           -- �G���[���b�Z�[�W����
        , x_msg_data         => lv_msg_date                -- �G���[���b�Z�[�W
          );
--
    -- ���b�g�쐬�����������łȂ��ꍇ
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- �G���[���b�Z�[�W���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_create_lot);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- �U�֐惍�b�gID�̎擾
    -- ==================================
    SELECT ilm.lot_id                  -- ���b�gID
    INTO   ir_masters_rec.to_lot_id
    FROM   ic_lots_mst ilm             -- OPM���b�g�}�X�^
    WHERE  ilm.lot_no  = ir_masters_rec.lot_no
    AND    ilm.item_id = ir_masters_rec.to_item_id
    ;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                           , gv_msg_52a_11);
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_lot;
--
  /**********************************************************************************
   * Procedure Name   : get_validity_rule_id
   * Description      : �Ó������[��ID�擾(A-21)
   ***********************************************************************************/
  PROCEDURE get_validity_rule_id(
    ir_masters_rec IN OUT NOCOPY masters_rec -- 1.�����Ώۃ��R�[�h
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_validity_rule_id'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    ln_recipe_id gmd_recipes_b.recipe_id%TYPE;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���V�sID�̎擾
    SELECT greb.recipe_id    recipe_id     -- ���V�sID
    INTO   ln_recipe_id                    -- ���V�sID
    FROM   gmd_recipes_b     greb          -- ���V�s�}�X�^
         , gmd_routings_b    grob          -- �H���}�X�^
    WHERE  greb.formula_id      = ir_masters_rec.formula_id
    AND    greb.routing_id      = grob.routing_id
    AND    grob.routing_no      = ir_masters_rec.routing_no
    AND    grob.routing_class   = gv_routing_class_70
    ;
--
    -- �Ó������[��ID�̎擾
    SELECT grvr.recipe_validity_rule_id  recipe_validity_rule_id -- �Ó������[��ID
    INTO   ir_masters_rec.recipe_validity_rule_id                -- �Ó������[��ID
    FROM   gmd_recipe_validity_rules     grvr                    -- ���V�s�Ó������[���}�X�^
    WHERE  grvr.recipe_id = ln_recipe_id                         -- ���V�sID
    ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_validity_rule_id;
--
  /**********************************************************************************
   * Procedure Name   : create_batch
   * Description      : �o�b�`�쐬(A-9)
   ***********************************************************************************/
  PROCEDURE create_batch(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.�����Ώۃ��R�[�h
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_batch'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_return_status VARCHAR2(2);     -- ���^�[���X�e�[�^�X
    ln_message_count NUMBER;          -- ���b�Z�[�W�J�E���g
    lv_message_list  VARCHAR2(200);   -- ���b�Z�[�W���X�g
--
    -- *** ���[�J���E���R�[�h ***
    lr_in_batch_hdr  gme_batch_header%ROWTYPE;     -- ���Y�o�b�`�w�b�_(����)
    lr_out_batch_hrd gme_batch_header%ROWTYPE;     -- ���Y�o�b�`�w�b�_(�o��)
    lt_unalloc_mtl   gme_api_pub.unallocated_materials_tab;
--
    l_data           VARCHAR2(2000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lr_in_batch_hdr.plant_code              := ir_masters_rec.orgn_code;    -- �v�����g�R�[�h(�K�{)
    lr_in_batch_hdr.plan_start_date         := ir_masters_rec.item_sysdate; -- ���Y�\���
    lr_in_batch_hdr.plan_cmplt_date         := ir_masters_rec.item_sysdate; -- ���Y������
    lr_in_batch_hdr.attribute6              := ir_masters_rec.remarks;      -- �E�v
    lr_in_batch_hdr.attribute7              := ir_masters_rec.item_chg_aim; -- �i�ڐU�֖ړI
    lr_in_batch_hdr.batch_type              := gn_bat_type_batch;           -- �o�b�`�^�C�v
    lr_in_batch_hdr.wip_whse_code           := ir_masters_rec.whse_code;    -- �q�ɃR�[�h
    -- 13.�Ó������[��ID
    --�Ó������[��ID���Z�b�g����Ă��Ȃ��ꍇ
    IF ( ir_masters_rec.recipe_validity_rule_id IS NULL ) THEN
      -- ====================================
      -- �Ó������[��ID�擾(A-21)
      -- ====================================
      get_validity_rule_id(ir_masters_rec  -- 1.�`�F�b�N�Ώۃ��R�[�h
                         , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                         , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                         , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
    END IF;
    lr_in_batch_hdr.recipe_validity_rule_id := ir_masters_rec.recipe_validity_rule_id;
--
    -- ���b�Z�[�W������API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- �o�b�`�쐬API
    -- ======================================
    GME_API_PUB.CREATE_BATCH(
          p_api_version          => GME_API_PUB.API_VERSION
        , p_validation_level     => GME_API_PUB.MAX_ERRORS
        , p_init_msg_list        => FALSE
        , p_commit               => FALSE
        , p_batch_header         => lr_in_batch_hdr             -- �K�{
        , p_batch_size           => ir_masters_rec.qty          -- �K�{
        , p_batch_size_uom       => ir_masters_rec.from_item_um -- �K�{
        , p_creation_mode        => 'PRODUCT'                   -- �K�{
        , p_recipe_id            => NULL                        -- ���V�sID
        , p_recipe_no            => NULL                        -- ���V�sNo
        , p_recipe_version       => NULL                        -- ���V�s�o�[�W����
        , p_product_no           => NULL                        -- �H��No
        , p_product_id           => NULL                        -- �H��ID
        , p_ignore_qty_below_cap => TRUE
        , p_ignore_shortages     => TRUE                        -- �K�{
        , p_use_shop_cal         => NULL
        , p_contiguity_override  => 1
        , x_batch_header         => lr_out_batch_hrd            -- �K�{
        , x_message_count        => ln_message_count
        , x_message_list         => lv_message_list
        , x_return_status        => lv_return_status
        , x_unallocated_material => lt_unalloc_mtl              -- �񊄓����e�[�u��
          );
--
    -- �o�b�`�쐬�����������łȂ��ꍇ
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- �G���[���b�Z�[�W���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_create_bat);
--
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    END IF;
--
    -- �o�b�`ID�̊i�[
    ir_masters_rec.batch_id := lr_out_batch_hrd.batch_id;
    -- �o�b�`No�̊i�[
    ir_masters_rec.batch_no := lr_out_batch_hrd.batch_no;
--
    -- �U�֌��i�ڂ̐��Y�����ڍ�ID�̎擾
    SELECT gmd.material_detail_id  material_detail_id  -- ���Y�����ڍ�ID
    INTO   ir_masters_rec.from_material_detail_id      -- ���Y�����ڍ�ID(�U�֌�)
    FROM   gme_material_details    gmd                 -- ���Y�����ڍ�
    WHERE  gmd.batch_id = ir_masters_rec.batch_id      -- �o�b�`ID
    AND    gmd.item_id  = ir_masters_rec.from_item_id  -- �i��ID(�U�֌�)
    ;
--
    -- �U�֐�i�ڂ̐��Y�����ڍ�ID�̎擾
    SELECT gmd.material_detail_id                      -- ���Y�����ڍ�ID
    INTO   ir_masters_rec.to_material_detail_id        -- ���Y�����ڍ�ID(�U�֐�)
    FROM   gme_material_details gmd                    -- ���Y�����ڍ�
    WHERE  gmd.batch_id = ir_masters_rec.batch_id      -- �o�b�`ID
    AND    gmd.item_id  = ir_masters_rec.to_item_id    -- �i��ID(�U�֐�)
    ;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                           , gv_msg_52a_11);
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_batch;
--
  /**********************************************************************************
   * Procedure Name   : input_lot_ins
   * Description      : ���̓��b�g�����ǉ�(A-10)
   ***********************************************************************************/
  PROCEDURE input_lot_ins(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.�����Ώۃ��R�[�h
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'input_lot_ins'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_return_status    VARCHAR2(2);     -- ���^�[���X�e�[�^�X
    ln_message_count    NUMBER;          -- ���b�Z�[�W�J�E���g
    lv_msg_date         VARCHAR2(10000); -- ���b�Z�[�W
    lv_message_list     VARCHAR2(200);   -- ���b�Z�[�W���X�g
    l_data              VARCHAR2(2000);
--
    -- *** ���[�J���E���R�[�h ***
    lr_material_datail  gme_material_details%ROWTYPE;
    lr_tran_row_in      gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out     gme_inventory_txns_gtmp%ROWTYPE;
    lr_def_tran_row     gme_inventory_txns_gtmp%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lr_tran_row_in.item_id            := ir_masters_rec.from_item_id;            -- 1.�i��ID
    lr_tran_row_in.whse_code          := ir_masters_rec.whse_code;               -- 2.�q�ɃR�[�h
    lr_tran_row_in.lot_id             := ir_masters_rec.from_lot_id;             -- 3.���b�gID
    lr_tran_row_in.location           := ir_masters_rec.inventory_location_code; -- 4.�ۊǏꏊ
    lr_tran_row_in.doc_id             := ir_masters_rec.batch_id;                -- �o�b�`ID
    lr_tran_row_in.doc_type           := 'PROD';                                 -- 5.�����^�C�v
-- 2009/01/15 H.Itou Mod Start �w�E2�Ή�
--    lr_tran_row_in.trans_date         := ir_masters_rec.item_sysdate;            -- ���ѓ�
--    lr_tran_row_in.trans_qty          := ir_masters_rec.qty;                     -- 6.����
    lr_tran_row_in.trans_date         := NVL(ir_masters_rec.item_sysdate, ir_masters_rec.plan_start_date); -- ���ѓ�
    lr_tran_row_in.trans_qty          := NVL(ir_masters_rec.qty, ir_masters_rec.trans_qty); -- 6.����
-- 2009/01/15 H.Itou Mod End
    lr_tran_row_in.trans_um           := ir_masters_rec.from_item_um;            -- 7.�P�ʂP
    lr_tran_row_in.material_detail_id := ir_masters_rec.from_material_detail_id; -- ���Y�����ڍ�ID
--
    -- �����敪5:����(���Y�o�b�`No�Ȃ�)�̏ꍇ�͊����t���OON
    IF (ir_masters_rec.process_type = gv_actual_new) THEN
      lr_tran_row_in.completed_ind      := 1;                                      -- �����t���O
--
    -- 5:����(���Y�o�b�`No�Ȃ�)�ȊO�̏ꍇ�͊����t���OOFF
    ELSE
      lr_tran_row_in.completed_ind      := 0;                                      -- �����t���O
    END IF;
--
    -- ���b�Z�[�W������API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- ���b�g�����ǉ�API
    -- ======================================
    GME_API_PUB.INSERT_LINE_ALLOCATION(
          p_api_version      => GME_API_PUB.API_VERSION
        , p_validation_level => GME_API_PUB.MAX_ERRORS
        , p_init_msg_list    => FALSE
        , p_commit           => FALSE
        , p_tran_row         => lr_tran_row_in
        , p_lot_no           => NULL
        , p_sublot_no        => NULL
        , p_create_lot       => FALSE
        , p_ignore_shortage  => TRUE
        , p_scale_phantom    => FALSE
        , x_material_detail  => lr_material_datail
        , x_tran_row         => lr_tran_row_out
        , x_def_tran_row     => lr_def_tran_row
        , x_message_count    => ln_message_count
        , x_message_list     => lv_message_list
        , x_return_status    => lv_return_status
          );
--
    -- ���̓��b�g�����ǉ������������łȂ��ꍇ
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- �G���[���b�Z�[�W���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_input_lot_ins);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    END IF;
--
    -- ======================================
    -- �ړ����b�g�ڍׂփf�[�^�o�^
    -- ======================================
    INSERT INTO xxinv_mov_lot_details(
      mov_lot_dtl_id                  -- ���b�g�ڍ�ID
    , mov_line_id                     -- ����ID
    , document_type_code              -- �����^�C�v
    , record_type_code                -- ���R�[�h�^�C�v
    , item_id                         -- OPM�i��ID
    , item_code                       -- �i��
    , lot_id                          -- ���b�gID
    , lot_no                          -- ���b�gNo
    , actual_date                     -- ���ѓ�
    , actual_quantity                 -- ���ѐ���
    , created_by                      -- �쐬��
    , creation_date                   -- �쐬��
    , last_updated_by                 -- �ŏI�X�V��
    , last_update_date                -- �ŏI�X�V��
    , last_update_login               -- �ŏI�X�V���O�C��
    , request_id                      -- �v��ID
    , program_application_id          -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    , program_id                      -- �R���J�����g�E�v���O����ID
    , program_update_date             -- �v���O�����X�V��
    )
    VALUES(
      xxinv_mov_lot_s1.NEXTVAL                      -- ���b�g�ڍ�ID
    , ir_masters_rec.from_material_detail_id        -- ����ID
    , gv_doc_type_code_prod                         -- �����^�C�v
    , gv_rec_type_code_plan                         -- ���R�[�h�^�C�v
    , ir_masters_rec.from_item_id                   -- OPM�i��ID
    , ir_masters_rec.from_item_no                   -- �i��
    , ir_masters_rec.from_lot_id                    -- ���b�gID
    , ir_masters_rec.lot_no                         -- ���b�gNo
    , NULL                                          -- ���ѓ�
-- 2009/01/15 H.Itou Mod Start �w�E2�Ή�
--    , ir_masters_rec.qty                     -- ���ѐ���
    , NVL(ir_masters_rec.qty, ir_masters_rec.trans_qty) -- ���ѐ���
-- 2009/01/15 H.Itou Mod End
    , FND_GLOBAL.USER_ID                            -- �쐬��
    , SYSDATE                                       -- �쐬��
    , FND_GLOBAL.USER_ID                            -- �ŏI�X�V��
    , SYSDATE                                       -- �ŏI�X�V��
    , FND_GLOBAL.LOGIN_ID                           -- �ŏI�X�V���O�C��
    , FND_GLOBAL.CONC_REQUEST_ID                    -- �v��ID
    , FND_GLOBAL.PROG_APPL_ID                       -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    , FND_GLOBAL.CONC_PROGRAM_ID                    -- �R���J�����g�E�v���O����ID
    , SYSDATE                                       -- �v���O�����X�V��
    );
--
    -- ======================================
    -- ���Y�����ڍ׃A�h�I���փf�[�^�o�^
    -- ======================================
    INSERT INTO xxwip_material_detail(-- ���Y�����ڍ׃A�h�I��
      mtl_detail_addon_id             -- ���Y�����ڍ׃A�h�I��ID
    , batch_id                        -- �o�b�`ID
    , material_detail_id              -- ���Y�����ڍ�ID
    , item_id                         -- �i��ID
    , lot_id                          -- ���b�gID
    , instructions_qty                -- �w������
    , invested_qty                    -- ��������
    , return_qty                      -- �ߓ�����
    , mtl_prod_qty                    -- ���ސ����s�ǐ�
    , mtl_mfg_qty                     -- ���ދƎҕs�ǐ�
    , location_code                   -- ��z�q�ɃR�[�h
    , plan_type                       -- �\��敪
    , plan_number                     -- �ԍ�
    , created_by                      -- �쐬��
    , creation_date                   -- �쐬��
    , last_updated_by                 -- �ŏI�X�V��
    , last_update_date                -- �ŏI�X�V��
    , last_update_login               -- �ŏI�X�V���O�C��
    , request_id                      -- �v��ID
    , program_application_id          -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    , program_id                      -- �R���J�����g�E�v���O����ID
    , program_update_date             -- �v���O�����X�V��
    )
    VALUES(
      xxwip_mtl_detail_addon_id_s1.NEXTVAL          -- ���Y�����ڍ׃A�h�I��ID
    , ir_masters_rec.batch_id                       -- �o�b�`ID
    , ir_masters_rec.from_material_detail_id        -- ���Y�����ڍ�ID
    , ir_masters_rec.from_item_id                   -- �i��ID
    , ir_masters_rec.from_lot_id                    -- ���b�gID
-- 2009/01/15 H.Itou Mod Start �w�E2�Ή�
--    , ir_masters_rec.qty                     -- ���ѐ���
    , NVL(ir_masters_rec.qty, ir_masters_rec.trans_qty) -- ���ѐ���
-- 2009/01/15 H.Itou Mod End
    , 0                                             -- ��������
    , 0                                             -- �ߓ�����
    , 0                                             -- ���ސ����s�ǐ�
    , 0                                             -- ���ދƎҕs�ǐ�
    , ir_masters_rec.inventory_location_code        -- ��z�q�ɃR�[�h
    , gv_plan_type_4                                -- �\��敪
    , NULL                                          -- �\��ԍ�
    , FND_GLOBAL.USER_ID                            -- �쐬��
    , SYSDATE                                       -- �쐬��
    , FND_GLOBAL.USER_ID                            -- �ŏI�X�V��
    , SYSDATE                                       -- �ŏI�X�V��
    , FND_GLOBAL.LOGIN_ID                           -- �ŏI�X�V���O�C��
    , FND_GLOBAL.CONC_REQUEST_ID                    -- �v��ID
    , FND_GLOBAL.PROG_APPL_ID                       -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    , FND_GLOBAL.CONC_PROGRAM_ID                    -- �R���J�����g�E�v���O����ID
    , SYSDATE                                       -- �v���O�����X�V��
    );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END input_lot_ins;
--
  /**********************************************************************************
   * Procedure Name   : output_lot_ins
   * Description      : �o�̓��b�g�����ǉ�(A-11)
   ***********************************************************************************/
  PROCEDURE output_lot_ins(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.�����Ώۃ��R�[�h
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_lot_ins'; -- �v���O������
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
    lv_return_status VARCHAR2(2);     -- ���^�[���X�e�[�^�X
    ln_message_count NUMBER;          -- ���b�Z�[�W�J�E���g
    lv_msg_date      VARCHAR2(10000); -- ���b�Z�[�W
    lv_message_list  VARCHAR2(200);   -- ���b�Z�[�W���X�g
    l_data           VARCHAR2(2000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_material_detail  gme_material_details%ROWTYPE;
    lr_tran_row_in      gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out     gme_inventory_txns_gtmp%ROWTYPE;
    lr_def_tran_row     gme_inventory_txns_gtmp%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lr_tran_row_in.item_id            := ir_masters_rec.to_item_id;              -- 1.�i��ID
    lr_tran_row_in.whse_code          := ir_masters_rec.whse_code;               -- 2.�q�ɃR�[�h
    lr_tran_row_in.lot_id             := ir_masters_rec.to_lot_id;               -- 3.���b�gID
    lr_tran_row_in.location           := ir_masters_rec.inventory_location_code; -- 4.�ۊǏꏊ
    lr_tran_row_in.doc_id             := ir_masters_rec.batch_id;                -- �o�b�`ID
    lr_tran_row_in.doc_type           := 'PROD';                                 -- 5.�����^�C�v
-- 2009/01/15 H.Itou Mod Start �w�E2�Ή�
--    lr_tran_row_in.trans_date         := ir_masters_rec.item_sysdate;            -- ���ѓ�
--    lr_tran_row_in.trans_qty          := ir_masters_rec.qty;                     -- 6.����
    lr_tran_row_in.trans_date         := NVL(ir_masters_rec.item_sysdate, ir_masters_rec.plan_start_date); -- ���ѓ�
    lr_tran_row_in.trans_qty          := NVL(ir_masters_rec.qty, ir_masters_rec.trans_qty); -- 6.����
-- 2009/01/15 H.Itou Mod End
    lr_tran_row_in.trans_um           := ir_masters_rec.to_item_um;              -- 7.�P�ʂP
    lr_tran_row_in.material_detail_id := ir_masters_rec.to_material_detail_id;   -- ���Y�����ڍ�ID
--
    -- �����敪5:����(���Y�o�b�`No�Ȃ�)�̏ꍇ�͊����t���OON
    IF (ir_masters_rec.process_type = gv_actual_new) THEN
      lr_tran_row_in.completed_ind      := 1;                                      -- �����t���O
--
    -- 5:����(���Y�o�b�`No�Ȃ�)�ȊO�̏ꍇ�͊����t���OOFF
    ELSE
      lr_tran_row_in.completed_ind      := 0;                                      -- �����t���O
    END IF;
--
    -- ���b�Z�[�W������API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- ���b�g�����ǉ�API
    -- ======================================
    GME_API_PUB.INSERT_LINE_ALLOCATION(
          p_api_version      => GME_API_PUB.API_VERSION
        , p_validation_level => GME_API_PUB.MAX_ERRORS
        , p_init_msg_list    => FALSE
        , p_commit           => FALSE
        , p_tran_row         => lr_tran_row_in
        , p_lot_no           => NULL
        , p_sublot_no        => NULL
        , p_create_lot       => FALSE
        , p_ignore_shortage  => TRUE
        , p_scale_phantom    => FALSE
        , x_material_detail  => lr_material_detail
        , x_tran_row         => lr_tran_row_out
        , x_def_tran_row     => lr_def_tran_row
        , x_message_count    => ln_message_count
        , x_message_list     => lv_message_list
        , x_return_status    => lv_return_status
          );
--
    -- �o�̓��b�g�����ǉ������������łȂ��ꍇ
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- �G���[���b�Z�[�W���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_output_lot_ins);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    END IF;
--
    -- ======================================
    -- �ړ����b�g�ڍׂփf�[�^�o�^
    -- ======================================
    INSERT INTO xxinv_mov_lot_details(
      mov_lot_dtl_id           -- ���b�g�ڍ�ID
    , mov_line_id              -- ����ID
    , document_type_code       -- �����^�C�v
    , record_type_code         -- ���R�[�h�^�C�v
    , item_id                  -- OPM�i��ID
    , item_code                -- �i��
    , lot_id                   -- ���b�gID
    , lot_no                   -- ���b�gNo
    , actual_date              -- ���ѓ�
    , actual_quantity          -- ���ѐ���
    , created_by               -- �쐬��
    , creation_date            -- �쐬��
    , last_updated_by          -- �ŏI�X�V��
    , last_update_date         -- �ŏI�X�V��
    , last_update_login        -- �ŏI�X�V���O�C��
    , request_id               -- �v��ID
    , program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    , program_id               -- �R���J�����g�E�v���O����ID
    , program_update_date      -- �v���O�����X�V��
    )
    VALUES(
      xxinv_mov_lot_s1.NEXTVAL               -- ���b�g�ڍ�ID
    , ir_masters_rec.to_material_detail_id   -- ����ID
    , gv_doc_type_code_prod                  -- �����^�C�v
    , gv_rec_type_code_plan                  -- ���R�[�h�^�C�v
    , ir_masters_rec.to_item_id              -- OPM�i��ID
    , ir_masters_rec.to_item_no              -- �i��
    , ir_masters_rec.to_lot_id               -- ���b�gID
    , ir_masters_rec.lot_no                  -- ���b�gNo
    , NULL                                   -- ���ѓ�
-- 2009/01/15 H.Itou Mod Start �w�E2�Ή�
--    , ir_masters_rec.qty                     -- ���ѐ���
    , NVL(ir_masters_rec.qty, ir_masters_rec.trans_qty) -- ���ѐ���
-- 2009/01/15 H.Itou Mod End
    , FND_GLOBAL.USER_ID                     -- �쐬��
    , SYSDATE                                -- �쐬��
    , FND_GLOBAL.USER_ID                     -- �ŏI�X�V��
    , SYSDATE                                -- �ŏI�X�V��
    , FND_GLOBAL.LOGIN_ID                    -- �ŏI�X�V���O�C��
    , FND_GLOBAL.CONC_REQUEST_ID             -- �v��ID
    , FND_GLOBAL.PROG_APPL_ID                -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    , FND_GLOBAL.CONC_PROGRAM_ID             -- �R���J�����g�E�v���O����ID
    , SYSDATE                                -- �v���O�����X�V��
    );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_lot_ins;
--
  /**********************************************************************************
   * Procedure Name   : cmpt_batch
   * Description      : �o�b�`����(A-12)
   ***********************************************************************************/
  PROCEDURE cmpt_batch(
    ir_masters_rec  IN OUT NOCOPY masters_rec -- 1.�����Ώۃ��R�[�h
  , ov_errbuf       OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode      OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cmpt_batch'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_return_status VARCHAR2(2);     -- ���^�[���X�e�[�^�X
    ln_message_count NUMBER;          -- ���b�Z�[�W�J�E���g
    lv_message_list  VARCHAR2(200);   -- ���b�Z�[�W���X�g
    l_data           VARCHAR2(2000);
--
    -- *** ���[�J���E���R�[�h ***
    lr_out_batch_hrd gme_batch_header%ROWTYPE; -- ���Y�o�b�`�w�b�_(�o��)
    lt_unalloc_mtl   gme_api_pub.unallocated_materials_tab;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    gr_gme_batch_header.actual_start_date := ir_masters_rec.plan_start_date; -- 2.���ъJ�n��
    gr_gme_batch_header.actual_cmplt_date := ir_masters_rec.plan_start_date; -- 3.���яI����
    gr_gme_batch_header.batch_id          := ir_masters_rec.batch_id;        -- �o�b�`ID
--
    -- ���b�Z�[�W������API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- �o�b�`����API
    -- ======================================
    GME_API_PUB.CERTIFY_BATCH(
          p_api_version           => GME_API_PUB.API_VERSION
        , p_validation_level      => GME_API_PUB.MAX_ERRORS
        , p_init_msg_list         => FALSE
        , p_commit                => FALSE
        , x_message_count         => ln_message_count
        , x_message_list          => lv_message_list
        , x_return_status         => lv_return_status
        , p_del_incomplete_manual => TRUE
        , p_ignore_shortages      => TRUE
        , p_batch_header          => gr_gme_batch_header
        , x_batch_header          => lr_out_batch_hrd
        , x_unallocated_material  => lt_unalloc_mtl
          );
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_message_list ='||lv_message_list);
--
    -- �o�b�`���������������łȂ��ꍇ
    IF ( lv_return_status IN ( FND_API.g_ret_sts_error, FND_API.g_ret_sts_unexp_error ) ) THEN
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_cmpt_bat);
      -- ���ʊ֐���O�n���h��
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END cmpt_batch;
--
  /**********************************************************************************
   * Procedure Name   : close_batch
   * Description      : �o�b�`�N���[�Y(A-13)
   ***********************************************************************************/
  PROCEDURE close_batch(
    ir_masters_rec  IN OUT NOCOPY masters_rec -- 1.�����Ώۃ��R�[�h
  , ov_errbuf       OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode      OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_batch'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_return_status VARCHAR2(2);     -- ���^�[���X�e�[�^�X
    ln_message_count NUMBER;          -- ���b�Z�[�W�J�E���g
    lv_message_list  VARCHAR2(200);   -- ���b�Z�[�W���X�g
    l_data           VARCHAR2(2000);
--
    -- *** ���[�J���E���R�[�h ***
    lr_out_batch_hrd gme_batch_header%ROWTYPE; -- ���Y�o�b�`�w�b�_(�o��)
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    gr_gme_batch_header.batch_close_date  := ir_masters_rec.plan_start_date; -- 2.���ъJ�n��
    gr_gme_batch_header.batch_id          := ir_masters_rec.batch_id;        -- �o�b�`ID
--
    -- ���b�Z�[�W������API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- �o�b�`�N���[�YAPI
    -- ======================================
    GME_API_PUB.CLOSE_BATCH(
          p_api_version      => GME_API_PUB.API_VERSION
        , p_validation_level => GME_API_PUB.MAX_ERRORS
        , p_init_msg_list    => FALSE
        , p_commit           => FALSE
        , x_message_count    => ln_message_count
        , x_message_list     => lv_message_list
        , x_return_status    => lv_return_status
        , p_batch_header     => gr_gme_batch_header
        , x_batch_header     => lr_out_batch_hrd
          );
--
    -- �o�b�`�N���[�Y�����������łȂ��ꍇ
    IF ( lv_return_status IN ( FND_API.g_ret_sts_error, FND_API.g_ret_sts_unexp_error ) ) THEN
      -- �G���[���b�Z�[�W���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_close_bat);
      -- ���ʊ֐���O�n���h��
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END close_batch;
--
  /**********************************************************************************
   * Procedure Name   : save_batch
   * Description      : �o�b�`�ۑ�(A-14)
   ***********************************************************************************/
  PROCEDURE save_batch(
    ir_masters_rec  IN OUT NOCOPY masters_rec -- 1.�����Ώۃ��R�[�h
  , ov_errbuf       OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode      OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'save_batch'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_return_status VARCHAR2(2);     -- ���^�[���X�e�[�^�X
--
    -- *** ���[�J���E���R�[�h ***
    lr_in_batch_hdr  gme_batch_header%ROWTYPE;     -- ���Y�o�b�`�w�b�_(����)
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lr_in_batch_hdr.batch_id := ir_masters_rec.batch_id;     -- �o�b�`ID
--
    -- ���b�Z�[�W������API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- �o�b�`�ۑ�API
    -- ======================================
    GME_API_PUB.SAVE_BATCH(
          p_batch_header  => lr_in_batch_hdr
        , x_return_status => lv_return_status
        , p_commit        => FALSE
          );
--
    -- �o�b�`�ۑ������������łȂ��ꍇ
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- �G���[���b�Z�[�W���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_save_bat);
      -- ���ʊ֐���O�n���h��
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END save_batch;
--
  /**********************************************************************************
   * Procedure Name   : cancel_batch
   * Description      : �o�b�`���(A-15)
   ***********************************************************************************/
  PROCEDURE cancel_batch(
    ir_masters_rec  IN OUT NOCOPY masters_rec -- 1.�����Ώۃ��R�[�h
  , ov_errbuf       OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode      OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cancel_batch'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_return_status VARCHAR2(2);     -- ���^�[���X�e�[�^�X
    ln_message_count NUMBER;          -- ���b�Z�[�W�J�E���g
    lv_message_list  VARCHAR2(200);   -- ���b�Z�[�W���X�g
    l_data           VARCHAR2(2000);
--
    -- *** ���[�J���E���R�[�h ***
    lr_in_batch_hdr  gme_batch_header%ROWTYPE; -- ���Y�o�b�`�w�b�_(����)
    lr_out_batch_hrd gme_batch_header%ROWTYPE; -- ���Y�o�b�`�w�b�_(�o��)
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lr_in_batch_hdr.batch_id := ir_masters_rec.batch_id; -- �o�b�`ID
--
    -- ���b�Z�[�W������API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- �o�b�`���API
    -- ======================================
    -- �o�b�`����֐������s
    GME_API_PUB.CANCEL_BATCH(
          p_api_version      =>  GME_API_PUB.API_VERSION
        , p_validation_level =>  GME_API_PUB.MAX_ERRORS
        , p_init_msg_list    =>  FALSE
        , p_commit           =>  FALSE
        , x_message_count    =>  ln_message_count
        , x_message_list     =>  lv_message_list
        , x_return_status    =>  lv_return_status
        , p_batch_header     =>  lr_in_batch_hdr
        , x_batch_header     =>  lr_out_batch_hrd
          );
--
    -- �o�b�`��������������łȂ��ꍇ
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- �G���[���b�Z�[�W���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_cancel_bat);
      -- ���ʊ֐���O�n���h��
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END cancel_batch;
--
  /**********************************************************************************
   * Procedure Name   : reschedule_batch
   * Description      : �o�b�`�ăX�P�W���[��(A-16)
   ***********************************************************************************/
  PROCEDURE reschedule_batch(
    ir_masters_rec  IN OUT NOCOPY masters_rec -- 1.�����Ώۃ��R�[�h
  , ov_errbuf       OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode      OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'reschedule_batch'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_return_status VARCHAR2(2);     -- ���^�[���X�e�[�^�X
    ln_message_count NUMBER;          -- ���b�Z�[�W�J�E���g
    lv_message_list  VARCHAR2(200);   -- ���b�Z�[�W���X�g
    l_data           VARCHAR2(2000);
--
    -- *** ���[�J���E���R�[�h ***
    lr_in_batch_hdr  gme_batch_header%ROWTYPE; -- ���Y�o�b�`�w�b�_(����)
    lr_out_batch_hrd gme_batch_header%ROWTYPE; -- ���Y�o�b�`�w�b�_(�o��)
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lr_in_batch_hdr.batch_id        := ir_masters_rec.batch_id;     -- �o�b�`ID
    lr_in_batch_hdr.plan_start_date := ir_masters_rec.item_sysdate; -- ���Y�\��J�n��
    lr_in_batch_hdr.plan_cmplt_date := ir_masters_rec.item_sysdate; -- ���Y�\�芮����
--
    -- ���b�Z�[�W������API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- �o�b�`�ăX�P�W���[��API
    -- ======================================
    -- �o�b�`�ăX�P�W���[���֐������s
    GME_API_PUB.RESCHEDULE_BATCH(
          p_api_version         =>  GME_API_PUB.API_VERSION
        , p_validation_level    =>  GME_API_PUB.MAX_ERRORS
        , p_init_msg_list       =>  FALSE
        , p_commit              =>  FALSE
        , x_message_count       =>  ln_message_count
        , x_message_list        =>  lv_message_list
        , x_return_status       =>  lv_return_status
        , p_batch_header        =>  lr_in_batch_hdr
        , p_use_shop_cal        =>  NULL
        , p_contiguity_override =>  NULL
        , x_batch_header        =>  lr_out_batch_hrd
          );
--
    -- �o�b�`�ăX�P�W���[�������������łȂ��ꍇ
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- �G���[���b�Z�[�W���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_resche__bat);
      -- ���ʊ֐���O�n���h��
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END reschedule_batch;
--
  /**********************************************************************************
   * Procedure Name   : input_lot_upd
   * Description      : ���̓��b�g�����X�V(A-17)
   ***********************************************************************************/
  PROCEDURE input_lot_upd(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.�����Ώۃ��R�[�h
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'input_lot_upd'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_return_status    VARCHAR2(2);     -- ���^�[���X�e�[�^�X
    ln_message_count    NUMBER;          -- ���b�Z�[�W�J�E���g
    lv_msg_date         VARCHAR2(10000); -- ���b�Z�[�W
    lv_message_list     VARCHAR2(200);   -- ���b�Z�[�W���X�g
    l_data           VARCHAR2(2000);
--
    -- *** ���[�J���E���R�[�h ***
    lr_material_detail  gme_material_details%ROWTYPE;
    lr_tran_row_in      gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out     gme_inventory_txns_gtmp%ROWTYPE;
    lr_def_tran_row     gme_inventory_txns_gtmp%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lr_tran_row_in.trans_id      := ir_masters_rec.from_trans_id;  -- �g�����U�N�V����ID
-- 2009/01/15 H.Itou Mod Start �w�E2�Ή�
--    lr_tran_row_in.trans_date    := ir_masters_rec.item_sysdate;   -- ���ѓ�
--    lr_tran_row_in.trans_qty     := ir_masters_rec.qty;            -- ����
    lr_tran_row_in.trans_date    := NVL(ir_masters_rec.item_sysdate, ir_masters_rec.plan_start_date);   -- ���ѓ�
    lr_tran_row_in.trans_qty     := NVL(ir_masters_rec.qty, ir_masters_rec.trans_qty);  -- ����
-- 2009/01/15 H.Itou Mod End
    lr_tran_row_in.completed_ind := 0;
--
    -- ���b�Z�[�W������API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- ���b�g�����X�VAPI
    -- ======================================
    GME_API_PUB.UPDATE_LINE_ALLOCATION(
          p_api_version      => GME_API_PUB.API_VERSION
        , p_validation_level => GME_API_PUB.MAX_ERRORS
        , p_init_msg_list    => FALSE
        , p_commit           => FALSE
        , p_tran_row         => lr_tran_row_in
        , p_lot_no           => NULL
        , p_sublot_no        => NULL
        , p_create_lot       => FALSE
        , p_ignore_shortage  => TRUE
        , p_scale_phantom    => FALSE
        , x_material_detail  => lr_material_detail
        , x_tran_row         => lr_tran_row_out
        , x_def_tran_row     => lr_def_tran_row
        , x_message_count    => ln_message_count
        , x_message_list     => lv_message_list
        , x_return_status    => lv_return_status
          );
--
    -- ���̓��b�g�����X�V�����������łȂ��ꍇ
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- �G���[���b�Z�[�W���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_input_lot_upd);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    END IF;
--
    -- ======================================
    -- �ړ����b�g�ڍׂփf�[�^�X�V
    -- ======================================
    UPDATE xxinv_mov_lot_details xmlv                                         -- �ړ����b�g�ڍ�
-- 2009/01/15 H.Itou Mod Start �w�E2�Ή�
--    SET    xmlv.actual_quantity             = ir_masters_rec.qty              -- ����
    SET    xmlv.actual_quantity             = NVL(ir_masters_rec.qty, ir_masters_rec.trans_qty) -- ����
-- 2009/01/15 H.Itou Mod End
         , xmlv.lot_id                      = ir_masters_rec.from_lot_id      -- ���b�gID(�U�֌�)
         , xmlv.lot_no                      = ir_masters_rec.lot_no           -- ���b�gNo
         , xmlv.last_updated_by             = FND_GLOBAL.USER_ID              -- �X�V���[�U�[ID
         , xmlv.last_update_date            = SYSDATE                         -- �ŏI�X�V��
         , xmlv.last_update_login           = FND_GLOBAL.LOGIN_ID             -- �X�V���O�C��ID
         , xmlv.request_id                  = FND_GLOBAL.CONC_REQUEST_ID      -- �v��ID
         , xmlv.program_application_id      = FND_GLOBAL.PROG_APPL_ID         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         , xmlv.program_id                  = FND_GLOBAL.CONC_PROGRAM_ID      -- �R���J�����g�E�v���O����ID
         , xmlv.program_update_date         = SYSDATE                         -- �v���O�����X�V��
    WHERE  xmlv.mov_line_id        = ir_masters_rec.from_material_detail_id   -- ����ID(�U�֌�)
    AND    xmlv.item_id            = ir_masters_rec.from_item_id              -- �i��ID(�U�֌�)
    AND    xmlv.document_type_code = gv_doc_type_code_prod                    -- �����^�C�v�F���Y
    AND    xmlv.record_type_code   = gv_rec_type_code_plan                    -- ���R�[�h�^�C�v�F�w��
    ;
--
    -- ======================================
    -- ���Y�����ڍ׃A�h�I���փf�[�^�X�V
    -- ======================================
    UPDATE xxwip_material_detail xmd                                         -- ���Y�����ڍ׃A�h�I��
-- 2009/01/15 H.Itou Mod Start �w�E2�Ή�
--    SET    xmd.instructions_qty            = ir_masters_rec.qty              -- ����
    SET    xmd.instructions_qty            = NVL(ir_masters_rec.qty, ir_masters_rec.trans_qty) -- ����
-- 2009/01/15 H.Itou Mod End
         , xmd.lot_id                      = ir_masters_rec.from_lot_id      -- ���b�gID(�U�֐�)
         , xmd.last_updated_by             = FND_GLOBAL.USER_ID              -- �X�V���[�U�[ID
         , xmd.last_update_date            = SYSDATE                         -- �ŏI�X�V��
         , xmd.last_update_login           = FND_GLOBAL.LOGIN_ID             -- �X�V���O�C��ID
         , xmd.request_id                  = FND_GLOBAL.CONC_REQUEST_ID      -- �v��ID
         , xmd.program_application_id      = FND_GLOBAL.PROG_APPL_ID         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         , xmd.program_id                  = FND_GLOBAL.CONC_PROGRAM_ID      -- �R���J�����g�E�v���O����ID
         , xmd.program_update_date         = SYSDATE                         -- �v���O�����X�V��
    WHERE  xmd.batch_id           = ir_masters_rec.batch_id                  -- �o�b�`ID
    AND    xmd.material_detail_id = ir_masters_rec.from_material_detail_id   -- ���Y�����ڍ�ID(�U�֌�)
    AND    xmd.item_id            = ir_masters_rec.from_item_id              -- �i��ID(�U�֌�)
    AND    xmd.plan_type          = gv_plan_type_4                           -- �\��敪
    ;
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END input_lot_upd;
--
  /**********************************************************************************
   * Procedure Name   : output_lot_upd
   * Description      : �o�̓��b�g�����X�V(A-18)
   ***********************************************************************************/
  PROCEDURE output_lot_upd(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.�����Ώۃ��R�[�h
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_lot_upd'; -- �v���O������
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
    lv_return_status VARCHAR2(2);     -- ���^�[���X�e�[�^�X
    ln_message_count NUMBER;          -- ���b�Z�[�W�J�E���g
    lv_msg_date      VARCHAR2(10000); -- ���b�Z�[�W
    lv_message_list  VARCHAR2(200);   -- ���b�Z�[�W���X�g
    l_data           VARCHAR2(2000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_material_detail  gme_material_details%ROWTYPE;
    lr_tran_row_in      gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out     gme_inventory_txns_gtmp%ROWTYPE;
    lr_def_tran_row     gme_inventory_txns_gtmp%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lr_tran_row_in.trans_id      := ir_masters_rec.to_trans_id;    -- �g�����U�N�V����ID
-- 2009/01/15 H.Itou Mod Start �w�E2�Ή�
--    lr_tran_row_in.trans_date    := ir_masters_rec.item_sysdate;   -- ���ѓ�
--    lr_tran_row_in.trans_qty     := ir_masters_rec.qty;            -- ����
    lr_tran_row_in.trans_date    := NVL(ir_masters_rec.item_sysdate, ir_masters_rec.plan_start_date);   -- ���ѓ�
    lr_tran_row_in.trans_qty     := NVL(ir_masters_rec.qty, ir_masters_rec.trans_qty);  -- ����
-- 2009/01/15 H.Itou Mod End
    lr_tran_row_in.completed_ind := 0;
--
    -- ���b�Z�[�W������API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- ���b�g�����X�VAPI
    -- ======================================
    GME_API_PUB.UPDATE_LINE_ALLOCATION(
          p_api_version      => GME_API_PUB.API_VERSION
        , p_validation_level => GME_API_PUB.MAX_ERRORS
        , p_init_msg_list    => FALSE
        , p_commit           => FALSE
        , p_tran_row         => lr_tran_row_in
        , p_lot_no           => ir_masters_rec.lot_no
        , p_sublot_no        => NULL
        , p_create_lot       => FALSE
        , p_ignore_shortage  => TRUE
        , p_scale_phantom    => FALSE
        , x_material_detail  => lr_material_detail
        , x_tran_row         => lr_tran_row_out
        , x_def_tran_row     => lr_def_tran_row
        , x_message_count    => ln_message_count
        , x_message_list     => lv_message_list
        , x_return_status    => lv_return_status
          );
--
    -- �o�̓��b�g�����X�V�����������łȂ��ꍇ
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- �G���[���b�Z�[�W���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_output_lot_upd);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    END IF;
--
    -- ======================================
    -- �ړ����b�g�ڍׂփf�[�^�X�V
    -- ======================================
    UPDATE xxinv_mov_lot_details xmlv                                         -- �ړ����b�g�ڍ�
-- 2009/01/15 H.Itou Mod Start �w�E2�Ή�
--    SET    xmlv.actual_quantity             = ir_masters_rec.qty              -- ����
    SET    xmlv.actual_quantity             = NVL(ir_masters_rec.qty, ir_masters_rec.trans_qty) -- ����
-- 2009/01/15 H.Itou Mod End
         , xmlv.lot_id                      = ir_masters_rec.to_lot_id        -- ���b�gID(�U�֌�)
         , xmlv.lot_no                      = ir_masters_rec.lot_no           -- ���b�gNo
         , xmlv.last_updated_by             = FND_GLOBAL.USER_ID              -- �X�V���[�U�[ID
         , xmlv.last_update_date            = SYSDATE                         -- �ŏI�X�V��
         , xmlv.last_update_login           = FND_GLOBAL.LOGIN_ID             -- �X�V���O�C��ID
         , xmlv.request_id                  = FND_GLOBAL.CONC_REQUEST_ID      -- �v��ID
         , xmlv.program_application_id      = FND_GLOBAL.PROG_APPL_ID         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         , xmlv.program_id                  = FND_GLOBAL.CONC_PROGRAM_ID      -- �R���J�����g�E�v���O����ID
         , xmlv.program_update_date         = SYSDATE                         -- �v���O�����X�V��
    WHERE  xmlv.mov_line_id        = ir_masters_rec.to_material_detail_id     -- ����ID(�U�֐�)
    AND    xmlv.item_id            = ir_masters_rec.to_item_id                -- �i��ID(�U�֐�)
    AND    xmlv.document_type_code = gv_doc_type_code_prod                    -- �����^�C�v�F���Y
    AND    xmlv.record_type_code   = gv_rec_type_code_plan                    -- ���R�[�h�^�C�v�F�w��
    ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_lot_upd;
--
  /**********************************************************************************
   * Procedure Name   : input_lot_del
   * Description      : ���̓��b�g�����폜(A-19)
   ***********************************************************************************/
  PROCEDURE input_lot_del(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.�����Ώۃ��R�[�h
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'input_lot_del'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_return_status    VARCHAR2(2);     -- ���^�[���X�e�[�^�X
    ln_message_count    NUMBER;          -- ���b�Z�[�W�J�E���g
    lv_msg_date         VARCHAR2(10000); -- ���b�Z�[�W
    lv_message_list     VARCHAR2(200);   -- ���b�Z�[�W���X�g
    l_data              VARCHAR2(2000);
--
    -- *** ���[�J���E���R�[�h ***
    lr_material_detail_out  gme_material_details   %ROWTYPE;
    lr_tran_row_out         gme_inventory_txns_gtmp%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���b�Z�[�W������API
    FND_MSG_PUB.INITIALIZE();
--
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ir_masters_rec.from_trans_id:'||ir_masters_rec.from_trans_id);
    -- ======================================
    -- ���b�g�����폜API
    -- ======================================
    GME_API_PUB.DELETE_LINE_ALLOCATION (
      p_api_version        => GME_API_PUB.API_VERSION          -- IN         NUMBER := gme_api_pub.api_version
     ,p_validation_level   => GME_API_PUB.MAX_ERRORS           -- IN         NUMBER := gme_api_pub.max_errors
     ,p_init_msg_list      => FALSE                            -- IN         BOOLEAN := FALSE
     ,p_commit             => FALSE                            -- IN         BOOLEAN := FALSE
     ,p_trans_id           => ir_masters_rec.from_trans_id     -- IN         NUMBER
     ,p_scale_phantom      => FALSE                            -- IN         BOOLEAN DEFAULT FALSE
     ,x_material_detail    => lr_material_detail_out           -- OUT NOCOPY gme_material_details%ROWTYPE
     ,x_def_tran_row       => lr_tran_row_out                  -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE
     ,x_message_count      => ln_message_count                 -- OUT NOCOPY NUMBER
     ,x_message_list       => lv_message_list                  -- OUT NOCOPY VARCHAR2
     ,x_return_status      => lv_return_status                 -- OUT NOCOPY VARCHAR2
    );
--
    -- ���̓��b�g�����폜�����������łȂ��ꍇ
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- �G���[���b�Z�[�W���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_input_lot_del);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    END IF;
--
    -- ======================================
    -- �ړ����b�g�ڍ׃f�[�^�폜
    -- ======================================
    DELETE xxinv_mov_lot_details xmld                                          -- �ړ����b�g�ڍ׃A�h�I��
    WHERE  xmld.mov_line_id        = ir_masters_rec.from_material_detail_id    -- ���Y�����ڍ�ID(�U�֌�)
    AND    xmld.item_id            = ir_masters_rec.from_item_id               -- �i��ID(�U�֌�)
    AND    xmld.lot_id             = ir_masters_rec.from_lot_id                -- ���b�gID(�U�֌�)
    AND    xmld.document_type_code = gv_doc_type_code_prod                     -- �����^�C�v
    AND    xmld.record_type_code   = gv_rec_type_code_plan                     -- ���R�[�h�^�C�v
    ;
--
    -- ======================================
    -- ���Y�����ڍ׃A�h�I���f�[�^�폜
    -- ======================================
    DELETE xxwip_material_detail xmd                                         -- ���Y�����ڍ׃A�h�I��
    WHERE  xmd.batch_id           = ir_masters_rec.batch_id                  -- �o�b�`ID
    AND    xmd.material_detail_id = ir_masters_rec.from_material_detail_id   -- ���Y�����ڍ�ID(�U�֌�)
    AND    xmd.item_id            = ir_masters_rec.from_item_id              -- �i��ID(�U�֌�)
    AND    xmd.lot_id             = ir_masters_rec.from_lot_id               -- ���b�gID(�U�֌�)
    ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END input_lot_del;
--
  /**********************************************************************************
   * Procedure Name   : output_lot_del
   * Description      : �o�̓��b�g�����폜(A-20)
   ***********************************************************************************/
  PROCEDURE output_lot_del(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.�����Ώۃ��R�[�h
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_lot_del'; -- �v���O������
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
    lv_return_status VARCHAR2(2);     -- ���^�[���X�e�[�^�X
    ln_message_count NUMBER;          -- ���b�Z�[�W�J�E���g
    lv_msg_date      VARCHAR2(10000); -- ���b�Z�[�W
    lv_message_list  VARCHAR2(200);   -- ���b�Z�[�W���X�g
    l_data           VARCHAR2(2000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_material_detail_out  gme_material_details   %ROWTYPE;
    lr_tran_row_out         gme_inventory_txns_gtmp%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���b�Z�[�W������API
    FND_MSG_PUB.INITIALIZE();
--
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ir_masters_rec.to_trans_id:'||ir_masters_rec.to_trans_id);
    -- ======================================
    -- ���b�g�����폜API
    -- ======================================
    GME_API_PUB.DELETE_LINE_ALLOCATION (
      p_api_version        => GME_API_PUB.API_VERSION          -- IN         NUMBER := gme_api_pub.api_version
     ,p_validation_level   => GME_API_PUB.MAX_ERRORS           -- IN         NUMBER := gme_api_pub.max_errors
     ,p_init_msg_list      => FALSE                            -- IN         BOOLEAN := FALSE
     ,p_commit             => FALSE                            -- IN         BOOLEAN := FALSE
     ,p_trans_id           => ir_masters_rec.to_trans_id       -- IN         NUMBER
     ,p_scale_phantom      => FALSE                            -- IN         BOOLEAN DEFAULT FALSE
     ,x_material_detail    => lr_material_detail_out           -- OUT NOCOPY gme_material_details%ROWTYPE
     ,x_def_tran_row       => lr_tran_row_out                  -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE
     ,x_message_count      => ln_message_count                 -- OUT NOCOPY NUMBER
     ,x_message_list       => lv_message_list                  -- OUT NOCOPY VARCHAR2
     ,x_return_status      => lv_return_status                 -- OUT NOCOPY VARCHAR2
    );
--
    -- �o�̓��b�g�����ǉ������������łȂ��ꍇ
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- �G���[���b�Z�[�W���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_output_lot_del);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    END IF;
--
    -- ======================================
    -- �ړ����b�g�ڍ׃f�[�^�폜
    -- ======================================
    DELETE xxinv_mov_lot_details xmld                                          -- �ړ����b�g�ڍ׃A�h�I��
    WHERE  xmld.mov_line_id        = ir_masters_rec.to_material_detail_id      -- ���Y�����ڍ�ID(�U�֐�)
    AND    xmld.item_id            = ir_masters_rec.to_item_id                 -- �i��ID(�U�֐�)
    AND    xmld.lot_id             = ir_masters_rec.to_lot_id                  -- ���b�gID(�U�֐�)
    AND    xmld.document_type_code = gv_doc_type_code_prod                     -- �����^�C�v
    AND    xmld.record_type_code   = gv_rec_type_code_plan                     -- ���R�[�h�^�C�v
    ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_lot_del;
--
  /**********************************************************************************
   * Procedure Name   : release_batch
   * Description      : �����[�X�o�b�`(A-33)
   ***********************************************************************************/
  PROCEDURE release_batch(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.�����Ώۃ��R�[�h
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'release_batch'; -- �v���O������
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
    lv_return_status VARCHAR2(2);     -- ���^�[���X�e�[�^�X
    ln_message_count NUMBER;          -- ���b�Z�[�W�J�E���g
    lv_msg_date      VARCHAR2(10000); -- ���b�Z�[�W
    lv_message_list  VARCHAR2(200);   -- ���b�Z�[�W���X�g
    l_data           VARCHAR2(2000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_material_detail  gme_material_details%ROWTYPE;
    lr_tran_row_in      gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out     gme_inventory_txns_gtmp%ROWTYPE;
    lr_def_tran_row     gme_inventory_txns_gtmp%ROWTYPE;
    lr_gme_batch_header           gme_batch_header%ROWTYPE;              --
    lr_gme_batch_header_temp      gme_batch_header%ROWTYPE;              --
    lr_unallocated_materials      GME_API_PUB.UNALLOCATED_MATERIALS_TAB; --
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
      lr_gme_batch_header.batch_id          := ir_masters_rec.batch_id;
      lr_gme_batch_header.actual_start_date := ir_masters_rec.plan_start_date;
--
    -- ���b�Z�[�W������API
    FND_MSG_PUB.INITIALIZE();
--
      -- =========================================
      -- ���Y�o�b�`�����[�X
      -- =========================================
      GME_API_PUB.RELEASE_BATCH(
        p_api_version                   =>  GME_API_PUB.API_VERSION
      , p_validation_level              =>  GME_API_PUB.MAX_ERRORS
      , p_init_msg_list                 =>  FALSE
      , p_commit                        =>  FALSE
      , x_message_count                 =>  ln_message_count
      , x_message_list                  =>  lv_message_list
      , x_return_status                 =>  lv_return_status
      , p_batch_header                  =>  lr_gme_batch_header
      , x_batch_header                  =>  lr_gme_batch_header_temp
      , p_ignore_shortages              =>  FALSE
      , p_consume_avail_plain_item      =>  FALSE
      , x_unallocated_material          =>  lr_unallocated_materials
      , p_ignore_unalloc                =>  TRUE
      );
--
    -- �o�̓��b�g�����X�V�����������łȂ��ꍇ
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- �G���[���b�Z�[�W���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_release_batch);
      -- ���ʊ֐���O�n���h��
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END release_batch;
--
  /**********************************************************************************
   * Procedure Name   : chk_and_ins_formula
   * Description      : �t�H�[�~�����L���`�F�b�N �o�^����(A-28)
   ***********************************************************************************/
  PROCEDURE chk_and_ins_formula(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.�����Ώۃ��R�[�h
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_and_ins_formula'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �t�H�[�~�����L���`�F�b�N(A-3)
    -- ===============================
    chk_formula(ir_masters_rec  -- 1.�`�F�b�N�Ώۃ��R�[�h
              , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
              , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
              , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt;
--
    -- �t�H�[�~���������݂��Ȃ��ꍇ
    ELSIF ( NOT(ir_masters_rec.is_info_flg) ) THEN
--
      -- ===============================
      -- �t�H�[�~�����o�^(A-4)
      -- ===============================
      ins_formula(ir_masters_rec  -- 1.�����Ώۃ��R�[�h
                , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_and_ins_formula;
--
  /**********************************************************************************
   * Procedure Name   : chk_and_ins_recipe
   * Description      : ���V�s�L���`�F�b�N �o�^����(A-29)
   ***********************************************************************************/
  PROCEDURE chk_and_ins_recipe(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.�����Ώۃ��R�[�h
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_and_ins_recipe'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- ���V�s�L���`�F�b�N(A-5)
    -- ===============================
    chk_recipe(ir_masters_rec
             , lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
             , lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
             , lv_errmsg);-- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- �G���[�̏ꍇ
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt;
--
    -- ���V�s�����݂��Ȃ��ꍇ
    ELSIF ( NOT(ir_masters_rec.is_info_flg) ) THEN
      -- ===============================
      -- ���V�s�o�^(A-6)
      -- ===============================
      ins_recipe(ir_masters_rec
               , lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
               , lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
               , lv_errmsg);-- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_and_ins_recipe;
--
  /**********************************************************************************
   * Procedure Name   : chk_and_ins_to_lot
   * Description      : �U�֐惍�b�g�L���`�F�b�N �o�^����(A-30)
   ***********************************************************************************/
  PROCEDURE chk_and_ins_to_lot(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.�����Ώۃ��R�[�h
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_and_ins_to_lot'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- ���b�g�L���`�F�b�N(A-7)
    -- ===============================
    chk_lot(ir_masters_rec             -- 1.�`�F�b�N�Ώۃ��R�[�h
          , ir_masters_rec.lot_no      -- 2.���b�gNo
          , ir_masters_rec.to_item_id  -- 3.�i��ID(�U�֐�)
          , ir_masters_rec.to_lot_id   -- 4.���b�gID(�U�֌�)
          , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
          , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
          , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt;
--
    -- ���b�g�����݂��Ȃ��ꍇ
    ELSIF ( NOT(ir_masters_rec.is_info_flg) ) THEN
--
      -- ===============================
      -- ���b�g�쐬(A-8)
      -- ===============================
      create_lot(ir_masters_rec  -- 1.�����Ώۃ��R�[�h
               , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
               , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
               , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_and_ins_to_lot;
--
  /**********************************************************************************
   * Procedure Name   : input_lot_upd_ind
   * Description      : ���̓��b�g�����X�V(����)(A-31)
   ***********************************************************************************/
  PROCEDURE input_lot_upd_ind(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.�����Ώۃ��R�[�h
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'input_lot_upd_ind'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_return_status    VARCHAR2(2);     -- ���^�[���X�e�[�^�X
    ln_message_count    NUMBER;          -- ���b�Z�[�W�J�E���g
    lv_msg_date         VARCHAR2(10000); -- ���b�Z�[�W
    lv_message_list     VARCHAR2(200);   -- ���b�Z�[�W���X�g
    l_data           VARCHAR2(2000);
--
    -- *** ���[�J���E���R�[�h ***
    lr_material_detail  gme_material_details%ROWTYPE;
    lr_tran_row_in      gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out     gme_inventory_txns_gtmp%ROWTYPE;
    lr_def_tran_row     gme_inventory_txns_gtmp%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lr_tran_row_in.trans_id      := ir_masters_rec.from_trans_id;  -- �g�����U�N�V����ID
    lr_tran_row_in.completed_ind := 1; -- ����
--
    -- ���b�Z�[�W������API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- ���b�g�����X�VAPI
    -- ======================================
    GME_API_PUB.UPDATE_LINE_ALLOCATION(
          p_api_version      => GME_API_PUB.API_VERSION
        , p_validation_level => GME_API_PUB.MAX_ERRORS
        , p_init_msg_list    => FALSE
        , p_commit           => FALSE
        , p_tran_row         => lr_tran_row_in
        , p_lot_no           => NULL
        , p_sublot_no        => NULL
        , p_create_lot       => FALSE
        , p_ignore_shortage  => TRUE
        , p_scale_phantom    => FALSE
        , x_material_detail  => lr_material_detail
        , x_tran_row         => lr_tran_row_out
        , x_def_tran_row     => lr_def_tran_row
        , x_message_count    => ln_message_count
        , x_message_list     => lv_message_list
        , x_return_status    => lv_return_status
          );
--
    -- ���̓��b�g�����X�V�����������łȂ��ꍇ
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- �G���[���b�Z�[�W���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_input_lot_upd_ind);
      -- ���ʊ֐���O�n���h��
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END input_lot_upd_ind;
--
  /**********************************************************************************
   * Procedure Name   : output_lot_upd_ind
   * Description      : �o�̓��b�g�����X�V(����)(A-32)
   ***********************************************************************************/
  PROCEDURE output_lot_upd_ind(
    ir_masters_rec  IN OUT NOCOPY masters_rec  -- 1.�����Ώۃ��R�[�h
  , ov_errbuf       OUT    NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode      OUT    NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_lot_upd_ind'; -- �v���O������
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
    lv_return_status VARCHAR2(2);     -- ���^�[���X�e�[�^�X
    ln_message_count NUMBER;          -- ���b�Z�[�W�J�E���g
    lv_msg_date      VARCHAR2(10000); -- ���b�Z�[�W
    lv_message_list  VARCHAR2(200);   -- ���b�Z�[�W���X�g
    l_data           VARCHAR2(2000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_material_detail  gme_material_details%ROWTYPE;
    lr_tran_row_in      gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out     gme_inventory_txns_gtmp%ROWTYPE;
    lr_def_tran_row     gme_inventory_txns_gtmp%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lr_tran_row_in.trans_id      := ir_masters_rec.to_trans_id;    -- �g�����U�N�V����ID
    lr_tran_row_in.completed_ind := 1; -- ����
--
    -- ���b�Z�[�W������API
    FND_MSG_PUB.INITIALIZE();
--
    -- ======================================
    -- ���b�g�����X�VAPI
    -- ======================================
    GME_API_PUB.UPDATE_LINE_ALLOCATION(
          p_api_version      => GME_API_PUB.API_VERSION
        , p_validation_level => GME_API_PUB.MAX_ERRORS
        , p_init_msg_list    => FALSE
        , p_commit           => FALSE
        , p_tran_row         => lr_tran_row_in
        , p_lot_no           => ir_masters_rec.lot_no
        , p_sublot_no        => NULL
        , p_create_lot       => FALSE
        , p_ignore_shortage  => TRUE
        , p_scale_phantom    => FALSE
        , x_material_detail  => lr_material_detail
        , x_tran_row         => lr_tran_row_out
        , x_def_tran_row     => lr_def_tran_row
        , x_message_count    => ln_message_count
        , x_message_list     => lv_message_list
        , x_return_status    => lv_return_status
          );
--
    -- �o�̓��b�g�����X�V�����������łȂ��ꍇ
    IF ( lv_return_status <> gv_ret_sts_success ) THEN
      -- �G���[���b�Z�[�W���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
--
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_52a_00
                                          , gv_tkn_api_name
                                          , gv_tkn_output_lot_upd_ind);
      -- ���ʊ֐���O�n���h��
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_lot_upd_ind;
--
  /**********************************************************************************
   * Procedure Name   : chk_future_date
   * Description      : �������`�F�b�N(A-34)
   ***********************************************************************************/
  PROCEDURE chk_future_date(
    id_date        IN            DATE        -- �`�F�b�N���t
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_future_date'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���t���������̏ꍇ
    IF ( TRUNC(SYSDATE) < TRUNC(id_date) ) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_xxinv_10066
                                          , gv_tkn_ship_date
                                          , gv_tkn_item_date);
      -- ���ʊ֐���O�n���h��
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_future_date;
--
-- 2009/01/15 H.Itou Add Start �w�E2,7�Ή�
  /**********************************************************************************
   * Procedure Name   : chk_qty_short_plan
   * Description      : �����\�݌ɕs���`�F�b�N(�\��)(A-35)
   ***********************************************************************************/
  PROCEDURE chk_qty_short_plan(
    ir_masters_rec    IN masters_rec                        -- 1.�`�F�b�N�Ώۃ��R�[�h
  , id_standard_date  IN DATE                               -- 2.�L�����t
  , in_before_qty     IN NUMBER                             -- 3.�X�V�O����
  , in_after_qty      IN NUMBER                             -- 4.�o�^����
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_qty_short_plan'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    ln_can_enc_qty     NUMBER;  -- �����\��
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �L�����x�[�X�����\��
    ln_can_enc_qty := xxcmn_common_pkg.get_can_enc_in_time_qty(
                         ir_masters_rec.inventory_location_id  -- 1.�ۊǑq��ID
                       , ir_masters_rec.to_item_id             -- 2.�i��ID
                       , ir_masters_rec.to_lot_id              -- 3.���b�gID
                       , id_standard_date);                    -- 4.�L�����t
--
    -- �����\�����s������ꍇ
    IF ( ln_can_enc_qty - in_before_qty + in_after_qty < 0) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_xxinv_10184
                                          , gv_tkn_location      , ir_masters_rec.inventory_location_code
                                          , gv_tkn_item          , ir_masters_rec.to_item_no
                                          , gv_tkn_lot           , ir_masters_rec.lot_no
                                          , gv_tkn_standard_date , TO_CHAR(id_standard_date, gv_yyyymmdd));
      -- ���ʊ֐���O�n���h��
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_qty_short_plan;
--
  /**********************************************************************************
   * Procedure Name   : chk_location
   * Description      : �ۊǑq�Ƀ`�F�b�N(A-36)
   ***********************************************************************************/
  PROCEDURE chk_location(
    it_location_code_01   IN xxcmn_item_locations_v.segment1%TYPE -- 1.�ۊǑq��01
  , it_location_code_02   IN xxcmn_item_locations_v.segment1%TYPE -- 2.�ۊǑq��02
  , ov_errbuf      OUT    NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode     OUT    NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg      OUT    NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_location'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
    -- �ۊǑq�ɂ��قȂ�ꍇ�A�G���[
    IF (it_location_code_01 <> it_location_code_02) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                          , gv_msg_xxinv_10183);
      RAISE global_api_expt;
    END IF;
--
--###########################  �Œ蕔 END   ############################
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_location;
-- 2009/01/15 H.Itou Add End
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_process_type   IN          VARCHAR2 --  1.�����敪(1:�\��,2:�\�����,3:�\����,4:����)
  , iv_plan_batch_id  IN          VARCHAR2 --  2.�o�b�`ID(�\��)
  , iv_inv_loc_code   IN          VARCHAR2 --  3.�ۊǑq�ɃR�[�h
  , iv_from_item_no   IN          VARCHAR2 --  4.�U�֌��i��No
  , iv_lot_no         IN          VARCHAR2 --  5.�U�֌����b�gNo
  , iv_to_item_no     IN          VARCHAR2 --  6.�U�֐�i��No
  , iv_quantity       IN          VARCHAR2 --  7.����
  , id_sysdate        IN          DATE     --  8.�i�ڐU�֓�
  , iv_remarks        IN          VARCHAR2 --  9.�E�v
  , iv_item_chg_aim   IN          VARCHAR2 -- 10.�i�ڐU�֖ړI
  , ov_errbuf         OUT  NOCOPY VARCHAR2 --  �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode        OUT  NOCOPY VARCHAR2 --  ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg         OUT  NOCOPY VARCHAR2)--  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lr_masters_rec masters_rec;                   -- �����Ώۃf�[�^�i�[���R�[�h
--
    lv_normal_msg VARCHAR2(1000);                 -- ����I�������b�Z�[�W�i�[�ϐ�
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
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
    -- �O���[�o�����R�[�h�ϐ��Ƀp�����[�^���Z�b�g
    lr_masters_rec.process_type            := iv_process_type;        -- �����敪
    lr_masters_rec.plan_batch_id           := iv_plan_batch_id;       -- �o�b�`ID(�\��)
    lr_masters_rec.inventory_location_code := iv_inv_loc_code;        -- �ۊǑq�ɃR�[�h
    lr_masters_rec.from_item_no            := iv_from_item_no;        -- �U�֌��i��No
    lr_masters_rec.lot_no                  := iv_lot_no;              -- ���b�gNo
    lr_masters_rec.to_item_no              := iv_to_item_no;          -- �U�֐�i��No
    lr_masters_rec.qty                     := TO_NUMBER(iv_quantity); -- ����
    lr_masters_rec.item_sysdate            := id_sysdate;             -- �i�ڐU�֓�
    lr_masters_rec.remarks                 := iv_remarks;             -- �E�v
    lr_masters_rec.item_chg_aim            := iv_item_chg_aim;        -- �i�ڐU�֖ړI
--
    -- �����敪[4:����]�����Y�o�b�`No(�\��)�Ɏw�肪�Ȃ��ꍇ�A�����敪��[5:����(���Y�o�b�`No�w��Ȃ�)]�ɕύX
    IF ( ( lr_masters_rec.process_type = gv_actual )
    AND  ( lr_masters_rec.plan_batch_id IS NULL ) ) THEN
      lr_masters_rec.process_type := gv_actual_new;
    END IF;
--
    -- ���������̐ݒ�
    gn_target_cnt := 1;
--
    -- ===============================
    -- ��������(A-0)
    -- ===============================
    init_proc(lr_masters_rec -- 1.�����Ώۃ��R�[�h
            , lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
            , lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
            , lv_errmsg);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ************************************************* --
    -- ** ������ʂ��u1�F�\��v�̏ꍇ                 ** --
    -- ************************************************* --
    IF ( lr_masters_rec.process_type = gv_plan_new ) THEN
--
      -- ===============================
      -- �K�{�`�F�b�N(�V�K)(A-1-1)
      -- ===============================
      chk_param_new(lr_masters_rec  -- 1.�`�F�b�N�Ώۃ��R�[�h
                  , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                  , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                  , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �}�X�^���݃`�F�b�N(A-22)
      -- ===============================
      chk_mst_data(lr_masters_rec  -- 1.�`�F�b�N�Ώۃ��R�[�h
                 , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                 , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                 , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �݌ɃN���[�Y�`�F�b�N(A-23)
      -- ===============================
      chk_close_period(id_sysdate  -- 1.��r���t = �i�ڐU�֓�
                     , lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
                     , lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
                     , lv_errmsg);                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �����\�����߃`�F�b�N(�\��)(A-24)
      -- ===============================
      -- �U�֌��i�� �o�ɐ��V�K�`�F�b�N
      chk_qty_over_plan(lr_masters_rec                       -- 1.�`�F�b�N�Ώۃ��R�[�h
-- 2009/01/15 H.Itou Add Start �w�E2�Ή�
                      , id_sysdate                           -- 2.�L�����t
                      , 0                                    -- 3.�X�V�O����
                      , TO_NUMBER(iv_quantity)               -- 4.�o�^����
-- 2009/01/15 H.Itou Add End
                      , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                      , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                      , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ====================================
      -- �H���L���`�F�b�N(A-2)
      -- ====================================
      chk_routing(lr_masters_rec -- 1.�����Ώۃ��R�[�h
                , lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
                , lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
                , lv_errmsg);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �t�H�[�~�����L���`�F�b�N �o�^����(A-28)
      -- ===============================
      chk_and_ins_formula(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                        , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                        , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                        , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ���V�s�L���`�F�b�N �o�^����(A-29)
      -- ===============================
      chk_and_ins_recipe(lr_masters_rec
                       , lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
                       , lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
                       , lv_errmsg);-- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �U�֐惍�b�g�L���`�F�b�N �o�^����(A-30)
      -- ===============================
      chk_and_ins_to_lot(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                       , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                       , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                       , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �o�b�`�쐬(A-9)
      -- ===============================
      create_batch(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                 , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                 , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                 , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ���̓��b�g�����ǉ�(A-10)
      -- ===============================
      input_lot_ins(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                  , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                  , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                  , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �o�̓��b�g�����ǉ�(A-11)
      -- ===============================
      output_lot_ins(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                   , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                   , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                   , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
    -- ************************************************* --
    -- ** ������ʂ��u2�F�\������v�̏ꍇ             ** --
    -- ************************************************* --
    ELSIF ( lr_masters_rec.process_type = gv_plan_change ) THEN
      -- ===============================
      -- �K�{�`�F�b�N(�X�V)(A-1-2)
      -- ===============================
      chk_param_upd(lr_masters_rec  -- 1.�`�F�b�N�Ώۃ��R�[�h
                  , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                  , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                  , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �o�b�`�f�[�^�擾(A-26)
      -- ===============================
      -- ���Y�o�b�`No�ɕR�t���O��o�^���̃o�b�`�f�[�^���擾
      get_batch_data(lr_masters_rec  -- 1.�`�F�b�N�Ώۃ��R�[�h
                   , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                   , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                   , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
-- 2009/01/15 H.Itou Add Start �w�E7
      -- ===============================
      -- �ۊǑq�Ƀ`�F�b�N(A-36)
      -- ===============================
      chk_location( lr_masters_rec.inventory_location_code  -- ���Y�o�b�`�ɓo�^�ς̕ۊǑq��
                  , iv_inv_loc_code                         -- IN�p�����[�^.�ۊǑq��
                  , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                  , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                  , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
-- 2009/01/15 H.Itou Add End
--
      -- ===============================
      -- �i�ڃf�[�^�擾(A-27)
      -- ===============================
      -- ���Y�o�b�`No�ɕR�t���O��o�^���̕i�ڃf�[�^�E���b�g�f�[�^���擾
      get_item_data(lr_masters_rec  -- 1.�`�F�b�N�Ώۃ��R�[�h
                  , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                  , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                  , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �݌ɃN���[�Y�`�F�b�N(A-23)
      -- ===============================
      -- ���Y�o�b�`No�ɕR�t���O��o�^���̐��Y�\����̃N���[�Y�`�F�b�N
      chk_close_period(lr_masters_rec.plan_start_date  -- 1.��r���t = ���Y�\���
                     , lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� #
                     , lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
                     , lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
-- 2009/01/15 H.Itou Del Start �w�E2�Ή�
--      -- ���ʂɕύX������ꍇ
--      IF (lr_masters_rec.trans_qty <> TO_NUMBER(iv_quantity)) THEN
--        -- ===============================
--        -- �����\�����߃`�F�b�N(�\��)(A-24)
--        -- ===============================
--        -- ���Y�o�b�`No�ɕR�t���O��o�^���̐��ʂƓ��͂������ʂ̍����ō݌ɐ��ʃ`�F�b�N
--        chk_qty_over_plan(lr_masters_rec  -- 1.�`�F�b�N�Ώۃ��R�[�h
--                   , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
--                   , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
--                   , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
----
--        -- �G���[�̏ꍇ
--        IF ( lv_retcode = gv_status_error ) THEN
--          gn_error_cnt := gn_error_cnt + 1;
--          RAISE global_process_expt;
--        END IF;
----
--      -- ���ʂɕύX���Ȃ��ꍇ
--      ELSE
--        -- �p�����[�^.���ʂɑO��o�^���̐��ʂ��Z�b�g
--        lr_masters_rec.qty := lr_masters_rec.trans_qty;
--      END IF;
-- 2009/01/15 H.Itou Del End
-- 2009/01/15 H.Itou Add Start �w�E2�Ή�
      -- �i�ڐU�֓�(��|��)�����b�gNo�ɕύX������ꍇ
      -- �o�^�ς݂̃f�[�^���e���������Ă������\�����s�����Ȃ����U�֐�i�ڂ��`�F�b�N
      IF ( lr_masters_rec.plan_start_date < id_sysdate )
      OR ( lr_masters_rec.lot_no         <> iv_lot_no ) THEN
        -- ===============================
        -- �����\�݌ɕs���`�F�b�N(�\��)(A-35)
        -- ===============================
        -- �U�֐�i�� ���Ɏ���`�F�b�N
        chk_qty_short_plan(lr_masters_rec                       -- 1.�`�F�b�N�Ώۃ��R�[�h
                         , lr_masters_rec.plan_start_date       -- 2.�L�����t
                         , lr_masters_rec.trans_qty             -- 3.�X�V�O����
                         , 0                                    -- 4.�o�^����
                         , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                         , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                         , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- �G���[�̏ꍇ
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
--
      -- ���ʂ̂ݕύX������ꍇ
      -- �o�^�ς݂̃f�[�^���e�Ƃ̐��ʂ̍������l�����Ĉ����\�������߁E�s�����Ȃ����U�֌��i�ځE�U�֐�i�ڂ��`�F�b�N
      ELSIF ( lr_masters_rec.trans_qty <> TO_NUMBER(iv_quantity) ) THEN
        -- ===============================
        -- �����\�����߃`�F�b�N(�\��)(A-24)
        -- ===============================
        -- �U�֌��i�� �o�ɐ������`�F�b�N
        chk_qty_over_plan(lr_masters_rec                       -- 1.�`�F�b�N�Ώۃ��R�[�h
                        , lr_masters_rec.plan_start_date       -- 2.�L�����t
                        , lr_masters_rec.trans_qty             -- 3.�X�V�O����
                        , TO_NUMBER(iv_quantity)               -- 4.�o�^����
                        , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                        , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                        , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- �G���[�̏ꍇ
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- �����\�݌ɕs���`�F�b�N(�\��)(A-35)
        -- ===============================
        -- �U�֐�i�� ���ɐ������`�F�b�N
        chk_qty_short_plan(lr_masters_rec                       -- 1.�`�F�b�N�Ώۃ��R�[�h
                         , lr_masters_rec.plan_start_date       -- 2.�L�����t
                         , lr_masters_rec.trans_qty             -- 3.�X�V�O����
                         , TO_NUMBER(iv_quantity)               -- 4.�o�^����
                         , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                         , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                         , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- �G���[�̏ꍇ
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
--
      END IF;
-- 2009/01/15 H.Itou Add End
--
      -- �i�ڐU�֓����ύX���ꂽ�ꍇ
      IF ( lr_masters_rec.plan_start_date <> id_sysdate ) THEN
        -- ===============================
        -- �݌ɃN���[�Y�`�F�b�N(A-23)
        -- ===============================
        -- �p�����[�^.�i�ڐU�֓��̃N���[�Y�`�F�b�N
        chk_close_period(id_sysdate  -- 1.��r���t = �i�ڐU�֓�
                       , lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
                       , lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
                       , lv_errmsg);                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- �G���[�̏ꍇ
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
--
-- 2009/01/15 H.Itou Add Start �w�E2�Ή�
        IF ( iv_lot_no IS NULL) THEN -- ���b�gNo�ɕύX������ꍇ�A�ύX���郍�b�gID�����܂��Ă���`�F�b�N���s���̂ŁA�����ł̓`�F�b�N���Ȃ��B
          -- ===============================
          -- �����\�����߃`�F�b�N(�\��)(A-24)
          -- ===============================
          -- �U�֌��i�� �o�ɐ��V�K�`�F�b�N
          chk_qty_over_plan(lr_masters_rec                       -- 1.�`�F�b�N�Ώۃ��R�[�h
                          , id_sysdate                           -- 2.�L�����t
                          , 0                                                      -- 3.�X�V�O����
                          , NVL(TO_NUMBER(iv_quantity), lr_masters_rec.trans_qty)  -- 4.�o�^����
                          , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                          , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                          , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
            -- �G���[�̏ꍇ
            IF ( lv_retcode = gv_status_error ) THEN
              gn_error_cnt := gn_error_cnt + 1;
              RAISE global_process_expt;
            END IF;
          END IF;
-- 2009/01/15 H.Itou Add End
        -- ===============================
        -- �o�b�`�ăX�P�W���[��(A-16)
        -- ===============================
-- 2009/01/15 H.Itou Del Start �w�E2�Ή�
--        -- ���Y�\����Ƀp�����[�^.�i�ڐU�֓����Z�b�g
--        lr_masters_rec.plan_start_date := lr_masters_rec.item_sysdate;
-- 2009/01/15 H.Itou Del End
--
        reschedule_batch(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                       , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                       , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                       , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- �G���[�̏ꍇ
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
--
-- 2009/01/15 H.Itou Del Start �w�E2�Ή�
--      -- �i�ڐU�֓��ɕύX���Ȃ��ꍇ
--      ELSE
--        -- �p�����[�^.�i�ڐU�֓��ɐ��Y�\������Z�b�g
--        lr_masters_rec.item_sysdate := lr_masters_rec.plan_start_date;
-- 2009/01/15 H.Itou Del End
      END IF;
--
      -- ���b�gNo���ύX���ꂽ�ꍇ
      IF ( lr_masters_rec.lot_no   <> iv_lot_no ) THEN
        -- ===============================
        -- ���̓��b�g�����폜(A-19)
        -- ===============================
        -- �O��o�^���̍폜
        input_lot_del(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                    , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                    , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                    , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- �G���[�̏ꍇ
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- �o�̓��b�g�����폜(A-20)
        -- ===============================
        -- �O��o�^���̍폜
        output_lot_del(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                     , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                     , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                     , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- �G���[�̏ꍇ
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- ���b�g�L���`�F�b�N(A-7)(�U�֌�)
        -- ===============================
        -- ���b�gNo�Ƀp�����[�^.���b�gNo���Z�b�g
        lr_masters_rec.lot_no := iv_lot_no;
--
        -- �V�K�o�^���b�gNo�ŐU�֌����b�g�����邩�`�F�b�N�B
        chk_lot(lr_masters_rec               -- 1.�`�F�b�N�Ώۃ��R�[�h
              , lr_masters_rec.lot_no        -- 2.���b�gNo
              , lr_masters_rec.from_item_id  -- 3.�i��ID(�U�֌�)
              , lr_masters_rec.from_lot_id   -- 4.���b�gID(�U�֌�)
              , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
              , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
              , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- �G���[�̏ꍇ
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
--
        -- ���b�g�����݂��Ȃ��ꍇ
        ELSIF ( NOT(lr_masters_rec.is_info_flg) ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                              , gv_msg_52a_17);
          RAISE global_process_expt;
        END IF;
--
-- 2009/01/15 H.Itou Add Start �w�E2�Ή�
        -- ===============================
        -- �����\�����߃`�F�b�N(�\��)(A-24)
        -- ===============================
        -- �U�֌��i�� �o�ɐ��V�K�`�F�b�N
        chk_qty_over_plan(lr_masters_rec                       -- 1.�`�F�b�N�Ώۃ��R�[�h
                        , NVL(id_sysdate, lr_masters_rec.plan_start_date)       -- 2.�L�����t
                        , 0                                                     -- 3.�X�V�O����
                        , NVL(TO_NUMBER(iv_quantity), lr_masters_rec.trans_qty) -- 4.�o�^����
                        , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                        , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                        , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          -- �G���[�̏ꍇ
          IF ( lv_retcode = gv_status_error ) THEN
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;
-- 2009/01/15 H.Itou Add End
--
        -- ===============================
        -- �U�֐惍�b�g�L���`�F�b�N �o�^����(A-30)
        -- ===============================
        -- �V�K�o�^���b�gNo�ŐU�֐惍�b�g�����邩�`�F�b�N�B�Ȃ���΍쐬
        chk_and_ins_to_lot(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                         , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                         , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                         , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- �G���[�̏ꍇ
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- ���̓��b�g�����ǉ�(A-10)
        -- ===============================
        -- �V�K���b�gNo�ōēo�^
        input_lot_ins(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                    , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                    , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                    , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- �G���[�̏ꍇ
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- �o�̓��b�g�����ǉ�(A-11)
        -- ===============================
        -- �V�K���b�gNo�ōēo�^
        output_lot_ins(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                     , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                     , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                     , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- �G���[�̏ꍇ
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
--
      ELSE
        -- ���ʂ��ύX���ꂽ�ꍇ
        IF (lr_masters_rec.trans_qty <> TO_NUMBER(iv_quantity)) THEN
          -- ===============================
          -- ���̓��b�g�����X�V(A-17)
          -- ===============================
          input_lot_upd(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                      , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                      , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                      , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          -- �G���[�̏ꍇ
          IF ( lv_retcode = gv_status_error ) THEN
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- �o�̓��b�g�����X�V(A-18)
          -- ===============================
          output_lot_upd(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                       , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                       , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                       , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          -- �G���[�̏ꍇ
          IF ( lv_retcode = gv_status_error ) THEN
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
      END IF;
--
    -- ************************************************* --
    -- ** ������ʂ��u3�F�\�����v�̏ꍇ             ** --
    -- ************************************************* --
    ELSIF ( lr_masters_rec.process_type = gv_plan_cancel ) THEN
      -- ===============================
      -- �K�{�`�F�b�N(�X�V)(A-1-2)
      -- ===============================
      chk_param_upd(lr_masters_rec  -- 1.�`�F�b�N�Ώۃ��R�[�h
                  , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                  , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                  , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �o�b�`�f�[�^�擾(A-26)
      -- ===============================
      get_batch_data(lr_masters_rec  -- 1.�`�F�b�N�Ώۃ��R�[�h
                   , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                   , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                   , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
-- 2009/01/15 H.Itou Add Start �w�E2�Ή�
      -- ===============================
      -- �ۊǑq�Ƀ`�F�b�N(A-36)
      -- ===============================
      chk_location( lr_masters_rec.inventory_location_code  -- ���Y�o�b�`�ɓo�^�ς̕ۊǑq��
                  , iv_inv_loc_code                         -- IN�p�����[�^.�ۊǑq��
                  , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                  , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                  , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
-- 2009/01/15 H.Itou Add End
-- 2009/01/15 H.Itou Add Start �w�E7�Ή�
      -- ===============================
      -- �i�ڃf�[�^�擾(A-27)
      -- ===============================
      -- ���Y�o�b�`No�ɕR�t���O��o�^���̕i�ڃf�[�^�E���b�g�f�[�^���擾
      get_item_data(lr_masters_rec  -- 1.�`�F�b�N�Ώۃ��R�[�h
                  , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                  , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                  , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �����\�݌ɕs���`�F�b�N(�\��)(A-35)
      -- ===============================
      -- �U�֐�i�� ���Ɏ���`�F�b�N
      chk_qty_short_plan(lr_masters_rec                       -- 1.�`�F�b�N�Ώۃ��R�[�h
                       , lr_masters_rec.plan_start_date       -- 2.�L�����t
                       , lr_masters_rec.trans_qty             -- 3.�X�V�O����
                       , 0                                    -- 4.�o�^����
                       , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                       , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                       , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
-- 2009/01/15 H.Itou Add End
--
      -- ===============================
      -- �o�b�`���(A-15)
      -- ===============================
      cancel_batch(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                 , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                 , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                 , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
    -- *************************************************** --
    -- ** ������ʂ��u4�F����(���Y�o�b�`No����)�v�̏ꍇ ** --
    -- *************************************************** --
    ELSIF ( lr_masters_rec.process_type = gv_actual ) THEN
      -- ===============================
      -- �K�{�`�F�b�N(�X�V)(A-1-2)
      -- ===============================
      chk_param_upd(lr_masters_rec  -- 1.�`�F�b�N�Ώۃ��R�[�h
                  , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                  , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                  , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �o�b�`�f�[�^�擾(A-26)
      -- ===============================
      get_batch_data(lr_masters_rec  -- 1.�`�F�b�N�Ώۃ��R�[�h
                   , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                   , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                   , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
-- 2009/01/15 H.Itou Add Start �w�E2�Ή�
      -- ===============================
      -- �ۊǑq�Ƀ`�F�b�N(A-36)
      -- ===============================
      chk_location( lr_masters_rec.inventory_location_code  -- ���Y�o�b�`�ɓo�^�ς̕ۊǑq��
                  , iv_inv_loc_code                         -- IN�p�����[�^.�ۊǑq��
                  , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                  , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                  , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
-- 2009/01/15 H.Itou Add End
--
      -- ===============================
      -- �i�ڃf�[�^�擾(A-27)
      -- ===============================
      -- ���Y�o�b�`No�ɕR�t���O��o�^���̕i�ڃf�[�^�E���b�g�f�[�^���擾
      get_item_data(lr_masters_rec  -- 1.�`�F�b�N�Ώۃ��R�[�h
                  , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                  , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                  , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �݌ɃN���[�Y�`�F�b�N(A-23)
      -- ===============================
      chk_close_period(lr_masters_rec.plan_start_date  -- 1.��r���t = ���Y�\���
                     , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                     , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                     , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �������`�F�b�N(A-34)
      -- ===============================
      chk_future_date(lr_masters_rec.plan_start_date  -- 1.��r���t = ���Y�\���
                    , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                    , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                    , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
-- 2009/01/15 H.Itou Add Start �w�E8�Ή�
      -- ===============================
      -- �����\�����߃`�F�b�N(����)(A-25)
      -- ===============================
      -- �U�֌��i�� �o�ɐ��V�K�`�F�b�N(�o�ɗ\�萔�Ƃ��ēo�^�ς݂Ȃ̂ŁA���Z���Ȃ�)
      chk_qty_over_actual(lr_masters_rec                 -- 1.�`�F�b�N�Ώۃ��R�[�h
                        , lr_masters_rec.plan_start_date -- 2.�L�����t
                        , 0                              -- 3.���ѐ���
                        , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                        , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                        , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
-- 2009/01/15 H.Itou Add End
--
      -- ===============================
      -- �����[�X�o�b�`(A-33)
      -- ===============================
      release_batch(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                  , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                  , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                  , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ���̓��b�g�����X�V(����)(A-31)
      -- ===============================
      input_lot_upd_ind(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                      , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                      , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                      , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �o�̓��b�g�����X�V(����)(A-32)
      -- ===============================
      output_lot_upd_ind(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                       , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                       , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                       , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �o�b�`����(A-12)
      -- ===============================
      cmpt_batch(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
               , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
               , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
               , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �o�b�`�N���[�Y(A-13)
      -- ===============================
      close_batch(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
    -- ******************************************************* --
    -- ** ������ʂ��u5�F����(���Y�o�b�`No�w��Ȃ�)�v�̏ꍇ ** --
    -- ******************************************************* --
    ELSIF ( lr_masters_rec.process_type = gv_actual_new ) THEN
--
      -- ===============================
      -- �K�{�`�F�b�N(�V�K)(A-1-1)
      -- ===============================
      chk_param_new(lr_masters_rec  -- 1.�`�F�b�N�Ώۃ��R�[�h
                  , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                  , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                  , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �}�X�^���݃`�F�b�N(A-22)
      -- ===============================
      chk_mst_data(lr_masters_rec  -- 1.�`�F�b�N�Ώۃ��R�[�h
                 , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                 , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                 , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �݌ɃN���[�Y�`�F�b�N(A-23)
      -- ===============================
      chk_close_period(id_sysdate  -- 1.��r���t = �i�ڐU�֓�
                     , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                     , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                     , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �������`�F�b�N(A-34)
      -- ===============================
      chk_future_date(id_sysdate  -- 1.��r���t = �i�ڐU�֓�
                    , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                    , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                    , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �����\�����߃`�F�b�N(����)(A-25)
      -- ===============================
      -- �U�֌��i�� �o�ɐ��V�K�`�F�b�N
      chk_qty_over_actual(lr_masters_rec          -- 1.�`�F�b�N�Ώۃ��R�[�h
-- 2009/01/15 H.Itou Add Start �w�E2�Ή�
                        , id_sysdate              -- 2.�L�����t
                        , TO_NUMBER(iv_quantity)  -- 3.���ѐ���
-- 2009/01/15 H.Itou Add End
                        , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                        , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                        , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ====================================
      -- �H���L���`�F�b�N(A-2)
      -- ====================================
      chk_routing(lr_masters_rec -- 1.�����Ώۃ��R�[�h
                , lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
                , lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
                , lv_errmsg);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �t�H�[�~�����L���`�F�b�N �o�^����(A-28)
      -- ===============================
      chk_and_ins_formula(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                        , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                        , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                        , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ���V�s�L���`�F�b�N �o�^����(A-29)
      -- ===============================
      chk_and_ins_recipe(lr_masters_rec
                       , lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
                       , lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
                       , lv_errmsg);-- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �U�֐惍�b�g�L���`�F�b�N �o�^����(A-30)
      -- ===============================
      chk_and_ins_to_lot(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                       , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                       , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                       , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �o�b�`�쐬(A-9)
      -- ===============================
      create_batch(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                 , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                 , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                 , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �����[�X�o�b�`(A-33)
      -- ===============================
      -- ���Y�\����Ƀp�����[�^.�i�ڐU�֓����Z�b�g
      lr_masters_rec.plan_start_date := id_sysdate;
--
      release_batch(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                  , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                  , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                  , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ���̓��b�g�����ǉ�(A-10)
      -- ===============================
      input_lot_ins(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                  , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                  , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                  , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �o�̓��b�g�����ǉ�(A-11)
      -- ===============================
      output_lot_ins(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                   , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                   , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                   , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �o�b�`����(A-12)
      -- ===============================
      cmpt_batch(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
               , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
               , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
               , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �o�b�`�N���[�Y(A-13)
      -- ===============================
      close_batch(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
                , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
                , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
                , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ===============================
    -- �o�b�`�ۑ�(A-14)
    -- ===============================
    save_batch(lr_masters_rec  -- 1.�����Ώۃ��R�[�h
             , lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
             , lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
             , lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ����I�����o��
    -- ===============================
    -- ���Y�o�b�`No
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_52
                                            , gv_tkn_value
                                            , lr_masters_rec.batch_no);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
--
    -- ���������̐ݒ�
    gn_normal_cnt := 1;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
    errbuf             OUT NOCOPY VARCHAR2 -- �G���[���b�Z�[�W #�Œ�#
  , retcode            OUT NOCOPY VARCHAR2 -- �G���[�R�[�h     #�Œ�#
  , iv_process_type    IN         VARCHAR2 --  1.�����敪(1:�\��,2:�\�����,3:�\����,4:����)
  , iv_plan_batch_id   IN         VARCHAR2 --  2.�o�b�`ID(�\��)
  , iv_inv_loc_code    IN         VARCHAR2 --  3.�ۊǑq�ɃR�[�h
  , iv_from_item_no    IN         VARCHAR2 --  4.�U�֌��i��No
  , iv_lot_no          IN         VARCHAR2 --  5.���b�gNo
  , iv_to_item_no      IN         VARCHAR2 --  6.�U�֐�i��No
  , iv_quantity        IN         VARCHAR2 --  7.����
  , iv_sysdate         IN         VARCHAR2 --  8.�i�ڐU�֓�
  , iv_remarks         IN         VARCHAR2 --  9.�E�v
  , iv_item_chg_aim    IN         VARCHAR2 -- 10.�i�ڐU�֖ړI
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    lv_normal_msg VARCHAR2(5000);  -- �K�{�o�̓��b�Z�[�W
    lv_aim_mean   VARCHAR2(20);    -- �i�ڐU�֖ړI �E�v
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118','TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    -- submain�̌Ăяo��
    submain(
        iv_process_type                                   --  1.�����敪(1:�\��,2:�\�����,3:�\����,4:����)
      , iv_plan_batch_id                                  --  2.�o�b�`ID(�\��)
      , iv_inv_loc_code                                   --  3.�ۊǑq��ID
      , iv_from_item_no                                   --  4.�U�֌��i��ID
      , iv_lot_no                                         --  5.���b�gID
      , iv_to_item_no                                     --  6.�U�֐�i��ID
      , iv_quantity                                       --  7.����
      , FND_DATE.STRING_TO_DATE(iv_sysdate, gv_yyyymmdd)  --  8.�i�ڐU�֓�
      , iv_remarks                                        --  9.�E�v
      , iv_item_chg_aim                                   -- 10.�i�ڐU�֖ړI
      , lv_errbuf                                         --  �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode                                        --  ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg);                                       --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- ===============================
    -- �K�{�o�͍���
    -- ===============================
    -- �p�����[�^�����敪���͒l
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_77
                                            , gv_tkn_value
                                            , iv_process_type);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- �p�����[�^�o�b�`ID(�\��)���͒l
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_52
                                            , gv_tkn_value
                                            , gv_plan_batch_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- �p�����[�^�ۊǑq�ɓ��͒l
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_45
                                            , gv_tkn_value
                                            , iv_inv_loc_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- �p�����[�^�U�֌��i�ړ��͒l
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_46
                                            , gv_tkn_value
                                            , iv_from_item_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- �p�����[�^�U�֌����b�gNo���͒l
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_47
                                            , gv_tkn_value
                                            , iv_lot_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- �p�����[�^�U�֐�i�ړ��͒l
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_48
                                            , gv_tkn_value
                                            , iv_to_item_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- �p�����[�^���ʓ��͒l
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_49
                                            , gv_tkn_value
                                            , iv_quantity);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- �p�����[�^�i�ڐU�֓����͒l
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_50
                                            , gv_tkn_value
                                            , iv_sysdate);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- �p�����[�^�E�v���͒l
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_51
                                            , gv_tkn_value
                                            , iv_remarks);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- �p�����[�^�i�ڐU�֖ړI
    -- �i�ڐU�֖ړI�̓E�v���擾
    BEGIN
      SELECT flvv.meaning            -- �E�v
      INTO   lv_aim_mean
      FROM   xxcmn_lookup_values_v flvv  -- ���b�N�A�b�vVIEW
      WHERE  flvv.lookup_type  = gv_lt_item_tran_cls
      AND    flvv.lookup_code  = iv_item_chg_aim
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN  -- �f�[�^�擾�G���[
        -- �i�ڐU�֖ړI�̃R�[�h���o��
        lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                                , gv_msg_52a_57
                                                , gv_tkn_value
                                                , iv_item_chg_aim);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    END;
--
    -- �f�[�^���擾�ł����ꍇ�͕i�ڐU�֖ړI�̓E�v���o��
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                            , gv_msg_52a_57
                                            , gv_tkn_value
                                            , lv_aim_mean);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
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
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type,
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = gv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxinv520003c;
/
