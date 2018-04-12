CREATE OR REPLACE PACKAGE BODY APPS.XXCOS001A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCOS001A10C(body)
 * Description      : HHT�󒍃f�[�^�̎捞���s��
 * MD.050           : HHT�󒍃f�[�^�捞(MD050_COS_001_A10)
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_work_data          ���[�N�e�[�u���f�[�^���o(A-2)
 *  ins_hht_order_header   HHT�󒍃w�b�_�f�[�^�ꊇ�o�^(A-3)
 *  ins_hht_order_line     HHT�󒍖��׃f�[�^�ꊇ�o�^(A-4)
 *  ins_oif_order_header   �󒍃w�b�_OIF�f�[�^�ꊇ�o�^(A-5)
 *  ins_oif_order_line     �󒍖���OIF�f�[�^�ꊇ�o�^(A-6)
 *  ins_oif_order_process  �󒍏���OIF�f�[�^�ꊇ�o�^(A-7)
 *  call_import            �󒍃C���|�[�g�G���[���m�N��(A-8)
 *  del_work_date          HHT�󒍃��[�N�f�[�^�폜(A-9)
 *  del_order_date         �ێ����Ԓ���HHT�󒍃f�[�^�폜(A-10)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/12/08    1.0   K.Kiriu          main�V�K�쐬(E_�{�ғ�_14486)
 *  2018/01/18    1.1   K.Nara           E_�{�ғ�_14486(�ǉ��Ή��F�󒍕i�ڐ��ʂ̒P�ʂ�i�ڂ̊�P�ʂƂ���)
 *  2018/04/12    1.2   K.Kiriu          E_�{�ғ�_15006(�`�[�敪�̓�1�����폜����OIF���쐬����)
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
  -- HHT�󒍖��׃��[�N�Ȃ��G���[
  no_line_data_expt  EXCEPTION;
  -- �Ώۍ폜�G���[
  del_target_expt    EXCEPTION;
  -- ���b�N�G���[
  lock_err_expt      EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_err_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS001A10C';      -- �p�b�P�[�W��
--
  --�A�v���P�[�V�����Z�k��
  cv_xxcos_appl_short_name  CONSTANT VARCHAR2(5)   := 'XXCOS';             -- �̕��Z�k�A�v����
  -- ���b�Z�[�W
  cv_msg_15251              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15251';  -- �p�����[�^�o��
  cv_msg_00004              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';  -- �v���t�@�C���擾�G���[
  cv_msg_00091              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00091';  -- �݌ɑg�DID�擾�G���[
  cv_msg_15260              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15260';  -- �󒍃\�[�X�擾�G���[
  cv_msg_15261              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15261';  -- �󒍃^�C�v�擾�G���[
  cv_msg_00122              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00122';  -- 00_�ʏ�󒍁i�����j
  cv_msg_00121              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00121';  -- 10_�ʏ�o�ׁi�����j
  cv_msg_00003              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';  -- �Ώۃf�[�^����
  cv_msg_00001              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';  -- ���b�N�G���[
  cv_msg_15259              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15259';  -- �[�i�҃R�[�h�Ȃ�
  cv_msg_15254              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15254';  -- �ۊǏꏊ�R�[�h�Ȃ�
  cv_msg_15255              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15255';  -- ���ׂȂ��G���[
  cv_msg_15256              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15256';  -- �i�ڃR�[�h�Ȃ�
  cv_msg_15257              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15257';  -- ����ΏۊO�i��
  cv_msg_15258              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15258';  -- �ڋq�󒍕s�i��
  cv_msg_00010              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00010';  -- �f�[�^�o�^�G���[
  cv_msg_15275              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15275';  -- HHT�󒍃w�b�_�i�����j
  cv_msg_15276              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15276';  -- HHT�󒍖��ׁi�����j
  cv_msg_15252              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15252';  -- HHT�󒍃w�b�_���[�N�i�����j
  cv_msg_15253              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15253';  -- HHT�󒍖��׃��[�N�i�����j
  cv_msg_00132              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00132';  -- �󒍃w�b�_�[OIF�i�����j
  cv_msg_00133              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00133';  -- �󒍖���OIF�i�����j
  cv_msg_00134              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00134';  -- �󒍏���OIF�i�����j
  cv_msg_15262              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15262';  -- �R���J�����g�G���[
  cv_msg_15263              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15263';  -- �R���J�����g�ҋ@�G���[
  cv_msg_15264              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15264';  -- �R���J�����g�ҋ@�x��
  cv_msg_15277              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15267';  -- HHT�󒍗p���[�N�p���b�N�G���[
  cv_msg_15278              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15278';  -- HHT�󒍃��[�N�p�폜�G���[
  cv_msg_15265              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15265';  -- HHT�󒍗p���b�N�G���[
  cv_msg_15266              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15266';  -- HHT�󒍗p�폜�G���[
  cv_msg_15267              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15267';  -- �w�b�_�Ώی���
  cv_msg_15268              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15268';  -- ���בΏی���
  cv_msg_15269              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15269';  -- �w�b�_�}������
  cv_msg_15270              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15270';  -- ���ב}������
  cv_msg_15271              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15271';  -- �w�b�_�x������
  cv_msg_15272              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15272';  -- ���׌x������
  cv_msg_15273              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15273';  -- �w�b�_�폜����
  cv_msg_15274              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15274';  -- ���׍폜����
  cv_msg_00147              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00147';  -- 20_���^�i�����j
  -- �g�[�N��
  cv_tkn_param              CONSTANT VARCHAR2(6)   := 'PARAME';
  cv_tkn_profile            CONSTANT VARCHAR2(7)   := 'PROFILE';
  cv_tkn_org_code_tok       CONSTANT VARCHAR2(12)  := 'ORG_CODE_TOK';
  cv_tkn_err_msg            CONSTANT VARCHAR2(7)   := 'ERR_MSG';
  cv_tkn_order_type         CONSTANT VARCHAR2(10)  := 'ORDER_TYPE';
  cv_tkn_key_data           CONSTANT VARCHAR2(8)   := 'KEY_DATA';
  cv_tkn_key_data1          CONSTANT VARCHAR2(9)   := 'KEY_DATA1';
  cv_tkn_key_data2          CONSTANT VARCHAR2(9)   := 'KEY_DATA2';
  cv_tkn_emp_code           CONSTANT VARCHAR2(8)   := 'EMP_CODE';
  cv_tkn_base_code          CONSTANT VARCHAR2(9)   := 'BASE_CODE';
  cv_tkn_item_code          CONSTANT VARCHAR2(9)   := 'ITEM_CODE';
  cv_tkn_table              CONSTANT VARCHAR2(5 )  := 'TABLE';
  cv_tkn_table_name         CONSTANT VARCHAR2(10)  := 'TABLE_NAME';
  cv_tkn_request_id         CONSTANT VARCHAR2(10)  := 'REQUEST_ID';
  cv_tkn_status             CONSTANT VARCHAR2(10)  := 'STATUS';
  -- �v���t�@�C��
  cv_prof_interval          CONSTANT VARCHAR2(27)  := 'XXCOS1_INTERVAL_XXCOS001A10';  -- XXCOS:�ҋ@�Ԋu�iHHT�󒍃C���|�[�g�j
  cv_prof_max_wait          CONSTANT VARCHAR2(27)  := 'XXCOS1_MAX_WAIT_XXCOS001A10';  -- XXCOS:�ő�ҋ@���ԁiHHT�󒍃C���|�[�g�j
-- Ver.1.1 E_�{�ғ�_14486(�ǉ��Ή�) DEL START
--  cv_prof_hon_uom           CONSTANT VARCHAR2(19)  := 'XXCOS1_HON_UOM_CODE';          -- XXCOS:�{�P�ʃR�[�h
-- Ver.1.1 E_�{�ғ�_14486(�ǉ��Ή�) DEL END
  cv_prof_organization      CONSTANT VARCHAR2(24)  := 'XXCOI1_ORGANIZATION_CODE';     -- XXCOI:�݌ɑg�D�R�[�h
  cv_prof_parge_date        CONSTANT VARCHAR2(27)  := 'XXCOS1_HHT_ORDER_PURGE_DATE';  -- XXCOS:HHT�󒍃f�[�^�捞�p�[�W�������Z�o�����
  cv_org_id                 CONSTANT VARCHAR2(6)   := 'ORG_ID';                       -- MO:�c�ƒP��
  -- �p�����[�^
  cv_mode_day               CONSTANT VARCHAR2(1)   := '1';                            -- ��������
  cv_mode_night             CONSTANT VARCHAR2(1)   := '2';                            -- ��ԏ���
  cv_mode_parge             CONSTANT VARCHAR2(1)   := '3';                            -- ���[�N�e�[�u���p�[�W����
  -- �Q�ƃ^�C�v�R�[�h
  cv_odr_src_mst_001_a10    CONSTANT VARCHAR2(26)  := 'XXCOS1_ODR_SRC_MST_001_A10';   -- �󒍃\�[�X
  cv_txn_type_mst_001_a10   CONSTANT VARCHAR2(27)  := 'XXCOS1_TXN_TYPE_MST_001_A10';  -- �󒍃^�C�v
  cv_001_a10_01             CONSTANT VARCHAR2(16)  := 'XXCOS_001_A10_01';             -- �Q�ƃ^�C�v�R�[�h�i00_�ʏ�󒍁j
  cv_001_a10_02             CONSTANT VARCHAR2(16)  := 'XXCOS_001_A10_02';             -- �Q�ƃ^�C�v�R�[�h�i10_�ʏ�o�ׁj
  cv_001_a10_03             CONSTANT VARCHAR2(16)  := 'XXCOS_001_A10_03';             -- �Q�ƃ^�C�v�R�[�h�i20_���^�j
  cv_edi_item_err_type      CONSTANT VARCHAR2(24)  := 'XXCOS1_EDI_ITEM_ERR_TYPE';     -- �G���[�i��
  -- ����
  cv_language               CONSTANT VARCHAR2(10)  := USERENV( 'LANG' );
  -- ���t�`��
  cv_date_format            CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  -- �V�X�e�����t
  cd_sysdate                CONSTANT DATE          := SYSDATE;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �󒍏���OIF�e�[�u�����R�[�h�^�C�v��`
  TYPE g_order_oif_actions_rtype  IS RECORD
    (
       order_source_id        oe_actions_iface_all.order_source_id%TYPE        -- �C���|�[�g�\�[�XID
      ,orig_sys_document_ref  oe_actions_iface_all.orig_sys_document_ref%TYPE  -- �O���V�X�e���󒍔ԍ�
      ,operation_code         oe_actions_iface_all.operation_code%TYPE         -- �I�y���[�V�����R�[�h
      );
  -- �󒍃w�b�_OIF�e�[�u�����R�[�h�^�C�v��`
  TYPE g_order_oif_header_rtype  IS RECORD (
     order_source_id        oe_headers_iface_all.order_source_id%TYPE        -- �C���|�[�g�\�[�XID
    ,order_type_id          oe_headers_iface_all.order_type_id%TYPE          -- �󒍃^�C�vID
    ,orig_sys_document_ref  oe_headers_iface_all.orig_sys_document_ref%TYPE  -- �O���V�X�e���󒍔ԍ�
    ,org_id                 oe_headers_iface_all.org_id%TYPE                 -- �g�DID
    ,salesrep_id            oe_headers_iface_all.salesrep_id%TYPE            -- �S���c��ID
    ,ordered_date           oe_headers_iface_all.ordered_date%TYPE           -- �󒍓�
    ,customer_po_number     oe_headers_iface_all.customer_po_number%TYPE     -- �ڋq�����ԍ�
    ,customer_number        oe_headers_iface_all.customer_number%TYPE        -- �ڋq�R�[�h
    ,request_date           oe_headers_iface_all.request_date%TYPE           -- �v����
    ,context                oe_headers_iface_all.context%TYPE                -- �R���e�L�X�g
    ,attribute12            oe_headers_iface_all.attribute12%TYPE            -- �����p���_
    ,attribute19            oe_headers_iface_all.attribute19%TYPE            -- �I�[�_�[No
    ,attribute5             oe_headers_iface_all.attribute5%TYPE             -- �`�[�敪
    ,attribute20            oe_headers_iface_all.attribute20%TYPE            -- ���ދ敪
    ,global_attribute4      oe_headers_iface_all.global_attribute4%TYPE      -- ��No.(HHT)
    ,global_attribute5      oe_headers_iface_all.global_attribute5%TYPE      -- �������敪
  );
  -- �󒍖���OIF�e�[�u�����R�[�h�^�C�v��`
  TYPE g_order_oif_line_rtype   IS RECORD (
     order_source_id        oe_lines_iface_all.order_source_id%TYPE        -- �C���|�[�g�\�[�XID
    ,line_type_id           oe_lines_iface_all.line_type_id%TYPE           -- ���׃^�C�vID
    ,orig_sys_document_ref  oe_lines_iface_all.orig_sys_document_ref%TYPE  -- �O���V�X�e���󒍔ԍ�
    ,orig_sys_line_ref      oe_lines_iface_all.orig_sys_line_ref%TYPE      -- �O���V�X�e���󒍖��הԍ�
    ,org_id                 oe_lines_iface_all.org_id%TYPE                 -- �g�DID
    ,line_number            oe_lines_iface_all.line_number%TYPE            -- ���הԍ�
    ,inventory_item         oe_lines_iface_all.inventory_item%TYPE         -- �󒍕i��
    ,ordered_quantity       oe_lines_iface_all.ordered_quantity%TYPE       -- �󒍐���
    ,order_quantity_uom     oe_lines_iface_all.order_quantity_uom%TYPE     -- �󒍒P��
    ,customer_po_number     oe_lines_iface_all.customer_po_number%TYPE     -- �ڋq�����ԍ�
    ,customer_line_number   oe_lines_iface_all.customer_line_number%TYPE   -- �ڋq�������הԍ�
    ,request_date           oe_lines_iface_all.request_date%TYPE           -- �v����
    ,unit_list_price        oe_lines_iface_all.unit_selling_price%TYPE     -- �W���P��
    ,unit_selling_price     oe_lines_iface_all.unit_selling_price%TYPE     -- �̔��P��
    ,subinventory           oe_lines_iface_all.subinventory%TYPE           -- �ۊǏꏊ
    ,context                oe_lines_iface_all.context%TYPE                -- �R���e�L�X�g
    ,attribute5             oe_lines_iface_all.attribute5%TYPE             -- ����敪
    ,attribute10            oe_lines_iface_all.attribute10%TYPE            -- ���P��
    ,calculate_price_flag   oe_lines_iface_all.calculate_price_flag%TYPE   -- ���i�v�Z�t���O
  );
--
  TYPE g_hht_order_header_ttype   IS TABLE OF xxcos_hht_order_headers%ROWTYPE INDEX BY BINARY_INTEGER; -- HHT�󒍃w�b�_�e�[�u��
  TYPE g_hht_order_line_ttype     IS TABLE OF xxcos_hht_order_lines%ROWTYPE   INDEX BY BINARY_INTEGER; -- HHT�󒍖��׃e�[�u��
  TYPE g_order_oif_actions_ttype  IS TABLE OF g_order_oif_actions_rtype       INDEX BY BINARY_INTEGER; -- �󒍏���OIF
  TYPE g_order_oif_header_ttype   IS TABLE OF g_order_oif_header_rtype        INDEX BY BINARY_INTEGER; -- �󒍃w�b�_OIF
  TYPE g_order_oif_line_ttype     IS TABLE OF g_order_oif_line_rtype          INDEX BY BINARY_INTEGER; -- �󒍖���OIF
--
  gt_hht_order_header   g_hht_order_header_ttype;
  gt_hht_order_line     g_hht_order_line_ttype;
  gt_order_oif_actions  g_order_oif_actions_ttype;
  gt_order_oif_header   g_order_oif_header_ttype;
  gt_order_oif_line     g_order_oif_line_ttype;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �v���t�@�C��
  gn_interval           NUMBER;       -- XXCOS:�ҋ@�Ԋu�iHHT�󒍃C���|�[�g�j
  gn_max_wait           NUMBER;       -- XXCOS:�ő�ҋ@���ԁiHHT�󒍃C���|�[�g�j
-- Ver.1.1 E_�{�ғ�_14486(�ǉ��Ή�) DEL START
--  gv_hon_uom            VARCHAR2(50); -- XXCOS:�{�P�ʃR�[�h
-- Ver.1.1 E_�{�ғ�_14486(�ǉ��Ή�) DEL END
  gv_organization       VARCHAR2(50); -- XXCOI:�݌ɑg�D�R�[�h
  gn_parge_date         NUMBER;       -- XXCOS:HHT�󒍃f�[�^�捞�p�[�W�������Z�o�����
  gn_org_id             NUMBER;       -- MO:�c�ƒP��
  gn_organization_id    NUMBER;       -- �݌ɑg�DID
  -- ��OIF�p
  gt_order_source_id    oe_order_sources.order_source_id%TYPE;             -- �󒍃\�[�XID
  gt_order_source_name  oe_order_sources.name%TYPE;                        -- �C���|�[�g�\�[�X����
  gt_order_type_id_h    oe_transaction_types_all.transaction_type_id%TYPE; -- ����^�C�vID�i�w�b�_�j
  gt_order_type_id_l    oe_transaction_types_all.transaction_type_id%TYPE; -- ����^�C�vID�i���ׁj
  gt_order_type_name_h  oe_transaction_types_tl.name%TYPE;                 -- ����^�C�v���́i�w�b�_�j
  gt_order_type_name_l  oe_transaction_types_tl.name%TYPE;                 -- ����^�C�v���́i���ׁj
  gt_order_type_id_l_20 oe_transaction_types_all.transaction_type_id%TYPE; -- ����^�C�vID�i20_���^�j
  gt_order_type_name_l_20 oe_transaction_types_tl.name%TYPE;               -- ����^�C�v���́i20_���^�j
  -- �󒍃C���|�[�g�G���[���m�p
  gv_import_status VARCHAR2(1);  --�󒍃C���|�[�g�G���[���m�̌x�����X�e�[�^�X�ێ��p
  -- �e���������p
  gn_h_target_cnt  NUMBER;  -- �w�b�_�Ώی���
  gn_l_target_cnt  NUMBER;  -- ���בΏی���
  gn_h_insert_cnt  NUMBER;  -- �w�b�_�}������
  gn_l_insert_cnt  NUMBER;  -- ���ב}������
  gn_h_warn_cnt    NUMBER;  -- �w�b�_�x������
  gn_l_warn_cnt    NUMBER;  -- ���׌x������
  gn_h_delete_cnt  NUMBER;  -- �w�b�_�폜����
  gn_l_delete_cnt  NUMBER;  -- ���׌x������
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_mode       IN  VARCHAR2,     -- 1.�N�����[�h�i1:���� 2:��� 3:���[�N�e�[�u���p�[�W�j
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ------------------------------------
    -- �p�����[�^�o��
    ------------------------------------
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   => cv_xxcos_appl_short_name
                   ,iv_name          => cv_msg_15251
                   ,iv_token_name1   => cv_tkn_param               -- �p�����[�^
                   ,iv_token_value1  => iv_mode                    -- �N�����[�h
                  );
    -- �o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- �o��(��s)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- ���O
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- ���O
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    ------------------------------------
    -- �v���t�@�C���擾
    ------------------------------------
    -- ���������̏ꍇ
    IF ( iv_mode = cv_mode_day ) THEN
--
      -- XXCOS:�ҋ@�Ԋu�iHHT�󒍃C���|�[�g�j
      gn_interval := TO_NUMBER( fnd_profile.value( cv_prof_interval ) );
      --
      IF ( gn_interval IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_00004
                      ,iv_token_name1   => cv_tkn_profile             -- �v���t�@�C��
                      ,iv_token_value1  => cv_prof_interval           -- �v���t�@�C����
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      -- XXCOS:�ő�ҋ@���ԁiHHT�󒍃C���|�[�g�j
      gn_max_wait := TO_NUMBER( fnd_profile.value( cv_prof_max_wait ) );
--
      IF ( gn_max_wait IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_00004
                      ,iv_token_name1   => cv_tkn_profile             -- �v���t�@�C��
                      ,iv_token_value1  => cv_prof_max_wait           -- �v���t�@�C����
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
-- Ver.1.1 E_�{�ғ�_14486(�ǉ��Ή�) DEL START
--      -- XXCOS:�{�P�ʃR�[�h
--      gv_hon_uom := fnd_profile.value( cv_prof_hon_uom );
----
--      IF ( gv_hon_uom IS NULL ) THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application   => cv_xxcos_appl_short_name
--                      ,iv_name          => cv_msg_00004
--                      ,iv_token_name1   => cv_tkn_profile             -- �v���t�@�C��
--                      ,iv_token_value1  => cv_prof_hon_uom            -- �v���t�@�C����
--                     );
--        lv_errbuf := lv_errmsg;
--        RAISE global_process_expt;
--      END IF;
-- Ver.1.1 E_�{�ғ�_14486(�ǉ��Ή�) DEL END
--
      -- XXCOI:�݌ɑg�D�R�[�h
      gv_organization := fnd_profile.value( cv_prof_organization );
--
      IF ( gv_organization IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_00004
                      ,iv_token_name1   => cv_tkn_profile             -- �v���t�@�C��
                      ,iv_token_value1  => cv_prof_organization       -- �v���t�@�C����
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
    -- ��ԏ����̏ꍇ
    ELSIF ( iv_mode = cv_mode_night ) THEN
--
      -- XXCOS: HHT�󒍃f�[�^�捞�p�[�W�������Z�o�����
      gn_parge_date := fnd_profile.value( cv_prof_parge_date );
--
      IF ( gn_parge_date IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_00004
                      ,iv_token_name1   => cv_tkn_profile             -- �v���t�@�C��
                      ,iv_token_value1  => cv_prof_parge_date         -- �v���t�@�C����
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    ------------------------------------
    -- �c�ƒP��ID�̎擾
    ------------------------------------
    -- ���������̏ꍇ�̂�
    IF ( iv_mode = cv_mode_day ) THEN
--
      -- MO:�c�ƒP��
      gn_org_id  := TO_NUMBER( fnd_profile.value( cv_org_id ) );
--
    END IF;
--
    ------------------------------------
    -- �݌ɑg�DID�̎擾
    ------------------------------------
    -- ���������̏ꍇ�̂�
    IF ( iv_mode = cv_mode_day ) THEN
--
      -- �݌ɑg�DID
      gn_organization_id := xxcoi_common_pkg.get_organization_id(
                              iv_organization_code  => gv_organization
                            );
--
      IF ( gn_organization_id IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application        => cv_xxcos_appl_short_name
                       ,iv_name               => cv_msg_00091
                       ,iv_token_name1        => cv_tkn_org_code_tok  -- �݌ɑg�D�R�[�h
                       ,iv_token_value1       => gv_organization      -- �݌ɑg�D�R�[�h
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    ------------------------------------
    -- ��OIF�ɐݒ肷����e�̎擾
    ------------------------------------
    -- ���������̏ꍇ�̂�
    IF ( iv_mode = cv_mode_day ) THEN
--
      -- �󒍃\�[�X
      BEGIN
        SELECT oos.order_source_id  order_source_id    -- �󒍃\�[�XID
              ,oos.name             order_source_name  -- �C���|�[�g�\�[�X����
        INTO   gt_order_source_id
              ,gt_order_source_name
        FROM   oe_order_sources     oos  -- �󒍃\�[�X
              ,fnd_lookup_values_vl flvv -- �Q�ƃ^�C�v
        WHERE  flvv.lookup_type = cv_odr_src_mst_001_a10
        AND    flvv.lookup_code = cv_001_a10_01
        AND    flvv.meaning     = oos.name
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application        => cv_xxcos_appl_short_name
                         ,iv_name               => cv_msg_15260
                         ,iv_token_name1        => cv_tkn_err_msg
                         ,iv_token_value1       => SQLERRM
                        );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      -- �󒍃w�b�_�^�C�v
      BEGIN
        SELECT otl.transaction_type_id  transaction_type_id  --����^�C�vID
              ,ott.name                 order_type_name      --����^�C�v����
        INTO   gt_order_type_id_h
              ,gt_order_type_name_h
        FROM   oe_transaction_types_all otl -- �󒍎���^�C�v
              ,oe_transaction_types_tl  ott -- �󒍎���^�C�v�i�E�v�j
              ,fnd_lookup_values_vl     flv -- �Q�ƃ^�C�v
        WHERE  flv.lookup_type           = cv_txn_type_mst_001_a10
        AND    flv.lookup_code           = cv_001_a10_01
        AND    flv.meaning               = ott.name
        AND    ott.language              = cv_language
        AND    ott.transaction_type_id   = otl.transaction_type_id
       ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application        => cv_xxcos_appl_short_name
                         ,iv_name               => cv_msg_15261
                         ,iv_token_name1        => cv_tkn_order_type
                         ,iv_token_value1       => cv_msg_00122
                         ,iv_token_name2        => cv_tkn_err_msg
                         ,iv_token_value2       => SQLERRM
                        );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      -- �󒍖��׃^�C�v�i10_�ʏ�o�ׁj
      BEGIN
        SELECT otl.transaction_type_id  transaction_type_id  -- ����^�C�vID
              ,ott.name                 order_type_name      -- ����^�C�v����
        INTO   gt_order_type_id_l
              ,gt_order_type_name_l
        FROM   oe_transaction_types_all otl -- �󒍎���^�C�v
              ,oe_transaction_types_tl  ott -- �󒍎���^�C�v�i�E�v�j
              ,fnd_lookup_values_vl     flv -- �Q�ƃ^�C�v
        WHERE  flv.lookup_type           = cv_txn_type_mst_001_a10
        AND    flv.lookup_code           = cv_001_a10_02
        AND    flv.meaning               = ott.name
        AND    ott.language              = cv_language
        AND    ott.transaction_type_id   = otl.transaction_type_id
       ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application        => cv_xxcos_appl_short_name
                         ,iv_name               => cv_msg_15261
                         ,iv_token_name1        => cv_tkn_order_type
                         ,iv_token_value1       => cv_msg_00121
                         ,iv_token_name2        => cv_tkn_err_msg
                         ,iv_token_value2       => SQLERRM
                        );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      -- �󒍖��׃^�C�v�i20_���^�j
      BEGIN
        SELECT otl.transaction_type_id  transaction_type_id  -- ����^�C�vID
              ,ott.name                 order_type_name      -- ����^�C�v����
        INTO   gt_order_type_id_l_20
              ,gt_order_type_name_l_20
        FROM   oe_transaction_types_all otl -- �󒍎���^�C�v
              ,oe_transaction_types_tl  ott -- �󒍎���^�C�v�i�E�v�j
              ,fnd_lookup_values_vl     flv -- �Q�ƃ^�C�v
        WHERE  flv.lookup_type           = cv_txn_type_mst_001_a10
        AND    flv.lookup_code           = cv_001_a10_03
        AND    flv.meaning               = ott.name
        AND    ott.language              = cv_language
        AND    ott.transaction_type_id   = otl.transaction_type_id
       ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application        => cv_xxcos_appl_short_name
                         ,iv_name               => cv_msg_15261
                         ,iv_token_name1        => cv_tkn_order_type
                         ,iv_token_value1       => cv_msg_00147
                         ,iv_token_name2        => cv_tkn_err_msg
                         ,iv_token_value2       => SQLERRM
                        );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
   * Procedure Name   : get_work_data
   * Description      : ���[�N�e�[�u���f�[�^���o(A-2)
   ***********************************************************************************/
  PROCEDURE get_work_data(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_work_data'; -- �v���O������
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
    cv_delete_flag_n         CONSTANT VARCHAR2(1)  := 'N';
    cv_category_employee     CONSTANT VARCHAR2(8)  := 'EMPLOYEE';
    cv_resource_group_number CONSTANT VARCHAR2(15) := 'RS_GROUP_MEMBER';
    cv_person_type           CONSTANT VARCHAR2(3)  := 'EMP';
    cv_active_flag_y         CONSTANT VARCHAR2(1)  := 'Y';
    cd_last_day              CONSTANT DATE         :=  TO_DATE( '9999/12/31', cv_date_format );
    cv_orig_sys_doc_ref      CONSTANT VARCHAR2(29) := 'OE_ORDER_HEADERS_XXCOS001A10_';
    cv_err_item_1            CONSTANT VARCHAR2(1)  := '1';
    cv_err_item_2            CONSTANT VARCHAR2(1)  := '2';
    cv_err_item_3            CONSTANT VARCHAR2(1)  := '3';
    cv_y                     CONSTANT VARCHAR2(1)  := 'Y';
    cv_n                     CONSTANT VARCHAR2(1)  := 'N';
    cv_sales_target_flag     CONSTANT VARCHAR2(1)  := '1';
    cv_create_hht            CONSTANT VARCHAR2(1)  := '1';
    cv_operation_code        CONSTANT VARCHAR2(10) := 'BOOK_ORDER';
    cv_sale_class_5          CONSTANT VARCHAR2(1)  := '5';                      -- ����敪�u5�i���^�j�v
--
    -- *** ���[�J���ϐ� ***
    lt_customer_id        xxcmm_cust_accounts.customer_id%TYPE;                 -- �ڋqID
    lt_ship_storage_code  xxcmm_cust_accounts.ship_storage_code%TYPE;           -- �o�׌��ۊǏꏊ
    lt_salesrep_id        jtf_rs_salesreps.salesrep_id%TYPE;                    -- �c�ƒS��ID
    lt_salesrep_number    jtf_rs_salesreps.salesrep_number%TYPE;                -- �]�ƈ��R�[�h
    lv_storage_location   VARCHAR2(10);                                         -- �ۊǏꏊ
    lt_orig_sys_doc_ref   oe_order_headers_all.orig_sys_document_ref%TYPE;      -- �O���V�X�e���ԍ�
    ln_orig_sys_seq       NUMBER;                                               -- �O���V�X�e���ԍ��̘A��
    ln_line_data_cnt      NUMBER;                                               -- ���׌���
    lt_item_code          mtl_system_items_b.segment1%TYPE;                     -- �i�ڃR�[�h
    lt_cust_order_e_flag  mtl_system_items_b.customer_order_enabled_flag%TYPE;  -- �ڋq�󒍉\�t���O
-- Ver.1.1 E_�{�ғ�_14486(�ǉ��Ή�) ADD START
    lt_primary_uom_code   mtl_system_items_b.primary_uom_code%TYPE;             -- �i�ڊ�P�ʃR�[�h
-- Ver.1.1 E_�{�ғ�_14486(�ǉ��Ή�) ADD END
    lt_sales_target_class ic_item_mst_b.attribute26%TYPE;                       -- ����Ώۋ敪
    lv_item_err_flag      VARCHAR2(1);                                          -- �i�ڂ̃G���[����p�t���O
    cn_h_cnt              NUMBER;                                               -- �w�b�_�z��p�J�E���^
    cn_l_cnt              NUMBER;                                               -- ���הz��p�J�E���^
    cv_warn_flag          VARCHAR2(1);                                          -- �x���t���O�i�����o�͐���p�j
--
    -- *** ���[�J���E�J�[�\�� ***
    -- HHT�󒍃w�b�_���[�N�e�[�u��
    CURSOR get_header_data_cur
    IS
      SELECT xhohw.order_no_hht           order_no_hht           -- ��No.(HHT)
            ,xhohw.base_code              base_code              -- ���_�R�[�h
            ,xhohw.dlv_by_code            dlv_by_code            -- �[�i�҃R�[�h
            ,xhohw.invoice_no             invoice_no             -- �`�[No.
            ,xhohw.dlv_date               dlv_date               -- �[�i�\���
            ,xhohw.sales_classification   sales_classification   -- ���㕪�ދ敪
            ,xhohw.sales_invoice          sales_invoice          -- ����`�[�敪
            ,xhohw.dlv_time               dlv_time               -- ����
            ,xhohw.customer_number        customer_number        -- �ڋq�R�[�h
            ,xhohw.consumption_tax_class  consumption_tax_class  -- ����ŋ敪
            ,xhohw.total_amount           total_amount           -- ���v���z
            ,xhohw.sales_consumption_tax  sales_consumption_tax  -- �������Ŋz
            ,xhohw.tax_include            tax_include            -- �ō����z
            ,xhohw.system_date            system_date            -- �V�X�e�����t
            ,xhohw.order_no               order_no               -- �I�[�_�[No
            ,xhohw.received_date          received_date          -- ��M����
      FROM   xxcos_hht_order_headers_work xhohw  -- HHT�󒍃w�b�_���[�N�e�[�u��
      FOR UPDATE NOWAIT
      ;
--
    -- HHT�󒍖��׃��[�N�e�[�u��
    CURSOR get_line_data_cur(
      it_order_no_hht IN xxcos_hht_order_lines_work.order_no_hht%TYPE
    )
    IS
      SELECT xholw.order_no_hht          order_no_hht         -- ��No.(HHT)
            ,xholw.line_no_hht           line_no_hht          -- �sNo.(HHT)
            ,xholw.item_code_self        item_code_self       -- �i���R�[�h(����)
            ,xholw.case_number           case_number          -- �P�[�X��
            ,xholw.quantity              quantity             -- ����
            ,xholw.sale_class            sale_class           -- ����敪
            ,xholw.wholesale_unit_plice  wholesale_unit_plice -- ���P��
            ,xholw.selling_price         selling_price        -- ���P��
            ,xholw.received_date         received_date        -- ��M����
      FROM   xxcos_hht_order_lines_work xholw  -- HHT�󒍖��׃��[�N�e�[�u��
      WHERE  xholw.order_no_hht = it_order_no_hht
      FOR UPDATE NOWAIT
      ;
--
    -- ���_�̍ŏ�ʉc�ƒS���擾
    CURSOR get_top_emp_code(
       it_sales_base_code IN jtf_rs_groups_b.attribute1%TYPE
      ,id_target_date     IN DATE
    )
    IS
      SELECT jrs.salesrep_id           salesrep_id            --�S���c�ƈ�ID
            ,jrs.salesrep_number       salesrep_number        --�]�ƈ��R�[�h
      FROM   per_person_types          pept_n                 --�]�ƈ��^�C�v
            ,per_periods_of_service    ppos_n                 --�]�ƈ��T�[�r�X
            ,per_all_assignments_f     paaf_n                 --�A�T�C�����g
            ,per_all_people_f          papf_n                 --�]�ƈ�
            ,jtf_rs_resource_extns     jrrx_n                 --���\�[�X
            ,jtf_rs_group_members      jrgm_n                 --�O���[�v�����o�[
            ,jtf_rs_groups_b           jrgb_n                 --���\�[�X�O���[�v
            ,jtf_rs_role_relations     jrrr                   --����
            ,jtf_rs_salesreps          jrs                    --�c�ƒS��
      WHERE  jrgb_n.attribute1            = it_sales_base_code  --���_�R�[�h
      AND    jrgb_n.group_id              = jrgm_n.group_id
      AND    jrgm_n.delete_flag           = cv_delete_flag_n
      AND    jrgm_n.resource_id           = jrrx_n.resource_id
      AND    jrrx_n.category              = cv_category_employee
      AND    jrrr.role_resource_id        = jrgm_n.group_member_id
      AND    jrrr.role_resource_type      = cv_resource_group_number
      AND    jrrr.delete_flag             = cv_delete_flag_n
      AND    jrrr.start_date_active      <= id_target_date
      AND    NVL( jrrr.end_date_active, id_target_date ) >= id_target_date
      AND    jrrx_n.source_id             = papf_n.person_id
      AND    papf_n.person_id             = paaf_n.person_id
      AND    paaf_n.period_of_service_id  = ppos_n.period_of_service_id
      AND    ppos_n.actual_termination_date IS NULL
      AND    papf_n.person_type_id        = pept_n.person_type_id
      AND    id_target_date BETWEEN papf_n.effective_start_date
                            AND     NVL( papf_n.effective_end_date, cd_last_day )
      AND    pept_n.system_person_type    = cv_person_type
      AND    pept_n.active_flag           = cv_active_flag_y
      AND    jrrx_n.resource_id           = jrs.resource_id
      AND    jrs.org_id                   = gn_org_id
      AND    TRUNC( jrs.start_date_active ) <= TRUNC( id_target_date )
      AND    TRUNC( NVL( jrs.end_date_active, id_target_date ) )
                                            >= TRUNC( id_target_date )
      ORDER BY
            paaf_n.ass_attribute11   -- �E�ʏ�
           ,ppos_n.date_start        -- ���Г�
           ,papf_n.employee_number   -- �]�ƈ��ԍ�
      ;
--
    -- *** ���[�J���E���R�[�h ***
    l_header_data_rec  get_header_data_cur%ROWTYPE;
    l_line_data_rec    get_line_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �z��p�J�E���^�̏�����
    cn_h_cnt := 0;
    cn_l_cnt := 0;
--
    ------------------------------------
    -- �w�b�_�f�[�^�擾
    ------------------------------------
    BEGIN
      OPEN get_header_data_cur;
    EXCEPTION
      WHEN lock_err_expt THEN
        -- ���b�Z�[�W�ҏW
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application        => cv_xxcos_appl_short_name
                       ,iv_name               => cv_msg_00001
                       ,iv_token_name1        => cv_tkn_table  -- �e�[�u��
                       ,iv_token_value1       => cv_msg_15252  -- �e�[�u����
                      );
        lv_errbuf := lv_errmsg;
        RAISE lock_err_expt;
    END;
--
    <<header_loop>>
    LOOP
--
      FETCH get_header_data_cur INTO l_header_data_rec;
      EXIT WHEN get_header_data_cur%NOTFOUND;
--
      -- ������
      lt_customer_id       := NULL;
      lt_ship_storage_code := NULL;
      lt_salesrep_id       := NULL;
      lt_salesrep_number   := NULL;
      lv_storage_location  := NULL;
      lt_orig_sys_doc_ref  := NULL;
      ln_orig_sys_seq      := NULL;
      ln_line_data_cnt     := 0;
      cv_warn_flag         := cv_n;
      -- �w�b�_�Ώی����J�E���g
      gn_h_target_cnt      := gn_h_target_cnt + 1;
--
      ------------------------------------
      -- �ڋq�R�[�h�������擾
      ------------------------------------
      SELECT xca.customer_id        customer_id        -- �ڋqID
            ,xca.ship_storage_code  ship_storage_code  -- �o�׌��ۊǏꏊ
      INTO   lt_customer_id
            ,lt_ship_storage_code
      FROM   xxcmm_cust_accounts  xca
      WHERE  xca.customer_code = l_header_data_rec.customer_number
      ;
--
      ------------------------------------
      -- �[�i�҃R�[�h�̃`�F�b�N
      ------------------------------------
      BEGIN
        SELECT jrs.salesrep_id      salesrep_id      -- �c�ƒS��ID
              ,jrs.salesrep_number  salesrep_number  -- �]�ƈ��R�[�h
        INTO   lt_salesrep_id
              ,lt_salesrep_number
        FROM   jtf_rs_salesreps  jrs --�c�ƒS��
        WHERE  jrs.salesrep_number  = l_header_data_rec.dlv_by_code
        AND    jrs.org_id           = gn_org_id
        AND    TRUNC( jrs.start_date_active ) <= TRUNC( l_header_data_rec.dlv_date )
        AND    TRUNC( NVL(jrs.end_date_active, l_header_data_rec.dlv_date ) )
                                              >= TRUNC( l_header_data_rec.dlv_date )
        ;
      EXCEPTION
        -- ���݂��Ȃ��ꍇ
        WHEN NO_DATA_FOUND THEN
          -- ���b�Z�[�W���o��
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application        => cv_xxcos_appl_short_name
                         ,iv_name               => cv_msg_15259
                         ,iv_token_name1        => cv_tkn_key_data1                -- �L�[�f�[�^
                         ,iv_token_value1       => l_header_data_rec.order_no_hht  -- ��No.(HHT)
                         ,iv_token_name2        => cv_tkn_emp_code                 -- �c�ƒS��
                         ,iv_token_value2       => l_header_data_rec.dlv_by_code   -- �[�i�҃R�[�h
                        );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
         );
         -- ���_�̍ŏ�ʎ҂̉c�ƒS�����擾
         OPEN get_top_emp_code(
                l_header_data_rec.base_code
               ,l_header_data_rec.dlv_date
              );
         FETCH get_top_emp_code INTO lt_salesrep_id
                                    ,lt_salesrep_number;
         CLOSE get_top_emp_code;
         -- ��������ׂ̈̃t���O�𗧂Ă�
         cv_warn_flag := cv_y;
      END;
--
      ------------------------------------
      -- �ۊǏꏊ�̑��݂��`�F�b�N
      ------------------------------------
      BEGIN
        SELECT msi.secondary_inventory_name
        INTO   lv_storage_location
        FROM   mtl_secondary_inventories msi
        WHERE  msi.attribute3      = lt_salesrep_number
        AND    msi.attribute7      = l_header_data_rec.base_code
        AND    msi.organization_id = gn_organization_id
        AND    ROWNUM = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���b�Z�[�W���o��
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application        => cv_xxcos_appl_short_name
                         ,iv_name               => cv_msg_15254
                         ,iv_token_name1        => cv_tkn_key_data1                 -- �L�[�f�[�^
                         ,iv_token_value1       => l_header_data_rec.order_no_hht   -- ��No.(HHT)
                         ,iv_token_name2        => cv_tkn_base_code                 -- ���_
                         ,iv_token_value2       => l_header_data_rec.base_code      -- ���_�R�[�h
                         ,iv_token_name3        => cv_tkn_emp_code                  -- �c�ƒS��
                         ,iv_token_value3       => lt_salesrep_number               -- �c�ƒS���R�[�h
                        );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
         );
         -- �ۊǏꏊ�Ƃ��Čڋq�̏o�׌��ۊǏꏊ��ݒ�
         lv_storage_location := lt_ship_storage_code;
         -- ��������ׂ̈̃t���O�𗧂Ă�
         cv_warn_flag := cv_y;
      END;
--
      -- �w�b�_�x�������̃J�E���g
      IF ( cv_warn_flag = cv_y ) THEN
        gn_h_warn_cnt := gn_h_warn_cnt + 1;
      END IF;
--
      ------------------------------------
      -- �O���V�X�e���󒍔ԍ���ҏW
      ------------------------------------
      SELECT xxcos_orig_sys_doc_ref_s02.NEXTVAL
      INTO   ln_orig_sys_seq
      FROM   DUAL
      ;
      lt_orig_sys_doc_ref := cv_orig_sys_doc_ref || ln_orig_sys_seq;
--
      ------------------------------------
      -- ���׃f�[�^�擾
      ------------------------------------
      BEGIN
        OPEN get_line_data_cur(
               l_header_data_rec.order_no_hht
             );
      EXCEPTION
        WHEN lock_err_expt THEN
          -- ���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application        => cv_xxcos_appl_short_name
                         ,iv_name               => cv_msg_00001
                         ,iv_token_name1        => cv_tkn_table  -- �e�[�u��
                         ,iv_token_value1       => cv_msg_15253  -- �e�[�u����
                        );
          lv_errbuf := lv_errmsg;
          RAISE lock_err_expt;
      END;
--
      <<line_loop>>
      LOOP
--
        FETCH get_line_data_cur INTO l_line_data_rec;
        EXIT WHEN get_line_data_cur%NOTFOUND;
--
        -- 1�`�[�ɕR�Â����׌����擾
        ln_line_data_cnt      := ln_line_data_cnt + 1;
        -- ������
        lt_item_code          := NULL;
        lt_cust_order_e_flag  := NULL;
        lt_sales_target_class := NULL;
        lv_item_err_flag      := cv_n;
        cv_warn_flag          := cv_n;
        -- ���בΏی����J�E���g
        gn_l_target_cnt       := gn_l_target_cnt + 1;
--
        ------------------------------------
        -- �i�ڃR�[�h�i���Ёj�̑��݂��`�F�b�N
        ------------------------------------
        BEGIN
          SELECT msib.segment1                     item_code
                ,msib.customer_order_enabled_flag  customer_order_enabled_flag
-- Ver.1.1 E_�{�ғ�_14486(�ǉ��Ή�) ADD START
                ,msib.primary_uom_code             primary_uom_code
-- Ver.1.1 E_�{�ғ�_14486(�ǉ��Ή�) ADD END
                ,iimb.attribute26                  sales_target_class
          INTO   lt_item_code
                ,lt_cust_order_e_flag
-- Ver.1.1 E_�{�ғ�_14486(�ǉ��Ή�) ADD START
                ,lt_primary_uom_code
-- Ver.1.1 E_�{�ғ�_14486(�ǉ��Ή�) ADD END
                ,lt_sales_target_class
          FROM   mtl_system_items_b msib  -- Disc�i��
                ,ic_item_mst_b      iimb  -- OPM�i��
          WHERE  msib.segment1         = l_line_data_rec.item_code_self  -- �i�ڃR�[�h
          AND    msib.organization_id  = gn_organization_id              -- �݌ɑg�DID
          AND    msib.segment1         = iimb.item_no                    -- �i�ڃR�[�h
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���b�Z�[�W���o��
            lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application        => cv_xxcos_appl_short_name
                           ,iv_name               => cv_msg_15256
                           ,iv_token_name1        => cv_tkn_key_data1                -- �L�[�f�[�^1
                           ,iv_token_value1       => l_header_data_rec.order_no_hht  -- ��No.(HHT)
                           ,iv_token_name2        => cv_tkn_key_data2                -- �L�[�f�[�^
                           ,iv_token_value2       => l_line_data_rec.line_no_hht     -- �sNo.(HHT)
                           ,iv_token_name3        => cv_tkn_item_code                -- �i��
                           ,iv_token_value3       => l_line_data_rec.item_code_self  -- �i�ڃR�[�h
                          );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
           );
           -- �G���[�i�ڂ��擾�i�}�X�^�[���o�^�G���[�i�ځj
          SELECT msib.segment1  item_code
          INTO   lt_item_code
          FROM   mtl_system_items_b msib  -- Disc�i��
                ,ic_item_mst_b      iimb  -- OPM�i��
          WHERE  msib.segment1         = (
                   SELECT  flvv.lookup_code
                   FROM    fnd_lookup_values_vl flvv
                   WHERE   flvv.lookup_type = cv_edi_item_err_type
                   AND     flvv.attribute1  = cv_err_item_1
                 )                                           -- �i�ڃR�[�h
          AND    msib.organization_id  = gn_organization_id  -- �݌ɑg�DID
          AND    msib.segment1         = iimb.item_no        -- �i�ڃR�[�h
          ;
          -- �G���[�t���O�𗧂Ă�
          lv_item_err_flag := cv_y;
          -- ��������ׂ̈̃t���O�𗧂Ă�
          cv_warn_flag     := cv_y;
        END;
--
        -- �ڋq�󒍉\�t���O�̃`�F�b�N�i�i�ڂ��擾�ł��āA�󒍉\�t���O��N�j
        IF ( lv_item_err_flag = cv_n AND lt_cust_order_e_flag = cv_n ) THEN
            -- ���b�Z�[�W���o��
            lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application        => cv_xxcos_appl_short_name
                           ,iv_name               => cv_msg_15258
                           ,iv_token_name1        => cv_tkn_key_data1                -- �L�[�f�[�^1
                           ,iv_token_value1       => l_header_data_rec.order_no_hht  -- ��No.(HHT)
                           ,iv_token_name2        => cv_tkn_key_data2                -- �L�[�f�[�^
                           ,iv_token_value2       => l_line_data_rec.line_no_hht     -- �sNo.(HHT)
                           ,iv_token_name3        => cv_tkn_item_code                -- �i��
                           ,iv_token_value3       => l_line_data_rec.item_code_self  -- �i�ڃR�[�h
                          );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
           );
           -- �G���[�i�ڂ��擾�i�i�ڃX�e�[�^�X�G���[�j
          SELECT msib.segment1  item_code
          INTO   lt_item_code
          FROM   mtl_system_items_b msib  -- Disc�i��
                ,ic_item_mst_b      iimb  -- OPM�i��
          WHERE  msib.segment1         = (
                   SELECT  flvv.lookup_code
                   FROM    fnd_lookup_values_vl flvv
                   WHERE   flvv.lookup_type = cv_edi_item_err_type
                   AND     flvv.attribute1  = cv_err_item_2
                 )                                           -- �i�ڃR�[�h
          AND    msib.organization_id  = gn_organization_id  -- �݌ɑg�DID
          AND    msib.segment1         = iimb.item_no        -- �i�ڃR�[�h
          ;
          -- �G���[�t���O�𗧂Ă�
          lv_item_err_flag := cv_y;
          -- ��������ׂ̈̃t���O�𗧂Ă�
          cv_warn_flag     := cv_y;
        END IF;
--
        -- ����敪�̃`�F�b�N�i�i�ڂ��擾�ł��āA�󒍉\�t���O��Y�A����敪��1�ȊO�j
        IF ( lv_item_err_flag = cv_n AND lt_sales_target_class <> cv_sales_target_flag ) THEN
            -- ���b�Z�[�W���o��
            lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application        => cv_xxcos_appl_short_name
                           ,iv_name               => cv_msg_15257
                           ,iv_token_name1        => cv_tkn_key_data1                -- �L�[�f�[�^1
                           ,iv_token_value1       => l_header_data_rec.order_no_hht  -- ��No.(HHT)
                           ,iv_token_name2        => cv_tkn_key_data2                -- �L�[�f�[�^
                           ,iv_token_value2       => l_line_data_rec.line_no_hht     -- �sNo.(HHT)
                           ,iv_token_name3        => cv_tkn_item_code                -- �i��
                           ,iv_token_value3       => l_line_data_rec.item_code_self  -- �i�ڃR�[�h
                          );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
           -- �G���[�i�ڂ��擾�i����敪�G���[�j
          SELECT msib.segment1  item_code
          INTO   lt_item_code
          FROM   mtl_system_items_b msib  -- Disc�i��
                ,ic_item_mst_b      iimb  -- OPM�i��
          WHERE  msib.segment1         = (
                   SELECT  flvv.lookup_code
                   FROM    fnd_lookup_values_vl flvv
                   WHERE   flvv.lookup_type = cv_edi_item_err_type
                   AND     flvv.attribute1  = cv_err_item_3
                 )                                           -- �i�ڃR�[�h
          AND    msib.organization_id  = gn_organization_id  -- �݌ɑg�DID
          AND    msib.segment1         = iimb.item_no        -- �i�ڃR�[�h
          ;
          -- ��������ׂ̈̃t���O�𗧂Ă�
          cv_warn_flag := cv_y;
        END IF;
--
        -- ���׌x�������̃J�E���g
        IF ( cv_warn_flag = cv_y ) THEN
          gn_l_warn_cnt := gn_l_warn_cnt + 1;
        END IF;
--
        -- ���הz��p�̃J�E���g�A�b�v
        cn_l_cnt := cn_l_cnt + 1;
--
        ------------------------------------
        -- HHT�󒍖��׃e�[�u���̔z��ݒ�
        ------------------------------------
        gt_hht_order_line(cn_l_cnt).order_no_hht           := l_line_data_rec.order_no_hht;         -- ��No.(HHT)
        gt_hht_order_line(cn_l_cnt).line_no_hht            := l_line_data_rec.line_no_hht;          -- �sNo.(HHT)
        gt_hht_order_line(cn_l_cnt).item_code_self         := l_line_data_rec.item_code_self;       -- �i���R�[�h(����)
        gt_hht_order_line(cn_l_cnt).item_code_conv         := lt_item_code;                         -- �ϊ���i�ڃR�[�h
        gt_hht_order_line(cn_l_cnt).subinventory_code      := lv_storage_location;                  -- �ۊǏꏊ�R�[�h
        gt_hht_order_line(cn_l_cnt).case_number            := l_line_data_rec.case_number;          -- �P�[�X��
        gt_hht_order_line(cn_l_cnt).quantity               := l_line_data_rec.quantity;             -- ����
        gt_hht_order_line(cn_l_cnt).sale_class             := l_line_data_rec.sale_class;           -- ����敪
        gt_hht_order_line(cn_l_cnt).wholesale_unit_plice   := l_line_data_rec.wholesale_unit_plice; -- ���P��
        gt_hht_order_line(cn_l_cnt).selling_price          := l_line_data_rec.selling_price;        -- ���P��
        gt_hht_order_line(cn_l_cnt).received_date          := l_line_data_rec.received_date;        -- ��M����
        gt_hht_order_line(cn_l_cnt).created_by             := cn_created_by;                        -- �쐬��
        gt_hht_order_line(cn_l_cnt).creation_date          := cd_creation_date;                     -- �쐬��
        gt_hht_order_line(cn_l_cnt).last_updated_by        := cn_last_updated_by;                   -- �ŏI�X�V��
        gt_hht_order_line(cn_l_cnt).last_update_date       := cd_last_update_date;                  -- �ŏI�X�V��
        gt_hht_order_line(cn_l_cnt).last_update_login      := cn_last_update_login;                 -- �ŏI�X�V���O�C��
        gt_hht_order_line(cn_l_cnt).request_id             := cn_request_id;                        -- �v��ID
        gt_hht_order_line(cn_l_cnt).program_application_id := cn_program_application_id;            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        gt_hht_order_line(cn_l_cnt).program_id             := cn_program_id;                        -- �R���J�����g�E�v���O����ID
        gt_hht_order_line(cn_l_cnt).program_update_date    := cd_program_update_date;               -- �v���O�����X�V��
--
        ------------------------------------
        -- �󒍖���OIF�̔z��ݒ�
        ------------------------------------
        gt_order_oif_line(cn_l_cnt).order_source_id        := gt_order_source_id;                   -- �C���|�[�g�\�[�XID
        IF l_line_data_rec.sale_class = cv_sale_class_5 THEN
          gt_order_oif_line(cn_l_cnt).line_type_id           := gt_order_type_id_l_20;              -- ���׃^�C�vID�i20_���^�j
        ELSE
          gt_order_oif_line(cn_l_cnt).line_type_id           := gt_order_type_id_l;                 -- ���׃^�C�vID�i10_�ʏ�o�ׁj
        END IF;
        gt_order_oif_line(cn_l_cnt).orig_sys_document_ref  := lt_orig_sys_doc_ref;                  -- �O���V�X�e���󒍔ԍ�
        gt_order_oif_line(cn_l_cnt).orig_sys_line_ref      := l_line_data_rec.line_no_hht;          -- �O���V�X�e���󒍖��הԍ�
        gt_order_oif_line(cn_l_cnt).org_id                 := gn_org_id;                            -- �g�DID
        gt_order_oif_line(cn_l_cnt).line_number            := l_line_data_rec.line_no_hht;          -- ���הԍ�
        gt_order_oif_line(cn_l_cnt).inventory_item         := lt_item_code;                         -- �󒍕i��
        gt_order_oif_line(cn_l_cnt).ordered_quantity       := l_line_data_rec.quantity;             -- �󒍐���
-- Ver.1.1 E_�{�ғ�_14486(�ǉ��Ή�) MOD START
--        gt_order_oif_line(cn_l_cnt).order_quantity_uom     := gv_hon_uom;                           -- �󒍒P��
        gt_order_oif_line(cn_l_cnt).order_quantity_uom     := lt_primary_uom_code;                  -- �󒍒P��
-- Ver.1.1 E_�{�ғ�_14486(�ǉ��Ή�) MOD END
        gt_order_oif_line(cn_l_cnt).customer_po_number     := l_header_data_rec.invoice_no;         -- �ڋq�����ԍ�
        gt_order_oif_line(cn_l_cnt).customer_line_number   := l_line_data_rec.line_no_hht;          -- �ڋq�������הԍ�
        gt_order_oif_line(cn_l_cnt).request_date           := l_header_data_rec.dlv_date;           -- �v����
        gt_order_oif_line(cn_l_cnt).unit_list_price        := l_line_data_rec.wholesale_unit_plice; -- �W���P��
        gt_order_oif_line(cn_l_cnt).unit_selling_price     := l_line_data_rec.wholesale_unit_plice; -- �̔��P��
        gt_order_oif_line(cn_l_cnt).subinventory           := lv_storage_location;                  -- �ۊǏꏊ
        IF l_line_data_rec.sale_class = cv_sale_class_5 THEN
          gt_order_oif_line(cn_l_cnt).context                := gt_order_type_name_l_20;            -- �R���e�L�X�g�i30_���^�j
        ELSE
          gt_order_oif_line(cn_l_cnt).context                := gt_order_type_name_l;               -- �R���e�L�X�g�i10_�ʏ�o�ׁj
        END IF;
        gt_order_oif_line(cn_l_cnt).attribute5             := l_line_data_rec.sale_class;           -- ����敪
        gt_order_oif_line(cn_l_cnt).attribute10            := l_line_data_rec.selling_price;        -- ���P��
        gt_order_oif_line(cn_l_cnt).calculate_price_flag   := cv_n;                                 -- ���i�v�Z�t���O
--
      END LOOP line_loop;
--
      CLOSE get_line_data_cur;
--
      -- �w�b�_�ɕR�Â����ׂ�1���������`�[�����݂���ꍇ�̓G���[�Ƃ���B
      IF ( ln_line_data_cnt = 0 ) THEN
        -- ���b�Z�[�W�ҏW
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application        => cv_xxcos_appl_short_name
                       ,iv_name               => cv_msg_15255
                       ,iv_token_name1        => cv_tkn_key_data1
                       ,iv_token_value1       => l_header_data_rec.order_no_hht
                      );
        lv_errbuf  := lv_errmsg;
        RAISE no_line_data_expt;
      END IF;
--
      -- �w�b�_�z��p�̃J�E���g�A�b�v
      cn_h_cnt := cn_h_cnt + 1;
--
      ------------------------------------
      -- HHT�󒍃w�b�_�e�[�u���̔z��ݒ�
      ------------------------------------
      gt_hht_order_header(cn_h_cnt).order_no_hht            := l_header_data_rec.order_no_hht;          -- ��No.(HHT)
      gt_hht_order_header(cn_h_cnt).base_code               := l_header_data_rec.base_code;             -- ���_�R�[�h
      gt_hht_order_header(cn_h_cnt).dlv_by_code             := l_header_data_rec.dlv_by_code;           -- �[�i�҃R�[�h
      gt_hht_order_header(cn_h_cnt).dlv_by_code_conv        := lt_salesrep_number;                      -- �ϊ���[�i�҃R�[�h
      gt_hht_order_header(cn_h_cnt).invoice_no              := l_header_data_rec.invoice_no;            -- �`�[No.
      gt_hht_order_header(cn_h_cnt).dlv_date                := l_header_data_rec.dlv_date;              -- �[�i�\���
      gt_hht_order_header(cn_h_cnt).sales_classification    := l_header_data_rec.sales_classification;  -- ���㕪�ދ敪
      gt_hht_order_header(cn_h_cnt).sales_invoice           := l_header_data_rec.sales_invoice;         -- ����`�[�敪
      gt_hht_order_header(cn_h_cnt).dlv_time                := l_header_data_rec.dlv_time;              -- ����
      gt_hht_order_header(cn_h_cnt).customer_number         := l_header_data_rec.customer_number;       -- �ڋq�R�[�h
      gt_hht_order_header(cn_h_cnt).consumption_tax_class   := l_header_data_rec.consumption_tax_class; -- ����ŋ敪
      gt_hht_order_header(cn_h_cnt).total_amount            := l_header_data_rec.total_amount;          -- ���v���z
      gt_hht_order_header(cn_h_cnt).sales_consumption_tax   := l_header_data_rec.sales_consumption_tax; -- �������Ŋz
      gt_hht_order_header(cn_h_cnt).tax_include             := l_header_data_rec.tax_include;           -- �ō����z
      gt_hht_order_header(cn_h_cnt).system_date             := l_header_data_rec.system_date;           -- �V�X�e�����t
      gt_hht_order_header(cn_h_cnt).order_no                := l_header_data_rec.order_no;              -- �I�[�_�[No
      gt_hht_order_header(cn_h_cnt).received_date           := l_header_data_rec.received_date;         -- ��M����
      gt_hht_order_header(cn_h_cnt).orig_sys_document_ref   := lt_orig_sys_doc_ref;                     -- �󒍊֘A�ԍ�
      gt_hht_order_header(cn_h_cnt).created_by              := cn_created_by;                           -- �쐬��
      gt_hht_order_header(cn_h_cnt).creation_date           := cd_creation_date;                        -- �쐬��
      gt_hht_order_header(cn_h_cnt).last_updated_by         := cn_last_updated_by;                      -- �ŏI�X�V��
      gt_hht_order_header(cn_h_cnt).last_update_date        := cd_last_update_date;                     -- �ŏI�X�V��
      gt_hht_order_header(cn_h_cnt).last_update_login       := cn_last_update_login;                    -- �ŏI�X�V���O�C��
      gt_hht_order_header(cn_h_cnt).request_id              := cn_request_id;                           -- �v��ID
      gt_hht_order_header(cn_h_cnt).program_application_id  := cn_program_application_id;               -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      gt_hht_order_header(cn_h_cnt).program_id              := cn_program_id;                           -- �R���J�����g�E�v���O����ID
      gt_hht_order_header(cn_h_cnt).program_update_date     := cd_program_update_date;                  -- �v���O�����X�V��
--
      ------------------------------------
      -- �󒍃w�b�_OIF�̔z��ݒ�
      ------------------------------------
      gt_order_oif_header(cn_h_cnt).order_source_id         := gt_order_source_id;                     -- �C���|�[�g�\�[�XID
      gt_order_oif_header(cn_h_cnt).order_type_id           := gt_order_type_id_h;                     -- �󒍃^�C�vID
      gt_order_oif_header(cn_h_cnt).orig_sys_document_ref   := lt_orig_sys_doc_ref;                    -- �O���V�X�e���󒍔ԍ�
      gt_order_oif_header(cn_h_cnt).org_id                  := gn_org_id;                              -- �g�DID
      gt_order_oif_header(cn_h_cnt).salesrep_id             := lt_salesrep_id;                         -- �S���c��ID
      gt_order_oif_header(cn_h_cnt).ordered_date            := l_header_data_rec.system_date;          -- �󒍓�
      gt_order_oif_header(cn_h_cnt).customer_po_number      := l_header_data_rec.invoice_no;           -- �ڋq�����ԍ�
      gt_order_oif_header(cn_h_cnt).customer_number         := l_header_data_rec.customer_number;      -- �ڋq�R�[�h
      gt_order_oif_header(cn_h_cnt).request_date            := l_header_data_rec.dlv_date;             -- �v����
      gt_order_oif_header(cn_h_cnt).context                 := gt_order_type_name_h;                   -- �R���e�L�X�g
      gt_order_oif_header(cn_h_cnt).attribute12             := l_header_data_rec.base_code;            -- �����p���_
      gt_order_oif_header(cn_h_cnt).attribute19             := l_header_data_rec.order_no;             -- �I�[�_�[No
-- Ver.1.2 Mod Start
--      gt_order_oif_header(cn_h_cnt).attribute5              := l_header_data_rec.sales_invoice;        -- �`�[�敪
      gt_order_oif_header(cn_h_cnt).attribute5              := SUBSTRB( l_header_data_rec.sales_invoice, 2,2 );  -- �`�[�敪(��1���폜)
-- Ver.1.2 Mod End
      gt_order_oif_header(cn_h_cnt).attribute20             := l_header_data_rec.sales_classification; -- ���ދ敪
      gt_order_oif_header(cn_h_cnt).global_attribute4       := l_header_data_rec.order_no_hht;         -- ��No.(HHT)
      gt_order_oif_header(cn_h_cnt).global_attribute5       := cv_create_hht;                          -- �������敪
--
      ------------------------------------
      -- �󒍏���OIF�̔z��ݒ�
      ------------------------------------
      gt_order_oif_actions(cn_h_cnt).order_source_id        := gt_order_source_id;  -- �C���|�[�g�\�[�XID
      gt_order_oif_actions(cn_h_cnt).orig_sys_document_ref  := lt_orig_sys_doc_ref; -- �O���V�X�e���󒍔ԍ�
      gt_order_oif_actions(cn_h_cnt).operation_code         := cv_operation_code;   -- �I�y���[�V�����R�[�h
--
    END LOOP header_loop;
--
    CLOSE get_header_data_cur;
--
  EXCEPTION
    -- *** HHT�󒍖��ׂȂ��G���[ ***
    WHEN no_line_data_expt THEN
      -- HHT�󒍃w�b�_���[�N�J�[�\���N���[�Y
      IF ( get_header_data_cur%ISOPEN ) THEN
        CLOSE get_header_data_cur;
      END IF;
      -- HHT�󒍃w�b�_���[�N�J�[�\���N���[�Y
      IF ( get_line_data_cur%ISOPEN ) THEN
        CLOSE get_line_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���b�N�G���[ ***
    WHEN lock_err_expt THEN
      -- HHT�󒍃w�b�_���[�N�J�[�\���N���[�Y
      IF ( get_header_data_cur%ISOPEN ) THEN
        CLOSE get_header_data_cur;
      END IF;
      -- HHT�󒍃w�b�_���[�N�J�[�\���N���[�Y
      IF ( get_line_data_cur%ISOPEN ) THEN
        CLOSE get_line_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
      -- HHT�󒍃w�b�_���[�N�J�[�\���N���[�Y
      IF ( get_header_data_cur%ISOPEN ) THEN
        CLOSE get_header_data_cur;
      END IF;
      -- HHT�󒍃w�b�_���[�N�J�[�\���N���[�Y
      IF ( get_line_data_cur%ISOPEN ) THEN
        CLOSE get_line_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_work_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_hht_order_header
   * Description      : HHT�󒍃w�b�_�f�[�^�ꊇ�o�^(A-3)
   ***********************************************************************************/
  PROCEDURE ins_hht_order_header(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_hht_order_header'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
--
      -- HHT�󒍃w�b�_�f�[�^�ꊇ�o�^
      FORALL i IN 1..gt_hht_order_header.COUNT
        INSERT INTO xxcos_hht_order_headers VALUES gt_hht_order_header(i);
--
    EXCEPTION
      WHEN OTHERS THEN
        --���b�Z�[�W�ҏW
                lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application        => cv_xxcos_appl_short_name
                       ,iv_name               => cv_msg_00010
                       ,iv_token_name1        => cv_tkn_table_name  -- �e�[�u��
                       ,iv_token_value1       => cv_msg_15275       -- �e�[�u����
                       ,iv_token_name2        => cv_tkn_key_data    -- �L�[�f�[�^
                       ,iv_token_value2       => SQLERRM            -- SQL�G���[���b�Z�[�W
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
  END ins_hht_order_header;
--
  /**********************************************************************************
   * Procedure Name   : ins_hht_order_line
   * Description      : HHT�󒍖��׃f�[�^�ꊇ�o�^(A-4)
   ***********************************************************************************/
  PROCEDURE ins_hht_order_line(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_hht_order_line'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
--
      -- HHT�󒍖��׃f�[�^�ꊇ�o�^
      FORALL i IN 1..gt_hht_order_line.COUNT
        INSERT INTO xxcos_hht_order_lines VALUES gt_hht_order_line(i);
--
    EXCEPTION
      WHEN OTHERS THEN
        --���b�Z�[�W�ҏW
                lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application        => cv_xxcos_appl_short_name
                       ,iv_name               => cv_msg_00010
                       ,iv_token_name1        => cv_tkn_table_name  -- �e�[�u��
                       ,iv_token_value1       => cv_msg_15276       -- �e�[�u����
                       ,iv_token_name2        => cv_tkn_key_data    -- �L�[�f�[�^
                       ,iv_token_value2       => SQLERRM            -- SQL�G���[���b�Z�[�W
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
  END ins_hht_order_line;
--
  /**********************************************************************************
   * Procedure Name   : ins_oif_order_header
   * Description      : �󒍃w�b�_OIF�f�[�^�ꊇ�o�^(A-5)
   ***********************************************************************************/
  PROCEDURE ins_oif_order_header(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
--
      -- �󒍃w�b�_OIF�f�[�^�ꊇ�o�^
      FORALL i IN 1..gt_order_oif_header.COUNT
        INSERT INTO oe_headers_iface_all(
           order_source_id        -- �C���|�[�g�\�[�XID
          ,order_type_id          -- �󒍃^�C�vID
          ,orig_sys_document_ref  -- �O���V�X�e���󒍔ԍ�
          ,org_id                 -- �g�DID
          ,salesrep_id            -- �S���c��ID
          ,ordered_date           -- �󒍓�
          ,customer_po_number     -- �ڋq�����ԍ�
          ,customer_number        -- �ڋq�R�[�h
          ,request_date           -- �v����
          ,context                -- �R���e�L�X�g
          ,attribute12            -- �����p���_
          ,attribute19            -- �I�[�_�[No
          ,attribute5             -- �`�[�敪
          ,attribute20            -- ���ދ敪
          ,global_attribute4      -- ��No.(HHT)
          ,global_attribute5      -- �������敪
          ,created_by             -- �쐬��
          ,creation_date          -- �쐬��
          ,last_updated_by        -- �ŏI�X�V��
          ,last_update_date       -- �ŏI�X�V��
          ,last_update_login      -- �ŏI�X�V���O�C��
          ,request_id             -- �v��ID
          ,program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id             -- �R���J�����g�E�v���O����ID
          ,program_update_date    -- �v���O�����X�V��
        )
        VALUES
        (
           gt_order_oif_header(i).order_source_id        -- �C���|�[�g�\�[�XID
          ,gt_order_oif_header(i).order_type_id          -- �󒍃^�C�vID
          ,gt_order_oif_header(i).orig_sys_document_ref  -- �O���V�X�e���󒍔ԍ�
          ,gt_order_oif_header(i).org_id                 -- �g�DID
          ,gt_order_oif_header(i).salesrep_id            -- �S���c��ID
          ,gt_order_oif_header(i).ordered_date           -- �󒍓�
          ,gt_order_oif_header(i).customer_po_number     -- �ڋq�����ԍ�
          ,gt_order_oif_header(i).customer_number        -- �ڋq�R�[�h
          ,gt_order_oif_header(i).request_date           -- �v����
          ,gt_order_oif_header(i).context                -- �R���e�L�X�g
          ,gt_order_oif_header(i).attribute12            -- �����p���_
          ,gt_order_oif_header(i).attribute19            -- �I�[�_�[No
          ,gt_order_oif_header(i).attribute5             -- �`�[�敪
          ,gt_order_oif_header(i).attribute20            -- ���ދ敪
          ,gt_order_oif_header(i).global_attribute4      -- ��No.(HHT)
          ,gt_order_oif_header(i).global_attribute5      -- �������敪
          ,cn_created_by                                 -- �쐬��
          ,cd_creation_date                              -- �쐬��
          ,cn_last_updated_by                            -- �ŏI�X�V��
          ,cd_last_update_date                           -- �ŏI�X�V��
          ,cn_last_update_login                          -- �ŏI�X�V���O�C��
          ,NULL                                          -- �v��ID
          ,cn_program_application_id                     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,cn_program_id                                 -- �R���J�����g�E�v���O����ID
          ,cd_program_update_date                        -- �v���O�����X�V��
        )
        ;
--
        -- �w�b�_�}���������J�E���g
        gn_h_insert_cnt := gt_order_oif_header.COUNT;
--
    EXCEPTION
      WHEN OTHERS THEN
        --���b�Z�[�W�ҏW
        lv_errmsg  := xxccp_common_pkg.get_msg(
                iv_application        => cv_xxcos_appl_short_name
               ,iv_name               => cv_msg_00010
               ,iv_token_name1        => cv_tkn_table_name  -- �e�[�u��
               ,iv_token_value1       => cv_msg_00132       -- �e�[�u����
               ,iv_token_name2        => cv_tkn_key_data    -- �L�[�f�[�^
               ,iv_token_value2       => SQLERRM            -- SQL�G���[���b�Z�[�W
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
  END ins_oif_order_header;
--
  /**********************************************************************************
   * Procedure Name   : ins_oif_order_line
   * Description      : �󒍖���OIF�f�[�^�ꊇ�o�^(A-6)
   ***********************************************************************************/
  PROCEDURE ins_oif_order_line(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
--
      -- �󒍖���OIF�f�[�^�ꊇ�o�^
      FORALL i IN 1..gt_order_oif_line.COUNT
        INSERT INTO oe_lines_iface_all(
           order_source_id        -- �C���|�[�g�\�[�XID
          ,line_type_id           -- ���׃^�C�vID
          ,orig_sys_document_ref  -- �O���V�X�e���󒍔ԍ�
          ,orig_sys_line_ref      -- �O���V�X�e���󒍖��הԍ�
          ,org_id                 -- �g�DID
          ,line_number            -- ���הԍ�
          ,inventory_item         -- �󒍕i��
          ,ordered_quantity       -- �󒍐���
          ,order_quantity_uom     -- �󒍒P��
          ,customer_po_number     -- �ڋq�����ԍ�
          ,customer_line_number   -- �ڋq�������הԍ�
          ,request_date           -- �v����
          ,unit_list_price        -- �W���P��
          ,unit_selling_price     -- �̔��P��
          ,subinventory           -- �ۊǏꏊ
          ,context                -- �R���e�L�X�g
          ,attribute5             -- ����敪
          ,attribute10            -- ���P��
          ,calculate_price_flag   -- ���i�v�Z�t���O
          ,created_by             -- �쐬��
          ,creation_date          -- �쐬��
          ,last_updated_by        -- �ŏI�X�V��
          ,last_update_date       -- �ŏI�X�V��
          ,last_update_login      -- �ŏI�X�V���O�C��
          ,request_id             -- �v��ID
          ,program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id             -- �R���J�����g�E�v���O����ID
          ,program_update_date    -- �v���O�����X�V��
        )
        VALUES
        (
           gt_order_oif_line(i).order_source_id        -- �C���|�[�g�\�[�XID
          ,gt_order_oif_line(i).line_type_id           -- ���׃^�C�vID
          ,gt_order_oif_line(i).orig_sys_document_ref  -- �O���V�X�e���󒍔ԍ�
          ,gt_order_oif_line(i).orig_sys_line_ref      -- �O���V�X�e���󒍖��הԍ�
          ,gt_order_oif_line(i).org_id                 -- �g�DID
          ,gt_order_oif_line(i).line_number            -- ���הԍ�
          ,gt_order_oif_line(i).inventory_item         -- �󒍕i��
          ,gt_order_oif_line(i).ordered_quantity       -- �󒍐���
          ,gt_order_oif_line(i).order_quantity_uom     -- �󒍒P��
          ,gt_order_oif_line(i).customer_po_number     -- �ڋq�����ԍ�
          ,gt_order_oif_line(i).customer_line_number   -- �ڋq�������הԍ�
          ,gt_order_oif_line(i).request_date           -- �v����
          ,gt_order_oif_line(i).unit_list_price        -- �W���P��
          ,gt_order_oif_line(i).unit_selling_price     -- �̔��P��
          ,gt_order_oif_line(i).subinventory           -- �ۊǏꏊ
          ,gt_order_oif_line(i).context                -- �R���e�L�X�g
          ,gt_order_oif_line(i).attribute5             -- ����敪
          ,gt_order_oif_line(i).attribute10            -- ���P��
          ,gt_order_oif_line(i).calculate_price_flag   -- ���i�v�Z�t���O
          ,cn_created_by                               -- �쐬��
          ,cd_creation_date                            -- �쐬��
          ,cn_last_updated_by                          -- �ŏI�X�V��
          ,cd_last_update_date                         -- �ŏI�X�V��
          ,cn_last_update_login                        -- �ŏI�X�V���O�C��
          ,NULL                                        -- �v��ID
          ,cn_program_application_id                   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,cn_program_id                               -- �R���J�����g�E�v���O����ID
          ,cd_program_update_date                      -- �v���O�����X�V��
        )
        ;
--
        -- ���ב}���������J�E���g
        gn_l_insert_cnt := gt_order_oif_line.COUNT;
--
    EXCEPTION
      WHEN OTHERS THEN
        --���b�Z�[�W�ҏW
        lv_errmsg  := xxccp_common_pkg.get_msg(
                iv_application        => cv_xxcos_appl_short_name
               ,iv_name               => cv_msg_00010
               ,iv_token_name1        => cv_tkn_table_name  -- �e�[�u��
               ,iv_token_value1       => cv_msg_00133       -- �e�[�u����
               ,iv_token_name2        => cv_tkn_key_data    -- �L�[�f�[�^
               ,iv_token_value2       => SQLERRM            -- SQL�G���[���b�Z�[�W
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
  END ins_oif_order_line;
--
  /**********************************************************************************
   * Procedure Name   : ins_oif_order_process
   * Description      : �󒍏���OIF�f�[�^�ꊇ�o�^(A-7)
   ***********************************************************************************/
  PROCEDURE ins_oif_order_process(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
--
      -- �󒍃w�b�_OIF�f�[�^�ꊇ�o�^
      FORALL i IN 1..gt_order_oif_actions.COUNT
        INSERT INTO oe_actions_iface_all(
           order_source_id        -- �C���|�[�g�\�[�XID
          ,orig_sys_document_ref  -- �O���V�X�e���󒍔ԍ�
          ,operation_code         -- �I�y���[�V�����R�[�h
        )
        VALUES
        (
           gt_order_oif_actions(i).order_source_id        -- �C���|�[�g�\�[�XID
          ,gt_order_oif_actions(i).orig_sys_document_ref  -- �O���V�X�e���󒍔ԍ�
          ,gt_order_oif_actions(i).operation_code         -- �I�y���[�V�����R�[�h
        )
        ;
--
    EXCEPTION
      WHEN OTHERS THEN
        --���b�Z�[�W�ҏW
        lv_errmsg  := xxccp_common_pkg.get_msg(
                iv_application        => cv_xxcos_appl_short_name
               ,iv_name               => cv_msg_00010
               ,iv_token_name1        => cv_tkn_table_name  -- �e�[�u��
               ,iv_token_value1       => cv_msg_00134       -- �e�[�u����
               ,iv_token_name2        => cv_tkn_key_data    -- �L�[�f�[�^
               ,iv_token_value2       => SQLERRM            -- SQL�G���[���b�Z�[�W
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
  END ins_oif_order_process;
--
  /**********************************************************************************
   * Procedure Name   : call_import
   * Description      : �󒍃C���|�[�g�G���[���m�N��(A-8)
   ***********************************************************************************/
  PROCEDURE call_import(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_import'; -- �v���O������
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
    --�v���̔��s
    cv_application            CONSTANT VARCHAR2(5)   := 'XXCOS';          -- Application
    cv_program                CONSTANT VARCHAR2(13)  := 'XXCOS010A062C';  -- �󒍃C���|�[�g�G���[���m(Online�p�j
    cv_description            CONSTANT VARCHAR2(9)   := NULL;             -- Description
    cv_start_time             CONSTANT VARCHAR2(10)  := NULL;             -- Start_time
    cb_sub_request            CONSTANT BOOLEAN       := FALSE;            -- Sub_request
    --�v���̑ҋ@
    cv_wait_error             CONSTANT VARCHAR2(5)   := 'ERROR';          -- �X�e�[�^�X�i�ُ�j
    cv_wait_warning           CONSTANT VARCHAR2(7)   := 'WARNING';        -- �X�e�[�^�X�i�x���j
    -- *** ���[�J���ϐ� ***
    --�v���̔��s
    ln_request_id             NUMBER;          -- �v��ID
    --�v���̑ҋ@
    ln_process_set            NUMBER;          -- �����Z�b�g
    lb_wait_result            BOOLEAN;         -- �R���J�����g�ҋ@����
    lv_phase                  VARCHAR2(50);    -- �t�F�[�Y�i���[�U�j
    lv_status                 VARCHAR2(50);    -- �X�e�[�^�X�i���[�U�j
    lv_dev_phase              VARCHAR2(50);    -- �t�F�[�Y�i�v���O�����j
    lv_dev_status             VARCHAR2(50);    -- �X�e�[�^�X�i�v���O�����j
    lv_message                VARCHAR2(5000);  -- ���b�Z�[�W
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �f�[�^�m��̈׃R�~�b�g
    COMMIT;
--
    ------------------------------------
    -- �R���J�����g�N��
    ------------------------------------
    ln_request_id := fnd_request.submit_request(
                        application  => cv_application        -- �A�v���P�[�V����
                       ,program      => cv_program            -- �v���O����
                       ,description  => cv_description        -- �K�p
                       ,start_time   => cv_start_time         -- �J�n����
                       ,sub_request  => cb_sub_request        -- �T�u�v��
                       ,argument1    => gt_order_source_name  -- �󒍃\�[�X��
                     );
--
    -- �v���̔��s�Ɏ��s�����ꍇ
    IF ( ln_request_id = 0 ) THEN
      -- ���b�Z�[�W�ҏW
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_appl_short_name
                     ,iv_name         => cv_msg_15262
                     ,iv_token_name1  => cv_tkn_request_id         -- �v��ID
                     ,iv_token_value1 => TO_CHAR( ln_request_id )  -- �v��ID
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�R���J�����g�N���̂��߃R�~�b�g
    COMMIT;
--
    ------------------------------------
    --�R���J�����g�̏I���ҋ@
    ------------------------------------
    lb_wait_result := fnd_concurrent.wait_for_request(
                         request_id   => ln_request_id  -- �v��ID
                        ,interval     => gn_interval    -- �ҋ@�Ԋu
                        ,max_wait     => gn_max_wait    -- �ő�ҋ@����
                        ,phase        => lv_phase       -- �t�F�[�Y�i���[�U�j
                        ,status       => lv_status      -- �X�e�[�^�X�i���[�U�j
                        ,dev_phase    => lv_dev_phase   -- �t�F�[�Y�i�v���O�����j
                        ,dev_status   => lv_dev_status  -- �X�e�[�^�X�i�v���O�����j
                        ,message      => lv_message     -- ���b�Z�[�W
                      );
--
    -- �ҋ@���ʂ�FALSE�A�������́A�v���X�e�[�^�X��ERROR�̏ꍇ
    IF (
         ( lb_wait_result = FALSE ) 
         OR
         ( lv_dev_status = cv_wait_error )
    ) THEN
      -- ���b�Z�[�W�ҏW
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_appl_short_name
                     ,iv_name         => cv_msg_15263
                     ,iv_token_name1  => cv_tkn_request_id         -- �v��ID
                     ,iv_token_value1 => TO_CHAR( ln_request_id )  -- �v��ID
                     ,iv_token_name2  => cv_tkn_status             -- �X�e�[�^�X
                     ,iv_token_value2 => lv_dev_status             -- �X�e�[�^�X�R�[�h
                     ,iv_token_name3  => cv_tkn_err_msg            -- �G���[���b�Z�[�W
                     ,iv_token_value3 => lv_message                -- API����ԋp���ꂽ���b�Z�[�W
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    -- �v���X�e�[�^�X��WARNING�̏ꍇ
    ELSIF ( lv_dev_status = cv_wait_warning ) THEN
      -- ���b�Z�[�W�ҏW
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_appl_short_name
                     ,iv_name         => cv_msg_15264
                     ,iv_token_name1  => cv_tkn_request_id         -- �v��ID
                     ,iv_token_value1 => TO_CHAR( ln_request_id )  -- �v��ID)
                     ,iv_token_name2  => cv_tkn_status             -- �X�e�[�^�X
                     ,iv_token_value2 => lv_dev_status             -- �X�e�[�^�X�R�[�h
                     ,iv_token_name3  => cv_tkn_err_msg            -- �G���[���b�Z�[�W
                     ,iv_token_value3 => lv_message                -- API����ԋp���ꂽ���b�Z�[�W
                     );
--
      -- ���b�Z�[�W�o��
       FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
      );
      -- �I���X�e�[�^�X�̐���p�ϐ��̐ݒ�
      gv_import_status := cv_status_warn;
--
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
  END call_import;
--
  /**********************************************************************************
   * Procedure Name   : del_work_date
   * Description      : HHT�󒍃��[�N�f�[�^�폜(A-9)
   ***********************************************************************************/
  PROCEDURE del_work_date(
     iv_mode       IN  VARCHAR2     --   1.�N�����[�h�i1:���� 3:���[�N�e�[�u���p�[�W�j
    ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_work_date'; -- �v���O������
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
    -- *** ���[�J���E�J�[�\�� ***
    -- HHT�󒍃w�b�_���[�N�e�[�u��
    CURSOR get_del_header_cur
    IS
      SELECT xhohw.order_no_hht  order_no_hht    -- ��No.(HHT)
      FROM   xxcos_hht_order_headers_work xhohw  -- HHT�󒍃w�b�_���[�N�e�[�u��
      FOR UPDATE NOWAIT
    ;
    -- HHT�󒍖��׃��[�N�e�[�u��
    CURSOR get_del_line_cur
    IS
      SELECT xholw.order_no_hht  order_no_hht  -- ��No.(HHT)
      FROM   xxcos_hht_order_lines_work xholw  -- HHT�󒍖��׃��[�N�e�[�u��
      FOR UPDATE NOWAIT
    ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ---------------------------------------------------------------
    -- �폜�Ώی������擾
    ---------------------------------------------------------------
    -- HHT�󒍃w�b�_���[�N�e�[�u��
    SELECT COUNT(1)
    INTO   gn_h_delete_cnt
    FROM   xxcos_hht_order_headers_work xhohw
    ;
    -- HHT�󒍖��׃��[�N�e�[�u��
    SELECT COUNT(1)
    INTO   gn_l_delete_cnt
    FROM   xxcos_hht_order_lines_work xholw
    ;
--
    ---------------------------------------------------------------
    -- �N�����[�h�����[�N�e�[�u���p�[�W�����̏ꍇ�A�e�[�u���̃��b�N
    ---------------------------------------------------------------
    IF ( iv_mode = cv_mode_parge) THEN
--
      -- HHT�󒍃w�b�_���[�N�e�[�u���̃��b�N
      BEGIN
        OPEN  get_del_header_cur;
        CLOSE get_del_header_cur;
      EXCEPTION
        WHEN lock_err_expt THEN
          --���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                  iv_application        => cv_xxcos_appl_short_name
                 ,iv_name               => cv_msg_15277
                 ,iv_token_name1        => cv_tkn_table  --�e�[�u��
                 ,iv_token_value1       => cv_msg_15252  --�e�[�u����
                );
          lv_errbuf  := lv_errmsg;
          RAISE lock_err_expt;
      END;
--
      -- HHT�󒍖��׃��[�N�e�[�u���̃��b�N
      BEGIN
        OPEN  get_del_line_cur;
        CLOSE get_del_line_cur;
      EXCEPTION
        WHEN lock_err_expt THEN
          --���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                  iv_application        => cv_xxcos_appl_short_name
                 ,iv_name               => cv_msg_15277
                 ,iv_token_name1        => cv_tkn_table  --�e�[�u��
                 ,iv_token_value1       => cv_msg_15253  --�e�[�u����
                );
          lv_errbuf  := lv_errmsg;
          RAISE lock_err_expt;
      END;
--
    END IF;
--
    ---------------------------------------------------------------
    -- �e�[�u���̃p�[�W
    ---------------------------------------------------------------
    BEGIN
--
      -- HHT�󒍃w�b�_���[�N�e�[�u���̍폜
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcos.xxcos_hht_order_headers_work';
--
    EXCEPTION
      WHEN OTHERS THEN
          --���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                  iv_application        => cv_xxcos_appl_short_name
                 ,iv_name               => cv_msg_15278
                 ,iv_token_name1        => cv_tkn_table    -- �e�[�u��
                 ,iv_token_value1       => cv_msg_15252    -- �e�[�u����
                 ,iv_token_name2        => cv_tkn_err_msg  -- �G���[���b�Z�[�W
                 ,iv_token_value2       => SQLERRM         -- SQL�G���[���b�Z�[�W
                );
          lv_errbuf  := lv_errmsg;
          RAISE del_target_expt;
    END;
--
    BEGIN
--
      -- HHT�󒍖��׃��[�N�e�[�u���̍폜
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcos.xxcos_hht_order_lines_work';
--
    EXCEPTION
      WHEN OTHERS THEN
        --���b�Z�[�W�ҏW
        lv_errmsg  := xxccp_common_pkg.get_msg(
                iv_application        => cv_xxcos_appl_short_name
               ,iv_name               => cv_msg_15278
               ,iv_token_name1        => cv_tkn_table      -- �e�[�u��
               ,iv_token_value1       => cv_msg_15253      -- �e�[�u����
               ,iv_token_name2        => cv_tkn_err_msg    -- �G���[���b�Z�[�W
               ,iv_token_value2       => SQLERRM           -- SQL�G���[���b�Z�[�W
              );
        lv_errbuf  := lv_errmsg;
        RAISE del_target_expt;
    END;
--
  EXCEPTION
    -- *** ���b�N�G���[ ***
    WHEN lock_err_expt THEN
      -- HHT�󒍃w�b�_���[�N�J�[�\���N���[�Y
      IF ( get_del_header_cur%ISOPEN ) THEN
        CLOSE get_del_header_cur;
      END IF;
      -- HHT�󒍃w�b�_���[�N�J�[�\���N���[�Y
      IF ( get_del_line_cur%ISOPEN ) THEN
        CLOSE get_del_line_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �Ώۍ폜�G���[ ***
    WHEN del_target_expt THEN
      -- HHT�󒍃w�b�_���[�N�J�[�\���N���[�Y
      IF ( get_del_header_cur%ISOPEN ) THEN
        CLOSE get_del_header_cur;
      END IF;
      -- HHT�󒍃w�b�_���[�N�J�[�\���N���[�Y
      IF ( get_del_line_cur%ISOPEN ) THEN
        CLOSE get_del_line_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END del_work_date;
--
  /**********************************************************************************
   * Procedure Name   : del_order_date
   * Description      : �ێ����Ԓ���HHT�󒍃f�[�^�폜(A-10)
   ***********************************************************************************/
  PROCEDURE del_order_date(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_order_date'; -- �v���O������
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
    -- *** ���[�J���E�ϐ� ***
    ld_process_date  DATE; --�Ɩ����t
--
    -- *** ���[�J���E�J�[�\�� ***
    -- HHT�󒍃w�b�_�e�[�u��
    CURSOR get_del_order_h_cur
    IS
      SELECT xhoh.order_no_hht  order_no_hht    -- ��No.(HHT)
      FROM   xxcos_hht_order_headers xhoh       -- HHT�󒍃w�b�_�e�[�u��
      WHERE  xhoh.received_date < ld_process_date - gn_parge_date  -- ��M�� < �Ɩ����t-�ێ�����
      FOR UPDATE NOWAIT
    ;
    -- HHT�󒍖��׃e�[�u��
    CURSOR get_del_order_l_cur(
      it_order_no_hht IN xxcos_hht_order_lines.order_no_hht%TYPE
    )
    IS
      SELECT xhol.order_no_hht  order_no_hht  -- ��No.(HHT)
      FROM   xxcos_hht_order_lines xhol       -- HHT�󒍖��׃��[�N�e�[�u��
      WHERE  xhol.order_no_hht = it_order_no_hht
      FOR UPDATE NOWAIT
      ;
--
    -- *** ���[�J���E���R�[�h ***
    l_del_order_h_rec  get_del_order_h_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �Ɩ����t�擾
    ld_process_date := xxccp_common_pkg2.get_process_date;
--
    -- HHT�󒍃w�b�_�e�[�u���̃��b�N
    BEGIN
      OPEN get_del_order_h_cur;
    EXCEPTION
      WHEN lock_err_expt THEN
        -- ���b�Z�[�W�ҏW
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application        => cv_xxcos_appl_short_name
                       ,iv_name               => cv_msg_15265
                       ,iv_token_name1        => cv_tkn_table  -- �e�[�u��
                       ,iv_token_value1       => cv_msg_15275  -- �e�[�u����
                      );
        lv_errbuf := lv_errmsg;
        RAISE lock_err_expt;
    END;
--
    <<del_header_loop>>
    LOOP
--
      FETCH get_del_order_h_cur INTO l_del_order_h_rec;
      EXIT WHEN get_del_order_h_cur%NOTFOUND;
--
      -- HHT�󒍖��׃e�[�u���̃��b�N
      BEGIN
        OPEN get_del_order_l_cur(
              l_del_order_h_rec.order_no_hht
        );
        CLOSE get_del_order_l_cur;
      EXCEPTION
        WHEN lock_err_expt THEN
          --���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                  iv_application        => cv_xxcos_appl_short_name
                 ,iv_name               => cv_msg_15265
                 ,iv_token_name1        => cv_tkn_table  -- �e�[�u��
                 ,iv_token_value1       => cv_msg_15276  -- �e�[�u����
                );
          lv_errbuf  := lv_errmsg;
          RAISE lock_err_expt;
      END;
--
        -- HHT�󒍖��׃e�[�u���̍폜(��No.(HHT)�P��)
      BEGIN
--
        DELETE FROM xxcos_hht_order_lines xhol
        WHERE  xhol.order_no_hht = l_del_order_h_rec.order_no_hht
        ;
--
        -- ���׍폜�����̃J�E���g
        gn_l_delete_cnt := gn_l_delete_cnt + SQL%ROWCOUNT;
--
      EXCEPTION
        WHEN OTHERS THEN
          --���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                  iv_application        => cv_xxcos_appl_short_name
                 ,iv_name               => cv_msg_15266
                 ,iv_token_name1        => cv_tkn_table    -- �e�[�u��
                 ,iv_token_value1       => cv_msg_15276    -- �e�[�u����
                 ,iv_token_name2        => cv_tkn_err_msg  -- �G���[���b�Z�[�W
                 ,iv_token_value2       => SQLERRM         -- SQL�G���[���b�Z�[�W
                );
          lv_errbuf  := lv_errmsg;
          RAISE del_target_expt;
      END;
--
      BEGIN
--
        -- HHT�󒍃w�b�_�e�[�u���̍폜
        DELETE FROM xxcos_hht_order_headers xhol
        WHERE  xhol.order_no_hht = l_del_order_h_rec.order_no_hht
        ;
--
        -- �w�b�_�폜�����̃J�E���g
        gn_h_delete_cnt := gn_h_delete_cnt + SQL%ROWCOUNT;
--
      EXCEPTION
        WHEN OTHERS THEN
          --���b�Z�[�W�ҏW
          lv_errmsg  := xxccp_common_pkg.get_msg(
                  iv_application        => cv_xxcos_appl_short_name
                 ,iv_name               => cv_msg_15266
                 ,iv_token_name1        => cv_tkn_table    -- �e�[�u��
                 ,iv_token_value1       => cv_msg_15275    -- �e�[�u����
                 ,iv_token_name2        => cv_tkn_err_msg  -- �G���[���b�Z�[�W
                 ,iv_token_value2       => SQLERRM         -- SQL�G���[���b�Z�[�W
                );
          lv_errbuf  := lv_errmsg;
          RAISE del_target_expt;
      END;
--
    END LOOP del_header_loop;
--
    CLOSE get_del_order_h_cur;
--
  EXCEPTION
    -- *** ���b�N�G���[ ***
    WHEN lock_err_expt THEN
      -- HHT�󒍃w�b�_�J�[�\���N���[�Y
      IF ( get_del_order_h_cur%ISOPEN ) THEN
        CLOSE get_del_order_h_cur;
      END IF;
      -- HHT�󒍖��׃J�[�\���N���[�Y
      IF ( get_del_order_l_cur%ISOPEN ) THEN
        CLOSE get_del_order_l_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �Ώۍ폜�G���[ ***
    WHEN del_target_expt THEN
      -- HHT�󒍃w�b�_�J�[�\���N���[�Y
      IF ( get_del_order_h_cur%ISOPEN ) THEN
        CLOSE get_del_order_h_cur;
      END IF;
      -- HHT�󒍖��׃J�[�\���N���[�Y
      IF ( get_del_order_l_cur%ISOPEN ) THEN
        CLOSE get_del_order_l_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      -- HHT�󒍃w�b�_���[�N�J�[�\���N���[�Y
      IF ( get_del_order_h_cur%ISOPEN ) THEN
        CLOSE get_del_order_h_cur;
      END IF;
      -- HHT�󒍃w�b�_���[�N�J�[�\���N���[�Y
      IF ( get_del_order_l_cur%ISOPEN ) THEN
        CLOSE get_del_order_l_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_order_date;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_mode       IN  VARCHAR2,     -- 1.�N�����[�h�i1:���� 2:��� 3:���[�N�e�[�u���p�[�W�j
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
    -- 
    gn_h_target_cnt := 0;  -- �w�b�_�Ώی���
    gn_l_target_cnt := 0;  -- ���בΏی���
    gn_h_insert_cnt := 0;  -- �w�b�_�}������
    gn_l_insert_cnt := 0;  -- ���ב}������
    gn_h_warn_cnt   := 0;  -- �w�b�_�x������
    gn_l_warn_cnt   := 0;  -- ���׌x������
    gn_h_delete_cnt := 0;  -- �w�b�_�폜����
    gn_l_delete_cnt := 0;  -- ���׍폜����
--
    gv_import_status := cv_status_normal; --�󒍃C���|�[�g�G���[���m
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
       iv_mode    => iv_mode    -- 1.�N�����[�h�i1:���� 2:��� 3:���[�N�e�[�u���p�[�W�j
      ,ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ���������̏ꍇ
    IF ( iv_mode = cv_mode_day ) THEN
--
      -- ===============================
      -- ���[�N�e�[�u���f�[�^���o(A-2)
      -- ===============================
      get_work_data(
         ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- HHT�󒍃w�b�_�f�[�^�ꊇ�o�^(A-3)
      -- ===============================
      ins_hht_order_header(
         ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      --�s�v�ƂȂ����z����폜
      gt_hht_order_header.DELETE;
--
      -- ===============================
      -- HHT�󒍖��׃f�[�^�ꊇ�o�^(A-4)
      -- ===============================
      ins_hht_order_line(
         ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      --�s�v�ƂȂ����z����폜
      gt_hht_order_line.DELETE;
--
      -- ===============================
      -- �󒍃w�b�_OIF�f�[�^�ꊇ�o�^(A-5)
      -- ===============================
      ins_oif_order_header(
         ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      --�s�v�ƂȂ����z����폜
      gt_order_oif_header.DELETE;
--
      -- ===============================
      -- �󒍖���OIF�f�[�^�ꊇ�o�^(A-6)
      -- ===============================
      ins_oif_order_line(
         ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      --�s�v�ƂȂ����z����폜
      gt_order_oif_line.DELETE;
--
      -- ===============================
      -- �󒍏���OIF�f�[�^�ꊇ�o�^(A-7)
      -- ===============================
      ins_oif_order_process(
         ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      --�s�v�ƂȂ����z����폜
      gt_order_oif_actions.DELETE;
--
      -- �Ώۂ����݂���ꍇ�iHHT�󒍃w�b�_���[�N�Ƀf�[�^������ꍇ�j
      IF ( gn_h_target_cnt <> 0 ) THEN
--
        -- ===============================
        -- �󒍃C���|�[�g�G���[���m�N��(A-8)
        -- ===============================
        call_import(
           ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
      -- ===============================
      -- HHT�󒍃��[�N�f�[�^�폜(A-9)
      -- ===============================
      del_work_date(
         iv_mode    => iv_mode     -- 1.�N�����[�h�i1:�����j
        ,ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �Ώۂ����݂��Ȃ��ꍇ�A�������x���I���Ƃ���
      IF ( gn_h_target_cnt = 0 ) THEN
        -- ���b�Z�[�W���o��
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_00003
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_warn;
      -- �w�b�_�E���ׂ̌x�����������݂���ꍇ�A�������x���I���Ƃ���
      ELSIF ( gn_h_warn_cnt <> 0 OR gn_l_warn_cnt <> 0 ) THEN
        ov_retcode := cv_status_warn;
      -- �󒍃C���|�[�g�G���[���m���x���̏ꍇ�A�������x���I���Ƃ���
      ELSIF ( gv_import_status = cv_status_warn ) THEN
        ov_retcode := cv_status_warn;
      END IF;
--
    -- ��ԏ����̏ꍇ
    ELSIF ( iv_mode = cv_mode_night ) THEN
--
      -- ===============================
      -- �ێ����Ԓ���HHT�󒍃f�[�^�폜(A-10)
      -- ===============================
      del_order_date(
         ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    -- ���[�N�e�[�u���p�[�W�̏ꍇ
    ELSIF ( iv_mode = cv_mode_parge ) THEN
--
      -- ===============================
      -- HHT�󒍃��[�N�f�[�^�폜(A-9)
      -- ===============================
      del_work_date(
         iv_mode    => iv_mode     -- 1.�N�����[�h�i3:���[�N�e�[�u���p�[�W�j
        ,ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
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
    iv_mode       IN  VARCHAR2       -- 1.�N�����[�h�i1:���� 2:��� 3:���[�N�e�[�u���p�[�W�j
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
       iv_mode     -- 1.�N�����[�h�i1:���� 2:��� 3:���[�N�e�[�u���p�[�W�j
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- �����̐ݒ�
      gn_h_target_cnt := 0;
      gn_l_target_cnt := 0;
      gn_h_insert_cnt := 0;
      gn_l_insert_cnt := 0;
      gn_h_warn_cnt   := 0;
      gn_l_warn_cnt   := 0;
      gn_h_delete_cnt := 0;
      gn_l_delete_cnt := 0;
      gn_error_cnt    := 1;
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ���������̌����o��
    IF ( iv_mode = cv_mode_day ) THEN
--
      --�w�b�_�Ώی����o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_15267
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_h_target_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --���בΏی����o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_15268
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_l_target_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --�w�b�_�}�������o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_15269
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_h_insert_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --���ב}�������o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_15270
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_l_insert_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --�w�b�_�x�������o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_15271
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_h_warn_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --���׌x�������o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_15272
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_l_warn_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
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
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
    -- ��ԏ����E���[�N�e�[�u���p�[�W�����̏ꍇ
    ELSE
      --
      --�w�b�_�폜�����o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_15273
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_h_delete_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --���׍폜�����o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_15274
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_l_delete_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
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
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
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
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
END XXCOS001A10C;
/
