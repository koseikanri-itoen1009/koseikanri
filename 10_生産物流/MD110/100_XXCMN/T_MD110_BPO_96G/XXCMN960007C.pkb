CREATE OR REPLACE PACKAGE BODY XXCMN960007C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN960007C(body)
 * Description      : �ړ��w���o�b�N�A�b�v
 * MD.050           : T_MD050_BPO_96G_�ړ��w���o�b�N�A�b�v
 * Version          : 1.00
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
 *  2012/11/09   1.00  Hiroshi.Ogawa     �V�K�쐬
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
  gn_arc_cnt_header         NUMBER;                                             -- �o�b�N�A�b�v�����i�ړ��˗�/�w���w�b�_�i�A�h�I���j�j
  gn_arc_cnt_line           NUMBER;                                             -- �o�b�N�A�b�v�����i�ړ��˗�/�w�����ׁi�A�h�I���j�j
  gn_arc_cnt_lot            NUMBER;                                             -- �o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j
  gt_mov_hdr_id             xxinv_mov_req_instr_headers.mov_hdr_id%TYPE;        -- �Ώۈړ��w�b�_ID
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN960007C'; -- �p�b�P�[�W��
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
    cv_local_others_hdr_msg     CONSTANT VARCHAR2(100) := 'APP-XXCMN-11023';  -- �o�b�N�A�b�v�����Ɏ��s���܂����B�y�ړ��w���z�ړ��w�b�_ID�F ��KEY
    cv_local_others_line_msg    CONSTANT VARCHAR2(100) := 'APP-XXCMN-11034';  -- �o�b�N�A�b�v�����Ɏ��s���܂����B�y�ړ��w���z�ړ�����ID�F ��KEY
    cv_local_others_lot_msg     CONSTANT VARCHAR2(100) := 'APP-XXCMN-11035';  -- �o�b�N�A�b�v�����Ɏ��s���܂����B�y�ړ��w���z�ړ����b�g�ڍ�ID�F ��KEY
    cv_token_profile            CONSTANT VARCHAR2(10)  := 'NG_PROFILE';
    cv_token_key                CONSTANT VARCHAR2(10)  := 'KEY';
--
    cv_xxcmn_commit_range       CONSTANT VARCHAR2(100) := 'XXCMN_COMMIT_RANGE';
    cv_xxcmn_archive_range      CONSTANT VARCHAR2(100) := 'XXCMN_ARCHIVE_RANGE';
