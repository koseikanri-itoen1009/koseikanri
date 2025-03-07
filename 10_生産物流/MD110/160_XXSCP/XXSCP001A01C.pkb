create or replace PACKAGE BODY APPS.XXSCP001A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 *
 * Package Name     : XXSCP001A01C(body)
 * Description      : �̔��I�[�_�[���W���[���Y�v��FBDI�A�g
 *                    �o�ח\�萔�ʂ�CSV�o�͂���B
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
 *  2024/12/05     1.0  SCSK M.Sato      [E_�{�ғ�_20298]�V�K�쐬
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXSCP001A01C'; -- �p�b�P�[�W��
--
  --�v���t�@�C��
  cv_file_name_enter    CONSTANT VARCHAR2(30) := 'XXSCP1_FILE_NAME_SALES_ORDER';     -- XXSCP:�̔��I�[�_�[�t�@�C������
  cv_file_dir_enter     CONSTANT VARCHAR2(100) := 'XXSCP1_FILE_DIR_SUPPLY_PLANNING';  -- XXSCP:���Y�v��t�@�C���i�[�p�X
  cv_scaling_number     CONSTANT VARCHAR2(50)  := 'XXSCP1_SCALING_NUMBER';            -- XXSCP:�X�P�[���l
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date       DATE;             -- �Ɩ����t
  gv_file_name_enter    VARCHAR2(100) ;   -- XXSCP:�̔��I�[�_�[�t�@�C������
  gv_file_dir_enter     VARCHAR2(500) ;   -- XXSCP:�̔��I�[�_�[�t�@�C���i�[�p�X
  gn_scaling_number     NUMBER  ;         -- XXSCP:�X�P�[���l
--
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
    ln_transaction_value           NUMBER;
    ln_transaction_version         NUMBER;
    lv_no_data_flg                 VARCHAR2(1);
    lv_csv_text_h                  VARCHAR2(3000);
    lv_csv_text_l                  VARCHAR2(3000);
    lf_file_hand                   UTL_FILE.FILE_TYPE ;  -- �t�@�C���E�n���h���̐錾
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �i�ڑq�Ƀ}�X�^�擾�p�J�[�\��
    CURSOR warehouse_mst_cur
      IS
        SELECT DISTINCT
              xwm.item_code       item_code     -- �i�ڃR�[�h
             ,xwm.rep_org_code    rep_org_code  -- ��\�g�D
        FROM  xxscp_warehouse_mst xwm
        WHERE xwm.rep_org_code <> 'DUMMY'
        ORDER BY xwm.item_code     -- �i�ڃR�[�h
                ,xwm.rep_org_code  -- ��\�g�D
        ;
--
    -- ���R�[�h�^�̐錾
    TYPE warehouse_mst_rec IS RECORD (
     item_code    VARCHAR2(7)         -- �i�ڃR�[�h
    ,rep_org_code VARCHAR2(13)        -- ��\�g�D�R�[�h
    );
    warehouse_mst_record warehouse_mst_rec; 
--
    -- CSV�o�͗p�J�[�\��
    CURSOR history_sales_order_cur
      IS
        SELECT xhso1.sr_instance_code            sr_instance_code            -- 
              ,xhso1.item_name                   item_name                   -- 
              ,xhso1.organization_code           organization_code           -- 
              ,xhso1.using_requirement_quantity  using_requirement_quantity  -- 
              ,xhso1.sales_order_number          sales_order_number          -- 
              ,xhso1.so_line_num                 so_line_num                 -- 
              ,xhso1.using_assembly_demand_date  using_assembly_demand_date  -- 
              ,xhso1.customer_name               customer_name               -- 
              ,xhso1.ship_to_site_code           ship_to_site_code           -- 
              ,xhso1.ordered_uom                 ordered_uom                 -- 
              ,xhso1.deleted_flag                deleted_flag                -- 
              ,xhso1.end_value                   end_value                   -- 
        FROM   xxscp_his_sales_order xhso1
        WHERE  xhso1.version = ln_transaction_version
        ORDER BY xhso1.item_name
                ,xhso1.organization_code
                ,xhso1.using_assembly_demand_date
        ;
--
    -- ���R�[�h�^�̐錾
    TYPE history_sales_order_rec IS RECORD (
     sr_instance_code             VARCHAR2(30)     -- �\�[�X�E�V�X�e���E�R�[�h
    ,item_name                    VARCHAR2(250)    -- �i�ڃR�[�h
    ,organization_code            VARCHAR2(13)     -- ��\�g�D�R�[�h
    ,using_requirement_quantity   NUMBER           -- �o�א���
    ,sales_order_number           VARCHAR2(250)    -- YYYYMMDD_��\�g�D
    ,so_line_num                  VARCHAR2(150)    -- �i�ڃR�[�h
    ,using_assembly_demand_date   DATE             -- �o�ד��\��
    ,customer_name                VARCHAR2(255)    -- �Œ�l�uC�v
    ,ship_to_site_code            VARCHAR2(255)    -- �Œ�l�uKI_S�v
    ,ordered_uom                  VARCHAR2(30)     -- �P��(�Œ�l�uCS�v)
    ,deleted_flag                 VARCHAR2(30)     -- �폜�t���O
    ,end_value                    VARCHAR2(3)      -- �I�[�L��
    );
    history_sales_order_record history_sales_order_rec; 
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
    -- XXSCP:�̔��I�[�_�[�t�@�C�����̂̎擾
    gv_file_name_enter      := FND_PROFILE.VALUE(cv_file_name_enter);
    IF (gv_file_name_enter IS NULL) THEN
      lv_errmsg := 'XXSCP:�̔��I�[�_�[�t�@�C�����̂̎擾�Ɏ��s���܂����B';
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
    SELECT xxscp_sales_order_ver_s1.NEXTVAL
    INTO   ln_transaction_version
    FROM   dual
    ;
--
    -- �J�[�\���̃I�[�v��
    OPEN warehouse_mst_cur;
    -- �擾�����[�v�@�J�n
    LOOP FETCH warehouse_mst_cur INTO warehouse_mst_record;
    EXIT WHEN warehouse_mst_cur%NOTFOUND;
--
      -- ���t���[�v�A�J�n
      FOR ln_day_offset IN 0..6 LOOP
--
        -- ������
        lv_no_data_flg := 'N';
--
        BEGIN
        -- �̔��I�[�_�[�̃g�����U�N�V�������擾
          SELECT
                SUM(v1.case_num / v1.uom_case)/gn_scaling_number                 AS case_num_total
          INTO  ln_transaction_value
          FROM (-- xoha.req_status = '04'��'03'�����ꂼ��擾������
                -- xoha.req_status = '04'�J�n
                SELECT xola.shipping_item_code                                   AS item_code
                      ,xwm.rep_org_code                                          AS rep_org_code
                      ,NVL(xola.shipped_quantity, 0)                             AS case_num
                      ,iimb.attribute11                                          AS uom_case
                FROM   xxwsh_order_headers_all   xoha   -- �󒍃w�b�_�A�h�I��
                      ,xxwsh_order_lines_all     xola   -- �󒍖��׃A�h�I��
                      ,oe_transaction_types_all  otta   -- �g�����U�N�V�����^�C�v�擾�p
                      ,ic_item_mst_b             iimb   -- OPM�i�ڃ}�X�^
                      ,xxscp_warehouse_mst       xwm    -- �i�ڑq�Ƀ}�X�^
                WHERE  xoha.order_header_id                                = xola.order_header_id
                AND    xoha.order_type_id                                  = otta.transaction_type_id
                AND    otta.attribute1                                     = '1'                             -- �g�����U�N�V�����^�C�v 1:�o��
                AND    xoha.req_status                                     = '04'                            -- 03:���ߍς�,04:�o�׎��ьv���
                AND    xoha.arrival_date                                   = gd_process_date + ln_day_offset -- �Ɩ����t+0D~+6D�̓��t���w��
                AND    xola.shipping_item_code                             = iimb.item_no
                AND    xoha.deliver_from                                   = xwm.whse_code
                AND    xola.shipping_item_code                             = xwm.item_code
                AND    xoha.latest_external_flag                           = 'Y'
                AND    xola.delete_flag                                    = 'N'                             -- �������׈ȊO
                -- ���[�v����
                AND    xwm.item_code                                       = warehouse_mst_record.item_code
                AND    xwm.rep_org_code                                    = warehouse_mst_record.rep_org_code
                -- xoha.req_status = '04'�I��
                UNION ALL
                -- xoha.req_status = '03'�J�n
                SELECT xola.shipping_item_code                                   AS item_code
                      ,xwm.rep_org_code                                          AS rep_org_code
                      ,NVL(xola.quantity, 0)                                     AS case_num
                      ,iimb.attribute11                                          AS uom_case
                FROM   xxwsh_order_headers_all   xoha   -- �󒍃w�b�_�A�h�I��
                      ,xxwsh_order_lines_all     xola   -- �󒍖��׃A�h�I��
                      ,oe_transaction_types_all  otta   -- �g�����U�N�V�����^�C�v�擾�p
                      ,ic_item_mst_b             iimb   -- OPM�i�ڃ}�X�^
                      ,xxscp_warehouse_mst       xwm    -- �i�ڑq�Ƀ}�X�^
                WHERE  xoha.order_header_id                                = xola.order_header_id
                AND    xoha.order_type_id                                  = otta.transaction_type_id
                AND    otta.attribute1                                     = '1'                             -- �g�����U�N�V�����^�C�v 1:�o��
                AND    xoha.req_status                                     = '03'                            -- 03:���ߍς�,04:�o�׎��ьv���
                AND    xoha.schedule_arrival_date                          = gd_process_date + ln_day_offset -- �Ɩ����t+0D~+6D�̓��t���w��
                AND    xola.shipping_item_code                             = iimb.item_no
                AND    xoha.deliver_from                                   = xwm.whse_code
                AND    xola.shipping_item_code                             = xwm.item_code
                AND    xoha.latest_external_flag                           = 'Y'
                AND    xola.delete_flag                                    = 'N'                             -- �������׈ȊO
                -- ���[�v����
                AND    xwm.item_code                                       = warehouse_mst_record.item_code
                AND    xwm.rep_org_code                                    = warehouse_mst_record.rep_org_code
                -- xoha.req_status = '03'�I��
                )v1
           GROUP BY v1.item_code,
                    v1.rep_org_code
           ;
--
        -- �g�������擾�ł��Ȃ������ꍇ
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- �����e�[�u���̌������m�F����
            SELECT COUNT(*)  transaction_count
            INTO   ln_transaction_count
            FROM   xxscp_his_sales_order xhso
            WHERE  xhso.using_assembly_demand_date  = gd_process_date + ln_day_offset -- �Ɩ����t+0D~+6D�̓��t���w��
            AND    xhso.item_name                   = warehouse_mst_record.item_code
            AND    xhso.organization_code           = warehouse_mst_record.rep_org_code
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
          INSERT INTO xxscp_his_sales_order(
                         his_sales_order_id               -- �e�[�u��ID
                        ,version                          -- �o�[�W����
                        ,sr_instance_code                 -- �\�[�X�E�V�X�e���E�R�[�h(�Œ�l�uKI�v)
                        ,item_name                        -- �i�ڃR�[�h1
                        ,organization_code                -- ��\�g�D
                        ,using_requirement_quantity       -- �o�א���
                        ,sales_order_number               -- YYYYMMDD_��\�g�D
                        ,so_line_num                      -- �i�ڃR�[�h2
                        ,using_assembly_demand_date       -- ���ד�_�\��
                        ,customer_name                    -- �Œ�l�uC�v
                        ,ship_to_site_code                -- �Œ�l�uKI_S�v
                        ,ordered_uom                      -- �P��(�Œ�l�uCS�v)
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
                         xxscp_sales_order_id_s1.NEXTVAL                                                                             -- �e�[�u��ID
                        ,ln_transaction_version                                                                                      -- �o�[�W����
                        ,'KI'                                                                                                        -- �\�[�X�E�V�X�e���E�R�[�h(�Œ�l�uKI�v)
                        ,warehouse_mst_record.item_code                                                                              -- �i�ڃR�[�h1
                        ,warehouse_mst_record.rep_org_code                                                                           -- ��\�g�D
                        ,ln_transaction_value                                                                                        -- �o�א���
                        ,to_char(gd_process_date + ln_day_offset, 'YYYYMMDD')  ||  '_'  ||  warehouse_mst_record.rep_org_code        -- YYYYMMDD_��\�g�D
                        ,warehouse_mst_record.item_code                                                                              -- �i�ڃR�[�h2
                        ,gd_process_date + ln_day_offset                                                                             -- ���ד�_�\��
                        ,'C'                                                                                                         -- �Œ�l�uC�v
                        ,'KI_S'                                                                                                      -- �Œ�l�uKI_S�v
                        ,'CS'                                                                                                        -- �P��(�Œ�l�uCS�v)
                        ,''                                                                                                          -- �폜�t���O
                        ,'END'                                                                                                       -- �I�[�L��
                        ,cn_created_by                                                                                               -- CREATED_BY
                        ,cd_creation_date                                                                                            -- CREATION_DATE
                        ,cn_last_updated_by                                                                                          -- LAST_UPDATED_BY
                        ,cd_last_update_date                                                                                         -- LAST_UPDATE_DATE
                        ,cn_last_update_login                                                                                        -- LAST_UPDATE_LOGIN
                        ,cn_request_id                                                                                               -- REQUEST_ID
                        ,cn_program_application_id                                                                                   -- PROGRAM_APPLICATION_ID
                        ,cn_program_id                                                                                               -- PROGRAM_ID
                        ,cd_program_update_date                                                                                      -- PROGRAM_UPDATE_DATE
          );
        END IF;
--
      -- ���t���[�v�A�I��
      END LOOP;
    -- �擾�����[�v�@�I��
    END LOOP;
    -- �R�~�b�g����
    COMMIT;
--
    CLOSE warehouse_mst_cur;
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
    lv_csv_text_h := 'SR_INSTANCE_CODE,ITEM_NAME,ORIGINAL_ITEM_NAME,ORGANIZATION_CODE,RECEIVING_ORG_CODE,USING_REQUIREMENT_QUANTITY,COMPLETED_QUANTITY,'    ||
                     'SALES_ORDER_NUMBER,SO_LINE_NUM,USING_ASSEMBLY_DEMAND_DATE,SCHEDULE_ARRIVAL_DATE,REQUEST_DATE,PROMISE_SHIP_DATE,PROMISE_ARRIVAL_DATE,' ||
                     'LATEST_ACCEPTABLE_SHIP_DATE,LATEST_ACCEPTABLE_ARRIVAL_DATE,EARLIEST_ACCEPT_SHIP_DATE,EARLIEST_ACCEPT_ARRIVAL_DATE,'                   ||
                     'ORDER_DATE_TYPE_CODE,SHIPPING_METHOD_CODE,CARRIER_NAME,SERVICE_LEVEL,MODE_OF_TRANSPORT,CUSTOMER_NAME,SHIP_TO_SITE_CODE,'              ||
                     'BILL_TO_SITE_CODE,SHIP_SET_NAME,ARRIVAL_SET_NAME,DEMAND_PRIORITY,DEMAND_CLASS,ORDERED_UOM,SUPPLIER_NAME,SUPPLIER_SITE_CODE,'          ||
                     'DEMAND_SOURCE_TYPE,SHIPPING_PREFERENCE,ROOT_FULFILLMENT_LINE,PARENT_FULFILLMENT_LINE,CONFIGURED_ITEM_NAME,INCLUDED_ITEMS_FLAG,'       ||
                     'SELLING_PRICE,SALESREP_CONTACT,CUSTOMER_PO_NUMBER,CUSTOMER_PO_LINE_NUMBER,MIN_REM_SHELF_LIFE_DAYS,ALLOW_SPLITS,ALLOW_SUBSTITUTION,'   ||
                     'FULFILLMENT_COST,SOURCE_SCHEDULE_NUMBER,ORDERED_DATE,ITEM_TYPE_CODE,ITEM_SUB_TYPE_CODE,ORDER_MARGIN,PROMISING_SYSTEM,DELIVERY_COST,'  ||
                     'DELIVERY_LEAD_TIME,MIN_PERCENTAGE_FOR_SPLIT,MIN_QUANTITY_FOR_SPLIT,SUPPLIER_SITE_SOURCE_SYSTEM,DROPSHIP_PO_NUMBER,'                   ||
                     'DROPSHIP_PO_LINE_NUM,DROPSHIP_PO_SCHEDULE_LINE_NUM,PO_DELETED_FLAG,CUSTOMER_PO_SCHEDULE_NUMBER,DELETED_FLAG,ATTRIBUTE_CHAR1,'         ||
                     'ATTRIBUTE_CHAR2,ATTRIBUTE_CHAR3,ATTRIBUTE_CHAR4,ATTRIBUTE_CHAR5,ATTRIBUTE_CHAR6,ATTRIBUTE_CHAR7,ATTRIBUTE_CHAR8,ATTRIBUTE_CHAR9,'     ||
                     'ATTRIBUTE_CHAR10,ATTRIBUTE_CHAR11,ATTRIBUTE_CHAR12,ATTRIBUTE_CHAR13,ATTRIBUTE_CHAR14,ATTRIBUTE_CHAR15,ATTRIBUTE_CHAR16,'              ||
                     'ATTRIBUTE_CHAR17,ATTRIBUTE_CHAR18,ATTRIBUTE_CHAR19,ATTRIBUTE_CHAR20,ATTRIBUTE_NUMBER1,ATTRIBUTE_NUMBER2,ATTRIBUTE_NUMBER3,'           ||
                     'ATTRIBUTE_NUMBER4,ATTRIBUTE_NUMBER5,ATTRIBUTE_NUMBER6,ATTRIBUTE_NUMBER7,ATTRIBUTE_NUMBER8,ATTRIBUTE_NUMBER9,ATTRIBUTE_NUMBER10,'      ||
                     'ATTRIBUTE_DATE1,ATTRIBUTE_DATE2,ATTRIBUTE_DATE3,ATTRIBUTE_DATE4,ATTRIBUTE_DATE5,ATTRIBUTE_DATE6,ATTRIBUTE_DATE7,ATTRIBUTE_DATE8,'     ||
                     'ATTRIBUTE_DATE9,ATTRIBUTE_DATE10,ATTRIBUTE_DATE11,ATTRIBUTE_DATE12,ATTRIBUTE_DATE13,ATTRIBUTE_DATE14,ATTRIBUTE_DATE15,'               ||
                     'ATTRIBUTE_DATE16,ATTRIBUTE_DATE17,ATTRIBUTE_DATE18,ATTRIBUTE_DATE19,ATTRIBUTE_DATE20,INQUIRY_DEMAND,GLOBAL_ATTRIBUTE_NUMBER11,'       ||
                     'GLOBAL_ATTRIBUTE_NUMBER12,GLOBAL_ATTRIBUTE_NUMBER13,GLOBAL_ATTRIBUTE_NUMBER14,GLOBAL_ATTRIBUTE_NUMBER15,GLOBAL_ATTRIBUTE_NUMBER16,'   ||
                     'GLOBAL_ATTRIBUTE_NUMBER17,GLOBAL_ATTRIBUTE_NUMBER18,GLOBAL_ATTRIBUTE_NUMBER19,GLOBAL_ATTRIBUTE_NUMBER20,GLOBAL_ATTRIBUTE_NUMBER21,'   ||
                     'GLOBAL_ATTRIBUTE_NUMBER22,GLOBAL_ATTRIBUTE_NUMBER23,GLOBAL_ATTRIBUTE_NUMBER24,GLOBAL_ATTRIBUTE_NUMBER25,GOP_REFERENCE_ID,'            ||
                     'SOURCE_DOCUMENT_NUMBER,SOURCE_DOCUMENT_LINE_NUMBER,GLOBAL_ATTRIBUTE_CHAR21,GLOBAL_ATTRIBUTE_CHAR22,GLOBAL_ATTRIBUTE_CHAR23,END'
    ;
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
    OPEN history_sales_order_cur;
--
    -- �f�[�^���o��
    LOOP
      FETCH history_sales_order_cur INTO history_sales_order_record;
      EXIT WHEN history_sales_order_cur%NOTFOUND;
--
      --�����Z�b�g
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ���ו��ݒ�
      lv_csv_text_l :=    history_sales_order_record.sr_instance_code                                 || ','
                       || history_sales_order_record.item_name                                        || ','
                       || ''                                                                          || ','
                       || history_sales_order_record.organization_code                                || ','
                       || ''                                                                          || ','
                       || TO_CHAR(history_sales_order_record.using_requirement_quantity)              || ','
                       || ''                                                                          || ','
                       || history_sales_order_record.sales_order_number                               || ','
                       || history_sales_order_record.so_line_num                                      || ','
                       || TO_CHAR(history_sales_order_record.using_assembly_demand_date,'YYYY/MM/DD') || ','
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
                       || history_sales_order_record.customer_name                                    || ','
                       || history_sales_order_record.ship_to_site_code                                || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || history_sales_order_record.ordered_uom                                      || ','
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
                       || history_sales_order_record.deleted_flag                                     || ','
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
                       || ''                                                                          || ','
                       || history_sales_order_record.end_value
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
    CLOSE history_sales_order_cur;
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
END XXSCP001A01C;
/