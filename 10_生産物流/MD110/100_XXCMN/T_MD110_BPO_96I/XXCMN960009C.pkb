CREATE OR REPLACE PACKAGE BODY XXCMN960009C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN960009C(body)
 * Description      : �z�Ԕz���v��o�b�N�A�b�v
 * MD.050           : T_MD050_BPO_96I_�z�Ԕz���v��o�b�N�A�b�v.xls
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
 *  2012/10/29    1.00  SCSK �{�{����    �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal   CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_error    CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --�ُ�:2
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
  local_process_expt        EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCMN960009C';            -- �p�b�P�[�W��
  cv_proc_date_msg   CONSTANT VARCHAR2(50)  := 'APP-XXCMN-11014';         --�������o��
  cv_par_token       CONSTANT VARCHAR2(10)  := 'PAR';                     --������MSG�pİ�ݖ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_arc_cnt_carrier        NUMBER;                                       -- �o�b�N�A�b�v�����i�z�Ԕz���v��i�A�h�I���j�j
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
    cv_prg_name            CONSTANT VARCHAR2(100) := 'submain';             -- �v���O������
    cv_appl_short_name     CONSTANT VARCHAR2(10)  := 'XXCMN';               -- �A�h�I���F���ʁEIF�̈�
    cv_get_priod_msg       CONSTANT VARCHAR2(100) := 'APP-XXCMN-11012';     -- �o�b�N�A�b�v���Ԃ̎擾�Ɏ��s���܂����B
    cv_get_profile_msg     CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002';     -- �v���t�@�C��[ ��NG_PROFILE ]�̎擾�Ɏ��s���܂����B
    cv_local_others_msg    CONSTANT VARCHAR2(100) := 'APP-XXCMN-11025';     -- �o�b�N�A�b�v�����Ɏ��s���܂����B�y�z�Ԕz���v��z���ID�F ��KEY
    cv_token_profile       CONSTANT VARCHAR2(10)  := 'NG_PROFILE';
    cv_token_key           CONSTANT VARCHAR2(10)  := 'KEY';
--
    cv_xxcmn_commit_range  CONSTANT VARCHAR2(100) := 'XXCMN_COMMIT_RANGE';  --XXCMN:�����R�~�b�g��
    cv_xxcmn_archive_range CONSTANT VARCHAR2(100) := 'XXCMN_ARCHIVE_RANGE'; --XXCMN:�o�b�N�A�b�v�����W
--
    cv_date_format         CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
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
    cv_purge_type   CONSTANT VARCHAR2(1)  := '1';                           -- �p�[�W�^�C�v�i1:�o�b�N�A�b�v�������ԁj
    cv_purge_code   CONSTANT VARCHAR2(30) := '9601';                        -- �p�[�W��`�R�[�h
--
    -- *** ���[�J���ϐ� ***
    ln_arc_cnt_carrier_yet    NUMBER DEFAULT 0;                             -- ���R�~�b�g�o�b�N�A�b�v�����i�z�Ԕz���v��i�A�h�I���j�j
    ln_archive_period         NUMBER;                                       -- �o�b�N�A�b�v����
    ln_archive_range          NUMBER;                                       -- �o�b�N�A�b�v�����W
    ld_standard_date          DATE;                                         -- ���
    ln_commit_range           NUMBER;                                       -- �����R�~�b�g��
    lt_transaction_id         xxwsh_carriers_schedule.transaction_id%TYPE;  -- �Ώۃg�����U�N�V����ID
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    /*
        -- �z�Ԕz���v��i�A�h�I���j
        CURSOR �o�b�N�A�b�v�Ώ۔z�Ԕz���v��i�A�h�I���j�擾
          id_���  IN DATE
          in_�o�b�N�A�b�v�����W IN NUMBER
        IS
          SELECT 
                 �z�Ԕz���v��i�A�h�I���j�D�g�����U�N�V�����h�c
          FROM �z�Ԕz���v��i�A�h�I���j
          WHERE �z�Ԕz���v��i�A�h�I���j�D���ד� IS NOT NULL
          AND �z�Ԕz���v��i�A�h�I���j�D���ד� >= id_��� - in_�o�b�N�A�b�v�����W
          AND �z�Ԕz���v��i�A�h�I���j�D���ד� < id_���
          AND NOT EXISTS (
                   SELECT  1
                   FROM �z�Ԕz���v��i�A�h�I���j�o�b�N�A�b�v
                   WHERE �z�Ԕz���v��i�A�h�I���j�o�b�N�A�b�v�D�g�����U�N�V�����h�c = �z�Ԕz���v��i�A�h�I���j�D�g�����U�N�V�����h�c
                   AND ROWNUM = 1
                 )
          UNION ALL
          SELECT 
                 �z�Ԕz���v��i�A�h�I���j�D�g�����U�N�V�����h�c
          FROM �z�Ԕz���v��i�A�h�I���j
          WHERE �z�Ԕz���v��i�A�h�I���j�D���ד� IS NULL
          AND �z�Ԕz���v��i�A�h�I���j�D���ח\��� >= id_��� - in_�o�b�N�A�b�v�����W
          AND �z�Ԕz���v��i�A�h�I���j�D���ח\��� < id_���
          AND NOT EXISTS (
                   SELECT  1
                   FROM �z�Ԕz���v��i�A�h�I���j�o�b�N�A�b�v
                   WHERE �z�Ԕz���v��i�A�h�I���j�o�b�N�A�b�v�D�g�����U�N�V�����h�c = �z�Ԕz���v��i�A�h�I���j�D�g�����U�N�V�����h�c
                   AND ROWNUM = 1
                 )
        ;
    */
--
    CURSOR arc_carriers_schedule_cur(
      id_standard_date           DATE
     ,in_archive_range           NUMBER
    )
    IS
      SELECT   xcs.transaction_id               AS transaction_id
              ,xcs.transaction_type             AS transaction_type
              ,xcs.mixed_type                   AS mixed_type
              ,xcs.delivery_no                  AS delivery_no
              ,xcs.default_line_number          AS default_line_number
              ,xcs.carrier_id                   AS carrier_id
              ,xcs.carrier_code                 AS carrier_code
              ,xcs.deliver_from_id              AS deliver_from_id
              ,xcs.deliver_from                 AS deliver_from
              ,xcs.deliver_to_id                AS deliver_to_id
              ,xcs.deliver_to                   AS deliver_to
              ,xcs.deliver_to_code_class        AS deliver_to_code_class
              ,xcs.delivery_type                AS delivery_type
              ,xcs.order_type_id                AS order_type_id
              ,xcs.auto_process_type            AS auto_process_type
              ,xcs.schedule_ship_date           AS schedule_ship_date
              ,xcs.schedule_arrival_date        AS schedule_arrival_date
              ,xcs.description                  AS description
              ,xcs.payment_freight_flag         AS payment_freight_flag
              ,xcs.demand_freight_flag          AS demand_freight_flag
              ,xcs.sum_loading_weight           AS sum_loading_weight
              ,xcs.sum_loading_capacity         AS sum_loading_capacity
              ,xcs.loading_efficiency_weight    AS loading_efficiency_weight
              ,xcs.loading_efficiency_capacity  AS loading_efficiency_capacity
              ,xcs.based_weight                 AS based_weight
              ,xcs.based_capacity               AS based_capacity
              ,xcs.result_freight_carrier_id    AS result_freight_carrier_id
              ,xcs.result_freight_carrier_code  AS result_freight_carrier_code
              ,xcs.result_shipping_method_code  AS result_shipping_method_code
              ,xcs.shipped_date                 AS shipped_date
              ,xcs.arrival_date                 AS arrival_date
              ,xcs.weight_capacity_class        AS weight_capacity_class
              ,xcs.freight_charge_type          AS freight_charge_type
              ,xcs.slip_number                  AS slip_number
              ,xcs.small_quantity               AS small_quantity
              ,xcs.label_quantity               AS label_quantity
              ,xcs.prod_class                   AS prod_class
              ,xcs.non_slip_class               AS non_slip_class
              ,xcs.created_by                   AS created_by
              ,xcs.creation_date                AS creation_date
              ,xcs.last_updated_by              AS last_updated_by
              ,xcs.last_update_date             AS last_update_date
              ,xcs.last_update_login            AS last_update_login
              ,xcs.request_id                   AS request_id
              ,xcs.program_application_id       AS program_application_id
              ,xcs.program_id                   AS program_id
              ,xcs.program_update_date          AS program_update_date
      FROM    xxwsh_carriers_schedule xcs
      WHERE   xcs.arrival_date IS NOT NULL
      AND     xcs.arrival_date >= id_standard_date - in_archive_range
      AND     xcs.arrival_date <  id_standard_date
      AND     NOT EXISTS (
                SELECT  1
                FROM    xxcmn_carriers_schedule_arc  xcsa
                WHERE   xcsa.transaction_id = xcs.transaction_id
                AND     ROWNUM                = 1
              )
      UNION ALL
      SELECT   xcs.transaction_id               AS transaction_id
              ,xcs.transaction_type             AS transaction_type
              ,xcs.mixed_type                   AS mixed_type
              ,xcs.delivery_no                  AS delivery_no
              ,xcs.default_line_number          AS default_line_number
              ,xcs.carrier_id                   AS carrier_id
              ,xcs.carrier_code                 AS carrier_code
              ,xcs.deliver_from_id              AS deliver_from_id
              ,xcs.deliver_from                 AS deliver_from
              ,xcs.deliver_to_id                AS deliver_to_id
              ,xcs.deliver_to                   AS deliver_to
              ,xcs.deliver_to_code_class        AS deliver_to_code_class
              ,xcs.delivery_type                AS delivery_type
              ,xcs.order_type_id                AS order_type_id
              ,xcs.auto_process_type            AS auto_process_type
              ,xcs.schedule_ship_date           AS schedule_ship_date
              ,xcs.schedule_arrival_date        AS schedule_arrival_date
              ,xcs.description                  AS description
              ,xcs.payment_freight_flag         AS payment_freight_flag
              ,xcs.demand_freight_flag          AS demand_freight_flag
              ,xcs.sum_loading_weight           AS sum_loading_weight
              ,xcs.sum_loading_capacity         AS sum_loading_capacity
              ,xcs.loading_efficiency_weight    AS loading_efficiency_weight
              ,xcs.loading_efficiency_capacity  AS loading_efficiency_capacity
              ,xcs.based_weight                 AS based_weight
              ,xcs.based_capacity               AS based_capacity
              ,xcs.result_freight_carrier_id    AS result_freight_carrier_id
              ,xcs.result_freight_carrier_code  AS result_freight_carrier_code
              ,xcs.result_shipping_method_code  AS result_shipping_method_code
              ,xcs.shipped_date                 AS shipped_date
              ,xcs.arrival_date                 AS arrival_date
              ,xcs.weight_capacity_class        AS weight_capacity_class
              ,xcs.freight_charge_type          AS freight_charge_type
              ,xcs.slip_number                  AS slip_number
              ,xcs.small_quantity               AS small_quantity
              ,xcs.label_quantity               AS label_quantity
              ,xcs.prod_class                   AS prod_class
              ,xcs.non_slip_class               AS non_slip_class
              ,xcs.created_by                   AS created_by
              ,xcs.creation_date                AS creation_date
              ,xcs.last_updated_by              AS last_updated_by
              ,xcs.last_update_date             AS last_update_date
              ,xcs.last_update_login            AS last_update_login
              ,xcs.request_id                   AS request_id
              ,xcs.program_application_id       AS program_application_id
              ,xcs.program_id                   AS program_id
              ,xcs.program_update_date          AS program_update_date
      FROM    xxwsh_carriers_schedule xcs
      WHERE   xcs.arrival_date IS NULL
      AND     xcs.schedule_arrival_date >= id_standard_date - in_archive_range
      AND     xcs.schedule_arrival_date <  id_standard_date
      AND     NOT EXISTS (
                SELECT  1
                FROM    xxcmn_carriers_schedule_arc  xcsa
                WHERE   xcsa.transaction_id = xcs.transaction_id
                AND     ROWNUM                = 1
              )
    ;
    -- <�J�[�\����>���R�[�h�^

    --���C���J�[�\���Ŏ擾�����f�[�^���i�[����e�[�u��
    TYPE arc_carriers_schedule_ttype IS TABLE OF xxwsh_carriers_schedule%ROWTYPE INDEX BY BINARY_INTEGER;
    lt_arc_carrier_schedule_tbl       arc_carriers_schedule_ttype;

    --�o�b�N�A�b�v�e�[�u���ɃZ�b�g����l���i�[����e�[�u��
    TYPE carriers_schedule_ttype IS TABLE OF xxcmn_carriers_schedule_arc%ROWTYPE INDEX BY BINARY_INTEGER;
    lt_carrier_schedule_tbl       carriers_schedule_ttype;                               -- �z�Ԕz���v��(�A�h�I��)�e�[�u��
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_arc_cnt_carrier := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================================
    -- 89�o�b�N�A�b�v���Ԏ擾
    -- ===============================================
    /*
    ln_�o�b�N�A�b�v���� := �o�b�N�A�b�v���Ԏ擾���ʊ֐��icv_�p�[�W��`�R�[�h�j;
     */
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
    FND_FILE.PUT_LINE (FND_FILE.LOG, '�o�b�N�A�b�v����:' || TO_CHAR(ln_archive_period));
--
    -- ===============================================
    -- �h�m�p�����[�^�̊m�F
    -- ===============================================
    /*96
    iv_proc_date��NULL�̏ꍇ
--
      ld_��� := �������擾���ʊ֐�����擾���������� - ln_�o�b�N�A�b�v����;
--
    iv_proc_date��NULL�łȂ��̏ꍇ
--
      ld_��� := TO_DATE(iv_proc_date) - ln_�o�b�N�A�b�v����;
     */
    IF ( iv_proc_date IS NULL ) THEN
--
      ld_standard_date := xxcmn_common4_pkg.get_syori_date - ln_archive_period;
--
    ELSE
--
      ld_standard_date := TO_DATE(iv_proc_date, cv_date_format) - ln_archive_period;
--
    END IF;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '���:' || TO_CHAR(ld_standard_date,'YYYY/MM/DD'));
--
    -- ===============================================
    -- �v���t�@�C���E�I�v�V�����l�擾
    -- ===============================================
    /*107
    ln_�����R�~�b�g�� := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾(XXCMN:�o�b�N�A�b�v�����R�~�b�g��));
    ln_�o�b�N�A�b�v�����W := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾(XXCMN:�o�b�N�A�b�v�����W));
     */
    BEGIN
      ln_commit_range  := TO_NUMBER(fnd_profile.value(cv_xxcmn_commit_range));
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
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_commit_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '�����R�~�b�g��:' || TO_CHAR(ln_commit_range));
--
    BEGIN
      ln_archive_range := TO_NUMBER(fnd_profile.value(cv_xxcmn_archive_range));
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
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_archive_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '�o�b�N�A�b�v�����W:' || TO_CHAR(ln_archive_range));
    FND_FILE.PUT_LINE (FND_FILE.LOG, '�o�b�N�A�b�vFrom:' || TO_CHAR(ld_standard_date-ln_archive_range,'YYYY/MM/DD'));
--
    -- ===============================================
    -- �o�b�N�A�b�v�Ώ۔z�Ԕz���v��i�A�h�I���j�擾
    -- ===============================================
    /*
      OPEN �o�b�N�A�b�v�Ώ۔z�Ԕz���v��i�A�h�I���j�擾�ild_����Cln_�o�b�N�A�b�v�����W);
      FETCH �o�b�N�A�b�v�Ώ۔z�Ԕz���v��i�A�h�I���j�擾 BULK COLLECT INTO lt_�Ώۃf�[�^�t�F�b�`�e�[�u��;
      �t�F�b�`�s�����݂����ꍇ��
      FOR ln_main_idx in 1 .. lt_�Ώۃf�[�^�t�F�b�`�e�[�u��.COUNT  LOOP
    */
    OPEN arc_carriers_schedule_cur(ld_standard_date,ln_archive_range);
    FETCH arc_carriers_schedule_cur BULK COLLECT INTO lt_arc_carrier_schedule_tbl;
--
    IF ( lt_arc_carrier_schedule_tbl.COUNT ) > 0 THEN
      << archive_carriers_schedule_loop >>
      FOR ln_main_idx in 1 .. lt_arc_carrier_schedule_tbl.COUNT
      LOOP
        -- ===============================================
        -- �����R�~�b�g
        -- ===============================================
        /*
          NVL(ln_�����R�~�b�g��, 0) <> 0�̏ꍇ
        */
        IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
  --
          /*
            ln_���R�~�b�g�o�b�N�A�b�v�����i�z�Ԕz���v��i�A�h�I���j�j > 0
            ���� MOD(ln_���R�~�b�g�o�b�N�A�b�v�����i�z�Ԕz���v��i�A�h�I���j�j, ln_�����R�~�b�g��) = 0�̏ꍇ
          */
          IF (  (ln_arc_cnt_carrier_yet > 0)
            AND (MOD(ln_arc_cnt_carrier_yet, ln_commit_range) = 0)
             )
          THEN
  --
            /*
              FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v�����i�z�Ԕz���v��i�A�h�I���j�j
                INSERT INTO �z�Ԕz���v��i�A�h�I���j�o�b�N�A�b�v
                (
                    �S�J����
                  , �o�b�N�A�b�v�o�^��
                  , �o�b�N�A�b�v�v��ID
                )
                VALUES
                (
                    lt_�z�Ԕz���v��i�A�h�I���j�e�[�u���iln_idx�j�S�J����
                  , SYSDATE
                  , �v��ID
                )
              ;
            */
            FORALL ln_idx IN 1..ln_arc_cnt_carrier_yet
              INSERT INTO xxcmn_carriers_schedule_arc VALUES lt_carrier_schedule_tbl(ln_idx);
  --
            /*
              ln_�o�b�N�A�b�v�����i�z�Ԕz���v��i�A�h�I���j�j := ln_�o�b�N�A�b�v�����i�z�Ԕz���v��i�A�h�I���j�j
                                                                          + ln_���R�~�b�g�o�b�N�A�b�v�����i�z�Ԕz���v��i�A�h�I���j�j;
              ln_���R�~�b�g�o�b�N�A�b�v�����i�z�Ԕz���v��i�A�h�I���j�j := 0;
              lt_�z�Ԕz���v��i�A�h�I���j�e�[�u���DDELETE;
            */
            gn_arc_cnt_carrier     := gn_arc_cnt_carrier + ln_arc_cnt_carrier_yet;
            ln_arc_cnt_carrier_yet := 0;
            lt_carrier_schedule_tbl.DELETE;
  --
            COMMIT;
  --
          END IF;
  --
        END IF;
  --
        /*
          ln_�Ώۃg�����U�N�V����ID := lr_header_rec�D�g�����U�N�V����ID;
          ln_���R�~�b�g�o�b�N�A�b�v�����i�z�Ԕz���v��i�A�h�I���j�j := ln_���R�~�b�g�o�b�N�A�b�v�����i�z�Ԕz���v��i�A�h�I���j�j + 1;
  --
          lt_�z�Ԕz���v��i�A�h�I���j�e�[�u���iln_���R�~�b�g�o�b�N�A�b�v�����i�z�Ԕz���v��i�A�h�I���j�j := lt_�Ώۃf�[�^�t�F�b�`�e�[�u��(ln_main_idx);
        */
        ln_arc_cnt_carrier_yet := ln_arc_cnt_carrier_yet + 1;
  --
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).transaction_id              := lt_arc_carrier_schedule_tbl(ln_main_idx).transaction_id;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).transaction_type            := lt_arc_carrier_schedule_tbl(ln_main_idx).transaction_type;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).mixed_type                  := lt_arc_carrier_schedule_tbl(ln_main_idx).mixed_type;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).delivery_no                 := lt_arc_carrier_schedule_tbl(ln_main_idx).delivery_no;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).default_line_number         := lt_arc_carrier_schedule_tbl(ln_main_idx).default_line_number;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).carrier_id                  := lt_arc_carrier_schedule_tbl(ln_main_idx).carrier_id;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).carrier_code                := lt_arc_carrier_schedule_tbl(ln_main_idx).carrier_code;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).deliver_from_id             := lt_arc_carrier_schedule_tbl(ln_main_idx).deliver_from_id;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).deliver_from                := lt_arc_carrier_schedule_tbl(ln_main_idx).deliver_from;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).deliver_to_id               := lt_arc_carrier_schedule_tbl(ln_main_idx).deliver_to_id;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).deliver_to                  := lt_arc_carrier_schedule_tbl(ln_main_idx).deliver_to;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).deliver_to_code_class       := lt_arc_carrier_schedule_tbl(ln_main_idx).deliver_to_code_class;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).delivery_type               := lt_arc_carrier_schedule_tbl(ln_main_idx).delivery_type;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).order_type_id               := lt_arc_carrier_schedule_tbl(ln_main_idx).order_type_id;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).auto_process_type           := lt_arc_carrier_schedule_tbl(ln_main_idx).auto_process_type;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).schedule_ship_date          := lt_arc_carrier_schedule_tbl(ln_main_idx).schedule_ship_date;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).schedule_arrival_date       := lt_arc_carrier_schedule_tbl(ln_main_idx).schedule_arrival_date;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).description                 := lt_arc_carrier_schedule_tbl(ln_main_idx).description;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).payment_freight_flag        := lt_arc_carrier_schedule_tbl(ln_main_idx).payment_freight_flag;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).demand_freight_flag         := lt_arc_carrier_schedule_tbl(ln_main_idx).demand_freight_flag;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).sum_loading_weight          := lt_arc_carrier_schedule_tbl(ln_main_idx).sum_loading_weight;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).sum_loading_capacity        := lt_arc_carrier_schedule_tbl(ln_main_idx).sum_loading_capacity;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).loading_efficiency_weight   := lt_arc_carrier_schedule_tbl(ln_main_idx).loading_efficiency_weight;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).loading_efficiency_capacity := lt_arc_carrier_schedule_tbl(ln_main_idx).loading_efficiency_capacity;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).based_weight                := lt_arc_carrier_schedule_tbl(ln_main_idx).based_weight;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).based_capacity              := lt_arc_carrier_schedule_tbl(ln_main_idx).based_capacity;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).result_freight_carrier_id   := lt_arc_carrier_schedule_tbl(ln_main_idx).result_freight_carrier_id;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).result_freight_carrier_code := lt_arc_carrier_schedule_tbl(ln_main_idx).result_freight_carrier_code;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).result_shipping_method_code := lt_arc_carrier_schedule_tbl(ln_main_idx).result_shipping_method_code;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).shipped_date                := lt_arc_carrier_schedule_tbl(ln_main_idx).shipped_date;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).arrival_date                := lt_arc_carrier_schedule_tbl(ln_main_idx).arrival_date;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).weight_capacity_class       := lt_arc_carrier_schedule_tbl(ln_main_idx).weight_capacity_class;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).freight_charge_type         := lt_arc_carrier_schedule_tbl(ln_main_idx).freight_charge_type;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).slip_number                 := lt_arc_carrier_schedule_tbl(ln_main_idx).slip_number;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).small_quantity              := lt_arc_carrier_schedule_tbl(ln_main_idx).small_quantity;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).label_quantity              := lt_arc_carrier_schedule_tbl(ln_main_idx).label_quantity;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).prod_class                  := lt_arc_carrier_schedule_tbl(ln_main_idx).prod_class;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).non_slip_class              := lt_arc_carrier_schedule_tbl(ln_main_idx).non_slip_class;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).created_by                  := lt_arc_carrier_schedule_tbl(ln_main_idx).created_by;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).creation_date               := lt_arc_carrier_schedule_tbl(ln_main_idx).creation_date;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).last_updated_by             := lt_arc_carrier_schedule_tbl(ln_main_idx).last_updated_by;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).last_update_date            := lt_arc_carrier_schedule_tbl(ln_main_idx).last_update_date;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).last_update_login           := lt_arc_carrier_schedule_tbl(ln_main_idx).last_update_login;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).request_id                  := lt_arc_carrier_schedule_tbl(ln_main_idx).request_id;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).program_application_id      := lt_arc_carrier_schedule_tbl(ln_main_idx).program_application_id;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).program_id                  := lt_arc_carrier_schedule_tbl(ln_main_idx).program_id;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).program_update_date         := lt_arc_carrier_schedule_tbl(ln_main_idx).program_update_date;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).archive_date                := SYSDATE;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).archive_request_id          := cn_request_id;
--
      /*
        END LOOP �o�b�N�A�b�v�Ώ۔z�Ԕz���v��i�A�h�I���j�擾;
      */
      END LOOP archive_carriers_schedule_loop;
    END IF;
