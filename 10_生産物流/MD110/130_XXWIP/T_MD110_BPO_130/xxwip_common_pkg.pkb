CREATE OR REPLACE PACKAGE BODY xxwip_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwip_common_pkg(BODY)
 * Description            : ���ʊ֐�(XXWIP)(BODY)
 * MD.070(CMD.050)        : �Ȃ�
 * Version                : 1.0
 *
 * Program List
 *  --------------------   ---- ----- --------------------------------------------------
 *   Name                  Type  Ret   Description
 *  --------------------   ---- ----- --------------------------------------------------
 *  update_duty_status     P          �Ɩ��X�e�[�^�X�X�V�֐�
 *  insert_material_line   P          �������גǉ��֐�
 *  update_material_line   P          �������׍X�V�֐�
 *  delete_material_line   P          �������׍폜�֐�
 *  get_batch_no           F   VAR    �o�b�`No�擾�֐�
 *  lot_execute            P          ���b�g�ǉ��E�X�V�֐�
 *  insert_line_allocation P          ���׊����ǉ��֐�
 *  update_line_allocation P          ���׊����X�V�֐�
 *  delete_line_allocation P          ���׊����폜�֐�
 *  update_lot_dff_api     P          ���b�g�}�X�^DFF�X�V(���Y�o�b�`�p)
 *  update_inv_price       P          �݌ɒP���X�V�֐�
 *  update_trust_price     P          �ϑ����H��X�V�֐�
 *  qt_parameter_check     P          ���̓p�����[�^�`�F�b�N(����J)
 *  qt_check_and_lock      P          �f�[�^�`�F�b�N/���b�N(����J)
 *  qt_get_gme_data        P          ���Y���擾(����J)
 *  qt_get_po_data         P          �������擾(����J)
 *  qt_get_lot_data        P          ���b�g���擾(����J)
 *  qt_get_vendor_supply_data
 *                         P          �O���o�������擾(����J)
 *  qt_get_namaha_prod_data
 *                         P          �r���������擾(����J)
 *  qt_inspection_ins      P          �i�������˗����o�^/�X�V(����J)
 *  qt_update_lot_dff_api  P          ���b�g�}�X�^�X�V(����J)
 *  get_business_date      P          �c�Ɠ��擾
 *  make_qt_inspection     P          �i�������˗����쐬
 *  get_can_stock_qty      F          �莝�݌ɐ��ʎZ�oAPI(�������їp)
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2007/11/13   1.0   H.Itou           �V�K�쐬
 *  2008/05/28   1.1   Oracle ��r ��� �����e�X�g�s��Ή�(�ϑ����H��X�V�֐��C��)
 *  2008/06/02   1.2   Oracle ��r ��� �����ύX�v��#130(�ϑ����H��X�V�֐��C��)
 *****************************************************************************************/
--
--###############################  �Œ�O���[�o���萔�錾�� START   ###############################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';   --����
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';   --�x��
  gv_status_error  CONSTANT VARCHAR2(1) := '2';   --���s
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';   --�X�e�[�^�X(����)
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';   --�X�e�[�^�X(�x��)
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';   --�X�e�[�^�X(���s)
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
  gv_flg_on        CONSTANT VARCHAR2(1) := '1';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  gv_prof_cost_price CONSTANT VARCHAR2(26) := 'XXCMN_COST_PRICE_WHSE_CODE';
