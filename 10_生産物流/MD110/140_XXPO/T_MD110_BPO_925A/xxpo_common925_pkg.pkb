CREATE OR REPLACE PACKAGE BODY xxpo_common925_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo_common925_pkg(body)
 * Description      : ���ʊ֐�
 * MD.050/070       : �x���w������̔��������쐬 Issue1.0  (T_MD050_BPO_925)
 * Version          : 1.5
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  create_reserve_data       FUNCTION  : �������쐬����
 *  prc_check_param_info      PROCEDURE : �p�����[�^�`�F�b�N(A-1)
 *  prc_get_order_info        PROCEDURE : �󒍏�񒊏o(A-2)
 *  prc_get_vendor_info       PROCEDURE : �d������擾(A-3)
 *  prc_get_item_info         PROCEDURE : �i�ڏ��擾(A-4)
 *  prc_get_price             PROCEDURE : �P���擾(A-6)
 *  prc_ins_interface_header  PROCEDURE : �����w�b�_�o�^(A-7)
 *  prc_ins_interface_lines   PROCEDURE : ����(����)���דo�^(A-8)
 *  prc_regist_all            PROCEDURE : �o�^�X�V����(A-9)
 *  prc_end                   PROCEDURE : �㏈��(A-10)
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  auto_purchase_orders      PROCEDURE : �x���w������̔��������쐬
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/12    1.0   M.Imazeki        �V�K�쐬
 *  2008/05/01    1.1   I.Higa           �w�E�����C��
 *                                        �EPO_HEADERS_INTERFACE�̐ݒ�l��ύX
 *                                        �EPO_LINES_INTERFACE�̐ݒ�l��ύX
 *  2008/05/07    1.2   M.Imazeki        �������쐬����(create_reserve_data)�ǉ�
 *  2008/05/22    1.3   Y.Majikina       �����w�b�_��Attribute1�ɐݒ�l��ύX
 *                                       �����w�b�_�i�A�h�I���j�ւ̓o�^��ǉ�
 *  2008/06/16    1.4   I.Higa           �w�E�����C��
 *                                        �E�]�ƈ��ԍ��̌^��NUMBER�^����TYPE�^�֕ύX
 *                                        �E�w�b�_�E�v�Ɏ󒍃w�b�_�A�h�I���̏o�׎w����ݒ�
 *  2008/07/03    1.5   I.Higa           ���ɗ\���(���ח\���)�𔭒��̔[�����ɂ��Ă��邪
 *                                       �o�ɗ\����𔭒��̔[�����Ƃ���悤�ɕύX����B
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal        CONSTANT VARCHAR2(1)  := '0' ;
  gv_status_error         CONSTANT VARCHAR2(1)  := '2' ;
  gv_msg_part             CONSTANT VARCHAR2(3)  := ' : ' ;
  gv_msg_cont             CONSTANT VARCHAR2(3)  := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
  -- ======================================================
  -- ���[�U�[�錾��
  -- ======================================================
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'xxpo_common925_pkg' ; --  �p�b�P�[�W��
  gv_provision_request    CONSTANT VARCHAR2(1)  := '2' ;                  -- '�x���˗�'
  gv_object               CONSTANT VARCHAR2(1)  := '1' ;                  -- '�Ώ�'
  gv_zero                 CONSTANT VARCHAR2(1)  := '0' ;                  -- ���p�[��������
  gv_received             CONSTANT VARCHAR2(2)  := '07' ;                 -- '��̍ς�'
  gv_attribute3           CONSTANT VARCHAR2(1)  := '3' ;                  -- ���K�敪
  gv_attribute6           CONSTANT VARCHAR2(1)  := '3' ;                  -- ���ۋ��敪
  gv_no                   CONSTANT VARCHAR2(3)  := 'N' ;                  -- NO
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application_cmn      CONSTANT VARCHAR2(5)  := 'XXCMN' ;           -- �A�v���P�[�V�����iXXCMN�j
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;            -- �A�v���P�[�V�����iXXPO�j
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �󒍏��f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_order_info  IS RECORD(
      order_header_id       xxwsh_order_headers_all.order_header_id%TYPE         -- ��ͯ�ޱ�޵�ID
     ,shipping_instructions xxwsh_order_headers_all.shipping_instructions%TYPE    -- �o�׎w��
     ,schedule_ship_date    xxwsh_order_headers_all.schedule_ship_date%TYPE       -- �o�ח\���
     ,deliver_from          xxwsh_order_headers_all.deliver_from%TYPE             -- �o�׌��ۊǏꏊ
     ,vendor_id             xxwsh_order_headers_all.vendor_id%TYPE                -- �����ID
     ,vendor_site_code      xxwsh_order_headers_all.vendor_site_code%TYPE         -- �����T�C�g
     ,shipping_inv_item_id  xxwsh_order_lines_all.shipping_inventory_item_id%TYPE -- �o�וi��ID
     ,shipping_item_code    xxwsh_order_lines_all.shipping_item_code%TYPE         -- �o�וi��
     ,quantity              xxwsh_order_lines_all.quantity%TYPE                   -- ����
     ,futai_code            xxwsh_order_lines_all.futai_code%TYPE                 -- �t�уR�[�h
     ,line_description      xxwsh_order_lines_all.line_description%TYPE           -- �E�v
     ) ;
--
  -- �d������i�[�p���R�[�h�ϐ�
  TYPE rec_vendor_info  IS RECORD(
      vendor_site_id        po_vendor_sites_all.vendor_site_id%TYPE               -- �d���滲�ID
     ,vendor_site_code      po_vendor_sites_all.vendor_site_code%TYPE             -- �d���滲ĺ���
     ,vendor_id             xxcmn_vendors2_v.vendor_id%TYPE                       -- �d����ID
     ,department            xxcmn_vendors2_v.department%TYPE                      -- ����
     ,location_id           hr_all_organization_units.location_id%TYPE            -- �[���掖�Ə�
     ,mtl_organization_id   xxcmn_item_locations_v.mtl_organization_id%TYPE       -- �݌ɑg�DID
    ) ;
--
  -- �i�ڏ��i�[�p���R�[�h�ϐ�
  TYPE rec_item_info  IS RECORD(
      item_no               xxcmn_item_mst_v.item_no%TYPE                         -- �i�ڃR�[�h
     ,frequent_qty          xxcmn_item_mst_v.frequent_qty%TYPE                    -- ��\�݌ɓ���
     ,item_um               xxcmn_item_mst_v.item_um%TYPE                         -- �P��
     ,lot_ctl               xxcmn_item_mst_v.lot_ctl%TYPE                         -- ���b�g
    ) ;
--
  -- �����w�b�_�I�[�v���C���^�[�t�F�[�X�o�^�p���R�[�h�ϐ�
  TYPE rec_po_headers_if  IS RECORD(
      if_header_id         po_headers_interface.interface_header_id%TYPE          -- ����̪��ͯ��ID
     ,batch_id             po_headers_interface.batch_id%TYPE                     -- �o�b�`ID
     ,document_num         po_headers_interface.document_num%TYPE                 -- �����ԍ�
     ,agent_id             po_headers_interface.agent_id%TYPE                     -- �w���S����ID
     ,vendor_id            po_headers_interface.vendor_id%TYPE                    -- �d����ID
     ,vendor_site_id       po_headers_interface.vendor_site_id%TYPE               -- �d����T�C�gID
     ,ship_to_location_id  po_headers_interface.ship_to_location_id%TYPE          -- �[���掖�Ə�ID
     ,bill_to_location_id  po_headers_interface.bill_to_location_id%TYPE          -- �����掖�Ə�ID
     ,delivery_date        po_headers_interface.attribute4%TYPE                   -- �[����
     ,delivery_to_code     po_headers_interface.attribute5%TYPE                   -- �[����R�[�h
     ,shipping_to_code     po_headers_interface.attribute7%TYPE                   -- �z����R�[�h
     ,dept_code            po_headers_interface.attribute10%TYPE                  -- �����R�[�h
     ,header_descript      po_headers_interface.attribute10%TYPE                  -- �w�b�_�E�v
    ) ;
--
  -- �����w�b�_�A�h�I���o�^�p���R�[�h�ϐ�
  TYPE rec_xxpo_headers_if  IS RECORD(
      xxpo_header_id   xxpo_headers_all.xxpo_header_id%TYPE          -- �����w�b�_(�A�h�I��ID)
  ) ;
--
  -- �󒍏��f�[�^�i�[�pPL/SQL�\�^
  TYPE tab_order_info     IS TABLE OF rec_order_info    INDEX BY BINARY_INTEGER ;
--
  -- �������׃I�[�v���C���^�[�t�F�[�X�o�^�pPL/SQL�\�^
  TYPE if_line_id_ttype       IS TABLE OF   po_lines_interface.interface_line_id%TYPE
                                              INDEX BY BINARY_INTEGER;            -- ����̪������ID
  TYPE line_num_ttype         IS TABLE OF   po_lines_interface.line_num%TYPE
                                              INDEX BY BINARY_INTEGER;            -- ���הԍ�
  TYPE item_ttype             IS TABLE OF   po_lines_interface.item%TYPE
                                              INDEX BY BINARY_INTEGER;            -- �i��
  TYPE unit_price_ttype       IS TABLE OF   po_lines_interface.unit_price%TYPE
                                              INDEX BY BINARY_INTEGER;            -- �P��
  TYPE quantity_ttype         IS TABLE OF   po_lines_interface.quantity%TYPE
                                              INDEX BY BINARY_INTEGER;            -- ����
  TYPE uom_code_ttype         IS TABLE OF   po_lines_interface.uom_code%TYPE
                                              INDEX BY BINARY_INTEGER;            -- �P��
  TYPE factory_code_ttype     IS TABLE OF   po_lines_interface.line_attribute2%TYPE
                                              INDEX BY BINARY_INTEGER;            -- �H��R�[�h
  TYPE futai_code_ttype       IS TABLE OF   po_lines_interface.line_attribute3%TYPE
                                              INDEX BY BINARY_INTEGER;            -- �t�уR�[�h
  TYPE frequent_qty_ttype     IS TABLE OF   po_lines_interface.line_attribute4%TYPE
                                              INDEX BY BINARY_INTEGER;            -- �݌ɓ���
  TYPE stocking_price_ttype   IS TABLE OF   po_lines_interface.line_attribute8%TYPE
                                              INDEX BY BINARY_INTEGER;            -- �d���艿
  TYPE order_unit_ttype       IS TABLE OF   po_lines_interface.line_attribute10%TYPE
                                              INDEX BY BINARY_INTEGER;            -- �����P��
  TYPE order_quantity_ttype   IS TABLE OF   po_lines_interface.line_attribute11%TYPE
                                              INDEX BY BINARY_INTEGER;            -- ��������
  TYPE ship_to_org_id_ttype   IS TABLE OF   po_lines_interface.ship_to_organization_id%TYPE
                                              INDEX BY BINARY_INTEGER;            -- �[����g�DID
  TYPE line_description_ttype IS TABLE OF   po_lines_interface.line_attribute15%TYPE
                                              INDEX BY BINARY_INTEGER;            -- �E�v
  TYPE attribute2_ttype IS TABLE OF   po_lines_interface.shipment_attribute2%TYPE
                                              INDEX BY BINARY_INTEGER;            -- ������P��
  TYPE attribute9_ttype IS TABLE OF   po_lines_interface.shipment_attribute9%TYPE
                                              INDEX BY BINARY_INTEGER;            -- ��������z
--
  -- �������׃I�[�v���C���^�[�t�F�[�X�o�^�pPL/SQL�\�^
  TYPE if_distribute_id_ttype IS TABLE OF po_distributions_interface.interface_distribution_id%TYPE
                                              INDEX BY BINARY_INTEGER;        -- ����̪����������ID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  -- �������׃I�[�v���C���^�[�t�F�[�X�o�^�pPL/SQL�\
  tab_if_line_id_ins                        if_line_id_ttype;                     -- ����̪������ID
  tab_line_num_ins                          line_num_ttype;                       -- ���הԍ�
  tab_item_ins                              item_ttype;                           -- �i��
  tab_unit_price_ins                        unit_price_ttype;                     -- �P��
  tab_quantity_ins                          quantity_ttype;                       -- ����
  tab_uom_code_ins                          uom_code_ttype;                       -- �P��
  tab_factory_code_ins                      factory_code_ttype;                   -- �H��R�[�h
  tab_futai_code_ins                        futai_code_ttype;                     -- �t�уR�[�h
  tab_frequent_qty_ins                      frequent_qty_ttype;                   -- �݌ɓ���
  tab_stocking_price_ins                    stocking_price_ttype;                 -- �d���艿
  tab_order_unit_ins                        order_unit_ttype;                     -- �����P��
  tab_order_quantity_ins                    order_quantity_ttype;                 -- ��������
  tab_ship_to_org_id_ins                    ship_to_org_id_ttype;                 -- �[����g�DID
  tab_line_description_ins                  line_description_ttype;               -- �E�v
  tab_attribute2_ins                        attribute2_ttype;                     -- ������P��
  tab_attribute9_ins                        attribute9_ttype;                     -- ��������z
--
  -- �������׃I�[�v���C���^�[�t�F�[�X�o�^�pPL/SQL�\
  tab_if_distribute_id_ins                  if_distribute_id_ttype;           -- ����̪����������ID
--
  gv_request_no       xxwsh_order_headers_all.request_no%TYPE ;               -- �˗�No
  gi_cnt              PLS_INTEGER ;                                           -- ���[�v�J�E���g
--
  -- ���O�C�����[�U�]�ƈ����
  gn_emp_id           xxpo_per_all_people_f_v.person_id%TYPE DEFAULT FND_GLOBAL.EMPLOYEE_ID;
  -- �v�g�n�J�������
    -- �쐬��ID
  gn_user_id          po_headers_interface.created_by%TYPE DEFAULT FND_GLOBAL.USER_ID;
    -- ���O�C��ID
  gn_login_id         po_headers_interface.last_update_login%TYPE DEFAULT FND_GLOBAL.LOGIN_ID;
    -- �v��ID
  gn_request_id       po_headers_interface.request_id%TYPE DEFAULT FND_GLOBAL.CONC_REQUEST_ID;
    -- �A�v���P�[�V����ID
  gn_prog_appl_id po_headers_interface.program_application_id%TYPE DEFAULT FND_GLOBAL.PROG_APPL_ID;
    -- �v���O����ID
  gn_conc_program_id  po_headers_interface.program_id%TYPE DEFAULT FND_GLOBAL.CONC_PROGRAM_ID;
--
  -- �V�X�e������
  gd_sysdate          DATE DEFAULT SYSDATE;                                   -- �V�X�e������
--
    -- ���׃^�C�vID
  gn_line_type_id  po_lines_interface.line_type_id%TYPE;
    -- �c�ƒS��ID
  gn_org_id        po_headers_interface.org_id%TYPE;
  -- ========================================
  -- �O���[�o���E�J�[�\�� �i���b�N�p�J�[�\��)
  -- ========================================
  CURSOR cur_order_info(
      iv_request_no       xxwsh_order_headers_all.request_no%TYPE
    )
  IS
    SELECT xoha.order_header_id             AS  order_header_id           -- �󒍃w�b�_�A�h�I��ID
          ,xoha.shipping_instructions       AS  shipping_instructions     -- �o�׎w��
          ,xoha.schedule_ship_date          AS  schedule_ship_date        -- �o�ח\���
          ,xoha.deliver_from                AS  deliver_from              -- �o�׌��ۊǏꏊ
          ,xoha.vendor_id                   AS  vendor_id                 -- �����ID
          ,xoha.vendor_site_code            AS  vendor_site_code          -- �����T�C�g
          ,xola.shipping_inventory_item_id  AS  shipping_inv_item_id      -- �o�וi��ID
          ,xola.shipping_item_code          AS  shipping_item_code        -- �o�וi��
          ,xola.quantity                    AS  quantity                  -- ����
          ,NVL(xola.futai_code, gv_zero)    AS  futai_code                -- �t�уR�[�h
          ,xola.line_description            AS  line_description          -- �E�v
    FROM   xxwsh_order_headers_all    xoha                                -- �󒍃w�b�_�A�h�I��
          ,xxwsh_order_lines_all      xola                                -- �󒍖��׃A�h�I��
          ,oe_transaction_types_all   otta                                -- �󒍃^�C�v
    WHERE  xoha.order_type_id       = otta.transaction_type_id            -- �󒍃^�C�vID
    AND    otta.attribute1          = gv_provision_request                -- �o�׎x���敪
    AND    otta.attribute3          = gv_object                           -- ���������쐬�敪
    AND    xoha.req_status          = gv_received                         -- �X�e�[�^�X
    AND    xoha.request_no          = iv_request_no                       -- �˗�No
    AND    xoha.order_header_id     = xola.order_header_id                -- �󒍃w�b�_�A�h�I��ID
    ORDER BY xola.order_line_number                                       -- ���הԍ�
    FOR UPDATE NOWAIT
  ;
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION ;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION ;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  �Œ蕔 END   ############################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  lock_expt              EXCEPTION;        -- ���b�N�擾��O
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ���b�N�擾��O
--
   /**********************************************************************************
   * Function Name    : create_reserve_data
   * Description      : �������쐬����
   ***********************************************************************************/
  FUNCTION create_reserve_data(
       in_order_header_id    IN  NUMBER         -- �󒍃w�b�_�A�h�I��ID
   )
  RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'create_reserve_data';      --�v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���E�萔 ***
    cv_doc_type_code  CONSTANT  xxinv_mov_lot_details.document_type_code%TYPE := '30';  -- �x���w��
    cv_rec_type_code  CONSTANT  xxinv_mov_lot_details.record_type_code%TYPE   := '10';  -- �w��
--
  BEGIN
    -- ===============================
    -- �ړ����b�g�ڍדo�^
    -- ===============================
    -- �p�����[�^�̎󒍃w�b�_�ɕR�Â��󒍖��ׂ��ƂɈړ����b�g�ڍׂփ��R�[�h�^�C�v�u10�F�w���v
    -- �̃f�[�^��o�^����B
    INSERT INTO xxinv_mov_lot_details                                       -- �ړ����b�g�ڍ�
              ( mov_lot_dtl_id                                              -- ���b�g�ڍ�ID
               ,mov_line_id                                                 -- ����ID
               ,document_type_code                                          -- �����^�C�v
               ,record_type_code                                            -- ���R�[�h�^�C�v
               ,item_id                                                     -- OPM�i��ID
               ,item_code                                                   -- �i��
               ,lot_id                                                      -- ���b�gID
               ,lot_no                                                      -- ���b�gNo
               ,actual_date                                                 -- ���ѓ�
               ,actual_quantity                                             -- ���ѐ���
               ,created_by                                                  -- �쐬��
               ,creation_date                                               -- �쐬��
               ,last_updated_by                                             -- �ŏI�X�V��
               ,last_update_date                                            -- �ŏI�X�V��
               ,last_update_login )                                         -- �ŏI�X�V���O�C��
        SELECT  xxinv_mov_lot_s1.NEXTVAL                                    -- �ړ����b�g�ڍ׎��ʗp
               ,xola.order_line_id                                          -- �󒍖��׃A�h�I��ID
               ,cv_doc_type_code                                            -- �����^�C�v:�x���w��
               ,cv_rec_type_code                                            -- ���R�[�h�^�C�v:�w��
               ,xitm.item_id                                                -- OPM�i��ID
               ,xitm.item_no                                                -- �i��
               ,opml.lot_id                                                 -- ���b�gID
               ,NULL                                                        -- ���b�gNo
               ,NULL                                                        -- ���ѓ�
               ,xola.quantity                                               -- ���ѐ���
               ,gn_user_id                                                  -- �쐬��
               ,gd_sysdate                                                  -- �쐬��
               ,gn_user_id                                                  -- �ŏI�X�V��
               ,gd_sysdate                                                  -- �ŏI�X�V��
               ,gn_login_id                                                 -- �ŏI�X�V���O�C��
        FROM    xxwsh_order_headers_all   xoha                              -- �󒍃w�b�_�A�h�I��
               ,xxwsh_order_lines_all     xola                              -- �󒍖��׃A�h�I��
               ,xxcmn_item_mst_v          xitm                              -- OPM�i�ڏ��VIEW
               ,ic_lots_mst               opml                              -- OPM���b�g�}�X�^
        WHERE   xoha.order_header_id    = in_order_header_id                -- �󒍃w�b�_�A�h�I��ID
        AND     xola.order_header_id    = xoha.order_header_id              -- �󒍃w�b�_�A�h�I��ID
        AND     xitm.inventory_item_id  = xola.shipping_inventory_item_id   -- INV�i��ID
        AND     opml.item_id            = xitm.item_id                      -- �i��ID
    ;
--
    -- ===============================
    -- �󒍖��׃A�h�I���X�V
    -- ===============================
    -- �p�����[�^�̎󒍃w�b�_�A�h�I��ID�ɕR�t���󒍖��׃A�h�I���̈��������w�����ōX�V����B
    UPDATE xxwsh_order_lines_all          xola                            -- �󒍖��׃A�h�I��
    SET    xola.reserved_quantity       = xola.quantity                   -- �������Ɏw�������Z�b�g
          ,xola.last_updated_by         = gn_user_id                      -- �ŏI�X�V��
          ,xola.last_update_date        = gd_sysdate                      -- �ŏI�X�V��
          ,xola.last_update_login       = gn_login_id                     -- �ŏI�X�V���O�C��
    WHERE  xola.order_header_id         = in_order_header_id              -- �󒍃w�b�_�A�h�I��ID
    AND    NVL(xola.delete_flag, gv_no) = gv_no                           -- �폜�t���OOFF
    ;
--
    --�X�e�[�^�X�Z�b�g
    RETURN gv_status_normal;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
      RETURN gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_reserve_data;
--
  /**********************************************************************************
   * Procedure Name   : prc_check_param_info
   * Description      : �p�����[�^�`�F�b�N(A-1)
   ***********************************************************************************/
  PROCEDURE prc_check_param_info(
      iv_request_no         IN          VARCHAR2         -- �˗�No
     ,ov_retcode            OUT         VARCHAR2         -- ���^�[���E�R�[�h
     ,ov_errmsg_code        OUT         VARCHAR2         -- �G���[�E���b�Z�[�W�E�R�[�h
     ,ov_errmsg             OUT         VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_param_info' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ln_ret_num                NUMBER ;        -- ���ʊ֐��߂�l�F���l�^
    lv_err_code               VARCHAR2(20) ;  -- �G���[�R�[�h�i�[�p
    lv_token_value1           VARCHAR2(20) ;  -- �g�[�N���i�[�p
--
    -- *** ���[�J���萔 ***
    cv_request_no             CONSTANT VARCHAR2(20) := '�˗�No' ;     -- �˗�No
--
    -- *** ���[�J���E��O���� ***
    parameter_check_expt      EXCEPTION ;     -- �p�����[�^�`�F�b�N��O
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �˗�No
    -- ====================================================
    -- �K�{�`�F�b�N
    IF (iv_request_no IS NULL) THEN
      lv_err_code     := 'APP-XXPO-10102' ;
      lv_token_value1 := cv_request_no ;
      RAISE parameter_check_expt ;
    END IF ;
--
    -- ���׃^�C�vID�擾
    gn_line_type_id       := FND_PROFILE.VALUE( 'XXPO_PO_LINE_TYPE_ID' ) ;
    -- �c�ƒS��ID
    gn_org_id             := FND_PROFILE.VALUE( 'ORG_ID' ) ;
--
  EXCEPTION
    --*** �p�����[�^�`�F�b�N��O ***
    WHEN parameter_check_expt THEN
      ov_retcode      :=  gv_status_error;
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg       :=  xxcmn_common_pkg.get_msg(
                            iv_application   => gc_application_po,
                            iv_name          => lv_err_code,
                            iv_token_name1   => 'PARAM_NAME',
                            iv_token_value1  => lv_token_value1);     -- ���b�Z�[�W�擾
      ov_errmsg       :=  lv_errmsg;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_retcode      :=  gv_status_error;
      ov_errmsg       :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_check_param_info ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_order_info
   * Description      : �󒍏�񒊏o�擾(A-2)
   ***********************************************************************************/
  PROCEDURE prc_get_order_info(
      ot_data_rec           OUT         tab_order_info   -- �擾���R�[�h�Q
     ,ov_retcode            OUT         VARCHAR2         -- ���^�[���E�R�[�h
     ,ov_errmsg_code        OUT         VARCHAR2         -- �G���[�E���b�Z�[�W�E�R�[�h
     ,ov_errmsg             OUT         VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_order_info'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���E�萔 ***
    cv_xoha                 CONSTANT VARCHAR2(20) := '�󒍃w�b�_�A�h�I��' ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    -- �J�[�\���I�[�v��
    OPEN cur_order_info(
      gv_request_no) ;               -- �˗�No
    -- �o���N�t�F�b�`
    FETCH cur_order_info BULK COLLECT INTO ot_data_rec ;
--
    IF ( ot_data_rec.COUNT = 0 ) THEN       -- �擾�f�[�^���O���̏ꍇ
      lv_errmsg  := xxcmn_common_pkg.get_msg(
                          iv_application   => gc_application_po,
                          iv_name          => 'APP-XXPO-10026',
                          iv_token_name1   => 'TABLE',
                          iv_token_value1  => cv_xoha);         -- ���b�Z�[�W�擾
      ov_errmsg  := lv_errmsg ;
      ov_retcode := gv_status_error ;
    END IF ;
--
  EXCEPTION
     --*** ���b�N�擾�G���[ ***
    WHEN lock_expt THEN
      IF (cur_order_info%ISOPEN) THEN
        CLOSE cur_order_info ;
      END IF ;
      lv_errmsg := xxcmn_common_pkg.get_msg(
                          iv_application   => gc_application_po,
                          iv_name          => 'APP-XXPO-10027',
                          iv_token_name1   => 'TABLE',
                          iv_token_value1  => cv_xoha);         -- ���b�Z�[�W�擾
      ov_errmsg  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (cur_order_info%ISOPEN) THEN
        CLOSE cur_order_info ;
      END IF ;
      ov_retcode      :=  gv_status_error;
      ov_errmsg       :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (cur_order_info%ISOPEN) THEN
        CLOSE cur_order_info ;
      END IF ;
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (cur_order_info%ISOPEN) THEN
        CLOSE cur_order_info ;
      END IF ;
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_order_info ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_vendor_info
   * Description      : �d������擾(A-3)
   ***********************************************************************************/
  PROCEDURE prc_get_vendor_info(
      ir_order_info         IN          rec_order_info   -- �󒍏�񃌃R�[�h
     ,or_vendor_info        OUT         rec_vendor_info  -- �d�����񃌃R�[�h
     ,ov_retcode            OUT         VARCHAR2         -- ���^�[���E�R�[�h
     ,ov_errmsg_code        OUT         VARCHAR2         -- �G���[�E���b�Z�[�W�E�R�[�h
     ,ov_errmsg             OUT         VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_vendor_info'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���E�萔 ***
    cv_po_vendor_sites_all   CONSTANT VARCHAR2(20) := '�d����T�C�g�}�X�^' ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    SELECT pvsa.vendor_site_id        AS  vendor_site_id                    -- �d����T�C�gID
          ,pvsa.vendor_site_code      AS  vendor_site_code                  -- �d����T�C�g�R�[�h
          ,xv2v.vendor_id             AS  vendor_id                         -- �d����ID
          ,xv2v.department            AS  department                        -- ����
          ,xilv.location_id           AS  location_id                       -- �[���掖�Ə�
          ,xilv.mtl_organization_id   AS  mtl_organization_id               -- �݌ɑg�DID
    INTO   or_vendor_info.vendor_site_id
          ,or_vendor_info.vendor_site_code
          ,or_vendor_info.vendor_id
          ,or_vendor_info.department
          ,or_vendor_info.location_id
          ,or_vendor_info.mtl_organization_id
    FROM   po_vendor_sites_all            pvsa                              -- �d����T�C�g�}�X�^
          ,xxcmn_vendors2_v               xv2v                              -- �d������VIEW2
          ,xxcmn_item_locations_v         xilv                              -- OPM�ۊǏꏊ���VIEW
    WHERE  xilv.segment1                = ir_order_info.deliver_from        -- �ۊǑq�ɃR�[�h
    AND    xilv.purchase_code           = xv2v.segment1                     -- �d����R�[�h
    AND  ((xilv.purchase_site_code IS NOT NULL
      AND  xilv.purchase_site_code      = pvsa.vendor_site_code)            -- �d����T�C�g�R�[�h
    OR    (xilv.purchase_site_code IS NULL
      AND  xv2v.frequent_factory        = pvsa.vendor_site_code))           -- �d����T�C�g�R�[�h
    AND    xv2v.vendor_id               = pvsa.vendor_id                    -- �d����ID
    AND    xv2v.inactive_date IS NULL                                       -- ������
    AND   (ir_order_info.schedule_ship_date                                 -- �o�ח\���
             BETWEEN  xv2v.start_date_active  AND  xv2v.end_date_active)    -- �K�p�J�n�E�I����
    ;
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN NO_DATA_FOUND THEN
      ov_retcode      :=  gv_status_error;
      lv_errmsg       :=  xxcmn_common_pkg.get_msg(
                            iv_application   => gc_application_po,
                            iv_name          => 'APP-XXPO-10026',
                            iv_token_name1   => 'TABLE',
                            iv_token_value1  => cv_po_vendor_sites_all);    -- ���b�Z�[�W�擾
      ov_errmsg       :=  lv_errmsg;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_retcode      :=  gv_status_error;
      ov_errmsg       :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_vendor_info ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_item_info
   * Description      : �i�ڏ��擾(A-4)
   ***********************************************************************************/
  PROCEDURE prc_get_item_info(
      ir_order_info         IN          rec_order_info   -- �󒍏�񃌃R�[�h
     ,or_item_info          OUT         rec_item_info    -- �i�ڏ�񃌃R�[�h
     ,ov_retcode            OUT         VARCHAR2         -- ���^�[���E�R�[�h
     ,ov_errmsg_code        OUT         VARCHAR2         -- �G���[�E���b�Z�[�W�E�R�[�h
     ,ov_errmsg             OUT         VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_item_info'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���E�萔 ***
    cv_system_items_b       CONSTANT VARCHAR2(20) := '�i�ڃ}�X�^' ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    SELECT ximv.item_no               AS  item_no                             -- �i�ڃR�[�h
          ,ximv.frequent_qty          AS  frequent_qty                        -- ��\�݌ɓ���
          ,ximv.item_um               AS  item_um                             -- �P��
          ,ximv.lot_ctl               AS  lot_ctl                             -- ���b�g
    INTO   or_item_info.item_no
          ,or_item_info.frequent_qty
          ,or_item_info.item_um
          ,or_item_info.lot_ctl
    FROM   xxcmn_item_mst_v           ximv                                    -- OPM�i�ڏ��VIEW
    WHERE  ximv.inventory_item_id   = ir_order_info.shipping_inv_item_id      -- �o�וi��ID
    ;
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN NO_DATA_FOUND THEN
      ov_retcode      :=  gv_status_error;
      lv_errmsg       :=  xxcmn_common_pkg.get_msg(
                            iv_application   => gc_application_po,
                            iv_name          => 'APP-XXPO-10026',
                            iv_token_name1   => 'TABLE',
                            iv_token_value1  => cv_system_items_b);           -- ���b�Z�[�W�擾
      ov_errmsg       :=  lv_errmsg;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_retcode      :=  gv_status_error;
      ov_errmsg       :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_item_info ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_price
   * Description      : �P���擾(A-6)
   ***********************************************************************************/
  PROCEDURE prc_get_price(
      ir_order_info       IN          rec_order_info                          -- �󒍏�񃌃R�[�h
     ,ir_vendor_info      IN          rec_vendor_info                         -- �d�����񃌃R�[�h
     ,on_total_amount     OUT         XXPO_PRICE_HEADERS.total_amount%TYPE    -- ���󍇌v
     ,ov_retcode          OUT         VARCHAR2                                -- ���^�[���E�R�[�h
     ,ov_errmsg_code      OUT         VARCHAR2                                -- �װ�Eү���ށE����
     ,ov_errmsg           OUT         VARCHAR2                                -- �G���[�E���b�Z�[�W
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_price'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���E�萔 ***
    cv_price_headers        CONSTANT VARCHAR2(20) := '�d��/�W���P���w�b�_' ;
    cv_price_type           CONSTANT VARCHAR2(1)  := '1' ;                   -- �d���P���f�[�^
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    SELECT xph.total_amount                AS  total_amount                  -- ���󍇌v
    INTO   on_total_amount
    FROM   xxpo_price_headers              xph                               -- �d��/�W���P���w�b�_
    WHERE  xph.price_type               =  cv_price_type                     -- �d���P���f�[�^
    AND    xph.item_code                =  ir_order_info.shipping_item_code  -- �i�ڃR�[�h=�o�וi��
    AND    NVL(xph.futai_code, gv_zero) =  ir_order_info.futai_code          -- �t�уR�[�h
    AND    xph.vendor_id                =  ir_vendor_info.vendor_id          -- �����ID=�d����ID
    AND    xph.factory_id               =  ir_vendor_info.vendor_site_id     -- �H��ID=�d���滲�ID
    AND    xph.supply_to_id             =  ir_order_info.vendor_id           -- �x����ID=�����ID
    AND   (ir_order_info.schedule_ship_date                                  -- �o�ח\���
             BETWEEN  xph.start_date_active  AND  xph.end_date_active)       -- �K�p�J�n�E�I����
    ;
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN NO_DATA_FOUND THEN
      ov_retcode      :=  gv_status_error;
      lv_errmsg       :=  xxcmn_common_pkg.get_msg(
                            iv_application   => gc_application_po,
                            iv_name          => 'APP-XXPO-10026',
                            iv_token_name1   => 'TABLE',
                            iv_token_value1  => cv_price_headers);           -- ���b�Z�[�W�擾
      ov_errmsg       :=  lv_errmsg;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_retcode      :=  gv_status_error;
      ov_errmsg       :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_price ;
--
  /**********************************************************************************
   * Procedure Name   : prc_ins_interface_header
   * Description      : �����w�b�_�o�^(A-7)
   ***********************************************************************************/
  PROCEDURE prc_ins_interface_header(
      ir_order_info      IN       rec_order_info    -- �󒍏�񃌃R�[�h
     ,ir_vendor_info     IN       rec_vendor_info   -- �d�����񃌃R�[�h
     ,or_po_headers_if   OUT      rec_po_headers_if -- �����w�b�_�I�[�v���C���^�[�t�F�[�X���R�[�h
     ,or_xxpo_headers_if OUT      rec_xxpo_headers_if  -- �����w�b�_�A�h�I�����R�[�h
     ,ov_retcode         OUT      VARCHAR2          -- ���^�[���E�R�[�h
     ,ov_errmsg_code     OUT      VARCHAR2          -- �G���[�E���b�Z�[�W�E�R�[�h
     ,ov_errmsg          OUT      VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_ins_interface_header'; -- �v���O������
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
    -- *** ���[�J���E�萔 ***
    cv_po_headers_interface CONSTANT VARCHAR2(30) := '�����w�b�_�C���^�[�t�F�[�XID' ;
    cv_xxpo_headers_id      CONSTANT VARCHAR2(30) := '�����w�b�_(�A�h�I��ID)';
    cv_po_no                CONSTANT VARCHAR2(10) := '�����ԍ�' ;
    cv_seq_class            CONSTANT VARCHAR2(2)  := '2'; -- ���ԋ敪�F�����ԍ�(xxcmn_order_no_s1)
    cv_agent_id             CONSTANT VARCHAR2(20) := '�w���S����ID';
--
    -- *** ���[�J���E�ϐ� ***
    lv_agent_id             fnd_profile_option_values.profile_option_value%TYPE ; -- �w���S����ID
--
    -- *** ���[�J���E��O���� ***
    get_user_error_expt       EXCEPTION ;  -- �̔ԃG���[�E�v���t�@�C���擾�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==============================================================
    -- �����w�b�_�C���^�t�F�[�X�V�[�P���X����l���擾
    -- ==============================================================
    BEGIN
      SELECT po_headers_interface_s.NEXTVAL
      INTO or_po_headers_if.if_header_id                                   -- ����̪��ͯ��ID
      FROM dual;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                          iv_application   => gc_application_cmn,
                          iv_name          => 'APP-XXCMN-10029',
                          iv_token_name1   => 'SEQ_NAME',
                          iv_token_value1  => cv_po_headers_interface);    -- ���b�Z�[�W�擾
        RAISE get_user_error_expt;
    END;
--
    -- ==============================================================
    -- �����w�b�_�i�A�h�I���j�V�[�P���X����l���擾
    -- ==============================================================
    BEGIN
      SELECT xxpo_headers_all_s1.NEXTVAL
      INTO or_xxpo_headers_if.xxpo_header_id               -- �����A�h�I��ID
      FROM dual;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                          iv_application   => gc_application_cmn,
                          iv_name          => 'APP-XXCMN-10029',
                          iv_token_name1   => 'SEQ_NAME',
                          iv_token_value1  => cv_xxpo_headers_id); -- ���b�Z�[�W�擾
        RAISE get_user_error_expt;
    END;
--
    -- ==============================================================
    -- �����ԍ����擾(�̔Ԋ֐�)
    -- ==============================================================
    xxcmn_common_pkg.get_seq_no(
        iv_seq_class      => cv_seq_class                   -- �̔Ԃ���ԍ���\���敪
       ,ov_seq_no         => or_po_headers_if.document_num  -- �����ԍ�(�̔Ԃ����Œ蒷12���̔ԍ�)
       ,ov_errbuf         => lv_errbuf                      -- �G���[�E���b�Z�[�W
       ,ov_retcode        => lv_retcode                     -- ���^�[���E�R�[�h
       ,ov_errmsg         => lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W
      ) ;
    IF (lv_retcode = gv_status_error OR or_po_headers_if.document_num IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                        iv_application   => gc_application_cmn,
                        iv_name          => 'APP-XXCMN-10029',
                        iv_token_name1   => 'SEQ_NAME',
                        iv_token_value1  => cv_po_no);                     -- ���b�Z�[�W�擾
      RAISE get_user_error_expt;
    END IF ;
--
    -- ====================================================
    -- �w���S����ID
    -- ====================================================
    lv_agent_id       := FND_PROFILE.VALUE( 'XXPO_PURCHASE_EMP_ID' ) ;
    IF ( lv_agent_id IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
      iv_application   => gc_application_cmn,
        iv_name          => 'APP-XXCMN-10002',
        iv_token_name1   => 'NG_PROFILE',
        iv_token_value1  => cv_agent_id);                                  -- ���b�Z�[�W�擾
      RAISE get_user_error_expt;
    END IF ;
--
    -- ==============================================================
    -- �����w�b�_�C���^�[�t�F�C�X�o�^�f�[�^�쐬
    -- ==============================================================
    or_po_headers_if.batch_id   :=  TO_NUMBER(TO_CHAR(or_po_headers_if.if_header_id)
                                 || TO_CHAR(or_po_headers_if.document_num));      -- �o�b�`ID
    or_po_headers_if.agent_id         :=  TO_NUMBER(lv_agent_id);                 -- �w���S����ID
    or_po_headers_if.vendor_id        :=  ir_vendor_info.vendor_id;               -- �d����ID
    or_po_headers_if.vendor_site_id   :=  ir_vendor_info.vendor_site_id;          -- �d����T�C�gID
    or_po_headers_if.ship_to_location_id  :=  ir_vendor_info.location_id;         -- �[���掖�Ə�ID
    or_po_headers_if.bill_to_location_id  :=  ir_vendor_info.location_id;         -- �����掖�Ə�ID
    or_po_headers_if.delivery_date    :=  ir_order_info.schedule_ship_date;       -- �o�ח\���
    or_po_headers_if.delivery_to_code :=  ir_order_info.deliver_from;             -- �o�׌��ۊǏꏊ
    or_po_headers_if.shipping_to_code :=  ir_order_info.vendor_site_code;         -- �����T�C�g
    or_po_headers_if.dept_code        :=  ir_vendor_info.department;              -- �����R�[�h
    or_po_headers_if.header_descript  :=  ir_order_info.shipping_instructions;    -- �w�b�_�E�v
--
  EXCEPTION
    --*** �̔ԃG���[�E�v���t�@�C���擾�G���[ ***
    WHEN get_user_error_expt THEN
      -- ���b�Z�[�W�Z�b�g
      ov_retcode      :=  gv_status_error;
      ov_errmsg       :=  lv_errmsg;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_retcode      :=  gv_status_error;
      ov_errmsg       :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_ins_interface_header ;
--
  /**********************************************************************************
   * Procedure Name   : prc_ins_interface_lines
   * Description      : ����(����)���דo�^(A-8)
   ***********************************************************************************/
  PROCEDURE prc_ins_interface_lines(
      ir_order_info         IN          rec_order_info                        -- �󒍏�񃌃R�[�h
     ,ir_vendor_info        IN          rec_vendor_info                       -- �d�����񃌃R�[�h
     ,ir_item_info          IN          rec_item_info                         -- �i�ڏ�񃌃R�[�h
     ,in_total_amount       IN          XXPO_PRICE_HEADERS.total_amount%TYPE  -- ���󍇌v
     ,ov_retcode            OUT         VARCHAR2                              -- ���^�[���E�R�[�h
     ,ov_errmsg_code        OUT         VARCHAR2                              -- �װ�Eү���ށE����
     ,ov_errmsg             OUT         VARCHAR2                              -- �G���[�E���b�Z�[�W
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_ins_interface_lines'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���E�萔 ***
    cv_po_lines_interface         CONSTANT VARCHAR2(30) := '�������׃C���^�[�t�F�[�XID' ;
    cv_po_distributions_interface CONSTANT VARCHAR2(30) := '�������׃C���^�[�t�F�[�XID' ;
--
    -- *** ���[�J���E��O���� ***
    get_sequence_expt      EXCEPTION ;     -- �̔ԃG���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==============================================================
    -- �������׃C���^�t�F�[�X�V�[�P���X����l���擾
    -- ==============================================================
    BEGIN
      SELECT po_lines_interface_s.NEXTVAL
      INTO tab_if_line_id_ins(gi_cnt)                                         -- ����̪������ID
      FROM dual;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                          iv_application   => gc_application_cmn,
                          iv_name          => 'APP-XXCMN-10029',
                          iv_token_name1   => 'SEQ_NAME',
                          iv_token_value1  => cv_po_lines_interface);         -- ���b�Z�[�W�擾
        RAISE get_sequence_expt;
    END;
--
    -- ==============================================================
    -- �������׃C���^�[�t�F�C�X�o�^�f�[�^�쐬
    -- ==============================================================
    tab_line_num_ins(gi_cnt)          :=  gi_cnt;                             -- ���הԍ�
    tab_item_ins(gi_cnt)              :=  ir_item_info.item_no;               -- �i��
    tab_unit_price_ins(gi_cnt)        :=  in_total_amount;                    -- �P��
    tab_quantity_ins(gi_cnt)          :=  ir_order_info.quantity;             -- ����
    tab_uom_code_ins(gi_cnt)          :=  ir_item_info.item_um;               -- �P��
    tab_factory_code_ins(gi_cnt)      :=  ir_vendor_info.vendor_site_code;    -- �H��R�[�h
    tab_futai_code_ins(gi_cnt)        :=  ir_order_info.futai_code;           -- �t�уR�[�h
    tab_frequent_qty_ins(gi_cnt)      :=  ir_item_info.frequent_qty;          -- �݌ɓ���
    tab_stocking_price_ins(gi_cnt)    :=  in_total_amount;                    -- �d���艿
    tab_order_unit_ins(gi_cnt)        :=  ir_item_info.item_um;               -- �����P��
    tab_order_quantity_ins(gi_cnt)    :=  ir_order_info.quantity;             -- ��������
    tab_ship_to_org_id_ins(gi_cnt)    :=  ir_vendor_info.mtl_organization_id; -- �[����g�DID
    tab_line_description_ins(gi_cnt)  :=  ir_order_info.line_description;     -- �E�v
    tab_attribute2_ins(gi_cnt)        :=  in_total_amount;                    -- ������P��
    tab_attribute9_ins(gi_cnt)        :=  in_total_amount * ir_order_info.quantity;   -- ��������z
--
    -- ==============================================================
    -- �������׃C���^�t�F�[�X�V�[�P���X����l���擾
    -- ==============================================================
    BEGIN
      SELECT po_distributions_interface_s.NEXTVAL
      INTO tab_if_distribute_id_ins(gi_cnt)                                   -- ����̪����������ID
      FROM dual;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                          iv_application   => gc_application_cmn,
                          iv_name          => 'APP-XXCMN-10029',
                          iv_token_name1   => 'SEQ_NAME',
                          iv_token_value1  => cv_po_distributions_interface); -- ���b�Z�[�W�擾
        RAISE get_sequence_expt;
    END;
--
  EXCEPTION
    --*** �̔ԃG���[ ***
    WHEN get_sequence_expt THEN
      -- ���b�Z�[�W�Z�b�g
      ov_retcode      :=  gv_status_error;
      ov_errmsg       :=  lv_errmsg;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_retcode      :=  gv_status_error;
      ov_errmsg       :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_ins_interface_lines ;
--
  /**********************************************************************************
   * Procedure Name   : prc_regist_all
   * Description      : �o�^�X�V����(A-9)
   ***********************************************************************************/
  PROCEDURE prc_regist_all(
      ir_po_headers_if      IN  rec_po_headers_if     -- �����w�b�_�I�[�v���C���^�[�t�F�[�X���R�[�h
     ,ir_xxpo_headers_if    IN  rec_xxpo_headers_if
     ,in_order_header_id    IN  xxwsh_order_headers_all.order_header_id%TYPE     -- ��ͯ�ޱ�޵�ID
     ,ov_retcode            OUT VARCHAR2              -- ���^�[���E�R�[�h
     ,ov_errmsg_code        OUT VARCHAR2              -- �G���[�E���b�Z�[�W�E�R�[�h
     ,ov_errmsg             OUT VARCHAR2              -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_regist_all'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���E�萔 ***
    cv_process_code   CONSTANT po_headers_interface.process_code%TYPE    := 'PENDING';  -- ��������
    cv_action         CONSTANT po_headers_interface.action%TYPE          := 'ORIGINAL'; -- �����敪
    cv_standard    CONSTANT po_headers_interface.document_type_code%TYPE := 'STANDARD'; -- �W������
    cv_approval_sts   CONSTANT po_headers_interface.approval_status%TYPE := 'APPROVED';-- ���F�ð��
    cv_po_add_status  CONSTANT po_headers_interface.attribute1%TYPE    := '20';-- �ð��(�����쐬��)
    cv_drop_ship_type CONSTANT po_headers_interface.attribute6%TYPE    := '3'; -- �����敪(�x��)
    cv_po_type        CONSTANT po_headers_interface.attribute11%TYPE   := '1'; -- �����敪(�V�K)
    cn_recovery_rate  CONSTANT po_distributions_interface.recovery_rate%TYPE := 100;
--
    -- *** ���[�J���E�ϐ� ***
    cn_emp_num        per_all_people_f.employee_number%TYPE;
    li_cnt            PLS_INTEGER ;                                      -- ���[�v�J�E���g
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==============================
    -- ���O�C�����[�U���擾
    -- ==============================
    BEGIN
      SELECT  xpav.employee_number
        INTO  cn_emp_num
        FROM  xxpo_per_all_people_f_v  xpav
       WHERE  person_id = gn_emp_id;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
--
    -- ==============================================================
    -- �����w�b�_�C���^�t�F�[�X�ɒǉ�
    -- ==============================================================
    BEGIN
      INSERT INTO po_headers_interface(
        interface_header_id,                                      -- �C���^�[�t�F�[�X�w�b�_ID
        batch_id,                                                 -- �o�b�`ID
        process_code,                                             -- �����R�[�h
        action,                                                   -- �����敪
        org_id,                                                   -- �c�ƒS��ID
        document_type_code,                                       -- �����^�C�v�R�[�h
        document_num,                                             -- �����ԍ�(�����ԍ�)
        agent_id,                                                 -- �w���S����ID
        vendor_id,                                                -- �d����ID
        vendor_site_id,                                           -- �d����T�C�gID
        ship_to_location_id,                                      -- �[���掖�Ə�ID
        bill_to_location_id,                                      -- �����掖�Ə�ID
        approval_status,                                          -- ���F�X�e�[�^�X
        attribute1,                                               -- �X�e�[�^�X
        attribute2,                                               -- �d���揳���v�t���O
        attribute4,                                               -- �[����
        attribute5,                                               -- �[����R�[�h
        attribute6,                                               -- �����敪
        attribute7,                                               -- �z����R�[�h
        attribute9,                                               -- �˗��ԍ�
        attribute10,                                              -- �����R�[�h
        attribute11,                                              -- �����敪
        attribute15,                                              -- �w�b�_�E�v
        creation_date,                                            -- �쐬��
        created_by,                                               -- �쐬��ID
        last_update_date,                                         -- �ŏI�X�V��
        last_updated_by,                                          -- �ŏI�X�V��ID
        last_update_login,                                        -- �ŏI�X�V���O�C��ID
        request_id,                                               -- �v��ID
        program_application_id,                                   -- �v���O�����A�v���P�[�V����ID
        program_id,                                               -- �v���O����ID
        program_update_date,                                      -- �v���O�����X�V��
        load_sourcing_rules_flag
        )
      VALUES
        (
        ir_po_headers_if.if_header_id,                            -- �C���^�[�t�F�[�X�w�b�_ID
        ir_po_headers_if.batch_id,                                -- �o�b�`ID
        cv_process_code,                                          -- �����R�[�h
        cv_action,                                                -- �����敪
        gn_org_id,                                                -- �c�ƒS��ID
        cv_standard,                                              -- �����^�C�v�R�[�h
        ir_po_headers_if.document_num,                            -- �����ԍ�(�����ԍ�)
        ir_po_headers_if.agent_id,                                -- �w���S����ID
        ir_po_headers_if.vendor_id,                               -- �d����ID
        ir_po_headers_if.vendor_site_id,                          -- �d����T�C�gID
        ir_po_headers_if.ship_to_location_id,                     -- �[���掖�Ə�ID
        ir_po_headers_if.bill_to_location_id,                     -- �����掖�Ə�ID
        cv_approval_sts,                                          -- ���F�X�e�[�^�X
        cv_po_add_status,                                         -- �X�e�[�^�X
        gv_no,                                                    -- �d���揳���v�t���O
        ir_po_headers_if.delivery_date,                           -- �[����
        ir_po_headers_if.delivery_to_code,                        -- �[����R�[�h
        cv_drop_ship_type,                                        -- �����敪
        ir_po_headers_if.shipping_to_code,                        -- �z����R�[�h
        gv_request_no,                                            -- �˗��ԍ�
        ir_po_headers_if.dept_code,                               -- �����R�[�h
        cv_po_type,                                               -- �����敪
        ir_po_headers_if.header_descript,                         -- �w�b�_�E�v
        gd_sysdate,                                               -- �쐬��
        gn_user_id,                                               -- �쐬��ID
        gd_sysdate,                                               -- �ŏI�X�V��
        gn_user_id,                                               -- �ŏI�X�V��ID
        gn_login_id,                                              -- �ŏI�X�V���O�C��ID
        gn_request_id,                                            -- �v��ID
        gn_prog_appl_id,                                          -- �v���O�����A�v���P�[�V����ID
        gn_conc_program_id,                                       -- �v���O����ID
        gd_sysdate,                                               -- �v���O�����X�V��
        gv_no
        );
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
--
    -- ===============================
    -- �����w�b�_�A�h�I���ɒǉ�
    -- ===============================
    BEGIN
      INSERT INTO xxpo_headers_all(
          xxpo_header_id,                                           -- �����w�b�_(�A�h�I��ID)
          po_header_number,                                         -- �����ԍ�
          requested_by_code,                                        -- �˗��҃R�[�h
          requested_department_code,                                -- �˗������R�[�h
          requested_date,                                           -- �˗���
          order_created_by_code,                                    -- �쐬�҃R�[�h
          order_created_date,                                       -- �쐬��
          order_approved_flg,                                       -- ���������t���O
          order_approved_by,                                        -- ���������҃��[�U�[ID
          order_approved_date,                                      -- �����������t
          purchase_approved_flg,                                    -- �d�������t���O
          purchase_approved_by,                                     -- �d���������[�U�[ID
          purchase_approved_date,                                   -- �d���������t
          creation_date,                                            -- �쐬��
          created_by,                                               -- �쐬��ID
          last_update_date,                                         -- �ŏI�X�V��
          last_updated_by,                                          -- �ŏI�X�V��ID
          last_update_login,                                        -- �ŏI�X�V���O�C��ID
          request_id,                                               -- �v��ID
          program_application_id,                                   -- �v���O�����A�v���P�[�V����ID
          program_id,                                               -- �v���O����ID
          program_update_date                                       -- �v���O�����X�V��
          )
        VALUES
          (
          ir_xxpo_headers_if.xxpo_header_id,                        -- �����w�b�_(�A�h�I��ID)
          ir_po_headers_if.document_num,                            -- �����ԍ�
          NULL,                                                     -- �˗��҃R�[�h
          NULL,                                                     -- �˗������R�[�h
          NULL,                                                     -- �˗���
          cn_emp_num,                                               -- �쐬�҃R�[�h
          gd_sysdate,                                               -- �쐬��
          gv_no,                                                    -- ���������t���O
          NULL,                                                     -- ���������҃��[�U�[ID
          NULL,                                                     -- �����������t
          gv_no,                                                    -- �d�������t���O
          NULL,                                                     -- �d���������[�U�[ID
          NULL,                                                     -- �d���������t
          gd_sysdate,                                               -- �쐬��
          gn_user_id,                                               -- �쐬��ID
          gd_sysdate,                                               -- �ŏI�X�V��
          gn_user_id,                                               -- �ŏI�X�V��ID
          gn_login_id,                                              -- �ŏI�X�V���O�C��ID
          gn_request_id,                                            -- �v��ID
          gn_prog_appl_id,                                          -- �v���O�����A�v���P�[�V����ID
          gn_conc_program_id,                                       -- �v���O����ID
          gd_sysdate                                                -- �v���O�����X�V��
          );
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
--
    BEGIN
      -- ==============================================================
      -- �������׃C���^�t�F�[�X�ɒǉ�
      -- ==============================================================
      <<ins_po_lines_loop>>
      FORALL li_cnt IN 1 .. tab_if_line_id_ins.COUNT
        INSERT INTO po_lines_interface(
          interface_line_id,                                        -- �C���^�[�t�F�[�X����ID
          interface_header_id,                                      -- �C���^�[�t�F�[�X�w�b�_ID
          line_num,                                                 -- ���הԍ�
          shipment_num,                                             -- �[�����הԍ�
          line_type_id,                                             -- ���׃^�C�vID
          item,                                                     -- �i��ID
          uom_code,                                                 -- �P��
          quantity,                                                 -- ����
          unit_price,                                               -- �P��
          ship_to_organization_id,                                  -- �[����g�DID
          promised_date,                                            -- �[��
          line_attribute2,                                          -- �H��R�[�h
          line_attribute3,                                          -- �t�уR�[�h
          line_attribute4,                                          -- �݌ɓ���
          line_attribute8,                                          -- �d���艿
          line_attribute10,                                         -- �����P��
          line_attribute11,                                         -- ��������
          line_attribute13,                                         -- ���ʊm��t���O
          line_attribute14,                                         -- ���z�m��t���O
          line_attribute15,                                         -- �E�v
          shipment_attribute2,                                      -- ������P��
          shipment_attribute3,                                      -- ���K�敪
          shipment_attribute6,                                      -- ���ۋ��敪
          shipment_attribute9,                                      -- ��������z
          creation_date,                                            -- �쐬��
          created_by,                                               -- �쐬��ID
          last_update_date,                                         -- �ŏI�X�V��
          last_updated_by,                                          -- �ŏI�X�V��ID
          last_update_login,                                        -- �ŏI�X�V���O�C��ID
          request_id,                                               -- �v��ID
          program_application_id,                                   -- �v���O�����A�v���P�[�V����ID
          program_id,                                               -- �v���O����ID
          program_update_date                                       -- �v���O�����X�V��
          )
        VALUES
          (
          tab_if_line_id_ins(li_cnt),                               -- �C���^�[�t�F�[�X����ID
          ir_po_headers_if.if_header_id,                            -- �C���^�[�t�F�[�X�w�b�_ID
          tab_line_num_ins(li_cnt),                                 -- ���הԍ�
          tab_line_num_ins(li_cnt),                                 -- �[�����הԍ�
          gn_line_type_id,                                          -- ���׃^�C�vID
          tab_item_ins(li_cnt),                                     -- �i��
          tab_uom_code_ins(li_cnt),                                 -- �P��
          tab_quantity_ins(li_cnt),                                 -- ����
          tab_unit_price_ins(li_cnt),                               -- �P��
          tab_ship_to_org_id_ins(li_cnt),                           -- �[����g�DID
          ir_po_headers_if.delivery_date,                           -- �[��
          tab_factory_code_ins(li_cnt),                             -- �H��R�[�h
          tab_futai_code_ins(li_cnt),                               -- �t�уR�[�h
          tab_frequent_qty_ins(li_cnt),                             -- �݌ɓ���
          tab_stocking_price_ins(li_cnt),                           -- �d���艿
          tab_order_unit_ins(li_cnt),                               -- �����P��
          tab_order_quantity_ins(li_cnt),                           -- ��������
          gv_no,                                                    -- ���ʊm��t���O
          gv_no,                                                    -- ���z�m��t���O
          tab_line_description_ins(li_cnt),                         -- �E�v
          tab_attribute2_ins(li_cnt),                               -- ������P��
          gv_attribute3,                                            -- ���K�敪
          gv_attribute6,                                            -- ���ۋ��敪
          tab_attribute9_ins(li_cnt),                               -- ��������z
          gd_sysdate,                                               -- �쐬��
          gn_user_id,                                               -- �쐬��ID
          gd_sysdate,                                               -- �ŏI�X�V��
          gn_user_id,                                               -- �ŏI�X�V��ID
          gn_login_id,                                              -- �ŏI�X�V���O�C��ID
          gn_request_id,                                            -- �v��ID
          gn_prog_appl_id,                                          -- �v���O�����A�v���P�[�V����ID
          gn_conc_program_id,                                       -- �v���O����ID
          gd_sysdate                                                -- �v���O�����X�V��
          );
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
--
    -- ==============================================================
    -- �������׃C���^�t�F�[�X�ɒǉ�
    -- ==============================================================
    BEGIN
      <<ins_po_distributions_loop>>
      FORALL li_cnt IN 1 .. tab_if_line_id_ins.COUNT
        INSERT INTO po_distributions_interface(
          interface_header_id,                                      -- �C���^�[�t�F�[�X�w�b�_ID
          interface_line_id,                                        -- �C���^�[�t�F�[�X����ID
          interface_distribution_id,                                -- �C���^�t�F�[�X��������ID
          distribution_num,                                         -- �������הԍ�
          quantity_ordered,                                         -- �󒍐���
          recovery_rate,                                            -- RECOVERY_RATE
          creation_date,                                            -- �쐬��
          created_by,                                               -- �쐬��ID
          last_update_date,                                         -- �ŏI�X�V��
          last_updated_by,                                          -- �ŏI�X�V��ID
          last_update_login,                                        -- �ŏI�X�V���O�C��ID
          request_id,                                               -- �v��ID
          program_application_id,                                   -- �v���O�����A�v���P�[�V����ID
          program_id,                                               -- �v���O����ID
          program_update_date                                       -- �v���O�����X�V��
          )
        VALUES
          (
          ir_po_headers_if.if_header_id,                            -- �C���^�[�t�F�[�X�w�b�_ID
          tab_if_line_id_ins(li_cnt),                               -- �C���^�[�t�F�[�X����ID
          tab_if_distribute_id_ins(li_cnt),                         -- �C���^�t�F�[�X��������ID
          tab_line_num_ins(li_cnt),                                 -- �������הԍ�
          tab_quantity_ins(li_cnt),                                 -- �󒍐���
          cn_recovery_rate,                                         -- RECOVERY_RATE
          gd_sysdate,                                               -- �쐬��
          gn_user_id,                                               -- �쐬��ID
          gd_sysdate,                                               -- �ŏI�X�V��
          gn_user_id,                                               -- �ŏI�X�V��ID
          gn_login_id,                                              -- �ŏI�X�V���O�C��ID
          gn_request_id,                                            -- �v��ID
          gn_prog_appl_id,                                          -- �v���O�����A�v���P�[�V����ID
          gn_conc_program_id,                                       -- �v���O����ID
          gd_sysdate                                                -- �v���O�����X�V��
          );
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
--
    -- ===============================
    -- �󒍃w�b�_�A�h�I���X�V����
    -- ===============================
    BEGIN
      UPDATE xxwsh_order_headers_all       xoha                             -- �󒍃w�b�_�A�h�I��
      SET   xoha.po_no                   = ir_po_headers_if.document_num    -- ����No
           ,xoha.last_updated_by         = gn_user_id                       -- �ŏI�X�V��
           ,xoha.last_update_date        = gd_sysdate                       -- �ŏI�X�V��
           ,xoha.last_update_login       = gn_login_id                      -- �ŏI�X�V���O�C��
           ,xoha.request_id              = gn_request_id                    -- �v��ID
           ,xoha.program_application_id  = gn_prog_appl_id                  -- ��۸��ѱ��ع����ID
           ,xoha.program_id              = gn_conc_program_id               -- �v���O����ID
           ,xoha.program_update_date     = gd_sysdate                       -- �v���O�����X�V��
      WHERE xoha.order_header_id         = in_order_header_id               -- �󒍃w�b�_�A�h�I��ID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
--
    -- ===============================
    -- �������쐬����
    -- ===============================
    IF (create_reserve_data(in_order_header_id) = gv_status_error) THEN
        RAISE global_api_others_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_retcode      :=  gv_status_error;
      ov_errmsg       :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_regist_all ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      iv_request_no        IN          VARCHAR2         -- 01 : �˗�No
     ,ov_retcode           OUT         VARCHAR2         -- ���^�[���E�R�[�h
     ,on_batch_id          OUT         NUMBER           -- �o�b�`ID
     ,ov_errmsg_code       OUT         VARCHAR2         -- �G���[�E���b�Z�[�W�E�R�[�h
     ,ov_errmsg            OUT         VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_retcode      VARCHAR2(1) ;                       --   ���^�[���E�R�[�h
    lv_errmsg_code  VARCHAR2(5000) ;                    --   �G���[�E���b�Z�[�W�E�R�[�h
    lv_errmsg       VARCHAR2(5000) ;                    --   ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    -- *** ���[�J���ϐ� ***
    lt_order_info           tab_order_info ;                        -- �󒍏��擾���R�[�h�\
    lr_vendor_info          rec_vendor_info ;                       -- �d�����񃌃R�[�h
    lr_item_info            rec_item_info ;                         -- �i�ڏ�񃌃R�[�h
    lr_po_headers_if        rec_po_headers_if ;                     -- ����ͯ�޵���ݲ���̪��ں���
    lr_xxpo_headers_if      rec_xxpo_headers_if;
    ln_total_amount         XXPO_PRICE_HEADERS.total_amount%TYPE ;  -- ���󍇌v
    ln_retcode              NUMBER ;
    li_cnt                  PLS_INTEGER ;                           -- ���[�v�J�E���g
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- �p�����[�^�`�F�b�N(A-1)
    -- =====================================================
    prc_check_param_info(
        iv_request_no       => iv_request_no      -- �˗�No
       ,ov_retcode          => lv_retcode         -- ���^�[���E�R�[�h
       ,ov_errmsg_code      => lv_errmsg_code     -- �G���[�E���b�Z�[�W�E�R�[�h
       ,ov_errmsg           => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- �p�����[�^�i�[
    gv_request_no       := iv_request_no ;                                  -- �˗�No
--
    -- =====================================================
    -- �󒍏�񒊏o(A-2)
    -- =====================================================
    prc_get_order_info(
        ot_data_rec       => lt_order_info        -- �擾���R�[�h
       ,ov_retcode        => lv_retcode           -- ���^�[���E�R�[�h
       ,ov_errmsg_code    => lv_errmsg_code       -- �G���[�E���b�Z�[�W�E�R�[�h
       ,ov_errmsg         => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    <<main_data_loop>>
    FOR li_cnt IN 1..lt_order_info.COUNT LOOP
      gi_cnt  :=  li_cnt;
--
      IF (li_cnt  = 1) THEN   -- �擪���R�[�h���̂ݏ���
        -- =====================================================
        -- �d������擾(A-3)
        -- =====================================================
        prc_get_vendor_info(
            ir_order_info     => lt_order_info(li_cnt)  -- �󒍏�񃌃R�[�h
           ,or_vendor_info    => lr_vendor_info         -- �d�����񃌃R�[�h
           ,ov_retcode        => lv_retcode             -- ���^�[���E�R�[�h
           ,ov_errmsg_code    => lv_errmsg_code         -- �G���[�E���b�Z�[�W�E�R�[�h
           ,ov_errmsg         => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
          ) ;
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt ;
        END IF ;
      END IF;
--
      -- =====================================================
      -- �i�ڏ��擾(A-4)
      -- =====================================================
      prc_get_item_info(
          ir_order_info       => lt_order_info(li_cnt)  -- �󒍏�񃌃R�[�h
         ,or_item_info        => lr_item_info           -- �i�ڏ�񃌃R�[�h
         ,ov_retcode          => lv_retcode             -- ���^�[���E�R�[�h
         ,ov_errmsg_code      => lv_errmsg_code         -- �G���[�E���b�Z�[�W�E�R�[�h
         ,ov_errmsg           => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
        ) ;
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- ���b�g�Ǘ��i�ڃ`�F�b�N(A-5)
      -- =====================================================
      IF (lr_item_info.lot_ctl != 0) THEN               -- ���b�g���L���̏ꍇ
        lv_errmsg  := xxcmn_common_pkg.get_msg(
                            iv_application   => gc_application_po,
                            iv_name          => 'APP-XXPO-10031');         -- ���b�Z�[�W�擾
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- �P���擾(A-6)
      -- =====================================================
      prc_get_price(
          ir_order_info       => lt_order_info(li_cnt)  -- �󒍏�񃌃R�[�h
         ,ir_vendor_info      => lr_vendor_info         -- �d�����񃌃R�[�h
         ,on_total_amount     => ln_total_amount        -- ���󍇌v
         ,ov_retcode          => lv_retcode             -- ���^�[���E�R�[�h
         ,ov_errmsg_code      => lv_errmsg_code         -- �G���[�E���b�Z�[�W�E�R�[�h
         ,ov_errmsg           => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
        ) ;
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
      IF (li_cnt  = 1) THEN   -- �擪���R�[�h���̂ݏ���
        -- =====================================================
        -- �����w�b�_�o�^(A-7)
        -- =====================================================
        prc_ins_interface_header(
            ir_order_info      => lt_order_info(li_cnt) -- �󒍏�񃌃R�[�h
           ,ir_vendor_info     => lr_vendor_info        -- �d�����񃌃R�[�h
           ,or_po_headers_if   => lr_po_headers_if    -- �����w�b�_�I�[�v���C���^�[�t�F�[�X���R�[�h
           ,or_xxpo_headers_if => lr_xxpo_headers_if
           ,ov_retcode         => lv_retcode            -- ���^�[���E�R�[�h
           ,ov_errmsg_code     => lv_errmsg_code        -- �G���[�E���b�Z�[�W�E�R�[�h
           ,ov_errmsg          => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
          ) ;
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt ;
        END IF ;
      END IF ;
--
      -- =====================================================
      -- ����(����)���דo�^(A-8)
      -- =====================================================
      prc_ins_interface_lines(
          ir_order_info      => lt_order_info(li_cnt) -- �󒍏�񃌃R�[�h
         ,ir_vendor_info     => lr_vendor_info        -- �d�����񃌃R�[�h
         ,ir_item_info       => lr_item_info          -- �i�ڏ�񃌃R�[�h
         ,in_total_amount    => ln_total_amount       -- ���󍇌v
         ,ov_retcode         => lv_retcode            -- ���^�[���E�R�[�h
         ,ov_errmsg_code     => lv_errmsg_code        -- �G���[�E���b�Z�[�W�E�R�[�h
         ,ov_errmsg          => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
        ) ;
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- �o�^�X�V����(A-9)
    -- =====================================================
    prc_regist_all(
        ir_po_headers_if    => lr_po_headers_if                     -- ����ͯ�޵���ݲ���̪��ں���
       ,ir_xxpo_headers_if  => lr_xxpo_headers_if
       ,in_order_header_id  => lt_order_info(1).order_header_id     -- �󒍃w�b�_�A�h�I��ID
       ,ov_retcode          => lv_retcode                           -- ���^�[���E�R�[�h
       ,ov_errmsg_code      => lv_errmsg_code                       -- �G���[�E���b�Z�[�W�E�R�[�h
       ,ov_errmsg           => lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- �㏈��(A-10)
    -- ==================================================
    on_batch_id   :=  lr_po_headers_if.batch_id ;                   -- �o�b�`ID
    ov_errmsg     :=  lv_errmsg ;
--
    -- ==================================================
    -- ���b�N�J�[�\����CLOSE
    -- ==================================================
    IF (cur_order_info%ISOPEN) THEN
      CLOSE cur_order_info ;
    END IF ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (cur_order_info%ISOPEN) THEN
        CLOSE cur_order_info ;
      END IF ;
    -- ==================================================
    -- �㏈��(A-10)
    -- ==================================================
      ov_retcode      :=  gv_status_error ;
      on_batch_id     :=  lr_po_headers_if.batch_id ;               -- �o�b�`ID
      ov_errmsg       :=  lv_errmsg ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (cur_order_info%ISOPEN) THEN
        CLOSE cur_order_info ;
      END IF ;
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (cur_order_info%ISOPEN) THEN
        CLOSE cur_order_info ;
      END IF ;
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
--
--####################################  �Œ蕔 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : auto_purchase_orders
   * Description      : �x���w������̔��������쐬
   **********************************************************************************/
--
  PROCEDURE auto_purchase_orders(
      iv_request_no         IN          VARCHAR2         -- 01 : �˗�No
     ,ov_retcode            OUT NOCOPY  VARCHAR2         -- ���^�[���E�R�[�h
     ,on_batch_id           OUT NOCOPY  NUMBER           -- �o�b�`ID
     ,ov_errmsg_code        OUT NOCOPY  VARCHAR2         -- �G���[�E���b�Z�[�W�E�R�[�h
     ,ov_errmsg             OUT NOCOPY  VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'auto_purchase_orders' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_retcode              VARCHAR2(1) ;         --   ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000) ;      --   ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    submain(
        iv_request_no       => iv_request_no      -- 01 : �˗�No
       ,ov_retcode          => lv_retcode         -- ���^�[���E�R�[�h
       ,on_batch_id         => on_batch_id        -- �o�b�`ID
       ,ov_errmsg_code      => ov_errmsg_code     -- �G���[�E���b�Z�[�W�E�R�[�h
       ,ov_errmsg           => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
     ) ;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
--
--###########################  �Œ蕔 START   #####################################################
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
  END auto_purchase_orders ;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxpo_common925_pkg ;
/