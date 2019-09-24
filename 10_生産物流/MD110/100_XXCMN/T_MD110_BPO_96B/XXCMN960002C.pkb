CREATE OR REPLACE PACKAGE BODY XXCMN960002C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN960002C(body)
 * Description      : �󒍃A�h�I���o�b�N�A�b�v
 * MD.050           : T_MD050_BPO_96B_�󒍃A�h�I���o�b�N�A�b�v
 * Version          : 1.01
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/16   1.00  Hiroshi.Ogawa     �V�K�쐬
 *  2019/09/04   1.01  H.Sasaki          E_�{�ғ�_15601�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := '0'; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := '1';   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := '2';  --�ُ�:2
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
  gn_arc_cnt_header         NUMBER;                                             -- �o�b�N�A�b�v�����i�󒍃w�b�_�i�A�h�I���j�j
  gn_arc_cnt_line           NUMBER;                                             -- �o�b�N�A�b�v�����i�󒍖��ׁi�A�h�I���j�j
  gn_arc_cnt_lot            NUMBER;                                             -- �o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j
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
  local_process_expt        EXCEPTION;
  not_init_collection_expt  EXCEPTION;
  PRAGMA EXCEPTION_INIT(not_init_collection_expt, -6531);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN960002C'; -- �p�b�P�[�W��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE g_order_header_ttype IS TABLE OF xxcmn_order_headers_all_arc%ROWTYPE INDEX BY BINARY_INTEGER;
  TYPE g_order_line_ttype   IS TABLE OF xxcmn_order_lines_all_arc%ROWTYPE   INDEX BY BINARY_INTEGER;
  TYPE g_mov_lot_dtl_ttype  IS TABLE OF xxcmn_mov_lot_details_arc%ROWTYPE   INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_proc_date  IN  VARCHAR2,     --   1.������
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                 CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    cv_appl_short_name          CONSTANT VARCHAR2(10)  := 'XXCMN';            -- �A�h�I���F���ʁEIF�̈�
    cv_get_priod_msg            CONSTANT VARCHAR2(100) := 'APP-XXCMN-11012';  -- �o�b�N�A�b�v���Ԃ̎擾�Ɏ��s���܂����B
    cv_get_profile_msg          CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002';  -- �v���t�@�C��[ ��NG_PROFILE ]�̎擾�Ɏ��s���܂����B
    cv_local_others_hdr_msg     CONSTANT VARCHAR2(100) := 'APP-XXCMN-11021';  -- �o�b�N�A�b�v�����Ɏ��s���܂����B�y�󒍁i�A�h�I���j�z�󒍃w�b�_�A�h�I��ID�F ��KEY
    cv_local_others_line_msg    CONSTANT VARCHAR2(100) := 'APP-XXCMN-11029';  -- �o�b�N�A�b�v�����Ɏ��s���܂����B�y�󒍁i�A�h�I���j�z�󒍖��׃A�h�I��ID�F ��KEY
    cv_local_others_lot_msg     CONSTANT VARCHAR2(100) := 'APP-XXCMN-11030';  -- �o�b�N�A�b�v�����Ɏ��s���܂����B�y�󒍁i�A�h�I���j�z�ړ����b�g�ڍ�ID�F ��KEY
    cv_token_profile            CONSTANT VARCHAR2(10)  := 'NG_PROFILE';
    cv_token_key                CONSTANT VARCHAR2(10)  := 'KEY';
    cv_closed                   CONSTANT VARCHAR2(10)  := 'CLOSED';           -- �󒍃X�e�[�^�X(�N���[�Y)
--
    cv_xxcmn_commit_range       CONSTANT VARCHAR2(100) := 'XXCMN_COMMIT_RANGE';
    cv_xxcmn_archive_range      CONSTANT VARCHAR2(100) := 'XXCMN_ARCHIVE_RANGE';
    cv_mo_org_id                CONSTANT VARCHAR2(30) := 'ORG_ID';            -- MO�F�c�ƒP��
--
    cv_shipping                 CONSTANT VARCHAR2(2)   := '04';
    cv_sikyu                    CONSTANT VARCHAR2(2)   := '08';
    cv_mov_shipping             CONSTANT VARCHAR2(2)   := '10';
    cv_mov_sikyu                CONSTANT VARCHAR2(2)   := '30';
--
    cv_date_format              CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
--
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
    cv_purge_type   CONSTANT VARCHAR2(1)  := '1';                               -- �p�[�W�^�C�v�i1:�o�b�N�A�b�v�������ԁj
    cv_purge_code   CONSTANT VARCHAR2(30) := '9601';                            -- �p�[�W��`�R�[�h
--
    -- *** ���[�J���ϐ� ***
    ln_arc_cnt_header_yet     NUMBER DEFAULT 0;                                 -- ���R�~�b�g�o�b�N�A�b�v�����i�󒍃w�b�_�i�A�h�I���j�j
    ln_arc_cnt_line_yet       NUMBER DEFAULT 0;                                 -- ���R�~�b�g�o�b�N�A�b�v�����i�󒍖��ׁi�A�h�I���j�j
    ln_arc_cnt_lot_yet        NUMBER DEFAULT 0;                                 -- ���R�~�b�g�o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j
    ln_archive_period         NUMBER;                                           -- �o�b�N�A�b�v����
    ln_archive_range          NUMBER;                                           -- �o�b�N�A�b�v�����W
    ld_standard_date          DATE;                                             -- ���
    ln_commit_range           NUMBER;                                           -- �����R�~�b�g��
    lt_org_id                 oe_order_headers_all.org_id%TYPE;                 -- �c�ƒP��ID
    lv_process_part           VARCHAR2(1000);                                   -- ������
    lt_order_header_id        xxcmn_order_headers_all_arc.order_header_id%TYPE;
    lt_order_line_id          xxcmn_order_lines_all_arc.order_line_id%TYPE;
    lt_mov_lot_dtl_id         xxcmn_mov_lot_details_arc.mov_lot_dtl_id%TYPE;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    /*
    -- �󒍃w�b�_�i�A�h�I���j
    CURSOR �o�b�N�A�b�v�Ώێ󒍃w�b�_�i�A�h�I���j�擾
      id_���  IN DATE
      in_�o�b�N�A�b�v�����W IN NUMBER
    IS
      SELECT 
             �󒍃w�b�_�i�A�h�I���j�S�J����
      FROM �󒍃w�b�_�i�A�h�I���j
          ,����w�b�_�i�W���j
      WHERE �󒍃w�b�_�i�A�h�I���j�D�X�e�[�^�X IN ('04','08')
      AND �󒍃w�b�_�i�A�h�I���j�D���ד� >= id_��� - in_�o�b�N�A�b�v�����W
      AND �󒍃w�b�_�i�A�h�I���j�D���ד� < id_���
      AND �󒍃w�b�_�i�A�h�I���j�D�󒍃w�b�_ID = �󒍃w�b�_�i�W���j�D�󒍃w�b�_ID(+)
      AND ( �󒍃w�b�_�i�W���j�D�c�ƒP��ID = lt_�c�ƒP��ID
          OR �󒍃w�b�_�i�W���j�D�c�ƒP��ID IS NULL )
      AND ( �󒍃w�b�_�i�W���j�D�X�e�[�^�X = �N���[�Y
          OR �󒍃w�b�_�i�W���j�D�X�e�[�^�X IS NULL )
      AND NOT EXISTS (
               SELECT 1
               FROM �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
               WHERE �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�D�󒍃w�b�_�A�h�I��ID = �󒍃w�b�_�i�A�h�I���j�D�󒍃w�b�_�A�h�I��ID
               AND ROWNUM = 1
             )
      UNION ALL
      SELECT 
             �󒍃w�b�_�i�A�h�I���j�S�J����
      FROM �󒍃w�b�_�i�A�h�I���j
      WHERE �󒍃w�b�_�i�A�h�I���j�D�X�e�[�^�X NOT IN ('04','08')
      AND �󒍃w�b�_�i�A�h�I���j�D���ח\��� >= id_��� - in_�o�b�N�A�b�v�����W
      AND �󒍃w�b�_�i�A�h�I���j�D���ח\��� < id_���
      AND NOT EXISTS (
               SELECT 1
               FROM �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
               WHERE �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�D�󒍃w�b�_�A�h�I��ID = �󒍃w�b�_�i�A�h�I���j�D�󒍃w�b�_�A�h�I��ID
               AND ROWNUM = 1
             )
     */
    CURSOR archive_order_header_cur(
      id_standard_date           DATE
     ,in_archive_range           NUMBER
     ,it_org_id                  oe_order_headers_all.org_id%TYPE
    )
    IS
      SELECT  /*+ USE_NL(xoha ooha) INDEX(xoha XXWSH_OH_N15 ooha OE_ORDER_HEADERS_U1) */
              xoha.order_header_id                AS order_header_id
             ,xoha.order_type_id                  AS order_type_id
             ,xoha.organization_id                AS organization_id
             ,xoha.header_id                      AS header_id
             ,xoha.latest_external_flag           AS latest_external_flag
             ,xoha.ordered_date                   AS ordered_date
             ,xoha.customer_id                    AS customer_id
             ,xoha.customer_code                  AS customer_code
             ,xoha.deliver_to_id                  AS deliver_to_id
             ,xoha.deliver_to                     AS deliver_to
             ,xoha.shipping_instructions          AS shipping_instructions
             ,xoha.career_id                      AS career_id
             ,xoha.freight_carrier_code           AS freight_carrier_code
             ,xoha.shipping_method_code           AS shipping_method_code
             ,xoha.cust_po_number                 AS cust_po_number
             ,xoha.price_list_id                  AS price_list_id
             ,xoha.request_no                     AS request_no
             ,xoha.base_request_no                AS base_request_no
             ,xoha.req_status                     AS req_status
             ,xoha.delivery_no                    AS delivery_no
             ,xoha.prev_delivery_no               AS prev_delivery_no
             ,xoha.schedule_ship_date             AS schedule_ship_date
             ,xoha.schedule_arrival_date          AS schedule_arrival_date
             ,xoha.mixed_no                       AS mixed_no
             ,xoha.collected_pallet_qty           AS collected_pallet_qty
             ,xoha.confirm_request_class          AS confirm_request_class
             ,xoha.freight_charge_class           AS freight_charge_class
             ,xoha.shikyu_instruction_class       AS shikyu_instruction_class
             ,xoha.shikyu_inst_rcv_class          AS shikyu_inst_rcv_class
             ,xoha.amount_fix_class               AS amount_fix_class
             ,xoha.takeback_class                 AS takeback_class
             ,xoha.deliver_from_id                AS deliver_from_id
             ,xoha.deliver_from                   AS deliver_from
             ,xoha.head_sales_branch              AS head_sales_branch
             ,xoha.input_sales_branch             AS input_sales_branch
             ,xoha.po_no                          AS po_no
             ,xoha.prod_class                     AS prod_class
             ,xoha.item_class                     AS item_class
             ,xoha.no_cont_freight_class          AS no_cont_freight_class
             ,xoha.arrival_time_from              AS arrival_time_from
             ,xoha.arrival_time_to                AS arrival_time_to
             ,xoha.designated_item_id             AS designated_item_id
             ,xoha.designated_item_code           AS designated_item_code
             ,xoha.designated_production_date     AS designated_production_date
             ,xoha.designated_branch_no           AS designated_branch_no
             ,xoha.slip_number                    AS slip_number
             ,xoha.sum_quantity                   AS sum_quantity
             ,xoha.small_quantity                 AS small_quantity
             ,xoha.label_quantity                 AS label_quantity
             ,xoha.loading_efficiency_weight      AS loading_efficiency_weight
             ,xoha.loading_efficiency_capacity    AS loading_efficiency_capacity
             ,xoha.based_weight                   AS based_weight
             ,xoha.based_capacity                 AS based_capacity
             ,xoha.sum_weight                     AS sum_weight
             ,xoha.sum_capacity                   AS sum_capacity
             ,xoha.mixed_ratio                    AS mixed_ratio
             ,xoha.pallet_sum_quantity            AS pallet_sum_quantity
             ,xoha.real_pallet_quantity           AS real_pallet_quantity
             ,xoha.sum_pallet_weight              AS sum_pallet_weight
             ,xoha.order_source_ref               AS order_source_ref
             ,xoha.result_freight_carrier_id      AS result_freight_carrier_id
             ,xoha.result_freight_carrier_code    AS result_freight_carrier_code
             ,xoha.result_shipping_method_code    AS result_shipping_method_code
             ,xoha.result_deliver_to_id           AS result_deliver_to_id
             ,xoha.result_deliver_to              AS result_deliver_to
             ,xoha.shipped_date                   AS shipped_date
             ,xoha.arrival_date                   AS arrival_date
             ,xoha.weight_capacity_class          AS weight_capacity_class
             ,xoha.actual_confirm_class           AS actual_confirm_class
             ,xoha.notif_status                   AS notif_status
             ,xoha.prev_notif_status              AS prev_notif_status
             ,xoha.notif_date                     AS notif_date
             ,xoha.new_modify_flg                 AS new_modify_flg
             ,xoha.process_status                 AS process_status
             ,xoha.performance_management_dept    AS performance_management_dept
             ,xoha.instruction_dept               AS instruction_dept
             ,xoha.transfer_location_id           AS transfer_location_id
             ,xoha.transfer_location_code         AS transfer_location_code
             ,xoha.mixed_sign                     AS mixed_sign
             ,xoha.screen_update_date             AS screen_update_date
             ,xoha.screen_update_by               AS screen_update_by
             ,xoha.tightening_date                AS tightening_date
             ,xoha.vendor_id                      AS vendor_id
             ,xoha.vendor_code                    AS vendor_code
             ,xoha.vendor_site_id                 AS vendor_site_id
             ,xoha.vendor_site_code               AS vendor_site_code
             ,xoha.registered_sequence            AS registered_sequence
             ,xoha.tightening_program_id          AS tightening_program_id
             ,xoha.corrected_tighten_class        AS corrected_tighten_class
             ,xoha.created_by                     AS created_by
             ,xoha.creation_date                  AS creation_date
             ,xoha.last_updated_by                AS last_updated_by
             ,xoha.last_update_date               AS last_update_date
             ,xoha.last_update_login              AS last_update_login
             ,xoha.request_id                     AS request_id
             ,xoha.program_application_id         AS program_application_id
             ,xoha.program_id                     AS program_id
             ,xoha.program_update_date            AS program_update_date
--  V1.01 Added START
             ,xoha.sikyu_return_date              AS sikyu_return_date
--  V1.01 Added END
      FROM    xxwsh_order_headers_all  xoha
             ,oe_order_headers_all     ooha
      WHERE   xoha.req_status    IN (cv_shipping, cv_sikyu)
      AND     xoha.arrival_date  >= id_standard_date - in_archive_range
      AND     xoha.arrival_date   < id_standard_date
      AND     xoha.header_id      = ooha.header_id(+)
      AND     ( ooha.flow_status_code = cv_closed
              OR ooha.flow_status_code IS NULL )
      AND     ( ooha.org_id         = it_org_id
              OR ooha.org_id IS NULL )
      AND     NOT EXISTS (
                SELECT  1
                FROM    xxcmn_order_headers_all_arc  xohaa
                WHERE   xohaa.order_header_id = xoha.order_header_id
                AND     ROWNUM                = 1
              )
      UNION ALL
      SELECT  /*+ INDEX(xoha XXWSH_OH_N14) */
              xoha.order_header_id                AS order_header_id
             ,xoha.order_type_id                  AS order_type_id
             ,xoha.organization_id                AS organization_id
             ,xoha.header_id                      AS header_id
             ,xoha.latest_external_flag           AS latest_external_flag
             ,xoha.ordered_date                   AS ordered_date
             ,xoha.customer_id                    AS customer_id
             ,xoha.customer_code                  AS customer_code
             ,xoha.deliver_to_id                  AS deliver_to_id
             ,xoha.deliver_to                     AS deliver_to
             ,xoha.shipping_instructions          AS shipping_instructions
             ,xoha.career_id                      AS career_id
             ,xoha.freight_carrier_code           AS freight_carrier_code
             ,xoha.shipping_method_code           AS shipping_method_code
             ,xoha.cust_po_number                 AS cust_po_number
             ,xoha.price_list_id                  AS price_list_id
             ,xoha.request_no                     AS request_no
             ,xoha.base_request_no                AS base_request_no
             ,xoha.req_status                     AS req_status
             ,xoha.delivery_no                    AS delivery_no
             ,xoha.prev_delivery_no               AS prev_delivery_no
             ,xoha.schedule_ship_date             AS schedule_ship_date
             ,xoha.schedule_arrival_date          AS schedule_arrival_date
             ,xoha.mixed_no                       AS mixed_no
             ,xoha.collected_pallet_qty           AS collected_pallet_qty
             ,xoha.confirm_request_class          AS confirm_request_class
             ,xoha.freight_charge_class           AS freight_charge_class
             ,xoha.shikyu_instruction_class       AS shikyu_instruction_class
             ,xoha.shikyu_inst_rcv_class          AS shikyu_inst_rcv_class
             ,xoha.amount_fix_class               AS amount_fix_class
             ,xoha.takeback_class                 AS takeback_class
             ,xoha.deliver_from_id                AS deliver_from_id
             ,xoha.deliver_from                   AS deliver_from
             ,xoha.head_sales_branch              AS head_sales_branch
             ,xoha.input_sales_branch             AS input_sales_branch
             ,xoha.po_no                          AS po_no
             ,xoha.prod_class                     AS prod_class
             ,xoha.item_class                     AS item_class
             ,xoha.no_cont_freight_class          AS no_cont_freight_class
             ,xoha.arrival_time_from              AS arrival_time_from
             ,xoha.arrival_time_to                AS arrival_time_to
             ,xoha.designated_item_id             AS designated_item_id
             ,xoha.designated_item_code           AS designated_item_code
             ,xoha.designated_production_date     AS designated_production_date
             ,xoha.designated_branch_no           AS designated_branch_no
             ,xoha.slip_number                    AS slip_number
             ,xoha.sum_quantity                   AS sum_quantity
             ,xoha.small_quantity                 AS small_quantity
             ,xoha.label_quantity                 AS label_quantity
             ,xoha.loading_efficiency_weight      AS loading_efficiency_weight
             ,xoha.loading_efficiency_capacity    AS loading_efficiency_capacity
             ,xoha.based_weight                   AS based_weight
             ,xoha.based_capacity                 AS based_capacity
             ,xoha.sum_weight                     AS sum_weight
             ,xoha.sum_capacity                   AS sum_capacity
             ,xoha.mixed_ratio                    AS mixed_ratio
             ,xoha.pallet_sum_quantity            AS pallet_sum_quantity
             ,xoha.real_pallet_quantity           AS real_pallet_quantity
             ,xoha.sum_pallet_weight              AS sum_pallet_weight
             ,xoha.order_source_ref               AS order_source_ref
             ,xoha.result_freight_carrier_id      AS result_freight_carrier_id
             ,xoha.result_freight_carrier_code    AS result_freight_carrier_code
             ,xoha.result_shipping_method_code    AS result_shipping_method_code
             ,xoha.result_deliver_to_id           AS result_deliver_to_id
             ,xoha.result_deliver_to              AS result_deliver_to
             ,xoha.shipped_date                   AS shipped_date
             ,xoha.arrival_date                   AS arrival_date
             ,xoha.weight_capacity_class          AS weight_capacity_class
             ,xoha.actual_confirm_class           AS actual_confirm_class
             ,xoha.notif_status                   AS notif_status
             ,xoha.prev_notif_status              AS prev_notif_status
             ,xoha.notif_date                     AS notif_date
             ,xoha.new_modify_flg                 AS new_modify_flg
             ,xoha.process_status                 AS process_status
             ,xoha.performance_management_dept    AS performance_management_dept
             ,xoha.instruction_dept               AS instruction_dept
             ,xoha.transfer_location_id           AS transfer_location_id
             ,xoha.transfer_location_code         AS transfer_location_code
             ,xoha.mixed_sign                     AS mixed_sign
             ,xoha.screen_update_date             AS screen_update_date
             ,xoha.screen_update_by               AS screen_update_by
             ,xoha.tightening_date                AS tightening_date
             ,xoha.vendor_id                      AS vendor_id
             ,xoha.vendor_code                    AS vendor_code
             ,xoha.vendor_site_id                 AS vendor_site_id
             ,xoha.vendor_site_code               AS vendor_site_code
             ,xoha.registered_sequence            AS registered_sequence
             ,xoha.tightening_program_id          AS tightening_program_id
             ,xoha.corrected_tighten_class        AS corrected_tighten_class
             ,xoha.created_by                     AS created_by
             ,xoha.creation_date                  AS creation_date
             ,xoha.last_updated_by                AS last_updated_by
             ,xoha.last_update_date               AS last_update_date
             ,xoha.last_update_login              AS last_update_login
             ,xoha.request_id                     AS request_id
             ,xoha.program_application_id         AS program_application_id
             ,xoha.program_id                     AS program_id
             ,xoha.program_update_date            AS program_update_date
--  V1.01 Added START
             ,xoha.sikyu_return_date              AS sikyu_return_date
--  V1.01 Added END
      FROM    xxwsh_order_headers_all  xoha
      WHERE   xoha.req_status         NOT IN (cv_shipping, cv_sikyu)
      AND     xoha.schedule_arrival_date  >= id_standard_date - in_archive_range
      AND     xoha.schedule_arrival_date   < id_standard_date
      AND     NOT EXISTS (
                SELECT  1
                FROM    xxcmn_order_headers_all_arc  xohaa
                WHERE   xohaa.order_header_id = xoha.order_header_id
                AND     ROWNUM                = 1
              )
    ;
    /*
    -- �󒍖��ׁi�A�h�I���j
    CURSOR �o�b�N�A�b�v�Ώێ󒍖��ׁi�A�h�I���j�擾
      it_�󒍃w�b�_�A�h�I���h�c IN �󒍃w�b�_�i�A�h�I���j�D�󒍃w�b�_�A�h�I���h�c%TYPE
    IS
      SELECT
             �󒍖��ׁi�A�h�I���j�S�J����
      FROM �󒍖��ׁi�A�h�I���j
      WHERE �󒍖��ׁi�A�h�I���j�D�󒍃w�b�_�A�h�I���h�c = it_�󒍃w�b�_�A�h�I���h�c
     */
    CURSOR archive_order_line_cur(
      it_order_header_id         xxwsh_order_headers_all.order_header_id%TYPE
    )
    IS
      SELECT  /*+ INDEX(xola XXWSH_OL_N01) */
              xola.order_line_id                  AS order_line_id
             ,xola.order_header_id                AS order_header_id
             ,xola.order_line_number              AS order_line_number
             ,xola.header_id                      AS header_id
             ,xola.line_id                        AS line_id
             ,xola.request_no                     AS request_no
             ,xola.shipping_inventory_item_id     AS shipping_inventory_item_id
             ,xola.shipping_item_code             AS shipping_item_code
             ,xola.quantity                       AS quantity
             ,xola.uom_code                       AS uom_code
             ,xola.unit_price                     AS unit_price
             ,xola.shipped_quantity               AS shipped_quantity
             ,xola.designated_production_date     AS designated_production_date
             ,xola.based_request_quantity         AS based_request_quantity
             ,xola.request_item_id                AS request_item_id
             ,xola.request_item_code              AS request_item_code
             ,xola.ship_to_quantity               AS ship_to_quantity
             ,xola.futai_code                     AS futai_code
             ,xola.designated_date                AS designated_date
             ,xola.move_number                    AS move_number
             ,xola.po_number                      AS po_number
             ,xola.cust_po_number                 AS cust_po_number
             ,xola.pallet_quantity                AS pallet_quantity
             ,xola.layer_quantity                 AS layer_quantity
             ,xola.case_quantity                  AS case_quantity
             ,xola.weight                         AS weight
             ,xola.capacity                       AS capacity
             ,xola.pallet_qty                     AS pallet_qty
             ,xola.pallet_weight                  AS pallet_weight
             ,xola.reserved_quantity              AS reserved_quantity
             ,xola.automanual_reserve_class       AS automanual_reserve_class
             ,xola.delete_flag                    AS delete_flag
             ,xola.warning_class                  AS warning_class
             ,xola.warning_date                   AS warning_date
             ,xola.line_description               AS line_description
             ,xola.rm_if_flg                      AS rm_if_flg
             ,xola.shipping_request_if_flg        AS shipping_request_if_flg
             ,xola.shipping_result_if_flg         AS shipping_result_if_flg
             ,xola.created_by                     AS created_by
             ,xola.creation_date                  AS creation_date
             ,xola.last_updated_by                AS last_updated_by
             ,xola.last_update_date               AS last_update_date
             ,xola.last_update_login              AS last_update_login
             ,xola.request_id                     AS request_id
             ,xola.program_application_id         AS program_application_id
             ,xola.program_id                     AS program_id
             ,xola.program_update_date            AS program_update_date
      FROM    xxwsh_order_lines_all  xola
      WHERE   xola.order_header_id = it_order_header_id
    ;
    /*
    -- �ړ����b�g�ڍׁi�A�h�I���j
    CURSOR �o�b�N�A�b�v�Ώۈړ����b�g�ڍׁi�A�h�I���j�擾
      it_�󒍖��׃A�h�I���h�c IN �󒍖��ׁi�A�h�I���j�D�󒍖��׃A�h�I���h�c%TYPE
    IS
      SELECT
             �ړ����b�g�ڍׁi�A�h�I���j�S�J����
      FROM �ړ����b�g�ڍׁi�A�h�I���j
      WHERE �ړ����b�g�ڍׁi�A�h�I���j�D���ׂh�c = it_�󒍖��׃A�h�I���h�c
      AND �ړ����b�g�ڍׁi�A�h�I���j�D�����^�C�v�R�[�h IN ('10','30')
     */
    CURSOR archive_mov_lot_dtl_cur(
      it_order_line_id           xxwsh_order_lines_all.order_line_id%TYPE
    )
    IS
      SELECT  /*+ INDEX(xmld XXINV_MLD_N01) */
              xmld.mov_lot_dtl_id                 AS mov_lot_dtl_id
             ,xmld.mov_line_id                    AS mov_line_id
             ,xmld.document_type_code             AS document_type_code
             ,xmld.record_type_code               AS record_type_code
             ,xmld.item_id                        AS item_id
             ,xmld.item_code                      AS item_code
             ,xmld.lot_id                         AS lot_id
             ,xmld.lot_no                         AS lot_no
             ,xmld.actual_date                    AS actual_date
             ,xmld.actual_quantity                AS actual_quantity
             ,xmld.before_actual_quantity         AS before_actual_quantity
             ,xmld.automanual_reserve_class       AS automanual_reserve_class
             ,xmld.created_by                     AS created_by
             ,xmld.creation_date                  AS creation_date
             ,xmld.last_updated_by                AS last_updated_by
             ,xmld.last_update_date               AS last_update_date
             ,xmld.last_update_login              AS last_update_login
             ,xmld.request_id                     AS request_id
             ,xmld.program_application_id         AS program_application_id
             ,xmld.program_id                     AS program_id
             ,xmld.program_update_date            AS program_update_date
             ,xmld.actual_confirm_class           AS actual_confirm_class
      FROM    xxinv_mov_lot_details  xmld
      WHERE   xmld.mov_line_id        = it_order_line_id
      AND     xmld.document_type_code IN (cv_mov_shipping, cv_mov_sikyu)
    ;
    -- <�J�[�\����>���R�[�h�^
    l_order_header_tbl       g_order_header_ttype;                               -- �󒍃w�b�_�i�A�h�I���j�e�[�u��
    l_order_line_tbl         g_order_line_ttype;                                 -- �󒍖��ׁi�A�h�I���j�e�[�u��
    l_mov_lot_dtl_tbl        g_mov_lot_dtl_ttype;                                -- �ړ����b�g�ڍׁi�A�h�I���j�e�[�u��
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
    gn_arc_cnt_header := 0;
    gn_arc_cnt_line   := 0;
    gn_arc_cnt_lot    := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================================
    -- �o�b�N�A�b�v���Ԏ擾
    -- ===============================================
    /*
    ln_�o�b�N�A�b�v���� := �o�b�N�A�b�v���Ԏ擾���ʊ֐��icv_�p�[�W��`�R�[�h�j;
     */
    lv_process_part := '�o�b�N�A�b�v���Ԏ擾';
    ln_archive_period := xxcmn_common4_pkg.get_purge_period(cv_purge_type, cv_purge_code);
    IF ( ln_archive_period IS NULL ) THEN
--
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_priod_msg
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    -- ===============================================
    -- �h�m�p�����[�^�̊m�F
    -- ===============================================
    /*
    iv_proc_date��NULL�̏ꍇ
--
      ld_��� := �������擾���ʊ֐�����擾���������� - ln_�o�b�N�A�b�v����;
--
    iv_proc_date��NULL�łȂ��̏ꍇ
--
      ld_��� := TO_DATE(iv_proc_date) - ln_�o�b�N�A�b�v����;
     */
    lv_process_part := 'IN�p�����[�^�̊m�F';
    IF ( iv_proc_date IS NULL ) THEN
--
      ld_standard_date := xxcmn_common4_pkg.get_syori_date - ln_archive_period;
--
    ELSE
--
      ld_standard_date := TO_DATE(iv_proc_date, cv_date_format) - ln_archive_period;
--
    END IF;
--
    -- ===============================================
    -- �v���t�@�C���E�I�v�V�����l�擾
    -- ===============================================
    /*
    ln_�����R�~�b�g�� := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾(XXCMN:�p�[�W/�o�b�N�A�b�v�����R�~�b�g��));
    ln_�o�b�N�A�b�v�����W := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾(XXCMN:�o�b�N�A�b�v�����W));
     */
    lv_process_part := '�v���t�@�C���E�I�v�V�����l�擾�i' || cv_xxcmn_commit_range || '�j';
    ln_commit_range  := fnd_profile.value(cv_xxcmn_commit_range);
    IF ( ln_commit_range IS NULL ) THEN
--
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_profile_msg
                    ,iv_token_name1  => cv_token_profile
                    ,iv_token_value1 => cv_xxcmn_commit_range
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
    lv_process_part := '�v���t�@�C���E�I�v�V�����l�擾�i' || cv_xxcmn_archive_range || '�j';
    ln_archive_range := fnd_profile.value(cv_xxcmn_archive_range);
    IF ( ln_archive_range IS NULL ) THEN
--
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_profile_msg
                    ,iv_token_name1  => cv_token_profile
                    ,iv_token_value1 => cv_xxcmn_archive_range
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    lv_process_part := '�v���t�@�C���E�I�v�V�����l�擾�i' || cv_mo_org_id || '�j';
    lt_org_id        := fnd_profile.value(cv_mo_org_id);
    IF ( lt_org_id IS NULL ) THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_profile_msg
                    ,iv_token_name1  => cv_token_profile
                    ,iv_token_value1 => cv_mo_org_id
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
    END IF;
--
    -- ===============================================
    -- �o�b�N�A�b�v�Ώێ󒍃w�b�_�i�A�h�I���j�擾
    -- ===============================================
    /*
    FOR lr_header_rec IN �o�b�N�A�b�v�Ώێ󒍃w�b�_�i�A�h�I���j�擾�ild_����Cln_�o�b�N�A�b�v�����W�Cln_�c�ƒP��ID�j LOOP
     */
    << archive_order_header_loop >>
    FOR lr_header_rec IN archive_order_header_cur(
                           ld_standard_date
                          ,ln_archive_range
                          ,lt_org_id
                         )
    LOOP
--
      -- ===============================================
      -- �����R�~�b�g
      -- ===============================================
      /*
      NVL(ln_�����R�~�b�g��, 0) <> 0�̏ꍇ
       */
      IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
--
        /*
        ln_���R�~�b�g�o�b�N�A�b�v�����i�󒍃w�b�_�i�A�h�I���j�j > 0 ���� MOD(ln_���R�~�b�g�o�b�N�A�b�v�����i�󒍃w�b�_�i�A�h�I���j�j, ln_�����R�~�b�g��) = 0�̏ꍇ
         */
        IF (  (ln_arc_cnt_header_yet > 0)
          AND (MOD(ln_arc_cnt_header_yet, ln_commit_range) = 0)
           )
        THEN
--
          /*
          FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v�����i�󒍃w�b�_�i�A�h�I���j�j
            INSERT INTO �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
            (
                �S�J����
              , �o�b�N�A�b�v�o�^��
              , �o�b�N�A�b�v�v��ID
            )
            VALUES
            (
                l_�󒍃w�b�_�i�A�h�I���j�e�[�u���iln_idx�j�S�J����
              , SYSDATE
              , �v��ID
            )
           */
          lv_process_part := '�󒍃w�b�_�i�A�h�I���j�o�^�P';
          FORALL ln_idx IN 1..ln_arc_cnt_header_yet
            INSERT INTO xxcmn_order_headers_all_arc VALUES l_order_header_tbl(ln_idx)
          ;
--
          /*
          l_�󒍃w�b�_�i�A�h�I���j�e�[�u���DDELETE;
           */
          l_order_header_tbl.DELETE;
--
          /*
          FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v�����i�󒍖��ׁi�A�h�I���j�j
            INSERT INTO �󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
            (
                �S�J����
              , �o�b�N�A�b�v�o�^��
              , �o�b�N�A�b�v�v��ID
            )
            VALUES
            (
                l_�󒍖��ׁi�A�h�I���j�e�[�u���iln_idx�j�S�J����
              , SYSDATE
              , �v��ID
            )
           */
          lv_process_part := '�󒍖��ׁi�A�h�I���j�o�^�P';
          FORALL ln_idx IN 1..ln_arc_cnt_line_yet
            INSERT INTO xxcmn_order_lines_all_arc VALUES l_order_line_tbl(ln_idx)
          ;
--
          /*
          l_�󒍖��ׁi�A�h�I���j�e�[�u���DDELETE;
           */
          l_order_line_tbl.DELETE;
--
          /*
          FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j
            INSERT INTO �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
            (
                �S�J����
              , �o�b�N�A�b�v�o�^��
              , �o�b�N�A�b�v�v��ID
            )
            VALUES
            (
                l_�ړ����b�g�ڍׁi�A�h�I���j�e�[�u���iln_idx�j�S�J����
              , SYSDATE
              , �v��ID
            )
           */
          lv_process_part := '�ړ����b�g�ڍׁi�A�h�I���j�o�^�P';
          FORALL ln_idx IN 1..ln_arc_cnt_lot_yet
            INSERT INTO xxcmn_mov_lot_details_arc VALUES l_mov_lot_dtl_tbl(ln_idx)
          ;
--
          /*
          l_�ړ����b�g�ڍׁi�A�h�I���j�e�[�u���DDELETE;
           */
          l_mov_lot_dtl_tbl.DELETE;
--
          /*
          gn_�o�b�N�A�b�v�����i�󒍃w�b�_�i�A�h�I���j�j := gn_�o�b�N�A�b�v�����i�󒍃w�b�_�i�A�h�I���j�j + ln_���R�~�b�g�o�b�N�A�b�v�����i�󒍃w�b�_�i�A�h�I���j�j;
          ln_���R�~�b�g�o�b�N�A�b�v�����i�󒍃w�b�_�i�A�h�I���j�j := 0;
           */
          gn_arc_cnt_header     := gn_arc_cnt_header + ln_arc_cnt_header_yet;
          ln_arc_cnt_header_yet := 0;
--
          /*
          gn_�o�b�N�A�b�v�����i�󒍖��ׁi�A�h�I���j�j := gn_�o�b�N�A�b�v�����i�󒍖��ׁi�A�h�I���j�j + ln_���R�~�b�g�o�b�N�A�b�v�����i�󒍖��ׁi�A�h�I���j�j;
          ln_���R�~�b�g�o�b�N�A�b�v�����i�󒍖��ׁi�A�h�I���j�j := 0;
           */
          gn_arc_cnt_line     := gn_arc_cnt_line + ln_arc_cnt_line_yet;
          ln_arc_cnt_line_yet := 0;
--
          /*
          gn_�o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j := gn_�o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j + ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j;
          ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j := 0;
           */
          gn_arc_cnt_lot     := gn_arc_cnt_lot + ln_arc_cnt_lot_yet;
          ln_arc_cnt_lot_yet := 0;
--
          /*
          COMMIT;
           */
          COMMIT;
--
        END IF;
--
      END IF;
--
      /*
      lt_�Ώێ󒍃w�b�_�A�h�I��ID := lr_header_rec�D�󒍃w�b�_�A�h�I��ID;
       */
      lt_order_header_id := lr_header_rec.order_header_id;
--
      -- ===============================================
      -- �o�b�N�A�b�v�Ώێ󒍖��ׁi�A�h�I���j�擾
      -- ===============================================
      /*
      FOR lr_line_rec IN �o�b�N�A�b�v�Ώێ󒍖��ׁi�A�h�I���j�擾�ilr_header_rec�D�󒍃w�b�_�A�h�I��ID�j LOOP
       */
      << archive_order_line_loop >>
      FOR lr_line_rec IN archive_order_line_cur(
                           lr_header_rec.order_header_id
                         )
      LOOP
--
        -- ===============================================
        -- �o�b�N�A�b�v�Ώۈړ����b�g�ڍׁi�A�h�I���j�擾
        -- ===============================================
        /*
        FOR lr_lot_rec IN �o�b�N�A�b�v�Ώۈړ����b�g�ڍׁi�A�h�I���j�擾�ilr_line_rec�D�󒍖��׃A�h�I��ID�C'10'�j LOOP
         */
        << archive_mov_lot_dtl_loop >>
        FOR lr_lot_rec IN archive_mov_lot_dtl_cur(
                            lr_line_rec.order_line_id
                          )
        LOOP
--
          /*
          ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j := ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j + 1;
          l_�ړ����b�g�ڍׁi�A�h�I���j�e�[�u���iln_���R�~�b�g�o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j := lr_lot_rec;
           */
          ln_arc_cnt_lot_yet := ln_arc_cnt_lot_yet + 1;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).mov_lot_dtl_id           := lr_lot_rec.mov_lot_dtl_id;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).mov_line_id              := lr_lot_rec.mov_line_id;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).document_type_code       := lr_lot_rec.document_type_code;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).record_type_code         := lr_lot_rec.record_type_code;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).item_id                  := lr_lot_rec.item_id;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).item_code                := lr_lot_rec.item_code;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).lot_id                   := lr_lot_rec.lot_id;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).lot_no                   := lr_lot_rec.lot_no;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).actual_date              := lr_lot_rec.actual_date;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).actual_quantity          := lr_lot_rec.actual_quantity;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).before_actual_quantity   := lr_lot_rec.before_actual_quantity;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).automanual_reserve_class := lr_lot_rec.automanual_reserve_class;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).created_by               := lr_lot_rec.created_by;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).creation_date            := lr_lot_rec.creation_date;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).last_updated_by          := lr_lot_rec.last_updated_by;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).last_update_date         := lr_lot_rec.last_update_date;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).last_update_login        := lr_lot_rec.last_update_login;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).request_id               := lr_lot_rec.request_id;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).program_application_id   := lr_lot_rec.program_application_id;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).program_id               := lr_lot_rec.program_id;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).program_update_date      := lr_lot_rec.program_update_date;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).actual_confirm_class     := lr_lot_rec.actual_confirm_class;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).archive_date             := SYSDATE;
          l_mov_lot_dtl_tbl(ln_arc_cnt_lot_yet).archive_request_id       := cn_request_id;
