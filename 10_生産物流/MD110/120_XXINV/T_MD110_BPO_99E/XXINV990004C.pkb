CREATE OR REPLACE PACKAGE BODY xxinv990004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv990004c(body)
 * Description      : ���o�Ɏ��т̃A�b�v���[�h
 * MD.050           : �t�@�C���A�b�v���[�h   T_MD050_BPO_990
 * MD.070           : ���o�Ɏ��т̃A�b�v���[�h T_MD070_BPO_99E
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init_proc              �֘A�f�[�^�擾 (E-1)
 *  get_upload_data_proc   �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (E-2)
 *  check_proc             �Ó����`�F�b�N (E-3,4,5)
 *  set_data_proc          �o�^�f�[�^�ݒ�
 *  insert_header_proc     �w�b�_�o�^ (E-6)
 *  insert_details_proc    ���דo�^ (E-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/28    1.0   Oracle �쑺       ����쐬
 *  2008/04/18    1.1   Oracle �R�� ��_  �ύX�v��No63�Ή�
 *  2008/05/07    1.2   Oracle �͖�       �����ύX�v��No82�Ή�
 *  2008/05/28    1.3   Oracle �R�� ��_  �ύX�v��No87�Ή�
 *  2008/07/08    1.4   Oracle �R�� ��_  I_S_192�Ή�
 *  2009/06/29    1.5   SCS    �ɓ�       �{�ԏ�Q#1550
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  check_lock_expt           EXCEPTION;     -- ���b�N�擾�G���[
  no_data_if_expt           EXCEPTION;     -- �Ώۃf�[�^�Ȃ�
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name       CONSTANT VARCHAR2(100) := 'xxinv990004c'; -- �p�b�P�[�W��
--
  gv_c_msg_kbn   CONSTANT VARCHAR2(5)   := 'XXINV';
--
  -- ���b�Z�[�W�ԍ�
  gv_c_msg_99e_001   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10025'; -- �v���t�@�C���擾�G���[
  gv_c_msg_99e_002   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10032'; -- ���b�N�G���[
  gv_c_msg_99e_003   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10008'; -- �Ώۃf�[�^�Ȃ�
  gv_c_msg_99e_004   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10026'; -- �w�b�_���׋敪�G���[
  gv_c_msg_99e_005   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10024'; -- �t�H�[�}�b�g�`�F�b�N�G���[���b�Z�[�W
-- 2009/06/29 H.Itou Add Start �{�ԏ�Q#1550
  gv_c_msg_99e_006   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10190'; -- �w�b�_�Ȃ��G���[
-- 2009/06/29 H.Itou Add End
--
  gv_c_msg_99e_101   CONSTANT VARCHAR2(15)  := 'APP-XXINV-00001'; -- �t�@�C����
  gv_c_msg_99e_103   CONSTANT VARCHAR2(15)  := 'APP-XXINV-00003'; -- �A�b�v���[�h����
  gv_c_msg_99e_104   CONSTANT VARCHAR2(15)  := 'APP-XXINV-00004'; -- �t�@�C���A�b�v���[�h����
--
  -- �g�[�N��
  gv_c_tkn_ng_profile          CONSTANT VARCHAR2(10)   := 'NAME';
  gv_c_tkn_table               CONSTANT VARCHAR2(15)   := 'TABLE';
  gv_c_tkn_item                CONSTANT VARCHAR2(15)   := 'ITEM';
  gv_c_tkn_value               CONSTANT VARCHAR2(15)   := 'VALUE';
-- 2009/06/29 H.Itou Add Start �{�ԏ�Q#1550
  gv_c_tkn_request_no          CONSTANT VARCHAR2(15)   := 'REQUEST_NO';
-- 2009/06/29 H.Itou Add End
  -- �v���t�@�C��
  gv_c_parge_term_004          CONSTANT VARCHAR2(20)   := 'XXINV_PURGE_TERM_004';
  gv_c_parge_term_name         CONSTANT VARCHAR2(36)   := '�p�[�W�Ώۊ���:���o�Ɏ���';
  -- �N�C�b�N�R�[�h �^�C�v
  gv_c_lookup_type             CONSTANT VARCHAR2(17)  := 'XXINV_FILE_OBJECT';
  gv_c_format_type             CONSTANT VARCHAR2(20)  := '�t�H�[�}�b�g�p�^�[��';
  -- �Ώ�DB��
  gv_c_xxinv_mrp_file_ul_name  CONSTANT VARCHAR2(100)
                                            := '�t�@�C���A�b�v���[�h�C���^�t�F�[�X�e�[�u��';
--
  -- *** �w�b�_���ږ� ***
  gv_c_file_id_name             CONSTANT VARCHAR2(24)   := 'FILE_ID';
  gv_c_data_type                CONSTANT VARCHAR2(24)   := '�f�[�^���';
  gv_c_tranceration_number      CONSTANT VARCHAR2(24)   := '�`���p�}��';
  gv_c_delivery_no              CONSTANT VARCHAR2(24)   := '�z��No';
  gv_c_order_source_ref         CONSTANT VARCHAR2(24)   := '�˗�No';
  gv_c_location_code            CONSTANT VARCHAR2(24)   := '�o�ɑq�ɃR�[�h';
  gv_c_ship_to_location         CONSTANT VARCHAR2(24)   := '���ɑq�ɃR�[�h';
  gv_c_freight_carrier_code     CONSTANT VARCHAR2(24)   := '�^���Ǝ҃R�[�h';
  gv_c_party_site_code          CONSTANT VARCHAR2(24)   := '�z����R�[�h';
  gv_c_shipped_date             CONSTANT VARCHAR2(24)   := '����';
  gv_c_arrival_date             CONSTANT VARCHAR2(24)   := '����';
  gv_c_shipping_method_code     CONSTANT VARCHAR2(24)   := '�z���敪';
  gv_c_collected_pallet_qty     CONSTANT VARCHAR2(24)   := '�p���b�g�������';
  gv_c_arrival_time_from        CONSTANT VARCHAR2(24)   := '���׎��Ԏw��(FROM)';
  gv_c_arrival_time_to          CONSTANT VARCHAR2(24)   := '���׎��Ԏw��(TO)';
  gv_c_cust_po_number           CONSTANT VARCHAR2(24)   := '�ڋq�����ԍ�';
  gv_c_used_pallet_qty          CONSTANT VARCHAR2(24)   := '�p���b�g�g�p����';
  gv_c_report_post_code         CONSTANT VARCHAR2(24)   := '�񍐕���';
  -- *** ���׍��ږ� ***
  gv_c_orderd_item_code         CONSTANT VARCHAR2(24)   := '�i�ڃR�[�h';
  gv_c_orderd_quantity          CONSTANT VARCHAR2(24)   := '�i�ڐ���';
  gv_c_lot_no                   CONSTANT VARCHAR2(24)   := '���b�g�ԍ�';
  gv_c_designated_prod_date     CONSTANT VARCHAR2(24)   := '������';
  gv_c_original_character       CONSTANT VARCHAR2(24)   := '�ŗL�L��';
  gv_c_use_by_date              CONSTANT VARCHAR2(24)   := '�ܖ�����';
  gv_c_detailed_quantity        CONSTANT VARCHAR2(24)   := '���b�g����';
--
  -- *** �w�b�_���ڌ��� ***
  gn_c_data_type_l              CONSTANT NUMBER         := 3;   -- �f�[�^���
  gn_c_delivery_no_l            CONSTANT NUMBER         := 12;  -- �z��No
  gn_c_order_source_ref_l       CONSTANT NUMBER         := 12;  -- �˗�No
  gn_c_location_code_l          CONSTANT NUMBER         := 4;   -- �o�ɑq�ɃR�[�h
  gn_c_ship_to_location_l       CONSTANT NUMBER         := 4;   -- ���ɑq�ɃR�[�h
  gn_c_freight_carrier_code_l   CONSTANT NUMBER         := 4;   -- �^���Ǝ҃R�[�h
  gn_c_party_site_code_l        CONSTANT NUMBER         := 9;   -- �z����R�[�h
  gn_c_shipping_method_code_l   CONSTANT NUMBER         := 2;   -- �z���敪
  gn_c_arrival_time_from_l      CONSTANT NUMBER         := 4;   -- ���׎��Ԏw��(FROM)
  gn_c_arrival_time_to_l        CONSTANT NUMBER         := 4;   -- ���׎��Ԏw��(TO)
  gn_c_cust_po_number_l         CONSTANT NUMBER         := 20;  -- �ڋq�����ԍ�
  gn_c_report_post_code_l       CONSTANT NUMBER         := 4;   -- �񍐕���
  -- *** ���׍��ڌ��� ***
  gn_c_orderd_item_code_l       CONSTANT NUMBER         := 7;   -- �i�ڃR�[�h
  gn_c_lot_no_l                 CONSTANT NUMBER         := 10;  -- ���b�g�ԍ�
  gn_c_original_character_l     CONSTANT NUMBER         := 6;   -- �ŗL�L��
--
  -- *** �w�b�_���׋敪 ***
--2008.05.07 Y.Kawano modify start
--  gn_c_tranc_header             CONSTANT VARCHAR2(2)    := '01';  -- �w�b�_
--  gn_c_tranc_details            CONSTANT VARCHAR2(2)    := '02';  -- ����
  gn_c_tranc_header             CONSTANT VARCHAR2(2)    := '10';  -- �w�b�_
  gn_c_tranc_details            CONSTANT VARCHAR2(2)    := '20';  -- ����
--2008.05.07 Y.Kawano modify end
  -- �f�[�^�敪
  gv_c_data_type_wsh            CONSTANT VARCHAR2(2)    := '30';  -- �O���q�ɓ��o�Ɏ���
--
  gv_c_period                   CONSTANT VARCHAR2(1)    := '.';           -- �s���I�h
  gv_c_comma                    CONSTANT VARCHAR2(1)    := ',';           -- �J���}
  gv_c_space                    CONSTANT VARCHAR2(1)    := ' ';           -- �X�y�[�X
  gv_c_err_msg_space            CONSTANT VARCHAR2(6)    := '      ';      -- �X�y�[�X�i6byte�j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- CSV���i�[���郌�R�[�h
  TYPE file_data_rec IS RECORD(
    corporation_name              VARCHAR2(32767), -- ��Ж�
    eos_data_type                 VARCHAR2(32767), -- �f�[�^���
    tranceration_number           VARCHAR2(32767), -- �`���p�}��
    delivery_no                   VARCHAR2(32767), -- �z��No
    order_source_ref              VARCHAR2(32767), -- �˗�No
    spare                         VARCHAR2(32767), -- �\��
    head_sales_branch             VARCHAR2(32767), -- ���_�R�[�h
    head_sales_branch_name        VARCHAR2(32767), -- �Ǌ����_����
    location_code                 VARCHAR2(32767), -- �o�ɑq�ɃR�[�h
    location_code_name            VARCHAR2(32767), -- �o�ɑq�ɖ���
    ship_to_location              VARCHAR2(32767), -- ���ɑq�ɃR�[�h
    ship_to_location_name         VARCHAR2(32767), -- ���ɑq�ɖ���
    freight_carrier_code          VARCHAR2(32767), -- �^���Ǝ҃R�[�h
    freight_carrier_code_name     VARCHAR2(32767), -- �^���ƎҖ�
    party_site_code               VARCHAR2(32767), -- �z����R�[�h
    party_site_code_name          VARCHAR2(32767), -- �z���於
    shipped_date                  VARCHAR2(32767), -- ����
    arrival_date                  VARCHAR2(32767), -- ����
    shipping_method_code          VARCHAR2(32767), -- �z���敪
    weight                        VARCHAR2(32767), -- �d��
    mixed_no                      VARCHAR2(32767), -- ���ڌ��˗�No
    collected_pallet_qty          VARCHAR2(32767), -- �p���b�g�������
    arrival_time_from             VARCHAR2(32767), -- ���׎��Ԏw��iFROM�j
    arrival_time_to               VARCHAR2(32767), -- ���׎��Ԏw��iTO�j
    cust_po_number                VARCHAR2(32767), -- �ڋq�����ԍ�
    summary                       VARCHAR2(32767), -- �E�v
    status                        VARCHAR2(32767), -- �X�e�[�^�X
    freight_charge_class          VARCHAR2(32767), -- �^���敪
    used_pallet_qty               VARCHAR2(32767), -- �p���b�g�g�p����
    spare1                        VARCHAR2(32767), -- �\���P
    spare2                        VARCHAR2(32767), -- �\���Q
    spare3                        VARCHAR2(32767), -- �\���R
    spare4                        VARCHAR2(32767), -- �\���S
    report_post_code              VARCHAR2(32767), -- �񍐕���
    orderd_item_code              VARCHAR2(32767), -- �i�ڃR�[�h
    orderd_item_code_name         VARCHAR2(32767), -- �i�ږ�
    item_uom_code                 VARCHAR2(32767), -- �i�ڒP��
    orderd_quantity               VARCHAR2(32767), -- �i�ڐ���
    lot_no                        VARCHAR2(32767), -- ���b�g�ԍ�
    designated_production_date    VARCHAR2(32767), -- ������
    original_character            VARCHAR2(32767), -- �ŗL�L��
    use_by_date                   VARCHAR2(32767), -- �ܖ�����
    detailed_quantity             VARCHAR2(32767), -- ���b�g����
    new_modify_del_class          VARCHAR2(32767), -- �f�[�^�敪
    update_date                   VARCHAR2(32767), -- �X�V����
    line                          VARCHAR2(32767), -- �s���e�S�āi��������p�j
    err_message                   VARCHAR2(32767)  -- �G���[���b�Z�[�W�i��������p�j
  );
--
  -- CSV���i�[���錋���z��
  TYPE file_data_tbl IS TABLE OF file_data_rec INDEX BY BINARY_INTEGER;
  fdata_tbl file_data_tbl;
--
  -- �o�^�pPL/SQL�\�^�i�w�b�_�j
  TYPE header_id_type             IS TABLE OF  
      xxwsh_shipping_headers_if.header_id%TYPE            INDEX BY BINARY_INTEGER;  -- �w�b�_ID
  TYPE  party_site_code_type      IS TABLE OF 
      xxwsh_shipping_headers_if.party_site_code%TYPE      INDEX BY BINARY_INTEGER;  -- �o�א�
  TYPE cust_po_number_type        IS TABLE OF 
      xxwsh_shipping_headers_if.cust_po_number%TYPE       INDEX BY BINARY_INTEGER;  -- �ڋq����
  TYPE  order_source_ref_type     IS TABLE OF 
      xxwsh_shipping_headers_if.order_source_ref%TYPE     INDEX BY BINARY_INTEGER;  -- �󒍃\�[�X�Q��
  TYPE  used_pallet_qty_type      IS TABLE OF 
      xxwsh_shipping_headers_if.used_pallet_qty%TYPE      INDEX BY BINARY_INTEGER;  -- �p���b�g�g�p����
  TYPE  collected_pallet_qty_type IS TABLE OF 
      xxwsh_shipping_headers_if.collected_pallet_qty%TYPE INDEX BY BINARY_INTEGER;  -- �p���b�g�������
  TYPE  location_code_type        IS TABLE OF 
      xxwsh_shipping_headers_if.location_code%TYPE        INDEX BY BINARY_INTEGER;  -- �o�׌�
  TYPE  arrival_time_from_type    IS TABLE OF 
      xxwsh_shipping_headers_if.arrival_time_from%TYPE    INDEX BY BINARY_INTEGER;  -- ���׎���From
  TYPE  arrival_time_to_type      IS TABLE OF 
      xxwsh_shipping_headers_if.arrival_time_to%TYPE      INDEX BY BINARY_INTEGER;  -- ���׎���To
  TYPE freight_carrier_code_type  IS TABLE OF 
      xxwsh_shipping_headers_if.freight_carrier_code%TYPE INDEX BY BINARY_INTEGER;  -- �^���Ǝ�
  TYPE shipping_method_code_type  IS TABLE OF 
      xxwsh_shipping_headers_if.shipping_method_code%TYPE INDEX BY BINARY_INTEGER;  -- �z���敪
  TYPE delivery_no_type           IS TABLE OF 
      xxwsh_shipping_headers_if.delivery_no%TYPE          INDEX BY BINARY_INTEGER;  -- �z��No
  TYPE shipped_date_type          IS TABLE OF 
      xxwsh_shipping_headers_if.shipped_date%TYPE         INDEX BY BINARY_INTEGER;  -- �o�ד�
  TYPE arrival_date_type          IS TABLE OF 
      xxwsh_shipping_headers_if.arrival_date%TYPE         INDEX BY BINARY_INTEGER;  -- ���ד�
  TYPE eos_data_type_type         IS TABLE OF 
      xxwsh_shipping_headers_if.eos_data_type%TYPE        INDEX BY BINARY_INTEGER;  -- EOS�f�[�^���
  TYPE tranceration_number_type   IS TABLE OF 
      xxwsh_shipping_headers_if.tranceration_number%TYPE  INDEX BY BINARY_INTEGER;  -- �`���p�}��
  TYPE ship_to_location_type      IS TABLE OF 
      xxwsh_shipping_headers_if.ship_to_location%TYPE     INDEX BY BINARY_INTEGER;  -- ���ɑq��
  TYPE  report_post_code_type     IS TABLE OF 
      xxwsh_shipping_headers_if.report_post_code%TYPE     INDEX BY BINARY_INTEGER;  -- �񍐕���
  TYPE  filler14_type             IS TABLE OF 
      xxwsh_shipping_headers_if.filler14%TYPE             INDEX BY BINARY_INTEGER;  -- �^���敪
--
  gt_header_id_tab              header_id_type;             -- �w�b�_ID
  gt_party_site_code_tab        party_site_code_type;       -- �o�א�
  gt_cust_po_number_tab         cust_po_number_type;        -- �ڋq����
  gt_order_source_ref_tab       order_source_ref_type;      -- �󒍃\�[�X�Q��
  gt_used_pallet_qty_tab        used_pallet_qty_type;       -- �p���b�g�g�p����
  gt_collected_pallet_qty_tab   collected_pallet_qty_type;  -- �p���b�g�������
  gt_location_code_tab          location_code_type;         -- �o�׌�
  gt_arrival_time_from_tab      arrival_time_from_type;     -- ���׎���From
  gt_arrival_time_to_tab        arrival_time_to_type;       -- ���׎���To
  gt_freight_carrier_code_tab   freight_carrier_code_type;  -- �^���Ǝ�
  gt_shipping_method_code_tab   shipping_method_code_type;  -- �z���敪
  gt_delivery_no_tab            delivery_no_type;           -- �z��No
  gt_shipped_date_tab           shipped_date_type;          -- �o�ד�
  gt_arrival_date_tab           arrival_date_type;          -- ���ד�
  gt_eos_data_tab               eos_data_type_type;         -- EOS�f�[�^���
  gt_ship_to_location_tab       ship_to_location_type;      -- ���ɑq��
  gt_report_post_code_tab       report_post_code_type;      -- �񍐕���
  gt_filler14_tab               filler14_type;              -- �^���敪
--
  -- �o�^�pPL/SQL�\�^�i���ׁj
  TYPE line_header_id_type              IS TABLE OF
      xxwsh_shipping_lines_if.header_id%TYPE                  INDEX BY BINARY_INTEGER;  -- ����ID
  TYPE line_id_type                     IS TABLE OF
      xxwsh_shipping_lines_if.line_id%TYPE                    INDEX BY BINARY_INTEGER;  -- �w�b�_ID
  TYPE orderd_item_code_type            IS TABLE OF
      xxwsh_shipping_lines_if.orderd_item_code%TYPE           INDEX BY BINARY_INTEGER;  -- �󒍕i��
  TYPE orderd_quantity_type             IS TABLE OF
      xxwsh_shipping_lines_if.orderd_quantity%TYPE            INDEX BY BINARY_INTEGER;  -- �i�ڐ���
  TYPE designated_prod_date_type        IS TABLE OF
      xxwsh_shipping_lines_if.designated_production_date%TYPE INDEX BY BINARY_INTEGER;  -- ������
  TYPE original_character_type          IS TABLE OF
      xxwsh_shipping_lines_if.original_character%TYPE         INDEX BY BINARY_INTEGER;  -- �ŗL�L��
  TYPE use_by_date_type                 IS TABLE OF
      xxwsh_shipping_lines_if.use_by_date%TYPE                INDEX BY BINARY_INTEGER;  -- �ܖ�����
  TYPE detailed_quantity_type           IS TABLE OF
      xxwsh_shipping_lines_if.detailed_quantity%TYPE          INDEX BY BINARY_INTEGER;  -- ���󐔗�
  TYPE lot_no_type                      IS TABLE OF
      xxwsh_shipping_lines_if.lot_no%TYPE                     INDEX BY BINARY_INTEGER;  -- ���b�gNo
--
  gt_line_header_id_tab                 line_header_id_type;              -- ����ID
  gt_line_id_tab                        line_id_type;                     -- ����ID
  gt_orderd_item_code_tab               orderd_item_code_type;            -- �󒍕i��
  gt_orderd_quantity_tab                orderd_quantity_type;             -- �i�ڐ���
  gt_designated_prod_date_tab           designated_prod_date_type;        -- ������
  gt_original_character_tab             original_character_type;          -- �ŗL�L��
  gt_use_by_date_tab                    use_by_date_type;                 -- �ܖ�����
  gt_detailed_quantity_tab              detailed_quantity_type;           -- ���󐔗�
  gt_lot_no_tab                         lot_no_type;                      -- ���b�gNo
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_header_count           NUMBER;           -- �w�b�_�f�[�^����
  gn_line_count             NUMBER;           -- ���׃f�[�^����
--
  gd_sysdate                DATE;             -- �V�X�e�����t
  gn_user_id                NUMBER;           -- ���[�UID
  gn_login_id               NUMBER;           -- �ŏI�X�V���O�C��
  gn_conc_request_id        NUMBER;           -- �v��ID
  gn_prog_appl_id           NUMBER;           -- �ݶ��āE��۸��т̱��ع����ID
  gn_conc_program_id        NUMBER;           -- �R���J�����g�E�v���O����ID
--
  gn_xxinv_parge_term       NUMBER;                          -- �p�[�W�Ώۊ���
  gv_file_name              VARCHAR2(256);                   -- �t�@�C����
  gv_file_up_name           VARCHAR2(256);                   -- �t�@�C���A�b�v���[�h����
  gn_created_by             NUMBER(15);                      -- �쐬��
  gd_creation_date          DATE;                            -- �쐬��
  gv_check_proc_retcode     VARCHAR2(1);                     -- �Ó����`�F�b�N�X�e�[�^�X
--
   /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : �֘A�f�[�^�擾 (E-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    in_file_format  IN  VARCHAR2,     -- �t�H�[�}�b�g�p�^�[��
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- �v���O������
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
    lv_parge_term       VARCHAR2(100);    -- �v���t�@�C���i�[�ꏊ
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �V�X�e�����t�擾
    gd_sysdate := SYSDATE;
    -- WHO�J�������擾
    gn_user_id          := FND_GLOBAL.USER_ID;              -- ���[�UID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;             -- �ŏI�X�V���O�C��
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;      -- �v��ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;         -- �ݶ��āE��۸��т̱��ع����ID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;      -- �R���J�����g�E�v���O����ID
--
    -- �v���t�@�C���u�p�[�W�Ώۊ��ԁv�擾
    lv_parge_term := FND_PROFILE.VALUE(gv_c_parge_term_004);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (lv_parge_term IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99e_001,
                                            gv_c_tkn_ng_profile,
                                            gv_c_parge_term_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C���l�`�F�b�N
    BEGIN
      -- TO_NUMBER�ł��Ȃ���΃G���[
      gn_xxinv_parge_term := TO_NUMBER(lv_parge_term);
    EXCEPTION
      WHEN INVALID_NUMBER OR VALUE_ERROR THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99e_001,
                                            gv_c_tkn_ng_profile,
                                            gv_c_parge_term_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
--
    -- �t�@�C���A�b�v���[�h���̎擾
    BEGIN
      SELECT  xlvv.meaning
      INTO    gv_file_up_name
      FROM    xxcmn_lookup_values_v xlvv                -- �N�C�b�N�R�[�hVIEW
      WHERE   xlvv.lookup_type = gv_c_lookup_type       -- �^�C�v
      AND     xlvv.lookup_code = in_file_format         -- �R�[�h
      AND     ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                             --*** �f�[�^�擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99e_003,
                                              gv_c_tkn_item,
                                              gv_c_format_type,
                                              gv_c_tkn_value,
                                              in_file_format);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
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
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data_proc
   * Description      : �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (E-2)
   ***********************************************************************************/
  PROCEDURE get_upload_data_proc(
    in_file_id    IN  NUMBER,       --   �t�@�C���h�c
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data_proc'; -- �v���O������
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
    lv_line       VARCHAR2(32767);    -- ���s�R�[�h���̏��
    ln_col        NUMBER;             -- �J����
    lb_col        BOOLEAN  := TRUE;   -- �J�����쐬�p��
    ln_length     NUMBER;             -- �����ۊǗp
--
    lt_file_line_data   xxcmn_common3_pkg.g_file_data_tbl;  -- �s�e�[�u���i�[�̈�
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾
    -- �s���b�N����
    SELECT xmf.file_name,    -- �t�@�C����
           xmf.created_by,   -- �쐬��
           xmf.creation_date -- �쐬��
    INTO   gv_file_name,
           gn_created_by,
           gd_creation_date
    FROM   xxinv_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = in_file_id
    FOR UPDATE OF xmf.file_id NOWAIT;
--
    -- **************************************************
    -- *** �t�@�C���A�b�v���[�h�C���^�[�t�F�[�X�f�[�^�擾
    -- **************************************************
    xxcmn_common3_pkg.blob_to_varchar2(
      in_file_id,         -- �t�@�C���h�c
      lt_file_line_data,  -- �ϊ���VARCHAR2�f�[�^
      lv_errbuf,          -- �G���[�E���b�Z�[�W             --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h               --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �^�C�g���s�̂݁A���́A2�s�ڂ����s�݂̂̏ꍇ
    IF (lt_file_line_data.LAST < 2) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99e_003,
                                            gv_c_tkn_item,
                                            gv_c_file_id_name,
                                            gv_c_tkn_value,
                                            in_file_id);
      lv_errbuf := lv_errmsg;
      RAISE no_data_if_expt;
    END IF;
--
    -- **************************************************
    -- *** �擾�����f�[�^���s���̃��[�v�i2�s�ڂ���j
    -- **************************************************
    <<line_loop>>
    FOR ln_index IN 2 .. lt_file_line_data.LAST LOOP
--
      -- �Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
      -- �s���ɍ�Ɨ̈�Ɋi�[
      lv_line := lt_file_line_data(ln_index);
--
      -- 1�s�̓��e�� line �Ɋi�[
      fdata_tbl(gn_target_cnt).line := lv_line;
--
      -- �J�����ԍ�������
      ln_col := 0;    --�J����
      lb_col := TRUE; --�J�����쐬�p��
--
      -- **************************************************
      -- *** 1�s���J���}���ɕ���
      -- **************************************************
      <<comma_loop>>
      LOOP
        --lv_line�̒�����0�Ȃ�I��
        EXIT WHEN ((lb_col = FALSE) OR (lv_line IS NULL));
--
        -- �J�����ԍ����J�E���g
        ln_col := ln_col + 1;
--
        -- �J���}�̈ʒu���擾
        ln_length := instr(lv_line, gv_c_comma);
        -- �J���}���Ȃ�
        IF (ln_length = 0) THEN
          ln_length := LENGTH(lv_line);
          lb_col    := FALSE;
        -- �J���}������
        ELSE
          ln_length := ln_length -1;
          lb_col    := TRUE;
        END IF;
--
        -- CSV�`�������ڂ��ƂɃ��R�[�h�Ɋi�[
        IF (ln_col = 1) THEN
          fdata_tbl(gn_target_cnt).corporation_name          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 2) THEN
          fdata_tbl(gn_target_cnt).eos_data_type             := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 3) THEN
          fdata_tbl(gn_target_cnt).tranceration_number       := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 4) THEN
          fdata_tbl(gn_target_cnt).delivery_no               := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 5) THEN
          fdata_tbl(gn_target_cnt).order_source_ref          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 6) THEN
          fdata_tbl(gn_target_cnt).spare                     := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 7) THEN
          fdata_tbl(gn_target_cnt).head_sales_branch         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 8) THEN
          fdata_tbl(gn_target_cnt).head_sales_branch_name    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 9) THEN
          fdata_tbl(gn_target_cnt).location_code             := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 10) THEN
          fdata_tbl(gn_target_cnt).location_code_name        := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 11) THEN
          fdata_tbl(gn_target_cnt).ship_to_location          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 12) THEN
          fdata_tbl(gn_target_cnt).ship_to_location_name     := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 13) THEN
          fdata_tbl(gn_target_cnt).freight_carrier_code      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 14) THEN
          fdata_tbl(gn_target_cnt).freight_carrier_code_name := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 15) THEN
          fdata_tbl(gn_target_cnt).party_site_code           := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 16) THEN
          fdata_tbl(gn_target_cnt).party_site_code_name      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 17) THEN
          fdata_tbl(gn_target_cnt).shipped_date              := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 18) THEN
          fdata_tbl(gn_target_cnt).arrival_date              := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 19) THEN
          fdata_tbl(gn_target_cnt).shipping_method_code      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 20) THEN
          fdata_tbl(gn_target_cnt).weight                    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 21) THEN
          fdata_tbl(gn_target_cnt).mixed_no                  := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 22) THEN
          fdata_tbl(gn_target_cnt).collected_pallet_qty      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 23) THEN
          fdata_tbl(gn_target_cnt).arrival_time_from         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 24) THEN
          fdata_tbl(gn_target_cnt).arrival_time_to           := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 25) THEN
          fdata_tbl(gn_target_cnt).cust_po_number            := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 26) THEN
          fdata_tbl(gn_target_cnt).summary                   := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 27) THEN
          fdata_tbl(gn_target_cnt).status                    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 28) THEN
          fdata_tbl(gn_target_cnt).freight_charge_class      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 29) THEN
          fdata_tbl(gn_target_cnt).used_pallet_qty           := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 30) THEN
          fdata_tbl(gn_target_cnt).spare1                    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 31) THEN
          fdata_tbl(gn_target_cnt).spare2                    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 32) THEN
          fdata_tbl(gn_target_cnt).spare3                    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 33) THEN
          fdata_tbl(gn_target_cnt).spare4                    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 34) THEN
          fdata_tbl(gn_target_cnt).report_post_code          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 35) THEN
          fdata_tbl(gn_target_cnt).orderd_item_code          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 36) THEN
          fdata_tbl(gn_target_cnt).orderd_item_code_name     := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 37) THEN
          fdata_tbl(gn_target_cnt).item_uom_code             := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 38) THEN
          fdata_tbl(gn_target_cnt).orderd_quantity           := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 39) THEN
          fdata_tbl(gn_target_cnt).lot_no                    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 40) THEN
          fdata_tbl(gn_target_cnt).designated_production_date:= SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 41) THEN
          fdata_tbl(gn_target_cnt).use_by_date               := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 42) THEN
          fdata_tbl(gn_target_cnt).original_character        := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 43) THEN
          fdata_tbl(gn_target_cnt).detailed_quantity         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 44) THEN
          fdata_tbl(gn_target_cnt).new_modify_del_class      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 45) THEN
          fdata_tbl(gn_target_cnt).update_date               := SUBSTR(lv_line, 1, ln_length);
        END IF;
--
        -- str�͍���擾�����s�������i�J���}�͂̂������߁Aln_length + 2�j
        IF (lb_col = TRUE) THEN
          lv_line := SUBSTR(lv_line, ln_length + 2);
        ELSE
          lv_line := SUBSTR(lv_line, ln_length);
        END IF;
--
      END LOOP comma_loop;
    END LOOP line_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN no_data_if_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := gv_status_warn;
--
    WHEN check_lock_expt THEN                           --*** ���b�N�擾�G���[ ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99e_002,
                                            gv_c_tkn_table,
                                            gv_c_xxinv_mrp_file_ul_name);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    WHEN NO_DATA_FOUND THEN                             --*** �f�[�^�擾�G���[ ***
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99e_003,
                                            gv_c_tkn_item,
                                            gv_c_file_id_name,
                                            gv_c_tkn_value,
                                            in_file_id);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END get_upload_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : check_proc
   * Description      : �Ó����`�F�b�N (E-3,4,5)
   ***********************************************************************************/
  PROCEDURE check_proc(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_proc'; -- �v���O������
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
-- 2009/06/29 H.Itou Add Start �{�ԏ�Q#1550
    cv_cnst_err_msg_space   CONSTANT VARCHAR2(6)   := '      ';   -- �X�y�[�X
-- 2009/06/29 H.Itou Add End
--
    lv_line_feed        VARCHAR2(1);                  -- ���s�R�[�h
--
    -- �����ڐ�
    ln_c_col         CONSTANT NUMBER      := 45;
--
    -- *** ���[�J���ϐ� ***
    lv_log_data                                      VARCHAR2(32767);  -- LOG�f�[�^���ޔ�p
-- 2009/06/29 H.Itou Add Start �{�ԏ�Q#1550
    lt_order_source_ref xxwsh_shipping_headers_if.order_source_ref%TYPE;    -- �w�b�_�̈˗�No
-- 2009/06/29 H.Itou Add End
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- ������
    gv_check_proc_retcode := gv_status_normal; -- �Ó����`�F�b�N�X�e�[�^�X
    lv_line_feed := CHR(10);                   -- ���s�R�[�h
--
    -- **************************************************
    -- *** �擾�������R�[�h���ɍ��ڃ`�F�b�N���s���B
    -- **************************************************
    <<check_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      -- **************************************************
      -- *** ���ڐ��`�F�b�N
      -- **************************************************
      -- �i�s�S�̂̒����|�s����J���}�𔲂����������J���}�̐��j <> �i�����ȍ��ڐ��|�P�������ȃJ���}�̐��j
      IF ((NVL(LENGTH(fdata_tbl(ln_index).line) ,0) - NVL(LENGTH(REPLACE(fdata_tbl(ln_index).line,gv_c_comma,NULL)),0))
          <> (ln_c_col - 1)) THEN
        fdata_tbl(ln_index).err_message := gv_c_err_msg_space
                                           || gv_c_err_msg_space
                                           || xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                                                       gv_c_msg_99e_005)
                                           || lv_line_feed;
      ELSE
        -- **************************************************
        -- *** ���ڃ`�F�b�N�i�w�b�_�^���ׁj
        -- **************************************************
        -- �w�b�_�[�̏ꍇ
        IF (fdata_tbl(ln_index).tranceration_number = gn_c_tranc_header) THEN
-- 2009/06/29 H.Itou Add Start �{�ԏ�Q#1550
          -- �w�b�_�̈˗�No���擾
          lt_order_source_ref := fdata_tbl(ln_index).order_source_ref;
-- 2009/06/29 H.Itou Add End
          -- ==============================
          --  �f�[�^���
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_data_type,
                                              fdata_tbl(ln_index).eos_data_type,
                                              gn_c_data_type_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �z��No
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_delivery_no,
                                              fdata_tbl(ln_index).delivery_no,
                                              gn_c_delivery_no_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �˗�No
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_order_source_ref,
                                              fdata_tbl(ln_index).order_source_ref,
                                              gn_c_order_source_ref_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ng,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �o�ɑq�ɃR�[�h
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_location_code,
                                              fdata_tbl(ln_index).location_code,
                                              gn_c_location_code_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- ���ɑq�ɃR�[�h
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_ship_to_location,
                                              fdata_tbl(ln_index).ship_to_location,
                                              gn_c_ship_to_location_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �^���Ǝ҃R�[�h
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_freight_carrier_code,
                                              fdata_tbl(ln_index).freight_carrier_code,
                                              gn_c_freight_carrier_code_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �z����R�[�h
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_party_site_code,
                                              fdata_tbl(ln_index).party_site_code,
                                              gn_c_party_site_code_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- ����
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_shipped_date,
                                              fdata_tbl(ln_index).shipped_date,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_dat,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- ����
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_arrival_date,
                                              fdata_tbl(ln_index).arrival_date,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_dat,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �z���敪
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_shipping_method_code,
                                              fdata_tbl(ln_index).shipping_method_code,
                                              gn_c_shipping_method_code_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �p���b�g�������
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_collected_pallet_qty,
                                              fdata_tbl(ln_index).collected_pallet_qty,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_num,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- ���׎��Ԏw��iFROM�j
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_arrival_time_from,
                                              fdata_tbl(ln_index).arrival_time_from,
                                              gn_c_arrival_time_from_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- ���׎��Ԏw��iTO�j
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_arrival_time_to,
                                              fdata_tbl(ln_index).arrival_time_to,
                                              gn_c_arrival_time_to_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �ڋq�����ԍ�
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_cust_po_number,
                                              fdata_tbl(ln_index).cust_po_number,
                                              gn_c_cust_po_number_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �p���b�g�g�p����
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_used_pallet_qty,
                                              fdata_tbl(ln_index).used_pallet_qty,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_num,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �񍐕���
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_report_post_code,
                                              fdata_tbl(ln_index).report_post_code,
                                              gn_c_report_post_code_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
        -- ���ׂ̏ꍇ
        ELSIF (fdata_tbl(ln_index).tranceration_number = gn_c_tranc_details) THEN
-- 2009/06/29 H.Itou Add Start �{�ԏ�Q#1550
          -- �w�b�_�ƈ˗�No���قȂ�ꍇ�̓G���[
          IF ((lt_order_source_ref IS NULL)
          OR  (lt_order_source_ref <> fdata_tbl(ln_index).order_source_ref)) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                 || cv_cnst_err_msg_space
                                                 || cv_cnst_err_msg_space
                                                 || xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                                                             gv_c_msg_99e_006,
                                                                             gv_c_tkn_request_no,
                                                                             fdata_tbl(ln_index).order_source_ref)
                                                 || lv_line_feed;
          END IF;
-- 2009/06/29 H.Itou Add End
          -- ==============================
          -- �i�ڃR�[�h
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_orderd_item_code,
                                              fdata_tbl(ln_index).orderd_item_code,
                                              gn_c_orderd_item_code_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ng,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �i�ڐ���
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_orderd_quantity,
                                              fdata_tbl(ln_index).orderd_quantity,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_num,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- ���b�g�ԍ�
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_lot_no,
                                              fdata_tbl(ln_index).lot_no,
                                              gn_c_lot_no_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- ������
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_designated_prod_date,
                                              fdata_tbl(ln_index).designated_production_date,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_dat,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �ŗL�L��
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_original_character,
                                              fdata_tbl(ln_index).original_character,
                                              gn_c_original_character_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- �ܖ�����
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_use_by_date,
                                              fdata_tbl(ln_index).use_by_date,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_dat,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- ���b�g����
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_detailed_quantity,
                                              fdata_tbl(ln_index).detailed_quantity,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_num,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
        -- �w�b�_���׋敪���s���ȏꍇ
        ELSE
          fdata_tbl(ln_index).err_message := gv_c_err_msg_space
                                             || gv_c_err_msg_space
                                             || xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                                                         gv_c_msg_99e_004)
                                             || lv_line_feed;
        END IF;
      END IF;
--
      -- **************************************************
      -- *** �G���[����
      -- **************************************************
      -- �`�F�b�N�G���[����̏ꍇ
      IF (fdata_tbl(ln_index).err_message IS NOT NULL) THEN
--
        -- **************************************************
        -- *** �f�[�^���o�͏����i�s�� + SPACE + �s�S�̂̃f�[�^�j
        -- **************************************************
        lv_log_data := NULL;
        lv_log_data := TO_CHAR(ln_index,'99999') || gv_c_space || fdata_tbl(ln_index).line;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_log_data);
--
        -- �G���[���b�Z�[�W���o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RTRIM(fdata_tbl(ln_index).err_message, lv_line_feed));
        -- �Ó����`�F�b�N�X�e�[�^�X
        gv_check_proc_retcode := gv_status_error;
        -- �G���[�����J�E���g
        gn_error_cnt := gn_error_cnt + 1;
--
      -- �`�F�b�N�G���[�Ȃ��̏ꍇ
      ELSE
        -- ���������J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
--
    END LOOP check_loop;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END check_proc;
--
  /**********************************************************************************
   * Procedure Name   : set_data_proc
   * Description      : �o�^�f�[�^�ݒ�
   ***********************************************************************************/
  PROCEDURE set_data_proc(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_data_proc'; -- �v���O������
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
    ln_header_id      NUMBER;   -- �w�b�_ID
    ln_line_id        NUMBER;   -- ����ID
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ����������
    gn_line_count     := 0;
    gn_header_count   := 0;
--
    -- ���[�J���ϐ�������
    ln_header_id      := NULL;
    ln_line_id        := NULL;
--
    -- **************************************************
    -- *** �o�^�pPL/SQL�\�ҏW�i2�s�ڂ���j
    -- **************************************************
    <<fdata_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      -- �w�b�_�o�^
      IF (fdata_tbl(ln_index).tranceration_number = gn_c_tranc_header) THEN
--
        -- �w�b�_���� �C���N�������g
        gn_header_count  := gn_header_count + 1;
--
        -- �w�b�_ID�̔�
        SELECT xxwsh_shipping_headers_if_s1.NEXTVAL 
        INTO ln_header_id 
        FROM dual;
--
        -- �w�b�_���
        gt_header_id_tab(gn_header_count)             := ln_header_id;                                             -- �w�b�_ID
        gt_party_site_code_tab(gn_header_count)       := fdata_tbl(ln_index).party_site_code;                      -- �o�א�
        gt_cust_po_number_tab(gn_header_count)        := fdata_tbl(ln_index).cust_po_number;                       -- �ڋq����
        gt_order_source_ref_tab(gn_header_count)      := fdata_tbl(ln_index).order_source_ref;                     -- �󒍃\�[�X�Q��
        gt_used_pallet_qty_tab(gn_header_count)       := TO_NUMBER(fdata_tbl(ln_index).used_pallet_qty);           -- �p���b�g�g�p����
        gt_collected_pallet_qty_tab(gn_header_count)  := TO_NUMBER(fdata_tbl(ln_index).collected_pallet_qty);      -- �p���b�g�������
        gt_location_code_tab(gn_header_count)         := fdata_tbl(ln_index).location_code;                        -- �o�׌�
        gt_arrival_time_from_tab(gn_header_count)     := fdata_tbl(ln_index).arrival_time_from;                    -- ���׎���From
        gt_arrival_time_to_tab(gn_header_count)       := fdata_tbl(ln_index).arrival_time_to;                      -- ���׎���To
        gt_freight_carrier_code_tab(gn_header_count)  := fdata_tbl(ln_index).freight_carrier_code;                 -- �^���Ǝ�
        gt_shipping_method_code_tab(gn_header_count)  := fdata_tbl(ln_index).shipping_method_code;                 -- �z���敪
        gt_delivery_no_tab(gn_header_count)           := fdata_tbl(ln_index).delivery_no;                          -- �z��No
        gt_shipped_date_tab(gn_header_count)          := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).shipped_date, 'RR/MM/DD');  -- �o�ד�
        gt_arrival_date_tab(gn_header_count)          := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).arrival_date, 'RR/MM/DD');  -- ���ד�
        gt_eos_data_tab(gn_header_count)              := fdata_tbl(ln_index).eos_data_type;                        -- EOS�f�[�^���
        gt_ship_to_location_tab(gn_header_count)      := fdata_tbl(ln_index).ship_to_location;                     -- ���ɑq��
        gt_report_post_code_tab(gn_header_count)      := fdata_tbl(ln_index).report_post_code;                     -- �񍐕���
        gt_filler14_tab(gn_header_count)              := fdata_tbl(ln_index).freight_charge_class;                 -- �^���敪
--
      -- ���דo�^
      ELSIF (fdata_tbl(ln_index).tranceration_number = gn_c_tranc_details) THEN
--
        -- ���׌��� �C���N�������g
        gn_line_count   := gn_line_count + 1;
--
        -- �ŏ��̃��R�[�h�����ׂ̏ꍇ�A�w�b�_ID���̔�
        IF (ln_header_id IS NULL) THEN
          -- �w�b�_ID�̔�
          SELECT xxwsh_shipping_headers_if_s1.NEXTVAL 
          INTO ln_header_id 
          FROM dual;
        END IF;
--
        -- ����ID�̔�
        SELECT xxwsh_shipping_lines_if_s1.NEXTVAL
        INTO ln_line_id 
        FROM dual;
--
        -- ���׏��
        gt_line_id_tab(gn_line_count)               := ln_line_id;                                               -- ����ID
        gt_line_header_id_tab(gn_line_count)        := ln_header_id;                                             -- �w�b�_ID
        gt_orderd_item_code_tab(gn_line_count)      := fdata_tbl(ln_index).orderd_item_code;                     -- �󒍕i��
        gt_orderd_quantity_tab(gn_line_count)       := TO_NUMBER(fdata_tbl(ln_index).orderd_quantity);           -- �i�ڐ���
        gt_designated_prod_date_tab(gn_line_count)  := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).designated_production_date, 'RR/MM/DD');  -- ������
        gt_original_character_tab(gn_line_count)    := fdata_tbl(ln_index).original_character;                   -- �ŗL�L��
        gt_use_by_date_tab(gn_line_count)           := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).use_by_date, 'RR/MM/DD'); -- �ܖ�����
        gt_detailed_quantity_tab(gn_line_count)     := TO_NUMBER(fdata_tbl(ln_index).detailed_quantity);         -- ���󐔗�
        gt_lot_no_tab(gn_line_count)                := fdata_tbl(ln_index).lot_no;                               -- ���b�gNo
      END IF;
--
    END LOOP fdata_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
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
  END set_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : insert_header_proc
   * Description      : �w�b�_�o�^ (E-6)
   ***********************************************************************************/
  PROCEDURE insert_header_proc(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_header_proc'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- **************************************************
    -- *** �o�׈˗��C���^�t�F�[�X�w�b�_�i�A�h�I���j�o�^
    -- **************************************************
    FORALL item_cnt IN 1 .. gn_header_count
      INSERT INTO xxwsh_shipping_headers_if
      (   header_id                                         -- �w�b�_ID
        , order_type                                        -- �󒍃^�C�v
        , ordered_date                                      -- �󒍓�
        , party_site_code                                   -- �o�א�
        , shipping_instructions                             -- �o�׎w��
        , cust_po_number                                    -- �ڋq����
        , order_source_ref                                  -- �󒍃\�[�X�Q��
        , schedule_ship_date                                -- �o�ח\���
        , schedule_arrival_date                             -- ���ח\���
        , used_pallet_qty                                   -- �p���b�g�g�p����
        , collected_pallet_qty                              -- �p���b�g�������
        , location_code                                     -- �o�׌�
        , head_sales_branch                                 -- �Ǌ����_
        , arrival_time_from                                 -- ���׎���From
        , arrival_time_to                                   -- ���׎���To
        , data_type                                         -- �f�[�^�^�C�v
        , freight_carrier_code                              -- �^���Ǝ�
        , shipping_method_code                              -- �z���敪
        , delivery_no                                       -- �z��No
        , shipped_date                                      -- �o�ד�
        , arrival_date                                      -- ���ד�
        , eos_data_type                                     -- EOS�f�[�^���
        , tranceration_number                               -- �`���p�}��
        , ship_to_location                                  -- ���ɑq��
        , rm_class                                          -- �q�֕ԕi�敪
        , ordered_class                                     -- �˗��敪
        , report_post_code                                  -- �񍐕���
        , created_by                                        -- �쐬��
        , creation_date                                     -- �쐬��
        , last_updated_by                                   -- �ŏI�X�V��
        , last_update_date                                  -- �ŏI�X�V��
        , last_update_login                                 -- �ŏI�X�V���O�C��
        , request_id                                        -- �v��ID
        , program_application_id                            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                                        -- �R���J�����g�E�v���O����ID
        , program_update_date                               -- �v���O�����X�V��
        , filler14                                          -- �^���敪
      ) VALUES (
          gt_header_id_tab(item_cnt)                        -- �w�b�_ID
        , NULL                                              -- �󒍃^�C�v
        , NULL                                              -- �󒍓�
        , gt_party_site_code_tab(item_cnt)                  -- �o�א�
        , NULL                                              -- �o�׎w��
        , gt_cust_po_number_tab(item_cnt)                   -- �ڋq����
        , gt_order_source_ref_tab(item_cnt)                 -- �󒍃\�[�X�Q��
        , NULL                                              -- �o�ח\���
        , NULL                                              -- ���ח\���
        , gt_used_pallet_qty_tab(item_cnt)                  -- �p���b�g�g�p����
        , gt_collected_pallet_qty_tab(item_cnt)             -- �p���b�g�������
        , gt_location_code_tab(item_cnt)                    -- �o�׌�
        , NULL                                              -- �Ǌ����_
        , gt_arrival_time_from_tab(item_cnt)                -- ���׎���From
        , gt_arrival_time_to_tab(item_cnt)                  -- ���׎���To
        , gv_c_data_type_wsh                                -- �f�[�^�^�C�v
        , gt_freight_carrier_code_tab(item_cnt)             -- �^���Ǝ�
        , gt_shipping_method_code_tab(item_cnt)             -- �z���敪
        , gt_delivery_no_tab(item_cnt)                      -- �z��No
        , gt_shipped_date_tab(item_cnt)                     -- �o�ד�
        , gt_arrival_date_tab(item_cnt)                     -- ���ד�
        , gt_eos_data_tab(item_cnt)                         -- EOS�f�[�^���
        , NULL                                              -- �`���p�}��
        , gt_ship_to_location_tab(item_cnt)                 -- ���ɑq��
        , NULL                                              -- �q�֕ԕi�敪
        , NULL                                              -- �˗��敪
        , gt_report_post_code_tab(item_cnt)                 -- �񍐕���
        , gn_user_id                                        -- �쐬��
        , gd_sysdate                                        -- �쐬��
        , gn_user_id                                        -- �ŏI�X�V��
        , gd_sysdate                                        -- �ŏI�X�V��
        , gn_login_id                                       -- �ŏI�X�V���O�C��
        , gn_conc_request_id                                -- �v��ID
        , gn_prog_appl_id                                   -- �ݶ��āE��۸��т̱��ع����ID
        , gn_conc_program_id                                -- �R���J�����g�E�v���O����ID
        , gd_sysdate                                        -- �v���O�����ɂ��X�V��
        , gt_filler14_tab(item_cnt)                         -- �^���敪
      );
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
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
  END insert_header_proc;
--
  /**********************************************************************************
   * Procedure Name   : insert_details_proc
   * Description      : ���דo�^ (E-7)
   ***********************************************************************************/
  PROCEDURE insert_details_proc(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_details_proc'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- **************************************************
    -- *** �o�׈˗��C���^�t�F�[�X���ׁi�A�h�I���j�o�^
    -- **************************************************
    FORALL item_cnt IN 1 .. gn_line_count
      INSERT INTO xxwsh_shipping_lines_if
      (   line_id                                           -- ����ID
        , header_id                                         -- �w�b�_ID
        , line_number                                       -- ���הԍ�
        , orderd_item_code                                  -- �󒍕i��
        , case_quantity                                     -- �P�[�X��
        , orderd_quantity                                   -- ����
        , shiped_quantity                                   -- �o�׎��ѐ���
        , designated_production_date                        -- ������(�C���^�t�F�[�X�p)
        , original_character                                -- �ŗL�L��(�C���^�t�F�[�X�p)
        , use_by_date                                       -- �ܖ�����(�C���^�t�F�[�X�p)
        , detailed_quantity                                 -- ���󐔗�(�C���^�t�F�[�X�p)
        , ship_to_quantity                                  -- ���Ɏ��ѐ���
        , reserved_status                                   -- �ۗ��X�e�[�^�X
        , lot_no                                            -- ���b�gNo
        , created_by                                        -- �쐬��
        , creation_date                                     -- �쐬��
        , last_updated_by                                   -- �ŏI�X�V��
        , last_update_date                                  -- �ŏI�X�V��
        , last_update_login                                 -- �ŏI�X�V���O�C��
        , request_id                                        -- �v��ID
        , program_application_id                            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                                        -- �R���J�����g�E�v���O����ID
        , program_update_date                               -- �v���O�����X�V��
      ) VALUES (
          gt_line_id_tab(item_cnt)                          -- ����ID
        , gt_line_header_id_tab(item_cnt)                   -- �w�b�_ID
        , NULL                                              -- ���הԍ�
        , gt_orderd_item_code_tab(item_cnt)                 -- �󒍕i��
        , NULL                                              -- �P�[�X��
        , gt_orderd_quantity_tab(item_cnt)                  -- ����
        , NULL                                              -- �o�׎��ѐ���
        , gt_designated_prod_date_tab(item_cnt)             -- ������(�C���^�t�F�[�X�p)
        , gt_original_character_tab(item_cnt)               -- �ŗL�L��(�C���^�t�F�[�X�p)
        , gt_use_by_date_tab(item_cnt)                      -- �ܖ�����(�C���^�t�F�[�X�p)
        , gt_detailed_quantity_tab(item_cnt)                -- ���󐔗�(�C���^�t�F�[�X�p)
        , NULL                                              -- ���Ɏ��ѐ���
        , NULL                                              -- �ۗ��X�e�[�^�X
        , gt_lot_no_tab(item_cnt)                           -- ���b�gNo
        , gn_user_id                                        -- �쐬��
        , gd_sysdate                                        -- �쐬��
        , gn_user_id                                        -- �ŏI�X�V��
        , gd_sysdate                                        -- �ŏI�X�V��
        , gn_login_id                                       -- �ŏI�X�V���O�C��
        , gn_conc_request_id                                -- �v��ID
        , gn_prog_appl_id                                   -- �ݶ��āE��۸��т̱��ع����ID
        , gn_conc_program_id                                -- �R���J�����g�E�v���O����ID
        , gd_sysdate                                        -- �v���O�����ɂ��X�V��
      );
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
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
  END insert_details_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id     IN  NUMBER,       --   �t�@�C���h�c
    in_file_format IN  VARCHAR2,     --   �t�H�[�}�b�g�p�^�[��
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���ϐ� ***
--
    lv_out_rep VARCHAR2(1000);  -- ���|�[�g�o��
--
    -- ===============================
    -- ���[�J���E�J�[�\��
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- �Ó����`�F�b�N�X�e�[�^�X ������
    gv_check_proc_retcode := gv_status_normal;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- �֘A�f�[�^�擾 (E-1)
    -- ===============================
    init_proc(
      in_file_format,    -- �t�H�[�}�b�g�p�^�[��
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (E-2,3)
    -- ===============================
    get_upload_data_proc(
      in_file_id,        -- �t�@�C���h�c
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
-- �������ʂɂ�����炸�������ʃ��|�[�g���o�͂���
--#################################  �A�b�v���[�h�Œ胁�b�Z�[�W START  ###################################
    --�������ʃ��|�[�g�o�́i�㕔�j
    -- �t�@�C����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99e_101,
                                              gv_c_tkn_value,
                                              gv_file_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �A�b�v���[�h����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99e_103,
                                              gv_c_tkn_value,
                                              TO_CHAR(gd_creation_date,'YYYY/MM/DD HH24:MI'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �t�@�C���A�b�v���[�h����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99e_104,
                                              gv_c_tkn_value,
                                              gv_file_up_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
--#################################  �A�b�v���[�h�Œ胁�b�Z�[�W END   ###################################
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- 2008/07/08 Add ��
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      RETURN;
    -- 2008/07/08 Add ��
    END IF;
--
    -- ===============================
    -- �Ó����`�F�b�N (E-4,5)
    -- ===============================
    check_proc(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- �Ó����`�F�b�N�ŃG���[���Ȃ������ꍇ
    ELSIF (gv_check_proc_retcode = gv_status_normal) THEN
--
      -- ===============================
      -- �o�^�f�[�^�Z�b�g
      -- ===============================
      set_data_proc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �w�b�_�o�^ (E-6)
      -- ===============================
      insert_header_proc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ���דo�^ (E-7)
      -- ===============================
      insert_details_proc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ===============================
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�폜 (E-8)
    -- ===============================
    xxcmn_common3_pkg.delete_fileup_proc(
      in_file_format,                 -- �t�H�[�}�b�g�p�^�[��
      gd_sysdate,                     -- �Ώۓ��t
      gn_xxinv_parge_term,            -- �p�[�W�Ώۊ���
      lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      -- �폜�����G���[����RollBack������ׁA�Ó����`�F�b�N�X�e�[�^�X��������
      gv_check_proc_retcode := gv_status_normal;
      RAISE global_process_expt;
    END IF;
--
    -- �`�F�b�N�����G���[
    IF (gv_check_proc_retcode = gv_status_error) THEN
      -- �Œ�̃G���[���b�Z�[�W�̏o�͂����Ȃ��悤�ɂ���
      lv_errmsg := gv_c_space;
      RAISE global_process_expt;
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
    errbuf         OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode        OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    in_file_id     IN  VARCHAR2,      --   �t�@�C���h�c 2008/04/18 �ύX
    in_file_format IN  VARCHAR2       --   �t�H�[�}�b�g�p�^�[��
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      TO_NUMBER(in_file_id),     -- �t�@�C���h�c 2008/04/18 �ύX
      in_file_format, -- �t�H�[�}�b�g�p�^�[��
      lv_errbuf,      -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,     -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) AND (gv_check_proc_retcode = gv_status_normal) THEN
      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxinv990004c;
/
