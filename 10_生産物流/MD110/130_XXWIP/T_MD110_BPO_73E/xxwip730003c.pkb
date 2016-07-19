CREATE OR REPLACE PACKAGE BODY xxwip730003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip730003c(body)
 * Description      : �^���A�h�I���C���^�t�F�[�X�捞����
 * MD.050           : �^���v�Z�i�g�����U�N�V�����j       T_MD050_BPO_732
 * MD.070           : �^���A�h�I���C���^�t�F�[�X�捞���� T_MD070_BPO_73E
 * Version          : 1.8
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_related_date       �֘A�f�[�^�擾(E-1)
 *  get_lock               ���b�N�擾(E-2)
 *  get_deliv_if_date      �^���A�h�I���C���^�t�F�[�X�f�[�^�擾(E-3)
 *  chk_object             �X�V�Ώۃ`�F�b�N(E-4)
 *  get_deliv_cal_date     �^���v�Z�p�f�[�^�擾(E-5)
 *  set_date               �f�[�^�ݒ�(E-6)
 *  upd_deliv_head         �^���w�b�_�[�A�h�I���X�V(E-7)
 *  del_deliv_head         �^���w�b�_�[�A�h�I���폜(E-8)
 *  del_deliv_if           �^���A�h�I���C���^�t�F�[�X�폜(E-9)
 *  out_message            ���b�Z�[�W�o��(E-10)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/07    1.0  Oracle �a�c ��P  ����쐬
 *  2008/05/13    1.1  Oracle �Ŗ� ���\  �����ύX�v��#85�Ή�
 *  2008/05/26    1.2  Oracle �쑺 ���K  ������Q 
 *  2008/07/10    1.3  Oracle �쑺 ���K  ST��Q #432 �Ή�
 *  2008/07/25    1.4  Oracle �쑺 ���K  ST��Q #473 �Ή�
 *  2008/09/16    1.5  Oracle �g�c �Ď�  T_S_570 �Ή�
 *  2008/12/01    1.6  Oracle �쑺 ���K  �{��#303�Ή�
 *  2009/03/03    1.7  �쑺 ���K         �{��#1239�Ή�
 *  2016/06/24    1.8  S.Niki            E_�{�ғ�_13659�Ή�
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
  gn_normal_cnt    NUMBER;                    -- �X�V����
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
    lock_expt                  EXCEPTION;  -- ���b�N�擾��O
--
    PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(100) := 'xxwip730003c'; -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  gv_wip_msg_kbn          CONSTANT VARCHAR2(5) := 'XXWIP';
--
  -- ���b�Z�[�W�ԍ�(XXWIP)
  gv_wip_msg_73e_005      CONSTANT VARCHAR2(15) := 'APP-XXWIP-10067'; -- �v���t�@�C���擾�G���[
  gv_wip_msg_73e_004      CONSTANT VARCHAR2(15) := 'APP-XXWIP-10004'; -- ���b�N�G���[�ڍ׃��b�Z�[�W
  gv_wip_msg_73e_306      CONSTANT VARCHAR2(15) := 'APP-XXWIP-30006'; -- �ۗ����Ԍo�߃��b�Z�[�W
  gv_wip_msg_73e_305      CONSTANT VARCHAR2(15) := 'APP-XXWIP-30005'; -- �z���敪���݂Ȃ����b�Z�[�W
  gv_wip_msg_73e_304      CONSTANT VARCHAR2(15) := 'APP-XXWIP-30004'; -- �^���X�V�s�\���b�Z�[�W
--
  -- �g�[�N��
  gv_tkn_ng_profile       CONSTANT VARCHAR2(10) := 'NG_PROFILE';
  gv_tkn_table            CONSTANT VARCHAR2(5)  := 'TABLE';
--
  -- �g�[�N���l
  gv_reserve_period_name  CONSTANT VARCHAR2(30) := '�^���f�[�^�ۗ�����';
  gv_deliv_if_name        CONSTANT VARCHAR2(30) := '�^���A�h�I���C���^�t�F�[�X';
  gv_deliv_head_name      CONSTANT VARCHAR2(30) := '�^���w�b�_�[�A�h�I��';
--
  -- �v���t�@�C���E�I�v�V����
  gv_reserve_period    CONSTANT VARCHAR2(20) := 'XXWIP_RESERVE_PERIOD';       -- �^���f�[�^�ۗ�����
--
  gv_ktg_yes           CONSTANT VARCHAR2(1)   := 'Y';
  gv_ktg_no            CONSTANT VARCHAR2(1)   := 'N';
--
  gv_tbl_n_deliv_if    CONSTANT VARCHAR2(18) := 'XXWIP_DELIVERYS_IF'; -- �^���A�h�I���C���^�t�F�[�X
  gv_tbl_n_deliv_head  CONSTANT VARCHAR2(15) := 'XXWIP_DELIVERYS';    -- �^���w�b�_�[�A�h�I��
--
  -- �Q�ƃ^�C�v�E�R�[�h
  gv_lu_cd_ship_method CONSTANT VARCHAR2(17) := 'XXCMN_SHIP_METHOD';  -- �z���敪
--
  gv_ptn_out           CONSTANT VARCHAR2(1) := '1';                   -- �O���p
  gv_ptn_it            CONSTANT VARCHAR2(1) := '2';                   -- �ɓ����Y�Ɨp
  -- �x�������敪
  gv_p_b_cls_pay       CONSTANT VARCHAR2(1) := '1';                   -- �x��
  gv_p_b_cls_bil       CONSTANT VARCHAR2(1) := '2';                   -- ����
-- ##### Ver.1.8 E_�{�ғ�_13659�Ή� START #####
  -- �_�~�[
  gv_dummy             CONSTANT VARCHAR2(1) := 'X';                   -- �_�~�[
-- ##### Ver.1.8 E_�{�ғ�_13659�Ή� END   #####
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �^���A�h�I���C���^�t�F�[�X�Ɋi�[���郌�R�[�h
  TYPE deliv_if_rec IS RECORD(
    delivery_id            xxwip_deliverys_if.delivery_id%TYPE,            -- 1.�^���A�h�I��ID
    pattern_flag           xxwip_deliverys_if.pattern_flag%TYPE,           -- 2.�p�^�[���敪
    delivery_company_code  xxwip_deliverys_if.delivery_company_code%TYPE,  -- 3.�^���Ǝ�
    delivery_no            xxwip_deliverys_if.delivery_no%TYPE,            -- 4.�z��No
    invoice_no             xxwip_deliverys_if.invoice_no%TYPE,             -- 5.�����No
    p_b_classe             xxwip_deliverys_if.p_b_classe%TYPE,             -- 6.�x�������敪
    delivery_classe        xxwip_deliverys_if.delivery_classe%TYPE,        -- 7.�z���敪
    charged_amount         xxwip_deliverys_if.charged_amount%TYPE,         -- 8.�����^��
    qty1                   xxwip_deliverys_if.qty1%TYPE,                   -- 9.��1
    qty2                   xxwip_deliverys_if.qty2%TYPE,                   -- 10.��2
    delivery_weight1       xxwip_deliverys_if.delivery_weight1%TYPE,       -- 11.�d��1
    delivery_weight2       xxwip_deliverys_if.delivery_weight2%TYPE,       -- 12.�d��2
    distance               xxwip_deliverys_if.distance%TYPE,               -- 13.����
    many_rate              xxwip_deliverys_if.many_rate%TYPE,              -- 14.������
    congestion_charge      xxwip_deliverys_if.congestion_charge%TYPE,      -- 15.�ʍs��
    picking_charge         xxwip_deliverys_if.picking_charge%TYPE,         -- 16.�s�b�L���O��
    consolid_surcharge     xxwip_deliverys_if.consolid_surcharge%TYPE,     -- 17.���ڊ������z
    total_amount           xxwip_deliverys_if.total_amount%TYPE,           -- 18.���v
    creation_date          xxwip_deliverys_if.creation_date%TYPE,          -- 19.�쐬��
    last_update_date       xxwip_deliverys_if.last_update_date%TYPE        -- 20.�ŏI�X�V��
  );
--
  -- �^���w�b�_�[�A�h�I���Ɋi�[���郌�R�[�h
  TYPE deliv_head_rec IS RECORD(
    deliverys_header_id   xxwip_deliverys.deliverys_header_id%TYPE,     -- 1.�^���w�b�_�[�A�h�I��ID
    delivery_company_code xxwip_deliverys.delivery_company_code%TYPE,   -- 2.�^���Ǝ�
    delivery_no           xxwip_deliverys.delivery_no%TYPE,             -- 3.�z��No
-- ##### 20080916 Ver.1.5 T_S_570�Ή� START #####
    --invoice_no            xxwip_deliverys.invoice_no%TYPE,              -- 4.�����No
    invoice_no2           xxwip_deliverys.invoice_no2%TYPE,              -- 4.�����No2
-- ##### 20080916 Ver.1.5 T_S_570�Ή� END #####
    p_b_classe            xxwip_deliverys.p_b_classe%TYPE,              -- 5.�x�������敪
    report_date           xxwip_deliverys.report_date%TYPE,             -- 6.�񍐓�
    judgement_date        xxwip_deliverys.judgement_date%TYPE,          -- 7.���f��
    goods_classe          xxwip_deliverys.goods_classe%TYPE,            -- 8.���i�敪
    charged_amount        xxwip_deliverys.charged_amount%TYPE,          -- 9.�����^��
    contract_rate         xxwip_deliverys.contract_rate%TYPE,           --   �_��^��
    balance               xxwip_deliverys.balance%TYPE,                 -- 10.���z
    total_amount          xxwip_deliverys.total_amount%TYPE,            -- 11.���v
    many_rate             xxwip_deliverys.many_rate%TYPE,               -- 12.������
    distance              xxwip_deliverys.distance%TYPE,                -- 13.�Œ�����
    delivery_classe       xxwip_deliverys.delivery_classe%TYPE,         -- 14.�z���敪
    qty1                  xxwip_deliverys.qty1%TYPE,                    -- 15.��1
    qty2                  xxwip_deliverys.qty2%TYPE,                    -- 16.��2
    delivery_weight1      xxwip_deliverys.delivery_weight1%TYPE,        -- 17.�d��1
    delivery_weight2      xxwip_deliverys.delivery_weight2%TYPE,        -- 18.�d��2
    consolid_surcharge    xxwip_deliverys.consolid_surcharge%TYPE,      -- 19.���ڊ������z
    congestion_charge     xxwip_deliverys.congestion_charge%TYPE,       -- 20.�ʍs��
    picking_charge        xxwip_deliverys.picking_charge%TYPE,          -- 21.�s�b�L���O��
    consolid_qty          xxwip_deliverys.consolid_qty%TYPE,            -- 22.���ڐ�
    output_flag           xxwip_deliverys.output_flag%TYPE,             -- 23.���ً敪
    defined_flag          xxwip_deliverys.defined_flag%TYPE,            -- 24.�x���m��敪
    return_flag           xxwip_deliverys.return_flag%TYPE,             -- 25.�x���m���
    form_update_flag      xxwip_deliverys.form_update_flag%TYPE,        -- 26.��ʍX�V�L���敪
    outside_up_count      xxwip_deliverys.outside_up_count%TYPE         -- 27.�O���ƎҕύX��
  );
--
  -- �^���A�h�I���}�X�^�Ɋi�[���郌�R�[�h
  gr_deliv_charges        xxwip_common3_pkg.delivery_charges_rec;
--
  -- �^���p�^���Ǝ҃A�h�I���}�X�^�Ɋi�[���郌�R�[�h
  TYPE delivery_company IS RECORD(
    pay_picking_amount    xxwip_delivery_company.pay_picking_amount%TYPE,  -- 1.�x���s�b�L���O�P��
    bill_picking_amount   xxwip_delivery_company.bill_picking_amount%TYPE  -- 2.�����s�b�L���O�P��
  );
--
  gr_deliv_company        delivery_company;
--
  -- PL/SQL�\
  TYPE deliv_if_tbl       IS TABLE OF deliv_if_rec   INDEX BY PLS_INTEGER;
  TYPE deliv_head_tbl     IS TABLE OF deliv_head_rec INDEX BY PLS_INTEGER;
  gt_deliv_if_tbl         deliv_if_tbl;       -- �^���A�h�I���C���^�t�F�[�X(�擾�p)
  gt_deliv_head_tbl       deliv_head_tbl;     -- �^���w�b�_�[�A�h�I��(�擾�p)
--
--
  -- *******************************************************
  -- * �^���A�h�I���C���^�t�F�[�X
  -- *******************************************************
  -- �폜�pPL/SQL�\�^
  -- �^���A�h�I��ID
  TYPE d_deliv_if_id_type IS TABLE OF xxwip_deliverys_if.delivery_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- �p�^�[���敪
  TYPE d_deliv_if_ptn_flg_type IS TABLE OF xxwip_deliverys_if.pattern_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- �^���Ǝ�
  TYPE d_deliv_if_com_cd_type IS TABLE OF xxwip_deliverys_if.delivery_company_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- �z��No
  TYPE d_deliv_if_no_type IS TABLE OF xxwip_deliverys_if.delivery_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- �����No
  TYPE d_deliv_if_invoice_no_type IS TABLE OF xxwip_deliverys_if.invoice_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- �x�������敪
  TYPE d_deliv_if_p_b_cls_type IS TABLE OF xxwip_deliverys_if.p_b_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- �z���敪
  TYPE d_deliv_if_deliv_cls_type IS TABLE OF xxwip_deliverys_if.delivery_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- �����^��
  TYPE d_deliv_if_chrg_amt_type IS TABLE OF xxwip_deliverys_if.charged_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- ��1
  TYPE d_deliv_if_qty1_type IS TABLE OF xxwip_deliverys_if.qty1%TYPE
  INDEX BY BINARY_INTEGER;
  -- ��2
  TYPE d_deliv_if_qty2_type IS TABLE OF xxwip_deliverys_if.qty2%TYPE
  INDEX BY BINARY_INTEGER;
  -- �d��1
  TYPE d_deliv_if_deliv_wht1_type IS TABLE OF xxwip_deliverys_if.delivery_weight1%TYPE
  INDEX BY BINARY_INTEGER;
  -- �d��2
  TYPE d_deliv_if_deliv_wht2_type IS TABLE OF xxwip_deliverys_if.delivery_weight2%TYPE
  INDEX BY BINARY_INTEGER;
  -- ����
  TYPE d_deliv_if_distance_type IS TABLE OF xxwip_deliverys_if.distance%TYPE
  INDEX BY BINARY_INTEGER;
  -- ������
  TYPE d_deliv_if_many_rt_type IS TABLE OF xxwip_deliverys_if.many_rate%TYPE
  INDEX BY BINARY_INTEGER;
  -- �ʍs��
  TYPE d_deliv_if_cng_chrg_type IS TABLE OF xxwip_deliverys_if.congestion_charge%TYPE
  INDEX BY BINARY_INTEGER;
  -- �s�b�L���O��
  TYPE d_deliv_if_pic_chrg_type IS TABLE OF xxwip_deliverys_if.picking_charge%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���ڊ������z
  TYPE d_deliv_if_cns_srchrg_type IS TABLE OF xxwip_deliverys_if.consolid_surcharge%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���v
  TYPE d_deliv_if_ttl_amt_type IS TABLE OF xxwip_deliverys_if.total_amount%TYPE
  INDEX BY BINARY_INTEGER;
--
  -- �폜�p�^���A�h�I���C���^�t�F�[�X��PL/SQL�\
  d_deliv_if_id_tab            d_deliv_if_id_type;           -- �^���A�h�I��ID
--
  -- �z���敪�`�F�b�N�pPL/SQL�\
  d_deliv_cls_id_tab           d_deliv_if_id_type;           -- �^���A�h�I��ID
  d_deliv_cls_ptn_flg_tab      d_deliv_if_ptn_flg_type;      -- �p�^�[���敪
  d_deliv_cls_com_cd_tab       d_deliv_if_com_cd_type;       -- �^���Ǝ�
  d_deliv_cls_no_tab           d_deliv_if_no_type;           -- �z��No
  d_deliv_cls_invoice_no_tab   d_deliv_if_invoice_no_type;   -- �����No
  d_deliv_cls_p_b_cls_tab      d_deliv_if_p_b_cls_type;      -- �x�������敪
  d_deliv_cls_deliv_cls_tab    d_deliv_if_deliv_cls_type;    -- �z���敪
  d_deliv_cls_chrg_amt_tab     d_deliv_if_chrg_amt_type;     -- �����^��
  d_deliv_cls_qty1_tab         d_deliv_if_qty1_type;         -- ��1
  d_deliv_cls_qty2_tab         d_deliv_if_qty2_type;         -- ��2
  d_deliv_cls_deliv_wht1_tab   d_deliv_if_deliv_wht1_type;   -- �d��1
  d_deliv_cls_deliv_wht2_tab   d_deliv_if_deliv_wht2_type;   -- �d��2
  d_deliv_cls_distance_tab     d_deliv_if_distance_type;     -- ����
  d_deliv_cls_many_rt_tab      d_deliv_if_many_rt_type;      -- ������
  d_deliv_cls_cng_chrg_tab     d_deliv_if_cng_chrg_type;     -- �ʍs��
  d_deliv_cls_pic_chrg_tab     d_deliv_if_pic_chrg_type;     -- �s�b�L���O��
  d_deliv_cls_cns_srchrg_tab   d_deliv_if_cns_srchrg_type;   -- ���ڊ������z
  d_deliv_cls_ttl_amt_tab      d_deliv_if_ttl_amt_type;      -- ���v
--
  -- �ۗ����Ԍo�߃`�F�b�N�pPL/SQL�\
  d_rsv_prd_id_tab           d_deliv_if_id_type;           -- �^���A�h�I��ID
  d_rsv_prd_ptn_flg_tab      d_deliv_if_ptn_flg_type;      -- �p�^�[���敪
  d_rsv_prd_com_cd_tab       d_deliv_if_com_cd_type;       -- �^���Ǝ�
  d_rsv_prd_no_tab           d_deliv_if_no_type;           -- �z��No
  d_rsv_prd_invoice_no_tab   d_deliv_if_invoice_no_type;   -- �����No
  d_rsv_prd_p_b_cls_tab      d_deliv_if_p_b_cls_type;      -- �x�������敪
  d_rsv_prd_deliv_cls_tab    d_deliv_if_deliv_cls_type;    -- �z���敪
  d_rsv_prd_chrg_amt_tab     d_deliv_if_chrg_amt_type;     -- �����^��
  d_rsv_prd_qty1_tab         d_deliv_if_qty1_type;         -- ��1
  d_rsv_prd_qty2_tab         d_deliv_if_qty2_type;         -- ��2
  d_rsv_prd_deliv_wht1_tab   d_deliv_if_deliv_wht1_type;   -- �d��1
  d_rsv_prd_deliv_wht2_tab   d_deliv_if_deliv_wht2_type;   -- �d��2
  d_rsv_prd_distance_tab     d_deliv_if_distance_type;     -- ����
  d_rsv_prd_many_rt_tab      d_deliv_if_many_rt_type;      -- ������
  d_rsv_prd_cng_chrg_tab     d_deliv_if_cng_chrg_type;     -- �ʍs��
  d_rsv_prd_pic_chrg_tab     d_deliv_if_pic_chrg_type;     -- �s�b�L���O��
  d_rsv_prd_cns_srchrg_tab   d_deliv_if_cns_srchrg_type;   -- ���ڊ������z
  d_rsv_prd_ttl_amt_tab      d_deliv_if_ttl_amt_type;      -- ���v
--
  -- �X�V�s�\�pPL/SQL�\
  d_not_upd_id_tab           d_deliv_if_id_type;           -- �^���A�h�I��ID
  d_not_upd_ptn_flg_tab      d_deliv_if_ptn_flg_type;      -- �p�^�[���敪
  d_not_upd_com_cd_tab       d_deliv_if_com_cd_type;       -- �^���Ǝ�
  d_not_upd_no_tab           d_deliv_if_no_type;           -- �z��No
  d_not_upd_invoice_no_tab   d_deliv_if_invoice_no_type;   -- �����No
  d_not_upd_p_b_cls_tab      d_deliv_if_p_b_cls_type;      -- �x�������敪
  d_not_upd_deliv_cls_tab    d_deliv_if_deliv_cls_type;    -- �z���敪
  d_not_upd_chrg_amt_tab     d_deliv_if_chrg_amt_type;     -- �����^��
  d_not_upd_qty1_tab         d_deliv_if_qty1_type;         -- ��1
  d_not_upd_qty2_tab         d_deliv_if_qty2_type;         -- ��2
  d_not_upd_deliv_wht1_tab   d_deliv_if_deliv_wht1_type;   -- �d��1
  d_not_upd_deliv_wht2_tab   d_deliv_if_deliv_wht2_type;   -- �d��2
  d_not_upd_distance_tab     d_deliv_if_distance_type;     -- ����
  d_not_upd_many_rt_tab      d_deliv_if_many_rt_type;      -- ������
  d_not_upd_cng_chrg_tab     d_deliv_if_cng_chrg_type;     -- �ʍs��
  d_not_upd_pic_chrg_tab     d_deliv_if_pic_chrg_type;     -- �s�b�L���O��
  d_not_upd_cns_srchrg_tab   d_deliv_if_cns_srchrg_type;   -- ���ڊ������z
  d_not_upd_ttl_amt_tab      d_deliv_if_ttl_amt_type;      -- ���v
--
  -- *******************************************************
  -- * �^���w�b�_�[�A�h�I��
  -- *******************************************************
  -- �X�V�pPL/SQL�\�^
  -- �^���Ǝ�
  TYPE u_deliv_head_com_code_id_type IS TABLE OF xxwip_deliverys.delivery_company_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- �z��No
  TYPE u_deliv_head_deliv_no_type IS TABLE OF xxwip_deliverys.delivery_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- �����No
-- ##### 20080916 Ver.1.5 T_S_570�Ή� START #####
  --TYPE u_deliv_head_invoice_no_type IS TABLE OF xxwip_deliverys.invoice_no%TYPE
  TYPE u_deliv_head_invoice_no_type IS TABLE OF xxwip_deliverys.invoice_no2%TYPE
-- ##### 20080916 Ver.1.5 T_S_570�Ή� END #####
  INDEX BY BINARY_INTEGER;
  -- �x�������敪
  TYPE u_deliv_head_p_b_cls_type IS TABLE OF xxwip_deliverys.p_b_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- �񍐓�
  TYPE u_deliv_head_rpt_date_type IS TABLE OF xxwip_deliverys.report_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- �z���敪
  TYPE u_deliv_head_deliv_cls_type IS TABLE OF xxwip_deliverys.delivery_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- �����^��
  TYPE u_deliv_head_chrg_amt_type IS TABLE OF xxwip_deliverys.charged_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- �_��^��
  TYPE u_deliv_head_con_rate_type IS TABLE OF xxwip_deliverys.contract_rate%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���z
  TYPE u_deliv_head_balance_type IS TABLE OF xxwip_deliverys.balance%TYPE
  INDEX BY BINARY_INTEGER;
  -- ��1
  TYPE u_deliv_head_qty1_type IS TABLE OF xxwip_deliverys.qty1%TYPE
  INDEX BY BINARY_INTEGER;
  -- ��2
  TYPE u_deliv_head_qty2_type IS TABLE OF xxwip_deliverys.qty2%TYPE
  INDEX BY BINARY_INTEGER;
  -- �d��1
  TYPE u_deliv_head_deliv_wht1_type IS TABLE OF xxwip_deliverys.delivery_weight1%TYPE
  INDEX BY BINARY_INTEGER;
  -- �d��2
  TYPE u_deliv_head_deliv_wht2_type IS TABLE OF xxwip_deliverys.delivery_weight2%TYPE
  INDEX BY BINARY_INTEGER;
  -- ����
  TYPE u_deliv_head_dst_type IS TABLE OF xxwip_deliverys.distance%TYPE
  INDEX BY BINARY_INTEGER;
  -- ������
  TYPE u_deliv_head_many_rt_type IS TABLE OF xxwip_deliverys.many_rate%TYPE
  INDEX BY BINARY_INTEGER;
  -- �ʍs��
  TYPE u_deliv_head_cng_chrg_type IS TABLE OF xxwip_deliverys.congestion_charge%TYPE
  INDEX BY BINARY_INTEGER;
  -- �s�b�L���O��
  TYPE u_deliv_head_pic_chrg_type IS TABLE OF xxwip_deliverys.picking_charge%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���ڊ������z
  TYPE u_deliv_head_cns_srchrg_type IS TABLE OF xxwip_deliverys.consolid_surcharge%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���v
  TYPE u_deliv_head_ttl_amt_type IS TABLE OF xxwip_deliverys.total_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���ً敪
  TYPE u_deliv_head_op_flg_type IS TABLE OF xxwip_deliverys.output_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- �x���m��敪
  TYPE u_deliv_head_dfn_flg_type IS TABLE OF xxwip_deliverys.defined_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- �x���m���
  TYPE u_deliv_head_rtrn_flg_type IS TABLE OF xxwip_deliverys.return_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- ��ʍX�V�L���敪
  TYPE u_deliv_head_frm_upd_flg_type IS TABLE OF xxwip_deliverys.form_update_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- �O���ƎҕύX��
  TYPE u_deliv_head_os_up_cnt_type IS TABLE OF xxwip_deliverys.outside_up_count%TYPE
  INDEX BY BINARY_INTEGER;
--
  u_deliv_head_com_code_id_tab   u_deliv_head_com_code_id_type;   -- �^���Ǝ�
  u_deliv_head_deliv_no_tab      u_deliv_head_deliv_no_type;      -- �z��No
  u_deliv_head_invoice_no_tab    u_deliv_head_invoice_no_type;    -- �����No2
  u_deliv_head_p_b_cls_tab       u_deliv_head_p_b_cls_type;       -- �x�������敪
  u_deliv_head_rpt_date_tab      u_deliv_head_rpt_date_type;      -- �񍐓�
  u_deliv_head_deliv_cls_tab     u_deliv_head_deliv_cls_type;     -- �z���敪
  u_deliv_head_chrg_amt_tab      u_deliv_head_chrg_amt_type;      -- �����^��
  u_deliv_head_con_rate_tab      u_deliv_head_con_rate_type;      -- �_��^��
  u_deliv_head_balance_tab       u_deliv_head_balance_type;       -- ���z
  u_deliv_head_qty1_tab          u_deliv_head_qty1_type;          -- ��1
  u_deliv_head_qty2_tab          u_deliv_head_qty2_type;          -- ��2
  u_deliv_head_deliv_wht1_tab    u_deliv_head_deliv_wht1_type;    -- �d��1
  u_deliv_head_deliv_wht2_tab    u_deliv_head_deliv_wht2_type;    -- �d��2
  u_deliv_head_dst_tab           u_deliv_head_dst_type;           -- ����
  u_deliv_head_many_rt_tab       u_deliv_head_many_rt_type;       -- ������
  u_deliv_head_cng_chrg_tab      u_deliv_head_cng_chrg_type;      -- �ʍs��
  u_deliv_head_pic_chrg_tab      u_deliv_head_pic_chrg_type;      -- �s�b�L���O��
  u_deliv_head_cns_srchrg_tab    u_deliv_head_cns_srchrg_type;    -- ���ڊ������z
  u_deliv_head_ttl_amt_tab       u_deliv_head_ttl_amt_type;       -- ���v
  u_deliv_head_op_flg_tab        u_deliv_head_op_flg_type;        -- ���ً敪
  u_deliv_head_dfn_flg_tab       u_deliv_head_dfn_flg_type;       -- �x���m��敪
  u_deliv_head_rtrn_flg_tab      u_deliv_head_rtrn_flg_type;      -- �x���m���
  u_deliv_head_frm_upd_flg_tab   u_deliv_head_frm_upd_flg_type;   -- ��ʍX�V�L���敪
  u_deliv_head_os_up_cnt_tab     u_deliv_head_os_up_cnt_type;     -- �O���ƎҕύX��
--
  -- �����f�[�^�폜�pPL/SQL�\
  -- �z��No
  TYPE d_bil_deliv_no_type IS TABLE OF xxwip_deliverys.delivery_no%TYPE
  INDEX BY BINARY_INTEGER;
  d_bil_deliv_no_tab       d_bil_deliv_no_type;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gd_sysdate               DATE;            -- �V�X�e�����t
  gn_user_id               NUMBER;          -- ���[�UID
  gn_login_id              NUMBER;          -- ���O�C��ID
  gn_conc_request_id       NUMBER;          -- �R���J�����g�v��ID
  gn_prog_appl_id          NUMBER;          -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  gn_conc_program_id       NUMBER;          -- �R���J�����g�E�v���O����ID
--
  -- �v���t�@�C���E�I�v�V����
  gn_wip_reserve_period    NUMBER;          -- �^���f�[�^�ۗ�����
--
  gv_target_type           VARCHAR2(1);     -- �����敪(Y:���ߓ��O�AN:���ߓ���)
--
  gn_deliv_head_cnt        NUMBER;          -- �^���w�b�_�[�A�h�I���pPL/SQL�\�J�E���^�[
  gn_upd_deliv_head_cnt    NUMBER;          -- �X�V�p�^���w�b�_�[�A�h�I���pPL/SQL�\�J�E���^�[
  gn_deliv_cls_cnt         NUMBER;          -- �z���敪�`�F�b�N�pPL/SQL�\�J�E���^�[
  gn_rsv_prd_cnt           NUMBER;          -- �ۗ����Ԍo�߃`�F�b�N�pPL/SQL�\�J�E���^�[
  gn_not_upd_cnt           NUMBER;          -- �X�V�s�\�pPL/SQL�\�J�E���^�[
  gn_bil_deliv_no_cnt      NUMBER;          -- �����f�[�^�폜�pPL/SQL�\�J�E���^�[
  gn_deliv_if_del_cnt      NUMBER;          -- �폜�p�^���A�h�I���C���^�t�F�[�X�J�E���^�[
--
-- ##### Ver.1.8 E_�{�ғ�_13659�Ή� START #####
  gv_prod_div              VARCHAR2(1);     -- ���i�敪
-- ##### Ver.1.8 E_�{�ғ�_13659�Ή� END   #####
--
  /**********************************************************************************
   * Procedure Name   : get_related_date
   * Description      : �֘A�f�[�^�擾(E-1)
   ***********************************************************************************/
  PROCEDURE get_related_date(
-- ##### Ver.1.8 E_�{�ғ�_13659�Ή� START #####
    iv_prod_div   IN  VARCHAR2,     --   ���i�敪
-- ##### Ver.1.8 E_�{�ғ�_13659�Ή� END   #####
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_related_date'; -- �v���O������
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
    lv_orgn_code      sy_orgn_mst.orgn_code%TYPE;   -- �g�D
    ln_grace_period   NUMBER;                       -- �^���v�Z�p�P�\����
    ld_close_date     DATE;                         -- �N���[�Y���t
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
    gn_user_id          := FND_GLOBAL.USER_ID;         -- ���[�UID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;        -- ���O�C��ID
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID; -- �R���J�����g�v��ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;    -- �ݶ��āE��۸��сE���ع����ID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID; -- �R���J�����g�E�v���O����ID
--
-- ##### Ver.1.8 E_�{�ғ�_13659�Ή� START #####
    -- ���͍���.���i�敪���O���[�o���ϐ��Ɋi�[
    gv_prod_div         := iv_prod_div;                -- ���i�敪
-- ##### Ver.1.8 E_�{�ғ�_13659�Ή� END   #####
--
    -- ***********************************************
    -- �v���t�@�C���F�^���f�[�^�ۗ����� �擾
    -- ***********************************************
    gn_wip_reserve_period := FND_PROFILE.VALUE(gv_reserve_period);
--
    IF (gn_wip_reserve_period IS NULL) THEN -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn,
                                            gv_wip_msg_73e_005,
                                            gv_tkn_ng_profile,
                                            gv_reserve_period_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- **********************************************
    -- �����敪�擾
    -- **********************************************
    xxwip_common3_pkg.check_lastmonth_close(
      gv_target_type,   -- ���ߓ��敪
      lv_errbuf,        -- �G���[�E���b�Z�[�W
      lv_retcode,       -- ���^�[���E�R�[�h
      lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W
    IF (lv_retcode = gv_status_error) THEN -- �����擾�G���[�̏ꍇ
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
  END get_related_date;
--
  /**********************************************************************************
   * Procedure Name   : get_lock
   * Description      : ���b�N�擾(E-2)
   ***********************************************************************************/
  PROCEDURE get_lock(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lock'; -- �v���O������
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
    -- *********************************************
    -- �^���w�b�_�[�A�h�I���̃��b�N�擾
    -- *********************************************
    -- ���b�N�擾���s�̏ꍇ
    IF (NOT(xxcmn_common_pkg.get_tbl_lock(
          gv_wip_msg_kbn,        -- �X�L�[�}��
          gv_tbl_n_deliv_head))) -- �e�[�u����
    THEN
      -- ���b�N�G���[�ڍ׃��b�Z�[�W�̏o��
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn,
                                            gv_wip_msg_73e_004,
                                            gv_tkn_table,
                                            gv_deliv_head_name);
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
  END get_lock;
--
--
  /**********************************************************************************
   * Procedure Name   : get_deliv_if_date
   * Description      : �^���A�h�I���C���^�t�F�[�X�f�[�^�擾(E-3)
   ***********************************************************************************/
  PROCEDURE get_deliv_if_date(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deliv_if_date'; -- �v���O������
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
    BEGIN
      -- �^���A�h�I���C���^�t�F�[�X�f�[�^���擾
      SELECT xdi.delivery_id,            -- 1.�^���A�h�I��ID
             xdi.pattern_flag,           -- 2.�p�^�[���敪
             xdi.delivery_company_code,  -- 3.�^���Ǝ�
             xdi.delivery_no,            -- 4.�z��No
             xdi.invoice_no,             -- 5.�����No
             xdi.p_b_classe,             -- 6.�x�������敪
             xdi.delivery_classe,        -- 7.�z���敪
             xdi.charged_amount,         -- 8.�����^��
             xdi.qty1,                   -- 9.��1
             xdi.qty2,                   -- 10.��2
             xdi.delivery_weight1,       -- 11.�d��1
             xdi.delivery_weight2,       -- 12.�d��2
             xdi.distance,               -- 13.����
             xdi.many_rate,              -- 14.������
             xdi.congestion_charge,      -- 15.�ʍs��
             xdi.picking_charge,         -- 16.�s�b�L���O��
             xdi.consolid_surcharge,     -- 17.���ڊ������z
             xdi.total_amount,           -- 18.���v
             xdi.creation_date,          -- 19.�쐬��
             xdi.last_update_date        -- 20.�ŏI�X�V��
      BULK COLLECT INTO gt_deliv_if_tbl
      FROM    xxwip_deliverys_if xdi     -- �^���A�h�I���C���^�t�F�[�X
-- ##### Ver.1.8 E_�{�ғ�_13659�Ή� START #####
      WHERE  EXISTS (SELECT /*+ INDEX(xd XXWIP_DELIVERYS_N01) */
                            gv_dummy
                     FROM   xxwip_deliverys  xd    -- �^���w�b�_�A�h�I��
                     WHERE  xdi.delivery_company_code = xd.delivery_company_code   -- �^���Ǝ�
                     AND    xdi.delivery_no           = xd.delivery_no             -- �z��No
                     AND    xdi.p_b_classe            = xd.p_b_classe              -- �x�������敪
                     AND    xd.goods_classe           = gv_prod_div                -- ���i�敪
             )
         OR  NOT EXISTS (SELECT /*+ INDEX(xd2 XXWIP_DELIVERYS_N01) */
                                gv_dummy
                         FROM   xxwip_deliverys  xd2    -- �^���w�b�_�A�h�I��
                         WHERE  xdi.delivery_company_code = xd2.delivery_company_code   -- �^���Ǝ�
                         AND    xdi.delivery_no           = xd2.delivery_no             -- �z��No
                         AND    xdi.p_b_classe            = xd2.p_b_classe              -- �x�������敪
             )
-- ##### Ver.1.8 E_�{�ғ�_13659�Ή� END   #####
      ORDER BY xdi.delivery_id
      FOR UPDATE NOWAIT;
--
    EXCEPTION
      WHEN lock_expt THEN 
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn,
                                              gv_wip_msg_73e_004,
                                              gv_tkn_table,
                                              gv_deliv_if_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
    -- �Ώۃf�[�^���Ȃ��ꍇ
    IF (gt_deliv_if_tbl.COUNT = 0) THEN
      -- ���^�[���E�R�[�h�Ɍx����ݒ�
      ov_retcode := gv_status_warn;
      -- �������X�L�b�v
      RETURN;
    ELSE
      -- �Ώی����̊i�[
      gn_target_cnt := gt_deliv_if_tbl.COUNT;
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
  END get_deliv_if_date;
--
--
  /**********************************************************************************
   * Procedure Name   : chk_object
   * Description      : �X�V�Ώۃ`�F�b�N(E-4)
   ***********************************************************************************/
  PROCEDURE chk_object(
    ir_deliv_if_rec IN  deliv_if_rec, --   �^���A�h�I���C���^�t�F�[�X���R�[�h
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_object'; -- �v���O������
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
    ln_count               NUMBER;        -- ���݃`�F�b�N�p�J�E���^�[
--
    lv_head_date_flg       VARCHAR2(1);   -- �^���w�b�_�[�A�h�I���f�[�^���݃t���O(Y:�L��AN:����)
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
    -- �p�^�[���敪 = �u�ɓ����Y�Ɓv���A�x�������敪 = �u�x���v
    -- �z���敪��NULL�ȊO�̏ꍇ�A�`�F�b�N�������s��
    IF ((ir_deliv_if_rec.delivery_classe IS NOT NULL)
      AND (ir_deliv_if_rec.pattern_flag = gv_ptn_it)
      AND (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay))
    THEN
--
      -- ************************************************
      -- �z���敪���݃`�F�b�N
      -- ************************************************
      SELECT COUNT(xlvv.meaning)         -- ���e
      INTO   ln_count
      FROM   xxcmn_lookup_values_v xlvv -- �N�C�b�N�R�[�h���VIEW
      WHERE  xlvv.lookup_type = gv_lu_cd_ship_method
      AND    xlvv.lookup_code = ir_deliv_if_rec.delivery_classe
      AND    ROWNUM = 1;
--
      -- ���݂��Ȃ��ꍇ
      IF (ln_count < 1) THEN
        -- �폜�p�^���A�h�I���C���^�t�F�[�X�J�E���^�[�̃J�E���g�A�b�v
        gn_deliv_if_del_cnt := gn_deliv_if_del_cnt + 1;
        -- �G���[�����̃J�E���g�A�b�v
        gn_error_cnt := gn_error_cnt + 1;
--
        -- �폜�p�^���A�h�I���C���^�t�F�[�X�Ɋi�[
        d_deliv_if_id_tab(gn_deliv_if_del_cnt) := ir_deliv_if_rec.delivery_id;
--
        -- �z���敪�`�F�b�N�pPL/SQL�\�p�J�E���^�[�̃J�E���g�A�b�v
        gn_deliv_cls_cnt := gn_deliv_cls_cnt + 1;
--
        -- �z���敪�`�F�b�N�pPL/SQL�\�Ɋi�[
        -- �^���A�h�I��ID
        d_deliv_cls_id_tab(gn_deliv_cls_cnt)         := ir_deliv_if_rec.delivery_id;
        -- �p�^�[���敪
        d_deliv_cls_ptn_flg_tab(gn_deliv_cls_cnt)    := ir_deliv_if_rec.pattern_flag;
        -- �^���Ǝ�
        d_deliv_cls_com_cd_tab(gn_deliv_cls_cnt)     := ir_deliv_if_rec.delivery_company_code;
        -- �z��No
        d_deliv_cls_no_tab(gn_deliv_cls_cnt)         := ir_deliv_if_rec.delivery_no;
        -- �����No
        d_deliv_cls_invoice_no_tab(gn_deliv_cls_cnt) := ir_deliv_if_rec.invoice_no;
        -- �x�������敪
        d_deliv_cls_p_b_cls_tab(gn_deliv_cls_cnt)    := ir_deliv_if_rec.p_b_classe;
        -- �z���敪
        d_deliv_cls_deliv_cls_tab(gn_deliv_cls_cnt)  := ir_deliv_if_rec.delivery_classe;
        -- �����^��
        d_deliv_cls_chrg_amt_tab(gn_deliv_cls_cnt)   := ir_deliv_if_rec.charged_amount;
        -- ��1
        d_deliv_cls_qty1_tab(gn_deliv_cls_cnt)       := ir_deliv_if_rec.qty1;
        -- ��2
        d_deliv_cls_qty2_tab(gn_deliv_cls_cnt)       := ir_deliv_if_rec.qty2;
        -- �d��1
        d_deliv_cls_deliv_wht1_tab(gn_deliv_cls_cnt) := ir_deliv_if_rec.delivery_weight1;
        -- �d��2
        d_deliv_cls_deliv_wht2_tab(gn_deliv_cls_cnt) := ir_deliv_if_rec.delivery_weight2;
        -- ����
        d_deliv_cls_distance_tab(gn_deliv_cls_cnt)   := ir_deliv_if_rec.distance;
        -- ������
        d_deliv_cls_many_rt_tab(gn_deliv_cls_cnt)    := ir_deliv_if_rec.many_rate;
        -- �ʍs��
        d_deliv_cls_cng_chrg_tab(gn_deliv_cls_cnt)   := ir_deliv_if_rec.congestion_charge;
        -- �s�b�L���O��
        d_deliv_cls_pic_chrg_tab(gn_deliv_cls_cnt)   := ir_deliv_if_rec.picking_charge;
        -- ���ڊ������z
        d_deliv_cls_cns_srchrg_tab(gn_deliv_cls_cnt) := ir_deliv_if_rec.consolid_surcharge;
        -- ���v
        d_deliv_cls_ttl_amt_tab(gn_deliv_cls_cnt)    := ir_deliv_if_rec.total_amount;
--
        -- ���^�[���E�R�[�h�Ɍx����ݒ�
        ov_retcode := gv_status_warn;
--
        -- �������X�L�b�v
        RETURN;
--
      END IF;
--
    END IF;
--
    BEGIN
      -- �^���w�b�_�[�A�h�I���pPL/SQL�\�p�J�E���^�[�̃J�E���g�A�b�v
      gn_deliv_head_cnt := gn_deliv_head_cnt + 1;
      -- �^���w�b�_�[�A�h�I���f�[�^���݃t���O�̏�����(�uY�v��ݒ�)
      lv_head_date_flg := gv_ktg_yes;
--
      -- ************************************************
      -- �^���w�b�_�[�A�h�I���f�[�^���o����
      -- ************************************************
      SELECT xd.deliverys_header_id,      -- 1.�^���w�b�_�[
             xd.delivery_company_code,    -- 2.�^���Ǝ�
             xd.delivery_no,              -- 3.�z��No
-- ##### 20080916 Ver.1.5 T_S_570�Ή� START #####
             --xd.invoice_no,               -- 4.�����No
             xd.invoice_no2,               -- 4.�����No2
-- ##### 20080916 Ver.1.5 T_S_570�Ή� END #####
             xd.p_b_classe,               -- 5.�x�������敪
             xd.report_date,              -- 6.�񍐓�
             xd.judgement_date,           -- 7.���f��
             xd.goods_classe,             -- 8.���i�敪
             xd.charged_amount,           -- 9.�����^��
             xd.contract_rate,            -- 10.�_��^��
             xd.balance,                  -- 11.���z
             xd.total_amount,             -- 12.���v
             xd.many_rate,                -- 13.������
             xd.distance,                 -- 14.�Œ�����
             xd.delivery_classe,          -- 15.�z���敪
             xd.qty1,                     -- 16.��1
             xd.qty2,                     -- 17.��2
             xd.delivery_weight1,         -- 18.�d��1
             xd.delivery_weight2,         -- 19.�d��2
             xd.consolid_surcharge,       -- 20.���ڊ������z
             xd.congestion_charge,        -- 21.�ʍs��
             xd.picking_charge,           -- 22.�s�b�L���O��
             xd.consolid_qty,             -- 23.���ڐ�
             xd.output_flag,              -- 24.���ً敪
             xd.defined_flag,             -- 25.�x���m��敪
             xd.return_flag,              -- 26.�x���m���
             xd.form_update_flag,         -- 27.��ʍX�V�L��
             xd.outside_up_count          -- 28.�O���ƎҕύX
      INTO   gt_deliv_head_tbl(gn_deliv_head_cnt)
      FROM   xxwip_deliverys xd           -- �^���w�b�_�[�A�h�I��
      WHERE  xd.delivery_company_code = ir_deliv_if_rec.delivery_company_code
      AND    xd.delivery_no           = ir_deliv_if_rec.delivery_no
      AND    xd.p_b_classe            = ir_deliv_if_rec.p_b_classe;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN   -- �f�[�^�Ȃ��G���[
        lv_head_date_flg := gv_ktg_no;
--
        -- �^���w�b�_�[�A�h�I���pPL/SQL�\�p�J�E���^�[�̃J�E���g�A�b�v
        gn_deliv_head_cnt := gn_deliv_head_cnt - 1;
    END;
--
    -- �^���w�b�_�[�A�h�I���f�[�^���擾�ł��Ȃ������ꍇ(�t���O = 'N')
    IF (lv_head_date_flg = gv_ktg_no) THEN
      -- ************************************************
      -- �ۗ������o�߃`�F�b�N
      -- ************************************************
      IF ((gn_wip_reserve_period + TRUNC(ir_deliv_if_rec.last_update_date)) < TRUNC(gd_sysdate))
      THEN
        -- �폜�p�^���A�h�I���C���^�t�F�[�X�J�E���^�[�̃J�E���g�A�b�v
        gn_deliv_if_del_cnt := gn_deliv_if_del_cnt + 1;
        -- �G���[�����̃J�E���g�A�b�v
        gn_error_cnt := gn_error_cnt + 1;
--
        -- �폜�p�^���A�h�I���C���^�t�F�[�X�Ɋi�[
        d_deliv_if_id_tab(gn_deliv_if_del_cnt) := ir_deliv_if_rec.delivery_id;
--
        -- �ۗ����Ԍo�߃`�F�b�N�pPL/SQL�\�p�J�E���^�[�̃J�E���g�A�b�v
        gn_rsv_prd_cnt := gn_rsv_prd_cnt + 1;
--
        -- �ۗ����Ԍo�߃`�F�b�N�pPL/SQL�\�Ɋi�[
        -- �^���A�h�I��ID
        d_rsv_prd_id_tab(gn_rsv_prd_cnt)         := ir_deliv_if_rec.delivery_id;
        -- �p�^�[���敪
        d_rsv_prd_ptn_flg_tab(gn_rsv_prd_cnt)    := ir_deliv_if_rec.pattern_flag;
        -- �^���Ǝ�
        d_rsv_prd_com_cd_tab(gn_rsv_prd_cnt)     := ir_deliv_if_rec.delivery_company_code;
        -- �z��No
        d_rsv_prd_no_tab(gn_rsv_prd_cnt)         := ir_deliv_if_rec.delivery_no;
        -- �����No
        d_rsv_prd_invoice_no_tab(gn_rsv_prd_cnt) := ir_deliv_if_rec.invoice_no;
        -- �x�������敪
        d_rsv_prd_p_b_cls_tab(gn_rsv_prd_cnt)    := ir_deliv_if_rec.p_b_classe;
        -- �z���敪
        d_rsv_prd_deliv_cls_tab(gn_rsv_prd_cnt)  := ir_deliv_if_rec.delivery_classe;
        -- �����^��
        d_rsv_prd_chrg_amt_tab(gn_rsv_prd_cnt)   := ir_deliv_if_rec.charged_amount;
        -- ��1
        d_rsv_prd_qty1_tab(gn_rsv_prd_cnt)       := ir_deliv_if_rec.qty1;
        -- ��2
        d_rsv_prd_qty2_tab(gn_rsv_prd_cnt)       := ir_deliv_if_rec.qty2;
        -- �d��1
        d_rsv_prd_deliv_wht1_tab(gn_rsv_prd_cnt) := ir_deliv_if_rec.delivery_weight1;
        -- �d��2
        d_rsv_prd_deliv_wht2_tab(gn_rsv_prd_cnt) := ir_deliv_if_rec.delivery_weight2;
        -- ����
        d_rsv_prd_distance_tab(gn_rsv_prd_cnt)   := ir_deliv_if_rec.distance;
        -- ������
        d_rsv_prd_many_rt_tab(gn_rsv_prd_cnt)    := ir_deliv_if_rec.many_rate;
        -- �ʍs��
        d_rsv_prd_cng_chrg_tab(gn_rsv_prd_cnt)   := ir_deliv_if_rec.congestion_charge;
        -- �s�b�L���O��
        d_rsv_prd_pic_chrg_tab(gn_rsv_prd_cnt)   := ir_deliv_if_rec.picking_charge;
        -- ���ڊ������z
        d_rsv_prd_cns_srchrg_tab(gn_rsv_prd_cnt) := ir_deliv_if_rec.consolid_surcharge;
        -- ���v
        d_rsv_prd_ttl_amt_tab(gn_rsv_prd_cnt)    := ir_deliv_if_rec.total_amount;
--
        -- ���^�[���E�R�[�h�Ɍx����ݒ�
        ov_retcode := gv_status_warn;
--
        -- �������X�L�b�v
        RETURN;
--
      -- �Ώۃf�[�^�����݂��Ȃ��A�ۗ����ԓ��̃f�[�^�̏ꍇ
      ELSE
        -- �X�L�b�v�����̊i�[
        gn_warn_cnt := gn_warn_cnt + 1;
        -- ���^�[���E�R�[�h�Ɍx����ݒ�
        ov_retcode := gv_status_warn;
        -- �������X�L�b�v
        RETURN;
--
      END IF;
--
    END IF;
--
    -- ************************************************
    -- �����`�F�b�N
    -- ************************************************
    -- ���ߓ��O�Ŋ��A���f�����O���̏����ȍ~�̏ꍇ
    IF ((gv_target_type = gv_ktg_yes) AND
      gt_deliv_head_tbl(gn_deliv_head_cnt).judgement_date >=
      TRUNC(ADD_MONTHS(gd_sysdate, -1), 'MM'))
    THEN
      -- ���폈�����p��
--
      -- �폜�p�^���A�h�I���C���^�t�F�[�X�J�E���^�[�̃J�E���g�A�b�v
      gn_deliv_if_del_cnt := gn_deliv_if_del_cnt + 1;
--
      -- �폜�p�^���A�h�I���C���^�t�F�[�X�Ɋi�[
      d_deliv_if_id_tab(gn_deliv_if_del_cnt) := ir_deliv_if_rec.delivery_id;
--
    -- ���ߓ���Ŋ��A���f���������̏����ȍ~�̏ꍇ
    ELSIF ((gv_target_type = gv_ktg_no) AND
      gt_deliv_head_tbl(gn_deliv_head_cnt).judgement_date >=
      TRUNC(gd_sysdate, 'MM'))
    THEN
      -- ���폈�����p��
--
      -- �폜�p�^���A�h�I���C���^�t�F�[�X�J�E���^�[�̃J�E���g�A�b�v
      gn_deliv_if_del_cnt := gn_deliv_if_del_cnt + 1;
--
      -- �폜�p�^���A�h�I���C���^�t�F�[�X�Ɋi�[
      d_deliv_if_id_tab(gn_deliv_if_del_cnt) := ir_deliv_if_rec.delivery_id;
--
    -- �G���[�Ώۃf�[�^�̏ꍇ
    ELSE
      -- �폜�p�^���A�h�I���C���^�t�F�[�X�J�E���^�[�̃J�E���g�A�b�v
      gn_deliv_if_del_cnt := gn_deliv_if_del_cnt + 1;
      -- �G���[�����̃J�E���g�A�b�v
      gn_error_cnt := gn_error_cnt + 1;
--
      -- �폜�p�^���A�h�I���C���^�t�F�[�X�Ɋi�[
      d_deliv_if_id_tab(gn_deliv_if_del_cnt) := ir_deliv_if_rec.delivery_id;
--
      -- �X�V�s�\�pPL/SQL�\�p�J�E���^�[�̃J�E���g�A�b�v
      gn_not_upd_cnt := gn_not_upd_cnt + 1;
--
      -- �X�V�s�\�pPL/SQL�\�Ɋi�[
      -- �^���A�h�I��ID
      d_not_upd_id_tab(gn_not_upd_cnt)         := ir_deliv_if_rec.delivery_id;
      -- �p�^�[���敪
      d_not_upd_ptn_flg_tab(gn_not_upd_cnt)    := ir_deliv_if_rec.pattern_flag;
      -- �^���Ǝ�
      d_not_upd_com_cd_tab(gn_not_upd_cnt)     := ir_deliv_if_rec.delivery_company_code;
      -- �z��No
      d_not_upd_no_tab(gn_not_upd_cnt)         := ir_deliv_if_rec.delivery_no;
      -- �����No
      d_not_upd_invoice_no_tab(gn_not_upd_cnt) := ir_deliv_if_rec.invoice_no;
      -- �x�������敪
      d_not_upd_p_b_cls_tab(gn_not_upd_cnt)    := ir_deliv_if_rec.p_b_classe;
      -- �z���敪
      d_not_upd_deliv_cls_tab(gn_not_upd_cnt)  := ir_deliv_if_rec.delivery_classe;
      -- �����^��
      d_not_upd_chrg_amt_tab(gn_not_upd_cnt)   := ir_deliv_if_rec.charged_amount;
      -- ��1
      d_not_upd_qty1_tab(gn_not_upd_cnt)       := ir_deliv_if_rec.qty1;
      -- ��2
      d_not_upd_qty2_tab(gn_not_upd_cnt)       := ir_deliv_if_rec.qty2;
      -- �d��1
      d_not_upd_deliv_wht1_tab(gn_not_upd_cnt) := ir_deliv_if_rec.delivery_weight1;
      -- �d��2
      d_not_upd_deliv_wht2_tab(gn_not_upd_cnt) := ir_deliv_if_rec.delivery_weight2;
      -- ����
      d_not_upd_distance_tab(gn_not_upd_cnt)   := ir_deliv_if_rec.distance;
      -- ������
      d_not_upd_many_rt_tab(gn_not_upd_cnt)    := ir_deliv_if_rec.many_rate;
      -- �ʍs��
      d_not_upd_cng_chrg_tab(gn_not_upd_cnt)   := ir_deliv_if_rec.congestion_charge;
      -- �s�b�L���O��
      d_not_upd_pic_chrg_tab(gn_not_upd_cnt)   := ir_deliv_if_rec.picking_charge;
      -- ���ڊ������z
      d_not_upd_cns_srchrg_tab(gn_not_upd_cnt) := ir_deliv_if_rec.consolid_surcharge;
      -- ���v
      d_not_upd_ttl_amt_tab(gn_not_upd_cnt)    := ir_deliv_if_rec.total_amount;
--
      -- ���^�[���E�R�[�h�Ɍx����ݒ�
      ov_retcode := gv_status_warn;
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
  END chk_object;
--
--
  /**********************************************************************************
   * Procedure Name   : get_deliv_cal_date
   * Description      : �^���v�Z�p�f�[�^�擾(E-5)
   ***********************************************************************************/
  PROCEDURE get_deliv_cal_date(
    ir_deliv_if_rec IN  deliv_if_rec, --   �^���A�h�I���C���^�t�F�[�X���R�[�h
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deliv_cal_date'; -- �v���O������
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
    lt_delivery_classe       xxwip_deliverys_if.delivery_classe%TYPE;       -- �z���敪
    lt_distance              xxwip_deliverys_if.distance%TYPE;              -- �^������
    lt_delivery_weight       xxwip_deliverys_if.delivery_weight1%TYPE;      -- �d��
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
    -- ********************************************
    -- �_��^���A���ڊ����^���̎擾
    -- ********************************************
    -- �z���敪�̐ݒ�
    -- �擾�����f�[�^�̃p�^�[���敪���u�ɓ����Y�Ɓv�Ŋ��A�x�������敪���u�x���v�̏ꍇ
    IF ((ir_deliv_if_rec.pattern_flag = gv_ptn_it) AND
      (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay))
    THEN
      -- �z���敪�ɒl�����͂���Ă���ꍇ
      IF (ir_deliv_if_rec.delivery_classe IS NOT NULL) THEN
        lt_delivery_classe := ir_deliv_if_rec.delivery_classe;
      -- �z���敪�ɒl�����͂���Ă��Ȃ��ꍇ
      ELSE
        lt_delivery_classe := gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_classe;
      END IF;
    -- ��L�ȊO�̏ꍇ
    ELSE
      lt_delivery_classe := gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_classe;
    END IF;
--
    -- �^�������̐ݒ�
    -- �擾�����f�[�^�̃p�^�[���敪���u�ɓ����Y�Ɓv�Ŋ��A�x�������敪���u�x���v�̏ꍇ
    IF ((ir_deliv_if_rec.pattern_flag = gv_ptn_it) AND
      (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay))
    THEN
      IF (ir_deliv_if_rec.distance IS NOT NULL) THEN
        lt_distance := ir_deliv_if_rec.distance;
      ELSE
        lt_distance := gt_deliv_head_tbl(gn_deliv_head_cnt).distance;
      END IF;
    -- ��L�ȊO�̏ꍇ
    ELSE
      lt_distance := gt_deliv_head_tbl(gn_deliv_head_cnt).distance;
    END IF;
--
    -- �d��
    -- �擾�����f�[�^�̃p�^�[���敪���u�ɓ����Y�Ɓv�Ŋ��A�x�������敪���u�x���v�̏ꍇ
    IF ((ir_deliv_if_rec.pattern_flag = gv_ptn_it) AND
      (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay))
    THEN
      IF (ir_deliv_if_rec.delivery_weight1 IS NOT NULL) THEN
        lt_delivery_weight := ir_deliv_if_rec.delivery_weight1;
      ELSE
        lt_delivery_weight := gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_weight1;
      END IF;
    -- ��L�ȊO�̏ꍇ
    ELSE
      lt_delivery_weight := gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_weight1;
    END IF;
--
    -- ********************************************
    -- �^���A�h�I���}�X�^�擾
    -- ********************************************
    -- ���ʊ֐����g�p���^������擾
    xxwip_common3_pkg.get_delivery_charges(
                        ir_deliv_if_rec.p_b_classe,                          -- 1.�x�������敪
                        gt_deliv_head_tbl(gn_deliv_head_cnt).goods_classe,   -- 2.���i�敪
                        ir_deliv_if_rec.delivery_company_code,               -- 3.�^���Ǝ�
                        lt_delivery_classe,                                  -- 4.�z���敪
                        lt_distance,                                         -- 5.�^������
                        lt_delivery_weight,                                  -- 6.�d��
                        gt_deliv_head_tbl(gn_deliv_head_cnt).judgement_date, -- 7.���f��
                        gr_deliv_charges,    -- 8.�^���A�h�I���}�X�^���R�[�h(�^����,���[�t���ڊ���)
                        lv_errbuf,           -- �G���[�E���b�Z�[�W           --# �Œ� #
                        lv_retcode,          -- ���^�[���E�R�[�h             --# �Œ� #
                        lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ********************************************
    -- �s�b�L���O�P���̎擾
    -- ********************************************
    BEGIN
      SELECT NVL(xdc.pay_picking_amount, 0),      -- 1.�x���s�b�L���O�P��
             NVL(xdc.bill_picking_amount, 0)      -- 2.�����s�b�L���O�P��
      INTO   gr_deliv_company.pay_picking_amount,
             gr_deliv_company.bill_picking_amount
      FROM   xxwip_delivery_company xdc           -- �^���p�^���Ǝ҃A�h�I���}�X�^
      WHERE  xdc.goods_classe          = gt_deliv_head_tbl(gn_deliv_head_cnt).goods_classe
      AND    xdc.delivery_company_code = ir_deliv_if_rec.delivery_company_code
      AND    gt_deliv_head_tbl(gn_deliv_head_cnt).judgement_date
             BETWEEN xdc.start_date_active AND xdc.end_date_active;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN  -- �Ώۃf�[�^�Ȃ��G���[
        -- 0 ��ݒ�
        gr_deliv_company.pay_picking_amount  := 0;
        gr_deliv_company.bill_picking_amount := 0;
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
  END get_deliv_cal_date;
--
--
  /**********************************************************************************
   * Procedure Name   : set_date
   * Description      : �f�[�^�ݒ�(E-6)
   ***********************************************************************************/
  PROCEDURE set_date(
    ir_deliv_if_rec IN  deliv_if_rec, --   �^���A�h�I���C���^�t�F�[�X���R�[�h
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_date'; -- �v���O������
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
    -- *******************************************************************
    -- �^���w�b�_�[�A�h�I���X�V�pPL/SQL�\�Ƀf�[�^��ݒ�
    -- *******************************************************************
--
    -- �X�V�p�^���w�b�_�[�A�h�I���pPL/SQL�\�p�J�E���^�[�̃J�E���g�A�b�v
    gn_upd_deliv_head_cnt := gn_upd_deliv_head_cnt + 1;
--
--
    -- �^���Ǝ҂̐ݒ�
    u_deliv_head_com_code_id_tab(gn_upd_deliv_head_cnt) := ir_deliv_if_rec.delivery_company_code;
--
    -- �z��No�̐ݒ�
    u_deliv_head_deliv_no_tab(gn_upd_deliv_head_cnt) := ir_deliv_if_rec.delivery_no;
--
    -- �����No2
    IF (ir_deliv_if_rec.invoice_no IS NOT NULL) THEN
      u_deliv_head_invoice_no_tab(gn_upd_deliv_head_cnt) := ir_deliv_if_rec.invoice_no;
    ELSE
      u_deliv_head_invoice_no_tab(gn_upd_deliv_head_cnt) :=
-- ##### 20080916 Ver.1.5 T_S_570�Ή� START #####
        --gt_deliv_head_tbl(gn_deliv_head_cnt).invoice_no;
        gt_deliv_head_tbl(gn_deliv_head_cnt).invoice_no2;
-- ##### 20080916 Ver.1.5 T_S_570�Ή� END #####
    END IF;
--
    -- �x�������敪
    u_deliv_head_p_b_cls_tab(gn_upd_deliv_head_cnt) := ir_deliv_if_rec.p_b_classe;
--
    -- �񍐓�
    -- �p�^�[���敪 �� �u�O���v�̏ꍇ
    IF (ir_deliv_if_rec.pattern_flag = gv_ptn_out) THEN
      u_deliv_head_rpt_date_tab(gn_upd_deliv_head_cnt) := ir_deliv_if_rec.creation_date;
    -- �p�^�[���敪 �� �u�ɓ����Y�Ɓv�̏ꍇ
    ELSIF (ir_deliv_if_rec.pattern_flag = gv_ptn_it) THEN
      u_deliv_head_rpt_date_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).report_date;
    END IF;
--
    -- �z���敪
    -- �p�^�[���敪 = �u�ɓ����Y�Ɓv�Ŋ��A�x�������敪 = �u�x���v�̏ꍇ
    IF ((ir_deliv_if_rec.pattern_flag = gv_ptn_it) AND
      (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay))
    THEN
      IF (ir_deliv_if_rec.delivery_classe IS NOT NULL) THEN
        u_deliv_head_deliv_cls_tab(gn_upd_deliv_head_cnt) :=
          ir_deliv_if_rec.delivery_classe;
      ELSE
        u_deliv_head_deliv_cls_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_classe;
      END IF;
    ELSE
      u_deliv_head_deliv_cls_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_classe;
    END IF;
--
    -- �����^��
    IF (ir_deliv_if_rec.charged_amount IS NOT NULL) THEN
      u_deliv_head_chrg_amt_tab(gn_upd_deliv_head_cnt) :=
        ir_deliv_if_rec.charged_amount;
    ELSE
      u_deliv_head_chrg_amt_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).charged_amount;
    END IF;
--
    -- �_��^��
    -- �p�^�[���敪 = �u�ɓ����Y�Ɓv�Ŋ��A�x�������敪 = �u�x���v�̏ꍇ
    IF ((ir_deliv_if_rec.pattern_flag = gv_ptn_it) AND
        (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay))
    THEN
      u_deliv_head_con_rate_tab(gn_upd_deliv_head_cnt) :=
                        gr_deliv_charges.shipping_expenses;
    ELSE
      u_deliv_head_con_rate_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).contract_rate;
    END IF;
--
    -- ��1
    -- �p�^�[���敪 = �u�ɓ����Y�Ɓv�Ŋ��A�x�������敪 = �u�x���v�̏ꍇ
    IF ((ir_deliv_if_rec.pattern_flag = gv_ptn_it) AND
      (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay))
    THEN
      IF (ir_deliv_if_rec.qty1 IS NOT NULL) THEN
        u_deliv_head_qty1_tab(gn_upd_deliv_head_cnt) := ir_deliv_if_rec.qty1;
      ELSE
        u_deliv_head_qty1_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).qty1;
      END IF;
    ELSE
      u_deliv_head_qty1_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).qty1;
    END IF;
--
    -- ��2
    -- �p�^�[���敪 = �u�O���v�̏ꍇ
    IF (ir_deliv_if_rec.pattern_flag = gv_ptn_out) THEN
      IF (ir_deliv_if_rec.qty2 IS NOT NULL) THEN
        u_deliv_head_qty2_tab(gn_upd_deliv_head_cnt) := ir_deliv_if_rec.qty2;
      ELSE
        u_deliv_head_qty2_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).qty2;
      END IF;
    ELSE
      u_deliv_head_qty2_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).qty2;
    END IF;
--
    -- �d��1
    -- �p�^�[���敪 = �u�ɓ����Y�Ɓv�Ŋ��A�x�������敪 = �u�x���v�̏ꍇ
    IF ((ir_deliv_if_rec.pattern_flag = gv_ptn_it) AND
      (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay))
    THEN
      IF (ir_deliv_if_rec.delivery_weight1 IS NOT NULL) THEN
        u_deliv_head_deliv_wht1_tab(gn_upd_deliv_head_cnt) :=
          ir_deliv_if_rec.delivery_weight1;
      ELSE
        u_deliv_head_deliv_wht1_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_weight1;
      END IF;
    ELSE
      u_deliv_head_deliv_wht1_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_weight1;
    END IF;
--
    -- �d��2
    -- �p�^�[���敪 = �u�O���v�̏ꍇ
    IF (ir_deliv_if_rec.pattern_flag = gv_ptn_out) THEN
      IF (ir_deliv_if_rec.delivery_weight2 IS NOT NULL) THEN
        u_deliv_head_deliv_wht2_tab(gn_upd_deliv_head_cnt) :=
          ir_deliv_if_rec.delivery_weight2;
      ELSE
        u_deliv_head_deliv_wht2_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_weight2;
      END IF;
    ELSE
      u_deliv_head_deliv_wht2_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_weight2;
    END IF;
--
    -- ����
    -- �p�^�[���敪 = �u�ɓ����Y�Ɓv�Ŋ��A�x�������敪 = �u�x���v�̏ꍇ
    IF ((ir_deliv_if_rec.pattern_flag = gv_ptn_it) AND
      (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay))
    THEN
      IF (ir_deliv_if_rec.distance IS NOT NULL) THEN
        u_deliv_head_dst_tab(gn_upd_deliv_head_cnt) := ir_deliv_if_rec.distance;
      ELSE
        u_deliv_head_dst_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).distance;
      END IF;
    ELSE
      u_deliv_head_dst_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).distance;
    END IF;
--
    -- ������
    -- �p�^�[���敪 = �u�ɓ����Y�Ɓv�̏ꍇ
    IF (ir_deliv_if_rec.pattern_flag = gv_ptn_it) THEN
      IF (ir_deliv_if_rec.many_rate IS NOT NULL) THEN
        u_deliv_head_many_rt_tab(gn_upd_deliv_head_cnt) := ir_deliv_if_rec.many_rate;
      ELSE
        u_deliv_head_many_rt_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).many_rate;
      END IF;
    ELSE
      u_deliv_head_many_rt_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).many_rate;
    END IF;
--
    -- �ʍs��
    IF (ir_deliv_if_rec.congestion_charge IS NOT NULL) THEN
      u_deliv_head_cng_chrg_tab(gn_upd_deliv_head_cnt) :=
        ir_deliv_if_rec.congestion_charge;
    ELSE
      u_deliv_head_cng_chrg_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).congestion_charge;
    END IF;
--
    -- �s�b�L���O��
    -- �p�^�[���敪 = �u�O���v�̏ꍇ
    IF (ir_deliv_if_rec.pattern_flag = gv_ptn_out) THEN
      u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).picking_charge;
    -- �p�^�[���敪 = �u�ɓ����Y�Ɓv�̏ꍇ
    ELSE
      -- �x�������敪 �� �u�x���v�̏ꍇ
      IF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay) THEN
        IF (ir_deliv_if_rec.picking_charge IS NOT NULL) THEN
          u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt) :=
            ir_deliv_if_rec.picking_charge;
        ELSE
          IF (ir_deliv_if_rec.qty1 IS NOT NULL) THEN
            u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt) :=
-- ##### 20080725 Ver.1.4 ST��Q473�Ή� START #####
--              ROUND(gr_deliv_company.pay_picking_amount * ir_deliv_if_rec.qty1);
              CEIL(gr_deliv_company.pay_picking_amount * ir_deliv_if_rec.qty1);
-- ##### 20080725 Ver.1.4 ST��Q473�Ή� END   #####
          ELSE
-- ##### 20080725 Ver.1.4 ST��Q473�Ή� START #####
/*****
            u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt) :=
              ROUND(gr_deliv_company.pay_picking_amount *
                gt_deliv_head_tbl(gn_deliv_head_cnt).qty1);
*****/
            u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt) :=
              CEIL(gr_deliv_company.pay_picking_amount *
                gt_deliv_head_tbl(gn_deliv_head_cnt).qty1);
-- ##### 20080725 Ver.1.4 ST��Q473�Ή� END   #####
          END IF;
        END IF;
      -- �x�������敪 �� �u�����v�̏ꍇ
      ELSIF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_bil) THEN
        IF (ir_deliv_if_rec.picking_charge IS NOT NULL) THEN
          u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt) :=
            ir_deliv_if_rec.picking_charge;
        ELSE
          u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt) :=
            gt_deliv_head_tbl(gn_deliv_head_cnt).picking_charge;
        END IF;
      END IF;
    END IF;
--
    -- ���ڊ������z
    -- �p�^�[���敪 = �u�O���v�̏ꍇ
    IF (ir_deliv_if_rec.pattern_flag = gv_ptn_out) THEN
      u_deliv_head_cns_srchrg_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).consolid_surcharge;
    -- �p�^�[���敪 = �u�ɓ����Y�Ɓv�̏ꍇ
    ELSE
      IF (ir_deliv_if_rec.consolid_surcharge IS NOT NULL) THEN
        u_deliv_head_cns_srchrg_tab(gn_upd_deliv_head_cnt) :=
          ir_deliv_if_rec.consolid_surcharge;
      ELSE
        u_deliv_head_cns_srchrg_tab(gn_upd_deliv_head_cnt) :=
          gr_deliv_charges.leaf_consolid_add * gt_deliv_head_tbl(gn_deliv_head_cnt).consolid_qty;
      END IF;
    END IF;
--
    -- ���v
    -- �p�^�[���敪 = �u�O���v�̏ꍇ
    IF (ir_deliv_if_rec.pattern_flag = gv_ptn_out) THEN
      u_deliv_head_ttl_amt_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).total_amount;
    -- �p�^�[���敪 = �u�ɓ����Y�Ɓv�̏ꍇ
    ELSE
      IF (ir_deliv_if_rec.total_amount IS NOT NULL) THEN
        u_deliv_head_ttl_amt_tab(gn_upd_deliv_head_cnt) := ir_deliv_if_rec.total_amount;
      ELSE
-- ##### 20080725 Ver.1.4 ST��Q473�Ή� START #####
/*****
        u_deliv_head_ttl_amt_tab(gn_upd_deliv_head_cnt) :=
                      u_deliv_head_con_rate_tab(gn_upd_deliv_head_cnt) +
                      u_deliv_head_cns_srchrg_tab(gn_upd_deliv_head_cnt) +
                      u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt) +
                      u_deliv_head_many_rt_tab(gn_upd_deliv_head_cnt);
*****/
-- ##### 20081201 Ver.1.6 �{��#303�Ή� START #####
        -- �x�������敪 �� �u�x���v�̏ꍇ
        -- �_����z �{ ���ڊ������z �{ �s�b�L���O�� �{ ������
        IF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay) THEN
-- ##### 20081201 Ver.1.6 �{��#303�Ή� END   #####
          u_deliv_head_ttl_amt_tab(gn_upd_deliv_head_cnt) :=
                        NVL(u_deliv_head_con_rate_tab(gn_upd_deliv_head_cnt),0) +
                        NVL(u_deliv_head_cns_srchrg_tab(gn_upd_deliv_head_cnt),0) +
                        NVL(u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt),0) +
                        NVL(u_deliv_head_many_rt_tab(gn_upd_deliv_head_cnt),0);
-- ##### 20081201 Ver.1.6 �{��#303�Ή� START #####
        -- �x�������敪 �� �u�����v�̏ꍇ
        -- �������z �{ ���ڊ������z �{ �s�b�L���O�� �{ ������
        ELSE
          u_deliv_head_ttl_amt_tab(gn_upd_deliv_head_cnt) :=
                        NVL(u_deliv_head_chrg_amt_tab(gn_upd_deliv_head_cnt),0) +
                        NVL(u_deliv_head_cns_srchrg_tab(gn_upd_deliv_head_cnt),0) +
                        NVL(u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt),0) +
                        NVL(u_deliv_head_many_rt_tab(gn_upd_deliv_head_cnt),0);
        END IF;
-- ##### 20081201 Ver.1.6 �{��#303�Ή� END   #####
-- ##### 20080725 Ver.1.4 ST��Q473�Ή� END   #####
      END IF;
    END IF;
--
    -- ���z
-- ##### 20080725 Ver.1.4 ST��Q473�Ή� START #####
/*****
    u_deliv_head_balance_tab(gn_upd_deliv_head_cnt) :=
                u_deliv_head_chrg_amt_tab(gn_upd_deliv_head_cnt) -
                  u_deliv_head_ttl_amt_tab(gn_upd_deliv_head_cnt);
*****/
-- ##### 20081201 Ver.1.6 �{��#303�Ή� START #####
    -- �x�������敪 �� �u�x���v�̏ꍇ
    IF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay) THEN
-- ##### 20081201 Ver.1.6 �{��#303�Ή� END   #####
--  �������z �| ���v
    u_deliv_head_balance_tab(gn_upd_deliv_head_cnt) :=
                NVL(u_deliv_head_chrg_amt_tab(gn_upd_deliv_head_cnt),0) -
                  NVL(u_deliv_head_ttl_amt_tab(gn_upd_deliv_head_cnt),0);
--
-- ##### 20081201 Ver.1.6 �{��#303�Ή� START #####
--
    -- �x�������敪 �� �u�����v�̏ꍇ
    ELSE
      -- ���v - �i�������z �{ ���ڊ������z �{ �s�b�L���O�� �{ �������j
      -- �v�Z���ʂ͂O�ɂȂ�
      u_deliv_head_balance_tab(gn_upd_deliv_head_cnt) :=
        u_deliv_head_ttl_amt_tab(gn_upd_deliv_head_cnt) -
        (NVL(u_deliv_head_chrg_amt_tab(gn_upd_deliv_head_cnt),0) +
         NVL(u_deliv_head_cns_srchrg_tab(gn_upd_deliv_head_cnt),0) +
         NVL(u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt),0) +
         NVL(u_deliv_head_many_rt_tab(gn_upd_deliv_head_cnt),0));
    END IF;
-- ##### 20081201 Ver.1.6 �{��#303�Ή� END   #####
-- ##### 20080725 Ver.1.4 ST��Q473�Ή� END   #####
--
    -- ���ً敪
    -- �x�������敪 = �u�x���v�̏ꍇ
    IF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay) THEN
      -- �X�V�pPL/SQL�\.���z �� �u0�v�̏ꍇ
      IF (u_deliv_head_balance_tab(gn_upd_deliv_head_cnt) <> 0) THEN
        u_deliv_head_op_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_yes;
      -- �X�V�pPL/SQL�\.���z �� �u0�v�̏ꍇ
      ELSIF (u_deliv_head_balance_tab(gn_upd_deliv_head_cnt) = 0) THEN
          u_deliv_head_op_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_no;
      END IF;
    -- �x�������敪 = �u�����v�̏ꍇ
    ELSE
      u_deliv_head_op_flg_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).output_flag;
    END IF;
--
    -- ��ʍX�V�L���敪
    -- �^���A�h�I���C���^�t�F�[�X.�x�������敪 �� �u�x���v�̏ꍇ
    IF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay) THEN
      -- �z���敪�A��1�A�d��1�A�����A�s�b�L���O���A���v�A���ڊ������z��
      -- �����ꂩ���ύX�ɂȂ����ꍇ
      IF (u_deliv_head_deliv_cls_tab(gn_upd_deliv_head_cnt) <>
            gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_classe OR
          u_deliv_head_qty1_tab(gn_upd_deliv_head_cnt) <>
            gt_deliv_head_tbl(gn_deliv_head_cnt).qty1 OR
          u_deliv_head_deliv_wht1_tab(gn_upd_deliv_head_cnt) <>
            gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_weight1 OR
          u_deliv_head_dst_tab(gn_upd_deliv_head_cnt) <>
            gt_deliv_head_tbl(gn_deliv_head_cnt).distance OR
          u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt) <>
            gt_deliv_head_tbl(gn_deliv_head_cnt).picking_charge OR
          u_deliv_head_ttl_amt_tab(gn_upd_deliv_head_cnt) <>
            gt_deliv_head_tbl(gn_deliv_head_cnt).total_amount OR
          u_deliv_head_cns_srchrg_tab(gn_upd_deliv_head_cnt) <>
            gt_deliv_head_tbl(gn_deliv_head_cnt).consolid_surcharge)
      THEN
        u_deliv_head_frm_upd_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_yes;
      ELSE
        u_deliv_head_frm_upd_flg_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).form_update_flag;
      END IF;
    -- �^���A�h�I���C���^�t�F�[�X.�x�������敪 �� �u�����v�̏ꍇ
    ELSIF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_bil) THEN
      u_deliv_head_frm_upd_flg_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).form_update_flag;
    END IF;
--
    -- �x���m��敪
    -- �^���A�h�I���C���^�t�F�[�X.�x�������敪 �� �u�x���v�̏ꍇ
    IF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay) THEN
      -- �X�V�pPL/SQL�\.���ً敪 = �uYes�v�̏ꍇ
      IF (u_deliv_head_op_flg_tab(gn_upd_deliv_head_cnt) = gv_ktg_yes) THEN
        u_deliv_head_dfn_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_no;
      -- �X�V�pPL/SQL�\.���ً敪 �� �uNo�v�̏ꍇ
      ELSIF (u_deliv_head_op_flg_tab(gn_upd_deliv_head_cnt) = gv_ktg_no) THEN
        -- �X�V�pPL/SQL�\.�����^�� �� �u0�v�̏ꍇ
        IF (u_deliv_head_chrg_amt_tab(gn_upd_deliv_head_cnt) <> 0) THEN
          u_deliv_head_dfn_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_yes;
        -- �X�V�pPL/SQL�\.�����^�� �� �u0�v�̏ꍇ
        ELSIF (u_deliv_head_chrg_amt_tab(gn_upd_deliv_head_cnt) = 0) THEN
          -- �X�V�pPL/SQL�\.��ʍX�V�L���敪 �� �uYes�v�̏ꍇ
          IF (u_deliv_head_frm_upd_flg_tab(gn_upd_deliv_head_cnt) = gv_ktg_yes) THEN
            u_deliv_head_dfn_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_yes;
          -- �X�V�pPL/SQL�\.��ʍX�V�L���敪 �� �uNo�v�̏ꍇ
          ELSIF (u_deliv_head_frm_upd_flg_tab(gn_upd_deliv_head_cnt) = gv_ktg_no) THEN
-- *--------* 20080916 Ver.1.7 �{��#1239�Ή� START *--------*
--            u_deliv_head_dfn_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_no;
--
            -- �p�^�[���敪 = �u�ɓ����Y�Ɓv�̏ꍇ
            IF (ir_deliv_if_rec.pattern_flag = gv_ptn_it) THEN
              u_deliv_head_dfn_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_yes;
--
            -- �p�^�[���敪 = �u�O���v�̏ꍇ
            ELSE
              u_deliv_head_dfn_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_no;
            END IF;
-- *--------* 20080916 Ver.1.7 �{��#1239�Ή� END   *--------*
          END IF;
        END IF;
      END IF;
    -- �^���A�h�I���C���^�t�F�[�X.�x�������敪 �� �u�����v�̏ꍇ
    ELSIF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_bil) THEN
      u_deliv_head_dfn_flg_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).defined_flag;
    END IF;
--
    -- �x���m���
    -- �^���A�h�I���C���^�t�F�[�X.�x�������敪 = �u�x���v�̏ꍇ
    IF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay) THEN
      -- �^���w�b�_�[�A�h�I��.�x���m��敪 �� �uYes�v�Ŋ��A
      -- �X�V�pPL/SQL�\.�x���m��敪 �� �uNo�v�̏ꍇ
      IF (gt_deliv_head_tbl(gn_deliv_head_cnt).defined_flag = gv_ktg_yes AND
            u_deliv_head_dfn_flg_tab(gn_upd_deliv_head_cnt) = gv_ktg_no)
      THEN
        u_deliv_head_rtrn_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_yes;
      -- �X�V�pPL/SQL�\.���ً敪 �� �uNo�v�Ŋ��A
      -- �X�V�pPL/SQL�\.�����^�� �� �u0�v�Ŋ��A
      -- �X�V�pPL/SQL�\.��ʍX�V�L���敪 �� �uYes�v�̏ꍇ
      ELSIF (u_deliv_head_op_flg_tab(gn_upd_deliv_head_cnt) = gv_ktg_no AND
              u_deliv_head_chrg_amt_tab(gn_upd_deliv_head_cnt) = 0 AND
              u_deliv_head_frm_upd_flg_tab(gn_upd_deliv_head_cnt) = gv_ktg_yes)
      THEN
        u_deliv_head_rtrn_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_no;
      -- ��L�ȊO�̏ꍇ
      ELSE
        u_deliv_head_rtrn_flg_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).return_flag;
      END IF;
    -- �^���A�h�I���C���^�t�F�[�X.�x�������敪 = �u�����v�̏ꍇ
    ELSIF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_bil) THEN
      u_deliv_head_rtrn_flg_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).return_flag;
    END IF;
--
    -- �O���ƎҕύX��
    -- �^���A�h�I���C���^�t�F�[�X.�x�������敪 �� �u�x���v�̏ꍇ
    IF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay) THEN
      -- �^���A�h�I���C���^�t�F�[�X.�p�^�[���敪 �� �u�O���v�̏ꍇ
      IF (ir_deliv_if_rec.pattern_flag = gv_ptn_out) THEN
        u_deliv_head_os_up_cnt_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).outside_up_count + 1;
      -- �^���A�h�I���C���^�t�F�[�X.�p�^�[���敪 �� �u�ɓ����Y�Ɓv�̏ꍇ
      ELSIF (ir_deliv_if_rec.pattern_flag = gv_ptn_it) THEN
        u_deliv_head_os_up_cnt_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).outside_up_count;
      END IF;
    -- �^���A�h�I���C���^�t�F�[�X.�x�������敪 �� �u�����v�̏ꍇ
    ELSIF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_bil) THEN
      u_deliv_head_os_up_cnt_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).outside_up_count;
    END IF;
--
--
    -- *******************************************************************
    -- �����f�[�^�폜�pPL/SQL�\�̐ݒ�
    -- *******************************************************************
    -- �X�V�pPL/SQL�\.�x���m��敪 �� �uNo�v�̏ꍇ
    IF (u_deliv_head_dfn_flg_tab(gn_upd_deliv_head_cnt) = gv_ktg_no) THEN
      -- �����f�[�^�폜�pPL/SQL�\�J�E���^�[�̃J�E���g�A�b�v
      gn_bil_deliv_no_cnt := gn_bil_deliv_no_cnt + 1;
      -- �Ώۃf�[�^�̔z��No��ݒ�
      d_bil_deliv_no_tab(gn_bil_deliv_no_cnt) := u_deliv_head_deliv_no_tab(gn_upd_deliv_head_cnt);
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
  END set_date;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_deliv_head
   * Description      : �^���w�b�_�[�A�h�I���X�V(E-7)
   ***********************************************************************************/
  PROCEDURE upd_deliv_head(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_deliv_head'; -- �v���O������
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
    -- * �^���w�b�_�[�A�h�I��   �X�V
    -- ***********************************
    FORALL ln_index IN u_deliv_head_com_code_id_tab.FIRST .. u_deliv_head_com_code_id_tab.LAST
      UPDATE xxwip_deliverys xd                                  -- �^���w�b�_�[�A�h�I��
-- ##### 20080916 Ver.1.5 T_S_570�Ή� START #####
      --SET    xd.invoice_no             = u_deliv_head_invoice_no_tab(ln_index),  -- 1.�����No
      SET    xd.invoice_no2             = u_deliv_head_invoice_no_tab(ln_index),  -- 1.�����No2
-- ##### 20080916 Ver.1.5 T_S_570�Ή� END #####
             xd.delivery_classe        = u_deliv_head_deliv_cls_tab(ln_index),   -- 2.�z���敪
             xd.report_date            = u_deliv_head_rpt_date_tab(ln_index),    -- 3.�񍐓�
             xd.charged_amount         = u_deliv_head_chrg_amt_tab(ln_index),    -- 4.�����^��
             xd.contract_rate          = u_deliv_head_con_rate_tab(ln_index),    --   �_��^��
             xd.distance               = u_deliv_head_dst_tab(ln_index),         -- 5.�Œ�����
             xd.qty1                   = u_deliv_head_qty1_tab(ln_index),        -- 6.��1
             xd.qty2                   = u_deliv_head_qty2_tab(ln_index),        -- 7.��2
             xd.delivery_weight1       = u_deliv_head_deliv_wht1_tab(ln_index),  -- 8.�d��1
             xd.delivery_weight2       = u_deliv_head_deliv_wht2_tab(ln_index),  -- 9.�d��2
             xd.balance                = u_deliv_head_balance_tab(ln_index),     -- 10.���z
             xd.many_rate              = u_deliv_head_many_rt_tab(ln_index),     -- 11.������
             xd.congestion_charge      = u_deliv_head_cng_chrg_tab(ln_index),    -- 12.�ʍs��
             xd.picking_charge         = u_deliv_head_pic_chrg_tab(ln_index),    -- 13.�s�b�L���O��
             xd.consolid_surcharge     = u_deliv_head_cns_srchrg_tab(ln_index),  -- 14.���ڊ������z
             xd.total_amount           = u_deliv_head_ttl_amt_tab(ln_index),     -- 15.���v
             xd.output_flag            = u_deliv_head_op_flg_tab(ln_index),      -- 16.���ً敪
             xd.defined_flag           = u_deliv_head_dfn_flg_tab(ln_index),     -- 17.�x���m��敪
             xd.return_flag            = u_deliv_head_rtrn_flg_tab(ln_index),    -- 18.�x���m���
             xd.form_update_flag       = u_deliv_head_frm_upd_flg_tab(ln_index), -- 19.��ʍX�V�L��
             xd.outside_up_count       = u_deliv_head_os_up_cnt_tab(ln_index),   -- 20.�O���ƎҕύX
             xd.last_updated_by        = gn_user_id,             -- 21.�ŏI�X�V��
             xd.last_update_date       = gd_sysdate,             -- 22.�ŏI�X�V��
             xd.last_update_login      = gn_login_id,            -- 23.�ŏI�X�V���O�C��
             xd.request_id             = gn_conc_request_id,     -- 24.�v��ID
             xd.program_application_id = gn_prog_appl_id,        -- 25.�ݶ��āE��۸��сE���ع����ID
             xd.program_id             = gn_conc_program_id,     -- 26.�R���J�����g�E�v���O����ID
             xd.program_update_date    = gd_sysdate              -- 27.�v���O�����X�V��
      WHERE  xd.delivery_company_code  = u_deliv_head_com_code_id_tab(ln_index)
      AND    xd.delivery_no            = u_deliv_head_deliv_no_tab(ln_index)
      AND    xd.p_b_classe             = u_deliv_head_p_b_cls_tab(ln_index);
--
    -- �X�V�����̊i�[
-- ##### 20080710 Ver.1.3 ST��Q432�Ή� START #####
--    gn_normal_cnt := u_deliv_head_com_code_id_tab.LAST;
    gn_normal_cnt := u_deliv_head_com_code_id_tab.COUNT;
-- ##### 20080710 Ver.1.3 ST��Q432�Ή� END   #####
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
  END upd_deliv_head;
--
--
  /**********************************************************************************
   * Procedure Name   : del_deliv_head
   * Description      : �^���w�b�_�[�A�h�I���폜(E-8)
   ***********************************************************************************/
  PROCEDURE del_deliv_head(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_deliv_head'; -- �v���O������
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
    -- * �^���w�b�_�[�A�h�I��   �폜
    -- ***********************************
    FORALL ln_index IN d_bil_deliv_no_tab.FIRST .. d_bil_deliv_no_tab.LAST
      DELETE FROM xxwip_deliverys xd   -- �^���w�b�_�[�A�h�I��
      WHERE  xd.p_b_classe  = gv_p_b_cls_bil
      AND    xd.delivery_no = d_bil_deliv_no_tab(ln_index);
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
  END del_deliv_head;
--
--
  /**********************************************************************************
   * Procedure Name   : del_deliv_if
   * Description      : �^���A�h�I���C���^�t�F�[�X�폜(E-9)
   ***********************************************************************************/
  PROCEDURE del_deliv_if(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_deliv_if'; -- �v���O������
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
    -- * �^���A�h�I���C���^�t�F�[�X   �폜
    -- ***********************************
    FORALL ln_index IN d_deliv_if_id_tab.FIRST .. d_deliv_if_id_tab.LAST
      DELETE FROM xxwip_deliverys_if xdi   -- �^���A�h�I���C���^�t�F�[�X
      WHERE  xdi.delivery_id  = d_deliv_if_id_tab(ln_index);
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
  END del_deliv_if;
--
--
  /**********************************************************************************
   * Procedure Name   : out_message
   * Description      : ���b�Z�[�W�o��(E-10)
   ***********************************************************************************/
  PROCEDURE out_message(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_message'; -- �v���O������
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
    lv_message VARCHAR2(5000);   -- ���b�Z�[�W�i�[
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
    -- **************************************************
    -- �ۗ����Ԍo�߃��b�Z�[�W�o�̓��[�v
    -- **************************************************
    -- �^���A�h�I��ID�����݂���ꍇ
    IF (d_rsv_prd_id_tab.EXISTS(1)) THEN
--
      -- �I���X�e�[�^�X���x���ɐݒ�
      ov_retcode := gv_status_warn;
--
      -- �^�C�g���̏o��
      lv_message := '     ';
      lv_message := lv_message || xxcmn_common_pkg.get_msg(gv_wip_msg_kbn,
                                                           gv_wip_msg_73e_306);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_message);
--
      <<reserve_period_loop>>
      FOR ln_index IN d_rsv_prd_id_tab.FIRST .. d_rsv_prd_id_tab.LAST LOOP
        lv_message := '     ' || ln_index || ' ';
        lv_message := lv_message || d_rsv_prd_id_tab(ln_index) || ',';          -- �^���A�h�I��ID
        lv_message := lv_message || d_rsv_prd_ptn_flg_tab(ln_index) || ',';     -- �p�^�[���敪
        lv_message := lv_message || d_rsv_prd_com_cd_tab(ln_index) || ',';      -- �^���Ǝ�
        lv_message := lv_message || d_rsv_prd_no_tab(ln_index) || ',';          -- �z��No
        lv_message := lv_message || d_rsv_prd_invoice_no_tab(ln_index) || ',';  -- �����No
        lv_message := lv_message || d_rsv_prd_p_b_cls_tab(ln_index) || ',';     -- �x�������敪
        lv_message := lv_message || d_rsv_prd_deliv_cls_tab(ln_index) || ',';   -- �z���敪
        lv_message := lv_message || d_rsv_prd_chrg_amt_tab(ln_index) || ',';    -- �����^��
        lv_message := lv_message || d_rsv_prd_qty1_tab(ln_index) || ',';        -- ��1
        lv_message := lv_message || d_rsv_prd_qty2_tab(ln_index) || ',';        -- ��2
        lv_message := lv_message || d_rsv_prd_deliv_wht1_tab(ln_index) || ',';  -- �d��1
        lv_message := lv_message || d_rsv_prd_deliv_wht2_tab(ln_index) || ',';  -- �d��2
        lv_message := lv_message || d_rsv_prd_distance_tab(ln_index) || ',';    -- ����
        lv_message := lv_message || d_rsv_prd_many_rt_tab(ln_index) || ',';     -- ������
        lv_message := lv_message || d_rsv_prd_cng_chrg_tab(ln_index) || ',';    -- �ʍs��
        lv_message := lv_message || d_rsv_prd_pic_chrg_tab(ln_index) || ',';    -- �s�b�L���O��
        lv_message := lv_message || d_rsv_prd_cns_srchrg_tab(ln_index) || ',';  -- ���ڊ������z
        lv_message := lv_message || d_rsv_prd_ttl_amt_tab(ln_index);             -- ���v
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_message);
      END LOOP reserve_period_loop;
    END IF;
--
    -- **************************************************
    -- �z���敪���݂Ȃ����b�Z�[�W�o�̓��[�v
    -- **************************************************
    -- �^���A�h�I��ID�����݂���ꍇ
    IF (d_deliv_cls_id_tab.EXISTS(1)) THEN
--
      -- �I���X�e�[�^�X���x���ɐݒ�
      ov_retcode := gv_status_warn;
--
      -- �^�C�g���̏o��
      lv_message := '     ';
      lv_message := lv_message || xxcmn_common_pkg.get_msg(gv_wip_msg_kbn,
                                                           gv_wip_msg_73e_305);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_message);
--
      <<delivery_classe_loop>>
      FOR ln_index IN d_deliv_cls_id_tab.FIRST .. d_deliv_cls_id_tab.LAST LOOP
        lv_message := '     ' || ln_index || ' ';
        lv_message := lv_message || d_deliv_cls_id_tab(ln_index) || ',';          -- �^���A�h�I��ID
        lv_message := lv_message || d_deliv_cls_ptn_flg_tab(ln_index) || ',';     -- �p�^�[���敪
        lv_message := lv_message || d_deliv_cls_com_cd_tab(ln_index) || ',';      -- �^���Ǝ�
        lv_message := lv_message || d_deliv_cls_no_tab(ln_index) || ',';          -- �z��No
        lv_message := lv_message || d_deliv_cls_invoice_no_tab(ln_index) || ',';  -- �����No
        lv_message := lv_message || d_deliv_cls_p_b_cls_tab(ln_index) || ',';     -- �x�������敪
        lv_message := lv_message || d_deliv_cls_deliv_cls_tab(ln_index) || ',';   -- �z���敪
        lv_message := lv_message || d_deliv_cls_chrg_amt_tab(ln_index) || ',';    -- �����^��
        lv_message := lv_message || d_deliv_cls_qty1_tab(ln_index) || ',';        -- ��1
        lv_message := lv_message || d_deliv_cls_qty2_tab(ln_index) || ',';        -- ��2
        lv_message := lv_message || d_deliv_cls_deliv_wht1_tab(ln_index) || ',';  -- �d��1
        lv_message := lv_message || d_deliv_cls_deliv_wht2_tab(ln_index) || ',';  -- �d��2
        lv_message := lv_message || d_deliv_cls_distance_tab(ln_index) || ',';    -- ����
        lv_message := lv_message || d_deliv_cls_many_rt_tab(ln_index) || ',';     -- ������
        lv_message := lv_message || d_deliv_cls_cng_chrg_tab(ln_index) || ',';    -- �ʍs��
        lv_message := lv_message || d_deliv_cls_pic_chrg_tab(ln_index) || ',';    -- �s�b�L���O��
        lv_message := lv_message || d_deliv_cls_cns_srchrg_tab(ln_index) || ',';  -- ���ڊ������z
        lv_message := lv_message || d_deliv_cls_ttl_amt_tab(ln_index);             -- ���v
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_message);
      END LOOP delivery_classe_loop;
    END IF;
--
    -- **************************************************
    -- �^���X�V�s�\���b�Z�[�W�o�̓��[�v
    -- **************************************************
    -- �^���A�h�I��ID�����݂���ꍇ
    IF (d_not_upd_id_tab.EXISTS(1)) THEN
--
      -- �I���X�e�[�^�X���x���ɐݒ�
      ov_retcode := gv_status_warn;
--
      -- �^�C�g���̏o��
      lv_message := '     ';
      lv_message := lv_message || xxcmn_common_pkg.get_msg(gv_wip_msg_kbn,
                                                           gv_wip_msg_73e_304);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_message);
--
      <<not_update_loop>>
      FOR ln_index IN d_not_upd_id_tab.FIRST .. d_not_upd_id_tab.LAST LOOP
        lv_message := '     ' || ln_index || ' ';
        lv_message := lv_message || d_not_upd_id_tab(ln_index) || ',';          -- �^���A�h�I��ID
        lv_message := lv_message || d_not_upd_ptn_flg_tab(ln_index) || ',';     -- �p�^�[���敪
        lv_message := lv_message || d_not_upd_com_cd_tab(ln_index) || ',';      -- �^���Ǝ�
        lv_message := lv_message || d_not_upd_no_tab(ln_index) || ',';          -- �z��No
        lv_message := lv_message || d_not_upd_invoice_no_tab(ln_index) || ',';  -- �����No
        lv_message := lv_message || d_not_upd_p_b_cls_tab(ln_index) || ',';     -- �x�������敪
        lv_message := lv_message || d_not_upd_deliv_cls_tab(ln_index) || ',';   -- �z���敪
        lv_message := lv_message || d_not_upd_chrg_amt_tab(ln_index) || ',';    -- �����^��
        lv_message := lv_message || d_not_upd_qty1_tab(ln_index) || ',';        -- ��1
        lv_message := lv_message || d_not_upd_qty2_tab(ln_index) || ',';        -- ��2
        lv_message := lv_message || d_not_upd_deliv_wht1_tab(ln_index) || ',';  -- �d��1
        lv_message := lv_message || d_not_upd_deliv_wht2_tab(ln_index) || ',';  -- �d��2
        lv_message := lv_message || d_not_upd_distance_tab(ln_index) || ',';    -- ����
        lv_message := lv_message || d_not_upd_many_rt_tab(ln_index) || ',';     -- ������
        lv_message := lv_message || d_not_upd_cng_chrg_tab(ln_index) || ',';    -- �ʍs��
        lv_message := lv_message || d_not_upd_pic_chrg_tab(ln_index) || ',';    -- �s�b�L���O��
        lv_message := lv_message || d_not_upd_cns_srchrg_tab(ln_index) || ',';  -- ���ڊ������z
        lv_message := lv_message || d_not_upd_ttl_amt_tab(ln_index);             -- ���v
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_message);
      END LOOP not_update_loop;
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
  END out_message;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
-- ##### Ver.1.8 E_�{�ғ�_13659�Ή� START #####
    iv_prod_div   IN  VARCHAR2,     --   ���i�敪
-- ##### Ver.1.8 E_�{�ғ�_13659�Ή� END   #####
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
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
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
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- �O���[�o���E���[�U�[��`�ϐ��̏�����
    gn_deliv_head_cnt       := 0;
    gn_upd_deliv_head_cnt   := 0;
    gn_deliv_cls_cnt        := 0;
    gn_rsv_prd_cnt          := 0;
    gn_not_upd_cnt          := 0;
    gn_bil_deliv_no_cnt     := 0;
    gn_deliv_if_del_cnt     := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- =========================================
    -- �֘A�f�[�^�擾(E-1)
    -- =========================================
    get_related_date(
-- ##### Ver.1.8 E_�{�ғ�_13659�Ή� START #####
      iv_prod_div,       -- ���i�敪
-- ##### Ver.1.8 E_�{�ғ�_13659�Ή� END   #####
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ���b�N�擾(E-2)
    -- =========================================
    get_lock(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- �^���A�h�I���C���^�t�F�[�X�f�[�^�擾(E-3)
    -- =========================================
    get_deliv_if_date(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_normal) THEN
--
      -- ****************************************************
      -- �`�F�b�N���[�v
      -- ****************************************************
      <<chech_loop>>
      FOR ln_index IN gt_deliv_if_tbl.FIRST .. gt_deliv_if_tbl.LAST LOOP
--
        -- =========================================
        -- �X�V�Ώۃ`�F�b�N(E-4)
        -- =========================================
        chk_object(
          gt_deliv_if_tbl(ln_index),   -- �^���A�h�I���C���^�t�F�[�X���R�[�h
          lv_errbuf,                   -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,                  -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- ���^�[���E�R�[�h������̏ꍇ
        ELSIF (lv_retcode = gv_status_normal) THEN
--
          -- =========================================
          -- �^���v�Z�p�f�[�^�擾(E-5)
          -- =========================================
          get_deliv_cal_date(
            gt_deliv_if_tbl(ln_index),   -- �^���A�h�I���C���^�t�F�[�X���R�[�h
            lv_errbuf,                   -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,                  -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- =========================================
          -- �f�[�^�ݒ�(E-6)
          -- =========================================
          set_date(
            gt_deliv_if_tbl(ln_index),   -- �^���A�h�I���C���^�t�F�[�X���R�[�h
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF; -- E-4�̏����ɂă��^�[���E�R�[�h���x���̏ꍇ�A�㏈�����X�L�b�v
--
      END LOOP chech_loop;
--
      -- =========================================
      -- �^���w�b�_�[�A�h�I���X�V(E-7)
      -- =========================================
      upd_deliv_head(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �^���w�b�_�[�A�h�I���폜(E-8)
      -- =========================================
      del_deliv_head(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �^���A�h�I���C���^�t�F�[�X�폜(E-9)
      -- =========================================
      del_deliv_if(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- ���b�Z�[�W�o��(E-10)
      -- =========================================
      out_message(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
-- ##### Ver.1.8 E_�{�ғ�_13659�Ή� START #####
--    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_prod_div   IN  VARCHAR2       --   ���i�敪
-- ##### Ver.1.8 E_�{�ғ�_13659�Ή� END   #####
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
-- ##### Ver.1.8 E_�{�ғ�_13659�Ή� START #####
      iv_prod_div, -- ���i�敪
-- ##### Ver.1.8 E_�{�ғ�_13659�Ή� END   #####
      lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--###########################  �Œ蕔 END   #######################################################
--
END xxwip730003c;
/