--
        END LOOP archive_mov_lot_dtl_loop;
--
        /*
        ln_���R�~�b�g�o�b�N�A�b�v�����i�󒍖��ׁi�A�h�I���j�j := ln_���R�~�b�g�o�b�N�A�b�v�����i�󒍖��ׁi�A�h�I���j�j + 1;
        l_�󒍖��ׁi�A�h�I���j�e�[�u���iln_���R�~�b�g�o�b�N�A�b�v�����i�󒍖��ׁi�A�h�I���j�j := lr_line_rec;
         */
        ln_arc_cnt_line_yet := ln_arc_cnt_line_yet + 1;
        l_order_line_tbl(ln_arc_cnt_line_yet).order_line_id                := lr_line_rec.order_line_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).order_header_id              := lr_line_rec.order_header_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).order_line_number            := lr_line_rec.order_line_number;
        l_order_line_tbl(ln_arc_cnt_line_yet).header_id                    := lr_line_rec.header_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).line_id                      := lr_line_rec.line_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).request_no                   := lr_line_rec.request_no;
        l_order_line_tbl(ln_arc_cnt_line_yet).shipping_inventory_item_id   := lr_line_rec.shipping_inventory_item_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).shipping_item_code           := lr_line_rec.shipping_item_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).quantity                     := lr_line_rec.quantity;
        l_order_line_tbl(ln_arc_cnt_line_yet).uom_code                     := lr_line_rec.uom_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).unit_price                   := lr_line_rec.unit_price;
        l_order_line_tbl(ln_arc_cnt_line_yet).shipped_quantity             := lr_line_rec.shipped_quantity;
        l_order_line_tbl(ln_arc_cnt_line_yet).designated_production_date   := lr_line_rec.designated_production_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).based_request_quantity       := lr_line_rec.based_request_quantity;
        l_order_line_tbl(ln_arc_cnt_line_yet).request_item_id              := lr_line_rec.request_item_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).request_item_code            := lr_line_rec.request_item_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).ship_to_quantity             := lr_line_rec.ship_to_quantity;
        l_order_line_tbl(ln_arc_cnt_line_yet).futai_code                   := lr_line_rec.futai_code;
        l_order_line_tbl(ln_arc_cnt_line_yet).designated_date              := lr_line_rec.designated_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).move_number                  := lr_line_rec.move_number;
        l_order_line_tbl(ln_arc_cnt_line_yet).po_number                    := lr_line_rec.po_number;
        l_order_line_tbl(ln_arc_cnt_line_yet).cust_po_number               := lr_line_rec.cust_po_number;
        l_order_line_tbl(ln_arc_cnt_line_yet).pallet_quantity              := lr_line_rec.pallet_quantity;
        l_order_line_tbl(ln_arc_cnt_line_yet).layer_quantity               := lr_line_rec.layer_quantity;
        l_order_line_tbl(ln_arc_cnt_line_yet).case_quantity                := lr_line_rec.case_quantity;
        l_order_line_tbl(ln_arc_cnt_line_yet).weight                       := lr_line_rec.weight;
        l_order_line_tbl(ln_arc_cnt_line_yet).capacity                     := lr_line_rec.capacity;
        l_order_line_tbl(ln_arc_cnt_line_yet).pallet_qty                   := lr_line_rec.pallet_qty;
        l_order_line_tbl(ln_arc_cnt_line_yet).pallet_weight                := lr_line_rec.pallet_weight;
        l_order_line_tbl(ln_arc_cnt_line_yet).reserved_quantity            := lr_line_rec.reserved_quantity;
        l_order_line_tbl(ln_arc_cnt_line_yet).automanual_reserve_class     := lr_line_rec.automanual_reserve_class;
        l_order_line_tbl(ln_arc_cnt_line_yet).delete_flag                  := lr_line_rec.delete_flag;
        l_order_line_tbl(ln_arc_cnt_line_yet).warning_class                := lr_line_rec.warning_class;
        l_order_line_tbl(ln_arc_cnt_line_yet).warning_date                 := lr_line_rec.warning_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).line_description             := lr_line_rec.line_description;
        l_order_line_tbl(ln_arc_cnt_line_yet).rm_if_flg                    := lr_line_rec.rm_if_flg;
        l_order_line_tbl(ln_arc_cnt_line_yet).shipping_request_if_flg      := lr_line_rec.shipping_request_if_flg;
        l_order_line_tbl(ln_arc_cnt_line_yet).shipping_result_if_flg       := lr_line_rec.shipping_result_if_flg;
        l_order_line_tbl(ln_arc_cnt_line_yet).created_by                   := lr_line_rec.created_by;
        l_order_line_tbl(ln_arc_cnt_line_yet).creation_date                := lr_line_rec.creation_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).last_updated_by              := lr_line_rec.last_updated_by;
        l_order_line_tbl(ln_arc_cnt_line_yet).last_update_date             := lr_line_rec.last_update_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).last_update_login            := lr_line_rec.last_update_login;
        l_order_line_tbl(ln_arc_cnt_line_yet).request_id                   := lr_line_rec.request_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).program_application_id       := lr_line_rec.program_application_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).program_id                   := lr_line_rec.program_id;
        l_order_line_tbl(ln_arc_cnt_line_yet).program_update_date          := lr_line_rec.program_update_date;
        l_order_line_tbl(ln_arc_cnt_line_yet).archive_date                 := SYSDATE;
        l_order_line_tbl(ln_arc_cnt_line_yet).archive_request_id           := cn_request_id;
