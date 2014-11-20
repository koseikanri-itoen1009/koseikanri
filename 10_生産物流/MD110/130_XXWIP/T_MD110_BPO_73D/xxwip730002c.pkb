CREATE OR REPLACE PACKAGE BODY xxwip730002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWIP730002C(BODY)
 * Description      : �^���X�V
 * MD.050           : �^���v�Z�i�g�����U�N�V�����j T_MD050_BPO_733
 * MD.070           : �^���X�V T_MD070_BPO_73D
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  cal_money_proc         ���z�v�Z����(�@�\�ڍהԍ�����)
 *  chk_param_proc         �p�����[�^�`�F�b�N����(D-1)
 *  get_init               �֘A�f�[�^�擾(D-2)
 *  chk_close_proc         �^���p�������擾(D-3)
 *  get_lock_xd            ���b�N�擾(D-4)
 *
 *  get_xd_data            �^���w�b�_�A�h�I�����o(D-5)
 *  get_xdc_data           �^���A�h�I���}�X�^���o(D-6)
 *  set_xd_data            �^���w�b�_�A�h�I��PL/SQL�\�i�[(D-7)
 *
 *  ins_xd_proc            �^���w�b�_�A�h�I���ꊇ�o�^����(D-8)
 *  upd_xd_proc            �^���w�b�_�A�h�I���ꊇ�X�V����(D-9)
 *  upd_calc_ctrl_proc     �^���v�Z�p�R���g���[���X�V����(D-10)
 *
 *  get_xd_exchange_data   ���։^���w�b�_�A�h�I�����o(D-11)
 *  get_xdc_exchange_data  ���։^���A�h�I���}�X�^���o(D-12)
 *  set_xd_exchange_data   ���։^���w�b�_�A�h�I��PL/SQL�\�i�[(D-13)
 *
 *  upd_xd_exchange_proc   ���։^���w�b�_�A�h�I���ꊇ�X�V����(D-14)
 *
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/03    1.0  Oracle ���� �~    ���ō쐬
 *  2008/07/11    1.1  Oracle �R�� ��_  �ύX�v����96�A��98�Ή�
 *  2008/07/23    1.2  Oracle �쑺 ���K  �����ύX#132�Ή�
 *  2008/09/16    1.3  Oracle �g�c �Ď�  T_S_570 �Ή�
 *  2008/10/24    1.4  Oracle �쑺 ���K  ����#408�Ή�
 *
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
  lock_expt                  EXCEPTION;  -- ���b�N�擾��O
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name                CONSTANT VARCHAR2(100) := 'xxwip730002c'; -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  gv_msg_kbn_cmn             CONSTANT VARCHAR2(5) := 'XXCMN';
  gv_msg_kbn_wip             CONSTANT VARCHAR2(5) := 'XXWIP';
--
  -- ���b�Z�[�W�ԍ�(XXCMN)
  gv_msg_cmn_00009           CONSTANT VARCHAR2(15) := 'APP-XXCMN-00009'; -- ��������
  gv_msg_cmn_10001           CONSTANT VARCHAR2(15) := 'APP-XXCMN-10001'; -- �Ώۃf�[�^�Ȃ�
  gv_msg_cmn_10010           CONSTANT VARCHAR2(15) := 'APP-XXCMN-10010'; -- �p�����[�^�G���[
--
  -- ���b�Z�[�W�ԍ�(XXWIP)
  gv_msg_wip_00010           CONSTANT VARCHAR2(15) := 'APP-XXWIP-00010'; -- �^��ͯ�ޱ�޵ݏ�������
  gv_msg_wip_10008           CONSTANT VARCHAR2(15) := 'APP-XXWIP-10008'; -- �K�{���ږ����̓G���[
  gv_msg_wip_10004           CONSTANT VARCHAR2(15) := 'APP-XXWIP-10004'; -- ���b�N�ڍ׃��b�Z�[�W
--
  -- �g�[�N��
  gv_tkn_item                CONSTANT VARCHAR2(10) := 'ITEM';
  gv_tkn_parameter           CONSTANT VARCHAR2(10) := 'PARAMETER';
  gv_tkn_value               CONSTANT VARCHAR2(10) := 'VALUE';
  gv_tkn_table               CONSTANT VARCHAR2(10) := 'TABLE';
  gv_tkn_key                 CONSTANT VARCHAR2(10) := 'KEY';
  gv_tkn_cnt                 CONSTANT VARCHAR2(10) := 'CNT';
--
  -- �g�[�N���l
  gv_exchange_type_name      CONSTANT VARCHAR2(30) := '���֋敪';
  gv_deli_ctrl_name          CONSTANT VARCHAR2(30) := '�^���v�Z�p�R���g���[��';
  gv_deli_name               CONSTANT VARCHAR2(30) := '�^���w�b�_�A�h�I��';
--
  -- YESNO�敪
  gv_ktg_yes                 CONSTANT VARCHAR2(1) := 'Y';
  gv_ktg_no                  CONSTANT VARCHAR2(1) := 'N';
  -- �x�������敪
  gv_paycharge_type_1        CONSTANT VARCHAR2(1) := '1';   -- 1:�x���^��
  gv_paycharge_type_2        CONSTANT VARCHAR2(1) := '2';   -- 2:�����^��
  -- �x���m��敪
  gv_defined_yes             CONSTANT VARCHAR2(1) := 'Y';   -- �x���m��敪�YES�
  gv_defined_no              CONSTANT VARCHAR2(1) := 'N';   -- �x���m��敪�NO�
  -- ���ڋ敪
  gv_mixed_code_1            CONSTANT VARCHAR2(1) := '1';   -- 1:����
  gv_mixed_code_2            CONSTANT VARCHAR2(1) := '2';   -- 2:���ڈȊO
  -- �R���J�����gNo(�^���v�Z�p�R���g���[��)
  gv_con_no_deli             CONSTANT VARCHAR2(1) := '2';   -- 2:�^���X�V
  -- ���i�敪
  gv_prod_class_lef          CONSTANT VARCHAR2(1) := '1';   -- 1:���[�t
  gv_prod_class_drk          CONSTANT VARCHAR2(1) := '2';   -- 2:�h�����N
  -- �z�ԃ^�C�v(2008/07/11)
  gv_dispatch_type_1         CONSTANT VARCHAR2(1) := '1';   -- 1:�ʏ�z��
  gv_dispatch_type_2         CONSTANT VARCHAR2(1) := '2';   -- 2:�`�[�Ȃ��z��(���[�t����)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �^���w�b�_�A�h�I�����o�p���R�[�h�^
  TYPE rec_extraction_xd IS RECORD(
    delivery_company_code    xxwip_deliverys.delivery_company_code%TYPE,    -- �^���Ǝ�
    delivery_no              xxwip_deliverys.delivery_no%TYPE,              -- �z��No
    invoice_no               xxwip_deliverys.invoice_no%TYPE,               -- �����No
-- ##### 20080916 Ver.1.3 T_S_570�Ή� START #####
    invoice_no2              xxwip_deliverys.invoice_no2%TYPE,              -- �����No2
-- ##### 20080916 Ver.1.3 T_S_570�Ή� END #####
    payments_judgment_classe xxwip_deliverys.payments_judgment_classe%TYPE, -- �x�����f�敪
    ship_date                xxwip_deliverys.ship_date%TYPE,                -- �o�ɓ�
    arrival_date             xxwip_deliverys.arrival_date%TYPE,             -- ������
    report_date              xxwip_deliverys.report_date%TYPE,              -- �񍐓�
    judgement_date           xxwip_deliverys.judgement_date%TYPE,           -- ���f��
    goods_classe             xxwip_deliverys.goods_classe%TYPE,             -- ���i�敪
    mixed_code               xxwip_deliverys.mixed_code%TYPE,               -- ���ڋ敪
    many_rate                xxwip_deliverys.many_rate%TYPE,                -- ������
    distance                 xxwip_deliverys.distance%TYPE,                 -- �Œ�����
    delivery_classe          xxwip_deliverys.delivery_classe%TYPE,          -- �z���敪
    whs_code                 xxwip_deliverys.whs_code%TYPE,                 -- ��\�o�ɑq�ɃR�[�h
    code_division            xxwip_deliverys.code_division%TYPE,            -- ��\�z����R�[�h�敪
    shipping_address_code    xxwip_deliverys.shipping_address_code%TYPE,    -- ��\�z����R�[�h
    qty1                     xxwip_deliverys.qty1%TYPE,                     -- ���P
    qty2                     xxwip_deliverys.qty2%TYPE,                     -- ���Q
    delivery_weight1         xxwip_deliverys.delivery_weight1%TYPE,         -- �d�ʂP
    delivery_weight2         xxwip_deliverys.delivery_weight2%TYPE,         -- �d�ʂQ
    actual_distance          xxwip_deliverys.actual_distance%TYPE,          -- �Œ����ۋ���
    congestion_charge        xxwip_deliverys.congestion_charge%TYPE,        -- �ʍs��
    consolid_qty             xxwip_deliverys.consolid_qty%TYPE,             -- ���ڐ�
    order_type               xxwip_deliverys.order_type%TYPE,               -- ��\�^�C�v
    weight_capacity_class    xxwip_deliverys.weight_capacity_class%TYPE,    -- �d�ʗe�ϋ敪
    outside_contract         xxwip_deliverys.outside_contract%TYPE,         -- �_��O�敪
    transfer_location        xxwip_deliverys.transfer_location%TYPE,        -- �U�֐�
    description              xxwip_deliverys.description%TYPE,              -- �^���E�v
    dispatch_type            xxwip_deliverys.dispatch_type%TYPE,            -- �z�ԃ^�C�v(2008/07/11)
    bill_picking_amount      xxwip_delivery_company.bill_picking_amount%TYPE-- �����s�b�L���O�P��
  );
--
  -- �^���w�b�_�A�h�I�����o�f�[�^���i�[����e�[�u��
  TYPE tbl_extraction_xd IS TABLE OF rec_extraction_xd INDEX BY PLS_INTEGER;
  gt_extraction_xd   tbl_extraction_xd;
--
  -- �^���A�h�I���}�X�^���o�f�[�^���i�[���郌�R�[�h�ϐ�
  gr_extraction_xdc  xxwip_common3_pkg.delivery_charges_rec;
--
  -- ���։^���w�b�_�A�h�I�����o�p���R�[�h�^
  TYPE rec_extraction_ex_xd IS RECORD(
    delivery_company_code    xxwip_deliverys.delivery_company_code%TYPE,    -- �^���Ǝ�
    delivery_no              xxwip_deliverys.delivery_no%TYPE,              -- �z��No
    judgement_date           xxwip_deliverys.judgement_date%TYPE,           -- ���f��
    goods_classe             xxwip_deliverys.goods_classe%TYPE,             -- ���i�敪
    mixed_code               xxwip_deliverys.mixed_code%TYPE,               -- ���ڋ敪
    charged_amount           xxwip_deliverys.charged_amount%TYPE,           -- �����^��
    many_rate                xxwip_deliverys.many_rate%TYPE,                -- ������
    distance                 xxwip_deliverys.distance%TYPE,                 -- �Œ�����
    delivery_classe          xxwip_deliverys.delivery_classe%TYPE,          -- �z���敪
    qty1                     xxwip_deliverys.qty1%TYPE,                     -- ���P
    delivery_weight1         xxwip_deliverys.delivery_weight1%TYPE,         -- �d�ʂP
    consolid_qty             xxwip_deliverys.consolid_qty%TYPE,             -- ���ڐ�
    bill_picking_amount      xxwip_delivery_company.bill_picking_amount%TYPE-- �����s�b�L���O�P��
  );
--
  -- ���։^���w�b�_�A�h�I�����o�f�[�^���i�[����e�[�u��
  TYPE tbl_extraction_ex_xd IS TABLE OF rec_extraction_ex_xd INDEX BY PLS_INTEGER;
  gt_extraction_ex_xd   tbl_extraction_ex_xd;
--
  -- ���։^���A�h�I���}�X�^���o�f�[�^���i�[���郌�R�[�h�ϐ�
  gr_extraction_ex_xdc  xxwip_common3_pkg.delivery_charges_rec;
--
  -- ====================================
  -- �^���w�b�_�A�h�I���o�^�pPL/SQL�\��`
  -- ====================================
--
  -- (�o�^�p)�^���w�b�_�[�A�h�I��ID
  TYPE t_ins_deliverys_header_id IS TABLE OF xxwip_deliverys.deliverys_header_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�^���Ǝ�
  TYPE t_ins_delivery_company_code IS TABLE OF xxwip_deliverys.delivery_company_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�z��No
  TYPE t_ins_delivery_no IS TABLE OF xxwip_deliverys.delivery_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�����No
  TYPE t_ins_invoice_no IS TABLE OF xxwip_deliverys.invoice_no%TYPE
  INDEX BY BINARY_INTEGER;
-- ##### 20080916 Ver.1.3 T_S_570�Ή� START #####
  -- (�o�^�p)�����No2
  TYPE t_ins_invoice_no2 IS TABLE OF xxwip_deliverys.invoice_no2%TYPE
  INDEX BY BINARY_INTEGER;
-- ##### 20080916 Ver.1.3 T_S_570�Ή� END #####
  -- (�o�^�p)�x�������敪
  TYPE t_ins_p_b_classe IS TABLE OF xxwip_deliverys.p_b_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�x�����f�敪
  TYPE t_ins_payments_judgment_classe IS TABLE OF xxwip_deliverys.payments_judgment_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�o�ɓ�
  TYPE t_ins_ship_date IS TABLE OF xxwip_deliverys.ship_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)������
  TYPE t_ins_arrival_date IS TABLE OF xxwip_deliverys.arrival_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�񍐓�
  TYPE t_ins_report_date IS TABLE OF xxwip_deliverys.report_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)���f��
  TYPE t_ins_judgement_date IS TABLE OF xxwip_deliverys.judgement_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)���i�敪
  TYPE t_ins_goods_classe IS TABLE OF xxwip_deliverys.goods_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)���ڋ敪
  TYPE t_ins_mixed_code IS TABLE OF xxwip_deliverys.mixed_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�����^��
  TYPE t_ins_charged_amount IS TABLE OF xxwip_deliverys.charged_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�_��^��
  TYPE t_ins_contract_rate IS TABLE OF xxwip_deliverys.contract_rate%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)���z
  TYPE t_ins_balance IS TABLE OF xxwip_deliverys.balance%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)���v
  TYPE t_ins_total_amount IS TABLE OF xxwip_deliverys.total_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)������
  TYPE t_ins_many_rate IS TABLE OF xxwip_deliverys.many_rate%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�Œ�����
  TYPE t_ins_distance IS TABLE OF xxwip_deliverys.distance%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�z���敪
  TYPE t_ins_delivery_classe IS TABLE OF xxwip_deliverys.delivery_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)��\�o�ɑq�ɃR�[�h
  TYPE t_ins_whs_code IS TABLE OF xxwip_deliverys.whs_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)��\�z����R�[�h�敪
  TYPE t_ins_code_division IS TABLE OF xxwip_deliverys.code_division%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)��\�z����R�[�h
  TYPE t_ins_shipping_address_code IS TABLE OF xxwip_deliverys.shipping_address_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)���P
  TYPE t_ins_qty1 IS TABLE OF xxwip_deliverys.qty1%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)���Q
  TYPE t_ins_qty2 IS TABLE OF xxwip_deliverys.qty2%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�d�ʂP
  TYPE t_ins_delivery_weight1 IS TABLE OF xxwip_deliverys.delivery_weight1%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�d�ʂQ
  TYPE t_ins_delivery_weight2 IS TABLE OF xxwip_deliverys.delivery_weight2%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)���ڊ������z
  TYPE t_ins_consolid_surcharge IS TABLE OF xxwip_deliverys.consolid_surcharge%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�Œ����ۋ���
  TYPE t_ins_actual_distance IS TABLE OF xxwip_deliverys.actual_distance%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�ʍs��
  TYPE t_ins_congestion_charge IS TABLE OF xxwip_deliverys.congestion_charge%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�s�b�L���O��
  TYPE t_ins_picking_charge IS TABLE OF xxwip_deliverys.picking_charge%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)���ڐ�
  TYPE t_ins_consolid_qty IS TABLE OF xxwip_deliverys.consolid_qty%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)��\�^�C�v
  TYPE t_ins_order_type IS TABLE OF xxwip_deliverys.order_type%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�d�ʗe�ϋ敪
  TYPE t_ins_weight_capacity_class IS TABLE OF xxwip_deliverys.weight_capacity_class%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�_��O�敪
  TYPE t_ins_outside_contract IS TABLE OF xxwip_deliverys.outside_contract%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)���ً敪
  TYPE t_ins_output_flag IS TABLE OF xxwip_deliverys.output_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�x���m��敪
  TYPE t_ins_defined_flag IS TABLE OF xxwip_deliverys.defined_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�x���m���
  TYPE t_ins_return_flag IS TABLE OF xxwip_deliverys.return_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)��ʍX�V�L���敪
  TYPE t_ins_form_update_flag IS TABLE OF xxwip_deliverys.form_update_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�U�֐�
  TYPE t_ins_transfer_location IS TABLE OF xxwip_deliverys.transfer_location%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�O���ƎҕύX��
  TYPE t_ins_outside_up_count IS TABLE OF xxwip_deliverys.outside_up_count%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�^���E�v
  TYPE t_ins_description IS TABLE OF xxwip_deliverys.description%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�o�^�p)�z�ԃ^�C�v(2008/07/11)
  TYPE t_ins_dispatch_type IS TABLE OF xxwip_deliverys.dispatch_type%TYPE
  INDEX BY BINARY_INTEGER;
--
  tab_ins_deliverys_header_id           t_ins_deliverys_header_id;
  tab_ins_delivery_company_code         t_ins_delivery_company_code;
  tab_ins_delivery_no                   t_ins_delivery_no;
  tab_ins_invoice_no                    t_ins_invoice_no;
-- ##### 20080916 Ver.1.3 T_S_570�Ή� START #####
  tab_ins_invoice_no2                   t_ins_invoice_no2;
-- ##### 20080916 Ver.1.3 T_S_570�Ή� END #####
  tab_ins_p_b_classe                    t_ins_p_b_classe;
  tab_ins_payments_judgment_clas        t_ins_payments_judgment_classe;
  tab_ins_ship_date                     t_ins_ship_date;
  tab_ins_arrival_date                  t_ins_arrival_date;
  tab_ins_report_date                   t_ins_report_date;
  tab_ins_judgement_date                t_ins_judgement_date;
  tab_ins_goods_classe                  t_ins_goods_classe;
  tab_ins_mixed_code                    t_ins_mixed_code;
  tab_ins_charged_amount                t_ins_charged_amount;
  tab_ins_contract_rate                 t_ins_contract_rate;
  tab_ins_balance                       t_ins_balance;
  tab_ins_total_amount                  t_ins_total_amount;
  tab_ins_many_rate                     t_ins_many_rate;
  tab_ins_distance                      t_ins_distance;
  tab_ins_delivery_classe               t_ins_delivery_classe;
  tab_ins_whs_code                      t_ins_whs_code;
  tab_ins_code_division                 t_ins_code_division;
  tab_ins_shipping_address_code         t_ins_shipping_address_code;
  tab_ins_qty1                          t_ins_qty1;
  tab_ins_qty2                          t_ins_qty2;
  tab_ins_delivery_weight1              t_ins_delivery_weight1;
  tab_ins_delivery_weight2              t_ins_delivery_weight2;
  tab_ins_consolid_surcharge            t_ins_consolid_surcharge;
  tab_ins_actual_distance               t_ins_actual_distance;
  tab_ins_congestion_charge             t_ins_congestion_charge;
  tab_ins_picking_charge                t_ins_picking_charge;
  tab_ins_consolid_qty                  t_ins_consolid_qty;
  tab_ins_order_type                    t_ins_order_type;
  tab_ins_weight_capacity_class         t_ins_weight_capacity_class;
  tab_ins_outside_contract              t_ins_outside_contract;
  tab_ins_output_flag                   t_ins_output_flag;
  tab_ins_defined_flag                  t_ins_defined_flag;
  tab_ins_return_flag                   t_ins_return_flag;
  tab_ins_form_update_flag              t_ins_form_update_flag;
  tab_ins_transfer_location             t_ins_transfer_location;
  tab_ins_outside_up_count              t_ins_outside_up_count;
  tab_ins_description                   t_ins_description;
  tab_ins_dispatch_type                 t_ins_dispatch_type;              -- 2008/07/11
--
  -- �^���w�b�_�A�h�I���o�^�pPL/SQL�\����
  gn_ins_cnt    NUMBER;
--
  -- ====================================
  -- �^���w�b�_�A�h�I���X�V�pPL/SQL�\��`
  -- ====================================
--
  -- (�X�V�p)�z��No
  TYPE t_upd_delivery_no IS TABLE OF xxwip_deliverys.delivery_no%TYPE INDEX BY BINARY_INTEGER;
  -- (�X�V�p)�_��^��
  TYPE t_upd_contract_rate IS TABLE OF xxwip_deliverys.contract_rate%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)���z
  TYPE t_upd_balance IS TABLE OF xxwip_deliverys.balance%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)���v
  TYPE t_upd_total_amount IS TABLE OF xxwip_deliverys.total_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)�Œ�����
  TYPE t_upd_distance IS TABLE OF xxwip_deliverys.distance%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)�z���敪
  TYPE t_upd_delivery_classe IS TABLE OF xxwip_deliverys.delivery_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)���P
  TYPE t_upd_qty1 IS TABLE OF xxwip_deliverys.qty1%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)���Q
  TYPE t_upd_qty2 IS TABLE OF xxwip_deliverys.qty2%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)�d�ʂP
  TYPE t_upd_delivery_weight1 IS TABLE OF xxwip_deliverys.delivery_weight1%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)�d�ʂQ
  TYPE t_upd_delivery_weight2 IS TABLE OF xxwip_deliverys.delivery_weight2%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)������
  TYPE t_upd_many_rate IS TABLE OF xxwip_deliverys.many_rate%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)���ڊ������z
  TYPE t_upd_consolid_surcharge IS TABLE OF xxwip_deliverys.consolid_surcharge%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)�ʍs��
  TYPE t_upd_congestion_charge IS TABLE OF xxwip_deliverys.congestion_charge%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)�s�b�L���O��
  TYPE t_upd_picking_charge IS TABLE OF xxwip_deliverys.picking_charge%TYPE
  INDEX BY BINARY_INTEGER;
--
  tab_upd_delivery_no                   t_upd_delivery_no;
  tab_upd_contract_rate                 t_upd_contract_rate;
  tab_upd_balance                       t_upd_balance;
  tab_upd_total_amount                  t_upd_total_amount;
  tab_upd_distance                      t_upd_distance;
  tab_upd_delivery_classe               t_upd_delivery_classe;
  tab_upd_qty1                          t_upd_qty1;
  tab_upd_qty2                          t_upd_qty2;
  tab_upd_delivery_weight1              t_upd_delivery_weight1;
  tab_upd_delivery_weight2              t_upd_delivery_weight2;
  tab_upd_many_rate                     t_upd_many_rate;
  tab_upd_consolid_surcharge            t_upd_consolid_surcharge;
  tab_upd_congestion_charge             t_upd_congestion_charge;
  tab_upd_picking_charge                t_upd_picking_charge;
--
-- ##### 20080723 Ver.1.2 �����ύX#132�Ή� START #####
--       �X�V���ڒǉ�
--
  -- (�X�V�p)�^���Ǝ�
  TYPE t_upd_delivery_company_code IS TABLE OF xxwip_deliverys.delivery_company_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)�����No
  TYPE t_upd_invoice_no IS TABLE OF xxwip_deliverys.invoice_no%TYPE
  INDEX BY BINARY_INTEGER;
-- ##### 20080916 Ver.1.3 T_S_570�Ή� START #####
  -- (�X�V�p)�����No2
  TYPE t_upd_invoice_no2 IS TABLE OF xxwip_deliverys.invoice_no2%TYPE
  INDEX BY BINARY_INTEGER;
-- ##### 20080916 Ver.1.3 T_S_570�Ή� END #####
  -- (�X�V�p)�x�����f�敪
  TYPE t_upd_payments_judgment_classe IS TABLE OF xxwip_deliverys.payments_judgment_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)�o�ɓ�
  TYPE t_upd_ship_date IS TABLE OF xxwip_deliverys.ship_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)������
  TYPE t_upd_arrival_date IS TABLE OF xxwip_deliverys.arrival_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)�񍐓�
  TYPE t_upd_report_date IS TABLE OF xxwip_deliverys.report_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)���f��
  TYPE t_upd_judgement_date IS TABLE OF xxwip_deliverys.judgement_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)���i�敪
  TYPE t_upd_goods_classe IS TABLE OF xxwip_deliverys.goods_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)���ڋ敪
  TYPE t_upd_mixed_code IS TABLE OF xxwip_deliverys.mixed_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)�����^��
  TYPE t_upd_charged_amount IS TABLE OF xxwip_deliverys.charged_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)��\�o�ɑq�ɃR�[�h
  TYPE t_upd_whs_code IS TABLE OF xxwip_deliverys.whs_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)��\�z����R�[�h�敪
  TYPE t_upd_code_division IS TABLE OF xxwip_deliverys.code_division%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)��\�z����R�[�h
  TYPE t_upd_shipping_address_code IS TABLE OF xxwip_deliverys.shipping_address_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)�Œ����ۋ���
  TYPE t_upd_actual_distance IS TABLE OF xxwip_deliverys.actual_distance%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)���ڐ�
  TYPE t_upd_consolid_qty IS TABLE OF xxwip_deliverys.consolid_qty%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)��\�^�C�v
  TYPE t_upd_order_type IS TABLE OF xxwip_deliverys.order_type%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)�d�ʗe�ϋ敪
  TYPE t_upd_weight_capacity_class IS TABLE OF xxwip_deliverys.weight_capacity_class%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)�_��O�敪
  TYPE t_upd_outside_contract IS TABLE OF xxwip_deliverys.outside_contract%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)���ً敪
  TYPE t_upd_output_flag IS TABLE OF xxwip_deliverys.output_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)�x���m��敪
  TYPE t_upd_defined_flag IS TABLE OF xxwip_deliverys.defined_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)�x���m���
  TYPE t_upd_return_flag IS TABLE OF xxwip_deliverys.return_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)�U�֐�
  TYPE t_upd_transfer_location IS TABLE OF xxwip_deliverys.transfer_location%TYPE
  INDEX BY BINARY_INTEGER;
  -- (�X�V�p)�z�ԃ^�C�v
  TYPE t_upd_dispatch_type IS TABLE OF xxwip_deliverys.dispatch_type%TYPE
  INDEX BY BINARY_INTEGER;