--
    cv_ship_actual              CONSTANT VARCHAR2(2)   := '05';
    cv_arrival_ship_actual      CONSTANT VARCHAR2(2)   := '06';
    cv_move                     CONSTANT VARCHAR2(2)   := '20';
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
    ln_arc_cnt_header_yet     NUMBER DEFAULT 0;                                 -- ���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w���w�b�_�i�A�h�I���j�j
    ln_arc_cnt_line_yet       NUMBER DEFAULT 0;                                 -- ���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w�����ׁi�A�h�I���j�j
    ln_arc_cnt_lot_yet        NUMBER DEFAULT 0;                                 -- ���R�~�b�g�o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j
    ln_archive_period         NUMBER;                                           -- �o�b�N�A�b�v����
    ln_archive_range          NUMBER;                                           -- �o�b�N�A�b�v�����W
    ld_standard_date          DATE;                                             -- ���
    ln_commit_range           NUMBER;                                           -- �����R�~�b�g��
    lv_process_part           VARCHAR2(1000);                                   -- ������
    lt_mov_hdr_id             xxcmn_mov_req_instr_hdrs_arc.mov_hdr_id%TYPE;
    lt_mov_line_id            xxcmn_mov_req_instr_lines_arc.mov_line_id%TYPE;
    lt_mov_lot_dtl_id         xxcmn_mov_lot_details_arc.mov_lot_dtl_id%TYPE;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    /*
    -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
    CURSOR �p�[�W�Ώۈړ��˗�/�w���w�b�_�i�A�h�I���j�擾
      id_���  IN DATE
      in_�p�[�W�����W IN NUMBER
    IS
      SELECT 
             �ړ��˗�/�w���w�b�_�i�A�h�I���j�S�J����
      FROM �ړ��˗�/�w���w�b�_�i�A�h�I���j
      WHERE �ړ��˗�/�w���w�b�_�i�A�h�I���j�D�X�e�[�^�X IN ('05','06')
      AND �ړ��˗�/�w���w�b�_�i�A�h�I���j�D���Ɏ��ѓ� >= id_��� - in_�o�b�N�A�b�v�����W
      AND �ړ��˗�/�w���w�b�_�i�A�h�I���j�D���Ɏ��ѓ� < id_���
      AND NOT EXISTS (
               SELECT 1
               FROM �ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
               WHERE �ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v�D�ړ��w�b�_ID = �ړ��˗�/�w���w�b�_�i�A�h�I���j�D�ړ��w�b�_ID
               AND ROWNUM = 1
             )
      UNION ALL
      SELECT 
             �ړ��˗�/�w���w�b�_�i�A�h�I���j�S�J����
      FROM �ړ��˗�/�w���w�b�_�i�A�h�I���j
      WHERE �ړ��˗�/�w���w�b�_�i�A�h�I���j�D�X�e�[�^�X NOT IN ('05','06')
      AND �ړ��˗�/�w���w�b�_�i�A�h�I���j�D���ɗ\��� >= id_��� - in_�o�b�N�A�b�v�����W
      AND �ړ��˗�/�w���w�b�_�i�A�h�I���j�D���ɗ\��� < id_���
      AND NOT EXISTS (
               SELECT 1
               FROM �ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
               WHERE �ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v�D�ړ��w�b�_ID = �ړ��˗�/�w���w�b�_�i�A�h�I���j�D�ړ��w�b�_ID
               AND ROWNUM = 1
             )
     */
    CURSOR archive_mov_header_cur(
      id_standard_date           DATE
     ,in_archive_range           NUMBER
    )
    IS
      SELECT  /*+ INDEX(xmrih XXINV_MRIH_N14) */
              xmrih.mov_hdr_id                    AS mov_hdr_id
             ,xmrih.mov_num                       AS mov_num
             ,xmrih.mov_type                      AS mov_type
             ,xmrih.entered_date                  AS entered_date
             ,xmrih.instruction_post_code         AS instruction_post_code
             ,xmrih.status                        AS status
             ,xmrih.notif_status                  AS notif_status
             ,xmrih.shipped_locat_id              AS shipped_locat_id
             ,xmrih.shipped_locat_code            AS shipped_locat_code
             ,xmrih.ship_to_locat_id              AS ship_to_locat_id
             ,xmrih.ship_to_locat_code            AS ship_to_locat_code
             ,xmrih.schedule_ship_date            AS schedule_ship_date
             ,xmrih.schedule_arrival_date         AS schedule_arrival_date
             ,xmrih.freight_charge_class          AS freight_charge_class
             ,xmrih.collected_pallet_qty          AS collected_pallet_qty
             ,xmrih.out_pallet_qty                AS out_pallet_qty
             ,xmrih.in_pallet_qty                 AS in_pallet_qty
             ,xmrih.no_cont_freight_class         AS no_cont_freight_class
             ,xmrih.delivery_no                   AS delivery_no
             ,xmrih.description                   AS description
             ,xmrih.loading_efficiency_weight     AS loading_efficiency_weight
             ,xmrih.loading_efficiency_capacity   AS loading_efficiency_capacity
             ,xmrih.organization_id               AS organization_id
             ,xmrih.career_id                     AS career_id
             ,xmrih.freight_carrier_code          AS freight_carrier_code
             ,xmrih.shipping_method_code          AS shipping_method_code
             ,xmrih.actual_career_id              AS actual_career_id
             ,xmrih.actual_freight_carrier_code   AS actual_freight_carrier_code
             ,xmrih.actual_shipping_method_code   AS actual_shipping_method_code
             ,xmrih.arrival_time_from             AS arrival_time_from
             ,xmrih.arrival_time_to               AS arrival_time_to
             ,xmrih.slip_number                   AS slip_number
             ,xmrih.sum_quantity                  AS sum_quantity
             ,xmrih.small_quantity                AS small_quantity
             ,xmrih.label_quantity                AS label_quantity
             ,xmrih.based_weight                  AS based_weight
             ,xmrih.based_capacity                AS based_capacity
             ,xmrih.sum_weight                    AS sum_weight
             ,xmrih.sum_capacity                  AS sum_capacity
             ,xmrih.sum_pallet_weight             AS sum_pallet_weight
             ,xmrih.pallet_sum_quantity           AS pallet_sum_quantity
             ,xmrih.mixed_ratio                   AS mixed_ratio
             ,xmrih.weight_capacity_class         AS weight_capacity_class
             ,xmrih.actual_ship_date              AS actual_ship_date
             ,xmrih.actual_arrival_date           AS actual_arrival_date
             ,xmrih.mixed_sign                    AS mixed_sign
             ,xmrih.batch_no                      AS batch_no
             ,xmrih.item_class                    AS item_class
             ,xmrih.product_flg                   AS product_flg
             ,xmrih.no_instr_actual_class         AS no_instr_actual_class
             ,xmrih.comp_actual_flg               AS comp_actual_flg
             ,xmrih.correct_actual_flg            AS correct_actual_flg
             ,xmrih.prev_notif_status             AS prev_notif_status
             ,xmrih.notif_date                    AS notif_date
             ,xmrih.prev_delivery_no              AS prev_delivery_no
             ,xmrih.new_modify_flg                AS new_modify_flg
             ,xmrih.screen_update_by              AS screen_update_by
             ,xmrih.screen_update_date            AS screen_update_date
             ,xmrih.created_by                    AS created_by
             ,xmrih.creation_date                 AS creation_date
             ,xmrih.last_updated_by               AS last_updated_by
             ,xmrih.last_update_date              AS last_update_date
             ,xmrih.last_update_login             AS last_update_login
             ,xmrih.request_id                    AS request_id
             ,xmrih.program_application_id        AS program_application_id
             ,xmrih.program_id                    AS program_id
             ,xmrih.program_update_date           AS program_update_date
      FROM    xxinv_mov_req_instr_headers   xmrih
      WHERE   xmrih.status               IN (cv_ship_actual, cv_arrival_ship_actual)
      AND     xmrih.actual_arrival_date  >= id_standard_date - in_archive_range
      AND     xmrih.actual_arrival_date   < id_standard_date
      AND     NOT EXISTS (
                SELECT  1
                FROM    xxcmn_mov_req_instr_hdrs_arc  xmriha
                WHERE   xmriha.mov_hdr_id     = xmrih.mov_hdr_id
                AND     ROWNUM                = 1
              )
      UNION ALL
      SELECT  /*+ INDEX(xmrih XXINV_MRIH_N09) */
              xmrih.mov_hdr_id                    AS mov_hdr_id
             ,xmrih.mov_num                       AS mov_num
             ,xmrih.mov_type                      AS mov_type
             ,xmrih.entered_date                  AS entered_date
             ,xmrih.instruction_post_code         AS instruction_post_code
             ,xmrih.status                        AS status
             ,xmrih.notif_status                  AS notif_status
             ,xmrih.shipped_locat_id              AS shipped_locat_id
             ,xmrih.shipped_locat_code            AS shipped_locat_code
             ,xmrih.ship_to_locat_id              AS ship_to_locat_id
             ,xmrih.ship_to_locat_code            AS ship_to_locat_code
             ,xmrih.schedule_ship_date            AS schedule_ship_date
             ,xmrih.schedule_arrival_date         AS schedule_arrival_date
             ,xmrih.freight_charge_class          AS freight_charge_class
             ,xmrih.collected_pallet_qty          AS collected_pallet_qty
             ,xmrih.out_pallet_qty                AS out_pallet_qty
             ,xmrih.in_pallet_qty                 AS in_pallet_qty
             ,xmrih.no_cont_freight_class         AS no_cont_freight_class
             ,xmrih.delivery_no                   AS delivery_no
             ,xmrih.description                   AS description
             ,xmrih.loading_efficiency_weight     AS loading_efficiency_weight
             ,xmrih.loading_efficiency_capacity   AS loading_efficiency_capacity
             ,xmrih.organization_id               AS organization_id
             ,xmrih.career_id                     AS career_id
             ,xmrih.freight_carrier_code          AS freight_carrier_code
             ,xmrih.shipping_method_code          AS shipping_method_code
             ,xmrih.actual_career_id              AS actual_career_id
             ,xmrih.actual_freight_carrier_code   AS actual_freight_carrier_code
             ,xmrih.actual_shipping_method_code   AS actual_shipping_method_code
             ,xmrih.arrival_time_from             AS arrival_time_from
             ,xmrih.arrival_time_to               AS arrival_time_to
             ,xmrih.slip_number                   AS slip_number
             ,xmrih.sum_quantity                  AS sum_quantity
             ,xmrih.small_quantity                AS small_quantity
             ,xmrih.label_quantity                AS label_quantity
             ,xmrih.based_weight                  AS based_weight
             ,xmrih.based_capacity                AS based_capacity
             ,xmrih.sum_weight                    AS sum_weight
             ,xmrih.sum_capacity                  AS sum_capacity
             ,xmrih.sum_pallet_weight             AS sum_pallet_weight
             ,xmrih.pallet_sum_quantity           AS pallet_sum_quantity
             ,xmrih.mixed_ratio                   AS mixed_ratio
             ,xmrih.weight_capacity_class         AS weight_capacity_class
             ,xmrih.actual_ship_date              AS actual_ship_date
             ,xmrih.actual_arrival_date           AS actual_arrival_date
             ,xmrih.mixed_sign                    AS mixed_sign
             ,xmrih.batch_no                      AS batch_no
             ,xmrih.item_class                    AS item_class
             ,xmrih.product_flg                   AS product_flg
             ,xmrih.no_instr_actual_class         AS no_instr_actual_class
             ,xmrih.comp_actual_flg               AS comp_actual_flg
             ,xmrih.correct_actual_flg            AS correct_actual_flg
             ,xmrih.prev_notif_status             AS prev_notif_status
             ,xmrih.notif_date                    AS notif_date
             ,xmrih.prev_delivery_no              AS prev_delivery_no
             ,xmrih.new_modify_flg                AS new_modify_flg
             ,xmrih.screen_update_by              AS screen_update_by
             ,xmrih.screen_update_date            AS screen_update_date
             ,xmrih.created_by                    AS created_by
             ,xmrih.creation_date                 AS creation_date
             ,xmrih.last_updated_by               AS last_updated_by
             ,xmrih.last_update_date              AS last_update_date
             ,xmrih.last_update_login             AS last_update_login
             ,xmrih.request_id                    AS request_id
             ,xmrih.program_application_id        AS program_application_id
             ,xmrih.program_id                    AS program_id
             ,xmrih.program_update_date           AS program_update_date
      FROM    xxinv_mov_req_instr_headers   xmrih
      WHERE   xmrih.status             NOT IN (cv_ship_actual, cv_arrival_ship_actual)
      AND     xmrih.schedule_arrival_date  >= id_standard_date - in_archive_range
      AND     xmrih.schedule_arrival_date   < id_standard_date
      AND     NOT EXISTS (
                SELECT  1
                FROM    xxcmn_mov_req_instr_hdrs_arc  xmriha
                WHERE   xmriha.mov_hdr_id     = xmrih.mov_hdr_id
                AND     ROWNUM                = 1
              )
    ;
    /*
    -- �ړ��˗�/�w�����ׁi�A�h�I���j
    CURSOR �o�b�N�A�b�v�Ώۈړ��˗�/�w�����ׁi�A�h�I���j�擾
      in_�ړ��w�b�_�h�c IN �ړ��˗�/�w���w�b�_�i�A�h�I���j�D�ړ��w�b�_�h�c%TYPE
    IS
      SELECT
             �ړ��˗�/�w�����ׁi�A�h�I���j�S�J����
      FROM �ړ��˗�/�w�����ׁi�A�h�I���j
      WHERE �ړ��˗�/�w�����ׁi�A�h�I���j�D�ړ��w�b�_�h�c = in_�ړ��w�b�_�h�c
     */
    CURSOR archive_mov_line_cur(
      it_mov_hdr_id              xxinv_mov_req_instr_headers.mov_hdr_id%TYPE
    )
    IS
      SELECT  /*+ INDEX(xmril XXINV_MRIL_N01) */
              xmril.mov_line_id                   AS mov_line_id
             ,xmril.mov_hdr_id                    AS mov_hdr_id
             ,xmril.line_number                   AS line_number
             ,xmril.organization_id               AS organization_id
             ,xmril.item_id                       AS item_id
             ,xmril.item_code                     AS item_code
             ,xmril.request_qty                   AS request_qty
             ,xmril.pallet_quantity               AS pallet_quantity
             ,xmril.layer_quantity                AS layer_quantity
             ,xmril.case_quantity                 AS case_quantity
             ,xmril.instruct_qty                  AS instruct_qty
             ,xmril.reserved_quantity             AS reserved_quantity
             ,xmril.uom_code                      AS uom_code
             ,xmril.designated_production_date    AS designated_production_date
             ,xmril.pallet_qty                    AS pallet_qty
             ,xmril.move_num                      AS move_num
             ,xmril.po_num                        AS po_num
             ,xmril.first_instruct_qty            AS first_instruct_qty
             ,xmril.shipped_quantity              AS shipped_quantity
             ,xmril.ship_to_quantity              AS ship_to_quantity
             ,xmril.weight                        AS weight
             ,xmril.capacity                      AS capacity
             ,xmril.pallet_weight                 AS pallet_weight
             ,xmril.automanual_reserve_class      AS automanual_reserve_class
             ,xmril.delete_flg                    AS delete_flg
             ,xmril.warning_date                  AS warning_date
             ,xmril.warning_class                 AS warning_class
             ,xmril.created_by                    AS created_by
             ,xmril.creation_date                 AS creation_date
             ,xmril.last_updated_by               AS last_updated_by
             ,xmril.last_update_date              AS last_update_date
             ,xmril.last_update_login             AS last_update_login
             ,xmril.request_id                    AS request_id
             ,xmril.program_application_id        AS program_application_id
             ,xmril.program_id                    AS program_id
             ,xmril.program_update_date           AS program_update_date
      FROM    xxinv_mov_req_instr_lines  xmril
      WHERE   xmril.mov_hdr_id = it_mov_hdr_id
    ;
    /*
    -- �ړ����b�g�ڍׁi�A�h�I���j
    CURSOR �o�b�N�A�b�v�Ώۈړ����b�g�ڍׁi�A�h�I���j�擾
      in_�ړ����ׂh�c IN �ړ��˗�/�w�����ׁi�A�h�I���j�D�ړ����ׂh�c%TYPE
    IS
      SELECT
             �ړ����b�g�ڍׁi�A�h�I���j�S�J����
      FROM �ړ����b�g�ڍׁi�A�h�I���j
      WHERE �ړ����b�g�ڍׁi�A�h�I���j�D���ׂh�c = in_�ړ����ׂh�c
      AND �ړ����b�g�ڍׁi�A�h�I���j�D�����^�C�v�R�[�h = '20'
     */
    CURSOR archive_mov_lot_dtl_cur(
      it_mov_line_id             xxinv_mov_req_instr_lines.mov_line_id%TYPE
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
      WHERE   xmld.mov_line_id        = it_mov_line_id
      AND     xmld.document_type_code = cv_move
    ;
    TYPE l_mov_header_ttype   IS TABLE OF xxcmn_mov_req_instr_hdrs_arc%ROWTYPE    INDEX BY BINARY_INTEGER;
    TYPE l_mov_line_ttype     IS TABLE OF xxcmn_mov_req_instr_lines_arc%ROWTYPE   INDEX BY BINARY_INTEGER;
    TYPE l_mov_lot_dtl_ttype  IS TABLE OF xxcmn_mov_lot_details_arc%ROWTYPE       INDEX BY BINARY_INTEGER;
    -- <�J�[�\����>���R�[�h�^
    l_mov_header_tbl         l_mov_header_ttype;                                 -- �ړ��˗�/�w���w�b�_�i�A�h�I���j�e�[�u��
    l_mov_line_tbl           l_mov_line_ttype;                                   -- �ړ��˗�/�w�����ׁi�A�h�I���j�e�[�u��
    l_mov_lot_dtl_tbl        l_mov_lot_dtl_ttype;                                -- �ړ����b�g�ڍׁi�A�h�I���j�e�[�u��
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
    -- ===============================================
    -- �o�b�N�A�b�v�Ώۈړ��˗�/�w���w�b�_�i�A�h�I���j�擾
    -- ===============================================
    /*
    FOR lr_header_rec IN �o�b�N�A�b�v�Ώۈړ��˗�/�w���w�b�_�i�A�h�I���j�擾�ild_����Cln_�o�b�N�A�b�v�����W�j LOOP
     */
    << archive_mov_header_loop >>
    FOR lr_header_rec IN archive_mov_header_cur(
                           ld_standard_date
                          ,ln_archive_range
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
        ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w���w�b�_�i�A�h�I���j�j > 0
        ���� MOD(ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w���w�b�_�i�A�h�I���j�j, ln_�����R�~�b�g��) = 0�̏ꍇ
         */
        IF (  (ln_arc_cnt_header_yet > 0)
          AND (MOD(ln_arc_cnt_header_yet, ln_commit_range) = 0)
           )
        THEN
--
          /*
          FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w���w�b�_�i�A�h�I���j�j
            INSERT INTO �ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
            (
                �S�J����
              , �o�b�N�A�b�v�o�^��
              , �o�b�N�A�b�v�v��ID
            )
            VALUES
            (
                l_�ړ��˗�/�w���w�b�_�i�A�h�I���j�e�[�u���iln_idx�j�S�J����
              , SYSDATE
              , �v��ID
            )
           */
          lv_process_part := '�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�^�P';
          FORALL ln_idx IN 1..ln_arc_cnt_header_yet
            INSERT INTO xxcmn_mov_req_instr_hdrs_arc VALUES l_mov_header_tbl(ln_idx)
          ;
--
          /*
          l_�ړ��˗�/�w���w�b�_�i�A�h�I���j�e�[�u���DDELETE;
           */
          l_mov_header_tbl.DELETE;
--
          /*
          FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w�����ׁi�A�h�I���j�j
            INSERT INTO �ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
            (
                �S�J����
              , �o�b�N�A�b�v�o�^��
              , �o�b�N�A�b�v�v��ID
            )
            VALUES
            (
                l_�ړ��˗�/�w�����ׁi�A�h�I���j�e�[�u���iln_idx�j�S�J����
              , SYSDATE
              , �v��ID
            )
           */
          lv_process_part := '�ړ��˗�/�w�����ׁi�A�h�I���j�o�^�P';
          FORALL ln_idx IN 1..ln_arc_cnt_line_yet
            INSERT INTO xxcmn_mov_req_instr_lines_arc VALUES l_mov_line_tbl(ln_idx)
          ;
--
          /*
          l_�ړ��˗�/�w�����ׁi�A�h�I���j�e�[�u���DDELETE;
           */
          l_mov_line_tbl.DELETE;
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
          ln_�o�b�N�A�b�v�����i�ړ��˗�/�w���w�b�_�i�A�h�I���j�j  := ln_�o�b�N�A�b�v�����i�ړ��˗�/�w���w�b�_�i�A�h�I���j�j
                                                                   + ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w���w�b�_�i�A�h�I���j�j;
          ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w���w�b�_�i�A�h�I���j�j := 0;
           */
          gn_arc_cnt_header     := gn_arc_cnt_header + ln_arc_cnt_header_yet;
          ln_arc_cnt_header_yet := 0;
--
          /*
          ln_�o�b�N�A�b�v�����i�ړ��˗�/�w�����ׁi�A�h�I���j�j  := ln_�o�b�N�A�b�v�����i�ړ��˗�/�w�����ׁi�A�h�I���j�j
                                                                 + ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w�����ׁi�A�h�I���j�j;
          ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w�����ׁi�A�h�I���j�j := 0;
           */
          gn_arc_cnt_line     := gn_arc_cnt_line + ln_arc_cnt_line_yet;
          ln_arc_cnt_line_yet := 0;
--
          /*
          ln_�o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j := ln_�o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j + ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j;
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
      gt_�Ώۈړ��w�b�_ID := lr_header_rec�D�ړ��w�b�_ID;
       */
      gt_mov_hdr_id := lr_header_rec.mov_hdr_id;
--
      -- ===============================================
      -- �o�b�N�A�b�v�Ώۈړ��˗�/�w�����ׁi�A�h�I���j�擾
      -- ===============================================
      /*
      FOR lr_line_rec IN �o�b�N�A�b�v�Ώۈړ��˗�/�w�����ׁi�A�h�I���j�擾�ilr_header_rec�D�ړ��w�b�_ID�j LOOP
       */
      << archive_mov_line_loop >>
      FOR lr_line_rec IN archive_mov_line_cur(
                           lr_header_rec.mov_hdr_id
                         )
      LOOP
--
        -- ===============================================
        -- �o�b�N�A�b�v�Ώۈړ����b�g�ڍׁi�A�h�I���j�擾
        -- ===============================================
        /*
        FOR lr_lot_rec IN �o�b�N�A�b�v�Ώۈړ����b�g�ڍׁi�A�h�I���j�擾�ilr_line_rec�D�ړ��˗�/�w�����׃A�h�I��ID�j LOOP
         */
        << archive_mov_lot_dtl_loop >>
        FOR lr_lot_rec IN archive_mov_lot_dtl_cur(
                            lr_line_rec.mov_line_id
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
        ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w�����ׁi�A�h�I���j�j := ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w�����ׁi�A�h�I���j�j + 1;
        l_�ړ��˗�/�w�����ׁi�A�h�I���j�e�[�u���iln_���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w�����ׁi�A�h�I���j�j := lr_line_rec;
         */
        ln_arc_cnt_line_yet := ln_arc_cnt_line_yet + 1;
        l_mov_line_tbl(ln_arc_cnt_line_yet).mov_line_id                := lr_line_rec.mov_line_id;
        l_mov_line_tbl(ln_arc_cnt_line_yet).mov_hdr_id                 := lr_line_rec.mov_hdr_id;
        l_mov_line_tbl(ln_arc_cnt_line_yet).line_number                := lr_line_rec.line_number;
        l_mov_line_tbl(ln_arc_cnt_line_yet).organization_id            := lr_line_rec.organization_id;
        l_mov_line_tbl(ln_arc_cnt_line_yet).item_id                    := lr_line_rec.item_id;
        l_mov_line_tbl(ln_arc_cnt_line_yet).item_code                  := lr_line_rec.item_code;
        l_mov_line_tbl(ln_arc_cnt_line_yet).request_qty                := lr_line_rec.request_qty;
        l_mov_line_tbl(ln_arc_cnt_line_yet).pallet_quantity            := lr_line_rec.pallet_quantity;
        l_mov_line_tbl(ln_arc_cnt_line_yet).layer_quantity             := lr_line_rec.layer_quantity;
        l_mov_line_tbl(ln_arc_cnt_line_yet).case_quantity              := lr_line_rec.case_quantity;
        l_mov_line_tbl(ln_arc_cnt_line_yet).instruct_qty               := lr_line_rec.instruct_qty;
        l_mov_line_tbl(ln_arc_cnt_line_yet).reserved_quantity          := lr_line_rec.reserved_quantity;
        l_mov_line_tbl(ln_arc_cnt_line_yet).uom_code                   := lr_line_rec.uom_code;
        l_mov_line_tbl(ln_arc_cnt_line_yet).designated_production_date := lr_line_rec.designated_production_date;
        l_mov_line_tbl(ln_arc_cnt_line_yet).pallet_qty                 := lr_line_rec.pallet_qty;
        l_mov_line_tbl(ln_arc_cnt_line_yet).move_num                   := lr_line_rec.move_num;
        l_mov_line_tbl(ln_arc_cnt_line_yet).po_num                     := lr_line_rec.po_num;
        l_mov_line_tbl(ln_arc_cnt_line_yet).first_instruct_qty         := lr_line_rec.first_instruct_qty;
        l_mov_line_tbl(ln_arc_cnt_line_yet).shipped_quantity           := lr_line_rec.shipped_quantity;
        l_mov_line_tbl(ln_arc_cnt_line_yet).ship_to_quantity           := lr_line_rec.ship_to_quantity;
        l_mov_line_tbl(ln_arc_cnt_line_yet).weight                     := lr_line_rec.weight;
        l_mov_line_tbl(ln_arc_cnt_line_yet).capacity                   := lr_line_rec.capacity;
        l_mov_line_tbl(ln_arc_cnt_line_yet).pallet_weight              := lr_line_rec.pallet_weight;
        l_mov_line_tbl(ln_arc_cnt_line_yet).automanual_reserve_class   := lr_line_rec.automanual_reserve_class;
        l_mov_line_tbl(ln_arc_cnt_line_yet).delete_flg                 := lr_line_rec.delete_flg;
        l_mov_line_tbl(ln_arc_cnt_line_yet).warning_date               := lr_line_rec.warning_date;
        l_mov_line_tbl(ln_arc_cnt_line_yet).warning_class              := lr_line_rec.warning_class;
        l_mov_line_tbl(ln_arc_cnt_line_yet).created_by                 := lr_line_rec.created_by;
        l_mov_line_tbl(ln_arc_cnt_line_yet).creation_date              := lr_line_rec.creation_date;
        l_mov_line_tbl(ln_arc_cnt_line_yet).last_updated_by            := lr_line_rec.last_updated_by;
        l_mov_line_tbl(ln_arc_cnt_line_yet).last_update_date           := lr_line_rec.last_update_date;
        l_mov_line_tbl(ln_arc_cnt_line_yet).last_update_login          := lr_line_rec.last_update_login;
        l_mov_line_tbl(ln_arc_cnt_line_yet).request_id                 := lr_line_rec.request_id;
        l_mov_line_tbl(ln_arc_cnt_line_yet).program_application_id     := lr_line_rec.program_application_id;
        l_mov_line_tbl(ln_arc_cnt_line_yet).program_id                 := lr_line_rec.program_id;
        l_mov_line_tbl(ln_arc_cnt_line_yet).program_update_date        := lr_line_rec.program_update_date;
        l_mov_line_tbl(ln_arc_cnt_line_yet).archive_date               := SYSDATE;
        l_mov_line_tbl(ln_arc_cnt_line_yet).archive_request_id         := cn_request_id;
--
      END LOOP archive_mov_line_loop;
--
      /*
      ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w���w�b�_�i�A�h�I���j�j := ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w���w�b�_�i�A�h�I���j�j + 1;
      l_�ړ��˗�/�w���w�b�_�i�A�h�I���j�e�[�u���iln_���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w���w�b�_�i�A�h�I���j�j := lr_header_rec;
       */
      ln_arc_cnt_header_yet := ln_arc_cnt_header_yet + 1;
      l_mov_header_tbl(ln_arc_cnt_header_yet).mov_hdr_id                  := lr_header_rec.mov_hdr_id;
      l_mov_header_tbl(ln_arc_cnt_header_yet).mov_num                     := lr_header_rec.mov_num;
      l_mov_header_tbl(ln_arc_cnt_header_yet).mov_type                    := lr_header_rec.mov_type;
      l_mov_header_tbl(ln_arc_cnt_header_yet).entered_date                := lr_header_rec.entered_date;
      l_mov_header_tbl(ln_arc_cnt_header_yet).instruction_post_code       := lr_header_rec.instruction_post_code;
      l_mov_header_tbl(ln_arc_cnt_header_yet).status                      := lr_header_rec.status;
      l_mov_header_tbl(ln_arc_cnt_header_yet).notif_status                := lr_header_rec.notif_status;
      l_mov_header_tbl(ln_arc_cnt_header_yet).shipped_locat_id            := lr_header_rec.shipped_locat_id;
      l_mov_header_tbl(ln_arc_cnt_header_yet).shipped_locat_code          := lr_header_rec.shipped_locat_code;
      l_mov_header_tbl(ln_arc_cnt_header_yet).ship_to_locat_id            := lr_header_rec.ship_to_locat_id;
      l_mov_header_tbl(ln_arc_cnt_header_yet).ship_to_locat_code          := lr_header_rec.ship_to_locat_code;
      l_mov_header_tbl(ln_arc_cnt_header_yet).schedule_ship_date          := lr_header_rec.schedule_ship_date;
      l_mov_header_tbl(ln_arc_cnt_header_yet).schedule_arrival_date       := lr_header_rec.schedule_arrival_date;
      l_mov_header_tbl(ln_arc_cnt_header_yet).freight_charge_class        := lr_header_rec.freight_charge_class;
      l_mov_header_tbl(ln_arc_cnt_header_yet).collected_pallet_qty        := lr_header_rec.collected_pallet_qty;
      l_mov_header_tbl(ln_arc_cnt_header_yet).out_pallet_qty              := lr_header_rec.out_pallet_qty;
      l_mov_header_tbl(ln_arc_cnt_header_yet).in_pallet_qty               := lr_header_rec.in_pallet_qty;
      l_mov_header_tbl(ln_arc_cnt_header_yet).no_cont_freight_class       := lr_header_rec.no_cont_freight_class;
      l_mov_header_tbl(ln_arc_cnt_header_yet).delivery_no                 := lr_header_rec.delivery_no;
      l_mov_header_tbl(ln_arc_cnt_header_yet).description                 := lr_header_rec.description;
      l_mov_header_tbl(ln_arc_cnt_header_yet).loading_efficiency_weight   := lr_header_rec.loading_efficiency_weight;
      l_mov_header_tbl(ln_arc_cnt_header_yet).loading_efficiency_capacity := lr_header_rec.loading_efficiency_capacity;
      l_mov_header_tbl(ln_arc_cnt_header_yet).organization_id             := lr_header_rec.organization_id;
      l_mov_header_tbl(ln_arc_cnt_header_yet).career_id                   := lr_header_rec.career_id;
      l_mov_header_tbl(ln_arc_cnt_header_yet).freight_carrier_code        := lr_header_rec.freight_carrier_code;
      l_mov_header_tbl(ln_arc_cnt_header_yet).shipping_method_code        := lr_header_rec.shipping_method_code;
      l_mov_header_tbl(ln_arc_cnt_header_yet).actual_career_id            := lr_header_rec.actual_career_id;
      l_mov_header_tbl(ln_arc_cnt_header_yet).actual_freight_carrier_code := lr_header_rec.actual_freight_carrier_code;
      l_mov_header_tbl(ln_arc_cnt_header_yet).actual_shipping_method_code := lr_header_rec.actual_shipping_method_code;
      l_mov_header_tbl(ln_arc_cnt_header_yet).arrival_time_from           := lr_header_rec.arrival_time_from;
      l_mov_header_tbl(ln_arc_cnt_header_yet).arrival_time_to             := lr_header_rec.arrival_time_to;
      l_mov_header_tbl(ln_arc_cnt_header_yet).slip_number                 := lr_header_rec.slip_number;
      l_mov_header_tbl(ln_arc_cnt_header_yet).sum_quantity                := lr_header_rec.sum_quantity;
      l_mov_header_tbl(ln_arc_cnt_header_yet).small_quantity              := lr_header_rec.small_quantity;
      l_mov_header_tbl(ln_arc_cnt_header_yet).label_quantity              := lr_header_rec.label_quantity;
      l_mov_header_tbl(ln_arc_cnt_header_yet).based_weight                := lr_header_rec.based_weight;
      l_mov_header_tbl(ln_arc_cnt_header_yet).based_capacity              := lr_header_rec.based_capacity;
      l_mov_header_tbl(ln_arc_cnt_header_yet).sum_weight                  := lr_header_rec.sum_weight;
      l_mov_header_tbl(ln_arc_cnt_header_yet).sum_capacity                := lr_header_rec.sum_capacity;
      l_mov_header_tbl(ln_arc_cnt_header_yet).sum_pallet_weight           := lr_header_rec.sum_pallet_weight;
      l_mov_header_tbl(ln_arc_cnt_header_yet).pallet_sum_quantity         := lr_header_rec.pallet_sum_quantity;
      l_mov_header_tbl(ln_arc_cnt_header_yet).mixed_ratio                 := lr_header_rec.mixed_ratio;
      l_mov_header_tbl(ln_arc_cnt_header_yet).weight_capacity_class       := lr_header_rec.weight_capacity_class;
      l_mov_header_tbl(ln_arc_cnt_header_yet).actual_ship_date            := lr_header_rec.actual_ship_date;
      l_mov_header_tbl(ln_arc_cnt_header_yet).actual_arrival_date         := lr_header_rec.actual_arrival_date;
      l_mov_header_tbl(ln_arc_cnt_header_yet).mixed_sign                  := lr_header_rec.mixed_sign;
      l_mov_header_tbl(ln_arc_cnt_header_yet).batch_no                    := lr_header_rec.batch_no;
      l_mov_header_tbl(ln_arc_cnt_header_yet).item_class                  := lr_header_rec.item_class;
      l_mov_header_tbl(ln_arc_cnt_header_yet).product_flg                 := lr_header_rec.product_flg;
      l_mov_header_tbl(ln_arc_cnt_header_yet).no_instr_actual_class       := lr_header_rec.no_instr_actual_class;
      l_mov_header_tbl(ln_arc_cnt_header_yet).comp_actual_flg             := lr_header_rec.comp_actual_flg;
      l_mov_header_tbl(ln_arc_cnt_header_yet).correct_actual_flg          := lr_header_rec.correct_actual_flg;
      l_mov_header_tbl(ln_arc_cnt_header_yet).prev_notif_status           := lr_header_rec.prev_notif_status;
      l_mov_header_tbl(ln_arc_cnt_header_yet).notif_date                  := lr_header_rec.notif_date;
      l_mov_header_tbl(ln_arc_cnt_header_yet).prev_delivery_no            := lr_header_rec.prev_delivery_no;
      l_mov_header_tbl(ln_arc_cnt_header_yet).new_modify_flg              := lr_header_rec.new_modify_flg;
      l_mov_header_tbl(ln_arc_cnt_header_yet).screen_update_by            := lr_header_rec.screen_update_by;
      l_mov_header_tbl(ln_arc_cnt_header_yet).screen_update_date          := lr_header_rec.screen_update_date;
      l_mov_header_tbl(ln_arc_cnt_header_yet).created_by                  := lr_header_rec.created_by;
      l_mov_header_tbl(ln_arc_cnt_header_yet).creation_date               := lr_header_rec.creation_date;
      l_mov_header_tbl(ln_arc_cnt_header_yet).last_updated_by             := lr_header_rec.last_updated_by;
      l_mov_header_tbl(ln_arc_cnt_header_yet).last_update_date            := lr_header_rec.last_update_date;
      l_mov_header_tbl(ln_arc_cnt_header_yet).last_update_login           := lr_header_rec.last_update_login;
      l_mov_header_tbl(ln_arc_cnt_header_yet).request_id                  := lr_header_rec.request_id;
      l_mov_header_tbl(ln_arc_cnt_header_yet).program_application_id      := lr_header_rec.program_application_id;
      l_mov_header_tbl(ln_arc_cnt_header_yet).program_id                  := lr_header_rec.program_id;
      l_mov_header_tbl(ln_arc_cnt_header_yet).program_update_date         := lr_header_rec.program_update_date;
      l_mov_header_tbl(ln_arc_cnt_header_yet).archive_date                := SYSDATE;
      l_mov_header_tbl(ln_arc_cnt_header_yet).archive_request_id          := cn_request_id;
--
    END LOOP archive_mov_header_loop;
--
    /*
    FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w���w�b�_�i�A�h�I���j�j
      INSERT INTO �ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
      (
           �S�J����
        , �o�b�N�A�b�v�o�^��
        , �o�b�N�A�b�v�v��ID
      )
      VALUES
      (
          l_�ړ��˗�/�w���w�b�_�i�A�h�I���j�e�[�u���iln_idx�j�S�J����
        , SYSDATE
        , �v��ID
      )
     */
    lv_process_part := '�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�^�Q';
    FORALL ln_idx IN 1..ln_arc_cnt_header_yet
      INSERT INTO xxcmn_mov_req_instr_hdrs_arc VALUES l_mov_header_tbl(ln_idx)
    ;
--
    /*
    l_�ړ��˗�/�w���w�b�_�i�A�h�I���j�e�[�u���DDELETE;
     */
    l_mov_header_tbl.DELETE;
--
    /*
    FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w�����ׁi�A�h�I���j�j
      INSERT INTO �ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
      (
          �S�J����
        , �o�b�N�A�b�v�o�^��
        , �o�b�N�A�b�v�v��ID
      )
      VALUES
      (
          l_�ړ��˗�/�w�����ׁi�A�h�I���j�e�[�u���iln_idx�j�S�J����
        , SYSDATE
        , �v��ID
      )
     */
    lv_process_part := '�ړ��˗�/�w�����ׁi�A�h�I���j�o�^�Q';
    FORALL ln_idx IN 1..ln_arc_cnt_line_yet
      INSERT INTO xxcmn_mov_req_instr_lines_arc VALUES l_mov_line_tbl(ln_idx)
    ;
--
    /*
    l_�ړ��˗�/�w�����ׁi�A�h�I���j�e�[�u���DDELETE;
     */
    l_mov_line_tbl.DELETE;
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
    ln_�o�b�N�A�b�v�����i�ړ��˗�/�w���w�b�_�i�A�h�I���j�j := ln_�o�b�N�A�b�v�����i�ړ��˗�/�w���w�b�_�i�A�h�I���j�j
                                                            + ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w���w�b�_�i�A�h�I���j�j;
    ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w���w�b�_�i�A�h�I���j�j := 0;
     */
    gn_arc_cnt_header     := gn_arc_cnt_header + ln_arc_cnt_header_yet;
    ln_arc_cnt_header_yet := 0;
--
    /*
    ln_�o�b�N�A�b�v�����i�ړ��˗�/�w�����ׁi�A�h�I���j�j := ln_�o�b�N�A�b�v�����i�ړ��˗�/�w�����ׁi�A�h�I���j�j
                                                          + ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w�����ׁi�A�h�I���j�j;
    ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ��˗�/�w�����ׁi�A�h�I���j�j := 0;
     */
    gn_arc_cnt_line     := gn_arc_cnt_line + ln_arc_cnt_line_yet;
    ln_arc_cnt_line_yet := 0;
--
    /*
    ln_�o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j := ln_�o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j + ln_���R�~�b�g�o�b�N�A�b�v�����i�ړ����b�g�ڍׁi�A�h�I���j�j;
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
          IF ( l_mov_header_tbl.COUNT > 0 ) THEN
            lt_mov_hdr_id := l_mov_header_tbl(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).mov_hdr_id;
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_local_others_hdr_msg
                          ,iv_token_name1  => cv_token_key
                          ,iv_token_value1 => TO_CHAR(lt_mov_hdr_id)
                         );
          ELSIF ( l_mov_line_tbl.COUNT > 0 ) THEN
            lt_mov_line_id := l_mov_line_tbl(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).mov_line_id;
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_local_others_line_msg
                          ,iv_token_name1  => cv_token_key
                          ,iv_token_value1 => TO_CHAR(lt_mov_line_id)
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
      IF ( (ov_errmsg IS NULL) AND (gt_mov_hdr_id IS NOT NULL) ) THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_local_others_hdr_msg
                      ,iv_token_name1  => cv_token_key
                      ,iv_token_value1 => TO_CHAR(gt_mov_hdr_id)
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
    cv_appl_short_name  CONSTANT VARCHAR2(10)  := 'XXCMN';                          -- �A�h�I���F���ʁEIF�̈�
    cv_cnt_msg          CONSTANT VARCHAR2(100) := 'APP-XXCMN-11040';                -- ��TBL_NAME ��SHORI �����F ��CNT ��
    cv_token_cnt        CONSTANT VARCHAR2(100) := 'CNT';                            -- �������b�Z�[�W�p�g�[�N�����i�����j
    cv_token_cnt_table  CONSTANT VARCHAR2(100) := 'TBL_NAME';                       -- �������b�Z�[�W�p�g�[�N�����i�e�[�u�����j
    cv_token_cnt_shori  CONSTANT VARCHAR2(100) := 'SHORI';                          -- �������b�Z�[�W�p�g�[�N�����i�������j
    cv_table_cnt_xmrih  CONSTANT VARCHAR2(100) := '�ړ��˗�/�w���w�b�_(�A�h�I��)';  -- �������b�Z�[�W�p�e�[�u����
    cv_table_cnt_xmril  CONSTANT VARCHAR2(100) := '�ړ��˗�/�w������(�A�h�I��)';    -- �������b�Z�[�W�p�e�[�u����
    cv_table_cnt_xmld   CONSTANT VARCHAR2(100) := '�ړ����b�g����(�A�h�I��)';       -- �������b�Z�[�W�p�e�[�u����
    cv_shori_cnt_arc    CONSTANT VARCHAR2(100) := '�o�b�N�A�b�v';                   -- �������b�Z�[�W�p������
    cv_target_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCMN-11008';  -- �Ώی����F ��CNT ��
    cv_success_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCMN-11009';  -- ���팏���F ��CNT ��
    cv_error_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCMN-00010';  -- �G���[�����F ��CNT ��
    cv_proc_date_msg    CONSTANT VARCHAR2(100) := 'APP-XXCMN-11014';                -- �������F ��PAR
    cv_par_token        CONSTANT VARCHAR2(100) := 'PAR';                            -- ���������b�Z�[�W�p�g�[�N����
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
    --header�o�b�N�A�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xmrih
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_arc
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt_header)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --line�o�b�N�A�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xmril
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_arc
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt_line)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --lot�o�b�N�A�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xmld
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_arc
                    ,iv_token_name3  => cv_token_cnt
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
                    ,iv_token_name1  => cv_token_cnt
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
                    ,iv_token_name1  => cv_token_cnt
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
END XXCMN960007C;
/