--
      END LOOP archive_order_line_loop;
--
      /*
      ln_���R�~�b�g�o�b�N�A�b�v�����i�󒍃w�b�_�i�A�h�I���j�j := ln_���R�~�b�g�o�b�N�A�b�v�����i�󒍃w�b�_�i�A�h�I���j�j + 1;
      l_�󒍃w�b�_�i�A�h�I���j�e�[�u���iln_���R�~�b�g�o�b�N�A�b�v�����i�󒍃w�b�_�i�A�h�I���j�j := lr_header_rec;
       */
      ln_arc_cnt_header_yet := ln_arc_cnt_header_yet + 1;
      l_order_header_tbl(ln_arc_cnt_header_yet).order_header_id              := lr_header_rec.order_header_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).order_type_id                := lr_header_rec.order_type_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).organization_id              := lr_header_rec.organization_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).header_id                    := lr_header_rec.header_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).latest_external_flag         := lr_header_rec.latest_external_flag;
      l_order_header_tbl(ln_arc_cnt_header_yet).ordered_date                 := lr_header_rec.ordered_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).customer_id                  := lr_header_rec.customer_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).customer_code                := lr_header_rec.customer_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).deliver_to_id                := lr_header_rec.deliver_to_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).deliver_to                   := lr_header_rec.deliver_to;
      l_order_header_tbl(ln_arc_cnt_header_yet).shipping_instructions        := lr_header_rec.shipping_instructions;
      l_order_header_tbl(ln_arc_cnt_header_yet).career_id                    := lr_header_rec.career_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).freight_carrier_code         := lr_header_rec.freight_carrier_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).shipping_method_code         := lr_header_rec.shipping_method_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).cust_po_number               := lr_header_rec.cust_po_number;
      l_order_header_tbl(ln_arc_cnt_header_yet).price_list_id                := lr_header_rec.price_list_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).request_no                   := lr_header_rec.request_no;
      l_order_header_tbl(ln_arc_cnt_header_yet).base_request_no              := lr_header_rec.base_request_no;
      l_order_header_tbl(ln_arc_cnt_header_yet).req_status                   := lr_header_rec.req_status;
      l_order_header_tbl(ln_arc_cnt_header_yet).delivery_no                  := lr_header_rec.delivery_no;
      l_order_header_tbl(ln_arc_cnt_header_yet).prev_delivery_no             := lr_header_rec.prev_delivery_no;
      l_order_header_tbl(ln_arc_cnt_header_yet).schedule_ship_date           := lr_header_rec.schedule_ship_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).schedule_arrival_date        := lr_header_rec.schedule_arrival_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).mixed_no                     := lr_header_rec.mixed_no;
      l_order_header_tbl(ln_arc_cnt_header_yet).collected_pallet_qty         := lr_header_rec.collected_pallet_qty;
      l_order_header_tbl(ln_arc_cnt_header_yet).confirm_request_class        := lr_header_rec.confirm_request_class;
      l_order_header_tbl(ln_arc_cnt_header_yet).freight_charge_class         := lr_header_rec.freight_charge_class;
      l_order_header_tbl(ln_arc_cnt_header_yet).shikyu_instruction_class     := lr_header_rec.shikyu_instruction_class;
      l_order_header_tbl(ln_arc_cnt_header_yet).shikyu_inst_rcv_class        := lr_header_rec.shikyu_inst_rcv_class;
      l_order_header_tbl(ln_arc_cnt_header_yet).amount_fix_class             := lr_header_rec.amount_fix_class;
      l_order_header_tbl(ln_arc_cnt_header_yet).takeback_class               := lr_header_rec.takeback_class;
      l_order_header_tbl(ln_arc_cnt_header_yet).deliver_from_id              := lr_header_rec.deliver_from_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).deliver_from                 := lr_header_rec.deliver_from;
      l_order_header_tbl(ln_arc_cnt_header_yet).head_sales_branch            := lr_header_rec.head_sales_branch;
      l_order_header_tbl(ln_arc_cnt_header_yet).input_sales_branch           := lr_header_rec.input_sales_branch;
      l_order_header_tbl(ln_arc_cnt_header_yet).po_no                        := lr_header_rec.po_no;
      l_order_header_tbl(ln_arc_cnt_header_yet).prod_class                   := lr_header_rec.prod_class;
      l_order_header_tbl(ln_arc_cnt_header_yet).item_class                   := lr_header_rec.item_class;
      l_order_header_tbl(ln_arc_cnt_header_yet).no_cont_freight_class        := lr_header_rec.no_cont_freight_class;
      l_order_header_tbl(ln_arc_cnt_header_yet).arrival_time_from            := lr_header_rec.arrival_time_from;
      l_order_header_tbl(ln_arc_cnt_header_yet).arrival_time_to              := lr_header_rec.arrival_time_to;
      l_order_header_tbl(ln_arc_cnt_header_yet).designated_item_id           := lr_header_rec.designated_item_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).designated_item_code         := lr_header_rec.designated_item_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).designated_production_date   := lr_header_rec.designated_production_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).designated_branch_no         := lr_header_rec.designated_branch_no;
      l_order_header_tbl(ln_arc_cnt_header_yet).slip_number                  := lr_header_rec.slip_number;
      l_order_header_tbl(ln_arc_cnt_header_yet).sum_quantity                 := lr_header_rec.sum_quantity;
      l_order_header_tbl(ln_arc_cnt_header_yet).small_quantity               := lr_header_rec.small_quantity;
      l_order_header_tbl(ln_arc_cnt_header_yet).label_quantity               := lr_header_rec.label_quantity;
      l_order_header_tbl(ln_arc_cnt_header_yet).loading_efficiency_weight    := lr_header_rec.loading_efficiency_weight;
      l_order_header_tbl(ln_arc_cnt_header_yet).loading_efficiency_capacity  := lr_header_rec.loading_efficiency_capacity;
      l_order_header_tbl(ln_arc_cnt_header_yet).based_weight                 := lr_header_rec.based_weight;
      l_order_header_tbl(ln_arc_cnt_header_yet).based_capacity               := lr_header_rec.based_capacity;
      l_order_header_tbl(ln_arc_cnt_header_yet).sum_weight                   := lr_header_rec.sum_weight;
      l_order_header_tbl(ln_arc_cnt_header_yet).sum_capacity                 := lr_header_rec.sum_capacity;
      l_order_header_tbl(ln_arc_cnt_header_yet).mixed_ratio                  := lr_header_rec.mixed_ratio;
      l_order_header_tbl(ln_arc_cnt_header_yet).pallet_sum_quantity          := lr_header_rec.pallet_sum_quantity;
      l_order_header_tbl(ln_arc_cnt_header_yet).real_pallet_quantity         := lr_header_rec.real_pallet_quantity;
      l_order_header_tbl(ln_arc_cnt_header_yet).sum_pallet_weight            := lr_header_rec.sum_pallet_weight;
      l_order_header_tbl(ln_arc_cnt_header_yet).order_source_ref             := lr_header_rec.order_source_ref;
      l_order_header_tbl(ln_arc_cnt_header_yet).result_freight_carrier_id    := lr_header_rec.result_freight_carrier_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).result_freight_carrier_code  := lr_header_rec.result_freight_carrier_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).result_shipping_method_code  := lr_header_rec.result_shipping_method_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).result_deliver_to_id         := lr_header_rec.result_deliver_to_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).result_deliver_to            := lr_header_rec.result_deliver_to;
      l_order_header_tbl(ln_arc_cnt_header_yet).shipped_date                 := lr_header_rec.shipped_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).arrival_date                 := lr_header_rec.arrival_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).weight_capacity_class        := lr_header_rec.weight_capacity_class;
      l_order_header_tbl(ln_arc_cnt_header_yet).actual_confirm_class         := lr_header_rec.actual_confirm_class;
      l_order_header_tbl(ln_arc_cnt_header_yet).notif_status                 := lr_header_rec.notif_status;
      l_order_header_tbl(ln_arc_cnt_header_yet).prev_notif_status            := lr_header_rec.prev_notif_status;
      l_order_header_tbl(ln_arc_cnt_header_yet).notif_date                   := lr_header_rec.notif_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).new_modify_flg               := lr_header_rec.new_modify_flg;
      l_order_header_tbl(ln_arc_cnt_header_yet).process_status               := lr_header_rec.process_status;
      l_order_header_tbl(ln_arc_cnt_header_yet).performance_management_dept  := lr_header_rec.performance_management_dept;
      l_order_header_tbl(ln_arc_cnt_header_yet).instruction_dept             := lr_header_rec.instruction_dept;
      l_order_header_tbl(ln_arc_cnt_header_yet).transfer_location_id         := lr_header_rec.transfer_location_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).transfer_location_code       := lr_header_rec.transfer_location_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).mixed_sign                   := lr_header_rec.mixed_sign;
      l_order_header_tbl(ln_arc_cnt_header_yet).screen_update_date           := lr_header_rec.screen_update_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).screen_update_by             := lr_header_rec.screen_update_by;
      l_order_header_tbl(ln_arc_cnt_header_yet).tightening_date              := lr_header_rec.tightening_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).vendor_id                    := lr_header_rec.vendor_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).vendor_code                  := lr_header_rec.vendor_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).vendor_site_id               := lr_header_rec.vendor_site_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).vendor_site_code             := lr_header_rec.vendor_site_code;
      l_order_header_tbl(ln_arc_cnt_header_yet).registered_sequence          := lr_header_rec.registered_sequence;
      l_order_header_tbl(ln_arc_cnt_header_yet).tightening_program_id        := lr_header_rec.tightening_program_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).corrected_tighten_class      := lr_header_rec.corrected_tighten_class;
      l_order_header_tbl(ln_arc_cnt_header_yet).created_by                   := lr_header_rec.created_by;
      l_order_header_tbl(ln_arc_cnt_header_yet).creation_date                := lr_header_rec.creation_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).last_updated_by              := lr_header_rec.last_updated_by;
      l_order_header_tbl(ln_arc_cnt_header_yet).last_update_date             := lr_header_rec.last_update_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).last_update_login            := lr_header_rec.last_update_login;
      l_order_header_tbl(ln_arc_cnt_header_yet).request_id                   := lr_header_rec.request_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).program_application_id       := lr_header_rec.program_application_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).program_id                   := lr_header_rec.program_id;
      l_order_header_tbl(ln_arc_cnt_header_yet).program_update_date          := lr_header_rec.program_update_date;
      l_order_header_tbl(ln_arc_cnt_header_yet).archive_date                 := SYSDATE;
      l_order_header_tbl(ln_arc_cnt_header_yet).archive_request_id           := cn_request_id;
