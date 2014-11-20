CREATE OR REPLACE PACKAGE BODY XXCOP_COMMON_PKG2
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP_COMMON_PKG(spec)
 * Description      : ���ʊ֐��p�b�P�[�W2(�v��)
 * MD.050           : ���ʊ֐�    MD070_IPO_COP
 * Version          : 2.5
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- -------------------------------------------------------
 * get_item_info             10.�i�ڏ��擾����
 * get_shipment_result       11.�o�׎��ю擾
 * get_num_of_shipped        12.�N�x�����ʏo�׎��ю擾
 * get_num_of_forecast       13.�o�ח\���擾����
 * get_stock_plan            14.���ɗ\��擾����
 * get_onhand_qty            15.�莝�݌Ɏ擾����
 * get_deliv_lead_time       16.�z�����[�h�^�C���擾����
 * get_working_days          17.�ғ������擾����
 * upd_assignment            18.�����Z�b�gAPI�N��
 * get_loct_info             19.�q�ɏ��擾����
 * get_critical_date_f       20.�N�x��������擾����
 * get_delivery_unit         21.�z���P�ʎ擾����
 * get_receipt_date          22.�����擾����
 * get_shipment_date         23.�o�ד��擾����(�p�~�\��)
 * get_item_category_f       24.�i�ڃJ�e�S���擾
 * get_last_arrival_date_f   25.�ŏI���ɓ��擾
 * get_last_purchase_date_f  26.�ŏI�w�����擾
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0                   �V�K�쐬
 *  2009/04/08    1.1  SCS.Kikuchi      T1_0272,T1_0279,T1_0282,T1_0284�Ή�
 *  2009/05/08    1.2  SCS.Kikuchi      T1_0918,T1_0919�Ή�
 *  2009/07/23    1.3  SCS.Fukada       0000670�Ή�(���ʉۑ�FI_E_479)
 *  2009/11/24    1.4  SCS.Itou         �{�ԏ�Q#7 �v�悪�ғ�����܂Ŋ����Z�b�gAPI�N�����N�����Ȃ��B
 *  2009/08/24    2.0  SCS.Fukada       0000669�Ή�(���ʉۑ�FI_E_479)�A�ύX�����폜
 *  2009/11/05    2.1  SCS.Goto         I_E_479_009
 *  2009/11/05    2.2  SCS.Goto         I_E_479_008
 *  2009/12/01    2.3  SCS.Goto         I_E_479_020 �A�v��PT�Ή�
 *  2009/12/01    2.4  SCS.Fukada       I_E_479_022 �����Z�b�gAPI�N���C��
 *  2009/12/07    2.5  SCS.Goto         I_E_479_023 �A�v��PT�Ή�
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  -- ���b�Z�[�W�E�A�v���P�[�V�������i�A�h�I���F�̕��E�v��̈�j
  cv_msg_application        CONSTANT VARCHAR2(100) := 'XXCOP';
  -- ���b�Z�[�W��
  cv_message_00002          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00002';
  -- ���b�Z�[�W�g�[�N��
  cv_message_00002_token_1  CONSTANT VARCHAR2(9)   := 'PROF_NAME';
  cv_cmn_drink_cal_cd       CONSTANT VARCHAR2(100) := 'XXCMN_DRNK_WHSE_STD_CAL';        -- �h�����N��J�����_
  cv_cmn_drink_cal_cd_name  CONSTANT VARCHAR2(100) := 'XXCMN:�h�����N�q�Ɋ�J�����_'; -- �h�����N��J�����_
--
--################################  �Œ蕔 END   ##################################
--
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOP_COMMON_PKG2';       -- �p�b�P�[�W��
  cv_lang                   CONSTANT VARCHAR2(100) := USERENV('LANG');           -- ����
--
--
  -- ===============================
  -- ���[�U�[��`�萔
  -- ===============================
  cd_sys_date               CONSTANT DATE        := SYSDATE;
  cn_zero                   CONSTANT NUMBER      := 0;
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  date_null_expt            EXCEPTION;
  date_from_to_expt         EXCEPTION;
  --
  /**********************************************************************************
   * Procedure Name   : get_item_info
   * Description      : �i�ڏ��擾����
   ***********************************************************************************/
  PROCEDURE get_item_info(
    id_target_date          IN  DATE,         -- �Ώۓ��t
    in_organization_id      IN  NUMBER,       -- �g�DID
    in_inventory_item_id    IN  NUMBER,       -- �݌ɕi��ID
    on_item_id              OUT NUMBER,       -- OPM�i��ID
    ov_item_no              OUT VARCHAR2,     -- �i�ڃR�[�h
    ov_item_name            OUT VARCHAR2,     -- �i�ږ���
    on_num_of_case          OUT NUMBER,       -- �P�[�X����
    on_palette_max_cs_qty   OUT NUMBER,       -- �z��
    on_palette_max_step_qty OUT NUMBER,       -- �i��
    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W
    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h
    ov_errmsg               OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'get_item_info'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    --�i�ڃJ�e�S��
    cv_category_prod_class    CONSTANT VARCHAR2(100) := '�{�Џ��i�敪';
    cv_category_item_class    CONSTANT VARCHAR2(100) := '�i�ڋ敪';
    cv_category_article_class CONSTANT VARCHAR2(100) := '���i���i�敪';
    --�i�ڃJ�e�S���l
    cv_prod_class_leaf        CONSTANT VARCHAR2(100) := '1';  -- ���[�t
    cv_prod_class_drink       CONSTANT VARCHAR2(100) := '2';  -- �h�����N
    cv_item_class_product     CONSTANT VARCHAR2(100) := '5';  -- ���i
    cv_article_class_product  CONSTANT VARCHAR2(100) := '2';  -- ���i
    --�i�ڃ}�X�^
    cn_iimb_status_active     CONSTANT NUMBER := 0;           -- �X�e�[�^�X
    cn_ximb_status_active     CONSTANT NUMBER := 0;           -- �X�e�[�^�X
    cv_shipping_enable        CONSTANT NUMBER := '1';         -- �X�e�[�^�X
--
    -- *** ���[�J���ϐ� ***
    lt_prod_class             mtl_categories_b.segment1%TYPE;  -- �{�Џ��i�敪
    lt_article_class          mtl_categories_b.segment1%TYPE;  -- ���i���i�敪
    lt_item_category          mtl_categories_b.segment1%TYPE;  -- �i�ڃJ�e�S��
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    --��O��`
    outside_scope_expt        EXCEPTION;
    --
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
--
    --==============================================================
    --�i�ڎ擾
    --==============================================================
    SELECT iimb.item_id                        item_id               -- OPM�i��ID
          ,iimb.item_no                        item_no               -- �i�ڃR�[�h
          ,ximb.item_short_name                item_name             -- �i�ږ���
          ,NVL(TO_NUMBER(iimb.attribute11), 1) num_of_case           -- �P�[�X����
          ,DECODE(ximb.palette_max_cs_qty , NULL , 1
                                          , 0    , 1
                                                 , ximb.palette_max_cs_qty
                 )                             palette_max_cs_qty    -- �z��
          ,DECODE(ximb.palette_max_step_qty, NULL , 1
                                           , 0    , 1
                                                  , ximb.palette_max_step_qty
                 )                             palette_max_step_qty  -- �i��
    INTO   on_item_id
          ,ov_item_no
          ,ov_item_name
          ,on_num_of_case
          ,on_palette_max_cs_qty
          ,on_palette_max_step_qty
    FROM   ic_item_mst_b         iimb                                -- OPM�i�ڃ}�X�^
          ,xxcmn_item_mst_b      ximb                                -- OPM�i�ڃA�h�I���}�X�^
          ,mtl_system_items_b    msib                                -- DISC�i�ڃ}�X�^
    WHERE iimb.inactive_ind      = cn_iimb_status_active
      AND iimb.attribute18       = cv_shipping_enable
      AND ximb.item_id           = iimb.item_id
      AND ximb.obsolete_class    = cn_ximb_status_active
      AND id_target_date         BETWEEN NVL(ximb.start_date_active, id_target_date)
                                     AND NVL(ximb.end_date_active  , id_target_date)
      AND msib.segment1          = iimb.item_no
      AND msib.organization_id   = in_organization_id
      AND msib.inventory_item_id = in_inventory_item_id
    ;
--
    -- �{�Џ��i�敪���擾
    lt_prod_class := XXCOP_COMMON_PKG2.get_item_category_f(
                       cv_category_prod_class
                      ,on_item_id
                       );
    -- �{�Џ��i�敪���h�����N�ȊO�͑ΏۊO
    IF   ( lt_prod_class IS NULL )
      OR ( lt_prod_class <> cv_prod_class_drink )THEN
      --
      RAISE outside_scope_expt;
      --
    END IF;
    --
    -- ���i���i�敪���擾
    lt_article_class := XXCOP_COMMON_PKG2.get_item_category_f(
                         cv_category_article_class
                        ,on_item_id
                       );
    -- ���i���i�敪�����i�ȊO�͑ΏۊO
    IF   ( lt_article_class IS NULL )
      OR ( lt_article_class <> cv_article_class_product ) THEN
      --
      RAISE outside_scope_expt;
      --
    END IF;
    --
    --�i�ڋ敪���擾
    lt_item_category := XXCOP_COMMON_PKG2.get_item_category_f(
                          cv_category_item_class
                          ,on_item_id
                        );
    --�i�ڋ敪�����i�ȊO�͑ΏۊO(�i�ڋ敪�����o�^(NULL)�͑Ώ�)
    IF ( lt_item_category <> cv_item_class_product ) THEN
      --
      RAISE outside_scope_expt;
      --
    END IF;
    --
  EXCEPTION
    WHEN outside_scope_expt THEN
      ov_retcode := cv_status_warn;
      ov_errbuf  := NULL;
      ov_errmsg  := NULL;
    WHEN NO_DATA_FOUND THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := NULL;
      ov_errmsg  := NULL;
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg  := NULL;
  END get_item_info;
  --
  /**********************************************************************************
   * Procedure Name   : get_shipment_result
   * Description      : �o�׎��ю擾
   ***********************************************************************************/
  PROCEDURE get_shipment_result(
     in_deliver_from_id        IN     NUMBER      -- OPM�ۊǏꏊID
    ,in_item_id                IN     NUMBER      -- OPM�i��ID
    ,id_shipment_date_from     IN     DATE        -- �o�׎��ъ���FROM
    ,id_shipment_date_to       IN     DATE        -- �o�׎��ъ���TO
    ,iv_freshness_condition    IN     VARCHAR2    -- �N�x����
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_START
    ,in_inventory_item_id      IN     NUMBER      -- INV�i��ID
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_END
    ,on_shipped_quantity       OUT    NUMBER      -- �o�׎��ѐ�
    ,ov_errbuf                 OUT    VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode                OUT    VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg                 OUT    VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  ) IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'get_shipment_result'; -- �v���O������
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    --
    cv_order_category_order    CONSTANT VARCHAR2(5) := 'ORDER';  -- �󒍃^�C�v�FORDER
    cv_order_category_return   CONSTANT VARCHAR2(6) := 'RETURN'; -- �󒍃^�C�v�FRETURN
    cv_req_status_03           CONSTANT VARCHAR2(2) := '03';     -- �o�׈˗��X�e�[�^�X�F���ߍς�
    cv_req_status_04           CONSTANT VARCHAR2(2) := '04';     -- �o�׈˗��X�e�[�^�X�F�o�׎��ьv���
    cv_notif_status_40         CONSTANT VARCHAR2(2) := '40';     -- �ʒm�X�e�[�^�X�F�m��ʒm��
    cv_doc_type                CONSTANT VARCHAR2(2) := '10';     -- �����^�C�v�F�o��
    cv_rec_type_10             CONSTANT VARCHAR2(2) := '10';     -- ���R�[�h�^�C�v�F�w��
    cv_rec_type_20             CONSTANT VARCHAR2(2) := '20';     -- ���R�[�h�^�C�v�F�o�Ɏ���
    cv_shipping_shikyu_cls     CONSTANT VARCHAR2(1) := '1';      -- �o�׎x���敪�F�o�׈˗�
    cv_shipping_shikyu_cls_rtn CONSTANT VARCHAR2(1) := '3';      -- �o�׎x���敪�F�q�֕ԕi
    cv_adjs_class_1            CONSTANT VARCHAR2(1) := '1';      -- �݌ɒ����敪�F�݌ɒ����ȊO
    cv_adjs_class_2            CONSTANT VARCHAR2(1) := '2';      -- �݌ɒ����敪�F�݌ɒ���
    cv_yes                     CONSTANT VARCHAR2(1) := 'Y';      -- �Œ�l�FYES
    cv_no                      CONSTANT VARCHAR2(1) := 'N';      -- �Œ�l�FNO
    --
--
    -- *** ���[�J���ϐ� ***
    ln_critical_value           NUMBER;         -- ��l
    lv_expt_value               VARCHAR2(100);  -- ��O�p�����[�^
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    --��O��`
--
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
--
    --
    --  �o�׎��і��v��͏o�א�_����(RESULT_DELIVER_TO_ID)�A�o�ד�(shipped_date)��
    --  NULL�̂��߁A�o�א�ID(DELIVER_TO)�A�o�ח\���(SCHEDULE_SHIP_DATE)�ŏW�v����
    --  �N�x������NULL�͑S�Ă̑N�x�����̏o�׎��т��W�v����
    --
    --�o�׎��яW�v
    SELECT SUM(shipped_quantity)
    INTO   on_shipped_quantity
    FROM   (
            -- ���і��v��
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_START
            SELECT /*+ LEADING(otta) */
                   NVL(SUM(CASE
--            SELECT NVL(SUM(CASE
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_END
                             WHEN (xmld.order_category_code = cv_order_category_order) THEN
                               xmld.actual_quantity - xmld.before_actual_quantity
                             WHEN (xmld.order_category_code = cv_order_category_return) THEN
                              (xmld.actual_quantity - xmld.before_actual_quantity) * -1
                           END), 0) shipped_quantity
            FROM xxcmn_party_sites          xps
                ,(
                  SELECT NVL(oha.shipped_date, oha.schedule_ship_date)    shipped_date
                        ,NVL(oha.result_deliver_to_id, oha.deliver_to_id) deliver_to_id
                        ,otta.order_category_code                         order_category_code
                        ,NVL(mld.actual_quantity, 0)                      actual_quantity
                        ,NVL(mld.before_actual_quantity, 0)               before_actual_quantity
                  FROM
                     xxwsh_order_headers_all    oha
                    ,xxwsh_order_lines_all      ola
                    ,xxinv_mov_lot_details      mld
                    ,oe_transaction_types_all   otta
                  WHERE oha.deliver_from_id       = in_deliver_from_id
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_START
                    AND oha.req_status            = cv_req_status_03
--                    AND oha.req_status           IN (cv_req_status_03,cv_req_status_04)
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_END
                    AND oha.notif_status          = cv_notif_status_40
                    AND oha.latest_external_flag  = cv_yes
                    --
                    AND oha.actual_confirm_class  = cv_no
                    --
                    AND oha.order_header_id       = ola.order_header_id
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_START
                    AND ola.shipping_inventory_item_id = in_inventory_item_id
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_END
                    AND ola.delete_flag           = cv_no
                    AND ola.order_line_id         = mld.mov_line_id
                    AND mld.item_id               = in_item_id
                    AND mld.document_type_code    = cv_doc_type
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_START
                    AND mld.record_type_code      = cv_rec_type_10
--                    AND mld.record_type_code     IN (cv_rec_type_10,cv_rec_type_20)
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_END
                    AND otta.attribute1          IN (cv_shipping_shikyu_cls,cv_shipping_shikyu_cls_rtn)
                    AND NVL( otta.attribute4, cv_adjs_class_1 ) <> cv_adjs_class_2
                    AND otta.transaction_type_id  = oha.order_type_id
                    AND otta.org_id               = FND_PROFILE.VALUE('ORG_ID')
                 ) xmld
            WHERE xmld.shipped_date  BETWEEN id_shipment_date_from
                                         AND id_shipment_date_to
              AND xmld.deliver_to_id       = xps.party_site_id
              AND xmld.shipped_date  BETWEEN NVL( xps.start_date_active, xmld.shipped_date )
                                         AND NVL( xps.end_date_active  , xmld.shipped_date )
              AND xps.freshness_condition   LIKE NVL(iv_freshness_condition, '%')
            UNION ALL
            -- ���ьv���
            SELECT NVL(SUM(CASE
                             WHEN (xmld.order_category_code = cv_order_category_order) THEN
                               xmld.actual_quantity - xmld.before_actual_quantity
                             WHEN (xmld.order_category_code = cv_order_category_return) THEN
                              (xmld.actual_quantity - xmld.before_actual_quantity) * -1
                           END), 0) shipped_quantity
            FROM xxcmn_party_sites          xps
                ,(
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_START
                  SELECT /*+ LEADING(otta) */
                         NVL(oha.shipped_date, oha.schedule_ship_date)    shipped_date
--                  SELECT NVL(oha.shipped_date, oha.schedule_ship_date)    shipped_date
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_END
                        ,NVL(oha.result_deliver_to_id, oha.deliver_to_id) deliver_to_id
                        ,otta.order_category_code                         order_category_code
                        ,NVL(mld.actual_quantity, 0)                      actual_quantity
                        ,NVL(mld.before_actual_quantity, 0)               before_actual_quantity
                  FROM
                     xxwsh_order_headers_all    oha
                    ,xxwsh_order_lines_all      ola
                    ,xxinv_mov_lot_details      mld
                    ,oe_transaction_types_all   otta
                  WHERE oha.deliver_from_id       = in_deliver_from_id
                    AND oha.req_status            = cv_req_status_04
                    AND oha.notif_status          = cv_notif_status_40
                    AND oha.latest_external_flag  = cv_yes
                    --
--20091201_Ver2.3_I_E_479_020_SCS.Goto_DEL_START
--                    AND oha.actual_confirm_class  = cv_yes
--20091201_Ver2.3_I_E_479_020_SCS.Goto_DEL_START
                    --
                    AND oha.order_header_id       = ola.order_header_id
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_START
                    AND ola.shipping_inventory_item_id = in_inventory_item_id
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_END
                    AND ola.delete_flag           = cv_no
                    AND ola.order_line_id         = mld.mov_line_id
                    AND mld.item_id               = in_item_id
                    AND mld.document_type_code    = cv_doc_type
                    AND mld.record_type_code      = cv_rec_type_20
                    AND otta.attribute1          IN (cv_shipping_shikyu_cls,cv_shipping_shikyu_cls_rtn)
                    AND NVL( otta.attribute4, cv_adjs_class_1 ) <> cv_adjs_class_2
                    AND otta.transaction_type_id  = oha.order_type_id
                    AND otta.org_id               = FND_PROFILE.VALUE('ORG_ID')
                 ) xmld
            WHERE xmld.shipped_date  BETWEEN id_shipment_date_from
                                         AND id_shipment_date_to
              AND xmld.deliver_to_id       = xps.party_site_id
              AND xmld.shipped_date  BETWEEN NVL( xps.start_date_active, xmld.shipped_date )
                                         AND NVL( xps.end_date_active  , xmld.shipped_date )
              AND xps.freshness_condition   LIKE NVL(iv_freshness_condition, '%')
           );
  --
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode   := cv_status_warn;
      ov_errbuf    := NULL;
      ov_errmsg    := NULL;
    WHEN OTHERS THEN
      ov_retcode   := cv_status_error;
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg    := NULL;
  --
  END get_shipment_result;
  --
  /**********************************************************************************
   * Procedure Name   : get_num_of_shipped
   * Description      : �N�x�����ʏo�׎��ю擾
   ***********************************************************************************/
  PROCEDURE get_num_of_shipped(
     in_deliver_from_id        IN  NUMBER      -- OPM�ۊǏꏊID
    ,in_item_id                IN  NUMBER      -- OPM�i��ID
    ,id_shipment_date_from     IN  DATE        -- �o�׎��ъ���FROM
    ,id_shipment_date_to       IN  DATE        -- �o�׎��ъ���TO
    ,iv_freshness_condition    IN  VARCHAR2    -- �N�x����
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_START
    ,in_inventory_item_id      IN  NUMBER      -- INV�i��ID
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_END
    ,on_shipped_quantity       OUT NUMBER      -- �o�׎��ѐ�
    ,ov_errbuf                 OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode                OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg                 OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  ) IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'get_num_of_shipped'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_dummy_frequent_whse     CONSTANT VARCHAR2(100) := 'XXCMN_DUMMY_FREQUENT_WHSE';  -- �_�~�[��\�q�Ƀv���t�@�C��
--
    -- *** ���[�J���ϐ� ***
    lv_errbuf                  VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    lt_frq_loct_code           mtl_item_locations.segment1%TYPE;               -- �_�~�[��\�q��
    lt_whse_code               mtl_item_locations.segment1%type;               -- �ۊǏꏊ�R�[�h
    lt_rep_whse_code           mtl_item_locations.segment1%type;               -- ��\�q�ɃR�[�h
    lt_rep_whse_id             mtl_item_locations.inventory_location_id%type;  -- ��\�q��ID
    ln_shipped_quantity        NUMBER DEFAULT 0;                               -- �o�׎��ѐ�(���q��)
    ln_shipped_quantity_rep    NUMBER DEFAULT 0;                               -- �o�׎��ѐ�(��\�q��)
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    --��O��`
    profile_exp               EXCEPTION;     -- �v���t�@�C���擾���s
    api_expt                  EXCEPTION;     -- ���ʊ֐���O
--
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
    -- �_�~�[��\�q�ɂ��擾
    lt_frq_loct_code := FND_PROFILE.VALUE(cv_dummy_frequent_whse);
    -- �擾�Ɏ��s�����ꍇ
    IF (lt_frq_loct_code IS NULL) THEN
      RAISE profile_exp;
    END IF ;
    --
    -- ���q�ɒP�Əo�׎��ю擾
    XXCOP_COMMON_PKG2.get_shipment_result(
      in_deliver_from_id      => in_deliver_from_id      -- OPM�ۊǏꏊID
     ,in_item_id              => in_item_id              -- OPM�i��ID
     ,id_shipment_date_from   => id_shipment_date_from   -- �o�׎��ъ���FROM
     ,id_shipment_date_to     => id_shipment_date_to     -- �o�׎��ъ���TO
     ,iv_freshness_condition  => iv_freshness_condition  -- �N�x����
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_START
     ,in_inventory_item_id    => in_inventory_item_id    -- INV�i��ID
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_END
     ,on_shipped_quantity     => ln_shipped_quantity     -- �o�׎��ѐ�
     ,ov_errbuf               => lv_errbuf               -- �G���[�E���b�Z�[�W
     ,ov_retcode              => lv_retcode              -- ���^�[���E�R�[�h
     ,ov_errmsg               => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
  --
    IF (lv_retcode = cv_status_error) THEN
      RAISE api_expt;
    END IF;
--
    -- ��\�q�Ɏ擾
    BEGIN
      SELECT mil1.segment1              whse_code       -- �ۊǏꏊ�R�[�h
            ,mil1.attribute5            rep_whse_code   -- ��\�q�ɃR�[�h
            ,mil2.inventory_location_id rep_whse_id     -- ��\�q��ID
      INTO   lt_whse_code
            ,lt_rep_whse_code
            ,lt_rep_whse_id
      FROM   mtl_item_locations         mil1            -- OPM�ۊǏꏊ(�ʏ�q��)
            ,mtl_item_locations         mil2            -- OPM�ۊǏꏊ(��\�q��)
      WHERE  mil1.attribute5            = mil2.segment1(+)
      AND    mil1.inventory_location_id = in_deliver_from_id
      ORDER BY mil1.segment1
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE NO_DATA_FOUND;
    END;
    --
    -- ��\�q�ɂ����q�ɂƓ���A�܂���NULL�̏ꍇ
    IF (  ( lt_whse_code     = lt_rep_whse_code ) 
       OR ( lt_rep_whse_code IS NULL            ) ) THEN
      -- ���q�ɂ���\�q�ɂƂȂ�̂ŏo�׎��ѐ�(��\�q��)��0��ݒ�
      ln_shipped_quantity_rep := 0;
      --
    ELSE
      -- ��\�q�ɂ�ZZZZ�̏ꍇ
      IF ( lt_rep_whse_code = lt_frq_loct_code ) THEN
        -- �q�ɕi�ڃA�h�I���}�X�^����\�q�Ɏ擾
        BEGIN
          SELECT frq_item_location_code   rep_whse_code  -- ��\�q�ɃR�[�h
                ,frq_item_location_id     rep_whse_id    -- ��\�q��ID
          INTO   lt_rep_whse_code
                ,lt_rep_whse_id
          FROM   xxwsh_frq_item_locations xfil           -- �q�ɕi�ڃA�h�I���}�X�^
          WHERE  xfil.item_location_id = in_deliver_from_id
          AND    xfil.item_id          = in_item_id
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- �i�ڕʑ�\�q�ɂ��擾�ł��Ȃ������ꍇ�͎��q�ɂ�
            -- ��\�q�ɂƂȂ�̂łŏo�׎��ѐ�(��\�q��)��0��ݒ�
            ln_shipped_quantity_rep := 0;
            --
        END;
      END IF;
      --
      -- �擾�����i�ڕʑ�\�q�ɂ̏o�׎��ю擾
      XXCOP_COMMON_PKG2.get_shipment_result(
        in_deliver_from_id      => lt_rep_whse_id          -- OPM�ۊǏꏊID
       ,in_item_id              => in_item_id              -- OPM�i��ID
       ,id_shipment_date_from   => id_shipment_date_from   -- �o�׎��ъ���FROM
       ,id_shipment_date_to     => id_shipment_date_to     -- �o�׎��ъ���TO
       ,iv_freshness_condition  => iv_freshness_condition  -- �N�x����
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_START
       ,in_inventory_item_id    => in_inventory_item_id    -- INV�i��ID
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_END
       ,on_shipped_quantity     => ln_shipped_quantity_rep -- �o�׎��ѐ�
       ,ov_errbuf               => lv_errbuf               -- �G���[�E���b�Z�[�W
       ,ov_retcode              => lv_retcode              -- ���^�[���E�R�[�h
       ,ov_errmsg               => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE api_expt;
      END IF;
      --
    END IF;
    --
    -- ���q�ɂƑ�\�q�ɂ̏o�׎��т����v
    on_shipped_quantity := ln_shipped_quantity + ln_shipped_quantity_rep;
    --
  EXCEPTION
    WHEN api_expt THEN
      ov_retcode          := cv_status_error;
      ov_errbuf           := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part|| lv_errbuf,1,5000);
      ov_errmsg           := lv_errmsg;
      on_shipped_quantity := 0;
    WHEN profile_exp THEN
      ov_retcode          := cv_status_error;
      ov_errbuf           := NULL;
      ov_errmsg           := NULL;
      on_shipped_quantity := 0;
    WHEN NO_DATA_FOUND THEN
      ov_retcode          := cv_status_warn;
      ov_errbuf           := NULL;
      ov_errmsg           := NULL;
      on_shipped_quantity := 0;
    WHEN OTHERS THEN
      ov_retcode          := cv_status_error;
      ov_errbuf           := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg           := NULL;
      on_shipped_quantity := 0;
  --
  END get_num_of_shipped;
  --
  /**********************************************************************************
   * Procedure Name   : get_num_of_forecast
   * Description      : �o�ח\���擾����
   ***********************************************************************************/
  PROCEDURE get_num_of_forecast(
    in_organization_id   IN  NUMBER       -- �݌ɑg�DID
   ,in_inventory_item_id IN  NUMBER       -- �݌ɕi��ID
   ,id_plan_date_from    IN  DATE         -- �o�ח\���擾����FROM
   ,id_plan_date_to      IN  DATE         -- �o�ח\���擾����TO
   ,in_loct_id           IN  NUMBER       -- OPM�ۊǏꏊID
   ,on_quantity          OUT  NUMBER      -- �o�ח\������
   ,ov_errbuf            OUT  VARCHAR2    -- �G���[�E���b�Z�[�W
   ,ov_retcode           OUT  VARCHAR2    -- ���^�[���E�R�[�h
   ,ov_errmsg            OUT  VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_num_of_forecast'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���萔 ***
    cv_dummy_frequent_whse    CONSTANT VARCHAR2(100) := 'XXCMN_DUMMY_FREQUENT_WHSE';  -- �_�~�[��\�q�Ƀv���t�@�C��
    --
    cn_del_mark_n             CONSTANT NUMBER        := 0;   -- �L��
    cv_ship_plan_type         CONSTANT VARCHAR2(1)   := '1'; -- ��v�敪�ށi�o�ח\���j
    cn_schedule_level         CONSTANT NUMBER        := 2;   -- ��v�惌�x���i���x���Q�j
    --
--
    -- *** ���[�J���ϐ� ***
    lt_frq_loct_code           mtl_item_locations.segment1%TYPE;               -- �_�~�[��\�q��
    lt_whse_code               mtl_item_locations.segment1%type;               -- �ۊǏꏊ�R�[�h
    lt_rep_whse_code           mtl_item_locations.segment1%type;               -- ��\�q�ɃR�[�h
    lt_rep_whse_id             mtl_item_locations.inventory_location_id%type;  -- ��\�q��ID
    lt_rep_org_id              mtl_item_locations.organization_id%type;        -- ��\�q�ɑg�DID
    ln_schedule_quantity       NUMBER DEFAULT 0;                               -- �o�׎��ѐ�(���q��)
    ln_schedule_quantity_rep   NUMBER DEFAULT 0;                               -- �o�׎��ѐ�(��\�q��)
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    --��O��`
    profile_exp               EXCEPTION;     -- �v���t�@�C���擾���s
--
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
    --
    -- �_�~�[��\�q�ɂ��擾
    lt_frq_loct_code := FND_PROFILE.VALUE(cv_dummy_frequent_whse);
    -- �擾�Ɏ��s�����ꍇ
    IF (lt_frq_loct_code IS NULL) THEN
      RAISE profile_exp;
    END IF ;
    --
     --==============================================================
    --���q�ɒP�Əo�ח\���擾
    --==============================================================
    SELECT NVL(SUM(msdd.schedule_quantity),0) stock_qty
    INTO   ln_schedule_quantity
    FROM   mrp_schedule_dates       msdd
          ,mrp_schedule_designators msdh
    WHERE  msdh.schedule_designator = msdd.schedule_designator
    AND    msdh.organization_id     = in_organization_id
    AND    msdh.organization_id     = msdd.organization_id
    AND    msdh.attribute1          = cv_ship_plan_type
    AND    msdd.schedule_date BETWEEN id_plan_date_from
                                  AND id_plan_date_to
    AND    msdd.inventory_item_id   = in_inventory_item_id
    AND    msdd.schedule_level      = cn_schedule_level
    ;
    --
    -- ��\�q�Ɏ擾
    BEGIN
      SELECT mil1.segment1              whse_code       -- �ۊǏꏊ�R�[�h
            ,mil1.attribute5            rep_whse_code   -- ��\�q�ɃR�[�h
            ,mil2.inventory_location_id rep_whse_id     -- ��\�q��ID
            ,mil2.organization_id       rep_org_id      -- ��\�q�ɑg�DID
      INTO   lt_whse_code
            ,lt_rep_whse_code
            ,lt_rep_whse_id
            ,lt_rep_org_id
      FROM   mtl_item_locations         mil1            -- OPM�ۊǏꏊ(�ʏ�q��)
            ,mtl_item_locations         mil2            -- OPM�ۊǏꏊ(��\�q��)
      WHERE  mil1.attribute5            = mil2.segment1(+)
      AND    mil1.organization_id       = in_organization_id
      AND    mil1.inventory_location_id = in_loct_id
      ORDER BY mil1.segment1
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE NO_DATA_FOUND;
    END;
    --
    -- ��\�q�ɂ����q�ɂƓ���A�܂���NULL�܂��͓���g�D�̏ꍇ
    IF (  ( lt_whse_code     = lt_rep_whse_code   )
       OR ( lt_rep_whse_code IS NULL              )
       OR ( lt_rep_org_id    = in_organization_id ) ) THEN
      -- ���q�ɂ���\�q�ɂƂȂ�̂ŏo�׎��ѐ�(��\�q��)��0��ݒ�
      ln_schedule_quantity_rep := 0;
      --
    ELSE
      -- ��\�q�ɂ�ZZZZ�̏ꍇ
      IF ( lt_rep_whse_code = lt_frq_loct_code ) THEN
        -- �q�ɕi�ڃA�h�I���}�X�^����\�q�Ɏ擾
        BEGIN
          SELECT frq_item_location_code   rep_whse_code  -- ��\�q�ɃR�[�h
                ,frq_item_location_id     rep_whse_id    -- ��\�q��ID
                ,mil.organization_id      rep_org_id     -- ��\�q�ɑg�DID
          INTO   lt_rep_whse_code
                ,lt_rep_whse_id
                ,lt_rep_org_id
          FROM   xxwsh_frq_item_locations xfil           -- �q�ɕi�ڃA�h�I���}�X�^
                ,mtl_item_locations       mil            -- OPM�ۊǏꏊ�}�X�^
          WHERE  xfil.frq_item_location_id = mil.inventory_location_id
          AND    xfil.item_location_id     = in_loct_id
          AND    xfil.item_id              = in_inventory_item_id
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- �i�ڕʑ�\�q�ɂ��擾�ł��Ȃ������ꍇ�͎��q�ɂ�
            -- ��\�q�ɂƂȂ�̂łŏo�׎��ѐ�(��\�q��)��0��ݒ�
            ln_schedule_quantity_rep := 0;
            --
        END;
      END IF;
      --
      -- �擾�����i�ڕʑ�\�q�ɂ̏o�׎��ю擾
      SELECT NVL(SUM(msdd.schedule_quantity),0) stock_qty
      INTO   ln_schedule_quantity_rep
      FROM   mrp_schedule_dates       msdd
            ,mrp_schedule_designators msdh
      WHERE  msdh.schedule_designator = msdd.schedule_designator
      AND    msdh.organization_id     = lt_rep_org_id
      AND    msdh.organization_id     = msdd.organization_id
      AND    msdh.attribute1          = cv_ship_plan_type
      AND    msdd.schedule_date BETWEEN id_plan_date_from
                                    AND id_plan_date_to
      AND    msdd.inventory_item_id   = in_inventory_item_id
      AND    msdd.schedule_level      = cn_schedule_level
      ;
      --
    END IF;
    --
    -- ���q�ɂƑ�\�q�ɂ̏o�׎��т����v
    on_quantity := ln_schedule_quantity + ln_schedule_quantity_rep;
    --
  EXCEPTION
    WHEN profile_exp THEN
      ov_retcode          := cv_status_error;
      ov_errbuf           := NULL;
      ov_errmsg           := NULL;
      on_quantity := 0;
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_quantity      := cn_zero;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_quantity      := NULL;
  END get_num_of_forecast;
  --
  /**********************************************************************************
   * Procedure Name   : get_stock_plan
   * Description      : ���ɗ\��擾����
   ***********************************************************************************/
  PROCEDURE get_stock_plan(
    in_loct_id           IN   NUMBER       -- �ۊǏꏊID
   ,in_item_id           IN   NUMBER       -- �i��ID
   ,id_plan_date_from    IN   DATE         -- �v�����From
   ,id_plan_date_to      IN   DATE         -- �v�����To
   ,on_quantity          OUT  NUMBER       -- �v�搔
   ,ov_errbuf            OUT  VARCHAR2     -- �G���[�E���b�Z�[�W          
   ,ov_retcode           OUT  VARCHAR2     -- ���^�[���E�R�[�h            
   ,ov_errmsg            OUT  VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_stock_plan'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_dummy_frequent_whse     CONSTANT VARCHAR2(100) := 'XXCMN_DUMMY_FREQUENT_WHSE';  -- �_�~�[��\�q�Ƀv���t�@�C��
--
    -- *** ���[�J���ϐ� ***
    lt_frq_loct_code           mtl_item_locations.segment1%TYPE;  -- �_�~�[��\�q��
    lt_whse_code               mtl_item_locations.segment1%type;  -- �ۊǏꏊ�R�[�h
    lt_rep_whse_code           mtl_item_locations.segment1%type;  -- ��\�q�ɃR�[�h
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    --��O��`
    profile_exp               EXCEPTION;     -- �v���t�@�C���擾���s
--
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
    --
    -- �_�~�[��\�q�ɂ��擾
    lt_frq_loct_code := FND_PROFILE.VALUE(cv_dummy_frequent_whse);
    -- �擾�Ɏ��s�����ꍇ
    IF (lt_frq_loct_code IS NULL) THEN
      RAISE profile_exp;
    END IF;
    --
    -- ��\�q�ɂ��擾
    SELECT mil.segment1    whse_code      -- �ۊǏꏊ�R�[�h
          ,mil.attribute5  rep_whse_code  -- ��\�q�ɃR�[�h
    INTO   lt_whse_code
          ,lt_rep_whse_code
    FROM   mtl_item_locations mil         -- OPM�ۊǏꏊ
    WHERE  mil.inventory_location_id = in_loct_id
    ;
    --==============================================================
    --���ɗ\��擾����
    --==============================================================
    -- ��\�q�ɂ����q�ɂƓ���̏ꍇ
    IF ( lt_whse_code = lt_rep_whse_code ) THEN
      SELECT NVL(SUM(TRUNC(xliv.loct_onhand)), 0) supplies_quantity
      INTO   on_quantity
      FROM   (
        SELECT xliv.lot_id                                lot_id
              ,xliv.lot_no                                lot_no
              ,xliv.manufacture_date                      manufacture_date
              ,xliv.expiration_date                       expiration_date
              ,xliv.unique_sign                           unique_sign
              ,xliv.lot_status                            lot_status
              ,CASE 
                 WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                   THEN SUM(xliv.unlimited_loct_onhand)
                 ELSE SUM(xliv.limited_loct_onhand)
               END loct_onhand
        FROM   ( 
          SELECT xliv.lot_id            lot_id
                ,xliv.lot_no            lot_no
                ,xliv.manufacture_date  manufacture_date
                ,xliv.expiration_date   expiration_date
                ,xliv.unique_sign        unique_sign
                ,xliv.lot_status        lot_status
                ,xliv.loct_onhand       unlimited_loct_onhand
                ,CASE 
                   WHEN xliv.schedule_date <= id_plan_date_to
                     THEN xliv.loct_onhand
                   ELSE 0
                 END limited_loct_onhand
          FROM   xxcop_loct_inv_v xliv  -- �莝�݌Ƀr���[
          WHERE  (   xliv.schedule_date >  id_plan_date_from
                 AND xliv.schedule_date <= id_plan_date_to   )
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_START
          AND EXISTS (
                   SELECT mil.segment1
                   FROM   mtl_item_locations mil  -- OPM�ۊǏꏊ
                   WHERE  mil.attribute5 = lt_rep_whse_code
                   AND    mil.segment1 = xliv.loct_code
                   UNION ALL
                   SELECT xfil.item_location_code
                   FROM   xxwsh_frq_item_locations xfil  -- �q�ɕi�ڃA�h�I��
                   WHERE  xfil.frq_item_location_code = lt_rep_whse_code
                   AND    xfil.item_id                = in_item_id
                   AND    xfil.item_location_code     = xliv.loct_code
          )
--          AND    xliv.loct_code IN (
--                   SELECT mil.segment1
--                   FROM   mtl_item_locations mil  -- OPM�ۊǏꏊ
--                   WHERE  mil.attribute5 = lt_rep_whse_code
--                   UNION
--                   SELECT xfil.item_location_code
--                   FROM   xxwsh_frq_item_locations xfil  -- �q�ɕi�ڃA�h�I��
--                   WHERE  xfil.frq_item_location_code = lt_rep_whse_code
--                   AND    xfil.item_id                = in_item_id
--                   )
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_END
          AND    xliv.item_id        = in_item_id
          ) xliv
        GROUP BY xliv.lot_id
                ,xliv.lot_no
                ,xliv.manufacture_date
                ,xliv.expiration_date
                ,xliv.unique_sign
                ,xliv.lot_status
        )xliv
      ;
      -- ����Ɏ擾�ł����ꍇ�͏������I��
      RETURN;
      --
    ELSE
      -- ���q�ɂ��z���q�ɂ̏ꍇ
      -- ��\�q�ɂ��_�~�[��\�q�ɂ̏ꍇ
      IF ( lt_rep_whse_code = lt_frq_loct_code ) THEN
        -- �q�ɕi�ڃA�h�I�����Q�Ƃ���\�q�ɂ��擾
        -- ���̎莝�݌ɐ���0�����̏ꍇ�͎��q�Ɏ莝�݌ɂ�茸�Z
        SELECT NVL(SUM(TRUNC(xliv.loct_onhand)), 0) supplies_quantity
        INTO   on_quantity
        FROM   (
          SELECT xliv.lot_id                   lot_id
                ,xliv.lot_no                   lot_no
                ,xliv.manufacture_date         manufacture_date
                ,xliv.expiration_date          expiration_date
                ,xliv.unique_sign              unique_sign
                ,xliv.lot_status               lot_status
                ,CASE
                   WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                     THEN SUM(xliv.unlimited_loct_onhand)
                   ELSE SUM(xliv.limited_loct_onhand)
                 END                           loct_onhand
          FROM ( 
            SELECT xliv.lot_id            lot_id
                  ,xliv.lot_no            lot_no
                  ,xliv.manufacture_date  manufacture_date
                  ,xliv.expiration_date   expiration_date
                  ,xliv.unique_sign       unique_sign
                  ,xliv.lot_status        lot_status
                  ,xliv.loct_onhand       unlimited_loct_onhand
                  ,CASE 
                     WHEN xliv.schedule_date <= id_plan_date_to
                       THEN xliv.loct_onhand
                     ELSE 0
                   END                    limited_loct_onhand
            FROM   xxcop_loct_inv_v         xliv
            WHERE  xliv.item_id        = in_item_id
            AND    (   xliv.schedule_date >  id_plan_date_from
                   AND xliv.schedule_date <= id_plan_date_to   )
            AND    xliv.loct_code      = lt_whse_code
            --
            UNION ALL
            SELECT xliv.lot_id                 lot_id
                  ,xliv.lot_no                 lot_no
                  ,xliv.manufacture_date       manufacture_date
                  ,xliv.expiration_date        expiration_date
                  ,xliv.unique_sign            unique_sign
                  ,xliv.lot_status             lot_status
                  ,LEAST(xliv.loct_onhand, 0)  unlimited_loct_onhand
                  ,CASE 
                     WHEN xliv.schedule_date <= id_plan_date_to
                       THEN LEAST(xliv.loct_onhand, 0)
                     ELSE 0
                   END                         limited_loct_onhand
            FROM   (
              SELECT xliv.lot_id            lot_id
                    ,xliv.lot_no            lot_no
                    ,xliv.manufacture_date  manufacture_date
                    ,xliv.expiration_date   expiration_date
                    ,xliv.unique_sign       unique_sign
                    ,xliv.lot_status        lot_status
                    ,xliv.schedule_date     schedule_date
                    ,SUM(xliv.loct_onhand)  loct_onhand
              FROM   xxcop_loct_inv_v              xliv
              WHERE  xliv.item_id            = in_item_id
              AND    (   xliv.schedule_date >  id_plan_date_from
                     AND xliv.schedule_date <= id_plan_date_to   )
              AND    xliv.loct_code IN ( 
                       SELECT xfil.frq_item_location_code    -- ��\�q��
                       FROM   xxwsh_frq_item_locations xfil  -- �q�ɕi�ڃA�h�I��
                       WHERE  xfil.item_location_code = lt_whse_code
                       AND    xfil.item_id            = in_item_id
                       )
              GROUP BY xliv.lot_id
                      ,xliv.lot_no
                      ,xliv.manufacture_date
                      ,xliv.expiration_date
                      ,xliv.unique_sign
                      ,xliv.lot_status
                      ,xliv.schedule_date
              ) xliv
            )xliv
          GROUP BY xliv.lot_id
                  ,xliv.lot_no
                  ,xliv.manufacture_date
                  ,xliv.expiration_date
                  ,xliv.unique_sign
                  ,xliv.lot_status
          ) xliv
        ;
        --
      -- ��\�q�ɐݒ肪���ݒ�(NULL)�̏ꍇ
      ELSIF ( lt_rep_whse_code IS NULL ) THEN
        -- ���q�ɒP�Ƃ̍݌ɐ��ʎ擾
        SELECT NVL(SUM(TRUNC(xliv.loct_onhand)), 0) supplies_quantity
        INTO   on_quantity
        FROM   (
          SELECT xliv.lot_id              lot_id
                ,xliv.lot_no              lot_no
                ,xliv.manufacture_date    manufacture_date
                ,xliv.expiration_date     expiration_date
                ,xliv.unique_sign         unique_sign
                ,xliv.lot_status          lot_status
                ,CASE 
                   WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                     THEN SUM(xliv.unlimited_loct_onhand)
                   ELSE SUM(xliv.limited_loct_onhand)
                 END                      loct_onhand
          FROM ( 
            SELECT xliv.lot_id            lot_id
                  ,xliv.lot_no            lot_no
                  ,xliv.manufacture_date  manufacture_date
                  ,xliv.expiration_date   expiration_date
                  ,xliv.unique_sign        unique_sign
                  ,xliv.lot_status        lot_status
                  ,xliv.loct_onhand       unlimited_loct_onhand
                  ,CASE 
                     WHEN xliv.schedule_date <= id_plan_date_to
                       THEN xliv.loct_onhand
                     ELSE 0
                   END                    limited_loct_onhand
            FROM   xxcop_loct_inv_v         xliv
            WHERE  xliv.item_id        = in_item_id
            AND    (   xliv.schedule_date >  id_plan_date_from
                   AND xliv.schedule_date <= id_plan_date_to   )
            AND    xliv.loct_code      = lt_whse_code
            ) xliv
          GROUP BY xliv.lot_id
                  ,xliv.lot_no
                  ,xliv.manufacture_date
                  ,xliv.expiration_date
                  ,xliv.unique_sign
                  ,xliv.lot_status
          ) xliv
        ;
        --
      ELSE
        -- ��\�q�ɂɎ��q�ɈȊO�̑q�ɂ̐ݒ肪����ꍇ
        SELECT NVL(SUM(TRUNC(xliv.loct_onhand)), 0) supplies_quantity
        INTO   on_quantity
        FROM   (
          SELECT xliv.lot_id              lot_id
                ,xliv.lot_no              lot_no
                ,xliv.manufacture_date    manufacture_date
                ,xliv.expiration_date     expiration_date
                 ,xliv.unique_sign        unique_sign
                ,xliv.lot_status          lot_status
                ,CASE 
                   WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                     THEN SUM(xliv.unlimited_loct_onhand)
                   ELSE SUM(xliv.limited_loct_onhand)
                 END                      loct_onhand
          FROM ( 
            SELECT xliv.lot_id            lot_id
                  ,xliv.lot_no            lot_no
                  ,xliv.manufacture_date  manufacture_date
                  ,xliv.expiration_date   expiration_date
                  ,xliv.unique_sign        unique_sign
                  ,xliv.lot_status        lot_status
                  ,xliv.loct_onhand       unlimited_loct_onhand
                  ,CASE 
                     WHEN xliv.schedule_date <= id_plan_date_to
                       THEN xliv.loct_onhand
                     ELSE 0
                   END                    limited_loct_onhand
            FROM   xxcop_loct_inv_v         xliv
            WHERE  xliv.item_id        = in_item_id
            AND    (   xliv.schedule_date >  id_plan_date_from
                   AND xliv.schedule_date <= id_plan_date_to   )
            AND    xliv.loct_code      = lt_whse_code
             --
            UNION ALL
            SELECT xliv.lot_id                 lot_id
                  ,xliv.lot_no                 lot_no
                  ,xliv.manufacture_date       manufacture_date
                  ,xliv.expiration_date        expiration_date
                  ,xliv.unique_sign            unique_sign
                  ,xliv.lot_status             lot_status
                  ,LEAST(xliv.loct_onhand, 0)  unlimited_loct_onhand
                  ,CASE 
                     WHEN xliv.schedule_date <= id_plan_date_to
                       THEN LEAST(xliv.loct_onhand, 0)
                     ELSE 0
                   END                         limited_loct_onhand
            FROM   (
              SELECT xliv.lot_id                               lot_id
                    ,xliv.lot_no                               lot_no
                    ,xliv.manufacture_date                     manufacture_date
                    ,xliv.expiration_date                      expiration_date
                    ,xliv.unique_sign                          unique_sign
                    ,xliv.lot_status                           lot_status
                    ,xliv.schedule_date                        schedule_date
                    ,SUM(xliv.loct_onhand)                     loct_onhand
              FROM   xxcop_loct_inv_v          xliv
              WHERE  xliv.item_id        = in_item_id
              AND    (   xliv.schedule_date >  id_plan_date_from
                     AND xliv.schedule_date <= id_plan_date_to   )
              AND    xliv.loct_code      = lt_rep_whse_code
              GROUP BY xliv.lot_id
                  ,xliv.lot_no
                  ,xliv.manufacture_date
                  ,xliv.expiration_date
                  ,xliv.unique_sign
                  ,xliv.lot_status
                  ,xliv.schedule_date
              ) xliv
            ) xliv
          GROUP BY xliv.lot_id
                  ,xliv.lot_no
                  ,xliv.manufacture_date
                  ,xliv.expiration_date
                  ,xliv.unique_sign
                  ,xliv.lot_status
          ) xliv
        ;
        --
      END IF;
      --
    END IF;
    --
  EXCEPTION
    WHEN profile_exp THEN
      ov_retcode          := cv_status_error;
      ov_errbuf           := NULL;
      ov_errmsg           := NULL;
      on_quantity := 0;
      --
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_quantity      := NULL;
  END get_stock_plan;
  --
  /**********************************************************************************
   * Procedure Name   : get_onhand_qty
   * Description      : �莝�݌Ɏ擾����
   ***********************************************************************************/
  PROCEDURE get_onhand_qty(
    in_loct_id           IN   NUMBER       -- �ۊǏꏊID
   ,in_item_id           IN   NUMBER       -- �i��ID
   ,id_target_date       IN   DATE         -- �Ώۓ��t
   ,id_allocated_date    IN   DATE         -- �����ϓ�
   ,on_quantity          OUT  NUMBER       -- �莝�݌ɐ���
   ,ov_errbuf            OUT  VARCHAR2     -- �G���[�E���b�Z�[�W          
   ,ov_retcode           OUT  VARCHAR2     -- ���^�[���E�R�[�h            
   ,ov_errmsg            OUT  VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_onhand_qty'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_dummy_frequent_whse     CONSTANT VARCHAR2(100) := 'XXCMN_DUMMY_FREQUENT_WHSE';  -- �_�~�[��\�q�Ƀv���t�@�C��
--
    -- *** ���[�J���ϐ� ***
    lt_frq_loct_code           mtl_item_locations.segment1%TYPE;  -- �_�~�[��\�q��
    lt_whse_code               mtl_item_locations.segment1%type;  -- �ۊǏꏊ�R�[�h
    lt_rep_whse_code           mtl_item_locations.segment1%type;  -- ��\�q�ɃR�[�h
    --
    ln_onhand_qty              NUMBER;                            -- �莝�݌ɐ���(���q�ɒP��)
    ln_rep_onhand_qty          NUMBER;                            -- �莝�݌ɐ���(��\�q�ɒP��)
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    --��O��`
    profile_exp               EXCEPTION;     -- �v���t�@�C���擾���s
--
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
    --
    -- �_�~�[��\�q�ɂ��擾
    lt_frq_loct_code := FND_PROFILE.VALUE(cv_dummy_frequent_whse);
    -- �擾�Ɏ��s�����ꍇ
    IF (lt_frq_loct_code IS NULL) THEN
      RAISE profile_exp;
    END IF ;
    --
    -- ��\�q�ɂ��擾
    SELECT mil.segment1    whse_code      -- �ۊǏꏊ�R�[�h
          ,mil.attribute5  rep_whse_code  -- ��\�q�ɃR�[�h
    INTO   lt_whse_code
          ,lt_rep_whse_code
    FROM   mtl_item_locations mil         -- OPM�ۊǏꏊ
    WHERE  mil.inventory_location_id = in_loct_id
    ;
    --
    --==============================================================
    --�莝�݌Ɏ擾
    --==============================================================
    -- ��\�q�ɂ����q�ɂƓ���̏ꍇ
    IF( lt_whse_code = lt_rep_whse_code ) THEN
      -- ��\�q�ɂ��L�[�Ɏ莝�݌ɐ����W�v(���q��+�z���q��)
      SELECT NVL(SUM(xliv.loct_onhand), 0) supplies_quantity
      INTO   on_quantity
      FROM   (
        SELECT xliv.lot_id                                lot_id
              ,xliv.lot_no                                lot_no
              ,xliv.manufacture_date                      manufacture_date
              ,xliv.expiration_date                       expiration_date
              ,xliv.unique_sign                           unique_sign
              ,xliv.lot_status                            lot_status
              ,CASE 
                 WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                   THEN SUM(xliv.unlimited_loct_onhand)
                 ELSE SUM(xliv.limited_loct_onhand)
               END loct_onhand
        FROM   ( 
          SELECT xliv.lot_id            lot_id
                ,xliv.lot_no            lot_no
                ,xliv.manufacture_date  manufacture_date
                ,xliv.expiration_date   expiration_date
                ,xliv.unique_sign        unique_sign
                ,xliv.lot_status        lot_status
                ,xliv.loct_onhand       unlimited_loct_onhand
                ,CASE 
                   WHEN xliv.schedule_date <= id_target_date
                     THEN xliv.loct_onhand
                   ELSE 0
                 END limited_loct_onhand
          FROM   xxcop_loct_inv_v xliv  -- �莝�݌Ƀr���[
          WHERE  xliv.shipment_date <= id_allocated_date
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_START
          AND EXISTS (
                   SELECT mil.segment1
                   FROM   mtl_item_locations mil  -- OPM�ۊǏꏊ
                   WHERE  mil.attribute5 = lt_rep_whse_code
                   AND    mil.segment1 = xliv.loct_code
                   UNION ALL
                   SELECT xfil.item_location_code
                   FROM   xxwsh_frq_item_locations xfil  -- �q�ɕi�ڃA�h�I��
                   WHERE  xfil.frq_item_location_code = lt_rep_whse_code
                   AND    xfil.item_id                = in_item_id
                   AND    xfil.item_location_code     = xliv.loct_code
          )
--          AND    xliv.loct_code IN (
--                   SELECT mil.segment1
--                   FROM   mtl_item_locations mil  -- OPM�ۊǏꏊ
--                   WHERE  mil.attribute5 = lt_rep_whse_code
--                   UNION
--                   SELECT xfil.item_location_code
--                   FROM   xxwsh_frq_item_locations xfil  -- �q�ɕi�ڃA�h�I��
--                   WHERE  xfil.frq_item_location_code = lt_rep_whse_code
--                   AND    xfil.item_id                = in_item_id
--                   )
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_END
          AND    xliv.item_id        = in_item_id
          ) xliv
        GROUP BY xliv.lot_id
                ,xliv.lot_no
                ,xliv.manufacture_date
                ,xliv.expiration_date
                ,xliv.unique_sign
                ,xliv.lot_status
        )xliv
      ;
      -- ����Ɏ擾�ł����ꍇ�͏������I��
      RETURN;
      --
    ELSE
      -- �z���q�ɂ̎莝�݌ɐ��ʎZ�o
      -- ��\�q�ɂ��_�~�[��\�q�ɂ̏ꍇ
      IF (lt_rep_whse_code = lt_frq_loct_code ) THEN
        -- �q�ɕi�ڃA�h�I�����Q�Ƃ���\�q�ɂ��擾���A
        -- ���̎莝�݌ɐ���0�����̏ꍇ�͎��q�Ɏ莝�݌ɂ��猸�Z
        SELECT NVL(SUM(xliv.loct_onhand), 0) supplies_quantity
        INTO   on_quantity
        FROM   (
          SELECT xliv.lot_id                   lot_id
                ,xliv.lot_no                   lot_no
                ,xliv.manufacture_date         manufacture_date
                ,xliv.expiration_date          expiration_date
                ,xliv.unique_sign              unique_sign
                ,xliv.lot_status               lot_status
                ,CASE
                   WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                     THEN SUM(xliv.unlimited_loct_onhand)
                   ELSE SUM(xliv.limited_loct_onhand)
                 END                           loct_onhand
          FROM ( 
            SELECT xliv.lot_id            lot_id
                  ,xliv.lot_no            lot_no
                  ,xliv.manufacture_date  manufacture_date
                  ,xliv.expiration_date   expiration_date
                  ,xliv.unique_sign       unique_sign
                  ,xliv.lot_status        lot_status
                  ,xliv.loct_onhand       unlimited_loct_onhand
                  ,CASE 
                     WHEN xliv.schedule_date <= id_target_date
                       THEN xliv.loct_onhand
                     ELSE 0
                   END                    limited_loct_onhand
            FROM   xxcop_loct_inv_v         xliv
            WHERE  xliv.item_id        = in_item_id
            AND    xliv.shipment_date <= id_allocated_date
            AND    xliv.loct_code      = lt_whse_code
             --
            UNION ALL
            SELECT xliv.lot_id                 lot_id
                  ,xliv.lot_no                 lot_no
                  ,xliv.manufacture_date       manufacture_date
                  ,xliv.expiration_date        expiration_date
                  ,xliv.unique_sign            unique_sign
                  ,xliv.lot_status             lot_status
                  ,LEAST(xliv.loct_onhand, 0)  unlimited_loct_onhand
                  ,CASE 
                     WHEN xliv.schedule_date <= id_target_date
                       THEN LEAST(xliv.loct_onhand, 0)
                     ELSE 0
                   END                         limited_loct_onhand
            FROM   (
              SELECT xliv.lot_id            lot_id
                    ,xliv.lot_no            lot_no
                    ,xliv.manufacture_date  manufacture_date
                    ,xliv.expiration_date   expiration_date
                    ,xliv.unique_sign       unique_sign
                    ,xliv.lot_status        lot_status
                    ,xliv.schedule_date     schedule_date
                    ,SUM(xliv.loct_onhand)  loct_onhand
              FROM   xxcop_loct_inv_v              xliv
              WHERE  xliv.item_id            = in_item_id
              AND    xliv.shipment_date     <= id_allocated_date
              AND    xliv.loct_code IN ( 
                       SELECT xfil.frq_item_location_code    -- ��\�q��
                       FROM   xxwsh_frq_item_locations xfil  -- �q�ɕi�ڃA�h�I��
                       WHERE  xfil.item_location_code = lt_whse_code
                       AND    xfil.item_id            = in_item_id
                       )
              GROUP BY xliv.lot_id
                      ,xliv.lot_no
                      ,xliv.manufacture_date
                      ,xliv.expiration_date
                      ,xliv.unique_sign
                      ,xliv.lot_status
                      ,xliv.schedule_date
              ) xliv
            )xliv
          GROUP BY xliv.lot_id
                  ,xliv.lot_no
                  ,xliv.manufacture_date
                  ,xliv.expiration_date
                  ,xliv.unique_sign
                  ,xliv.lot_status
          ) xliv
        ;
        --
      -- ��\�q�ɐݒ肪���ݒ�(NULL)�̏ꍇ
      ELSIF ( lt_rep_whse_code IS NULL ) THEN
        -- ���q�ɒP�Ƃ̍݌ɐ��ʎ擾
        SELECT NVL(SUM(xliv.loct_onhand), 0) supplies_quantity
        INTO   on_quantity
        FROM   (
          SELECT xliv.lot_id              lot_id
                ,xliv.lot_no              lot_no
                ,xliv.manufacture_date    manufacture_date
                ,xliv.expiration_date     expiration_date
                ,xliv.unique_sign         unique_sign
                ,xliv.lot_status          lot_status
                ,CASE 
                   WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                     THEN SUM(xliv.unlimited_loct_onhand)
                   ELSE SUM(xliv.limited_loct_onhand)
                 END                      loct_onhand
          FROM ( 
            SELECT xliv.lot_id            lot_id
                  ,xliv.lot_no            lot_no
                  ,xliv.manufacture_date  manufacture_date
                  ,xliv.expiration_date   expiration_date
                  ,xliv.unique_sign        unique_sign
                  ,xliv.lot_status        lot_status
                  ,xliv.loct_onhand       unlimited_loct_onhand
                  ,CASE 
                     WHEN xliv.schedule_date <= id_target_date
                       THEN xliv.loct_onhand
                     ELSE 0
                   END                    limited_loct_onhand
            FROM   xxcop_loct_inv_v         xliv
            WHERE  xliv.item_id        = in_item_id
            AND    xliv.shipment_date <= id_allocated_date
            AND    xliv.loct_code      = lt_whse_code
            ) xliv
          GROUP BY xliv.lot_id
                  ,xliv.lot_no
                  ,xliv.manufacture_date
                  ,xliv.expiration_date
                  ,xliv.unique_sign
                  ,xliv.lot_status
          ) xliv
        ;
        --
      ELSE
        -- ��\�q�ɂɎ��q�ɈȊO�̑q�ɂ̐ݒ肪����ꍇ
        SELECT NVL(SUM(xliv.loct_onhand), 0) supplies_quantity
        INTO   on_quantity
        FROM   (
          SELECT xliv.lot_id              lot_id
                ,xliv.lot_no              lot_no
                ,xliv.manufacture_date    manufacture_date
                ,xliv.expiration_date     expiration_date
                 ,xliv.unique_sign        unique_sign
                ,xliv.lot_status          lot_status
                ,CASE 
                   WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                     THEN SUM(xliv.unlimited_loct_onhand)
                   ELSE SUM(xliv.limited_loct_onhand)
                 END                      loct_onhand
          FROM ( 
            SELECT xliv.lot_id            lot_id
                  ,xliv.lot_no            lot_no
                  ,xliv.manufacture_date  manufacture_date
                  ,xliv.expiration_date   expiration_date
                  ,xliv.unique_sign        unique_sign
                  ,xliv.lot_status        lot_status
                  ,xliv.loct_onhand       unlimited_loct_onhand
                  ,CASE 
                     WHEN xliv.schedule_date <= id_target_date
                       THEN xliv.loct_onhand
                     ELSE 0
                   END                    limited_loct_onhand
            FROM   xxcop_loct_inv_v         xliv
            WHERE  xliv.item_id        = in_item_id
            AND    xliv.shipment_date <= id_allocated_date
            AND    xliv.loct_code      = lt_whse_code
             --
            UNION ALL
            SELECT xliv.lot_id                 lot_id
                  ,xliv.lot_no                 lot_no
                  ,xliv.manufacture_date       manufacture_date
                  ,xliv.expiration_date        expiration_date
                  ,xliv.unique_sign            unique_sign
                  ,xliv.lot_status             lot_status
                  ,LEAST(xliv.loct_onhand, 0)  unlimited_loct_onhand
                  ,CASE 
                     WHEN xliv.schedule_date <= id_target_date
                       THEN LEAST(xliv.loct_onhand, 0)
                     ELSE 0
                   END                         limited_loct_onhand
            FROM   (
              SELECT xliv.lot_id                               lot_id
                    ,xliv.lot_no                               lot_no
                    ,xliv.manufacture_date                     manufacture_date
                    ,xliv.expiration_date                      expiration_date
                    ,xliv.unique_sign                          unique_sign
                    ,xliv.lot_status                           lot_status
                    ,xliv.schedule_date                        schedule_date
                    ,SUM(xliv.loct_onhand)                     loct_onhand
              FROM   xxcop_loct_inv_v          xliv
              WHERE  xliv.item_id        = in_item_id
              AND    xliv.shipment_date <= id_allocated_date
              AND    xliv.loct_code      = lt_rep_whse_code
              GROUP BY xliv.lot_id
                  ,xliv.lot_no
                  ,xliv.manufacture_date
                  ,xliv.expiration_date
                  ,xliv.unique_sign
                  ,xliv.lot_status
                  ,xliv.schedule_date
              ) xliv
            ) xliv
          GROUP BY xliv.lot_id
                  ,xliv.lot_no
                  ,xliv.manufacture_date
                  ,xliv.expiration_date
                  ,xliv.unique_sign
                  ,xliv.lot_status
          ) xliv
        ;
        --
      END IF;
      --
    END IF;
    --
  EXCEPTION
    WHEN profile_exp THEN
      ov_retcode          := cv_status_error;
      ov_errbuf           := NULL;
      ov_errmsg           := NULL;
      on_quantity := 0;
      --
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_quantity      := NULL;
  END get_onhand_qty;
  --
  /**********************************************************************************
   * Procedure Name   : get_deliv_lead_time
   * Description      : �z�����[�h�^�C���擾����
   ***********************************************************************************/
  PROCEDURE get_deliv_lead_time(
     id_target_date     IN  DATE         -- �Ώۓ��t
    ,iv_from_loct_code  IN  VARCHAR2     -- �o�וۊǑq�ɃR�[�h
    ,iv_to_loct_code    IN  VARCHAR2     -- ����ۊǑq�ɃR�[�h
    ,on_delivery_lt     OUT NUMBER       -- ���[�h�^�C��(��)
    ,ov_errbuf          OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode         OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg          OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deliv_lead_time'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_code_class   CONSTANT VARCHAR2(1) := '4';  -- �q��
    cv_na_loct_code CONSTANT VARCHAR2(4) := 'ZZZZ';  -- �w��Ȃ�
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
--
    --==============================================================
    --�z�����[�h�^�C���擾�P(���o�ɏꏊ�w��)
    --==============================================================
    BEGIN
      SELECT xdl.delivery_lead_time
      INTO   on_delivery_lt
      FROM   xxcmn_delivery_lt xdl
      WHERE  xdl.code_class1       = cv_code_class
        AND  xdl.code_class2       = cv_code_class
        AND  id_target_date BETWEEN NVL(xdl.start_date_active, id_target_date)
                                AND NVL(xdl.end_date_active  , id_target_date)
        AND  xdl.entering_despatching_code1 = iv_from_loct_code
        AND  xdl.entering_despatching_code2 = iv_to_loct_code
      ;
      IF (on_delivery_lt IS NOT NULL) THEN
        RETURN;
      END IF;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    --==============================================================
    --�z�����[�h�^�C���擾�Q(���o�ɏꏊ2�w��Ȃ�)
    --==============================================================
    BEGIN
      SELECT xdl.delivery_lead_time delivery_lt
      INTO   on_delivery_lt
      FROM   xxcmn_delivery_lt xdl
      WHERE  xdl.code_class1       = cv_code_class
        AND  xdl.code_class2       = cv_code_class
        AND  id_target_date BETWEEN NVL(xdl.start_date_active, id_target_date)
                                AND NVL(xdl.end_date_active  , id_target_date)
        AND  xdl.entering_despatching_code1 = iv_from_loct_code
        AND  xdl.entering_despatching_code2 = cv_na_loct_code
      ;
      IF (on_delivery_lt IS NOT NULL) THEN
        RETURN;
      END IF;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    --==============================================================
    --�z�����[�h�^�C���擾�R(���o�ɏꏊ1�w��Ȃ�)
    --==============================================================
    BEGIN
      SELECT xdl.delivery_lead_time delivery_lt
      INTO   on_delivery_lt
      FROM   xxcmn_delivery_lt xdl
      WHERE  xdl.code_class1       = cv_code_class
        AND  xdl.code_class2       = cv_code_class
        AND  id_target_date BETWEEN NVL(xdl.start_date_active, id_target_date)
                                AND NVL(xdl.end_date_active  , id_target_date)
        AND  xdl.entering_despatching_code1 = cv_na_loct_code
        AND  xdl.entering_despatching_code2 = iv_to_loct_code
      ;
      IF (on_delivery_lt IS NOT NULL) THEN
        RETURN;
      END IF;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    --==============================================================
    --�z�����[�h�^�C���擾�S(�w��Ȃ�)
    --==============================================================
    BEGIN
      SELECT xdl.delivery_lead_time delivery_lt
      INTO   on_delivery_lt
      FROM   xxcmn_delivery_lt xdl
      WHERE  xdl.code_class1       = cv_code_class
        AND  xdl.code_class2       = cv_code_class
        AND  id_target_date BETWEEN NVL(xdl.start_date_active, id_target_date)
                                AND NVL(xdl.end_date_active  , id_target_date)
        AND  xdl.entering_despatching_code1 = cv_na_loct_code
        AND  xdl.entering_despatching_code2 = cv_na_loct_code
      ;
      IF (on_delivery_lt IS NOT NULL) THEN
        RETURN;
      END IF;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE NO_DATA_FOUND;
    END;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_delivery_lt   := NULL;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_delivery_lt   := NULL;
  END get_deliv_lead_time;
--
  /**********************************************************************************
   * Function Name   : get_working_days
   * Description      : �ғ������擾����
   ***********************************************************************************/
  PROCEDURE get_working_days(
    iv_calendar_code   IN  VARCHAR2,  -- �����J�����_�R�[�h
    in_organization_id IN  NUMBER,    -- �g�DID
    in_loct_id         IN  NUMBER,    -- �ۊǑq��ID
    id_from_date       IN  DATE,      -- ��_���t
    id_to_date         IN  DATE,      -- �I�_���t
    on_working_days    OUT NUMBER,    -- �ғ���
    ov_errbuf          OUT VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_working_days'; -- �v���O������
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
    cn_active     NUMBER := 0;
--
    -- *** ���[�J���ϐ� ***
    ld_work_date     DATE   DEFAULT NULL;
    ld_from_date     DATE   DEFAULT NULL;
    ln_cnt_days      NUMBER DEFAULT 0;
    lt_calendar_code mtl_parameters.calendar_code%TYPE DEFAULT NULL;
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
    -- �����J�����_�R�[�h���ݒ�̏ꍇ�͎擾����
    IF ( iv_calendar_code IS NULL ) THEN
      -- ===============================
      -- �J�����_�[�R�[�h�擾
      -- ===============================
      BEGIN
        SELECT mil.attribute10 calendar_code
        INTO   lt_calendar_code
        FROM   mtl_item_locations mil
        WHERE  mil.organization_id        = in_organization_id
          AND  mil.inventory_location_id  = in_loct_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lt_calendar_code := NULL;
        --
      END;
      --
      -- �J�����_�R�[�h���擾�ł��Ȃ������ꍇ�̓v���t�@�C���̃h�����N��J�����_��ݒ肷��B
      IF ( lt_calendar_code IS NULL ) THEN
        lt_calendar_code := FND_PROFILE.VALUE( cv_cmn_drink_cal_cd );
        --
        IF ( lt_calendar_code IS NULL ) THEN
          ov_errbuf        := NULL;
          ov_errmsg        := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_application
                                ,iv_name         => cv_message_00002
                                ,iv_token_name1  => cv_message_00002_token_1
                                ,iv_token_value1 => cv_cmn_drink_cal_cd_name
                                );
          on_working_days  := NULL;
          ov_retcode       := cv_status_error;
          RETURN;
        END IF;
        --
      END IF;
    ELSE
      lt_calendar_code := iv_calendar_code;
    END IF;
--
    -- ===============================
    -- �ғ������擾
    -- ===============================
    SELECT COUNT(*)
    INTO   on_working_days
    FROM   mr_shcl_hdr msh    -- �����J�����_�w�b�_
          ,mr_shcl_dtl msd    -- �����J�����_����
    WHERE  msh.calendar_no = lt_calendar_code
      AND  msh.calendar_id = msd.calendar_id
      AND  msd.delete_mark = cn_active
      AND  msd.calendar_date BETWEEN id_from_date
                                 AND id_to_date
    ;
--
  EXCEPTION
--
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_working_days  := NULL;
--
  END get_working_days;
--
  /**********************************************************************************
   * Procedure Name   : upd_assignment
   * Description      : �����Z�b�gAPI�N��
   ***********************************************************************************/
  PROCEDURE upd_assignment(
    iv_mov_num              IN  VARCHAR2,     -- �ړ��w�b�_ID
    iv_process_type         IN  VARCHAR2,     -- �����敪(0�F���Z�A1�F���Z)
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'upd_assignment';   -- �v���V�[�W����
    -- ���b�Z�[�W��
    cv_message_00003          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00003';
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD START
    cv_message_00048          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00048';
    cv_message_00048_token_1  CONSTANT VARCHAR2(9)   := 'ITEM_NAME';
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD END
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�U�[��`��O ***
    api_expt                  EXCEPTION;
    internal_process_expt     EXCEPTION;     -- ����PROCEDURE/FUNCTION�G���[�n���h�����O�p
--
    -- *** ���[�J���萔 ***
    cv_doc_type               CONSTANT VARCHAR2(2) := '20';    -- �����^�C�v(20�F�ړ�)
    cv_rec_type               CONSTANT VARCHAR2(2) := '10';    -- ���R�[�h�^�C�v(10�F�w��)
    cv_attribute_category     CONSTANT VARCHAR2(1) := '2';     -- �����Z�b�g�敪(2:���ʉ���)
    cv_assignment_type        CONSTANT VARCHAR2(1) := '6';     -- ������^�C�v(6:�i�ځE�g�D)
    cv_sourcing_rule_type     CONSTANT VARCHAR2(1) := '1';     -- �����\���\/�\�[�X���[���^�C�v(1:�\�[�X���[��)
    cv_lookup_type            CONSTANT VARCHAR2(22) := 'XXCOP1_ASSIGNMENT_NAME';  -- �N�C�b�N�R�[�h�^�C�v��
    --
    cv_api_version            CONSTANT VARCHAR2(4) := '1.0';      -- �o�[�W����
    cv_operation_update       CONSTANT VARCHAR2(6) := 'UPDATE';   -- �X�V
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_START
    gv_msg_encoded            CONSTANT VARCHAR2(1)   := 'F';      -- �G���[���b�Z�[�W�G���R�[�h
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_END
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD START
    cv_category_prod_class    CONSTANT VARCHAR2(100) := '�{�Џ��i�敪';
    --�i�ڃJ�e�S���l
    cv_prod_class_leaf        CONSTANT VARCHAR2(100) := '1';  -- ���[�t
    cv_prod_class_drink       CONSTANT VARCHAR2(100) := '2';  -- �h�����N
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD END
    --
    cv_process_type_plus      CONSTANT VARCHAR2(1) := '0';     -- �����敪 0�F���Z
    cv_process_type_minus     CONSTANT VARCHAR2(1) := '1';     -- �����敪 1�F���Z
--
    -- *** ���[�J���ϐ� ***
    lv_errbuf                          VARCHAR2(5000);         -- �G���[�E���b�Z�[�W
    lv_retcode                         VARCHAR2(1);            -- ���^�[���E�R�[�h
    lv_errmsg                          VARCHAR2(5000);         -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    ln_quantity                        NUMBER;                 -- �ړ�����
    ln_quantity_before                 NUMBER;                 -- �ύX�O�ړ�����
    --
    ln_case_qty                        NUMBER;                 -- �P�[�X���Z����
    --
    ln_loop_cnt                        NUMBER DEFAULT 0;       -- ���[�v�J�E���^
    lv_rowid                           ROWID;                  -- ���b�N�擾�p
    --
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada MOD START
    lv_category_value                  mtl_categories_b.segment1%TYPE;  -- �i�ڃJ�e�S���l
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada MOD START
    lv_message_code                    VARCHAR2(100);
    lv_param                           VARCHAR2(256);          -- �p�����[�^
    lv_return_status                   VARCHAR2(1);
    ln_msg_count                       NUMBER;
    lv_msg_data                        VARCHAR2(3000);
    ln_msg_index_out                   NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �ړ��֘A���̎擾
    CURSOR l_move_info_cur
    IS
      SELECT xmrih.shipped_locat_code    ship_from_code      -- �o�׌��q��(�o�Ɍ��ۊǏꏊ)
            ,xmrih.ship_to_locat_code    ship_to_code        -- ���ɐ�q��(���ɐ�ۊǏꏊ)
            ,TO_CHAR(xmrih.schedule_arrival_date,'YYYY/MM/DD') arrival_date        -- ����(���ɗ\���)
            ,xmril.item_code             item_code           -- �i��
            ,xmld.actual_quantity        quantity            -- �ړ�����
            ,ilm.attribute1              prod_start_date     -- �����N����
            --
            ,xmrih.mov_hdr_id            mov_hdr_id          -- �ړ��w�b�_ID
            ,xmrih.mov_num               mov_num             -- �ړ��ԍ�
            ,xmril.mov_line_id           mov_line_id         -- �ړ�����ID
            ,xmril.line_number           line_number         -- ���הԍ�
            ,xmril.delete_flg            delete_flg          -- ���׍폜�t���O
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada MOD START
            ,xmril.item_id               item_id             -- �i��ID
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada MOD END
            ,xmld.lot_id                 lot_id              -- ���b�gID
            ,xmld.lot_no                 lot_no              -- ���b�gNo
      FROM   xxinv_mov_req_instr_headers xmrih               -- �ړ��˗�/�w���w�b�_
            ,xxinv_mov_req_instr_lines   xmril               -- �ړ��˗�/�w������
            ,xxinv_mov_lot_details       xmld                -- �ړ����b�g�ڍ�
            ,ic_lots_mst                 ilm                 -- OPM���b�g�}�X�^
      WHERE
      -- �e�[�u����������
             xmrih.mov_hdr_id        = xmril.mov_hdr_id
      AND    xmril.mov_line_id       = xmld.mov_line_id
      AND    xmld.document_type_code = cv_doc_type
      AND    xmld.record_type_code   = cv_rec_type
      AND    xmld.item_id            = ilm.item_id
      AND    xmld.lot_id             = ilm.lot_id
      -- ���o����
      AND    xmrih.mov_num           = iv_mov_num
      ;
    --
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_START
    CURSOR l_remove_info_cur
    IS
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada MOD START
--      SELECT xac.ROWID                   xac_rowid           -- ���ʉ�������}�X�^�R���g���[��ROWID
--            ,xmrih.shipped_locat_code    ship_from_code      -- �o�׌��q��(�o�Ɍ��ۊǏꏊ)
--            ,xmrih.ship_to_locat_code    ship_to_code        -- ���ɐ�q��(���ɐ�ۊǏꏊ)
--            ,TO_CHAR(xac.arrival_date,'YYYY/MM/DD') arrival_date        -- ����(���ɗ\���)
--            ,xac.item_code               item_code           -- �i��
--            ,xac.mov_qty                 quantity            -- �ړ�����
--            ,ilm.attribute1              prod_start_date     -- �����N����
--            --
--            ,xac.mov_hdr_id              mov_hdr_id          -- �ړ��w�b�_ID
--            ,xac.mov_num                 mov_num             -- �ړ��ԍ�
--            ,xac.mov_line_id             mov_line_id         -- �ړ�����ID
--            ,xac.line_number             line_number         -- ���הԍ�
--            ,xac.lot_id                  lot_id              -- ���b�gID
--            ,xac.lot_no                  lot_no              -- ���b�gNo
--      FROM   xxinv_mov_req_instr_headers xmrih               -- �ړ��˗�/�w���w�b�_
--            ,xxcop_assignment_controls   xac                 -- ���ʉ�������}�X�^�R���g���[��
--            ,ic_item_mst_b               iimb                -- OPM�i�ڃ}�X�^
--            ,ic_lots_mst                 ilm                 -- OPM���b�g�}�X�^
--      WHERE
--      -- �e�[�u����������
--             xmrih.mov_hdr_id        = xac.mov_hdr_id
--      AND    iimb.item_no            = xac.item_code
--      AND    iimb.item_id            = ilm.item_id
--      AND    xac.lot_id              = ilm.lot_id
--      -- ���o����
--      AND    xmrih.mov_num           = iv_mov_num
--      FOR UPDATE OF xac.mov_hdr_id NOWAIT
--      ;
--
      SELECT xac.ROWID                   xac_rowid                       -- ���ʉ�������}�X�^�R���g���[��ROWID
            ,xac.ship_from_code          ship_from_code                  -- �o�׌��q��(�o�Ɍ��ۊǏꏊ)
            ,xac.ship_to_code            ship_to_code                    -- ���ɐ�q��(���ɐ�ۊǏꏊ)
            ,TO_CHAR(xac.arrival_date,'YYYY/MM/DD')     arrival_date     -- ����(���ɗ\���)
            ,xac.item_code               item_code                       -- �i��
            ,xac.mov_qty                 quantity                        -- �ړ�����
            ,TO_CHAR(xac.prod_start_date,'YYYY/MM/DD')  prod_start_date  -- �����N����
            ,xac.mov_hdr_id              mov_hdr_id                      -- �ړ��w�b�_ID
            ,xac.mov_num                 mov_num                         -- �ړ��ԍ�
            ,xac.mov_line_id             mov_line_id                     -- �ړ�����ID
            ,xac.line_number             line_number                     -- ���הԍ�
            ,xac.lot_id                  lot_id                          -- ���b�gID
            ,xac.lot_no                  lot_no                          -- ���b�gNo
      FROM   xxcop_assignment_controls   xac                             -- ���ʉ�������}�X�^�R���g���[��
      -- ���o����
      WHERE  xac.mov_num = iv_mov_num
      FOR UPDATE OF xac.mov_hdr_id NOWAIT
      ;
    --
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada MOD END
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_END
    -- ���ʉ�������}�X�^�֘A���̎擾
    CURSOR l_assignments_info_cur(
      prm_ship_from_code   VARCHAR2  -- �o�׌��q��(�o�Ɍ��ۊǏꏊ)
     ,prm_ship_to_code     VARCHAR2  -- ���ɐ�q��(���ɐ�ۊǏꏊ)
     ,prm_arrival_date     VARCHAR2  -- ����(���ɗ\���)
     ,prm_item_code        VARCHAR2  -- �i��
     ,prm_quantity         NUMBER    -- �ړ�����
     ,prm_prod_start_date  VARCHAR2) -- �����N����
    IS
      SELECT mas.assignment_set_id    mas_assignment_set_id      -- �����Z�b�g�w�b�_.�����Z�b�g�w�b�_ID
            ,mas.assignment_set_name  mas_assignment_set_name    -- �����Z�b�g�w�b�_.�����Z�b�g��
            ,mas.creation_date        mas_creation_date          -- �����Z�b�g�w�b�_.�쐬��
            ,mas.created_by           mas_created_by             -- �����Z�b�g�w�b�_.�쐬��
            ,mas.description          mas_desctiption            -- �����Z�b�g�w�b�_.�����Z�b�g�E�v
            ,mas.attribute_category   mas_attribute_category     -- �����Z�b�g�w�b�_.Attribute_Category
            ,mas.attribute1           mas_attribute1             -- �����Z�b�g�w�b�_.�����Z�b�g�敪(DFF1)
            ,mas.attribute2           mas_attribute2             -- �����Z�b�g�w�b�_.DFF2
            ,mas.attribute3           mas_attribute3             -- �����Z�b�g�w�b�_.DFF3
            ,mas.attribute4           mas_attribute4             -- �����Z�b�g�w�b�_.DFF4
            ,mas.attribute5           mas_attribute5             -- �����Z�b�g�w�b�_.DFF5
            ,mas.attribute6           mas_attribute6             -- �����Z�b�g�w�b�_.DFF6
            ,mas.attribute7           mas_attribute7             -- �����Z�b�g�w�b�_.DFF7
            ,mas.attribute8           mas_attribute8             -- �����Z�b�g�w�b�_.DFF8
            ,mas.attribute9           mas_attribute9             -- �����Z�b�g�w�b�_.DFF9
            ,mas.attribute10          mas_attribute10            -- �����Z�b�g�w�b�_.DFF10
            ,mas.attribute11          mas_attribute11            -- �����Z�b�g�w�b�_.DFF11
            ,mas.attribute12          mas_attribute12            -- �����Z�b�g�w�b�_.DFF12
            ,mas.attribute13          mas_attribute13            -- �����Z�b�g�w�b�_.DFF13
            ,mas.attribute14          mas_attribute14            -- �����Z�b�g�w�b�_.DFF14
            ,mas.attribute15          mas_attribute15            -- �����Z�b�g�w�b�_.DFF15
             --
            ,msa.assignment_id        msa_assignment_id          -- �����Z�b�g����.�����Z�b�g����ID
            ,msa.assignment_type      msa_assignment_type        -- �����Z�b�g����.������^�C�v
            ,msa.sourcing_rule_id     msa_sourcing_rule_id       -- �����Z�b�g����.�\�[�X���[��ID
            ,msa.sourcing_rule_type   msa_sourcing_rule_type     -- �����Z�b�g����.�����\���\/�\�[�X���[���^�C�v
            ,msa.assignment_set_id    msa_assignment_set_id      -- �����Z�b�g����.�����Z�b�g�w�b�_ID
            ,msa.creation_date        msa_creation_date          -- �����Z�b�g����.�쐬��
            ,msa.created_by           msa_created_by             -- �����Z�b�g����.�쐬��
            ,msa.organization_id      msa_organization_id        -- �����Z�b�g����.�g�DID
            ,msa.customer_id          msa_cutomer_id             -- �����Z�b�g����.Customer_Id
            ,msa.ship_to_site_id      msa_ship_to_site_id        -- �����Z�b�g����.Ship_To_Site_Id
            ,msa.category_id          msa_category_id            -- �����Z�b�g����.Category_Id
            ,msa.category_set_id      msa_category_set_id        -- �����Z�b�g����.Category_Set_Id
            ,msa.inventory_item_id    msa_inventory_item_id      -- �����Z�b�g����.�i��ID
            ,msa.secondary_inventory  msa_secondary_inventory    -- �����Z�b�g����.Secondary_Inventory
            ,msa.attribute_category   msa_attribute_category     -- �����Z�b�g����.�����Z�b�g�敪
            ,msa.attribute1           msa_attribute1             -- �����Z�b�g����.�J�n�����N����(DFF1)
            ,msa.attribute2           msa_attribute2             -- �����Z�b�g����.�L���J�n��(DFF2)
            ,msa.attribute3           msa_attribute3             -- �����Z�b�g����.�L���I����(DFF3)
            ,msa.attribute4           msa_attribute4             -- �����Z�b�g����.�ݒ萔��(DFF4)
            ,msa.attribute5           msa_attribute5             -- �����Z�b�g����.�ړ���(DFF5)
            ,msa.attribute6           msa_attribute6             -- �����Z�b�g����.DFF6
            ,msa.attribute7           msa_attribute7             -- �����Z�b�g����.DFF7
            ,msa.attribute8           msa_attribute8             -- �����Z�b�g����.DFF8
            ,msa.attribute9           msa_attribute9             -- �����Z�b�g����.DFF9
            ,msa.attribute10          msa_attribute10            -- �����Z�b�g����.DFF10
            ,msa.attribute11          msa_attribute11            -- �����Z�b�g����.DFF11
            ,msa.attribute12          msa_attribute12            -- �����Z�b�g����.DFF12
            ,msa.attribute13          msa_attribute13            -- �����Z�b�g����.DFF13
            ,msa.attribute14          msa_attribute14            -- �����Z�b�g����.DFF14
            ,msa.attribute15          msa_attribute15            -- �����Z�b�g����.DFF15
      FROM   mrp_assignment_sets      mas                        -- �����Z�b�g�w�b�_
            ,mrp_sr_assignments       msa                        -- �����Z�b�g����
            ,mrp_sourcing_rules       msr                        -- �\�[�X���[��
            ,mrp_sr_receipt_org       msro                       --
            ,mtl_item_locations       mil_to                     -- OPM�ۊǏꏊ
            ,mrp_sr_source_org        msso                       --
            ,mtl_item_locations       mil_from                   -- OPM�ۊǏꏊ
            ,xxcop_item_categories1_v xicv                       -- �v��̈�F�i�ڃ}�X�^
            ,fnd_lookup_values        flv                        -- �N�C�b�N�R�[�h
      WHERE
      -- �e�[�u����������
            mas.assignment_set_id                = msa.assignment_set_id
      AND   msa.sourcing_rule_id                  = msr.sourcing_rule_id
      AND   msr.sourcing_rule_id                  = msro.sourcing_rule_id
      AND   SYSDATE                               BETWEEN NVL(msro.effective_date,SYSDATE)
                                                  AND     NVL(msro.disable_date  ,SYSDATE)
      AND   msro.receipt_organization_id          = mil_to.organization_id
      AND   msro.sr_receipt_id                    = msso.sr_receipt_id
      AND   msso.source_organization_id           = mil_from.organization_id
      AND   msa.inventory_item_id                 = xicv.inventory_item_id
      AND   flv.lookup_type                       = cv_lookup_type
      AND   flv.language                          = USERENV('LANG')
      AND   flv.enabled_flag                      = 'Y'
      AND   flv.lookup_code                       = mas.assignment_set_name
      -- �f�[�^���o����(���ʉ����̂ݒ��o)
      AND   msa.attribute_category                = cv_attribute_category
      AND   msa.assignment_type                   = cv_assignment_type
      AND   msa.sourcing_rule_type                = cv_sourcing_rule_type
      -- ���o����
      AND   mil_from.segment1                     = prm_ship_from_code
      AND   mil_to.segment1                       = prm_ship_to_code
      AND   xicv.item_no                          = prm_item_code
            -- ���o�����F���ʉ����擾�p�^�[���P
      AND   (   (   prm_prod_start_date >= msa.attribute1
                AND prm_arrival_date    <= msa.attribute3
                AND (  (   iv_process_type            = cv_process_type_plus 
--20091105_Ver2.1_I_E_479_009_SCS.Goto_MOD_START
--                       AND TO_NUMBER(msa.attribute4) >= TO_NUMBER(msa.attribute5)
                       AND TO_NUMBER(msa.attribute4) >= NVL(TO_NUMBER(msa.attribute5), 0)
--20091105_Ver2.1_I_E_479_009_SCS.Goto_MOD_END
                       )
                    OR iv_process_type                = cv_process_type_minus
                    )
                )
            -- ���o�����F���ʉ����擾�p�^�[���Q
            OR  (   msa.attribute1                IS NULL
                AND prm_arrival_date     BETWEEN msa.attribute2
                                         AND     msa.attribute3
                AND (  (   iv_process_type            = cv_process_type_plus 
--20091105_Ver2.1_I_E_479_009_SCS.Goto_MOD_START
--                       AND TO_NUMBER(msa.attribute4) >= TO_NUMBER(msa.attribute5)
                       AND TO_NUMBER(msa.attribute4) >= NVL(TO_NUMBER(msa.attribute5), 0)
--20091105_Ver2.1_I_E_479_009_SCS.Goto_MOD_END
                       )
                    OR iv_process_type                = cv_process_type_minus
                    )
                )
            -- ���o�����F���ʉ����擾�p�^�[���R
            OR  (   prm_prod_start_date >= msa.attribute1
                AND msa.attribute3                IS NULL
                AND (  (   iv_process_type            = cv_process_type_plus 
--20091105_Ver2.1_I_E_479_009_SCS.Goto_MOD_START
--                       AND TO_NUMBER(msa.attribute4) >= TO_NUMBER(msa.attribute5)
                       AND TO_NUMBER(msa.attribute4) >= NVL(TO_NUMBER(msa.attribute5), 0)
--20091105_Ver2.1_I_E_479_009_SCS.Goto_MOD_END
                       )
                    OR iv_process_type                = cv_process_type_minus
                    )
                )
            -- ���o�����F���ʉ����擾�p�^�[���S
            OR  (   prm_prod_start_date >= msa.attribute1
                AND msa.attribute2                IS NULL
                AND prm_arrival_date    <= msa.attribute3
                AND msa.attribute4                IS NULL
                )
            -- ���o�����F���ʉ����擾�p�^�[���T
            OR  (   msa.attribute1                IS NULL
                AND prm_arrival_date     BETWEEN msa.attribute2
                                         AND     msa.attribute3
                AND msa.attribute4                IS NULL
                )
            -- ���o�����F���ʉ����擾�p�^�[���U
            OR  (   msa.attribute1                IS NULL
                AND prm_arrival_date    >= msa.attribute2
                AND msa.attribute3                IS NULL
                AND (  (   iv_process_type            = cv_process_type_plus 
--20091105_Ver2.1_I_E_479_009_SCS.Goto_MOD_START
--                       AND TO_NUMBER(msa.attribute4) >= TO_NUMBER(msa.attribute5)
                       AND TO_NUMBER(msa.attribute4) >= NVL(TO_NUMBER(msa.attribute5), 0)
--20091105_Ver2.1_I_E_479_009_SCS.Goto_MOD_END
                       )
                    OR iv_process_type                = cv_process_type_minus
                    )
                )
             )
      ;
--
    -- *** ���[�J���E���R�[�h ***
    l_move_info_rec           l_move_info_cur%ROWTYPE;          -- �ړ��֘A���擾
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_START
    l_remove_info_rec         l_remove_info_cur%ROWTYPE;        -- �ړ��֘A���擾
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_END
    --
    l_in_mas_rec              mrp_src_assignment_pub.assignment_set_rec_type;        -- �����Z�b�g�w�b�_�[
    l_mas_val_rec             mrp_src_assignment_pub.assignment_set_val_rec_type;
    l_out_mas_rec             mrp_src_assignment_pub.assignment_set_rec_type;
    l_out_mas_val_rec         mrp_src_assignment_pub.assignment_set_val_rec_type;
--
    -- *** ���[�J���EPL/SQL�\ ***
    l_in_msa_tab              mrp_src_assignment_pub.assignment_tbl_type;            -- �����Z�b�g����
    l_msa_val_tab             mrp_src_assignment_pub.assignment_val_tbl_type;
    l_out_msa_tab             mrp_src_assignment_pub.assignment_tbl_type;
    l_out_msa_val_tab         mrp_src_assignment_pub.assignment_val_tbl_type;
--
    -- *** ���[�J���EPL/SQL�\ ***
--
  BEGIN
    --==============================================================
    -- �X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
--
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_START
    -- �m��ʒm��(���Z)�̏ꍇ
    IF ( iv_process_type = cv_process_type_plus ) THEN
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_END
      --==============================================================
      -- �֘A�ړ����̎擾
      --==============================================================
      OPEN l_move_info_cur;
      << assignment_loop >>
      LOOP
        FETCH l_move_info_cur INTO l_move_info_rec;
        EXIT WHEN l_move_info_cur%NOTFOUND;
        --
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada DEL START
--        -- �J�E���g�A�b�v
--        ln_loop_cnt := ln_loop_cnt + 1;
--        --
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada DEL END
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD START
        -- �Ώەi�ڂ̖{�Џ��i�敪�擾
        lv_category_value := xxcop_common_pkg2.get_item_category_f(
                               iv_category_set  => cv_category_prod_class   -- �i�ڃJ�e�S����
                              ,in_item_id       => l_move_info_rec.item_id  -- �i��ID
                              );
        -- ���i�敪�̎擾�Ɏ��s�����ꍇ
        IF ( lv_category_value IS NULL ) THEN
          ov_errbuf        := NULL;
          ov_errmsg        := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_application
                                ,iv_name         => cv_message_00048
                                ,iv_token_name1  => cv_message_00048_token_1
                                ,iv_token_value1 => cv_category_prod_class
                                );
          ov_retcode       := cv_status_error;
          -- �J�[�\���N���[�Y
          CLOSE l_move_info_cur;
          --
          RETURN;
          --
        END IF;
        --
        -- �h�����N���i�݂̂������ΏۂƂ���(���[�t�̏ꍇ�͏������X�L�b�v)
        IF ( lv_category_value = cv_prod_class_drink ) THEN
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD END
        --
        -- �m��ʒm��(���Z)�̏ꍇ�͈ړ����׍폜���l�����Ȃ��̂ŏ������X�L�b�v
        IF ( ( iv_process_type = cv_process_type_plus ) AND ( l_move_info_rec.delete_flg = 'Y' ) ) THEN
          NULL;
        ELSE
          --
--
      --==============================================================
      -- ���ʉ�������}�X�^���̎擾
      --==============================================================
          OPEN l_assignments_info_cur (
             l_move_info_rec.ship_from_code
            ,l_move_info_rec.ship_to_code
            ,l_move_info_rec.arrival_date
            ,l_move_info_rec.item_code
            ,l_move_info_rec.quantity
            ,l_move_info_rec.prod_start_date
            );
          FETCH l_assignments_info_cur INTO 
            l_in_mas_rec.assignment_set_id          -- �����Z�b�g�w�b�_.�����Z�b�g�w�b�_ID
           ,l_in_mas_rec.assignment_set_name        -- �����Z�b�g�w�b�_.�����Z�b�g��
           ,l_in_mas_rec.creation_date              -- �����Z�b�g�w�b�_.�쐬��
           ,l_in_mas_rec.created_by                 -- �����Z�b�g�w�b�_.�쐬��
           ,l_in_mas_rec.description                -- �����Z�b�g�w�b�_.�����Z�b�g�E�v
           ,l_in_mas_rec.attribute_category         -- �����Z�b�g�w�b�_.Attribute_Category
           ,l_in_mas_rec.attribute1                 -- �����Z�b�g�w�b�_.�����Z�b�g�敪(DFF1)
           ,l_in_mas_rec.attribute2                 -- �����Z�b�g�w�b�_.DFF2
           ,l_in_mas_rec.attribute3                 -- �����Z�b�g�w�b�_.DFF3
           ,l_in_mas_rec.attribute4                 -- �����Z�b�g�w�b�_.DFF4
           ,l_in_mas_rec.attribute5                 -- �����Z�b�g�w�b�_.DFF5
           ,l_in_mas_rec.attribute6                 -- �����Z�b�g�w�b�_.DFF6
           ,l_in_mas_rec.attribute7                 -- �����Z�b�g�w�b�_.DFF7
           ,l_in_mas_rec.attribute8                 -- �����Z�b�g�w�b�_.DFF8
           ,l_in_mas_rec.attribute9                 -- �����Z�b�g�w�b�_.DFF9
           ,l_in_mas_rec.attribute10                -- �����Z�b�g�w�b�_.DFF10
           ,l_in_mas_rec.attribute11                -- �����Z�b�g�w�b�_.DFF11
           ,l_in_mas_rec.attribute12                -- �����Z�b�g�w�b�_.DFF12
           ,l_in_mas_rec.attribute13                -- �����Z�b�g�w�b�_.DFF13
           ,l_in_mas_rec.attribute14                -- �����Z�b�g�w�b�_.DFF14
           ,l_in_mas_rec.attribute15                -- �����Z�b�g�w�b�_.DFF15
           ,l_in_msa_tab(1).assignment_id           -- �����Z�b�g����.�����Z�b�g����ID
           ,l_in_msa_tab(1).assignment_type         -- �����Z�b�g����.������^�C�v
           ,l_in_msa_tab(1).sourcing_rule_id        -- �����Z�b�g����.�\�[�X���[��ID
           ,l_in_msa_tab(1).sourcing_rule_type      -- �����Z�b�g����.�����\���\/�\�[�X���[���^�C�v
           ,l_in_msa_tab(1).assignment_set_id       -- �����Z�b�g����.�����Z�b�g�w�b�_ID
           ,l_in_msa_tab(1).creation_date           -- �����Z�b�g����.�쐬��
           ,l_in_msa_tab(1).created_by              -- �����Z�b�g����.�쐬��
           ,l_in_msa_tab(1).organization_id         -- �����Z�b�g����.�g�DID
           ,l_in_msa_tab(1).customer_id             -- �����Z�b�g����.Customer_Id
           ,l_in_msa_tab(1).ship_to_site_id         -- �����Z�b�g����.Ship_To_Site_Id
           ,l_in_msa_tab(1).category_id             -- �����Z�b�g����.Category_Id
           ,l_in_msa_tab(1).category_set_id         -- �����Z�b�g����.Category_Set_Id
           ,l_in_msa_tab(1).inventory_item_id       -- �����Z�b�g����.�i��ID
           ,l_in_msa_tab(1).secondary_inventory     -- �����Z�b�g����.Secondary_Inventory
           ,l_in_msa_tab(1).attribute_category      -- �����Z�b�g����.�����Z�b�g�敪
           ,l_in_msa_tab(1).attribute1              -- �����Z�b�g����.�J�n�����N����(DFF1)
           ,l_in_msa_tab(1).attribute2              -- �����Z�b�g����.�L���J�n��(DFF2)
           ,l_in_msa_tab(1).attribute3              -- �����Z�b�g����.�L���I����(DFF3)
           ,l_in_msa_tab(1).attribute4              -- �����Z�b�g����.�ݒ萔��(DFF4)
           ,l_in_msa_tab(1).attribute5              -- �����Z�b�g����.�ړ���(DFF5)
           ,l_in_msa_tab(1).attribute6              -- �����Z�b�g����.DFF6
           ,l_in_msa_tab(1).attribute7              -- �����Z�b�g����.DFF7
           ,l_in_msa_tab(1).attribute8              -- �����Z�b�g����.DFF8
           ,l_in_msa_tab(1).attribute9              -- �����Z�b�g����.DFF9
           ,l_in_msa_tab(1).attribute10             -- �����Z�b�g����.DFF10
           ,l_in_msa_tab(1).attribute11             -- �����Z�b�g����.DFF11
           ,l_in_msa_tab(1).attribute12             -- �����Z�b�g����.DFF12
           ,l_in_msa_tab(1).attribute13             -- �����Z�b�g����.DFF13
           ,l_in_msa_tab(1).attribute14             -- �����Z�b�g����.DFF14
           ,l_in_msa_tab(1).attribute15             -- �����Z�b�g����.DFF15
           ;
          --
          -- �Ώۃf�[�^�����݂���ꍇ
          IF ( l_assignments_info_cur%FOUND ) THEN
            -- �����Z�b�g�EAPI�W�����R�[�h�^�C�v�̏���
            l_in_mas_rec.operation         := cv_operation_update;      -- �����Z�b�g�w�b�_.�����敪(UPDATE)
            l_in_mas_rec.last_update_date  := cd_last_update_date;      -- �����Z�b�g�w�b�_.�ŏI�X�V��
            l_in_mas_rec.last_updated_by   := cn_last_updated_by;       -- �����Z�b�g�w�b�_.�ŏI�X�V��
            l_in_mas_rec.last_update_login := cn_last_update_login;     -- �����Z�b�g�w�b�_.�ŏI�X�V���O�C��
            --
      --==============================================================
      -- �ړ����ʂ̌v�Z
      --==============================================================
--20091105_Ver2.2_I_E_479_008_SCS.Goto_DEL_START
--            --
--            -- �����敪�ɂ���ĉ��Z�A���Z�𐧌�
--            IF ( iv_process_type = cv_process_type_plus ) THEN
--20091105_Ver2.2_I_E_479_008_SCS.Goto_DEL_END
            -- ���Z�̏ꍇ
            -- �P�[�X���Z
            xxcop_common_pkg.get_case_quantity(
              iv_item_no               => l_move_info_rec.item_code  -- �i�ڃR�[�h
             ,in_individual_quantity   => l_move_info_rec.quantity   -- �o������
             ,in_trunc_digits          => 0                          -- �؎̂Č���
             ,on_case_quantity         => ln_case_qty                -- �P�[�X����
             ,ov_retcode               => lv_retcode                 -- ���^�[���R�[�h
             ,ov_errbuf                => lv_errbuf                  -- �G���[�E���b�Z�[�W
             ,ov_errmsg                => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
            );
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE internal_process_expt;
            END IF;
            --
--20091105_Ver2.1_I_E_479_009_SCS.Goto_MOD_START
--            ln_quantity := TO_NUMBER( l_in_msa_tab(1).attribute5 ) + ln_case_qty;
            ln_quantity := NVL(TO_NUMBER( l_in_msa_tab(1).attribute5 ), 0) + ln_case_qty;
--20091105_Ver2.1_I_E_479_009_SCS.Goto_MOD_END
            --
--20091105_Ver2.2_I_E_479_008_SCS.Goto_DEL_START
--            ELSIF ( iv_process_type = cv_process_type_minus ) THEN
--              -- ���Z�̏ꍇ�͓��ʉ�������}�X�^�R���g���[���A�h�I���e�[�u�����ύX�O���ʂ��擾
--              BEGIN
--                SELECT xac.mov_qty mov_qty
--                INTO   ln_quantity_before
--                FROM   xxcop_assignment_controls xac    -- ���ʉ�������}�X�^�R���g���[��
--                WHERE  xac.mov_hdr_id  = l_move_info_rec.mov_hdr_id
--                AND    xac.mov_line_id = l_move_info_rec.mov_line_id
--                AND    xac.lot_id      = l_move_info_rec.lot_id
--                ;
--                -- �P�[�X���Z
--                xxcop_common_pkg.get_case_quantity(
--                  iv_item_no               => l_move_info_rec.item_code  -- �i�ڃR�[�h
--                 ,in_individual_quantity   => ln_quantity_before         -- �o������
--                 ,in_trunc_digits          => 0                          -- �؎̂Č���
--                 ,on_case_quantity         => ln_case_qty                -- �P�[�X����
--                 ,ov_retcode               => lv_retcode                 -- ���^�[���R�[�h
--                 ,ov_errbuf                => lv_errbuf                  -- �G���[�E���b�Z�[�W
--                 ,ov_errmsg                => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
--                );
--                IF ( lv_retcode = cv_status_error ) THEN
--                  RAISE internal_process_expt;
--                END IF;
--                --
--              EXCEPTION
--                WHEN NO_DATA_FOUND THEN
--                  ln_quantity_before := 0;
--                  ln_case_qty := 0;
--                  --
--              END;
--              -- �ړ����ʂ����Z
--              ln_quantity := TO_NUMBER( l_in_msa_tab(1).attribute5 ) - ln_case_qty;
--              --
--            END IF;
--            --
--20091105_Ver2.2_I_E_479_008_SCS.Goto_DEL_END
      --==============================================================
      -- �����Z�b�gAPI�N��
      --==============================================================
            -- �����Z�b�g����PLSQL�\�̏���
            l_in_msa_tab(1).attribute5         := TO_CHAR( ln_quantity );    -- �����Z�b�g����.�ړ���(DFF5)
            l_in_msa_tab(1).operation          := cv_operation_update;       -- �����Z�b�g����.�����敪(UPDATE)
            l_in_msa_tab(1).last_update_date   := cd_last_update_date;       -- �����Z�b�g����.�ŏI�X�V��
            l_in_msa_tab(1).last_updated_by    := cn_last_updated_by;        -- �����Z�b�g����.�ŏI�X�V��
            l_in_msa_tab(1).last_update_login  := cn_last_update_login;      -- �����Z�b�g����.�ŏI�X�V���O�C��
            --
            -- �����Z�b�g�w�b�_/���ׂ̍X�V�iAPI�N���j
            mrp_src_assignment_pub.process_assignment(
               p_api_version_number     => cv_api_version
              ,p_init_msg_list          => FND_API.G_TRUE
              ,p_return_values          => FND_API.G_TRUE
              ,p_commit                 => FND_API.G_FALSE
              ,x_return_status          => lv_return_status
              ,x_msg_count              => ln_msg_count
              ,x_msg_data               => lv_msg_data
              ,p_Assignment_Set_rec     => l_in_mas_rec
              ,p_Assignment_Set_val_rec => l_mas_val_rec
              ,p_Assignment_tbl         => l_in_msa_tab
              ,p_Assignment_val_tbl     => l_msa_val_tab
              ,x_Assignment_Set_rec     => l_out_mas_rec
              ,x_Assignment_Set_val_rec => l_out_mas_val_rec
              ,x_Assignment_tbl         => l_out_msa_tab
              ,x_Assignment_val_tbl     => l_out_msa_val_tab
            );
            --
            -- �G���[�����������ꍇ
            IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
--20091105_Ver2.2_I_E_479_008_SCS.Goto_MOD_START
--              ov_errmsg := lv_msg_data;
              IF ( ln_msg_count = 1 ) THEN
                ov_errmsg := lv_msg_data;
              ELSE
                <<errmsg_loop>>
                FOR ln_err_idx IN 1 .. ln_msg_count LOOP
                  fnd_msg_pub.get(
                     p_msg_index     => ln_err_idx
                    ,p_encoded       => gv_msg_encoded
                    ,p_data          => lv_msg_data
                    ,p_msg_index_out => ln_msg_index_out
                  );
                  ov_errmsg := ov_errmsg || lv_msg_data || CHR(10) ;
                END LOOP errmsg_loop;
              END IF;
--20091105_Ver2.2_I_E_479_008_SCS.Goto_MOD_END
              RAISE api_expt;
            END IF;
            --

      --==============================================================
      -- ���ʉ�������}�X�^�R���g���[���e�[�u�����f
      --==============================================================
--20091105_Ver2.2_I_E_479_008_SCS.Goto_DEL_START
--            -- �����敪�ɂ���đ}���A�폜�𐧌�
--            IF ( iv_process_type = cv_process_type_plus ) THEN
--20091105_Ver2.2_I_E_479_008_SCS.Goto_DEL_END
            -- �����敪�����Z�̏ꍇ�̓f�[�^�o�^
            INSERT INTO xxcop_assignment_controls (
              mov_hdr_id                -- �ړ��w�b�_ID
             ,mov_num                   -- �ړ��ԍ�
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD START
             ,ship_from_code            -- �o�׌��q��
             ,ship_to_code              -- ���ɐ�q��
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD END
             ,mov_line_id               -- �ړ�����ID
             ,line_number               -- ���הԍ�
             ,lot_id                    -- ���b�gID
             ,lot_no                    -- ���b�gNo
             ,item_code                 -- �i�ڃR�[�h
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD START
             ,prod_start_date           -- �����J�n�N����
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD START
             ,arrival_date              -- ����
             ,mov_qty                   -- �ړ�����
             ,created_by                -- �쐬��
             ,creation_date             -- �쐬��
             ,last_updated_by           -- �ŏI�X�V��
             ,last_update_date          -- �ŏI�X�V����
             ,last_update_login         -- �ŏI�X�V���O�C��
             ,request_id                -- �v��ID
             ,program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,program_id                -- �R���J�����g�E�v���O����ID
             ,program_update_date       -- �v���O�����X�V��
            )VALUES(
              l_move_info_rec.mov_hdr_id    -- �ړ��w�b�_ID
             ,l_move_info_rec.mov_num       -- �ړ��ԍ�
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD START
             ,l_move_info_rec.ship_from_code  -- �o�׌��q��
             ,l_move_info_rec.ship_to_code    -- ���ɐ�q��
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD END
             ,l_move_info_rec.mov_line_id   -- �ړ�����ID
             ,l_move_info_rec.line_number   -- ���הԍ�
             ,l_move_info_rec.lot_id        -- ���b�gID
             ,l_move_info_rec.lot_no        -- ���b�gNo
             ,l_move_info_rec.item_code     -- �i�ڃR�[�h
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD START
             ,TO_DATE(l_move_info_rec.prod_start_date, 'YYYY/MM/DD')  -- �����J�n�N����
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD START
             ,TO_DATE(l_move_info_rec.arrival_date, 'YYYY/MM/DD')  -- ����
             ,l_move_info_rec.quantity      -- �ړ�����
             ,cn_created_by                 -- �쐬��
             ,cd_creation_date              -- �쐬��
             ,cn_last_updated_by            -- �ŏI�X�V��
             ,cd_last_update_date           -- �ŏI�X�V����
             ,cn_last_update_login          -- �ŏI�X�V���O�C��
             ,cn_request_id                 -- �v��ID
             ,cn_program_application_id     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,cn_program_id                 -- �R���J�����g�E�v���O����ID
             ,cd_program_update_date        -- �v���O�����X�V��
            );
            --
--20091105_Ver2.2_I_E_479_008_SCS.Goto_DEL_START
--            ELSIF ( iv_process_type = cv_process_type_minus ) THEN
--              -- �����敪�����Z�̏ꍇ�̓f�[�^�폜
--              BEGIN
--                SELECT xac.ROWID xac_rowid
--                INTO   lv_rowid
--                FROM   xxcop_assignment_controls xac
--                WHERE  xac.mov_hdr_id  = l_move_info_rec.mov_hdr_id
--                AND    xac.mov_line_id = l_move_info_rec.mov_line_id
--                AND    xac.lot_id      = l_move_info_rec.lot_id
--                FOR UPDATE NOWAIT
--                ;
--              EXCEPTION
--                WHEN NO_DATA_FOUND THEN
--                  NULL;
--                  --
--              END;
--              --
--              DELETE xxcop_assignment_controls xac
--              WHERE  xac.mov_hdr_id  = l_move_info_rec.mov_hdr_id
--              AND    xac.mov_line_id = l_move_info_rec.mov_line_id
--              AND    xac.lot_id      = l_move_info_rec.lot_id
--              ;
--            END IF;
--            --
--20091105_Ver2.2_I_E_479_008_SCS.Goto_DEL_END
          END IF;
          --
          -- �J�[�\���N���[�Y
          CLOSE l_assignments_info_cur;
        --
        END IF;
        --
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD START
        END IF;
        --
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD END
        END LOOP assignment_loop;
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada DEL START
--        --
--        IF ( ln_loop_cnt < 1 ) THEN
--          ov_errbuf        := NULL;
--          ov_errmsg        := xxccp_common_pkg.get_msg(
--                                 iv_application  => cv_msg_application
--                                ,iv_name         => cv_message_00003
--                                );
--          ov_retcode       := cv_status_error;
--          RETURN;
--          -- �J�[�\���N���[�Y
--          CLOSE l_move_info_cur;
--          --
--        END IF;
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada DEL END
      -- �J�[�\���N���[�Y
      CLOSE l_move_info_cur;
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_START
    ELSIF ( iv_process_type = cv_process_type_minus ) THEN
      OPEN l_remove_info_cur;
      << remove_assignment_loop >>
      LOOP
        FETCH l_remove_info_cur INTO l_remove_info_rec;
        EXIT WHEN l_remove_info_cur%NOTFOUND;
--
      --==============================================================
      -- ���ʉ�������}�X�^���̎擾
      --==============================================================
        OPEN l_assignments_info_cur (
           l_remove_info_rec.ship_from_code
          ,l_remove_info_rec.ship_to_code
          ,l_remove_info_rec.arrival_date
          ,l_remove_info_rec.item_code
          ,l_remove_info_rec.quantity
          ,l_remove_info_rec.prod_start_date
          );
        FETCH l_assignments_info_cur INTO 
          l_in_mas_rec.assignment_set_id          -- �����Z�b�g�w�b�_.�����Z�b�g�w�b�_ID
         ,l_in_mas_rec.assignment_set_name        -- �����Z�b�g�w�b�_.�����Z�b�g��
         ,l_in_mas_rec.creation_date              -- �����Z�b�g�w�b�_.�쐬��
         ,l_in_mas_rec.created_by                 -- �����Z�b�g�w�b�_.�쐬��
         ,l_in_mas_rec.description                -- �����Z�b�g�w�b�_.�����Z�b�g�E�v
         ,l_in_mas_rec.attribute_category         -- �����Z�b�g�w�b�_.Attribute_Category
         ,l_in_mas_rec.attribute1                 -- �����Z�b�g�w�b�_.�����Z�b�g�敪(DFF1)
         ,l_in_mas_rec.attribute2                 -- �����Z�b�g�w�b�_.DFF2
         ,l_in_mas_rec.attribute3                 -- �����Z�b�g�w�b�_.DFF3
         ,l_in_mas_rec.attribute4                 -- �����Z�b�g�w�b�_.DFF4
         ,l_in_mas_rec.attribute5                 -- �����Z�b�g�w�b�_.DFF5
         ,l_in_mas_rec.attribute6                 -- �����Z�b�g�w�b�_.DFF6
         ,l_in_mas_rec.attribute7                 -- �����Z�b�g�w�b�_.DFF7
         ,l_in_mas_rec.attribute8                 -- �����Z�b�g�w�b�_.DFF8
         ,l_in_mas_rec.attribute9                 -- �����Z�b�g�w�b�_.DFF9
         ,l_in_mas_rec.attribute10                -- �����Z�b�g�w�b�_.DFF10
         ,l_in_mas_rec.attribute11                -- �����Z�b�g�w�b�_.DFF11
         ,l_in_mas_rec.attribute12                -- �����Z�b�g�w�b�_.DFF12
         ,l_in_mas_rec.attribute13                -- �����Z�b�g�w�b�_.DFF13
         ,l_in_mas_rec.attribute14                -- �����Z�b�g�w�b�_.DFF14
         ,l_in_mas_rec.attribute15                -- �����Z�b�g�w�b�_.DFF15
         ,l_in_msa_tab(1).assignment_id           -- �����Z�b�g����.�����Z�b�g����ID
         ,l_in_msa_tab(1).assignment_type         -- �����Z�b�g����.������^�C�v
         ,l_in_msa_tab(1).sourcing_rule_id        -- �����Z�b�g����.�\�[�X���[��ID
         ,l_in_msa_tab(1).sourcing_rule_type      -- �����Z�b�g����.�����\���\/�\�[�X���[���^�C�v
         ,l_in_msa_tab(1).assignment_set_id       -- �����Z�b�g����.�����Z�b�g�w�b�_ID
         ,l_in_msa_tab(1).creation_date           -- �����Z�b�g����.�쐬��
         ,l_in_msa_tab(1).created_by              -- �����Z�b�g����.�쐬��
         ,l_in_msa_tab(1).organization_id         -- �����Z�b�g����.�g�DID
         ,l_in_msa_tab(1).customer_id             -- �����Z�b�g����.Customer_Id
         ,l_in_msa_tab(1).ship_to_site_id         -- �����Z�b�g����.Ship_To_Site_Id
         ,l_in_msa_tab(1).category_id             -- �����Z�b�g����.Category_Id
         ,l_in_msa_tab(1).category_set_id         -- �����Z�b�g����.Category_Set_Id
         ,l_in_msa_tab(1).inventory_item_id       -- �����Z�b�g����.�i��ID
         ,l_in_msa_tab(1).secondary_inventory     -- �����Z�b�g����.Secondary_Inventory
         ,l_in_msa_tab(1).attribute_category      -- �����Z�b�g����.�����Z�b�g�敪
         ,l_in_msa_tab(1).attribute1              -- �����Z�b�g����.�J�n�����N����(DFF1)
         ,l_in_msa_tab(1).attribute2              -- �����Z�b�g����.�L���J�n��(DFF2)
         ,l_in_msa_tab(1).attribute3              -- �����Z�b�g����.�L���I����(DFF3)
         ,l_in_msa_tab(1).attribute4              -- �����Z�b�g����.�ݒ萔��(DFF4)
         ,l_in_msa_tab(1).attribute5              -- �����Z�b�g����.�ړ���(DFF5)
         ,l_in_msa_tab(1).attribute6              -- �����Z�b�g����.DFF6
         ,l_in_msa_tab(1).attribute7              -- �����Z�b�g����.DFF7
         ,l_in_msa_tab(1).attribute8              -- �����Z�b�g����.DFF8
         ,l_in_msa_tab(1).attribute9              -- �����Z�b�g����.DFF9
         ,l_in_msa_tab(1).attribute10             -- �����Z�b�g����.DFF10
         ,l_in_msa_tab(1).attribute11             -- �����Z�b�g����.DFF11
         ,l_in_msa_tab(1).attribute12             -- �����Z�b�g����.DFF12
         ,l_in_msa_tab(1).attribute13             -- �����Z�b�g����.DFF13
         ,l_in_msa_tab(1).attribute14             -- �����Z�b�g����.DFF14
         ,l_in_msa_tab(1).attribute15             -- �����Z�b�g����.DFF15
         ;
        --
        -- �Ώۃf�[�^�����݂���ꍇ
        IF ( l_assignments_info_cur%FOUND ) THEN
          -- �����Z�b�g�EAPI�W�����R�[�h�^�C�v�̏���
          l_in_mas_rec.operation         := cv_operation_update;      -- �����Z�b�g�w�b�_.�����敪(UPDATE)
          l_in_mas_rec.last_update_date  := cd_last_update_date;      -- �����Z�b�g�w�b�_.�ŏI�X�V��
          l_in_mas_rec.last_updated_by   := cn_last_updated_by;       -- �����Z�b�g�w�b�_.�ŏI�X�V��
          l_in_mas_rec.last_update_login := cn_last_update_login;     -- �����Z�b�g�w�b�_.�ŏI�X�V���O�C��
          -- �P�[�X���Z
          xxcop_common_pkg.get_case_quantity(
            iv_item_no               => l_remove_info_rec.item_code   -- �i�ڃR�[�h
           ,in_individual_quantity   => l_remove_info_rec.quantity    -- �o������
           ,in_trunc_digits          => 0                             -- �؎̂Č���
           ,on_case_quantity         => ln_case_qty                   -- �P�[�X����
           ,ov_retcode               => lv_retcode                    -- ���^�[���R�[�h
           ,ov_errbuf                => lv_errbuf                     -- �G���[�E���b�Z�[�W
           ,ov_errmsg                => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE internal_process_expt;
          END IF;
          -- �ړ����ʂ����Z
          ln_quantity := NVL(TO_NUMBER( l_in_msa_tab(1).attribute5 ), 0) - ln_case_qty;
          --
      --==============================================================
      -- �����Z�b�gAPI�N��
      --==============================================================
          -- �����Z�b�g����PLSQL�\�̏���
          l_in_msa_tab(1).attribute5         := TO_CHAR( ln_quantity );    -- �����Z�b�g����.�ړ���(DFF5)
          l_in_msa_tab(1).operation          := cv_operation_update;       -- �����Z�b�g����.�����敪(UPDATE)
          l_in_msa_tab(1).last_update_date   := cd_last_update_date;       -- �����Z�b�g����.�ŏI�X�V��
          l_in_msa_tab(1).last_updated_by    := cn_last_updated_by;        -- �����Z�b�g����.�ŏI�X�V��
          l_in_msa_tab(1).last_update_login  := cn_last_update_login;      -- �����Z�b�g����.�ŏI�X�V���O�C��
          --
          -- �����Z�b�g�w�b�_/���ׂ̍X�V�iAPI�N���j
          mrp_src_assignment_pub.process_assignment(
             p_api_version_number     => cv_api_version
            ,p_init_msg_list          => FND_API.G_TRUE
            ,p_return_values          => FND_API.G_TRUE
            ,p_commit                 => FND_API.G_FALSE
            ,x_return_status          => lv_return_status
            ,x_msg_count              => ln_msg_count
            ,x_msg_data               => lv_msg_data
            ,p_Assignment_Set_rec     => l_in_mas_rec
            ,p_Assignment_Set_val_rec => l_mas_val_rec
            ,p_Assignment_tbl         => l_in_msa_tab
            ,p_Assignment_val_tbl     => l_msa_val_tab
            ,x_Assignment_Set_rec     => l_out_mas_rec
            ,x_Assignment_Set_val_rec => l_out_mas_val_rec
            ,x_Assignment_tbl         => l_out_msa_tab
            ,x_Assignment_val_tbl     => l_out_msa_val_tab
          );
          --
          -- �G���[�����������ꍇ
          IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
            IF ( ln_msg_count = 1 ) THEN
              ov_errmsg := lv_msg_data;
            ELSE
              <<errmsg_loop>>
              FOR ln_err_idx IN 1 .. ln_msg_count LOOP
                fnd_msg_pub.get(
                   p_msg_index     => ln_err_idx
                  ,p_encoded       => gv_msg_encoded
                  ,p_data          => lv_msg_data
                  ,p_msg_index_out => ln_msg_index_out
                );
                ov_errmsg := ov_errmsg || lv_msg_data || CHR(10) ;
              END LOOP errmsg_loop;
            END IF;
            RAISE api_expt;
          END IF;
          --
          DELETE xxcop_assignment_controls xac
          WHERE  xac.ROWID  = l_remove_info_rec.xac_rowid
          ;
        END IF;
        --
        -- �J�[�\���N���[�Y
        CLOSE l_assignments_info_cur;
      END LOOP remove_assignment_loop;
      --
      -- �J�[�\���N���[�Y
      CLOSE l_remove_info_cur;
    END IF;
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_END
--
  EXCEPTION
    WHEN internal_process_expt THEN
      IF ( l_move_info_cur%ISOPEN ) THEN
        CLOSE l_move_info_cur;
      END IF;
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_START
      IF ( l_remove_info_cur%ISOPEN ) THEN
        CLOSE l_remove_info_cur;
      END IF;
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_END
      IF ( l_assignments_info_cur%ISOPEN ) THEN
        CLOSE l_assignments_info_cur;
      END IF;
      ov_errmsg  := NULL;
      ov_errbuf  := NVL(lv_errbuf,lv_errmsg);
      ov_retcode := cv_status_error;
      --
    -- API�N���ŃG���[
    WHEN api_expt THEN
      IF ( l_move_info_cur%ISOPEN ) THEN
        CLOSE l_move_info_cur;
      END IF;
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_START
      IF ( l_remove_info_cur%ISOPEN ) THEN
        CLOSE l_remove_info_cur;
      END IF;
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_END
      IF ( l_assignments_info_cur%ISOPEN ) THEN
        CLOSE l_assignments_info_cur;
      END IF;
      ov_retcode       := cv_status_error;
      --
    -- ���̑���O�G���[
    WHEN OTHERS THEN
      IF ( l_move_info_cur%ISOPEN ) THEN
        CLOSE l_move_info_cur;
      END IF;
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_START
      IF ( l_remove_info_cur%ISOPEN ) THEN
        CLOSE l_remove_info_cur;
      END IF;
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_END
      IF ( l_assignments_info_cur%ISOPEN ) THEN
        CLOSE l_assignments_info_cur;
      END IF;
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      --
  END upd_assignment;
  --
  /**********************************************************************************
   * Procedure Name   : get_loct_info
   * Description      : �q�ɏ��擾����
   ***********************************************************************************/
  PROCEDURE get_loct_info(
    id_target_date          IN  DATE,         -- �Ώۓ��t
    in_organization_id      IN  NUMBER,       -- �g�DID
    ov_organization_code    OUT VARCHAR2,     -- �g�D�R�[�h
    ov_organization_name    OUT VARCHAR2,     -- �g�D����
    on_loct_id              OUT NUMBER,       -- �ۊǑq��ID
    ov_loct_code            OUT VARCHAR2,     -- �ۊǑq�ɃR�[�h
    ov_loct_name            OUT VARCHAR2,     -- �ۊǑq�ɖ���
    ov_calendar_code        OUT VARCHAR2,     -- �J�����_�R�[�h
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'get_loct_info'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�U�[��`��O ***
    no_loct_info            EXCEPTION;                        -- �ۊǏꏊ�擾�G���[
--
    -- *** ���[�J���萔 ***
    cn_del_mark_n  CONSTANT NUMBER       := 0;                -- �L��
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
--
    --======================================================
    -- �q�ɃR�[�h�擾
    --======================================================
    BEGIN
      SELECT mp.organization_code  -- �g�D�R�[�h
            ,haou.name             -- �g�D��
      INTO   ov_organization_code
            ,ov_organization_name
      FROM   hr_all_organization_units haou  -- �g�D�}�X�^
            ,mtl_parameters            mp    -- �g�D�p�����[�^
      WHERE  id_target_date       BETWEEN NVL( haou.date_from, id_target_date )
                                  AND     NVL( haou.date_to  , id_target_date )
      AND    mp.organization_id   = haou.organization_id
      AND    haou.organization_id = in_organization_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE NO_DATA_FOUND;
    END;
    --
    --======================================================
    -- �ۊǏꏊ�R�[�h�擾
    --======================================================
    BEGIN
      SELECT location_id
            ,location_code
            ,location_name
            ,calendar_code
      INTO   on_loct_id
            ,ov_loct_code
            ,ov_loct_name
            ,ov_calendar_code
      FROM   (SELECT mil.inventory_location_id  location_id
                    ,mil.segment1               location_code
                    ,ilm.loct_desc              location_name
                    ,mil.attribute10            calendar_code
                    ,RANK() OVER(PARTITION BY ilm.whse_code
                                 ORDER BY     NVL(mil.attribute4,0) DESC  -- �o�׈����Ώۃt���O
                                             ,ilm.location                -- �ۊǏꏊ�R�[�h
                                )               frequent_rank             -- �����N
              FROM   mtl_item_locations  mil  -- OPM�ۊǏꏊ�}�X�^
                    ,ic_loct_mst         ilm  -- OPM�ۊǑq�Ƀ}�X�^
                    ,ic_whse_mst         iwm  -- OPM�q�Ƀ}�X�^
              WHERE  iwm.mtl_organization_id   = mil.organization_id
              AND    iwm.delete_mark           = cn_del_mark_n
              AND    mil.inventory_location_id = ilm.inventory_location_id
              AND    ilm.delete_mark           = cn_del_mark_n
              AND    id_target_date           <= NVL( mil.disable_date, id_target_date )
              AND    mil.organization_id       = in_organization_id
             ) loct_info
      WHERE  loct_info.frequent_rank = '1'
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE no_loct_info;
    END;
    --
  EXCEPTION
    WHEN no_loct_info THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_loct_id       := NULL;
      ov_loct_code     := NULL;
      ov_loct_name     := NULL;
      ov_calendar_code := NULL;
    WHEN NO_DATA_FOUND THEN
      ov_retcode            := cv_status_error;
      ov_errbuf             := NULL;
      ov_errmsg             := NULL;
      ov_organization_code  := NULL;
      ov_organization_name  := NULL;
      on_loct_id            := NULL;
      ov_loct_code          := NULL;
      ov_loct_name          := NULL;
      ov_calendar_code      := NULL;
    WHEN OTHERS THEN
      ov_retcode   := cv_status_error;
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg    := NULL;
  END get_loct_info;
  --
  /**********************************************************************************
   * Procedure Name   : get_critical_date_f
   * Description      : �N�x��������擾����
   ***********************************************************************************/
  FUNCTION get_critical_date_f(
     iv_freshness_class        IN     VARCHAR2    -- �N�x��������
    ,in_freshness_check_value  IN     NUMBER      -- �N�x�����`�F�b�N�l
    ,in_freshness_adjust_value IN     NUMBER      -- �N�x���������l
    ,in_max_stock_days         IN     NUMBER      -- �ő�݌ɓ���
    ,in_freshness_buffer_days  IN     NUMBER      -- �N�x�����o�b�t�@����
    ,id_manufacture_date       IN     DATE        -- �����N����
    ,id_expiration_date        IN     DATE        -- �ܖ�����
  ) RETURN DATE IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_critical_date_f'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_general                  CONSTANT VARCHAR2(1)   := '0';     -- ���
    cv_expiration               CONSTANT VARCHAR2(1)   := '1';     -- �ܖ������
    cv_manufacture              CONSTANT VARCHAR2(1)   := '2';     -- �������
    cd_max_date                 CONSTANT DATE          := TO_DATE('9999/12/31', 'YYYY/MM/DD');
--
    -- *** ���[�J���ϐ� ***
    ln_critical_value                    NUMBER;                   -- ��l
    lv_expt_value                        VARCHAR2(100);            -- ��O�p�����[�^
    ld_critical_date                     DATE;                     -- ���
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    --��O��`
--
  BEGIN
  --
    --
    IF ( id_expiration_date IS NULL ) THEN
      --�ܖ�������NULL�͍w���v��A�H��o�׌v�惍�b�g�̂��ߍő�l��߂�
      ld_critical_date := cd_max_date;
    ELSE
      --�N�x��������:���
      IF ( iv_freshness_class = cv_general ) THEN
        --��l�̌v�Z
        ln_critical_value := in_freshness_check_value;
        --����̌v�Z
        ld_critical_date := id_expiration_date
                          + NVL(ln_critical_value,0)
                          + NVL(in_freshness_adjust_value, 0)
                          - ( in_max_stock_days + in_freshness_buffer_days )
        ;
      END IF;
  --
      --�N�x��������:�ܖ������
      IF ( iv_freshness_class = cv_expiration ) THEN
        --��l�̌v�Z
        ln_critical_value := TRUNC(( id_expiration_date - id_manufacture_date )
                                   / in_freshness_check_value);
        --����̌v�Z
        ld_critical_date := id_manufacture_date
                          + NVL(ln_critical_value,0)
                          + NVL(in_freshness_adjust_value, 0)
                          - ( in_max_stock_days + in_freshness_buffer_days )
        ;
      END IF;
  --
      --�N�x��������:�������
      IF ( iv_freshness_class = cv_manufacture ) THEN
        --��l�̌v�Z
        ln_critical_value := in_freshness_check_value;
        --����̌v�Z
        ld_critical_date := id_manufacture_date
                          + NVL(ln_critical_value,0)
                          + NVL(in_freshness_adjust_value, 0)
                          - ( in_max_stock_days + in_freshness_buffer_days )
        ;
      END IF;
    END IF;
  --
    RETURN ld_critical_date;
--
  END get_critical_date_f;
  --
  /**********************************************************************************
   * Procedure Name   : get_delivery_unit
   * Description      : �z���P�ʎ擾����
   ***********************************************************************************/
  PROCEDURE get_delivery_unit(
     in_shipping_pace          IN     NUMBER      -- �o�׃y�[�X
    ,in_palette_max_cs_qty     IN     NUMBER      -- �z��
    ,in_palette_max_step_qty   IN     NUMBER      -- �i��
    ,ov_unit_delivery          OUT    VARCHAR2    -- �z���P��
    ,ov_errbuf                 OUT    VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode                OUT    VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg                 OUT    VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  ) IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_delivery_unit'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_unit_delivery            CONSTANT VARCHAR2(100) := 'XXCOP1_UNIT_DELIVERY';   -- �N�C�b�N�R�[�h��
    cv_enable                   CONSTANT VARCHAR2(100) := 'Y';                      -- �L���t���O
    --�z���P��
    cv_unit_palette             CONSTANT VARCHAR2(10)  := '1';                      -- �p���b�g
    cv_unit_step                CONSTANT VARCHAR2(10)  := '2';                      -- �i
    cv_unit_case                CONSTANT VARCHAR2(10)  := '3';                      -- �P�[�X
--
    -- *** ���[�J���ϐ� ***
    ld_process_date             DATE;
    ln_unit_quantity            NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    --�z���P�ʂ̊��
    CURSOR flv_cur IS
      SELECT flv.lookup_code  lookup_code       -- �R�[�h
            ,flv.meaning      meaning           -- ���e
            ,flv.description  description       -- �E�v
      FROM fnd_lookup_values  flv               -- �N�C�b�N�R�[�h
      WHERE flv.lookup_type            = cv_unit_delivery
        AND flv.language               = cv_lang
        AND flv.source_lang            = cv_lang
        AND flv.enabled_flag           = cv_enable
        AND ld_process_date BETWEEN NVL(flv.start_date_active, ld_process_date)
                                AND NVL(flv.end_date_active, ld_process_date)
      ORDER BY flv.lookup_code ASC;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
    --
    --�Ɩ����t�̎擾
    ld_process_date  :=  xxccp_common_pkg2.get_process_date;
--
    <<unit_loop>>
    FOR flv_rec IN flv_cur LOOP
      CASE
        WHEN flv_rec.lookup_code = cv_unit_palette THEN
          --�p���b�g�̊���Ŕ���
          ln_unit_quantity := in_shipping_pace / ( in_palette_max_cs_qty * in_palette_max_step_qty );
        WHEN flv_rec.lookup_code = cv_unit_step THEN
          --�i�̊���Ŕ���
          ln_unit_quantity := in_shipping_pace / in_palette_max_cs_qty;
        WHEN flv_rec.lookup_code = cv_unit_case THEN
          --�P�[�X�̊���Ŕ���
          ln_unit_quantity := in_shipping_pace;
      END CASE;
      IF ( ln_unit_quantity > TO_NUMBER(flv_rec.description) ) THEN
        ov_unit_delivery := flv_rec.meaning;
        EXIT unit_loop;
      END IF;
    END LOOP unit_loop;
--
  EXCEPTION
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      ov_unit_delivery := NULL;
  END get_delivery_unit;
--
  /**********************************************************************************
   * Function Name   : get_receipt_date
   * Description      : �����擾����
   ***********************************************************************************/
  PROCEDURE get_receipt_date(
    iv_calendar_code   IN     VARCHAR2       --   ��������޺���
   ,in_organization_id IN     NUMBER         --   �g�DID
   ,in_loct_id         IN     NUMBER         --   �ۊǑq��ID
   ,id_shipment_date   IN     DATE           --   �o�ד�
   ,in_lead_time       IN     NUMBER         --   �z��ذ�����
   ,od_receipt_date    OUT    DATE           --   ����
   ,ov_errbuf          OUT    VARCHAR2       --   �װ�ү����           --# �Œ� #
   ,ov_retcode         OUT    VARCHAR2       --   ���ݥ����             --# �Œ� #
   ,ov_errmsg          OUT    VARCHAR2       --   հ�ް��װ�ү���� --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ�۰�ْ萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_receipt_date'; -- ��۸��і�
--
--#####################  �Œ�۰�ٕϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �װ�ү����
    lv_retcode VARCHAR2(1);     -- ���ݥ����
    lv_errmsg  VARCHAR2(5000);  -- հ�ް��װ�ү����
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- հ�ް�錾��
    -- ===============================
    -- *** ۰�ْ萔 ***
    cn_active     CONSTANT NUMBER := 0;
--
    -- *** ۰�ٕϐ� ***
    lt_calendar_code mtl_parameters.calendar_code%TYPE := NULL;
--
    -- *** ۰�٥���� ***
--
    -- *** ۰�٥ں��� ***
--
--
  BEGIN
--
--##################  �Œ�ð���������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    IF ( iv_calendar_code IS NULL ) THEN
      -- ===============================
      -- �J�����_�[�R�[�h�擾
      -- ===============================
      BEGIN
        SELECT mil.attribute10
        INTO   lt_calendar_code
        FROM   mtl_item_locations mil
        WHERE  mil.organization_id        = in_organization_id
          AND  mil.inventory_location_id  = in_loct_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lt_calendar_code := NULL;
        --
      END;
      --
      -- �J�����_�R�[�h���擾�ł��Ȃ������ꍇ�̓v���t�@�C���̃h�����N��J�����_��ݒ肷��B
      IF lt_calendar_code IS NULL THEN
        lt_calendar_code := FND_PROFILE.VALUE( cv_cmn_drink_cal_cd );
        --
        IF ( lt_calendar_code IS NULL ) THEN
          ov_errbuf        := NULL;
          ov_errmsg        := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_application
                                ,iv_name         => cv_message_00002
                                ,iv_token_name1  => cv_message_00002_token_1
                                ,iv_token_value1 => cv_cmn_drink_cal_cd_name
                                );
          od_receipt_date  := NULL;
          ov_retcode       := cv_status_error;
          RETURN;
        END IF;
        --
      END IF;
    ELSE
      lt_calendar_code := iv_calendar_code;
    END IF;
--
    -- ===============================
    -- �ғ�������ގQ��
    -- ===============================
    IF (in_lead_time = 0 ) THEN
      --�z��ذ����т�0��
      SELECT calendar_date
      INTO   od_receipt_date
      FROM (
        SELECT msd.calendar_date
        FROM   mr_shcl_hdr msh    -- ���������ͯ��
              ,mr_shcl_dtl msd    -- ��������ޖ���
        WHERE  msh.calendar_no    = lt_calendar_code
          AND  msh.calendar_id    = msd.calendar_id
          AND  msd.delete_mark    = cn_active
          AND  msd.calendar_date >= id_shipment_date
          AND  msd.calendar_date  < ADD_MONTHS(id_shipment_date, 1)
        ORDER BY msd.calendar_date
      )
      WHERE ROWNUM <= 1
      ;
    ELSE
      --�z��ذ����т�1���ȏ�
      SELECT MAX(calendar_date)
      INTO   od_receipt_date
      FROM (
        SELECT msd.calendar_date
        FROM   mr_shcl_hdr msh    -- ���������ͯ��
              ,mr_shcl_dtl msd    -- ��������ޖ���
        WHERE  msh.calendar_no    =  lt_calendar_code
          AND  msh.calendar_id    =  msd.calendar_id
          AND  msd.delete_mark    =  cn_active
          AND  msd.calendar_date  > id_shipment_date
          AND  msd.calendar_date  < ADD_MONTHS(id_shipment_date, 1)
        ORDER BY msd.calendar_date
      )
      WHERE ROWNUM <= in_lead_time
      ;
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      od_receipt_date  := NULL;
--
  END get_receipt_date;
--
  /**********************************************************************************
   * Function Name   : get_shipment_date
   * Description      : �o�ד��擾����
   ***********************************************************************************/
  PROCEDURE get_shipment_date(
    iv_calendar_code   IN     VARCHAR2   --   �����J�����_�R�[�h
   ,in_organization_id IN     NUMBER     --   �g�DID
   ,in_loct_id         IN     NUMBER     --   �ۊǑq��ID
   ,id_receipt_date    IN     DATE       --   ����
   ,in_lead_time       IN     NUMBER     --   �z�����[�h�^�C��
   ,od_shipment_date   OUT    DATE       --   �o�ד�
   ,ov_errbuf          OUT    VARCHAR2   --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode         OUT    VARCHAR2   --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg          OUT    VARCHAR2   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_shipment_date'; -- �v���O������
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
    cn_active     CONSTANT NUMBER := 0;
--
    -- *** ���[�J���ϐ� ***
    lt_calendar_code mtl_parameters.calendar_code%TYPE DEFAULT NULL;
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
    IF ( iv_calendar_code IS NULL ) THEN
      -- ===============================
      -- �J�����_�[�R�[�h�擾
      -- ===============================
      BEGIN
        SELECT mil.attribute10
        INTO   lt_calendar_code
        FROM   mtl_item_locations mil
        WHERE  mil.organization_id        = in_organization_id
          AND  mil.inventory_location_id  = in_loct_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lt_calendar_code := NULL;
        --
      END;
      --
      -- �J�����_�R�[�h���擾�ł��Ȃ������ꍇ�̓v���t�@�C���̃h�����N��J�����_��ݒ肷��B
      IF ( lt_calendar_code IS NULL ) THEN
        lt_calendar_code := FND_PROFILE.VALUE( cv_cmn_drink_cal_cd );
        --
        IF ( lt_calendar_code IS NULL ) THEN
          ov_errbuf        := NULL;
          ov_errmsg        := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_application
                                ,iv_name         => cv_message_00002
                                ,iv_token_name1  => cv_message_00002_token_1
                                ,iv_token_value1 => cv_cmn_drink_cal_cd_name
                                );
          od_shipment_date := NULL;
          ov_retcode       := cv_status_error;
          RETURN;
        END IF;
        --
      END IF;
    ELSE
      lt_calendar_code := iv_calendar_code;
    END IF;
--
    -- ===============================
    -- �ғ����J�����_�Q��
    -- ===============================
    IF (in_lead_time = 0 ) THEN
      --�z�����[�h�^�C����0��
      SELECT calendar_date
      INTO   od_shipment_date
      FROM (
        SELECT msd.calendar_date
        FROM   mr_shcl_hdr msh    -- �����J�����_�w�b�_
              ,mr_shcl_dtl msd    -- �����J�����_����
        WHERE  msh.calendar_no    = lt_calendar_code
          AND  msh.calendar_id    = msd.calendar_id
          AND  msd.delete_mark    = cn_active
          AND  msd.calendar_date <= id_receipt_date
        ORDER BY msd.calendar_date DESC
      )
      WHERE ROWNUM <= 1
      ;
    ELSE
      --�z�����[�h�^�C����1���ȏ�
      SELECT MIN(calendar_date)
      INTO   od_shipment_date
      FROM (
        SELECT msd.calendar_date
        FROM   mr_shcl_hdr msh    -- �����J�����_�w�b�_
              ,mr_shcl_dtl msd    -- �����J�����_����
        WHERE  msh.calendar_no    = lt_calendar_code
          AND  msh.calendar_id    = msd.calendar_id
          AND  msd.delete_mark    = cn_active
          AND  msd.calendar_date  < id_receipt_date
        ORDER BY msd.calendar_date DESC
      )
      WHERE ROWNUM <= in_lead_time
      ;
    END IF;
  EXCEPTION
--
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      od_shipment_date := NULL;
--
  END get_shipment_date;
--
  /**********************************************************************************
   * Function Name   : get_item_category_f
   * Description      : �i�ڃJ�e�S���擾
   ***********************************************************************************/
  FUNCTION get_item_category_f(
     iv_category_set           IN     VARCHAR2    -- �i�ڃJ�e�S����
    ,in_item_id                IN     NUMBER      -- �i��ID
  ) RETURN VARCHAR2 IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_category_f'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_category_value      VARCHAR2(100);                          -- �i�ڃJ�e�S���l
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
  --
    SELECT mcb.segment1            -- �i�ڃJ�e�S���l
    INTO   lv_category_value
    FROM   gmi_item_categories       gic
          ,mtl_categories_b          mcb
          ,mtl_category_sets_tl      mcst
    WHERE  gic.category_id        = mcb.category_id
      AND  gic.category_set_id    = mcst.category_set_id
      AND  mcst.source_lang       = cv_lang
      AND  mcst.language          = cv_lang
      AND  mcst.category_set_name = iv_category_set
      AND  gic.item_id            = in_item_id
    ;
--
    RETURN lv_category_value;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
  END get_item_category_f;
--
  /**********************************************************************************
   * Function Name   : get_last_arrival_date_f
   * Description      : �ŏI���ɓ��擾
   ***********************************************************************************/
  FUNCTION get_last_arrival_date_f(
    in_rcpt_loct_id         IN     NUMBER,     --   �ړ���ۊǑq��ID
    in_ship_loct_id         IN     NUMBER,     --   �ړ����ۊǑq��ID
    in_item_id              IN     NUMBER      --   �i��ID
  ) RETURN DATE IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_last_arrival_date_f'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_mov_status_receipt  CONSTANT VARCHAR2(2) := '05';  -- �ړ��X�e�[�^�X�F���ɕ񍐗L
    cv_mov_status_ship     CONSTANT VARCHAR2(2) := '06';  -- �ړ��X�e�[�^�X�F���o�ɕ񍐗L
    cv_doc_type            CONSTANT VARCHAR2(2) := '20';  -- �����^�C�v�F�ړ�
    cv_rec_type            CONSTANT VARCHAR2(2) := '30';  -- ���R�[�h�^�C�v�F���Ɏ���
    cv_yes                 CONSTANT VARCHAR2(1) := 'Y';
    cv_no                  CONSTANT VARCHAR2(1) := 'N';
    cd_min_date            CONSTANT DATE        := TO_DATE('1900/01/01','YYYY/MM/DD');
--
    -- *** ���[�J���ϐ� ***
    ld_actual_arrival_date          DATE;      -- ���ɓ�
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
  --
    SELECT MAX(actual_arrival_date)       actual_arrival_date
    INTO   ld_actual_arrival_date
    FROM (
      SELECT mrih.actual_arrival_date     actual_arrival_date  -- ���Ɏ��ѓ�
      FROM   ic_item_mst_b               iimb                  -- OPM�i�ڃ}�X�^
            ,mtl_item_locations          mil_r                 -- OPM�ۊǏꏊ�}�X�^(����)
            ,ic_whse_mst                 iwm_r                 -- OPM�q�Ƀ}�X�^(����)
            ,mtl_item_locations          mil_s                 -- OPM�ۊǏꏊ�}�X�^(�o��)
            ,ic_whse_mst                 iwm_s                 -- OPM�q�Ƀ}�X�^(�o��)
            ,ic_lots_mst                 ilm                   -- OPM���b�g�}�X�^
            ,xxinv_mov_req_instr_headers mrih                  -- �ړ��˗�/�w���w�b�_
            ,xxinv_mov_req_instr_lines   mril                  -- �ړ��˗�/�w������
            ,xxinv_mov_lot_details       mld                   -- �ړ����b�g�ڍ�
      WHERE  ilm.item_id                 = iimb.item_id
        AND  ilm.lot_id                 <> 0
        AND  iwm_r.mtl_organization_id   = mil_r.organization_id
        AND  mrih.ship_to_locat_id       = mil_r.inventory_location_id
        AND  iwm_s.mtl_organization_id   = mil_s.organization_id
        AND  mrih.shipped_locat_id       = mil_s.inventory_location_id
        AND  mrih.correct_actual_flg     = cv_no
        AND  mrih.status                IN (cv_mov_status_receipt,cv_mov_status_ship)
        AND  mrih.mov_hdr_id             = mril.mov_hdr_id
        AND  mril.mov_line_id            = mld.mov_line_id
        AND  mril.delete_flg             = cv_no
        AND  mld.item_id                 = iimb.item_id
        AND  mld.lot_id                  = ilm.lot_id
        AND  mld.document_type_code      = cv_doc_type
        AND  mld.record_type_code        = cv_rec_type
        AND  mil_r.inventory_location_id = in_rcpt_loct_id
        AND  mil_s.inventory_location_id = in_ship_loct_id
        AND  iimb.item_id                = in_item_id
      UNION ALL
      SELECT mrih.actual_arrival_date     actual_arrival_date  -- ���Ɏ��ѓ�
      FROM   ic_item_mst_b               iimb                  -- OPM�i�ڃ}�X�^
            ,mtl_item_locations          mil_r                 -- OPM�ۊǏꏊ�}�X�^(����)
            ,ic_whse_mst                 iwm_r                 -- OPM�q�Ƀ}�X�^(����)
            ,mtl_item_locations          mil_s                 -- OPM�ۊǏꏊ�}�X�^(�o��)
            ,ic_whse_mst                 iwm_s                 -- OPM�q�Ƀ}�X�^(�o��)
            ,ic_lots_mst                 ilm                   -- OPM���b�g�}�X�^
            ,xxinv_mov_req_instr_headers mrih                  -- �ړ��˗�/�w���w�b�_
            ,xxinv_mov_req_instr_lines   mril                  -- �ړ��˗�/�w������
            ,xxinv_mov_lot_details       mld                   -- �ړ����b�g�ڍ�
      WHERE  ilm.item_id                 = iimb.item_id
        AND  ilm.lot_id                 <> 0
        AND  iwm_r.mtl_organization_id   = mil_r.organization_id
        AND  mrih.ship_to_locat_id       = mil_r.inventory_location_id
        AND  iwm_s.mtl_organization_id   = mil_s.organization_id
        AND  mrih.shipped_locat_id       = mil_s.inventory_location_id
        AND  mrih.correct_actual_flg     = cv_yes
        AND  mrih.status                 = cv_mov_status_ship
        AND  mrih.mov_hdr_id             = mril.mov_hdr_id
        AND  mril.mov_line_id            = mld.mov_line_id
        AND  mril.delete_flg             = cv_no
        AND  mld.item_id                 = iimb.item_id
        AND  mld.lot_id                  = ilm.lot_id
        AND  mld.document_type_code      = cv_doc_type
        AND  mld.record_type_code        = cv_rec_type
        AND  mil_r.inventory_location_id = in_rcpt_loct_id
        AND  mil_s.inventory_location_id = in_ship_loct_id
        AND  iimb.item_id                = in_item_id
    );
--
    -- �擾�ł��Ȃ������ꍇ�͍ŏ����t��ݒ�
    IF ( ld_actual_arrival_date IS NULL ) THEN
      ld_actual_arrival_date := cd_min_date;
    END IF;
    --
    RETURN ld_actual_arrival_date;
--
  END get_last_arrival_date_f;
--
  /**********************************************************************************
   * Function Name   : get_last_purchase_date_f
   * Description      : �ŏI�w�����擾
   ***********************************************************************************/
  FUNCTION get_last_purchase_date_f(
    in_loct_id              IN     NUMBER,     --   �ۊǑq��ID
    in_item_id              IN     NUMBER      --   �i��ID
  ) RETURN DATE IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'get_last_purchase_date_f'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cd_min_date           CONSTANT DATE          := TO_DATE('1900/01/01','YYYY/MM/DD');  -- �ŏ����t
    cv_lot_status_reject  CONSTANT VARCHAR2(2)   := '60';          -- ���b�g�X�e�[�^�X�F�s���i
    cv_duty_status_finish CONSTANT VARCHAR2(1)   := '7';           -- �Ɩ��X�e�[�^�X�F����
    cv_duty_status_close  CONSTANT VARCHAR2(1)   := '8';           -- �Ɩ��X�e�[�^�X�F�N���[�Y
    cv_doc_type           CONSTANT VARCHAR2(4)   := 'PROD';        -- �����^�C�v
    cv_po_status_receive  CONSTANT VARCHAR2(2)   := '25';          -- �����A�h�I���X�e�[�^�X�F�������
    cv_po_status_fix_qty  CONSTANT VARCHAR2(2)   := '30';          -- �����A�h�I���X�e�[�^�X�F���ʊm���
    cv_po_status_fix_amt  CONSTANT VARCHAR2(2)   := '35';          -- �����A�h�I���X�e�[�^�X�F���z�m���
    cv_txn_type_receive   CONSTANT VARCHAR2(1)   := '1';           -- ���ы敪�F���
--
    -- *** ���[�J���ϐ� ***
    ld_actual_txn_date             DATE;                           -- �ŏI�w����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
    --
    SELECT MAX(actual_txn_date)
    INTO   ld_actual_txn_date
    FROM   (
      -- �ŏI���Y���擾
      SELECT TO_DATE(gmd.attribute11,'YYYY/MM/DD')  actual_txn_date
             --
      FROM   gme_batch_header gbh            -- ���Y�o�b�`�w�b�_
            ,gme_material_details gmd        -- ���Y�����ڍ�
            ,gmd_routings_vl grv             -- �H���}�X�^
            ,mtl_item_locations mil          -- OPM�ۊǏꏊ�}�X�^
            ,hr_all_organization_units haou  -- �g�D�}�X�^
            ,ic_whse_mst iwm                 -- OPM�q�Ƀ}�X�^
            ,ic_tran_pnd itp                 -- OPM�ۗ��݌Ƀg�����U�N�V����
            ,ic_lots_mst ilm                 -- OPM���b�g
            ,ic_item_mst_b iimb              -- OPM�i�ڃ}�X�^
      WHERE
             gbh.routing_id            = grv.routing_id
      AND    grv.attribute9            = mil.segment1
      AND    mil.organization_id       = iwm.mtl_organization_id
      AND    iwm.mtl_organization_id   = haou.organization_id
      AND    gbh.batch_id              = gmd.batch_id
      AND    gmd.material_detail_id    = itp.line_id
--20091207_Ver2.5_I_E_479_023_SCS.Goto_ADD_START
      AND    gmd.item_id               = iimb.item_id
--20091207_Ver2.5_I_E_479_023_SCS.Goto_ADD_END
      AND    itp.lot_id                = ilm.lot_id
      AND    itp.item_id               = ilm.item_id
      AND    ilm.item_id               = iimb.item_id
      AND    ilm.attribute23           NOT IN (cv_lot_status_reject)
      AND    ilm.lot_id                <> 0
      AND    gbh.attribute4            IN (cv_duty_status_finish,cv_duty_status_close)
      AND    gmd.line_type             = 1
      AND    itp.reverse_id (+)        IS NULL
      AND    itp.doc_type              = cv_doc_type
      AND    itp.delete_mark           = 0
      AND    mil.inventory_location_id = in_loct_id
      AND    iimb.item_id              = in_item_id
      --
      UNION ALL
      -- �ŏI�w��(���)���t
      SELECT xrart.txns_date  actual_txn_date
      FROM   po_headers_all            pha    -- �����w�b�_
            ,po_lines_all              pla    -- ��������
            ,xxpo_rcv_and_rtn_txns     xrart  -- ����ԕi����
            ,ic_lots_mst               ilm    -- OPM���b�g�}�X�^
            ,ic_item_mst_b             iimb   -- OPM�i�ڃ}�X�^
            ,hr_all_organization_units haou   -- �g�D�}�X�^
            ,ic_whse_mst               iwm    -- OPM�q�Ƀ}�X�^
            ,mtl_item_locations        mil    -- OPM�ۊǏꏊ�}�X�^
      WHERE  
             pha.attribute1            IN (cv_po_status_receive,cv_po_status_fix_qty,cv_po_status_fix_amt)
      AND    pha.org_id                = FND_PROFILE.VALUE('ORG_ID')
      AND    pha.po_header_id          = pla.po_header_id
      AND    pha.segment1              = xrart.source_document_number
      AND    pla.line_num              = xrart.source_document_line_num
      AND    xrart.txns_type           = cv_txn_type_receive
      AND    xrart.lot_id              = ilm.lot_id
--20091207_Ver2.5_I_E_479_023_SCS.Goto_ADD_START
      AND    xrart.item_id             = iimb.item_id
--20091207_Ver2.5_I_E_479_023_SCS.Goto_ADD_END
      AND    ilm.lot_id                <> 0
      AND    ilm.attribute23           NOT IN (cv_lot_status_reject)
      AND    ilm.item_id               = iimb.item_id
      AND    haou.organization_id      = iwm.mtl_organization_id
      AND    iwm.mtl_organization_id   = mil.organization_id
      AND    mil.segment1              = xrart.location_code
      AND    mil.inventory_location_id = in_loct_id
      AND    iimb.item_id              = in_item_id
    );
--
    -- �擾�ł��Ȃ������ꍇ�͍ŏ����t��ݒ�
    IF ( ld_actual_txn_date IS NULL ) THEN
      ld_actual_txn_date := cd_min_date;
    END IF;
    --
    RETURN ld_actual_txn_date;
--
  END get_last_purchase_date_f;
--
END XXCOP_COMMON_PKG2;
/
