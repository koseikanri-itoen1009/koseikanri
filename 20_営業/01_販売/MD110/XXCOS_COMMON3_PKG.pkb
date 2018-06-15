CREATE OR REPLACE PACKAGE BODY XXCOS_COMMON3_PKG
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCOS_COMMON3_PKG(body)
 * Description      : ���ʊ֐��p�b�P�[�W3(�̔�)
 * MD.070           : ���ʊ֐�    MD070_IPO_COS
 * Version          : 1.1
 *
 * Program List
 * --------------------------- ------ ---------- -----------------------------------------
 *  Name                        Type   Return     Description
 * --------------------------- ------ ---------- -----------------------------------------
 *  process_order               P                 oe_order_pub�̎��s
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/04/18    1.0   H.Sasaki         �V�K�쐬
 *  2018/06/11    1.1   H.Sasaki         �̔��P��������������Ȃ��悤�Ή�[E_�{�ғ�_14886]
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
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100)  :=  'XXCOS_COMMON3_PKG';                --  �p�b�P�[�W��
  --  �A�v���P�[�V�����Z�k��
  cv_appl_short_name_xxcos  CONSTANT VARCHAR2(5)    :=  'XXCOS';                            --  �A�h�I���F�̕��E�̔�OM�̈�
  --  ���b�Z�[�W��
  cv_msg_name_xxcos11202    CONSTANT VARCHAR2(30)   :=  'APP-XXCOS1-11202';                 --  �w�b�_ID�K�{�G���[
  cv_msg_name_xxcos11203    CONSTANT VARCHAR2(30)   :=  'APP-XXCOS1-11203';                 --  �[�i�\����K�{�G���[
  cv_msg_name_xxcos11204    CONSTANT VARCHAR2(30)   :=  'APP-XXCOS1-11204';                 --  ���׏��K�{�G���[
  cv_msg_name_xxcos11223    CONSTANT VARCHAR2(30)   :=  'APP-XXCOS1-11223';                 --  �K�{�t���O�ݒ�G���[
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : process_order
   * Description      : oe_order_pub�̎��s
   ***********************************************************************************/
  PROCEDURE process_order(
      iv_upd_status_booked    IN  VARCHAR2                                              --  �X�e�[�^�X�X�V�t���O�i�L���j
    , iv_upd_request_date     IN  VARCHAR2                                              --  �����X�V�t���O
--  2018/06/12 V1.1 Added START
    , iv_upd_item_code        IN  VARCHAR2                                              --  �i�ڍX�V�t���O
--  2018/06/12 V1.1 Added END
    , it_header_id            IN  oe_order_headers_all.header_id%TYPE                   --  �w�b�_ID
    , it_line_id              IN  oe_order_lines_all.line_id%TYPE                       --  ����ID                          #�K�{#
    , it_inventory_item_id    IN  oe_order_lines_all.inventory_item_id%TYPE             --  �i��ID                          #�K�{#
    , it_ordered_quantity     IN  oe_order_lines_all.ordered_quantity%TYPE              --  �󒍐���                        #�K�{#
    , it_reason_code          IN  oe_reasons.reason_code%TYPE                           --  ���R�R�[�h
    , it_request_date         IN  oe_order_lines_all.request_date%TYPE                  --  �[�i�\���(����)
    , it_subinv_code          IN  oe_order_lines_all.subinventory%TYPE                  --  �ۊǏꏊ                        #�K�{#
    , ov_errbuf               OUT NOCOPY VARCHAR2                                       --  �G���[�E���b�Z�[�W�G���[        #�Œ�#
    , ov_retcode              OUT NOCOPY VARCHAR2                                       --  ���^�[���E�R�[�h                #�Œ�#
    , ov_errmsg               OUT NOCOPY VARCHAR2                                       --  ���[�U�[�E�G���[�E���b�Z�[�W    #�Œ�#
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'process_order'; -- �v���O������
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
    cv_separate                         CONSTANT VARCHAR2(1)  :=  '/';  --  �G���[���b�Z�[�W�����p
    cv_encoded                          CONSTANT VARCHAR2(1)  :=  'F';  --  �G���[���b�Z�[�W�����p
    -- *** ���[�J���ϐ� ***
    --  API�p�ϐ�
    lv_return_status                    VARCHAR2(1);                    --  API�̏I���X�e�[�^�X
    ln_msg_count                        NUMBER  := 0;                   --  API�̃G���[���b�Z�[�W����
    lv_msg_data                         VARCHAR2(2000);                 --  API�̃G���[���b�Z�[�W
    lv_out_message                      VARCHAR2(4000);                 --  OUT�p�̃��b�Z�[�W
    lr_header_rec                       oe_order_pub.header_rec_type;   --  oe_order_pub�p�ϐ�
    lt_line_tbl                         oe_order_pub.line_tbl_type;     --  oe_order_pub�p�ϐ�
    lt_action_request_tbl               oe_order_pub.request_tbl_type;  --  oe_order_pub�p�ϐ�
--  2018/06/12 V1.1 Added START
    lt_line_adj_tbl                     oe_order_pub.line_adj_tbl_type; --  oe_order_pub�p�ϐ�
    lt_unit_selling_price               oe_order_lines_all.unit_selling_price%TYPE;       --  �̔��P��
    lt_calculate_price_flag             oe_order_lines_all.calculate_price_flag%TYPE;     --  ���i�v�Z�t���O
--  2018/06/12 V1.1 Added END
    --  API��OUT�p�ϐ��i�߂�l�̎󂯂ɂ̂ݎg�p�j
    lt_out_header_rec                   oe_order_pub.header_rec_type;
    lt_out_header_val_rec               oe_order_pub.header_val_rec_type;
    lt_out_header_adj_tbl               oe_order_pub.header_adj_tbl_type;
    lt_out_header_adj_val_tbl           oe_order_pub.header_adj_val_tbl_type;
    lt_out_header_price_att_tbl         oe_order_pub.header_price_att_tbl_type;
    lt_out_header_adj_att_tbl           oe_order_pub.header_adj_att_tbl_type;
    lt_out_header_adj_assoc_tbl         oe_order_pub.header_adj_assoc_tbl_type;
    lt_out_header_scredit_tbl           oe_order_pub.header_scredit_tbl_type;
    lt_out_header_scredit_val_tbl       oe_order_pub.header_scredit_val_tbl_type;
    lt_out_line_tbl                     oe_order_pub.line_tbl_type;
    lt_out_line_val_tbl                 oe_order_pub.line_val_tbl_type;
    lt_out_line_adj_tbl                 oe_order_pub.line_adj_tbl_type;
    lt_out_line_adj_val_tbl             oe_order_pub.line_adj_val_tbl_type;
    lt_out_line_price_att_tbl           oe_order_pub.line_price_att_tbl_type;
    lt_out_line_adj_att_tbl             oe_order_pub.line_adj_att_tbl_type;
    lt_out_line_adj_assoc_tbl           oe_order_pub.line_adj_assoc_tbl_type;
    lt_out_line_scredit_tbl             oe_order_pub.line_scredit_tbl_type;
    lt_out_line_scredit_val_tbl         oe_order_pub.line_scredit_val_tbl_type;
    lt_out_lot_serial_tbl               oe_order_pub.lot_serial_tbl_type;
    lt_out_lot_serial_val_tbl           oe_order_pub.lot_serial_val_tbl_type;
    lt_out_action_request_tbl           oe_order_pub.request_tbl_type;
    -- *** ���[�J���E�J�[�\�� ***
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    --  �p�����[�^�`�F�b�N
    --==============================================================
    IF  ( NVL( iv_upd_status_booked, '*' ) NOT IN( 'Y', 'N' )
          OR
          NVL( iv_upd_request_date,  '*' ) NOT IN( 'Y', 'N' )
        )
    THEN
      --  �X�e�[�^�X�X�V�t���O�ƒ����X�V�t���O�́A�K�{��Y�܂���N�̂݉�
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_appl_short_name_xxcos
                      , iv_name         =>  cv_msg_name_xxcos11223
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    IF  ( ( iv_upd_status_booked = 'Y'
            OR
            iv_upd_request_date  = 'Y'
          )
          AND it_header_id          IS NULL   --  �w�b�_ID
        )
    THEN
      --  �X�e�[�^�X�X�V�t���OY, �܂��� �����X�V�t���OY �̏ꍇ�A�w�b�_ID�K�{
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_appl_short_name_xxcos
                      , iv_name         =>  cv_msg_name_xxcos11202
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    IF  (     iv_upd_request_date = 'Y'
          AND it_request_date       IS NULL   --  �[�i�\���
        )
    THEN
      --  �����X�V�t���OY �̏ꍇ�A�[�i�\����i�����j�K�{
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_appl_short_name_xxcos
                      , iv_name         =>  cv_msg_name_xxcos11203
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    IF  ( iv_upd_status_booked = 'N'
          AND
          (     it_line_id            IS NULL   --  ����ID
            OR  it_inventory_item_id  IS NULL   --  �i��ID
            OR  it_ordered_quantity   IS NULL   --  �󒍐���
            OR  it_subinv_code        IS NULL   --  �ۊǏꏊ
          )
        )
    THEN
      --  �X�e�[�^�X�X�V�t���ON�̏ꍇ�A���׊֘A�̃p�����[�^�͐ݒ�K�{
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_appl_short_name_xxcos
                      , iv_name         =>  cv_msg_name_xxcos11204
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --==============================================================
    --  �󒍍X�V����
    --==============================================================
    --  ������
    lv_errbuf                   :=  NULL;
    lv_errmsg                   :=  NULL;
    OE_MSG_PUB.INITIALIZE;
    --
    IF ( iv_upd_status_booked = 'Y' ) THEN
      --  �X�e�[�^�X�X�V�t���OY�̏ꍇ�A�L�������݂̂����{
      --  �{�����ŋL���\���̔���͍s���܂���B�Ăяo�����ł̃`�F�b�N�K�{
      lt_action_request_tbl(1)                :=  OE_ORDER_PUB.G_MISS_REQUEST_REC;
      lt_action_request_tbl(1).entity_code    :=  OE_GLOBALS.G_ENTITY_HEADER;
      lt_action_request_tbl(1).request_type   :=  OE_GLOBALS.G_BOOK_ORDER;
      lt_action_request_tbl(1).entity_id      :=  it_header_id;
      --  �X�V�������s
      oe_order_pub.process_order(
          p_api_version_number            =>  1.0
        , x_return_status                 =>  lv_return_status
        , x_msg_count                     =>  ln_msg_count
        , x_msg_data                      =>  lv_msg_data
        , p_header_rec                    =>  lr_header_rec                   --  �w�b�_���
        , p_line_tbl                      =>  lt_line_tbl                     --  ���׏��
        , p_action_request_tbl            =>  lt_action_request_tbl           --  �A�N�V�������N�G�X�g
        , x_header_rec                    =>  lt_out_header_rec
        , x_header_val_rec                =>  lt_out_header_val_rec
        , x_header_adj_tbl                =>  lt_out_header_adj_tbl
        , x_header_adj_val_tbl            =>  lt_out_header_adj_val_tbl
        , x_header_price_att_tbl          =>  lt_out_header_price_att_tbl
        , x_header_adj_att_tbl            =>  lt_out_header_adj_att_tbl
        , x_header_adj_assoc_tbl          =>  lt_out_header_adj_assoc_tbl
        , x_header_scredit_tbl            =>  lt_out_header_scredit_tbl
        , x_header_scredit_val_tbl        =>  lt_out_header_scredit_val_tbl
        , x_line_tbl                      =>  lt_out_line_tbl
        , x_line_val_tbl                  =>  lt_out_line_val_tbl
        , x_line_adj_tbl                  =>  lt_out_line_adj_tbl
        , x_line_adj_val_tbl              =>  lt_out_line_adj_val_tbl
        , x_line_price_att_tbl            =>  lt_out_line_price_att_tbl
        , x_line_adj_att_tbl              =>  lt_out_line_adj_att_tbl
        , x_line_adj_assoc_tbl            =>  lt_out_line_adj_assoc_tbl
        , x_line_scredit_tbl              =>  lt_out_line_scredit_tbl
        , x_line_scredit_val_tbl          =>  lt_out_line_scredit_val_tbl
        , x_lot_serial_tbl                =>  lt_out_lot_serial_tbl
        , x_lot_serial_val_tbl            =>  lt_out_lot_serial_val_tbl
        , x_action_request_tbl            =>  lt_out_action_request_tbl
      );
      --  ���s���ʔ���
      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
        --  �X�e�[�^�X����ȊO�̏ꍇ�A���b�Z�[�W�𐶐�
        FOR ln_count IN 1 .. ln_msg_count LOOP
          lv_errmsg :=    lv_out_message
                      ||  cv_separate
                      ||  oe_msg_pub.get(
                              p_msg_index   =>  ln_count
                            , p_encoded     =>  cv_encoded
                          );
        END LOOP;
        --
        lv_errbuf :=  lv_errmsg;
        RAISE global_api_expt;
      END IF;
    ELSIF ( iv_upd_status_booked = 'N' ) THEN
      --  �X�e�[�^�X�X�V�t���ON�̏ꍇ�A���ڍX�V�݂̂����{�i�{�@�\�R�[��1��ɑ΂��A����1�s�̂ݍX�V�j
      --  �{�@�\�ōX�V�\���̔���͍s���܂���B�Ăяo�����ł̃`�F�b�N�K�{
      lt_line_tbl(1)                      :=  OE_ORDER_PUB.G_MISS_LINE_REC;
      lt_line_tbl(1).operation            :=  OE_GLOBALS.G_OPR_UPDATE;      --  UPDATE
      lt_line_tbl(1).line_id              :=  it_line_id;                   --  ����ID
      lt_line_tbl(1).inventory_item_id    :=  it_inventory_item_id;         --  �i��ID
      lt_line_tbl(1).ordered_item_id      :=  it_inventory_item_id;         --  �󒍕i��ID
      lt_line_tbl(1).ordered_quantity     :=  it_ordered_quantity;          --  �󒍐���
      lt_line_tbl(1).subinventory         :=  it_subinv_code;               --  �ۊǏꏊ
      --  �ύX���R�ݒ�
      IF ( it_reason_code IS NOT NULL ) THEN
        lt_line_tbl(1).change_reason        :=  it_reason_code;               --  ���R
      END IF;
      --  �����X�V
      IF ( iv_upd_request_date = 'Y' ) THEN
        lr_header_rec               :=  OE_ORDER_PUB.G_MISS_HEADER_REC;
        lr_header_rec.operation     :=  OE_GLOBALS.G_OPR_UPDATE;
        lr_header_rec.header_id     :=  it_header_id;
        lr_header_rec.request_date  :=  it_request_date;                      --  �w�b�_����
        lt_line_tbl(1).request_date :=  it_request_date;                      --  ���ג���
      END IF;
      --
--  2018/06/12 V1.1 Added START
      --  �P�������X�V����
      IF ( iv_upd_item_code = 'Y' ) THEN
        --  �i�ڍX�V���s���ꍇ�ŁA�󒍂̉��i�v�Z�t���O��N�̏ꍇ�A��������{
        BEGIN
          SELECT  oola.unit_selling_price
                , oola.calculate_price_flag
          INTO    lt_unit_selling_price           --  �̔��P��
                , lt_calculate_price_flag         --  ���i�v�Z�t���O
          FROM    oe_order_lines_all      oola
          WHERE   oola.line_id    =   it_line_id
          ;
        END;
        IF ( lt_calculate_price_flag = 'N' ) THEN
          --  ���i�v�Z�t���O��N�̏ꍇ���{
          --  ORDER LINE
          lt_line_tbl(1).calculate_price_flag     :=  'Y';
          --  PRICE ADJUSTMENT
          lt_line_adj_tbl(1)                      :=  OE_ORDER_PUB.G_MISS_LINE_ADJ_REC;
          lt_line_adj_tbl(1).operation            :=  OE_GLOBALS.G_OPR_CREATE;
          lt_line_adj_tbl(1).automatic_flag       :=  'N';
          lt_line_adj_tbl(1).line_index           :=  1;
          lt_line_adj_tbl(1).arithmetic_operator  :=  'NEWPRICE';
          lt_line_adj_tbl(1).applied_flag         :=  'Y';
          lt_line_adj_tbl(1).modifier_level_code  :=  'LINE';
          lt_line_adj_tbl(1).updated_flag         :=  'Y';
          lt_line_adj_tbl(1).operand              :=  lt_unit_selling_price;
          --
          BEGIN
            --  �蓮���f�B�t�@�C�A
            SELECT  qmv.list_header_id
                  , qmv.list_line_id
                  , qmv.list_line_type_code
            INTO    lt_line_adj_tbl(1).list_header_id               --  ���X�g�w�b�_ID
                  , lt_line_adj_tbl(1).list_line_id                 --  ���X�g����ID
                  , lt_line_adj_tbl(1).list_line_type_code          --  ���X�g���׃^�C�v
            FROM    qp_modifier_summary_v     qmv
                  , qp_secu_list_headers_vl   qhv
            WHERE   qmv.list_header_id  =   qhv.list_header_id
            AND     qhv.name            =   'XXOM_MOD1'
            ;
          END;
          --
        END IF;
      END IF;
--  2018/06/12 V1.1 Added END
      --  �X�V�������s
      oe_order_pub.process_order(
          p_api_version_number            =>  1.0
        , x_return_status                 =>  lv_return_status
        , x_msg_count                     =>  ln_msg_count
        , x_msg_data                      =>  lv_msg_data
        , p_header_rec                    =>  lr_header_rec                   --  �w�b�_���
        , p_line_tbl                      =>  lt_line_tbl                     --  ���׏��
--  2018/06/12 V1.1 Added START
        , p_line_adj_tbl                  =>  lt_line_adj_tbl
--  2018/06/12 V1.1 Added END
        , x_header_rec                    =>  lt_out_header_rec
        , x_header_val_rec                =>  lt_out_header_val_rec
        , x_header_adj_tbl                =>  lt_out_header_adj_tbl
        , x_header_adj_val_tbl            =>  lt_out_header_adj_val_tbl
        , x_header_price_att_tbl          =>  lt_out_header_price_att_tbl
        , x_header_adj_att_tbl            =>  lt_out_header_adj_att_tbl
        , x_header_adj_assoc_tbl          =>  lt_out_header_adj_assoc_tbl
        , x_header_scredit_tbl            =>  lt_out_header_scredit_tbl
        , x_header_scredit_val_tbl        =>  lt_out_header_scredit_val_tbl
        , x_line_tbl                      =>  lt_out_line_tbl
        , x_line_val_tbl                  =>  lt_out_line_val_tbl
        , x_line_adj_tbl                  =>  lt_out_line_adj_tbl
        , x_line_adj_val_tbl              =>  lt_out_line_adj_val_tbl
        , x_line_price_att_tbl            =>  lt_out_line_price_att_tbl
        , x_line_adj_att_tbl              =>  lt_out_line_adj_att_tbl
        , x_line_adj_assoc_tbl            =>  lt_out_line_adj_assoc_tbl
        , x_line_scredit_tbl              =>  lt_out_line_scredit_tbl
        , x_line_scredit_val_tbl          =>  lt_out_line_scredit_val_tbl
        , x_lot_serial_tbl                =>  lt_out_lot_serial_tbl
        , x_lot_serial_val_tbl            =>  lt_out_lot_serial_val_tbl
        , x_action_request_tbl            =>  lt_out_action_request_tbl
      );
      --  ���s���ʔ���
      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
        --  �X�e�[�^�X����ȊO�̏ꍇ�A���b�Z�[�W�𐶐�
        FOR ln_count IN 1 .. ln_msg_count LOOP
          lv_errmsg :=    lv_out_message
                      ||  cv_separate
                      ||  oe_msg_pub.get(
                              p_msg_index   =>  ln_count
                            , p_encoded     =>  cv_encoded
                          );
        END LOOP;
        --
        lv_errbuf :=  lv_errmsg;
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
  END process_order;
--
END XXCOS_COMMON3_PKG;
/