-- V1.01 Added START
      l_order_header_tbl(ln_arc_cnt_header_yet).sikyu_return_date            := lr_header_rec.sikyu_return_date;
-- V1.01 Added END
--
    END LOOP archive_order_header_loop;
--
    /*
    FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v�����i�󒍃w�b�_�i�A�h�I���j�j
      INSERT INTO �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
      (
           �S�J����
        , �o�b�N�A�b�v�o�^��
        , �o�b�N�A�b�v�v��ID
      )
      VALUES
      (
          l_�󒍃w�b�_�i�A�h�I���j�e�[�u���iln_idx�j�S�J����
        , SYSDATE
        , �v��ID
      )
     */
    lv_process_part := '�󒍃w�b�_�i�A�h�I���j�o�^�Q';
    FORALL ln_idx IN 1..ln_arc_cnt_header_yet
      INSERT INTO xxcmn_order_headers_all_arc VALUES l_order_header_tbl(ln_idx)
    ;
--
    /*
    l_�󒍃w�b�_�i�A�h�I���j�e�[�u���DDELETE;
     */
    l_order_header_tbl.DELETE;
--
    /*
    FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v�����i�󒍖��ׁi�A�h�I���j�j
      INSERT INTO �󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
      (
          �S�J����
        , �o�b�N�A�b�v�o�^��
        , �o�b�N�A�b�v�v��ID
      )
      VALUES
      (
          l_�󒍖��ׁi�A�h�I���j�e�[�u���iln_idx�j�S�J����
        , SYSDATE
        , �v��ID
      )
     */
    lv_process_part := '�󒍖��ׁi�A�h�I���j�o�^�Q';
    FORALL ln_idx IN 1..ln_arc_cnt_line_yet
      INSERT INTO xxcmn_order_lines_all_arc VALUES l_order_line_tbl(ln_idx)
    ;
