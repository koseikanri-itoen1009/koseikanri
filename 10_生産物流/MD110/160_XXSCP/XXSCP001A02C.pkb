create or replace PACKAGE BODY APPS.XXSCP001A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 *
 * Package Name     : XXSCP001A02C(body)
 * Description      : �]���I�[�_�[���W���[���Y�v��FBDI�A�g
 *                    �ړ��\�萔�ʂ�CSV�o�͂���B
 * Version          : 1.0
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
 *  2024/12/13     1.0  SCSK M.Sato      [E_�{�ғ�_20298]�V�K�쐬
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXSCP001A02C'; -- �p�b�P�[�W��
--
  --�v���t�@�C��
  cv_file_name_enter    CONSTANT VARCHAR2(50)  := 'XXSCP1_FILE_NAME_TRANSFER_ORDER';    -- XXSCP:�]���I�[�_�[�t�@�C������
  cv_file_dir_enter     CONSTANT VARCHAR2(100) := 'XXSCP1_FILE_DIR_SUPPLY_PLANNING';    -- XXSCP:���Y�v��t�@�C���i�[�p�X
  cv_scaling_number     CONSTANT VARCHAR2(50)  := 'XXSCP1_SCALING_NUMBER';              -- XXSCP:�X�P�[���l
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date       DATE;             -- �Ɩ����t
  gv_file_name_enter    VARCHAR2(100) ;   -- XXSCP:�]���I�[�_�[�t�@�C������
  gv_file_dir_enter     VARCHAR2(500) ;   -- XXSCP:�]���I�[�_�[�t�@�C���i�[�p�X
  gn_scaling_number     NUMBER  ;         -- XXSCP:�X�P�[���l
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_open_mode_w      CONSTANT VARCHAR2(10) := 'w';     -- �t�@�C���I�[�v�����[�h�i�㏑���j
--
    -- *** ���[�J���ϐ� ***
--
    -- �ϐ��^�̐錾
    ln_transaction_count           NUMBER; 
    ln_transaction_value           NUMBER(10,3);
    ln_transaction_version         NUMBER;
    lv_no_data_flg                 VARCHAR2(1);
    lv_csv_text_h                  VARCHAR2(3000);
    lv_csv_text_l                  VARCHAR2(3000);
    lf_file_hand                   UTL_FILE.FILE_TYPE ;  -- �t�@�C���E�n���h���̐錾
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �i�ڑq�Ƀ}�X�^�o�Ɍ��g�D�擾�p�J�[�\��
    CURSOR warehouse_mst_from_cur
      IS
        SELECT DISTINCT
              xwmf.item_code       item_code     -- �i�ڃR�[�h
             ,xwmf.rep_org_code    rep_org_code  -- ��\�g�DFROM
        FROM  xxscp_warehouse_mst xwmf
        WHERE xwmf.rep_org_code <> 'DUMMY'
        ORDER BY xwmf.item_code     -- �i�ڃR�[�h
                ,xwmf.rep_org_code  -- ��\�g�D
        ;
--
    -- ���R�[�h�^�̐錾
    TYPE warehouse_mst_from_rec IS RECORD (
     item_code    VARCHAR2(7)         -- �i�ڃR�[�h
    ,rep_org_code VARCHAR2(13)        -- ��\�g�D�R�[�h
    );
    warehouse_mst_from_record warehouse_mst_from_rec; 
--
    -- �i�ڑq�Ƀ}�X�^���ɐ�g�D�擾�p�J�[�\��
    CURSOR warehouse_mst_to_cur
      IS
        SELECT DISTINCT
              xwmt.rep_org_code    rep_org_code  -- ��\�g�DTO
        FROM  xxscp_warehouse_mst xwmt
        WHERE xwmt.rep_org_code <> 'DUMMY'
        AND   xwmt.item_code     = warehouse_mst_from_record.item_code
        ORDER BY xwmt.rep_org_code  -- ��\�g�DTO
        ;
--
    -- ���R�[�h�^�̐錾
    TYPE warehouse_mst_to_rec IS RECORD (
     rep_org_code VARCHAR2(13)        -- ��\�g�D�R�[�h
    );
    warehouse_mst_to_record warehouse_mst_to_rec; 
--
    -- CSV�o�͗p�J�[�\��
    CURSOR history_transfer_order_cur
      IS
        SELECT xhto.sr_instance_code        sr_instance_code       -- �\�[�X�E�V�X�e���E�R�[�h(�Œ�l�uKI�v)
              ,xhto.organization_code       organization_code      -- ��\�g�D�R�[�h(TO)
              ,xhto.from_organization_code  from_organization_code -- ��\�g�D�R�[�h(FROM)
              ,xhto.order_type              order_type             -- �Œ�l�u94�v
              ,xhto.new_order_quantity      new_order_quantity     -- �G���A�Ԉړ�����
              ,xhto.to_line_number          to_line_number         -- �i�ڃR�[�h1
              ,xhto.item_name               item_name              -- �i�ڃR�[�h2
              ,xhto.order_number            order_number           -- YYYYMMDD_��\�g�DFROM_��\�g�DTO
              ,xhto.firm_planned_type       firm_planned_type      -- �Œ�l�uYes�v
              ,xhto.need_by_date            need_by_date           -- �ړ����\��
              ,xhto.deleted_flag            deleted_flag           -- �폜�t���O
              ,xhto.end_value               end_value              -- �I�[�L��
        FROM   xxscp_his_transfer_order     xhto
        WHERE  xhto.version = ln_transaction_version
        ORDER BY xhto.to_line_number
                ,xhto.from_organization_code
                ,xhto.organization_code
                ,xhto.need_by_date
        ;
--
    -- ���R�[�h�^�̐錾
    TYPE history_transfer_order_rec IS RECORD (
     sr_instance_code         VARCHAR2(30)     -- �\�[�X�E�V�X�e���E�R�[�h
    ,organization_code        VARCHAR2(13)     -- ��\�g�D�R�[�h(TO)
    ,from_organization_code   VARCHAR2(13)     -- ��\�g�D�R�[�h(FROM)
    ,order_type               NUMBER           -- �Œ�l�u94�v
    ,new_order_quantity       NUMBER(10,3)     -- �G���A�Ԉړ�����
    ,to_line_number           VARCHAR2(20)     -- �i�ڃR�[�h1
    ,item_name                VARCHAR2(250)    -- �i�ڃR�[�h2
    ,order_number             VARCHAR2(240)    -- YYYYMMDD_��\�g�DFROM_��\�g�DTO
    ,firm_planned_type        VARCHAR2(3)      -- �Œ�l�uYes�v
    ,need_by_date             DATE             -- �ړ����\��
    ,deleted_flag             VARCHAR2(30)     -- �폜�t���O
    ,end_value                VARCHAR2(3)      -- �I�[�L��
    );
    history_transfer_order_record history_transfer_order_rec; 
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- ������
    -- ===============================
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --==============================================================
    -- �Ɩ����t�擾
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := '�Ɩ����t�̎擾�Ɏ��s���܂����B';
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF
    ;
--
    --==============================================================
    -- �v���t�@�C���擾
    --==============================================================
    -- XXSCP:���Y�v��t�@�C���i�[�p�X�̎擾
    gv_file_dir_enter := FND_PROFILE.VALUE(cv_file_dir_enter);
    IF (gv_file_dir_enter IS NULL) THEN
      lv_errmsg := 'XXSCP:���Y�v��t�@�C���i�[�p�X�̎擾�Ɏ��s���܂����B';
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- XXSCP:�]���I�[�_�[�t�@�C�����̂̎擾
    gv_file_name_enter      := FND_PROFILE.VALUE(cv_file_name_enter);
    IF (gv_file_name_enter IS NULL) THEN
      lv_errmsg := 'XXSCP:�]���I�[�_�[�t�@�C�����̂̎擾�Ɏ��s���܂����B';
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- XXSCP:�X�P�[���l�̎擾
    gn_scaling_number       := TO_NUMBER(FND_PROFILE.VALUE(cv_scaling_number));
    IF (gn_scaling_number  IS NULL) THEN
      lv_errmsg := 'XXSCP:�X�P�[���l�̎擾�Ɏ��s���܂����B';
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ŐV�o�[�W�����̎擾
    SELECT xxscp_transfer_order_ver_s1.NEXTVAL
    INTO   ln_transaction_version
    FROM   dual
    ;
--
    -- �J�[�\���̃I�[�v��
    OPEN warehouse_mst_from_cur;
    -- �擾�����[�v�@�J�n
    LOOP FETCH warehouse_mst_from_cur INTO warehouse_mst_from_record;
    EXIT WHEN warehouse_mst_from_cur%NOTFOUND;
--
       -- �J�[�\���̃I�[�v��
      OPEN warehouse_mst_to_cur;
      -- �擾�����[�v�A�J�n
      LOOP FETCH warehouse_mst_to_cur INTO warehouse_mst_to_record;
      EXIT WHEN warehouse_mst_to_cur%NOTFOUND;
--
        -- ���G���A�Ԃ̈ړ��̏ꍇ�̓X�L�b�v
        IF (warehouse_mst_from_record.rep_org_code = warehouse_mst_to_record.rep_org_code) THEN
          CONTINUE;
        END IF;
        -- ���t���[�v�J�n
        FOR ln_day_offset IN 0..6 LOOP
--
          -- ������
          lv_no_data_flg := 'N';
--
          BEGIN
          -- �]���I�[�_�[�̃g�����U�N�V�������擾
          SELECT SUM(v1.case_num/v1.CASE_UOM)/gn_scaling_number                      AS CASE_NUM_TOTAL
          INTO   ln_transaction_value
          FROM
              (-- xmrih.status = '03''04''05''06'�����ꂼ��擾������
               -- xmrih.status = '03'�J�n
               SELECT xmril.item_code               AS ITEM_CODE
                     ,xmrih.schedule_arrival_date   AS WAREHOUSING_DATE
                     ,xwm1.rep_org_code             AS REP_ORG_FROM
                     ,xwm2.rep_org_code             AS REP_ORG_TO
                     ,xmril.instruct_qty            AS CASE_NUM
                     ,iimb.attribute11              AS CASE_UOM
               FROM   xxinv_mov_req_instr_headers  xmrih
                     ,xxinv_mov_req_instr_lines    xmril
                     ,ic_item_mst_b                iimb
                     ,xxcmn_item_locations_v       xilv1
                     ,xxcmn_item_locations_v       xilv2
                     ,xxscp_warehouse_mst          xwm1
                     ,xxscp_warehouse_mst          xwm2
               WHERE  xmril.mov_hdr_id                    = xmrih.mov_hdr_id
               AND    xmril.item_code                     = iimb.item_no
               AND    xmrih.shipped_locat_id              = xilv1.inventory_location_id
               AND    xmrih.ship_to_locat_id              = xilv2.inventory_location_id
               AND    xmrih.status                        = '03'                         -- 03������
               AND    xmrih.comp_actual_flg               = 'N'                          -- ���ьv��σt���O
               AND    xmrih.schedule_arrival_date         = gd_process_date + ln_day_offset
               AND    xilv1.description            NOT LIKE '��u%'
               AND    xilv2.description            NOT LIKE '��u%'
               AND    xmrih.shipped_locat_code            = xwm1.whse_code
               AND    xmril.item_code                     = xwm1.item_code
               AND    xmrih.ship_to_locat_code            = xwm2.whse_code
               AND    xmril.item_code                     = xwm2.item_code
               AND    NVL( xmril.delete_flg, 'N' )       <> 'Y'
               -- ���[�v����
               AND    xwm1.item_code                      = warehouse_mst_from_record.item_code
               AND    xwm1.rep_org_code                   = warehouse_mst_from_record.rep_org_code
               AND    xwm2.rep_org_code                   = warehouse_mst_to_record.rep_org_code
               -- xmrih.status = '03'�I��
               UNION ALL
               -- xmrih.status = '04'�J�n
               SELECT xmril.item_code               AS ITEM_CODE
                     ,xmrih.schedule_arrival_date   AS WAREHOUSING_DATE
                     ,xwm1.rep_org_code             AS REP_ORG_FROM
                     ,xwm2.rep_org_code             AS REP_ORG_TO
                     ,XMRIL.shipped_quantity        AS CASE_NUM
                     ,iimb.attribute11              AS CASE_UOM
               FROM   xxinv_mov_req_instr_headers  xmrih
                     ,xxinv_mov_req_instr_lines    xmril
                     ,ic_item_mst_b                iimb
                     ,xxcmn_item_locations_v       xilv1
                     ,xxcmn_item_locations_v       xilv2
                     ,xxscp_warehouse_mst          xwm1
                     ,xxscp_warehouse_mst          xwm2
               WHERE  xmril.mov_hdr_id                   = xmrih.mov_hdr_id
               AND    xmril.item_code                    = iimb.item_no
               AND    xmrih.shipped_locat_id             = xilv1.inventory_location_id
               AND    xmrih.ship_to_locat_id             = xilv2.inventory_location_id
               AND    xmrih.status                       = '04'                              -- 04�o�ɕ񍐍�
               AND    xmrih.comp_actual_flg              = 'N'                               -- ���ьv��σt���O
               AND    xmrih.schedule_arrival_date        = gd_process_date + ln_day_offset   -- ���ɓ��\���������ȍ~
               AND    xilv1.description           NOT LIKE '��u%'
               AND    xilv2.description           NOT LIKE '��u%'
               AND    xmrih.shipped_locat_code           = xwm1.whse_code
               AND    xmril.item_code                    = xwm1.item_code
               AND    xmrih.ship_to_locat_code           = xwm2.whse_code
               AND    xmril.item_code                    = xwm2.item_code
               AND    NVL( xmril.delete_flg, 'N' )      <> 'Y'
               -- ���[�v����
               AND    xwm1.item_code                     = warehouse_mst_from_record.item_code
               AND    xwm1.rep_org_code                  = warehouse_mst_from_record.rep_org_code
               AND    xwm2.rep_org_code                  = warehouse_mst_to_record.rep_org_code
               -- xmrih.status = '04'�I��
               UNION ALL
               -- xmrih.status = '05'�J�n
               SELECT xmril.item_code               AS ITEM_CODE
                     ,xmrih.actual_arrival_date     AS WAREHOUSING_DATE
                     ,xwm1.rep_org_code             AS REP_ORG_FROM
                     ,xwm2.rep_org_code             AS REP_ORG_TO
                     ,XMRIL.ship_to_quantity        AS CASE_NUM
                     ,iimb.attribute11              AS CASE_UOM
               FROM   xxinv_mov_req_instr_headers  xmrih
                     ,xxinv_mov_req_instr_lines    xmril
                     ,ic_item_mst_b                iimb
                     ,xxcmn_item_locations_v       xilv1
                     ,xxcmn_item_locations_v       xilv2
                     ,xxscp_warehouse_mst          xwm1
                     ,xxscp_warehouse_mst          xwm2
               WHERE xmril.mov_hdr_id                    = xmrih.mov_hdr_id
               AND   xmril.item_code                     = iimb.item_no
               AND   xmrih.shipped_locat_id              = xilv1.inventory_location_id
               AND   xmrih.ship_to_locat_id              = xilv2.inventory_location_id
               AND   xmrih.status                        = '05'                              -- 05���ɕ񍐍�
               AND   xmrih.comp_actual_flg               = 'N'                               -- ���ьv��σt���O
               AND   xmrih.actual_arrival_date           = gd_process_date + ln_day_offset   -- ���ɓ��\���������ȍ~
               AND   xilv1.description            NOT LIKE '��u%'
               AND   xilv2.description            NOT LIKE '��u%'
               AND   xmrih.shipped_locat_code            = xwm1.whse_code
               AND   xmril.item_code                     = xwm1.item_code
               AND   xmrih.ship_to_locat_code            = xwm2.whse_code
               AND   xmril.item_code                     = xwm2.item_code
               AND   NVL( xmril.delete_flg, 'N' )       <> 'Y'
               -- ���[�v����
               AND   xwm1.item_code                      = warehouse_mst_from_record.item_code
               AND   xwm1.rep_org_code                   = warehouse_mst_from_record.rep_org_code
               AND   xwm2.rep_org_code                   = warehouse_mst_to_record.rep_org_code
               -- xmrih.status = '05'�I��
               UNION ALL
               -- xmrih.status = '06'�J�n
               SELECT xmril.item_code               AS ITEM_CODE
                     ,xmrih.actual_arrival_date     AS WAREHOUSING_DATE
                     ,xwm1.rep_org_code             AS REP_ORG_FROM
                     ,xwm2.rep_org_code             AS REP_ORG_TO
                     ,XMRIL.ship_to_quantity        AS CASE_NUM
                     ,iimb.attribute11              AS CASE_UOM
               FROM   xxinv_mov_req_instr_headers   xmrih
                     ,xxinv_mov_req_instr_lines     xmril
                     ,ic_item_mst_b                 iimb
                     ,xxcmn_item_locations_v        xilv1
                     ,xxcmn_item_locations_v        xilv2
                     ,xxscp_warehouse_mst           xwm1
                     ,xxscp_warehouse_mst           xwm2
               WHERE  xmril.mov_hdr_id                    = xmrih.mov_hdr_id
               AND    xmril.item_code                     = iimb.item_no
               AND    xmrih.shipped_locat_id              = xilv1.inventory_location_id
               AND    xmrih.ship_to_locat_id              = xilv2.inventory_location_id
               AND    xmrih.status                        = '06'
               AND    xmrih.actual_arrival_date           = gd_process_date + ln_day_offset   -- ���ɓ��\���������ȍ~
               AND    xilv1.description            NOT LIKE '��u%'
               AND    xilv2.description            NOT LIKE '��u%'
               AND    xmrih.shipped_locat_code            = xwm1.whse_code
               AND    xmril.item_code                     = xwm1.item_code
               AND    xmrih.ship_to_locat_code            = xwm2.whse_code
               AND    xmril.item_code                     = xwm2.item_code
               AND    NVL( xmril.delete_flg, 'N' )       <> 'Y'
               -- ���[�v����
               AND    xwm1.item_code                      = warehouse_mst_from_record.item_code
               AND    xwm1.rep_org_code                   = warehouse_mst_from_record.rep_org_code
               AND    xwm2.rep_org_code                   = warehouse_mst_to_record.rep_org_code
                -- xmrih.status = '06'�I��
              )v1
          GROUP BY
                  v1.ITEM_CODE
                 ,v1.REP_ORG_FROM
                 ,v1.REP_ORG_TO
                 ,v1.WAREHOUSING_DATE
               ;
--
          -- �g�������擾�ł��Ȃ������ꍇ
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- �����e�[�u���̌������m�F����
              SELECT COUNT(*)  transaction_count
              INTO   ln_transaction_count
              FROM   xxscp_his_transfer_order xhto
              WHERE  xhto.need_by_date                = gd_process_date + ln_day_offset -- �Ɩ����t+0D~+6D�̓��t���w��
              AND    xhto.to_line_number              = warehouse_mst_from_record.item_code
              AND    xhto.organization_code           = warehouse_mst_to_record.rep_org_code
              AND    xhto.from_organization_code      = warehouse_mst_from_record.rep_org_code
              ;
--
              -- �����e�[�u���Ƀg�����U�N�V���������݂���ꍇ
              IF ln_transaction_count <> 0 THEN
                -- �l��0�ōŐV������
                ln_transaction_value := 0;
              ELSE
                lv_no_data_flg := 'Y';
              END IF;
          -- ��O�����I��
          END;
--
          -- �����e�[�u�����X�V����
          IF lv_no_data_flg = 'N' THEN
            INSERT INTO xxscp_his_transfer_order(
                           his_transfer_order_id            -- �e�[�u��ID
                          ,version                          -- �o�[�W����
                          ,sr_instance_code                 -- �\�[�X�E�V�X�e���E�R�[�h(�Œ�l�uKI�v)
                          ,organization_code                -- ��\�g�D�R�[�h(TO)
                          ,from_organization_code           -- ��\�g�D�R�[�h(FROM)
                          ,order_type                       -- �Œ�l�u94�v
                          ,new_order_quantity               -- �G���A�Ԉړ�����
                          ,to_line_number                   -- �i�ڃR�[�h1
                          ,item_name                        -- �i�ڃR�[�h2
                          ,order_number                     -- YYYYMMDD_��\�g�DFROM_��\�g�DTO
                          ,firm_planned_type                -- �Œ�l�uYes�v
                          ,need_by_date                     -- �ړ����\��
                          ,deleted_flag                     -- �폜�t���O
                          ,end_value                        -- �I�[�L��
                          ,created_by                       -- CREATED_BY
                          ,creation_date                    -- CREATION_DATE
                          ,last_updated_by                  -- LAST_UPDATED_BY
                          ,last_update_date                 -- LAST_UPDATE_DATE
                          ,last_update_login                -- LAST_UPDATE_LOGIN
                          ,request_id                       -- REQUEST_ID
                          ,program_application_id           -- PROGRAM_APPLICATION_ID
                          ,program_id                       -- PROGRAM_ID
                          ,program_update_date              -- PROGRAM_UPDATE_DATE
            )VALUES(
                           xxscp_transfer_order_id_s1.NEXTVAL
                          ,ln_transaction_version
                          ,'KI'
                          ,warehouse_mst_to_record.rep_org_code
                          ,warehouse_mst_from_record.rep_org_code
                          ,94
                          ,ln_transaction_value
                          ,warehouse_mst_from_record.item_code
                          ,warehouse_mst_from_record.item_code
                          ,to_char(gd_process_date + ln_day_offset, 'YYYYMMDD')  ||  '_'  ||  warehouse_mst_from_record.rep_org_code  ||  '_'  ||  warehouse_mst_to_record.rep_org_code
                          ,'Yes'
                          ,gd_process_date + ln_day_offset
                          ,''
                          ,'END'
                          ,cn_created_by
                          ,cd_creation_date
                          ,cn_last_updated_by
                          ,cd_last_update_date
                          ,cn_last_update_login
                          ,cn_request_id
                          ,cn_program_application_id
                          ,cn_program_id
                          ,cd_program_update_date
            );
          END IF;
--
        -- ���t���[�v�I��
        END LOOP;
--
     -- �擾�����[�v�A�I��
     END LOOP;
     CLOSE warehouse_mst_to_cur;
--
    -- �擾�����[�v�@�I��
    END LOOP;
    CLOSE warehouse_mst_from_cur;
--
    -- �R�~�b�g����
    COMMIT;
--
    -- ====================================================
    -- �t�s�k�t�@�C���I�[�v��
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN(gv_file_dir_enter,
                                   gv_file_name_enter,
                                   cv_open_mode_w,
                                   32767
                                  );
--
    -- ===============================
    -- CSV�w�b�_������
    -- ===============================
--
    -- �w�b�_�[���ݒ�
    lv_csv_text_h := 'SR_INSTANCE_CODE,ORGANIZATION_CODE,FROM_ORGANIZATION_CODE,SOURCE_SUBINVENTORY_CODE,SUBINVENTORY_CODE,ORDER_TYPE,NEW_ORDER_QUANTITY,TO_LINE_NUMBER,ITEM_NAME,ORDER_NUMBER,CARRIER_NAME,MODE_OF_TRANSPORT,SERVICE_LEVEL,FIRM_PLANNED_TYPE,NEED_BY_DATE,NEW_SHIP_DATE,NEW_DOCK_DATE,REVISION,SHIP_METHOD,SHIPMENT_HEADER_NUM,SHIPMENT_LINE_NUM ,RECEIPT_NUM,EXPENSE_TRANSFER,NEW_ORDER_PLACEMENT_DATE,UOM_CODE,DELETED_FLAG,ATTRIBUTE_CHAR1,ATTRIBUTE_CHAR2,ATTRIBUTE_CHAR3,ATTRIBUTE_CHAR4,ATTRIBUTE_CHAR5,ATTRIBUTE_CHAR6,ATTRIBUTE_CHAR7,ATTRIBUTE_CHAR8,ATTRIBUTE_CHAR9,ATTRIBUTE_CHAR10,ATTRIBUTE_CHAR11,ATTRIBUTE_CHAR12,ATTRIBUTE_CHAR13,ATTRIBUTE_CHAR14,ATTRIBUTE_CHAR15,ATTRIBUTE_CHAR16,ATTRIBUTE_CHAR17,ATTRIBUTE_CHAR18,ATTRIBUTE_CHAR19,ATTRIBUTE_CHAR20,ATTRIBUTE_NUMBER1,ATTRIBUTE_NUMBER2,ATTRIBUTE_NUMBER3,ATTRIBUTE_NUMBER4,ATTRIBUTE_NUMBER5,ATTRIBUTE_NUMBER6,ATTRIBUTE_NUMBER7,ATTRIBUTE_NUMBER8,ATTRIBUTE_NUMBER9,ATTRIBUTE_NUMBER10,ATTRIBUTE_DATE1,ATTRIBUTE_DATE2,ATTRIBUTE_DATE3,ATTRIBUTE_DATE4,ATTRIBUTE_DATE5,ATTRIBUTE_DATE6,ATTRIBUTE_DATE7,ATTRIBUTE_DATE8,ATTRIBUTE_DATE9,ATTRIBUTE_DATE10,ATTRIBUTE_DATE11,ATTRIBUTE_DATE12,ATTRIBUTE_DATE13,ATTRIBUTE_DATE14,ATTRIBUTE_DATE15,ATTRIBUTE_DATE16,ATTRIBUTE_DATE17,ATTRIBUTE_DATE18,ATTRIBUTE_DATE19,ATTRIBUTE_DATE20,QTY_COMPLETED,GLOBAL_ATTRIBUTE_NUMBER11,GLOBAL_ATTRIBUTE_NUMBER12,GLOBAL_ATTRIBUTE_NUMBER13,GLOBAL_ATTRIBUTE_NUMBER14,GLOBAL_ATTRIBUTE_NUMBER15,GLOBAL_ATTRIBUTE_NUMBER16,GLOBAL_ATTRIBUTE_NUMBER17,GLOBAL_ATTRIBUTE_NUMBER18,GLOBAL_ATTRIBUTE_NUMBER19,GLOBAL_ATTRIBUTE_NUMBER20,GLOBAL_ATTRIBUTE_NUMBER21,GLOBAL_ATTRIBUTE_NUMBER22,GLOBAL_ATTRIBUTE_NUMBER23,GLOBAL_ATTRIBUTE_NUMBER24,GLOBAL_ATTRIBUTE_NUMBER25,FULFILL_ORCHESTRATION_REQUIRED,GLOBAL_ATTRIBUTE_CHAR21,GLOBAL_ATTRIBUTE_CHAR22,GLOBAL_ATTRIBUTE_CHAR23,MATURITY_DATE,END';
--
    -- �w�b�_�[���ݒ胍�O�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_text_h
    );
--
    -- ====================================================
    -- �w�b�_�[��CSV�o��
    -- ====================================================
    UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text_h ) ;
--
    -- ===============================
    -- CSV���ו�����
    -- ===============================
--
    -- �J�[�\���̃I�[�v��
    OPEN history_transfer_order_cur;
--
    -- �f�[�^���o��
    LOOP
      FETCH history_transfer_order_cur INTO history_transfer_order_record;
      EXIT WHEN history_transfer_order_cur%NOTFOUND;
--
      --�����Z�b�g
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ���ו��ݒ�
      lv_csv_text_l :=    history_transfer_order_record.sr_instance_code                              || ','
                       || history_transfer_order_record.organization_code                             || ','
                       || history_transfer_order_record.from_organization_code                        || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || history_transfer_order_record.order_type                                    || ','
                       || RTRIM(TO_CHAR(history_transfer_order_record.new_order_quantity, 'FM9999990.999'), '.')  || ','
                       || history_transfer_order_record.to_line_number                                || ','
                       || history_transfer_order_record.item_name                                     || ','
                       || history_transfer_order_record.order_number                                  || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || history_transfer_order_record.firm_planned_type                             || ','
                       || TO_CHAR(history_transfer_order_record.need_by_date,'YYYY/MM/DD')            || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || history_transfer_order_record.deleted_flag                                  || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || history_transfer_order_record.end_value
                       ;
--
      -- ���ו��ݒ胍�O�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_csv_text_l)
      ;
--
      -- ====================================================
      -- ���ו�CSV�o��
      -- ====================================================
      UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text_l ) ;
--
    END LOOP;
    CLOSE history_transfer_order_cur;
--
    -- ====================================================
    -- �t�s�k�t�@�C���N���[�Y
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand );
--
    -- �����������Ώی���
    gn_normal_cnt  := gn_target_cnt;
--
    -- �Ώی���=0�ł���Όx��
    IF (gn_target_cnt = 0) THEN
      ov_retcode     := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
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
      IF UTL_FILE.IS_OPEN  ( lf_file_hand ) THEN
         UTL_FILE.FCLOSE   ( lf_file_hand );
      END IF;
--
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
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
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
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      gn_error_cnt := 1;
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (lv_retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
    --�X�e�[�^�X�Z�b�g
    ov_retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      lv_retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      lv_retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXSCP001A02C;
/