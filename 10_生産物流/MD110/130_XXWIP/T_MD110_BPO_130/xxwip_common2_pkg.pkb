CREATE OR REPLACE PACKAGE BODY xxwip_common2_pkg
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxwip_common2_pkg(BODY)
 * Description            : ���Y�o�b�`�ꗗ��ʗp�֐�
 * MD.070(CMD.050)        : �Ȃ�
 * Version                : 1.1
 *
 * Program List
 * --------------------   ---- ----- --------------------------------------------------
 *  Name                  Type  Ret   Description
 * --------------------   ---- ----- --------------------------------------------------
 * save_batch              P         �o�b�`�Z�[�uAPI�ďo ��ʗp
 * create_batch            P         �o�b�`�쐬API�ďo ��ʗp
 * create_lot              P         ���b�g�̔ԁE���b�g�쐬API�ďo ��ʗp
 * insert_line_allocation  P         ���׊����ǉ�API�ďo ��ʗp
 * insert_material_line    P         ���Y�����ڍגǉ�API�ďo ��ʗp
 * delete_material_line    P         ���Y�����ڍ׍폜API�ďo ��ʗp
 * reschedule_batch        P         �o�b�`�ăX�P�W���[��
 * update_lot_dff          P         ���b�g�}�X�^�X�VAPI�ďo ��ʗp
 * update_line_allocation  P         ���׊����X�VAPI�ďo ��ʗp
 * delete_line_allocation  P         ���׊����폜API�ďo ��ʗp
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/01/08   1.0   T.Oikawa         �V�K�쐬
 *  2008/12/22   1.1   Oracle ��r ��� �{�ԏ�Q#743�Ή�(���b�g�ǉ��E�X�V�֐�)
 *****************************************************************************************/
AS
--
--###############################  �Œ�O���[�o���萔�錾�� START   ###############################
--
  gv_status_normal                CONSTANT VARCHAR2(1) := '0';   --����
  gv_status_warn                  CONSTANT VARCHAR2(1) := '1';   --�x��
  gv_status_error                 CONSTANT VARCHAR2(1) := '2';   --���s
  gv_sts_cd_normal                CONSTANT VARCHAR2(1) := 'C';   --�X�e�[�^�X(����)
  gv_sts_cd_warn                  CONSTANT VARCHAR2(1) := 'G';   --�X�e�[�^�X(�x��)
  gv_sts_cd_error                 CONSTANT VARCHAR2(1) := 'E';   --�X�e�[�^�X(���s)
  gv_msg_part                     CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_dot                      CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt                      CONSTANT VARCHAR2(3) := ',';
  gv_flg_on                       CONSTANT VARCHAR2(1) := '1';
  gv_msg_cont                     CONSTANT VARCHAR2(3) := '.';
  gv_prof_cost_price              CONSTANT VARCHAR2(26) := 'XXCMN_COST_PRICE_WHSE_CODE';
--
--#####################################  �Œ蕔 END   #############################################
--
--###############################  �Œ�O���[�o���ϐ��錾�� START   ###############################
--
  gv_out_msg                      VARCHAR2(2000);
  gv_sep_msg                      VARCHAR2(2000);
  gv_exec_user                    VARCHAR2(100);             -- ���s���[�U��
  gv_conc_name                    VARCHAR2(30);              -- ���s�R���J�����g��
  gv_conc_status                  VARCHAR2(30);              -- ��������
  gn_target_cnt                   NUMBER;                    -- �Ώی���
  gn_normal_cnt                   NUMBER;                    -- ���팏��
  gn_error_cnt                    NUMBER;                    -- ���s����
  gn_warn_cnt                     NUMBER;                    -- �x������
  gn_report_cnt                   NUMBER;                    -- ���|�[�g����
--
--#####################################  �Œ蕔 END   #############################################
--
--##################################  �Œ苤�ʗ�O�錾�� START   ##################################
--
  --*** ���������ʗ�O ***
  global_process_expt             EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt                 EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt          EXCEPTION;
--
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--#####################################  �Œ蕔 END   #############################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  api_expt                        EXCEPTION;     -- API��O
  skip_expt                       EXCEPTION;     -- �X�L�b�v��O
  deadlock_detected               EXCEPTION;     -- �f�b�h���b�N�G���[
--
  PRAGMA EXCEPTION_INIT( deadlock_detected, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name                     CONSTANT VARCHAR2(100) := 'xxwip_common2_pkg'; -- �p�b�P�[�W��
  -- ���W���[��������
  gv_xxcmn                        CONSTANT VARCHAR2(100) := 'XXCMN';            -- ���W���[�������́FXXCMN ����
  gv_xxwip                        CONSTANT VARCHAR2(100) := 'XXWIP';            -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
  -- ���b�Z�[�W
  gv_msg_xxwip10049               CONSTANT VARCHAR2(100) := 'APP-XXWIP-10049';  -- ���b�Z�[�W�FAPP-XXWIP-10049 API�G���[���b�Z�[�W
  gv_batch_no                     CONSTANT VARCHAR2(100) := '�o�b�`No.';
--
  -- �g�[�N��
  gv_tkn_batch_no                 CONSTANT VARCHAR2(100) := 'BATCH_NO';         -- �g�[�N���FBATCH_NO
  gv_tkn_api_name                 CONSTANT VARCHAR2(100) := 'API_NAME';         -- �g�[�N���FAPI_NAME
--
  -- ���C���^�C�v
  gn_prod                         CONSTANT NUMBER        := 1;                  -- �����i
  gn_co_prod                      CONSTANT NUMBER        := 2;                  -- ���Y��
  gn_material                     CONSTANT NUMBER        := -1;                 -- �����i
--
  gn_default_lot_id               CONSTANT NUMBER        := 0;                  -- �f�t�H���g���b�gID
  gn_delete_mark_on               CONSTANT NUMBER        := 1;                  -- �폜�t���OON
  gn_delete_mark_off              CONSTANT NUMBER        := 0;                  -- �폜�t���OOFF
  gv_cmpnt_code_gen               CONSTANT VARCHAR2(5)   := '01GEN';            -- �i�ڃR���|�[�l���g�敪�F01GEN
  -- xxcmn���ʊ֐����^�[���E�R�[�h
  gn_e                            CONSTANT NUMBER        := 1;                  -- xxcmn���ʊ֐����^�[���E�R�[�h�F1�i�G���[�j
--
  -- �Ɩ��X�e�[�^�X
  gt_duty_status_com              CONSTANT gme_batch_header.attribute4%TYPE  := '7';  -- �Ɩ��X�e�[�^�X�F7�i�����j
  gt_duty_status_cls              CONSTANT gme_batch_header.attribute4%TYPE  := '8';  -- �Ɩ��X�e�[�^�X�F8�i�N���[�Y�j
  gt_duty_status_can              CONSTANT gme_batch_header.attribute4%TYPE  := '-1'; -- �Ɩ��X�e�[�^�X�F-1�i����j
  -- �敪
  gt_division_gme                 CONSTANT xxwip_qt_inspection.division%TYPE := '1';  -- �敪  1:���Y
  gt_division_po                  CONSTANT xxwip_qt_inspection.division%TYPE := '2';  -- �敪  2:����
  gt_division_lot                 CONSTANT xxwip_qt_inspection.division%TYPE := '3';  -- �敪  3:���b�g���
  gt_division_spl                 CONSTANT xxwip_qt_inspection.division%TYPE := '4';  -- �敪  4:�O���o����
  gt_division_tea                 CONSTANT xxwip_qt_inspection.division%TYPE := '5';  -- �敪  5:�r������
  -- �����敪
  gv_disposal_div_ins             CONSTANT VARCHAR2(1) := '1'; -- �����敪  1:�ǉ�
  gv_disposal_div_upd             CONSTANT VARCHAR2(1) := '2'; -- �����敪  2:�X�V
  gv_disposal_div_del             CONSTANT VARCHAR2(1) := '3'; -- �����敪  3:�폜
  -- �Ώې�
  gv_qt_object_tea                CONSTANT VARCHAR2(1) := '1'; -- �Ώې�  1:�r���i��
  gv_qt_object_bp1                CONSTANT VARCHAR2(1) := '2'; -- �Ώې�  2:���Y���P
  gv_qt_object_bp2                CONSTANT VARCHAR2(1) := '3'; -- �Ώې�  3:���Y���Q
  gv_qt_object_bp3                CONSTANT VARCHAR2(1) := '4'; -- �Ώې�  4:���Y���R
  -- ���Y�����ڍ�.���C���^�C�v
  gt_line_type_goods              CONSTANT gme_material_details.line_type%TYPE := 1;    -- ���C���^�C�v�F1�i�����i�j
  gt_line_type_sub                CONSTANT gme_material_details.line_type%TYPE := 2;    -- ���C���^�C�v�F2�i���Y���j
  -- OPM�ۗ��݌Ƀg�����U�N�V����.�����t���O
  gt_completed_ind_com            CONSTANT ic_tran_pnd.completed_ind%TYPE     := '1';  -- �����t���O�F1�i�����j
  -- �i����������
  gt_qt_status_mi                 CONSTANT fnd_lookup_values.lookup_code%TYPE := '10';  -- �i���������� 10:������
  -- �������
  gt_inspect_class_gme            CONSTANT xxwip_qt_inspection.inspect_class%TYPE := '1'; -- ������ʁF1�i���Y�j
  gt_inspect_class_po             CONSTANT xxwip_qt_inspection.inspect_class%TYPE := '2'; -- ������ʁF2�i�����d���j
  -- �i�ڋ敪
  gv_item_type_harf_prod          CONSTANT VARCHAR2(1) := '4'; -- �i�ڋ敪  4:�����i
  gv_item_type_prod               CONSTANT VARCHAR2(1) := '5'; -- �i�ڋ敪  5:���i
  -- OPM���b�g�}�X�^DFF�X�VAPI�o�[�W����
  gn_api_version                  CONSTANT NUMBER(2,1) := 1.0;
--
  -- �O���o�������.�����^�C�v
  gt_txns_type_aite               CONSTANT xxpo_vendor_supply_txns.txns_type%TYPE := '1';  -- �����^�C�v�F�����݌�
  gt_txns_type_sok                CONSTANT xxpo_vendor_supply_txns.txns_type%TYPE := '2';  -- �����^�C�v�F�����d��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /************************************************************************
   * Procedure Name  : save_batch
   * Description     : �o�b�`�Z�[�uAPI�ďo
   ************************************************************************/
  PROCEDURE save_batch(
    it_batch_id                     IN  gme_batch_header.batch_id%TYPE
  , ov_retcode                      OUT VARCHAR2
  )
  IS
    lr_batch_save                   gme_batch_header%ROWTYPE;
    lv_return_status                VARCHAR2(100);
--
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'save_batch';     -- �v���O������
    cv_api_name                     CONSTANT VARCHAR2(100) := '�o�b�`�Z�[�u';
--
  BEGIN
    -- �p�����[�^�ݒ�
    lr_batch_save.batch_id := it_batch_id;
--
    -- �o�b�`�Z�[�uAPI���s
    GME_API_PUB.SAVE_BATCH(
      p_batch_header                  =>  lr_batch_save
    , x_return_status                 =>  lv_return_status 
    );
--
    -- ���^�[���R�[�h�ݒ�
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      RAISE api_expt;
    END IF;
--
    -- ����I��
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
  END save_batch;
--
  /**********************************************************************************
   * Procedure Name   : create_batch
   * Description      : �o�b�`�쐬API�ďo
   ***********************************************************************************/
  PROCEDURE create_batch(
    it_plan_start_date              IN  gme_batch_header.plan_start_date          %TYPE
  , it_plan_cmplt_date              IN  gme_batch_header.plan_cmplt_date          %TYPE
  , it_recipe_validity_rule_id      IN  gme_batch_header.recipe_validity_rule_id  %TYPE   -- �Ó������[��ID
  , it_plant_code                   IN  gme_batch_header.plant_code               %TYPE
  , it_wip_whse_code                IN  gme_batch_header.wip_whse_code            %TYPE
  , in_batch_size                   IN  NUMBER
  , iv_batch_size_uom               IN  VARCHAR2
  , ot_batch_id                     OUT gme_batch_header.batch_id                 %TYPE
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                   -- �G���[�E���b�Z�[�W
  , ov_retcode                      OUT NOCOPY VARCHAR2                                   -- ���^�[���E�R�[�h
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'create_batch';            --�v���O������
    cv_api_name                     CONSTANT VARCHAR2(100) := '�o�b�`�쐬API�ďo';
--
    ln_message_count                NUMBER;
    lv_message_list                 VARCHAR2(200);
    lv_return_status                VARCHAR2(10);
--
    lr_batch_header_in              gme_batch_header%ROWTYPE;
    lr_batch_header_out             gme_batch_header%ROWTYPE;
    unallocated_materials_tab       GME_API_PUB.UNALLOCATED_MATERIALS_TAB;
--
  BEGIN
    -- ***********************************************
    -- ***  �o�b�`�쐬
    -- ***********************************************
    lr_batch_header_in.plan_start_date         := it_plan_start_date;
    lr_batch_header_in.plan_cmplt_date         := it_plan_cmplt_date;
    lr_batch_header_in.recipe_validity_rule_id := it_recipe_validity_rule_id;   -- �Ó������[��ID
    lr_batch_header_in.plant_code              := it_plant_code;
    lr_batch_header_in.wip_whse_code           := it_wip_whse_code;
    lr_batch_header_in.batch_type              := 0;
--
    -- �o�b�`�쐬API���s
    GME_API_PUB.CREATE_BATCH(
      p_api_version                   =>  GME_API_PUB.API_VERSION         --      IN         NUMBER
    , p_validation_level              =>  GME_API_PUB.MAX_ERRORS          --      IN         NUMBER := gme_api_pub.max_errors,
    , p_init_msg_list                 =>  FALSE                           --      IN         BOOLEAN := FALSE ,
    , p_commit                        =>  FALSE                           --      IN         BOOLEAN := FALSE ,
    , x_message_count                 =>  ln_message_count                --      OUT NOCOPY NUMBER,
    , x_message_list                  =>  lv_message_list                 --      OUT NOCOPY VARCHAR2,
    , x_return_status                 =>  lv_return_status                --      OUT NOCOPY VARCHAR2,
    , p_batch_header                  =>  lr_batch_header_in              -- �K�{ IN         gme_batch_header%ROWTYPE,
    , x_batch_header                  =>  lr_batch_header_out             -- �K�{ OUT NOCOPY gme_batch_header%ROWTYPE,
    , p_batch_size                    =>  in_batch_size                   -- �K�{ IN         NUMBER := NULL,
    , p_batch_size_uom                =>  iv_batch_size_uom               -- �K�{ IN         VARCHAR2 := NULL,
    , p_creation_mode                 =>  'PRODUCT'                       -- �K�{ IN         VARCHAR2,
    , p_recipe_id                     =>  NULL                            --      IN         NUMBER := NULL,
    , p_recipe_no                     =>  NULL                            --      IN         VARCHAR2 := NULL,
    , p_recipe_version                =>  NULL                            --      IN         NUMBER := NULL,
    , p_product_no                    =>  NULL                            --      IN         VARCHAR2 := NULL,
    , p_product_id                    =>  NULL                            --      IN         NUMBER := NULL,
    , p_ignore_qty_below_cap          =>  TRUE                            --      IN         BOOLEAN := TRUE ,
    , p_ignore_shortages              =>  TRUE                            -- �K�{ IN         BOOLEAN,
    , p_use_shop_cal                  =>  NULL                            --      IN         NUMBER,
    , p_contiguity_override           =>  NULL                            --      IN         NUMBER,
    , x_unallocated_material          =>  unallocated_materials_tab       -- �K�{ OUT NOCOPY GME_API_PUB.UNALLOCATED_MATERIALS_TAB �񊄓��̌����܂��͍݌ɕs���̃G���[�߂�
    );
--
    -- �G���[������
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      ov_errbuf := lv_message_list;
      ov_errmsg := '�o�b�`�쐬�Ɏ��s���܂����B';
      RAISE api_expt;
    END IF;
--
    -- �쐬���ꂽ�o�b�`ID���Z�b�g
    ot_batch_id := lr_batch_header_out.batch_id;
--
    -- ����I��
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
  END create_batch;
--
  /**********************************************************************************
   * Procedure Name   : create_lot
   * Description      : ���b�g�̔ԁE���b�g�쐬API�ďo
   ***********************************************************************************/
  PROCEDURE create_lot(
    it_item_id                      IN         ic_item_mst_b.item_id%TYPE    -- �i��ID
  , it_item_no                      IN         ic_item_mst_b.item_no%TYPE    -- �i�ڃR�[�h
  , ot_lot_id                       OUT NOCOPY ic_lots_mst.lot_id   %TYPE    -- ���b�gID
  , ov_errbuf                       OUT NOCOPY VARCHAR2                      -- �G���[�E���b�Z�[�W
  , ov_retcode                      OUT NOCOPY VARCHAR2                      -- ���^�[���E�R�[�h
  , ov_errmsg                       OUT NOCOPY VARCHAR2                      -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'create_lot';            --�v���O������
    cv_api_name                     CONSTANT VARCHAR2(100) := '���b�g�̔ԁE���b�g�쐬';
--
    lt_lot_no                       ic_lots_mst.lot_no   %TYPE;              -- ���b�gNo
    lt_sublot_no                    ic_lots_mst.sublot_no%TYPE;              -- �T�u���b�gNo
    ln_return_status                NUMBER;                                  -- ���^�[���X�e�[�^�X
    lv_return_status                VARCHAR2(1);                             -- ���^�[���X�e�[�^�X
    ln_message_count                NUMBER;
    lv_msg_data                     VARCHAR2(10000);
--
    lr_create_lot                   GMIGAPI.LOT_REC_TYP;
    lr_ic_lots_mst                  ic_lots_mst%ROWTYPE;
    lr_ic_lots_cpg                  ic_lots_cpg%ROWTYPE;
--
    lv_errbuf                       VARCHAR2(5000);                          -- �G���[�E���b�Z�[�W
    lv_retcode                      VARCHAR2(1);                             -- ���^�[���E�R�[�h
    lv_errmsg                       VARCHAR2(5000);                          -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
    -- ***********************************************
    -- ***  ���b�gNo�̔�
    -- ***********************************************
    GMI_AUTOLOT.GENERATE_LOT_NUMBER(
      p_item_id                       =>  it_item_id          -- IN         NUMBER
    , p_in_lot_no                     =>  NULL                -- IN         VARCHAR2
    , p_orgn_code                     =>  NULL                -- IN         VARCHAR2
    , p_doc_id                        =>  NULL                -- IN         NUMBER
    , p_line_id                       =>  NULL                -- IN         NUMBER
    , p_doc_type                      =>  NULL                -- IN         VARCHAR2
    , p_out_lot_no                    =>  lt_lot_no           -- OUT NOCOPY VARCHAR2
    , p_sublot_no                     =>  lt_sublot_no        -- OUT NOCOPY VARCHAR2
    , p_return_status                 =>  ln_return_status    -- OUT NOCOPY NUMBER
    );
--
    -- �̔Ԃ���Ă��Ȃ��ꍇ�A�G���[�I��
    IF ( lt_lot_no IS NULL ) THEN
      ov_errmsg  := '���b�g�̔ԂɎ��s���܂����B';
      RAISE api_expt;
    END IF;
--
    -- ***********************************************
    -- ***  ���b�g�쐬
    -- ***********************************************
    lr_create_lot.item_no          := it_item_no;
    lr_create_lot.lot_no           := lt_lot_no;
    lr_create_lot.sublot_no        := NULL;
    lr_create_lot.lot_desc         := NULL;
    lr_create_lot.origination_type := 2;
    lr_create_lot.attribute24      := '5'; -- ���Y�o����
    lr_create_lot.user_name        := FND_GLOBAL.USER_NAME;
    lr_create_lot.lot_created      := SYSDATE;
-- 2008/12/22 D.Nihei ADD START
    lr_create_lot.expaction_date   := TO_DATE('2099/12/31', 'YYYY/MM/DD');
    lr_create_lot.expire_date      := TO_DATE('2099/12/31', 'YYYY/MM/DD');
-- 2008/12/22 D.Nihei ADD END
--
    -- ���b�g�쐬API
    GMIPAPI.CREATE_LOT(
      p_api_version                   =>  3.0                           -- IN         NUMBER
    , p_init_msg_list                 =>  FND_API.G_FALSE               -- IN         VARCHAR2 default fnd_api.g_false
    , p_commit                        =>  FND_API.G_FALSE               -- IN         VARCHAR2 default fnd_api.g_false
    , p_validation_level              =>  FND_API.G_VALID_LEVEL_FULL    -- IN         NUMBER   default fnd_api.g_valid_level_full
    , p_lot_rec                       =>  lr_create_lot                 -- IN         GMIGAPI.lot_rec_typ
    , x_ic_lots_mst_row               =>  lr_ic_lots_mst                -- OUT NOCOPY ic_lots_mst%ROWTYPE
    , x_ic_lots_cpg_row               =>  lr_ic_lots_cpg                -- OUT NOCOPY ic_lots_cpg%ROWTYPE
    , x_return_status                 =>  lv_return_status              -- OUT NOCOPY VARCHAR2
    , x_msg_count                     =>  ln_message_count              -- OUT NOCOPY NUMBER
    , x_msg_data                      =>  lv_msg_data                   -- OUT NOCOPY VARCHAR2
    );
--
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      ov_errbuf  := lv_msg_data;
      ov_errmsg  := '���b�g�쐬�Ɏ��s���܂����B';
      RAISE api_expt;
    END IF;
--
    -- �쐬���ꂽ���b�gID���Z�b�g
    ot_lot_id := lr_ic_lots_mst.lot_id;
--
    -- ����I��
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
  END create_lot;
--
  /**********************************************************************************
   * Procedure Name   : insert_line_allocation
   * Description      : ���׊����ǉ�API�ďo
   ***********************************************************************************/
  PROCEDURE insert_line_allocation(
    it_item_id                      IN         gme_inventory_txns_gtmp.item_id            %TYPE
  , it_whse_code                    IN         gme_inventory_txns_gtmp.whse_code          %TYPE
  , it_lot_id                       IN         gme_inventory_txns_gtmp.lot_id             %TYPE
  , it_location                     IN         gme_inventory_txns_gtmp.location           %TYPE
  , it_doc_id                       IN         gme_inventory_txns_gtmp.doc_id             %TYPE
  , it_trans_date                   IN         gme_inventory_txns_gtmp.trans_date         %TYPE
  , it_trans_qty                    IN         gme_inventory_txns_gtmp.trans_qty          %TYPE
  , it_completed_ind                IN         gme_inventory_txns_gtmp.completed_ind      %TYPE
  , it_material_detail_id           IN         gme_inventory_txns_gtmp.material_detail_id %TYPE
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                   -- �G���[�E���b�Z�[�W
  , ov_retcode                      OUT NOCOPY VARCHAR2                                   -- ���^�[���E�R�[�h
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'insert_line_allocation';            --�v���O������
    cv_api_name                     CONSTANT VARCHAR2(100) := '���׊����ǉ�API�ďo';
--
    lv_errbuf                       VARCHAR2(5000);                          -- �G���[�E���b�Z�[�W
    lv_retcode                      VARCHAR2(1);                             -- ���^�[���E�R�[�h
    lv_errmsg                       VARCHAR2(5000);                          -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_message_cnt                  NUMBER;
    lv_return_status                VARCHAR2(1);
    lv_message_list                 VARCHAR2(200);
--
    lr_material_detail              gme_material_details     %ROWTYPE;
    lr_tran_row_in                  gme_inventory_txns_gtmp  %ROWTYPE;
    lr_tran_row_out                 gme_inventory_txns_gtmp  %ROWTYPE;
    lr_def_tran_row                 gme_inventory_txns_gtmp  %ROWTYPE;
--
  BEGIN
    -- ***********************************************
    -- ***  ���׊����ǉ�
    -- ***********************************************
    -- �p�����[�^�ݒ�
    lr_tran_row_in.item_id            := it_item_id;
    lr_tran_row_in.whse_code          := it_whse_code;
    lr_tran_row_in.lot_id             := it_lot_id;
    lr_tran_row_in.location           := it_location;
    lr_tran_row_in.doc_id             := it_doc_id;
    lr_tran_row_in.trans_date         := it_trans_date;
    lr_tran_row_in.trans_qty          := it_trans_qty;
    lr_tran_row_in.completed_ind      := it_completed_ind;
    lr_tran_row_in.material_detail_id := it_material_detail_id;
--
    -- ���׊����ǉ�API���s
    GME_API_PUB.INSERT_LINE_ALLOCATION(
      p_api_version                   =>  GME_API_PUB.API_VERSION       -- IN         NUMBER  := gme_api_pub.api_version
    , p_validation_level              =>  GME_API_PUB.MAX_ERRORS        -- IN         NUMBER  := gme_api_pub.max_errors
    , p_init_msg_list                 =>  FALSE                         -- IN         BOOLEAN := FALSE
    , p_commit                        =>  FALSE                         -- IN         BOOLEAN := FALSE
    , p_tran_row                      =>  lr_tran_row_in                -- IN         gme_inventory_txns_gtmp%ROWTYPE
    , p_lot_no                        =>  NULL                          -- IN         VARCHAR2 DEFAULT NULL
    , p_sublot_no                     =>  NULL                          -- IN         VARCHAR2 DEFAULT NULL
    , p_create_lot                    =>  FALSE                         -- IN         BOOLEAN DEFAULT FALSE
    , p_ignore_shortage               =>  TRUE                          -- IN         BOOLEAN DEFAULT FALSE
    , p_scale_phantom                 =>  FALSE                         -- IN         BOOLEAN DEFAULT FALSE
    , x_material_detail               =>  lr_material_detail            -- OUT NOCOPY gme_material_details%ROWTYPE,
    , x_tran_row                      =>  lr_tran_row_out               -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE,
    , x_def_tran_row                  =>  lr_def_tran_row               -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE,
    , x_message_count                 =>  ln_message_cnt                -- OUT NOCOPY NUMBER,
    , x_message_list                  =>  lv_message_list               -- OUT NOCOPY VARCHAR2,
    , x_return_status                 =>  lv_return_status              -- OUT NOCOPY VARCHAR2
    );
--
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      ov_errbuf := lv_message_list;
      ov_errmsg := '���׊����ǉ��Ɏ��s���܂����B';
      RAISE api_expt;
    END IF;
--
    -- ����I��
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
  END insert_line_allocation;
--
  /************************************************************************
   * Procedure Name  : insert_material_line
   * Description     : ���Y�����ڍגǉ�API�ďo
   ************************************************************************/
  PROCEDURE insert_material_line(
    it_batch_id                     IN  gme_material_details.batch_id           %TYPE -- �o�b�`ID
  , it_item_id                      IN  gme_material_details.item_id            %TYPE -- �i��ID
  , it_item_um                      IN  gme_material_details.item_um            %TYPE -- �P��
  , it_slit                         IN  gme_material_details.attribute8         %TYPE -- ������
  , it_attribute5                   IN  gme_material_details.attribute5         %TYPE -- �ō��敪
  , it_attribute7                   IN  gme_material_details.attribute7         %TYPE -- �˗�����
  , it_attribute13                  IN  gme_material_details.attribute13        %TYPE -- �o�q�ɃR�[�h�P
  , it_attribute18                  IN  gme_material_details.attribute18        %TYPE -- �o�q�ɃR�[�h�Q
  , it_attribute19                  IN  gme_material_details.attribute19        %TYPE -- �o�q�ɃR�[�h�R
  , it_attribute20                  IN  gme_material_details.attribute20        %TYPE -- �o�q�ɃR�[�h�S
  , it_attribute21                  IN  gme_material_details.attribute21        %TYPE -- �o�q�ɃR�[�h�T
  , ot_material_detail_id           OUT gme_material_details.material_detail_id %TYPE -- ���Y�����ڍ�ID
  , ov_errbuf                       OUT NOCOPY VARCHAR2                               -- �G���[�E���b�Z�[�W
  , ov_retcode                      OUT NOCOPY VARCHAR2                               -- ���^�[���E�R�[�h
  , ov_errmsg                       OUT NOCOPY VARCHAR2                               -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'insert_material_line';     -- �v���O������
    cv_api_name                     CONSTANT VARCHAR2(100) := '���Y�����ڍגǉ�API�ďo';
--
    ln_line_no                      NUMBER;
    ln_batch_step_no                NUMBER;
--
    ln_message_count                NUMBER;
    lv_message_list                 VARCHAR2(200);
    lv_return_status                VARCHAR2(10);
    lv_api_msg                      VARCHAR2(2000);
    ln_dummy_cnt                    NUMBER;
--
    lr_material_detail_in           gme_material_details%ROWTYPE;
    lr_material_detail_out          gme_material_details%ROWTYPE;
--
  BEGIN
    -- �s�ԍ����擾
    SELECT COUNT( gmd.rowid ) + 1
    INTO ln_line_no
    FROM gme_material_details  gmd
    WHERE gmd.line_type = -1
      AND gmd.batch_id  = it_batch_id
    ;
--
    -- �p�����[�^�ݒ�
    lr_material_detail_in.batch_id                := it_batch_id;
    lr_material_detail_in.line_no                 := ln_line_no;
    lr_material_detail_in.item_id                 := it_item_id;
    lr_material_detail_in.line_type               := -1;
    lr_material_detail_in.item_um                 := it_item_um;
    lr_material_detail_in.release_type            := 1;                                     -- �����[�X�^�C�v
    lr_material_detail_in.scrap_factor            := 0;                                     -- �p���W��
    lr_material_detail_in.scale_type              := 1;                                     -- �X�P�[���^�C�v
    lr_material_detail_in.phantom_type            := 0;
    lr_material_detail_in.contribute_yield_ind    := 'Y';                                   -- �R���g���r���[�g����
    lr_material_detail_in.contribute_step_qty_ind := 'Y';                                   -- �R���g���r���[�g���o��X�e�b�v����
    lr_material_detail_in.plan_qty                := NVL( TO_NUMBER( it_attribute7 ), 0 );  -- �v�搔
    lr_material_detail_in.actual_qty              := NULL;                                  -- ���ѐ���
    lr_material_detail_in.original_qty            := NULL;                                  -- �I���W�i������
--
    ln_batch_step_no := TO_NUMBER( it_slit );
--
    lr_material_detail_in.attribute5  := it_attribute5;
    lr_material_detail_in.attribute7  := it_attribute7;
    lr_material_detail_in.attribute8  := it_slit;
    lr_material_detail_in.attribute13 := it_attribute13;
    lr_material_detail_in.attribute18 := it_attribute18;
    lr_material_detail_in.attribute19 := it_attribute19;
    lr_material_detail_in.attribute20 := it_attribute20;
    lr_material_detail_in.attribute21 := it_attribute21;
--
    -- ���Y�����ڍגǉ�API���s
    GME_API_PUB.INSERT_MATERIAL_LINE(
      p_api_version               =>  GME_API_PUB.API_VERSION         -- IN         NUMBER  := gme_api_pub.api_version
    , p_validation_level          =>  GME_API_PUB.MAX_ERRORS          -- IN         NUMBER  := gme_api_pub.max_errors
    , p_init_msg_list             =>  FALSE                           -- IN         BOOLEAN := FALSE
    , p_commit                    =>  FALSE                           -- IN         BOOLEAN := FALSE
    , x_message_count             =>  ln_message_count                -- OUT NOCOPY NUMBER
    , x_message_list              =>  lv_message_list                 -- OUT NOCOPY VARCHAR2
    , x_return_status             =>  lv_return_status                -- OUT NOCOPY VARCHAR2
    , p_material_detail           =>  lr_material_detail_in           -- IN         gme_material_details%ROWTYPE
    , p_batchstep_no              =>  ln_batch_step_no                -- IN         NUMBER DEFAULT NULL
    , x_material_detail           =>  lr_material_detail_out          -- OUT NOCOPY gme_material_details%ROWTYPE
    );
--
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      ov_errbuf  := lv_message_list;
      ov_errmsg  := '���Y�����ڍגǉ��Ɏ��s���܂����B';
      RAISE api_expt;
    END IF;
--
    -- ����I��
    ot_material_detail_id := lr_material_detail_out.material_detail_id;
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
  END insert_material_line;
--
  /************************************************************************
   * Procedure Name  : delete_material_line
   * Description     : ���Y�����ڍ׍폜API�ďo
   ************************************************************************/
  PROCEDURE delete_material_line(
    it_batch_id                     IN  gme_material_details.item_id            %TYPE
  , it_material_detail_id           IN  gme_material_details.material_detail_id %TYPE
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                   -- �G���[�E���b�Z�[�W
  , ov_retcode                      OUT NOCOPY VARCHAR2                                   -- ���^�[���E�R�[�h
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'delete_material_line';     -- �v���O������
    cv_api_name                     CONSTANT VARCHAR2(100) := '���Y�����ڍ׍폜';
--
    lv_errbuf                       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_message_count                NUMBER;
    lv_message_list                 VARCHAR2(100);
    lv_return_status                VARCHAR2(100);
--
    lr_material_detail_in           gme_material_details    %ROWTYPE;
--
  BEGIN
    lr_material_detail_in.batch_id           := it_batch_id;
    lr_material_detail_in.material_detail_id := it_material_detail_id;
--
    GME_API_PUB.DELETE_MATERIAL_LINE(
      p_api_version                   =>  GME_API_PUB.API_VERSION     -- IN         NUMBER  := gme_api_pub.api_version
    , p_validation_level              =>  GME_API_PUB.MAX_ERRORS      -- IN         NUMBER  := gme_api_pub.max_errors
    , p_init_msg_list                 =>  FALSE                       -- IN         BOOLEAN := FALSE
    , p_commit                        =>  FALSE                       -- IN         BOOLEAN := FALSE
    , x_message_count                 =>  ln_message_count            -- OUT NOCOPY NUMBER
    , x_message_list                  =>  lv_message_list             -- OUT NOCOPY VARCHAR2
    , x_return_status                 =>  lv_return_status            -- OUT NOCOPY VARCHAR2
    , p_material_detail               =>  lr_material_detail_in       -- IN         gme_material_details%ROWTYPE
    );
--
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      ov_errbuf := lv_message_list;
      ov_errmsg := '���Y�����ڍ׍폜�Ɏ��s���܂����B';
      RAISE api_expt;
    END IF;
--
    -- ����I��
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
  END delete_material_line;
--
  /************************************************************************
   * Procedure Name  : reschedule_batch
   * Description     : �o�b�`�ăX�P�W���[��
   ************************************************************************/
  PROCEDURE reschedule_batch(
    it_batch_id                     IN         gme_batch_header.batch_id         %TYPE
  , it_plan_start_date              IN         gme_batch_header.plan_start_date  %TYPE
  , it_plan_cmplt_date              IN         gme_batch_header.plan_cmplt_date  %TYPE
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                   -- �G���[�E���b�Z�[�W
  , ov_retcode                      OUT NOCOPY VARCHAR2                                   -- ���^�[���E�R�[�h
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'reschedule_batch';     -- �v���O������
    cv_api_name                     CONSTANT VARCHAR2(100) := '�o�b�`�ăX�P�W���[��';
--
    lv_return_status                VARCHAR2(1);
    lv_retcode                      VARCHAR2(1);
    ln_message_count                NUMBER;
    lv_message_list                 VARCHAR2(100);
--
    p_batch_header                  gme_batch_header%ROWTYPE;
    o_batch_header                  gme_batch_header%ROWTYPE;
--
  BEGIN
    p_batch_header.batch_id        := it_batch_id;
    p_batch_header.plan_start_date := it_plan_start_date;
    p_batch_header.plan_cmplt_date := it_plan_cmplt_date;
--
    -- �o�b�`�ăX�P�W���[��API�����s
    GME_API_PUB.RESCHEDULE_BATCH(
      p_api_version                   =>  GME_API_PUB.API_VERSION     -- IN         NUMBER := GME_API_PUB.API_VERSION
    , p_validation_level              =>  GME_API_PUB.MAX_ERRORS      -- IN         NUMBER := GME_API_PUB.MAX_ERRORS
    , p_init_msg_list                 =>  FALSE                       -- IN         BOOLEAN := FALSE
    , p_commit                        =>  FALSE                       -- IN         BOOLEAN := FALSE
    , x_message_count                 =>  ln_message_count            -- OUT NOCOPY NUMBER
    , x_message_list                  =>  lv_message_list             -- OUT NOCOPY VARCHAR2
    , x_return_status                 =>  lv_return_status            -- OUT NOCOPY VARCHAR2
    , p_batch_header                  =>  p_batch_header              -- IN         gme_batch_header%ROWTYPE
    , p_use_shop_cal                  =>  NULL                        -- IN         NUMBER
    , p_contiguity_override           =>  NULL                        -- IN         NUMBER
    , x_batch_header                  =>  o_batch_header              -- OUT NOCOPY gme_batch_header%ROWTYPE
    );
--
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      ov_errbuf := lv_message_list;
      ov_errmsg := '�o�b�`�ăX�P�W���[���Ɏ��s���܂����B';
      RAISE api_expt;
    END IF;
--
    -- ����I��
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
  END reschedule_batch;
--
  /**********************************************************************************
   * Procedure Name   : update_lot_dff
   * Description      : ���b�g�}�X�^DFF�X�VAPI�ďo
  /*********************************************************************************/
  PROCEDURE update_lot_dff(
    it_item_id                      IN         ic_lots_mst.item_id     %TYPE              -- �i��ID
  , it_lot_id                       IN         ic_lots_mst.lot_id      %TYPE              -- ���b�gID
  , it_attribute2                   IN         ic_lots_mst.attribute2  %TYPE DEFAULT NULL -- �ŗL�L��
  , it_attribute13                  IN         ic_lots_mst.attribute13 %TYPE DEFAULT NULL -- �^�C�v
  , it_attribute14                  IN         ic_lots_mst.attribute14 %TYPE DEFAULT NULL -- �����N1
  , it_attribute15                  IN         ic_lots_mst.attribute15 %TYPE DEFAULT NULL -- �����N2
  , it_attribute16                  IN         ic_lots_mst.attribute16 %TYPE DEFAULT NULL -- �`�[�敪
  , it_attribute17                  IN         ic_lots_mst.attribute17 %TYPE DEFAULT NULL -- ���C��No
  , it_attribute18                  IN         ic_lots_mst.attribute18 %TYPE DEFAULT NULL -- �E�v
  , it_attribute23                  IN         ic_lots_mst.attribute23 %TYPE DEFAULT NULL -- ���b�g�X�e�[�^�X
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                   -- �G���[�E���b�Z�[�W
  , ov_retcode                      OUT NOCOPY VARCHAR2                                   -- ���^�[���E�R�[�h
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'update_lot_dff';       -- �v���O������
    cv_api_name                     CONSTANT VARCHAR2(100) := '���b�g�}�X�^DFF�X�VAPI�ďo';
--
    lv_errbuf                       VARCHAR2(5000);
    lv_retcode                      VARCHAR2(1);
    lv_errmsg                       VARCHAR2(5000);
--
    ln_message_count                NUMBER;
    lv_message_list                 VARCHAR2(200);
--
    lr_ic_lots_mst                  ic_lots_mst%ROWTYPE;
--
  BEGIN
    -- �p�����[�^�ݒ�
    lr_ic_lots_mst.last_updated_by        := FND_GLOBAL.USER_ID;                -- �ŏI�X�V��
    lr_ic_lots_mst.last_update_date       := SYSDATE;                           -- �ŏI�X�V��
--
    -- OPM���b�g�}�X�^DFF�擾
    BEGIN
      SELECT
        ilm.item_id           item_id
      , ilm.lot_id            lot_id
      , ilm.lot_no            lot_no
      , ilm.attribute1        attribute1
      , ilm.attribute2        attribute2
      , ilm.attribute3        attribute3
      , ilm.attribute4        attribute4
      , ilm.attribute5        attribute5
      , ilm.attribute6        attribute6
      , ilm.attribute7        attribute7
      , ilm.attribute8        attribute8
      , ilm.attribute9        attribute9
      , ilm.attribute10       attribute10
      , ilm.attribute11       attribute11
      , ilm.attribute12       attribute12
      , ilm.attribute13       attribute13
      , ilm.attribute14       attribute14
      , ilm.attribute15       attribute15
      , ilm.attribute16       attribute16
      , ilm.attribute17       attribute17
      , ilm.attribute18       attribute18
      , ilm.attribute19       attribute19
      , ilm.attribute20       attribute20
      , ilm.attribute21       attribute21
      , ilm.attribute22       attribute22
      , ilm.attribute23       attribute23
      , ilm.attribute24       attribute24
      , ilm.attribute25       attribute25
      , ilm.attribute26       attribute26
      , ilm.attribute27       attribute27
      , ilm.attribute28       attribute28
      , ilm.attribute29       attribute29
      , ilm.attribute30       attribute30
      INTO
        lr_ic_lots_mst.item_id
      , lr_ic_lots_mst.lot_id
      , lr_ic_lots_mst.lot_no
      , lr_ic_lots_mst.attribute1
      , lr_ic_lots_mst.attribute2
      , lr_ic_lots_mst.attribute3
      , lr_ic_lots_mst.attribute4
      , lr_ic_lots_mst.attribute5
      , lr_ic_lots_mst.attribute6
      , lr_ic_lots_mst.attribute7
      , lr_ic_lots_mst.attribute8
      , lr_ic_lots_mst.attribute9
      , lr_ic_lots_mst.attribute10
      , lr_ic_lots_mst.attribute11
      , lr_ic_lots_mst.attribute12
      , lr_ic_lots_mst.attribute13
      , lr_ic_lots_mst.attribute14
      , lr_ic_lots_mst.attribute15
      , lr_ic_lots_mst.attribute16
      , lr_ic_lots_mst.attribute17
      , lr_ic_lots_mst.attribute18
      , lr_ic_lots_mst.attribute19
      , lr_ic_lots_mst.attribute20
      , lr_ic_lots_mst.attribute21
      , lr_ic_lots_mst.attribute22
      , lr_ic_lots_mst.attribute23
      , lr_ic_lots_mst.attribute24
      , lr_ic_lots_mst.attribute25
      , lr_ic_lots_mst.attribute26
      , lr_ic_lots_mst.attribute27
      , lr_ic_lots_mst.attribute28
      , lr_ic_lots_mst.attribute29
      , lr_ic_lots_mst.attribute30
      FROM
        ic_lots_mst   ilm -- OPM���b�g�}�X�^
      WHERE
            ilm.item_id = it_item_id   -- �i��ID
        AND ilm.lot_id  = it_lot_id    -- ���b�gID
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ov_errmsg  := 'OPM���b�g�}�X�^���擾�ł��܂���';
        RAISE api_expt;
--
      WHEN TOO_MANY_ROWS THEN
        ov_errmsg  := 'OPM���b�g�}�X�^���畡���t�F�b�`����܂����B';
        RAISE api_expt;
--
    END;
--
    -- ===============================
    -- �l�̐ݒ�
    -- ===============================
    IF ( it_attribute2 IS NOT NULL ) THEN
      lr_ic_lots_mst.attribute2 := it_attribute2;   -- �ŗL�L��
    END IF;
    IF ( it_attribute13 IS NOT NULL ) THEN
      lr_ic_lots_mst.attribute13 := it_attribute13;   -- �^�C�v
    END IF;
    IF ( it_attribute14 IS NOT NULL ) THEN
      lr_ic_lots_mst.attribute14 := it_attribute14;   -- �����N1
    END IF;
    IF ( it_attribute15 IS NOT NULL ) THEN
      lr_ic_lots_mst.attribute15 := it_attribute15;   -- �����N2
    END IF;
    IF ( it_attribute16 IS NOT NULL ) THEN
      lr_ic_lots_mst.attribute16 := it_attribute16;   -- �`�[�敪
    END IF;
    IF ( it_attribute17 IS NOT NULL ) THEN
      lr_ic_lots_mst.attribute17 := it_attribute17;   -- ���C��No
    END IF;
    IF ( it_attribute18 IS NOT NULL ) THEN
      lr_ic_lots_mst.attribute18 := it_attribute18;   -- �E�v
    END IF;
    IF ( it_attribute23 IS NOT NULL ) THEN
      lr_ic_lots_mst.attribute23 := it_attribute23;   -- ���b�g�X�e�[�^�X
    END IF;
--
    -- ===============================
    -- OPM���b�g�}�X�^DFF�X�V
    -- ===============================
    GMI_LOTUPDATE_PUB.UPDATE_LOT_DFF(
      p_api_version                 =>  gn_api_version                -- IN         NUMBER
    , p_init_msg_list               =>  FND_API.G_FALSE               -- IN         VARCHAR2 DEFAULT FND_API.G_FALSE
    , p_commit                      =>  FND_API.G_FALSE               -- IN         VARCHAR2 DEFAULT FND_API.G_FALSE
    , p_validation_level            =>  FND_API.G_VALID_LEVEL_FULL    -- IN         NUMBER   DEFAULT FND_API.G_VALID_LEVEL_FULL
    , x_return_status               =>  lv_retcode                    -- OUT NOCOPY VARCHAR2
    , x_msg_count                   =>  ln_message_count              -- OUT NOCOPY NUMBER
    , x_msg_data                    =>  lv_message_list               -- OUT NOCOPY VARCHAR2
    , p_lot_rec                     =>  lr_ic_lots_mst                -- IN  ic_lots_mst%ROWTYPE
    );
--
    -- �����ȊO�̏ꍇ�A�G���[
    IF ( lv_retcode <> FND_API.G_RET_STS_SUCCESS ) THEN
      ov_errbuf  := lv_retcode || lv_message_list;
      ov_errmsg  := '���b�g�}�X�^DFF�X�V�֐��G���[';
      RAISE api_expt;
--
    END IF;
--
    -- ����I��
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;
--
  END update_lot_dff;
--
  /**********************************************************************************
   * Function Name    : update_line_allocation
   * Description      : ���׊����X�VAPI�ďo
   ***********************************************************************************/
  PROCEDURE update_line_allocation(
    it_batch_id                     IN         gme_batch_header.batch_id  %TYPE -- �o�b�`ID
  , it_trans_id                     IN         ic_tran_pnd.trans_id       %TYPE -- �ۗ��݌�TrID
  , it_trans_qty                    IN         ic_tran_pnd.trans_qty      %TYPE -- �w������
  , it_completed_ind                IN         ic_tran_pnd.completed_ind  %TYPE -- �����t���O
  , ov_errbuf                       OUT NOCOPY VARCHAR2                         -- �G���[�E���b�Z�[�W
  , ov_retcode                      OUT NOCOPY VARCHAR2                         -- ���^�[���E�R�[�h
  , ov_errmsg                       OUT NOCOPY VARCHAR2                         -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'update_line_allocation';            --�v���O������
    cv_api_name                     CONSTANT VARCHAR2(100) := '���׊����X�VAPI�ďo';
--
    lv_errbuf                       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_message_count                NUMBER;
    lv_message_list                 VARCHAR2(100);
    lv_return_status                VARCHAR2(100);
--
    lr_tran_row_in                  gme_inventory_txns_gtmp %ROWTYPE;
    lr_tran_row_out                 gme_inventory_txns_gtmp %ROWTYPE;
    lr_def_tran_row                 gme_inventory_txns_gtmp %ROWTYPE;
    lr_material_detail              gme_material_details    %ROWTYPE;
--
  BEGIN
    -- �p�����[�^�ݒ�
    lr_tran_row_in.trans_id      := it_trans_id;
    lr_tran_row_in.trans_qty     := it_trans_qty;
    lr_tran_row_in.completed_ind := it_completed_ind;
--
    -- API���s
    GME_API_PUB.UPDATE_LINE_ALLOCATION(
      p_api_version                   =>  GME_API_PUB.API_VERSION       -- IN         NUMBER := GME_API_PUB.API_VERSION
    , p_validation_level              =>  GME_API_PUB.MAX_ERRORS        -- IN         NUMBER := GME_API_PUB.MAX_ERRORS
    , p_init_msg_list                 =>  FALSE                         -- IN         BOOLEAN := FALSE
    , p_commit                        =>  FALSE                         -- IN         BOOLEAN := FALSE
    , p_tran_row                      =>  lr_tran_row_in                -- IN         gme_inventory_txns_gtmp%ROWTYPE
    , p_lot_no                        =>  NULL                          -- IN         VARCHAR2 DEFAULT NULL
    , p_sublot_no                     =>  NULL                          -- IN         VARCHAR2 DEFAULT NULL
    , p_create_lot                    =>  FALSE                         -- IN         BOOLEAN DEFAULT FALSE
    , p_ignore_shortage               =>  TRUE                          -- IN         BOOLEAN DEFAULT FALSE
    , p_scale_phantom                 =>  FALSE                         -- IN         BOOLEAN DEFAULT FALSE
    , x_material_detail               =>  lr_material_detail            -- OUT NOCOPY gme_material_details%ROWTYPE
    , x_tran_row                      =>  lr_tran_row_out               -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE
    , x_def_tran_row                  =>  lr_def_tran_row               -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE
    , x_message_count                 =>  ln_message_count              -- OUT NOCOPY NUMBER
    , x_message_list                  =>  lv_message_list               -- OUT NOCOPY VARCHAR2
    , x_return_status                 =>  lv_return_status              -- OUT NOCOPY VARCHAR2
    );
--
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      ov_errbuf := lv_message_list;
      ov_errmsg := '���׊����X�V�Ɏ��s���܂����B';
      RAISE api_expt;
    END IF;
--
    -- ����I��
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
  END update_line_allocation;
--
  /**********************************************************************************
   * Function Name    : delete_line_allocation
   * Description      : ���׊����폜API�ďo
   ***********************************************************************************/
  PROCEDURE delete_line_allocation(
    it_batch_id                     IN         gme_batch_header.batch_id  %TYPE -- �o�b�`ID
  , it_trans_id                     IN         ic_tran_pnd.trans_id       %TYPE -- �ۗ��݌�TrID
  , ov_errbuf                       OUT NOCOPY VARCHAR2                         -- �G���[�E���b�Z�[�W
  , ov_retcode                      OUT NOCOPY VARCHAR2                         -- ���^�[���E�R�[�h
  , ov_errmsg                       OUT NOCOPY VARCHAR2                         -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'delete_line_allocation';   -- �v���O������
    cv_api_name                     CONSTANT VARCHAR2(100) := '���׊����폜API�ďo';
--
    lv_errbuf                       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_message_count                NUMBER;
    lv_message_list                 VARCHAR2(100);
    lv_return_status                VARCHAR2(100);
--
    lr_material_detail              gme_material_details    %ROWTYPE;
    lr_def_tran_row                 gme_inventory_txns_gtmp %ROWTYPE;
--
  BEGIN
    -- API���s
    gme_api_pub.delete_line_allocation(
      p_api_version                   =>  GME_API_PUB.API_VERSION       -- IN         NUMBER  := GME_API_PUB.API_VERSION
    , p_validation_level              =>  GME_API_PUB.MAX_ERRORS        -- IN         NUMBER  := GME_API_PUB.MAX_ERRORS
    , p_init_msg_list                 =>  FALSE                         -- IN         BOOLEAN := FALSE
    , p_commit                        =>  FALSE                         -- IN         BOOLEAN := FALSE
    , p_trans_id                      =>  it_trans_id                   -- IN         NUMBER
    , p_scale_phantom                 =>  FALSE                         -- IN         BOOLEAN DEFAULT FALSE
    , x_material_detail               =>  lr_material_detail            -- OUT NOCOPY gme_material_details%ROWTYPE
    , x_def_tran_row                  =>  lr_def_tran_row               -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE
    , x_message_count                 =>  ln_message_count              -- OUT NOCOPY NUMBER
    , x_message_list                  =>  lv_message_list               -- OUT NOCOPY VARCHAR2
    , x_return_status                 =>  lv_return_status              -- OUT NOCOPY VARCHAR2
    );
--
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      ov_errbuf  := lv_message_list;
      ov_errmsg  := '���׊����폜�Ɏ��s���܂����B';
      RAISE api_expt;
    END IF;
--
    -- ����I��
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
  END delete_line_allocation;
--
END xxwip_common2_pkg;
/