--
    /*
    l_�󒍖��ׁi�A�h�I���j�e�[�u���DDELETE;
     */
    l_order_line_tbl.DELETE;
--
    /*
    FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j
      INSERT INTO �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
      (
          �S�J����
        , �o�b�N�A�b�v�o�^��
        , �o�b�N�A�b�v�v��ID
      )
      VALUES
      (
          l_�ړ����b�g�ڍׁi�A�h�I���j�e�[�u���iln_idx�j�S�J����
        , SYSDATE
        , �v��ID
      )
     */
    lv_process_part := '�ړ����b�g�ڍׁi�A�h�I���j�o�^�Q';
    FORALL ln_idx IN 1..ln_arc_cnt_lot_yet
      INSERT INTO xxcmn_mov_lot_details_arc VALUES l_mov_lot_dtl_tbl(ln_idx)
    ;
--
    /*
    l_�ړ����b�g�ڍׁi�A�h�I���j�e�[�u���DDELETE;
     */
    l_mov_lot_dtl_tbl.DELETE;
--
    /*
    gn_�o�b�N�A�b�v�����i�󒍃w�b�_�i�A�h�I���j�j := gn_�o�b�N�A�b�v�����i�󒍃w�b�_�i�A�h�I���j�j + ln_���R�~�b�g�o�b�N�A�b�v�����i�󒍃w�b�_�i�A�h�I���j�j;
    ln_���R�~�b�g�o�b�N�A�b�v�����i�󒍃w�b�_�i�A�h�I���j�j := 0;
     */
    gn_arc_cnt_header     := gn_arc_cnt_header + ln_arc_cnt_header_yet;
    ln_arc_cnt_header_yet := 0;
