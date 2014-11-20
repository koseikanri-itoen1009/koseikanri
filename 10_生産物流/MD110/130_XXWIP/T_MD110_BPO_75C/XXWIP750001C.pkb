CREATE OR REPLACE PACKAGE BODY xxwip750001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip750001c(body)
 * Description      : �U�։^�����X�V
 * MD.050           : �^���v�Z�i�U�ցj T_MD050_BPO_750
 * MD.070           : �U�։^�����X�V T_MD070_BPO_75C
 * Version          : 1.9
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_deliveryoff_proc   �z�ԉ����Ώۃf�[�^�폜����  -- �����ύX#225 �ǉ�
 *
 *  chk_param_proc         �p�����[�^�`�F�b�N����(C-1)
 *  get_init               �֘A�f�[�^�擾(C-2)
 *
 *  get_order_proc         �󒍃f�[�^���o����(C-3)
 *  set_trn                �U�։^�����A�h�I���f�[�^�ݒ�(C-4)
 *  ins_trn_proc           �U�։^�����A�h�I���ꊇ�o�^����(C-5)
 *  upd_trn_proc           �U�։^�����A�h�I���ꊇ�X�V����(C-6)
 *
 *  get_trn_proc           �U�։^�����A�h�I�����o����(C-7)
 *  set_trn_sum            �U�։^�����T�}���[�A�h�I���f�[�^�ݒ�(C-8)
 *  ins_trn_sum_proc       �U�։^�����T�}���[�A�h�I���ꊇ�o�^����(C-9)
 *  upd_trn_sum_proc       �U�։^�����T�}���[�A�h�I���ꊇ�X�V����(C-10)
 *
 *  get_trn_sum_proc       �U�։^�����T�}���[�A�h�I�����o����(C-11)
 *  set_trn_inf            �U�֏��A�h�I���f�[�^�ݒ�(C-12)
 *  ins_trn_inf_proc       �U�֏��A�h�I���ꊇ�o�^����(C-13)
 *  upd_trn_inf_proc       �U�֏��A�h�I���ꊇ�X�V����(C-14)
 *
 *  upd_deliv_ctrl_proc    �^���v�Z�p�R���g���[���X�V����(C-15)
 *
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/29    1.0  Oracle �a�c ��P  ����쐬
 *  2008/05/01    1.1  Oracle �쑺 ���K  �����ύX�v��#59�A#75�Ή�
 *  2008/06/09    1.2  Oracle �쑺 ���K  TE080�w�E�����Ή�
 *  2008/06/27    1.3  Oracle �ۉ� ����  �����ύX�v��144
 *  2008/07/29    1.4  Oracle �R�� ��_  ST��QNo484�Ή�
 *  2008/09/03    1.5  Oracle �쑺 ���K  �����ύX�v��201_203
 *  2008/09/22    1.6  Oracle �R�� ��_  T_S_552,T_TE080_BPO_750 �w�E4�Ή�
 *  2008/10/16    1.7  Oracle �쑺 ���K  �����ύX#225
 *  2008/10/17    1.8  Oracle �쑺 ���K  T_S_465�Ή�
 *  2008/11/06    1.9  Oracle ���c ����  ����#537�Ή�
 *  2008/11/06    1.9  Oracle ���c ����  ����#563�Ή�
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
  func_inv_expt              EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ���b�N�擾��O
--
  PRAGMA EXCEPTION_INIT(func_inv_expt, -20001);    -- �t�@���N�V�����G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name                CONSTANT VARCHAR2(100) := 'xxwip750001c'; -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  gv_cmn_msg_kbn             CONSTANT VARCHAR2(5) := 'XXCMN';
  gv_wip_msg_kbn             CONSTANT VARCHAR2(5) := 'XXWIP';
--
  -- ���b�Z�[�W�ԍ�(XXCMN)
  gv_cmn_msg_75c_008         CONSTANT VARCHAR2(15) := 'APP-XXCMN-00008'; -- ��������
  gv_cmn_msg_75c_009         CONSTANT VARCHAR2(15) := 'APP-XXCMN-00009'; -- ��������
  gv_cmn_msg_75c_001         CONSTANT VARCHAR2(15) := 'APP-XXCMN-10001'; -- �Ώۃf�[�^�Ȃ�
  gv_cmn_msg_75c_010         CONSTANT VARCHAR2(15) := 'APP-XXCMN-10010'; -- �p�����[�^�G���[
--
  -- ���b�Z�[�W�ԍ�(XXWIP)
  -- �U�։^�����A�h�I�������������b�Z�[�W
  gv_wip_msg_75c_005         CONSTANT VARCHAR2(15) := 'APP-XXWIP-00005';
  -- �U�֏��A�h�I�������������b�Z�[�W
  gv_wip_msg_75c_006         CONSTANT VARCHAR2(15) := 'APP-XXWIP-00006';
  -- �U�։^�����T�}���[�A�h�I�������������b�Z�[�W
  gv_wip_msg_75c_008         CONSTANT VARCHAR2(15) := 'APP-XXWIP-00008';
  gv_wip_msg_75c_004         CONSTANT VARCHAR2(15) := 'APP-XXWIP-10004'; -- ���b�N�ڍ׃��b�Z�[�W
--
  gv_wip_msg_75c_009         CONSTANT VARCHAR2(15) := 'APP-XXWIP-30012'; -- 2008/09/22 Add
--
  -- �g�[�N��
  gv_tkn_parameter           CONSTANT VARCHAR2(10) := 'PARAMETER';
  gv_tkn_value               CONSTANT VARCHAR2(10) := 'VALUE';
  gv_tkn_table               CONSTANT VARCHAR2(10) := 'TABLE';
  gv_tkn_key                 CONSTANT VARCHAR2(10) := 'KEY';
  gv_tkn_cnt                 CONSTANT VARCHAR2(10) := 'CNT';
--2008/09/22 Add
  gv_tkn_tbl_name            CONSTANT VARCHAR2(10) := 'TBL_NAME';
  gv_tkn_req_no              CONSTANT VARCHAR2(10) := 'REQ_NO';
--
  -- �g�[�N���l
-- ##### 20081017 Ver.1.8 T_S_465�Ή� start #####
  gv_iv_prod_div_name        CONSTANT VARCHAR2(30) := '���i�敪';
-- ##### 20081017 Ver.1.8 T_S_465�Ή� end   #####
  gv_exchange_type_name      CONSTANT VARCHAR2(30) := '���֋敪';
  gv_party_view_name         CONSTANT VARCHAR2(30) := '�p�[�e�B���VIEW2';
  gv_deli_ctrl_name          CONSTANT VARCHAR2(30) := '�^���v�Z�p�R���g���[��';
  gv_trans_fare_inf_name     CONSTANT VARCHAR2(30) := '�U�։^�����A�h�I��';
  gv_trans_fare_sum_name     CONSTANT VARCHAR2(30) := '�U�։^�����T�}���[�A�h�I��';
  gv_trans_inf_name          CONSTANT VARCHAR2(30) := '�U�֏��A�h�I��';
--
  gv_jurisdicyional_hub_name CONSTANT VARCHAR2(30) := '�Ǌ����_';
--
  -- YESNO�敪
  gv_ktg_yes                 CONSTANT VARCHAR2(1) := 'Y';
  gv_ktg_no                  CONSTANT VARCHAR2(1) := 'N';
--
  -- �R���J�����gNo(�^���v�Z�p�R���g���[��)
-- ##### 20081017 Ver.1.8 T_S_465�Ή� start #####
/***** �g�p���Ȃ��Ȃ������߁A�R�����g�A�E�g
  gv_con_no_deli             CONSTANT VARCHAR2(1) := '3';   -- 3:�U�։^�����X�V
*****/
-- ##### 20081017 Ver.1.8 T_S_465�Ή� end   #####
  -- ���i�敪
  gv_prod_class_lef          CONSTANT VARCHAR2(1) := '1';   -- 1:���[�t
  gv_prod_class_drk          CONSTANT VARCHAR2(1) := '2';   -- 2:�h�����N
  -- �����敪
  gv_small_sum_yes           CONSTANT VARCHAR2(1) := '1';   -- 1:����
  gv_small_sum_no            CONSTANT VARCHAR2(1) := '0';   -- 0:�ԗ�
  -- �y�i���e�B�敪
  gv_penalty_yes             CONSTANT VARCHAR2(1) := '1';   -- 1:�L��
  gv_penalty_no              CONSTANT VARCHAR2(1) := '0';   -- 0:����
  -- ���o�Ɋ��Z�֐� �ϊ����@
  gv_rcv_to_inout            CONSTANT VARCHAR2(1)  := '1';  -- ���o�Ɋ��Z�P�ʂ����1�P�ʂ֕ϊ�
  gv_rcv_to_first            CONSTANT VARCHAR2(1)  := '2';  -- ��1�P�ʂ�����o�Ɋ��Z�P�ʂ֕ϊ�
--
-- ##### 20081017 Ver.1.8 T_S_465�Ή� start #####
  -- �R���J�����gNO
  gv_con_lef                 CONSTANT VARCHAR2(1) := '3';   -- 1:���[�t
  gv_con_drk                 CONSTANT VARCHAR2(1) := '4';   -- 2:�h�����N
-- ##### 20081017 Ver.1.8 T_S_465�Ή� end   #####
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �U�։^�����A�h�I���Ɋi�[���郌�R�[�h
  TYPE order_inf_rec IS RECORD(
    order_header_id      xxwsh_order_headers_all.order_header_id%TYPE,      -- 1.��ͯ�ޱ�޵�ID
    order_type_id        xxwsh_order_headers_all.order_type_id%TYPE,        -- 2.�󒍃^�C�vID
    request_no           xxwsh_order_headers_all.request_no%TYPE,           -- 3.�˗�No
    arrival_date         xxwsh_order_headers_all.arrival_date%TYPE,         -- 4.���ד�
    head_sales_branch    xxwsh_order_headers_all.head_sales_branch%TYPE,    -- 5.�Ǌ����_
    deliver_from         xxwsh_order_headers_all.deliver_from%TYPE,         -- 6.�o�׌��ۊǏꏊ
-- ##### 20080609 MOD TE080�w�E�����Ή� start #####
/***
    shipping_method_code xxwsh_order_headers_all.shipping_method_code%TYPE, -- 8.�z���敪
    deliver_to           xxwsh_order_headers_all.deliver_to%TYPE,           -- 7.�o�א�
***/
    deliver_to           xxwsh_order_headers_all.result_deliver_to%TYPE,           -- 7.�o�א�_����
    shipping_method_code xxwsh_order_headers_all.result_shipping_method_code%TYPE, -- 8.�z���敪_����
-- ##### 20080609 MOD TE080�w�E�����Ή� end   #####
    small_quantity       xxwsh_order_headers_all.small_quantity%TYPE,       -- 9.������
    prod_class           xxwsh_order_headers_all.prod_class%TYPE,           -- 10.���i�敪
    arrival_yyyymm       VARCHAR2(6),                                       -- 11.�Ώ۔N��
    shipping_item_code   xxwsh_order_lines_all.shipping_item_code%TYPE,     -- 12.�o�וi��
    shipped_quantity     xxwsh_order_lines_all.shipped_quantity%TYPE,       -- 13.�o�׎��ѐ���
    product_class        xxcmn_item_mst_v.product_class%TYPE,               -- 14.���i����
    conv_unit            xxcmn_item_mst_v.conv_unit%TYPE,                   -- 15.���o�Ɋ��Z�P��
    num_of_cases         xxcmn_item_mst_v.num_of_cases%TYPE,                -- 16.�P�[�X����
-- ##### 20080903 Ver.1.5 �����ύX�v��201_203 start #####
--    base_major_division  xxcmn_parties2_v.base_major_division%TYPE,         -- 17.���_�啪��
    base_major_division  xxcmn_cust_accounts2_v.base_major_division%TYPE,   -- 17.���_�啪��
-- ##### 20080903 Ver.1.5 �����ύX�v��201_203 end   #####
    small_amount_class   xxwsh_ship_method_v.small_amount_class%TYPE,       -- 18.�����敪
    penalty_class        xxwsh_ship_method_v.penalty_class%TYPE,            -- 19.�y�i���e�B�敪
-- ##### 20080903 Ver.1.5 �����ύX�v��201_203 start #####
--    setting_amount       xxwip_leaf_trans_deli_chrgs.setting_amount%TYPE    -- 20.�P��(�֐ݒ���z)
-- ##### 20081016 Ver.1.7 �����ύX#225 start #####
--    setting_amount       xxwip_transfer_fare_inf.price%TYPE                 -- 20.�P��(�֐ݒ���z)
    setting_amount       xxwip_transfer_fare_inf.price%TYPE,                 -- 20.�P��(�֐ݒ���z)
    delivery_no          xxwsh_order_headers_all.delivery_no%TYPE            -- �z��No
-- ##### 20081016 Ver.1.7 �����ύX#225 end   #####
-- ##### 20080903 Ver.1.5 �����ύX�v��201_203 end   #####
  );
--
  -- �Ώۃf�[�^�����i�[����e�[�u���^�̒�`
  TYPE order_inf_tbl IS TABLE OF order_inf_rec INDEX BY PLS_INTEGER;
  gt_order_inf_tbl   order_inf_tbl;
--
  -- *****************************
  -- * �U�։^�����A�h�I�� �֘A
  -- *****************************
  -- �o�^PL/SQL�\�^
  -- �U�։^�����ID
  TYPE i_trn_fare_inf_id_type        IS TABLE OF xxwip_transfer_fare_inf.transfer_fare_inf_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- �Ώ۔N��
  TYPE i_trn_target_date_type        IS TABLE OF xxwip_transfer_fare_inf.target_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- �˗�No
  TYPE i_trn_request_no_type         IS TABLE OF xxwip_transfer_fare_inf.request_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���i�敪
  TYPE i_trn_goods_classe_type       IS TABLE OF xxwip_transfer_fare_inf.goods_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- �z����
  TYPE i_trn_delivery_date_type      IS TABLE OF xxwip_transfer_fare_inf.delivery_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- �Ǌ����_
  TYPE i_trn_jurisdicyional_hub_type IS TABLE OF xxwip_transfer_fare_inf.jurisdicyional_hub%TYPE
  INDEX BY BINARY_INTEGER;
  -- �o�Ɍ�
  TYPE i_trn_delivery_whs_type       IS TABLE OF xxwip_transfer_fare_inf.delivery_whs%TYPE
  INDEX BY BINARY_INTEGER;
  -- �z����
  TYPE i_trn_ship_to_type            IS TABLE OF xxwip_transfer_fare_inf.ship_to%TYPE
  INDEX BY BINARY_INTEGER;
  -- �i�ڃR�[�h
  TYPE i_trn_item_code_type          IS TABLE OF xxwip_transfer_fare_inf.item_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- �P��
  TYPE i_trn_price_type              IS TABLE OF xxwip_transfer_fare_inf.price%TYPE
  INDEX BY BINARY_INTEGER;
  -- �v�Z����
  TYPE i_trn_calc_qry_type           IS TABLE OF xxwip_transfer_fare_inf.calc_qry%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���ې���
  TYPE i_trn_actual_qty_type         IS TABLE OF xxwip_transfer_fare_inf.actual_qty%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���z
  TYPE i_trn_amount_type             IS TABLE OF xxwip_transfer_fare_inf.amount%TYPE
  INDEX BY BINARY_INTEGER;
--
  i_trn_fare_inf_id_tab              i_trn_fare_inf_id_type;          -- �U�։^�����ID
  i_trn_target_date_tab              i_trn_target_date_type;          -- �Ώ۔N��
  i_trn_request_no_tab               i_trn_request_no_type;           -- �˗�No
  i_trn_goods_classe_tab             i_trn_goods_classe_type;         -- ���i�敪
  i_trn_delivery_date_tab            i_trn_delivery_date_type;        -- �z����
  i_trn_jurisdicyional_hub_tab       i_trn_jurisdicyional_hub_type;   -- �Ǌ����_
  i_trn_delivery_whs_tab             i_trn_delivery_whs_type;         -- �o�Ɍ�
  i_trn_ship_to_tab                  i_trn_ship_to_type;              -- �z����
  i_trn_item_code_tab                i_trn_item_code_type;            -- �i�ڃR�[�h
  i_trn_price_tab                    i_trn_price_type;                -- �P��
  i_trn_calc_qry_tab                 i_trn_calc_qry_type;             -- �v�Z����
  i_trn_actual_qty_tab               i_trn_actual_qty_type;           -- ���ې���
  i_trn_amount_tab                   i_trn_amount_type;               -- ���z
--
  -- �X�VPL/SQL�\�^
  -- �U�։^�����ID
  TYPE u_trn_fare_inf_id_type        IS TABLE OF xxwip_transfer_fare_inf.transfer_fare_inf_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- �Ώ۔N��
  TYPE u_trn_target_date_type        IS TABLE OF xxwip_transfer_fare_inf.target_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- �˗�No
  TYPE u_trn_request_no_type         IS TABLE OF xxwip_transfer_fare_inf.request_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���i�敪
  TYPE u_trn_goods_classe_type       IS TABLE OF xxwip_transfer_fare_inf.goods_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- �z����
  TYPE u_trn_delivery_date_type      IS TABLE OF xxwip_transfer_fare_inf.delivery_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- �Ǌ����_
  TYPE u_trn_jurisdicyional_hub_type IS TABLE OF xxwip_transfer_fare_inf.jurisdicyional_hub%TYPE
  INDEX BY BINARY_INTEGER;
  -- �o�Ɍ�
  TYPE u_trn_delivery_whs_type       IS TABLE OF xxwip_transfer_fare_inf.delivery_whs%TYPE
  INDEX BY BINARY_INTEGER;
  -- �z����
  TYPE u_trn_ship_to_type            IS TABLE OF xxwip_transfer_fare_inf.ship_to%TYPE
  INDEX BY BINARY_INTEGER;
  -- �i�ڃR�[�h
  TYPE u_trn_item_code_type          IS TABLE OF xxwip_transfer_fare_inf.item_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- �P��
  TYPE u_trn_price_type              IS TABLE OF xxwip_transfer_fare_inf.price%TYPE
  INDEX BY BINARY_INTEGER;
  -- �v�Z����
  TYPE u_trn_calc_qry_type           IS TABLE OF xxwip_transfer_fare_inf.calc_qry%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���ې���
  TYPE u_trn_actual_qty_type         IS TABLE OF xxwip_transfer_fare_inf.actual_qty%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���z
  TYPE u_trn_amount_type             IS TABLE OF xxwip_transfer_fare_inf.amount%TYPE
  INDEX BY BINARY_INTEGER;
--
  u_trn_fare_inf_id_tab              u_trn_fare_inf_id_type;          -- �U�։^�����ID
  u_trn_target_date_tab              u_trn_target_date_type;          -- �Ώ۔N��
  u_trn_request_no_tab               u_trn_request_no_type;           -- �˗�No
  u_trn_goods_classe_tab             u_trn_goods_classe_type;         -- ���i�敪
  u_trn_delivery_date_tab            u_trn_delivery_date_type;        -- �z����
  u_trn_jurisdicyional_hub_tab       u_trn_jurisdicyional_hub_type;   -- �Ǌ����_
  u_trn_delivery_whs_tab             u_trn_delivery_whs_type;         -- �o�Ɍ�
  u_trn_ship_to_tab                  u_trn_ship_to_type;              -- �z����
  u_trn_item_code_tab                u_trn_item_code_type;            -- �i�ڃR�[�h
  u_trn_price_tab                    u_trn_price_type;                -- �P��
  u_trn_calc_qry_tab                 u_trn_calc_qry_type;             -- �v�Z����
  u_trn_actual_qty_tab               u_trn_actual_qty_type;           -- ���ې���
  u_trn_amount_tab                   u_trn_amount_type;               -- ���z
--
  -- �U�։^�����T�}���[�A�h�I���Ɋi�[���郌�R�[�h
  TYPE order_summary_rec IS RECORD(
    target_date        xxwip_transfer_fare_inf.target_date%TYPE,          -- 1.�Ώ۔N��
    request_no         xxwip_transfer_fare_inf.request_no%TYPE,           -- 2.�˗�No
    goods_classe       xxwip_transfer_fare_inf.goods_classe%TYPE,         -- 3.���i�敪
    jurisdicyional_hub xxwip_transfer_fare_inf.jurisdicyional_hub%TYPE,   -- 4.�Ǌ����_
    summary_qry        xxwip_transfer_fare_inf.actual_qty%TYPE,           -- 5.�U�֐���
    leaf_chg_amount    xxwip_transfer_fare_sum.leaf_amount%TYPE,          -- 6.���[�t�U�֋��z
    drink_chg_amount   xxwip_transfer_fare_sum.drink_amount%TYPE          -- 7.�h�����N�U�֋��z
  );
--
  -- �Ώۃf�[�^�����i�[����e�[�u���^�̒�`
  TYPE order_summary_tbl IS TABLE OF order_summary_rec INDEX BY PLS_INTEGER;
  gt_order_summary_tbl   order_summary_tbl;
--
  -- ***********************************
  -- * �U�։^�����T�}���[�A�h�I�� �֘A
  -- ***********************************
  -- �o�^PL/SQL�\�^
  -- �U�։^�����T�}���[ID
  TYPE i_trn_fare_sum_id_type         IS TABLE OF xxwip_transfer_fare_sum.transfer_fare_sum_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- �Ώ۔N��
  TYPE i_trn_fare_sum_target_dt_type  IS TABLE OF xxwip_transfer_fare_sum.target_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- �˗�No
  TYPE i_trn_fare_sum_request_no_type IS TABLE OF xxwip_transfer_fare_sum.request_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���i�敪
  TYPE i_trn_fare_sum_goods_cls_type  IS TABLE OF xxwip_transfer_fare_sum.goods_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- �Ǌ����_
  TYPE i_trn_fare_sum_juris_hub_type  IS TABLE OF xxwip_transfer_fare_sum.jurisdicyional_hub%TYPE
  INDEX BY BINARY_INTEGER;
  -- �U�֐���
  TYPE i_trn_fare_sum_actual_qty_type IS TABLE OF xxwip_transfer_fare_sum.actual_qty%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���[�t�U�֋��z
  TYPE i_trn_fare_sum_leaf_amnt_type  IS TABLE OF xxwip_transfer_fare_sum.leaf_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- �h�����N�U�֋��z
  TYPE i_trn_fare_sum_drink_amnt_type IS TABLE OF xxwip_transfer_fare_sum.drink_amount%TYPE
  INDEX BY BINARY_INTEGER;
--
  i_trn_fare_sum_id_tab                 i_trn_fare_sum_id_type;         -- �U�։^�����T�}���[ID
  i_trn_fare_sum_target_date_tab        i_trn_fare_sum_target_dt_type;  -- �Ώ۔N��
  i_trn_fare_sum_request_no_tab         i_trn_fare_sum_request_no_type; -- �˗�No
  i_trn_fare_sum_goods_clas_tab         i_trn_fare_sum_goods_cls_type;  -- ���i�敪
  i_trn_fare_sum_juris_hub_tab          i_trn_fare_sum_juris_hub_type;  -- �Ǌ����_
  i_trn_fare_sum_actual_qty_tab         i_trn_fare_sum_actual_qty_type; -- �U�֐���
  i_trn_fare_sum_leaf_amount_tab        i_trn_fare_sum_leaf_amnt_type;  -- ���[�t�U�֋��z
  i_trn_fare_sum_drk_amount_tab         i_trn_fare_sum_drink_amnt_type; -- �h�����N�U�֋��z
--
  -- �X�VPL/SQL�\�^
  -- �U�։^�����T�}���[ID
  TYPE u_trn_fare_sum_id_type         IS TABLE OF xxwip_transfer_fare_sum.transfer_fare_sum_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- �Ώ۔N��
  TYPE u_trn_fare_sum_target_dt_type  IS TABLE OF xxwip_transfer_fare_sum.target_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- �˗�No
  TYPE u_trn_fare_sum_request_no_type IS TABLE OF xxwip_transfer_fare_sum.request_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���i�敪
  TYPE u_trn_fare_sum_goods_cls_type  IS TABLE OF xxwip_transfer_fare_sum.goods_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- �Ǌ����_
  TYPE u_trn_fare_sum_juris_hub_type  IS TABLE OF xxwip_transfer_fare_sum.jurisdicyional_hub%TYPE
  INDEX BY BINARY_INTEGER;
  -- �U�֐���
  TYPE u_trn_fare_sum_actual_qty_type IS TABLE OF xxwip_transfer_fare_sum.actual_qty%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���[�t�U�֋��z
  TYPE u_trn_fare_sum_leaf_amnt_type  IS TABLE OF xxwip_transfer_fare_sum.leaf_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- �h�����N�U�֋��z
  TYPE u_trn_fare_sum_drink_amnt_type IS TABLE OF xxwip_transfer_fare_sum.drink_amount%TYPE
  INDEX BY BINARY_INTEGER;
--
  u_trn_fare_sum_id_tab                 u_trn_fare_sum_id_type;         -- �U�։^�����T�}���[ID
  u_trn_fare_sum_target_date_tab        u_trn_fare_sum_target_dt_type;  -- �Ώ۔N��
  u_trn_fare_sum_request_no_tab         u_trn_fare_sum_request_no_type; -- �˗�No
  u_trn_fare_sum_goods_clas_tab         u_trn_fare_sum_goods_cls_type;  -- ���i�敪
  u_trn_fare_sum_juris_hub_tab          u_trn_fare_sum_juris_hub_type;  -- �Ǌ����_
  u_trn_fare_sum_actual_qty_tab         u_trn_fare_sum_actual_qty_type; -- �U�֐���
  u_trn_fare_sum_leaf_amount_tab        u_trn_fare_sum_leaf_amnt_type;  -- ���[�t�U�֋��z
  u_trn_fare_sum_drk_amount_tab         u_trn_fare_sum_drink_amnt_type; -- �h�����N�U�֋��z
--
  -- �U�֏��A�h�I���Ɋi�[���郌�R�[�h
  TYPE trans_inf_rec IS RECORD(
    target_date        xxwip_transfer_fare_sum.target_date%TYPE,          -- 1.�Ώ۔N��
    goods_classe       xxwip_transfer_fare_sum.goods_classe%TYPE,         -- 2.���i�敪
    jurisdicyional_hub xxwip_transfer_fare_sum.jurisdicyional_hub%TYPE,   -- 3.�Ǌ����_
    summary_qry        xxwip_transfer_fare_sum.actual_qty%TYPE,           -- 4.�U�֐���
    trans_amount       xxwip_transfer_inf.transfer_amount%TYPE,           -- 5.�U�֋��z
    business_block     xxwip_transfer_inf.business_block%TYPE,            -- 6.�c�ƃu���b�N
    area_name          xxwip_transfer_inf.area_name%TYPE                  -- 7.�n�於
  );
--
  -- �Ώۃf�[�^�����i�[����e�[�u���^�̒�`
  TYPE trans_inf_tbl IS TABLE OF trans_inf_rec INDEX BY PLS_INTEGER;
  gt_trans_inf_tbl   trans_inf_tbl;
--
  -- ***********************
  -- * �U�֏��A�h�I�� �֘A
  -- ***********************
  -- �o�^PL/SQL�\�^
  -- �U�֏��ID
  TYPE i_trn_inf_id_type                  IS TABLE OF xxwip_transfer_inf.transfer_inf_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- �Ώ۔N��
  TYPE i_trn_inf_target_date_type         IS TABLE OF xxwip_transfer_inf.target_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- �c�ƃu���b�N
  TYPE i_trn_inf_business_block_type      IS TABLE OF xxwip_transfer_inf.business_block%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���i�敪
  TYPE i_trn_inf_goods_classe_type        IS TABLE OF xxwip_transfer_inf.goods_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- �Ǌ����_
  TYPE i_trn_inf_juris_hub_type           IS TABLE OF xxwip_transfer_inf.jurisdicyional_hub%TYPE
  INDEX BY BINARY_INTEGER;
  -- �n�於
  TYPE i_trn_inf_area_name_type           IS TABLE OF xxwip_transfer_inf.area_name%TYPE
  INDEX BY BINARY_INTEGER;
  -- �U�֐���
  TYPE i_trn_inf_transfe_qty_type         IS TABLE OF xxwip_transfer_inf.transfe_qty%TYPE
  INDEX BY BINARY_INTEGER;
  -- �U�֋��z
  TYPE i_trn_inf_transfer_amount_type     IS TABLE OF xxwip_transfer_inf.transfer_amount%TYPE
  INDEX BY BINARY_INTEGER;
--
  i_trn_inf_id_tab                    i_trn_inf_id_type;                  -- �U�֏��ID
  i_trn_inf_target_date_tab           i_trn_inf_target_date_type;         -- �Ώ۔N��
  i_trn_inf_business_block_tab        i_trn_inf_business_block_type;      -- �c�ƃu���b�N
  i_trn_inf_goods_classe_tab          i_trn_inf_goods_classe_type;        -- ���i�敪
  i_trn_inf_juris_hub_tab             i_trn_inf_juris_hub_type;           -- �Ǌ����_
  i_trn_inf_area_name_tab             i_trn_inf_area_name_type;           -- �n�於
  i_trn_inf_transfe_qty_tab           i_trn_inf_transfe_qty_type;         -- �U�֐���
  i_trn_inf_transfer_amount_tab       i_trn_inf_transfer_amount_type;     -- �U�֋��z
--
  -- �X�VPL/SQL�\�^
  -- �U�֏��ID
  TYPE u_trn_inf_id_type                  IS TABLE OF xxwip_transfer_inf.transfer_inf_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- �Ώ۔N��
  TYPE u_trn_inf_target_date_type         IS TABLE OF xxwip_transfer_inf.target_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- �c�ƃu���b�N
  TYPE u_trn_inf_business_block_type      IS TABLE OF xxwip_transfer_inf.business_block%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���i�敪
  TYPE u_trn_inf_goods_classe_type        IS TABLE OF xxwip_transfer_inf.goods_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- �Ǌ����_
  TYPE u_trn_inf_juris_hub_type           IS TABLE OF xxwip_transfer_inf.jurisdicyional_hub%TYPE
  INDEX BY BINARY_INTEGER;
  -- �n�於
  TYPE u_trn_inf_area_name_type           IS TABLE OF xxwip_transfer_inf.area_name%TYPE
  INDEX BY BINARY_INTEGER;
  -- �U�֐���
  TYPE u_trn_inf_transfe_qty_type         IS TABLE OF xxwip_transfer_inf.transfe_qty%TYPE
  INDEX BY BINARY_INTEGER;
  -- �U�֋��z
  TYPE u_trn_inf_transfer_amount_type     IS TABLE OF xxwip_transfer_inf.transfer_amount%TYPE
  INDEX BY BINARY_INTEGER;
--
  u_trn_inf_id_tab                    u_trn_inf_id_type;                  -- �U�֏��ID
  u_trn_inf_target_date_tab           u_trn_inf_target_date_type;         -- �Ώ۔N��
  u_trn_inf_business_block_tab        u_trn_inf_business_block_type;      -- �c�ƃu���b�N
  u_trn_inf_goods_classe_tab          u_trn_inf_goods_classe_type;        -- ���i�敪
  u_trn_inf_juris_hub_tab             u_trn_inf_juris_hub_type;           -- �Ǌ����_
  u_trn_inf_area_name_tab             u_trn_inf_area_name_type;           -- �n�於
  u_trn_inf_transfe_qty_tab           u_trn_inf_transfe_qty_type;         -- �U�֐���
  u_trn_inf_transfer_amount_tab       u_trn_inf_transfer_amount_type;     -- �U�֋��z
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
  -- �󒍌���
  gn_ins_order_inf_cnt   NUMBER DEFAULT 0; -- �U�։^�����A�h�I�� �o�^�pPL/SQL�\ ����
  gn_upd_order_inf_cnt   NUMBER DEFAULT 0; -- �U�։^�����A�h�I�� �X�V�pPL/SQL�\ ����
--
  gn_ins_order_sum_cnt   NUMBER DEFAULT 0; -- �U�։^�����T�}���[�A�h�I�� �o�^�pPL/SQL�\ ����
  gn_upd_order_sum_cnt   NUMBER DEFAULT 0; -- �U�։^�����T�}���[�A�h�I�� �X�V�pPL/SQL�\ ����
--
  gn_ins_trans_inf_cnt   NUMBER DEFAULT 0; -- �U�֏��A�h�I�� �o�^�pPL/SQL�\ ����
  gn_upd_trans_inf_cnt   NUMBER DEFAULT 0; -- �U�֏��A�h�I�� �X�V�pPL/SQL�\ ����
--
  gn_order_inf_cnt       NUMBER DEFAULT 0; -- �U�։^�����A�h�I��         �o�^/�X�V��������
  gn_order_sum_cnt       NUMBER DEFAULT 0; -- �U�։^�����T�}���[�A�h�I�� �o�^/�X�V��������
  gn_trans_inf_cnt       NUMBER DEFAULT 0; -- �U�֏��A�h�I��             �o�^/�X�V��������
--
-- ##### 20081017 Ver.1.8 T_S_465�Ή� start #####
  gv_prod_div           xxwip_transfer_fare_inf.goods_classe%TYPE; -- ���i�敪
  gv_concurrent_no      xxwip_deliverys_ctrl.concurrent_no%TYPE;   -- �R���J�����gNO
-- ##### 20081017 Ver.1.8 T_S_465�Ή� end   #####
--
-- ##### 20081016 Ver.1.7 �����ύX#225 start #####
--
  /**********************************************************************************
   * Procedure Name   : del_deliveryoff_proc
   * Description      : �z�ԉ����Ώۃf�[�^�폜����
   ***********************************************************************************/
  PROCEDURE del_deliveryoff_proc(
    iv_request_no    IN         VARCHAR2,     -- �˗�No
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_deliveryoff_proc'; -- �v���O������
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
    -- ================================================
    -- = �U�։^�����A�h�I�� �폜����
    -- ================================================
    DELETE FROM xxwip_transfer_fare_inf
    WHERE  request_no = iv_request_no;
--
    -- ================================================
    -- = �U�։^�����T�}���[�A�h�I�� �폜����
    -- ================================================
    DELETE FROM xxwip_transfer_fare_sum
    WHERE  request_no = iv_request_no;
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
  END del_deliveryoff_proc;
--
-- ##### 20081016 Ver.1.7 �����ύX#225 end   #####
--
  /**********************************************************************************
   * Procedure Name   : chk_param_proc
   * Description      : �p�����[�^�`�F�b�N����(C-1)
   ***********************************************************************************/
  PROCEDURE chk_param_proc(
    iv_exchange_type   IN         VARCHAR2,     -- �􂢑ւ��敪
-- ##### 20081017 Ver.1.8 T_S_465�Ή� start #####
    iv_prod_div        IN         VARCHAR2,     -- ���i�敪
-- ##### 20081017 Ver.1.8 T_S_465�Ή� end   #####
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_count NUMBER;   -- �`�F�b�N�p�J�E���^�[
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
    -- �􂢑ւ��敪�����݂��Ȃ��ꍇ
    IF (ln_count < 1) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cmn_msg_kbn,   gv_cmn_msg_75c_010,
                                            gv_tkn_parameter, gv_exchange_type_name,
                                            gv_tkn_value,     iv_exchange_type);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- ##### 20081017 Ver.1.8 T_S_465�Ή� start #####
--
  -- ���i�敪 �R�[�h���݊m�F
    SELECT COUNT(1) CNT             -- �J�E���g
    INTO   ln_count
    FROM   xxcmn_categories_v xcv   -- �J�e�S�����VIEW
    WHERE  xcv.category_set_name = '���i�敪'
    AND    xcv.segment1 = iv_prod_div
    AND    ROWNUM = 1;
--
    -- ���i�敪�����݂��Ȃ��ꍇ
    IF (ln_count < 1) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cmn_msg_kbn,
                                            gv_cmn_msg_75c_010,
                                            gv_tkn_parameter,
                                            gv_iv_prod_div_name,
                                            gv_tkn_value,
                                            iv_prod_div);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ==================================================
    -- �p�����[�^�`�F�b�NOK�ł���΁A���i�敪��ݒ�
    -- ==================================================
    gv_prod_div := iv_prod_div;
--
-- ##### 20081017 Ver.1.8 T_S_465�Ή� end   #####
--
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
   * Description      : �֘A�f�[�^�擾(C-2)
   ***********************************************************************************/
  PROCEDURE get_init(
    iv_exchange_type IN         VARCHAR2,     -- �􂢑ւ��敪
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
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_close_type VARCHAR2(1);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
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
-- ##### 20081017 Ver.1.8 T_S_465�Ή� start #####
--
    -- �^���v�Z�p�R���g���[���̃R���J�����gNO�ݒ�
    -- ���[�t�̏ꍇ
    IF (gv_prod_div = gv_prod_class_lef) THEN
      gv_concurrent_no := gv_con_lef ;
--
    -- �h�����N�̏ꍇ
    ELSE
      gv_concurrent_no := gv_con_drk ;
    END IF;
-- ##### 20081017 Ver.1.8 T_S_465�Ή� end   #####
--
    -- ���̓p�����[�^.�􂢑ւ��敪 = NO �̏ꍇ
    IF (iv_exchange_type = gv_ktg_no) THEN
--
      -- �^���v�Z�p�R���g���[�����O�񏈗����t���擾
      BEGIN
        SELECT xdc.last_process_date    -- �O�񏈗����t
        INTO   gd_last_process_date
        FROM   xxwip_deliverys_ctrl xdc -- �^���v�Z�p�R���g���[���A�h�I��
-- ##### 20081017 Ver.1.8 T_S_465�Ή� start #####
--        WHERE  xdc.concurrent_no = gv_con_no_deli
        WHERE  xdc.concurrent_no = gv_concurrent_no
-- ##### 20081017 Ver.1.8 T_S_465�Ή� end   #####
        FOR UPDATE NOWAIT;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   --*** �f�[�^�擾�G���[ ***
-- ##### 20081017 Ver.1.8 T_S_465�Ή� start #####
/*****
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cmn_msg_kbn, gv_cmn_msg_75c_001,
                                                gv_tkn_table,   gv_deli_ctrl_name,
                                                gv_tkn_key,     gv_con_no_deli);
*****/
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cmn_msg_kbn,
                                                gv_cmn_msg_75c_001,
                                                gv_tkn_table,
                                                gv_deli_ctrl_name,
                                                gv_tkn_key,
                                                gv_concurrent_no);
-- ##### 20081017 Ver.1.8 T_S_465�Ή� end   #####
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
        WHEN lock_expt THEN   --*** ���b�N�擾�G���[ ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn, gv_wip_msg_75c_004,
                                                gv_tkn_table,   gv_deli_ctrl_name);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
    END IF;
--
    -- �O���^�����ߌ� ����
    xxwip_common3_pkg.check_lastmonth_close(
      lv_close_type,   -- ���ߋ敪(Y:�����O�AN:������)
      lv_errbuf,       -- �G���[�E���b�Z�[�W
      lv_retcode,      -- ���^�[���E�R�[�h
      lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errbuf := lv_errmsg;
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
  END get_init;
--
  /**********************************************************************************
   * Procedure Name   : get_order_proc
   * Description      : �󒍃f�[�^���o����(C-3)
   ***********************************************************************************/
  PROCEDURE get_order_proc(
    iv_exchange_type IN         VARCHAR2,     -- �􂢑ւ��敪
    ov_target_flg    OUT        VARCHAR2,     -- �Ώۃf�[�^�L���t���O 0:�����A1:�L��
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_proc'; -- �v���O������
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
    -- �Ώۃf�[�^�L���t���O�̏����� �f�t�H���g:�f�[�^�L��
    ov_target_flg := '1';
--
    -- �󒍃w�b�_�A�h�I���A�󒍖��׃A�h�I���A�p�[�e�B���VIEW2�AOPM�i�ڏ��VIEW�A
    -- �󒍃^�C�v���VIEW�A�z���敪���VIEW ���Ώۃf�[�^���擾
    SELECT xoha.order_header_id,                 -- 1.�󒍃w�b�_�A�h�I��ID
           xoha.order_type_id,                   -- 2.�󒍃^�C�v
           xoha.request_no,                      -- 3.�˗�No
           xoha.arrival_date,                    -- 4.���ד�
           xoha.head_sales_branch,               -- 5.�Ǌ����_
           xoha.deliver_from,                    -- 6.�o�׌��ۊǏꏊ
-- ##### 20080609 MOD TE080�w�E�����Ή� start #####
/***
           xoha.deliver_to,                      -- 7.�o�א�
           xoha.shipping_method_code,            -- 8.�z���敪
***/
           xoha.result_deliver_to,               -- 7.�o�א�_����
           xoha.result_shipping_method_code,     -- 8.�z���敪_����
-- ##### 20080609 MOD TE080�w�E�����Ή� end  #####
           xoha.small_quantity,                  -- 9.������
           xoha.prod_class,                      -- 10.���i�敪
           TO_CHAR(xoha.arrival_date, 'YYYYMM'), -- 11.�Ώ۔N��(�`��:YYYYMM)
           xola.shipping_item_code,              -- 12.�o�וi��
-- 2008/07/29 Mod ��
/*
           xola.shipped_quantity,                -- 13.�o�׎��ѐ���
*/
           NVL(xola.shipped_quantity,0),         -- 13.�o�׎��ѐ���
-- 2008/07/29 Mod ��
           ximv.product_class,                   -- 14.���i����
           ximv.conv_unit,                       -- 15.���o�Ɋ��Z�P��
           ximv.num_of_cases,                    -- 16.�P�[�X����
           xpv.base_major_division,              -- 17.���_�啪��
           xsmv.small_amount_class,              -- 18.�����敪
           xsmv.penalty_class,                   -- 19.�y�i���e�B�敪
-- ##### 20081016 Ver.1.7 �����ύX#225 start #####
--           NULL                                  -- 20.�P��(�����ł�NULL��ݒ�)
           NULL ,                                -- 20.�P��(�����ł�NULL��ݒ�)
           xoha.delivery_no                      -- �z��No
-- ##### 20081016 Ver.1.7 �����ύX#225 end   #####
    BULK COLLECT INTO gt_order_inf_tbl
    FROM   xxwsh_order_headers_all      xoha,    -- �󒍃w�b�_�A�h�I��
           xxwsh_order_lines_all        xola,    -- �󒍖��׃A�h�I��
-- ##### 20080903 Ver.1.5 �����ύX�v��201_203 start #####
--           xxcmn_parties2_v             xpv,     -- �p�[�e�B���VIEW2
           xxcmn_cust_accounts2_v         xpv,     -- �ڋq���VIEW2
-- ##### 20080903 Ver.1.5 �����ύX�v��201_203 end   #####
           xxcmn_item_mst2_v            ximv,    -- OPM�i�ڏ��VIEW
           xxwsh_ship_method_v          xsmv,    -- �z���敪���VIEW
           xxwsh_oe_transaction_types_v xotv     -- �󒍃^�C�v���VIEW
    WHERE  xoha.order_header_id       = xola.order_header_id
    AND    xoha.order_type_id         = xotv.transaction_type_id
    AND    xoha.latest_external_flag  = gv_ktg_yes
-- ##### 20081017 Ver.1.8 T_S_465�Ή� start #####
    AND    xoha.prod_class            = gv_prod_div -- ���i�敪
-- ##### 20081017 Ver.1.8 T_S_465�Ή� end   #####
-- ##### 20080903 Ver.1.5 �����ύX�v��201_203 start #####
    AND    xoha.result_deliver_to           IS NOT NULL   -- �o�א�_����
    AND    xoha.result_shipping_method_code IS NOT NULL   -- �z����_����
    AND    xoha.result_freight_carrier_code IS NOT NULL   -- �^���Ǝ�_����
    AND    xoha.arrival_date                IS NOT NULL   -- ���ד�
-- ##### 20080903 Ver.1.5 �����ύX�v��201_203 end   #####
-- ********** 20080508 �����ύX�v�� seq#75 MOD START **********
/***
    AND    xpv.transfer_standard      = '1'      -- �u1:�ݒ�U�ցv
***/
    AND (
            ((xoha.prod_class = gv_prod_class_lef)      -- ���i�敪 = ���[�t
            AND (xpv.leaf_transfer_std       = '1'))    -- �u1:�ݒ�U�ցv
          OR
            ((xoha.prod_class = gv_prod_class_drk)      -- ���i�敪 = �h�����N
            AND (xpv.drink_transfer_std      = '1'))    -- �u1:�ݒ�U�ցv
        )
-- ********** 20080508 �����ύX�v�� seq#75 MOD END   **********
--
-- ##### 20081106 Ver.1.9 ����#563�Ή� start #####
    AND 
      NOT ((xoha.prod_class = gv_prod_class_lef)            -- ���i�敪 = ���[�t��
            AND (xsmv.small_amount_class = gv_small_sum_no) -- �u0:�ԗ��v�͏��O����
          )
-- ##### 20081106 Ver.1.9 ����#563�Ή� end   #####
--
    AND    xotv.shipping_shikyu_class = '1'      -- �u1:�o�׈˗��v
    AND    xola.shipping_item_code    = ximv.item_no
    AND    xola.delete_flag           = 'N'      -- �폜����Ă��Ȃ�����
    AND    FND_DATE.STRING_TO_DATE(TO_CHAR(xoha.arrival_date, 'YYYYMM') || '01', 'YYYYMMDD')
      BETWEEN ximv.start_date_active AND ximv.end_date_active
    AND    xpv.party_number = xoha.head_sales_branch
    AND    FND_DATE.STRING_TO_DATE(TO_CHAR(xoha.arrival_date, 'YYYYMM') || '01', 'YYYYMMDD')
      BETWEEN xpv.start_date_active
        AND NVL(xpv.end_date_active, FND_DATE.STRING_TO_DATE('99991231','YYYYMMDD'))
-- ##### 20080609 MOD TE080�w�E�����Ή� start #####
/***
    AND    xsmv.ship_method_code      = xoha.shipping_method_code
***/
    AND    xsmv.ship_method_code      = xoha.result_shipping_method_code
-- ##### 20080609 MOD TE080�w�E�����Ή� end   #####
    AND    FND_DATE.STRING_TO_DATE(TO_CHAR(xoha.arrival_date, 'YYYYMM') || '01', 'YYYYMMDD')
      BETWEEN xsmv.start_date_active
        AND NVL(xsmv.end_date_active, FND_DATE.STRING_TO_DATE('99991231','YYYYMMDD'))
    AND    (((gv_closed_day = gv_ktg_no)          -- �֘A�f�[�^�擾.�O���^��������̏ꍇ
      AND (TO_CHAR(xoha.arrival_date, 'YYYYMM') = TO_CHAR(gd_sysdate, 'YYYYMM')))
        OR (((gv_closed_day = gv_ktg_yes)       -- �֘A�f�[�^�擾.�O���^�������O�̏ꍇ
          AND ((TO_CHAR(xoha.arrival_date, 'YYYYMM') = TO_CHAR(gd_sysdate, 'YYYYMM'))
            OR (TO_CHAR(xoha.arrival_date, 'YYYYMM') =
              TO_CHAR(ADD_MONTHS(gd_sysdate, -1), 'YYYYMM'))))))
    AND    (((iv_exchange_type = gv_ktg_no)        -- ���̓p�����[�^.�􂢑ւ��敪 = �uNO�v�̏ꍇ
      AND (((xoha.last_update_date >  gd_last_process_date)
        AND (gd_sysdate        >= xoha.last_update_date))
      OR ((xola.last_update_date >  gd_last_process_date)
        AND (gd_sysdate        >= xola.last_update_date))))
          OR ( iv_exchange_type = gv_ktg_yes ))
    ORDER BY xoha.request_no;
--
    -- �Ώۃf�[�^�Ȃ��̏ꍇ
    IF (NOT gt_order_inf_tbl.EXISTS(1)) THEN
      -- �Ώۃf�[�^�L���t���O�Ɂu�����v��ݒ�
      ov_target_flg := '0';
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
  END get_order_proc;
--
  /**********************************************************************************
   * Procedure Name   : set_trn
   * Description      : �U�։^�����A�h�I���f�[�^�ݒ�(C-4)
   ***********************************************************************************/
  PROCEDURE set_trn(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_trn'; -- �v���O������
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
    cv_reaf_tbl_name  CONSTANT VARCHAR2(50) := '���[�t�U�։^���A�h�I���}�X�^';
    cv_drink_tbl_name CONSTANT VARCHAR2(50) := '�h�����N�U�։^���A�h�I���}�X�^';
--
    -- *** ���[�J���ϐ� ***
    ln_flg              NUMBER;   -- ���݃`�F�b�N�p�t���O �u0:�����A1:�L��v
    ln_trn_fare_inf_id  NUMBER;   -- ID�i�[�p
    lt_item_id          xxcmn_item_mst_b.item_id%TYPE;   -- �i��ID
--2008/09/22 Add
    ln_msg_flg          NUMBER;
    lv_tbl_name         VARCHAR2(200);
--
-- ##### 20081016 Ver.1.7 �����ύX#225 start #####
    lv_request_no      xxwsh_order_headers_all.request_no%TYPE;   -- �˗�No�i�ێ��p�j
-- ##### 20081016 Ver.1.7 �����ύX#225 end   #####
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
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
-- ##### 20081016 Ver.1.7 �����ύX#225 start #####
    -- �˗�No ������
    lv_request_no := NULL;
-- ##### 20081016 Ver.1.7 �����ύX#225 end   #####
--
    -- �擾�����Ώۃf�[�^�̃}�X�^�f�[�^���擾����
    <<gt_order_inf_tbl_loop>>
    FOR ln_index IN gt_order_inf_tbl.FIRST .. gt_order_inf_tbl.LAST LOOP
--
-- ##### 20081016 Ver.1.7 �����ύX#225 start #####
--
      -- ==================================================
      -- = �z��No��NULL�̏ꍇ
      -- =   �z�Ԃ���������Ă���ׁA�U�֏�񂩂�폜����
      -- ==================================================
      IF (gt_order_inf_tbl(ln_index).delivery_no IS NULL ) THEN
--
        -- �˗��ԍ����ύX���ꂽ�ꍇ
        IF ((lv_request_no IS NULL)
          OR (gt_order_inf_tbl(ln_index).request_no <> lv_request_no )) THEN
--
          -- �폜�Ώ� �˗�No �ݒ�ibrack�p�j
          lv_request_no := gt_order_inf_tbl(ln_index).request_no;
--
          -- �z�ԉ����̍폜����
          del_deliveryoff_proc(gt_order_inf_tbl(ln_index).request_no ,   -- �˗�No
                               lv_errbuf ,
                               lv_retcode ,
                               lv_errmsg  );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
      -- ==================================================
      -- = �z��No���ݒ肳��Ă���ꍇ
      -- =    �U�։^���̑ΏۂƂ���
      -- ==================================================
      ELSE
--
-- ##### 20081016 Ver.1.7 �����ύX#225 end   #####
--
--2008/09/22 Add
        ln_msg_flg := 0;
--
        -- �󒍃f�[�^���o����.���i�敪 = �u���[�t�v�̏ꍇ
        IF (gt_order_inf_tbl(ln_index).prod_class = gv_prod_class_lef) THEN
          -- �󒍃f�[�^���o����.�����敪 = �u�ԗ��v�̏ꍇ
          IF (gt_order_inf_tbl(ln_index).small_amount_class = gv_small_sum_no) THEN
            -- ���[�t�U�։^���A�h�I���}�X�^���P��(�֐ݒ���z)���擾
            BEGIN
              SELECT xltdc.setting_amount              -- �P��(�֐ݒ���z)
              INTO   gt_order_inf_tbl(ln_index).setting_amount
              FROM   xxwip_leaf_trans_deli_chrgs xltdc -- ���[�t�U�։^���A�h�I���}�X�^
              WHERE  FND_DATE.STRING_TO_DATE(
                       gt_order_inf_tbl(ln_index).arrival_yyyymm || '01', 'YYYYMMDD')
                     BETWEEN xltdc.start_date_active
                       AND NVL(xltdc.end_date_active
                              ,FND_DATE.STRING_TO_DATE('99991231', 'YYYYMMDD'));
            EXCEPTION
              WHEN NO_DATA_FOUND THEN   --*** �f�[�^�擾�G���[ ***
                -- �f�[�^�����݂��Ȃ��ꍇ�͒P���Ɂu0�v��ݒ�
                gt_order_inf_tbl(ln_index).setting_amount := 0;
                ln_msg_flg := 1;                                    -- 2008/09/22 Add
            END;
--
          -- �󒍃f�[�^���o����.�����敪 = �u�����v�̏ꍇ
          ELSIF (gt_order_inf_tbl(ln_index).small_amount_class = gv_small_sum_yes) THEN
            -- ���[�t�U�։^���A�h�I���}�X�^���P��(�֐ݒ���z)���擾
            BEGIN
              -- �������ɂ���Đݒ���z���擾
              SELECT 
                CASE
                  WHEN (gt_order_inf_tbl(ln_index).small_quantity <= xltdc.upper_limit_number1) THEN
                    xltdc.setting_amount1
                  WHEN (gt_order_inf_tbl(ln_index).small_quantity <= xltdc.upper_limit_number2) THEN
                    xltdc.setting_amount2
                  WHEN (gt_order_inf_tbl(ln_index).small_quantity <= xltdc.upper_limit_number3) THEN
                    xltdc.setting_amount3
                  WHEN (gt_order_inf_tbl(ln_index).small_quantity <= xltdc.upper_limit_number4) THEN
                    xltdc.setting_amount4
                  WHEN (gt_order_inf_tbl(ln_index).small_quantity <= xltdc.upper_limit_number5) THEN
                    xltdc.setting_amount5
                  WHEN (gt_order_inf_tbl(ln_index).small_quantity <= xltdc.upper_limit_number6) THEN
                    xltdc.setting_amount6
                  WHEN (gt_order_inf_tbl(ln_index).small_quantity <= xltdc.upper_limit_number7) THEN
                    xltdc.setting_amount7
                  WHEN (gt_order_inf_tbl(ln_index).small_quantity <= xltdc.upper_limit_number8) THEN
                    xltdc.setting_amount8
                  WHEN (gt_order_inf_tbl(ln_index).small_quantity <= xltdc.upper_limit_number9) THEN
                    xltdc.setting_amount9
                  WHEN (gt_order_inf_tbl(ln_index).small_quantity <= xltdc.upper_limit_number10) THEN
                     xltdc.setting_amount10
                  ELSE 0
                END AS setting_amount                   -- �P��(�֐ݒ���z)
              INTO  gt_order_inf_tbl(ln_index).setting_amount
              FROM  xxwip_leaf_trans_deli_chrgs xltdc -- ���[�t�U�։^���A�h�I���}�X�^
              WHERE FND_DATE.STRING_TO_DATE(
                      gt_order_inf_tbl(ln_index).arrival_yyyymm || '01', 'YYYYMMDD')
                    BETWEEN xltdc.start_date_active AND xltdc.end_date_active;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN   --*** �f�[�^�擾�G���[ ***
                -- �f�[�^�����݂��Ȃ��ꍇ�͒P���Ɂu0�v��ݒ�
                gt_order_inf_tbl(ln_index).setting_amount := 0;
                ln_msg_flg := 1;                                    -- 2008/09/22 Add
            END;
--
          END IF;
--
        -- �󒍃f�[�^���o����.���i�敪 = �u�h�����N�v�̏ꍇ
        ELSIF (gt_order_inf_tbl(ln_index).prod_class = gv_prod_class_drk) THEN
--
          BEGIN
            SELECT CASE
                     WHEN (gt_order_inf_tbl(ln_index).penalty_class = gv_penalty_no) THEN
                       xdtdc.setting_amount
                     WHEN (gt_order_inf_tbl(ln_index).penalty_class = gv_penalty_yes) THEN
                       xdtdc.penalty_amount
                     ELSE 0
                   END AS setting_amount                     -- �֐ݒ���z
            INTO   gt_order_inf_tbl(ln_index).setting_amount
            FROM   xxwip_drink_trans_deli_chrgs xdtdc -- �h�����N�U�։^���A�h�I���}�X�^
            WHERE  xdtdc.godds_classification   = gt_order_inf_tbl(ln_index).product_class
            AND    xdtdc.dellivary_classe       = gt_order_inf_tbl(ln_index).shipping_method_code
            AND    xdtdc.foothold_macrotaxonomy = gt_order_inf_tbl(ln_index).base_major_division
            AND    FND_DATE.STRING_TO_DATE(
                     gt_order_inf_tbl(ln_index).arrival_yyyymm || '01', 'YYYYMMDD')
                   BETWEEN xdtdc.start_date_active AND xdtdc.end_date_active;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN   --*** �f�[�^�擾�G���[ ***
              -- �f�[�^�����݂��Ȃ��ꍇ�͒P���Ɂu0�v��ݒ�
              gt_order_inf_tbl(ln_index).setting_amount := 0;
              ln_msg_flg := 2;                                      -- 2008/09/22 Add
          END;
--
        END IF;
--
        -- ���o�����f�[�^�����ɐU�։^�����A�h�I���̑��݃`�F�b�N���s���A���݂���ꍇ�̓��b�N���s��
        BEGIN
          SELECT xtfi.transfer_fare_inf_id    -- �U�։^�����ID
          INTO   ln_trn_fare_inf_id
          FROM   xxwip_transfer_fare_inf xtfi -- �U�։^�����A�h�I��
          WHERE  xtfi.target_date        = gt_order_inf_tbl(ln_index).arrival_yyyymm
          AND    xtfi.request_no         = gt_order_inf_tbl(ln_index).request_no
          AND    xtfi.goods_classe       = gt_order_inf_tbl(ln_index).prod_class
          AND    xtfi.jurisdicyional_hub = gt_order_inf_tbl(ln_index).head_sales_branch
          AND    xtfi.item_code          = gt_order_inf_tbl(ln_index).shipping_item_code
          FOR UPDATE NOWAIT;
--
          -- ���݂���ꍇ�͑��݃`�F�b�N�p�t���O���u1�v�ɐݒ�
          ln_flg := 1;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN   --*** �f�[�^�擾�G���[ ***
            -- �f�[�^�����݂��Ȃ��ꍇ�͑��݃`�F�b�N�p�t���O�Ɂu0�v��ݒ�
            ln_flg := 0;
          WHEN lock_expt THEN   -- *** ���b�N�擾�G���[ ***
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn, gv_wip_msg_75c_004,
                                                  gv_tkn_table,   gv_trans_fare_inf_name);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
        -- �i��ID�̎擾
        BEGIN
          SELECT ximv.item_id            -- �i��ID
          INTO   lt_item_id
          FROM   xxcmn_item_mst2_v ximv   -- OPM�i�ڏ��VIEW
          WHERE  ximv.item_no = gt_order_inf_tbl(ln_index).shipping_item_code
          AND    FND_DATE.STRING_TO_DATE(
                   gt_order_inf_tbl(ln_index).arrival_yyyymm || '01', 'YYYYMMDD')
                 BETWEEN ximv.start_date_active AND ximv.end_date_active;
        EXCEPTION
          WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN   -- *** �f�[�^�擾�G���[ ***
            RAISE global_api_expt;
        END;
--
        -- ���݂��Ȃ��ꍇ�͐U�։^�����A�h�I���o�^�pPL/SQL�\�Ɋi�[
        IF (ln_flg = 0) THEN
--
          -- �o�^�pPL/SQL�\ �����J�E���g
          gn_ins_order_inf_cnt := gn_ins_order_inf_cnt + 1;
--
          -- 1.�U�։^�����ID �̔�
          SELECT xxwip_transfer_fare_inf_id_s1.NEXTVAL
          INTO   i_trn_fare_inf_id_tab(gn_ins_order_inf_cnt)
          FROM   dual;
--
          -- ****************************************
          -- * �U�։^�����f�[�^ �o�^�pPL/SQL�\ �ݒ�
          -- ****************************************
          -- 2.�Ώ۔N��
          i_trn_target_date_tab(gn_ins_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).arrival_yyyymm;
          -- 3.�˗�No
          i_trn_request_no_tab(gn_ins_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).request_no;
          -- 4.���i�敪
          i_trn_goods_classe_tab(gn_ins_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).prod_class;
          -- 5.�z����
          i_trn_delivery_date_tab(gn_ins_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).arrival_date;
          -- 6.�Ǌ����_
          i_trn_jurisdicyional_hub_tab(gn_ins_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).head_sales_branch;
          -- 7.�o�Ɍ�
          i_trn_delivery_whs_tab(gn_ins_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).deliver_from;
          -- 8.�z����
          i_trn_ship_to_tab(gn_ins_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).deliver_to;
          -- 9.�i�ڃR�[�h
          i_trn_item_code_tab(gn_ins_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).shipping_item_code;
          -- 10.�P��
          i_trn_price_tab(gn_ins_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).setting_amount;
--
          -- 11.�v�Z����
          -- �󒍃f�[�^���o����.���i�敪 = �u�h�����N�v�̏ꍇ
          IF (gt_order_inf_tbl(ln_index).prod_class = gv_prod_class_drk) THEN
-- ********** 20080508 �����ύX�v�� seq#59 MOD START **********
/***
            i_trn_calc_qry_tab(gn_ins_order_inf_cnt) :=
              TRUNC(xxcmn_common_pkg.rcv_ship_conv_qty(
                      gv_rcv_to_first                               -- �ϊ����@
                     ,lt_item_id                                    -- �i��ID
                     ,gt_order_inf_tbl(ln_index).shipped_quantity   -- ����
                    ));
***/
            -- �v�Z���ʕϊ�
            i_trn_calc_qry_tab(gn_ins_order_inf_cnt) :=
              xxwip_common3_pkg.deliv_rcv_ship_conv_qty(
                    gt_order_inf_tbl(ln_index).shipping_item_code -- �i�ڃR�[�h
                  , gt_order_inf_tbl(ln_index).shipped_quantity);    -- ����
-- ********** 20080508 �����ύX�v�� seq#59 MOD END   **********
--
          -- �󒍃f�[�^���o����.���i�敪 = �u���[�t�v�̏ꍇ
          ELSIF (gt_order_inf_tbl(ln_index).prod_class = gv_prod_class_lef) THEN
            -- �󒍃f�[�^���o����.�����敪 = �u�ԗ��v�̏ꍇ
-- 2008/07/29 Mod ��
/*
            IF (gt_order_inf_tbl(ln_index).prod_class = gv_small_sum_no) THEN
*/
            IF (gt_order_inf_tbl(ln_index).small_amount_class = gv_small_sum_no) THEN
-- 2008/07/29 Mod ��
              -- �Œ�Łu1�v��ݒ�
              i_trn_calc_qry_tab(gn_ins_order_inf_cnt) := 1;
            -- �󒍃f�[�^���o����.�����敪 = �u�����v�̏ꍇ
-- 2008/07/29 Mod ��
/*
            ELSIF (gt_order_inf_tbl(ln_index).prod_class = gv_small_sum_yes) THEN
*/
            ELSIF (gt_order_inf_tbl(ln_index).small_amount_class = gv_small_sum_yes) THEN
-- 2008/07/29 Mod ��
              -- �󒍃f�[�^���o����.��������ݒ�
              i_trn_calc_qry_tab(gn_ins_order_inf_cnt) := gt_order_inf_tbl(ln_index).small_quantity;
            END IF;
          END IF;
--
          -- 12.���ې���
-- ********** 20080508 �����ύX�v�� seq#59 MOD START **********
/***
          i_trn_actual_qty_tab(gn_ins_order_inf_cnt) :=
            TRUNC(xxcmn_common_pkg.rcv_ship_conv_qty(
                    gv_rcv_to_first                               -- �ϊ����@
                   ,lt_item_id                                    -- �i��ID
                   ,gt_order_inf_tbl(ln_index).shipped_quantity   -- ����
                 ));
***/
          i_trn_actual_qty_tab(gn_ins_order_inf_cnt) :=
                  xxwip_common3_pkg.deliv_rcv_ship_conv_qty(
                        gt_order_inf_tbl(ln_index).shipping_item_code -- �i�ڃR�[�h
                      , gt_order_inf_tbl(ln_index).shipped_quantity); -- ����
-- ********** 20080508 �����ύX�v�� seq#59 MOD END   **********
--
          -- 13.���z
          i_trn_amount_tab(gn_ins_order_inf_cnt) :=
-- ##### 20080903 Ver.1.5 �����ύX�v��201_203 start #####
--          gt_order_inf_tbl(ln_index).setting_amount * i_trn_calc_qry_tab(gn_ins_order_inf_cnt);
   -- ##### 20081106 Ver.1.9 ����#537�Ή� start #####
--          ROUND(gt_order_inf_tbl(ln_index).setting_amount * i_trn_calc_qry_tab(gn_ins_order_inf_cnt));
            gt_order_inf_tbl(ln_index).setting_amount;
   -- ##### 20081106 Ver.1.9 ����#537�Ή� End   #####
-- ##### 20080903 Ver.1.5 �����ύX�v��201_203 end   #####
--
        -- ���݂���ꍇ�͐U�։^�����A�h�I���X�V�pPL/SQL�\�Ɋi�[
        ELSIF (ln_flg = 1) THEN
--
        -- �X�V�pPL/SQL�\ �����J�E���g
        gn_upd_order_inf_cnt := gn_upd_order_inf_cnt + 1;
--
          -- **************************************
          -- * �U�։^�����f�[�^ �X�V�pPL/SQL �ݒ�
          -- **************************************
          -- 1.�U�։^�����ID
          u_trn_fare_inf_id_tab(gn_upd_order_inf_cnt) := ln_trn_fare_inf_id;
          -- 2.�Ώ۔N��
          u_trn_target_date_tab(gn_upd_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).arrival_yyyymm;
          -- 3.�˗�No
          u_trn_request_no_tab(gn_upd_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).request_no;
          -- 4.���i�敪
          u_trn_goods_classe_tab(gn_upd_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).prod_class;
          -- 5.�z����
          u_trn_delivery_date_tab(gn_upd_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).arrival_date;
          -- 6.�Ǌ����_
          u_trn_jurisdicyional_hub_tab(gn_upd_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).head_sales_branch;
          -- 7.�o�Ɍ�
          u_trn_delivery_whs_tab(gn_upd_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).deliver_from;
          -- 8.�z����
          u_trn_ship_to_tab(gn_upd_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).deliver_to;
          -- 9.�i�ڃR�[�h
          u_trn_item_code_tab(gn_upd_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).shipping_item_code;
          -- 10.�P��
          u_trn_price_tab(gn_upd_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).setting_amount;
--
          -- 11.�v�Z����
          -- �󒍃f�[�^���o����.���i�敪 = �u�h�����N�v�̏ꍇ
          IF (gt_order_inf_tbl(ln_index).prod_class = gv_prod_class_drk) THEN
-- ********** 20080508 �����ύX�v�� seq#59 MOD START **********
/***
            -- ���o�Ɋ��Z�֐��̌Ăяo��
            u_trn_calc_qry_tab(gn_upd_order_inf_cnt) :=
              TRUNC(xxcmn_common_pkg.rcv_ship_conv_qty(
                      gv_rcv_to_first                               -- �ϊ����@
                     ,lt_item_id                                    -- �i��ID
                     ,gt_order_inf_tbl(ln_index).shipped_quantity   -- ����
                   ));
***/
            u_trn_calc_qry_tab(gn_upd_order_inf_cnt) :=
                xxwip_common3_pkg.deliv_rcv_ship_conv_qty(
                      gt_order_inf_tbl(ln_index).shipping_item_code -- �i�ڃR�[�h
                    , gt_order_inf_tbl(ln_index).shipped_quantity); -- ����
-- ********** 20080508 �����ύX�v�� seq#59 MOD END   **********
--
          -- �󒍃f�[�^���o����.���i�敪 = �u���[�t�v�̏ꍇ
          ELSIF (gt_order_inf_tbl(ln_index).prod_class = gv_prod_class_lef) THEN
            -- �󒍃f�[�^���o����.�����敪 = �u�ԗ��v�̏ꍇ
-- 2008/07/29 Mod ��
/*
            IF (gt_order_inf_tbl(ln_index).prod_class = gv_small_sum_no) THEN
*/
            IF (gt_order_inf_tbl(ln_index).small_amount_class = gv_small_sum_no) THEN
-- 2008/07/29 Mod ��
              -- �Œ�Łu1�v��ݒ�
              u_trn_calc_qry_tab(gn_upd_order_inf_cnt) := 1;
            -- �󒍃f�[�^���o����.�����敪 = �u�����v�̏ꍇ
-- 2008/07/29 Mod ��
/*
            ELSIF (gt_order_inf_tbl(ln_index).prod_class = gv_small_sum_yes) THEN
*/
            ELSIF (gt_order_inf_tbl(ln_index).small_amount_class = gv_small_sum_yes) THEN
-- 2008/07/29 Mod ��
              -- �󒍃f�[�^���o����.��������ݒ�
              u_trn_calc_qry_tab(gn_upd_order_inf_cnt) := gt_order_inf_tbl(ln_index).small_quantity;
            END IF;
          END IF;
--
-- ********** 20080508 �����ύX�v�� seq#59 MOD START **********
/***
          -- 12.���ې���
          u_trn_actual_qty_tab(gn_upd_order_inf_cnt) :=
            TRUNC(xxcmn_common_pkg.rcv_ship_conv_qty(
                    gv_rcv_to_first                               -- �ϊ����@
                   ,lt_item_id                                    -- �i��ID
                   ,gt_order_inf_tbl(ln_index).shipped_quantity   -- ����
                 ));
***/
          u_trn_actual_qty_tab(gn_upd_order_inf_cnt) :=
                xxwip_common3_pkg.deliv_rcv_ship_conv_qty(
                      gt_order_inf_tbl(ln_index).shipping_item_code -- �i�ڃR�[�h
                    , gt_order_inf_tbl(ln_index).shipped_quantity); -- ����
-- ********** 20080508 �����ύX�v�� seq#59 MOD END   **********
--
          -- 13.���z
          u_trn_amount_tab(gn_upd_order_inf_cnt) :=
-- ##### 20080903 Ver.1.5 �����ύX�v��201_203 start #####
--          gt_order_inf_tbl(ln_index).setting_amount * u_trn_calc_qry_tab(gn_upd_order_inf_cnt);
   -- ##### 20081106 Ver.1.9 ����#537�Ή� start #####
--          ROUND(gt_order_inf_tbl(ln_index).setting_amount * u_trn_calc_qry_tab(gn_upd_order_inf_cnt));
            gt_order_inf_tbl(ln_index).setting_amount;
   -- ##### 20081106 Ver.1.9 ����#537�Ή� End   #####
-- ##### 20080903 Ver.1.5 �����ύX�v��201_203 end   #####
        END IF;
--2008/09/22 Add ��
        IF (ln_msg_flg > 0) THEN
--
          -- ���[�t
          IF (ln_msg_flg = 1) THEN
            lv_tbl_name := cv_reaf_tbl_name;
--
          -- �h�����N
          ELSIF (ln_msg_flg = 2) THEN
            lv_tbl_name := cv_drink_tbl_name;
          END IF;
--
          -- ���b�Z�[�W�o��
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn,
                                                gv_wip_msg_75c_009,
                                                gv_tkn_tbl_name,
                                                lv_tbl_name,
                                                gv_tkn_req_no,
                                                gt_order_inf_tbl(ln_index).request_no);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        END IF;
  --2008/09/22 Add ��
  --
-- ##### 20081016 Ver.1.7 �����ύX#225 start #####
      END IF;
-- ##### 20081016 Ver.1.7 �����ύX#225 end   #####
--
    END LOOP gt_order_inf_tbl_loop;
--
  EXCEPTION
    WHEN func_inv_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
-- ##### 20081016 Ver.1.7 �����ύX#225 start #####
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
-- ##### 20081016 Ver.1.7 �����ύX#225 end   #####
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
  END set_trn;
--
  /**********************************************************************************
   * Procedure Name   : ins_trn_proc
   * Description      : �U�։^�����A�h�I���ꊇ�o�^����(C-5)
   ***********************************************************************************/
  PROCEDURE ins_trn_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_trn_proc'; -- �v���O������
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
    -- ***************************
    -- * �U�։^�����A�h�I�� �o�^
    -- ***************************
    FORALL ln_index IN i_trn_fare_inf_id_tab.FIRST .. i_trn_fare_inf_id_tab.LAST
      INSERT INTO xxwip_transfer_fare_inf     -- �U�։^�����A�h�I��
      (transfer_fare_inf_id                   -- 1.�U�։^�����ID
      ,target_date                            -- 2.�Ώ۔N��
      ,request_no                             -- 3.�˗��m��
      ,goods_classe                           -- 4.���i�敪
      ,delivery_date                          -- 5.�z����
      ,jurisdicyional_hub                     -- 6.�Ǌ����_
      ,delivery_whs                           -- 7.�o�Ɍ�
      ,ship_to                                -- 8.�z����
      ,item_code                              -- 9.�i�ڃR�[�h
      ,price                                  -- 10.�P��
      ,calc_qry                               -- 11.�v�Z����
      ,actual_qty                             -- 12.���ې���
      ,amount                                 -- 13.���z
      ,created_by                             -- 14.�쐬��
      ,creation_date                          -- 15.�쐬��
      ,last_updated_by                        -- 16.�ŏI�X�V��
      ,last_update_date                       -- 17.�ŏI�X�V��
      ,last_update_login                      -- 18.�ŏI�X�V���O�C��
      ,request_id                             -- 19.�v��ID
      ,program_application_id                 -- 20.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      ,program_id                             -- 21.�R���J�����g�E�v���O����ID
      ,program_update_date)                   -- 22.�v���O�����X�V��
      VALUES
      (i_trn_fare_inf_id_tab(ln_index)        -- 1.�U�։^�����ID
      ,i_trn_target_date_tab(ln_index)        -- 2.�Ώ۔N��
      ,i_trn_request_no_tab(ln_index)         -- 3.�˗��m��
      ,i_trn_goods_classe_tab(ln_index)       -- 4.���i�敪
      ,i_trn_delivery_date_tab(ln_index)      -- 5.�z����
      ,i_trn_jurisdicyional_hub_tab(ln_index) -- 6.�Ǌ����_
      ,i_trn_delivery_whs_tab(ln_index)       -- 7.�o�Ɍ�
      ,i_trn_ship_to_tab(ln_index)            -- 8.�z����
      ,i_trn_item_code_tab(ln_index)          -- 9.�i�ڃR�[�h
      ,i_trn_price_tab(ln_index)              -- 10.�P��
      ,i_trn_calc_qry_tab(ln_index)           -- 11.�v�Z����
      ,i_trn_actual_qty_tab(ln_index)         -- 12.���ې���
      ,i_trn_amount_tab(ln_index)             -- 13.���z
      ,gn_user_id                             -- 14.�쐬��
      ,gd_sysdate                             -- 15.�쐬��
      ,gn_user_id                             -- 16.�ŏI�X�V��
      ,gd_sysdate                             -- 17.�ŏI�X�V��
      ,gn_login_id                            -- 18.�ŏI�X�V���O�C��
      ,gn_conc_request_id                     -- 19.�v��ID
      ,gn_prog_appl_id                        -- 20.�ݶ��āE��۸��сE���ع����ID
      ,gn_conc_program_id                     -- 21.�R���J�����g�E�v���O����ID
      ,gd_sysdate);                           -- 22.�v���O�����X�V��
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
  END ins_trn_proc;
--
  /**********************************************************************************
   * Procedure Name   : upd_trn_proc
   * Description      : �U�։^�����A�h�I���ꊇ�X�V����(C-6)
   ***********************************************************************************/
  PROCEDURE upd_trn_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_trn_proc'; -- �v���O������
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
    -- ***************************
    -- * �U�։^�����A�h�I�� �X�V
    -- ***************************
    FORALL ln_index IN u_trn_target_date_tab.FIRST .. u_trn_target_date_tab.LAST
      UPDATE xxwip_transfer_fare_inf xtfi -- �U�։^�����A�h�I��
      SET    price                     = u_trn_price_tab(ln_index)      -- �P��
            ,calc_qry                  = u_trn_calc_qry_tab(ln_index)   -- �v�Z����
            ,actual_qty                = u_trn_actual_qty_tab(ln_index) -- ���ې���
            ,amount                    = u_trn_amount_tab(ln_index)     -- ���z
            ,last_updated_by           = gn_user_id                 -- �ŏI�X�V��
            ,last_update_date          = gd_sysdate                 -- �ŏI�X�V��
            ,last_update_login         = gn_login_id                -- �ŏI�X�V���O�C��
            ,request_id                = gn_conc_request_id         -- �v��ID
            ,program_application_id    = gn_prog_appl_id            -- �ݶ��āE��۸��сE���ع����ID
            ,program_id                = gn_conc_program_id         -- �R���J�����g�E�v���O����ID
            ,program_update_date       = gd_sysdate                 -- �v���O�����X�V��
      WHERE  xtfi.transfer_fare_inf_id = u_trn_fare_inf_id_tab(ln_index);
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
  END upd_trn_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_trn_proc
   * Description      : �U�։^�����A�h�I�����o����(C-7)
   ***********************************************************************************/
  PROCEDURE get_trn_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_trn_proc'; -- �v���O������
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
    -- �Ώۃf�[�^�̎擾
    SELECT xtfi.target_date,            -- 1.�Ώ۔N��
           xtfi.request_no,             -- 2.�˗�No
           xtfi.goods_classe,           -- 3.���i�敪
           xtfi.jurisdicyional_hub,     -- 4.�Ǌ����_
           SUM(xtfi.actual_qty),        -- 5.�U�֐���
           CASE                         -- 6.���[�t�U�֋��z
             WHEN (xtfi.goods_classe = gv_prod_class_lef) THEN
               TRUNC(AVG(xtfi.amount))
             WHEN (xtfi.goods_classe = gv_prod_class_drk) THEN
               NULL
             ELSE 0
           END AS leaf_chg_amount,
           CASE                         -- 7.�h�����N�U�֋��z
             WHEN (xtfi.goods_classe = gv_prod_class_lef) THEN
               NULL
             WHEN (xtfi.goods_classe = gv_prod_class_drk) THEN
               SUM(xtfi.amount)
             ELSE 0
           END AS drink_chg_amount
    BULK COLLECT INTO gt_order_summary_tbl
    FROM   xxwip_transfer_fare_inf xtfi       -- �U�։^�����A�h�I��
    WHERE  (((gv_closed_day = gv_ktg_no)
             AND (xtfi.target_date = TO_CHAR(gd_sysdate, 'YYYYMM')))
           OR ((gv_closed_day = gv_ktg_yes)   -- �O���^�������O�̏ꍇ
             AND (xtfi.target_date  = TO_CHAR(gd_sysdate, 'YYYYMM'))
             OR  (xtfi.target_date  = TO_CHAR(ADD_MONTHS(gd_sysdate, -1), 'YYYYMM'))))
-- ##### 20081017 Ver.1.8 T_S_465�Ή� start #####
    AND    xtfi.goods_classe  = gv_prod_div   -- ���i�敪
-- ##### 20081017 Ver.1.8 T_S_465�Ή� end   #####
    GROUP BY xtfi.target_date,
             xtfi.request_no,
             xtfi.goods_classe,
             xtfi.jurisdicyional_hub;
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
  END get_trn_proc;
--
  /**********************************************************************************
   * Procedure Name   : set_trn_sum
   * Description      : �U�։^�����T�}���[�A�h�I���f�[�^�ݒ�(C-8)
   ***********************************************************************************/
  PROCEDURE set_trn_sum(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_trn_sum'; -- �v���O������
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
    ln_flg             NUMBER;   -- ���݃`�F�b�N�p�t���O �u0:�����A1:�L��v
    ln_trn_fare_sum_id NUMBER;   -- ID�i�[�p
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
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
    -- ���o�����Ώۃf�[�^�̃��R�[�h���P�����擾����
    <<gt_order_summary_tbl_loop>>
    FOR ln_index IN gt_order_summary_tbl.FIRST .. gt_order_summary_tbl.LAST LOOP
--
      -- ���o�����f�[�^�����ɐU�։^�����T�}���[�A�h�I���̑��݃`�F�b�N���s��
      -- ���݂���ꍇ�̓��b�N���s��
      BEGIN
        SELECT xtfs.transfer_fare_sum_id    -- �U�։^�����T�}���[ID
        INTO   ln_trn_fare_sum_id
        FROM   xxwip_transfer_fare_sum xtfs -- �U�։^�����T�}���[�A�h�I��
        WHERE  xtfs.target_date        = gt_order_summary_tbl(ln_index).target_date
        AND    xtfs.request_no         = gt_order_summary_tbl(ln_index).request_no
        AND    xtfs.goods_classe       = gt_order_summary_tbl(ln_index).goods_classe
        AND    xtfs.jurisdicyional_hub = gt_order_summary_tbl(ln_index).jurisdicyional_hub
        FOR UPDATE NOWAIT;
--
        -- ���݂���ꍇ�͑��݃`�F�b�N�p�t���O���u1�v�ɐݒ�
        ln_flg := 1;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   --*** �f�[�^�擾�G���[ ***
          -- �f�[�^�����݂��Ȃ��ꍇ�͑��݃`�F�b�N�p�t���O�Ɂu0�v��ݒ�
          ln_flg := 0;
        WHEN lock_expt THEN   -- *** ���b�N�擾�G���[ ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn, gv_wip_msg_75c_004,
                                                gv_tkn_table,   gv_trans_fare_sum_name);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      -- �Ώۃf�[�^�����݂��Ȃ��ꍇ�͐U�։^�����T�}���[�A�h�I���o�^�pPL/SQL�\�Ɋi�[
      IF (ln_flg = 0) THEN
        -- �o�^�pPL/SQL�\ �����J�E���g
        gn_ins_order_sum_cnt := gn_ins_order_sum_cnt + 1;
--
        -- ************************************************
        -- * �U�։^�����T�}���[�f�[�^ �o�^�pPL/SQL�\ �ݒ�
        -- ************************************************
        -- 1.�U�։^�����T�}���[ID �̔�
        SELECT xxwip_transfer_fare_sum_id_s1.NEXTVAL
        INTO   i_trn_fare_sum_id_tab(gn_ins_order_sum_cnt)
        FROM   dual;
--
        -- 2.�Ώ۔N��
        i_trn_fare_sum_target_date_tab(gn_ins_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).target_date;
        -- 3.�˗�No
        i_trn_fare_sum_request_no_tab(gn_ins_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).request_no;
        -- 4.���i�敪
        i_trn_fare_sum_goods_clas_tab(gn_ins_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).goods_classe;
        -- 5.�Ǌ����_
        i_trn_fare_sum_juris_hub_tab(gn_ins_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).jurisdicyional_hub;
        -- 6.�U�֐���
        i_trn_fare_sum_actual_qty_tab(gn_ins_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).summary_qry;
        -- 7.���[�t�U�֋��z
        i_trn_fare_sum_leaf_amount_tab(gn_ins_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).leaf_chg_amount;
        -- 8.�h�����N�U�֋��z
        i_trn_fare_sum_drk_amount_tab(gn_ins_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).drink_chg_amount;
--
      -- �Ώۃf�[�^�����݂���ꍇ�͐U�։^�����T�}���[�A�h�I���X�V�pPL/SQL�\�Ɋi�[
      ELSIF (ln_flg = 1) THEN
--
        -- �X�V�pPL/SQL�\ �����J�E���g
        gn_upd_order_sum_cnt := gn_upd_order_sum_cnt + 1;
--
        -- ************************************************
        -- * �U�։^�����T�}���[�f�[�^ �X�V�pPL/SQL�\ �ݒ�
        -- ************************************************
        -- 1.�U�։^�����T�}���[ID
        u_trn_fare_sum_id_tab(gn_upd_order_sum_cnt) := ln_trn_fare_sum_id;
        -- 2.�Ώ۔N��
        u_trn_fare_sum_target_date_tab(gn_upd_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).target_date;
        -- 3.�˗�No
        u_trn_fare_sum_request_no_tab(gn_upd_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).request_no;
        -- 4.���i�敪
        u_trn_fare_sum_goods_clas_tab(gn_upd_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).goods_classe;
        -- 5.�Ǌ����_
        u_trn_fare_sum_juris_hub_tab(gn_upd_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).jurisdicyional_hub;
        -- 6.�U�֐���
        u_trn_fare_sum_actual_qty_tab(gn_upd_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).summary_qry;
        -- 7.���[�t�U�֋��z
        u_trn_fare_sum_leaf_amount_tab(gn_upd_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).leaf_chg_amount;
        -- 8.�h�����N�U�֋��z
        u_trn_fare_sum_drk_amount_tab(gn_upd_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).drink_chg_amount;
--
      END IF;
--
    END LOOP gt_order_summary_tbl_loop;
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
  END set_trn_sum;
--
  /**********************************************************************************
   * Procedure Name   : ins_trn_sum_proc
   * Description      : �U�։^�����T�}���[�A�h�I���ꊇ�o�^����(C-9)
   ***********************************************************************************/
  PROCEDURE ins_trn_sum_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_trn_sum_proc'; -- �v���O������
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
    -- ***********************************
    -- * �U�։^�����T�}���[�A�h�I�� �o�^
    -- ***********************************
    FORALL ln_index IN i_trn_fare_sum_id_tab.FIRST .. i_trn_fare_sum_id_tab.LAST
      INSERT INTO xxwip_transfer_fare_sum        -- �U�։^�����T�}���[�A�h�I��
      (transfer_fare_sum_id                      -- 1.�U�։^�����T�}���[ID
      ,target_date                               -- 2.�Ώ۔N��
      ,request_no                                -- 3.�˗�No
      ,goods_classe                              -- 4.���i�敪
      ,jurisdicyional_hub                        -- 5.�Ǌ����_
      ,actual_qty                                -- 6.�U�֐���
      ,leaf_amount                               -- 7.���[�t�U�֋��z
      ,drink_amount                              -- 8.�h�����N�U�֋��z
      ,created_by                                -- 9.�쐬��
      ,creation_date                             -- 10.�쐬��
      ,last_updated_by                           -- 11.�ŏI�X�V��
      ,last_update_date                          -- 12.�ŏI�X�V��
      ,last_update_login                         -- 13.�ŏI�X�V���O�C��
      ,request_id                                -- 14.�v��ID
      ,program_application_id                    -- 15.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      ,program_id                                -- 16.�R���J�����g�E�v���O����ID
      ,program_update_date)                      -- 17.�v���O�����X�V��
      VALUES
      (i_trn_fare_sum_id_tab(ln_index)           -- 1.�U�։^�����T�}���[ID
      ,i_trn_fare_sum_target_date_tab(ln_index)  -- 2.�Ώ۔N��
      ,i_trn_fare_sum_request_no_tab(ln_index)   -- 3.�˗�No
      ,i_trn_fare_sum_goods_clas_tab(ln_index)   -- 4.���i�敪
      ,i_trn_fare_sum_juris_hub_tab(ln_index)    -- 5.�Ǌ����_
      ,i_trn_fare_sum_actual_qty_tab(ln_index)   -- 6.�U�֐���
      ,i_trn_fare_sum_leaf_amount_tab(ln_index)  -- 7.���[�t�U�֋��z
      ,i_trn_fare_sum_drk_amount_tab(ln_index)   -- 8.�h�����N�U�֋��z
      ,gn_user_id                                -- 9.�쐬��
      ,gd_sysdate                                -- 10.�쐬��
      ,gn_user_id                                -- 11.�ŏI�X�V��
      ,gd_sysdate                                -- 12.�ŏI�X�V��
      ,gn_login_id                               -- 13.�ŏI�X�V���O�C��
      ,gn_conc_request_id                        -- 14.�v��ID
      ,gn_prog_appl_id                           -- 15.�ݶ��āE��۸��сE���ع����ID
      ,gn_conc_program_id                        -- 16.�R���J�����g�E�v���O����ID
      ,gd_sysdate);                              -- 17.�v���O�����X�V��
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
  END ins_trn_sum_proc;
--
  /**********************************************************************************
   * Procedure Name   : upd_trn_sum_proc
   * Description      : �U�։^�����T�}���[�A�h�I���ꊇ�X�V����(C-10)
   ***********************************************************************************/
  PROCEDURE upd_trn_sum_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_trn_sum_proc'; -- �v���O������
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
    -- ***********************************
    -- * �U�։^�����T�}���[�A�h�I�� �X�V
    -- ***********************************
    FORALL ln_index IN u_trn_fare_sum_target_date_tab.FIRST .. u_trn_fare_sum_target_date_tab.LAST
      UPDATE xxwip_transfer_fare_sum xtfs   -- �U�։^�����T�}���[�A�h�I��
      SET    xtfs.actual_qty        = u_trn_fare_sum_actual_qty_tab(ln_index)  -- �U�֐���
            ,xtfs.leaf_amount       = u_trn_fare_sum_leaf_amount_tab(ln_index) -- ���[�t�U�֋��z
            ,xtfs.drink_amount      = u_trn_fare_sum_drk_amount_tab(ln_index)  -- �h�����N�U�֋��z
            ,xtfs.last_updated_by        = gn_user_id               -- �ŏI�X�V��
            ,xtfs.last_update_date       = gd_sysdate               -- �ŏI�X�V��
            ,xtfs.last_update_login      = gn_login_id              -- �ŏI�X�V���O�C��
            ,xtfs.request_id             = gn_conc_request_id       -- �v��ID
            ,xtfs.program_application_id = gn_prog_appl_id          -- �ݶ��āE��۸��сE���ع����ID
            ,xtfs.program_id             = gn_conc_program_id       -- �R���J�����g�E�v���O����ID
            ,xtfs.program_update_date    = gd_sysdate               -- �v���O�����X�V��
      WHERE  xtfs.transfer_fare_sum_id   = u_trn_fare_sum_id_tab(ln_index);
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
  END upd_trn_sum_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_trn_sum_proc
   * Description      : �U�։^�����T�}���[�A�h�I�����o����(C-11)
   ***********************************************************************************/
  PROCEDURE get_trn_sum_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_trn_sum_proc'; -- �v���O������
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
    -- �Ώۃf�[�^�̎擾
    SELECT xtfs.target_date,            -- 1.�Ώ۔N��
           xtfs.goods_classe,           -- 2.���i�敪
           xtfs.jurisdicyional_hub,     -- 3.�Ǌ����_
           SUM(xtfs.actual_qty),        -- 4.�U�֐���
           CASE                         -- 5.�U�֋��z
             WHEN (xtfs.goods_classe = gv_prod_class_lef) THEN
               SUM(xtfs.leaf_amount)
             WHEN (xtfs.goods_classe = gv_prod_class_drk) THEN
               SUM(xtfs.drink_amount)
             ELSE 0
           END AS transfer_amount,
           NULL,                        -- 6.�c�ƃu���b�N(�����ł�NULL)
           NULL                         -- 7,�n�於(�����ł�NULL)
    BULK COLLECT INTO gt_trans_inf_tbl
    FROM   xxwip_transfer_fare_sum xtfs -- �U�։^�����T�}���[�A�h�I��
    WHERE  (((gv_closed_day = gv_ktg_no) -- �O���^��������̏ꍇ
             AND (xtfs.target_date = TO_CHAR(gd_sysdate, 'YYYYMM')))
           OR ((gv_closed_day = gv_ktg_yes)  -- �O���^�������O�̏ꍇ
             AND (xtfs.target_date = TO_CHAR(gd_sysdate, 'YYYYMM'))
             OR  (xtfs.target_date = TO_CHAR(ADD_MONTHS(gd_sysdate, -1), 'YYYYMM'))))
-- ##### 20081017 Ver.1.8 T_S_465�Ή� start #####
    AND   xtfs.goods_classe = gv_prod_div   -- ���i�敪
-- ##### 20081017 Ver.1.8 T_S_465�Ή� end   #####
    GROUP BY xtfs.target_date,
             xtfs.goods_classe,
             xtfs.jurisdicyional_hub;
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
  END get_trn_sum_proc;
--
  /**********************************************************************************
   * Procedure Name   : set_trn_inf
   * Description      : �U�֏��A�h�I���f�[�^�ݒ�(C-12)
   ***********************************************************************************/
  PROCEDURE set_trn_inf(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_trn_inf'; -- �v���O������
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
    ln_flg        NUMBER;   -- ���݃`�F�b�N�p�t���O �u0:�����A1:�L��v
    ln_trn_inf_id NUMBER;   -- ID�i�[�p
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
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
    -- �擾�����Ώۃf�[�^�̃}�X�^�f�[�^���擾����
    <<gt_trans_inf_tbl_loop>>
    FOR ln_index IN gt_trans_inf_tbl.FIRST .. gt_trans_inf_tbl.LAST LOOP
--
      BEGIN
        SELECT CASE                         -- �c�ƃu���b�N
                 WHEN (gt_trans_inf_tbl(ln_index).target_date || '01' <
                   TO_CHAR(xpv.start_date_active, 'YYYYMMDD'))
                 THEN
                   SUBSTR(xpv.old_division_code, 0, 4) -- ���E�{���R�[�h�̓�����4��
                 WHEN (gt_trans_inf_tbl(ln_index).target_date || '01' >=
                   TO_CHAR(xpv.start_date_active, 'YYYYMMDDD'))
                 THEN
                   SUBSTR(xpv.new_division_code, 0, 4) -- �V�E�{���R�[�h�̓�����4��
                 ELSE '0'
--2008/09/22 Mod ��
/*
               END AS business_block,
               xpv.block_name               -- �n�於
        INTO   gt_trans_inf_tbl(ln_index).business_block,
               gt_trans_inf_tbl(ln_index).area_name
*/
               END AS business_block
        INTO   gt_trans_inf_tbl(ln_index).business_block
--2008/09/22 Mod ��
-- ##### 20080903 Ver.1.5 �����ύX�v��201_203 start #####
--        FROM   xxcmn_parties2_v xpv         -- �p�[�e�B���VIEW2
        FROM   xxcmn_cust_accounts2_v xpv         -- �ڋq���VIEW2
-- ##### 20080903 Ver.1.5 �����ύX�v��201_203 end   #####
        WHERE  xpv.party_number = gt_trans_inf_tbl(ln_index).jurisdicyional_hub
        AND    FND_DATE.STRING_TO_DATE(gt_trans_inf_tbl(ln_index).target_date || '01', 'YYYYMMDD')
-- ********** 20080508 �����ύX�v�� seq#75 MOD START **********
/***
                 BETWEEN xpv.start_date_active AND xpv.end_date_active
        AND    xpv.transfer_standard = '1'; -- �u1:�ݒ�U�ցv
***/
                 BETWEEN xpv.start_date_active AND xpv.end_date_active;
-- ********** 20080508 �����ύX�v�� seq#75 MOD END   **********
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   --*** �f�[�^�擾�G���[ ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cmn_msg_kbn, gv_cmn_msg_75c_001,
                                                gv_tkn_table,   gv_party_view_name,
                                                gv_tkn_key,     gv_jurisdicyional_hub_name);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--2008/09/22 Add ��
      -- �n�於�̎擾
      BEGIN
        SELECT xlvv.meaning
        INTO   gt_trans_inf_tbl(ln_index).area_name
        FROM   xxcmn_lookup_values2_v xlvv
        WHERE  xlvv.lookup_type = 'XXCMN_AREA'
        AND    xlvv.lookup_code = gt_trans_inf_tbl(ln_index).business_block
        AND ( xlvv.start_date_active <= 
              FND_DATE.STRING_TO_DATE(gt_trans_inf_tbl(ln_index).target_date || '01', 'YYYYMMDD')
         OR xlvv.start_date_active IS NULL )
        AND ( xlvv.end_date_active >= 
              FND_DATE.STRING_TO_DATE(gt_trans_inf_tbl(ln_index).target_date || '01', 'YYYYMMDD')
         OR xlvv.end_date_active IS NULL )
        AND xlvv.enabled_flag = gv_ktg_yes;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   --*** �f�[�^�擾�G���[ ***
          gt_trans_inf_tbl(ln_index).area_name := NULL;
      END;
--2008/09/22 Add ��
--
      -- ���o�����f�[�^�����ɐU�֏��A�h�I���̑��݃`�F�b�N���s���A���݂���ꍇ�̓��b�N���s��
      BEGIN
        SELECT xti.transfer_inf_id        -- �U�֏��ID
        INTO   ln_trn_inf_id
        FROM   xxwip_transfer_inf xti     -- �U�֏��A�h�I��
        WHERE  xti.target_date        = gt_trans_inf_tbl(ln_index).target_date
        AND    xti.goods_classe       = gt_trans_inf_tbl(ln_index).goods_classe
        AND    xti.jurisdicyional_hub = gt_trans_inf_tbl(ln_index).jurisdicyional_hub
        FOR UPDATE NOWAIT;
--
        -- ���݂���ꍇ�͑��݃`�F�b�N�p�t���O���u1�v�ɐݒ�
        ln_flg := 1;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   --*** �f�[�^�擾�G���[ ***
          -- �f�[�^�����݂��Ȃ��ꍇ�͑��݃`�F�b�N�p�t���O�Ɂu0�v��ݒ�
          ln_flg := 0;
        WHEN lock_expt THEN   -- *** ���b�N�擾�G���[ ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn, gv_wip_msg_75c_004,
                                                gv_tkn_table,   gv_trans_inf_name);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      -- �Ώۃf�[�^�����݂��Ȃ��ꍇ�͐U�֏��A�h�I���o�^�pPL/SQL�\�Ɋi�[
      IF (ln_flg = 0) THEN
        -- �o�^�pPL/SQL�\ �����J�E���g
        gn_ins_trans_inf_cnt := gn_ins_trans_inf_cnt + 1;
--
        -- ************************************************
        -- * �U�֏��f�[�^ �o�^�pPL/SQL�\ �ݒ�
        -- ************************************************
        -- 1.�U�֏��ID
        SELECT xxwip_transfer_inf_id_s1.NEXTVAL
        INTO   i_trn_inf_id_tab(gn_ins_trans_inf_cnt)
        FROM   dual;
--
        -- 2.�Ώ۔N��
        i_trn_inf_target_date_tab(gn_ins_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).target_date;
        -- 3.�c�ƃu���b�N
        i_trn_inf_business_block_tab(gn_ins_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).business_block;
        -- 4.���i�敪
        i_trn_inf_goods_classe_tab(gn_ins_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).goods_classe;
        -- 5.�Ǌ����_
        i_trn_inf_juris_hub_tab(gn_ins_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).jurisdicyional_hub;
        -- 6.�n�於
        i_trn_inf_area_name_tab(gn_ins_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).area_name;
        -- 7.�U�֐���
        i_trn_inf_transfe_qty_tab(gn_ins_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).summary_qry;
        -- 8.�U�֋��z
        i_trn_inf_transfer_amount_tab(gn_ins_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).trans_amount;
--
      -- �Ώۃf�[�^�����݂���ꍇ�͐U�֏��A�h�I���X�V�pPL/SQL�\�Ɋi�[
      ELSIF (ln_flg = 1) THEN
--
        -- �X�V�pPL/SQL�\ �����J�E���g
        gn_upd_trans_inf_cnt := gn_upd_trans_inf_cnt + 1;
--
        -- ************************************************
        -- * �U�֏��f�[�^ �X�V�pPL/SQL�\ �ݒ�
        -- ************************************************
        -- 1.�U�֏��ID
        u_trn_inf_id_tab(gn_upd_trans_inf_cnt) := ln_trn_inf_id;
        -- 2.�Ώ۔N��
        u_trn_inf_target_date_tab(gn_upd_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).target_date;
        -- 3.�c�ƃu���b�N
        u_trn_inf_business_block_tab(gn_upd_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).business_block;
        -- 4.���i�敪
        u_trn_inf_goods_classe_tab(gn_upd_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).goods_classe;
        -- 5.�Ǌ����_
        u_trn_inf_juris_hub_tab(gn_upd_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).jurisdicyional_hub;
        -- 6.�n�於
        u_trn_inf_area_name_tab(gn_upd_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).area_name;
        -- 7.�U�֐���
        u_trn_inf_transfe_qty_tab(gn_upd_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).summary_qry;
        -- 8.�U�֋��z
        u_trn_inf_transfer_amount_tab(gn_upd_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).trans_amount;
--
      END IF;
    END LOOP gt_trans_inf_tbl_loop;
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
  END set_trn_inf;
--
  /**********************************************************************************
   * Procedure Name   : ins_trn_inf_proc
   * Description      : �U�֏��A�h�I���ꊇ�o�^����(C-13)
   ***********************************************************************************/
  PROCEDURE ins_trn_inf_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_trn_inf_proc'; -- �v���O������
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
    -- ***********************
    -- * �U�֏��A�h�I�� �o�^
    -- ***********************
    FORALL ln_index IN i_trn_inf_id_tab.FIRST .. i_trn_inf_id_tab.LAST
      INSERT INTO xxwip_transfer_inf              -- �U�֏��A�h�I��
      (transfer_inf_id                            -- 1.�U�֏��ID
      ,target_date                                -- 2.�Ώ۔N��
      ,business_block                             -- 3.�c�ƃu���b�N
      ,goods_classe                               -- 4.���i�敪
      ,jurisdicyional_hub                         -- 5.�Ǌ����_
      ,area_name                                  -- 6.�n�於
      ,transfe_qty                                -- 7.�U�֐���
      ,transfer_amount                            -- 8.�U�֋��z
      ,restore_amount                             -- 9.�Ҍ����z
      ,shipping_expenses_a                        -- 10.�^����A
      ,shipping_expenses_b                        -- 11.�^����B
      ,shipping_expenses_c                        -- 12.�^����C
      ,etc_amount                                 -- 13.���̑�
      ,created_by                                 -- 14.�쐬��
      ,creation_date                              -- 15.�쐬��
      ,last_updated_by                            -- 16.�ŏI�X�V��
      ,last_update_date                           -- 17.�ŏI�X�V��
      ,last_update_login                          -- 18.�ŏI�X�V���O�C��
      ,request_id                                 -- 19.�v��ID
      ,program_application_id                     -- 20.20.�ݶ��āE��۸��сE���ع����ID
      ,program_id                                 -- 21.�R���J�����g�E�v���O����ID
      ,program_update_date)                       -- 22.�v���O�����X�V��
      VALUES
      (i_trn_inf_id_tab(ln_index)                 -- 1.�U�֏��ID
      ,i_trn_inf_target_date_tab(ln_index)        -- 2.�Ώ۔N��
      ,i_trn_inf_business_block_tab(ln_index)     -- 3.�c�ƃu���b�N
      ,i_trn_inf_goods_classe_tab(ln_index)       -- 4.���i�敪
      ,i_trn_inf_juris_hub_tab(ln_index)          -- 5.�Ǌ����_
      ,i_trn_inf_area_name_tab(ln_index)          -- 6.�n�於
      ,i_trn_inf_transfe_qty_tab(ln_index)        -- 7.�U�֐���
      ,i_trn_inf_transfer_amount_tab(ln_index)    -- 8.�U�֋��z
      ,0                                          -- 9.�Ҍ����z
      ,0                                          -- 10.�^����A
      ,0                                          -- 11.�^����B
      ,0                                          -- 12.�^����C
      ,0                                          -- 13.���̑�
      ,gn_user_id                                 -- 14.�쐬��
      ,gd_sysdate                                 -- 15.�쐬��
      ,gn_user_id                                 -- 16.�ŏI�X�V��
      ,gd_sysdate                                 -- 17.�ŏI�X�V��
      ,gn_login_id                                -- 18.�ŏI�X�V���O�C��
      ,gn_conc_request_id                         -- 19.�v��ID
      ,gn_prog_appl_id                            -- 20.�ݶ��āE��۸��сE���ع����ID
      ,gn_conc_program_id                         -- 21.�R���J�����g�E�v���O����ID
      ,gd_sysdate);                               -- 22.�v���O�����X�V��
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
  END ins_trn_inf_proc;
--
  /**********************************************************************************
   * Procedure Name   : upd_trn_inf_proc
   * Description      : �U�֏��A�h�I���ꊇ�X�V����(C-14)
   ***********************************************************************************/
  PROCEDURE upd_trn_inf_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_trn_inf_proc'; -- �v���O������
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
    -- ***********************
    -- * �U�֏��A�h�I�� �X�V
    -- ***********************
    FORALL ln_index IN u_trn_inf_target_date_tab.FIRST .. u_trn_inf_target_date_tab.LAST
      UPDATE xxwip_transfer_inf xti      -- �U�֏��A�h�I��
      SET    xti.business_block          = u_trn_inf_business_block_tab(ln_index)  -- �c�ƃu���b�N
            ,xti.area_name               = u_trn_inf_area_name_tab(ln_index)       -- �n�於
            ,xti.transfe_qty             = u_trn_inf_transfe_qty_tab(ln_index)     -- �U�֐���
            ,xti.transfer_amount         = u_trn_inf_transfer_amount_tab(ln_index) -- �U�֋��z
            ,xti.last_updated_by        = gn_user_id               -- �ŏI�X�V��
            ,xti.last_update_date       = gd_sysdate               -- �ŏI�X�V��
            ,xti.last_update_login      = gn_login_id              -- �ŏI�X�V���O�C��
            ,xti.request_id             = gn_conc_request_id       -- �v��ID
            ,xti.program_application_id = gn_prog_appl_id          -- �ݶ��āE��۸��сE���ع����ID
            ,xti.program_id             = gn_conc_program_id       -- �R���J�����g�E�v���O����ID
            ,xti.program_update_date    = gd_sysdate               -- �v���O�����X�V��
      WHERE  xti.transfer_inf_id        = u_trn_inf_id_tab(ln_index);
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
  END upd_trn_inf_proc;
--
  /**********************************************************************************
   * Procedure Name   : upd_deliv_ctrl_proc
   * Description      : �^���v�Z�p�R���g���[���X�V����(C-15)
   ***********************************************************************************/
  PROCEDURE upd_deliv_ctrl_proc(
    iv_exchange_type IN         VARCHAR2,     -- �􂢑ւ��敪
    ov_errbuf        OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_deliv_ctrl_proc'; -- �v���O������
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
    -- ���̓p�����[�^.�􂢑ւ��敪 = �uNO�v�̏ꍇ
    IF (iv_exchange_type = gv_ktg_no) THEN
--
      -- �^���v�Z�p�R���g���[���̑O�񏈗����t���X�V
      UPDATE xxwip_deliverys_ctrl xdc   -- �^���v�Z�p�R���g���[���A�h�I��
      SET    xdc.last_process_date      = gd_sysdate         -- �O�񏈗����t
            ,xdc.last_updated_by        = gn_user_id         -- �ŏI�X�V��
            ,xdc.last_update_date       = gd_sysdate         -- �ŏI�X�V��
            ,xdc.last_update_login      = gn_login_id        -- �ŏI�X�V���O�C��
            ,xdc.request_id             = gn_conc_request_id -- �v��ID
            ,xdc.program_application_id = gn_prog_appl_id    -- �ݶ��āE��۸��сE���ع����ID
            ,xdc.program_id             = gn_conc_program_id -- �R���J�����g�E�v���O����ID
            ,xdc.program_update_date    = gd_sysdate         -- �v���O�����X�V��
-- ##### 20081017 Ver.1.8 T_S_465�Ή� start #####
--      WHERE  xdc.concurrent_no          = gv_con_no_deli;
      WHERE  xdc.concurrent_no          = gv_concurrent_no;   -- �R���J�����gNO
-- ##### 20081017 Ver.1.8 T_S_465�Ή� end   #####
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
  END upd_deliv_ctrl_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_exchange_type  IN         VARCHAR2,     -- �􂢑ւ��敪
-- ##### 20081017 Ver.1.8 T_S_465�Ή� start #####
    iv_prod_div       IN         VARCHAR2,     -- ���i�敪
-- ##### 20081017 Ver.1.8 T_S_465�Ή� end   #####
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- =========================================
    -- �p�����[�^�`�F�b�N����(C-1)
    -- =========================================
    chk_param_proc(
      iv_exchange_type,  -- �􂢑ւ��敪
-- ##### 20081017 Ver.1.8 T_S_465�Ή� start #####
      iv_prod_div,       -- ���i�敪
-- ##### 20081017 Ver.1.8 T_S_465�Ή� end   #####
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- �֘A�f�[�^�擾(C-2)
    -- =========================================
    get_init(
      iv_exchange_type,  -- �􂢑ւ��敪
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- �󒍃f�[�^���o����(C-3)
    -- =========================================
    get_order_proc(
      iv_exchange_type,  -- �􂢑ւ��敪
      lv_target_flg,     -- �Ώۃf�[�^�L���t���O
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ���o�f�[�^��1���ȏ㑶�݂���ꍇ�͈ȉ��̏������s��
    IF (lv_target_flg = '1') THEN
--
      -- =========================================
      -- �U�։^�����A�h�I���f�[�^�ݒ�(C-4)
      -- =========================================
      set_trn(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �U�։^�����A�h�I���ꊇ�o�^����(C-5)
      -- =========================================
      ins_trn_proc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �U�։^�����A�h�I���ꊇ�X�V����(C-6)
      -- =========================================
      upd_trn_proc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �U�։^�����A�h�I�������ݒ�
      gn_order_inf_cnt := gn_ins_order_inf_cnt + gn_upd_order_inf_cnt;
--
      -- =========================================
      -- �U�։^�����A�h�I�����o����(C-7)
      -- =========================================
      get_trn_proc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �U�։^�����T�}���[�A�h�I���f�[�^�ݒ�(C-8)
      -- =========================================
      set_trn_sum(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �U�։^�����T�}���[�A�h�I���ꊇ�o�^����(C-9)
      -- =========================================
      ins_trn_sum_proc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �U�։^�����T�}���[�A�h�I���ꊇ�X�V����(C-10)
      -- =========================================
      upd_trn_sum_proc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �U�։^�����T�}���[�A�h�I�������ݒ�
      gn_order_sum_cnt := gn_ins_order_sum_cnt + gn_upd_order_sum_cnt;
--
      -- =========================================
      -- �U�։^�����T�}���[�A�h�I�����o����(C-11)
      -- =========================================
      get_trn_sum_proc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �U�֏��A�h�I���f�[�^�ݒ�(C-12)
      -- =========================================
      set_trn_inf(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �U�֏��A�h�I���ꊇ�o�^����(C-13)
      -- =========================================
      ins_trn_inf_proc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �U�֏��A�h�I���ꊇ�X�V����(C-14)
      -- =========================================
      upd_trn_inf_proc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �U�֏��A�h�I�������ݒ�
      gn_trans_inf_cnt := gn_ins_trans_inf_cnt + gn_upd_trans_inf_cnt;
--
      -- =========================================
      -- �^���v�Z�p�R���g���[���X�V����(C-15)
      -- =========================================
      upd_deliv_ctrl_proc(
        iv_exchange_type,  -- �􂢑ւ��敪
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
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
    iv_exchange_type  IN         VARCHAR2,      --   ���֋敪
-- ##### 20081017 Ver.1.8 T_S_465�Ή� start #####
    iv_prod_div       IN         VARCHAR2       --   ���i�敪
-- ##### 20081017 Ver.1.8 T_S_465�Ή� end   #####
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
      iv_exchange_type,  -- �􂢑ւ��敪
-- ##### 20081017 Ver.1.8 T_S_465�Ή� start #####
      iv_prod_div,       -- ���i�敪
-- ##### 20081017 Ver.1.8 T_S_465�Ή� end   #####
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
--2008/09/22 Add ��
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;   --��؂蕶����o��
    -------------------------------------------------------
    -- ���̓p�����[�^
    -------------------------------------------------------
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '���̓p�����[�^' );
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '���֋敪�F' || iv_exchange_type ) ;
-- ##### 20081017 Ver.1.8 T_S_465�Ή� start #####
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '���i�敪�F' || iv_prod_div ) ;
-- ##### 20081017 Ver.1.8 T_S_465�Ή� end   #####
--2008/09/22 Add ��
--
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- =========================================
    -- ���b�Z�[�W�o��(C-16)
    -- =========================================
    -- 1.�U�։^�����A�h�I�������������b�Z�[�W
    lv_message := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn, gv_wip_msg_75c_005);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- 2.���������o��
    lv_message := xxcmn_common_pkg.get_msg(gv_cmn_msg_kbn, gv_cmn_msg_75c_009,
                                           gv_tkn_cnt,
                                           TO_CHAR(gn_order_inf_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- 3.�U�։^�����T�}���[�A�h�I�������������b�Z�[�W
    lv_message := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn, gv_wip_msg_75c_008);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- 4.���������o��
    lv_message := xxcmn_common_pkg.get_msg(gv_cmn_msg_kbn, gv_cmn_msg_75c_009,
                                           gv_tkn_cnt,
                                           TO_CHAR(gn_order_sum_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- 5.�U�֏��A�h�I�������������b�Z�[�W
    lv_message := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn, gv_wip_msg_75c_006);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- 6.���������o��
    lv_message := xxcmn_common_pkg.get_msg(gv_cmn_msg_kbn, gv_cmn_msg_75c_009,
                                           gv_tkn_cnt,
                                           TO_CHAR(gn_trans_inf_cnt));
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
END xxwip750001c;
/