--
  tab_upd_delivery_company_code         t_upd_delivery_company_code;     -- (�X�V�p)�^���Ǝ�
  tab_upd_invoice_no                    t_upd_invoice_no;                -- (�X�V�p)�����No
-- ##### 20080916 Ver.1.3 T_S_570�Ή� START #####
  tab_upd_invoice_no2                   t_upd_invoice_no2;               -- (�X�V�p)�����No2
-- ##### 20080916 Ver.1.3 T_S_570�Ή� END #####
  tab_upd_payments_judgment_clas        t_upd_payments_judgment_classe;  -- (�X�V�p)�x�����f�敪
  tab_upd_ship_date                     t_upd_ship_date;                 -- (�X�V�p)�o�ɓ�
  tab_upd_arrival_date                  t_upd_arrival_date;              -- (�X�V�p)������
  tab_upd_report_date                   t_upd_report_date;               -- (�X�V�p)�񍐓�
  tab_upd_judgement_date                t_upd_judgement_date;            -- (�X�V�p)���f��
  tab_upd_goods_classe                  t_upd_goods_classe;              -- (�X�V�p)���i�敪
  tab_upd_mixed_code                    t_upd_mixed_code;                -- (�X�V�p)���ڋ敪
  tab_upd_charged_amount                t_upd_charged_amount;            -- (�X�V�p)�����^��
  tab_upd_whs_code                      t_upd_whs_code;                  -- (�X�V�p)��\�o�ɑq�ɃR�[�h
  tab_upd_code_division                 t_upd_code_division;             -- (�X�V�p)��\�z����R�[�h�敪
  tab_upd_shipping_address_code         t_upd_shipping_address_code;     -- (�X�V�p)��\�z����R�[�h
  tab_upd_actual_distance               t_upd_actual_distance;           -- (�X�V�p)�Œ����ۋ���
  tab_upd_consolid_qty                  t_upd_consolid_qty;              -- (�X�V�p)���ڐ�
  tab_upd_order_type                    t_upd_order_type;                -- (�X�V�p)��\�^�C�v
  tab_upd_weight_capacity_class         t_upd_weight_capacity_class;     -- (�X�V�p)�d�ʗe�ϋ敪
  tab_upd_outside_contract              t_upd_outside_contract;          -- (�X�V�p)�_��O�敪
  tab_upd_output_flag                   t_upd_output_flag;               -- (�X�V�p)���ً敪
  tab_upd_defined_flag                  t_upd_defined_flag;              -- (�X�V�p)�x���m��敪
  tab_upd_return_flag                   t_upd_return_flag;               -- (�X�V�p)�x���m���
  tab_upd_transfer_location             t_upd_transfer_location;         -- (�X�V�p)�U�֐�
  tab_upd_dispatch_type                 t_upd_dispatch_type;             -- (�X�V�p)�z�ԃ^�C�v
--
-- ##### 20080723 Ver.1.2 �����ύX#132�Ή� END   #####
--
  -- �^���w�b�_�A�h�I���X�V�pPL/SQL�\����
  gn_upd_cnt    NUMBER;
--
  -- ========================================
  -- ���։^���w�b�_�A�h�I���X�V�pPL/SQL�\��`
  -- ========================================
--
  -- (���֗p)�z��No
  TYPE t_ex_delivery_no IS TABLE OF xxwip_deliverys.delivery_no%TYPE INDEX BY BINARY_INTEGER;
  -- (���֗p)�_��^��
  TYPE t_ex_contract_rate IS TABLE OF xxwip_deliverys.contract_rate%TYPE INDEX BY BINARY_INTEGER;
  -- (���֗p)���z
  TYPE t_ex_balance IS TABLE OF xxwip_deliverys.balance%TYPE INDEX BY BINARY_INTEGER;
  -- (���֗p)���v
  TYPE t_ex_total_amount IS TABLE OF xxwip_deliverys.total_amount%TYPE INDEX BY BINARY_INTEGER;
  -- (���֗p)���ڊ������z
  TYPE t_ex_consolid_surcharge IS TABLE OF xxwip_deliverys.consolid_surcharge%TYPE INDEX BY BINARY_INTEGER;
  -- (���֗p)�s�b�L���O��
  TYPE t_ex_picking_charge IS TABLE OF xxwip_deliverys.picking_charge%TYPE INDEX BY BINARY_INTEGER;
--
  tab_ex_delivery_no                    t_ex_delivery_no;
  tab_ex_contract_rate                  t_ex_contract_rate;
  tab_ex_balance                        t_ex_balance;
  tab_ex_total_amount                   t_ex_total_amount;
  tab_ex_consolid_surcharge             t_ex_consolid_surcharge;
  tab_ex_picking_charge                 t_ex_picking_charge;
--
  -- ���։^���w�b�_�A�h�I���X�V�pPL/SQL�\����
  gn_ex_cnt     NUMBER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gd_sysdate             DATE;             -- �V�X�e�����t
  gn_user_id             NUMBER;           -- ���[�UID
  gn_login_id            NUMBER;           -- �ŏI�X�V���O�C��
  gn_conc_request_id     NUMBER;           -- �v��ID
  gn_prog_appl_id        NUMBER;           -- �ݶ��āE��۸��т̱��ع����ID
  gn_conc_program_id     NUMBER;           -- �R���J�����g�E�v���O����ID
--
  gd_last_process_date   DATE;             -- �O�񏈗����t
  gv_closed_day          VARCHAR2(1);      -- ��������
--
  /**********************************************************************************
   * Procedure Name   : cal_money_proc
   * Description      : ���z�v�Z����(�@�\�ڍהԍ�����)
   ***********************************************************************************/
  PROCEDURE cal_money_proc(
    in_goods_classe        IN  xxwip_deliverys.goods_classe%TYPE,               -- ���i�敪
    in_mixed_code          IN  xxwip_deliverys.mixed_code%TYPE,                 -- ���ڋ敪
-- ##### 20080723 Ver.1.2 �����ύX#132�Ή� START #####
    in_charged_amount      IN  xxwip_deliverys.charged_amount%TYPE,             -- �����^��
-- ##### 20080723 Ver.1.2 �����ύX#132�Ή� END   #####
    in_shipping_expenses   IN  xxwip_delivery_charges.shipping_expenses%TYPE,   -- �^����
    in_many_rate           IN  xxwip_deliverys.many_rate%TYPE,                  -- ������
    in_leaf_consolid_add   IN  xxwip_delivery_charges.leaf_consolid_add%TYPE,   -- ���[�t���ڊ���
    in_consolid_qty        IN  xxwip_deliverys.consolid_qty%TYPE,               -- ���ڐ�
    in_qty1                IN  xxwip_deliverys.qty1%TYPE,                       -- ��1
    in_bill_picking_amount IN  xxwip_delivery_company.bill_picking_amount%TYPE, -- �����߯�ݸޒP��
    on_balance             OUT NOCOPY xxwip_deliverys.balance%TYPE,             -- ���z
    on_total_amount        OUT NOCOPY xxwip_deliverys.total_amount%TYPE,        -- ���v
    on_consolid_surcharge  OUT NOCOPY xxwip_deliverys.consolid_surcharge%TYPE,  -- ���ڊ������z
    on_picking_charge      OUT NOCOPY xxwip_deliverys.picking_charge%TYPE,      -- �s�b�L���O��
    ov_errbuf              OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cal_money_proc'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    ln_balance            NUMBER; -- ����z��Z�o���ʊi�[�p
    ln_total_amount       NUMBER; -- ����v��Z�o���ʊi�[�p
    ln_consolid_surcharge NUMBER; -- ����ڊ������z��Z�o���ʊi�[�p
    ln_picking_charge     NUMBER; -- ��s�b�L���O����Z�o���ʊi�[�p
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
    -- ����ڊ������z��̎Z�o
    IF ((in_goods_classe = gv_prod_class_lef)
      AND (in_mixed_code = gv_mixed_code_1))
    THEN
      ln_consolid_surcharge := ROUND(in_leaf_consolid_add * in_consolid_qty);
    ELSE
      ln_consolid_surcharge := 0;
    END IF;
--
    -- ��s�b�L���O����̎Z�o
    ln_picking_charge := ROUND(in_qty1 * in_bill_picking_amount);
--
    -- ����v��̎Z�o
-- ##### 20081024 Ver.1.4 ����#408�Ή� START #####
--    ln_total_amount := in_shipping_expenses + ln_consolid_surcharge
--                     + ln_picking_charge    + NVL(in_many_rate, 0);
    -- ���v �� �����^���{���ڊ������z�{PIC�{������
    ln_total_amount := NVL(in_charged_amount,0) + ln_consolid_surcharge
                     + ln_picking_charge    + NVL(in_many_rate, 0);
-- ##### 20081024 Ver.1.4 ����#408�Ή� END   #####
--
    -- ����z��̎Z�o(���v�|�����^���{���ڊ������z�{PIC�{������)
-- ##### 20080723 Ver.1.2 �����ύX#132�Ή� START #####
--    ln_balance := in_shipping_expenses - ln_total_amount;
-- ##### 20081024 Ver.1.4 ����#408�Ή� START #####
--    ln_balance := in_charged_amount - ln_total_amount;
    ln_balance := ln_total_amount - (NVL(in_charged_amount,0) + ln_consolid_surcharge
                                       + ln_picking_charge    + NVL(in_many_rate, 0));
-- ##### 20081024 Ver.1.4 ����#408�Ή� END   #####
-- ##### 20080723 Ver.1.2 �����ύX#132�Ή� END   #####
--
    -- �e�Z�o�l��OUT�ϐ��ɃZ�b�g
    on_balance            := ln_balance;
    on_total_amount       := ln_total_amount;
    on_picking_charge     := ln_picking_charge;
    on_consolid_surcharge := ln_consolid_surcharge;
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
  END cal_money_proc;
--
  /**********************************************************************************
   * Procedure Name   : chk_param_proc
   * Description      : �p�����[�^�`�F�b�N����(D-1)
   ***********************************************************************************/
  PROCEDURE chk_param_proc(
    iv_exchange_type   IN         VARCHAR2,     -- ���֋敪
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param_proc'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    ln_count NUMBER;   -- �`�F�b�N�p�J�E���^
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
    -- �K�{�`�F�b�N
    IF (iv_exchange_type IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wip
                                           ,gv_msg_wip_10008
                                           ,gv_tkn_item
                                           ,gv_exchange_type_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �`�F�b�N�p�J�E���^�[�̏�����
    ln_count := 0;
--
    -- ���̓p�����[�^�̑��݃`�F�b�N
    SELECT COUNT(1) CNT                -- �J�E���g
    INTO   ln_count
    FROM   xxcmn_lookup_values_v xlv   -- �N�C�b�N�R�[�h���VIEW
    WHERE  xlv.lookup_type = 'XXCMN_YESNO'
    AND    xlv.lookup_code = iv_exchange_type
    AND    ROWNUM          = 1;
--
    -- ���֋敪�����݂��Ȃ��ꍇ
    IF (ln_count < 1) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn,   gv_msg_cmn_10010,
                                            gv_tkn_parameter, gv_exchange_type_name,
                                            gv_tkn_value,     iv_exchange_type);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
  END chk_param_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_init
   * Description      : �֘A�f�[�^�擾(D-2)
   ***********************************************************************************/
  PROCEDURE get_init(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_init'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    gd_sysdate          := SYSDATE;                    -- �V�X�e������
    gn_user_id          := FND_GLOBAL.USER_ID;         -- ���O�C�����[�UID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;        -- ���O�C��ID
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID; -- �R���J�����g�v��ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;    -- �ݶ��āE��۸��сE���ع����ID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID; -- �R���J�����g�E�v���O����ID
--
    -- �^���v�Z�p�R���g���[�����O�񏈗����t���擾
    BEGIN
      SELECT xdc.last_process_date    -- �O�񏈗����t
      INTO   gd_last_process_date
      FROM   xxwip_deliverys_ctrl xdc -- �^���v�Z�p�R���g���[���A�h�I��
      WHERE  xdc.concurrent_no = gv_con_no_deli
      FOR UPDATE NOWAIT;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN   --*** �f�[�^�擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_cmn_10001,
                                              gv_tkn_table,   gv_deli_ctrl_name,
                                              gv_tkn_key,     gv_con_no_deli);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN lock_expt THEN       --*** ���b�N�擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wip, gv_msg_wip_10004,
                                              gv_tkn_table,   gv_deli_ctrl_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END get_init;
--
  /**********************************************************************************
   * Procedure Name   : chk_close_proc
   * Description      : �^���p�������擾(D-3)
   ***********************************************************************************/
  PROCEDURE chk_close_proc(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_close_proc'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    lv_close_type VARCHAR2(1);
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
    -- �O���^�����ߌ� ����
    xxwip_common3_pkg.check_lastmonth_close(
      lv_close_type,   -- ���ߋ敪(Y:�����O�AN:������)
      lv_errbuf,       -- �G���[�E���b�Z�[�W
      lv_retcode,      -- ���^�[���E�R�[�h
      lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���ߔ��� �ݒ�
    gv_closed_day := lv_close_type;
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
  END chk_close_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_lock_xd
   * Description      : ���b�N�擾(D-4)
   ***********************************************************************************/
  PROCEDURE get_lock_xd(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lock_xd'; -- �v���O������
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
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cur_lock_xd IS
      SELECT xd.deliverys_header_id
      FROM   xxwip_deliverys xd
      WHERE  xd.p_b_classe = gv_paycharge_type_2
      FOR UPDATE NOWAIT;
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
    -- �^���w�b�_�A�h�I���̃��R�[�h���b�N���擾
    OPEN cur_lock_xd;
--
  EXCEPTION
--
    -- ���b�N���s�G���[
    WHEN lock_expt THEN
      lv_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_wip, gv_msg_wip_10004,
                                             gv_tkn_table,   gv_deli_name);
      lv_errbuf  := lv_errmsg;
      -- OUT�ϐ��ɏ����o��
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END get_lock_xd;
--
  /**********************************************************************************
   * Procedure Name   : get_xd_data
   * Description      : �^���w�b�_�A�h�I�����o(D-5)
   ***********************************************************************************/
  PROCEDURE get_xd_data(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xd_data'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    ld_first_day        DATE;   -- �^���p����
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
    IF (gv_closed_day = 'N') THEN
      -- (������)�����̏������擾
      ld_first_day := TRUNC(gd_sysdate, 'MM');
    ELSIF (gv_closed_day = 'Y') THEN
      -- (�����O)�挎�̌��������擾
      ld_first_day := TRUNC(ADD_MONTHS(gd_sysdate, -1), 'MM');
    END IF;
--
    -- �^���w�b�_�A�h�I���f�[�^���o
    BEGIN
      SELECT xd.delivery_company_code,       -- �^���Ǝ�
             xd.delivery_no,                 -- �z��No
             xd.invoice_no,                  -- �����No
-- ##### 20080916 Ver.1.3 T_S_570�Ή� START #####
             xd.invoice_no2,                 -- �����No2
-- ##### 20080916 Ver.1.3 T_S_570�Ή� END #####
             xd.payments_judgment_classe,    -- �x�����f�敪
             xd.ship_date,                   -- �o�ɓ�
             xd.arrival_date,                -- ������
             xd.report_date,                 -- �񍐓�
             xd.judgement_date,              -- ���f��
             xd.goods_classe,                -- ���i�敪
             xd.mixed_code,                  -- ���ڋ敪
             xd.many_rate,                   -- ������
             xd.distance,                    -- �Œ�����
             xd.delivery_classe,             -- �z���敪
             xd.whs_code,                    -- ��\�o�ɑq�ɃR�[�h
             xd.code_division,               -- ��\�z����R�[�h�敪
             xd.shipping_address_code,       -- ��\�z����R�[�h
             xd.qty1,                        -- ���P
             xd.qty2,                        -- ���Q
             xd.delivery_weight1,            -- �d�ʂP
             xd.delivery_weight2,            -- �d�ʂQ
             xd.actual_distance,             -- �Œ����ۋ���
             xd.congestion_charge,           -- �ʍs��
             xd.consolid_qty,                -- ���ڐ�
             xd.order_type,                  -- ��\�^�C�v
             xd.weight_capacity_class,       -- �d�ʗe�ϋ敪
             xd.outside_contract,            -- �_��O�敪
             xd.transfer_location,           -- �U�֐�
             xd.description,                 -- �^���E�v
             xd.dispatch_type,               -- �z�ԃ^�C�v(2008/07/11)
             NVL(xdc.bill_picking_amount, 0) -- �����s�b�L���O�P��
      BULK COLLECT INTO gt_extraction_xd
      FROM   xxwip_deliverys        xd,  -- �^���w�b�_�A�h�I��
             xxwip_delivery_company xdc  -- �^���p�^���Ǝ҃A�h�I���}�X�^
      WHERE  xd.p_b_classe            =  gv_paycharge_type_1
      AND    xd.defined_flag          =  gv_defined_yes
      AND    xd.goods_classe          =  xdc.goods_classe(+)
      AND    xd.delivery_company_code =  xdc.delivery_company_code(+)
      AND    xd.judgement_date        >= xdc.start_date_active(+)
      AND    xd.judgement_date        <= xdc.end_date_active(+)
      AND    xd.judgement_date        >= ld_first_day
      AND    xd.last_update_date      >  gd_last_process_date
      AND    xd.last_update_date      <= gd_sysdate
      ORDER BY xd.delivery_no;
    END;
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
  END get_xd_data;
--
  /**********************************************************************************
   * Procedure Name   : get_xdc_data
   * Description      : �^���A�h�I���}�X�^���o(D-6)
   ***********************************************************************************/
  PROCEDURE get_xdc_data(
    ir_xd_data    IN  rec_extraction_xd,   --   �^���w�b�_�[�A�h�I�����R�[�h
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xdc_data'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- (�^���A�h�I���}�X�^)�^����A���[�t���ڊ����擾
    xxwip_common3_pkg.get_delivery_charges(
      iv_p_b_classe              => gv_paycharge_type_2,              -- �x�������敪������
      iv_goods_classe            => ir_xd_data.goods_classe,          -- ���i�敪
      iv_delivery_company_code   => ir_xd_data.delivery_company_code, -- �^���Ǝ�
      iv_shipping_address_classe => ir_xd_data.delivery_classe,       -- �z���敪
      iv_delivery_distance       => ir_xd_data.distance,              -- �Œ�����
      iv_delivery_weight         => ir_xd_data.delivery_weight1,      -- �d��
      id_target_date             => ir_xd_data.judgement_date,        -- ���f��
      or_delivery_charges        => gr_extraction_xdc,                -- �^���A�h�I�����R�[�h
      ov_errbuf                  => lv_errbuf,                        -- �G���[�E���b�Z�[�W
      ov_retcode                 => lv_retcode,                       -- ���^�[���E�R�[�h
      ov_errmsg                  => lv_errmsg);                       -- հ�ް��װ�ү����
--
    -- ������`�F�b�N
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
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
  END get_xdc_data;
--
  /**********************************************************************************
   * Procedure Name   : set_xd_data
   * Description      : �^���w�b�_�A�h�I��PL/SQL�\�i�[(D-7)
   ***********************************************************************************/
  PROCEDURE set_xd_data(
    ir_xd_data    IN  rec_extraction_xd,   --   �^���w�b�_�[�A�h�I�����R�[�h
    ir_xdc_data   IN  xxwip_common3_pkg.delivery_charges_rec,
                                           --   �^���A�h�I���}�X�^���R�[�h
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_xd_data'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    ln_cnt                 NUMBER; -- ���݃`�F�b�N�p
    ln_balance             NUMBER; -- ����z�
    ln_total_amount        NUMBER; -- ����v�
    ln_consolid_surcharge  NUMBER; -- ����ڊ������z�
    ln_picking_charge      NUMBER; -- ��s�b�L���O���
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
    -- �o�^�A�X�V�𔻒�(���݃`�F�b�N)
    BEGIN
      SELECT COUNT(xd.deliverys_header_id)
      INTO   ln_cnt
      FROM   xxwip_deliverys xd
      WHERE  xd.p_b_classe  = gv_paycharge_type_2
      AND    xd.delivery_no = ir_xd_data.delivery_no
      AND    ROWNUM         = 1;
    END;
--
    -- ����z�����v�����ڊ������z���s�b�L���O����̎Z�o
    cal_money_proc(
      in_goods_classe        => ir_xd_data.goods_classe,        -- ���i�敪
      in_mixed_code          => ir_xd_data.mixed_code,          -- ���ڋ敪
-- ##### 20080723 Ver.1.2 �����ύX#132�Ή� START #####
      in_charged_amount      => ir_xdc_data.shipping_expenses,  -- �������z�i�^����j
-- ##### 20080723 Ver.1.2 �����ύX#132�Ή� END   #####
      in_shipping_expenses   => ir_xdc_data.shipping_expenses,  -- �^����
      in_many_rate           => ir_xd_data.many_rate,           -- ������
      in_leaf_consolid_add   => ir_xdc_data.leaf_consolid_add,  -- ���[�t���ڊ���
      in_consolid_qty        => ir_xd_data.consolid_qty,        -- ���ڐ�
      in_qty1                => ir_xd_data.qty1,                -- ��1
      in_bill_picking_amount => ir_xd_data.bill_picking_amount, -- �����s�b�L���O�P��
      on_balance             => ln_balance,                     -- ���z
      on_total_amount        => ln_total_amount,                -- ���v
      on_consolid_surcharge  => ln_consolid_surcharge,          -- ���ڊ������z
      on_picking_charge      => ln_picking_charge,              -- �s�b�L���O��
      ov_errbuf              => lv_errbuf,                      -- �G���[�E���b�Z�[�W
      ov_retcode             => lv_retcode,                     -- ���^�[���E�R�[�h
      ov_errmsg              => lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- �������ʃ`�F�b�N
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    IF (ln_cnt = 0) THEN
--
      -- ***************************************
      -- *** �o�^�pPL/SQL�\�i�[����          ***
      -- ***************************************
--
      -- �o�^�e�[�u�������C���N�������g
      gn_ins_cnt := gn_ins_cnt + 1;
--
      -- �V�[�P���X�擾
      SELECT xxwip_deliverys_id_s1.NEXTVAL
      INTO   tab_ins_deliverys_header_id(gn_ins_cnt)  -- �^���w�b�_�[�A�h�I��ID
      FROM   dual;
--
      tab_ins_delivery_company_code(gn_ins_cnt) := ir_xd_data.delivery_company_code;
                                                                                 -- �^���Ǝ�
      tab_ins_delivery_no(gn_ins_cnt)           := ir_xd_data.delivery_no;       -- �z��No
      tab_ins_invoice_no(gn_ins_cnt)            := ir_xd_data.invoice_no;        -- �����No
-- ##### 20080916 Ver.1.3 T_S_570�Ή� START #####
      tab_ins_invoice_no2(gn_ins_cnt)           := ir_xd_data.invoice_no2;        -- �����No2
-- ##### 20080916 Ver.1.3 T_S_570�Ή� END #####
      tab_ins_p_b_classe(gn_ins_cnt)            := gv_paycharge_type_2;          -- �x��������
      tab_ins_payments_judgment_clas(gn_ins_cnt) := ir_xd_data.payments_judgment_classe;
                                                                                 -- �x�����f��
      tab_ins_ship_date(gn_ins_cnt)             := ir_xd_data.ship_date;         -- �o�ɓ�
      tab_ins_arrival_date(gn_ins_cnt)          := ir_xd_data.arrival_date;      -- ������
      tab_ins_report_date(gn_ins_cnt)           := ir_xd_data.report_date;       -- �񍐓�
      tab_ins_judgement_date(gn_ins_cnt)        := ir_xd_data.judgement_date;    -- ���f��
      tab_ins_goods_classe(gn_ins_cnt)          := ir_xd_data.goods_classe;      -- ���i�敪
      tab_ins_mixed_code(gn_ins_cnt)            := ir_xd_data.mixed_code;        -- ���ڋ敪
      tab_ins_charged_amount(gn_ins_cnt)        := ir_xdc_data.shipping_expenses;-- �����^��
      tab_ins_contract_rate(gn_ins_cnt)         := ir_xdc_data.shipping_expenses;-- �_��^��
      tab_ins_balance(gn_ins_cnt)               := ln_balance;                   -- ���z
      tab_ins_total_amount(gn_ins_cnt)          := ln_total_amount;              -- ���v
      tab_ins_many_rate(gn_ins_cnt)             := ir_xd_data.many_rate;         -- ������
      tab_ins_distance(gn_ins_cnt)              := ir_xd_data.distance;          -- �Œ�����
      tab_ins_delivery_classe(gn_ins_cnt)       := ir_xd_data.delivery_classe;   -- �z���敪
      tab_ins_whs_code(gn_ins_cnt)              := ir_xd_data.whs_code;          -- ��\�o�ɑq��CD
      tab_ins_code_division(gn_ins_cnt)         := ir_xd_data.code_division;     -- ��\�z����CD��
      tab_ins_shipping_address_code(gn_ins_cnt) := ir_xd_data.shipping_address_code;
                                                                                 -- ��\�z����CD
      tab_ins_qty1(gn_ins_cnt)                  := ir_xd_data.qty1;              -- ���P
      tab_ins_qty2(gn_ins_cnt)                  := ir_xd_data.qty2;              -- ���Q
      tab_ins_delivery_weight1(gn_ins_cnt)      := ir_xd_data.delivery_weight1;  -- �d�ʂP
      tab_ins_delivery_weight2(gn_ins_cnt)      := ir_xd_data.delivery_weight2;  -- �d�ʂQ
      tab_ins_consolid_surcharge(gn_ins_cnt)    := ln_consolid_surcharge;        -- ���ڊ������z
      tab_ins_actual_distance(gn_ins_cnt)       := ir_xd_data.actual_distance;   -- �Œ����ۋ���
      tab_ins_congestion_charge(gn_ins_cnt)     := ir_xd_data.congestion_charge; -- �ʍs��
      tab_ins_picking_charge(gn_ins_cnt)        := ln_picking_charge;            -- �s�b�L���O��
      tab_ins_consolid_qty(gn_ins_cnt)          := ir_xd_data.consolid_qty;      -- ���ڐ�
      tab_ins_order_type(gn_ins_cnt)            := ir_xd_data.order_type;        -- ��\�^�C�v
      tab_ins_weight_capacity_class(gn_ins_cnt) := ir_xd_data.weight_capacity_class;
                                                                                 -- �d�ʗe�ϋ敪
      tab_ins_outside_contract(gn_ins_cnt)      := ir_xd_data.outside_contract;  -- �_��O�敪
      tab_ins_output_flag(gn_ins_cnt)           := NULL;                         -- ���ً敪
      tab_ins_defined_flag(gn_ins_cnt)          := NULL;                         -- �x���m��敪
      tab_ins_return_flag(gn_ins_cnt)           := NULL;                         -- �x���m���
      tab_ins_form_update_flag(gn_ins_cnt)      := 'N';                          -- ��ʍX�V�L����
      tab_ins_transfer_location(gn_ins_cnt)     := ir_xd_data.transfer_location; -- �U�֐�
      tab_ins_outside_up_count(gn_ins_cnt)      := 0;                            -- �O���ƎҕύX��
      tab_ins_description(gn_ins_cnt)           := ir_xd_data.description;       -- �^���E�v
--
      -- 2008/07/11
      tab_ins_dispatch_type(gn_ins_cnt)         := ir_xd_data.dispatch_type;     -- �z�ԃ^�C�v
--
    ELSE
--
      -- ***************************************
      -- *** �X�V�pPL/SQL�\�i�[����          ***
      -- ***************************************
--
      -- �X�V�e�[�u�������C���N�������g
      gn_upd_cnt := gn_upd_cnt + 1;
--
-- ##### 20080723 Ver.1.2 �����ύX#132�Ή� START #####
-- �o�^���Ɠ�����ԂɍX�V����ׁA�X�V���ڒǉ�
--
      tab_upd_delivery_company_code(gn_upd_cnt)     := ir_xd_data.delivery_company_code;    -- �^���Ǝ�
      tab_upd_invoice_no(gn_upd_cnt)                := ir_xd_data.invoice_no;               -- �����No
-- ##### 20080916 Ver.1.3 T_S_570�Ή� START #####
      tab_upd_invoice_no2(gn_upd_cnt)               := ir_xd_data.invoice_no2;              -- �����No2
-- ##### 20080916 Ver.1.3 T_S_570�Ή� END #####
      tab_upd_payments_judgment_clas(gn_upd_cnt)    := ir_xd_data.payments_judgment_classe; -- �x�����f�敪
      tab_upd_ship_date(gn_upd_cnt)                 := ir_xd_data.ship_date;              -- �o�ɓ�
      tab_upd_arrival_date(gn_upd_cnt)              := ir_xd_data.arrival_date;           -- ������
      tab_upd_report_date(gn_upd_cnt)               := ir_xd_data.report_date;            -- �񍐓�
      tab_upd_judgement_date(gn_upd_cnt)            := ir_xd_data.judgement_date;         -- ���f��
      tab_upd_goods_classe(gn_upd_cnt)              := ir_xd_data.goods_classe;           -- ���i�敪
      tab_upd_mixed_code(gn_upd_cnt)                := ir_xd_data.mixed_code;             -- ���ڋ敪
      tab_upd_charged_amount(gn_upd_cnt)            := ir_xdc_data.shipping_expenses;     -- �����^��
      tab_upd_whs_code(gn_upd_cnt)                  := ir_xd_data.whs_code;               -- ��\�o�ɑq�ɃR�[�h
      tab_upd_code_division(gn_upd_cnt)             := ir_xd_data.code_division;          -- ��\�z����R�[�h�敪
      tab_upd_shipping_address_code(gn_upd_cnt)     := ir_xd_data.shipping_address_code;  -- ��\�z����R�[�h
      tab_upd_actual_distance(gn_upd_cnt)           := ir_xd_data.actual_distance;        -- �Œ����ۋ���
      tab_upd_consolid_qty(gn_upd_cnt)              := ir_xd_data.consolid_qty;           -- ���ڐ�
      tab_upd_order_type(gn_upd_cnt)                := ir_xd_data.order_type;             -- ��\�^�C�v
      tab_upd_weight_capacity_class(gn_upd_cnt)     := ir_xd_data.weight_capacity_class;  -- �d�ʗe�ϋ敪
      tab_upd_outside_contract(gn_upd_cnt)          := ir_xd_data.outside_contract;       -- �_��O�敪
      tab_upd_output_flag(gn_upd_cnt)               := NULL;     -- ���ً敪
      tab_upd_defined_flag(gn_upd_cnt)              := NULL;     -- �x���m��敪
      tab_upd_return_flag(gn_upd_cnt)               := NULL;     -- �x���m���
      tab_upd_transfer_location(gn_upd_cnt)         := ir_xd_data.transfer_location;      -- �U�֐�
      tab_upd_dispatch_type(gn_upd_cnt)             := ir_xd_data.dispatch_type;          -- �z�ԃ^�C�v
--
-- ##### 20080723 Ver.1.2 �����ύX#132�Ή� END   #####
--
      tab_upd_delivery_no(gn_upd_cnt)        := ir_xd_data.delivery_no;        -- �z��No
      tab_upd_contract_rate(gn_upd_cnt)      := ir_xdc_data.shipping_expenses; -- �_��^��
      tab_upd_balance(gn_upd_cnt)            := ln_balance;                    -- ���z
      tab_upd_total_amount(gn_upd_cnt)       := ln_total_amount;               -- ���v
      tab_upd_distance(gn_upd_cnt)           := ir_xd_data.distance;           -- �Œ�����
      tab_upd_delivery_classe(gn_upd_cnt)    := ir_xd_data.delivery_classe;    -- �z���敪
      tab_upd_qty1(gn_upd_cnt)               := ir_xd_data.qty1;               -- ���P
      tab_upd_qty2(gn_upd_cnt)               := ir_xd_data.qty2;               -- ���Q
      tab_upd_delivery_weight1(gn_upd_cnt)   := ir_xd_data.delivery_weight1;   -- �d�ʂP
      tab_upd_delivery_weight2(gn_upd_cnt)   := ir_xd_data.delivery_weight2;   -- �d�ʂQ
      tab_upd_many_rate(gn_upd_cnt)          := ir_xd_data.many_rate;          -- ������
      tab_upd_consolid_surcharge(gn_upd_cnt) := ln_consolid_surcharge;         -- ���ڊ������z
      tab_upd_congestion_charge(gn_upd_cnt)  := ir_xd_data.congestion_charge;  -- �ʍs��
      tab_upd_picking_charge(gn_upd_cnt)     := ln_picking_charge;             -- �s�b�L���O��
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
  END set_xd_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_xd_proc
   * Description      : �^���w�b�_�A�h�I���ꊇ�o�^����(D-8)
   ***********************************************************************************/
  PROCEDURE ins_xd_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_xd_proc'; -- �v���O������
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
-- ##### 20080723 Ver.1.2 �����ύX#132�Ή� START #####
    -- �f�[�^�����݂��Ȃ��ꍇ�́A�������X�L�b�v
    IF (tab_ins_deliverys_header_id.COUNT = 0) THEN
      RETURN;
    END IF;
-- ##### 20080723 Ver.1.2 �����ύX#132�Ή� END   #####
--
--
    FORALL ln_index IN tab_ins_deliverys_header_id.FIRST .. tab_ins_deliverys_header_id.LAST
      INSERT INTO xxwip_deliverys(
        deliverys_header_id,        -- �^���w�b�_�[�A�h�I��ID
        delivery_company_code,      -- �^���Ǝ�
        delivery_no,                -- �z��No
        invoice_no,                 -- �����No
-- ##### 20080916 Ver.1.3 T_S_570�Ή� START #####
        invoice_no2,                -- �����No2
-- ##### 20080916 Ver.1.3 T_S_570�Ή� END #####
        p_b_classe,                 -- �x�������敪
        payments_judgment_classe,   -- �x�����f�敪
        ship_date,                  -- �o�ɓ�
        arrival_date,               -- ������
        report_date,                -- �񍐓�
        judgement_date,             -- ���f��
        goods_classe,               -- ���i�敪
        mixed_code,                 -- ���ڋ敪
        charged_amount,             -- �����^��
        contract_rate,              -- �_��^��
        balance,                    -- ���z
        total_amount,               -- ���v
        many_rate,                  -- ������
        distance,                   -- �Œ�����
        delivery_classe,            -- �z���敪
        whs_code,                   -- ��\�o�ɑq�ɃR�[�h
        code_division,              -- ��\�z����R�[�h�敪
        shipping_address_code,      -- ��\�z����R�[�h
        qty1,                       -- ���P
        qty2,                       -- ���Q
        delivery_weight1,           -- �d�ʂP
        delivery_weight2,           -- �d�ʂQ
        consolid_surcharge,         -- ���ڊ������z
        actual_distance,            -- �Œ����ۋ���
        congestion_charge,          -- �ʍs��
        picking_charge,             -- �s�b�L���O��
        consolid_qty,               -- ���ڐ�
        order_type,                 -- ��\�^�C�v
        weight_capacity_class,      -- �d�ʗe�ϋ敪
        outside_contract,           -- �_��O�敪
        output_flag,                -- ���ً敪
        defined_flag,               -- �x���m��敪
        return_flag,                -- �x���m���
        form_update_flag,           -- ��ʍX�V�L���敪
        transfer_location,          -- �U�֐�
        outside_up_count,           -- �O���ƎҕύX��
        description,                -- �^���E�v
        dispatch_type,              -- �z�ԃ^�C�v(2008/07/11)
        created_by,                 -- �쐬��
        creation_date,              -- �쐬��
        last_updated_by,            -- �ŏI�X�V��
        last_update_date,           -- �ŏI�X�V��
        last_update_login,          -- �ŏI�X�V���O�C��
        request_id,                 -- �v��ID
        program_application_id,     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        program_id,                 -- �R���J�����g�E�v���O����ID
        program_update_date         -- �v���O�����X�V��
      ) VALUES (
        tab_ins_deliverys_header_id(ln_index),        -- �^���w�b�_�[�A�h�I��ID
        tab_ins_delivery_company_code(ln_index),      -- �^���Ǝ�
        tab_ins_delivery_no(ln_index),                -- �z��No
        tab_ins_invoice_no(ln_index),                 -- �����No
-- ##### 20080916 Ver.1.3 T_S_570�Ή� START #####
        tab_ins_invoice_no2(ln_index),                -- �����No2
-- ##### 20080916 Ver.1.3 T_S_570�Ή� END #####
        tab_ins_p_b_classe(ln_index),                 -- �x�������敪
        tab_ins_payments_judgment_clas(ln_index),     -- �x�����f�敪
        tab_ins_ship_date(ln_index),                  -- �o�ɓ�
        tab_ins_arrival_date(ln_index),               -- ������
        tab_ins_report_date(ln_index),                -- �񍐓�
        tab_ins_judgement_date(ln_index),             -- ���f��
        tab_ins_goods_classe(ln_index),               -- ���i�敪
        tab_ins_mixed_code(ln_index),                 -- ���ڋ敪
        tab_ins_charged_amount(ln_index),             -- �����^��
        tab_ins_contract_rate(ln_index),              -- �_��^��
        tab_ins_balance(ln_index),                    -- ���z
        tab_ins_total_amount(ln_index),               -- ���v
        tab_ins_many_rate(ln_index),                  -- ������
        tab_ins_distance(ln_index),                   -- �Œ�����
        tab_ins_delivery_classe(ln_index),            -- �z���敪
        tab_ins_whs_code(ln_index),                   -- ��\�o�ɑq�ɃR�[�h
        tab_ins_code_division(ln_index),              -- ��\�z����R�[�h�敪
        tab_ins_shipping_address_code(ln_index),      -- ��\�z����R�[�h
        tab_ins_qty1(ln_index),                       -- ���P
        tab_ins_qty2(ln_index),                       -- ���Q
        tab_ins_delivery_weight1(ln_index),           -- �d�ʂP
        tab_ins_delivery_weight2(ln_index),           -- �d�ʂQ
        tab_ins_consolid_surcharge(ln_index),         -- ���ڊ������z
        tab_ins_actual_distance(ln_index),            -- �Œ����ۋ���
        tab_ins_congestion_charge(ln_index),          -- �ʍs��
        tab_ins_picking_charge(ln_index),             -- �s�b�L���O��
        tab_ins_consolid_qty(ln_index),               -- ���ڐ�
        tab_ins_order_type(ln_index),                 -- ��\�^�C�v
        tab_ins_weight_capacity_class(ln_index),      -- �d�ʗe�ϋ敪
        tab_ins_outside_contract(ln_index),           -- �_��O�敪
        tab_ins_output_flag(ln_index),                -- ���ً敪
        tab_ins_defined_flag(ln_index),               -- �x���m��敪
        tab_ins_return_flag(ln_index),                -- �x���m���
        tab_ins_form_update_flag(ln_index),           -- ��ʍX�V�L���敪
        tab_ins_transfer_location(ln_index),          -- �U�֐�
        tab_ins_outside_up_count(ln_index),           -- �O���ƎҕύX��
        tab_ins_description(ln_index),                -- �^���E�v
        tab_ins_dispatch_type(ln_index),              -- �z�ԃ^�C�v(2008/07/11)
        gn_user_id,                                   -- �쐬��
        gd_sysdate,                                   -- �쐬��
        gn_user_id,                                   -- �ŏI�X�V��
        gd_sysdate,                                   -- �ŏI�X�V��
        gn_login_id,                                  -- �ŏI�X�V���O�C��
        gn_conc_request_id,                           -- �v��ID
        gn_prog_appl_id,                              -- �ݶ��ĥ��۸��ѥ���ع����ID
        gn_conc_program_id,                           -- �R���J�����g�E�v���O����ID
        gd_sysdate);                                  -- �v���O�����X�V��
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
  END ins_xd_proc;
--
  /**********************************************************************************
   * Procedure Name   : upd_xd_proc
   * Description      : �^���w�b�_�A�h�I���ꊇ�X�V����(D-9)
   ***********************************************************************************/
  PROCEDURE upd_xd_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_xd_proc'; -- �v���O������
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
-- ##### 20080723 Ver.1.2 �����ύX#132�Ή� START #####
    -- �f�[�^�����݂��Ȃ��ꍇ�́A�������X�L�b�v
    IF (tab_upd_delivery_no.COUNT = 0) THEN
      RETURN;
    END IF;
-- ##### 20080723 Ver.1.2 �����ύX#132�Ή� END   #####
--
--
    FORALL ln_index IN tab_upd_delivery_no.FIRST .. tab_upd_delivery_no.LAST
      UPDATE xxwip_deliverys
      SET    contract_rate          = tab_upd_contract_rate(ln_index),      -- �_��^��
             balance                = tab_upd_balance(ln_index),            -- ���z
             total_amount           = tab_upd_total_amount(ln_index),       -- ���v
             distance               = tab_upd_distance(ln_index),           -- �Œ�����
             delivery_classe        = tab_upd_delivery_classe(ln_index),    -- �z���敪
             qty1                   = tab_upd_qty1(ln_index),               -- ���P
             qty2                   = tab_upd_qty2(ln_index),               -- ���Q
             delivery_weight1       = tab_upd_delivery_weight1(ln_index),   -- �d�ʂP
             delivery_weight2       = tab_upd_delivery_weight2(ln_index),   -- �d�ʂQ
             many_rate              = tab_upd_many_rate(ln_index),          -- ������
             consolid_surcharge     = tab_upd_consolid_surcharge(ln_index), -- ���ڊ������z
             congestion_charge      = tab_upd_congestion_charge(ln_index),  -- �ʍs��
             picking_charge         = tab_upd_picking_charge(ln_index),     -- �s�b�L���O��
-- ##### 20080723 Ver.1.2 �����ύX#132�Ή� START #####
             delivery_company_code    = tab_upd_delivery_company_code(ln_index),    -- �^���Ǝ�
             invoice_no               = tab_upd_invoice_no(ln_index),               -- �����No
-- ##### 20080916 Ver.1.3 T_S_570�Ή� START #####
             invoice_no2              = tab_upd_invoice_no2(ln_index),              -- �����No2
-- ##### 20080916 Ver.1.3 T_S_570�Ή� END #####
             payments_judgment_classe = tab_upd_payments_judgment_clas(ln_index),   -- �x�����f�敪
             ship_date                = tab_upd_ship_date(ln_index),                -- �o�ɓ�
             arrival_date             = tab_upd_arrival_date(ln_index),             -- ������
             report_date              = tab_upd_report_date(ln_index),              -- �񍐓�
             judgement_date           = tab_upd_judgement_date(ln_index),           -- ���f��
             goods_classe             = tab_upd_goods_classe(ln_index),             -- ���i�敪
             mixed_code               = tab_upd_mixed_code(ln_index),               -- ���ڋ敪
             charged_amount           = tab_upd_charged_amount(ln_index),           -- �����^��
             whs_code                 = tab_upd_whs_code(ln_index),                 -- ��\�o�ɑq�ɃR�[�h
             code_division            = tab_upd_code_division(ln_index),            -- ��\�z����R�[�h�敪
             shipping_address_code    = tab_upd_shipping_address_code(ln_index),    -- ��\�z����R�[�h
             actual_distance          = tab_upd_actual_distance(ln_index),          -- �Œ����ۋ���
             consolid_qty             = tab_upd_consolid_qty(ln_index),             -- ���ڐ�
             order_type               = tab_upd_order_type(ln_index),               -- ��\�^�C�v
             weight_capacity_class    = tab_upd_weight_capacity_class(ln_index),    -- �d�ʗe�ϋ敪
             outside_contract         = tab_upd_outside_contract(ln_index),         -- �_��O�敪
             output_flag              = tab_upd_output_flag(ln_index),              -- ���ً敪
             defined_flag             = tab_upd_defined_flag(ln_index),             -- �x���m��敪
             return_flag              = tab_upd_return_flag(ln_index),              -- �x���m���
             transfer_location        = tab_upd_transfer_location(ln_index),        -- �U�֐�
             dispatch_type            = tab_upd_dispatch_type(ln_index),            -- �z�ԃ^�C�v
-- ##### 20080723 Ver.1.2 �����ύX#132�Ή� END   #####
             last_updated_by        = gn_user_id,               -- �ŏI�X�V��
             last_update_date       = gd_sysdate,               -- �ŏI�X�V��
             last_update_login      = gn_login_id,              -- �ŏI�X�V���O�C��
             request_id             = gn_conc_request_id,       -- �v��ID
             program_application_id = gn_prog_appl_id,          -- �ݶ��ĥ��۸��ѥ���ع����ID
             program_id             = gn_conc_program_id,       -- �R���J�����g�E�v���O����ID
             program_update_date    = gd_sysdate                -- �v���O�����X�V��
      WHERE  p_b_classe             = gv_paycharge_type_2
      AND    delivery_no            = tab_upd_delivery_no(ln_index);
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
  END upd_xd_proc;
--
  /**********************************************************************************
   * Procedure Name   : upd_calc_ctrl_proc
   * Description      : �^���v�Z�p�R���g���[���X�V����(D-10)
   ***********************************************************************************/
  PROCEDURE upd_calc_ctrl_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_calc_ctrl_proc'; -- �v���O������
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
    -- �O�񏈗����t���R���J�����g���s���ԂɍX�V
    UPDATE xxwip_deliverys_ctrl
    SET    last_process_date      = gd_sysdate,         -- �O�񏈗����t
           last_updated_by        = gn_user_id,         -- �ŏI�X�V��
           last_update_date       = gd_sysdate,         -- �ŏI�X�V��
           last_update_login      = gn_login_id,        -- �ŏI�X�V���O�C��
           request_id             = gn_conc_request_id, -- �v��ID
           program_application_id = gn_prog_appl_id,    -- �ݶ��ĥ��۸��ѥ���ع����ID
           program_id             = gn_conc_program_id, -- �R���J�����g�E�v���O����ID
           program_update_date    = gd_sysdate          -- �v���O�����X�V��
    WHERE  concurrent_no = gv_con_no_deli;
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
  END upd_calc_ctrl_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_xd_exchange_data
   * Description      : ���։^���w�b�_�A�h�I�����o(D-11)
   ***********************************************************************************/
  PROCEDURE get_xd_exchange_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xd_exchange_data'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    ld_first_day        DATE;   -- �^���p����
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
    IF (gv_closed_day = 'N') THEN
      -- (������)�����̏������擾
      ld_first_day := TRUNC(gd_sysdate, 'MM');
    ELSIF (gv_closed_day = 'Y') THEN
      -- (�����O)�挎�̌��������擾
      ld_first_day := TRUNC(ADD_MONTHS(gd_sysdate, -1), 'MM');
    END IF;
--
    -- ���։^���w�b�_�A�h�I���f�[�^���o
    BEGIN
      SELECT xd.delivery_company_code,       -- �^���Ǝ�
             xd.delivery_no,                 -- �z��No
             xd.judgement_date,              -- ���f��
             xd.goods_classe,                -- ���i�敪
             xd.mixed_code,                  -- ���ڋ敪
             xd.charged_amount,              -- �����^��
             xd.many_rate,                   -- ������
             xd.distance,                    -- �Œ�����
             xd.delivery_classe,             -- �z���敪
             xd.qty1,                        -- ���P
             xd.delivery_weight1,            -- �d�ʂP
             xd.consolid_qty,                -- ���ڐ�
             NVL(xdc.bill_picking_amount, 0) -- �����s�b�L���O�P��
      BULK COLLECT INTO gt_extraction_ex_xd
      FROM   xxwip_deliverys        xd,  -- �^���w�b�_�A�h�I��
             xxwip_delivery_company xdc  -- �^���p�^���Ǝ҃A�h�I���}�X�^
      WHERE  xd.p_b_classe            =  gv_paycharge_type_2
      AND    xd.dispatch_type IN (gv_dispatch_type_1,gv_dispatch_type_2)    -- 2008/07/11
      AND    xd.goods_classe IS NOT NULL
      AND    xd.goods_classe          =  xdc.goods_classe(+)
      AND    xd.delivery_company_code =  xdc.delivery_company_code(+)
      AND    xd.judgement_date        >= xdc.start_date_active(+)
      AND    xd.judgement_date        <= xdc.end_date_active(+)
      AND    xd.judgement_date        >= ld_first_day
      ORDER BY xd.delivery_no;
    END;
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
  END get_xd_exchange_data;
--
  /**********************************************************************************
   * Procedure Name   : get_xdc_exchange_data
   * Description      : ���։^���A�h�I���}�X�^���o(D-12)
   ***********************************************************************************/
  PROCEDURE get_xdc_exchange_data(
    ir_xd_ex_data IN  rec_extraction_ex_xd,--   ���։^���w�b�_�[�A�h�I�����R�[�h
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xdc_exchange_data'; -- �v���O������
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
    -- (���։^���A�h�I���}�X�^)�^����A���[�t���ڊ����擾
    xxwip_common3_pkg.get_delivery_charges(
      iv_p_b_classe              => gv_paycharge_type_2,                 -- �x�������敪������
      iv_goods_classe            => ir_xd_ex_data.goods_classe,          -- ���i�敪
      iv_delivery_company_code   => ir_xd_ex_data.delivery_company_code, -- �^���Ǝ�
      iv_shipping_address_classe => ir_xd_ex_data.delivery_classe,       -- �z���敪
      iv_delivery_distance       => ir_xd_ex_data.distance,              -- �Œ�����
      iv_delivery_weight         => ir_xd_ex_data.delivery_weight1,      -- �d��
      id_target_date             => ir_xd_ex_data.judgement_date,        -- ���f��
      or_delivery_charges        => gr_extraction_ex_xdc,                -- �^���A�h�I�����R�[�h
      ov_errbuf                  => lv_errbuf,                           -- �G���[�E���b�Z�[�W
      ov_retcode                 => lv_retcode,                          -- ���^�[���E�R�[�h
      ov_errmsg                  => lv_errmsg);                          -- հ�ް��װ�ү����
--
    -- �������ʃ`�F�b�N
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
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
  END get_xdc_exchange_data;
--
  /**********************************************************************************
   * Procedure Name   : set_xd_exchange_data
   * Description      : ���։^���w�b�_�A�h�I��PL/SQL�\�i�[(D-13)
   ***********************************************************************************/
  PROCEDURE set_xd_exchange_data(
    ir_xd_ex_data  IN  rec_extraction_ex_xd,   --   ���։^���w�b�_�[�A�h�I�����R�[�h
    ir_xdc_ex_data IN  xxwip_common3_pkg.delivery_charges_rec,
                                               --   ���։^���A�h�I���}�X�^���R�[�h
    ov_errbuf      OUT NOCOPY VARCHAR2,        --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,        --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_xd_exchange_data'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    ln_balance             NUMBER; -- ����z�
    ln_total_amount        NUMBER; -- ����v�
    ln_consolid_surcharge  NUMBER; -- ����ڊ������z�
    ln_picking_charge      NUMBER; -- ��s�b�L���O���
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
    -- ����z�����v�����ڊ������z���s�b�L���O����̎Z�o
    cal_money_proc(
      in_goods_classe        => ir_xd_ex_data.goods_classe,        -- ���i�敪
      in_mixed_code          => ir_xd_ex_data.mixed_code,          -- ���ڋ敪
-- ##### 20080723 Ver.1.2 �����ύX#132�Ή� START #####
      in_charged_amount      => ir_xd_ex_data.charged_amount,      -- �����^��
-- ##### 20080723 Ver.1.2 �����ύX#132�Ή� END   #####
      in_shipping_expenses   => ir_xdc_ex_data.shipping_expenses,  -- �^����
      in_many_rate           => ir_xd_ex_data.many_rate,           -- ������
      in_leaf_consolid_add   => ir_xdc_ex_data.leaf_consolid_add,  -- ���[�t���ڊ���
      in_consolid_qty        => ir_xd_ex_data.consolid_qty,        -- ���ڐ�
      in_qty1                => ir_xd_ex_data.qty1,                -- ��1
      in_bill_picking_amount => ir_xd_ex_data.bill_picking_amount, -- �����s�b�L���O�P��
      on_balance             => ln_balance,                     -- ���z
      on_total_amount        => ln_total_amount,                -- ���v
      on_consolid_surcharge  => ln_consolid_surcharge,          -- ���ڊ������z
      on_picking_charge      => ln_picking_charge,              -- �s�b�L���O��
      ov_errbuf              => lv_errbuf,                      -- �G���[�E���b�Z�[�W
      ov_retcode             => lv_retcode,                     -- ���^�[���E�R�[�h
      ov_errmsg              => lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- �������ʃ`�F�b�N
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
      -- ***************************************
      -- *** �X�V�pPL/SQL�\�i�[����          ***
      -- ***************************************
--
      -- �X�V�e�[�u�������C���N�������g
      gn_ex_cnt := gn_ex_cnt + 1;
--
      tab_ex_delivery_no(gn_ex_cnt)        := ir_xd_ex_data.delivery_no;        -- �z��No
      tab_ex_contract_rate(gn_ex_cnt)      := ir_xdc_ex_data.shipping_expenses; -- �_��^��
      tab_ex_balance(gn_ex_cnt)            := ln_balance;                       -- ���z
      tab_ex_total_amount(gn_ex_cnt)       := ln_total_amount;                  -- ���v
      tab_ex_consolid_surcharge(gn_ex_cnt) := ln_consolid_surcharge;            -- ���ڊ������z
      tab_ex_picking_charge(gn_ex_cnt)     := ln_picking_charge;                -- �s�b�L���O��
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
  END set_xd_exchange_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_xd_exchange_proc
   * Description      : ���։^���w�b�_�A�h�I���ꊇ�X�V����(D-14)
   ***********************************************************************************/
  PROCEDURE upd_xd_exchange_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_xd_exchange_proc'; -- �v���O������
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
    FORALL ln_index IN tab_ex_delivery_no.FIRST .. tab_ex_delivery_no.LAST
      UPDATE xxwip_deliverys
      SET    contract_rate          = tab_ex_contract_rate(ln_index),      -- �_��^��
             balance                = tab_ex_balance(ln_index),            -- ���z
             total_amount           = tab_ex_total_amount(ln_index),       -- ���v
             consolid_surcharge     = tab_ex_consolid_surcharge(ln_index), -- ���ڊ������z
             picking_charge         = tab_ex_picking_charge(ln_index),     -- �s�b�L���O��
             last_updated_by        = gn_user_id,               -- �ŏI�X�V��
             last_update_date       = gd_sysdate,               -- �ŏI�X�V��
             last_update_login      = gn_login_id,              -- �ŏI�X�V���O�C��
             request_id             = gn_conc_request_id,       -- �v��ID
             program_application_id = gn_prog_appl_id,          -- �ݶ��ĥ��۸��ѥ���ع����ID
             program_id             = gn_conc_program_id,       -- �R���J�����g�E�v���O����ID
             program_update_date    = gd_sysdate                -- �v���O�����X�V��
      WHERE  p_b_classe             = gv_paycharge_type_2
      AND    delivery_no            = tab_ex_delivery_no(ln_index);
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
  END upd_xd_exchange_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_exchange_type  IN         VARCHAR2,     -- ���֋敪
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_message    VARCHAR2(5000);  -- ���b�Z�[�W�o��
    lv_target_flg VARCHAR2(1);     -- �Ώۃf�[�^�L���t���O 0:�����A1:�L��
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_ins_cnt     := 0;
    gn_upd_cnt     := 0;
    gn_ex_cnt      := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- =========================================
    -- �p�����[�^�`�F�b�N����(D-1)
    -- =========================================
    chk_param_proc(
      iv_exchange_type,  -- ���֋敪
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- �֘A�f�[�^�擾(D-2)
    -- =========================================
    get_init(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- �^���p�������擾(D-3)
    -- =========================================
    chk_close_proc(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ���b�N�擾(D-4)
    -- =========================================
    get_lock_xd(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ���֋敪�ɂ�鏈���̕���(Y:���֏���, N:�ʏ폈��)
    IF (iv_exchange_type = gv_ktg_no) THEN
      --*********************************************
      --***               �ʏ폈��                ***
      --*********************************************
--
      -- =========================================
      -- �^���w�b�_�A�h�I�����o(D-5)
      -- =========================================
      get_xd_data(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ���o�f�[�^���P���ł����݂���ꍇ�AD-6�`D-9�̏��������{
      IF (gt_extraction_xd.EXISTS(1) = TRUE) THEN
        -- ���o�f�[�^�������Ȃ�܂�PL/SQL�\�i�[���������{
        <<set_xd_tab_loop>>
        FOR ln_index IN gt_extraction_xd.FIRST .. gt_extraction_xd.LAST LOOP
--
          -- =========================================
          -- �^���A�h�I���}�X�^���o(D-6)
          -- =========================================
          get_xdc_data(
            gt_extraction_xd(ln_index),   -- �^���w�b�_�[�A�h�I�����R�[�h
            lv_errbuf,                    -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,                   -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- =========================================
          -- �^���w�b�_�A�h�I��PL/SQL�\�i�[(D-7)
          -- =========================================
          set_xd_data(
            gt_extraction_xd(ln_index),   -- �^���w�b�_�[�A�h�I�����R�[�h
            gr_extraction_xdc,            -- �^���A�h�I���}�X�^���R�[�h
            lv_errbuf,                    -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,                   -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END LOOP set_xd_tab_loop;
--
        -- =========================================
        -- �^���w�b�_�A�h�I���ꊇ�o�^����(D-8)
        -- =========================================
        ins_xd_proc(
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =========================================
        -- �^���w�b�_�A�h�I���ꊇ�X�V����(D-9)
        -- =========================================
        upd_xd_proc(
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- =========================================
      -- �^���v�Z�p�R���g���[���X�V����(D-10)
      -- =========================================
      upd_calc_ctrl_proc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    ELSIF (iv_exchange_type = gv_ktg_yes) THEN
--
      -- =========================================
      -- ���։^���w�b�_�A�h�I�����o(D-11)
      -- =========================================
      get_xd_exchange_data(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ���o�f�[�^���P���ł����݂���ꍇ�AD-12�`D-14�̏��������{
      IF (gt_extraction_ex_xd.EXISTS(1) = TRUE) THEN
        -- ���o�f�[�^�������Ȃ�܂�PL/SQL�\�i�[���������{
        <<set_ex_xd_tab_loop>>
        FOR ln_index IN gt_extraction_ex_xd.FIRST .. gt_extraction_ex_xd.LAST LOOP
--
          -- =========================================
          -- ���։^���A�h�I���}�X�^���o(D-12)
          -- =========================================
          get_xdc_exchange_data(
            gt_extraction_ex_xd(ln_index),   -- ���։^���w�b�_�[�A�h�I�����R�[�h
            lv_errbuf,                       -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,                      -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- =========================================
          -- ���։^���w�b�_�A�h�I��PL/SQL�\�i�[(D-13)
          -- =========================================
          set_xd_exchange_data(
            gt_extraction_ex_xd(ln_index),   -- ���։^���w�b�_�[�A�h�I�����R�[�h
            gr_extraction_ex_xdc,            -- ���։^���A�h�I���}�X�^���R�[�h
            lv_errbuf,                       -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,                      -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END LOOP set_ex_xd_tab_loop;
--
        -- =========================================
        -- ���։^���w�b�_�A�h�I���ꊇ�X�V����(D-14)
        -- =========================================
        upd_xd_exchange_proc(
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
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
    errbuf            OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode           OUT NOCOPY VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_exchange_type  IN         VARCHAR2       --   ���֋敪
  )
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
--###########################  �Œ蕔 END   #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
--
    lv_message VARCHAR2(5000);  -- ���[�U�[�E���b�Z�[�W
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
      iv_exchange_type,  -- ���֋敪
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- =========================================
    -- ���b�Z�[�W�o��(D-15)
    -- =========================================
    -- 1.�^���w�b�_�A�h�I�������������b�Z�[�W
    lv_message := xxcmn_common_pkg.get_msg(gv_msg_kbn_wip, gv_msg_wip_00010);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- 2.���������o��
    lv_message := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_cmn_00009,
                                           gv_tkn_cnt,
                                           TO_CHAR(gn_ins_cnt + gn_upd_cnt + gn_ex_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
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
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
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
END xxwip730002c;
/