--
    /*
    gn_�o�b�N�A�b�v�����i�󒍖��ׁi�A�h�I���j�j := gn_�o�b�N�A�b�v�����i�󒍖��ׁi�A�h�I���j�j + ln_���R�~�b�g�o�b�N�A�b�v�����i�󒍖��ׁi�A�h�I���j�j;
    ln_���R�~�b�g�o�b�N�A�b�v�����i�󒍖��ׁi�A�h�I���j�j := 0;
     */
    gn_arc_cnt_line     := gn_arc_cnt_line + ln_arc_cnt_line_yet;
    ln_arc_cnt_line_yet := 0;
--
    /*
    gn_�o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j := gn_�o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j + ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j;
    ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j := 0;
     */
    gn_arc_cnt_lot     := gn_arc_cnt_lot + ln_arc_cnt_lot_yet;
    ln_arc_cnt_lot_yet := 0;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
    WHEN local_process_expt THEN
      NULL;
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
      BEGIN
        IF ( SQL%BULK_EXCEPTIONS.COUNT > 0 ) THEN
--
          IF ( l_order_header_tbl.COUNT > 0 ) THEN
            lt_order_header_id := l_order_header_tbl(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).order_header_id;
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_local_others_hdr_msg
                          ,iv_token_name1  => cv_token_key
                          ,iv_token_value1 => TO_CHAR(lt_order_header_id)
                         );
          ELSIF ( l_order_line_tbl.COUNT > 0 ) THEN
            lt_order_line_id := l_order_line_tbl(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).order_line_id;
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_local_others_line_msg
                          ,iv_token_name1  => cv_token_key
                          ,iv_token_value1 => TO_CHAR(lt_order_line_id)
                         );
          ELSIF ( l_mov_lot_dtl_tbl.COUNT > 0 ) THEN
            lt_mov_lot_dtl_id := l_mov_lot_dtl_tbl(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).mov_lot_dtl_id;
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_local_others_lot_msg
                          ,iv_token_name1  => cv_token_key
                          ,iv_token_value1 => TO_CHAR(lt_mov_lot_dtl_id)
                         );
          END IF;
        END IF;
      EXCEPTION
        WHEN not_init_collection_expt THEN
          NULL;
      END;
