CREATE OR REPLACE PACKAGE BODY xxinv520001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV520001C(body)
 * Description      : �i�ڐU��
 * MD.050           : �i�ڐU�� T_MD050_BPO_520
 * MD.070           : �i�ڐU�� T_MD070_BPO_52A
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init_proc              �����������s���v���V�[�W��
 *  chk_param              �p�����[�^�`�F�b�N���s���v���V�[�W��(A-1)
 *  set_masters_rec        �p�����[�^���瓱�o�����f�[�^�̃Z�b�g���s���v���V�[�W��
 *  chk_formula            �t�H�[�~�����L���`�F�b�N���s���v���V�[�W��(A-2)
 *  ins_formula            �t�H�[�~�����o�^���s���v���V�[�W��(A-3)
 *  chk_recipe             ���V�s�L���`�F�b�N���s���v���V�[�W��(A-4)
 *  upd_recipe             ���V�s�X�V���s���v���V�[�W��
 *  chk_lot                ���b�g�L���`�F�b�N���s���v���V�[�W��(A-6)
 *  create_lot             ���b�g�쐬���s���v���V�[�W��(A-7)
 *  create_batch           �o�b�`�쐬���s���v���V�[�W��(A-8)
 *  input_lot_assign       ���̓��b�g�������s���v���V�[�W��(A-9)
 *  output_lot_assign      �o�̓��b�g�������s���v���V�[�W��(A-11)
 *  cmpt_batch             �o�b�`�������s���v���V�[�W��(A-12)
 *  close_batch            �o�b�`�N���[�Y���s���v���V�[�W��(A-13)
 *  save_batch             �o�b�`�ۑ����s���v���V�[�W��
 *  get_validity_rule_id   �Ó������[��ID���擾����v���V�[�W��
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/11    1.0  Oracle �a�c ��P   ����쐬
 *  2008/04/28    1.1  Oracle �͖� �D�q   �����ύX�Ή�#63
 *  2008/05/22    1.2  Oracle �F�{ �a�Y   �����e�X�g��Q�Ή�(�X�e�[�^�X�`�F�b�N�E�X�V�����ǉ�)
 *  2008/05/22    1.3  Oracle �F�{ �a�Y   �����e�X�g��Q�Ή�(����p�����[�^�ɂ����s���̃G���[)
 *
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
  gv_ret_sts_success CONSTANT VARCHAR2(1)   := 'S';            -- ����
  gv_pkg_name        CONSTANT VARCHAR2(100) := 'xxinv520001c'; -- �p�b�P�[�W��
  gv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN';
  gv_msg_kbn_inv     CONSTANT VARCHAR2(5)   := 'XXINV';
--
  -- ���b�Z�[�W�ԍ�
  gv_msg_52a_02      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002'; -- �v���t�@�C���擾�G���[
--
  gv_msg_52a_00      CONSTANT VARCHAR2(15) := 'APP-XXINV-10000'; -- API�G���[
  gv_msg_52a_03      CONSTANT VARCHAR2(15) := 'APP-XXINV-10003'; -- �J�����_�N���[�Y���b�Z�[�W
  gv_msg_52a_11      CONSTANT VARCHAR2(15) := 'APP-XXINV-10011'; -- �f�[�^�擾�G���[���b�Z�[�W
  gv_msg_52a_15      CONSTANT VARCHAR2(15) := 'APP-XXINV-10015'; -- �p�����[�^�G���[
  gv_msg_52a_17      CONSTANT VARCHAR2(15) := 'APP-XXINV-10017'; -- �p�����[�^�U�֌����b�gNo�G���[
  gv_msg_52a_20      CONSTANT VARCHAR2(15) := 'APP-XXINV-10020'; -- �p�����[�^���ʃG���[
  gv_msg_52a_21      CONSTANT VARCHAR2(15) := 'APP-XXINV-10021'; -- �p�����[�^�i�ڐU�֎��ѓ��G���[
  gv_msg_52a_71      CONSTANT VARCHAR2(15) := 'APP-XXINV-10071'; -- �p�����[�^�E�v�T�C�Y�G���[
--
  gv_msg_52a_45      CONSTANT VARCHAR2(15) := 'APP-XXINV-10145'; -- �i�ڐU��_�ۊǑq��
  gv_msg_52a_46      CONSTANT VARCHAR2(15) := 'APP-XXINV-10146'; -- �i�ڐU��_�U�֌��i��
  gv_msg_52a_47      CONSTANT VARCHAR2(15) := 'APP-XXINV-10147'; -- �i�ڐU��_�U�֌����b�gNo
  gv_msg_52a_48      CONSTANT VARCHAR2(15) := 'APP-XXINV-10148'; -- �i�ڐU��_�U�֐�i��
  gv_msg_52a_49      CONSTANT VARCHAR2(15) := 'APP-XXINV-10149'; -- �i�ڐU��_����
  gv_msg_52a_50      CONSTANT VARCHAR2(15) := 'APP-XXINV-10150'; -- �i�ڐU��_�i�ڐU�֎��ѓ�
  gv_msg_52a_51      CONSTANT VARCHAR2(15) := 'APP-XXINV-10151'; -- �i�ڐU��_�E�v
  gv_msg_52a_57      CONSTANT VARCHAR2(15) := 'APP-XXINV-10157'; -- �i�ڐU��_�i�ڐU�֖ړI
  gv_msg_52a_52      CONSTANT VARCHAR2(15) := 'APP-XXINV-10152'; -- �i�ڐU��_���Y�o�b�`No
--add start 1.2
  gv_msg_52a_66      CONSTANT VARCHAR2(15) := 'APP-XXINV-10166'; -- �X�e�[�^�X�G���[(�t�H�[�~����)
  gv_msg_52a_67      CONSTANT VARCHAR2(15) := 'APP-XXINV-10167'; -- �X�e�[�^�X�G���[(���V�s)
  gv_msg_52a_69      CONSTANT VARCHAR2(15) := 'APP-XXINV-10169'; -- �X�e�[�^�X�G���[(�Ó������[��)
--add end 1.2
--
  -- �g�[�N��
  gv_tkn_parameter   CONSTANT VARCHAR2(15) := 'PARAMETER';
  gv_tkn_value       CONSTANT VARCHAR2(15) := 'VALUE';
  gv_tkn_api_name    CONSTANT VARCHAR2(15) := 'API_NAME';
  gv_tkn_err_msg     CONSTANT VARCHAR2(15) := 'ERR_MSG';
  gv_tkn_ng_profile  CONSTANT VARCHAR2(15) := 'NG_PROFILE';
--add start 1.2
  gv_tkn_formula     CONSTANT VARCHAR2(15) := 'FORMULA_NO';
  gv_tkn_recipe      CONSTANT VARCHAR2(15) := 'RECIPE_NO';
--add end 1.2
--
  -- �g�[�N���l
  gv_tkn_prf_dummy   CONSTANT VARCHAR2(20) := '�_�~�[�H��';
  gv_tkn_inv_loc     CONSTANT VARCHAR2(20) := '�ۊǑq��';
  gv_tkn_from_item   CONSTANT VARCHAR2(20) := '�U�֌��i��';
  gv_tkn_to_item     CONSTANT VARCHAR2(20) := '�U�֐�i��';
  gv_tkn_item_date   CONSTANT VARCHAR2(20) := '�i�ڐU�֎��ѓ�';
  gv_tkn_item_aim    CONSTANT VARCHAR2(20) := '�i�ڐU�֖ړI';
  gv_tkn_ins_formula CONSTANT VARCHAR2(20) := '�t�H�[�~�����o�^';
  gv_tkn_upd_recipe  CONSTANT VARCHAR2(20) := '���V�s�X�V';
  gv_tkn_create_lot  CONSTANT VARCHAR2(20) := '���b�g�쐬';
  gv_tkn_create_bat  CONSTANT VARCHAR2(20) := '�o�b�`�쐬';
  gv_tkn_input_lot   CONSTANT VARCHAR2(20) := '���̓��b�g����';
  gv_tkn_output_lot  CONSTANT VARCHAR2(20) := '�o�̓��b�g����';
  gv_tkn_cmpt_bat    CONSTANT VARCHAR2(20) := '�o�b�`����';
  gv_tkn_close_bat   CONSTANT VARCHAR2(20) := '�o�b�`�N���[�Y';
  gv_tkn_save_bat    CONSTANT VARCHAR2(20) := '�o�b�`�ۑ�';
--
  -- �v���t�@�C��
  gv_prf_dummy_routing  CONSTANT VARCHAR2(20) := 'XXINV_DUMMY_ROUTING';
  -- �v���t�@�C���l
  gv_prf_val_item_ctgr  CONSTANT VARCHAR2(10) := '�i�ڋ敪';
--
  -- ���b�N�A�b�v
  gv_lt_item_tran_cls   CONSTANT VARCHAR2(30) := 'XXINV_ITEM_TRANS_CLASS';
--
  -- �i�ڋ敪
  gv_material        CONSTANT VARCHAR2(2)  := '1'; -- ����
  gv_half_material   CONSTANT VARCHAR2(2)  := '4'; -- �����i
--
  -- ROWNUM����
  gn_rownum          CONSTANT NUMBER       := 1;
--
  -- �t�H�[�~�����o�^�^�C�v
  gv_record_type     CONSTANT VARCHAR2(2) := 'I'; -- �}��
  -- �t�H�[�~�����X�e�[�^�X
  gv_fml_sts_new     CONSTANT VARCHAR2(4) := '100'; -- �V�K
  gv_fml_sts_appr    CONSTANT VARCHAR2(4) := '700'; -- ��ʎg�p�̏��F
  -- �t�H�[�~�����E�o�[�W����
  gn_fml_vers        CONSTANT NUMBER      := 1;
  -- ���V�s�E�o�[�W����
  gn_rcp_vers        CONSTANT NUMBER      := 1;
--
  -- ���׃^�C�v
  gn_line_type_p     CONSTANT NUMBER      := 1;   -- ���i
  gn_line_type_i     CONSTANT NUMBER      := -1;  -- ����
--
  gn_remarks_max     CONSTANT NUMBER      := 240; -- �E�v�`�F�b�N�p�ő�o�C�g��
--
  gn_bat_type_batch  CONSTANT NUMBER      := 0; -- 0:batch, 10:firm
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_prf_dummy_val   gmd_routings_b.routing_desc%TYPE;  -- �_�~�[�H��
--
  -- �e�}�X�^�ւ̔��f�����ɕK�v�ȃf�[�^���i�[���郌�R�[�h
  TYPE masters_rec IS RECORD(
    -- �t�H�[�~�����}�X�^
    formula_no              fm_form_mst_b.formula_no%TYPE,     -- �t�H�[�~�����ԍ�
    formula_type            fm_form_mst_b.formula_type%TYPE,   -- �t�H�[�~�����^�C�v
    inactive_ind            fm_form_mst_b.inactive_ind%TYPE,   -- (�K�{����)
    orgn_code               fm_form_mst_b.orgn_code%TYPE,      -- �g�D(�v�����g)�R�[�h
    formula_status          fm_form_mst_b.formula_status%TYPE, -- �X�e�[�^�X
    formula_id              fm_form_mst_b.formula_id%TYPE,     -- �t�H�[�~����ID
    scale_type_hdr          fm_form_mst_b.scale_type%TYPE,     -- �X�P�[�����O��
    delete_mark             fm_form_mst_b.delete_mark%TYPE,    -- (�K�{����)
    -- �t�H�[�~�������׃}�X�^
    formulaline_id          fm_matl_dtl.formulaline_id%TYPE,   -- ����ID
    line_type               fm_matl_dtl.line_type%TYPE,        -- ���׃^�C�v
    line_no                 fm_matl_dtl.line_no%TYPE,          -- ���הԍ�
    qty                     fm_matl_dtl.qty%TYPE,              -- ����
    release_type            fm_matl_dtl.release_type%TYPE,     -- ���v�^�C�v/����^�C�v
    scrap_factor            fm_matl_dtl.scrap_factor%TYPE,     -- �p���W��
    scale_type_dtl          fm_matl_dtl.scale_type%TYPE,       -- �X�P�[���^�C�v
    phantom_type            fm_matl_dtl.phantom_type%TYPE,     -- �t�@���g���^�C�v
    rework_type             fm_matl_dtl.rework_type%TYPE,      -- (�K�{����)
    -- ���V�s�}�X�^
    recipe_id               gmd_recipes_b.recipe_id%TYPE,               -- ���V�sID
    recipe_status           gmd_recipes_b.recipe_status%TYPE,           -- ���V�s�X�e�[�^�X
    calculate_step_quantity gmd_recipes_b.calculate_step_quantity%TYPE, -- �X�e�b�v���ʂ̌v�Z
    -- ���V�s�Ó������[���e�[�u��
    recipe_validity_rule_id gmd_recipe_validity_rules.recipe_validity_rule_id%TYPE, -- �Ó������[��
    -- �H���}�X�^
    routing_id              gmd_routings_b.routing_id%TYPE,   -- �H��ID
    routing_no              gmd_routings_b.routing_no%TYPE,   -- �H��No
    routing_version         gmd_routings_b.routing_vers%TYPE, -- �H���o�[�W����
    -- OPM�ۊǑq�Ƀ}�X�^
    inventory_location_id   mtl_item_locations.inventory_location_id%TYPE, -- �ۊǑq��ID
    inventory_location_code mtl_item_locations.segment1%TYPE,              -- �ۊǑq�ɃR�[�h
    -- OPM�q�Ƀ}�X�^
    whse_code               ic_whse_mst.whse_code%TYPE,                    -- �q�ɃR�[�h
    -- OPM�i�ڃ}�X�^
    from_item_id            ic_item_mst_b.item_id%TYPE, -- �U�֌��i��ID
    from_item_no            ic_item_mst_b.item_no%TYPE, -- �U�֌��i��No
    from_item_um            ic_item_mst_b.item_um%TYPE, -- �U�֌��P��
    to_item_id              ic_item_mst_b.item_id%TYPE, -- �U�֐�i��ID
    to_item_no              ic_item_mst_b.item_no%TYPE, -- �U�֐�i��No
    to_item_um              ic_item_mst_b.item_um%TYPE, -- �U�֐�P��
    -- OPM���b�g�}�X�^
    from_lot_id             ic_lots_mst.lot_id%TYPE,   -- �U�֌����b�gID
    to_lot_id               ic_lots_mst.lot_id%TYPE,   -- �U�֐惍�b�gID
    lot_no                  ic_lots_mst.lot_no%TYPE,        -- ���b�gNo
    lot_desc                ic_lots_mst.lot_desc%TYPE,      -- �E�v
    lot_attribute1          ic_lots_mst.attribute1%TYPE,    -- �����N����
    lot_attribute2          ic_lots_mst.attribute2%TYPE,    -- �ŗL�L��
    lot_attribute3          ic_lots_mst.attribute3%TYPE,    -- �ܖ�����
    lot_attribute4          ic_lots_mst.attribute4%TYPE,    -- �[����(����)
    lot_attribute5          ic_lots_mst.attribute5%TYPE,    -- �[����(�ŏI)
    lot_attribute6          ic_lots_mst.attribute6%TYPE,    -- �݌ɓ���
    lot_attribute7          ic_lots_mst.attribute7%TYPE,    -- �݌ɒP��
    lot_attribute8          ic_lots_mst.attribute8%TYPE,    -- �����
    lot_attribute9          ic_lots_mst.attribute9%TYPE,    -- �d���`��
    lot_attribute10         ic_lots_mst.attribute10%TYPE,   -- �����敪
    lot_attribute11         ic_lots_mst.attribute11%TYPE,   -- �N�x
    lot_attribute12         ic_lots_mst.attribute12%TYPE,   -- �Y�n
    lot_attribute13         ic_lots_mst.attribute13%TYPE,   -- �^�C�v
    lot_attribute14         ic_lots_mst.attribute14%TYPE,   -- �����N�P
    lot_attribute15         ic_lots_mst.attribute15%TYPE,   -- �����N�Q
    lot_attribute16         ic_lots_mst.attribute16%TYPE,   -- ���Y�`�[�敪
    lot_attribute17         ic_lots_mst.attribute17%TYPE,   -- ���C��No
    lot_attribute18         ic_lots_mst.attribute18%TYPE,   -- �E�v
    lot_attribute19         ic_lots_mst.attribute19%TYPE,   -- �����N�R
    lot_attribute20         ic_lots_mst.attribute20%TYPE,   -- ���������H��
    lot_attribute21         ic_lots_mst.attribute21%TYPE,   -- �������������b�g�ԍ�
    lot_attribute22         ic_lots_mst.attribute22%TYPE,   -- �����˗�No
    lot_attribute23         ic_lots_mst.attribute23%TYPE,   -- ���b�g�X�e�[�^�X
    lot_attribute24         ic_lots_mst.attribute24%TYPE,   -- �쐬�敪
    lot_attribute25         ic_lots_mst.attribute25%TYPE,
    lot_attribute26         ic_lots_mst.attribute26%TYPE,
    lot_attribute27         ic_lots_mst.attribute27%TYPE,
    lot_attribute28         ic_lots_mst.attribute28%TYPE,
    lot_attribute29         ic_lots_mst.attribute29%TYPE,
    lot_attribute30         ic_lots_mst.attribute30%TYPE,
--
    -- ���Y�o�b�`�w�b�_
    batch_id                gme_batch_header.batch_id%TYPE,  -- �o�b�`ID
    batch_no                gme_batch_header.batch_no%TYPE,  -- �o�b�`No
--
    -- ���Y�����ڍ�
    from_material_detail_id gme_material_details.material_detail_id%TYPE, -- ���Y�����ڍ�ID(�U�֌�)
    to_material_detail_id   gme_material_details.material_detail_id%TYPE, -- ���Y�����ڍ�ID(�U�֐�)
--
    item_sysdate            DATE,                          -- �i�ڐU�֎��ѓ�
    remarks                 VARCHAR2(240),                 -- �E�v
    item_chg_aim            VARCHAR2(1),                   -- �i�ڐU�֖ړI
    is_info_flg             BOOLEAN                        -- ���L���t���O
  );
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : ��������
   ***********************************************************************************/
  PROCEDURE init_proc(
    ir_masters_rec IN OUT NOCOPY masters_rec, -- 1.�����Ώۃ��R�[�h
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �_�~�[�H���Ƀv���t�@�C���l���Z�b�g
    gv_prf_dummy_val := FND_PROFILE.VALUE(gv_prf_dummy_routing);
    -- �v���t�@�C���l���擾�ł��Ȃ��ꍇ
    IF (gv_prf_dummy_val IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,    gv_msg_52a_02,
                                            gv_tkn_ng_profile, gv_tkn_prf_dummy);
      RAISE global_api_expt;
    END IF;
--
    -- �t�H�[�~����No�̎擾
    ir_masters_rec.formula_no := xxinv_common_pkg.xxinv_get_formula_no(ir_masters_rec.from_item_no
                                                                      ,ir_masters_rec.to_item_no);
    -- �t�H�[�~����No���擾�ł��Ȃ��ꍇ
    IF (ir_masters_rec.formula_no IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_11);
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
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : �p�����[�^�`�F�b�N(A-1)
   ***********************************************************************************/
  PROCEDURE chk_param(
    ir_masters_rec IN OUT NOCOPY masters_rec, -- 1.�`�F�b�N�Ώۃ��R�[�h
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param'; -- �v���O������
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
    ln_count           NUMBER;  -- �J�E���^�[
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �莝�݌ɐ��ʂ̏�����
    ln_onhand_stk_qty := 0;
--
    -- ==================================
    -- �ۊǑq�ɂ̃p�����[�^�`�F�b�N
    -- ==================================
    -- �J�E���^�[�̏�����
    ln_count := 0;
--
    SELECT COUNT(xilv.segment1) inventory_location_code  -- �ۊǑq�ɃR�[�h
    INTO   ln_count
    FROM   xxcmn_item_locations_v  xilv                             -- OPM�ۊǏꏊ���VIEW
    WHERE  xilv.segment1 = ir_masters_rec.inventory_location_code
    AND    ROWNUM        = gn_rownum;
--
    -- OPM�ۊǏꏊ�}�X�^�ɓo�^����Ă��Ȃ��ꍇ
    IF (ln_count < 1) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,   gv_msg_52a_15,
                                            gv_tkn_parameter, gv_tkn_inv_loc,
                                            gv_tkn_value,
                                            ir_masters_rec.inventory_location_code);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    -- �o�^����Ă���ꍇ
    ELSE
      -- ==================================
      -- �ۊǑq��ID�A�q�ɃR�[�h�̎擾
      -- ==================================
      SELECT xilv.inventory_location_id,  -- �ۊǑq��ID
             xilv.whse_code               -- �q�ɃR�[�h
      INTO   ir_masters_rec.inventory_location_id,
             ir_masters_rec.whse_code
      FROM   xxcmn_item_locations_v xilv -- OPM�ۊǏꏊ���VIEW
      WHERE  xilv.segment1 = ir_masters_rec.inventory_location_code;
    END IF;
--
    -- ==================================
    -- �U�֌��i�ڂ̃p�����[�^�`�F�b�N
    -- ==================================
    -- �J�E���^�[�̏�����
    ln_count := 0;
--
    SELECT COUNT(xicv.item_no) item_no  -- �i��No
    INTO   ln_count
    FROM   xxcmn_item_categories_v xicv -- OPM�i�ڃJ�e�S���������VIEW
    WHERE  xicv.item_no  = ir_masters_rec.from_item_no
    AND    xicv.category_set_name = gv_prf_val_item_ctgr
    AND    xicv.segment1 IN (gv_material, gv_half_material)
    AND    ROWNUM        = gn_rownum;
--
    -- �U�֌��i��ID���o�^����Ă��Ȃ��A�܂��͌����������i�łȂ��ꍇ
    IF (ln_count < 1) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,   gv_msg_52a_15,
                                            gv_tkn_parameter, gv_tkn_from_item,
                                            gv_tkn_value,     ir_masters_rec.from_item_no);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    -- �o�^����Ă���ꍇ
    ELSE
      -- ==================================
      -- �U�֌�No��蓱�o�������̎擾
      -- ==================================
      SELECT iimb.item_id,               -- �i��ID
             iimb.item_um                -- �P��
      INTO   ir_masters_rec.from_item_id,
             ir_masters_rec.from_item_um
      FROM   ic_item_mst_b iimb          -- OPM�i�ڃ}�X�^
      WHERE  iimb.item_no = ir_masters_rec.from_item_no;
    END IF;
--
    -- ==================================
    -- �U�֌����b�gNo�̃p�����[�^�`�F�b�N
    -- ==================================
    -- �J�E���^�[�̏�����
    ln_count := 0;
--
    SELECT COUNT(ilm.lot_no) lot_no  -- ���b�gNo
    INTO   ln_count
    FROM   ic_lots_mst  ilm          -- OPM���b�g�}�X�^
    WHERE  ilm.lot_no       = ir_masters_rec.lot_no
    AND    ilm.item_id      = ir_masters_rec.from_item_id
    --AND    ilm.inactive_ind = '0'
    --AND    ilm.delete_mark  = '0'
    AND    ROWNUM           = gn_rownum;
--
    -- OPM���b�g�}�X�^�ɓo�^����Ă��Ȃ��ꍇ
    IF (ln_count < 1) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_17);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    -- �o�^����Ă���ꍇ
    ELSE
      -- ==================================
      -- �U�֌����b�gID�̎擾
      -- ==================================
      SELECT ilm.lot_id                  -- ���b�gID
      INTO   ir_masters_rec.from_lot_id
      FROM   ic_lots_mst ilm             -- OPM���b�g�}�X�^
      WHERE  ilm.lot_no  = ir_masters_rec.lot_no
      AND    ilm.item_id = ir_masters_rec.from_item_id;
    END IF;
--
    -- ==================================
    -- �U�֐�i�ڂ̃p�����[�^�`�F�b�N
    -- ==================================
    -- �J�E���^�[�̏�����
    ln_count := 0;
--
    SELECT COUNT(xicv.item_no) item_no  -- �i��No
    INTO   ln_count
    FROM   xxcmn_item_categories_v xicv -- OPM�i�ڃJ�e�S���������VIEW
    WHERE  xicv.item_no  = ir_masters_rec.to_item_no
    AND    xicv.category_set_name = gv_prf_val_item_ctgr
    AND    xicv.segment1 IN (gv_material, gv_half_material)
    AND    ROWNUM        = gn_rownum;
--
    -- OPM�i�ڃ}�X�^�ɓo�^����Ă��Ȃ��ꍇ
    IF (ln_count < 1) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,   gv_msg_52a_15,
                                            gv_tkn_parameter, gv_tkn_to_item,
                                            gv_tkn_value,     ir_masters_rec.to_item_no);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    -- �o�^����Ă���ꍇ
    ELSE
      -- ==================================
      -- �U�֐�i��No��蓱�o�������̎擾
      -- ==================================
      SELECT iimb.item_id,               -- �i��ID
             iimb.item_um                -- �P��
      INTO   ir_masters_rec.to_item_id,
             ir_masters_rec.to_item_um
      FROM   ic_item_mst_b iimb          -- OPM�i�ڃ}�X�^
      WHERE  iimb.item_no = ir_masters_rec.to_item_no;
    END IF;
--
    -- ==================================
    -- �i�ڐU�֎��ѓ��̃p�����[�^�`�F�b�N
    -- ==================================
    -- �i�ڐU�֎��ѓ����������̏ꍇ
    IF (TRUNC(ir_masters_rec.item_sysdate) > TRUNC(SYSDATE)) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,   gv_msg_52a_21);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    END IF;
--
    -- �i�ڐU�֎��ѓ����݌ɃJ�����_�[�̃I�[�v���łȂ��ꍇ
    IF (TRUNC(ir_masters_rec.item_sysdate) <=
      TRUNC(LAST_DAY(FND_DATE.STRING_TO_DATE(xxcmn_common_pkg.get_opminv_close_period(),
        'YYYY/MM')))) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_03,
                                            gv_tkn_err_msg, ir_masters_rec.item_sysdate);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- ���ʂ̃p�����[�^�`�F�b�N
    -- ==================================
    -- �莝�݌ɐ��ʂ̎擾
    ln_onhand_stk_qty := xxcmn_common_pkg.get_stock_qty(
                                     ir_masters_rec.inventory_location_id,     -- 1.�ۊǑq��ID
                                     ir_masters_rec.from_item_id,              -- 2.�i��ID
                                     ir_masters_rec.from_lot_id);              -- 3.���b�gID
--
    -- ���ʂ̎擾<���і��v��̏o�׈˗�>
    xxcmn_common2_pkg.get_dem_lot_ship_qty(
                                     ir_masters_rec.inventory_location_id,     -- 1.�ۊǑq��ID
                                     ir_masters_rec.from_item_id,              -- 2.�i��ID
                                     ir_masters_rec.from_lot_id,               -- 3.���b�gID
                                     ir_masters_rec.item_sysdate,              -- 4.�L�����t
                                     ln_lot_ship_qty,                          -- 5.����
                                     lv_errbuf,     -- �G���[�E���b�Z�[�W           --# �Œ� #
                                     lv_retcode,    -- ���^�[���E�R�[�h             --# �Œ� #
                                     lv_errmsg);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- ���ʂ̎擾<���і��v��̎x���w��>
    xxcmn_common2_pkg.get_dem_lot_provide_qty(
                                     ir_masters_rec.inventory_location_id,     -- 1.�ۊǑq��ID
                                     ir_masters_rec.from_item_id,              -- 2.�i��ID
                                     ir_masters_rec.from_lot_id,               -- 3.���b�gID
                                     ir_masters_rec.item_sysdate,              -- 4.�L�����t
                                     ln_lot_provide_qty,                       -- 5.����
                                     lv_errbuf,     -- �G���[�E���b�Z�[�W           --# �Œ� #
                                     lv_retcode,    -- ���^�[���E�R�[�h             --# �Œ� #
                                     lv_errmsg);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- ���ʂ̎擾<���і��v��̈ړ��w��>
    xxcmn_common2_pkg.get_dem_lot_inv_out_qty(
                                     ir_masters_rec.inventory_location_id,     -- 1.�ۊǑq��ID
                                     ir_masters_rec.from_item_id,              -- 2.�i��ID
                                     ir_masters_rec.from_lot_id,               -- 3.���b�gID
                                     ir_masters_rec.item_sysdate,              -- 4.�L�����t
                                     ln_lot_inv_out_qty,                       -- 5.����
                                     lv_errbuf,     -- �G���[�E���b�Z�[�W           --# �Œ� #
                                     lv_retcode,    -- ���^�[���E�R�[�h             --# �Œ� #
                                     lv_errmsg);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- ���ʂ̎擾<���ьv��ς̈ړ����Ɏ���>
    xxcmn_common2_pkg.get_dem_lot_inv_in_qty(
                                     ir_masters_rec.inventory_location_id,     -- 1.�ۊǑq��ID
                                     ir_masters_rec.from_item_id,              -- 2.�i��ID
                                     ir_masters_rec.from_lot_id,               -- 3.���b�gID
                                     ir_masters_rec.item_sysdate,              -- 4.�L�����t
                                     ln_lot_inv_in_qty,                        -- 5.����
                                     lv_errbuf,     -- �G���[�E���b�Z�[�W           --# �Œ� #
                                     lv_retcode,    -- ���^�[���E�R�[�h             --# �Œ� #
                                     lv_errmsg);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- ���ʂ̎擾<���і��v��̐��Y�����\��>
    xxcmn_common2_pkg.get_dem_lot_produce_qty(
                                     ir_masters_rec.inventory_location_id,     -- 1.�ۊǑq��ID
                                     ir_masters_rec.from_item_id,              -- 2.�i��ID
                                     ir_masters_rec.from_lot_id,               -- 3.���b�gID
                                     ir_masters_rec.item_sysdate,              -- 4.�L�����t
                                     ln_lot_produce_qty,                       -- 5.����
                                     lv_errbuf,     -- �G���[�E���b�Z�[�W           --# �Œ� #
                                     lv_retcode,    -- ���^�[���E�R�[�h             --# �Œ� #
                                     lv_errmsg);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- ���ʂ̎擾<���і��v��̑����q�ɔ������ɗ\��>
    xxcmn_common2_pkg.get_dem_lot_order_qty(
                                     ir_masters_rec.inventory_location_id,     -- 1.�ۊǑq��ID
                                     ir_masters_rec.from_item_id,              -- 2.�i��ID
                                     ir_masters_rec.from_lot_id,               -- 3.���b�gID
                                     ir_masters_rec.item_sysdate,              -- 4.�L�����t
                                     ln_lot_order_qty,                         -- 5.����
                                     lv_errbuf,    -- �G���[�E���b�Z�[�W           --# �Œ� #
                                     lv_retcode,   -- ���^�[���E�R�[�h             --# �Œ� #
                                     lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �����ύ݌ɐ��ʂ̎Z�o
    ln_fin_stk_qty := ln_lot_ship_qty + ln_lot_provide_qty + ln_lot_inv_out_qty
                      + ln_lot_inv_in_qty + ln_lot_produce_qty + ln_lot_order_qty;
--
    -- �����\���̎Z�o
    ln_can_enc_qty := ln_onhand_stk_qty - ln_fin_stk_qty;
--
    -- �����\�����傫���ꍇ
    IF (ir_masters_rec.qty > ln_can_enc_qty) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_20);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- �E�v�̃p�����[�^�`�F�b�N
    -- ==================================
    IF (LENGTHB(ir_masters_rec.remarks) > gn_remarks_max) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_71);
      -- ���ʊ֐���O�n���h��
      RAISE global_api_expt;
    END IF;
--
    -- ==================================
    -- �i�ڐU�֖ړI�̃p�����[�^�`�F�b�N
    -- ==================================
    -- �J�E���^�[�̏�����
    ln_count := 0;
--
    -- �N�C�b�N�R�[�h�ɑ��݂��Ă��邩���m�F
    SELECT COUNT(flvv.lookup_code)
    INTO   ln_count
    FROM   xxcmn_lookup_values_v flvv   -- ���b�N�A�b�vVIEW
    WHERE  flvv.lookup_type  = gv_lt_item_tran_cls
    AND    flvv.lookup_code  = ir_masters_rec.item_chg_aim;
--
    -- �i�ڐU�֖ړI���N�C�b�N�R�[�h�ɓo�^����Ă��Ȃ��ꍇ
    IF (ln_count < 1) THEN
      -- �G���[���b�Z�[�W���o��
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,   gv_msg_52a_15,
                                            gv_tkn_parameter, gv_tkn_item_aim,
                                            gv_tkn_value,     ir_masters_rec.item_chg_aim);
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
  END chk_param;
--
  /**********************************************************************************
   * Procedure Name   : set_masters_rec
   * Description      : �f�[�^�Z�b�g����
   ***********************************************************************************/
  PROCEDURE set_masters_rec(
    ir_masters_rec IN OUT NOCOPY masters_rec, -- 1.�`�F�b�N�Ώۃ��R�[�h
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_masters_rec'; -- �v���O������
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ==================================
    -- �v�����g(�g�D)�R�[�h�̎擾
    -- ==================================
    SELECT xilv.orgn_code               -- �v�����g�R�[�h
    INTO   ir_masters_rec.orgn_code
    FROM   xxcmn_item_locations_v xilv -- OPM�ۊǏꏊ���VIEW
    WHERE  xilv.inventory_location_id = ir_masters_rec.inventory_location_id;
--
    -- ==================================
    -- �H�����̎擾
    -- ==================================
    SELECT grb.routing_id,             -- �H��ID
           grb.routing_no,             -- �H��NO
           grb.routing_vers            -- �H���o�[�W����
    INTO   ir_masters_rec.routing_id,
           ir_masters_rec.routing_no,
           ir_masters_rec.routing_version
    FROM   gmd_routings_b       grb,   -- �H���}�X�^
           gmd_routing_class_b  grcb,  -- �H���敪�}�X�^
           gmd_routing_class_tl grct   -- �H���敪�}�X�^���{��
    WHERE  grct.routing_class_desc = gv_prf_dummy_val
    AND    grct.language           = 'JA'
    AND    grct.routing_class      = grcb.routing_class
    AND    grcb.routing_class      = grb.routing_class;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_11);
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
  END set_masters_rec;
--
  /**********************************************************************************
   * Procedure Name   : chk_formula
   * Description      : �t�H�[�~�����L���`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE chk_formula(
    ir_masters_rec IN OUT NOCOPY masters_rec, -- 1.�`�F�b�N�Ώۃ��R�[�h
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--add start 1.2
    lv_formula_status  fm_form_mst_b.formula_status%TYPE;
    lv_return_status VARCHAR2(2);
    ln_message_count NUMBER;
    lv_msg_date      VARCHAR2(2000);
    lv_msg_list      VARCHAR2(2000);
--add end 1.2
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���L���t���O�̏�����
    ir_masters_rec.is_info_flg := TRUE;
--
    -- ======================================
    -- �U�֌��i�ڂ̃t�H�[�~����ID�L���`�F�b�N
    -- ======================================
--
    -- �t�H�[�~����ID�̎擾
--mod start 1.2
--    SELECT ffmb.formula_id            -- �t�H�[�~����ID
--    INTO   ir_masters_rec.formula_id
    SELECT ffmb.formula_id             -- �t�H�[�~����ID
          ,ffmb.formula_status         -- �t�H�[�~�����X�e�[�^�X
    INTO   ir_masters_rec.formula_id
          ,lv_formula_status
--mod end 1.2
    FROM   fm_form_mst_b ffmb,         -- �t�H�[�~�����}�X�^
           fm_matl_dtl   fmd1,         -- �t�H�[�~�����}�X�^����
           fm_matl_dtl   fmd2          -- �t�H�[�~�����}�X�^����
    WHERE  ffmb.formula_id = fmd1.formula_id
    AND    ffmb.formula_id = fmd2.formula_id
    AND    fmd1.item_id    = ir_masters_rec.from_item_id
    AND    fmd2.item_id    = ir_masters_rec.to_item_id
    AND    ffmb.formula_no = ir_masters_rec.formula_no;
--
--add start 1.2
    -- �X�e�[�^�X���u��ʎg�p�̏��F�v�̏ꍇ
    IF (lv_formula_status = gv_fml_sts_appr) THEN
      NULL;
    -- �X�e�[�^�X���u�V�K�v�̏ꍇ
    ELSIF (lv_formula_status = gv_fml_sts_new) THEN
      -- �X�e�[�^�X�ύX(EBS�W��API)
      GMD_STATUS_PUB.MODIFY_STATUS(
                         P_API_VERSION    => 1.0,                       -- API�o�[�W�����ԍ�
                         P_INIT_MSG_LIST  => TRUE,                      -- ���b�Z�[�W�������t���O
                         P_ENTITY_NAME    => 'FORMULA',                 -- �t�H�[�~������
                         P_ENTITY_ID      => ir_masters_rec.formula_id, -- �t�H�[�~����ID
                         P_ENTITY_NO      => NULL,                      -- �ԍ�(NULL�Œ�)
                         P_ENTITY_VERSION => NULL,                      -- �o�[�W����(NULL�Œ�)
                         P_TO_STATUS      => gv_fml_sts_appr,           -- �X�e�[�^�X�ύX�l
                         P_IGNORE_FLAG    => FALSE,
                         X_MESSAGE_COUNT  => ln_message_count,          -- �G���[���b�Z�[�W����
                         X_MESSAGE_LIST   => lv_msg_list,               -- �G���[���b�Z�[�W
                         X_RETURN_STATUS  => lv_return_status           -- �v���Z�X�I���X�e�[�^�X
                            );
--
      -- �X�e�[�^�X�ύX�����������łȂ��ꍇ
      IF (lv_return_status <> gv_ret_sts_success) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                              gv_tkn_api_name, gv_tkn_ins_formula);
        RAISE global_api_expt;
      -- �X�e�[�^�X�ύX�����������̏ꍇ
      ELSIF (lv_return_status = gv_ret_sts_success) THEN
        -- �m�菈��
        COMMIT;
      END IF;
--
    -- �X�e�[�^�X����L�ȊO�̏ꍇ
    ELSE
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_66,
                                            gv_tkn_formula, ir_masters_rec.formula_no);
      RAISE global_api_expt;
    END IF;
--add end 1.2
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
  END chk_formula;
--
  /**********************************************************************************
   * Procedure Name   : ins_formula
   * Description      : �t�H�[�~�����o�^(A-3)
   ***********************************************************************************/
  PROCEDURE ins_formula(
    ir_masters_rec IN OUT NOCOPY masters_rec, -- 1.�����Ώۃ��R�[�h
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_return_status VARCHAR2(2);
    ln_message_count NUMBER;
    lv_msg_date      VARCHAR2(2000);
    -- MODIFY_STATUS API�p�ϐ�
    lv_msg_list      VARCHAR2(2000);
--
    -- �t�H�[�~�����e�[�u���^�ϐ�
    lt_formula_header_tbl GMD_FORMULA_PUB.FORMULA_INSERT_HDR_TBL_TYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
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
    lt_formula_header_tbl(1).release_type   := 0;                         -- �����^�C�v(0:����)
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
    lt_formula_header_tbl(2).release_type   := 0;                           -- �����^�C�v(0:����)
--
    -- �t�H�[�~�����o�^(EBS�W��API)
    GMD_FORMULA_PUB.INSERT_FORMULA(
                         P_API_VERSION        => 1.0,                   -- API�o�[�W�����ԍ�
                         P_INIT_MSG_LIST      => FND_API.G_FALSE,       -- ���b�Z�[�W�������t���O
                         P_COMMIT             => FND_API.G_TRUE,        -- �����R�~�b�g�t���O
                         P_CALLED_FROM_FORMS  => 'NO',
                         X_RETURN_STATUS      => lv_return_status,      -- �v���Z�X�I���X�e�[�^�X
                         X_MSG_COUNT          => ln_message_count,      -- �G���[���b�Z�[�W����
                         X_MSG_DATA           => lv_msg_date,           -- �G���[���b�Z�[�W
                         P_FORMULA_HEADER_TBL => lt_formula_header_tbl,
                         P_ALLOW_ZERO_ING_QTY => 'FALSE'
                                  );
    -- �o�^�����������łȂ��ꍇ
    IF (lv_return_status <> gv_ret_sts_success) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_ins_formula);
      RAISE global_api_expt;
    -- �o�^�����������̏ꍇ
    ELSIF (lv_return_status = gv_ret_sts_success) THEN
      -- �t�H�[�~����ID�̎擾
      SELECT ffmb.formula_id           -- �t�H�[�~����ID
      INTO   ir_masters_rec.formula_id
      FROM   fm_form_mst_b ffmb,       -- �t�H�[�~�����}�X�^
             fm_matl_dtl   fmd1,       -- �t�H�[�~�����}�X�^����
             fm_matl_dtl   fmd2        -- �t�H�[�~�����}�X�^����
      WHERE  ffmb.formula_id = fmd1.formula_id
      AND    ffmb.formula_id = fmd2.formula_id
      AND    fmd1.item_id    = ir_masters_rec.from_item_id
      AND    fmd2.item_id    = ir_masters_rec.to_item_id
      AND    ffmb.formula_no = ir_masters_rec.formula_no;
    END IF;
--
    -- �X�e�[�^�X�ύX(EBS�W��API)
    GMD_STATUS_PUB.MODIFY_STATUS(
                       P_API_VERSION    => 1.0,                       -- API�o�[�W�����ԍ�
                       P_INIT_MSG_LIST  => TRUE,                      -- ���b�Z�[�W�������t���O
                       P_ENTITY_NAME    => 'FORMULA',                 -- �t�H�[�~������
                       P_ENTITY_ID      => ir_masters_rec.formula_id, -- �t�H�[�~����ID
                       P_ENTITY_NO      => NULL,                      -- �ԍ�(NULL�Œ�)
                       P_ENTITY_VERSION => NULL,                      -- �o�[�W����(NULL�Œ�)
                       P_TO_STATUS      => gv_fml_sts_appr,           -- �X�e�[�^�X�ύX�l
                       P_IGNORE_FLAG    => FALSE,
                       X_MESSAGE_COUNT  => ln_message_count,          -- �G���[���b�Z�[�W����
                       X_MESSAGE_LIST   => lv_msg_list,               -- �G���[���b�Z�[�W
                       X_RETURN_STATUS  => lv_return_status           -- �v���Z�X�I���X�e�[�^�X
                          );
--
    -- �X�e�[�^�X�ύX�����������łȂ��ꍇ
    IF (lv_return_status <> gv_ret_sts_success) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_ins_formula);
      RAISE global_api_expt;
    -- �X�e�[�^�X�ύX�����������̏ꍇ
    ELSIF (lv_return_status = gv_ret_sts_success) THEN
      -- �m�菈��
      COMMIT;
    END IF;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_11);
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
   * Description      : ���V�s�L���`�F�b�N(A-4)
   ***********************************************************************************/
  PROCEDURE chk_recipe(
    ir_masters_rec IN OUT NOCOPY masters_rec, -- 1.�`�F�b�N�Ώۃ��R�[�h
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--add start 1.2
    lv_recipe_status                gmd_recipes_b.recipe_status%TYPE;
    lv_recipe_no                    gmd_recipes_b.recipe_no%TYPE;
    ln_recipe_validity_rule_id      gmd_recipe_validity_rules.recipe_validity_rule_id%TYPE;
    lv_validity_rule_status         gmd_recipe_validity_rules.validity_rule_status%TYPE;
    lv_return_status VARCHAR2(2);
    ln_message_count NUMBER;
    lv_msg_date      VARCHAR2(4000);
    lv_msg_list      VARCHAR2(2000);
--add end 1.2
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���L���t���O�̏�����
    ir_masters_rec.is_info_flg := TRUE;
--
    -- ���V�sID�̎擾
--mod start 1.2
--    SELECT greb.recipe_id              -- ���V�sID
--    INTO   ir_masters_rec.recipe_id
    SELECT greb.recipe_id              -- ���V�sID
          ,greb.recipe_status          -- ���V�s�X�e�[�^�X
          ,greb.recipe_no              -- ���V�sNo
    INTO   ir_masters_rec.recipe_id
          ,lv_recipe_status
          ,lv_recipe_no
--mod end 1.2
    FROM   gmd_recipes_b             greb, -- ���V�s�}�X�^
           gmd_routings_b            grob  -- �H���}�X�^
    WHERE  greb.formula_id      = ir_masters_rec.formula_id
    AND    greb.routing_id      = grob.routing_id
    AND    grob.routing_no      = ir_masters_rec.routing_no
    AND    grob.routing_class   = (SELECT grb.routing_class
                                   FROM   gmd_routings_b        grb,  -- �H���}�X�^
                                          gmd_routing_class_b   grcb, -- �H���敪�}�X�^
                                          gmd_routing_class_tl  grct  -- �H���敪�}�X�^���{��
                                   WHERE  grb.routing_class       = grcb.routing_class
                                   AND    grcb.routing_class      = grct.routing_class
                                   AND    grct.language           = 'JA'
                                   AND    grct.routing_class_desc = gv_prf_dummy_val
                                   AND    grb.routing_id = ir_masters_rec.routing_id);
--
--add start 1.2
    -- �X�e�[�^�X���u��ʎg�p�̏��F�v�̏ꍇ
    IF (lv_recipe_status = gv_fml_sts_appr) THEN
      NULL;
    -- �X�e�[�^�X���u�V�K�v�̏ꍇ
    ELSIF (lv_recipe_status = gv_fml_sts_new) THEN
      -- ���V�s�X�e�[�^�X�ύX(EBS�W��API)
      GMD_STATUS_PUB.MODIFY_STATUS(
                                   P_API_VERSION    => 1.0,
                                   P_INIT_MSG_LIST  => TRUE,
                                   P_ENTITY_NAME    => 'RECIPE',
                                   P_ENTITY_ID      => ir_masters_rec.recipe_id,
                                   P_ENTITY_NO      => NULL,            -- (NULL�Œ�)
                                   P_ENTITY_VERSION => NULL,            -- (NULL�Œ�)
                                   P_TO_STATUS      => gv_fml_sts_appr,
                                   P_IGNORE_FLAG    => FALSE,
                                   X_MESSAGE_COUNT  => ln_message_count,
                                   X_MESSAGE_LIST   => lv_msg_list,
                                   X_RETURN_STATUS  => lv_return_status
                                  );
--
      -- �X�e�[�^�X�ύX�����������łȂ��ꍇ
      IF (lv_return_status <> gv_ret_sts_success) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                              gv_tkn_api_name, gv_tkn_upd_recipe);
        RAISE global_api_expt;
      ELSE
        COMMIT;
      END IF;
--
    -- �X�e�[�^�X����L�ȊO�̏ꍇ
    ELSE
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_67,
                                            gv_tkn_recipe, lv_recipe_no);
      RAISE global_api_expt;
    END IF;
--
    -- �Ó������[��ID�̎擾
    SELECT grvr.recipe_validity_rule_id
          ,grvr.validity_rule_status
    INTO   ln_recipe_validity_rule_id
          ,lv_validity_rule_status
    FROM   gmd_recipe_validity_rules grvr   -- ���V�s�Ó������[���}�X�^
    WHERE  grvr.recipe_id = ir_masters_rec.recipe_id;
--
    -- �X�e�[�^�X���u��ʎg�p�̏��F�v�̏ꍇ
    IF (lv_validity_rule_status = gv_fml_sts_appr) THEN
      NULL;
    -- �X�e�[�^�X���u�V�K�v�̏ꍇ
    ELSIF (lv_validity_rule_status = gv_fml_sts_new) THEN
      -- �Ó������[���X�e�[�^�X�ύX(EBS�W��API)
      GMD_STATUS_PUB.MODIFY_STATUS(
                                   P_API_VERSION    => 1.0,
                                   P_INIT_MSG_LIST  => TRUE,
                                   P_ENTITY_NAME    => 'VALIDITY',
                                   P_ENTITY_ID      => ln_recipe_validity_rule_id,
                                   P_ENTITY_NO      => NULL,            -- (NULL�Œ�)
                                   P_ENTITY_VERSION => NULL,            -- (NULL�Œ�)
                                   P_TO_STATUS      => gv_fml_sts_appr,
                                   P_IGNORE_FLAG    => FALSE,
                                   X_MESSAGE_COUNT  => ln_message_count,
                                   X_MESSAGE_LIST   => lv_msg_list,
                                   X_RETURN_STATUS  => lv_return_status
                                  );
--
      -- �X�e�[�^�X�ύX�����������łȂ��ꍇ
      IF (lv_return_status <> gv_ret_sts_success) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                              gv_tkn_api_name, gv_tkn_upd_recipe);
        RAISE global_api_expt;
      -- �X�e�[�^�X�ύX�����������̏ꍇ
      ELSIF (lv_return_status = gv_ret_sts_success) THEN
        -- �m�菈��
        COMMIT;
      END IF;
--
    -- �X�e�[�^�X����L�ȊO�̏ꍇ
    ELSE
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_69,
                                            gv_tkn_recipe, lv_recipe_no);
      RAISE global_api_expt;
    END IF;
--add end 1.2
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
   * Procedure Name   : upd_recipe
   * Description      : ���V�s�X�V
   ***********************************************************************************/
  PROCEDURE upd_recipe(
    ir_masters_rec IN OUT NOCOPY masters_rec, -- 1.�����Ώۃ��R�[�h
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_recipe'; -- �v���O������
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
    -- CREATE_RECIPE_HEADER API�p�ϐ�
    lv_return_status VARCHAR2(2);
    ln_message_count NUMBER;
    lv_msg_date      VARCHAR2(4000);
    -- MODIFY_STATUS API�p�ϐ�
    lv_msg_list      VARCHAR2(2000);
--
    -- ���V�s�e�[�u���^�ϐ�
    lt_recipe_hdr_tbl    GMD_RECIPE_HEADER.RECIPE_TBL;
    lt_recipe_hdr_flex   GMD_RECIPE_HEADER.RECIPE_UPDATE_FLEX;
--
-- for debug
	l_data					VARCHAR2(2000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- ���V�sID�̎擾
    SELECT greb.recipe_id              -- ���V�sID
    INTO   ir_masters_rec.recipe_id
    FROM   gmd_recipes_b             greb, -- ���V�s�}�X�^
           gmd_routings_b            grob  -- �H���}�X�^
    WHERE  greb.formula_id      = ir_masters_rec.formula_id
    AND    greb.routing_id      IS NULL
    AND    grob.routing_no      = ir_masters_rec.routing_no
    AND    grob.routing_class   = (SELECT grb.routing_class
                                   FROM   gmd_routings_b        grb,  -- �H���}�X�^
                                          gmd_routing_class_b   grcb, -- �H���敪�}�X�^
                                          gmd_routing_class_tl  grct  -- �H���敪�}�X�^���{��
                                   WHERE  grb.routing_class       = grcb.routing_class
                                   AND    grcb.routing_class      = grct.routing_class
                                   AND    grct.language           = 'JA'
                                   AND    grct.routing_class_desc = gv_prf_dummy_val
                                   AND    grb.routing_id = ir_masters_rec.routing_id);
--
    -- ===============================
    -- �o�^�����Z�b�g
    -- ===============================
    -- ���V�sID
    lt_recipe_hdr_tbl(1).recipe_id          := ir_masters_rec.recipe_id;
    -- �H��ID
    lt_recipe_hdr_tbl(1).routing_id         := ir_masters_rec.routing_id;
    -- �H���ԍ�
    lt_recipe_hdr_tbl(1).routing_no         := ir_masters_rec.routing_no;
    -- �H���o�[�W����
    lt_recipe_hdr_tbl(1).routing_vers       := ir_masters_rec.routing_version;
    -- ���V�s�X�V(EBS�W��API)
    GMD_RECIPE_HEADER.UPDATE_RECIPE_HEADER(
                                           P_API_VERSION        => 2.0,
                                           P_INIT_MSG_LIST      => FND_API.G_FALSE,
                                           P_COMMIT             => FND_API.G_TRUE,
                                           P_CALLED_FROM_FORMS  => 'NO',
                                           X_RETURN_STATUS      => lv_return_status,
                                           X_MSG_COUNT          => ln_message_count,
                                           X_MSG_DATA           => lv_msg_date,
                                           P_RECIPE_HEADER_TBL  => lt_recipe_hdr_tbl,
                                           P_RECIPE_UPDATE_FLEX => lt_recipe_hdr_flex
                                          );
    -- �X�V�����������łȂ��ꍇ
    IF (lv_return_status <> gv_ret_sts_success) THEN
-- add 2008/05/20
      -- �G���[���b�Z�[�W���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
      IF (ln_message_count > 0) THEN
        FOR i IN 1..ln_message_count LOOP
          -- ���̃��b�Z�[�W�̎擾
          l_data := FND_MSG_PUB.Get(i, FND_API.G_FALSE);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'l_data = '|| l_data);
        END LOOP;
      END IF;
-- add 2008/05/20
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_upd_recipe);
      RAISE global_api_expt;
    END IF;
--
    -- ���V�s�X�e�[�^�X�ύX(EBS�W��API)
    GMD_STATUS_PUB.MODIFY_STATUS(
                                 P_API_VERSION    => 1.0,
                                 P_INIT_MSG_LIST  => TRUE,
                                 P_ENTITY_NAME    => 'RECIPE',
                                 P_ENTITY_ID      => ir_masters_rec.recipe_id,
                                 P_ENTITY_NO      => NULL,            -- (NULL�Œ�)
                                 P_ENTITY_VERSION => NULL,            -- (NULL�Œ�)
                                 P_TO_STATUS      => gv_fml_sts_appr,
                                 P_IGNORE_FLAG    => FALSE,
                                 X_MESSAGE_COUNT  => ln_message_count,
                                 X_MESSAGE_LIST   => lv_msg_list,
                                 X_RETURN_STATUS  => lv_return_status
                                );
--
    -- �X�e�[�^�X�ύX�����������łȂ��ꍇ
    IF (lv_return_status <> gv_ret_sts_success) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_upd_recipe);
      RAISE global_api_expt;
    END IF;
--
    -- �Ó������[��ID�̎擾
    SELECT grvr.recipe_validity_rule_id
    INTO   ir_masters_rec.recipe_validity_rule_id
    FROM   gmd_recipe_validity_rules grvr   -- ���V�s�Ó������[���}�X�^
    WHERE  grvr.recipe_id = ir_masters_rec.recipe_id;
--
    -- �Ó������[���X�e�[�^�X�ύX(EBS�W��API)
    GMD_STATUS_PUB.MODIFY_STATUS(
                                 P_API_VERSION    => 1.0,
                                 P_INIT_MSG_LIST  => TRUE,
                                 P_ENTITY_NAME    => 'VALIDITY',
                                 P_ENTITY_ID      => ir_masters_rec.recipe_validity_rule_id,
                                 P_ENTITY_NO      => NULL,            -- (NULL�Œ�)
                                 P_ENTITY_VERSION => NULL,            -- (NULL�Œ�)
                                 P_TO_STATUS      => gv_fml_sts_appr,
                                 P_IGNORE_FLAG    => FALSE,
                                 X_MESSAGE_COUNT  => ln_message_count,
                                 X_MESSAGE_LIST   => lv_msg_list,
                                 X_RETURN_STATUS  => lv_return_status
                                );
--
    -- �X�e�[�^�X�ύX�����������łȂ��ꍇ
    IF (lv_return_status <> gv_ret_sts_success) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_upd_recipe);
      RAISE global_api_expt;
    -- �X�e�[�^�X�ύX�����������̏ꍇ
    ELSIF (lv_return_status = gv_ret_sts_success) THEN
      -- �m�菈��
      COMMIT;
--
    END IF;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_11);
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
  END upd_recipe;
--
  /**********************************************************************************
   * Procedure Name   : chk_lot
   * Description      : ���b�g�L���`�F�b�N(A-6)
   ***********************************************************************************/
  PROCEDURE chk_lot(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- 1.�`�F�b�N�Ώۃ��R�[�h
    ov_errbuf       OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���L���t���O�̏�����
    ir_masters_rec.is_info_flg := TRUE;
--
    -- ======================================
    -- ���b�gID�L���`�F�b�N
    -- ======================================
    -- ���b�g���̎擾
    SELECT ilm.lot_id,        -- ���b�gID
           ilm.lot_desc,      -- �E�v
           ilm.attribute1,    -- �����N����
           ilm.attribute2,    -- �ŗL�L��
           ilm.attribute3,    -- �ܖ�����
           ilm.attribute4,    -- �[����(����)
           ilm.attribute5,    -- �[����(�ŏI)
           ilm.attribute6,    -- �݌ɓ���
           ilm.attribute7,    -- �݌ɒP��
           ilm.attribute8,    -- �����
           ilm.attribute9,    -- �d���`��
           ilm.attribute10,   -- �����敪
           ilm.attribute11,   -- �N�x
           ilm.attribute12,   -- �Y�n
           ilm.attribute13,   -- �^�C�v
           ilm.attribute14,   -- �����N�P
           ilm.attribute15,   -- �����N�Q
           ilm.attribute16,   -- ���Y�`�[�敪
           ilm.attribute17,   -- ���C��No
           ilm.attribute18,   -- �E�v
           ilm.attribute19,   -- �����N�R
           ilm.attribute20,   -- ���������H��
           ilm.attribute21,   -- �������������b�g�ԍ�
           ilm.attribute22,   -- �����˗�No
           ilm.attribute23,   -- ���b�g�X�e�[�^�X
           ilm.attribute24,   -- �쐬�敪
           ilm.attribute25,   -- ����25
           ilm.attribute26,   -- ����26
           ilm.attribute27,   -- ����27
           ilm.attribute28,   -- ����28
           ilm.attribute29,   -- ����29
           ilm.attribute30    -- ����30
    INTO   ir_masters_rec.to_lot_id,
           ir_masters_rec.lot_desc,
           ir_masters_rec.lot_attribute1,
           ir_masters_rec.lot_attribute2,
           ir_masters_rec.lot_attribute3,
           ir_masters_rec.lot_attribute4,
           ir_masters_rec.lot_attribute5,
           ir_masters_rec.lot_attribute6,
           ir_masters_rec.lot_attribute7,
           ir_masters_rec.lot_attribute8,
           ir_masters_rec.lot_attribute9,
           ir_masters_rec.lot_attribute10,
           ir_masters_rec.lot_attribute11,
           ir_masters_rec.lot_attribute12,
           ir_masters_rec.lot_attribute13,
           ir_masters_rec.lot_attribute14,
           ir_masters_rec.lot_attribute15,
           ir_masters_rec.lot_attribute16,
           ir_masters_rec.lot_attribute17,
           ir_masters_rec.lot_attribute18,
           ir_masters_rec.lot_attribute19,
           ir_masters_rec.lot_attribute20,
           ir_masters_rec.lot_attribute21,
           ir_masters_rec.lot_attribute22,
           ir_masters_rec.lot_attribute23,
           ir_masters_rec.lot_attribute24,
           ir_masters_rec.lot_attribute25,
           ir_masters_rec.lot_attribute26,
           ir_masters_rec.lot_attribute27,
           ir_masters_rec.lot_attribute28,
           ir_masters_rec.lot_attribute29,
           ir_masters_rec.lot_attribute30
    FROM   ic_lots_mst  ilm   -- OPM���b�g�}�X�^
    WHERE  ilm.lot_no  = ir_masters_rec.lot_no
    AND    ilm.item_id = ir_masters_rec.to_item_id;
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
   * Description      : ���b�g�쐬(A-7)
   ***********************************************************************************/
  PROCEDURE create_lot(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- 1.�����Ώۃ��R�[�h
    ov_errbuf       OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_return_status VARCHAR2(2);     -- ���^�[���X�e�[�^�X
    ln_message_count NUMBER;          -- ���b�Z�[�W�J�E���g
    lv_msg_date      VARCHAR2(10000); -- ���b�Z�[�W
    lb_return_status BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_lot_rec     GMIGAPI.LOT_REC_TYP;
    lr_ic_lots_cpg ic_lots_cpg%ROWTYPE;
    lr_lot_mst     ic_lots_mst%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    lb_return_status := GMIGUTL.SETUP(FND_GLOBAL.USER_NAME()); -- CREATE_LOT API_VERSION�⏕(�K�{)
--
        -- ���b�g���̎擾
    SELECT lot_desc,          -- �E�v
           ilm.attribute1,    -- �����N����
           ilm.attribute2,    -- �ŗL�L��
           ilm.attribute3,    -- �ܖ�����
           ilm.attribute4,    -- �[����(����)
           ilm.attribute5,    -- �[����(�ŏI)
           ilm.attribute6,    -- �݌ɓ���
           ilm.attribute7,    -- �݌ɒP��
           ilm.attribute8,    -- �����
           ilm.attribute9,    -- �d���`��
           ilm.attribute10,   -- �����敪
           ilm.attribute11,   -- �N�x
           ilm.attribute12,   -- �Y�n
           ilm.attribute13,   -- �^�C�v
           ilm.attribute14,   -- �����N�P
           ilm.attribute15,   -- �����N�Q
           ilm.attribute16,   -- ���Y�`�[�敪
           ilm.attribute17,   -- ���C��No
           ilm.attribute18,   -- �E�v
           ilm.attribute19,   -- �����N�R
           ilm.attribute20,   -- ���������H��
           ilm.attribute21,   -- �������������b�g�ԍ�
           ilm.attribute22,   -- �����˗�No
           ilm.attribute23,   -- ���b�g�X�e�[�^�X
           ilm.attribute24,   -- �쐬�敪
           ilm.attribute25,   -- ����25
           ilm.attribute26,   -- ����26
           ilm.attribute27,   -- ����27
           ilm.attribute28,   -- ����28
           ilm.attribute29,   -- ����29
           ilm.attribute30    -- ����30
    INTO   ir_masters_rec.lot_desc,
           ir_masters_rec.lot_attribute1,
           ir_masters_rec.lot_attribute2,
           ir_masters_rec.lot_attribute3,
           ir_masters_rec.lot_attribute4,
           ir_masters_rec.lot_attribute5,
           ir_masters_rec.lot_attribute6,
           ir_masters_rec.lot_attribute7,
           ir_masters_rec.lot_attribute8,
           ir_masters_rec.lot_attribute9,
           ir_masters_rec.lot_attribute10,
           ir_masters_rec.lot_attribute11,
           ir_masters_rec.lot_attribute12,
           ir_masters_rec.lot_attribute13,
           ir_masters_rec.lot_attribute14,
           ir_masters_rec.lot_attribute15,
           ir_masters_rec.lot_attribute16,
           ir_masters_rec.lot_attribute17,
           ir_masters_rec.lot_attribute18,
           ir_masters_rec.lot_attribute19,
           ir_masters_rec.lot_attribute20,
           ir_masters_rec.lot_attribute21,
           ir_masters_rec.lot_attribute22,
           ir_masters_rec.lot_attribute23,
           ir_masters_rec.lot_attribute24,
           ir_masters_rec.lot_attribute25,
           ir_masters_rec.lot_attribute26,
           ir_masters_rec.lot_attribute27,
           ir_masters_rec.lot_attribute28,
           ir_masters_rec.lot_attribute29,
           ir_masters_rec.lot_attribute30
    FROM   ic_lots_mst  ilm   -- OPM���b�g�}�X�^
    WHERE  ilm.lot_no  = ir_masters_rec.lot_no
    AND    ilm.item_id = ir_masters_rec.from_item_id;
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
    lr_lot_rec.sublot_no        := NULL;
    lr_lot_rec.lot_desc         :=  ir_masters_rec.lot_desc;       -- �E�v
    lr_lot_rec.user_name        := FND_GLOBAL.USER_NAME;
    lr_lot_rec.lot_created      := SYSDATE;
--
    --���b�g�쐬API
    GMIPAPI.CREATE_LOT(
                       P_API_VERSION      => 3.0,                        -- API�o�[�W�����ԍ�
                       P_INIT_MSG_LIST    => FND_API.G_FALSE,            -- ���b�Z�[�W�������t���O
                       P_COMMIT           => FND_API.G_TRUE,            -- �����R�~�b�g�t���O
                       P_VALIDATION_LEVEL => FND_API.G_VALID_LEVEL_FULL, -- ���؃��x��
                       P_LOT_REC          => lr_lot_rec,
                       X_IC_LOTS_MST_ROW  => lr_lot_mst,
                       X_IC_LOTS_CPG_ROW  => lr_ic_lots_cpg,
                       X_RETURN_STATUS    => lv_return_status,           -- �v���Z�X�I���X�e�[�^�X
                       X_MSG_COUNT        => ln_message_count,           -- �G���[���b�Z�[�W����
                       X_MSG_DATA         => lv_msg_date                 -- �G���[���b�Z�[�W
                      );
--
    -- ���b�g�쐬�����������łȂ��ꍇ
    IF (lv_return_status <> gv_ret_sts_success) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_create_lot);
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
    AND    ilm.item_id = ir_masters_rec.to_item_id;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_11);
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
--add start 1.3
  /**********************************************************************************
   * Procedure Name   : get_validity_rule_id
   * Description      : �Ó������[��ID
   ***********************************************************************************/
  PROCEDURE get_validity_rule_id(
    ir_masters_rec IN OUT NOCOPY masters_rec, -- 1.�����Ώۃ��R�[�h
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���V�sID�̎擾
    SELECT greb.recipe_id              -- ���V�sID
    INTO   ln_recipe_id
    FROM   gmd_recipes_b             greb, -- ���V�s�}�X�^
           gmd_routings_b            grob  -- �H���}�X�^
    WHERE  greb.formula_id      = ir_masters_rec.formula_id
    AND    greb.routing_id      = grob.routing_id
    AND    grob.routing_no      = ir_masters_rec.routing_no
    AND    grob.routing_class   = (SELECT grb.routing_class
                                   FROM   gmd_routings_b        grb,  -- �H���}�X�^
                                          gmd_routing_class_b   grcb, -- �H���敪�}�X�^
                                          gmd_routing_class_tl  grct  -- �H���敪�}�X�^���{��
                                   WHERE  grb.routing_class       = grcb.routing_class
                                   AND    grcb.routing_class      = grct.routing_class
                                   AND    grct.language           = 'JA'
                                   AND    grct.routing_class_desc = gv_prf_dummy_val
                                   AND    grb.routing_id = ir_masters_rec.routing_id);
--
    -- �Ó������[��ID�̎擾
    SELECT grvr.recipe_validity_rule_id
    INTO   ir_masters_rec.recipe_validity_rule_id
    FROM   gmd_recipe_validity_rules grvr   -- ���V�s�Ó������[���}�X�^
    WHERE  grvr.recipe_id = ln_recipe_id;
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
--add end 1.3
  /**********************************************************************************
   * Procedure Name   : create_batch
   * Description      : �o�b�`�쐬(A-8)
   ***********************************************************************************/
  PROCEDURE create_batch(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- 1.�����Ώۃ��R�[�h
    ov_errbuf       OUT    NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT    NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT    NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lr_in_batch_hdr  GME_BATCH_HEADER%ROWTYPE;     -- ���Y�o�b�`�w�b�_(����)
    lr_out_batch_hrd GME_BATCH_HEADER%ROWTYPE;     -- ���Y�o�b�`�w�b�_(�o��)
    lr_batch_dtl     GME_MATERIAL_DETAILS%ROWTYPE; -- ���Y���ޗ��ڍ�
    lt_unalloc_mtl   GME_API_PUB.UNALLOCATED_MATERIALS_TAB;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    lr_in_batch_hdr.plant_code              := ir_masters_rec.orgn_code;    -- 1.�g�D�R�[�h(�K�{)
    lr_in_batch_hdr.formula_id              := ir_masters_rec.formula_id;   -- 2.�t�H�[�~����ID
    lr_in_batch_hdr.routing_id              := ir_masters_rec.routing_id;   -- 3.�H��ID
    lr_in_batch_hdr.actual_start_date       := ir_masters_rec.item_sysdate; -- 4.���ъJ�n��
    lr_in_batch_hdr.actual_cmplt_date       := ir_masters_rec.item_sysdate; -- 5.���яI����
    lr_in_batch_hdr.attribute6              := ir_masters_rec.remarks;      -- 6.�E�v
    lr_in_batch_hdr.attribute7              := ir_masters_rec.item_chg_aim; -- 7.�i�ڐU�֖ړI
    lr_batch_dtl.item_id                    := ir_masters_rec.from_item_id; -- 8.�i��ID
    lr_batch_dtl.wip_plan_qty               := ir_masters_rec.qty;          -- 9.�\�萔��
    lr_batch_dtl.original_qty               := ir_masters_rec.qty;          -- 10.���ѐ���
    lr_batch_dtl.item_um                    := ir_masters_rec.from_item_um; -- 11.�P�ʂP
    lr_in_batch_hdr.batch_type              := gn_bat_type_batch;           -- 12.�o�b�`�^�C�v
    lr_in_batch_hdr.wip_whse_code           := ir_masters_rec.whse_code;    -- 13.�q�ɃR�[�h
    -- 13.�Ó������[��ID
--add start 1.3
    --�Ó������[��ID���Z�b�g����Ă��Ȃ��ꍇ
    IF (ir_masters_rec.recipe_validity_rule_id IS NULL) THEN
      get_validity_rule_id(ir_masters_rec,  -- 1.�`�F�b�N�Ώۃ��R�[�h
                           lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
                           lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
                           lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    END IF;
--add end 1.3
    lr_in_batch_hdr.recipe_validity_rule_id := ir_masters_rec.recipe_validity_rule_id;
--
    -- ======================================
    -- �o�b�`�쐬API
    -- ======================================
    GME_API_PUB.CREATE_BATCH(
                       P_API_VERSION          => GME_API_PUB.API_VERSION,
                       P_VALIDATION_LEVEL     => GME_API_PUB.MAX_ERRORS,
                       P_INIT_MSG_LIST        => FALSE,
                       P_COMMIT               => FALSE,
                       P_BATCH_HEADER         => lr_in_batch_hdr,             -- �K�{
                       P_BATCH_SIZE           => ir_masters_rec.qty,          -- �K�{
                       P_BATCH_SIZE_UOM       => ir_masters_rec.from_item_um, -- �K�{
                       P_CREATION_MODE        => 'PRODUCT',                   -- �K�{
                       P_RECIPE_ID            => NULL,                        -- ���V�sID
                       P_RECIPE_NO            => NULL,                        -- ���V�sNo
                       P_RECIPE_VERSION       => NULL,                        -- ���V�s�o�[�W����
                       P_PRODUCT_NO           => NULL,                        -- �H��No
                       P_PRODUCT_ID           => NULL,                        -- �H��ID
                       P_IGNORE_QTY_BELOW_CAP => TRUE,
                       P_IGNORE_SHORTAGES     => TRUE,                        -- �K�{
                       P_USE_SHOP_CAL         => NULL,
                       P_CONTIGUITY_OVERRIDE  => 1,
                       X_BATCH_HEADER         => lr_out_batch_hrd,            -- �K�{
                       X_MESSAGE_COUNT        => ln_message_count,
                       X_MESSAGE_LIST         => lv_message_list,
                       X_RETURN_STATUS        => lv_return_status,
                       X_UNALLOCATED_MATERIAL => lt_unalloc_mtl               -- �񊄓����e�[�u��
    );
--
    -- �o�b�`�쐬�����������łȂ��ꍇ
    IF (lv_return_status <> gv_ret_sts_success) THEN
--
      -- add 2008/05/20
      -- �G���[���b�Z�[�W���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lv_return_status ='||lv_return_status);
      IF (ln_message_count > 0) THEN
        FOR i IN 1..ln_message_count LOOP
          -- ���̃��b�Z�[�W�̎擾
          l_data := FND_MSG_PUB.Get(i, FND_API.G_FALSE);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'l_data = '|| l_data);
        END LOOP;
      END IF;
      -- add 2008/05/20
--
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_create_bat);
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
    SELECT gmd.material_detail_id                -- ���Y�����ڍ�ID
    INTO   ir_masters_rec.from_material_detail_id
    FROM   gme_material_details gmd              -- ���Y�����ڍ�
    WHERE  gmd.batch_id = ir_masters_rec.batch_id
    AND    gmd.item_id  = ir_masters_rec.from_item_id;
--
    -- �U�֐�i�ڂ̐��Y�����ڍ�ID�̎擾
    SELECT gmd.material_detail_id                -- ���Y�����ڍ�ID
    INTO   ir_masters_rec.to_material_detail_id
    FROM   gme_material_details gmd              -- ���Y�����ڍ�
    WHERE  gmd.batch_id = ir_masters_rec.batch_id
    AND    gmd.item_id  = ir_masters_rec.to_item_id;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_11);
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
   * Procedure Name   : input_lot_assign
   * Description      : ���̓��b�g����(A-9)
   ***********************************************************************************/
  PROCEDURE input_lot_assign(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- 1.�����Ώۃ��R�[�h
    ov_errbuf       OUT    NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT    NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT    NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'input_lot_assign'; -- �v���O������
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
    lv_msg_date      VARCHAR2(10000); -- ���b�Z�[�W
    lv_message_list  VARCHAR2(200);   -- ���b�Z�[�W���X�g
--
    -- *** ���[�J���E���R�[�h ***
    lr_material_datail GME_MATERIAL_DETAILS%ROWTYPE;
    lr_tran_row_in     GME_INVENTORY_TXNS_GTMP%ROWTYPE;
    lr_tran_row_out    GME_INVENTORY_TXNS_GTMP%ROWTYPE;
    lr_def_tran_row    GME_INVENTORY_TXNS_GTMP%ROWTYPE;
    lr_in_batch_hdr    GME_BATCH_HEADER%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    lr_tran_row_in.item_id            := ir_masters_rec.from_item_id;            -- 1.�i��ID
    lr_tran_row_in.whse_code          := ir_masters_rec.whse_code;               -- 2.�q�ɃR�[�h
    lr_tran_row_in.lot_id             := ir_masters_rec.from_lot_id;             -- 3.���b�gID
    lr_tran_row_in.location           := ir_masters_rec.inventory_location_code; -- 4.�ۊǏꏊ
    lr_tran_row_in.doc_id             := ir_masters_rec.batch_id;                -- �o�b�`ID
    lr_tran_row_in.doc_type           := 'PROD';                                 -- 5.�����^�C�v
    lr_tran_row_in.trans_date         := ir_masters_rec.item_sysdate;            -- ���ѓ�
    lr_tran_row_in.trans_qty          := ir_masters_rec.qty;                     -- 6.���ʂP
    lr_tran_row_in.trans_um           := ir_masters_rec.from_item_um;            -- 7.�P�ʂP
    lr_tran_row_in.completed_ind      := 0;                                      -- �����t���O
    lr_tran_row_in.material_detail_id := ir_masters_rec.from_material_detail_id; -- ���Y�����ڍ�ID
    lr_in_batch_hdr.batch_id          := ir_masters_rec.batch_id;                -- �o�b�`ID
--
    -- ======================================
    -- ���b�g����API
    -- ======================================
    GME_API_PUB.INSERT_LINE_ALLOCATION(
                                       P_API_VERSION      => GME_API_PUB.API_VERSION,
                                       P_VALIDATION_LEVEL => GME_API_PUB.MAX_ERRORS,
                                       P_INIT_MSG_LIST    => FALSE,
                                       P_COMMIT           => FALSE,
                                       P_TRAN_ROW         => lr_tran_row_in,
                                       P_LOT_NO           => NULL,
                                       P_SUBLOT_NO        => NULL,
                                       P_CREATE_LOT       => FALSE,
                                       P_IGNORE_SHORTAGE  => TRUE,
                                       P_SCALE_PHANTOM    => FALSE,
                                       X_MATERIAL_DETAIL  => lr_material_datail,
                                       X_TRAN_ROW         => lr_tran_row_out,
                                       X_DEF_TRAN_ROW     => lr_def_tran_row,
                                       X_MESSAGE_COUNT    => ln_message_count,
                                       X_MESSAGE_LIST     => lv_message_list,
                                       X_RETURN_STATUS    => lv_return_status
                                      );
--
    -- ���̓��b�g���������������łȂ��ꍇ
    IF (lv_return_status <> gv_ret_sts_success) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_input_lot);
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
  END input_lot_assign;
--
  /**********************************************************************************
   * Procedure Name   : output_lot_assign
   * Description      : �o�̓��b�g����(A-11)
   ***********************************************************************************/
  PROCEDURE output_lot_assign(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- 1.�����Ώۃ��R�[�h
    ov_errbuf       OUT    NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT    NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT    NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_lot_assign'; -- �v���O������
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
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_material_detail  GME_MATERIAL_DETAILS%ROWTYPE;
    lr_tran_row_in      GME_INVENTORY_TXNS_GTMP%ROWTYPE;
    lr_tran_row_out     GME_INVENTORY_TXNS_GTMP%ROWTYPE;
    lr_def_tran_row     GME_INVENTORY_TXNS_GTMP%ROWTYPE;
    lr_in_batch_hdr     GME_BATCH_HEADER%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    lr_tran_row_in.item_id            := ir_masters_rec.to_item_id;              -- 1.�i��ID
    lr_tran_row_in.whse_code          := ir_masters_rec.whse_code;               -- 2.�q�ɃR�[�h
    lr_tran_row_in.lot_id             := ir_masters_rec.to_lot_id;               -- 3.���b�gID
    lr_tran_row_in.location           := ir_masters_rec.inventory_location_code; -- 4.�ۊǏꏊ
    lr_tran_row_in.doc_id             := ir_masters_rec.batch_id;                -- �o�b�`ID
    lr_tran_row_in.doc_type           := 'PROD';                                 -- 5.�����^�C�v
    lr_tran_row_in.trans_date         := ir_masters_rec.item_sysdate;            -- ���ѓ�
    lr_tran_row_in.trans_qty          := ir_masters_rec.qty;                     -- 6.���ʂP
    lr_tran_row_in.trans_um           := ir_masters_rec.to_item_um;              -- 7.�P�ʂP
    lr_tran_row_in.completed_ind      := 0;                                      -- �����t���O
    lr_tran_row_in.material_detail_id := ir_masters_rec.to_material_detail_id;   -- ���Y�����ڍ�ID
    lr_in_batch_hdr.batch_id          := ir_masters_rec.batch_id;                -- �o�b�`ID
--
    -- ======================================
    -- ���b�g����API
    -- ======================================
    GME_API_PUB.INSERT_LINE_ALLOCATION(
                                       P_API_VERSION      => GME_API_PUB.API_VERSION,
                                       P_VALIDATION_LEVEL => GME_API_PUB.MAX_ERRORS,
                                       P_INIT_MSG_LIST    => FALSE,
                                       P_COMMIT           => FALSE,
                                       P_TRAN_ROW         => lr_tran_row_in,
                                       P_LOT_NO           => ir_masters_rec.lot_no,
                                       P_SUBLOT_NO        => NULL,
                                       P_CREATE_LOT       => FALSE,
                                       P_IGNORE_SHORTAGE  => TRUE,
                                       P_SCALE_PHANTOM    => FALSE,
                                       X_MATERIAL_DETAIL  => lr_material_detail,
                                       X_TRAN_ROW         => lr_tran_row_out,
                                       X_DEF_TRAN_ROW     => lr_def_tran_row,
                                       X_MESSAGE_COUNT    => ln_message_count,
                                       X_MESSAGE_LIST     => lv_message_list,
                                       X_RETURN_STATUS    => lv_return_status
                                      );
--
    -- �o�̓��b�g���������������łȂ��ꍇ
    IF (lv_return_status <> gv_ret_sts_success) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_output_lot);
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
  END output_lot_assign;
--
  /**********************************************************************************
   * Procedure Name   : cmpt_batch
   * Description      : �o�b�`����(A-12)
   ***********************************************************************************/
  PROCEDURE cmpt_batch(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- 1.�����Ώۃ��R�[�h
    ov_errbuf       OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���E���R�[�h ***
    lr_in_batch_hdr  GME_BATCH_HEADER%ROWTYPE; -- ���Y�o�b�`�w�b�_(����)
    lr_out_batch_hrd GME_BATCH_HEADER%ROWTYPE; -- ���Y�o�b�`�w�b�_(�o��)
    lt_unalloc_mtl   GME_API_PUB.UNALLOCATED_MATERIALS_TAB;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    lr_in_batch_hdr.batch_status      := 1;                           -- 1.�X�e�[�^�X
    lr_in_batch_hdr.actual_start_date := ir_masters_rec.item_sysdate; -- 2.���ъJ�n��
    lr_in_batch_hdr.actual_cmplt_date := ir_masters_rec.item_sysdate; -- 3.���яI����
    lr_in_batch_hdr.batch_id          := ir_masters_rec.batch_id;     -- �o�b�`ID

--
    -- ======================================
    -- �o�b�`����API
    -- ======================================
    GME_API_PUB.CERTIFY_BATCH(
                              P_API_VERSION           => GME_API_PUB.API_VERSION,
                              P_VALIDATION_LEVEL      => GME_API_PUB.MAX_ERRORS,
                              P_INIT_MSG_LIST         => FALSE,
                              P_COMMIT                => FALSE,
                              X_MESSAGE_COUNT         => ln_message_count,
                              X_MESSAGE_LIST          => lv_message_list,
                              X_RETURN_STATUS         => lv_return_status,
                              P_DEL_INCOMPLETE_MANUAL => FALSE,
                              P_IGNORE_SHORTAGES      => TRUE,
                              P_BATCH_HEADER          => lr_in_batch_hdr,
                              X_BATCH_HEADER          => lr_out_batch_hrd,
                              X_UNALLOCATED_MATERIAL  => lt_unalloc_mtl
                             );
--
    -- �o�b�`���������������łȂ��ꍇ
    IF (lv_return_status <> gv_ret_sts_success) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_cmpt_bat);
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
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- 1.�����Ώۃ��R�[�h
    ov_errbuf       OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���E���R�[�h ***
    lr_in_batch_hdr  GME_BATCH_HEADER%ROWTYPE; -- ���Y�o�b�`�w�b�_(����)
    lr_out_batch_hrd GME_BATCH_HEADER%ROWTYPE; -- ���Y�o�b�`�w�b�_(�o��)
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    lr_in_batch_hdr.batch_status     := 2;                           -- 1.�X�e�[�^�X
    lr_in_batch_hdr.batch_close_date := ir_masters_rec.item_sysdate; -- 2.���ъJ�n��
    lr_in_batch_hdr.batch_id         := ir_masters_rec.batch_id;     -- �o�b�`ID
--
    -- ======================================
    -- �o�b�`�N���[�YAPI
    -- ======================================
    GME_API_PUB.CLOSE_BATCH(
                            P_API_VERSION      => GME_API_PUB.API_VERSION,
                            P_VALIDATION_LEVEL => GME_API_PUB.MAX_ERRORS,
                            P_INIT_MSG_LIST    => FALSE,
                            P_COMMIT           => FALSE,
                            X_MESSAGE_COUNT    => ln_message_count,
                            X_MESSAGE_LIST     => lv_message_list,
                            X_RETURN_STATUS    => lv_return_status,
                            P_BATCH_HEADER     => lr_in_batch_hdr,
                            X_BATCH_HEADER     => lr_out_batch_hrd
                           );
--
    -- �o�b�`�N���[�Y�����������łȂ��ꍇ
    IF (lv_return_status <> gv_ret_sts_success) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_close_bat);
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
   * Description      : �o�b�`�ۑ�
   ***********************************************************************************/
  PROCEDURE save_batch(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- 1.�����Ώۃ��R�[�h
    ov_errbuf       OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lr_in_batch_hdr  GME_BATCH_HEADER%ROWTYPE;     -- ���Y�o�b�`�w�b�_(����)
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    lr_in_batch_hdr.batch_id         := ir_masters_rec.batch_id;     -- �o�b�`ID
--
    -- ======================================
    -- �o�b�`�ۑ�API
    -- ======================================
    GME_API_PUB.SAVE_BATCH(
                           P_BATCH_HEADER  => lr_in_batch_hdr,
                           X_RETURN_STATUS => lv_return_status,
                           P_COMMIT        => FALSE
                          );
--
    -- �o�b�`�ۑ������������łȂ��ꍇ
    IF (lv_return_status <> gv_ret_sts_success) THEN
      -- �G���[���b�Z�[�W���擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv,  gv_msg_52a_00,
                                            gv_tkn_api_name, gv_tkn_save_bat);
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
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_inv_loc_code   IN          VARCHAR2, --  1.�ۊǑq�ɃR�[�h
    iv_from_item_no   IN          VARCHAR2, --  2.�U�֌��i��No
    iv_lot_no         IN          VARCHAR2, --  3.�U�֌����b�gNo
    iv_to_item_no     IN          VARCHAR2, --  4.�U�֐�i��No
--2008.4.28 Y.Kawano modify start
--    in_quantity       IN          NUMBER,   --  5.����
    iv_quantity       IN          VARCHAR2, --  5.����
--2008.4.28 Y.Kawano modify end
    id_sysdate        IN          DATE,     --  6.�i�ڐU�֎��ѓ�
    iv_remarks        IN          VARCHAR2, --  7.�E�v
    iv_item_chg_aim   IN          VARCHAR2, --  8.�i�ڐU�֖ړI
    ov_errbuf         OUT  NOCOPY VARCHAR2, --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT  NOCOPY VARCHAR2, --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT  NOCOPY VARCHAR2) --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lr_masters_rec masters_rec;                  -- �����Ώۃf�[�^�i�[���R�[�h
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
    lr_masters_rec.inventory_location_code := iv_inv_loc_code; -- �ۊǑq�ɃR�[�h
    lr_masters_rec.from_item_no            := iv_from_item_no; -- �U�֌��i��No
    lr_masters_rec.lot_no                  := iv_lot_no;       -- ���b�gNo
    lr_masters_rec.to_item_no              := iv_to_item_no;   -- �U�֐�i��No
--2008.4.28 Y.Kawano modify start
--    lr_masters_rec.qty                     := in_quantity;     -- ����
    lr_masters_rec.qty                     := TO_NUMBER(iv_quantity);
                                                               -- ����
--2008.4.28 Y.Kawano modify end
    lr_masters_rec.item_sysdate            := id_sysdate;      -- �i�ڐU�֎��ѓ�
    lr_masters_rec.remarks                 := iv_remarks;      -- �E�v
    lr_masters_rec.item_chg_aim            := iv_item_chg_aim; -- �i�ڐU�֖ړI
--
    -- ���������̐ݒ�
    gn_target_cnt := 1;
--
    -- ===============================
    -- ��������
    -- ===============================
    init_proc(lr_masters_rec, -- 1.�����Ώۃ��R�[�h
              lv_errbuf,      -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,     -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �p�����[�^�`�F�b�N(A-1)
    -- ===============================
    chk_param(lr_masters_rec,  -- 1.�`�F�b�N�Ώۃ��R�[�h
              lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- �f�[�^�Z�b�g����
    -- ====================================
    set_masters_rec(lr_masters_rec, -- 1.�����Ώۃ��R�[�h
                    lv_errbuf,      -- �G���[�E���b�Z�[�W           --# �Œ� #
                    lv_retcode,     -- ���^�[���E�R�[�h             --# �Œ� #
                    lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �t�H�[�~�����L���`�F�b�N(A-2)
    -- ===============================
    chk_formula(lr_masters_rec,  -- 1.�`�F�b�N�Ώۃ��R�[�h
                lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
--
    -- �t�H�[�~���������݂��Ȃ��ꍇ
    ELSIF (NOT(lr_masters_rec.is_info_flg)) THEN
--
      -- ===============================
      -- �t�H�[�~�����o�^(A-3)
      -- ===============================
      ins_formula(lr_masters_rec,  -- 1.�����Ώۃ��R�[�h
                  lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- ���V�s�L���`�F�b�N(A-4)
    -- ===============================
    chk_recipe(lr_masters_rec,
               lv_errbuf,  -- �G���[�E���b�Z�[�W           --# �Œ� #
               lv_retcode, -- ���^�[���E�R�[�h             --# �Œ� #
               lv_errmsg); -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
--
    -- ���V�s�̍H�����ݒ肳��Ă��Ȃ��ꍇ
    ELSIF (NOT(lr_masters_rec.is_info_flg)) THEN
      -- ===============================
      -- ���V�s�X�V
      -- ===============================
      upd_recipe(lr_masters_rec,
                 lv_errbuf,  -- �G���[�E���b�Z�[�W           --# �Œ� #
                 lv_retcode, -- ���^�[���E�R�[�h             --# �Œ� #
                 lv_errmsg); -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- ���b�g�L���`�F�b�N(A-6)
    -- ===============================
    chk_lot(lr_masters_rec,  -- 1.�`�F�b�N�Ώۃ��R�[�h
            lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
--
    -- ���b�g�����݂��Ȃ��ꍇ
    ELSIF (NOT(lr_masters_rec.is_info_flg)) THEN
--
      -- ===============================
      -- ���b�g�쐬(A-7)
      -- ===============================
      create_lot(lr_masters_rec,  -- 1.�����Ώۃ��R�[�h
                 lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
                 lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
                 lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- �o�b�`�쐬(A-8)
    -- ===============================
    create_batch(lr_masters_rec,  -- 1.�����Ώۃ��R�[�h
                 lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
                 lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
                 lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���̓��b�g����(A-9)
    -- ===============================
    input_lot_assign(lr_masters_rec,  -- 1.�����Ώۃ��R�[�h
                     lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
                     lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
                     lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �o�̓��b�g����(A-11)
    -- ===============================
    output_lot_assign(lr_masters_rec,  -- 1.�����Ώۃ��R�[�h
                      lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
                      lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
                      lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �o�b�`����(A-12)
    -- ===============================
    cmpt_batch(lr_masters_rec,  -- 1.�����Ώۃ��R�[�h
               lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
               lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
               lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �o�b�`�N���[�Y(A-13)
    -- ===============================
    close_batch(lr_masters_rec,  -- 1.�����Ώۃ��R�[�h
                lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �o�b�`�ۑ�
    -- ===============================
    save_batch(lr_masters_rec,  -- 1.�����Ώۃ��R�[�h
               lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
               lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
               lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ����I�����o��
    -- ===============================
    -- ���Y�o�b�`No
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_52,
                                              gv_tkn_value,   lr_masters_rec.batch_no);
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
    errbuf          OUT NOCOPY VARCHAR2, -- �G���[���b�Z�[�W #�Œ�#
    retcode         OUT NOCOPY VARCHAR2, -- �G���[�R�[�h     #�Œ�#
    iv_inv_loc_code IN         VARCHAR2, -- 1.�ۊǑq�ɃR�[�h
    iv_from_item_no IN         VARCHAR2, -- 2.�U�֌��i��No
    iv_lot_no       IN         VARCHAR2, -- 3.���b�gNo
    iv_to_item_no   IN         VARCHAR2, -- 4.�U�֐�i��No
 --2008.4.28 Y.Kawano modify start
--   in_quantity     IN         NUMBER,   -- 5.����
   iv_quantity     IN         VARCHAR2, -- 5.����
--2008.4.28 Y.Kawano modify end
    iv_sysdate      IN         VARCHAR2, -- 6.�i�ڐU�֎��ѓ�
    iv_remarks      IN         VARCHAR2, -- 7.�E�v
    iv_item_chg_aim IN         VARCHAR2  -- 8.�i�ڐU�֖ړI
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
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    lv_normal_msg VARCHAR2(5000); -- �K�{�o�̓��b�Z�[�W
    lv_aim_mean   VARCHAR2(20);   -- �i�ڐU�֖ړI �E�v
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
    AND    ROWNUM                    = 1;
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
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    -- submain�̌Ăяo��
    submain(
      iv_inv_loc_code,                                   --  1.�ۊǑq��ID
      iv_from_item_no,                                   --  2.�U�֌��i��ID
      iv_lot_no,                                         --  3.���b�gID
      iv_to_item_no,                                     --  4.�U�֐�i��ID
--2008.4.28 Y.Kawano modify start
--      in_quantity,                                       --  5.����
      iv_quantity,                                       --  5.����
--2008.4.28 Y.Kawano modify end
      FND_DATE.STRING_TO_DATE(iv_sysdate, 'YYYY/MM/DD'), --  6.�i�ڐU�֎��ѓ�
      iv_remarks,                                        --  7.�E�v
      iv_item_chg_aim,                                   --  8.�i�ڐU�֖ړI
      lv_errbuf,                         --  �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                        --  ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                        --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- ===============================
    -- �K�{�o�͍���
    -- ===============================
    -- �p�����[�^�ۊǑq�ɓ��͒l
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_45,
                                              gv_tkn_value,   iv_inv_loc_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- �p�����[�^�U�֌��i�ړ��͒l
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_46,
                                              gv_tkn_value,   iv_from_item_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- �p�����[�^�U�֌����b�gNo���͒l
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_47,
                                              gv_tkn_value,   iv_lot_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- �p�����[�^�U�֐�i�ړ��͒l
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_48,
                                              gv_tkn_value,   iv_to_item_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- �p�����[�^���ʓ��͒l
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_49,
                                              gv_tkn_value,   iv_quantity);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- �p�����[�^�i�ڐU�֎��ѓ����͒l
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_50,
                                              gv_tkn_value,   iv_sysdate);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- �p�����[�^�E�v���͒l
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_51,
                                              gv_tkn_value,   iv_remarks);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    -- �p�����[�^�i�ڐU�֖ړI
    -- �i�ڐU�֖ړI�̓E�v���擾
    BEGIN
      SELECT flvv.meaning            -- �E�v
      INTO   lv_aim_mean
      FROM   xxcmn_lookup_values_v flvv  -- ���b�N�A�b�vVIEW
      WHERE  flvv.lookup_type  = gv_lt_item_tran_cls
      AND    flvv.lookup_code  = iv_item_chg_aim;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN  -- �f�[�^�擾�G���[
        -- �i�ڐU�֖ړI�̃R�[�h���o��
        lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_57,
                                                  gv_tkn_value,   iv_item_chg_aim);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_normal_msg);
    END;
--
    -- �f�[�^���擾�ł����ꍇ�͕i�ڐU�֖ړI�̓E�v���o��
    lv_normal_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv, gv_msg_52a_57,
                                              gv_tkn_value,   lv_aim_mean);
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
    IF (retcode = gv_status_error) THEN
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
END xxinv520001c;
/