--
--#####################################  �Œ蕔 END   #############################################
--
--###############################  �Œ�O���[�o���ϐ��錾�� START   ###############################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);             -- ���s���[�U��
  gv_conc_name     VARCHAR2(30);              -- ���s�R���J�����g��
  gv_conc_status   VARCHAR2(30);              -- ��������
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- ���s����
  gn_warn_cnt      NUMBER;                    -- �x������
  gn_report_cnt    NUMBER;                    -- ���|�[�g����
--
--#####################################  �Œ蕔 END   #############################################
--
--##################################  �Œ苤�ʗ�O�錾�� START   ##################################
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
--#####################################  �Œ蕔 END   #############################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  api_expt               EXCEPTION;     -- API��O
  skip_expt              EXCEPTION;     -- �X�L�b�v��O
  deadlock_detected      EXCEPTION;     -- �f�b�h���b�N�G���[
--
  PRAGMA EXCEPTION_INIT(deadlock_detected, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name        CONSTANT VARCHAR2(100) := 'xxwip_common_pkg'; -- �p�b�P�[�W��
  -- ���W���[��������
  gv_xxcmn           CONSTANT VARCHAR2(100) := 'XXCMN';            -- ���W���[�������́FXXCMN ����
  gv_xxwip           CONSTANT VARCHAR2(100) := 'XXWIP';            -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
  -- ���b�Z�[�W
  gv_msg_xxwip10049  CONSTANT VARCHAR2(100) := 'APP-XXWIP-10049';  -- ���b�Z�[�W�FAPP-XXWIP-10049 API�G���[���b�Z�[�W
  gv_batch_no        CONSTANT VARCHAR2(100) := '�o�b�`No.';
--
  -- �g�[�N��
  gv_tkn_batch_no    CONSTANT VARCHAR2(100) := 'BATCH_NO';         -- �g�[�N���FBATCH_NO
  gv_tkn_api_name    CONSTANT VARCHAR2(100) := 'API_NAME';         -- �g�[�N���FAPI_NAME
--
  -- API���^�[���E�R�[�h
  gv_api_s           CONSTANT VARCHAR2(1)   := 'S';                -- API���^�[���E�R�[�h�FS �i�����j
--
  gv_type_y          CONSTANT VARCHAR2(1)   := 'Y';                -- �^�C�v�FY
  gv_type_n          CONSTANT VARCHAR2(1)   := 'N';                -- �^�C�v�FN
--
  -- ���C���^�C�v
  gn_prod            CONSTANT NUMBER        := 1;                  -- �����i
  gn_co_prod         CONSTANT NUMBER        := 2;                  -- ���Y��
  gn_material        CONSTANT NUMBER        := -1;                 -- �����i
--
  gn_default_lot_id  CONSTANT NUMBER        := 0;                  -- �f�t�H���g���b�gID
  gn_delete_mark_on  CONSTANT NUMBER        := 1;                  -- �폜�t���OON
  gn_delete_mark_off CONSTANT NUMBER        := 0;                  -- �폜�t���OOFF
  gv_cmpnt_code_gen  CONSTANT VARCHAR2(5)   := '01GEN';            -- �i�ڃR���|�[�l���g�敪�F01GEN
  -- xxcmn���ʊ֐����^�[���E�R�[�h
  gn_e               CONSTANT NUMBER        := 1;                  -- xxcmn���ʊ֐����^�[���E�R�[�h�F1�i�G���[�j
--
  -- �Ɩ��X�e�[�^�X
  gt_duty_status_com   CONSTANT gme_batch_header.attribute4%TYPE := '7';  -- �Ɩ��X�e�[�^�X�F7�i�����j
  gt_duty_status_cls   CONSTANT gme_batch_header.attribute4%TYPE := '8';  -- �Ɩ��X�e�[�^�X�F8�i�N���[�Y�j
  gt_duty_status_can   CONSTANT gme_batch_header.attribute4%TYPE := '-1'; -- �Ɩ��X�e�[�^�X�F-1�i����j
  -- �敪
  gt_division_gme     CONSTANT xxwip_qt_inspection.division%TYPE := '1';  -- �敪  1:���Y
  gt_division_po      CONSTANT xxwip_qt_inspection.division%TYPE := '2';  -- �敪  2:����
  gt_division_lot     CONSTANT xxwip_qt_inspection.division%TYPE := '3';  -- �敪  3:���b�g���
  gt_division_spl     CONSTANT xxwip_qt_inspection.division%TYPE := '4';  -- �敪  4:�O���o����
  gt_division_tea     CONSTANT xxwip_qt_inspection.division%TYPE := '5';  -- �敪  5:�r������
  -- �����敪
  gv_disposal_div_ins CONSTANT VARCHAR2(1) := '1'; -- �����敪  1:�ǉ�
  gv_disposal_div_upd CONSTANT VARCHAR2(1) := '2'; -- �����敪  2:�X�V
  gv_disposal_div_del CONSTANT VARCHAR2(1) := '3'; -- �����敪  3:�폜
  -- �Ώې�
  gv_qt_object_tea    CONSTANT VARCHAR2(1) := '1'; -- �Ώې�  1:�r���i��
  gv_qt_object_bp1    CONSTANT VARCHAR2(1) := '2'; -- �Ώې�  2:���Y���P
  gv_qt_object_bp2    CONSTANT VARCHAR2(1) := '3'; -- �Ώې�  3:���Y���Q
  gv_qt_object_bp3    CONSTANT VARCHAR2(1) := '4'; -- �Ώې�  4:���Y���R
  -- ���Y�����ڍ�.���C���^�C�v
  gt_line_type_goods  CONSTANT gme_material_details.line_type%TYPE := 1;    -- ���C���^�C�v�F1�i�����i�j
  gt_line_type_sub    CONSTANT gme_material_details.line_type%TYPE := 2;    -- ���C���^�C�v�F2�i���Y���j
  -- OPM�ۗ��݌Ƀg�����U�N�V����.�����t���O
  gt_completed_ind_com CONSTANT ic_tran_pnd.completed_ind%TYPE     := '1';  -- �����t���O�F1�i�����j
  -- �i����������
  gt_qt_status_mi     CONSTANT fnd_lookup_values.lookup_code%TYPE := '10';  -- �i���������� 10:������
  -- �������
  gt_inspect_class_gme   CONSTANT xxwip_qt_inspection.inspect_class%TYPE := '1'; -- ������ʁF1�i���Y�j
  gt_inspect_class_po    CONSTANT xxwip_qt_inspection.inspect_class%TYPE := '2'; -- ������ʁF2�i�����d���j
  -- �i�ڋ敪
  gv_item_type_mtl       CONSTANT VARCHAR2(1) := '1'; -- �i�ڋ敪  1:����
  gv_item_type_shz       CONSTANT VARCHAR2(1) := '2'; -- �i�ڋ敪  2:����
  gv_item_type_harf_prod CONSTANT VARCHAR2(1) := '4'; -- �i�ڋ敪  4:�����i
  gv_item_type_prod      CONSTANT VARCHAR2(1) := '5'; -- �i�ڋ敪  5:���i
  -- �ϑ��v�Z�敪
  gv_trust_calc_type_volume  CONSTANT VARCHAR2(1) := '1'; -- �ϑ��v�Z�敪  1:�o����
  gv_trust_calc_type_invest  CONSTANT VARCHAR2(1) := '2'; -- �ϑ��v�Z�敪  2:����
  -- OPM���b�g�}�X�^DFF�X�VAPI�o�[�W����
  gn_api_version      CONSTANT NUMBER(2,1) := 1.0;
--
  -- �O���o�������.�����^�C�v
  gt_txns_type_aite CONSTANT XXPO_VENDOR_SUPPLY_TXNS.txns_type%TYPE := '1';  -- �����^�C�v�F�����݌�
  gt_txns_type_sok  CONSTANT XXPO_VENDOR_SUPPLY_TXNS.txns_type%TYPE := '2';  -- �����^�C�v�F�����d��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : update_duty_status
   * Description      : �Ɩ��X�e�[�^�X�X�V�֐�
   ***********************************************************************************/
  PROCEDURE update_duty_status(
    in_batch_id                   IN  NUMBER                -- 1.�X�V�Ώۂ̃o�b�`ID
  , iv_duty_status                IN  VARCHAR2              -- 2.�X�V�X�e�[�^�X
  , ov_errbuf                     OUT NOCOPY VARCHAR2       -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode                    OUT NOCOPY VARCHAR2       -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg                     OUT NOCOPY VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                   CONSTANT VARCHAR2(100) := 'update_duty_status';           --�v���O������
    cv_api_name                   CONSTANT VARCHAR2(100) := '�Ɩ��X�e�[�^�X�X�V�֐�';
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf                     VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode                    VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg                     VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ld_date                       DATE;
    ln_message_count              NUMBER;                             -- ���b�Z�[�W�J�E���g
    lv_message_list               VARCHAR2(200);                      -- ���b�Z�[�W���X�g
    lv_return_status              VARCHAR2(100);                      -- ���^�[���X�e�[�^�X
    lt_batch_status               gme_batch_header.batch_status%TYPE; -- �o�b�`�X�e�[�^�X
    lt_batch_no                   gme_batch_header.batch_no%TYPE;     -- �o�b�`NO
    lt_batch_id_dummy             gme_batch_header.batch_id%TYPE;     -- �o�b�`ID
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_gme_batch_header           gme_batch_header%ROWTYPE;              --
    lr_gme_batch_header_temp      gme_batch_header%ROWTYPE;              --
    lr_unallocated_materials      GME_API_PUB.UNALLOCATED_MATERIALS_TAB; --
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***********************************************
    -- ***  ���Y�o�b�`�w�b�_�̃��b�N
    -- ***********************************************
    BEGIN
      SELECT gbh.batch_id   batch_id   -- �o�b�`ID
      INTO   lt_batch_id_dummy
      FROM   gme_batch_header gbh      -- ���Y�o�b�`�w�b�_
      WHERE  gbh.batch_id = in_batch_id
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN DEADLOCK_DETECTED THEN
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        null;
--
      WHEN TOO_MANY_ROWS THEN
        null;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ***********************************************
    -- ***  �o�b�`No���擾
    -- ***********************************************
    lt_batch_no := xxwip_common_pkg.get_batch_no( in_batch_id );
--
    -- ***********************************************
    -- ***  ���Y�o�b�`�w�b�_�̋Ɩ��X�e�[�^�X���X�V
    -- ***********************************************
    UPDATE gme_batch_header gbh
    SET    gbh.attribute4       = iv_duty_status       -- �Ɩ��X�e�[�^�X
      ,    gbh.last_update_date = SYSDATE              -- �ŏI�X�V��
      ,    gbh.last_updated_by  = FND_GLOBAL.USER_ID   -- �ŏI�X�V��
    WHERE  gbh.batch_id = in_batch_id
    ;
--
    -- *************************************************
    -- ***  ���Y�o�b�`�w�b�_�̃o�b�`�X�e�[�^�X���擾
    -- *************************************************
    SELECT gbh.batch_status batch_status -- �o�b�`�X�e�[�^�X
    INTO   lt_batch_status
    FROM   gme_batch_header gbh          -- ���Y�o�b�`�w�b�_
    WHERE  gbh.batch_id = in_batch_id
    ;
--
    -- *************************************************
    -- ***  ���Y�����擾�ANULL�̏ꍇ�̓V�X�e�����t���擾
    -- *************************************************
    SELECT NVL( FND_DATE.STRING_TO_DATE( gmd.attribute11, 'YYYY/MM/DD' ), TRUNC( SYSDATE ) )
    INTO   ld_date
    FROM   gme_material_details gmd     -- ���Y�����ڍ�
    WHERE  gmd.batch_id  = in_batch_id
    AND    gmd.line_type = gn_prod
    AND    ROWNUM        = 1
    ;
--
    -- �o�b�`�X�e�[�^�X���ۗ����A�X�V�X�e�[�^�X�������̏ꍇ�A�o�b�`�X�e�[�^�X��WIP�ɍX�V
    IF (
             ( '1' = lt_batch_status )
         AND ( iv_duty_status = gt_duty_status_com )
    )
    THEN
--
      lr_gme_batch_header.batch_id          := in_batch_id;
      lr_gme_batch_header.actual_start_date := ld_date;
--
      -- ���Y�o�b�`�����[�X�֐������s
      GME_API_PUB.RELEASE_BATCH(
        p_api_version                   =>  GME_API_PUB.API_VERSION
      , p_validation_level              =>  GME_API_PUB.MAX_ERRORS
      , p_init_msg_list                 =>  FALSE
      , p_commit                        =>  FALSE
      , x_message_count                 =>  ln_message_count
      , x_message_list                  =>  lv_message_list
      , x_return_status                 =>  lv_retcode
      , p_batch_header                  =>  lr_gme_batch_header
      , x_batch_header                  =>  lr_gme_batch_header_temp
      , p_ignore_shortages              =>  FALSE
      , p_consume_avail_plain_item      =>  FALSE
      , x_unallocated_material          =>  lr_unallocated_materials
      , p_ignore_unalloc                =>  TRUE
      );
--
      IF ( lv_retcode <> gv_api_s ) THEN
        RAISE api_expt;
      END IF;
--
    -- �o�b�`�X�e�[�^�X���N���[�Y�A�X�V�X�e�[�^�X�������̏ꍇ�A�o�b�`�X�e�[�^�X��WIP�ɍX�V
    ELSIF (
             ( '4' = lt_batch_status )
         AND ( iv_duty_status = gt_duty_status_com )
    )
    THEN
      lr_gme_batch_header.batch_id          := in_batch_id;
      lr_gme_batch_header.actual_start_date := ld_date;
--
      -- �o�b�`�ăI�[�v���֐������s
      GME_API_PUB.REOPEN_BATCH(
        p_api_version                   =>  GME_API_PUB.API_VERSION   -- IN         NUMBER  := gme_api_pub.api_version
      , p_validation_level              =>  GME_API_PUB.MAX_ERRORS    -- IN         NUMBER  := gme_api_pub.max_errors
      , p_init_msg_list                 =>  FALSE                     -- IN         BOOLEAN := FALSE
      , p_commit                        =>  FALSE                     -- IN         BOOLEAN := FALSE
      , x_message_count                 =>  ln_message_count          -- OUT NOCOPY NUMBER
      , x_message_list                  =>  lv_message_list           -- OUT NOCOPY VARCHAR2
      , x_return_status                 =>  lv_retcode                -- OUT NOCOPY VARCHAR2
      , p_batch_header                  =>  lr_gme_batch_header       -- IN         gme_batch_header%ROWTYPE
-- �ύX START 2008/05/07 Oikawa
      , p_reopen_steps                  =>  TRUE                      -- IN         BOOLEAN := FALSE
--      , p_reopen_steps                  =>  FALSE                     -- IN         BOOLEAN := FALSE
-- �ύX END
      , x_batch_header                  =>  lr_gme_batch_header_temp  -- OUT NOCOPY gme_batch_header%ROWTYPE
      );
--
      IF ( lv_retcode <> gv_api_s ) THEN
        RAISE api_expt;
      END IF;
--
      -- WIP�ɖ߂��֐������s
      GME_API_PUB.UNCERTIFY_BATCH(
        p_api_version                   =>  GME_API_PUB.API_VERSION   -- IN              NUMBER := gme_api_pub.api_version
      , p_validation_level              =>  GME_API_PUB.MAX_ERRORS    -- IN              NUMBER := gme_api_pub.max_errors
      , p_init_msg_list                 =>  FALSE                     -- IN              BOOLEAN := FALSE
      , p_commit                        =>  FALSE                     -- IN              BOOLEAN := FALSE
      , x_message_count                 =>  ln_message_count          -- OUT NOCOPY      NUMBER
      , x_message_list                  =>  lv_message_list           -- OUT NOCOPY      VARCHAR2
      , x_return_status                 =>  lv_retcode                -- OUT NOCOPY      VARCHAR2
      , p_batch_header                  =>  lr_gme_batch_header       -- IN              gme_batch_header%ROWTYPE
      , x_batch_header                  =>  lr_gme_batch_header_temp  -- OUT NOCOPY      gme_batch_header%ROWTYPE
      );
--
      IF ( lv_retcode <> gv_api_s ) THEN
        RAISE api_expt;
      END IF;
--
    -- �X�V�X�e�[�^�X������̏ꍇ�A�o�b�`�X�e�[�^�X������ɍX�V
    ELSIF ( iv_duty_status = gt_duty_status_can ) THEN
      lr_gme_batch_header.batch_id := in_batch_id;
--
      -- ���Y����֐������s
      GME_API_PUB.CANCEL_BATCH(
        p_api_version                   =>  GME_API_PUB.API_VERSION   -- IN              NUMBER := gme_api_pub.api_version
      , p_validation_level              =>  GME_API_PUB.MAX_ERRORS    -- IN              NUMBER := gme_api_pub.max_errors
      , p_init_msg_list                 =>  FALSE                     -- IN              BOOLEAN := FALSE
      , p_commit                        =>  FALSE                     -- IN              BOOLEAN := FALSE
      , x_message_count                 =>  ln_message_count          -- OUT NOCOPY      NUMBER
      , x_message_list                  =>  lv_message_list           -- OUT NOCOPY      VARCHAR2
      , x_return_status                 =>  lv_retcode                -- OUT NOCOPY      VARCHAR2
      , p_batch_header                  =>  lr_gme_batch_header       -- IN              gme_batch_header%ROWTYPE
      , x_batch_header                  =>  lr_gme_batch_header_temp  -- OUT NOCOPY      gme_batch_header%ROWTYPE
      );
--
      IF ( lv_retcode <> gv_api_s ) THEN
        RAISE api_expt;
      END IF;
--
    END IF;
--
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip                -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
                     ,gv_msg_xxwip10049       -- ���b�Z�[�W�FAPP-XXWIP-10049 API�G���[���b�Z�[�W
                     ,gv_tkn_api_name         -- �g�[�N���FAPI_NAME
                     ,cv_api_name             -- API��
                    ),1,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
      -- API���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,gv_batch_no || lt_batch_no);
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- ���O������
      FND_MSG_PUB.INITIALIZE;
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END update_duty_status;
--
  /**********************************************************************************
   * Function Name    : get_batch_no
   * Description      : �o�b�`No�擾
   ***********************************************************************************/
  FUNCTION get_batch_no(
    it_batch_id gme_batch_header.batch_id%TYPE
  )
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_batch_no' ; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lt_batch_no   gme_batch_header.batch_no%TYPE;            -- �o�b�`No
--
  BEGIN
--
    -- ***********************************************
    -- ***  �o�b�`No���擾���܂��B***
    -- ***********************************************
    SELECT gbh.batch_no batch_no -- �o�b�`No
    INTO   lt_batch_no
    FROM   gme_batch_header gbh -- ���Y�o�b�`�w�b�_
    WHERE  gbh.batch_id = it_batch_id
    ;
--
    RETURN lt_batch_no ;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
    RETURN NULL ;
  END get_batch_no ;
--
  /**********************************************************************************
   * Procedure Name   : insert_material_line
   * Description      : �������גǉ��֐�
   ***********************************************************************************/
  PROCEDURE insert_material_line(
    ir_material_detail IN  gme_material_details%ROWTYPE,
    or_material_detail OUT NOCOPY gme_material_details%ROWTYPE,
    ov_errbuf      OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_material_line'; --�v���O������
    -- *** ���[�J���萔 ***
    cv_api_name   CONSTANT VARCHAR2(100) := '�������גǉ��֐�';
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
    ln_message_count       NUMBER;                       -- ���b�Z�[�W����
    lv_message_list        VARCHAR2(100);                -- ���b�Z�[�W���X�g
    lv_return_status       VARCHAR2(100);                -- ���^�[���X�e�[�^�X
    lr_material_detail_in  gme_material_details%ROWTYPE; -- ���Y�����ڍ�IN
    lr_material_detail_out gme_material_details%ROWTYPE; -- ���Y�����ڍ�OUT
    lt_batch_no            gme_batch_header.batch_no%TYPE;  -- �o�b�`NO
    ln_batch_step_no       NUMBER;                          -- �o�b�`�X�e�b�vNo
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- IN�p�����[�^��ݒ肵�܂�
    lr_material_detail_in := ir_material_detail;
--
    -- ***********************************************
    -- ***  �o�b�`No���擾���܂��B***
    -- ***********************************************
    lt_batch_no := xxwip_common_pkg.get_batch_no(lr_material_detail_in.batch_id);
--
    -- ***********************************************
    -- ***  �sNo���擾���܂��B               ***
    -- ***********************************************
    BEGIN
      SELECT NVL(MAX(gmd.line_no),0) + 1 line_no  -- �����i�̍ő�sNo
      INTO   lr_material_detail_in.line_no
      FROM   gme_material_details gmd -- ���Y�����ڍ�
      WHERE  gmd.batch_id  = lr_material_detail_in.batch_id
      AND    gmd.line_type = lr_material_detail_in.line_type
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE api_expt;
    END;
--
    -- �����i�̏ꍇ
    IF ( lr_material_detail_in.line_type = gn_material) THEN
      -- ***********************************************
      -- ***  �e�����ݒ肵�܂��B                 ***
      -- ***********************************************
      lr_material_detail_in.release_type            := 1;     -- �����[�X�^�C�v
      lr_material_detail_in.scrap_factor            := 0;     -- �p���W��
      lr_material_detail_in.scale_type              := 1;     -- �X�P�[���^�C�v
      lr_material_detail_in.contribute_yield_ind    := 'Y';   -- �R���g���r���[�g����
      lr_material_detail_in.contribute_step_qty_ind := 'Y';   -- �R���g���r���[�g���o��X�e�b�v����
      lr_material_detail_in.wip_plan_qty            := 0;     -- WIP�v�搔
      lr_material_detail_in.plan_qty                := 0;     -- �v�搔
      lr_material_detail_in.actual_qty              := null;  -- ���ѐ���
      lr_material_detail_in.original_qty            := null;  -- �I���W�i������
      ln_batch_step_no := TO_NUMBER(lr_material_detail_in.attribute8);
--
      -- ***********************************************
      -- ***  �����i��ǉ����܂��B                   ***
      -- ***********************************************
      GME_API_PUB.INSERT_MATERIAL_LINE(
        p_api_version           => GME_API_PUB.API_VERSION
       ,p_validation_level      => GME_API_PUB.MAX_ERRORS
       ,p_init_msg_list         => FALSE
       ,p_commit                => FALSE
       ,x_message_count         => ln_message_count
       ,x_message_list          => lv_message_list
       ,x_return_status         => lv_return_status
       ,p_material_detail       => lr_material_detail_in
       ,p_batchstep_no          => ln_batch_step_no
       ,x_material_detail       => lr_material_detail_out
      );
      IF (lv_return_status <> gv_api_s) THEN
        lv_errbuf := lv_message_list;
        RAISE api_expt;
      END IF;
--
    -- ���Y���̏ꍇ
    ELSIF ( lr_material_detail_in.line_type = gn_co_prod ) THEN
--
      -- ***********************************************
      -- ***  �����i�̐��Y���A�ܖ��������擾���܂��B ***
      -- ***********************************************
      BEGIN
        SELECT gmd.attribute10 -- �ܖ�������
              ,gmd.attribute11 -- ���Y��
              ,gmd.attribute17 -- ������
        INTO   lr_material_detail_in.attribute10
              ,lr_material_detail_in.attribute11
              ,lr_material_detail_in.attribute17
        FROM   gme_material_details gmd  -- ���Y�����ڍ�
        WHERE  gmd.line_type = gn_prod -- �����i
        AND    gmd.batch_id  = lr_material_detail_in.batch_id
        AND    ROWNUM        = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lr_material_detail_in.attribute10 := NULL; -- �ܖ�������
          lr_material_detail_in.attribute11 := NULL; -- ���Y��
          lr_material_detail_in.attribute17 := NULL; -- ������
      END;
--
      -- ***********************************************
      -- ***  �e�����ݒ肵�܂��B                 ***
      -- ***********************************************
      lr_material_detail_in.release_type            := 1;     -- �����[�X�^�C�v
      lr_material_detail_in.scrap_factor            := 0;     -- �p���W��
      lr_material_detail_in.scale_type              := 1;     -- �X�P�[���^�C�v
      lr_material_detail_in.contribute_yield_ind    := 'Y';   -- �R���g���r���[�g����
      lr_material_detail_in.contribute_step_qty_ind := 'Y';   -- �R���g���r���[�g���o��X�e�b�v����
      lr_material_detail_in.wip_plan_qty            := 0;     -- WIP�v�搔
      lr_material_detail_in.plan_qty                := 0;     -- �v�搔
      lr_material_detail_in.actual_qty              := null;  -- ���ѐ���
      lr_material_detail_in.original_qty            := null;  -- �I���W�i������
      ln_batch_step_no := TO_NUMBER(lr_material_detail_in.attribute8);
--
      -- ***********************************************
      -- ***  ���Y����ǉ����܂��B                   ***
      -- ***********************************************
      GME_API_PUB.INSERT_MATERIAL_LINE(
        p_api_version           => GME_API_PUB.API_VERSION   -- IN �Fp_api_version
       ,p_validation_level      => GME_API_PUB.MAX_ERRORS    -- IN �Fp_validation_level
       ,p_init_msg_list         => FALSE                     -- IN �Fp_init_msg_list
       ,p_commit                => FALSE                     -- IN �Fp_commit
       ,x_message_count         => ln_message_count          -- OUT�Fx_message_count
       ,x_message_list          => lv_message_list           -- OUT�Fx_message_list
       ,x_return_status         => lv_return_status          -- OUT�Fx_return_status
       ,p_material_detail       => lr_material_detail_in     -- IN :p_material_detail
       ,p_batchstep_no          => ln_batch_step_no          -- IN :p_batchstep_no
       ,x_material_detail       => lr_material_detail_out    -- OUT:x_material_detail
      );
--
      IF (lv_return_status <> gv_api_s) THEN
        lv_errbuf := lv_message_list;
        RAISE api_expt;
      END IF;
--
    END IF;
    -- OUT�p�����[�^��ݒ肵�܂�
    or_material_detail := lr_material_detail_out;
--
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip                -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
                     ,gv_msg_xxwip10049       -- ���b�Z�[�W�FAPP-XXWIP-10049 API�G���[���b�Z�[�W
                     ,gv_tkn_api_name         -- �g�[�N���FAPI_NAME
                     ,cv_api_name             -- API��
                    ),1,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
      -- API���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,gv_batch_no || lt_batch_no);
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END insert_material_line;
--
  /**********************************************************************************
   * Procedure Name   : update_material_line
   * Description      : �������׍X�V�֐�
   ***********************************************************************************/
  PROCEDURE update_material_line(
    ir_material_detail IN  gme_material_details%ROWTYPE,
    ov_errbuf      OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W             --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h               --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_material_line'; --�v���O������
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
    ln_message_count        NUMBER;                       --
    lv_message_list         VARCHAR2(100);                --
    lv_return_status        VARCHAR2(100);                --
    lt_batch_id             gme_material_details.batch_id%TYPE;           -- �o�b�`ID
    lt_material_detail_id   gme_material_details.material_detail_id%TYPE; -- ���Y�����ڍ�ID
    lt_expiration_date      gme_material_details.attribute10%TYPE;        -- �ܖ�������
    lt_prouct_date          gme_material_details.attribute11%TYPE;        -- ���Y��
    lt_maker_date           gme_material_details.attribute17%TYPE;        -- ������
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_material_detail           gme_material_details%ROWTYPE;        --
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    lr_material_detail := ir_material_detail;
    -- ***********************************************
    -- ***  ���Y�����ڍׂ̃��b�N���擾���܂��B     ***
    -- ***********************************************
    BEGIN
      SELECT gmd.batch_id            -- �o�b�`ID
            ,gmd.material_detail_id  -- ���Y�����ڍ�ID
      INTO   lt_batch_id
            ,lt_material_detail_id
      FROM   gme_material_details gmd  -- ���Y�����ڍ�
      WHERE  gmd.material_detail_id = lr_material_detail.material_detail_id
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN DEADLOCK_DETECTED THEN
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        null;
--
      WHEN TOO_MANY_ROWS THEN
        null;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- �����i�̏ꍇ
    IF ( lr_material_detail.line_type = gn_prod ) THEN
      -- ***********************************************
      -- ***  �����i�̐��Y���A�ܖ��������擾���܂��B ***
      -- ***********************************************
      BEGIN
        SELECT gmd.attribute10 -- �ܖ�������
              ,gmd.attribute11 -- ���Y��
              ,gmd.attribute17 -- ������
        INTO   lt_expiration_date
              ,lt_prouct_date
              ,lt_maker_date
        FROM   gme_material_details gmd  -- ���Y�����ڍ�
        WHERE  gmd.line_type = gn_prod
        AND    gmd.batch_id  = lt_batch_id
        AND    ROWNUM        = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lt_expiration_date := NULL; -- �ܖ�������
          lt_prouct_date     := NULL; -- ���Y��
          lt_maker_date      := NULL; -- ������
      END;
      -- ***********************************************
      -- ***  �����i�̏����X�V���܂��B             ***
      -- ***********************************************
      UPDATE gme_material_details gmd
      SET    gmd.attribute1  = lr_material_detail.attribute1
            ,gmd.attribute2  = lr_material_detail.attribute2
            ,gmd.attribute3  = lr_material_detail.attribute3
            ,gmd.attribute4  = lr_material_detail.attribute4
            ,gmd.attribute6  = lr_material_detail.attribute6
            ,gmd.attribute9  = lr_material_detail.attribute9
            ,gmd.attribute10 = lr_material_detail.attribute10
            ,gmd.attribute11 = lr_material_detail.attribute11
            ,gmd.attribute14 = lr_material_detail.attribute14
            ,gmd.attribute15 = lr_material_detail.attribute15
            ,gmd.attribute16 = lr_material_detail.attribute16
            ,gmd.attribute17 = lr_material_detail.attribute17
            ,gmd.last_updated_by   = FND_GLOBAL.USER_ID
            ,gmd.last_update_date  = SYSDATE
            ,gmd.last_update_login = FND_GLOBAL.LOGIN_ID
      WHERE  gmd.material_detail_id  = lr_material_detail.material_detail_id
      ;
--
      -- ���Y���A�������A�ܖ��������̂����ꂩ�ɕύX���������ꍇ
      IF (   (lr_material_detail.attribute10 <> lt_expiration_date)
          OR (lr_material_detail.attribute11 <> lt_prouct_date)
          OR (lr_material_detail.attribute17 <> lt_maker_date)     ) THEN
--
        -- *******************************************************
        -- ***  ���Y���̐��Y�����ڍׂ̃��b�N���擾���܂��B     ***
        -- *******************************************************
        BEGIN
          SELECT gmd.batch_id            -- �o�b�`ID
          INTO   lt_batch_id
          FROM   gme_material_details gmd  -- ���Y�����ڍ�
          WHERE  gmd.material_detail_id = lt_batch_id
          AND    line_type = gn_co_prod
          FOR UPDATE NOWAIT
          ;
        EXCEPTION
          WHEN DEADLOCK_DETECTED THEN
            RAISE global_api_expt;
--
          WHEN NO_DATA_FOUND THEN
            null;
--
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
--
        UPDATE gme_material_details gmd
        SET    gmd.attribute10 = lr_material_detail.attribute10
              ,gmd.attribute11 = lr_material_detail.attribute11
              ,gmd.attribute17 = lr_material_detail.attribute17
              ,gmd.last_updated_by   = FND_GLOBAL.USER_ID
              ,gmd.last_update_date  = SYSDATE
              ,gmd.last_update_login = FND_GLOBAL.LOGIN_ID
        WHERE  gmd.batch_id = lt_batch_id
        AND    line_type    = gn_co_prod
        ;
      END IF;
    -- ���Y���̏ꍇ
    ELSIF ( lr_material_detail.line_type = gn_co_prod ) THEN
      -- ***********************************************
      -- ***  �����i�̐��Y���A�ܖ��������擾���܂��B ***
      -- ***********************************************
      BEGIN
        SELECT gmd.attribute10 -- �ܖ�������
              ,gmd.attribute11 -- ���Y��
              ,gmd.attribute17 -- ������
        INTO   lr_material_detail.attribute10
              ,lr_material_detail.attribute11
              ,lr_material_detail.attribute17
        FROM   gme_material_details gmd  -- ���Y�����ڍ�
        WHERE  gmd.line_type = gn_prod
        AND    gmd.batch_id  = lt_batch_id
        AND    ROWNUM        = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lr_material_detail.attribute10 := NULL; -- �ܖ�������
          lr_material_detail.attribute11 := NULL; -- ���Y��
          lr_material_detail.attribute17 := NULL; -- ������
      END;
--
      -- ***********************************************
      -- ***  ���Y���̏����X�V���܂��B             ***
      -- ***********************************************
      UPDATE gme_material_details gmd
      SET    gmd.attribute1        = lr_material_detail.attribute1
            ,gmd.attribute2        = lr_material_detail.attribute2
            ,gmd.attribute3        = lr_material_detail.attribute3
            ,gmd.attribute6        = lr_material_detail.attribute6
            ,gmd.attribute10       = lr_material_detail.attribute10
            ,gmd.attribute11       = lr_material_detail.attribute11
            ,gmd.attribute17       = lr_material_detail.attribute17
            ,gmd.last_updated_by   = FND_GLOBAL.USER_ID
            ,gmd.last_update_date  = SYSDATE
            ,gmd.last_update_login = FND_GLOBAL.LOGIN_ID
      WHERE  gmd.material_detail_id  = lr_material_detail.material_detail_id
      ;
--
    END IF;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
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
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
      ov_retcode := gv_status_error;                                            --# �C�� #
  END update_material_line;
--
  /**********************************************************************************
   * Procedure Name   : delete_material_line
   * Description      : �������׍폜�֐�
   ***********************************************************************************/
  PROCEDURE delete_material_line(
    in_batch_id    IN  NUMBER,     -- ���Y�o�b�`ID
    in_mtl_dtl_id  IN  NUMBER,     -- ���Y�����ڍ�ID
    ov_errbuf      OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_material_line'; --�v���O������
    -- *** ���[�J���萔 ***
    cv_api_name   CONSTANT VARCHAR2(100) := '�������׍폜�֐�';
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
    ln_message_count       NUMBER;                       --
    lv_message_list        VARCHAR2(100);                --
    lv_return_status       VARCHAR2(100);                --
    lt_batch_status        gme_batch_header.batch_status%TYPE; -- �o�b�`�X�e�[�^�X
    lt_batch_no            gme_batch_header.batch_no%TYPE;     -- �o�b�`NO
--
    -- *** ���[�J���E�J�[�\�� ***
    -- OPM�ۗ��݌Ƀg�����U�N�V�����J�[�\��
    CURSOR cur_ic_tran_pnd
    IS
      SELECT itp.trans_id trans_id
            ,itp.trans_qty
            ,itp.line_type
      FROM   ic_tran_pnd itp -- OPM�ۗ��݌Ƀg�����U�N�V����
      WHERE  itp.doc_id    = in_batch_id
      AND    itp.line_id   = in_mtl_dtl_id
      AND    itp.lot_id    = gn_default_lot_id
      ;
    -- ���Y���pOPM�ۗ��݌Ƀg�����U�N�V�����J�[�\��
    CURSOR cur_ic_tran_pnd_co_prod
    IS
      SELECT itp.trans_id trans_id
      FROM   ic_tran_pnd itp -- OPM�ۗ��݌Ƀg�����U�N�V����
      WHERE  itp.line_id     = in_mtl_dtl_id
      AND    itp.line_type   = gn_co_prod
      AND    itp.reverse_id  IS NULL
      AND    itp.delete_mark = gn_delete_mark_off
      AND    itp.lot_id      > gn_default_lot_id
      ;
--
    -- *** ���[�J���E���R�[�h ***
    lr_material_detail_in  gme_material_details%ROWTYPE;
    lr_material_detail_out gme_material_details%ROWTYPE;
    lr_tran_row_in         gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out        gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_def        gme_inventory_txns_gtmp%ROWTYPE;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    lr_material_detail_in.batch_id           := in_batch_id;
    lr_material_detail_in.material_detail_id := in_mtl_dtl_id;
--
    -- ***********************************************
    -- ***  �o�b�`No���擾���܂��B***
    -- ***********************************************
    lt_batch_no := xxwip_common_pkg.get_batch_no(lr_material_detail_in.batch_id);
--
    -- *************************************************
    -- ***  ���Y�o�b�`�w�b�_�̃o�b�`�X�e�[�^�X���擾���܂��B***
    -- *************************************************
    BEGIN
      SELECT gbh.batch_status batch_status
      INTO   lt_batch_status
      FROM   gme_batch_header gbh
      WHERE  gbh.batch_id = lr_material_detail_in.batch_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_api_expt;
--
      WHEN TOO_MANY_ROWS THEN
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    -- �o�b�`�X�e�[�^�X��WIP�̏ꍇ
    IF (2 = lt_batch_status) THEN
      -- *************************************************
      -- ***  ���Y���̊������폜���܂��B   ***
      -- *************************************************
      <<co_prod_loop>>
      FOR rec_ic_tran_pnd_co_prod IN cur_ic_tran_pnd_co_prod LOOP
        -- *************************************************
        -- ***  �����폜�֐������s���܂��B               ***
        -- *************************************************
        GME_API_PUB.DELETE_LINE_ALLOCATION (
          p_api_version        => GME_API_PUB.API_VERSION          -- IN         NUMBER := gme_api_pub.api_version
         ,p_validation_level   => GME_API_PUB.MAX_ERRORS           -- IN         NUMBER := gme_api_pub.max_errors
         ,p_init_msg_list      => FALSE                            -- IN         BOOLEAN := FALSE
         ,p_commit             => FALSE                            -- IN         BOOLEAN := FALSE
         ,p_trans_id           => rec_ic_tran_pnd_co_prod.trans_id -- IN         NUMBER
         ,p_scale_phantom      => FALSE                            -- IN         BOOLEAN DEFAULT FALSE
         ,x_material_detail    => lr_material_detail_out           -- OUT NOCOPY gme_material_details%ROWTYPE
         ,x_def_tran_row       => lr_tran_row_def                  -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE
         ,x_message_count      => ln_message_count                 -- OUT NOCOPY NUMBER
         ,x_message_list       => lv_message_list                  -- OUT NOCOPY VARCHAR2
         ,x_return_status      => lv_return_status                 -- OUT NOCOPY VARCHAR2
        );
        IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          lv_errbuf := lv_message_list;
          RAISE api_expt;
        END IF;
      END LOOP;
      -- *************************************************
      -- ***  �f�t�H���g���b�g�̏���ID���擾���܂��B   ***
      -- *************************************************
      <<ic_tran_pnd_loop>>
      FOR rec_ic_tran_pnd IN cur_ic_tran_pnd LOOP
        lr_tran_row_in.trans_id := rec_ic_tran_pnd.trans_id;
        IF (rec_ic_tran_pnd.trans_qty > 0) THEN
          -- *************************************************
          -- ***  �������ʂ�0��ݒ肵�܂��B                ***
          -- *************************************************
          lr_tran_row_in.trans_qty := 0;
          -- *************************************************
          -- ***  �����X�V�֐������s���܂��B               ***
          -- *************************************************
          GME_API_PUB.UPDATE_LINE_ALLOCATION (
            p_api_version        => GME_API_PUB.API_VERSION -- IN         NUMBER := gme_api_pub.api_version
           ,p_validation_level   => GME_API_PUB.MAX_ERRORS  -- IN         NUMBER := gme_api_pub.max_errors
           ,p_init_msg_list      => FALSE                   -- IN         BOOLEAN := FALSE
           ,p_commit             => FALSE                   -- IN         BOOLEAN := FALSE
           ,p_tran_row           => lr_tran_row_in          -- IN         gme_inventory_txns_gtmp%ROWTYPE
           ,p_lot_no             => NULL                    -- IN         VARCHAR2 DEFAULT NULL
           ,p_sublot_no          => NULL                    -- IN         VARCHAR2 DEFAULT NULL
           ,p_create_lot         => FALSE                   -- IN         BOOLEAN DEFAULT FALSE
           ,p_ignore_shortage    => FALSE                   -- IN         BOOLEAN DEFAULT FALSE
           ,p_scale_phantom      => FALSE                   -- IN         BOOLEAN DEFAULT FALSE
           ,x_material_detail    => lr_material_detail_out  -- OUT NOCOPY gme_material_details%ROWTYPE
           ,x_tran_row           => lr_tran_row_out         -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE
           ,x_def_tran_row       => lr_tran_row_def         -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE
           ,x_message_count      => ln_message_count        -- OUT NOCOPY NUMBER
           ,x_message_list       => lv_message_list         -- OUT NOCOPY VARCHAR2
           ,x_return_status      => lv_return_status        -- OUT NOCOPY VARCHAR2
          );
          IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
            lv_errbuf := lv_message_list;
            RAISE api_expt;
          END IF;
        END IF;
        -- ********************************************
        -- ***  �폜�t���O���X�V���܂��B               ***
        -- ********************************************
        UPDATE gme_material_details gmd
        SET    gmd.attribute24        = gv_type_y,           -- �폜�t���O
               gmd.last_update_date   = SYSDATE,             -- �ŏI�X�V��
               gmd.last_updated_by    = FND_GLOBAL.USER_ID   -- �ŏI�X�V��
        WHERE  gmd.material_detail_id = lr_material_detail_in.material_detail_id
        ;
      END LOOP;
    ELSE
      -- *********************************************
      -- ***  �����폜�֐������s���܂��B           ***
      -- *********************************************
      GME_API_PUB.DELETE_MATERIAL_LINE(
        p_api_version        => GME_API_PUB.API_VERSION -- IN         NUMBER := gme_api_pub.api_version
       ,p_validation_level   => GME_API_PUB.MAX_ERRORS  -- IN         NUMBER := gme_api_pub.max_errors
       ,p_init_msg_list      => FALSE                   -- IN         BOOLEAN := FALSE
       ,p_commit             => FALSE                   -- IN         BOOLEAN := FALSE
       ,x_message_count      => ln_message_count        -- OUT NOCOPY NUMBER
       ,x_message_list       => lv_message_list         -- OUT NOCOPY VARCHAR2
       ,x_return_status      => lv_return_status        -- OUT NOCOPY VARCHAR2
       ,p_material_detail    => lr_material_detail_in   -- IN         gme_material_details%ROWTYPE
      );
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        lv_errbuf := lv_message_list;
        RAISE api_expt;
      END IF;
    END IF;
--
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip                -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
                     ,gv_msg_xxwip10049       -- ���b�Z�[�W�FAPP-XXWIP-10049 API�G���[���b�Z�[�W
                     ,gv_tkn_api_name         -- �g�[�N���FAPI_NAME
                     ,cv_api_name             -- API���F���Y�o�b�`�w�b�_����
                    ),1,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
      -- API���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,gv_batch_no || lt_batch_no);
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END delete_material_line;
--
  /**********************************************************************************
   * Procedure Name   : update_lot_dff_api
   * Description      : ���b�g�}�X�^�X�V(���Y�o�b�`�p)
  /*********************************************************************************/
  PROCEDURE update_lot_dff_api(
    iv_update_type          IN  VARCHAR2,                   -- IN 1.Y:NULL�ł�UPDATE�AN:NULL�̏ꍇ��UPDATE�ΏۊO
    ir_ic_lots_mst_in       IN  ic_lots_mst%ROWTYPE,        -- IN 2.ic_lots_mst���R�[�h�^
    ir_ic_lots_mst_out      OUT NOCOPY ic_lots_mst%ROWTYPE, -- OUT 1.ic_lots_mst���R�[�h�^
    ov_errbuf               OUT NOCOPY VARCHAR2,                   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,                   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_lot_dff_api'; -- �v���O������
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
    ln_message_count      NUMBER;         -- ���b�Z�[�W�J�E���g
    lv_message_list       VARCHAR2(200);  -- ���b�Z�[�W���X�g

--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_ic_lots_mst          ic_lots_mst%ROWTYPE;          -- ���b�g�}�X�^���R�[�h�^
--
  BEGIN
    -- ���^�[���R�[�h�Z�b�g
    ov_retcode := gv_status_normal;
--
    -- ====================================
    -- OPM���b�g�}�X�^���R�[�h�ɒl���Z�b�g
    -- ====================================
    lr_ic_lots_mst.last_updated_by        := FND_GLOBAL.USER_ID;                -- �ŏI�X�V��
    lr_ic_lots_mst.last_update_date       := SYSDATE;                           -- �ŏI�X�V��
--
    -- ===============================
    -- OPM���b�g�}�X�^���b�N
    -- ===============================
    BEGIN
      SELECT ilm.item_id       item_id
            ,ilm.lot_id        lot_id
            ,ilm.lot_no        lot_no
            ,ilm.attribute1    attribute1
            ,ilm.attribute2    attribute2
            ,ilm.attribute3    attribute3
            ,ilm.attribute4    attribute4
            ,ilm.attribute5    attribute5
            ,ilm.attribute6    attribute6
            ,ilm.attribute7    attribute7
            ,ilm.attribute8    attribute8
            ,ilm.attribute9    attribute9
            ,ilm.attribute10   attribute10
            ,ilm.attribute11   attribute11
            ,ilm.attribute12   attribute12
            ,ilm.attribute13   attribute13
            ,ilm.attribute14   attribute14
            ,ilm.attribute15   attribute15
            ,ilm.attribute16   attribute16
            ,ilm.attribute17   attribute17
            ,ilm.attribute18   attribute18
            ,ilm.attribute19   attribute19
            ,ilm.attribute20   attribute20
            ,ilm.attribute21   attribute21
            ,ilm.attribute22   attribute22
            ,ilm.attribute23   attribute23
            ,ilm.attribute24   attribute24
            ,ilm.attribute25   attribute25
            ,ilm.attribute26   attribute26
            ,ilm.attribute27   attribute27
            ,ilm.attribute28   attribute28
            ,ilm.attribute29   attribute29
            ,ilm.attribute30   attribute30
      INTO   lr_ic_lots_mst.item_id
            ,lr_ic_lots_mst.lot_id
            ,lr_ic_lots_mst.lot_no
            ,lr_ic_lots_mst.attribute1
            ,lr_ic_lots_mst.attribute2
            ,lr_ic_lots_mst.attribute3
            ,lr_ic_lots_mst.attribute4
            ,lr_ic_lots_mst.attribute5
            ,lr_ic_lots_mst.attribute6
            ,lr_ic_lots_mst.attribute7
            ,lr_ic_lots_mst.attribute8
            ,lr_ic_lots_mst.attribute9
            ,lr_ic_lots_mst.attribute10
            ,lr_ic_lots_mst.attribute11
            ,lr_ic_lots_mst.attribute12
            ,lr_ic_lots_mst.attribute13
            ,lr_ic_lots_mst.attribute14
            ,lr_ic_lots_mst.attribute15
            ,lr_ic_lots_mst.attribute16
            ,lr_ic_lots_mst.attribute17
            ,lr_ic_lots_mst.attribute18
            ,lr_ic_lots_mst.attribute19
            ,lr_ic_lots_mst.attribute20
            ,lr_ic_lots_mst.attribute21
            ,lr_ic_lots_mst.attribute22
            ,lr_ic_lots_mst.attribute23
            ,lr_ic_lots_mst.attribute24
            ,lr_ic_lots_mst.attribute25
            ,lr_ic_lots_mst.attribute26
            ,lr_ic_lots_mst.attribute27
            ,lr_ic_lots_mst.attribute28
            ,lr_ic_lots_mst.attribute29
            ,lr_ic_lots_mst.attribute30
      FROM   ic_lots_mst   ilm -- OPM���b�g�}�X�^
      WHERE  ilm.item_id = ir_ic_lots_mst_in.item_id   -- �i��ID
      AND    ilm.lot_id  = ir_ic_lots_mst_in.lot_id    -- ���b�gID
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN DEADLOCK_DETECTED THEN
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        RAISE global_api_expt;
--
      WHEN TOO_MANY_ROWS THEN
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ===============================
    -- �l�̐ݒ�
    -- ===============================
    IF (ir_ic_lots_mst_in.attribute7 IS NOT NULL) THEN
      -- �݌ɒP��
      lr_ic_lots_mst.attribute7 := ir_ic_lots_mst_in.attribute7;
    ELSE
      -- �ܖ�����
      lr_ic_lots_mst.attribute3 := ir_ic_lots_mst_in.attribute3;
      -- �݌ɓ���
      lr_ic_lots_mst.attribute6 := ir_ic_lots_mst_in.attribute6;
      IF (iv_update_type = gv_type_y) THEN
        -- �����N����
        IF (ir_ic_lots_mst_in.attribute1 IS NOT NULL) THEN
          lr_ic_lots_mst.attribute1 := ir_ic_lots_mst_in.attribute1;
        END IF;
        -- �^�C�v
        IF (ir_ic_lots_mst_in.attribute13 IS NOT NULL) THEN
          lr_ic_lots_mst.attribute13 := ir_ic_lots_mst_in.attribute13;
        END IF;
        -- �����N�P
        IF (ir_ic_lots_mst_in.attribute14 IS NOT NULL) THEN
          lr_ic_lots_mst.attribute14 := ir_ic_lots_mst_in.attribute14;
        END IF;
        -- �����N�Q
        IF (ir_ic_lots_mst_in.attribute15 IS NOT NULL) THEN
          lr_ic_lots_mst.attribute15 := ir_ic_lots_mst_in.attribute15;
        END IF;
        -- �E�v
        IF (ir_ic_lots_mst_in.attribute18 IS NOT NULL) THEN
          lr_ic_lots_mst.attribute18 := ir_ic_lots_mst_in.attribute18;
        END IF;
      ELSE
        -- �����N����
        lr_ic_lots_mst.attribute1  := ir_ic_lots_mst_in.attribute1;
        -- �^�C�v
        lr_ic_lots_mst.attribute13 := ir_ic_lots_mst_in.attribute13;
        -- �����N�P
        lr_ic_lots_mst.attribute14 := ir_ic_lots_mst_in.attribute14;
        -- �����N�Q
        lr_ic_lots_mst.attribute15 := ir_ic_lots_mst_in.attribute15;
        -- �E�v
        lr_ic_lots_mst.attribute18 := ir_ic_lots_mst_in.attribute18;
      END IF;
    END IF;
--
    -- ===============================
    -- OPM���b�g�}�X�^DFF�X�V
    -- ===============================
    GMI_LOTUPDATE_PUB.UPDATE_LOT_DFF(
      p_api_version       => gn_api_version             -- IN  NUMBER
     ,p_init_msg_list     => FND_API.G_FALSE            -- IN  VARCHAR2 DEFAULT FND_API.G_FALSE
     ,p_commit            => FND_API.G_FALSE            -- IN  VARCHAR2 DEFAULT FND_API.G_FALSE
     ,p_validation_level  => FND_API.G_VALID_LEVEL_FULL -- IN  NUMBER   DEFAULT FND_API.G_VALID_LEVEL_FULL
     ,x_return_status     => lv_retcode                 -- OUT NOCOPY       VARCHAR2
     ,x_msg_count         => ln_message_count           -- OUT NOCOPY       NUMBER
     ,x_msg_data          => lv_message_list            -- OUT NOCOPY       VARCHAR2
     ,p_lot_rec           => lr_ic_lots_mst             -- IN  ic_lots_mst%ROWTYPE
    );
    -- �����ȊO�̏ꍇ�A�G���[
    IF (lv_retcode <> FND_API.G_RET_STS_SUCCESS)THEN
      ov_errbuf  := lv_message_list;
      ov_errmsg  := '���b�g�X�V�֐��G���[';
      RAISE api_expt;
    END IF;
--
    -- ===============================
    -- OPM���b�g�}�X�^DFF�Z�b�g
    -- ===============================
    ir_ic_lots_mst_out.lot_id      := lr_ic_lots_mst.lot_id;
    ir_ic_lots_mst_out.lot_no      := lr_ic_lots_mst.lot_no;
    ir_ic_lots_mst_out.attribute1  := lr_ic_lots_mst.attribute1;
    ir_ic_lots_mst_out.attribute3  := lr_ic_lots_mst.attribute3;
    ir_ic_lots_mst_out.attribute6  := lr_ic_lots_mst.attribute6;
    ir_ic_lots_mst_out.attribute13 := lr_ic_lots_mst.attribute13;
    ir_ic_lots_mst_out.attribute14 := lr_ic_lots_mst.attribute14;
    ir_ic_lots_mst_out.attribute15 := lr_ic_lots_mst.attribute15;
    ir_ic_lots_mst_out.attribute18 := lr_ic_lots_mst.attribute18;
    ir_ic_lots_mst_out.attribute22 := lr_ic_lots_mst.attribute22;
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;                                            --# �C�� #
--
--###############################  �Œ��O������ START   ###################################
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
--###################################  �Œ蕔 END   #########################################
--
  END update_lot_dff_api;
--
  /**********************************************************************************
   * Procedure Name   : lot_execute
   * Description      : ���b�g�ǉ��E�X�V�֐�
   ***********************************************************************************/
  PROCEDURE lot_execute(
    ir_lot_mst         IN  ic_lots_mst%ROWTYPE,                 -- OPM���b�g�}�X�^
    it_item_no         IN  ic_item_mst_b.item_no%TYPE,          -- �i�ڃR�[�h
    it_line_type       IN  gme_material_details.line_type%TYPE, -- ���C���^�C�v
    it_item_class_code IN  mtl_categories_b.segment1%TYPE,      -- �i�ڋ敪
    it_lot_no_prod     IN  ic_lots_mst.lot_no%TYPE,             -- �����i�̃��b�gNo
    or_lot_mst         OUT NOCOPY ic_lots_mst%ROWTYPE,          -- OPM���b�g�}�X�^
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lot_execute'; --�v���O������
    -- *** ���[�J���萔 ***
    cv_api_name   CONSTANT VARCHAR2(100) := '���b�g�ǉ��E�X�V�֐�';
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
    lt_sublot_no           ic_lots_mst.sublot_no%TYPE;   -- �T�u���b�gNo
    ln_return_status       NUMBER;                       -- ���^�[���X�e�[�^�X
    ln_message_count       NUMBER;                       --
    lv_message_list        VARCHAR2(10000);              --
    lv_msg_data            VARCHAR2(10000);              --
    lv_return_status       VARCHAR2(100);                --
    lt_batch_status        gme_batch_header.batch_status%TYPE; -- �o�b�`�X�e�[�^�X
    lt_batch_no            gme_batch_header.batch_no%TYPE;     -- �o�b�`NO
    ln_message_cnt_dummy   NUMBER;                       --
    lb_return_status       BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_material_detail_in  gme_material_details%ROWTYPE;
    lr_material_detail_out gme_material_details%ROWTYPE;
    lr_tran_row_in         gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out        gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_def        gme_inventory_txns_gtmp%ROWTYPE;
    lr_lot_mst_base        ic_lots_mst%ROWTYPE;
    lr_lot_mst             ic_lots_mst%ROWTYPE;
    lr_create_lot          GMIGAPI.lot_rec_typ;
    lr_ic_lots_mst         ic_lots_mst%ROWTYPE;
    lr_ic_lots_cpg         ic_lots_cpg%ROWTYPE;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ���b�g����ޔ�
    lr_lot_mst_base := ir_lot_mst;
    lr_lot_mst      := ir_lot_mst;
--
    lb_return_status :=GMIGUTL.SETUP(FND_GLOBAL.USER_NAME);
--
    -- ���C���^�C�v�������i�̏ꍇ
    IF (it_line_type = gn_prod) THEN
--
      -- ���i�̏ꍇ�A���݃`�F�b�N���s���B
      IF (it_item_class_code = gv_item_type_prod) THEN
        -- ***********************************************
        -- ***  ���݃`�F�b�N���s���܂��B               ***
        -- ***********************************************
        BEGIN
          SELECT ilm.lot_id
                ,ilm.lot_no
          INTO   lr_lot_mst.lot_id
                ,lr_lot_mst.lot_no
          FROM   ic_lots_mst ilm  --OPM���b�g�}�X�^
          WHERE  ilm.item_id    = lr_lot_mst_base.item_id     --�i��ID
          AND    ilm.attribute1 = lr_lot_mst_base.attribute1  --�����N����
          AND    ilm.attribute2 = lr_lot_mst_base.attribute2  --�ŗL�L��
          AND    ROWNUM         = 1
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lr_lot_mst.lot_id := NULL;
            lr_lot_mst.lot_no := NULL;
        END;
      -- �����i�̏ꍇ
      ELSIF (it_item_class_code = gv_item_type_harf_prod) THEN
        lr_lot_mst.lot_no := it_lot_no_prod;
        IF ((lr_lot_mst.lot_id IS NULL) OR (lr_lot_mst.lot_no IS NULL)) THEN
          ov_errbuf  := '�s���ȃf�[�^�ł��B';
          RAISE api_expt;
        END IF;
      END IF;
      -- ���b�gNo�����݂��Ȃ��ꍇ
      IF (lr_lot_mst.lot_no IS NULL) THEN
        -- ***********************************************
        -- ***  ���b�gNo���擾���܂��B                 ***
        -- ***********************************************
        GMI_AUTOLOT.GENERATE_LOT_NUMBER(
          p_item_id         => lr_lot_mst.item_id
         ,p_in_lot_no       => NULL
         ,p_orgn_code       => NULL
         ,p_doc_id          => NULL
         ,p_line_id         => NULL
         ,p_doc_type        => NULL
         ,p_out_lot_no      => lr_lot_mst.lot_no
         ,p_sublot_no       => lt_sublot_no
         ,p_return_status   => ln_return_status
        );
        -- �̔Ԃ���Ă��Ȃ��ꍇ
        IF (lr_lot_mst.lot_no IS NULL) THEN
          ov_errbuf  := '���b�g�̔ԂɎ��s���܂����B';
          RAISE api_expt;
        END IF;
        -- *************************************************
        -- *** ���b�g��V�K�ɍ쐬���܂��B                ***
        -- *************************************************
        lr_create_lot.item_no          := it_item_no;
        lr_create_lot.lot_no           := lr_lot_mst.lot_no;
        lr_create_lot.sublot_no        := NULL;
        lr_create_lot.lot_desc         := NULL;
        lr_create_lot.origination_type := 2;
        lr_create_lot.attribute1       := lr_lot_mst.attribute1;
        lr_create_lot.attribute2       := lr_lot_mst.attribute2;
        lr_create_lot.attribute3       := lr_lot_mst.attribute3;
        lr_create_lot.attribute6       := lr_lot_mst.attribute6;
        lr_create_lot.attribute13      := lr_lot_mst.attribute13;
        lr_create_lot.attribute14      := lr_lot_mst.attribute14;
        lr_create_lot.attribute15      := lr_lot_mst.attribute15;
        lr_create_lot.attribute16      := lr_lot_mst.attribute16;
        lr_create_lot.attribute17      := lr_lot_mst.attribute17;
        lr_create_lot.attribute18      := lr_lot_mst.attribute18;
        lr_create_lot.attribute23      := lr_lot_mst.attribute23;
        lr_create_lot.attribute24      := '5'; -- ���Y�o����
        lr_create_lot.user_name        := FND_GLOBAL.USER_NAME;
        lr_create_lot.lot_created      := SYSDATE;
--
        --���b�g�쐬API
        GMIPAPI.CREATE_LOT(
           p_api_version      => 3.0
          ,p_init_msg_list    => FND_API.G_FALSE
          ,p_commit           => FND_API.G_FALSE
          ,p_validation_level => FND_API.G_VALID_LEVEL_FULL
          ,p_lot_rec          => lr_create_lot
          ,x_ic_lots_mst_row  => or_lot_mst
          ,x_ic_lots_cpg_row  => lr_ic_lots_cpg
          ,x_return_status    => lv_return_status
          ,x_msg_count        => ln_message_count
          ,x_msg_data         => lv_msg_data
        );
        IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          ov_errbuf  := lv_msg_data;
          ov_errmsg  := ov_errmsg || '���b�g�쐬�Ɏ��s���܂����B';
          RAISE api_expt;
        END IF;
      -- ���b�gNo�����݂���ꍇ(�t���ւ��̏ꍇ)
      ELSIF (NVL(it_lot_no_prod, -1) <> lr_lot_mst.lot_no) THEN
        update_lot_dff_api(
          iv_update_type      => gv_type_y
         ,ir_ic_lots_mst_in   => lr_lot_mst
         ,ir_ic_lots_mst_out  => or_lot_mst
         ,ov_errbuf           => lv_errbuf
         ,ov_retcode          => lv_retcode
         ,ov_errmsg           => lv_errmsg
        );
        IF (lv_retcode <> gv_status_normal) THEN
          ov_errbuf  := lv_errbuf;
          ov_errmsg  := '���b�g�X�V�Ɏ��s���܂����B�F' || lv_errmsg;
          RAISE api_expt;
        END IF;
      -- ���b�gNo�����݂���ꍇ(���b�g�ύX�Ȃ��Œʏ�̍X�V)
      ELSIF (it_lot_no_prod = lr_lot_mst.lot_no) THEN
        update_lot_dff_api(
          iv_update_type      => gv_type_n
         ,ir_ic_lots_mst_in   => lr_lot_mst
         ,ir_ic_lots_mst_out  => or_lot_mst
         ,ov_errbuf           => lv_errbuf
         ,ov_retcode          => lv_retcode
         ,ov_errmsg           => lv_errmsg
        );
        IF (lv_retcode <> gv_status_normal) THEN
          ov_errbuf  := lv_errbuf;
          ov_errmsg  := '���b�g�X�V�Ɏ��s���܂����B�F' || lv_errmsg;
          RAISE api_expt;
        END IF;
      END IF;
    -- ���C���^�C�v�����Y���̏ꍇ
    ELSE
      -- �����i�̃��b�gNo�ƈقȂ�ꍇ
      IF (it_lot_no_prod <> NVL(lr_lot_mst_base.lot_no, -1)) THEN
        -- ***********************************************
        -- ***  ���݃`�F�b�N���s���܂��B               ***
        -- ***********************************************
        BEGIN
          SELECT ilm.lot_id
                ,ilm.lot_no
          INTO   lr_lot_mst.lot_id
                ,lr_lot_mst.lot_no
          FROM   ic_lots_mst ilm  -- OPM���b�g�}�X�^
          WHERE  ilm.item_id = lr_lot_mst_base.item_id -- �i��ID
          AND    ilm.lot_no  = it_lot_no_prod          -- ���b�gNo
          AND    ROWNUM      = 1
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lr_lot_mst.lot_id := NULL;
            lr_lot_mst.lot_no := NULL;
        END;
      END IF;
      -- ���b�gNo�����݂��Ȃ��ꍇ
      IF (lr_lot_mst.lot_no IS NULL) THEN
        -- *************************************************
        -- *** �����i�̃��b�gNo�Ń��b�g��V�K�ɍ쐬���܂��B*
        -- *************************************************
        lr_create_lot.item_no          := it_item_no;
        lr_create_lot.lot_no           := it_lot_no_prod;
        lr_create_lot.sublot_no        := NULL;
        lr_create_lot.lot_desc         := NULL;
        lr_create_lot.origination_type := 2;
        lr_create_lot.attribute1       := lr_lot_mst.attribute1;
        lr_create_lot.attribute2       := lr_lot_mst.attribute2;
        lr_create_lot.attribute3       := lr_lot_mst.attribute3;
        lr_create_lot.attribute6       := lr_lot_mst.attribute6;
        lr_create_lot.attribute13      := lr_lot_mst.attribute13;
        lr_create_lot.attribute14      := lr_lot_mst.attribute14;
        lr_create_lot.attribute15      := lr_lot_mst.attribute15;
        lr_create_lot.attribute16      := lr_lot_mst.attribute16;
        lr_create_lot.attribute17      := lr_lot_mst.attribute17;
        lr_create_lot.attribute23      := lr_lot_mst.attribute23;
        lr_create_lot.attribute24      := '5'; -- ���Y�o����
        lr_create_lot.user_name        := FND_GLOBAL.USER_NAME;
        lr_create_lot.lot_created      := SYSDATE;
--
        --���b�g�쐬API
        GMIPAPI.CREATE_LOT(
          p_api_version      => 3.0
         ,p_init_msg_list    => FND_API.G_FALSE
         ,p_commit           => FND_API.G_FALSE
         ,p_validation_level => FND_API.G_VALID_LEVEL_FULL
         ,p_lot_rec          => lr_create_lot
         ,x_ic_lots_mst_row  => or_lot_mst
         ,x_ic_lots_cpg_row  => lr_ic_lots_cpg
         ,x_return_status    => lv_return_status
         ,x_msg_count        => ln_message_count
         ,x_msg_data         => lv_msg_data
        );
        IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          ov_errbuf  := lv_msg_data;
          ov_errmsg  := '���b�g�X�V�Ɏ��s���܂����B�F' || lv_errmsg;
          RAISE api_expt;
        END IF;
      -- ���b�gNo�����݂��邪���݂̃��b�gNo�ƈقȂ�ꍇ(�t���ւ�)
      ELSIF (lr_lot_mst.lot_no <> NVL(lr_lot_mst_base.lot_no, -1)) THEN
        -- *************************************************
        -- *** ���b�g���X�V���܂��B                      ***
        -- *************************************************
        update_lot_dff_api(
          iv_update_type      => gv_type_y
         ,ir_ic_lots_mst_in   => lr_lot_mst
         ,ir_ic_lots_mst_out  => or_lot_mst
         ,ov_errbuf           => lv_errbuf
         ,ov_retcode          => lv_retcode
         ,ov_errmsg           => lv_errmsg
        );
        IF (lv_retcode <> gv_status_normal) THEN
          ov_errbuf  := lv_errbuf;
          ov_errmsg  := '���b�g�X�V�Ɏ��s���܂����B�F' || lv_errmsg;
          RAISE api_expt;
        END IF;
      -- ���b�gNo�����݂����݂̃��b�gNo�Ɠ����ꍇ(�ʏ�X�V)
      ELSIF (lr_lot_mst.lot_no = lr_lot_mst_base.lot_no) THEN
        -- *************************************************
        -- *** ���b�g���X�V���܂��B                      ***
        -- *************************************************
        update_lot_dff_api(
          iv_update_type      => gv_type_n
         ,ir_ic_lots_mst_in   => lr_lot_mst
         ,ir_ic_lots_mst_out  => or_lot_mst
         ,ov_errbuf           => lv_errbuf
         ,ov_retcode          => lv_retcode
         ,ov_errmsg           => lv_errmsg
        );
        IF (lv_retcode <> gv_status_normal) THEN
          ov_errbuf  := lv_errbuf;
          ov_errmsg  := '���b�g�X�V�Ɏ��s���܂����B�F' || lv_errmsg;
          RAISE api_expt;
        END IF;
      ELSE
        ov_errmsg  := '�\�����ʃ��W�b�N��ʉ߂��܂����B:' || ov_errmsg;
        RAISE api_expt;
      END IF;
    END IF;
--
    -- ����I��
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;                                            --# �C�� #
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END lot_execute;
--
  /**********************************************************************************
   * Procedure Name   : insert_line_allocation
   * Description      : ���׊����ǉ��֐�
   ***********************************************************************************/
  PROCEDURE insert_line_allocation(
    ir_tran_row_in IN  gme_inventory_txns_gtmp%ROWTYPE,
    ov_errbuf      OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_line_allocation'; --�v���O������
    -- *** ���[�J���萔 ***
    cv_api_name   CONSTANT VARCHAR2(100) := '���׊����ǉ��֐�';
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
    ln_message_cnt       NUMBER;
    lv_return_status     VARCHAR2(1);
    lv_message_list      VARCHAR2(200);
    lt_batch_no          gme_batch_header.batch_no%TYPE;     -- �o�b�`NO
    lv_msg               VARCHAR2(2000);
    ln_dummy_cnt         NUMBER(10);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_material_detail   gme_material_details%ROWTYPE;
    lr_tran_row_in       gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out      gme_inventory_txns_gtmp%ROWTYPE;
    lr_def_tran_row      gme_inventory_txns_gtmp%ROWTYPE;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- IN�p�����[�^��ݒ肵�܂�
    lr_tran_row_in := ir_tran_row_in;
--
    -- ***********************************************
    -- ***  �o�b�`No���擾���܂��B***
    -- ***********************************************
    lt_batch_no := xxwip_common_pkg.get_batch_no(lr_tran_row_in.doc_id);
--
    -- ***********************************************
    -- ***  API�����s���܂��B                      ***
    -- ***********************************************
    GME_API_PUB.INSERT_LINE_ALLOCATION (
      p_api_version       => GME_API_PUB.API_VERSION
     ,p_validation_level  => GME_API_PUB.MAX_ERRORS
     ,p_init_msg_list     => FALSE
     ,p_commit            => FALSE
     ,p_tran_row          => lr_tran_row_in
     ,p_lot_no            => NULL
     ,p_sublot_no         => NULL
     ,p_create_lot        => FALSE
     ,p_ignore_shortage   => TRUE
     ,p_scale_phantom     => FALSE
     ,x_material_detail   => lr_material_detail
     ,x_tran_row          => lr_tran_row_out
     ,x_def_tran_row      => lr_def_tran_row
     ,x_message_count     => ln_message_cnt
     ,x_message_list      => lv_message_list
     ,x_return_status     => lv_return_status
    );
    IF (lv_return_status <> gv_api_s) THEN
      lv_errbuf := SUBSTRB(lv_message_list,1,5000);
      FOR i IN 1 .. FND_MSG_PUB.COUNT_MSG LOOP
        -- ���b�Z�[�W�擾
        FND_MSG_PUB.GET(
               p_msg_index      => i
              ,p_encoded        => FND_API.G_FALSE
              ,p_data           => lv_msg
              ,p_msg_index_out  => ln_dummy_cnt
        );
        -- ���O�o��
        lv_errmsg := lv_errmsg || lv_msg;
  --
      END LOOP count_msg_loop;
      RAISE api_expt;
    END IF;
--
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip                -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
                     ,gv_msg_xxwip10049       -- ���b�Z�[�W�FAPP-XXWIP-10049 API�G���[���b�Z�[�W
                     ,gv_tkn_api_name         -- �g�[�N���FAPI_NAME
                     ,cv_api_name             -- API��
                    ),1,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
      -- API���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, gv_batch_no || lt_batch_no);
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END insert_line_allocation;
--
  /**********************************************************************************
   * Procedure Name   : update_line_allocation
   * Description      : ���׊����X�V�֐�
   ***********************************************************************************/
  PROCEDURE update_line_allocation(
    ir_tran_row_in IN  gme_inventory_txns_gtmp%ROWTYPE,
    ov_errbuf      OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_line_allocation'; --�v���O������
    -- *** ���[�J���萔 ***
    cv_api_name   CONSTANT VARCHAR2(100) := '���׊����X�V�֐�';
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
    ln_message_cnt       NUMBER;
    lv_return_status     VARCHAR2(1);
    lv_message_list      VARCHAR2(200);
    lt_batch_no          gme_batch_header.batch_no%TYPE;     -- �o�b�`NO
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_material_detail   gme_material_details%ROWTYPE;
    lr_tran_row_in       gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out      gme_inventory_txns_gtmp%ROWTYPE;
    lr_def_tran_row      gme_inventory_txns_gtmp%ROWTYPE;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- IN�p�����[�^��ݒ肵�܂�
    lr_tran_row_in := ir_tran_row_in;
--
    -- ***********************************************
    -- ***  �o�b�`No���擾���܂��B***
    -- ***********************************************
    lt_batch_no := xxwip_common_pkg.get_batch_no(lr_tran_row_in.doc_id);
--
    -- ***********************************************
    -- ***  API�����s���܂��B                      ***
    -- ***********************************************
    GME_API_PUB.UPDATE_LINE_ALLOCATION (
      p_api_version       => GME_API_PUB.API_VERSION
     ,p_validation_level  => GME_API_PUB.MAX_ERRORS
     ,p_init_msg_list     => FALSE
     ,p_commit            => FALSE
     ,p_tran_row          => lr_tran_row_in
     ,p_lot_no            => NULL
     ,p_sublot_no         => NULL
     ,p_create_lot        => FALSE
     ,p_ignore_shortage   => TRUE
     ,p_scale_phantom     => FALSE
     ,x_material_detail   => lr_material_detail
     ,x_tran_row          => lr_tran_row_out
     ,x_def_tran_row      => lr_def_tran_row
     ,x_message_count     => ln_message_cnt
     ,x_message_list      => lv_message_list
     ,x_return_status     => lv_return_status
    );
    IF (lv_return_status <> gv_api_s) THEN
      lv_errbuf := lv_message_list;
      RAISE api_expt;
    END IF;
--
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip                -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
                     ,gv_msg_xxwip10049       -- ���b�Z�[�W�FAPP-XXWIP-10049 API�G���[���b�Z�[�W
                     ,gv_tkn_api_name         -- �g�[�N���FAPI_NAME
                     ,cv_api_name             -- API��
                    ),1,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
      -- API���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,gv_batch_no || lt_batch_no);
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END update_line_allocation;
--
  /**********************************************************************************
   * Procedure Name   : delete_line_allocation
   * Description      : ���׊����폜�֐�
   ***********************************************************************************/
  PROCEDURE delete_line_allocation(
    ir_tran_row_in IN  gme_inventory_txns_gtmp%ROWTYPE,
    ov_errbuf      OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_line_allocation'; --�v���O������
    -- *** ���[�J���萔 ***
    cv_api_name   CONSTANT VARCHAR2(100) := '���׊����폜�֐�';
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
    ln_message_cnt       NUMBER;
    lv_return_status     VARCHAR2(1);
    lv_message_list      VARCHAR2(200);
    lt_batch_no          gme_batch_header.batch_no%TYPE;     -- �o�b�`NO
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_material_detail   gme_material_details%ROWTYPE;
    lr_tran_row          gme_inventory_txns_gtmp%ROWTYPE;
    lr_def_tran_row      gme_inventory_txns_gtmp%ROWTYPE;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- IN�p�����[�^��ݒ肵�܂�
    lr_tran_row := ir_tran_row_in;
--
    -- ***********************************************
    -- ***  �o�b�`No���擾���܂��B***
    -- ***********************************************
    lt_batch_no := xxwip_common_pkg.get_batch_no(lr_tran_row.doc_id);
--
    -- ***********************************************
    -- ***  API�����s���܂��B                      ***
    -- ***********************************************
    GME_API_PUB.DELETE_LINE_ALLOCATION (
      p_api_version       => GME_API_PUB.API_VERSION
     ,p_validation_level  => GME_API_PUB.MAX_ERRORS
     ,p_init_msg_list     => FALSE
     ,p_commit            => FALSE
     ,p_trans_id          => lr_tran_row.trans_id
     ,p_scale_phantom     => FALSE
     ,x_material_detail   => lr_material_detail
     ,x_def_tran_row      => lr_def_tran_row
     ,x_message_count     => ln_message_cnt
     ,x_message_list      => lv_message_list
     ,x_return_status     => lv_return_status
     );
    IF (lv_return_status <> gv_api_s) THEN
      lv_errbuf := lv_message_list;
      RAISE api_expt;
    END IF;
--
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip                -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
                     ,gv_msg_xxwip10049       -- ���b�Z�[�W�FAPP-XXWIP-10049 API�G���[���b�Z�[�W
                     ,gv_tkn_api_name         -- �g�[�N���FAPI_NAME
                     ,cv_api_name             -- API��
                    ),1,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
      -- API���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,gv_batch_no || lt_batch_no);
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END delete_line_allocation;
--
  /**********************************************************************************
   * Procedure Name   : update_inv_price
   * Description      : �݌ɒP���X�V�֐�
   ***********************************************************************************/
  PROCEDURE update_inv_price(
    it_batch_id        IN  gme_batch_header.batch_id%TYPE,
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_inv_price'; --�v���O������
    -- *** ���[�J���萔 ***
    cv_api_name   CONSTANT VARCHAR2(100) := '�݌ɒP���X�V�֐�';
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
    ln_invest_price       NUMBER;   -- �����i�v
    ln_co_prod_price      NUMBER;   -- ���Y���v
    ln_prod_price         NUMBER;   -- �����i�v
    lb_return_status      BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_lot_mst             ic_lots_mst%ROWTYPE;
    lr_lot_mst_out         ic_lots_mst%ROWTYPE;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    lb_return_status :=GMIGUTL.SETUP(FND_GLOBAL.USER_NAME);
    -- ***********************************************
    -- ***  �����i�v�擾                           ***
    -- ***********************************************
    BEGIN
      SELECT SUM(NVL(ilm.attribute7, 0) * itp.trans_qty * -1) invest_price -- �����P���v
      INTO   ln_invest_price
      FROM   ic_tran_pnd itp -- OPM�ۗ��݌Ƀg�����U�N�V����
            ,ic_lots_mst ilm -- ���b�g�}�X�^
      WHERE  itp.lot_id      = ilm.lot_id
      AND    itp.reverse_id  IS NULL
      AND    itp.delete_mark = gn_delete_mark_off
      AND    itp.lot_id      > gn_default_lot_id
      AND    itp.line_type   = gn_material
      AND    itp.doc_id      = it_batch_id
      AND    itp.completed_ind = gv_flg_on
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_invest_price      := 0;
--
      WHEN TOO_MANY_ROWS THEN
        ln_invest_price      := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    -- ***********************************************
    -- ***  ���Y���v�擾                           ***
    -- ***********************************************
    BEGIN
      SELECT SUM(ccd.cmpnt_cost * itp.trans_qty) co_prod_price -- ���Y���P���v
      INTO   ln_co_prod_price
      FROM   gme_material_details gmd  -- ���Y�����ڍ�
            ,ic_tran_pnd          itp  -- OPM�ۗ��݌Ƀg�����U�N�V����
            ,cm_cmpt_dtl          ccd  -- �i�ڌ����}�X�^
            ,cm_cmpt_mst_b        ccmb -- �R���|�[�l���g�敪�}�X�^
            ,cm_cldr_dtl          ccdt -- �����J�����_
      WHERE  gmd.material_detail_id  = itp.line_id
      AND    itp.reverse_id          IS NULL
      AND    itp.delete_mark         = gn_delete_mark_off
      AND    itp.lot_id              > gn_default_lot_id
      AND    itp.line_type           = gn_co_prod
      AND    ccd.cost_cmpntcls_id    = ccmb.cost_cmpntcls_id
      AND    ccmb.cost_cmpntcls_code = gv_cmpnt_code_gen
      AND    ccd.calendar_code       = ccdt.calendar_code
      AND    ccdt.start_date        <= NVL(FND_DATE.STRING_TO_DATE(gmd.attribute11, 'YYYY/MM/DD') , TRUNC(SYSDATE))
      AND    ccdt.end_date          >= NVL(FND_DATE.STRING_TO_DATE(gmd.attribute11, 'YYYY/MM/DD') , TRUNC(SYSDATE))
      AND    ccd.whse_code           = fnd_profile.value(gv_prof_cost_price)
      AND    itp.item_id             = ccd.item_id
      AND    itp.doc_id              = it_batch_id
      AND    itp.completed_ind       = gv_flg_on
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_co_prod_price      := 0;
--
      WHEN TOO_MANY_ROWS THEN
        ln_co_prod_price      := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ***********************************************
    -- ***  �����i�v�擾                           ***
    -- ***********************************************
    BEGIN
      SELECT itp.item_id
            ,itp.lot_id lot_id -- ���b�gID
            ,itp.trans_qty prod_price -- �����i�P���v
      INTO   lr_lot_mst.item_id
            ,lr_lot_mst.lot_id
            ,ln_prod_price
      FROM   ic_tran_pnd     itp -- OPM�ۗ��݌Ƀg�����U�N�V����
            ,ic_lots_mst     ilm -- ���b�g�}�X�^
      WHERE  itp.lot_id        = ilm.lot_id
      AND    itp.reverse_id    IS NULL
      AND    itp.delete_mark   = gn_delete_mark_off
      AND    itp.lot_id        > gn_default_lot_id
      AND    itp.line_type     = gn_prod
      AND    itp.doc_id        = it_batch_id
      AND    itp.completed_ind = gv_flg_on
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lr_lot_mst.item_id := null;
        lr_lot_mst.lot_id  := null;
        ln_prod_price      := 0;
--
      WHEN TOO_MANY_ROWS THEN
        lr_lot_mst.item_id := null;
        lr_lot_mst.lot_id  := null;
        ln_prod_price      := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ***********************************************
    -- ***  �݌ɒP���v�Z                           ***
    -- ***********************************************
    IF (ln_prod_price = 0) THEN
      RAISE skip_expt;
    ELSE
      lr_lot_mst.attribute7 := NVL(TO_CHAR(ROUND((NVL(ln_invest_price, 0) + NVL(ln_co_prod_price, 0)) / NVL(ln_prod_price, 0), 2)), '0');
    END IF;
--
    update_lot_dff_api(
      iv_update_type      => gv_type_n
     ,ir_ic_lots_mst_in   => lr_lot_mst
     ,ir_ic_lots_mst_out  => lr_lot_mst_out
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    IF (lv_retcode <> gv_status_normal) THEN
      ov_errbuf  := lv_errbuf;
      ov_errmsg  := '�݌ɒP���X�V�Ɏ��s���܂����B:' || lv_errmsg;
      RAISE api_expt;
    END IF;
--
    -- ����I��
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** ����l ***
    WHEN skip_expt THEN
      ov_retcode := gv_status_normal;                                           --# �C�� #
    --*** API��O ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END update_inv_price;
--
  /**********************************************************************************
   * Procedure Name   : UPDATE_TRUST_PRICE
   * Description      : �ϑ����H��X�V�֐�
   ***********************************************************************************/
  PROCEDURE update_trust_price(
    it_batch_id        IN  gme_batch_header.batch_id%TYPE,
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_trust_price'; --�v���O������
    -- *** ���[�J���萔 ***
    cv_api_name   CONSTANT VARCHAR2(100) := '�ϑ����H��X�V�֐�';
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
    ln_invest_actual_qty     NUMBER;   -- �����i�v
    ln_volume_actual_qty     NUMBER;   -- �o��������
    ln_trust_price           NUMBER;   -- �ϑ����H�P��
    ln_trust_price_total     NUMBER;   -- �ϑ����H��
    lb_return_status         BOOLEAN;
    lt_trust_calculate_type  xxpo_price_headers.calculate_type%TYPE;       -- �v�Z�敪
    lt_material_detail_id    gme_material_details.material_detail_id%TYPE; -- ���Y�����ڍ�ID
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***  �����i�v�擾                           ***
    -- ***********************************************
    BEGIN
-- 2008/06/02 D.Nihei MOD START
--      SELECT SUM(gmd.actual_qty) invest_actual_qty 
--      INTO   ln_invest_actual_qty
--      FROM   gme_material_details      gmd
--            ,xxcmn_item_categories3_v  xicv -- �i�ڃJ�e�S�����VIEW3
--      WHERE  gmd.batch_id          = it_batch_id
--      AND    gmd.item_id           = xicv.item_id
--      AND    gmd.line_type         = gn_material
--      AND    xicv.item_class_code  IN(gv_item_type_mtl
--                                     ,gv_item_type_harf_prod
--                                     ,gv_item_type_prod)
--      AND    gmd.attribute24       IS NULL
      SELECT SUM(xmd.invested_qty) invest_actual_qty 
      INTO   ln_invest_actual_qty
      FROM   xxwip_material_detail     xmd  -- ���Y�����ڍ׃A�h�I��
            ,xxcmn_item_categories3_v  xicv -- �i�ڃJ�e�S�����VIEW3
      WHERE  xmd.batch_id          = it_batch_id
      AND    xmd.item_id           = xicv.item_id
      AND    xicv.item_class_code  IN(gv_item_type_mtl
                                     ,gv_item_type_harf_prod
                                     ,gv_item_type_prod)
-- 2008/06/02 D.Nihei MOD END
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_invest_actual_qty      := 0;
--
      WHEN TOO_MANY_ROWS THEN
        ln_invest_actual_qty      := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    -- ***********************************************************
    -- ***  �ϑ��v�Z�敪�E�ϑ����H�P���E�o�������ѐ����o      ***
    -- ***********************************************************
    BEGIN
      SELECT gmd.material_detail_id            material_detail_id
-- 2008/05/28 D.Nihei MOD START
--            ,xph.calculate_type                trust_calculate_type
            ,NVL(xph.calculate_type, '1')      trust_calculate_type
-- 2008/05/28 D.Nihei MOD END
            ,NVL(TO_NUMBER(gmd.attribute9), 0) trust_price
            ,NVL(gmd.actual_qty, 0)            volume_actual_qty
      INTO   lt_material_detail_id
            ,lt_trust_calculate_type
            ,ln_trust_price
            ,ln_volume_actual_qty
      FROM   gme_material_details      gmd
            ,xxpo_price_headers        xph     -- �d���E�W���P���w�b�_(�A�h�I��)
-- 2008/05/28 D.Nihei MOD START
--      WHERE  gmd.item_id           = xph.item_id
--      AND    xph.start_date_active<= NVL(FND_DATE.STRING_TO_DATE(gmd.attribute11, 'YYYY/MM/DD'), TRUNC(SYSDATE))
--      AND    xph.end_date_active  >= NVL(FND_DATE.STRING_TO_DATE(gmd.attribute11, 'YYYY/MM/DD'), TRUNC(SYSDATE))
--      AND    xph.futai_code        = '9' -- �t�уR�[�h9
      WHERE  gmd.item_id               = xph.item_id(+)
      AND    xph.start_date_active(+) <= NVL(FND_DATE.STRING_TO_DATE(gmd.attribute11, 'YYYY/MM/DD'), TRUNC(SYSDATE))
      AND    xph.end_date_active(+)   >= NVL(FND_DATE.STRING_TO_DATE(gmd.attribute11, 'YYYY/MM/DD'), TRUNC(SYSDATE))
      AND    xph.futai_code(+)         = '9' -- �t�уR�[�h9
-- 2008/05/28 D.Nihei MOD START
      AND    gmd.batch_id          = it_batch_id
      AND    gmd.line_type         = gn_prod
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_trust_calculate_type := null;
        ln_trust_price          := 0;
        ln_volume_actual_qty    := 0;
--
      WHEN TOO_MANY_ROWS THEN
        lt_trust_calculate_type := null;
        ln_trust_price          := 0;
        ln_volume_actual_qty    := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ***********************************************
    -- ***  �ϑ����H��Z�o                         ***
    -- ***********************************************
    -- �ϑ��v�Z�敪��null�̏ꍇ
    IF (lt_trust_calculate_type IS NULL) THEN
      ov_errmsg  := lv_errmsg || '�ϑ����H��X�V�֐��Ɏ��s���܂����B';
      RAISE api_expt;
--
    -- �ϑ��v�Z�敪��'�o����'�̏ꍇ
    ELSIF (lt_trust_calculate_type = gv_trust_calc_type_volume) THEN
      ln_trust_price_total := ln_trust_price * ln_volume_actual_qty;
--
    -- �ϑ��v�Z�敪��'����'�̏ꍇ
    ELSIF (lt_trust_calculate_type = gv_trust_calc_type_invest) THEN
      ln_trust_price_total := ln_trust_price * ln_invest_actual_qty;
--
    END IF;
--
    -- ***********************************************
    -- ***  �ϑ����H��E�ϑ��v�Z�敪�X�V           ***
    -- ***********************************************
    UPDATE gme_material_details gmd
    SET    gmd.attribute14        = lt_trust_calculate_type
          ,gmd.attribute15        = TO_CHAR(ln_trust_price_total ,'FM999999990.000')
          ,gmd.last_updated_by    = FND_GLOBAL.USER_ID
          ,gmd.last_update_date   = SYSDATE
          ,gmd.last_update_login  = FND_GLOBAL.LOGIN_ID
    WHERE  gmd.material_detail_id = lt_material_detail_id
    ;
--
    -- ����I��
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** ����l ***
    WHEN skip_expt THEN
      ov_retcode := gv_status_normal;                                           --# �C�� #
    --*** API��O ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END update_trust_price;
--
  /**********************************************************************************
   * Procedure Name   : qt_parameter_check
   * Description      : ���̓p�����[�^�`�F�b�N(make_qt_inspection �i�������˗����쐬 A-1)(����J)
  /*********************************************************************************/
  PROCEDURE qt_parameter_check(
    it_division          IN  xxwip_qt_inspection.division%TYPE,         -- IN  1.�敪
    iv_disposal_div      IN  VARCHAR2,                                  -- IN  2.�����敪
    it_lot_id            IN  xxwip_qt_inspection.lot_id%TYPE,           -- IN  3.���b�gID
    it_item_id           IN  xxwip_qt_inspection.item_id%TYPE,          -- IN  4.�i��ID
    iv_qt_object         IN  VARCHAR2,                                  -- IN  5.�Ώې�
    it_batch_id          IN  xxwip_qt_inspection.batch_po_id%TYPE,      -- IN  6.���Y�o�b�`ID
    it_batch_po_id       IN  xxwip_qt_inspection.batch_po_id%TYPE,      -- IN  7.���הԍ�
    it_qty               IN  xxwip_qt_inspection.qty%TYPE,              -- IN  8.����
    it_prod_dely_date    IN  xxwip_qt_inspection.prod_dely_date%TYPE,   -- IN  9.�[����
    it_vendor_line       IN  xxwip_qt_inspection.vendor_line%TYPE,      -- IN 10.�d����R�[�h
    it_qt_inspect_req_no IN  xxwip_qt_inspection.qt_inspect_req_no%TYPE,-- IN 11.�����˗�No
    ov_errbuf            OUT NOCOPY VARCHAR2,                                  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY VARCHAR2,                                  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2                                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'qt_parameter_check'; -- �v���O������
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
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
    -- ���^�[���R�[�h�Z�b�g
    ov_retcode := gv_status_normal;
--
    -- 1.�敪
    IF (it_division IS NULL) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 2.�����敪
    IF (iv_disposal_div IS NULL) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 3.���b�gID
    IF (it_lot_id IS NULL) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 4.�i��ID
    IF (it_item_id IS NULL) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �����敪��3:�폜�ȊO�̏ꍇ
    IF (iv_disposal_div <> gv_disposal_div_del) THEN
      -- �敪��1:���Y�̏ꍇ�̂�
      IF (it_division = gt_division_gme) THEN
        -- 6.���Y�o�b�`ID
        IF it_batch_id IS NULL THEN
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
      -- �敪��2:�����̏ꍇ�̂�
      IF (it_division = gt_division_po) THEN
        -- 8.����
        IF (it_qty IS NULL) THEN
          RAISE global_api_expt;
        END IF;
--
        -- 9.�[����
        IF (it_prod_dely_date IS NULL) THEN
          RAISE global_api_expt;
        END IF;
--
        -- 10.�d����R�[�h
        IF (it_vendor_line IS NULL) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
--
    END IF;
--
    -- �敪��5:�r�������̏ꍇ�̂�
    IF (it_division = gt_division_tea) THEN
      -- 5.�Ώې�
      IF (iv_qt_object IS NULL) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- �����敪��1:�ǉ��̏ꍇ
    IF (iv_disposal_div = gv_disposal_div_ins) THEN
      -- 11.�����˗�No
      IF (it_qt_inspect_req_no IS NOT NULL) THEN
        RAISE global_api_expt;
      END IF;
--
    -- �����敪��2:�X�V�A3:�폜�̏ꍇ
    ELSE
      -- 11.�����˗�No
      IF (it_qt_inspect_req_no IS NULL) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
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
--###################################  �Œ蕔 END   #########################################
--
  END qt_parameter_check;
--
  /**********************************************************************************
   * Procedure Name   : qt_check_and_lock
   * Description      : �f�[�^�`�F�b�N/���b�N(make_qt_inspection �i�������˗����쐬 A-3)(����J)
  /*********************************************************************************/
  PROCEDURE qt_check_and_lock(
    iv_disposal_div         IN  VARCHAR2,                                  -- IN  1.�����敪
    it_lot_id               IN  xxwip_qt_inspection.lot_id%TYPE,           -- IN  2.���b�gID
    it_item_id              IN  xxwip_qt_inspection.item_id%TYPE,          -- IN  3.�i��ID
    it_qt_inspect_req_no    IN  xxwip_qt_inspection.qt_inspect_req_no%TYPE,-- IN  4.�����˗�No
    it_division             IN  xxwip_qt_inspection.division%TYPE,         -- IN  5.�敪
    or_xxwip_qt_inspection  OUT NOCOPY xxwip_qt_inspection%ROWTYPE,               -- OUT 1.xxwip_qt_inspection���R�[�h�^
    ov_errbuf               OUT NOCOPY VARCHAR2,                                  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,                                  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2                                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'qt_check_and_lock'; -- �v���O������
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
    ln_temp        NUMBER;   -- �J�E���g�i�[�p
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_xxwip_qt_inspection  xxwip_qt_inspection%ROWTYPE;  -- xxwip_qt_inspection���R�[�h�^
--
  BEGIN
    -- ���^�[���R�[�h�Z�b�g
    ov_retcode := gv_status_normal;
--
    -- �����敪��1:�ǉ��̏ꍇ
    IF (iv_disposal_div = gv_disposal_div_ins) THEN
      --==============================
      -- �i�������f�[�^�`�F�b�N
      --==============================
      -- ����L�[���i�������˗����A�h�I���ɑ��݂��Ȃ����`�F�b�N
      SELECT COUNT(xqi.qt_inspect_req_no) cnt
      INTO   ln_temp
      FROM   xxwip_qt_inspection  xqi  -- �i�������˗����A�h�I��
      WHERE  xqi.lot_id  = it_lot_id   -- ���b�gID
      AND    xqi.item_id = it_item_id  -- �i��ID
      AND    ROWNUM      = 1
      ;
--
      IF (ln_temp <> 0) THEN
        -- �G���[
        RAISE global_api_expt;
      END IF;
--
    -- �����敪��2:�X�V�A3:�폜�̏ꍇ
    ELSE
      --==============================
      -- �i�������f�[�^�`�F�b�N/���b�N
      --==============================
      SELECT xqi.test_date1      test_date1     -- �������P
            ,xqi.test_date2      test_date2     -- �������Q
            ,xqi.test_date3      test_date3     -- �������R
            ,xqi.use_by_date     use_by_date    -- �ܖ�����
            ,xqi.prod_dely_date  prod_dely_date -- ���Y/�[����
      INTO   lr_xxwip_qt_inspection.test_date1     -- test_date1
            ,lr_xxwip_qt_inspection.test_date2     -- test_date1
            ,lr_xxwip_qt_inspection.test_date3     -- test_date1
            ,lr_xxwip_qt_inspection.use_by_date    -- use_by_date
            ,lr_xxwip_qt_inspection.prod_dely_date -- prod_dely_date
      FROM   xxwip_qt_inspection  xqi                      -- �i�������˗����A�h�I��
      WHERE  xqi.qt_inspect_req_no  = it_qt_inspect_req_no -- �����˗�No
      FOR UPDATE NOWAIT
      ;
--
      -- �����敪��2:�X�V���敪��1:���Y�ȊO�̏ꍇ
      IF (iv_disposal_div = gv_disposal_div_upd)
      AND(it_division <> gt_division_gme)  THEN
        -- �������̂��Âꂩ�ɓ��͂����邩�`�F�b�N
        IF (lr_xxwip_qt_inspection.test_date1 IS NOT NULL)
        OR (lr_xxwip_qt_inspection.test_date2 IS NOT NULL)
        OR (lr_xxwip_qt_inspection.test_date3 IS NOT NULL) THEN
--
          -- �x��
          ov_retcode :=gv_status_warn;
        END IF;
--
      -- �����敪��3:�폜�̏ꍇ
      ELSIF (iv_disposal_div = gv_disposal_div_del) THEN
        -- �������̂��Âꂩ�ɓ��͂����邩�`�F�b�N
        IF (lr_xxwip_qt_inspection.test_date1 IS NOT NULL)
        OR (lr_xxwip_qt_inspection.test_date2 IS NOT NULL)
        OR (lr_xxwip_qt_inspection.test_date3 IS NOT NULL) THEN
--
          -- �G���[
          RAISE global_api_expt;
--
        END IF;
      END IF;
--
    -- ====================================
    -- OUT�p�����[�^�Z�b�g
    -- ====================================
    or_xxwip_qt_inspection := lr_xxwip_qt_inspection;  -- xxwip_qt_inspection���R�[�h�^
    END IF;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
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
--###################################  �Œ蕔 END   #########################################
--
  END qt_check_and_lock;
--
  /**********************************************************************************
   * Procedure Name   : qt_get_gme_data
   * Description      : ���Y���擾(make_qt_inspection �i�������˗����쐬 A-4)(����J)
  /*********************************************************************************/
  PROCEDURE qt_get_gme_data(
    it_batch_id             IN  xxwip_qt_inspection.batch_po_id%TYPE,   -- IN  1.���Y�o�b�`ID
    it_lot_id               IN  xxwip_qt_inspection.lot_id%TYPE,        -- IN  2.���b�gID
    it_item_id              IN  xxwip_qt_inspection.item_id%TYPE,       -- IN  3.�i��ID
    iv_disposal_div         IN  VARCHAR2,                               -- IN  4.�����敪
    ir_xxwip_qt_inspection  IN  xxwip_qt_inspection%ROWTYPE,            -- IN  5.xxwip_qt_inspection���R�[�h�^
    or_xxwip_qt_inspection  OUT NOCOPY xxwip_qt_inspection%ROWTYPE,            -- OUT 1.xxwip_qt_inspection���R�[�h�^
    ov_errbuf               OUT NOCOPY VARCHAR2,                               -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,                               -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2                                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'qt_get_gme_data'; -- �v���O������
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
    lr_xxwip_qt_inspection  xxwip_qt_inspection%ROWTYPE;  -- xxwip_qt_inspection���R�[�h�^
--
  BEGIN
    -- ���^�[���R�[�h�Z�b�g
    ov_retcode := gv_status_normal;
--
    --================================
    -- �f�[�^�擾
    --================================
    SELECT grb.routing_no           vendor_line          -- �d����R�[�h/���C��No
          ,gmd.actual_qty           qty                  -- ����
          ,FND_DATE.STRING_TO_DATE(gmd.attribute17,'YYYY/MM/DD')
                                    product_date         -- ������
          ,TO_NUMBER(ximv.inspect_lot)
                                    inspect_period       -- ����L/T
          ,FND_DATE.STRING_TO_DATE(ilm.attribute3,'YYYY/MM/DD')
                                    use_by_date          -- �ܖ�����
          ,ilm.attribute2           unique_sign          -- �ŗL�L��
    INTO   lr_xxwip_qt_inspection.vendor_line            -- �d����R�[�h/���C��No
          ,lr_xxwip_qt_inspection.qty                    -- ����
          ,lr_xxwip_qt_inspection.product_date           -- ������
          ,lr_xxwip_qt_inspection.inspect_period         -- ����L/T
          ,lr_xxwip_qt_inspection.use_by_date            -- �ܖ�����
          ,lr_xxwip_qt_inspection.unique_sign            -- �ŗL�L��
    FROM   gme_batch_header         gbh                  -- ���Y�o�b�`�w�b�_
          ,gme_material_details     gmd                  -- ���Y�����ڍ�
          ,ic_tran_pnd              itp                  -- OPM�ۗ��݌Ƀg�����U�N�V����
          ,gmd_routings_b           grb                  -- �H���}�X�^
          ,ic_lots_mst              ilm                  -- OPM���b�g�}�X�^
          ,xxcmn_item_mst_v         ximv                 -- OPM�i�ڏ��VIEW
    WHERE  gbh.batch_id           = it_batch_id          -- �o�b�`ID
    AND    gmd.item_id            = it_item_id           -- �i��ID
    AND    itp.lot_id             = it_lot_id            -- ���b�gID
    AND    gmd.line_type          IN (gt_line_type_goods
                                     ,gt_line_type_sub)  -- ���C���^�C�v   IN (1:�����i 2:���Y��)
    AND    gbh.attribute4         = gt_duty_status_com   -- �Ɩ��X�e�[�^�X = 7:����
    AND    itp.completed_ind      = gt_completed_ind_com -- �����t���O     = 1:����
    AND    itp.reverse_id         IS NULL                -- ���o�[�XID     = NULL
    AND    gbh.batch_id           = gmd.batch_id         -- �o�b�`ID�i���������j���Y�o�b�`�w�b�_ AND ���Y�����ڍ�
    AND    gmd.material_detail_id = itp.line_id          -- ���C��ID�i���������j���Y�����ڍ� AND OPM�ۗ��݌Ƀg�����U�N�V����
    AND    gbh.routing_id         = grb.routing_id       -- �H��ID�i���������j  ���Y�o�b�`�w�b�_ AND �H���}�X�^
    AND    itp.item_id            = ilm.item_id          -- �i��ID�i���������j  OPM�ۗ��݌Ƀg�����U�N�V���� AND OPM���b�g�}�X�^
    AND    itp.lot_id             = ilm.lot_id           -- ���b�gID�i���������jOPM�ۗ��݌Ƀg�����U�N�V���� AND OPM���b�g�}�X�^
    AND    itp.item_id            = ximv.item_id         -- �i��ID�i���������j  OPM�ۗ��݌Ƀg�����U�N�V���� AND OPM�i�ڏ��VIEW
    ;
--
    -- ====================================
    -- �i�������˗���񃌃R�[�h�ɒl���Z�b�g
    -- ====================================
    lr_xxwip_qt_inspection.inspect_class  := gt_inspect_class_gme;                 -- ������ʁF1�i���Y�j
    lr_xxwip_qt_inspection.item_id        := it_item_id;                           -- �i��ID
    lr_xxwip_qt_inspection.lot_id         := it_lot_id;                            -- ���b�gID
    lr_xxwip_qt_inspection.prod_dely_date := lr_xxwip_qt_inspection.product_date;  -- ���Y/�[����
    lr_xxwip_qt_inspection.batch_po_id    := it_batch_id;                          -- �ԍ�
--
    -- �����敪��2:�X�V�̏ꍇ
    -- �o�^�ς̕i�������˗����̌������̂��Âꂩ�ɓ��͂�����ꍇ
    IF (iv_disposal_div = gv_disposal_div_upd)
    AND((ir_xxwip_qt_inspection.test_date1 IS NOT NULL)
      OR(ir_xxwip_qt_inspection.test_date2 IS NOT NULL)
      OR(ir_xxwip_qt_inspection.test_date3 IS NOT NULL))THEN
      -- ���Y/�[����,�ܖ�������v�`�F�b�N
      IF (ir_xxwip_qt_inspection.prod_dely_date <> lr_xxwip_qt_inspection.prod_dely_date)
      OR (ir_xxwip_qt_inspection.use_by_date    <> lr_xxwip_qt_inspection.use_by_date) THEN
--
        ov_retcode := gv_status_warn;
      END IF;
    END IF;
--
    -- ====================================
    -- OUT�p�����[�^�Z�b�g
    -- ====================================
    or_xxwip_qt_inspection := lr_xxwip_qt_inspection;  -- xxwip_qt_inspection���R�[�h�^
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
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
--###################################  �Œ蕔 END   #########################################
--
  END qt_get_gme_data;
--
  /**********************************************************************************
   * Procedure Name   : qt_get_po_data
   * Description      : �������擾(make_qt_inspection �i�������˗����쐬 A-5)(����J)
  /*********************************************************************************/
  PROCEDURE qt_get_po_data(
    it_lot_id               IN  xxwip_qt_inspection.lot_id%TYPE,        -- IN  1.���b�gID
    it_item_id              IN  xxwip_qt_inspection.item_id%TYPE,       -- IN  2.�i��ID
    it_batch_po_id          IN  xxwip_qt_inspection.batch_po_id%TYPE,   -- IN  3.���הԍ�
    it_qty                  IN  xxwip_qt_inspection.qty%TYPE,           -- IN  4.����
    it_prod_dely_date       IN  xxwip_qt_inspection.prod_dely_date%TYPE,-- IN  5.�[����
    it_vendor_line          IN  xxwip_qt_inspection.vendor_line%TYPE,   -- IN  6.�d����R�[�h
    or_xxwip_qt_inspection  OUT NOCOPY xxwip_qt_inspection%ROWTYPE,            -- OUT 1.xxwip_qt_inspection���R�[�h�^
    ov_errbuf               OUT NOCOPY VARCHAR2,                               -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,                               -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2                                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'qt_get_po_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
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
    lr_xxwip_qt_inspection  xxwip_qt_inspection%ROWTYPE;  -- xxwip_qt_inspection���R�[�h�^
--
  BEGIN
    -- ���^�[���R�[�h�Z�b�g
    ov_retcode := gv_status_normal;
--
    --================================
    -- �f�[�^�擾
    --================================
    SELECT FND_DATE.STRING_TO_DATE(ilm.attribute1,'YYYY/MM/DD')
                                    product_date         -- ������
          ,TO_NUMBER(ximv.inspect_lot)
                                    inspect_period       -- ����L/T
          ,FND_DATE.STRING_TO_DATE(ilm.attribute3,'YYYY/MM/DD')
                                    use_by_date          -- �ܖ�����
          ,ilm.attribute2           unique_sign          -- �ŗL�L��
    INTO   lr_xxwip_qt_inspection.product_date           -- ������
          ,lr_xxwip_qt_inspection.inspect_period         -- ����L/T
          ,lr_xxwip_qt_inspection.use_by_date            -- �ܖ�����
          ,lr_xxwip_qt_inspection.unique_sign            -- �ŗL�L��
    FROM   ic_lots_mst              ilm                  -- OPM���b�g�}�X�^
          ,xxcmn_item_mst_v         ximv                 -- OPM�i�ڏ��VIEW
    WHERE  ximv.item_id           = it_item_id           -- �i��ID
    AND    ilm.lot_id             = it_lot_id            -- ���b�gID
    AND    ilm.item_id            = ximv.item_id         -- �i��ID�i���������jOPM���b�g�}�X�^ AND OPM�i�ڃ}�X�^VIEW
    ;
--
    -- ====================================
    -- �i�������˗���񃌃R�[�h�ɒl���Z�b�g
    -- ====================================
    lr_xxwip_qt_inspection.inspect_class  := gt_inspect_class_po;   -- ������ʁF2�i�����d���j
    lr_xxwip_qt_inspection.item_id        := it_item_id;            -- �i��ID
    lr_xxwip_qt_inspection.lot_id         := it_lot_id;             -- ���b�gID
    lr_xxwip_qt_inspection.prod_dely_date := it_prod_dely_date;     -- ���Y/�[����
    lr_xxwip_qt_inspection.vendor_line    := it_vendor_line;        -- �d����R�[�h/���C��No
    lr_xxwip_qt_inspection.qty            := it_qty;                -- ����
    lr_xxwip_qt_inspection.batch_po_id    := it_batch_po_id;        -- �ԍ�
--
    -- ====================================
    -- OUT�p�����[�^�Z�b�g
    -- ====================================
    or_xxwip_qt_inspection := lr_xxwip_qt_inspection;  -- xxwip_qt_inspection���R�[�h�^
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
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
--###################################  �Œ蕔 END   #########################################
--
  END qt_get_po_data;
--
  /**********************************************************************************
   * Procedure Name   : qt_get_lot_data
   * Description      : ���b�g���擾(make_qt_inspection �i�������˗����쐬 A-6)(����J)
  /*********************************************************************************/
  PROCEDURE qt_get_lot_data(
    it_lot_id                IN  xxwip_qt_inspection.lot_id%TYPE,  -- IN  1.���b�gID
    it_item_id               IN  xxwip_qt_inspection.item_id%TYPE, -- IN  2.�i��ID
    it_qty                   IN  xxwip_qt_inspection.qty%TYPE,            -- IN  3.����
    or_xxwip_qt_inspection   OUT NOCOPY xxwip_qt_inspection%ROWTYPE,      -- OUT 1.xxwip_qt_inspection���R�[�h�^
    ov_errbuf                OUT NOCOPY VARCHAR2,                         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,                         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'qt_get_lot_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
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
    lr_xxwip_qt_inspection  xxwip_qt_inspection%ROWTYPE;  -- xxwip_qt_inspection���R�[�h�^
--
  BEGIN
    -- ���^�[���R�[�h�Z�b�g
    ov_retcode := gv_status_normal;
--
    --================================
    -- �f�[�^�擾
    --================================
    SELECT ilm.attribute8           vendor_line          -- �d����R�[�h/���C��No
          ,FND_DATE.STRING_TO_DATE(ilm.attribute1,'YYYY/MM/DD')
                                    product_date         -- ������
          ,TO_NUMBER(ximv.inspect_lot)
                                    inspect_period       -- ����L/T
          ,FND_DATE.STRING_TO_DATE(ilm.attribute3,'YYYY/MM/DD')
                                    use_by_date          -- �ܖ�����
          ,ilm.attribute2           unique_sign          -- �ŗL�L��
    INTO   lr_xxwip_qt_inspection.vendor_line            -- �d����R�[�h/���C��No
          ,lr_xxwip_qt_inspection.product_date           -- ������
          ,lr_xxwip_qt_inspection.inspect_period         -- ����L/T
          ,lr_xxwip_qt_inspection.use_by_date            -- �ܖ�����
          ,lr_xxwip_qt_inspection.unique_sign            -- �ŗL�L��
    FROM   ic_lots_mst              ilm                  -- OPM���b�g�}�X�^
          ,xxcmn_item_mst_v         ximv                 -- OPM�i�ڏ��VIEW
    WHERE  ximv.item_id           = it_item_id           -- �i��ID
    AND    ilm.lot_id             = it_lot_id            -- ���b�gID
    AND    ilm.item_id            = ximv.item_id         -- �i��ID�i���������jOPM���b�g�}�X�^ AND OPM�i�ڃ}�X�^VIEW
    ;
--
    -- ====================================
    -- �i�������˗���񃌃R�[�h�ɒl���Z�b�g
    -- ====================================
    lr_xxwip_qt_inspection.inspect_class  := gt_inspect_class_po;                     -- ������ʁF2�i�����d���j
    lr_xxwip_qt_inspection.item_id        := it_item_id;                              -- �i��ID
    lr_xxwip_qt_inspection.lot_id         := it_lot_id;                               -- ���b�gID
    lr_xxwip_qt_inspection.prod_dely_date := lr_xxwip_qt_inspection.product_date;     -- ���Y/�[����
    lr_xxwip_qt_inspection.qty            := it_qty;                                  -- ����
    lr_xxwip_qt_inspection.batch_po_id    := NULL;                                    -- �ԍ�
--
    -- ====================================
    -- OUT�p�����[�^�Z�b�g
    -- ====================================
    or_xxwip_qt_inspection := lr_xxwip_qt_inspection;  -- xxwip_qt_inspection���R�[�h�^
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
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
--###################################  �Œ蕔 END   #########################################
--
  END qt_get_lot_data;
--
  /**********************************************************************************
   * Procedure Name   : qt_get_vendor_supply_data
   * Description      : �O���o�������擾(make_qt_inspection �i�������˗����쐬 A-7)(����J)
  /*********************************************************************************/
  PROCEDURE qt_get_vendor_supply_data(
    it_lot_id               IN  xxwip_qt_inspection.lot_id%TYPE,   -- IN  1.���b�gID
    it_item_id              IN  xxwip_qt_inspection.item_id%TYPE,  -- IN  2.�i��ID
    or_xxwip_qt_inspection  OUT NOCOPY xxwip_qt_inspection%ROWTYPE,       -- OUT 1.xxwip_qt_inspection���R�[�h�^
    ov_errbuf               OUT NOCOPY VARCHAR2,                          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,                          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'qt_get_vendor_supply_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
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
    lr_xxwip_qt_inspection  xxwip_qt_inspection%ROWTYPE;  -- xxwip_qt_inspection���R�[�h�^
--
  BEGIN
    -- ���^�[���R�[�h�Z�b�g
    ov_retcode := gv_status_normal;
--
    --================================
    -- �f�[�^�擾
    --================================
    SELECT xvst.vendor_code        vendor_line          -- �d����R�[�h/���C��No
          ,DECODE (
             xvst.txns_type
            ,gt_txns_type_aite , xvst.quantity            -- �����^�C�v�F1�i�����݌Ɂj�̏ꍇ ����
            ,gt_txns_type_sok  , xvst.corrected_quantity  -- �����^�C�v�F2�i�����d���j�̏ꍇ ��������
           )                        qty                 -- ����
          ,FND_DATE.STRING_TO_DATE(ilm.attribute1,'YYYY/MM/DD')
                                    prod_dely_date      -- ���Y/�[����
          ,xvst.producted_date      producted_date      -- ������
          ,TO_NUMBER(ximv.inspect_lot)
                                    inspect_period      -- ����L/T
          ,FND_DATE.STRING_TO_DATE(ilm.attribute3,'YYYY/MM/DD')
                                    use_by_date         -- �ܖ�����
          ,ilm.attribute2           unique_sign         -- �ŗL�L��
    INTO   lr_xxwip_qt_inspection.vendor_line           -- �d����R�[�h/���C��No
          ,lr_xxwip_qt_inspection.qty                   -- ����
          ,lr_xxwip_qt_inspection.prod_dely_date        -- ���Y/�[����
          ,lr_xxwip_qt_inspection.product_date          -- ������
          ,lr_xxwip_qt_inspection.inspect_period        -- ����L/T
          ,lr_xxwip_qt_inspection.use_by_date           -- �ܖ�����
          ,lr_xxwip_qt_inspection.unique_sign           -- �ŗL�L��
    FROM   xxpo_vendor_supply_txns     xvst             -- �O���o�������уA�h�I��
          ,ic_lots_mst                 ilm              -- OPM���b�g�}�X�^
          ,xxcmn_item_mst_v            ximv             -- OPM�i�ڏ��VIEW
    WHERE  xvst.item_id           = it_item_id          -- �i��ID
    AND    xvst.lot_id            = it_lot_id           -- ���b�gID
    AND    xvst.item_id           = ximv.item_id        -- �i��ID�i���������j�O���o�������уA�h�I�� AND OPM�i�ڃ}�X�^VIEW
    AND    xvst.lot_id            = ilm.lot_id          -- �i��ID�i���������j�O���o�������уA�h�I�� AND OPM���b�g�}�X�^
    AND    xvst.item_id           = ilm.item_id         -- �i��ID�i���������j�O���o�������уA�h�I�� AND OPM���b�g�}�X�^
    ;
--
    -- ====================================
    -- �i�������˗���񃌃R�[�h�ɒl���Z�b�g
    -- ====================================
    lr_xxwip_qt_inspection.inspect_class  := gt_inspect_class_po;                     -- ������ʁF2�i�����d���j
    lr_xxwip_qt_inspection.item_id        := it_item_id;                              -- �i��ID
    lr_xxwip_qt_inspection.lot_id         := it_lot_id;                               -- ���b�gID
    lr_xxwip_qt_inspection.batch_po_id    := NULL;                                    -- �ԍ�
--
    -- ====================================
    -- OUT�p�����[�^�Z�b�g
    -- ====================================
    or_xxwip_qt_inspection := lr_xxwip_qt_inspection;  -- xxwip_qt_inspection���R�[�h�^
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
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
--###################################  �Œ蕔 END   #########################################
--
  END qt_get_vendor_supply_data;
--
  /**********************************************************************************
   * Procedure Name   : qt_get_namaha_prod_data
   * Description      : �r���������擾(make_qt_inspection �i�������˗����쐬 A-2)(����J)
  /*********************************************************************************/
  PROCEDURE qt_get_namaha_prod_data(
    it_lot_id               IN  xxwip_qt_inspection.lot_id%TYPE,  -- IN  1.���b�gID
    it_item_id              IN  xxwip_qt_inspection.item_id%TYPE, -- IN  2.�i��ID
    iv_qt_object            IN  VARCHAR2,                         -- IN  3.�Ώې�
    or_xxwip_qt_inspection  OUT NOCOPY xxwip_qt_inspection%ROWTYPE,      -- OUT 1.xxwip_qt_inspection���R�[�h�^
    ov_errbuf               OUT NOCOPY VARCHAR2,                         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,                         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'qt_get_namaha_prod_data'; -- �v���O������
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
    lr_xxwip_qt_inspection       xxwip_qt_inspection%ROWTYPE;  -- xxwip_qt_inspection���R�[�h�^
    lr_xxwip_qt_inspection_temp  xxwip_qt_inspection%ROWTYPE;  -- xxwip_qt_inspection���R�[�h�^
--
  BEGIN
    -- ���^�[���R�[�h�Z�b�g
    ov_retcode := gv_status_normal;
--
    --================================
    -- �r���f�[�^�擾
    --================================
    SELECT DECODE (
             iv_qt_object
            ,gv_qt_object_tea , xnpt.aracha_item_id      -- �Ώې�F1�i�r���j�̏ꍇ �r���i��ID
            ,gv_qt_object_bp1 , xnpt.byproduct1_item_id  -- �Ώې�F2�i���Y���P�j�̏ꍇ ���Y���P�i��ID
            ,gv_qt_object_bp2 , xnpt.byproduct2_item_id  -- �Ώې�F3�i���Y���Q�j�̏ꍇ ���Y���Q�i��ID
            ,gv_qt_object_bp3 , xnpt.byproduct3_item_id  -- �Ώې�F4�i���Y���R�j�̏ꍇ ���Y���R�i��ID
           )                                   item_id    -- �i��ID
          ,DECODE (
             iv_qt_object
            ,gv_qt_object_tea , xnpt.aracha_lot_id      -- �Ώې�F1�i�r���j�̏ꍇ �r�����b�gID
            ,gv_qt_object_bp1 , xnpt.byproduct1_lot_id  -- �Ώې�F2�i���Y���P�j�̏ꍇ ���Y���P���b�gID
            ,gv_qt_object_bp2 , xnpt.byproduct2_lot_id  -- �Ώې�F3�i���Y���Q�j�̏ꍇ ���Y���Q���b�gID
            ,gv_qt_object_bp3 , xnpt.byproduct3_lot_id  -- �Ώې�F4�i���Y���R�j�̏ꍇ ���Y���R���b�gID
           )                                   lot_id     -- ���b�gID
          ,DECODE (
             iv_qt_object
            ,gv_qt_object_tea , xnpt.aracha_quantity      -- �Ώې�F1�i�r���j�̏ꍇ �r������
            ,gv_qt_object_bp1 , xnpt.byproduct1_quantity  -- �Ώې�F2�i���Y���P�j�̏ꍇ ���Y���P����
            ,gv_qt_object_bp2 , xnpt.byproduct2_quantity  -- �Ώې�F3�i���Y���Q�j�̏ꍇ ���Y���Q����
            ,gv_qt_object_bp3 , xnpt.byproduct3_quantity  -- �Ώې�F4�i���Y���R�j�̏ꍇ ���Y���R����
           )                                   qty        -- ����
    INTO   lr_xxwip_qt_inspection.item_id        -- �i��ID
          ,lr_xxwip_qt_inspection.lot_id         -- ���b�gID
          ,lr_xxwip_qt_inspection.qty            -- ����
    FROM   xxpo_namaha_prod_txns      xnpt       -- ���t���уA�h�I��
    WHERE  xnpt.aracha_item_id = it_item_id      -- �i��ID
    AND    xnpt.aracha_lot_id  = it_lot_id       -- ���b�gID
    ;
--
    --================================
    -- ���b�g�f�[�^�擾
    --================================
    SELECT ilm.attribute8           vendor_line          -- �d����R�[�h/���C��No
          ,FND_DATE.STRING_TO_DATE(ilm.attribute1,'YYYY/MM/DD')
                                    product_date         -- ������
          ,TO_NUMBER(ximv.inspect_lot)
                                    inspect_period       -- ����L/T
          ,FND_DATE.STRING_TO_DATE(ilm.attribute3,'YYYY/MM/DD')
                                    use_by_date          -- �ܖ�����
          ,ilm.attribute2           unique_sign          -- �ŗL�L��
    INTO   lr_xxwip_qt_inspection.vendor_line            -- �d����R�[�h/���C��No
          ,lr_xxwip_qt_inspection.product_date           -- ������
          ,lr_xxwip_qt_inspection.inspect_period         -- ����L/T
          ,lr_xxwip_qt_inspection.use_by_date            -- �ܖ�����
          ,lr_xxwip_qt_inspection.unique_sign            -- �ŗL�L��
    FROM   ic_lots_mst              ilm                  -- OPM���b�g�}�X�^
          ,xxcmn_item_mst_v         ximv                 -- OPM�i�ڏ��VIEW
    WHERE  ximv.item_id           = it_item_id           -- �i��ID
    AND    ilm.lot_id             = it_lot_id            -- ���b�gID
    AND    ilm.item_id            = ximv.item_id         -- �i��ID�i���������jOPM���b�g�}�X�^ AND OPM�i�ڃ}�X�^VIEW
    ;
--
    -- ====================================
    -- �i�������˗���񃌃R�[�h�ɒl���Z�b�g
    -- ====================================
    lr_xxwip_qt_inspection.inspect_class  := gt_inspect_class_po;                     -- ������ʁF2�i�����d���j
    lr_xxwip_qt_inspection.prod_dely_date := lr_xxwip_qt_inspection.product_date;     -- ���Y/�[����
    lr_xxwip_qt_inspection.batch_po_id    := NULL;                                    -- �ԍ�
--
    -- ====================================
    -- OUT�p�����[�^�Z�b�g
    -- ====================================
    or_xxwip_qt_inspection := lr_xxwip_qt_inspection;  -- xxwip_qt_inspection���R�[�h�^
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
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
--###################################  �Œ蕔 END   #########################################
--
  END qt_get_namaha_prod_data;
--
  /**********************************************************************************
   * Procedure Name   : qt_inspection_ins
   * Description      : �i�������˗����o�^/�X�V(make_qt_inspection �i�������˗����쐬 A-9)(����J)
  /*********************************************************************************/
  PROCEDURE qt_inspection_ins(
    it_division             IN  xxwip_qt_inspection.division%TYPE,         -- IN 1.�敪
    iv_disposal_div         IN  VARCHAR2,                                  -- IN 2.�����敪
    it_qt_inspect_req_no    IN  xxwip_qt_inspection.qt_inspect_req_no%TYPE,-- IN 3.�����˗�No
    ior_xxwip_qt_inspection IN  OUT xxwip_qt_inspection%ROWTYPE,           -- IN OUT 4.xxwip_qt_inspection���R�[�h�^
    ov_errbuf               OUT NOCOPY VARCHAR2,                          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,                          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'qt_inspection_ins'; -- �v���O������
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
    lr_xxwip_qt_inspection  xxwip_qt_inspection%ROWTYPE;  -- xxwip_qt_inspection���R�[�h�^
--
  BEGIN
    -- ���^�[���R�[�h�Z�b�g
    ov_retcode := gv_status_normal;
--
    lr_xxwip_qt_inspection := ior_xxwip_qt_inspection;  -- IN �p�����[�^���R�[�h�Z�b�g
--
    -- ====================================
    -- �i�������˗���񃌃R�[�h�ɒl���Z�b�g
    -- ====================================
    lr_xxwip_qt_inspection.qt_effect1             := gt_qt_status_mi;                   -- ���ʂP 10:������
    lr_xxwip_qt_inspection.qt_effect2             := gt_qt_status_mi;                   -- ���ʂQ 10:������
    lr_xxwip_qt_inspection.qt_effect3             := gt_qt_status_mi;                   -- ���ʂR 10:������
    lr_xxwip_qt_inspection.division               := it_division;                       -- �敪
    lr_xxwip_qt_inspection.last_updated_by        := FND_GLOBAL.USER_ID;                -- �ŏI�X�V��
    lr_xxwip_qt_inspection.last_update_date       := SYSDATE;                           -- �ŏI�X�V��
    lr_xxwip_qt_inspection.last_update_login      := FND_GLOBAL.LOGIN_ID;               -- �ŏI�X�V���O�C��
    lr_xxwip_qt_inspection.request_id             := FND_GLOBAL.CONC_REQUEST_ID;        -- �v��ID
    lr_xxwip_qt_inspection.program_application_id := FND_GLOBAL.PROG_APPL_ID;           -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    lr_xxwip_qt_inspection.program_id             := FND_GLOBAL.CONC_PROGRAM_ID;        -- �R���J�����g�E�v���O����ID
    lr_xxwip_qt_inspection.program_update_date    := SYSDATE;                           -- �v���O�����X�V��
--
    -- �����敪�F1�i�ǉ��j�̏ꍇ
    IF (iv_disposal_div = gv_disposal_div_ins) THEN
      -- ====================================
      -- �i�������˗���񃌃R�[�h�ɒl���Z�b�g
      -- ====================================
      SELECT xxwip_qt_inspect_req_no_s1.NEXTVAL  qt_inspect_req_no -- �����˗�No
      INTO   lr_xxwip_qt_inspection.qt_inspect_req_no
      FROM   DUAL;
      lr_xxwip_qt_inspection.created_by     := FND_GLOBAL.USER_ID; -- �쐬��
      lr_xxwip_qt_inspection.creation_date  := SYSDATE;            -- �쐬��
--
      -- ==================================
      -- �o�^����
      -- ==================================
      INSERT INTO xxwip_qt_inspection xqi(  -- �i�������˗����A�h�I��
         xqi.qt_inspect_req_no    -- �����˗�No
        ,xqi.inspect_class        -- �������
        ,xqi.item_id              -- �i��ID
        ,xqi.lot_id               -- ���b�gID
        ,xqi.vendor_line          -- �d����R�[�h/���C��No
        ,xqi.product_date         -- ������
        ,xqi.qty                  -- ����
        ,xqi.prod_dely_date       -- ���Y/�[����
        ,xqi.inspect_due_date1    -- �����\����P
        ,xqi.qt_effect1           -- ���ʂP
        ,xqi.inspect_due_date2    -- �����\����Q
        ,xqi.qt_effect2           -- ���ʂQ
        ,xqi.inspect_due_date3    -- �����\����R
        ,xqi.qt_effect3           -- ���ʂR
        ,xqi.inspect_period       -- ��������
        ,xqi.use_by_date          -- �ܖ�����
        ,xqi.unique_sign          -- �ŗL�L��
        ,xqi.division             -- �敪
        ,xqi.batch_po_id          -- �ԍ�
        ,xqi.created_by           -- �쐬��
        ,xqi.creation_date        -- �쐬��
        ,xqi.last_updated_by      -- �ŏI�X�V��
        ,xqi.last_update_date     -- �ŏI�X�V��
        ,xqi.last_update_login    -- �ŏI�X�V���O�C��
        ,xqi.request_id           -- �v��ID
        ,xqi.program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,xqi.program_id              -- �R���J�����g�E�v���O����ID
        ,xqi.program_update_date     -- �v���O�����X�V��
        )
      VALUES(
         lr_xxwip_qt_inspection.qt_inspect_req_no    -- �����˗�No
        ,lr_xxwip_qt_inspection.inspect_class        -- �������
        ,lr_xxwip_qt_inspection.item_id              -- �i��ID
        ,lr_xxwip_qt_inspection.lot_id               -- ���b�gID
        ,lr_xxwip_qt_inspection.vendor_line          -- �d����R�[�h/���C��No
        ,lr_xxwip_qt_inspection.product_date         -- ������
        ,lr_xxwip_qt_inspection.qty                  -- ����
        ,lr_xxwip_qt_inspection.prod_dely_date       -- ���Y/�[����
        ,lr_xxwip_qt_inspection.inspect_due_date1    -- �����\����P
        ,lr_xxwip_qt_inspection.qt_effect1           -- ���ʂP
        ,lr_xxwip_qt_inspection.inspect_due_date2    -- �����\����Q
        ,lr_xxwip_qt_inspection.qt_effect2           -- ���ʂQ
        ,lr_xxwip_qt_inspection.inspect_due_date3    -- �����\����R
        ,lr_xxwip_qt_inspection.qt_effect3           -- ���ʂR
        ,lr_xxwip_qt_inspection.inspect_period       -- ��������
        ,lr_xxwip_qt_inspection.use_by_date          -- �ܖ�����
        ,lr_xxwip_qt_inspection.unique_sign          -- �ŗL�L��
        ,lr_xxwip_qt_inspection.division             -- �敪
        ,lr_xxwip_qt_inspection.batch_po_id          -- �ԍ�
        ,lr_xxwip_qt_inspection.created_by           -- �쐬��
        ,lr_xxwip_qt_inspection.creation_date        -- �쐬��
        ,lr_xxwip_qt_inspection.last_updated_by      -- �ŏI�X�V��
        ,lr_xxwip_qt_inspection.last_update_date     -- �ŏI�X�V��
        ,lr_xxwip_qt_inspection.last_update_login    -- �ŏI�X�V���O�C��
        ,lr_xxwip_qt_inspection.request_id           -- �v��ID
        ,lr_xxwip_qt_inspection.program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,lr_xxwip_qt_inspection.program_id              -- �R���J�����g�E�v���O����ID
        ,lr_xxwip_qt_inspection.program_update_date     -- �v���O�����X�V��
      );
--
    -- �����敪�F2�i�X�V�j�̏ꍇ
    ELSIF (iv_disposal_div = gv_disposal_div_upd) THEN
      -- ====================================
      -- �i�������˗���񃌃R�[�h�ɒl���Z�b�g
      -- ====================================
      lr_xxwip_qt_inspection.qt_inspect_req_no := it_qt_inspect_req_no; -- �����˗�No
--
      -- ==================================
      -- �X�V����
      -- ==================================
      UPDATE xxwip_qt_inspection    xqi -- �i�������˗����A�h�I��
      SET    xqi.inspect_class           = lr_xxwip_qt_inspection.inspect_class          -- �������
            ,xqi.item_id                 = lr_xxwip_qt_inspection.item_id                -- �i��ID
            ,xqi.lot_id                  = lr_xxwip_qt_inspection.lot_id                 -- ���b�gID
            ,xqi.vendor_line             = lr_xxwip_qt_inspection.vendor_line            -- �d����R�[�h/���C��No
            ,xqi.product_date            = lr_xxwip_qt_inspection.product_date           -- ������
            ,xqi.qty                     = lr_xxwip_qt_inspection.qty                    -- ����
            ,xqi.prod_dely_date          = lr_xxwip_qt_inspection.prod_dely_date         -- ���Y/�[����
            ,xqi.inspect_due_date1       = lr_xxwip_qt_inspection.inspect_due_date1      -- �����\����P
            ,xqi.qt_effect1              = lr_xxwip_qt_inspection.qt_effect1             -- ���ʂP
            ,xqi.inspect_due_date2       = lr_xxwip_qt_inspection.inspect_due_date2      -- �����\����Q
            ,xqi.qt_effect2              = lr_xxwip_qt_inspection.qt_effect2             -- ���ʂQ
            ,xqi.inspect_due_date3       = lr_xxwip_qt_inspection.inspect_due_date3      -- �����\����R
            ,xqi.qt_effect3              = lr_xxwip_qt_inspection.qt_effect3             -- ���ʂR
            ,xqi.inspect_period          = lr_xxwip_qt_inspection.inspect_period         -- ��������
            ,xqi.use_by_date             = lr_xxwip_qt_inspection.use_by_date            -- �ܖ�����
            ,xqi.unique_sign             = lr_xxwip_qt_inspection.unique_sign            -- �ŗL�L��
            ,xqi.division                = lr_xxwip_qt_inspection.division               -- �敪
            ,xqi.batch_po_id             = lr_xxwip_qt_inspection.batch_po_id            -- �ԍ�
            ,xqi.last_updated_by         = lr_xxwip_qt_inspection.last_updated_by        -- �ŏI�X�V��
            ,xqi.last_update_date        = lr_xxwip_qt_inspection.last_update_date       -- �ŏI�X�V��
            ,xqi.last_update_login       = lr_xxwip_qt_inspection.last_update_login      -- �ŏI�X�V���O�C��
            ,xqi.request_id              = lr_xxwip_qt_inspection.request_id             -- �v��ID
            ,xqi.program_application_id  = lr_xxwip_qt_inspection.program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,xqi.program_id              = lr_xxwip_qt_inspection.program_id             -- �R���J�����g�E�v���O����ID
            ,xqi.program_update_date     = lr_xxwip_qt_inspection.program_update_date    -- �v���O�����X�V��
      WHERE xqi.qt_inspect_req_no        = lr_xxwip_qt_inspection.qt_inspect_req_no      -- �����˗�No
      ;
    END IF;
--
    -- ====================================
    -- OUT�p�����[�^�Z�b�g
    -- ====================================
    ior_xxwip_qt_inspection := lr_xxwip_qt_inspection;
--
  EXCEPTION
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
  END qt_inspection_ins;
--
  /**********************************************************************************
   * Procedure Name   : qt_update_lot_dff_api
   * Description      : ���b�g�}�X�^�X�V(make_qt_inspection �i�������˗����쐬 A-11)(����J)
  /*********************************************************************************/
  PROCEDURE qt_update_lot_dff_api(
    ir_xxwip_qt_inspection  IN xxwip_qt_inspection%ROWTYPE, -- IN 1.xxwip_qt_inspection���R�[�h�^
    ov_errbuf               OUT NOCOPY VARCHAR2,                   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,                   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'qt_update_lot_dff_api'; -- �v���O������
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
    ln_message_count      NUMBER;         -- ���b�Z�[�W�J�E���g
    lv_message_list       VARCHAR2(200);  -- ���b�Z�[�W���X�g

--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_xxwip_qt_inspection  xxwip_qt_inspection%ROWTYPE;  -- xxwip_qt_inspection���R�[�h�^
    lr_ic_lots_mst          ic_lots_mst%ROWTYPE;          -- ���b�g�}�X�^���R�[�h�^
--
  BEGIN
    -- ���^�[���R�[�h�Z�b�g
    ov_retcode := gv_status_normal;
--
    lr_xxwip_qt_inspection := ir_xxwip_qt_inspection;  -- IN �p�����[�^���R�[�h�Z�b�g
--
    -- ====================================
    -- OPM���b�g�}�X�^���R�[�h�ɒl���Z�b�g
    -- ====================================
    lr_ic_lots_mst.last_updated_by        := FND_GLOBAL.USER_ID;                -- �ŏI�X�V��
    lr_ic_lots_mst.last_update_date       := SYSDATE;                           -- �ŏI�X�V��
    lr_ic_lots_mst.last_update_login      := FND_GLOBAL.LOGIN_ID;               -- �ŏI�X�V���O�C��
    lr_ic_lots_mst.request_id             := FND_GLOBAL.CONC_REQUEST_ID;        -- �v��ID
    lr_ic_lots_mst.program_application_id := FND_GLOBAL.PROG_APPL_ID;           -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    lr_ic_lots_mst.program_id             := FND_GLOBAL.CONC_PROGRAM_ID;        -- �R���J�����g�E�v���O����ID
    lr_ic_lots_mst.program_update_date    := SYSDATE;                           -- �v���O�����X�V��
--
    -- ===============================
    -- OPM���b�g�}�X�^���b�N
    -- ===============================
    SELECT ilm.item_id                               item_id
          ,ilm.lot_id                                lot_id
          ,ilm.vendor_lot_no                         vendor_lot_no
          ,ilm.expire_date                           expire_date
          ,ilm.attribute1                            attribute1
          ,ilm.attribute2                            attribute2
          ,ilm.attribute3                            attribute3
          ,ilm.attribute4                            attribute4
          ,ilm.attribute5                            attribute5
          ,ilm.attribute6                            attribute6
          ,ilm.attribute7                            attribute7
          ,ilm.attribute8                            attribute8
          ,ilm.attribute9                            attribute9
          ,ilm.attribute10                           attribute10
          ,ilm.attribute11                           attribute11
          ,ilm.attribute12                           attribute12
          ,ilm.attribute13                           attribute13
          ,ilm.attribute14                           attribute14
          ,ilm.attribute15                           attribute15
          ,ilm.attribute16                           attribute16
          ,ilm.attribute17                           attribute17
          ,ilm.attribute18                           attribute18
          ,ilm.attribute19                           attribute19
          ,ilm.attribute20                           attribute20
          ,ilm.attribute21                           attribute21
          ,lr_xxwip_qt_inspection.qt_inspect_req_no  attribute22
          ,ilm.attribute23                           attribute23
          ,ilm.attribute24                           attribute24
          ,ilm.attribute25                           attribute25
          ,ilm.attribute26                           attribute26
          ,ilm.attribute27                           attribute27
          ,ilm.attribute28                           attribute28
          ,ilm.attribute29                           attribute29
          ,ilm.attribute30                           attribute30
    INTO   lr_ic_lots_mst.item_id
          ,lr_ic_lots_mst.lot_id
          ,lr_ic_lots_mst.vendor_lot_no
          ,lr_ic_lots_mst.expire_date
          ,lr_ic_lots_mst.attribute1
          ,lr_ic_lots_mst.attribute2
          ,lr_ic_lots_mst.attribute3
          ,lr_ic_lots_mst.attribute4
          ,lr_ic_lots_mst.attribute5
          ,lr_ic_lots_mst.attribute6
          ,lr_ic_lots_mst.attribute7
          ,lr_ic_lots_mst.attribute8
          ,lr_ic_lots_mst.attribute9
          ,lr_ic_lots_mst.attribute10
          ,lr_ic_lots_mst.attribute11
          ,lr_ic_lots_mst.attribute12
          ,lr_ic_lots_mst.attribute13
          ,lr_ic_lots_mst.attribute14
          ,lr_ic_lots_mst.attribute15
          ,lr_ic_lots_mst.attribute16
          ,lr_ic_lots_mst.attribute17
          ,lr_ic_lots_mst.attribute18
          ,lr_ic_lots_mst.attribute19
          ,lr_ic_lots_mst.attribute20
          ,lr_ic_lots_mst.attribute21
          ,lr_ic_lots_mst.attribute22
          ,lr_ic_lots_mst.attribute23
          ,lr_ic_lots_mst.attribute24
          ,lr_ic_lots_mst.attribute25
          ,lr_ic_lots_mst.attribute26
          ,lr_ic_lots_mst.attribute27
          ,lr_ic_lots_mst.attribute28
          ,lr_ic_lots_mst.attribute29
          ,lr_ic_lots_mst.attribute30
    FROM   ic_lots_mst                   ilm              -- OPM���b�g�}�X�^
    WHERE  ilm.item_id = lr_xxwip_qt_inspection.item_id   -- �i��ID
    AND    ilm.lot_id  = lr_xxwip_qt_inspection.lot_id    -- ���b�gID
    FOR UPDATE NOWAIT
    ;
--
    -- ===============================
    -- OPM���b�g�}�X�^DFF�X�V
    -- ===============================
    GMI_LOTUPDATE_PUB.UPDATE_LOT_DFF(
      p_api_version       => gn_api_version             -- IN  NUMBER
     ,p_init_msg_list     => FND_API.G_FALSE            -- IN  VARCHAR2 DEFAULT FND_API.G_FALSE
     ,p_commit            => FND_API.G_FALSE            -- IN  VARCHAR2 DEFAULT FND_API.G_FALSE
     ,p_validation_level  => FND_API.G_VALID_LEVEL_FULL -- IN  NUMBER   DEFAULT FND_API.G_VALID_LEVEL_FULL
     ,x_return_status     => lv_retcode                 -- OUT NOCOPY       VARCHAR2
     ,x_msg_count         => ln_message_count           -- OUT NOCOPY       NUMBER
     ,x_msg_data          => lv_message_list            -- OUT NOCOPY       VARCHAR2
     ,p_lot_rec           => lr_ic_lots_mst             -- IN  ic_lots_mst%ROWTYPE
    );
--
    -- �����ȊO�̏ꍇ�A�G���[
    IF (lv_retcode <> FND_API.G_RET_STS_SUCCESS)THEN
      ov_retcode := gv_status_error;
    END IF;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
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
--###################################  �Œ蕔 END   #########################################
--
  END qt_update_lot_dff_api;
--
  /**********************************************************************************
   * Procedure Name   : get_business_date
   * Description      : �c�Ɠ��擾
  /*********************************************************************************/
  PROCEDURE get_business_date(
    id_date               IN  DATE,        -- IN  1.���t �K�{
    in_period             IN  NUMBER,      -- IN  2.���� �K�{ �}�C�i�X�̓G���[�B
    od_business_date      OUT NOCOPY DATE,        -- OUT 1.���t�́����c�Ɠ���̓��t
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_business_date'; -- �v���O������
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
    cv_gmems_default_orgn  VARCHAR2(30) := 'GEMMS_DEFAULT_ORGN';  -- �v���t�@�C���I�v�V����(GMA: �f�t�H���g�g�D)
--
    -- *** ���[�J���ϐ� ***
    lv_orgn_code      fnd_profile_option_values.profile_option_value%TYPE;  -- �g�D�R�[�h
    ln_cnt            NUMBER := 0;   -- �J�E���g
    ld_business_date  DATE;          -- ���t�́����c�Ɠ���̓��t
    lv_errm           VARCHAR2(100);
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR mr_shcl_dtl_cur IS
      SELECT msd.calendar_date -- �J�����_���t
      FROM   mr_shcl_dtl msd   -- �����J�����_�[����
            ,sy_orgn_mst som   -- OPM�v�����g�}�X�^
      WHERE  som.orgn_code      = lv_orgn_code               -- �I���O�R�[�h
      AND    msd.calendar_id    = som.mfg_calendar_id        -- �J�����_�[ID�i���������j
      AND    msd.delete_mark    = 0                          -- �폜�}�[�N = 0 (�ғ���)
      AND    msd.calendar_date >= id_date                    -- �J�����_���t
      ORDER BY calendar_date asc
    ;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
    -- ���^�[���R�[�h�Z�b�g
    ov_retcode := gv_status_normal;
--
    -- ================================
    -- ���̓G���[�`�F�b�N
    -- ================================
    IF (id_date IS NULL) THEN -- ���tNULL�̓G���[
      RAISE global_api_expt;
    END IF;
--
    IF (in_period IS NULL) OR (in_period < 0) THEN -- ���Ԗ����͂܂���0�����̓G���[
      RAISE global_api_expt;
    END IF;
--
    -- ================================
    -- �v���t�@�C���擾
    -- ================================
    lv_orgn_code := FND_PROFILE.VALUE(cv_gmems_default_orgn);
--
    IF (lv_orgn_code IS NULL) THEN -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
      RAISE global_api_expt;
    END IF;
--
    --================================
    -- �f�[�^�擾
    --================================
    <<mr_shcl_dtl_loop>>
    FOR mr_shcl_dtl_rec IN mr_shcl_dtl_cur LOOP
      IF ln_cnt = in_period THEN
        ld_business_date := mr_shcl_dtl_rec.calendar_date;
        EXIT;
      END If;
      ln_cnt := ln_cnt + 1;
    END LOOP mr_shcl_dtl_loop;
--
   IF (ld_business_date IS NULL) THEN -- ���t�����Ȃ������ꍇ�̓G���[
     RAISE global_api_expt;
   END IF;
--
   od_business_date := ld_business_date;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
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
--###################################  �Œ蕔 END   #########################################
--
  END get_business_date;
--
  /**********************************************************************************
   * Function Name    : make_qt_inspection
   * Description      : �i�������˗����쐬
   ***********************************************************************************/
  -- �i�������˗����쐬
  PROCEDURE make_qt_inspection(
    it_division          IN  xxwip_qt_inspection.division%TYPE,         -- IN  1.�敪         �K�{�i1:���Y 2:���� 3:���b�g��� 4:�O���o���� 5:�r�������j
    iv_disposal_div      IN  VARCHAR2,                                  -- IN  2.�����敪     �K�{�i1:�ǉ� 2:�X�V 3:�폜�j
    it_lot_id            IN  xxwip_qt_inspection.lot_id%TYPE,           -- IN  3.���b�gID     �K�{
    it_item_id           IN  xxwip_qt_inspection.item_id%TYPE,          -- IN  4.�i��ID       �K�{
    iv_qt_object         IN  VARCHAR2,                                  -- IN  5.�Ώې�       �敪:5�̂ݕK�{�i1:�r���i�� 2:���Y���P 3:���Y���Q 4:���Y���R�j
    it_batch_id          IN  xxwip_qt_inspection.batch_po_id%TYPE,      -- IN  6.���Y�o�b�`ID �����敪3�ȊO���敪:1�̂ݕK�{
    it_batch_po_id       IN  xxwip_qt_inspection.batch_po_id%TYPE,      -- IN  7.���הԍ�     �����敪3�ȊO���敪:2�̂ݕK�{
    it_qty               IN  xxwip_qt_inspection.qty%TYPE,              -- IN  8.����         �����敪3�ȊO���敪:2�̂ݕK�{
    it_prod_dely_date    IN  xxwip_qt_inspection.prod_dely_date%TYPE,   -- IN  9.�[����       �����敪3�ȊO���敪:2�̂ݕK�{
    it_vendor_line       IN  xxwip_qt_inspection.vendor_line%TYPE,      -- IN 10.�d����R�[�h �����敪3�ȊO���敪:2�̂ݕK�{
    it_qt_inspect_req_no IN  xxwip_qt_inspection.qt_inspect_req_no%TYPE,-- IN 11.�����˗�No   �����敪:2�A3�̂ݕK�{
    ot_qt_inspect_req_no OUT NOCOPY xxwip_qt_inspection.qt_inspect_req_no%TYPE,-- OUT 1.�����˗�No
    ov_errbuf            OUT NOCOPY VARCHAR2,                                  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY VARCHAR2,                                  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2                                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_qt_inspection'; --�v���O������
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
    lt_temp_date    xxwip_qt_inspection.prod_dely_date%TYPE; -- TEMP���t(�����\����Z�o�p)
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_xxwip_qt_inspection      xxwip_qt_inspection%ROWTYPE;  -- �i�������˗����A�h�I�����R�[�h�^
    lr_xxwip_qt_inspection_now  xxwip_qt_inspection%ROWTYPE;  -- �i�������˗����A�h�I�����R�[�h�^
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    err_expt  EXCEPTION;  -- �G���[��O
--
  BEGIN
--
    -- ���^�[���R�[�h�Z�b�g
    ov_retcode := gv_status_normal;
--
    -- =============================
    -- A-1.���̓p�����[�^�`�F�b�N
    -- =============================
    qt_parameter_check(
      it_division          => it_division          -- IN  1.�敪
     ,iv_disposal_div      => iv_disposal_div      -- IN  2.�����敪
     ,it_lot_id            => it_lot_id            -- IN  3.���b�gID
     ,it_item_id           => it_item_id           -- IN  4.�i��ID
     ,iv_qt_object         => iv_qt_object         -- IN  5.�Ώې�
     ,it_batch_id          => it_batch_id          -- IN  6.���Y�o�b�`ID
     ,it_batch_po_id       => it_batch_po_id       -- IN  7.���הԍ�
     ,it_qty               => it_qty               -- IN  8.����
     ,it_prod_dely_date    => it_prod_dely_date    -- IN  9.�[����
     ,it_vendor_line       => it_vendor_line       -- IN 10.�d����R�[�h
     ,it_qt_inspect_req_no => it_qt_inspect_req_no -- IN 11.�����˗�No
     ,ov_errbuf            => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode           => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg            => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�̏ꍇ�A�����I��
    IF (lv_retcode = gv_status_error) THEN
      RAISE err_expt;
    END IF;
--
    -- �敪��5:�r�������̏ꍇ
    IF (it_division = gt_division_tea) THEN
      -- =============================
      -- A-2.�r���������擾
      -- =============================
      qt_get_namaha_prod_data(
        it_lot_id                => it_lot_id              -- IN  1.���b�gID
       ,it_item_id               => it_item_id             -- IN  2.�i��ID
       ,iv_qt_object             => iv_qt_object           -- IN  3.�Ώې�
       ,or_xxwip_qt_inspection   => lr_xxwip_qt_inspection -- OUT 1.xxwip_qt_inspection���R�[�h�^
       ,ov_errbuf                => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
    -- �敪��5:�r�������ȊO�̏ꍇ
    ELSE
      -- �f�[�^�`�F�b�N�p���b�gID�A�i��ID�擾
      lr_xxwip_qt_inspection.lot_id  := it_lot_id;  -- �f�[�^�`�F�b�N�p���b�gID
      lr_xxwip_qt_inspection.item_id := it_item_id; -- �f�[�^�`�F�b�N�p�i��ID
--
    END IF;
--
    -- �G���[�̏ꍇ�A�����I��
    IF (lv_retcode = gv_status_error) THEN
      RAISE err_expt;
    END IF;
--
    -- =============================
    -- A-3.�f�[�^�`�F�b�N/���b�N
    -- =============================
    qt_check_and_lock(
      iv_disposal_div        => iv_disposal_div                -- IN  1.�����敪
     ,it_lot_id              => lr_xxwip_qt_inspection.lot_id  -- IN  2.���b�gID
     ,it_item_id             => lr_xxwip_qt_inspection.item_id -- IN  3.�i��ID
     ,it_qt_inspect_req_no   => it_qt_inspect_req_no           -- IN  4.�����˗�No
     ,it_division            => it_division                    -- IN  5.�敪
     ,or_xxwip_qt_inspection => lr_xxwip_qt_inspection_now     -- OUT 1.xxwip_qt_inspection���R�[�h�^
     ,ov_errbuf              => lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode             => lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg              => lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�̏ꍇ�A�����I��
    IF (lv_retcode = gv_status_error) THEN
      RAISE err_expt;
--
    -- �x���̏ꍇ�A���^�[���R�[�h���Z�b�g���A�������s
    ELSIF (lv_retcode = gv_status_warn) THEN
      -- ���^�[���R�[�h���Z�b�g
      ov_retcode := lv_retcode;
    END IF;
--
    -- �����敪��3:�폜�ȊO�̏ꍇ
    IF (iv_disposal_div <> gv_disposal_div_del) THEN
      -- �敪��1:���Y�̏ꍇ
      IF (it_division = gt_division_gme) THEN
        -- =============================
        -- A-4.���Y���擾
        -- =============================
        qt_get_gme_data(
          it_batch_id             => it_batch_id                -- IN  1.���Y�o�b�`ID
         ,it_lot_id               => it_lot_id                  -- IN  2.���b�gID
         ,it_item_id              => it_item_id                 -- IN  3.�i��ID
         ,iv_disposal_div         => iv_disposal_div            -- IN  4.�����敪
         ,ir_xxwip_qt_inspection  => lr_xxwip_qt_inspection_now -- IN  5.xxwip_qt_inspection���R�[�h�^
         ,or_xxwip_qt_inspection  => lr_xxwip_qt_inspection     -- OUT 1.xxwip_qt_inspection���R�[�h�^
         ,ov_errbuf               => lv_errbuf                  -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode              => lv_retcode                 -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg               => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
      -- �敪��2:�����̏ꍇ
      ELSIF (it_division = gt_division_po) THEN
        -- =============================
        -- A-5.�������擾
        -- =============================
        qt_get_po_data(
          it_lot_id               => it_lot_id              -- IN  1.���b�gID
         ,it_item_id              => it_item_id             -- IN  2.�i��ID
         ,it_batch_po_id          => it_batch_po_id         -- IN  3.���הԍ�
         ,it_qty                  => it_qty                 -- IN  4.����
         ,it_prod_dely_date       => it_prod_dely_date      -- IN  5.�[����
         ,it_vendor_line          => it_vendor_line         -- IN  6.�d����R�[�h
         ,or_xxwip_qt_inspection  => lr_xxwip_qt_inspection -- OUT 1.xxwip_qt_inspection���R�[�h�^
         ,ov_errbuf               => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode              => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg               => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
      -- �敪��3:���b�g���̏ꍇ
      ELSIF (it_division = gt_division_lot) THEN
        -- =============================
        -- A-6.���b�g���擾
        -- =============================
        qt_get_lot_data(
          it_lot_id                => it_lot_id              -- IN  1.���b�gID
         ,it_item_id               => it_item_id             -- IN  2.�i��ID
         ,it_qty                   => it_qty                 -- IN  3.����
         ,or_xxwip_qt_inspection   => lr_xxwip_qt_inspection -- OUT 1.xxwip_qt_inspection���R�[�h�^
         ,ov_errbuf                => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode               => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg                => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
      -- �敪��4:�O���o�����̏ꍇ
      ELSIF (it_division = gt_division_spl) THEN
        -- =============================
        -- A-7.�O���o�������擾
        -- =============================
        qt_get_vendor_supply_data(
          it_lot_id               => it_lot_id              -- IN  1.���b�gID
         ,it_item_id              => it_item_id             -- IN  2.�i��ID
         ,or_xxwip_qt_inspection  => lr_xxwip_qt_inspection -- OUT 1.xxwip_qt_inspection���R�[�h�^
         ,ov_errbuf               => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode              => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg               => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
      END IF;
--
      -- �G���[�̏ꍇ�A�����I��
      IF (lv_retcode = gv_status_error) THEN
        RAISE err_expt;
--
      -- �x���̏ꍇ�A���^�[���R�[�h���Z�b�g���A�������s
      ELSIF (lv_retcode = gv_status_warn) THEN
        -- ���^�[���R�[�h���Z�b�g
        ov_retcode := lv_retcode;
      END IF;
--
      -- =============================
      -- A-8.�����\����Z�o
      -- =============================
      -- �敪��4:�O���o�����ȊO�̏ꍇ
      IF (it_division <> gt_division_spl) THEN
        -- �����\����Z�o���t�m��
        -- �敪��3:���b�g���̏ꍇ
        IF (it_division = gt_division_lot) THEN
          -- ���Y/�[������NULL�̏ꍇ��SYSDATE
          lt_temp_date := NVL(lr_xxwip_qt_inspection.prod_dely_date, TRUNC(SYSDATE));
--
        -- �敪��3:���b�g���ȊO�̏ꍇ
        ELSE
          -- ���Y/�[����
          lt_temp_date := lr_xxwip_qt_inspection.prod_dely_date;
        END IF;
--
        get_business_date(
          id_date           => lt_temp_date                              -- IN  1.���t �K�{
         ,in_period         => lr_xxwip_qt_inspection.inspect_period     -- IN  2.���� �K�{ �}�C�i�X�̓G���[�B
         ,od_business_date  => lr_xxwip_qt_inspection.inspect_due_date1  -- OUT 1.�����\����P
         ,ov_errbuf         => lv_errbuf                                 -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode                                -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg                                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        -- �G���[�̏ꍇ�A�����I��
        IF (lv_retcode = gv_status_error) THEN
          RAISE err_expt;
        END IF;
--
        -- �i�������˗���񃌃R�[�h�ɒl���Z�b�g
        lr_xxwip_qt_inspection.inspect_due_date2 := lr_xxwip_qt_inspection.inspect_due_date1;  -- �����\����Q
        lr_xxwip_qt_inspection.inspect_due_date3 := lr_xxwip_qt_inspection.inspect_due_date1;  -- �����\����R
      END IF;
--
      -- =============================
      -- A-9.�i�������˗����o�^/�X�V
      -- =============================
      qt_inspection_ins(
        it_division             => it_division            -- IN 1.�敪
       ,iv_disposal_div         => iv_disposal_div        -- IN 2.�����敪
       ,it_qt_inspect_req_no    => it_qt_inspect_req_no   -- IN 3.�����˗�No
       ,ior_xxwip_qt_inspection => lr_xxwip_qt_inspection -- IN OUT 4.xxwip_qt_inspection���R�[�h�^
       ,ov_errbuf               => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode              => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg               => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �G���[�̏ꍇ�A�����I��
      IF (lv_retcode = gv_status_error) THEN
        RAISE err_expt;
      END IF;
--
    -- �����敪��3:�폜�̏ꍇ
    ELSE
      -- =============================
      -- A-10.�i�������˗����폜
      -- =============================
--
      DELETE xxwip_qt_inspection   xqi   -- �i�������˗����
      WHERE  xqi.qt_inspect_req_no  = it_qt_inspect_req_no    -- �����˗�No
      ;
--
    END IF;
--
    -- =============================
    -- A-11.���b�g�}�X�^�X�V
    -- =============================
    qt_update_lot_dff_api(
      ir_xxwip_qt_inspection  => lr_xxwip_qt_inspection -- IN 1.xxwip_qt_inspection���R�[�h�^
     ,ov_errbuf               => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode              => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg               => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�̏ꍇ�A�����I��
    IF (lv_retcode = gv_status_error) THEN
      RAISE err_expt;
    END IF;
--
    -- =============================
    -- A-12.OUT�p�����[�^�ݒ�
    -- =============================
    -- �����敪��3:�폜�ȊO�̏ꍇ
    IF (iv_disposal_div <> gv_disposal_div_del) THEN
      ot_qt_inspect_req_no := lr_xxwip_qt_inspection.qt_inspect_req_no;  -- �����˗�No
--
    -- �����敪��3:�폜�̏ꍇ
    ELSE
      ot_qt_inspect_req_no := it_qt_inspect_req_no;  -- �����˗�No
    END IF;
--
  EXCEPTION
    -- �G���[������
    WHEN err_expt THEN
      -- =============================
      -- A-12.OUT�p�����[�^�ݒ�
      -- =============================
      ot_qt_inspect_req_no := it_qt_inspect_req_no;
      ov_retcode           := gv_status_error;
      ov_errmsg            := lv_errmsg;
      ov_errbuf            := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
--
--###############################  �Œ��O������ START   ###################################
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
--###################################  �Œ蕔 END   #########################################
--
  END make_qt_inspection;
--
  /**********************************************************************************
   * Function Name    : get_can_stock_qty
   * Description      : �莝�݌ɐ��ʎZ�oAPI(�������їp)
   ***********************************************************************************/
  FUNCTION get_can_stock_qty(
    in_batch_id         IN NUMBER,                    -- �o�b�`ID
    in_whse_id          IN NUMBER,                    -- OPM�ۊǑq��ID
    in_item_id          IN NUMBER,                    -- OPM�i��ID
    in_lot_id           IN NUMBER DEFAULT NULL)       -- ���b�gID
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_can_stock_qty'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    ln_total_qty NUMBER;
    ln_other_qty NUMBER;
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
--
    ln_total_qty := xxcmn_common_pkg.get_stock_qty(in_whse_id, in_item_id, in_lot_id);
--
    -- **************************************************
    -- ***  ���̐��Y�o�b�`�Ŏg�p����Ă��鐔�ʂ��擾  ***
    -- **************************************************
--
    BEGIN
      SELECT NVL(SUM(itp.trans_qty), 0) total
      INTO   ln_other_qty
      FROM   ic_tran_pnd            itp
            ,xxcmn_item_locations_v xilv
      WHERE  itp.whse_code     = xilv.whse_code
      AND    itp.doc_id        <>in_batch_id
      AND    itp.item_id       = in_item_id
      AND    itp.lot_id        = in_lot_id
      AND    itp.completed_ind = 0
      AND    itp.reverse_id    IS NULL
      AND    xilv.inventory_location_id = in_whse_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        ln_other_qty := 0 ;
    END ;
    ln_total_qty := ln_other_qty + ln_total_qty;
--
    RETURN ln_total_qty;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
    RETURN 0;
  END get_can_stock_qty;
--
  /**********************************************************************************
   * Procedure Name   : change_trans_date_all
   * Description      : �������t�X�V�֐�
   ***********************************************************************************/
  PROCEDURE change_trans_date_all(
    in_batch_id    IN  NUMBER,            -- ���Y�o�b�`ID
    ov_errbuf      OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'change_trans_date_all'; --�v���O������
    -- *** ���[�J���萔 ***
    cv_api_name   CONSTANT VARCHAR2(100) := '�������t�X�V�֐�';
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
    ln_message_count       NUMBER;                       --
    lv_message_list        VARCHAR2(100);                --
    lv_return_status       VARCHAR2(100);                --
    lt_batch_no            gme_batch_header.batch_no%TYPE;  -- �o�b�`NO
    lt_trans_date          ic_tran_pnd.trans_date%TYPE;     -- �������t
--
    -- *** ���[�J���E�J�[�\�� ***
    -- OPM�ۗ��݌Ƀg�����U�N�V�����J�[�\��
    CURSOR cur_ic_tran_pnd
    IS
      SELECT itp.trans_id   trans_id
            ,itp.trans_date trans_date
      FROM   ic_tran_pnd itp -- OPM�ۗ��݌Ƀg�����U�N�V����
      WHERE  itp.reverse_id  IS NULL
      AND    itp.delete_mark = gn_delete_mark_off
      AND    itp.doc_id      = in_batch_id
      ;
--
    -- *** ���[�J���E���R�[�h ***
    lr_material_detail_out gme_material_details%ROWTYPE;
    lr_tran_row_in         gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out        gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_def        gme_inventory_txns_gtmp%ROWTYPE;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***  �o�b�`No�Ɛ��Y�����擾���܂��B         ***
    -- ***********************************************
    SELECT gbh.batch_no -- �o�b�`No
          ,FND_DATE.STRING_TO_DATE( gmd.attribute11, 'YYYY/MM/DD' )  -- ���Y��
    INTO   lt_batch_no
          ,lt_trans_date
    FROM   gme_batch_header     gbh -- ���Y�o�b�`�w�b�_
          ,gme_material_details gmd -- ���Y�����ڍ�
    WHERE  gbh.batch_id = gmd.batch_id
    AND    line_type    = gn_prod
    AND    gbh.batch_id = in_batch_id
    AND    ROWNUM       = 1
    ;
--
    -- *************************************************
    -- ***  �f�t�H���g���b�g�̏���ID���擾���܂��B   ***
    -- *************************************************
    <<ic_tran_pnd_loop>>
    FOR rec_ic_tran_pnd IN cur_ic_tran_pnd LOOP
--
      -- �������t���A�����i�̓��t�ƈقȂ�ꍇ
      IF (lt_trans_date <> rec_ic_tran_pnd.trans_date) THEN
--
        -- *************************************************
        -- ***  �������t�ɐ��Y����ݒ肵�܂��B           ***
        -- *************************************************
        lr_tran_row_in.trans_id     := rec_ic_tran_pnd.trans_id;
        lr_tran_row_in.trans_date   := lt_trans_date;
--
        -- *************************************************
        -- ***  �����X�V�֐������s���܂��B               ***
        -- *************************************************
        GME_API_PUB.UPDATE_LINE_ALLOCATION (
          p_api_version        => GME_API_PUB.API_VERSION -- IN         NUMBER := gme_api_pub.api_version
         ,p_validation_level   => GME_API_PUB.MAX_ERRORS  -- IN         NUMBER := gme_api_pub.max_errors
         ,p_init_msg_list      => FALSE                   -- IN         BOOLEAN := FALSE
         ,p_commit             => FALSE                   -- IN         BOOLEAN := FALSE
         ,p_tran_row           => lr_tran_row_in          -- IN         gme_inventory_txns_gtmp%ROWTYPE
         ,p_lot_no             => NULL                    -- IN         VARCHAR2 DEFAULT NULL
         ,p_sublot_no          => NULL                    -- IN         VARCHAR2 DEFAULT NULL
         ,p_create_lot         => FALSE                   -- IN         BOOLEAN DEFAULT FALSE
         ,p_ignore_shortage    => FALSE                   -- IN         BOOLEAN DEFAULT FALSE
         ,p_scale_phantom      => FALSE                   -- IN         BOOLEAN DEFAULT FALSE
         ,x_material_detail    => lr_material_detail_out  -- OUT NOCOPY gme_material_details%ROWTYPE
         ,x_tran_row           => lr_tran_row_out         -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE
         ,x_def_tran_row       => lr_tran_row_def         -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE
         ,x_message_count      => ln_message_count        -- OUT NOCOPY NUMBER
         ,x_message_list       => lv_message_list         -- OUT NOCOPY VARCHAR2
         ,x_return_status      => lv_return_status        -- OUT NOCOPY VARCHAR2
        );
--
        IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          lv_errbuf := lv_message_list;
          RAISE api_expt;
        END IF;
      END IF;
    END LOOP;
--
    -- *************************************************
    -- ***  �ړ����b�g�ڍׂ̎��ѓ����X�V���܂��B     ***
    -- *************************************************
    UPDATE xxinv_mov_lot_details xmld 
    SET    xmld.actual_date       = lt_trans_date
          ,xmld.last_updated_by   = FND_GLOBAL.USER_ID  
          ,xmld.last_update_date  = SYSDATE             
          ,xmld.last_update_login = FND_GLOBAL.LOGIN_ID 
    WHERE  xmld.record_type_code   = '40' -- ���R�[�h�^�C�v
    AND    xmld.document_type_code = '40' -- �����^�C�v
    AND    xmld.actual_date       <> lt_trans_date
    AND    EXISTS ( SELECT 'X'
                    FROM   gme_material_details gmd
                    WHERE  gmd.material_detail_id = xmld.mov_line_id
                    AND    gmd.batch_id = in_batch_id );
--
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip                -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
                     ,gv_msg_xxwip10049       -- ���b�Z�[�W�FAPP-XXWIP-10049 API�G���[���b�Z�[�W
                     ,gv_tkn_api_name         -- �g�[�N���FAPI_NAME
                     ,cv_api_name             -- API���F���Y�o�b�`�w�b�_����
                    ),1,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
      -- API���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,gv_batch_no || lt_batch_no);
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END change_trans_date_all;
--
END xxwip_common_pkg;
/