--
    /*
      FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v�����i�z�Ԕz���v��i�A�h�I���j�j
        INSERT INTO �z�Ԕz���v��i�A�h�I���j�o�b�N�A�b�v
        (
             �S�J����
          , �o�b�N�A�b�v�o�^��
          , �o�b�N�A�b�v�v��ID
        )
        VALUES
        (
            lt_�z�Ԕz���v��i�A�h�I���j�e�[�u���iln_idx�j�S�J����
          , SYSDATE
          , �v��ID
        )
      ;
    */
    FORALL ln_idx IN 1..ln_arc_cnt_carrier_yet
      INSERT INTO xxcmn_carriers_schedule_arc VALUES lt_carrier_schedule_tbl(ln_idx);
--
    /*
      ln_�o�b�N�A�b�v�����i�z�Ԕz���v��i�A�h�I���j�j := ln_�o�b�N�A�b�v�����i�z�Ԕz���v��i�A�h�I���j�j
                                                                  + ln_���R�~�b�g�o�b�N�A�b�v�����i�z�Ԕz���v��i�A�h�I���j�j;
      ln_���R�~�b�g�o�b�N�A�b�v�����i�z�Ԕz���v��i�A�h�I���j�j := 0;
      lt_�z�Ԕz���v��i�A�h�I���j�e�[�u���DDELETE;
    */
    gn_arc_cnt_carrier     := gn_arc_cnt_carrier + ln_arc_cnt_carrier_yet;
    ln_arc_cnt_carrier_yet := 0;
    lt_carrier_schedule_tbl.DELETE;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    WHEN local_process_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
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
      lt_transaction_id := lt_carrier_schedule_tbl(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).transaction_id;
      IF ( lt_transaction_id IS NOT NULL ) THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_local_others_msg
                      ,iv_token_name1  => cv_token_key
                      ,iv_token_value1 => TO_CHAR(lt_transaction_id)
                     );
      END IF;
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
    cv_prg_name         CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name  CONSTANT VARCHAR2(10)  := 'XXCMN';            -- �A�h�I���F���ʁEIF�̈�
    cv_cnt_msg          CONSTANT VARCHAR2(100) := 'APP-XXCMN-11040';             -- ��TBL_NAME ��SHORI �����F ��CNT ��
    cv_token_cnt        CONSTANT VARCHAR2(100) := 'CNT';                         -- �������b�Z�[�W�p�g�[�N�����i�����j
    cv_token_cnt_table  CONSTANT VARCHAR2(100) := 'TBL_NAME';                    -- �������b�Z�[�W�p�g�[�N�����i�e�[�u�����j
    cv_token_cnt_shori  CONSTANT VARCHAR2(100) := 'SHORI';                       -- �������b�Z�[�W�p�g�[�N�����i�������j
    cv_table_cnt_xcs    CONSTANT VARCHAR2(100) := '�z�Ԕz���v��';                -- �������b�Z�[�W�p�e�[�u����
    cv_shori_cnt_arc    CONSTANT VARCHAR2(100) := '�o�b�N�A�b�v';                -- �������b�Z�[�W�p������
    cv_shori_cnt_normal CONSTANT VARCHAR2(100) := '����';                -- �������b�Z�[�W�p������
    cv_shori_cnt_error  CONSTANT VARCHAR2(100) := '�G���[';                -- �������b�Z�[�W�p������
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
    -- ===============================================
    -- ���O�o�͏���
    -- ===============================================
    --�p�����[�^(�������F PAR)
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
    --�o�b�N�A�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xcs
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_arc
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt_carrier)
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
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xcs
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_normal
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt_carrier)
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
END XXCMN960009C;
/
