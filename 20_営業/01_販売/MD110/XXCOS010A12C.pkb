CREATE OR REPLACE PACKAGE BODY XXCOS010A12C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 *
 * Package Name     : XXCOS010A12C(body)
 * Description      : �ŐV��Ԃ̃A�h�I���󒍃}�e�r���[���Q�Ƃ��A�W����OIF���쐬���܂��B
 * MD.050           : PaaS����̎󒍎捞(MD050_COS_010_A12)
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_order_headers      �A�h�I���󒍃w�b�_�f�[�^���o(A-2)
 *  ins_oif_order_header   �󒍃w�b�_OIF�e�[�u���o�^(A-3)
 *  ins_oif_order_process  �󒍏���OIF�e�[�u���o�^(A-4)
 *  ins_upd_order_process  EBS�󒍏������o�^�ƍX�V(A-5)
 *  get_order_lines        �A�h�I���󒍖��׃f�[�^���o(A-6)
 *  ins_oif_order_line     �󒍖���OIF�e�[�u���o�^(A-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2024/06/20    1.0   Y.Ryu            �V�K�쐬
 *  2024/12/16    1.1   A.Igimi          [ST0017]EBS�󒍏������o�^�ƍX�V���@�̏C��
 *  2024/01/15    1.2   A.Igimi          [ST0017]�󒍃C���|�[�g�G���[�Ή�
 *  2025/02/14    1.3   Y.Ooyama         STEP3�V�X�e�������e�X�g�s��Ή�(No.25)
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER       := fnd_global.user_id;           --CREATED_BY
  cd_creation_date          CONSTANT DATE         := SYSDATE;                      --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER       := fnd_global.user_id;           --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE         := SYSDATE;                      --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER       := fnd_global.login_id;          --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER       := fnd_global.conc_request_id;   --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER       := fnd_global.prog_appl_id;      --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER       := fnd_global.conc_program_id;   --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE         := SYSDATE;                      --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)  := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gn_target_cnt             NUMBER;                    -- �Ώی���
  gn_normal_cnt             NUMBER;                    -- ���팏��
  gn_error_cnt              NUMBER;                    -- �G���[����
  gn_warn_cnt               NUMBER;                    -- �x������
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
  cv_pkg_name               CONSTANT VARCHAR2(20)  := 'XXCOS010A12C';                 -- �p�b�P�[�W��
  cv_appl_cos               CONSTANT VARCHAR2(10)  := 'XXCOS';                        -- �A�h�I���F�̕��E�̔�OM�̈�
  cv_appl_ccp               CONSTANT VARCHAR2(10)  := 'XXCCP';                        -- �A�h�I���F���ʁEIF�̈�
  -- ���b�Z�[�W�R�[�h
  cv_msg_00003              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';             -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_msg_00010              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00010';             -- �f�[�^�o�^�G���[
  cv_msg_00011              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00011';             -- �f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_00013              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';             -- �f�[�^���o�G���[���b�Z�[�W
  cv_msg_00069              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00069';             -- �󒍃w�b�_���e�[�u���i�����j
  cv_msg_00070              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00070';             -- �󒍖��׏��e�[�u���i�����j
  cv_msg_00132              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00132';             -- �󒍃w�b�_�[OIF�i�����j
  cv_msg_00133              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00133';             -- �󒍖���OIF�i�����j
  cv_msg_00134              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00134';             -- �󒍏���OIF�i�����j
  cv_msg_16003              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-16003';             -- �󒍃w�b�_�X�L�b�v���b�Z�[�W
  cv_msg_16004              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-16004';             -- �󒍖��׃X�L�b�v���b�Z�[�W
  cv_msg_16005              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-16005';             -- �󒍃w�b�_�G���[���b�Z�[�W
  cv_msg_16006              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-16006';             -- �󒍖��׃G���[���b�Z�[�W
  cv_msg_16007              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-16007';             -- �A�h�I���󒍃w�b�_�}�e���C�Y�h�r���[�i�����j
  cv_msg_16008              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-16008';             -- �A�h�I���󒍖��׃}�e���C�Y�h�r���[�i�����j
  cv_msg_16009              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-16009';             -- EBS�󒍏������i�����j
  cv_msg_16011              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-16011';             -- �󒍃w�b�_�N���[�Y�σ��b�Z�[�W
  cv_msg_16012              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-16012';             -- �󒍖��׃N���[�Y�σ��b�Z�[�W
  cv_msg_16013              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-16013';             -- �󒍖��הԍ��擾�G���[���b�Z�[�W
  --
  cv_msg_90000              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';             -- �Ώی������b�Z�[�W
  cv_msg_90001              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';             -- �����������b�Z�[�W
  cv_msg_90002              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';             -- �G���[�������b�Z�[�W
  cv_msg_90008              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';             -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_normal_msg             CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';             -- ����I�����b�Z�[�W
  cv_warn_msg               CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90005';             -- �x���I�����b�Z�[�W
  cv_error_msg              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90006';             -- �G���[�I���S���[���o�b�N���b�Z�[�W
--
  -- �g�[�N��
  cv_tkn_table_name         CONSTANT VARCHAR2(20)  := 'TABLE_NAME';                   -- �e�[�u����
  cv_tkn_key_data           CONSTANT VARCHAR2(20)  := 'KEY_DATA';                     -- �L�[���
  cv_tkn_count              CONSTANT VARCHAR2(20)  := 'COUNT';                        -- �Ώی���
  cv_tkn_header_id          CONSTANT VARCHAR2(20)  := 'HEADER_ID';                    -- �A�h�I���w�b�_ID
  cv_tkn_header_status      CONSTANT VARCHAR2(20)  := 'HEADER_STATUS';                -- �󒍃X�e�[�^�X�i�w�b�_�j
  cv_tkn_line_id            CONSTANT VARCHAR2(20)  := 'LINE_ID';                      -- �A�h�I������ID
  cv_tkn_line_status        CONSTANT VARCHAR2(20)  := 'LINE_STATUS';                  -- �󒍃X�e�[�^�X�i���ׁj
--
  -- ���̑��萔
  cv_trans_order            CONSTANT VARCHAR2(50)  := 'ORDER';                        -- ����^�C�v�R�[�h
  cv_trans_line             CONSTANT VARCHAR2(50)  := 'LINE';                         -- ����^�C�v�R�[�h(����)
  cv_ctgry_mixed            CONSTANT VARCHAR2(50)  := 'MIXED';                        -- �󒍃J�e�S��
  cv_ctgry_order            CONSTANT VARCHAR2(50)  := 'ORDER';                        -- �󒍃J�e�S��
  cv_op_insert              CONSTANT VARCHAR2(50)  := 'INSERT';                       -- �I�y���[�V�����F�V�K
  cv_op_update              CONSTANT VARCHAR2(50)  := 'UPDATE';                       -- �I�y���[�V�����F�X�V
  cv_sts_booked             CONSTANT VARCHAR2(50)  := 'BOOKED';                       -- �󒍃X�e�[�^�X�F�L����
  cv_sts_cancelled          CONSTANT VARCHAR2(50)  := 'CANCELLED';                    -- �󒍃X�e�[�^�X�F�����
  cv_sts_closed             CONSTANT VARCHAR2(50)  := 'CLOSED';                       -- �󒍃X�e�[�^�X�F�N���[�Y��
  cv_book_order             CONSTANT VARCHAR2(10)  := 'BOOK_ORDER';                   -- �I�y���[�V�����F�L��
--
  cn_zero                   CONSTANT NUMBER        :=  0;                             -- ���o�Ώۃf�[�^0��
  cv_flg_y                  CONSTANT VARCHAR2(1)   := 'Y';                            -- 'Y'
  cv_flg_n                  CONSTANT VARCHAR2(1)   := 'N';                            -- 'N'
  cv_flg_1                  CONSTANT VARCHAR2(1)   := '1';                            -- 1�F�o�^
  cv_flg_2                  CONSTANT VARCHAR2(1)   := '2';                            -- 2�F�X�V
-- Ver1.3 Add Start
  cv_flg_3                  CONSTANT VARCHAR2(1)   := '3';                            -- 3�F�w�b�_���
-- Ver1.3 Add End
  cv_stand_date             CONSTANT VARCHAR(25)   := 'YYYY/MM/DD HH24:MI:SS';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  gn_l_target_cnt           NUMBER;                             -- �Ώی����i���חp�j
  gn_line_number            NUMBER;                             -- �󒍖��הԍ��ϐ�
  --
  gv_skip_flg               VARCHAR2(1);                        -- �󒍃X�L�b�v�t���O
--
  -- �A�h�I���󒍃w�b�_
  CURSOR order_headers_cur
  IS
    SELECT
           xoohm.header_id                header_id                 -- �A�h�I���w�b�_ID
          ,xoohm.order_number             order_number              -- �A�h�I���󒍔ԍ�
          ,xoohm.org_id                   org_id                    -- �g�DID
          ,xoohm.order_source_id          order_source_id           -- �󒍃\�[�XID
          ,xoohm.order_type_id            order_type_id             -- �󒍃^�C�vID
          ,xoohm.ordered_date             ordered_date              -- �󒍓�
          ,xoohm.cust_number              customer_number           -- �ڋq�R�[�h
          ,xoohm.cust_po_number           customer_po_number        -- �ڋq�����ԍ�
          ,xoohm.request_date             request_date              -- �[�i�\���
          ,xoohm.price_list_id            price_list_id             -- ���i�\ID
          ,xoohm.flow_status_code         flow_status_code          -- �󒍃X�e�[�^�X
          ,xoohm.salesrep_id              salesrep_id               -- �c�ƒS��ID
          ,xoohm.sold_to_org_id           sold_to_org_id            -- �����ڋqID
          ,xoohm.shipping_instructions    shipping_instructions     -- �o�׎w��
          ,xoohm.payment_term_id          payment_term_id           -- �x������ID
          ,xoohm.context                  context                   -- �R���e�L�X�g
          ,xoohm.attribute5               attribute5                -- �`�[�敪
          ,xoohm.attribute12              attribute12               -- �����p���_
          ,xoohm.attribute13              attribute13               -- ���Ԏw��(From)
          ,xoohm.attribute14              attribute14               -- ���Ԏw��(To)
          ,xoohm.attribute15              attribute15               -- �`�[No
          ,xoohm.attribute16              attribute16               -- �}��
          ,xoohm.attribute17              attribute17               -- ������(�ɓ���)����ϋ��
          ,xoohm.attribute18              attribute18               -- ������(����@)����ϋ��
          ,xoohm.attribute19              attribute19               -- �I�[�_�[No
          ,xoohm.attribute20              attribute20               -- ���ދ敪
          ,xoohm.global_attribute1        global_attribute1         -- ���ʒ��[�l���p�[�i�����s�t���O�G���A
          ,xoohm.global_attribute3        global_attribute3         -- ���敪
          ,xoohm.global_attribute4        global_attribute4         -- ��No.(HHT)
          ,xoohm.global_attribute5        global_attribute5         -- �������敪
          ,xoohm.orig_sys_document_ref    orig_sys_document_ref     -- �󒍊֘A�ԍ�(EDI)
          ,xoohm.return_reason_code       return_reason_code        -- ������R�R�[�h
          ,CASE WHEN
                  (SELECT COUNT(1)
                   FROM   oe_order_headers_all  ooha  -- �󒍃w�b�_
                   WHERE  ooha.order_source_id       = xoohm.order_source_id
                   AND    ooha.orig_sys_document_ref = xoohm.orig_sys_document_ref
                  ) > 0
                THEN cv_op_update
                ELSE cv_op_insert
           END                            operation_code            -- �I�y���[�V����
          ,CASE WHEN xoohm.flow_status_code = cv_sts_cancelled
                THEN cv_flg_y ELSE NULL
                END                       cancelled_flag            -- ����t���O
    FROM   xxcos_oe_order_headers_mv xoohm        -- �A�h�I���󒍃w�b�_�}�e���C�Y�h�r���[
    WHERE  xoohm.booked_date IS NOT NULL
    ORDER BY
      xoohm.header_id;
--
  -- �A�h�I���󒍃w�b�_ �e�[�u���^�C�v��`
  TYPE  g_tab_order_headers             IS TABLE OF order_headers_cur%ROWTYPE
    INDEX BY PLS_INTEGER;
--
  -- �A�h�I���󒍃w�b�_�e�[�u���p�ϐ��i�J�[�\�����R�[�h�^�j
  gt_order_headers                      g_tab_order_headers;
--
  -- �A�h�I���󒍖���
  CURSOR order_lines_cur(
    it_header_id IN xxcos_oe_order_lines_mv.header_id%TYPE
  )
  IS
    SELECT
           xoolm.line_id                  line_id                   -- �A�h�I������ID
          ,xoolm.header_id                header_id                 -- �A�h�I���w�b�_ID
          ,xoolm.org_id                   org_id                    -- �g�DID
          ,xoolm.line_type_id             line_type_id              -- ���׃^�C�vID
          ,xoolm.line_number              line_number               -- ���הԍ�
          ,xoolm.order_source_id          order_source_id           -- �󒍃\�[�XID
          ,xoolm.ordered_item             inventory_item            -- �i�ڃR�[�h
          ,xoolm.request_date             request_date              -- �[�i�\���
          ,CASE WHEN xoolm.flow_status_code = cv_sts_cancelled
                THEN cn_zero ELSE xoolm.ordered_quantity
                END                       ordered_quantity          -- ����
          ,xoolm.order_quantity_uom       order_quantity_uom        -- �P��
          ,xoolm.price_list_id            price_list_id             -- ���i�\ID
          ,xoolm.payment_term_id          payment_term_id           -- �x������ID
          ,xoolm.orig_sys_document_ref    orig_sys_document_ref     -- �󒍊֘A�ԍ�(EDI)
          ,xoolm.orig_sys_line_ref        orig_sys_line_ref         -- �󒍊֘A���הԍ�(EDI)
          ,xoolm.unit_list_price          unit_list_price           -- �P��
          ,xoolm.unit_selling_price       unit_selling_price        -- �̔��P��
          ,xoolm.flow_status_code         flow_status_code          -- �󒍃X�e�[�^�X
          ,xoolm.subinventory             subinventory              -- �ۊǏꏊ
          ,xoolm.packing_instructions     packing_instructions      -- �o�׈˗��ԍ�
          ,xoolm.return_reason_code       return_reason_code        -- ������R�R�[�h
          ,xoolm.cust_po_number           customer_po_number        -- �ڋq�����ԍ�
          ,xoolm.customer_line_number     customer_line_number      -- �ڋq���הԍ�
          ,xoolm.calculate_price_flag     calculate_price_flag      -- ���i�v�Z�t���O
          ,xoolm.schedule_ship_date       schedule_ship_date        -- �\��o�ד�
          ,xoolm.salesrep_id              salesrep_id               -- �c�ƒS��ID
          ,xoolm.inventory_item_id        inventory_item_id         -- �i��ID
          ,xoolm.sold_to_org_id           sold_to_org_id            -- �����ڋqID
          ,xoolm.ship_from_org_id         ship_from_org_id          -- �o�׌��݌ɑg�DID
          ,xoolm.cancelled_quantity       cancelled_quantity        -- �������
          ,xoolm.context                  context                   -- �R���e�L�X�g
          ,xoolm.attribute4               attribute4                -- ������
          ,xoolm.attribute5               attribute5                -- ����敪
          ,xoolm.attribute6               attribute6                -- �q�R�[�h
          ,xoolm.attribute7               attribute7                -- ���l
          ,xoolm.attribute8               attribute8                -- ����_���Ԏw��(From)
          ,xoolm.attribute9               attribute9                -- ����_���Ԏw��(To)
          ,xoolm.attribute10              attribute10               -- ���P��
          ,xoolm.attribute11              attribute11               -- �|%
          ,xoolm.attribute12              attribute12               -- ����󔭍s�ԍ�
          ,xoolm.global_attribute1        global_attribute1         -- �󒍈ꗗ�o�͓�
          ,xoolm.global_attribute2        global_attribute2         -- �[�i�����s�t���O�G���A
          ,xoolm.global_attribute3        global_attribute3         -- �󒍖���ID(�����O)
          ,xoolm.global_attribute4        global_attribute4         -- �󒍖��׎Q��
          ,xoolm.global_attribute5        global_attribute5         -- �̔����јA�g�t���O
          ,xoolm.global_attribute6        global_attribute6         -- �󒍈ꗗ�t�@�C���o�͓�
          ,xoolm.global_attribute7        global_attribute7         -- HHT�󒍑��M�t���O
          ,xoolm.global_attribute9        global_attribute9         -- ���הԍ�(�����O)
          ,TO_CHAR(
             xoolm.last_update_date, cv_stand_date
           )                              global_attribute10        -- PaaS���׍ŏI�X�V��(UTC)
          ,CASE WHEN
                  (SELECT COUNT(1)
                   FROM   oe_order_lines_all    oola  -- �󒍖���
                   WHERE  oola.order_source_id       = xoolm.order_source_id
                   AND    oola.orig_sys_document_ref = xoolm.orig_sys_document_ref
                   AND    oola.global_attribute8     = xoolm.line_number
                  ) > 0
                THEN cv_op_update
                ELSE cv_op_insert
           END                            operation_code            -- �I�y���[�V����
    FROM   xxcos_oe_order_lines_mv xoolm          -- �A�h�I���󒍖��׃}�e���C�Y�h�r���[
    WHERE  xoolm.header_id = it_header_id
    ORDER BY
      xoolm.line_number;
--
  -- �A�h�I���󒍖��� �e�[�u���^�C�v��`
  TYPE  g_tab_order_lines               IS TABLE OF order_lines_cur%ROWTYPE
    INDEX BY PLS_INTEGER;
--
  -- �A�h�I���󒍖��׏��e�[�u���p�ϐ��i�J�[�\�����R�[�h�^�j
  gt_order_lines                        g_tab_order_lines;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'init';           -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf               VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_function_id          VARCHAR2(30);               -- �@�\ID
    ld_pre_process_date     DATE;                       -- �O�񏈗�����
    ld_pre_process_date_utc DATE;                       -- �O�񏈗�����(UTC)
    lv_date1                VARCHAR2(30);
    lv_date2                VARCHAR2(30);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==============================================================
    -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W�o��
    -- ==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appl_ccp
                    , iv_name        => cv_msg_90008
                  );
    -- ���b�Z�[�W�o��
    fnd_file.put_line(
        which  => fnd_file.output
      , buff   => gv_out_msg
    );
    -- ���O�o��
    fnd_file.put_line(
         which  => fnd_file.log
        ,buff   => gv_out_msg
    );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_order_headers
   * Description      : �A�h�I���󒍃w�b�_�f�[�^���o(A-2)
   ***********************************************************************************/
  PROCEDURE get_order_headers(
    on_target_cnt OUT NOCOPY NUMBER,       --   �Ώۃf�[�^����
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'get_order_headers'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf               VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_idx                  NUMBER;
    -- *** ���[�J���E���R�[�h ***
    l_headers_rec  order_headers_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- OUT�p�����[�^������
    on_target_cnt := 0;
    --
    ln_idx        := 0;
--
    BEGIN
      -- �J�[�\���I�[�v��
      OPEN order_headers_cur;
--
      <<headers_loop>>
      LOOP
--
        FETCH order_headers_cur INTO l_headers_rec;
        EXIT WHEN order_headers_cur%NOTFOUND;
--
        -- �J�E���g�A�b�v
        ln_idx := ln_idx + 1;
        ------------------------------------
        -- �A�h�I���󒍃w�b�_�f�[�^�z��ݒ�
        ------------------------------------
        gt_order_headers(ln_idx).header_id                := l_headers_rec.header_id;                 -- �w�b�_ID
        gt_order_headers(ln_idx).order_number             := l_headers_rec.order_number;              -- �A�h�I���󒍔ԍ�
        gt_order_headers(ln_idx).org_id                   := l_headers_rec.org_id;                    -- �g�DID
        gt_order_headers(ln_idx).order_source_id          := l_headers_rec.order_source_id;           -- �󒍃\�[�XID
        gt_order_headers(ln_idx).order_type_id            := l_headers_rec.order_type_id;             -- �󒍃^�C�vID
        gt_order_headers(ln_idx).ordered_date             := l_headers_rec.ordered_date;              -- �󒍓�
        gt_order_headers(ln_idx).customer_number          := l_headers_rec.customer_number;           -- �ڋq�R�[�h
        gt_order_headers(ln_idx).customer_po_number       := l_headers_rec.customer_po_number;        -- �ڋq�����ԍ�
        gt_order_headers(ln_idx).request_date             := l_headers_rec.request_date;              -- �[�i�\���
        gt_order_headers(ln_idx).price_list_id            := l_headers_rec.price_list_id;             -- ���i�\ID
        gt_order_headers(ln_idx).flow_status_code         := l_headers_rec.flow_status_code;          -- �󒍃X�e�[�^�X
        gt_order_headers(ln_idx).salesrep_id              := l_headers_rec.salesrep_id;               -- �c�ƒS��ID
        gt_order_headers(ln_idx).sold_to_org_id           := l_headers_rec.sold_to_org_id;            -- �����ڋqID
        gt_order_headers(ln_idx).shipping_instructions    := l_headers_rec.shipping_instructions;     -- �o�׎w��
        gt_order_headers(ln_idx).payment_term_id          := l_headers_rec.payment_term_id;           -- �x������ID
        gt_order_headers(ln_idx).context                  := l_headers_rec.context;                   -- �R���e�L�X�g
        gt_order_headers(ln_idx).attribute5               := l_headers_rec.attribute5;                -- �`�[�敪
        gt_order_headers(ln_idx).attribute12              := l_headers_rec.attribute12;               -- �����p���_
        gt_order_headers(ln_idx).attribute13              := l_headers_rec.attribute13;               -- ���Ԏw��(From)
        gt_order_headers(ln_idx).attribute14              := l_headers_rec.attribute14;               -- ���Ԏw��(To)
        gt_order_headers(ln_idx).attribute15              := l_headers_rec.attribute15;               -- �`�[No
        gt_order_headers(ln_idx).attribute16              := l_headers_rec.attribute16;               -- �}��
        gt_order_headers(ln_idx).attribute17              := l_headers_rec.attribute17;               -- ������(�ɓ���)����ϋ��
        gt_order_headers(ln_idx).attribute18              := l_headers_rec.attribute18;               -- ������(����@)����ϋ��
        gt_order_headers(ln_idx).attribute19              := l_headers_rec.attribute19;               -- �I�[�_�[No
        gt_order_headers(ln_idx).attribute20              := l_headers_rec.attribute20;               -- ���ދ敪
        gt_order_headers(ln_idx).global_attribute1        := l_headers_rec.global_attribute1;         -- ���ʒ��[�l���p�[�i�����s�t���O�G���A
        gt_order_headers(ln_idx).global_attribute3        := l_headers_rec.global_attribute3;         -- ���敪
        gt_order_headers(ln_idx).global_attribute4        := l_headers_rec.global_attribute4;         -- ��No.(HHT)
        gt_order_headers(ln_idx).global_attribute5        := l_headers_rec.global_attribute5;         -- �������敪
        gt_order_headers(ln_idx).orig_sys_document_ref    := l_headers_rec.orig_sys_document_ref;     -- �󒍊֘A�ԍ�(EDI)
        gt_order_headers(ln_idx).return_reason_code       := l_headers_rec.return_reason_code;        -- ������R�R�[�h
        gt_order_headers(ln_idx).operation_code           := l_headers_rec.operation_code;            -- �I�y���[�V����
        gt_order_headers(ln_idx).cancelled_flag           := l_headers_rec.cancelled_flag;            -- ����t���O
--
      END LOOP headers_loop;
--
      -- �J�[�\���N���[�Y
      CLOSE order_headers_cur;
--
    EXCEPTION
      -- �f�[�^���o�G���[
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_cos
                       , iv_name         => cv_msg_00013
                       , iv_token_name1  => cv_tkn_table_name
                       , iv_token_value1 => cv_msg_16007
                       , iv_token_name2  => cv_tkn_key_data
                       , iv_token_value2 => cv_msg_part||SQLERRM
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- OUT�p�����[�^�ݒ�
    on_target_cnt := ln_idx;
--
    -- �Ώۃf�[�^�Ȃ��̏ꍇ
    IF ( on_target_cnt = cn_zero )
    THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_cos
                     , iv_name         => cv_msg_00003
                    );
      lv_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg, 1, 5000);
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
        which  => fnd_file.output,
        buff   => lv_errmsg
      );
      -- ���O�o��
      fnd_file.put_line(
        which  => fnd_file.log,
        buff   => lv_errbuf
      );
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( order_headers_cur%ISOPEN ) THEN
        CLOSE order_headers_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( order_headers_cur%ISOPEN ) THEN
        CLOSE order_headers_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( order_headers_cur%ISOPEN ) THEN
        CLOSE order_headers_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_order_headers;
--
  /**********************************************************************************
   * Procedure Name   : ins_oif_order_header
   * Description      : �󒍃w�b�_OIF�e�[�u���o�^(A-3)
   ***********************************************************************************/
  PROCEDURE ins_oif_order_header(
     in_h_idx      IN  NUMBER       --   �󒍃w�b�_�f�[�^�C���f�N�X
    ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_oif_order_header'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lt_flow_status_code  oe_order_headers_all.flow_status_code%TYPE; -- �X�e�[�^�X�i�󒍃w�b�_�j
    lt_line_number_max   oe_order_lines_all.line_number%TYPE;        -- ���הԍ��}�b�N�X
-- ************** Ver1.2 A.Igimi ADD START *************** --
    ln_headers_iface_count  NUMBER;  -- �󒍃w�b�_OIF���݃`�F�b�N
    ln_lines_iface_count    NUMBER;  -- �󒍖���OIF���݃`�F�b�N
    ln_actions_iface_count  NUMBER;  -- �󒍏���OIF���݃`�F�b�N
-- ************** Ver1.2 A.Igimi ADD  END  *************** --
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �󒍃X�e�[�^�X���uBOOKED�F�L���ρv�A�uCANCELLED�F����ρv�ȊO�̏ꍇ
    IF ( gt_order_headers(in_h_idx).flow_status_code <> cv_sts_booked )
      AND ( gt_order_headers(in_h_idx).flow_status_code <> cv_sts_cancelled )
    THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_cos
                     , iv_name         => cv_msg_16005
                     , iv_token_name1  => cv_tkn_header_id        -- �A�h�I���w�b�_ID
                     , iv_token_value1 => gt_order_headers(in_h_idx).header_id
                     , iv_token_name2  => cv_tkn_header_status    -- �󒍃X�e�[�^�X
                     , iv_token_value2 => gt_order_headers(in_h_idx).flow_status_code
                    );
      lv_errbuf  := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ����ώ󒍃f�[�^�̐V�K�o�^�X�L�b�v
    IF ( gt_order_headers(in_h_idx).operation_code = cv_op_insert )
      AND ( gt_order_headers(in_h_idx).flow_status_code = cv_sts_cancelled )
    THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_cos
                     , iv_name         => cv_msg_16003
                     , iv_token_name1  => cv_tkn_header_id        -- �A�h�I���w�b�_ID
                     , iv_token_value1 => gt_order_headers(in_h_idx).header_id
                    );
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
          which  => fnd_file.output
        , buff   => lv_errmsg
      );
      -- ���O�o��
      fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => lv_errmsg
      );
      -- �󒍃X�L�b�v�t���O��ݒ�
      gv_skip_flg := cv_flg_y;
-- Ver1.3 Del Start
--      gn_warn_cnt := gn_warn_cnt + 1;
-- Ver1.3 Del End
      RETURN;
    END IF;
--
    -- �N���[�Y�ώ󒍃f�[�^�̍X�V�X�L�b�v
    IF ( gt_order_headers(in_h_idx).operation_code = cv_op_update )
    THEN
      -- �󒍃w�b�_�̃X�e�[�^�X�擾
      BEGIN
--
        SELECT
               ooha.flow_status_code               flow_status_code     -- �X�e�[�^�X
              ,(SELECT MAX(line_number)
                FROM   oe_order_lines_all
                WHERE  header_id = ooha.header_id) line_number_max      -- ���הԍ��}�b�N�X
        INTO   lt_flow_status_code
              ,lt_line_number_max
        FROM   oe_order_headers_all    ooha         -- �󒍃w�b�_�e�[�u��
        WHERE  ooha.order_source_id       = gt_order_headers(in_h_idx).order_source_id
        AND    ooha.orig_sys_document_ref = gt_order_headers(in_h_idx).orig_sys_document_ref;
--
      EXCEPTION
        -- ���݂��Ȃ��ꍇ
        WHEN NO_DATA_FOUND THEN
          lt_flow_status_code  := NULL;
--
      END;
      -- �X�e�[�^�X�ϐ���NULL�ȊO���X�e�[�^�X�ϐ����uCLOSED�F�N���[�Y�ρv�̏ꍇ
      IF ( lt_flow_status_code IS NOT NULL )
        AND ( lt_flow_status_code = cv_sts_closed )
      THEN
          lv_errmsg    := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_cos
                         , iv_name         => cv_msg_16011
                         , iv_token_name1  => cv_tkn_header_id        -- �A�h�I���w�b�_ID
                         , iv_token_value1 => gt_order_headers(in_h_idx).header_id
                        );
        -- ���b�Z�[�W�o��
        fnd_file.put_line(
            which  => fnd_file.output
          , buff   => lv_errmsg
        );
        -- ���O�o��
        fnd_file.put_line(
             which  => fnd_file.log
            ,buff   => lv_errmsg
        );
        -- �󒍃X�L�b�v�t���O��ݒ�
        gv_skip_flg := cv_flg_y;
        gn_warn_cnt := gn_warn_cnt + 1;
        RETURN;
      END IF;
    END IF;
--
    -- �󒍖��הԍ��ϐ��̏�����
    IF ( gt_order_headers(in_h_idx).operation_code = cv_op_update )
    THEN
      gn_line_number := lt_line_number_max;
    ELSE
      gn_line_number := cn_zero;
    END IF;
--
-- ************** Ver1.2 A.Igimi ADD START *************** --
    ------------------------------------
    -- �󒍃w�b�_OIF �d�����R�[�h�폜
    ------------------------------------
    -- �󒍃w�b�_OIF ���݃`�F�b�N
    BEGIN
      SELECT count(*)
      INTO   ln_headers_iface_count
      FROM   oe_headers_iface_all
      WHERE  orig_sys_document_ref = gt_order_headers(in_h_idx).orig_sys_document_ref;     -- �O���V�X�e���󒍔ԍ�
--
    -- �󒍃w�b�_OIF �d�����R�[�h�폜
      IF ln_headers_iface_count = cn_zero THEN
        NULL;
      ELSE 
        DELETE FROM oe_headers_iface_all
        WHERE  orig_sys_document_ref = gt_order_headers(in_h_idx).orig_sys_document_ref;     -- �O���V�X�e���󒍔ԍ�
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SQLERRM;
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    ------------------------------------
    -- �󒍖���OIF �d�����R�[�h�폜
    ------------------------------------
    -- �󒍖���OIF ���݃`�F�b�N
    BEGIN
      SELECT count(*)
      INTO   ln_lines_iface_count
      FROM   oe_lines_iface_all
      WHERE  orig_sys_document_ref = gt_order_headers(in_h_idx).orig_sys_document_ref;     -- �O���V�X�e���󒍔ԍ�
--
    -- �󒍖���OIF �d�����R�[�h�폜
      IF ln_lines_iface_count = cn_zero THEN
        NULL;
      ELSE 
        DELETE FROM oe_lines_iface_all
        WHERE  orig_sys_document_ref = gt_order_headers(in_h_idx).orig_sys_document_ref;     -- �O���V�X�e���󒍔ԍ�
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SQLERRM;
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    ------------------------------------
    -- �󒍏���OIF �d�����R�[�h�폜
    ------------------------------------
    -- �󒍏���OIF ���݃`�F�b�N
    BEGIN
      SELECT count(*)
      INTO   ln_actions_iface_count
      FROM   oe_actions_iface_all
      WHERE  orig_sys_document_ref = gt_order_headers(in_h_idx).orig_sys_document_ref;     -- �O���V�X�e���󒍔ԍ�
--
    -- �󒍏���OIF �d�����R�[�h�폜
      IF ln_actions_iface_count = cn_zero THEN
        NULL;
      ELSE 
        DELETE FROM oe_actions_iface_all
        WHERE  orig_sys_document_ref = gt_order_headers(in_h_idx).orig_sys_document_ref;     -- �O���V�X�e���󒍔ԍ�
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SQLERRM;
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
-- ************** Ver1.2 A.Igimi ADD  END  *************** --
--
    BEGIN
--
      -- �󒍃w�b�_OIF�e�[�u���o�^
      INSERT INTO oe_headers_iface_all(
        org_id                    -- �g�DID
       ,order_source_id           -- �󒍃\�[�XID
       ,order_type_id             -- �󒍃^�C�vID
       ,ordered_date              -- �󒍓�
       ,customer_number           -- �ڋq�R�[�h
       ,customer_po_number        -- �ڋq�����ԍ�
       ,request_date              -- �[�i�\���
       ,price_list_id             -- ���i�\ID
       ,salesrep_id               -- �c�ƒS��ID
       ,sold_to_org_id            -- �����ڋqID
       ,shipping_instructions     -- �o�׎w��
       ,payment_term_id           -- �x������ID
       ,context                   -- �R���e�L�X�g
       ,attribute5                -- �`�[�敪
       ,attribute12               -- �����p���_
       ,attribute13               -- ���Ԏw��(From)
       ,attribute14               -- ���Ԏw��(To)
       ,attribute15               -- �`�[No
       ,attribute16               -- �}��
       ,attribute17               -- ������(�ɓ���)����ϋ��
       ,attribute18               -- ������(����@)����ϋ��
       ,attribute19               -- �I�[�_�[No
       ,attribute20               -- ���ދ敪
       ,global_attribute1         -- ���ʒ��[�l���p�[�i�����s�t���O�G���A
       ,global_attribute3         -- ���敪
       ,global_attribute4         -- ��No.(HHT)
       ,global_attribute5         -- �������敪
       ,orig_sys_document_ref     -- �O���V�X�e���󒍔ԍ�
       ,change_reason             -- �ύX���R
       ,global_attribute6         -- PaaS���󒍔ԍ�
       ,operation_code            -- �I�y���[�V����
       ,cancelled_flag            -- ����t���O
       ,created_by                -- �쐬��
       ,creation_date             -- �쐬��
       ,last_updated_by           -- �ŏI�X�V��
       ,last_update_date          -- �ŏI�X�V��
       ,last_update_login         -- �ŏI�X�V���O�C��
       ,request_id                -- �v��ID
       ,program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,program_id                -- �R���J�����g�E�v���O����ID
       ,program_update_date       -- �v���O�����X�V��
      )
      VALUES
      (
        gt_order_headers(in_h_idx).org_id                    -- �g�DID
       ,gt_order_headers(in_h_idx).order_source_id           -- �󒍃\�[�XID
       ,gt_order_headers(in_h_idx).order_type_id             -- �󒍃^�C�vID
       ,gt_order_headers(in_h_idx).ordered_date              -- �󒍓�
       ,gt_order_headers(in_h_idx).customer_number           -- �ڋq�R�[�h
       ,gt_order_headers(in_h_idx).customer_po_number        -- �ڋq�����ԍ�
       ,gt_order_headers(in_h_idx).request_date              -- �[�i�\���
       ,gt_order_headers(in_h_idx).price_list_id             -- ���i�\ID
       ,gt_order_headers(in_h_idx).salesrep_id               -- �c�ƒS��ID
       ,gt_order_headers(in_h_idx).sold_to_org_id            -- �����ڋqID
       ,gt_order_headers(in_h_idx).shipping_instructions     -- �o�׎w��
       ,gt_order_headers(in_h_idx).payment_term_id           -- �x������ID
       ,gt_order_headers(in_h_idx).context                   -- �R���e�L�X�g
       ,gt_order_headers(in_h_idx).attribute5                -- �`�[�敪
       ,gt_order_headers(in_h_idx).attribute12               -- �����p���_
       ,gt_order_headers(in_h_idx).attribute13               -- ���Ԏw��(From)
       ,gt_order_headers(in_h_idx).attribute14               -- ���Ԏw��(To)
       ,gt_order_headers(in_h_idx).attribute15               -- �`�[No
       ,gt_order_headers(in_h_idx).attribute16               -- �}��
       ,gt_order_headers(in_h_idx).attribute17               -- ������(�ɓ���)����ϋ��
       ,gt_order_headers(in_h_idx).attribute18               -- ������(����@)����ϋ��
       ,gt_order_headers(in_h_idx).attribute19               -- �I�[�_�[No
       ,gt_order_headers(in_h_idx).attribute20               -- ���ދ敪
       ,gt_order_headers(in_h_idx).global_attribute1         -- ���ʒ��[�l���p�[�i�����s�t���O�G���A
       ,gt_order_headers(in_h_idx).global_attribute3         -- ���敪
       ,gt_order_headers(in_h_idx).global_attribute4         -- ��No.(HHT)
       ,gt_order_headers(in_h_idx).global_attribute5         -- �������敪
       ,gt_order_headers(in_h_idx).orig_sys_document_ref     -- �󒍊֘A�ԍ�(EDI)
       ,gt_order_headers(in_h_idx).return_reason_code        -- ������R�R�[�h
       ,gt_order_headers(in_h_idx).order_number              -- �A�h�I���󒍔ԍ�
       ,gt_order_headers(in_h_idx).operation_code            -- �I�y���[�V����
       ,gt_order_headers(in_h_idx).cancelled_flag            -- ����t���O
       ,cn_created_by                                        -- �쐬��
       ,cd_creation_date                                     -- �쐬��
       ,cn_last_updated_by                                   -- �ŏI�X�V��
       ,cd_last_update_date                                  -- �ŏI�X�V��
       ,cn_last_update_login                                 -- �ŏI�X�V���O�C��
       ,NULL                                                 -- �v��ID
       ,cn_program_application_id                            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,cn_program_id                                        -- �R���J�����g�E�v���O����ID
       ,cd_program_update_date                               -- �v���O�����X�V��
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        --���b�Z�[�W�ҏW
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_cos
                       , iv_name         => cv_msg_00010
                       , iv_token_name1  => cv_tkn_table_name  -- �e�[�u��
                       , iv_token_value1 => cv_msg_00132       -- �e�[�u����
                       , iv_token_name2  => cv_tkn_key_data    -- �L�[�f�[�^
                       , iv_token_value2 => SQLERRM            -- SQL�G���[���b�Z�[�W
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_oif_order_header;
--
  /**********************************************************************************
   * Procedure Name   : ins_oif_order_process
   * Description      : �󒍏���OIF�e�[�u���o�^(A-4)
   ***********************************************************************************/
  PROCEDURE ins_oif_order_process(
     in_h_idx      IN  NUMBER       --   �A�h�I���󒍃w�b�_�f�[�^�C���f�N�X
    ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_oif_order_process'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �I�y���[�V�������uINSERT�v�A�󒍃X�e�[�^�X���uBOOKED�F�L���ρv�̏ꍇ
    IF ( gt_order_headers(in_h_idx).operation_code = cv_op_insert )
      AND ( gt_order_headers(in_h_idx).flow_status_code = cv_sts_booked )
    THEN
--
      BEGIN
--
        -- �󒍏���OIF�e�[�u���o�^
        INSERT INTO oe_actions_iface_all(
          order_source_id        -- �C���|�[�g�\�[�XID
         ,orig_sys_document_ref  -- �O���V�X�e���󒍔ԍ�
         ,operation_code         -- �I�y���[�V�����R�[�h
        )
        VALUES
        (
          gt_order_headers(in_h_idx).order_source_id        -- �󒍃\�[�XID
         ,gt_order_headers(in_h_idx).orig_sys_document_ref  -- �󒍊֘A�ԍ�(EDI)
         ,cv_book_order                                     -- �I�y���[�V����
        );
 --
      EXCEPTION
        WHEN OTHERS THEN
          --���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_cos
                         , iv_name         => cv_msg_00010
                         , iv_token_name1  => cv_tkn_table_name  -- �e�[�u��
                         , iv_token_value1 => cv_msg_00134       -- �e�[�u����
                         , iv_token_name2  => cv_tkn_key_data    -- �L�[�f�[�^
                         , iv_token_value2 => SQLERRM            -- SQL�G���[���b�Z�[�W
                        );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_oif_order_process;
--
  /**********************************************************************************
   * Procedure Name   : ins_upd_order_process
   * Description      : EBS�󒍏������o�^�ƍX�V(A-5)
   ***********************************************************************************/
  PROCEDURE ins_upd_order_process(
     in_h_idx      IN  NUMBER       --   �A�h�I���󒍃w�b�_�f�[�^�C���f�N�X
    ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_upd_order_process'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
-- ************** Ver1.1 A.Igimi ADD START *************** --
    lv_flg VARCHAR2(1);     -- �f�[�^���݃t���O
-- ************** Ver1.1 A.Igimi ADD  END  *************** --
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
-- ************** Ver1.1 A.Igimi MOD START *************** --
--    IF ( gt_order_headers(in_h_idx).operation_code = cv_op_insert)
--
    -- XXCOS_ORDER_PROCESS�̃f�[�^���݃`�F�b�N
    BEGIN
      SELECT cv_flg_y
      INTO   lv_flg
      FROM   xxcos_order_process  xop
      WHERE  xop.paas_order_number        =  gt_order_headers(in_h_idx).order_number;
--
    EXCEPTION
      -- XXCOS_ORDER_PROCESS�Ƀf�[�^�����݂��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_flg := cv_flg_n;
      -- ���̑��G���[
      WHEN OTHERS THEN
        lv_errmsg := SQLERRM;
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    IF lv_flg = cv_flg_n
-- ************** Ver1.1 A.Igimi MOD  END  *************** --
    THEN
      --
      BEGIN
        -- EBS�󒍏������o�^
        INSERT INTO xxcos_order_process(
          order_process_id          -- EBS�󒍏���ID
         ,paas_order_number         -- �A�h�I���󒍔ԍ�
         ,order_source_id           -- �󒍃\�[�XID
         ,orig_sys_document_ref     -- �󒍊֘A�ԍ�(EDI)
         ,process_flag              -- �����t���O
         ,created_by                -- �쐬��
         ,creation_date             -- �쐬��
         ,last_updated_by           -- �ŏI�X�V��
         ,last_update_date          -- �ŏI�X�V��
         ,last_update_login         -- �ŏI�X�V���O�C��
         ,request_id                -- �v��ID
         ,program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id                -- �R���J�����g�E�v���O����ID
         ,program_update_date       -- �v���O�����X�V��
        )
        VALUES
        (
          xxcos_order_process_s01.NEXTVAL                      -- EBS�󒍏���ID
         ,gt_order_headers(in_h_idx).order_number              -- �A�h�I���󒍔ԍ�
         ,gt_order_headers(in_h_idx).order_source_id           -- �󒍃\�[�XID
         ,gt_order_headers(in_h_idx).orig_sys_document_ref     -- �󒍊֘A�ԍ�(EDI)
         ,cv_flg_1                                             -- �����t���O�u1�F�o�^�v
         ,cn_created_by                                        -- �쐬��
         ,cd_creation_date                                     -- �쐬��
         ,cn_last_updated_by                                   -- �ŏI�X�V��
         ,cd_last_update_date                                  -- �ŏI�X�V��
         ,cn_last_update_login                                 -- �ŏI�X�V���O�C��
         ,cn_request_id                                        -- �v��ID
         ,cn_program_application_id                            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,cn_program_id                                        -- �R���J�����g�E�v���O����ID
         ,cd_program_update_date                               -- �v���O�����X�V��
        );
      EXCEPTION
        WHEN OTHERS THEN
          --���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_cos
                         , iv_name         => cv_msg_00010
                         , iv_token_name1  => cv_tkn_table_name  -- �e�[�u��
                         , iv_token_value1 => cv_msg_16009       -- �e�[�u����
                         , iv_token_name2  => cv_tkn_key_data    -- �L�[�f�[�^
                         , iv_token_value2 => SQLERRM            -- SQL�G���[���b�Z�[�W
                        );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
--
    ELSE
      --
      BEGIN
        -- EBS�󒍏������X�V
        UPDATE  xxcos_order_process  xop
-- Ver1.3 Mod Start
--        SET     xop.process_flag             =  cv_flg_2,                          -- �����t���O�u2�F�X�V�v
        SET     xop.process_flag             =  CASE
                                                  WHEN gt_order_headers(in_h_idx).flow_status_code = cv_sts_cancelled THEN
                                                    cv_flg_3                       -- �����t���O�u3�F�w�b�_����v
                                                  ELSE
                                                    cv_flg_2                       -- �����t���O�u2�F�X�V�v
                                                END,
-- Ver1.3 Mod End
                xop.last_updated_by          =  cn_last_updated_by,                -- �ŏI�X�V��
                xop.last_update_date         =  cd_last_update_date,               -- �ŏI�X�V��
                xop.last_update_login        =  cn_last_update_login,              -- �ŏI�X�V۸޲�
                xop.request_id               =  cn_request_id,                     -- �v��ID
                xop.program_application_id   =  cn_program_application_id,         -- �ݶ��ĥ��۸��ѥ���ع����ID
                xop.program_id               =  cn_program_id,                     -- �ݶ��ĥ��۸���ID
                xop.program_update_date      =  cd_program_update_date             -- ��۸��эX�V��
        WHERE   xop.paas_order_number        =  gt_order_headers(in_h_idx).order_number;
      EXCEPTION
        WHEN OTHERS THEN
          --���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_cos
                         , iv_name         => cv_msg_00011
                         , iv_token_name1  => cv_tkn_table_name  -- �e�[�u��
                         , iv_token_value1 => cv_msg_16009       -- �e�[�u����
                         , iv_token_name2  => cv_tkn_key_data    -- �L�[�f�[�^
                         , iv_token_value2 => SQLERRM            -- SQL�G���[���b�Z�[�W
                        );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_upd_order_process;
--
  /**********************************************************************************
   * Procedure Name   : get_order_lines
   * Description      : �A�h�I���󒍖��׃f�[�^���o(A-6)
   ***********************************************************************************/
  PROCEDURE get_order_lines(
    in_h_idx      IN  NUMBER,              --   �A�h�I���󒍃w�b�_�f�[�^�C���f�N�X
    on_target_cnt OUT NOCOPY NUMBER,       --   �Ώۃf�[�^����
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'get_order_lines'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf               VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_idx                  NUMBER;
    -- *** ���[�J���E���R�[�h ***
    l_lines_rec  order_lines_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- OUT�p�����[�^������
    on_target_cnt := 0;
    --
    ln_idx        := 0;
--
    BEGIN
      -- �J�[�\���I�[�v��
      OPEN order_lines_cur(gt_order_headers(in_h_idx).header_id);
--
      <<lines_loop>>
      LOOP
--
        FETCH order_lines_cur INTO l_lines_rec;
        EXIT WHEN order_lines_cur%NOTFOUND;
--
        -- �J�E���g�A�b�v
        ln_idx := ln_idx + 1;
        ------------------------------------
        -- �A�h�I���󒍖��׃f�[�^�z��ݒ�
        ------------------------------------
        gt_order_lines(ln_idx).line_id                  := l_lines_rec.line_id;                   -- �A�h�I������ID
        gt_order_lines(ln_idx).header_id                := l_lines_rec.header_id;                 -- �A�h�I���w�b�_ID
        gt_order_lines(ln_idx).org_id                   := l_lines_rec.org_id;                    -- �g�DID
        gt_order_lines(ln_idx).line_type_id             := l_lines_rec.line_type_id;              -- ���׃^�C�vID
        gt_order_lines(ln_idx).line_number              := l_lines_rec.line_number;               -- ���הԍ�
        gt_order_lines(ln_idx).order_source_id          := l_lines_rec.order_source_id;           -- �󒍃\�[�XID
        gt_order_lines(ln_idx).inventory_item           := l_lines_rec.inventory_item;            -- �i�ڃR�[�h
        gt_order_lines(ln_idx).request_date             := l_lines_rec.request_date;              -- �[�i�\���
        gt_order_lines(ln_idx).ordered_quantity         := l_lines_rec.ordered_quantity;          -- ����
        gt_order_lines(ln_idx).order_quantity_uom       := l_lines_rec.order_quantity_uom;        -- �P��
        gt_order_lines(ln_idx).price_list_id            := l_lines_rec.price_list_id;             -- ���i�\ID
        gt_order_lines(ln_idx).payment_term_id          := l_lines_rec.payment_term_id;           -- �x������ID
        gt_order_lines(ln_idx).orig_sys_document_ref    := l_lines_rec.orig_sys_document_ref;     -- �󒍊֘A�ԍ�(EDI)
        gt_order_lines(ln_idx).orig_sys_line_ref        := l_lines_rec.orig_sys_line_ref;         -- �󒍊֘A���הԍ�(EDI)
        gt_order_lines(ln_idx).unit_list_price          := l_lines_rec.unit_list_price;           -- �P��
        gt_order_lines(ln_idx).unit_selling_price       := l_lines_rec.unit_selling_price;        -- �̔��P��
        gt_order_lines(ln_idx).flow_status_code         := l_lines_rec.flow_status_code;          -- �󒍃X�e�[�^�X
        gt_order_lines(ln_idx).subinventory             := l_lines_rec.subinventory;              -- �ۊǏꏊ
        gt_order_lines(ln_idx).packing_instructions     := l_lines_rec.packing_instructions;      -- �o�׈˗��ԍ�
        gt_order_lines(ln_idx).return_reason_code       := l_lines_rec.return_reason_code;        -- ������R�R�[�h
        gt_order_lines(ln_idx).customer_po_number       := l_lines_rec.customer_po_number;        -- �ڋq�����ԍ�
        gt_order_lines(ln_idx).customer_line_number     := l_lines_rec.customer_line_number;      -- �ڋq���הԍ�
        gt_order_lines(ln_idx).calculate_price_flag     := l_lines_rec.calculate_price_flag;      -- ���i�v�Z�t���O
        gt_order_lines(ln_idx).schedule_ship_date       := l_lines_rec.schedule_ship_date;        -- �\��o�ד�
        gt_order_lines(ln_idx).salesrep_id              := l_lines_rec.salesrep_id;               -- �c�ƒS��ID
        gt_order_lines(ln_idx).inventory_item_id        := l_lines_rec.inventory_item_id;         -- �i��ID
        gt_order_lines(ln_idx).sold_to_org_id           := l_lines_rec.sold_to_org_id;            -- �����ڋqID
        gt_order_lines(ln_idx).ship_from_org_id         := l_lines_rec.ship_from_org_id;          -- �o�׌��݌ɑg�DID
        gt_order_lines(ln_idx).cancelled_quantity       := l_lines_rec.cancelled_quantity;        -- �������
        gt_order_lines(ln_idx).context                  := l_lines_rec.context;                   -- �R���e�L�X�g
        gt_order_lines(ln_idx).attribute4               := l_lines_rec.attribute4;                -- ������
        gt_order_lines(ln_idx).attribute5               := l_lines_rec.attribute5;                -- ����敪
        gt_order_lines(ln_idx).attribute6               := l_lines_rec.attribute6;                -- �q�R�[�h
        gt_order_lines(ln_idx).attribute7               := l_lines_rec.attribute7;                -- ���l
        gt_order_lines(ln_idx).attribute8               := l_lines_rec.attribute8;                -- ����_���Ԏw��(From)
        gt_order_lines(ln_idx).attribute9               := l_lines_rec.attribute9;                -- ����_���Ԏw��(To)
        gt_order_lines(ln_idx).attribute10              := l_lines_rec.attribute10;               -- ���P��
        gt_order_lines(ln_idx).attribute11              := l_lines_rec.attribute11;               -- �|%
        gt_order_lines(ln_idx).attribute12              := l_lines_rec.attribute12;               -- ����󔭍s�ԍ�
        gt_order_lines(ln_idx).global_attribute1        := l_lines_rec.global_attribute1;         -- �󒍈ꗗ�o�͓�
        gt_order_lines(ln_idx).global_attribute2        := l_lines_rec.global_attribute2;         -- �[�i�����s�t���O�G���A
        gt_order_lines(ln_idx).global_attribute3        := l_lines_rec.global_attribute3;         -- �󒍖���ID(�����O)
        gt_order_lines(ln_idx).global_attribute4        := l_lines_rec.global_attribute4;         -- �󒍖��׎Q��
        gt_order_lines(ln_idx).global_attribute5        := l_lines_rec.global_attribute5;         -- �̔����јA�g�t���O
        gt_order_lines(ln_idx).global_attribute6        := l_lines_rec.global_attribute6;         -- �󒍈ꗗ�t�@�C���o�͓�
        gt_order_lines(ln_idx).global_attribute7        := l_lines_rec.global_attribute7;         -- HHT�󒍑��M�t���O
        gt_order_lines(ln_idx).global_attribute9        := l_lines_rec.global_attribute9;         -- ���הԍ�(�����O)
        gt_order_lines(ln_idx).global_attribute10       := l_lines_rec.global_attribute10;        -- PaaS���׍ŏI�X�V��(UTC)
        gt_order_lines(ln_idx).operation_code           := l_lines_rec.operation_code;            -- �I�y���[�V����
--
      END LOOP lines_loop;
--
      -- �J�[�\���N���[�Y
      CLOSE order_lines_cur;
--
    EXCEPTION
      -- �f�[�^���o�G���[
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_cos
                       , iv_name         => cv_msg_00013
                       , iv_token_name1  => cv_tkn_table_name
                       , iv_token_value1 => cv_msg_16008
                       , iv_token_name2  => cv_tkn_key_data
                       , iv_token_value2 => cv_msg_part||SQLERRM
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- OUT�p�����[�^�ݒ�
    on_target_cnt := ln_idx;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( order_lines_cur%ISOPEN ) THEN
        CLOSE order_lines_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( order_lines_cur%ISOPEN ) THEN
        CLOSE order_lines_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( order_lines_cur%ISOPEN ) THEN
        CLOSE order_lines_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_order_lines;
--
  /**********************************************************************************
   * Procedure Name   : ins_oif_order_line
   * Description      : �󒍖���OIF�e�[�u���o�^(A-7)
   ***********************************************************************************/
  PROCEDURE ins_oif_order_line(
     in_h_idx      IN  NUMBER       --   �A�h�I���󒍃w�b�_�f�[�^�C���f�N�X
    ,in_l_idx      IN  NUMBER       --   �A�h�I���󒍖��׃f�[�^�C���f�N�X
    ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_oif_order_line'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lt_flow_status_code  oe_order_lines_all.flow_status_code%TYPE;   -- �X�e�[�^�X�i�󒍖��ׁj
    lt_line_number       oe_order_lines_all.line_number%TYPE;        -- ���הԍ�
    lt_orig_sys_line_ref oe_order_lines_all.orig_sys_line_ref%TYPE;  -- �O���V�X�e���󒍖��הԍ�
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �󒍃X�e�[�^�X�i���ׁj���uBOOKED�F�L���ρv�A�uCANCELLED�F����ρv�ȊO�̏ꍇ
    IF ( gt_order_lines(in_l_idx).flow_status_code <> cv_sts_booked )
      AND ( gt_order_lines(in_l_idx).flow_status_code <> cv_sts_cancelled )
    THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_cos
                     , iv_name         => cv_msg_16006
                     , iv_token_name1  => cv_tkn_header_id        -- �A�h�I���w�b�_ID
                     , iv_token_value1 => gt_order_headers(in_h_idx).header_id
                     , iv_token_name2  => cv_tkn_header_status    -- �󒍃X�e�[�^�X
                     , iv_token_value2 => gt_order_headers(in_h_idx).flow_status_code
                     , iv_token_name3  => cv_tkn_line_id          -- �A�h�I����ID
                     , iv_token_value3 => gt_order_lines(in_l_idx).line_id
                     , iv_token_name4  => cv_tkn_line_status      -- �󒍃X�e�[�^�X�i���ׁj
                     , iv_token_value4 => gt_order_lines(in_l_idx).flow_status_code
                    );
      lv_errbuf  := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �󒍃X�e�[�^�X�i�w�b�_�j���uCANCELLED�F����ρv�A�󒍃X�e�[�^�X�i���ׁj���uCANCELLED�F����ρv�ȊO�̏ꍇ
    IF ( gt_order_headers(in_h_idx).flow_status_code = cv_sts_cancelled )
      AND ( gt_order_lines(in_l_idx).flow_status_code <> cv_sts_cancelled )
    THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_cos
                     , iv_name         => cv_msg_16006
                     , iv_token_name1  => cv_tkn_header_id        -- �A�h�I���w�b�_ID
                     , iv_token_value1 => gt_order_headers(in_h_idx).header_id
                     , iv_token_name2  => cv_tkn_header_status    -- �󒍃X�e�[�^�X
                     , iv_token_value2 => gt_order_headers(in_h_idx).flow_status_code
                     , iv_token_name3  => cv_tkn_line_id          -- �A�h�I����ID
                     , iv_token_value3 => gt_order_lines(in_l_idx).line_id
                     , iv_token_name4  => cv_tkn_line_status      -- �󒍃X�e�[�^�X�i���ׁj
                     , iv_token_value4 => gt_order_lines(in_l_idx).flow_status_code
                    );
      lv_errbuf  := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ����ώ󒍖��׃f�[�^�̐V�K�o�^�X�L�b�v
    IF ( gt_order_lines(in_l_idx).operation_code = cv_op_insert )
      AND ( gt_order_lines(in_l_idx).flow_status_code = cv_sts_cancelled )
    THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_cos
                     , iv_name         => cv_msg_16004
                     , iv_token_name1  => cv_tkn_header_id        -- �A�h�I���w�b�_ID
                     , iv_token_value1 => gt_order_lines(in_l_idx).header_id
                     , iv_token_name2  => cv_tkn_line_id          -- �A�h�I������ID
                     , iv_token_value2 => gt_order_lines(in_l_idx).line_id
                    );
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
          which  => fnd_file.output
        , buff   => lv_errmsg
      );
      -- ���O�o��
      fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => lv_errmsg
      );
-- Ver1.3 Del Start
--      gn_warn_cnt := gn_warn_cnt + 1;
-- Ver1.3 Del End
      RETURN;
    END IF;
--
    -- �N���[�Y�ώ󒍖��׃f�[�^�̍X�V�X�L�b�v
    IF ( gt_order_lines(in_l_idx).operation_code = cv_op_update )
    THEN
      -- �󒍖��ׂ̃X�e�[�^�X�擾
      BEGIN
--
        SELECT
               oola.flow_status_code         flow_status_code           -- �X�e�[�^�X
              ,oola.line_number              line_number                -- ���הԍ�
              ,oola.orig_sys_line_ref        orig_sys_line_ref          -- �O���V�X�e���󒍖��הԍ�
        INTO   lt_flow_status_code
              ,lt_line_number
              ,lt_orig_sys_line_ref
        FROM   oe_order_lines_all      oola         -- �󒍖��׃e�[�u��
        WHERE  oola.order_source_id       = gt_order_lines(in_l_idx).order_source_id
        AND    oola.orig_sys_document_ref = gt_order_lines(in_l_idx).orig_sys_document_ref
        AND    oola.global_attribute8     = gt_order_lines(in_l_idx).line_number;
--
      EXCEPTION
        -- ���݂��Ȃ��ꍇ
        WHEN NO_DATA_FOUND THEN
        -- �󒍖��הԍ��擾�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_cos
                       , iv_name         => cv_msg_16013
                       , iv_token_name1  => cv_tkn_header_id        -- �A�h�I���w�b�_ID
                       , iv_token_value1 => gt_order_lines(in_l_idx).header_id
                       , iv_token_name2  => cv_tkn_line_id          -- �A�h�I������ID
                       , iv_token_value2 => gt_order_lines(in_l_idx).line_id
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
--
      END;
      -- �X�e�[�^�X�ϐ���NULL�ȊO���X�e�[�^�X�ϐ����uCLOSED�F�N���[�Y�ρv�̏ꍇ
      IF ( lt_flow_status_code IS NOT NULL )
        AND ( lt_flow_status_code = cv_sts_closed )
      THEN
          lv_errmsg    := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_cos
                         , iv_name         => cv_msg_16012
                         , iv_token_name1  => cv_tkn_header_id        -- �A�h�I���w�b�_ID
                         , iv_token_value1 => gt_order_lines(in_l_idx).header_id
                         , iv_token_name2  => cv_tkn_line_id          -- �A�h�I������ID
                         , iv_token_value2 => gt_order_lines(in_l_idx).line_id
                        );
        -- ���b�Z�[�W�o��
        fnd_file.put_line(
            which  => fnd_file.output
          , buff   => lv_errmsg
        );
        -- ���O�o��
        fnd_file.put_line(
             which  => fnd_file.log
            ,buff   => lv_errmsg
        );
        gn_warn_cnt := gn_warn_cnt + 1;
        RETURN;
      END IF;
    END IF;
--
    -- �I�y���[�V�������uINSERT�v�v�̏ꍇ�A�󒍖��הԍ��ϐ����J�E���g�A�b�v
     IF ( gt_order_lines(in_l_idx).operation_code = cv_op_insert )
    THEN
      gn_line_number := gn_line_number + 1;
    END IF;
--
    BEGIN
--
      -- �󒍖���OIF�e�[�u���o�^
      INSERT INTO oe_lines_iface_all(
        org_id                    -- �g�DID
       ,line_type_id              -- ���׃^�C�vID
       ,line_number               -- ���הԍ�
       ,order_source_id           -- �󒍃\�[�XID
       ,inventory_item            -- �i�ڃR�[�h
       ,request_date              -- �[�i�\���
       ,ordered_quantity          -- ����
       ,order_quantity_uom        -- �P��
       ,price_list_id             -- ���i�\ID
       ,payment_term_id           -- �x������ID
       ,orig_sys_document_ref     -- �O���V�X�e���󒍔ԍ�
       ,orig_sys_line_ref         -- �O���V�X�e���󒍖��הԍ�
       ,unit_list_price           -- �P��
       ,unit_selling_price        -- �̔��P��
       ,subinventory              -- �ۊǏꏊ
       ,packing_instructions      -- �o�׈˗��ԍ�
       ,change_reason             -- �ύX���R
       ,customer_po_number        -- �ڋq�����ԍ�
       ,customer_line_number      -- �ڋq���הԍ�
       ,calculate_price_flag      -- ���i�v�Z�t���O
       ,schedule_ship_date        -- �\��o�ד�
       ,salesrep_id               -- �c�ƒS��ID
       ,inventory_item_id         -- �i��ID
       ,sold_to_org_id            -- �����ڋqID
       ,ship_from_org_id          -- �o�׌��݌ɑg�DID
       ,cancelled_quantity        -- �������
       ,context                   -- �R���e�L�X�g
       ,attribute4                -- ������
       ,attribute5                -- ����敪
       ,attribute6                -- �q�R�[�h
       ,attribute7                -- ���l
       ,attribute8                -- ����_���Ԏw��(From)
       ,attribute9                -- ����_���Ԏw��(To)
       ,attribute10               -- ���P��
       ,attribute11               -- �|%
       ,attribute12               -- ����󔭍s�ԍ�
       ,global_attribute1         -- �󒍈ꗗ�o�͓�
       ,global_attribute2         -- �[�i�����s�t���O�G���A
       ,global_attribute3         -- �󒍖���ID(�����O)
       ,global_attribute4         -- �󒍖��׎Q��
       ,global_attribute5         -- �̔����јA�g�t���O
       ,global_attribute6         -- �󒍈ꗗ�t�@�C���o�͓�
       ,global_attribute7         -- HHT�󒍑��M�t���O
       ,global_attribute8         -- ���הԍ�
       ,global_attribute9         -- ���הԍ�(�����O)
       ,global_attribute10        -- PaaS���׍ŏI�X�V��(UTC)
       ,operation_code            -- �I�y���[�V����
       ,created_by                -- �쐬��
       ,creation_date             -- �쐬��
       ,last_updated_by           -- �ŏI�X�V��
       ,last_update_date          -- �ŏI�X�V��
       ,last_update_login         -- �ŏI�X�V���O�C��
       ,request_id                -- �v��ID
       ,program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,program_id                -- �R���J�����g�E�v���O����ID
       ,program_update_date       -- �v���O�����X�V��
      )
      VALUES
      (
        gt_order_lines(in_l_idx).org_id                    -- �g�DID
       ,gt_order_lines(in_l_idx).line_type_id              -- ���׃^�C�vID
       ,CASE WHEN ( gt_order_headers(in_h_idx).operation_code = cv_op_insert )
               THEN gt_order_lines(in_l_idx).line_number
             WHEN ( gt_order_lines(in_l_idx).operation_code = cv_op_insert )
               THEN gn_line_number
             ELSE lt_line_number
        END                                                -- ���הԍ�
       ,gt_order_lines(in_l_idx).order_source_id           -- �󒍃\�[�XID
       ,gt_order_lines(in_l_idx).inventory_item            -- �i�ڃR�[�h
       ,gt_order_lines(in_l_idx).request_date              -- �[�i�\���
       ,gt_order_lines(in_l_idx).ordered_quantity          -- ����
       ,gt_order_lines(in_l_idx).order_quantity_uom        -- �P��
       ,gt_order_lines(in_l_idx).price_list_id             -- ���i�\ID
       ,gt_order_lines(in_l_idx).payment_term_id           -- �x������ID
       ,gt_order_lines(in_l_idx).orig_sys_document_ref     -- �󒍊֘A�ԍ�(EDI)
       ,CASE WHEN ( gt_order_headers(in_h_idx).operation_code = cv_op_insert )
               THEN TO_CHAR(gt_order_lines(in_l_idx).line_number)
             WHEN ( gt_order_lines(in_l_idx).operation_code = cv_op_insert )
               THEN TO_CHAR(gn_line_number)
             ELSE lt_orig_sys_line_ref
        END                                                -- �󒍊֘A���הԍ�(EDI)
       ,NVL(gt_order_lines(in_l_idx).unit_list_price,
            gt_order_lines(in_l_idx).unit_selling_price)   -- �P��
       ,gt_order_lines(in_l_idx).unit_selling_price        -- �̔��P��
       ,gt_order_lines(in_l_idx).subinventory              -- �ۊǏꏊ
       ,gt_order_lines(in_l_idx).packing_instructions      -- �o�׈˗��ԍ�
       ,gt_order_lines(in_l_idx).return_reason_code        -- ������R�R�[�h
       ,gt_order_lines(in_l_idx).customer_po_number        -- �ڋq�����ԍ�
       ,gt_order_lines(in_l_idx).customer_line_number      -- �ڋq���הԍ�
       ,gt_order_lines(in_l_idx).calculate_price_flag      -- ���i�v�Z�t���O
       ,gt_order_lines(in_l_idx).schedule_ship_date        -- �\��o�ד�
       ,gt_order_lines(in_l_idx).salesrep_id               -- �c�ƒS��ID
       ,gt_order_lines(in_l_idx).inventory_item_id         -- �i��ID
       ,gt_order_lines(in_l_idx).sold_to_org_id            -- �����ڋqID
       ,gt_order_lines(in_l_idx).ship_from_org_id          -- �o�׌��݌ɑg�DID
       ,NULL                                                -- �������
       ,gt_order_lines(in_l_idx).context                   -- �R���e�L�X�g
       ,gt_order_lines(in_l_idx).attribute4                -- ������
       ,gt_order_lines(in_l_idx).attribute5                -- ����敪
       ,gt_order_lines(in_l_idx).attribute6                -- �q�R�[�h
       ,gt_order_lines(in_l_idx).attribute7                -- ���l
       ,gt_order_lines(in_l_idx).attribute8                -- ����_���Ԏw��(From)
       ,gt_order_lines(in_l_idx).attribute9                -- ����_���Ԏw��(To)
       ,gt_order_lines(in_l_idx).attribute10               -- ���P��
       ,gt_order_lines(in_l_idx).attribute11               -- �|%
       ,gt_order_lines(in_l_idx).attribute12               -- ����󔭍s�ԍ�
       ,gt_order_lines(in_l_idx).global_attribute1         -- �󒍈ꗗ�o�͓�
       ,gt_order_lines(in_l_idx).global_attribute2         -- �[�i�����s�t���O�G���A
       ,gt_order_lines(in_l_idx).global_attribute3         -- �󒍖���ID(�����O)
       ,gt_order_lines(in_l_idx).global_attribute4         -- �󒍖��׎Q��
       ,gt_order_lines(in_l_idx).global_attribute5         -- �̔����јA�g�t���O
       ,gt_order_lines(in_l_idx).global_attribute6         -- �󒍈ꗗ�t�@�C���o�͓�
       ,gt_order_lines(in_l_idx).global_attribute7         -- HHT�󒍑��M�t���O
       ,gt_order_lines(in_l_idx).line_number               -- ���הԍ�
       ,gt_order_lines(in_l_idx).global_attribute9         -- ���הԍ�(�����O)
       ,gt_order_lines(in_l_idx).global_attribute10        -- PaaS���׍ŏI�X�V��(UTC)
       ,gt_order_lines(in_l_idx).operation_code            -- �I�y���[�V����
       ,cn_created_by                                      -- �쐬��
       ,cd_creation_date                                   -- �쐬��
       ,cn_last_updated_by                                 -- �ŏI�X�V��
       ,cd_last_update_date                                -- �ŏI�X�V��
       ,cn_last_update_login                               -- �ŏI�X�V���O�C��
       ,NULL                                               -- �v��ID
       ,cn_program_application_id                          -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,cn_program_id                                      -- �R���J�����g�E�v���O����ID
       ,cd_program_update_date                             -- �v���O�����X�V��
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        --���b�Z�[�W�ҏW
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_cos
                       , iv_name         => cv_msg_00010
                       , iv_token_name1  => cv_tkn_table_name  -- �e�[�u��
                       , iv_token_value1 => cv_msg_00133       -- �e�[�u����
                       , iv_token_name2  => cv_tkn_key_data    -- �L�[�f�[�^
                       , iv_token_value2 => SQLERRM            -- SQL�G���[���b�Z�[�W
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_oif_order_line;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf               VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt           := 0;
    gn_l_target_cnt         := 0;
    gn_normal_cnt           := 0;
    gn_warn_cnt             := 0;
    gn_error_cnt            := 0;
--
    -- ============================================
    -- ��������(A-1)
    -- ============================================
    init(
      ov_errbuf   => lv_errbuf,
      ov_retcode  => lv_retcode,
      ov_errmsg   => lv_errmsg
    );
--
    -- �G���[�̏ꍇ
    IF ( lv_retcode = cv_status_error )
    THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ============================================
    -- �A�h�I���󒍃w�b�_���e�[�u���f�[�^���o(A-2)
    -- ============================================
    get_order_headers(
      on_target_cnt => gn_target_cnt,
      ov_errbuf     => lv_errbuf,
      ov_retcode    => lv_retcode,
      ov_errmsg     => lv_errmsg
    );
--
    -- �G���[�̏ꍇ
    IF ( lv_retcode = cv_status_error )
    THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    <<order_headers_loop>>
    FOR ln_i IN 1..gn_target_cnt LOOP
--
      -- �󒍃X�L�b�v�t���O������
      gv_skip_flg := cv_flg_n;
--
      -- ============================================
      -- �󒍃w�b�_OIF�e�[�u���o�^(A-3)
      -- ============================================
--
        ins_oif_order_header(
          in_h_idx       => ln_i,
          ov_errbuf      => lv_errbuf,
          ov_retcode     => lv_retcode,
          ov_errmsg      => lv_errmsg
        );
        -- �G���[�̏ꍇ
        IF ( lv_retcode = cv_status_error )
        THEN
          ov_errbuf  := lv_errbuf;
          ov_retcode := lv_retcode;
          ov_errmsg  := lv_errmsg;
          -- �G���[����
          gn_error_cnt := gn_error_cnt + 1;
          RETURN;
        END IF;
--
      -- �󒍃X�L�b�v�t���O��N�̏ꍇ
      IF ( gv_skip_flg = cv_flg_n )
      THEN
        -- ============================================
        -- �󒍏���OIF�e�[�u���o�^(A-4)
        -- ============================================
--
        ins_oif_order_process(
          in_h_idx       => ln_i,
          ov_errbuf      => lv_errbuf,
          ov_retcode     => lv_retcode,
          ov_errmsg      => lv_errmsg
        );
        -- �G���[�̏ꍇ
        IF ( lv_retcode = cv_status_error ) THEN
          ov_errbuf  := lv_errbuf;
          ov_retcode := lv_retcode;
          ov_errmsg  := lv_errmsg;
          -- �G���[����
          gn_error_cnt := gn_error_cnt + 1;
          RETURN;
        END IF;
--
        -- ============================================
        -- EBS�󒍏������o�^�ƍX�V(A-5)
        -- ============================================
-- 
        ins_upd_order_process(
          in_h_idx       => ln_i,
          ov_errbuf      => lv_errbuf,
          ov_retcode     => lv_retcode,
          ov_errmsg      => lv_errmsg
        );
        -- �G���[�̏ꍇ
        IF ( lv_retcode = cv_status_error )
        THEN
          ov_errbuf  := lv_errbuf;
          ov_retcode := lv_retcode;
          ov_errmsg  := lv_errmsg;
          -- �G���[����
          gn_error_cnt := gn_error_cnt + 1;
          RETURN;
        END IF;
--
        -- �I�y���[�V�������uUPDATE�v�A�󒍃X�e�[�^�X���uCANCELLED�F����ρv�̏ꍇ�A�X�L�b�v
        IF ( gt_order_headers(ln_i).operation_code <> cv_op_update )
          OR ( gt_order_headers(ln_i).flow_status_code <> cv_sts_cancelled )
        THEN
          -- ============================================
          -- �A�h�I���󒍖��׃f�[�^���o(A-6)
          -- ============================================
--
          get_order_lines(
            in_h_idx       => ln_i,
            on_target_cnt  => gn_l_target_cnt,
            ov_errbuf      => lv_errbuf,
            ov_retcode     => lv_retcode,
            ov_errmsg      => lv_errmsg
          );
          -- �G���[�̏ꍇ
          IF ( lv_retcode = cv_status_error )
          THEN
            ov_errbuf  := lv_errbuf;
            ov_retcode := lv_retcode;
            ov_errmsg  := lv_errmsg;
            -- �G���[����
            gn_error_cnt := gn_error_cnt + 1;
            RETURN;
          END IF;
--
          <<order_lines_loop>>
          FOR ln_j IN 1..gn_l_target_cnt LOOP
--
            -- ============================================
            -- �󒍖���OIF�e�[�u���o�^(A-7)
            -- ============================================
--
            ins_oif_order_line(
              in_h_idx       => ln_i,
              in_l_idx       => ln_j,
              ov_errbuf      => lv_errbuf,
              ov_retcode     => lv_retcode,
              ov_errmsg      => lv_errmsg
            );
            -- �G���[�̏ꍇ
            IF ( lv_retcode = cv_status_error )
            THEN
              ov_errbuf  := lv_errbuf;
              ov_retcode := lv_retcode;
              ov_errmsg  := lv_errmsg;
              -- �G���[����
              gn_error_cnt := gn_error_cnt + 1;
              RETURN;
            END IF;
--
          END LOOP order_lines_loop;
--
        END IF;
        -- ��������
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END IF;
--
    END LOOP order_headers_loop;
--
    -- �G���[�̏ꍇ
    IF ( lv_retcode = cv_status_error )
    THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,              --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2               --   ���^�[���E�R�[�h    --# �Œ� #
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
    cv_prg_name             CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf               VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code         VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
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
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
        which  => fnd_file.output,
        buff   => lv_errmsg
      );
      -- ���O�o��
      fnd_file.put_line(
        which  => fnd_file.log,
        buff   => lv_errbuf
      );
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --��s�}��
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_ccp
                    ,iv_name         => cv_msg_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_ccp
                    ,iv_name         => cv_msg_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_ccp
                    ,iv_name         => cv_msg_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
--
    -- �x��������1���ȏ゠��ꍇ�A�I���X�e�[�^�X���x���ɐݒ�
    IF ( gn_warn_cnt != 0 )
      AND (lv_retcode = cv_status_normal)THEN
      lv_retcode  := cv_status_warn;
    END IF;
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
                     iv_application  => cv_appl_ccp
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END main;
--
END XXCOS010A12C;
/