--
      IF ( (ov_errmsg IS NULL) AND (lt_order_header_id IS NOT NULL) ) THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_local_others_hdr_msg
                      ,iv_token_name1  => cv_token_key
                      ,iv_token_value1 => TO_CHAR(lt_order_header_id)
                     );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_process_part||cv_msg_part||SQLERRM;
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_proc_date  IN  VARCHAR2       --   1.������
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCMN';            -- �A�h�I���F���ʁEIF�̈�
    cv_arc_cnt_1_msg   CONSTANT VARCHAR2(100) := 'APP-XXCMN-11005';  -- �o�b�N�A�b�v�����P�F ��CNT ��
    cv_arc_cnt_2_msg   CONSTANT VARCHAR2(100) := 'APP-XXCMN-11006';  -- �o�b�N�A�b�v�����Q�F ��CNT ��
    cv_arc_cnt_3_msg   CONSTANT VARCHAR2(100) := 'APP-XXCMN-11007';  -- �o�b�N�A�b�v�����R�F ��CNT ��
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCMN-11009';  -- ���팏���F ��CNT ��
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCMN-00010';  -- �G���[�����F ��CNT ��
    cv_proc_date_msg   CONSTANT VARCHAR2(100) := 'APP-XXCMN-11014';  -- �������F ��PAR
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'CNT';              -- �������b�Z�[�W�p�g�[�N����
    cv_par_token       CONSTANT VARCHAR2(10)  := 'PAR';              -- ���������b�Z�[�W�p�g�[�N����
    --TBL_NAME SHORI �����F CNT ��
    cv_end_msg         CONSTANT VARCHAR2(100) := 'APP-XXCMN-11040';          --�������e�o��
    cv_token_tblname   CONSTANT VARCHAR2(10)  := 'TBL_NAME';
    cv_tblname_head    CONSTANT VARCHAR2(100) := '�󒍃w�b�_(�A�h�I��)';
    cv_tblname_line    CONSTANT VARCHAR2(100) := '�󒍖���(�A�h�I��)';
    cv_tblname_lot     CONSTANT VARCHAR2(100) := '�ړ����b�g�ڍ�(�A�h�I��)';
    cv_token_shori     CONSTANT VARCHAR2(10)  := 'SHORI';
    cv_shori           CONSTANT VARCHAR2(50)  := '�o�b�N�A�b�v';
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
    --�������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_proc_date_msg
                    ,iv_token_name1  => cv_par_token
                    ,iv_token_value1 => iv_proc_date
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_proc_date -- 1.������
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�o�b�N�A�b�v����(�󒍃w�b�_(�A�h�I��))�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_end_msg
                    ,iv_token_name1  => cv_token_tblname
                    ,iv_token_value1 => cv_tblname_head
                    ,iv_token_name2  => cv_token_shori
                    ,iv_token_value2 => cv_shori
                    ,iv_token_name3  => cv_cnt_token
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt_header)
                    );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�o�b�N�A�b�v����(�󒍖���(�A�h�I��))�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_end_msg
                    ,iv_token_name1  => cv_token_tblname
                    ,iv_token_value1 => cv_tblname_line
                    ,iv_token_name2  => cv_token_shori
                    ,iv_token_value2 => cv_shori
                    ,iv_token_name3  => cv_cnt_token
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt_line)
                    );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�o�b�N�A�b�v����(�ړ����b�g�ڍ�(�A�h�I��))�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_end_msg
                    ,iv_token_name1  => cv_token_tblname
                    ,iv_token_value1 => cv_tblname_lot
                    ,iv_token_name2  => cv_token_shori
                    ,iv_token_value2 => cv_shori
                    ,iv_token_name3  => cv_cnt_token
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt_lot)
                    );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --���팏���o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_arc_cnt_header)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    IF (lv_retcode = cv_status_error) THEN
--
      gn_error_cnt := 1;
--
    ELSE
--
      gn_error_cnt := 0;
--
    END IF;
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --
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
END XXCMN960002C;
/
