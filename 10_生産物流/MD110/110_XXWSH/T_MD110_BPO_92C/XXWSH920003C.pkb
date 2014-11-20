CREATE OR REPLACE PACKAGE BODY XXWSH920003C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920003C(body)
 * Description      : �ړ��w�������˗������쐬
 * MD.050           : ���Y�������ʁi�o�ׁE�ړ��������j T_MD050_BPO921
 * MD.070           : �ړ��w�������˗������쐬 T_MD070_BPO92C
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 * set_debug_switch       �f�o�b�O�p���O�o�͗p�؂�ւ��X�C�b�`�擾����
 * debug_log              �f�o�b�O�p���O�o�͏���
 * check_parameter        C-1  �p�����[�^�`�F�b�N
 * get_profile            C-2  �v���t�@�C���l�擾
 * purge_table            C-3  �p�[�W����
 * get_data               C-4  ��񒊏o
 * get_rule               C-5  ���[���擾
 * ins_ints_table         C-6  ���ԃe�[�u���o�^(�o��)
 * ins_intm_table         C-7  ���ԃe�[�u���o�^(�ړ�)
 * get_ints_data          C-8  ���ԃe�[�u�����o(�o��)
 * get_intm_data          C-9  ���ԃe�[�u�����o(�ړ�)
 * regi_move_data         C-10 �ړ��˗�/�w���o�^
 * regi_poreq_data        C-11 �����˗��o�^
 * regi_order_detail      C-12 �󒍖��׍X�V
 * regi_move_detail       C-13 �ړ��w��/�w�����׍X�V
 * insert_tables          C-14 �o�^�X�V����
 * calc_weight_capacity   C-15 �d�ʗe�όv�Z/�ύڌ����Z�o
 * submain                ���C�������v���V�[�W��
 * main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/23   1.0   Oracle �y�c ��   ����쐬
 *  2008/06/11   1.1   Oracle ���c ��   �f�o�b�O�o�͐���Ή��B�G���[�n���h�����O�s���̏C���B
 *                                      �d�ʗe�ώZ�o/�ύڌ����Z�o�������v���V�[�W����(C-15)�B
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gn_status_normal NUMBER := 0;
  gn_status_error  NUMBER := 2;
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
--  lock_expt              EXCEPTION;     -- ���b�N(�r�W�[)�G���[
  common_warn_expt       EXCEPTION;
--
--  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name          CONSTANT VARCHAR2(15)  := 'XXWSH920003C';       -- �p�b�P�[�W��
  --�v���t�@�C��
  --���b�Z�[�W�ԍ�
  gv_msg_wsh_13101     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13101';    -- �K�{�p�����[�^
  gv_msg_wsh_13004     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13004';    -- ���t����
  gv_msg_wsh_13005     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13005';    -- ���t�t�]
  gv_msg_wsh_13002     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13002';    -- �v���t�@�C���擾
  gv_msg_wsh_13103     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13103';    -- ���b�N�G���[
  gv_msg_wsh_13006     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13006';    -- �f�[�^�폜�G���[
  gv_msg_wsh_13007     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13007';    -- �݌ɕ�[���擾
  gv_msg_wsh_13008     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13008';    -- �̔Ԋ֐��G���[
  gv_msg_wsh_13009     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13009';    -- �ő�z���敪�Z�o�G���[
  gv_msg_wsh_13124     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13124';    -- ���v�l�Z�o�֐��G���[
  gv_msg_wsh_13172     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13172';    -- �ύڌ����Z�o�֐��G���[
  gv_msg_wsh_13001     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13001';    -- �ύڃI�[�o�[���b�Z�[�W
  gv_msg_wsh_11653     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11653';    -- �݌ɉ�v���ԃN���[�Y�G���[
  --�g�[�N��
  gv_tkn_item          CONSTANT VARCHAR2(15)  := 'ITEM';               -- ���̓p�����[�^
  gv_tkn_item_from     CONSTANT VARCHAR2(15)  := 'ITEM_FROM';          -- ����From
  gv_tkn_item_to       CONSTANT VARCHAR2(15)  := 'ITEM_TO';            -- ����To
  gv_tkn_value         CONSTANT VARCHAR2(15)  := 'VALUE';              -- ���͓��t�l
  gv_tkn_value_from    CONSTANT VARCHAR2(15)  := 'VALUE_FROM';         -- ���͓��tFrom
  gv_tkn_value_to      CONSTANT VARCHAR2(15)  := 'VALUE_TO';           -- ���͓��tTo
  gv_tkn_table_name    CONSTANT VARCHAR2(15)  := 'TABLE_NAME';         -- �e�[�u����
  gv_tkn_prof_name     CONSTANT VARCHAR2(15)  := 'PROF_NAME';          -- �v���t�@�C����
  gv_tkn_param1        CONSTANT VARCHAR2(15)  := 'PARAM1';             -- �p�����[�^1
  gv_tkn_param2        CONSTANT VARCHAR2(15)  := 'PARAM2';             -- �p�����[�^2
  gv_tkn_param3        CONSTANT VARCHAR2(15)  := 'PARAM3';             -- �p�����[�^3
  gv_tkn_param4        CONSTANT VARCHAR2(15)  := 'PARAM4';             -- �p�����[�^4
  gv_tkn_param5        CONSTANT VARCHAR2(15)  := 'PARAM5';             -- �p�����[�^5
  gv_tkn_param6        CONSTANT VARCHAR2(15)  := 'PARAM6';             -- �p�����[�^6
  gv_tkn_param7        CONSTANT VARCHAR2(15)  := 'PARAM7';             -- �p�����[�^7
  gv_tkn_param8        CONSTANT VARCHAR2(15)  := 'PARAM8';             -- �p�����[�^8
  gv_tkn_param9        CONSTANT VARCHAR2(15)  := 'PARAM9';             -- �p�����[�^9
  gv_tkn_param10       CONSTANT VARCHAR2(15)  := 'PARAM10';            -- �p�����[�^10
  gv_tkn_date          CONSTANT VARCHAR2(15)  := 'DATE';               -- �݌ɉ�v���ԃ`�F�b�N
  --�萔
  gv_cons_input_param  CONSTANT VARCHAR2(100) := '���̓p�����[�^�l';   -- '���̓p�����[�^�l'
  gv_cons_m_org_id     CONSTANT VARCHAR2(50)  := 'XXCMN_MASTER_ORG_ID';-- �}�X�^�g�DID
  gv_cons_m_org_id_tkn CONSTANT VARCHAR2(50)  := 'XXCMN:�}�X�^�g�DID'; -- �}�X�^�g�DID
  gv_cons_msg_kbn_wsh  CONSTANT VARCHAR2(5)   := 'XXWSH';              -- ���b�Z�[�W�敪XXWSH
  gv_cons_msg_kbn_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN';              -- ���b�Z�[�W�敪XXCMN
  gv_cons_t_deliv      CONSTANT VARCHAR2(1)   := '1';                  -- '�o�׈˗�'(�������)
  gv_cons_t_move       CONSTANT VARCHAR2(1)   := '3';                  -- '�ړ��w��'(�������)
  gv_cons_a_type       CONSTANT VARCHAR2(15)  := '�������';           -- '�������'
  gv_cons_deliv_f      CONSTANT VARCHAR2(15)  := '�o�Ɍ�';             -- '�o�Ɍ�'
  gv_cons_deliv_type   CONSTANT VARCHAR2(15)  := '�o�Ɍ`��';           -- '�o�Ɍ`��'
  gv_cons_obj_d_from   CONSTANT VARCHAR2(15)  := '�Ώۊ���From';       -- '�Ώۊ���From'
  gv_cons_obj_d_to     CONSTANT VARCHAR2(15)  := '�Ώۊ���To';         -- '�Ώۊ���To'
  gv_cons_ship_date    CONSTANT VARCHAR2(15)  := '�o�ɓ��w��';         -- '�o�ɓ��w��'
  gv_cons_arvl_date    CONSTANT VARCHAR2(15)  := '�����w��';           -- '�����w��'
  gv_cons_inst_p_code  CONSTANT VARCHAR2(15)  := '�w�������w��';       -- '�w�������w��'
  gv_cons_dlv_tmp_jp   CONSTANT VARCHAR2(50)  := '�o�׍݌ɕ�[�����ԃe�[�u��';
  gv_cons_dlv_tmp_tbl  CONSTANT VARCHAR2(50)  := 'xxwsh_shipping_stock_rep_tmp';
                                                                 -- �o�׍݌ɕ�[�����ԃe�[�u��
  gv_cons_mov_tmp_tbl  CONSTANT VARCHAR2(50)  := 'xxwsh_mov_stock_rep_tmp';
                                                                 -- �ړ��݌ɕ�[�����ԃe�[�u��
  gv_cons_mov_tmp_jp   CONSTANT VARCHAR2(50)  := '�ړ��݌ɕ�[�����ԃe�[�u��';
  gv_cons_mov_hdr_tbl  CONSTANT VARCHAR2(50)  := '�ړ��˗�/�w���w�b�_�e�[�u��';
  gv_cons_odr_hdr_tbl  CONSTANT VARCHAR2(50)  := '�����˗��w�b�_�e�[�u��';
  gv_cons_odr_cat_ret  CONSTANT VARCHAR2(15)  := 'RETURN';             -- �󒍃J�e�S��(RETURN)
  gv_cons_status_shime CONSTANT VARCHAR2(2)   := '03';                 -- �u���ߍς݁v
  gv_cons_flg_y        CONSTANT VARCHAR2(1)   := 'Y';                  -- �t���O 'Y'
  gv_cons_flg_n        CONSTANT VARCHAR2(1)   := 'N';                  -- �t���O 'N'
  gv_cons_flg_on       CONSTANT VARCHAR2(1)   := '1';                  -- �t���O '1'=ON
  gv_cons_flg_off      CONSTANT VARCHAR2(1)   := '0';                  -- �t���O '0'=OFF
  gv_cons_id_drink     CONSTANT VARCHAR2(1)   := '2';                  -- ���i�敪�E�h�����N
  gv_cons_id_leaf      CONSTANT VARCHAR2(1)   := '1';                  -- ���i�敪�E���[�t
  gv_cons_item_product CONSTANT VARCHAR2(1)   := '5';                  -- �u���i�v
  gv_cons_mov_sts_e    CONSTANT VARCHAR2(2)   := '02';                 -- �u�˗��ρv
  gv_cons_mov_sts_c    CONSTANT VARCHAR2(2)   := '03';                 -- �u�������v
  gv_cons_move_type    CONSTANT VARCHAR2(1)   := '1';                  -- �u�ϑ�����v
  gv_cons_rule_move    CONSTANT VARCHAR2(1)   := '0';                  -- �u�ړ��v
  gv_cons_rule_order   CONSTANT VARCHAR2(1)   := '1';                  -- �u�����v
  gv_cons_schema_wsh   CONSTANT VARCHAR2(5)   := 'XXWSH';              -- �X�L�[�}XXWSH
  gv_cons_seq_move     CONSTANT VARCHAR2(1)   := '1';                  -- �̔ԋ敪�u�ړ��v
  gv_cons_seq_order    CONSTANT VARCHAR2(1)   := '2';                  -- �̔ԋ敪�u�����v
  gv_cons_sts_mi       CONSTANT VARCHAR2(2)   := '10';                 -- �ʒm�X�e�[�^�X�u���ʒm�v
  gv_cons_umu_ari      CONSTANT VARCHAR2(1)   := '1';                  -- �L���敪�u�L�v
  gv_cons_wh           CONSTANT VARCHAR2(1)   := '4';                  -- �R�[�h�敪�u�q�Ɂv
  gv_cons_ds_deliv     CONSTANT VARCHAR2(1)   := '2';                  -- �����q�ɋ敪�u�o�ׁv
  gv_cons_ds_normal    CONSTANT VARCHAR2(1)   := '1';                  -- �����q�ɋ敪�u�ʏ�v
  gv_cons_ds_type_d    CONSTANT VARCHAR2(1)   := '1';                  -- ����
  gv_cons_ds_type_n    CONSTANT VARCHAR2(1)   := '0';                  -- �����ȊO
  gv_cons_wild_card    CONSTANT VARCHAR2(7)   := 'ZZZZZZZ';            -- �i�ڃR�[�h('ZZZZZZZ')
  gv_cons_weight       CONSTANT VARCHAR2(1)   := '1';                  -- �d�ʗe�ϋ敪�u�d�ʁv
  gv_cons_capacity     CONSTANT VARCHAR2(1)   := '2';                  -- �d�ʗe�ϋ敪�u�e�ρv
  gv_cons_p_flg_prod   CONSTANT VARCHAR2(1)   := '1';                  -- ���i���ʋ敪�u���i�v
  gv_cons_p_flg_noprod CONSTANT VARCHAR2(1)   := '2';                  -- ���i���ʋ敪�u���i�ȊO�v
  gv_cons_over_1y      CONSTANT VARCHAR2(1)   := '1';               -- �ύڃI�[�o�[�敪�u�I�[�o�[�v
  gv_cons_over_0n      CONSTANT VARCHAR2(1)   := '0';               -- �ύڃI�[�o�[�敪�u����v
  gv_cons_no_cont_freight   CONSTANT VARCHAR2(1)   := '0';                  -- �_��O�^���敪�u�ΏۊO�v
  gv_cons_po_sts       CONSTANT VARCHAR2(2)   := '10';                 -- �u�˗��쐬�ρv
  gv_change_flag_n     CONSTANT VARCHAR2(2)   := 'N';                  -- �ύX�敪�u�ύX�Ȃ��v
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_organization_id   NUMBER :=0;       -- �}�X�^�g�DID
  gn_target_cnt_deliv  NUMBER :=0;       -- �Ώی���(�o��)
  gn_target_cnt_move   NUMBER :=0;       -- �Ώی���(�ړ�)
  gn_upd_data_cnt_ol   NUMBER :=0;       -- �󒍖��׍X�V�Ώی���
  gn_upd_data_cnt_ml   NUMBER :=0;       -- �ړ��˗�/�w�����׍X�V�Ώی���
  gn_ins_data_cnt_ph   NUMBER :=0;       -- �����˗��w�b�_�}���Ώی���
  gn_ins_data_cnt_pl   NUMBER :=0;       -- �����˗����ב}���Ώی���
  gn_ins_data_cnt_mh   NUMBER :=0;       -- �ړ��˗�/�w���w�b�_�}���Ώی���
  gn_ins_data_cnt_ml   NUMBER :=0;       -- �ړ��˗�/�w�����ב}���Ώی���
  gn_login_user        NUMBER;           -- ���O�C��ID
  gn_created_by        NUMBER;           -- ���O�C�����[�UID
  gn_conc_request_id   NUMBER;           -- �v��ID
  gn_prog_appl_id      NUMBER;           -- �A�v���P�[�V����ID
  gn_conc_program_id   NUMBER;           -- �v���O����ID
  gn_mov_hdr_id        xxinv_mov_req_instr_headers.mov_hdr_id%TYPE;              -- �ړ��w�b�_ID
  gn_poreq_hdr_id      xxpo_requisition_headers.requisition_header_id%TYPE;      -- �����w�b�_ID
--
-- �w�b�_�P�ʍ��ڕۑ��p(�ړ�)
  gv_stock_rep_origin_m  xxwsh_shipping_stock_rep_tmp.stock_rep_origin%TYPE;     -- �݌ɕ�[��
  gv_deliver_from_m      xxwsh_shipping_stock_rep_tmp.deliver_from%TYPE;         -- �o�׌��R�[�h
  gv_prod_class_code_m   xxwsh_shipping_stock_rep_tmp.prod_class_code%TYPE;      -- ���i�敪
  gv_weight_capacity_class_m xxwsh_shipping_stock_rep_tmp.weight_capacity_class%TYPE;
                                                                                 -- �d�ʗe�ϋ敪
  gv_product_flg_m       xxinv_mov_req_instr_headers.product_flg%TYPE;           -- ���i���ʋ敪
  gv_item_class_code_m   xxwsh_shipping_stock_rep_tmp.item_class_code%TYPE;      -- �i�ڋ敪
  gv_stock_rep_rule_m    xxwsh_shipping_stock_rep_tmp.stock_rep_rule%TYPE;       --�݌ɕ�[���[��
-- �w�b�_�P�ʍ��ڕۑ��p(����)
  gv_stock_rep_origin_p  xxwsh_shipping_stock_rep_tmp.stock_rep_origin%TYPE;     -- �݌ɕ�[��
  gv_deliver_from_p      xxwsh_shipping_stock_rep_tmp.deliver_from%TYPE;         -- �o�׌��R�[�h
  gv_deliver_to_p        xxwsh_shipping_stock_rep_tmp.deliver_to%TYPE;           -- �o�א�R�[�h
  gv_stock_rep_rule_p    xxwsh_shipping_stock_rep_tmp.stock_rep_rule%TYPE;       --�݌ɕ�[���[��
-- ���גP�ʍ��ڕۑ��p(�ړ�)
  gv_item_code_ml        xxwsh_mov_stock_rep_tmp.item_code%TYPE;           -- �i�ڃR�[�h
-- ���גP�ʍ��ڕۑ��p(����)
  gv_item_code_pl        xxwsh_mov_stock_rep_tmp.item_code%TYPE;           -- �i�ڃR�[�h
  gn_line_number            NUMBER := 0;                                   -- ���הԍ�(�ړ�)
  gn_order_line_number      NUMBER := 0;                                   -- ���הԍ�(��)
--���v�ێ��p
  gn_sum_quantity           NUMBER :=0;                                    -- ���v����
  gn_sum_small_quantity     NUMBER :=0;                                    -- ���v������
  gn_sum_weight             NUMBER :=0;                                    -- ���v���ڏd��
  gn_sum_capacity           NUMBER :=0;                                    -- ���v���ڗe��
  gn_sum_inst_quantity      NUMBER :=0;                                  -- �w�b�_���v�w������(�ړ�)
  gn_sum_inst_line_quantity NUMBER :=0;                                    -- ���׍��v�w������(�ړ�)
  gn_sum_req_line_quantity  NUMBER :=0;                                    -- ���׍��v�˗�����(����)
--
-- �f�o�b�O�p
  gb_debug                  BOOLEAN DEFAULT FALSE;    --�f�o�b�O���O�o�͗p�X�C�b�`
--
  -- C-4, C-8 �o�׏�񒊏o�̃f�[�^���i�[���郌�R�[�h
  TYPE deliv_data_rec IS RECORD(
    deliver_to_id             xxwsh_shipping_stock_rep_tmp.deliver_to_id%TYPE,    -- �o�א�ID
    deliver_to                xxwsh_shipping_stock_rep_tmp.deliver_to%TYPE,       -- �o�א�R�[�h
    request_no                xxwsh_shipping_stock_rep_tmp.request_no%TYPE,       -- �˗�No
    deliver_from_id           xxwsh_shipping_stock_rep_tmp.deliver_from_id%TYPE,  -- �o�׌�ID
    deliver_from              xxwsh_shipping_stock_rep_tmp.deliver_from%TYPE,     -- �o�׌��R�[�h
    weight_capacity_class     xxwsh_shipping_stock_rep_tmp.weight_capacity_class%TYPE,
                                                                                  -- �d�ʗe�ϋ敪
    shipping_inventory_item_id xxwsh_shipping_stock_rep_tmp.shipping_inventory_item_id%TYPE,
                                                                                  -- �o�וi��ID
    item_id                   xxwsh_shipping_stock_rep_tmp.item_id%TYPE,          -- OPM�i��ID
    shipping_item_code        xxwsh_shipping_stock_rep_tmp.shipping_item_code%TYPE, -- �i�ڃR�[�h
    quantity                  xxwsh_shipping_stock_rep_tmp.quantity%TYPE,         -- ����
    order_type_id             xxwsh_shipping_stock_rep_tmp.order_type_id%TYPE,    -- �󒍃^�C�vID
    transaction_type_name     xxwsh_shipping_stock_rep_tmp.transaction_type_name%TYPE,-- �o�Ɍ`��
    item_class_code           xxwsh_shipping_stock_rep_tmp.item_class_code%TYPE,  -- �i�ڋ敪
    product_flg               xxinv_mov_req_instr_headers.product_flg%TYPE,       -- ���i���ʃt���O
    prod_class_code           xxwsh_shipping_stock_rep_tmp.prod_class_code%TYPE,  -- ���i�敪
    drop_ship_wsh_div         xxwsh_shipping_stock_rep_tmp.drop_ship_wsh_div%TYPE,-- �����敪
    num_of_deliver            xxwsh_shipping_stock_rep_tmp.num_of_deliver%TYPE,   -- �o�ד���
    conv_unit                 xxwsh_shipping_stock_rep_tmp.conv_unit%TYPE,        -- ���o�Ɋ��Z�P��
    num_of_cases              xxwsh_shipping_stock_rep_tmp.num_of_cases%TYPE,     -- �P�[�X����
    item_um                   xxwsh_shipping_stock_rep_tmp.item_um%TYPE,          -- �P��
    frequent_qty              xxwsh_shipping_stock_rep_tmp.frequent_qty%TYPE,     -- ��\����
    stock_rep_rule            xxwsh_shipping_stock_rep_tmp.stock_rep_rule%TYPE,   -- �݌ɕ�[���[��
    stock_rep_origin          xxwsh_shipping_stock_rep_tmp.stock_rep_origin%TYPE  -- �݌ɕ�[��
  );
  TYPE deliv_data_tbl IS TABLE OF deliv_data_rec INDEX BY PLS_INTEGER;
  gr_deliv_data_tbl deliv_data_tbl;
--
  -- C-4, C-9 �ړ���񒊏o�̃f�[�^���i�[���郌�R�[�h
  TYPE move_data_rec IS RECORD(
    mov_num                xxwsh_mov_stock_rep_tmp.mov_num%TYPE,              -- �ړ�No
    shipped_locat_id       xxwsh_mov_stock_rep_tmp.shipped_locat_id%TYPE,     -- �o�Ɍ�ID
    shipped_locat_code     xxwsh_mov_stock_rep_tmp.shipped_locat_code%TYPE,   -- �o�Ɍ��R�[�h
    ship_to_locat_id       xxwsh_mov_stock_rep_tmp.ship_to_locat_id%TYPE,     -- ���ɐ�ID
    ship_to_locat_code     xxwsh_mov_stock_rep_tmp.ship_to_locat_code%TYPE,   -- ���ɐ�R�[�h
    weight_capacity_class  xxwsh_mov_stock_rep_tmp.weight_capacity_class%TYPE,-- �d�ʗe�ϋ敪
    item_id                xxwsh_mov_stock_rep_tmp.item_id%TYPE,              -- �i��ID
    inventory_item_id      xxwsh_mov_stock_rep_tmp.inventory_item_id%TYPE,    -- �݌ɕi��ID
    item_code              xxwsh_mov_stock_rep_tmp.item_code%TYPE,            -- �i�ڃR�[�h
    instruct_qty           xxwsh_mov_stock_rep_tmp.instruct_qty%TYPE,         -- �w������
    item_class_code        xxwsh_mov_stock_rep_tmp.item_class_code%TYPE,      -- �i�ڋ敪
    product_flg            xxinv_mov_req_instr_headers.product_flg%TYPE,      -- ���i���ʃt���O
    prod_class_code        xxwsh_mov_stock_rep_tmp.prod_class_code%TYPE,      -- ���i�敪
    num_of_deliver         xxwsh_mov_stock_rep_tmp.num_of_deliver%TYPE,       -- �o�ד���
    conv_unit              xxwsh_mov_stock_rep_tmp.conv_unit%TYPE,            -- ���o�Ɋ��Z�P��
    num_of_cases           xxwsh_mov_stock_rep_tmp.num_of_cases%TYPE,         -- �P�[�X����
    item_um                xxwsh_mov_stock_rep_tmp.item_um%TYPE,              -- �P��
    frequent_qty           xxwsh_mov_stock_rep_tmp.frequent_qty%TYPE,         -- ��\����
    stock_rep_rule         xxwsh_mov_stock_rep_tmp.stock_rep_rule%TYPE,       -- �݌ɕ�[���[��
    stock_rep_origin       xxwsh_mov_stock_rep_tmp.stock_rep_origin%TYPE      -- �݌ɕ�[��
  );
  TYPE move_data_tbl IS TABLE OF move_data_rec INDEX BY PLS_INTEGER;
  gr_move_data_tbl move_data_tbl;
--
  -- �o�׏�񒊏o�̃f�[�^(FORALL�ł�INSERT�p)
  TYPE s_deliver_to_id                 -- �o�א�ID
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.deliver_to_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_deliver_to                    -- �o�א�R�[�h
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.deliver_to%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_request_no                    -- �˗�No
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.request_no%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_deliver_from_id               -- �o�׌�ID
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.deliver_from_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_deliver_from                  -- �o�׌��R�[�h
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.deliver_from%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_weight_capacity_class         -- �d�ʗe�ϋ敪
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.weight_capacity_class%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_shipping_inventory_item_id    -- �o�וi��ID
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.shipping_inventory_item_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_item_id                       -- �o�וi��ID
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.item_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_shipping_item_code            -- �i�ڃR�[�h
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.shipping_item_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_quantity                      -- ����
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_order_type_id                 -- �󒍃^�C�vID
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.order_type_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_transaction_type_name         -- �o�Ɍ`��
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.transaction_type_name%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_item_class_code               -- �i�ڋ敪
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.item_class_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_prod_class_code               -- ���i�敪
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.prod_class_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_drop_ship_wsh_div             -- �����敪
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.drop_ship_wsh_div%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_num_of_deliver                -- �o�ד���
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.num_of_deliver%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_conv_unit                     -- ���o�Ɋ��Z�P��
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.conv_unit%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_num_of_cases                  -- �P�[�X����
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.num_of_cases%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_item_um                       -- �P��
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.item_um%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_frequent_qty                  -- ��\����
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.frequent_qty%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_stock_rep_rule                -- �݌ɕ�[���[��
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.stock_rep_rule%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_stock_rep_origin              -- �݌ɕ�[��
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.stock_rep_origin%TYPE
    INDEX BY BINARY_INTEGER;
--
  -- �ړ���񒊏o�̃f�[�^(FORALL�ł�INSERT�p)
  TYPE i_mov_num                       -- �ړ��w�b�_ID
    IS TABLE OF xxwsh_mov_stock_rep_tmp.mov_num%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_shipped_locat_id              -- �o�Ɍ�ID
    IS TABLE OF xxwsh_mov_stock_rep_tmp.shipped_locat_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_shipped_locat_code            -- �o�Ɍ��R�[�h
    IS TABLE OF xxwsh_mov_stock_rep_tmp.shipped_locat_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_ship_to_locat_id              -- ���ɐ�ID
    IS TABLE OF xxwsh_mov_stock_rep_tmp.ship_to_locat_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_ship_to_locat_code            -- ���ɐ�R�[�h
    IS TABLE OF xxwsh_mov_stock_rep_tmp.ship_to_locat_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_weight_capacity_class         -- �d�ʗe�ϋ敪
    IS TABLE OF xxwsh_mov_stock_rep_tmp.weight_capacity_class%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_item_id                       -- �i��ID
    IS TABLE OF xxwsh_mov_stock_rep_tmp.item_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_inventory_item_id             -- �݌ɕi��ID
    IS TABLE OF xxwsh_mov_stock_rep_tmp.inventory_item_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_item_code                     -- �i�ڃR�[�h
    IS TABLE OF xxwsh_mov_stock_rep_tmp.item_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_instruct_qty                  -- �w������
    IS TABLE OF xxwsh_mov_stock_rep_tmp.instruct_qty%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_item_class_code               -- �i�ڋ敪
    IS TABLE OF xxwsh_mov_stock_rep_tmp.item_class_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_prod_class_code               -- ���i�敪
    IS TABLE OF xxwsh_mov_stock_rep_tmp.prod_class_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_num_of_deliver                -- �o�ד���
    IS TABLE OF xxwsh_mov_stock_rep_tmp.num_of_deliver%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_conv_unit                     -- ���o�Ɋ��Z�P��
    IS TABLE OF xxwsh_mov_stock_rep_tmp.conv_unit%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_num_of_cases                  -- �P�[�X����
    IS TABLE OF xxwsh_mov_stock_rep_tmp.num_of_cases%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_item_um                       -- �P��
    IS TABLE OF xxwsh_mov_stock_rep_tmp.item_um%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_frequent_qty                  -- ��\����
    IS TABLE OF xxwsh_mov_stock_rep_tmp.frequent_qty%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_stock_rep_rule                -- �݌ɕ�[���[��
    IS TABLE OF xxwsh_mov_stock_rep_tmp.stock_rep_rule%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_stock_rep_origin              -- �݌ɕ�[��
    IS TABLE OF xxwsh_mov_stock_rep_tmp.stock_rep_origin%TYPE
    INDEX BY BINARY_INTEGER;
--
  -- �o�׏�񒊏o�̃f�[�^(FORALL�ł�INSERT�p)
  gt_s_deliver_to_id              s_deliver_to_id;              -- �o�א�ID
  gt_s_deliver_to                 s_deliver_to;                 -- �o�א�R�[�h
  gt_s_request_no                 s_request_no;                 -- �˗�No
  gt_s_deliver_from_id            s_deliver_from_id;            -- �o�׌�ID
  gt_s_deliver_from               s_deliver_from;               -- �o�׌��R�[�h
  gt_s_weight_capacity_class      s_weight_capacity_class;      -- �d�ʗe�ϋ敪
  gt_s_shipping_inv_item_id       s_shipping_inventory_item_id; -- �o�וi��ID
  gt_s_item_id                    s_item_id;                    -- �o�וi��ID
  gt_s_shipping_item_code         s_shipping_item_code;         -- �i�ڃR�[�h
  gt_s_quantity                   s_quantity;                   -- ����
  gt_s_order_type_id              s_order_type_id;              -- �󒍃^�C�vID
  gt_s_transaction_type_name      s_transaction_type_name;      -- �o�Ɍ`��
  gt_s_item_class_code            s_item_class_code;            -- �i�ڋ敪
  gt_s_prod_class_code            s_prod_class_code;            -- ���i�敪
  gt_s_drop_ship_wsh_div          s_drop_ship_wsh_div;          -- �����敪
  gt_s_num_of_deliver             s_num_of_deliver;             -- �o�ד���
  gt_s_conv_unit                  s_conv_unit;                  -- ���o�Ɋ��Z�P��
  gt_s_num_of_cases               s_num_of_cases;               -- �P�[�X����
  gt_s_item_um                    s_item_um;                    -- �P��
  gt_s_frequent_qty               s_frequent_qty;               -- ��\����
  gt_s_stock_rep_rule             s_stock_rep_rule;             -- �݌ɕ�[���[��
  gt_s_stock_rep_origin           s_stock_rep_origin;           -- �݌ɕ�[��
--
  -- �ړ���񒊏o�̃f�[�^(FORALL�ł�INSERT�p)
  gt_i_mov_num                    i_mov_num;                    -- �ړ��ԍ�
  gt_i_shipped_locat_id           i_shipped_locat_id;           -- �o�Ɍ�ID
  gt_i_shipped_locat_code         i_shipped_locat_code;         -- �o�Ɍ��R�[�h
  gt_i_ship_to_locat_id           i_ship_to_locat_id;           -- ���ɐ�ID
  gt_i_ship_to_locat_code         i_ship_to_locat_code;         -- ���ɐ�R�[�h
  gt_i_weight_capacity_class      i_weight_capacity_class;      -- �d�ʗe�ϋ敪
  gt_i_item_id                    i_item_id;                    -- �i��ID
  gt_i_inventory_item_id          i_inventory_item_id;          -- �݌ɕi�ڃR�[�h
  gt_i_item_code                  i_item_code;                  -- �i�ڃR�[�h
  gt_i_instruct_qty               i_instruct_qty;               -- �w������
  gt_i_item_class_code            i_item_class_code;            -- �i�ڋ敪
  gt_i_prod_class_code            i_prod_class_code;            -- ���i�敪
  gt_i_num_of_deliver             i_num_of_deliver;             -- �o�ד���
  gt_i_conv_unit                  i_conv_unit;                  -- ���o�Ɋ��Z�P��
  gt_i_num_of_cases               i_num_of_cases;               -- �P�[�X����
  gt_i_item_um                    i_item_um;                    -- �P��
  gt_i_frequent_qty               i_frequent_qty;               -- ��\����
  gt_i_stock_rep_rule             i_stock_rep_rule;             -- �݌ɕ�[���[��
  gt_i_stock_rep_origin           i_stock_rep_origin;           -- �݌ɕ�[��
--
  -- C-10 �ړ��˗�/�w���w�b�_�̃f�[�^���i�[���郌�R�[�h
  TYPE move_header_rec IS RECORD(
    mov_hdr_id                  xxinv_mov_req_instr_headers.mov_hdr_id%TYPE,
    -- �ړ��w�b�_ID
    mov_num                     xxinv_mov_req_instr_headers.mov_num%TYPE,
    -- �ړ��ԍ�
    mov_type                    xxinv_mov_req_instr_headers.mov_type%TYPE,
    -- �ړ��^�C�v
    entered_date                xxinv_mov_req_instr_headers.entered_date%TYPE,
    -- ���͓�
    instruction_post_code       xxinv_mov_req_instr_headers.instruction_post_code%TYPE,
    -- �w������
    status                      xxinv_mov_req_instr_headers.status%TYPE,
    -- �X�e�[�^�X
    notif_status                xxinv_mov_req_instr_headers.notif_status%TYPE,
    -- �ʒm�X�e�[�^�X
    shipped_locat_id            xxinv_mov_req_instr_headers.shipped_locat_id%TYPE,
    -- �o�Ɍ�ID
    shipped_locat_code          xxinv_mov_req_instr_headers.shipped_locat_code%TYPE,
    -- �o�Ɍ��ۊǏꏊ
    ship_to_locat_id            xxinv_mov_req_instr_headers.ship_to_locat_id%TYPE,
    -- ���ɐ�ID
    ship_to_locat_code          xxinv_mov_req_instr_headers.ship_to_locat_code%TYPE,
    -- ���ɐ�ۊǏꏊ
    schedule_ship_date          xxinv_mov_req_instr_headers.schedule_ship_date%TYPE,
    -- �o�ɗ\���
    schedule_arrival_date       xxinv_mov_req_instr_headers.schedule_arrival_date%TYPE,
    -- ���ɗ\���
    freight_charge_class        xxinv_mov_req_instr_headers.freight_charge_class%TYPE,
    -- �^���敪
    collected_pallet_qty        xxinv_mov_req_instr_headers.collected_pallet_qty%TYPE,
    -- �p���b�g�������
    out_pallet_qty              xxinv_mov_req_instr_headers.out_pallet_qty%TYPE,
    -- �p���b�g����(�o)
    in_pallet_qty               xxinv_mov_req_instr_headers.in_pallet_qty%TYPE,
    -- �p���b�g����(��)
    no_cont_freight_class       xxinv_mov_req_instr_headers.no_cont_freight_class%TYPE,
    -- �_��O�^���敪
    delivery_no                 xxinv_mov_req_instr_headers.delivery_no%TYPE,
    -- �z��No
    description                 xxinv_mov_req_instr_headers.description%TYPE,
    -- �E�v
    loading_efficiency_weight   xxinv_mov_req_instr_headers.loading_efficiency_weight%TYPE,
    -- �ύڗ�(�d��)
    loading_efficiency_capacity xxinv_mov_req_instr_headers.loading_efficiency_capacity%TYPE,
    -- �ύڗ�(�e��)
    organization_id             xxinv_mov_req_instr_headers.organization_id%TYPE,
    -- �g�DID
    career_id                   xxinv_mov_req_instr_headers.career_id%TYPE,
    -- �^���Ǝ�ID
    freight_carrier_code        xxinv_mov_req_instr_headers.freight_carrier_code%TYPE,
    -- �^���Ǝ�
    shipping_method_code        xxinv_mov_req_instr_headers.shipping_method_code%TYPE,
    -- �z���敪
    actual_career_id            xxinv_mov_req_instr_headers.actual_career_id%TYPE,
    -- �^���Ǝ�ID_����
    actual_freight_carrier_code xxinv_mov_req_instr_headers.actual_freight_carrier_code%TYPE,
    -- �^���Ǝ�_����
    actual_shipping_method_code xxinv_mov_req_instr_headers.actual_shipping_method_code%TYPE,
    -- �z���敪_����
    arrival_time_from           xxinv_mov_req_instr_headers.arrival_time_from%TYPE,
    -- ���׎���FROM
    arrival_time_to             xxinv_mov_req_instr_headers.arrival_time_to%TYPE,
    -- ���׎���TO
    slip_number                 xxinv_mov_req_instr_headers.slip_number%TYPE,
    -- �����No
    sum_quantity                xxinv_mov_req_instr_headers.sum_quantity%TYPE,
    -- ���v����
    small_quantity              xxinv_mov_req_instr_headers.small_quantity%TYPE,
    -- ������
    label_quantity              xxinv_mov_req_instr_headers.label_quantity%TYPE,
    -- ���x������
    based_weight                xxinv_mov_req_instr_headers.based_weight%TYPE,
    -- ��{�d��
    based_capacity              xxinv_mov_req_instr_headers.based_capacity%TYPE,
    -- ��{�e��
    sum_weight                  xxinv_mov_req_instr_headers.sum_weight%TYPE,
    -- ���ڏd�ʍ��v
    sum_capacity                xxinv_mov_req_instr_headers.sum_capacity%TYPE,
    -- ���ڗe�ύ��v
    sum_pallet_weight           xxinv_mov_req_instr_headers.sum_pallet_weight%TYPE,
    -- ���v�p���b�g�d��
    pallet_sum_quantity         xxinv_mov_req_instr_headers.pallet_sum_quantity%TYPE,
    -- �p���b�g���v����
    mixed_ratio                 xxinv_mov_req_instr_headers.mixed_ratio%TYPE,
    -- ���ڗ�
    weight_capacity_class       xxinv_mov_req_instr_headers.weight_capacity_class%TYPE,
    -- �d�ʗe�ϋ敪
    actual_ship_date            xxinv_mov_req_instr_headers.actual_ship_date%TYPE,
    -- �o�Ɏ��ѓ�
    actual_arrival_date         xxinv_mov_req_instr_headers.actual_arrival_date%TYPE,
    -- ���Ɏ��ѓ�
    mixed_sign                  xxinv_mov_req_instr_headers.mixed_sign%TYPE,
    -- ���ڋL��
    batch_no                    xxinv_mov_req_instr_headers.batch_no%TYPE,
    -- ��zNo
    item_class                  xxinv_mov_req_instr_headers.item_class%TYPE,
    -- ���i�敪
    product_flg                 xxinv_mov_req_instr_headers.product_flg%TYPE,
    -- ���i���ʋ敪
    no_instr_actual_class       xxinv_mov_req_instr_headers.no_instr_actual_class%TYPE,
    -- �w���Ȃ����ы敪
    comp_actual_flg             xxinv_mov_req_instr_headers.comp_actual_flg%TYPE,
    -- ���ьv��σt���O
    correct_actual_flg          xxinv_mov_req_instr_headers.correct_actual_flg%TYPE,
    -- ���ђ����t���O
    prev_notif_status           xxinv_mov_req_instr_headers.prev_notif_status%TYPE,
    -- �O��ʒm�X�e�[�^�X
    notif_date                  xxinv_mov_req_instr_headers.notif_date%TYPE,
    -- �m��ʒm���ѓ���
    prev_delivery_no            xxinv_mov_req_instr_headers.prev_delivery_no%TYPE,
    -- �O��z��No
    new_modify_flg              xxinv_mov_req_instr_headers.new_modify_flg%TYPE,
    -- �V�K�C���t���O
    screen_update_by            xxinv_mov_req_instr_headers.screen_update_by%TYPE,
    -- ��ʍX�V��
    screen_update_date          xxinv_mov_req_instr_headers.screen_update_date%TYPE,
    -- ��ʍX�V����
    created_by                  xxinv_mov_req_instr_headers.created_by%TYPE,
    -- �쐬��
    creation_date               xxinv_mov_req_instr_headers.creation_date%TYPE,
    -- �쐬��
    last_updated_by             xxinv_mov_req_instr_headers.last_updated_by%TYPE,
    -- �ŏI�X�V��
    last_update_date            xxinv_mov_req_instr_headers.last_update_date%TYPE,
    -- �ŏI�X�V��
    last_update_login           xxinv_mov_req_instr_headers.last_update_login%TYPE,
    -- �ŏI�X�V���O�C��
    request_id                  xxinv_mov_req_instr_headers.request_id%TYPE,
    -- �v��ID
    program_application_id      xxinv_mov_req_instr_headers.program_application_id%TYPE,
    -- �R���J�����g�v���O�����A�v���P�[�V����ID
    program_id                  xxinv_mov_req_instr_headers.program_id%TYPE,
    -- �R���J�����g�v���O����ID
    program_update_date         xxinv_mov_req_instr_headers.program_update_date%TYPE,
    -- �v���O�����X�V��
    not_insert_flg              VARCHAR2(1)
    -- �G���[�����ɂ��o�^���O���R�[�h���ʃt���O
  );
  TYPE move_header_tbl IS TABLE OF move_header_rec INDEX BY PLS_INTEGER;
  gr_move_header_tbl  move_header_tbl;
--
  -- �ړ��˗�/�w���w�b�_�̃f�[�^(FORALL�ł�INSERT�p)
  TYPE h_mov_hdr_id
    IS TABLE OF xxinv_mov_req_instr_headers.mov_hdr_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �ړ��w�b�_ID
  TYPE h_mov_num
    IS TABLE OF xxinv_mov_req_instr_headers.mov_num%TYPE
    INDEX BY BINARY_INTEGER;
    -- �ړ��ԍ�
  TYPE h_mov_type
    IS TABLE OF xxinv_mov_req_instr_headers.mov_type%TYPE
    INDEX BY BINARY_INTEGER;
    -- �ړ��^�C�v
  TYPE h_entered_date
    IS TABLE OF xxinv_mov_req_instr_headers.entered_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���͓�
  TYPE h_instruction_post_code
    IS TABLE OF xxinv_mov_req_instr_headers.instruction_post_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- �w������
  TYPE h_status
    IS TABLE OF xxinv_mov_req_instr_headers.status%TYPE
    INDEX BY BINARY_INTEGER;
    -- �X�e�[�^�X
  TYPE h_notif_status
    IS TABLE OF xxinv_mov_req_instr_headers.notif_status%TYPE
    INDEX BY BINARY_INTEGER;
    -- �ʒm�X�e�[�^�X
  TYPE h_shipped_locat_id
    IS TABLE OF xxinv_mov_req_instr_headers.shipped_locat_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �o�Ɍ�ID
  TYPE h_shipped_locat_code
    IS TABLE OF xxinv_mov_req_instr_headers.shipped_locat_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- �o�Ɍ��ۊǏꏊ
  TYPE h_ship_to_locat_id
    IS TABLE OF xxinv_mov_req_instr_headers.ship_to_locat_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���ɐ�ID
  TYPE h_ship_to_locat_code
    IS TABLE OF xxinv_mov_req_instr_headers.ship_to_locat_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���ɐ�ۊǏꏊ
  TYPE h_schedule_ship_date
    IS TABLE OF xxinv_mov_req_instr_headers.schedule_ship_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- �o�ɗ\���
  TYPE h_schedule_arrival_date
    IS TABLE OF xxinv_mov_req_instr_headers.schedule_arrival_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���ɗ\���
  TYPE h_freight_charge_class
    IS TABLE OF xxinv_mov_req_instr_headers.freight_charge_class%TYPE
    INDEX BY BINARY_INTEGER;
    -- �^���敪
  TYPE h_collected_pallet_qty
    IS TABLE OF xxinv_mov_req_instr_headers.collected_pallet_qty%TYPE
    INDEX BY BINARY_INTEGER;
    -- �p���b�g�������
  TYPE h_out_pallet_qty
    IS TABLE OF xxinv_mov_req_instr_headers.out_pallet_qty%TYPE
    INDEX BY BINARY_INTEGER;
    -- �p���b�g����(�o)
  TYPE h_in_pallet_qty
    IS TABLE OF xxinv_mov_req_instr_headers.in_pallet_qty%TYPE
    INDEX BY BINARY_INTEGER;
    -- �p���b�g����(��)
  TYPE h_no_cont_freight_class
    IS TABLE OF xxinv_mov_req_instr_headers.no_cont_freight_class%TYPE
    INDEX BY BINARY_INTEGER;
    -- �_��O�^���敪
  TYPE h_delivery_no
    IS TABLE OF xxinv_mov_req_instr_headers.delivery_no%TYPE
    INDEX BY BINARY_INTEGER;
    -- �z��No
  TYPE h_description
    IS TABLE OF xxinv_mov_req_instr_headers.description%TYPE
    INDEX BY BINARY_INTEGER;
    -- �E�v
  TYPE h_loading_efficiency_weight
    IS TABLE OF xxinv_mov_req_instr_headers.loading_efficiency_weight%TYPE
    INDEX BY BINARY_INTEGER;
    -- �ύڗ�(�d��)
  TYPE h_loading_efficiency_capacity
    IS TABLE OF xxinv_mov_req_instr_headers.loading_efficiency_capacity%TYPE
    INDEX BY BINARY_INTEGER;
    -- �ύڗ�(�e��)
  TYPE h_organization_id
    IS TABLE OF xxinv_mov_req_instr_headers.organization_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �g�DID
  TYPE h_career_id
    IS TABLE OF xxinv_mov_req_instr_headers.career_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �^���Ǝ�ID
  TYPE h_freight_carrier_code
    IS TABLE OF xxinv_mov_req_instr_headers.freight_carrier_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- �^���Ǝ�
  TYPE h_shipping_method_code
    IS TABLE OF xxinv_mov_req_instr_headers.shipping_method_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- �z���敪
  TYPE h_actual_career_id
    IS TABLE OF xxinv_mov_req_instr_headers.actual_career_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �^���Ǝ�ID_����
  TYPE h_actual_freight_carrier_code
    IS TABLE OF xxinv_mov_req_instr_headers.actual_freight_carrier_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- �^���Ǝ�_����
  TYPE h_actual_shipping_method_code
    IS TABLE OF xxinv_mov_req_instr_headers.actual_shipping_method_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- �z���敪_����
  TYPE h_arrival_time_from
    IS TABLE OF xxinv_mov_req_instr_headers.arrival_time_from%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���׎���FROM
  TYPE h_arrival_time_to
    IS TABLE OF xxinv_mov_req_instr_headers.arrival_time_to%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���׎���TO
  TYPE h_slip_number
    IS TABLE OF xxinv_mov_req_instr_headers.slip_number%TYPE
    INDEX BY BINARY_INTEGER;
    -- �����No
  TYPE h_sum_quantity
    IS TABLE OF xxinv_mov_req_instr_headers.sum_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���v����
  TYPE h_small_quantity
    IS TABLE OF xxinv_mov_req_instr_headers.small_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- ������
  TYPE h_label_quantity
    IS TABLE OF xxinv_mov_req_instr_headers.label_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���x������
  TYPE h_based_weight
    IS TABLE OF xxinv_mov_req_instr_headers.based_weight%TYPE
    INDEX BY BINARY_INTEGER;
    -- ��{�d��
  TYPE h_based_capacity
    IS TABLE OF xxinv_mov_req_instr_headers.based_capacity%TYPE
    INDEX BY BINARY_INTEGER;
    -- ��{�e��
  TYPE h_sum_weight
    IS TABLE OF xxinv_mov_req_instr_headers.sum_weight%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���ڏd�ʍ��v
  TYPE h_sum_capacity
    IS TABLE OF xxinv_mov_req_instr_headers.sum_capacity%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���ڗe�ύ��v
  TYPE h_sum_pallet_weight
    IS TABLE OF xxinv_mov_req_instr_headers.sum_pallet_weight%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���v�p���b�g�d��
  TYPE h_pallet_sum_quantity
    IS TABLE OF xxinv_mov_req_instr_headers.pallet_sum_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- �p���b�g���v����
  TYPE h_mixed_ratio
    IS TABLE OF xxinv_mov_req_instr_headers.mixed_ratio%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���ڗ�
  TYPE h_weight_capacity_class
    IS TABLE OF xxinv_mov_req_instr_headers.weight_capacity_class%TYPE
    INDEX BY BINARY_INTEGER;
    -- �d�ʗe�ϋ敪
  TYPE h_actual_ship_date
    IS TABLE OF xxinv_mov_req_instr_headers.actual_ship_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- �o�Ɏ��ѓ�
  TYPE h_actual_arrival_date
    IS TABLE OF xxinv_mov_req_instr_headers.actual_arrival_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���Ɏ��ѓ�
  TYPE h_mixed_sign
    IS TABLE OF xxinv_mov_req_instr_headers.mixed_sign%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���ڋL��
  TYPE h_batch_no
    IS TABLE OF xxinv_mov_req_instr_headers.batch_no%TYPE
    INDEX BY BINARY_INTEGER;
    -- ��zNo
  TYPE h_item_class
    IS TABLE OF xxinv_mov_req_instr_headers.item_class%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���i�敪
  TYPE h_product_flg
    IS TABLE OF xxinv_mov_req_instr_headers.product_flg%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���i���ʋ敪
  TYPE h_no_instr_actual_class
    IS TABLE OF xxinv_mov_req_instr_headers.no_instr_actual_class%TYPE
    INDEX BY BINARY_INTEGER;
    -- �w���Ȃ����ы敪
  TYPE h_comp_actual_flg
    IS TABLE OF xxinv_mov_req_instr_headers.comp_actual_flg%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���ьv��σt���O
  TYPE h_correct_actual_flg
    IS TABLE OF xxinv_mov_req_instr_headers.correct_actual_flg%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���ђ����t���O
  TYPE h_prev_notif_status
    IS TABLE OF xxinv_mov_req_instr_headers.prev_notif_status%TYPE
    INDEX BY BINARY_INTEGER;
    -- �O��ʒm�X�e�[�^�X
  TYPE h_notif_date
    IS TABLE OF xxinv_mov_req_instr_headers.notif_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- �m��ʒm���ѓ���
  TYPE h_prev_delivery_no
    IS TABLE OF xxinv_mov_req_instr_headers.prev_delivery_no%TYPE
    INDEX BY BINARY_INTEGER;
    -- �O��z��No
  TYPE h_new_modify_flg
    IS TABLE OF xxinv_mov_req_instr_headers.new_modify_flg%TYPE
    INDEX BY BINARY_INTEGER;
    -- �V�K�C���t���O
  TYPE h_screen_update_by
    IS TABLE OF xxinv_mov_req_instr_headers.screen_update_by%TYPE
    INDEX BY BINARY_INTEGER;
    -- ��ʍX�V��
  TYPE h_screen_update_date
    IS TABLE OF xxinv_mov_req_instr_headers.screen_update_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- ��ʍX�V����
  TYPE h_created_by
    IS TABLE OF xxinv_mov_req_instr_headers.created_by%TYPE
    INDEX BY BINARY_INTEGER;
    -- �쐬��
  TYPE h_creation_date
    IS TABLE OF xxinv_mov_req_instr_headers.creation_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- �쐬��
  TYPE h_last_updated_by
    IS TABLE OF xxinv_mov_req_instr_headers.last_updated_by%TYPE
    INDEX BY BINARY_INTEGER;
    -- �ŏI�X�V��
  TYPE h_last_update_date
    IS TABLE OF xxinv_mov_req_instr_headers.last_update_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- �ŏI�X�V��
  TYPE h_last_update_login
    IS TABLE OF xxinv_mov_req_instr_headers.last_update_login%TYPE
    INDEX BY BINARY_INTEGER;
    -- �ŏI�X�V���O�C��
  TYPE h_request_id
    IS TABLE OF xxinv_mov_req_instr_headers.request_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �v��ID
  TYPE h_program_application_id
    IS TABLE OF xxinv_mov_req_instr_headers.program_application_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �R���J�����g�v���O�����A�v���P�[�V����ID
  TYPE h_program_id
    IS TABLE OF xxinv_mov_req_instr_headers.program_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �R���J�����g�v���O����ID
  TYPE h_program_update_date
    IS TABLE OF xxinv_mov_req_instr_headers.program_update_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- �v���O�����X�V��
--
  -- �ړ��˗�/�w���w�b�_�̃f�[�^(FORALL�ł�INSERT�p)
  gt_h_mov_hdr_id                  h_mov_hdr_id;                  -- �ړ��w�b�_ID
  gt_h_mov_num                     h_mov_num;                     -- �ړ��ԍ�
  gt_h_mov_type                    h_mov_type;                    -- �ړ��^�C�v
  gt_h_entered_date                h_entered_date;                -- ���͓�
  gt_h_instruction_post_code       h_instruction_post_code;       -- �w������
  gt_h_status                      h_status;                      -- �X�e�[�^�X
  gt_h_notif_status                h_notif_status;                -- �ʒm�X�e�[�^�X
  gt_h_shipped_locat_id            h_shipped_locat_id;            -- �o�Ɍ�ID
  gt_h_shipped_locat_code          h_shipped_locat_code;          -- �o�Ɍ��ۊǏꏊ
  gt_h_ship_to_locat_id            h_ship_to_locat_id;            -- ���ɐ�ID
  gt_h_ship_to_locat_code          h_ship_to_locat_code;          -- ���ɐ�ۊǏꏊ
  gt_h_schedule_ship_date          h_schedule_ship_date;          -- �o�ɗ\���
  gt_h_schedule_arrival_date       h_schedule_arrival_date;       -- ���ɗ\���
  gt_h_freight_charge_class        h_freight_charge_class;        -- �^���敪
  gt_h_collected_pallet_qty        h_collected_pallet_qty;        -- �p���b�g�������
  gt_h_out_pallet_qty              h_out_pallet_qty;              -- �p���b�g����(�o)
  gt_h_in_pallet_qty               h_in_pallet_qty;               -- �p���b�g����(��)
  gt_h_no_cont_freight_class       h_no_cont_freight_class;       -- �_��O�^���敪
  gt_h_delivery_no                 h_delivery_no;                 -- �z��No
  gt_h_description                 h_description;                 -- �E�v
  gt_h_loading_efficiency_weight   h_loading_efficiency_weight;   -- �ύڗ�(�d��)
  gt_h_loading_efficiency_capa     h_loading_efficiency_capacity; -- �ύڗ�(�e��)
  gt_h_organization_id             h_organization_id;             -- �g�DID
  gt_h_career_id                   h_career_id;                   -- �^���Ǝ�ID
  gt_h_freight_carrier_code        h_freight_carrier_code;        -- �^���Ǝ�
  gt_h_shipping_method_code        h_shipping_method_code;        -- �z���敪
  gt_h_actual_career_id            h_actual_career_id;            -- �^���Ǝ�ID_����
  gt_h_actual_freight_carrier_cd   h_actual_freight_carrier_code; -- �^���Ǝ�_����
  gt_h_actual_shipping_method_cd   h_actual_shipping_method_code; -- �z���敪_����
  gt_h_arrival_time_from           h_arrival_time_from;           -- ���׎���FROM
  gt_h_arrival_time_to             h_arrival_time_to;             -- ���׎���TO
  gt_h_slip_number                 h_slip_number;                 -- �����No
  gt_h_sum_quantity                h_sum_quantity;                -- ���v����
  gt_h_small_quantity              h_small_quantity;              -- ������
  gt_h_label_quantity              h_label_quantity;              -- ���x������
  gt_h_based_weight                h_based_weight;                -- ��{�d��
  gt_h_based_capacity              h_based_capacity;              -- ��{�e��
  gt_h_sum_weight                  h_sum_weight;                  -- ���ڏd�ʍ��v
  gt_h_sum_capacity                h_sum_capacity;                -- ���ڗe�ύ��v
  gt_h_sum_pallet_weight           h_sum_pallet_weight;           -- ���v�p���b�g�d��
  gt_h_pallet_sum_quantity         h_pallet_sum_quantity;         -- �p���b�g���v����
  gt_h_mixed_ratio                 h_mixed_ratio;                 -- ���ڗ�
  gt_h_weight_capacity_class       h_weight_capacity_class;       -- �d�ʗe�ϋ敪
  gt_h_actual_ship_date            h_actual_ship_date;            -- �o�Ɏ��ѓ�
  gt_h_actual_arrival_date         h_actual_arrival_date;         -- ���Ɏ��ѓ�
  gt_h_mixed_sign                  h_mixed_sign;                  -- ���ڋL��
  gt_h_batch_no                    h_batch_no;                    -- ��zNo
  gt_h_item_class                  h_item_class;                  -- ���i�敪
  gt_h_product_flg                 h_product_flg;                 -- ���i���ʋ敪
  gt_h_no_instr_actual_class       h_no_instr_actual_class;       -- �w���Ȃ����ы敪
  gt_h_comp_actual_flg             h_comp_actual_flg;             -- ���ьv��σt���O
  gt_h_correct_actual_flg          h_correct_actual_flg;          -- ���ђ����t���O
  gt_h_prev_notif_status           h_prev_notif_status;           -- �O��ʒm�X�e�[�^�X
  gt_h_notif_date                  h_notif_date;                  -- �m��ʒm���ѓ���
  gt_h_prev_delivery_no            h_prev_delivery_no;            -- �O��z��No
  gt_h_new_modify_flg              h_new_modify_flg;              -- �V�K�C���t���O
  gt_h_screen_update_by            h_screen_update_by;            -- ��ʍX�V��
  gt_h_screen_update_date          h_screen_update_date;          -- ��ʍX�V����
  gt_h_created_by                  h_created_by;                  -- �쐬��
  gt_h_creation_date               h_creation_date;               -- �쐬��
  gt_h_last_updated_by             h_last_updated_by;             -- �ŏI�X�V��
  gt_h_last_update_date            h_last_update_date;            -- �ŏI�X�V��
  gt_h_last_update_login           h_last_update_login;           -- �ŏI�X�V���O�C��
  gt_h_request_id                  h_request_id;                  -- �v��ID
  gt_h_program_application_id      h_program_application_id;
                                                  -- �R���J�����g�v���O�����A�v���P�[�V����ID
  gt_h_program_id                  h_program_id;                  -- �R���J�����g�v���O����ID
  gt_h_program_update_date         h_program_update_date;         -- �v���O�����X�V��
--
  -- C-10 �ړ��˗�/�w�����ׂ̃f�[�^���i�[���郌�R�[�h
  TYPE move_lines_rec IS RECORD(
    mov_line_id                xxinv_mov_req_instr_lines.mov_line_id%TYPE,
    -- �ړ�����ID
    mov_hdr_id                 xxinv_mov_req_instr_lines.mov_hdr_id%TYPE,
    -- �ړ��w�b�_ID
    line_number                xxinv_mov_req_instr_lines.line_number%TYPE,
    -- ���הԍ�
    organization_id            xxinv_mov_req_instr_lines.organization_id%TYPE,
    -- �g�DID
    item_id                    xxinv_mov_req_instr_lines.item_id%TYPE,
    -- OPM�i��ID
    item_code                  xxinv_mov_req_instr_lines.item_code%TYPE,
    -- �i��
    request_qty                xxinv_mov_req_instr_lines.request_qty%TYPE,
    -- �˗�����
    pallet_quantity            xxinv_mov_req_instr_lines.pallet_quantity%TYPE,
    -- �p���b�g��
    layer_quantity             xxinv_mov_req_instr_lines.layer_quantity%TYPE,
    -- �i��
    case_quantity              xxinv_mov_req_instr_lines.case_quantity%TYPE,
    -- �P�[�X��
    instruct_qty               xxinv_mov_req_instr_lines.instruct_qty%TYPE,
    -- �w������
    reserved_quantity          xxinv_mov_req_instr_lines.reserved_quantity%TYPE,
    -- ������
    uom_code                   xxinv_mov_req_instr_lines.uom_code%TYPE,
    -- �P��
    designated_production_date xxinv_mov_req_instr_lines.designated_production_date%TYPE,
    -- �w�萻����
    pallet_qty                 xxinv_mov_req_instr_lines.pallet_qty%TYPE,
    -- �p���b�g����
    move_num                   xxinv_mov_req_instr_lines.move_num%TYPE,
    -- �Q�ƈړ��ԍ�
    po_num                     xxinv_mov_req_instr_lines.po_num%TYPE,
    -- �Q�Ɣ����ԍ�
    first_instruct_qty         xxinv_mov_req_instr_lines.first_instruct_qty%TYPE,
    -- ����w������
    shipped_quantity           xxinv_mov_req_instr_lines.shipped_quantity%TYPE,
    -- �o�Ɏ��ѐ���
    ship_to_quantity           xxinv_mov_req_instr_lines.ship_to_quantity%TYPE,
    -- ���Ɏ��ѐ���
    weight                     xxinv_mov_req_instr_lines.weight%TYPE,
    -- �d��
    capacity                   xxinv_mov_req_instr_lines.capacity%TYPE,
    -- �e��
    pallet_weight              xxinv_mov_req_instr_lines.pallet_weight%TYPE,
    -- �p���b�g�d��
    automanual_reserve_class   xxinv_mov_req_instr_lines.automanual_reserve_class%TYPE,
    -- �����蓮�����敪
    delete_flg                 xxinv_mov_req_instr_lines.delete_flg%TYPE,
    -- ����t���O
    warning_date               xxinv_mov_req_instr_lines.warning_date%TYPE,
    -- �x�����t
    warning_class              xxinv_mov_req_instr_lines.warning_class%TYPE,
    -- �x���敪
    created_by                 xxinv_mov_req_instr_lines.created_by%TYPE,
    -- �쐬��
    creation_date              xxinv_mov_req_instr_lines.creation_date%TYPE,
    -- �쐬��
    last_updated_by            xxinv_mov_req_instr_lines.last_updated_by%TYPE,
    -- �ŏI�X�V��
    last_update_date           xxinv_mov_req_instr_lines.last_update_date%TYPE,
    -- �ŏI�X�V��
    last_update_login          xxinv_mov_req_instr_lines.last_update_login%TYPE,
    -- �ŏI�X�V���O�C��
    request_id                 xxinv_mov_req_instr_lines.request_id%TYPE,
    -- �v��ID
    program_application_id     xxinv_mov_req_instr_lines.program_application_id%TYPE,
    -- �R���J�����g�v���O�����A�v���P�[�V����ID
    program_id                 xxinv_mov_req_instr_lines.program_id%TYPE,
    -- �R���J�����g�v���O����ID
    program_update_date        xxinv_mov_req_instr_lines.program_update_date%TYPE,
    -- �v���O�����X�V��
    not_insert_flg              VARCHAR2(1)
    -- �G���[�����ɂ��o�^���O���R�[�h���ʃt���O
  );
  TYPE move_lines_tbl IS TABLE OF move_lines_rec INDEX BY PLS_INTEGER;
  gr_move_lines_tbl  move_lines_tbl;
--
  -- �ړ��˗�/�w�����ׂ̃f�[�^(FORALL�ł�INSERT�p)
    TYPE m_mov_line_id
      IS TABLE OF xxinv_mov_req_instr_lines.mov_line_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �ړ�����ID
    TYPE m_mov_hdr_id
      IS TABLE OF xxinv_mov_req_instr_lines.mov_hdr_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �ړ��w�b�_ID
    TYPE m_line_number
      IS TABLE OF xxinv_mov_req_instr_lines.line_number%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���הԍ�
    TYPE m_organization_id
      IS TABLE OF xxinv_mov_req_instr_lines.organization_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �g�DID
    TYPE m_item_id
      IS TABLE OF xxinv_mov_req_instr_lines.item_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- OPM�i��ID
    TYPE m_item_code
      IS TABLE OF xxinv_mov_req_instr_lines.item_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- �i��
    TYPE m_request_qty
      IS TABLE OF xxinv_mov_req_instr_lines.request_qty%TYPE
    INDEX BY BINARY_INTEGER;
    -- �˗�����
    TYPE m_pallet_quantity
      IS TABLE OF xxinv_mov_req_instr_lines.pallet_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- �p���b�g��
    TYPE m_layer_quantity
      IS TABLE OF xxinv_mov_req_instr_lines.layer_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- �i��
    TYPE m_case_quantity
      IS TABLE OF xxinv_mov_req_instr_lines.case_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- �P�[�X��
    TYPE m_instruct_qty
      IS TABLE OF xxinv_mov_req_instr_lines.instruct_qty%TYPE
    INDEX BY BINARY_INTEGER;
    -- �w������
    TYPE m_reserved_quantity
      IS TABLE OF xxinv_mov_req_instr_lines.reserved_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- ������
    TYPE m_uom_code
      IS TABLE OF xxinv_mov_req_instr_lines.uom_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- �P��
    TYPE m_designated_production_date
      IS TABLE OF xxinv_mov_req_instr_lines.designated_production_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- �w�萻����
    TYPE m_pallet_qty
      IS TABLE OF xxinv_mov_req_instr_lines.pallet_qty%TYPE
    INDEX BY BINARY_INTEGER;
    -- �p���b�g����
    TYPE m_move_num
      IS TABLE OF xxinv_mov_req_instr_lines.move_num%TYPE
    INDEX BY BINARY_INTEGER;
    -- �Q�ƈړ��ԍ�
    TYPE m_po_num
      IS TABLE OF xxinv_mov_req_instr_lines.po_num%TYPE
    INDEX BY BINARY_INTEGER;
    -- �Q�Ɣ����ԍ�
    TYPE m_first_instruct_qty
      IS TABLE OF xxinv_mov_req_instr_lines.first_instruct_qty%TYPE
    INDEX BY BINARY_INTEGER;
    -- ����w������
    TYPE m_shipped_quantity
      IS TABLE OF xxinv_mov_req_instr_lines.shipped_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- �o�Ɏ��ѐ���
    TYPE m_ship_to_quantity
      IS TABLE OF xxinv_mov_req_instr_lines.ship_to_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���Ɏ��ѐ���
    TYPE m_weight
      IS TABLE OF xxinv_mov_req_instr_lines.weight%TYPE
    INDEX BY BINARY_INTEGER;
    -- �d��
    TYPE m_capacity
      IS TABLE OF xxinv_mov_req_instr_lines.capacity%TYPE
    INDEX BY BINARY_INTEGER;
    -- �e��
    TYPE m_pallet_weight
      IS TABLE OF xxinv_mov_req_instr_lines.pallet_weight%TYPE
    INDEX BY BINARY_INTEGER;
    -- �p���b�g�d��
    TYPE m_automanual_reserve_class
      IS TABLE OF xxinv_mov_req_instr_lines.automanual_reserve_class%TYPE
    INDEX BY BINARY_INTEGER;
    -- �����蓮�����敪
    TYPE m_delete_flg
      IS TABLE OF xxinv_mov_req_instr_lines.delete_flg%TYPE
    INDEX BY BINARY_INTEGER;
    -- ����t���O
    TYPE m_warning_date
      IS TABLE OF xxinv_mov_req_instr_lines.warning_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- �x�����t
    TYPE m_warning_class
      IS TABLE OF xxinv_mov_req_instr_lines.warning_class%TYPE
    INDEX BY BINARY_INTEGER;
    -- �x���敪
    TYPE m_created_by
      IS TABLE OF xxinv_mov_req_instr_lines.created_by%TYPE
    INDEX BY BINARY_INTEGER;
    -- �쐬��
    TYPE m_creation_date
      IS TABLE OF xxinv_mov_req_instr_lines.creation_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- �쐬��
    TYPE m_last_updated_by
      IS TABLE OF xxinv_mov_req_instr_lines.last_updated_by%TYPE
    INDEX BY BINARY_INTEGER;
    -- �ŏI�X�V��
    TYPE m_last_update_date
      IS TABLE OF xxinv_mov_req_instr_lines.last_update_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- �ŏI�X�V��
    TYPE m_last_update_login
      IS TABLE OF xxinv_mov_req_instr_lines.last_update_login%TYPE
    INDEX BY BINARY_INTEGER;
    -- �ŏI�X�V���O�C��
    TYPE m_request_id
      IS TABLE OF xxinv_mov_req_instr_lines.request_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �v��ID
    TYPE m_program_application_id
      IS TABLE OF xxinv_mov_req_instr_lines.program_application_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �R���J�����g�v���O�����A�v���P�[�V����ID
    TYPE m_program_id
      IS TABLE OF xxinv_mov_req_instr_lines.program_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �R���J�����g�v���O����ID
    TYPE m_program_update_date
      IS TABLE OF xxinv_mov_req_instr_lines.program_update_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- �v���O�����X�V��
--
  -- �ړ��˗�/�w�����ׂ̃f�[�^(FORALL�ł�INSERT�p)
    gt_m_mov_line_id                 m_mov_line_id;                -- �ړ�����ID
    gt_m_mov_hdr_id                  m_mov_hdr_id;                 -- �ړ��w�b�_ID
    gt_m_line_number                 m_line_number;                -- ���הԍ�
    gt_m_organization_id             m_organization_id;            -- �g�DID
    gt_m_item_id                     m_item_id;                    -- OPM�i��ID
    gt_m_item_code                   m_item_code;                  -- �i��
    gt_m_request_qty                 m_request_qty;                -- �˗�����
    gt_m_pallet_quantity             m_pallet_quantity;            -- �p���b�g��
    gt_m_layer_quantity              m_layer_quantity;             -- �i��
    gt_m_case_quantity               m_case_quantity;              -- �P�[�X��
    gt_m_instruct_qty                m_instruct_qty;               -- �w������
    gt_m_reserved_quantity           m_reserved_quantity;          -- ������
    gt_m_uom_code                    m_uom_code;                   -- �P��
    gt_m_designated_pdt_date         m_designated_production_date; -- �w�萻����
    gt_m_pallet_qty                  m_pallet_qty;                 -- �p���b�g����
    gt_m_move_num                    m_move_num;                   -- �Q�ƈړ��ԍ�
    gt_m_po_num                      m_po_num;                     -- �Q�Ɣ����ԍ�
    gt_m_first_instruct_qty          m_first_instruct_qty;         -- ����w������
    gt_m_shipped_quantity            m_shipped_quantity;           -- �o�Ɏ��ѐ���
    gt_m_ship_to_quantity            m_ship_to_quantity;           -- ���Ɏ��ѐ���
    gt_m_weight                      m_weight;                     -- �d��
    gt_m_capacity                    m_capacity;                   -- �e��
    gt_m_pallet_weight               m_pallet_weight;              -- �p���b�g�d��
    gt_m_automanual_reserve_class    m_automanual_reserve_class;   -- �����蓮�����敪
    gt_m_delete_flg                  m_delete_flg;                 -- ����t���O
    gt_m_warning_date                m_warning_date;               -- �x�����t
    gt_m_warning_class               m_warning_class;              -- �x���敪
    gt_m_created_by                  m_created_by;                 -- �쐬��
    gt_m_creation_date               m_creation_date;              -- �쐬��
    gt_m_last_updated_by             m_last_updated_by;            -- �ŏI�X�V��
    gt_m_last_update_date            m_last_update_date;           -- �ŏI�X�V��
    gt_m_last_update_login           m_last_update_login;          -- �ŏI�X�V���O�C��
    gt_m_request_id                  m_request_id;                 -- �v��ID
    gt_m_program_application_id      m_program_application_id;
                                                     -- �R���J�����g�v���O�����A�v���P�[�V����ID
    gt_m_program_id                  m_program_id;                 -- �R���J�����g�v���O����ID
    gt_m_program_update_date         m_program_update_date;        -- �v���O�����X�V��
--
  -- C-11 �����˗��w�b�_�̃f�[�^���i�[���郌�R�[�h
  TYPE requisition_header_rec IS RECORD(
    requisition_header_id         xxpo_requisition_headers.requisition_header_id%TYPE,
    -- �����˗��w�b�_ID
    po_header_number              xxpo_requisition_headers.po_header_number%TYPE,
    -- �����ԍ�
    status                        xxpo_requisition_headers.status%TYPE,
    -- �X�e�[�^�X
    vendor_id                     xxpo_requisition_headers.vendor_id%TYPE,
    -- �d����ID
    vendor_code                   xxpo_requisition_headers.vendor_code%TYPE,
    -- �d����R�[�h
    vendor_site_id                xxpo_requisition_headers.vendor_site_id%TYPE,
    -- �d����T�C�gID
    promised_date                 xxpo_requisition_headers.promised_date%TYPE,
    -- �[����
    location_id                   xxpo_requisition_headers.location_id%TYPE,
    -- �[����ID
    location_code                 xxpo_requisition_headers.location_code%TYPE,
    -- �[����R�[�h
    drop_ship_type                xxpo_requisition_headers.drop_ship_type%TYPE,
    -- �����敪
    delivery_code                 xxpo_requisition_headers.delivery_code%TYPE,
    -- �z����R�[�h
    requested_by_code             xxpo_requisition_headers.requested_by_code%TYPE,
    -- �˗��҃R�[�h
    requested_dept_code           xxpo_requisition_headers.requested_dept_code%TYPE,
    -- �˗��ҕ����R�[�h
    requested_to_department_code  xxpo_requisition_headers.requested_to_department_code%TYPE,
    -- �˗��敔���R�[�h
    description                   xxpo_requisition_headers.description%TYPE,
    -- �E�v
    change_flag                   xxpo_requisition_headers.change_flag%TYPE,
    -- �ύX�t���O
    created_by                    xxpo_requisition_headers.created_by%TYPE,
    -- �쐬��
    creation_date                 xxpo_requisition_headers.creation_date%TYPE,
    -- �쐬��
    last_updated_by               xxpo_requisition_headers.last_updated_by%TYPE,
    -- �ŏI�X�V��
    last_update_date              xxpo_requisition_headers.last_update_date%TYPE,
    -- �ŏI�X�V��
    last_update_login             xxpo_requisition_headers.last_update_login%TYPE,
    -- �ŏI�X�V���O�C��
    request_id                    xxpo_requisition_headers.request_id%TYPE,
    -- �v��ID
    program_application_id        xxpo_requisition_headers.program_application_id%TYPE,
    -- �A�v���P�[�V����ID
    program_id                    xxpo_requisition_headers.program_id%TYPE,
    -- �v���O����ID
    program_update_date           xxpo_requisition_headers.program_update_date%TYPE
    -- �v���O�����X�V��
  );
  TYPE requisition_header_tbl IS TABLE OF requisition_header_rec INDEX BY PLS_INTEGER;
  gr_requisition_header_tbl  requisition_header_tbl;
--
  -- �����˗��w�b�_�̃f�[�^(FORALL�ł�INSERT�p)
    TYPE rh_requisition_header_id
      IS TABLE OF xxpo_requisition_headers.requisition_header_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �����˗��w�b�_ID
    TYPE rh_po_header_number
      IS TABLE OF xxpo_requisition_headers.po_header_number%TYPE
    INDEX BY BINARY_INTEGER;
    -- �����ԍ�
    TYPE rh_status
      IS TABLE OF xxpo_requisition_headers.status%TYPE
    INDEX BY BINARY_INTEGER;
    -- �X�e�[�^�X
    TYPE rh_vendor_id
      IS TABLE OF xxpo_requisition_headers.vendor_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �d����ID
    TYPE rh_vendor_code
      IS TABLE OF xxpo_requisition_headers.vendor_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- �d����R�[�h
    TYPE rh_vendor_site_id
      IS TABLE OF xxpo_requisition_headers.vendor_site_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �d����T�C�gID
    TYPE rh_promised_date
      IS TABLE OF xxpo_requisition_headers.promised_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- �[����
    TYPE rh_location_id
      IS TABLE OF xxpo_requisition_headers.location_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �[����ID
    TYPE rh_location_code
      IS TABLE OF xxpo_requisition_headers.location_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- �[����R�[�h
    TYPE rh_drop_ship_type
      IS TABLE OF xxpo_requisition_headers.drop_ship_type%TYPE
    INDEX BY BINARY_INTEGER;
    -- �����敪
    TYPE rh_delivery_code
      IS TABLE OF xxpo_requisition_headers.delivery_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- �z����R�[�h
    TYPE rh_requested_by_code
      IS TABLE OF xxpo_requisition_headers.requested_by_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- �˗��҃R�[�h
    TYPE rh_requested_dept_code
      IS TABLE OF xxpo_requisition_headers.requested_dept_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- �˗��ҕ����R�[�h
    TYPE rh_requested_to_dpt_code
      IS TABLE OF xxpo_requisition_headers.requested_to_department_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- �˗��敔���R�[�h
    TYPE rh_description
      IS TABLE OF xxpo_requisition_headers.description%TYPE
    INDEX BY BINARY_INTEGER;
    -- �E�v
    TYPE rh_change_flag
      IS TABLE OF xxpo_requisition_headers.change_flag%TYPE
    INDEX BY BINARY_INTEGER;
    -- �ύX�t���O
    TYPE rh_created_by
      IS TABLE OF xxpo_requisition_headers.created_by%TYPE
    INDEX BY BINARY_INTEGER;
    -- �쐬��
    TYPE rh_creation_date
      IS TABLE OF xxpo_requisition_headers.creation_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- �쐬��
    TYPE rh_last_updated_by
      IS TABLE OF xxpo_requisition_headers.last_updated_by%TYPE
    INDEX BY BINARY_INTEGER;
    -- �ŏI�X�V��
    TYPE rh_last_update_date
      IS TABLE OF xxpo_requisition_headers.last_update_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- �ŏI�X�V��
    TYPE rh_last_update_login
      IS TABLE OF xxpo_requisition_headers.last_update_login%TYPE
    INDEX BY BINARY_INTEGER;
    -- �ŏI�X�V���O�C��
    TYPE rh_request_id
      IS TABLE OF xxpo_requisition_headers.request_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �v��ID
    TYPE rh_program_application_id
      IS TABLE OF xxpo_requisition_headers.program_application_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �A�v���P�[�V����ID
    TYPE rh_program_id
      IS TABLE OF xxpo_requisition_headers.program_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �v���O����ID
    TYPE rh_program_update_date
      IS TABLE OF xxpo_requisition_headers.program_update_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- �v���O�����X�V��
--
  -- �����˗��w�b�_�̃f�[�^(FORALL�ł�INSERT�p)
    gt_rh_requisition_header_id        rh_requisition_header_id;
    -- �����˗��w�b�_ID
    gt_rh_po_header_number             rh_po_header_number;
    -- �����ԍ�
    gt_rh_status                       rh_status;
    -- �X�e�[�^�X
    gt_rh_vendor_id                    rh_vendor_id;
    -- �d����ID
    gt_rh_vendor_code                  rh_vendor_code;
    -- �d����R�[�h
    gt_rh_vendor_site_id               rh_vendor_site_id;
    -- �d����T�C�gID
    gt_rh_promised_date                rh_promised_date;
    -- �[����
    gt_rh_location_id                  rh_location_id;
    -- �[����ID
    gt_rh_location_code                rh_location_code;
    -- �[����R�[�h
    gt_rh_drop_ship_type               rh_drop_ship_type;
    -- �����敪
    gt_rh_delivery_code                rh_delivery_code;
    -- �z����R�[�h
    gt_rh_requested_by_code            rh_requested_by_code;
    -- �˗��҃R�[�h
    gt_rh_requested_dept_code          rh_requested_dept_code;
    -- �˗��ҕ����R�[�h
    gt_rh_requested_to_dpt_code        rh_requested_to_dpt_code;
    -- �˗��敔���R�[�h
    gt_rh_description                  rh_description;
    -- �E�v
    gt_rh_change_flag                  rh_change_flag;
    -- �ύX�t���O
    gt_rh_created_by                   rh_created_by;
    -- �쐬��
    gt_rh_creation_date                rh_creation_date;
    -- �쐬��
    gt_rh_last_updated_by              rh_last_updated_by;
    -- �ŏI�X�V��
    gt_rh_last_update_date             rh_last_update_date;
    -- �ŏI�X�V��
    gt_rh_last_update_login            rh_last_update_login;
    -- �ŏI�X�V���O�C��
    gt_rh_request_id                   rh_request_id;
    -- �v��ID
    gt_rh_program_application_id       rh_program_application_id;
    -- �A�v���P�[�V����ID
    gt_rh_program_id                   rh_program_id;
    -- �v���O����ID
    gt_rh_program_update_date          rh_program_update_date;
    -- �v���O�����X�V��
--
  -- C-11 �����˗����ׂ̃f�[�^���i�[���郌�R�[�h
  TYPE requisition_lines_rec IS RECORD(
    requisition_line_id           xxpo_requisition_lines.requisition_line_id%TYPE,
    -- �����˗�����ID
    requisition_header_id         xxpo_requisition_lines.requisition_header_id%TYPE,
    -- �����˗��w�b�_ID
    requisition_line_number       xxpo_requisition_lines.requisition_line_number%TYPE,
    -- ���הԍ�
    item_id                       xxpo_requisition_lines.item_id%TYPE,
    -- �i��ID
    item_code                     xxpo_requisition_lines.item_code%TYPE,
    -- �i�ڃR�[�h
    pack_quantity                 xxpo_requisition_lines.pack_quantity%TYPE,
    -- �݌ɓ���
    requested_quantity            xxpo_requisition_lines.requested_quantity%TYPE,
    -- �˗�����
    requested_quantity_uom        xxpo_requisition_lines.requested_quantity_uom%TYPE,
    -- �˗����ʒP�ʃR�[�h
    requested_date                xxpo_requisition_lines.requested_date%TYPE,
    -- ���t�w��
    ordered_quantity              xxpo_requisition_lines.ordered_quantity%TYPE,
    -- ��������
    description                   xxpo_requisition_lines.description%TYPE,
    -- �E�v
    cancelled_flg                 xxpo_requisition_lines.cancelled_flg%TYPE,
    -- ����t���O
    created_by                    xxpo_requisition_lines.created_by%TYPE,
    -- �쐬��
    creation_date                 xxpo_requisition_lines.creation_date%TYPE,
    -- �쐬��
    last_updated_by               xxpo_requisition_lines.last_updated_by%TYPE,
    -- �ŏI�X�V��
    last_update_date              xxpo_requisition_lines.last_update_date%TYPE,
    -- �ŏI�X�V��
    last_update_login             xxpo_requisition_lines.last_update_login%TYPE,
    -- �ŏI�X�V���O�C��
    request_id                    xxpo_requisition_lines.request_id%TYPE,
    -- �v��ID
    program_application_id        xxpo_requisition_lines.program_application_id%TYPE,
    -- �A�v���P�[�V����ID
    program_id                    xxpo_requisition_lines.program_id%TYPE,
    -- �v���O����ID
    program_update_date           xxpo_requisition_lines.program_update_date%TYPE
    -- �v���O�����X�V��
  );
  TYPE requisition_lines_tbl IS TABLE OF requisition_lines_rec INDEX BY PLS_INTEGER;
  gr_requisition_lines_tbl  requisition_lines_tbl;
--
  -- �����˗����ׂ̃f�[�^(FORALL�ł�INSERT�p)
    TYPE rl_requisition_line_id
      IS TABLE OF xxpo_requisition_lines.requisition_line_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �����˗�����ID
    TYPE rl_requisition_header_id
      IS TABLE OF xxpo_requisition_lines.requisition_header_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �����˗��w�b�_ID
    TYPE rl_requisition_line_number
      IS TABLE OF xxpo_requisition_lines.requisition_line_number%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���הԍ�
    TYPE rl_item_id
      IS TABLE OF xxpo_requisition_lines.item_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �i��ID
    TYPE rl_item_code
      IS TABLE OF xxpo_requisition_lines.item_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- �i�ڃR�[�h
    TYPE rl_pack_quantity
      IS TABLE OF xxpo_requisition_lines.pack_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- �݌ɓ���
    TYPE rl_requested_quantity
      IS TABLE OF xxpo_requisition_lines.requested_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- �˗�����
    TYPE rl_requested_quantity_uom
      IS TABLE OF xxpo_requisition_lines.requested_quantity_uom%TYPE
    INDEX BY BINARY_INTEGER;
    -- �˗����ʒP�ʃR�[�h
    TYPE rl_requested_date
      IS TABLE OF xxpo_requisition_lines.requested_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- ���t�w��
    TYPE rl_ordered_quantity
      IS TABLE OF xxpo_requisition_lines.ordered_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- ��������
    TYPE rl_description
      IS TABLE OF xxpo_requisition_lines.description%TYPE
    INDEX BY BINARY_INTEGER;
    -- �E�v
    TYPE rl_cancelled_flg
      IS TABLE OF xxpo_requisition_lines.cancelled_flg%TYPE
    INDEX BY BINARY_INTEGER;
    -- ����t���O
    TYPE rl_created_by
      IS TABLE OF xxpo_requisition_lines.created_by%TYPE
    INDEX BY BINARY_INTEGER;
    -- �쐬��
    TYPE rl_creation_date
      IS TABLE OF xxpo_requisition_lines.creation_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- �쐬��
    TYPE rl_last_updated_by
      IS TABLE OF xxpo_requisition_lines.last_updated_by%TYPE
    INDEX BY BINARY_INTEGER;
    -- �ŏI�X�V��
    TYPE rl_last_update_date
      IS TABLE OF xxpo_requisition_lines.last_update_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- �ŏI�X�V��
    TYPE rl_last_update_login
      IS TABLE OF xxpo_requisition_lines.last_update_login%TYPE
    INDEX BY BINARY_INTEGER;
    -- �ŏI�X�V���O�C��
    TYPE rl_request_id
      IS TABLE OF xxpo_requisition_lines.request_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �v��ID
    TYPE rl_program_application_id
      IS TABLE OF xxpo_requisition_lines.program_application_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �A�v���P�[�V����ID
    TYPE rl_program_id
      IS TABLE OF xxpo_requisition_lines.program_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- �v���O����ID
    TYPE rl_program_update_date
      IS TABLE OF xxpo_requisition_lines.program_update_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- �v���O�����X�V��
--
  -- �����˗����ׂ̃f�[�^(FORALL�ł�INSERT�p)
    gt_rl_requisition_line_id      rl_requisition_line_id;    -- �����˗�����ID
    gt_rl_requisition_header_id    rl_requisition_header_id;  -- �����˗��w�b�_ID
    gt_rl_requisition_line_number  rl_requisition_line_number;-- ���הԍ�
    gt_rl_item_id                  rl_item_id;                -- �i��ID
    gt_rl_item_code                rl_item_code;              -- �i�ڃR�[�h
    gt_rl_pack_quantity            rl_pack_quantity;          -- �݌ɓ���
    gt_rl_requested_quantity       rl_requested_quantity;     -- �˗�����
    gt_rl_requested_quantity_uom   rl_requested_quantity_uom; -- �˗����ʒP�ʃR�[�h
    gt_rl_requested_date           rl_requested_date;         -- ���t�w��
    gt_rl_ordered_quantity         rl_ordered_quantity;       -- ��������
    gt_rl_description              rl_description;            -- �E�v
    gt_rl_cancelled_flg            rl_cancelled_flg;          -- ����t���O
    gt_rl_created_by               rl_created_by;             -- �쐬��
    gt_rl_creation_date            rl_creation_date;          -- �쐬��
    gt_rl_last_updated_by          rl_last_updated_by;        -- �ŏI�X�V��
    gt_rl_last_update_date         rl_last_update_date;       -- �ŏI�X�V��
    gt_rl_last_update_login        rl_last_update_login;      -- �ŏI�X�V���O�C��
    gt_rl_request_id               rl_request_id;             -- �v��ID
    gt_rl_program_application_id   rl_program_application_id; -- �A�v���P�[�V����ID
    gt_rl_program_id               rl_program_id;             -- �v���O����ID
    gt_rl_program_update_date      rl_program_update_date;    -- �v���O�����X�V��
--
  -- C-12 �󒍖��ׂ̃f�[�^���i�[���郌�R�[�h
  TYPE order_lines_u_rec IS RECORD(
    request_no               xxwsh_order_headers_all.request_no%TYPE,-- �˗�No�i�L�[�j
    shipping_item_code       xxwsh_order_lines_all.shipping_item_code%TYPE, -- �i�ڃR�[�h�i�L�[�j
    move_number              xxwsh_order_lines_all.move_number%TYPE,
                                                                   -- �ړ�No
    po_number                xxwsh_order_lines_all.po_number%TYPE,
                                                                   -- ����No
    last_updated_by          xxwsh_order_lines_all.last_updated_by%TYPE,
                                                                   -- �ŏI�X�V��
    last_update_date         xxwsh_order_lines_all.last_update_date%TYPE,
                                                                   -- �ŏI�X�V��
    last_update_login        xxwsh_order_lines_all.last_update_login%TYPE,
                                                                   -- �ŏI�X�V���O�C��
    request_id               xxwsh_order_lines_all.request_id%TYPE,-- �v��ID
    program_application_id   xxwsh_order_lines_all.program_application_id%TYPE,
                                                                   -- �A�v���P�[�V����ID
    program_id               xxwsh_order_lines_all.program_id%TYPE,-- �v���O����ID
    program_update_date      xxwsh_order_lines_all.program_update_date%TYPE
                                                                   -- �v���O�����X�V��
  );
  TYPE order_lines_u_tbl IS TABLE OF order_lines_u_rec INDEX BY PLS_INTEGER;
  gr_order_lines_u_tbl  order_lines_u_tbl;
--
  -- �󒍖��ׂ̃f�[�^(FORALL�ł�UPDATE�p)
    TYPE ol_request_no
      IS TABLE OF xxwsh_order_headers_all.request_no%TYPE
    INDEX BY BINARY_INTEGER;                                      -- �˗�No�i�L�[�j
    TYPE ol_shipping_item_code
      IS TABLE OF xxwsh_order_lines_all.shipping_item_code%TYPE
    INDEX BY BINARY_INTEGER;                                      -- �i�ڃR�[�h�i�L�[�j
    TYPE ol_move_number
      IS TABLE OF xxwsh_order_lines_all.move_number%TYPE
    INDEX BY BINARY_INTEGER;                                      -- �ړ�No
    TYPE ol_po_number
      IS TABLE OF xxwsh_order_lines_all.po_number%TYPE
    INDEX BY BINARY_INTEGER;                                      -- ����No
    TYPE ol_last_updated_by
      IS TABLE OF xxwsh_order_lines_all.last_updated_by%TYPE
    INDEX BY BINARY_INTEGER;                                      -- �ŏI�X�V��
    TYPE ol_last_update_date
      IS TABLE OF xxwsh_order_lines_all.last_update_date%TYPE
    INDEX BY BINARY_INTEGER;                                      -- �ŏI�X�V��
    TYPE ol_last_update_login
      IS TABLE OF xxwsh_order_lines_all.last_update_login%TYPE
    INDEX BY BINARY_INTEGER;                                      -- �ŏI�X�V���O�C��
    TYPE ol_request_id
      IS TABLE OF xxwsh_order_lines_all.request_id%TYPE
    INDEX BY BINARY_INTEGER;                                      -- �v��ID
    TYPE ol_program_application_id
      IS TABLE OF xxwsh_order_lines_all.program_application_id%TYPE
    INDEX BY BINARY_INTEGER;                                      -- �A�v���P�[�V����ID
    TYPE ol_program_id
      IS TABLE OF xxwsh_order_lines_all.program_id%TYPE
    INDEX BY BINARY_INTEGER;                                      -- �v���O����ID
    TYPE ol_program_update_date
      IS TABLE OF xxwsh_order_lines_all.program_update_date%TYPE
    INDEX BY BINARY_INTEGER;                                      -- �v���O�����X�V��
--
  -- �󒍖��ׂ̃f�[�^(FORALL�ł�UPDATE�p)
    gt_ol_request_no             ol_request_no;                   -- �˗�No�i�L�[�j
    gt_ol_shipping_item_code     ol_shipping_item_code;           -- �i�ڃR�[�h�i�L�[�j
    gt_ol_move_number            ol_move_number;                  -- �ړ�No
    gt_ol_po_number              ol_po_number;                    -- ����No
    gt_ol_last_updated_by        ol_last_updated_by;              -- �ŏI�X�V��
    gt_ol_last_update_date       ol_last_update_date;             -- �ŏI�X�V��
    gt_ol_last_update_login      ol_last_update_login;            -- �ŏI�X�V���O�C��
    gt_ol_request_id             ol_request_id;                   -- �v��ID
    gt_ol_program_application_id ol_program_application_id;       -- �A�v���P�[�V����ID
    gt_ol_program_id             ol_program_id;                   -- �v���O����ID
    gt_ol_program_update_date    ol_program_update_date;          -- �v���O�����X�V��
--
  -- C-13 �ړ��˗�/�w�����׃f�[�^���i�[���郌�R�[�h
  TYPE move_lines_u_rec IS RECORD(
    mov_num                  xxinv_mov_req_instr_headers.mov_num%TYPE,-- �ړ��ԍ��i�L�[�j
    item_code                xxinv_mov_req_instr_lines.item_code%TYPE, -- �i�ڃR�[�h�i�L�[�j
    move_num                 xxinv_mov_req_instr_lines.move_num%TYPE,
                                                                   -- �Q�ƈړ��ԍ�
    po_num                   xxinv_mov_req_instr_lines.po_num%TYPE,
                                                                   -- �Q�Ɣ����ԍ�
    last_updated_by          xxinv_mov_req_instr_lines.last_updated_by%TYPE,
                                                                   -- �ŏI�X�V��
    last_update_date         xxinv_mov_req_instr_lines.last_update_date%TYPE,
                                                                   -- �ŏI�X�V��
    last_update_login        xxinv_mov_req_instr_lines.last_update_login%TYPE,
                                                                   -- �ŏI�X�V���O�C��
    request_id               xxinv_mov_req_instr_lines.request_id%TYPE,-- �v��ID
    program_application_id   xxinv_mov_req_instr_lines.program_application_id%TYPE,
                                                                   -- �A�v���P�[�V����ID
    program_id               xxinv_mov_req_instr_lines.program_id%TYPE,-- �v���O����ID
    program_update_date      xxinv_mov_req_instr_lines.program_update_date%TYPE
                                                                   -- �v���O�����X�V��
  );
  TYPE move_lines_u_tbl IS TABLE OF move_lines_u_rec INDEX BY PLS_INTEGER;
  gr_move_lines_u_tbl  move_lines_u_tbl;
--
  -- C-13 �ړ��˗�/�w�����׃f�[�^���i�[���郌�R�[�h
    TYPE ml_mov_num
      IS TABLE OF xxinv_mov_req_instr_headers.mov_num%TYPE
    INDEX BY BINARY_INTEGER;                               -- �ړ��ԍ��i�L�[�j
    TYPE ml_item_code
      IS TABLE OF xxinv_mov_req_instr_lines.item_code%TYPE
    INDEX BY BINARY_INTEGER;                               -- �i�ڃR�[�h�i�L�[�j
    TYPE ml_move_num
      IS TABLE OF xxinv_mov_req_instr_lines.move_num%TYPE
    INDEX BY BINARY_INTEGER;                               -- �Q�ƈړ��ԍ�
    TYPE ml_po_num
      IS TABLE OF xxinv_mov_req_instr_lines.po_num%TYPE
    INDEX BY BINARY_INTEGER;                               -- �Q�Ɣ����ԍ�
    TYPE ml_last_updated_by
      IS TABLE OF xxinv_mov_req_instr_lines.last_updated_by%TYPE
    INDEX BY BINARY_INTEGER;                               -- �ŏI�X�V��
    TYPE ml_last_update_date
      IS TABLE OF xxinv_mov_req_instr_lines.last_update_date%TYPE
    INDEX BY BINARY_INTEGER;                               -- �ŏI�X�V��
    TYPE ml_last_update_login
      IS TABLE OF xxinv_mov_req_instr_lines.last_update_login%TYPE
    INDEX BY BINARY_INTEGER;                               -- �ŏI�X�V���O�C��
    TYPE ml_request_id
      IS TABLE OF xxinv_mov_req_instr_lines.request_id%TYPE
    INDEX BY BINARY_INTEGER;                               -- �v��ID
    TYPE ml_program_application_id
      IS TABLE OF xxinv_mov_req_instr_lines.program_application_id%TYPE
    INDEX BY BINARY_INTEGER;                               -- �A�v���P�[�V����ID
    TYPE ml_program_id
      IS TABLE OF xxinv_mov_req_instr_lines.program_id%TYPE
    INDEX BY BINARY_INTEGER;                               -- �v���O����ID
    TYPE ml_program_update_date
      IS TABLE OF xxinv_mov_req_instr_lines.program_update_date%TYPE
    INDEX BY BINARY_INTEGER;                               -- �v���O�����X�V��
--
  -- C-13 �ړ��˗�/�w�����׃f�[�^���i�[���郌�R�[�h
    gt_ml_mov_num                 ml_mov_num;                 -- �ړ��ԍ��i�L�[�j
    gt_ml_item_code               ml_item_code;               -- �i�ڃR�[�h�i�L�[�j
    gt_ml_move_num                ml_move_num;                -- �Q�ƈړ��ԍ�
    gt_ml_po_num                  ml_po_num;                  -- �Q�Ɣ����ԍ�
    gt_ml_last_updated_by         ml_last_updated_by;         -- �ŏI�X�V��
    gt_ml_last_update_date        ml_last_update_date;        -- �ŏI�X�V��
    gt_ml_last_update_login       ml_last_update_login;       -- �ŏI�X�V���O�C��
    gt_ml_request_id              ml_request_id;              -- �v��ID
    gt_ml_program_application_id  ml_program_application_id;  -- �A�v���P�[�V����ID
    gt_ml_program_id              ml_program_id;              -- �v���O����ID
    gt_ml_program_update_date     ml_program_update_date;     -- �v���O�����X�V��
--
  /**********************************************************************************
   * Procedure Name   : set_debug_switch
   * Description      : �f�o�b�O�p���O�o�͗p�؂�ւ��X�C�b�`�擾����
   ***********************************************************************************/
  PROCEDURE set_debug_switch
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_debug_switch'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_debug_switch_prof_name CONSTANT VARCHAR2(30) := 'XXWSH_92C_DEBUG_SWITCH';  -- ���ޯ���׸�
    cv_debug_switch_on        CONSTANT VARCHAR2(1)  := '1';   --�f�o�b�O�o�͂���
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    --�f�o�b�O�؂�ւ��v���t�@�C���擾
    IF (FND_PROFILE.VALUE(cv_debug_switch_prof_name) = cv_debug_switch_on ) THEN
      gb_debug := TRUE;
    END IF;
  EXCEPTION
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      gb_debug := FALSE;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_debug_switch;
--
--
  /**********************************************************************************
   * Procedure Name   : debug_log
   * Description      : �f�o�b�O�p���O�o�͏���
   ***********************************************************************************/
  PROCEDURE debug_log(in_which in number,       -- �o�͐�FFND_FILE.LOG or FND_FILE.OUTPUT
                      iv_msg   in varchar2 )    -- ���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'debug_log'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    --�f�o�b�OON�Ȃ�o��
    IF (gb_debug) THEN
      FND_FILE.PUT_LINE(in_which, iv_msg);
    END IF;
  EXCEPTION
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      NULL ;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END debug_log;
--
--
   /**********************************************************************************
   * Procedure Name   : check_parameter
   * Description      : C-1  �p�����[�^�`�F�b�N
   ***********************************************************************************/
  PROCEDURE check_parameter(
    iv_action_type           IN         VARCHAR2,   -- �������
    iv_req_mov_no            IN         VARCHAR2,   -- �˗�/�ړ�No
    iv_deliver_from          IN         VARCHAR2,   -- �o�Ɍ�
    iv_deliver_type          IN         VARCHAR2,   -- �o�Ɍ`��
    iv_object_date_from      IN         VARCHAR2,   -- �Ώۊ���From
    iv_object_date_to        IN         VARCHAR2,   -- �Ώۊ���To
    iv_shipped_date          IN         VARCHAR2,   -- �o�ɓ��w��
    iv_arrival_date          IN         VARCHAR2,   -- �����w��
    iv_instruction_post_code IN         VARCHAR2,   -- �w�������w��
    ov_errbuf                OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_parameter'; -- �v���O������
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
debug_log(FND_FILE.LOG,'(C-1)' || cv_prg_name || ' Start���');
--
    -- ������ʕK�{�`�F�b�N
    IF (iv_action_type IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_wsh_13101 -- �K�{���̓p�����[�^�G���[
                                                    ,gv_tkn_item      -- �g�[�N��'ITEM'
                                                    ,gv_cons_a_type)  -- '�������'
                                                    ,1
                                                    ,5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- �o�Ɍ��K�{�`�F�b�N
    IF (iv_deliver_from IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_wsh_13101  -- �K�{���̓p�����[�^�G���[
                                                    ,gv_tkn_item       -- �g�[�N��'ITEM'
                                                    ,gv_cons_deliv_f)  -- '�o�Ɍ�'
                                                    ,1
                                                    ,5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- ������ʂ��u�o�ׁv�̎��̂݃`�F�b�N����
    IF (iv_action_type = gv_cons_t_deliv) THEN
      -- �o�Ɍ`�ԕK�{�`�F�b�N
      IF (iv_deliver_type IS NULL) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                      ,gv_msg_wsh_13101 -- �K�{���̓p�����[�^�G���[
                                                      ,gv_tkn_item      -- �g�[�N��'ITEM'
                                                      ,gv_cons_deliv_type) -- '�o�Ɍ`��'
                                                      ,1
                                                      ,5000);
        -- �G���[���^�[�����������~
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- �Ώۊ���From�K�{�`�F�b�N
    IF (iv_object_date_from IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_wsh_13101 -- �K�{���̓p�����[�^�G���[
                                                    ,gv_tkn_item      -- �g�[�N��'ITEM'
                                                    ,gv_cons_obj_d_from) -- '�Ώۊ���From'
                                                    ,1
                                                    ,5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- �o�ɓ��w��K�{�`�F�b�N
    IF (iv_shipped_date IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_wsh_13101 -- �K�{���̓p�����[�^�G���[
                                                    ,gv_tkn_item      -- �g�[�N��'ITEM'
                                                    ,gv_cons_ship_date) -- '�o�ɓ��w��'
                                                    ,1
                                                    ,5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- �����w��K�{�`�F�b�N
    IF (iv_arrival_date IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_wsh_13101 -- �K�{���̓p�����[�^�G���[
                                                    ,gv_tkn_item      -- �g�[�N��'ITEM'
                                                    ,gv_cons_arvl_date) -- '�����w��'
                                                    ,1
                                                    ,5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- �w�������w��K�{�`�F�b�N
    IF (iv_instruction_post_code IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_wsh_13101 -- �K�{���̓p�����[�^�G���[
                                                    ,gv_tkn_item      -- �g�[�N��'ITEM'
                                                    ,gv_cons_inst_p_code) -- '�w�������w��'
                                                    ,1
                                                    ,5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- �Ώۊ���From�̑��݃`�F�b�N
    IF (FND_DATE.STRING_TO_DATE(iv_object_date_from, 'YYYY/MM/DD') IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_wsh_13004 -- ���t���݃`�F�b�N�G���[
                                                    ,gv_tkn_item          -- �g�[�N��'ITEM'
                                                    ,gv_cons_obj_d_from   -- '�Ώۊ���From'
                                                    ,gv_tkn_value         -- �g�[�N��'VALUE'
                                                    ,iv_object_date_from) -- '�Ώۊ���From'
                                                    ,1
                                                    ,5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- �Ώۊ���To�͓��͂���Ă����Ƃ��̂݃`�F�b�N����
    IF (iv_object_date_to IS NOT NULL) THEN
      -- �Ώۊ���To�̑��݃`�F�b�N
      IF (FND_DATE.STRING_TO_DATE(iv_object_date_to, 'YYYY/MM/DD') IS NULL) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                      ,gv_msg_wsh_13004 -- ���t���݃`�F�b�N�G���[
                                                      ,gv_tkn_item          -- �g�[�N��'ITEM'
                                                      ,gv_cons_obj_d_to     -- '�Ώۊ���To'
                                                      ,gv_tkn_value         -- �g�[�N��'VALUE'
                                                      ,iv_object_date_to)   -- '�Ώۊ���To'
                                                      ,1
                                                      ,5000);
        -- �G���[���^�[�����������~
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- �o�ɓ��w��̑��݃`�F�b�N
    IF (FND_DATE.STRING_TO_DATE(iv_shipped_date, 'YYYY/MM/DD') IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_wsh_13004 -- ���t���݃`�F�b�N�G���[
                                                    ,gv_tkn_item          -- �g�[�N��'ITEM'
                                                    ,gv_cons_ship_date    -- '�o�ɓ��w��'
                                                    ,gv_tkn_value         -- �g�[�N��'VALUE'
                                                    ,iv_shipped_date)     -- '�o�ɓ��w��'
                                                    ,1
                                                    ,5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- �����w��̑��݃`�F�b�N
    IF (FND_DATE.STRING_TO_DATE(iv_arrival_date, 'YYYY/MM/DD') IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_wsh_13004 -- ���t���݃`�F�b�N�G���[
                                                    ,gv_tkn_item          -- �g�[�N��'ITEM'
                                                    ,gv_cons_arvl_date    -- '�����w��'
                                                    ,gv_tkn_value         -- �g�[�N��'VALUE'
                                                    ,iv_arrival_date)     -- '�����w��'
                                                    ,1
                                                    ,5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- �Ώۊ���To�͓��͂���Ă����Ƃ��̂ݑΏۊ���FromTo�̋t�]�G���[�`�F�b�N����
    IF (iv_object_date_to IS NOT NULL) THEN
      -- �Ώۊ���FromTo�̋t�]�G���[�`�F�b�N
      IF (iv_object_date_from > iv_object_date_to) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                      ,gv_msg_wsh_13005 -- ���t�t�]�G���[
                                                      ,gv_tkn_item_from     -- �g�[�N��'ITEM_FROM'
                                                      ,gv_cons_obj_d_from   -- '�Ώۊ���From'
                                                      ,gv_tkn_value_from    -- �g�[�N��'VALUE_FROM'
                                                      ,iv_object_date_from  -- '�Ώۊ���From'
                                                      ,gv_tkn_item_to       -- �g�[�N��'ITEM_TO'
                                                      ,gv_cons_obj_d_to     -- '�Ώۊ���To'
                                                      ,gv_tkn_value_to      -- �g�[�N��'VALUE_TO'
                                                      ,iv_object_date_to)   -- '�Ώۊ���To'
                                                      ,1
                                                      ,5000);
        -- �G���[���^�[�����������~
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- �w���FromTo�̋t�]�G���[�`�F�b�N
    IF (iv_shipped_date > iv_arrival_date) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                    ,gv_msg_wsh_13005     -- ���t�t�]�G���[
                                                    ,gv_tkn_item_from     -- �g�[�N��'ITEM_FROM'
                                                    ,gv_cons_ship_date    -- '�o�ɓ��w��'
                                                    ,gv_tkn_value_from    -- �g�[�N��'VALUE_FROM'
                                                    ,iv_shipped_date      -- '�o�ɓ��w��'
                                                    ,gv_tkn_item_to       -- �g�[�N��'ITEM_TO'
                                                    ,gv_cons_arvl_date    -- '�����w��'
                                                    ,gv_tkn_value_to      -- �g�[�N��'VALUE_TO'
                                                    ,iv_arrival_date)     -- '�����w��'
                                                    ,1
                                                    ,5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- �o�ɓ��w�肪OPM�݌ɉ�v���ԂŃN���[�Y�̏ꍇ
    IF (xxcmn_common_pkg.get_opminv_close_period
          >= TO_CHAR(TO_DATE(iv_shipped_date, 'YYYY/MM/DD'),'YYYYMM')) THEN
--
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                             gv_cons_msg_kbn_wsh                            -- 'XXWSH'
                            ,gv_msg_wsh_11653                               -- �݌ɉ�v���ԃN���[�Y
                            ,gv_tkn_date                                    -- �g�[�N��'DATE'
                            ,TO_CHAR(TO_DATE(iv_shipped_date, 'YYYY/MM/DD')
                                    ,'YYYYMM'))                             -- '�o�ɓ��w��'
                            ,1
                            ,5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
--
    END IF;
--
debug_log(FND_FILE.LOG,'(C-1)' || cv_prg_name || ' End�����');
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
  END check_parameter;
--
--
  /**********************************************************************************
   * Procedure Name   : get_profile
   * Description      : C-2  �v���t�@�C���擾
   ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile'; -- �v���O������
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
    lv_organization_id  VARCHAR2(15);   -- �v���t�@�C��(�}�X�^�g�DID)
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
debug_log(FND_FILE.LOG,'(C-2)' || cv_prg_name || ' Start���');
--
    -- ���[�U�v���t�@�C���̎擾
    lv_organization_id := SUBSTRB(FND_PROFILE.VALUE(gv_cons_m_org_id), 1,15);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (lv_organization_id IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                    ,gv_msg_wsh_13002     -- �v���t�@�C���擾�G���[
                                                    ,gv_tkn_prof_name     -- �g�[�N��'PROF_NAME'
                                                    ,gv_cons_m_org_id_tkn) -- XXCMN:�}�X�^�g�DID
                                                    ,1
                                                    ,5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    BEGIN
      -- ���l�^�ɕϊ�(�ϊ��ł��Ȃ��ꍇ�͗�O�����ց��G���[�j
      gn_organization_id := TO_NUMBER(lv_organization_id);
    EXCEPTION
      WHEN OTHERS THEN
        RAISE INVALID_NUMBER;
    END;
--
--
debug_log(FND_FILE.LOG,'(C-2)' || cv_prg_name || ' End�����');
--
  EXCEPTION
    --*** ���l�^�ɕϊ��ł��Ȃ������ꍇ=TO_NUMBER() ***
    WHEN INVALID_NUMBER THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh   -- 'XXWSH'
                                                    ,gv_msg_wsh_13002  -- �v���t�@�C���擾�G���[
                                                    ,gv_tkn_prof_name  -- �g�[�N��'PROF_NAME'
                                                    ,gv_cons_m_org_id_tkn) -- XXCMN:�}�X�^�g�DID
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
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
  END get_profile;
--
--
  /**********************************************************************************
   * Procedure Name   : purge_table
   * Description      : C-3  �p�[�W����
   ***********************************************************************************/
  PROCEDURE purge_table(
    iv_action_type        IN         VARCHAR2,     -- �������
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'purge_table'; -- �v���O������
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
    lb_retcode  BOOLEAN;
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
debug_log(FND_FILE.LOG,'(C-3)' || cv_prg_name || ' Start���');
--
    -- ������ʂŏ����Ώۃe�[�u�����قȂ�
    -- ������ʂ��u�o�׈˗��v�̏ꍇ
    IF (iv_action_type = gv_cons_t_deliv) THEN
--
debug_log(FND_FILE.LOG,'(C-3)������ʁ��u�o�׈˗��v');
--
      -- �o�׍݌ɕ�[�����ԃe�[�u�������b�N����
      lb_retcode := xxcmn_common_pkg.get_tbl_lock(gv_cons_schema_wsh, gv_cons_dlv_tmp_tbl);
      -- ���b�N�ł��Ȃ������ꍇ
      IF (lb_retcode = FALSE) THEN
--
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                      ,gv_msg_wsh_13103     -- �e�[�u�����b�N�G���[
                                                      ,gv_tkn_table_name    -- �g�[�N��'TABLE_NAME'
                                                      ,gv_cons_dlv_tmp_jp)
                                                                      -- �o�׍݌ɕ�[�����ԃe�[�u��
                                                      ,1
                                                      ,5000);
         RAISE global_api_expt;
      END IF;
--
      -- �S�e�[�u���f�[�^���폜����
      lb_retcode := xxcmn_common_pkg.del_all_data(gv_cons_schema_wsh, gv_cons_dlv_tmp_tbl);
      -- �f�[�^�̍폜�Ɏ��s�����ꍇ
      IF (lb_retcode = FALSE) THEN
--
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                      ,gv_msg_wsh_13006 -- �e�[�u���f�[�^�폜�G���[
                                                      ,gv_tkn_table_name    -- �g�[�N��'TABLE_NAME'
                                                      ,gv_cons_dlv_tmp_jp)
                                                                      -- �o�׍݌ɕ�[�����ԃe�[�u��
                                                      ,1
                                                      ,5000);
         RAISE global_api_expt;
      END IF;
--
    -- ������ʂ��u�ړ��w���v�̏ꍇ
    ELSE
--
debug_log(FND_FILE.LOG,'(C-3)������ʁ��u�ړ��w���v');
--
      -- �ړ��݌ɕ�[�����ԃe�[�u�������b�N����
      lb_retcode := xxcmn_common_pkg.get_tbl_lock(gv_cons_schema_wsh, gv_cons_mov_tmp_tbl);
      -- ���b�N�ł��Ȃ������ꍇ
      IF (lb_retcode = FALSE) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                      ,gv_msg_wsh_13103     -- �e�[�u�����b�N�G���[
                                                      ,gv_tkn_table_name    -- �g�[�N��'TABLE_NAME'
                                                      ,gv_cons_mov_tmp_jp)
                                                                      -- �ړ��݌ɕ�[�����ԃe�[�u��
                                                      ,1
                                                      ,5000);
         RAISE global_api_expt;
      END IF;
      -- �S�e�[�u���f�[�^���폜����
      lb_retcode := xxcmn_common_pkg.del_all_data(gv_cons_schema_wsh, gv_cons_mov_tmp_tbl);
      -- �f�[�^�̍폜�Ɏ��s�����ꍇ
      IF (lb_retcode = FALSE) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                      ,gv_msg_wsh_13006 -- �e�[�u���f�[�^�폜�G���[
                                                      ,gv_tkn_table_name    -- �g�[�N��'TABLE_NAME'
                                                      ,gv_cons_mov_tmp_jp)
                                                                      -- �ړ��݌ɕ�[�����ԃe�[�u��
                                                      ,1
                                                      ,5000);
         RAISE global_api_expt;
      END IF;
    END IF;
--
--
debug_log(FND_FILE.LOG,'(C-3)' || cv_prg_name || ' End�����');
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
  END purge_table;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : C-4  ��񒊏o
   ***********************************************************************************/
  PROCEDURE get_data(
      iv_action_type         IN VARCHAR2,            -- �������
      iv_req_mov_no          IN VARCHAR2,            -- �˗�/�ړ�No
      iv_deliver_from        IN VARCHAR2,            -- �o�Ɍ��ۊǏꏊ
      iv_deliver_type        IN VARCHAR2,            -- �o�Ɍ`��
      iv_object_date_from    IN VARCHAR2,            -- �Ώۊ���From
      iv_object_date_to      IN VARCHAR2,            -- �Ώۊ���To
      iv_arrival_date        IN VARCHAR2,            -- �����w��
      ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- �v���O������
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
    -- �o�׏�񒊏o�̃f�[�^�𒊏o����J�[�\��(From�̂�)
    CURSOR lc_deliv_data_cur_from
    IS
      SELECT
        xoha.deliver_to_id,                 -- �o�א�ID
        xoha.deliver_to,                    -- �o�א�R�[�h
        xoha.request_no,                    -- �˗�No
        xoha.deliver_from_id,               -- �o�׌�ID
        xoha.deliver_from,                  -- �o�׌��R�[�h
        xoha.weight_capacity_class,         -- �d�ʗe�ϋ敪
        xola.shipping_inventory_item_id,    -- INV�o�וi��ID
        ximv.item_id,                       -- OPM�i��ID
        xola.shipping_item_code,            -- �i�ڃR�[�h
        xola.quantity,                      -- ����
        xottv.transaction_type_id,          -- �󒍃^�C�vID
        xottv.transaction_type_code,        -- �o�Ɍ`��
        xicv.item_class_code,               -- �i�ڋ敪
        NULL,                               -- ���i���ʋ敪
        xicv.prod_class_code,               -- ���i�敪
        NVL(xilv.direct_ship_type,gv_cons_ds_type_n),              -- �����敪
        TO_NUMBER(ximv.num_of_deliver),     -- �o�ד���
        ximv.conv_unit,                     -- ���o�Ɋ��Z�P��
        TO_NUMBER(ximv.num_of_cases),       -- �P�[�X����
        ximv.item_um,                       -- �P��
        TO_NUMBER(ximv.frequent_qty),       -- ��\����
        NULL,                               -- �݌ɕ�[���[��
        NULL                                -- �݌ɕ�[��
      FROM
        xxwsh_order_headers_all        xoha,   -- �󒍃w�b�_�A�h�I��
        xxwsh_order_lines_all          xola,   -- �󒍖��׃A�h�I��
        xxwsh_oe_transaction_types2_v  xottv,  -- �󒍃^�C�v���View2
        xxcmn_item_categories4_v       xicv,   -- �J�e�S�����View4
        xxcmn_item_locations2_v        xilv,   -- �ۊǏꏊ���View2
        xxcmn_item_mst2_v              ximv    -- �i�ڏ��View2
      WHERE
            xoha.order_type_id          = xottv.transaction_type_id  -- �󒍃^�C�vID
        AND xottv.shipping_shikyu_class = gv_cons_t_deliv            -- �o�׈˗�
        AND xottv.order_category_code   <> gv_cons_odr_cat_ret       -- �󒍃J�e�S��RETURN�ȊO
        AND xoha.req_status             = gv_cons_status_shime       -- �X�e�[�^�X�u���ߍς݁v
        AND xoha.request_no            = NVL(iv_req_mov_no, xoha.request_no)
            -- �˗�No�����͂���Ă����炻�̒l���A�����͂Ȃ�IS NULL�Ō�������
        AND xoha.deliver_from           = iv_deliver_from            -- �o�׌��ۊǏꏊ
        AND xottv.transaction_type_id   = iv_deliver_type            -- �o�Ɍ`��
        AND xoha.latest_external_flag   = gv_cons_flg_y              -- �ŐV�t���O 'Y'
        AND xoha.order_header_id        = xola.order_header_id       -- �󒍃w�b�_�A�h�I��ID
        AND NVL(xola.delete_flag,'N')  <> gv_cons_flg_y              -- �폜�t���O
        AND xola.move_number           IS NULL                       -- �ړ�No
        AND xola.po_number             IS NULL                       -- ����No
        AND xoha.deliver_from_id        = xilv.inventory_location_id    -- �ۊǑq��ID
        AND xola.shipping_inventory_item_id  = ximv.inventory_item_id   -- �o�וi��ID
        AND xoha.schedule_ship_date    >= TO_DATE(iv_object_date_from,'YYYY/MM/DD')-- �o�ח\���
        AND xicv.item_id                = ximv.item_id               -- �i��ID
        AND xicv.item_id           NOT IN ( SELECT xicv.item_id
                                            FROM   xxcmn_item_categories4_v xicv
                                            WHERE  xicv.prod_class_code = gv_cons_id_drink
                                              AND  xicv.item_class_code = gv_cons_item_product)
        AND ximv.start_date_active     <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')
        AND (ximv.end_date_active IS NULL
             OR ximv.end_date_active   >= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))
      ORDER BY
        xola.shipping_item_code,
        xoha.deliver_from
      FOR UPDATE OF xoha.order_header_id,
                    xola.order_line_id;
--
    -- �o�׏�񒊏o�̃f�[�^�𒊏o����J�[�\��(FromTo)
    CURSOR lc_deliv_data_cur_fromto
    IS
      SELECT
        xoha.deliver_to_id,                 -- �o�א�ID
        xoha.deliver_to,                    -- �o�א�R�[�h
        xoha.request_no,                    -- �˗�No
        xoha.deliver_from_id,               -- �o�׌�ID
        xoha.deliver_from,                  -- �o�׌��R�[�h
        xoha.weight_capacity_class,         -- �d�ʗe�ϋ敪
        xola.shipping_inventory_item_id,    -- INV�o�וi��ID
        ximv.item_id,                       -- OPM�i��ID
        xola.shipping_item_code,            -- �i�ڃR�[�h
        xola.quantity,                      -- ����
        xottv.transaction_type_id,          -- �󒍃^�C�vID
        xottv.transaction_type_code,        -- �o�Ɍ`��
        xicv.item_class_code,               -- �i�ڋ敪
        NULL,                               -- ���i���ʋ敪
        xicv.prod_class_code,               -- ���i�敪
        NVL(xilv.direct_ship_type,gv_cons_ds_type_n),              -- �����敪
        TO_NUMBER(ximv.num_of_deliver),     -- �o�ד���
        ximv.conv_unit,                     -- ���o�Ɋ��Z�P��
        TO_NUMBER(ximv.num_of_cases),       -- �P�[�X����
        ximv.item_um,                       -- �P��
        TO_NUMBER(ximv.frequent_qty),       -- ��\����
        NULL,                               -- �݌ɕ�[���[��
        NULL                                -- �݌ɕ�[��
      FROM
        xxwsh_order_headers_all        xoha,   -- �󒍃w�b�_�A�h�I��
        xxwsh_order_lines_all          xola,   -- �󒍖��׃A�h�I��
        xxwsh_oe_transaction_types2_v  xottv,   -- �󒍃^�C�v���View2
        xxcmn_item_categories4_v       xicv,   -- �J�e�S�����View4
        xxcmn_item_locations2_v        xilv,   -- �ۊǏꏊ���View2
        xxcmn_item_mst2_v              ximv    -- �i�ڏ��View2
      WHERE
            xoha.order_type_id          = xottv.transaction_type_id  -- �󒍃^�C�vID
        AND xottv.shipping_shikyu_class = gv_cons_t_deliv            -- �o�׈˗�
        AND xottv.order_category_code   <> gv_cons_odr_cat_ret       -- �󒍃J�e�S��RETURN�ȊO
        AND xoha.req_status             = gv_cons_status_shime       -- �X�e�[�^�X�u���ߍς݁v
        AND xoha.request_no            = NVL(iv_req_mov_no, xoha.request_no)
            -- �˗�No�����͂���Ă����炻�̒l���A�����͂Ȃ�IS NULL�Ō�������
        AND xoha.deliver_from           = iv_deliver_from            -- �o�׌��ۊǏꏊ
        AND xottv.transaction_type_id   = iv_deliver_type            -- �o�Ɍ`��
        AND xoha.latest_external_flag   = gv_cons_flg_y              -- �ŐV�t���O 'Y'
        AND xoha.order_header_id        = xola.order_header_id       -- �󒍃w�b�_�A�h�I��ID
        AND NVL(xola.delete_flag,'N')  <> gv_cons_flg_y              -- �폜�t���O
        AND xola.move_number           IS NULL                       -- �ړ�No
        AND xola.po_number             IS NULL                       -- ����No
        AND xoha.deliver_from_id        = xilv.inventory_location_id    -- �ۊǑq��ID
        AND xola.shipping_inventory_item_id  = ximv.inventory_item_id   -- �o�וi��ID
        AND xoha.schedule_ship_date    >= TO_DATE(iv_object_date_from,'YYYY/MM/DD')-- �o�ח\���
        AND xoha.schedule_ship_date    <= TO_DATE(iv_object_date_to,'YYYY/MM/DD')-- �o�ח\���
        AND xicv.item_id                = ximv.item_id               -- �i��ID
        AND xicv.item_id           NOT IN ( SELECT xicv.item_id
                                            FROM   xxcmn_item_categories4_v xicv
                                            WHERE  xicv.prod_class_code = gv_cons_id_drink
                                              AND  xicv.item_class_code = gv_cons_item_product)
        AND ximv.start_date_active     <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')
        AND (ximv.end_date_active IS NULL
             OR ximv.end_date_active   >= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))
      ORDER BY
        xola.shipping_item_code,
        xoha.deliver_from
      FOR UPDATE OF xoha.order_header_id,
                    xola.order_line_id;
--
    -- �ړ���񒊏o�̃f�[�^�𒊏o����J�[�\��(From)
    CURSOR lc_move_data_cur_from
    IS
      SELECT
        xmrih.mov_num,                  -- �ړ��ԍ�
        xmrih.shipped_locat_id,         -- �o�Ɍ�ID
        xmrih.shipped_locat_code,       -- �o�Ɍ��R�[�h
        xmrih.ship_to_locat_id,         -- ���ɐ�ID
        xmrih.ship_to_locat_code,       -- ���ɐ�R�[�h
        xmrih.weight_capacity_class,    -- �d�ʗe�ϋ敪
        ximv.item_id,                   -- OPM�i��ID
        ximv.inventory_item_id,         -- INV�i��ID
        xmril.item_code,                -- �i�ڃR�[�h
        xmril.instruct_qty,             -- �w������
        xicv.item_class_code,           -- �i�ڋ敪
        NULL,                           -- ���i���ʋ敪
        xicv.prod_class_code,           -- ���i�敪
        TO_NUMBER(ximv.num_of_deliver), -- �o�ד���
        ximv.conv_unit,                 -- ���o�Ɋ��Z�P��
        TO_NUMBER(ximv.num_of_cases),   -- �P�[�X����
        ximv.item_um,                   -- �P��
        TO_NUMBER(ximv.frequent_qty),   -- ��\����
        NULL,                           -- �݌ɕ�[���[��
        NULL                            -- �݌ɕ�[��
      FROM
        xxinv_mov_req_instr_headers    xmrih,  -- �ړ��˗�/�w���w�b�_
        xxinv_mov_req_instr_lines      xmril,  -- �ړ��˗�/�w������
        xxcmn_item_categories4_v       xicv,   -- �J�e�S�����View4
        xxcmn_item_mst2_v              ximv    -- �i�ڏ��View2
      WHERE
            xmrih.status          IN (gv_cons_mov_sts_e,gv_cons_mov_sts_c) --�u�˗��ς݁v�u�������v
        AND xmrih.mov_type           = gv_cons_move_type      -- �u�ϑ�����v
        AND xmrih.mov_num           = NVL(iv_req_mov_no, xmrih.mov_num)
            -- �ړ�No�����͂���Ă����炻�̒l���A�����͂Ȃ�IS NULL�Ō�������
        AND xmrih.shipped_locat_code = iv_deliver_from        -- �o�׌��ۊǏꏊ
        AND xmrih.mov_hdr_id         = xmril.mov_hdr_id       -- �ړ��w�b�_ID
        AND NVL(xmril.delete_flg,'N') <> gv_cons_flg_y        -- ����t���O
        AND xmril.move_num          IS NULL                   -- �Q�ƈړ��ԍ�
        AND xmril.po_num            IS NULL                   -- �Q�Ɣ����ԍ�
        AND xmril.item_id            = ximv.item_id           -- �i��ID
        AND xmrih.schedule_ship_date   >= TO_DATE(iv_object_date_from,'YYYY/MM/DD') -- �o�ח\���
        AND xicv.item_id                = ximv.item_id        -- �i��ID
        AND xicv.item_id           NOT IN ( SELECT xicv.item_id
                                            FROM   xxcmn_item_categories4_v xicv
                                            WHERE  xicv.prod_class_code = gv_cons_id_drink
                                              AND  xicv.item_class_code = gv_cons_item_product)
        AND ximv.start_date_active     <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')
        AND (ximv.end_date_active IS NULL
             OR ximv.end_date_active   >= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))
      ORDER BY
        xmril.item_code,
        xmrih.shipped_locat_code
      FOR UPDATE OF xmrih.mov_num,
                    xmril.mov_line_id;
--
    -- �ړ���񒊏o�̃f�[�^�𒊏o����J�[�\��(FromTo)
    CURSOR lc_move_data_cur_fromto
    IS
      SELECT
        xmrih.mov_num,                  -- �ړ��ԍ�
        xmrih.shipped_locat_id,         -- �o�Ɍ�ID
        xmrih.shipped_locat_code,       -- �o�Ɍ��R�[�h
        xmrih.ship_to_locat_id,         -- ���ɐ�ID
        xmrih.ship_to_locat_code,       -- ���ɐ�R�[�h
        xmrih.weight_capacity_class,    -- �d�ʗe�ϋ敪
        ximv.item_id,                   -- OPM�i��ID
        ximv.inventory_item_id,         -- INV�i��ID
        xmril.item_code,                -- �i�ڃR�[�h
        xmril.instruct_qty,             -- �w������
        xicv.item_class_code,           -- �i�ڋ敪
        NULL,                           -- ���i���ʋ敪
        xicv.prod_class_code,           -- ���i�敪
        TO_NUMBER(ximv.num_of_deliver), -- �o�ד���
        ximv.conv_unit,                 -- ���o�Ɋ��Z�P��
        TO_NUMBER(ximv.num_of_cases),   -- �P�[�X����
        ximv.item_um,                   -- �P��
        TO_NUMBER(ximv.frequent_qty),   -- ��\����
        NULL,                           -- �݌ɕ�[���[��
        NULL                            -- �݌ɕ�[��
      FROM
        xxinv_mov_req_instr_headers    xmrih,   -- �ړ��˗�/�w���w�b�_
        xxinv_mov_req_instr_lines      xmril,   -- �ړ��˗�/�w������
        xxcmn_item_categories4_v       xicv,    -- �J�e�S�����View4
        xxcmn_item_mst2_v              ximv     -- �i�ڏ��View2
      WHERE
            xmrih.status             IN (gv_cons_mov_sts_e,gv_cons_mov_sts_c)
                                                --�u�˗��ς݁v�u�������v
        AND xmrih.mov_type            = gv_cons_move_type      -- �u�ϑ�����v
        AND xmrih.mov_num           = NVL(iv_req_mov_no, xmrih.mov_num)
            -- �ړ�No�����͂���Ă����炻�̒l���A�����͂Ȃ�IS NULL�Ō�������
        AND xmrih.shipped_locat_code  = iv_deliver_from        -- �o�׌��ۊǏꏊ
        AND xmrih.mov_hdr_id          = xmril.mov_hdr_id       -- �ړ��w�b�_ID
        AND NVL(xmril.delete_flg,'N') <> gv_cons_flg_y          -- ����t���O
        AND xmril.move_num           IS NULL                   -- �Q�ƈړ��ԍ�
        AND xmril.po_num             IS NULL                   -- �Q�Ɣ����ԍ�
        AND xmril.item_id             = ximv.item_id           -- �i��ID
        AND xmrih.schedule_ship_date >= TO_DATE(iv_object_date_from,'YYYY/MM/DD')    -- �o�ח\���
        AND xmrih.schedule_ship_date <= TO_DATE(iv_object_date_to,'YYYY/MM/DD') --(NULL�̏ꍇ����)
        AND xicv.item_id                = ximv.item_id               -- �i��ID
        AND xicv.item_id           NOT IN ( SELECT xicv.item_id
                                            FROM   xxcmn_item_categories4_v xicv
                                            WHERE  xicv.prod_class_code = gv_cons_id_drink
                                              AND  xicv.item_class_code = gv_cons_item_product)
        AND ximv.start_date_active   <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')
        AND (ximv.end_date_active     IS NULL
             OR ximv.end_date_active >= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))
      ORDER BY
        xmril.item_code,
        xmrih.shipped_locat_code
      FOR UPDATE OF xmrih.mov_num,
                    xmril.mov_line_id;
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
debug_log(FND_FILE.LOG,'(C-4)' || cv_prg_name || ' Start���');
debug_log(FND_FILE.LOG,'  iv_action_type = ' || iv_action_type);
debug_log(FND_FILE.LOG,'  iv_req_mov_no = ' || iv_req_mov_no);
debug_log(FND_FILE.LOG,'  iv_deliver_from = ' || iv_deliver_from);
debug_log(FND_FILE.LOG,'  iv_deliver_type = ' || iv_deliver_type);
debug_log(FND_FILE.LOG,'  iv_object_date_from = ' || iv_object_date_from);
debug_log(FND_FILE.LOG,'  iv_object_date_to = ' || iv_object_date_to);
debug_log(FND_FILE.LOG,'  iv_arrival_date = ' || iv_arrival_date);
--
    -- ������ʂ��u�o�ׁv�őΏۊ���TO�����͂���Ă��Ȃ��ꍇ�̃f�[�^���o
    IF ((iv_action_type = gv_cons_t_deliv) AND (iv_object_date_to IS NULL)) THEN
--
debug_log(FND_FILE.LOG,'  ������ʂ��u�o�ׁv�őΏۊ���TO�����͂���Ă��Ȃ��ꍇ�̃f�[�^���o');
--
      -- �J�[�\���I�[�v��
      OPEN lc_deliv_data_cur_from;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH lc_deliv_data_cur_from BULK COLLECT INTO gr_deliv_data_tbl;
--
      -- ���������̃Z�b�g
      gn_target_cnt := gr_deliv_data_tbl.COUNT;
--
debug_log(FND_FILE.LOG,'  ���o���� = ' || gn_target_cnt);
--
      -- �J�[�\���N���[�Y
      CLOSE lc_deliv_data_cur_from;
--
    -- ������ʂ��u�o�ׁv�őΏۊ���TO�����͂���Ă���ꍇ�̃f�[�^���o
    ELSIF ((iv_action_type = gv_cons_t_deliv) AND (iv_object_date_to IS NOT NULL)) THEN
--
debug_log(FND_FILE.LOG,'  ������ʂ��u�o�ׁv�őΏۊ���TO�����͂���Ă���ꍇ�̃f�[�^���o');
--
      -- �J�[�\���I�[�v��
      OPEN lc_deliv_data_cur_fromto;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH lc_deliv_data_cur_fromto BULK COLLECT INTO gr_deliv_data_tbl;
--
      -- ���������̃Z�b�g
      gn_target_cnt := gr_deliv_data_tbl.COUNT;
--
debug_log(FND_FILE.LOG,'  ���o���� = ' || gn_target_cnt);
--
      -- �J�[�\���N���[�Y
      CLOSE lc_deliv_data_cur_fromto;
--
    -- ������ʂ��u�ړ��v�őΏۊ���TO�����͂���Ă��Ȃ��ꍇ�̃f�[�^���o
    ELSIF ((iv_action_type = gv_cons_t_move) AND (iv_object_date_to IS NULL)) THEN
--
debug_log(FND_FILE.LOG,'  ������ʂ��u�ړ��v�őΏۊ���TO�����͂���Ă��Ȃ��ꍇ�̃f�[�^���o');
--
      -- �J�[�\���I�[�v��
      OPEN lc_move_data_cur_from;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH lc_move_data_cur_from BULK COLLECT INTO gr_move_data_tbl;
--
      -- ���������̃Z�b�g
      gn_target_cnt := gr_move_data_tbl.COUNT;
--
debug_log(FND_FILE.LOG,'  ���o���� = ' || gn_target_cnt);
--
      -- �J�[�\���N���[�Y
      CLOSE lc_move_data_cur_from;
--
    -- ������ʂ��u�ړ��v�őΏۊ���TO�����͂���Ă���ꍇ�̃f�[�^���o
    ELSE
--
debug_log(FND_FILE.LOG,'  ������ʂ��u�ړ��v�őΏۊ���TO�����͂���Ă���ꍇ�̃f�[�^���o');
--
      -- �J�[�\���I�[�v��
      OPEN lc_move_data_cur_fromto;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH lc_move_data_cur_fromto BULK COLLECT INTO gr_move_data_tbl;
--
      -- ���������̃Z�b�g
      gn_target_cnt := gr_move_data_tbl.COUNT;
--
debug_log(FND_FILE.LOG,'  ���o���� = ' || gn_target_cnt);
--
--
      -- �J�[�\���N���[�Y
      CLOSE lc_move_data_cur_fromto;
--
    END IF;
--
--
debug_log(FND_FILE.LOG,'(C-4)' || cv_prg_name || ' End�����');
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
--
      IF ( lc_deliv_data_cur_from%ISOPEN ) THEN
        CLOSE lc_deliv_data_cur_from;
      END IF;
      IF ( lc_deliv_data_cur_fromto%ISOPEN ) THEN
        CLOSE lc_deliv_data_cur_fromto;
      END IF;
      IF ( lc_move_data_cur_from%ISOPEN ) THEN
        CLOSE lc_move_data_cur_from;
      END IF;
      IF ( lc_move_data_cur_fromto%ISOPEN ) THEN
        CLOSE lc_move_data_cur_fromto;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
--
      IF ( lc_deliv_data_cur_from%ISOPEN ) THEN
        CLOSE lc_deliv_data_cur_from;
      END IF;
      IF ( lc_deliv_data_cur_fromto%ISOPEN ) THEN
        CLOSE lc_deliv_data_cur_fromto;
      END IF;
      IF ( lc_move_data_cur_from%ISOPEN ) THEN
        CLOSE lc_move_data_cur_from;
      END IF;
      IF ( lc_move_data_cur_fromto%ISOPEN ) THEN
        CLOSE lc_move_data_cur_fromto;
      END IF;
--
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--
      IF ( lc_deliv_data_cur_from%ISOPEN ) THEN
        CLOSE lc_deliv_data_cur_from;
      END IF;
      IF ( lc_deliv_data_cur_fromto%ISOPEN ) THEN
        CLOSE lc_deliv_data_cur_fromto;
      END IF;
      IF ( lc_move_data_cur_from%ISOPEN ) THEN
        CLOSE lc_move_data_cur_from;
      END IF;
      IF ( lc_move_data_cur_fromto%ISOPEN ) THEN
        CLOSE lc_move_data_cur_fromto;
      END IF;
--
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : get_rule
   * Description      : C-5  ���[���擾
   ***********************************************************************************/
  PROCEDURE get_rule(
    in_shori_cnt          IN         NUMBER,       -- �����J�E���^
    iv_action_type        IN         VARCHAR2,     -- �������
    iv_arrival_date       IN         VARCHAR2,     -- �����w��
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_rule'; -- �v���O������
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
    lv_move_from_whse_code1  xxcmn_sourcing_rules2_v.move_from_whse_code1%TYPE;
    -- �ړ����ۊǑq�ɃR�[�h1
    lv_move_from_whse_code2  xxcmn_sourcing_rules2_v.move_from_whse_code2%TYPE;
    -- �ړ����ۊǑq�ɃR�[�h2
    lv_vendor_site_code1     xxcmn_sourcing_rules2_v.vendor_site_code1%TYPE;
    -- �d����T�C�g�R�[�h1
    lv_item_code          xxcmn_sourcing_rules2_v.item_code%TYPE;          -- �i�ڃR�[�h
    lv_delivery_whse_code xxcmn_sourcing_rules2_v.delivery_whse_code%TYPE; -- �o�׌��R�[�h
    lv_no                 xxwsh_order_headers_all.request_no%TYPE;         -- �˗�/�ړ�No
    lv_item_name          xxcmn_item_mst2_v.item_name%TYPE;                -- �i�ږ���
--
    -- *** ���[�J���E�J�[�\�� ***
    -- 1-1 �i�ڎw�� �o�וۊǑq�ɃR�[�h <-- �ړ��ۊǑq�ɃR�[�h1
    CURSOR lc_rule_cur1_1  -- 1-1�̏���
    IS
    SELECT
      xsrv.move_from_whse_code1      -- �ړ����ۊǑq�ɃR�[�h1
    FROM
      xxcmn_sourcing_rules2_v  xsrv  -- �����\�����View2
    WHERE
      xsrv.item_code            = lv_item_code            -- �i�ڃR�[�h
      AND
      xsrv.delivery_whse_code   = lv_delivery_whse_code   -- �o�וۊǑq�ɃR�[�h
      AND
      xsrv.move_from_whse_code1 IS NOT NULL               -- �ړ����ۊǑq�ɃR�[�h1
      AND
      xsrv.start_date_active   <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�J�n��
      AND
      xsrv.end_date_active     >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�I����
    ORDER BY
      xsrv.move_from_whse_code1;
 --
    -- 1-2 �i�ڎw�� �o�וۊǑq�ɃR�[�h <-- �d����T�C�g�R�[�h
    CURSOR lc_rule_cur1_2  -- 1-2�̏���
    IS
    SELECT
      xsrv.vendor_site_code1         -- �d����T�C�g�R�[�h1
    FROM
      xxcmn_sourcing_rules2_v  xsrv  -- �����\�����View2
    WHERE
      xsrv.item_code            = lv_item_code            -- �i�ڃR�[�h
      AND
      xsrv.delivery_whse_code   = lv_delivery_whse_code   -- �o�וۊǑq�ɃR�[�h
      AND
       ((xsrv.vendor_site_code1    IS NOT NULL)           -- �d����T�C�g�R�[�h1          =
        AND                                               -- 1-2�̏��� ====================
        (xsrv.move_from_whse_code1 IS NULL))              -- �ړ����ۊǑq�ɃR�[�h1        =
      AND
      xsrv.start_date_active   <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�J�n��
      AND
      xsrv.end_date_active     >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�I����
    ORDER BY
      xsrv.vendor_site_code1;
--
    -- 2-1 �i�ڎw�� �ړ��ۊǑq�ɃR�[�h1 <-- �ړ��ۊǑq�ɃR�[�h2
    CURSOR lc_rule_cur2_1  -- 2-1�̏���
    IS
    SELECT
      xsrv.move_from_whse_code2      -- �ړ����ۊǑq�ɃR�[�h2
    FROM
      xxcmn_sourcing_rules2_v  xsrv  -- �����\�����View2
    WHERE
      xsrv.item_code              = lv_item_code            -- �i�ڃR�[�h
      AND
      xsrv.move_from_whse_code1   = lv_delivery_whse_code   -- �ړ����ۊǑq�ɃR�[�h1
      AND
      xsrv.move_from_whse_code2 IS NOT NULL                 -- �ړ����ۊǑq�ɃR�[�h2
      AND
      xsrv.start_date_active      <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�J�n��
      AND
      xsrv.end_date_active        >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�I����
    ORDER BY
      xsrv.move_from_whse_code2;
--
    -- 2-2 �i�ڎw�� �ړ��ۊǑq�ɃR�[�h1 <-- �d����T�C�g�R�[�h
    CURSOR lc_rule_cur2_2  -- 2-2�̏���
    IS
    SELECT
      xsrv.vendor_site_code1         -- �d����T�C�g�R�[�h1
    FROM
      xxcmn_sourcing_rules2_v  xsrv  -- �����\�����View2
    WHERE
      xsrv.item_code              = lv_item_code            -- �i�ڃR�[�h
      AND
      xsrv.move_from_whse_code1   = lv_delivery_whse_code   -- �ړ����ۊǑq�ɃR�[�h1
      AND
       ((xsrv.vendor_site_code1   IS NOT NULL)              -- �d����T�C�g�R�[�h1          =
         AND                                                -- 2-2�̏��� ====================
        (xsrv.move_from_whse_code2 IS NULL))                -- �ړ����ۊǑq�ɃR�[�h2        =
      AND
      xsrv.start_date_active      <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�J�n��
      AND
      xsrv.end_date_active        >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�I����
    ORDER BY
      xsrv.vendor_site_code1;
--
    -- 3-1 �i�ڎw�� �ړ��ۊǑq�ɃR�[�h2 <-- �d����T�C�g�R�[�h
    CURSOR lc_rule_cur3_1
    IS
    SELECT
      xsrv.vendor_site_code1         -- �d����T�C�g�R�[�h1
    FROM
      xxcmn_sourcing_rules2_v  xsrv  -- �����\�����View2
    WHERE
      xsrv.item_code              = lv_item_code              -- �i�ڃR�[�h
    AND
      xsrv.move_from_whse_code2   = lv_delivery_whse_code   -- �ړ����ۊǑq�ɃR�[�h2
    AND                                                     -- 3-1�̏���=====================
      xsrv.vendor_site_code1     IS NOT NULL                -- �d����T�C�g�R�[�h1          =
    AND
      xsrv.start_date_active      <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�J�n��
    AND
      xsrv.end_date_active        >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�I����
    ORDER BY
      xsrv.vendor_site_code1;
--
    -- 1-1-z �i��ALL �o�וۊǑq�ɃR�[�h <-- �ړ��ۊǑq�ɃR�[�h1
    CURSOR lc_rule_cur1_1_z
    IS
    SELECT
      xsrv.move_from_whse_code1      -- �ړ����ۊǑq�ɃR�[�h1
    FROM
      xxcmn_sourcing_rules2_v  xsrv  -- �����\�����View2
    WHERE
      xsrv.item_code            = gv_cons_wild_card       -- �i�ڃR�[�h('ZZZZZZZ')
    AND
      xsrv.delivery_whse_code   = lv_delivery_whse_code   -- �o�וۊǑq�ɃR�[�h
    AND
      xsrv.move_from_whse_code1 IS NOT NULL               -- �ړ����ۊǑq�ɃR�[�h1
    AND
      xsrv.start_date_active   <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�J�n��
    AND
      xsrv.end_date_active     >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�I����
    ORDER BY
      xsrv.move_from_whse_code1;
--
    -- 1-2-z �i��ALL �o�וۊǑq�ɃR�[�h <-- �d����T�C�g�R�[�h
    CURSOR lc_rule_cur1_2_z
    IS
    SELECT
      xsrv.vendor_site_code1         -- �d����T�C�g�R�[�h1
    FROM
      xxcmn_sourcing_rules2_v  xsrv  -- �����\�����View2
    WHERE
      xsrv.item_code            = gv_cons_wild_card       -- �i�ڃR�[�h('ZZZZZZZ')
    AND
      xsrv.delivery_whse_code   = lv_delivery_whse_code   -- �o�וۊǑq�ɃR�[�h
    AND
       ((xsrv.vendor_site_code1    IS NOT NULL)           -- �d����T�C�g�R�[�h1          =
       AND                                                -- 1-2�̏��� ====================
       (xsrv.move_from_whse_code1 IS NULL))               -- �ړ����ۊǑq�ɃR�[�h1        =
    AND
      xsrv.start_date_active   <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�J�n��
    AND
      xsrv.end_date_active     >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�I����
    ORDER BY
      xsrv.vendor_site_code1;
--
    -- 2-1-z �i��ALL �ړ��ۊǑq�ɃR�[�h1 <-- �ړ��ۊǑq�ɃR�[�h2
    CURSOR lc_rule_cur2_1_z
    IS
    SELECT
      xsrv.move_from_whse_code2      -- �ړ����ۊǑq�ɃR�[�h2
    FROM
      xxcmn_sourcing_rules2_v  xsrv  -- �����\�����View2
    WHERE
      xsrv.item_code            = gv_cons_wild_card         -- �i�ڃR�[�h('ZZZZZZZ')
    AND
      xsrv.move_from_whse_code1   = lv_delivery_whse_code   -- �ړ����ۊǑq�ɃR�[�h1
    AND
       xsrv.move_from_whse_code2 IS NOT NULL                -- �ړ����ۊǑq�ɃR�[�h2
    AND
      xsrv.start_date_active      <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�J�n��
    AND
      xsrv.end_date_active        >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�I����
    ORDER BY
      xsrv.move_from_whse_code2;
--
    -- 2-2-z �i��ALL �ړ��ۊǑq�ɃR�[�h1 <-- �d����T�C�g�R�[�h
    CURSOR lc_rule_cur2_2_z
    IS
    SELECT
      xsrv.vendor_site_code1         -- �d����T�C�g�R�[�h1
    FROM
      xxcmn_sourcing_rules2_v  xsrv  -- �����\�����View2
    WHERE
      xsrv.item_code            = gv_cons_wild_card         -- �i�ڃR�[�h('ZZZZZZZ')
    AND
      xsrv.move_from_whse_code1   = lv_delivery_whse_code   -- �ړ����ۊǑq�ɃR�[�h1
    AND
       ((xsrv.vendor_site_code1   IS NOT NULL)              -- �d����T�C�g�R�[�h1          =
         AND                                                -- 2-2�̏��� ====================
       (xsrv.move_from_whse_code2 IS NULL))                 -- �ړ����ۊǑq�ɃR�[�h2        =
    AND
      xsrv.start_date_active      <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�J�n��
    AND
      xsrv.end_date_active        >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�I����
    ORDER BY
      xsrv.vendor_site_code1;
--
    -- 3-1-z �i��ALL �ړ��ۊǑq�ɃR�[�h2 <-- �d����T�C�g�R�[�h
    CURSOR lc_rule_cur3_1_z
    IS
    SELECT
      xsrv.vendor_site_code1         -- �d����T�C�g�R�[�h1
    FROM
      xxcmn_sourcing_rules2_v  xsrv  -- �����\�����View2
    WHERE
      xsrv.item_code            = gv_cons_wild_card         -- �i�ڃR�[�h('ZZZZZZZ')
    AND
      xsrv.move_from_whse_code2   = lv_delivery_whse_code   -- �ړ����ۊǑq�ɃR�[�h2
    AND                                                     -- 3-1�̏���=====================
      xsrv.vendor_site_code1    IS NOT NULL                 -- �d����T�C�g�R�[�h1          =
    AND
      xsrv.start_date_active      <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�J�n��
    AND
      xsrv.end_date_active        >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�I����
    ORDER BY
      xsrv.vendor_site_code1;
--
    -- �i�ږ��̂��擾����J�[�\��
    CURSOR lc_item_name_cur
    IS
    SELECT ximv.item_name
    FROM   xxcmn_item_mst2_v  ximv
    WHERE
           ximv.item_no            = lv_item_code     -- �i�ڃR�[�h
    AND
           ximv.start_date_active <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�J�n��
    AND
           ximv.end_date_active   >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �K�p�I����
    AND
    ROWNUM                         = 1;
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
debug_log(FND_FILE.LOG,'(C-5)' || cv_prg_name || ' Start���');
debug_log(FND_FILE.LOG,'  in_shori_cnt =' || in_shori_cnt);
debug_log(FND_FILE.LOG,'  iv_action_type =' || iv_action_type);
debug_log(FND_FILE.LOG,'  iv_arrival_date =' || iv_arrival_date);
--
    -- ������ʂɂ��i�ڃR�[�h�Əo�וۊǑq�ɃR�[�h��No��؂蕪����
    -- �o�ׂȂ�
    IF (iv_action_type = gv_cons_t_deliv) THEN
      lv_item_code          := gr_deliv_data_tbl(in_shori_cnt).shipping_item_code;  -- �i�ڃR�[�h
      lv_delivery_whse_code := gr_deliv_data_tbl(in_shori_cnt).deliver_from;        -- �o�׌��R�[�h
      lv_no                 := gr_deliv_data_tbl(in_shori_cnt).request_no;          -- �˗�No
    ELSE
      lv_item_code          := gr_move_data_tbl(in_shori_cnt).item_code;            -- �i�ڃR�[�h
      lv_delivery_whse_code := gr_move_data_tbl(in_shori_cnt).shipped_locat_code;   -- �o�Ɍ��R�[�h
      lv_no                 := gr_move_data_tbl(in_shori_cnt).mov_num;              -- �ړ�No
    END IF;
--
debug_log(FND_FILE.LOG,'  lv_item_code =' || lv_item_code);
debug_log(FND_FILE.LOG,'  lv_delivery_whse_code =' || lv_delivery_whse_code);
debug_log(FND_FILE.LOG,'  lv_no(�˗�No/�ړ�No) =' || lv_no);
--
    -- 1-1 (�ړ����ۊǑq�ɃR�[�h1������)
    FOR r_rule_cur1_1 IN lc_rule_cur1_1 LOOP
--
debug_log(FND_FILE.LOG,'  lc_rule_cur1_1 Found...');
--
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- �݌ɕ�[���[���́u�ړ��v
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_move;
        -- �݌ɕ�[���͈ړ����ۊǑq�ɃR�[�h1
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur1_1.move_from_whse_code1;
      -- �ړ��Ȃ�
      ELSE
        -- �݌ɕ�[���[���́u�ړ��v
        gr_move_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_move;
        -- �݌ɕ�[���͈ړ����ۊǑq�ɃR�[�h1
        gr_move_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur1_1.move_from_whse_code1;
      END IF;
--
debug_log(FND_FILE.LOG,'(C-5)' || cv_prg_name || ' End�����');
      RETURN;
--
    END LOOP;
--
debug_log(FND_FILE.LOG,'  lc_rule_cur1_1 NotFound...');
--
--
    -- 1-2 (�d����T�C�g�R�[�h1������)
    FOR r_rule_cur1_2 IN lc_rule_cur1_2 LOOP
--
debug_log(FND_FILE.LOG,'  lc_rule_cur1_2 Found...');
--
      -- �o�ׂȂ�
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- �݌ɕ�[���[���́u�����v
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- �݌ɕ�[���͎d����T�C�g�R�[�h1
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur1_2.vendor_site_code1;
      -- �ړ��Ȃ�
      ELSE
        -- �݌ɕ�[���[���́u�����v
        gr_move_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- �݌ɕ�[���͎d����T�C�g�R�[�h1
        gr_move_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur1_2.vendor_site_code1;
      END IF;
--
debug_log(FND_FILE.LOG,'(C-5)' || cv_prg_name || ' End�����');
      RETURN;
--
    END LOOP;
--
debug_log(FND_FILE.LOG,'  lc_rule_cur1_2 NotFound...');
--
--
    -- 2-1 (�ړ����ۊǑq�ɃR�[�h2������)
    FOR r_rule_cur2_1 IN lc_rule_cur2_1 LOOP
--
debug_log(FND_FILE.LOG,'  lc_rule_cur2_1 Found...');
--
      -- �o�ׂȂ�
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- �݌ɕ�[���[���́u�ړ��v
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_move;
        -- �݌ɕ�[���͈ړ����ۊǑq�ɃR�[�h1
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur2_1.move_from_whse_code2;
      -- �ړ��Ȃ�
      ELSE
        -- �݌ɕ�[���[���́u�ړ��v
        gr_move_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_move;
        -- �݌ɕ�[���͈ړ����ۊǑq�ɃR�[�h2
        gr_move_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur2_1.move_from_whse_code2;
      END IF;
--
debug_log(FND_FILE.LOG,'(C-5)' || cv_prg_name || ' End�����');
      RETURN;
--
    END LOOP;
--
debug_log(FND_FILE.LOG,'  lc_rule_cur2_1 NotFound...');
--
--
    -- 2-2 (�d����T�C�g�R�[�h1������)
    FOR r_rule_cur2_2 IN lc_rule_cur2_2 LOOP
--
debug_log(FND_FILE.LOG,'  lc_rule_cur2_2 Found...');
--
      -- �o�ׂȂ�
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- �݌ɕ�[���[���́u�����v
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- �݌ɕ�[���͎d����T�C�g�R�[�h1
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur2_2.vendor_site_code1;
      -- �ړ��Ȃ�
      ELSE
        -- �݌ɕ�[���[���́u�����v
        gr_move_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- �݌ɕ�[���͎d����T�C�g�R�[�h1
        gr_move_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur2_2.vendor_site_code1;
      END IF;
--
debug_log(FND_FILE.LOG,'(C-5)' || cv_prg_name || ' End�����');
      RETURN;
--
    END LOOP;
--
debug_log(FND_FILE.LOG,'  lc_rule_cur2_2 NotFound...');
--
--
    -- 3-1 (�d����T�C�g�R�[�h1������)
    FOR r_rule_cur3_1 IN lc_rule_cur3_1 LOOP
--
debug_log(FND_FILE.LOG,'  lc_rule_cur3_1 Found...');
--
      -- �o�ׂȂ�
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- �݌ɕ�[���[���́u�����v
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- �݌ɕ�[���͎d����T�C�g�R�[�h1
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur3_1.vendor_site_code1;
      -- �ړ��Ȃ�
      ELSE
        -- �݌ɕ�[���[���́u�����v
        gr_move_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- �݌ɕ�[���͎d����T�C�g�R�[�h1
        gr_move_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur3_1.vendor_site_code1;
      END IF;
--
debug_log(FND_FILE.LOG,'(C-5)' || cv_prg_name || ' End�����');
      RETURN;
--
    END LOOP;
--
debug_log(FND_FILE.LOG,'  lc_rule_cur3_1 NotFound...');
--
--
    -- 1-1 Z��(�ړ����ۊǑq�ɃR�[�h1������)
    FOR r_rule_cur1_1_z IN lc_rule_cur1_1_z LOOP
--
debug_log(FND_FILE.LOG,'  lc_rule_cur1_1_z Found...');
--
      -- �o�ׂȂ�
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- �݌ɕ�[���[���́u�ړ��v
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_move;
        -- �݌ɕ�[���͈ړ����ۊǑq�ɃR�[�h1
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur1_1_z.move_from_whse_code1;
      -- �ړ��Ȃ�
      ELSE
        -- �݌ɕ�[���[���́u�ړ��v
        gr_move_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_move;
        -- �݌ɕ�[���͈ړ����ۊǑq�ɃR�[�h1
        gr_move_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur1_1_z.move_from_whse_code1;
      END IF;
--
debug_log(FND_FILE.LOG,'(C-5)' || cv_prg_name || ' End�����');
      RETURN;
--
    END LOOP;
--
debug_log(FND_FILE.LOG,'  lc_rule_cur1_1_z NotFound...');
--
--
    -- 1-2 Z��(�d����T�C�g�R�[�h1������)
    FOR r_rule_cur1_2_z IN lc_rule_cur1_2_z LOOP
--
debug_log(FND_FILE.LOG,'  lc_rule_cur1_2_z Found...');
--
      -- �o�ׂȂ�
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- �݌ɕ�[���[���́u�����v
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- �݌ɕ�[���͎d����T�C�g�R�[�h1
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur1_2_z.vendor_site_code1;
      -- �ړ��Ȃ�
      ELSE
        -- �݌ɕ�[���[���́u�����v
        gr_move_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- �݌ɕ�[���͎d����T�C�g�R�[�h1
        gr_move_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur1_2_z.vendor_site_code1;
      END IF;
--
debug_log(FND_FILE.LOG,'(C-5)' || cv_prg_name || ' End�����');
      RETURN;
--
    END LOOP;
--
debug_log(FND_FILE.LOG,'  lc_rule_cur1_2_z NotFound...');
--
--
    -- 2_1 Z��(�ړ����ۊǑq�ɃR�[�h2������)
    FOR r_rule_cur2_1_z IN lc_rule_cur2_1_z LOOP
--
debug_log(FND_FILE.LOG,'  lc_rule_cur2_1_z Found...');
--
      -- �o�ׂȂ�
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- �݌ɕ�[���[���́u�ړ��v
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_move;
        -- �݌ɕ�[���͈ړ����ۊǑq�ɃR�[�h1
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur2_1_z.move_from_whse_code2;
      -- �ړ��Ȃ�
      ELSE
        -- �݌ɕ�[���[���́u�ړ��v
        gr_move_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_move;
        -- �݌ɕ�[���͈ړ����ۊǑq�ɃR�[�h2
        gr_move_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur2_1_z.move_from_whse_code2;
      END IF;
--
debug_log(FND_FILE.LOG,'(C-5)' || cv_prg_name || ' End�����');
      RETURN;
--
    END LOOP;
--
debug_log(FND_FILE.LOG,'  lc_rule_cur2_1_z NotFound...');
--
--
    -- 2-2 Z��(�d����T�C�g�R�[�h1������)
    FOR r_rule_cur2_2_z IN lc_rule_cur2_2_z LOOP
--
debug_log(FND_FILE.LOG,'  lc_rule_cur2_2_z Found...');
--
      -- �o�ׂȂ�
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- �݌ɕ�[���[���́u�����v
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- �݌ɕ�[���͎d����T�C�g�R�[�h1
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur2_2_z.vendor_site_code1;
      -- �ړ��Ȃ�
      ELSE
        -- �݌ɕ�[���[���́u�����v
        gr_move_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- �݌ɕ�[���͎d����T�C�g�R�[�h1
        gr_move_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur2_2_z.vendor_site_code1;
      END IF;
--
debug_log(FND_FILE.LOG,'(C-5)' || cv_prg_name || ' End�����');
      RETURN;
--
    END LOOP;
--
debug_log(FND_FILE.LOG,'  lc_rule_cur2_2_z NotFound...');
--
--
    -- 3-1 Z��(�d����T�C�g�R�[�h1������)
    FOR r_rule_cur3_1_z IN lc_rule_cur3_1_z LOOP
--
debug_log(FND_FILE.LOG,'  lc_rule_cur3_1_z Found...');
--
      -- �o�ׂȂ�
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- �݌ɕ�[���[���́u�����v
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- �݌ɕ�[���͎d����T�C�g�R�[�h1
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur3_1_z.vendor_site_code1;
      -- �ړ��Ȃ�
      ELSE
        -- �݌ɕ�[���[���́u�����v
        gr_move_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- �݌ɕ�[���͎d����T�C�g�R�[�h1
        gr_move_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur3_1_z.vendor_site_code1;
      END IF;
--
debug_log(FND_FILE.LOG,'(C-5)' || cv_prg_name || ' End�����');
      RETURN;
--
    END LOOP;
--
debug_log(FND_FILE.LOG,'  lc_rule_cur3_1_z NotFound...');
--
--
    -- �J�[�\��1-1 ���� 3-1�A1-1-Z ���� 3-1-Z�Ō����ł��Ȃ������ꍇ�́u�݌ɕ�[���Ȃ��v�Ƃ��āA
    -- �����쐬���Ȃ�
    -- �i�ږ��̂�����
    FOR r_item_name_cur IN lc_item_name_cur LOOP
--
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                  ,gv_msg_wsh_13007       -- �݌ɕ�[���擾�G���[
                                                  ,gv_tkn_param1          -- �g�[�N��'PARAM1'
                                                  ,iv_action_type         -- �������
                                                  ,gv_tkn_param2          -- �g�[�N��'PARAM2'
                                                  ,lv_no                  -- �˗�/�ړ�No
                                                  ,gv_tkn_param3          -- �g�[�N��'PARAM3'
                                                  ,lv_item_code           -- �i�ڃR�[�h
                                                  ,gv_tkn_param4          -- �g�[�N��'PARAM4'
                                                  ,r_item_name_cur.item_name     -- �i�ږ���
                                                  ,gv_tkn_param5          -- �g�[�N��'PARAM5'
                                                  ,lv_delivery_whse_code  -- �o��(��)���R�[�h
                                                  )
                                                  ,1
                                                  ,5000);
    END LOOP;
--
    -- �x�����^�[������
    RAISE common_warn_expt;
--
  EXCEPTION
    -- *** ���ʊ֐��G���[�n���h�� (�x����Ԃ�)***
    WHEN common_warn_expt THEN
debug_log(FND_FILE.LOG,'(C-5)' || cv_prg_name || ' End with Warnning�����');
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
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
  END get_rule;
--
  /**********************************************************************************
   * Procedure Name   : ins_ints_table
   * Description      : C-6  ���ԃe�[�u���o�^(�o��)
   ***********************************************************************************/
  PROCEDURE ins_ints_table(
      ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ints_table'; -- �v���O������
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
    ln_tbl_cnt   NUMBER :=0;     -- �����Ώی���
    ln_cnt       NUMBER :=0;     -- ���ԃe�[�u���i�[�Ώی����J�E���^
    ln_inst_cnt  NUMBER :=0;     -- ���ԃe�[�u���i�[�����p���[�v�J�E���^
    ln_loop_cnt  NUMBER :=0;     -- �����Ώۃ��R�[�h�擾���[�v�J�E���^
    ln_not_cnt   NUMBER :=0;     -- �ǂݔ�΂����R�[�h�̃J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
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
debug_log(FND_FILE.LOG,'(C-6)' || cv_prg_name || ' Start���');
--
    -- ���R�[�h�ϐ��̃��R�[�h�������߂�
    ln_tbl_cnt := gr_deliv_data_tbl.COUNT;
debug_log(FND_FILE.LOG,'  �����Ώی��� = ' || ln_tbl_cnt);
--
    -- FORALL�Ŏg�p�ł���悤�Ƀ��R�[�h�ϐ��𕪊��i�[����
    <<shipped_loop>>
    FOR ln_loop_cnt IN 1..ln_tbl_cnt LOOP
--
debug_log(FND_FILE.LOG,'  ' || ln_loop_cnt || '����');
debug_log(FND_FILE.LOG,'  �݌ɕ�[���[�� = ' || gr_deliv_data_tbl(ln_loop_cnt).stock_rep_rule);
debug_log(FND_FILE.LOG,'  �݌ɕ�[�� = ' || gr_deliv_data_tbl(ln_loop_cnt).stock_rep_origin);
debug_log(FND_FILE.LOG,'  �o�׌�ID = ' || gr_deliv_data_tbl(ln_loop_cnt).deliver_from_id);
debug_log(FND_FILE.LOG,'  �o�׌��R�[�h = ' || gr_deliv_data_tbl(ln_loop_cnt).deliver_from);
debug_log(FND_FILE.LOG,'  �o�א�ID = ' || gr_deliv_data_tbl(ln_loop_cnt).deliver_to_id);
debug_log(FND_FILE.LOG,'  �o�א�R�[�h = ' || gr_deliv_data_tbl(ln_loop_cnt).deliver_to);
debug_log(FND_FILE.LOG,'  �o��OPM�i��ID = '
                        || gr_deliv_data_tbl(ln_loop_cnt).item_id);
debug_log(FND_FILE.LOG,'  �o��INV�i��ID = '
                        || gr_deliv_data_tbl(ln_loop_cnt).shipping_inventory_item_id);
debug_log(FND_FILE.LOG,'  �o�וi�ڃR�[�h = '
                        || gr_deliv_data_tbl(ln_loop_cnt).shipping_item_code);
debug_log(FND_FILE.LOG,'  �˗�No = ' || gr_deliv_data_tbl(ln_loop_cnt).request_no);
--
      -- ���[�����擾�ł������R�[�h�݂̂𒆊ԃe�[�u���i�[�ΏۂƂ���B
      IF ((gr_deliv_data_tbl(ln_loop_cnt).stock_rep_rule = gv_cons_rule_move)
           OR
           (gr_deliv_data_tbl(ln_loop_cnt).stock_rep_rule = gv_cons_rule_order))
      THEN
        ln_cnt := ln_cnt + 1;
        gt_s_deliver_to_id(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).deliver_to_id;              -- �o�א�ID
        gt_s_deliver_to(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).deliver_to;                 -- �o�א�R�[�h
        gt_s_request_no(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).request_no;                 -- �˗�No
        gt_s_deliver_from_id(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).deliver_from_id;            -- �o�׌�ID
        gt_s_deliver_from(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).deliver_from;               -- �o�׌��R�[�h
        gt_s_weight_capacity_class(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).weight_capacity_class;      -- �d�ʗe�ϋ敪
        gt_s_shipping_inv_item_id(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).shipping_inventory_item_id; -- �o��INV�i��ID
        gt_s_item_id(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).item_id;                    -- �o��OPM�i��ID
        gt_s_shipping_item_code(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).shipping_item_code;         -- �i�ڃR�[�h
        gt_s_quantity(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).quantity;                   -- ����
        gt_s_order_type_id(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).order_type_id;              -- �󒍃^�C�vID
        gt_s_transaction_type_name(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).transaction_type_name;      -- �o�Ɍ`��
        gt_s_item_class_code(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).item_class_code;            -- �i�ڋ敪
        gt_s_prod_class_code(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).prod_class_code;            -- ���i�敪
        gt_s_drop_ship_wsh_div(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).drop_ship_wsh_div;          -- �����敪
        gt_s_num_of_deliver(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).num_of_deliver;             -- �o�ד���
        gt_s_conv_unit(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).conv_unit;                  -- ���o�Ɋ��Z�P��
        gt_s_num_of_cases(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).num_of_cases;               -- �P�[�X����
        gt_s_item_um(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).item_um;                    -- �P��
        gt_s_frequent_qty(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).frequent_qty;               -- ��\����
        gt_s_stock_rep_rule(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).stock_rep_rule;             -- �݌ɕ�[���[��
        gt_s_stock_rep_origin(ln_cnt) :=
          gr_deliv_data_tbl(ln_loop_cnt).stock_rep_origin;           -- �݌ɕ�[��
--
      -- ���[�����擾�ł��Ȃ������ꍇ�͒��ԃe�[�u���i�[�ΏۊO�Ƃ���B
      ELSE
        ln_not_cnt := ln_not_cnt + 1;
      END IF;
    END LOOP shipped_loop;
--
    -- �o�׍݌ɕ�[�����ԃe�[�u���o�^
    IF (ln_cnt > 0) THEN
    FORALL ln_inst_cnt IN 1..ln_cnt
      INSERT INTO xxwsh_shipping_stock_rep_tmp(
        deliver_to_id,              -- �o�א�ID
        deliver_to,                 -- �o�א�R�[�h
        request_no,                 -- �˗�No
        deliver_from_id,            -- �o�׌�ID
        deliver_from,               -- �o�׌��R�[�h
        weight_capacity_class,      -- �d�ʗe�ϋ敪
        shipping_inventory_item_id, -- �o�וi��ID
        item_id,                    -- �i��ID
        shipping_item_code,         -- �i�ڃR�[�h
        quantity,                   -- ����
        order_type_id,              -- �󒍃^�C�vID
        transaction_type_name,      -- �o�Ɍ`��
        item_class_code,            -- �i�ڋ敪
        prod_class_code,            -- ���i�敪
        drop_ship_wsh_div,          -- �����敪
        num_of_deliver,             -- �o�ד���
        conv_unit,                  -- ���o�Ɋ��Z�P��
        num_of_cases,               -- �P�[�X����
        item_um,                    -- �P��
        frequent_qty,               -- ��\����
        stock_rep_rule,             -- �݌ɕ�[���[��
        stock_rep_origin            -- �݌ɕ�[��
      )VALUES(
        gt_s_deliver_to_id(ln_inst_cnt),              -- �o�א�ID
        gt_s_deliver_to(ln_inst_cnt),                 -- �o�א�R�[�h
        gt_s_request_no(ln_inst_cnt),                 -- �˗�No
        gt_s_deliver_from_id(ln_inst_cnt),            -- �o�׌�ID
        gt_s_deliver_from(ln_inst_cnt),               -- �o�׌��R�[�h
        gt_s_weight_capacity_class(ln_inst_cnt),      -- �d�ʗe�ϋ敪
        gt_s_shipping_inv_item_id(ln_inst_cnt),       -- INV�o�וi��ID
        gt_s_item_id(ln_inst_cnt),                    -- OPM�i��ID
        gt_s_shipping_item_code(ln_inst_cnt),         -- �i�ڃR�[�h
        gt_s_quantity(ln_inst_cnt),                   -- ����
        gt_s_order_type_id(ln_inst_cnt),              -- �󒍃^�C�vID
        gt_s_transaction_type_name(ln_inst_cnt),      -- �o�Ɍ`��
        gt_s_item_class_code(ln_inst_cnt),            -- �i�ڋ敪
        gt_s_prod_class_code(ln_inst_cnt),            -- ���i�敪
        gt_s_drop_ship_wsh_div(ln_inst_cnt),          -- �����敪
        gt_s_num_of_deliver(ln_inst_cnt),             -- �o�ד���
        gt_s_conv_unit(ln_inst_cnt),                  -- ���o�Ɋ��Z�P��
        gt_s_num_of_cases(ln_inst_cnt),               -- �P�[�X����
        gt_s_item_um(ln_inst_cnt),                    -- �P��
        gt_s_frequent_qty(ln_inst_cnt),               -- ��\����
        gt_s_stock_rep_rule(ln_inst_cnt),             -- �݌ɕ�[���[��
        gt_s_stock_rep_origin(ln_inst_cnt)            -- �݌ɕ�[��
      );
      END IF;
--
--
debug_log(FND_FILE.LOG,'  ���ԃe�[�u��(�o��)�i�[���� = ' || ln_cnt);
debug_log(FND_FILE.LOG,'  �ǂݔ�΂����R�[�h���� = ' || ln_not_cnt);
debug_log(FND_FILE.LOG,'(C-6)' || cv_prg_name || ' End�����');
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
  END ins_ints_table;
--
  /**********************************************************************************
   * Procedure Name   : ins_intm_table
   * Description      : C-7  ���ԃe�[�u���o�^(�ړ�)
   ***********************************************************************************/
  PROCEDURE ins_intm_table(
      ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_intm_table'; -- �v���O������
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
    ln_tbl_cnt   NUMBER :=0;     -- �����Ώی���
    ln_cnt       NUMBER :=0;     -- ���ԃe�[�u���i�[�Ώی����J�E���^
    ln_inst_cnt  NUMBER :=0;     -- ���ԃe�[�u���i�[�����p���[�v�J�E���^
    ln_loop_cnt  NUMBER :=0;     -- �����Ώۃ��R�[�h�擾���[�v�J�E���^
    ln_not_cnt   NUMBER :=0;     -- �ǂݔ�΂����R�[�h�̃J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
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
debug_log(FND_FILE.LOG,'(C-7)' || cv_prg_name || ' Start���');
--
    -- ���R�[�h�ϐ��̃��R�[�h�������߂�
    ln_tbl_cnt := gr_move_data_tbl.COUNT;
debug_log(FND_FILE.LOG,'  �����Ώی��� = ' || ln_tbl_cnt);
--
    -- FORALL�Ŏg�p�ł���悤�Ƀ��R�[�h�ϐ��𕪊��i�[����
    ln_cnt := 0;
    <<move_loop>>
    FOR ln_loop_cnt IN 1..ln_tbl_cnt LOOP
--
debug_log(FND_FILE.LOG,'  ' || ln_loop_cnt || '����');
debug_log(FND_FILE.LOG,'  �݌ɕ�[���[�� = ' || gr_move_data_tbl(ln_loop_cnt).stock_rep_rule);
debug_log(FND_FILE.LOG,'  �݌ɕ�[�� = ' || gr_move_data_tbl(ln_loop_cnt).stock_rep_origin);
debug_log(FND_FILE.LOG,'  �o�Ɍ�ID = ' || gr_move_data_tbl(ln_loop_cnt).shipped_locat_id);
debug_log(FND_FILE.LOG,'  �o�Ɍ��R�[�h = ' || gr_move_data_tbl(ln_loop_cnt).shipped_locat_code);
debug_log(FND_FILE.LOG,'  ���ɐ�ID = ' || gr_move_data_tbl(ln_loop_cnt).ship_to_locat_id);
debug_log(FND_FILE.LOG,'  ���ɐ�R�[�h = ' || gr_move_data_tbl(ln_loop_cnt).ship_to_locat_code);
debug_log(FND_FILE.LOG,'  OPM�i��ID = ' || gr_move_data_tbl(ln_loop_cnt).item_id);
debug_log(FND_FILE.LOG,'  INV�i��ID = ' || gr_move_data_tbl(ln_loop_cnt).inventory_item_id);
debug_log(FND_FILE.LOG,'  �i�ڃR�[�h = ' || gr_move_data_tbl(ln_loop_cnt).item_code);
debug_log(FND_FILE.LOG,'  �ړ��ԍ� = ' || gr_move_data_tbl(ln_loop_cnt).mov_num);
--
      -- ���[�����擾�ł������R�[�h�݂̂𒆊ԃe�[�u���i�[�ΏۂƂ���B
      IF ((gr_move_data_tbl(ln_loop_cnt).stock_rep_rule = gv_cons_rule_move)
           OR
           (gr_move_data_tbl(ln_loop_cnt).stock_rep_rule = gv_cons_rule_order))
      THEN
        ln_cnt := ln_cnt + 1;
        gt_i_mov_num(ln_cnt) :=
           gr_move_data_tbl(ln_loop_cnt).mov_num;                    -- �ړ��ԍ�
        gt_i_shipped_locat_id(ln_cnt) :=
          gr_move_data_tbl(ln_loop_cnt).shipped_locat_id;           -- �o�Ɍ�ID
        gt_i_shipped_locat_code(ln_cnt) :=
          gr_move_data_tbl(ln_loop_cnt).shipped_locat_code;         -- �o�Ɍ��R�[�h
        gt_i_ship_to_locat_id(ln_cnt) :=
          gr_move_data_tbl(ln_loop_cnt).ship_to_locat_id;           -- ���ɐ�ID
        gt_i_ship_to_locat_code(ln_cnt) :=
          gr_move_data_tbl(ln_loop_cnt).ship_to_locat_code;         -- ���ɐ�R�[�h
        gt_i_weight_capacity_class(ln_cnt) :=
          gr_move_data_tbl(ln_loop_cnt).weight_capacity_class;      -- �d�ʗe�ϋ敪
        gt_i_item_id(ln_cnt) :=
          gr_move_data_tbl(ln_loop_cnt).item_id;                    -- OPM�i��ID
        gt_i_inventory_item_id(ln_cnt) :=
          gr_move_data_tbl(ln_loop_cnt).inventory_item_id;          -- INV�i��ID
        gt_i_item_code(ln_cnt) :=
          gr_move_data_tbl(ln_loop_cnt).item_code;                  -- �i�ڃR�[�h
        gt_i_instruct_qty(ln_cnt) :=
          gr_move_data_tbl(ln_loop_cnt).instruct_qty;               -- �w������
        gt_i_item_class_code(ln_cnt) :=
          gr_move_data_tbl(ln_loop_cnt).item_class_code;            -- �i�ڋ敪
        gt_i_prod_class_code(ln_cnt) :=
          gr_move_data_tbl(ln_loop_cnt).prod_class_code;            -- ���i�敪
        gt_i_num_of_deliver(ln_cnt) :=
          gr_move_data_tbl(ln_loop_cnt).num_of_deliver;             -- �o�ד���
        gt_i_conv_unit(ln_cnt) :=
          gr_move_data_tbl(ln_loop_cnt).conv_unit;                  -- ���o�Ɋ��Z�P��
        gt_i_num_of_cases(ln_cnt) :=
          gr_move_data_tbl(ln_loop_cnt).num_of_cases;               -- �P�[�X����
        gt_i_item_um(ln_cnt) :=
          gr_move_data_tbl(ln_loop_cnt).item_um;                    -- �P��
        gt_i_frequent_qty(ln_cnt) :=
          gr_move_data_tbl(ln_loop_cnt).frequent_qty;               -- ��\����
        gt_i_stock_rep_rule(ln_cnt) :=
          gr_move_data_tbl(ln_loop_cnt).stock_rep_rule;             -- �݌ɕ�[���[��
        gt_i_stock_rep_origin(ln_cnt) :=
          gr_move_data_tbl(ln_loop_cnt).stock_rep_origin;           -- �݌ɕ�[��
--
      -- ���[�����擾�ł��Ȃ������ꍇ�͒��ԃe�[�u���i�[�ΏۊO�Ƃ���B
      ELSE
        ln_not_cnt := ln_not_cnt + 1;
      END IF;
    END LOOP move_loop;
--
    -- �ړ��݌ɕ�[�����ԃe�[�u���o�^
    IF (ln_cnt > 0) THEN
    FORALL ln_inst_cnt IN 1..ln_cnt
      INSERT INTO xxwsh_mov_stock_rep_tmp(
        mov_num,                     -- �ړ�No
        shipped_locat_id,            -- �o�Ɍ�ID
        shipped_locat_code,          -- �o�Ɍ��R�[�h
        ship_to_locat_id,            -- ���ɐ�ID
        ship_to_locat_code,          -- ���ɐ�R�[�h
        weight_capacity_class,       -- �d�ʗe�ϋ敪
        item_id,                     -- OPM�i��ID
        inventory_item_id,           -- INV�i��ID
        item_code,                   -- �i�ڃR�[�h
        instruct_qty,                -- �w������
        item_class_code,             -- �i�ڋ敪
        prod_class_code,             -- ���i�敪
        num_of_deliver,              -- �o�ד���
        conv_unit,                   -- ���o�Ɋ��Z�P��
        num_of_cases,                -- �P�[�X����
        item_um,                     -- �P��
        frequent_qty,                -- ��\����
        stock_rep_rule,              -- �݌ɕ�[���[��
        stock_rep_origin             -- �݌ɕ�[��
      )VALUES(
        gt_i_mov_num(ln_inst_cnt),                     -- �ړ�No
        gt_i_shipped_locat_id(ln_inst_cnt),            -- �o�Ɍ�ID
        gt_i_shipped_locat_code(ln_inst_cnt),          -- �o�Ɍ��R�[�h
        gt_i_ship_to_locat_id(ln_inst_cnt),            -- ���ɐ�ID
        gt_i_ship_to_locat_code(ln_inst_cnt),          -- ���ɐ�R�[�h
        gt_i_weight_capacity_class(ln_inst_cnt),       -- �d�ʗe�ϋ敪
        gt_i_item_id(ln_inst_cnt),                     -- OPM�i��ID
        gt_i_inventory_item_id(ln_inst_cnt),           -- INV�i��ID
        gt_i_item_code(ln_inst_cnt),                   -- �i�ڃR�[�h
        gt_i_instruct_qty(ln_inst_cnt),                -- �w������
        gt_i_item_class_code(ln_inst_cnt),             -- �i�ڋ敪
        gt_i_prod_class_code(ln_inst_cnt),             -- ���i�敪
        gt_i_num_of_deliver(ln_inst_cnt),              -- �o�ד���
        gt_i_conv_unit(ln_inst_cnt),                   -- ���o�Ɋ��Z�P��
        gt_i_num_of_cases(ln_inst_cnt),                -- �P�[�X����
        gt_i_item_um(ln_inst_cnt),                     -- �P��
        gt_i_frequent_qty(ln_inst_cnt),                -- ��\����
        gt_i_stock_rep_rule(ln_inst_cnt),              -- �݌ɕ�[���[��
        gt_i_stock_rep_origin(ln_inst_cnt)             -- �݌ɕ�[��
      );
    END IF;
--
--
debug_log(FND_FILE.LOG,'  ���ԃe�[�u��(�ړ�)�i�[���� = ' || ln_cnt);
debug_log(FND_FILE.LOG,'  �ǂݔ�΂����R�[�h���� = ' || ln_not_cnt);
debug_log(FND_FILE.LOG,'(C-7)' || cv_prg_name || ' End�����');
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
  END ins_intm_table;
--
   /**********************************************************************************
   * Procedure Name   : get_ints_data
   * Description      : C-8  ���ԃe�[�u�����o(�o��)
   ***********************************************************************************/
  PROCEDURE get_ints_data(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ints_data'; -- �v���O������
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
    -- �o�׍݌ɕ�[�����ԃe�[�u���̃f�[�^�𒊏o����J�[�\��
    CURSOR lc_deliv_data_cur
    IS
      SELECT
        xssrt.deliver_to_id,                 -- �o�א�ID
        xssrt.deliver_to,                    -- �o�א�R�[�h
        xssrt.request_no,                    -- �˗�No
        xssrt.deliver_from_id,               -- �o�׌�ID
        xssrt.deliver_from,                  -- �o�׌��R�[�h
        xssrt.weight_capacity_class,         -- �d�ʗe�ϋ敪
        xssrt.shipping_inventory_item_id,    -- �o�וi��ID
        xssrt.item_id,                       -- �i��ID
        xssrt.shipping_item_code,            -- �i�ڃR�[�h
        xssrt.quantity,                      -- ����
        xssrt.order_type_id,                 -- �󒍃^�C�vID
        xssrt.transaction_type_name,         -- �o�Ɍ`��
        xssrt.item_class_code,               -- �i�ڋ敪
        DECODE(xssrt.item_class_code,gv_cons_item_product,gv_cons_p_flg_prod,gv_cons_p_flg_noprod),
        -- �i�ڋ敪��'1'�Ȃ�'1'�����̑���'2'���Z�b�g�����i���ʋ敪
        xssrt.prod_class_code,               -- ���i�敪
        NVL(xssrt.drop_ship_wsh_div,gv_cons_ds_type_n),   -- �����敪
        xssrt.num_of_deliver,                -- �o�ד���
        xssrt.conv_unit,                     -- ���o�Ɋ��Z�P��
        xssrt.num_of_cases,                  -- �P�[�X����
        xssrt.item_um,                       -- �P��
        xssrt.frequent_qty,                  -- ��\����
        xssrt.stock_rep_rule,                -- �݌ɕ�[���[��
        xssrt.stock_rep_origin               -- �݌ɕ�[��
      FROM
        xxwsh_shipping_stock_rep_tmp       xssrt   -- �o�׍݌ɕ�[�����ԃe�[�u��
      ORDER BY
        xssrt.stock_rep_rule,                -- �݌ɕ�[���[��
        xssrt.stock_rep_origin,              -- �݌ɕ�[��
        xssrt.deliver_from,                  -- �o�׌��R�[�h
        xssrt.drop_ship_wsh_div,             -- �����敪
        xssrt.deliver_to,                    -- �o�א�R�[�h
        xssrt.prod_class_code,               -- ���i�敪
        xssrt.weight_capacity_class,         -- �d�ʗe�ϋ敪
        DECODE(xssrt.item_class_code,gv_cons_item_product,gv_cons_p_flg_prod,gv_cons_p_flg_noprod),
                                             -- ���i���ʋ敪
        xssrt.shipping_item_code;            -- �i�ڃR�[�h
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
--
debug_log(FND_FILE.LOG,'(C-8)' || cv_prg_name || ' Start���');
--
    -- ���R�[�h�ϐ��̏�����
    gr_deliv_data_tbl.delete;
--
    -- �J�[�\���I�[�v��
    OPEN lc_deliv_data_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH lc_deliv_data_cur BULK COLLECT INTO gr_deliv_data_tbl;
--
    -- ���������̃Z�b�g
    gn_target_cnt_deliv := gr_deliv_data_tbl.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE lc_deliv_data_cur;
--
debug_log(FND_FILE.LOG,'  ���ԃe�[�u��(�o��)�擾���� =' || gn_target_cnt_deliv);
debug_log(FND_FILE.LOG,'(C-8)' || cv_prg_name || ' End�����');
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
--
      IF ( lc_deliv_data_cur%ISOPEN ) THEN
        CLOSE lc_deliv_data_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
--
      IF ( lc_deliv_data_cur%ISOPEN ) THEN
        CLOSE lc_deliv_data_cur;
      END IF;
--
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--
      IF ( lc_deliv_data_cur%ISOPEN ) THEN
        CLOSE lc_deliv_data_cur;
      END IF;
--
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_ints_data;
--
   /**********************************************************************************
   * Procedure Name   : get_intm_data
   * Description      : C-9  ���ԃe�[�u�����o(�ړ�)
   ***********************************************************************************/
  PROCEDURE get_intm_data(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_intm_data'; -- �v���O������
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
    -- �ړ��݌ɕ�[�����ԃe�[�u���̃f�[�^�𒊏o����J�[�\��
    CURSOR lc_move_data_cur
    IS
      SELECT
        xmsrt.mov_num,                       -- �ړ��ԍ�
        xmsrt.shipped_locat_id,              -- �o�Ɍ�ID
        xmsrt.shipped_locat_code,            -- �o�Ɍ��R�[�h
        xmsrt.ship_to_locat_id,              -- ���ɐ�ID
        xmsrt.ship_to_locat_code,            -- ���ɐ�R�[�h
        xmsrt.weight_capacity_class,         -- �d�ʗe�ϋ敪
        xmsrt.item_id,                       -- �i��ID
        xmsrt.inventory_item_id,             --
        xmsrt.item_code,                     -- �i�ڃR�[�h
        xmsrt.instruct_qty,                  -- �w������
        xmsrt.item_class_code,               -- �i�ڋ敪
        DECODE(xmsrt.item_class_code,gv_cons_item_product,gv_cons_p_flg_prod,gv_cons_p_flg_noprod),
        -- �i�ڋ敪��'1'�Ȃ�'1'�����̑���'2'���Z�b�g�����i���ʋ敪
        xmsrt.prod_class_code,               -- ���i�敪
        xmsrt.num_of_deliver,                -- �o�ד���
        xmsrt.conv_unit,                     -- ���o�Ɋ��Z�P��
        xmsrt.num_of_cases,                  -- �P�[�X����
        xmsrt.item_um,                       -- �P��
        xmsrt.frequent_qty,                  -- ��\����
        xmsrt.stock_rep_rule,                -- �݌ɕ�[���[��
        xmsrt.stock_rep_origin               -- �݌ɕ�[��
      FROM
        xxwsh_mov_stock_rep_tmp        xmsrt    -- �ړ��݌ɕ�[�����ԃe�[�u��
      ORDER BY
        xmsrt.stock_rep_rule,                -- �݌ɕ�[���[��
        xmsrt.stock_rep_origin,              -- �݌ɕ�[��
        xmsrt.shipped_locat_code,            -- �o�Ɍ��R�[�h
        xmsrt.prod_class_code,               -- ���i�敪
        xmsrt.weight_capacity_class,         -- �d�ʗe�ϋ敪
        DECODE(xmsrt.item_class_code,gv_cons_item_product,gv_cons_p_flg_prod,gv_cons_p_flg_noprod),
                                             -- ���i���ʋ敪
        xmsrt.item_code;                     -- �i�ڃR�[�h
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
--
debug_log(FND_FILE.LOG,'(C-9)' || cv_prg_name || ' Start���');
--
    -- ���R�[�h�ϐ��̏�����
    gr_move_data_tbl.delete;
--
    -- �J�[�\���I�[�v��
    OPEN lc_move_data_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH lc_move_data_cur BULK COLLECT INTO gr_move_data_tbl;
--
    -- ���������̃Z�b�g
    gn_target_cnt_move := gr_move_data_tbl.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE lc_move_data_cur;
--
debug_log(FND_FILE.LOG,'  ���ԃe�[�u��(�ړ�)�擾���� =' || gn_target_cnt_move);
debug_log(FND_FILE.LOG,'(C-9)' || cv_prg_name || ' End�����');
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
--
      IF ( lc_move_data_cur%ISOPEN ) THEN
        CLOSE lc_move_data_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
--
      IF ( lc_move_data_cur%ISOPEN ) THEN
        CLOSE lc_move_data_cur;
      END IF;
--
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--
      IF ( lc_move_data_cur%ISOPEN ) THEN
        CLOSE lc_move_data_cur;
      END IF;
--
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_intm_data;
--
   /**********************************************************************************
   * Procedure Name   : regi_move_data
   * Description      : C-10 �ړ��˗�/�w���o�^
   ***********************************************************************************/
  PROCEDURE regi_move_data(
    in_shori_cnt             IN         NUMBER,     -- �����J�E���^
    iv_action_type           IN         VARCHAR2,   -- �������
    iv_shipped_date          IN         VARCHAR2,   -- �o�ɓ��w��
    iv_arrival_date          IN         VARCHAR2,   -- �����w��
    iv_instruction_post_code IN         VARCHAR2,   -- �w�������w��
    ov_errbuf                OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'regi_move_data'; -- �v���O������
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
    ln_ret_code                    NUMBER;  -- ���ʊ֐��̃��^�[���l
    lv_mov_line_id                 xxinv_mov_req_instr_lines.mov_line_id%TYPE;              --����ID
    lv_seq_no                      VARCHAR2(12);
    lv_stock_rep_origin      xxcmn_item_locations2_v.segment1%TYPE;                     --�݌ɕ�[��
    lv_stock_rep_origin_id   xxcmn_item_locations2_v.inventory_location_id%TYPE;      --�݌ɕ�[��ID
    lv_frequent_mover        xxcmn_item_locations2_v.frequent_mover%TYPE;             --��\�^���Ǝ�
    lv_locat_to_code         xxcmn_item_locations2_v.segment1%TYPE;                 --���ɐ�(�o�Ɍ�)
    lv_locat_to_id           xxcmn_item_locations2_v.inventory_location_id%TYPE;
                                                                                --���ɐ�ID(�o�Ɍ�ID)
    lv_loading_over_class          VARCHAR2(1);                                   --�ύڃI�[�o�[�敪
    ln_sum_palette_weight    xxinv_mov_req_instr_headers.sum_pallet_weight%TYPE;  --���v�p���b�g�d��
    ln_load_efficiency_weight   xxinv_mov_req_instr_headers.loading_efficiency_weight%TYPE;
                                                                                      --�d�ʐύڌ���
    ln_load_efficiency_capacity xxinv_mov_req_instr_headers.loading_efficiency_capacity%TYPE;
                                                                                     -- �e�ϐύڌ���
    lv_ship_methods          xxinv_mov_req_instr_headers.shipping_method_code%TYPE;      -- �o�ו��@
    lv_mixed_ship_method     xxinv_mov_req_instr_headers.shipping_method_code%TYPE;  -- ���ڔz���敪
    lv_career_id             xxinv_mov_req_instr_headers.career_id%TYPE;               -- �^���Ǝ�ID
    lv_prod_class_code       xxinv_mov_req_instr_headers.item_class%TYPE;                -- ���i�敪
    lv_weight_capacity_class xxinv_mov_req_instr_headers.weight_capacity_class%TYPE; -- �d�ʗe�ϋ敪
    lv_max_ship_methods      xxinv_mov_req_instr_headers.shipping_method_code%TYPE;   -- �ő�z���敪
    ln_drink_deadweight      xxinv_mov_req_instr_headers.sum_weight%TYPE;         -- �h�����N�ύڏd��
    ln_leaf_deadweight       xxinv_mov_req_instr_headers.sum_weight%TYPE;           -- ���[�t�ύڏd��
    ln_drink_loading_capacity xxinv_mov_req_instr_headers.sum_capacity%TYPE;      -- �h�����N�ύڗe��
    ln_leaf_loading_capacity  xxinv_mov_req_instr_headers.sum_capacity%TYPE;        -- ���[�t�ύڗe��
    ln_palette_max_qty        NUMBER;          -- �p���b�g�ő喇��
    lv_item_code              xxinv_mov_req_instr_lines.item_code%TYPE;                 -- �i�ڃR�[�h
    lv_product_flg            xxinv_mov_req_instr_headers.product_flg%TYPE;           -- ���i���ʋ敪
    ln_item_id                xxinv_mov_req_instr_lines.item_id%TYPE;                    -- OPM�i��ID
    lv_item_um                xxwsh_mov_stock_rep_tmp.item_um%TYPE;                           -- �P��
    ln_num_of_deliver         xxwsh_mov_stock_rep_tmp.num_of_deliver%TYPE;                -- �o�ד���
    lv_conv_unit              xxwsh_mov_stock_rep_tmp.conv_unit%TYPE;               -- ���o�Ɋ��Z�P��
    ln_num_of_cases           xxwsh_mov_stock_rep_tmp.num_of_cases%TYPE;                -- �P�[�X����
--
    lv_header_create_flg      VARCHAR2(1) := gv_cons_flg_n;  -- �w�b�_�쐬�t���O
    lv_line_create_flg        VARCHAR2(1) := gv_cons_flg_n;  -- ���׍쐬�t���O
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR lc_il_id_cur  -- �ۊǒIID����������
    IS
      SELECT xilv.inventory_location_id,           -- �ۊǒIID(No.8�Ŏg�p)
             xilv.frequent_mover                   -- ��\�^���Ǝ�(No.22�Ŏg�p)
      FROM   xxcmn_item_locations2_v  xilv         -- OPM�ۊǏꏊ���View2
      WHERE  xilv.segment1   = lv_stock_rep_origin -- �݌ɕ�[���q�ɃR�[�h
        AND  xilv.date_from <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')     -- �����w��
        AND  ((xilv.date_to   >= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))  --
               OR                                                        --
              (xilv.date_to   IS NULL))                                  -- �Ŕ͈͓��ł��邱��
        AND  ROWNUM          = 1;
--
    CURSOR lc_carrier_id_cur  -- �^���Ǝ�ID����������
    IS
      SELECT xcv.party_id                              -- �^���Ǝ�ID(No.21�Ŏg�p)
      FROM   xxcmn_carriers2_v        xcv              -- �^���Ǝҏ��View2
      WHERE  xcv.freight_code    = lv_frequent_mover   -- ��\�^���Ǝ҃R�[�h
        AND  xcv.START_DATE_ACTIVE <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- �����w��
        AND  ((xcv.END_DATE_ACTIVE >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')) --
               OR                                                            --
              (xcv.END_DATE_ACTIVE   IS NULL))                               -- �Ŕ͈͓��ł��邱��
        AND  ROWNUM            = 1;
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
--
debug_log(FND_FILE.LOG,'(C-10)' || cv_prg_name || ' Start���');
--
-- ############################################################################################
-- �w�b�_�f�[�^�Z�b�g
-- ############################################################################################
    -- �w�b�_���쐬���邩�𔻒f����(�݌ɕ�[���A�o�׌��R�[�h�A���i�敪�A�d�ʗe�ϋ敪�A
    -- ���i���ʋ敪�̂��Âꂩ���قȂ�ꍇ)
    -- ������ʂ��u�o�ׁv
    IF (iv_action_type = gv_cons_t_deliv) THEN
      IF ((gv_stock_rep_origin_m IS NULL)                -- 1���ڂ̃w�b�_�쐬�� �܂���
         OR                                              -- �ȉ��̂ǂꂩ�̍��ڂ��قȂ�
         ((gv_stock_rep_origin_m      <> gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin)
          OR
          (gv_stock_rep_rule_m        <> gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule)
          OR
          (gv_deliver_from_m          <> gr_deliv_data_tbl(in_shori_cnt).deliver_from)
          OR
          (gv_prod_class_code_m       <> gr_deliv_data_tbl(in_shori_cnt).prod_class_code)
          OR
          (gv_weight_capacity_class_m <> gr_deliv_data_tbl(in_shori_cnt).weight_capacity_class)
          OR
          (gv_product_flg_m           <> gr_deliv_data_tbl(in_shori_cnt).product_flg)))
      THEN
--
        lv_header_create_flg := gv_cons_flg_y;
--
debug_log(FND_FILE.LOG,'  �ړ��w�b�_�쐬......................');
debug_log(FND_FILE.LOG,'    �݌ɕ�[�� = ' || gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin);
debug_log(FND_FILE.LOG,'    �݌ɕ�[���[�� = ' || gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule);
debug_log(FND_FILE.LOG,'    �o�Ɍ�(��[��) = ' || gr_deliv_data_tbl(in_shori_cnt).deliver_from);
debug_log(FND_FILE.LOG,'    �d�ʗe�ϋ敪 = '
                        || gr_deliv_data_tbl(in_shori_cnt).weight_capacity_class);
debug_log(FND_FILE.LOG,'    ���i�敪 = ' || gr_deliv_data_tbl(in_shori_cnt).prod_class_code);
debug_log(FND_FILE.LOG,'    ���i���ʋ敪 = ' || gr_deliv_data_tbl(in_shori_cnt).product_flg);
debug_log(FND_FILE.LOG,'    �i�ڋ敪 = ' || gr_deliv_data_tbl(in_shori_cnt).item_class_code);
--
      ELSE
--
        lv_header_create_flg := gv_cons_flg_n;
--
debug_log(FND_FILE.LOG,'  �ړ��w�b�_�쐬�s�v..................');
--
      END IF;
--
    -- ������ʂ��u�ړ��v
    ELSE
--
      IF ((gv_stock_rep_origin_m IS NULL)                -- 1���ڂ̃w�b�_�쐬�� �܂���
         OR                                              -- �ȉ��̂ǂꂩ�̍��ڂ��قȂ�
         ((gv_stock_rep_origin_m      <> gr_move_data_tbl(in_shori_cnt).stock_rep_origin)
            OR
          (gv_stock_rep_rule_m        <> gr_move_data_tbl(in_shori_cnt).stock_rep_rule)
            OR
          (gv_deliver_from_m          <> gr_move_data_tbl(in_shori_cnt).shipped_locat_code)
            OR
          (gv_prod_class_code_m       <> gr_move_data_tbl(in_shori_cnt).prod_class_code)
            OR
          (gv_weight_capacity_class_m <> gr_move_data_tbl(in_shori_cnt).weight_capacity_class)
            OR
          (gv_product_flg_m           <> gr_move_data_tbl(in_shori_cnt).product_flg)))
      THEN
--
        lv_header_create_flg := gv_cons_flg_y;
--
debug_log(FND_FILE.LOG,'  �ړ��w�b�_�쐬......................');
debug_log(FND_FILE.LOG,'    �݌ɕ�[�� = ' || gr_move_data_tbl(in_shori_cnt).stock_rep_origin);
debug_log(FND_FILE.LOG,'    �݌ɕ�[���[�� = ' || gr_move_data_tbl(in_shori_cnt).stock_rep_rule);
debug_log(FND_FILE.LOG,'    �o�Ɍ�(��[��) = ' || gr_move_data_tbl(in_shori_cnt).shipped_locat_code);
debug_log(FND_FILE.LOG,'    �d�ʗe�ϋ敪 = '
                        || gr_move_data_tbl(in_shori_cnt).weight_capacity_class);
debug_log(FND_FILE.LOG,'    ���i�敪 = ' || gr_move_data_tbl(in_shori_cnt).prod_class_code);
debug_log(FND_FILE.LOG,'    ���i���ʋ敪 = ' || gr_move_data_tbl(in_shori_cnt).product_flg);
debug_log(FND_FILE.LOG,'    �i�ڋ敪 = ' || gr_move_data_tbl(in_shori_cnt).item_class_code);
--
      ELSE
--
        lv_header_create_flg := gv_cons_flg_n;
--
debug_log(FND_FILE.LOG,'  �ړ��w�b�_�쐬�s�v..................');
--
      END IF;
--
    END IF;
--
    -- �w�b�_�쐬�v�̏ꍇ
    IF (lv_header_create_flg = gv_cons_flg_y) THEN
      -- **************************************************
      -- �ړ��˗�/�w���w�b�_�o�^�p�ϐ��Ƀf�[�^���Z�b�g����
      -- **************************************************
--
      -- �w�����ʍ��v�ϐ����w�b�_�P�ʂŏ�����
      gn_sum_inst_quantity  := 0;
      -- ���הԍ�������
      gn_line_number   := 0;
--
      BEGIN
        -- �V�[�P���X���ړ��w�b�_ID�����߂�
        SELECT xxinv_mov_hdr_s1.NEXTVAL
        INTO   gn_mov_hdr_id
        FROM   DUAL;
--
      EXCEPTION
        WHEN OTHERS THEN
          ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
          ov_retcode := gv_status_error;
          RAISE global_api_expt;
      END;
--
      -- �̔Ԋ֐�
      xxcmn_common_pkg.get_seq_no( gv_cons_seq_move,
                                   lv_seq_no,
                                   lv_errbuf,
                                   lv_retcode,
                                   lv_errmsg);
--
debug_log(FND_FILE.LOG,'  �ړ��ԍ� = ' || lv_seq_no);
--
      -- �G���[�̏ꍇ  �����������͌p�����A�x���I���ƂȂ� #######################3
      IF (lv_retcode <> gv_status_normal) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                      ,gv_msg_wsh_13008     -- �̔Ԋ֐��G���[
                                                      ,gv_tkn_table_name    -- �g�[�N��'TABLE_NAME'
                                                      ,gv_cons_mov_hdr_tbl  -- �ړ��˗�/�w���w�b�_
                                                      ,gv_tkn_param1        -- �g�[�N��'PARAM1'
                                                      ,gv_cons_seq_move     -- �̔ԋ敪�u�ړ��v
                                                      ,gv_tkn_param2        -- �g�[�N��'PARAM2'
                                                      ,lv_retcode           -- ���^�[���R�[�h
                                                      ,gv_tkn_param3        -- �g�[�N��'PARAM3'
                                                      ,lv_errmsg)           -- ���b�Z�[�W
                                                      ,1
                                                      ,5000);
--
        gn_warn_cnt := gn_warn_cnt + 1;
        RAISE common_warn_expt;
--
      END IF;
--
      -- �p�����[�^�̏�����ʂŒl�̎擾��(�o��/�ړ�)��؂蕪����
      IF (iv_action_type = gv_cons_t_deliv) THEN -- �o�ׂ̏ꍇ
--
        lv_stock_rep_origin := gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin; --�o�Ɍ�(��[��)
        lv_locat_to_code    := gr_deliv_data_tbl(in_shori_cnt).deliver_from;     --���ɐ�
        lv_locat_to_id      := gr_deliv_data_tbl(in_shori_cnt).deliver_from_id;  --���ɐ�ID
        lv_weight_capacity_class := gr_deliv_data_tbl(in_shori_cnt).weight_capacity_class;
                                                                                      --�d�ʗe�ϋ敪
        lv_prod_class_code := gr_deliv_data_tbl(in_shori_cnt).prod_class_code;   --���i�敪
        lv_product_flg := gr_deliv_data_tbl(in_shori_cnt).product_flg;           --���i���ʋ敪
--
      ELSE --�ړ��̏ꍇ
--
        lv_stock_rep_origin := gr_move_data_tbl(in_shori_cnt).stock_rep_origin;  --�o�Ɍ�(��[��)
        lv_locat_to_code    := gr_move_data_tbl(in_shori_cnt).shipped_locat_code;--���ɐ�
        lv_locat_to_id      := gr_move_data_tbl(in_shori_cnt).shipped_locat_id;  --���ɐ�ID
        lv_weight_capacity_class := gr_move_data_tbl(in_shori_cnt).weight_capacity_class;
                                                                                      --�d�ʗe�ϋ敪
        lv_prod_class_code := gr_move_data_tbl(in_shori_cnt).prod_class_code;    --���i�敪
        lv_product_flg := gr_move_data_tbl(in_shori_cnt).product_flg;            --���i���ʋ敪
--
      END IF;
--
--
      -- �o�Ɍ�ID(��[����OPM�ۊǏꏊID)����ё�\�^���Ǝ҂�����
      OPEN  lc_il_id_cur;
      FETCH lc_il_id_cur INTO lv_stock_rep_origin_id,
                              lv_frequent_mover;
      CLOSE lc_il_id_cur;
--
debug_log(FND_FILE.LOG,'    �݌ɕ�[��ID =' || lv_stock_rep_origin_id);
debug_log(FND_FILE.LOG,'    �^���Ǝ҃R�[�h =' || lv_frequent_mover);
--
      -- �^���Ǝ�ID������
      OPEN  lc_carrier_id_cur;
      FETCH lc_carrier_id_cur INTO lv_career_id;
      CLOSE lc_carrier_id_cur;
--
debug_log(FND_FILE.LOG,'    �^���Ǝ�ID =' || lv_career_id);
--
      -- �ő�z���敪�Z�o�֐�
      ln_ret_code := xxwsh_common_pkg.get_max_ship_method(
                                       gv_cons_wh,                -- 1.�R�[�h�敪�P I '4'
                                       lv_stock_rep_origin,       -- 2.���o�ɏꏊ�R�[�h�P I
                                       gv_cons_wh,                -- 3.�R�[�h�敪�Q I '4'
                                       lv_locat_to_code,          -- 4.���o�ɏꏊ�R�[�h�Q I
                                       lv_prod_class_code,        -- 5.���i�敪 I
                                       lv_weight_capacity_class,  -- 6.�d�ʗe�ϋ敪 I
                                       NULL,                      -- 7.�����z�ԑΏۋ敪 I
                           TO_DATE(iv_arrival_date,'YYYY/MM/DD'), -- 8.���(�K�p�����) I
                                       lv_max_ship_methods,       -- 9.�ő�z���敪 O
                                       ln_drink_deadweight,       -- 10.�h�����N�ύڏd�� O
                                       ln_leaf_deadweight,        -- 11.���[�t�ύڏd�� O
                                       ln_drink_loading_capacity, -- 12.�h�����N�ύڗe�� O
                                       ln_leaf_loading_capacity,  -- 13.���[�t�ύڗe�� O
                                       ln_palette_max_qty);       -- 14.�p���b�g�ő喇�� O
--
debug_log(FND_FILE.LOG,'  �ő�z���敪�擾�֐� ��������');
debug_log(FND_FILE.LOG,'    lv_stock_rep_origin = ' || lv_stock_rep_origin);
debug_log(FND_FILE.LOG,'    lv_locat_to_code = ' || lv_locat_to_code);
debug_log(FND_FILE.LOG,'    lv_prod_class_code = ' || lv_prod_class_code);
debug_log(FND_FILE.LOG,'    lv_weight_capacity_class = ' || lv_weight_capacity_class);
debug_log(FND_FILE.LOG,'    ln_ret_code = ' || ln_ret_code);
debug_log(FND_FILE.LOG,'    lv_max_ship_methods = ' || lv_max_ship_methods);
debug_log(FND_FILE.LOG,'    ln_drink_deadweight = ' || TO_CHAR(ln_drink_deadweight));
debug_log(FND_FILE.LOG,'    ln_leaf_deadweight = ' || TO_CHAR(ln_leaf_deadweight));
debug_log(FND_FILE.LOG,'    ln_drink_loading_capacity = ' || TO_CHAR(ln_drink_loading_capacity));
debug_log(FND_FILE.LOG,'    ln_leaf_loading_capacity = ' || TO_CHAR(ln_leaf_loading_capacity));
debug_log(FND_FILE.LOG,'    ln_palette_max_qty = ' || TO_CHAR(ln_palette_max_qty));
--
      -- �G���[�̏ꍇ  �����������͌p�����A�x���I���ƂȂ� #######################3
      IF (ln_ret_code <> gn_status_normal) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                    ,gv_msg_wsh_13009     -- �ő�z���敪�֐��G���[
                                                    ,gv_tkn_table_name    -- �g�[�N��'TABLE_NAME'
                                                    ,gv_cons_mov_hdr_tbl  -- �ړ��˗�/�w���w�b�_
                                                    ,gv_tkn_param1        -- �g�[�N��'PARAM1'
                                                    ,gv_cons_wh           -- �R�[�h�敪
                                                    ,gv_tkn_param2        -- �g�[�N��'PARAM2'
                                                    ,lv_stock_rep_origin  -- ���o�ɏꏊ�R�[�h
                                                    ,gv_tkn_param3        -- �g�[�N��'PARAM3'
                                                    ,gv_cons_wh           -- �R�[�h�敪
                                                    ,gv_tkn_param4        -- �g�[�N��'PARAM4'
                                                    ,lv_locat_to_code     -- ���o�ɏꏊ�R�[�h
                                                    ,gv_tkn_param5        -- �g�[�N��'PARAM5'
                                                    ,lv_prod_class_code   -- ���i�敪
                                                    ,gv_tkn_param6        -- �g�[�N��'PARAM6'
                                                    ,lv_weight_capacity_class -- �d�ʗe�ϋ敪
                                                    ,gv_tkn_param7        -- �g�[�N��'PARAM7'
                                                    ,iv_arrival_date)     -- ���
                                                    ,1
                                                    ,5000);
--
        gn_warn_cnt := gn_warn_cnt + 1;
        RAISE common_warn_expt;
--
      END IF;
--
      -- ##########################################################################
      -- �ϐ��Ɋi�[���� ###########################################################
      -- ##########################################################################
      -- �z��ԍ����{�P����
      gn_ins_data_cnt_mh := gn_ins_data_cnt_mh + 1;
--
debug_log(FND_FILE.LOG,'  �w�b�_�ϐ��i�[ gn_ins_data_cnt_mh =' || TO_CHAR(gn_ins_data_cnt_mh));
--
      -- �ړ��w�b�_ID
      gr_move_header_tbl(gn_ins_data_cnt_mh).mov_hdr_id := gn_mov_hdr_id;
      -- �ړ��ԍ�
      gr_move_header_tbl(gn_ins_data_cnt_mh).mov_num := lv_seq_no;-- �V�[�P���XNo
      -- �ړ��^�C�v
      gr_move_header_tbl(gn_ins_data_cnt_mh).mov_type := gv_cons_move_type; --�u�ϑ�����'1'�v
      -- ���͓�
      gr_move_header_tbl(gn_ins_data_cnt_mh).entered_date := SYSDATE; -- �V�X�e������
      -- �w������                                                  -- �p�����[�^�̎w�������w��
      gr_move_header_tbl(gn_ins_data_cnt_mh).instruction_post_code := iv_instruction_post_code;
      -- �X�e�[�^�X
      gr_move_header_tbl(gn_ins_data_cnt_mh).status := gv_cons_mov_sts_c; --�u������'03'�v
      -- �ʒm�X�e�[�^�X
      gr_move_header_tbl(gn_ins_data_cnt_mh).notif_status := gv_cons_sts_mi; --�u���ʒm'10'�v
      -- �o�Ɍ�ID
      gr_move_header_tbl(gn_ins_data_cnt_mh).shipped_locat_id := lv_stock_rep_origin_id;
      -- �o�Ɍ��ۊǏꏊ
      gr_move_header_tbl(gn_ins_data_cnt_mh).shipped_locat_code := lv_stock_rep_origin;
                                                                           -- �݌ɕ�[��
      -- ���ɐ�ID
      gr_move_header_tbl(gn_ins_data_cnt_mh).ship_to_locat_id := lv_locat_to_id;
      -- ���ɐ�ۊǏꏊ
      gr_move_header_tbl(gn_ins_data_cnt_mh).ship_to_locat_code := lv_locat_to_code;
      -- �o�ɗ\���
      gr_move_header_tbl(gn_ins_data_cnt_mh).schedule_ship_date :=
                                    TRUNC(TO_DATE(iv_shipped_date,'YYYY/MM/DD')); --�o�ɓ��w��
      -- ���ɗ\���
      gr_move_header_tbl(gn_ins_data_cnt_mh).schedule_arrival_date :=
                                    TRUNC(TO_DATE(iv_arrival_date,'YYYY/MM/DD')); -- �����w��
      -- �^���敪
      gr_move_header_tbl(gn_ins_data_cnt_mh).freight_charge_class := gv_cons_umu_ari; -- �u�L'1'�v
      -- �_��O�^���敪
      gr_move_header_tbl(gn_ins_data_cnt_mh).no_cont_freight_class
                                                              := gv_cons_no_cont_freight; --�ΏۊO0
      -- �z���敪
      gr_move_header_tbl(gn_ins_data_cnt_mh).shipping_method_code := lv_max_ship_methods;
      -- �g�DID
      gr_move_header_tbl(gn_ins_data_cnt_mh).organization_id := gn_organization_id; -- �}�X�^�g�DID
      -- �^���Ǝ�ID
      gr_move_header_tbl(gn_ins_data_cnt_mh).career_id := lv_career_id;
      -- �^���Ǝ�
      gr_move_header_tbl(gn_ins_data_cnt_mh).freight_carrier_code := lv_frequent_mover;
      -- ��{�d��
      gr_move_header_tbl(gn_ins_data_cnt_mh).based_weight := ln_leaf_deadweight; -- ���[�t�ύڏd��
      -- ��{�e��
      gr_move_header_tbl(gn_ins_data_cnt_mh).based_capacity := ln_leaf_loading_capacity;
                                                                                 -- ���[�t�ύڗe��
      -- �d�ʗe�ϋ敪
      gr_move_header_tbl(gn_ins_data_cnt_mh).weight_capacity_class := lv_weight_capacity_class;
      -- ���i�敪
      gr_move_header_tbl(gn_ins_data_cnt_mh).item_class := lv_prod_class_code;
      -- ���i���ʋ敪
      gr_move_header_tbl(gn_ins_data_cnt_mh).product_flg := lv_product_flg;
      -- ���ьv��σt���O
      gr_move_header_tbl(gn_ins_data_cnt_mh).comp_actual_flg := gv_cons_flg_n; --���і��v��'N'
      -- ���ђ����t���O
      gr_move_header_tbl(gn_ins_data_cnt_mh).correct_actual_flg := gv_cons_flg_n; --���і�����'N'
      -- ��ʍX�V��
      gr_move_header_tbl(gn_ins_data_cnt_mh).screen_update_by := gn_created_by;
      -- ��ʍX�V����
      gr_move_header_tbl(gn_ins_data_cnt_mh).screen_update_date := SYSDATE;
      -- �쐬��
      gr_move_header_tbl(gn_ins_data_cnt_mh).created_by := gn_created_by;
      -- �쐬��
      gr_move_header_tbl(gn_ins_data_cnt_mh).creation_date :=SYSDATE;
      -- �ŏI�X�V��
      gr_move_header_tbl(gn_ins_data_cnt_mh).last_updated_by := gn_created_by;
      -- �ŏI�X�V��
      gr_move_header_tbl(gn_ins_data_cnt_mh).last_update_date := SYSDATE;
      -- �ŏI�X�V���O�C��
      gr_move_header_tbl(gn_ins_data_cnt_mh).last_update_login := gn_login_user;
      -- �v��ID
      gr_move_header_tbl(gn_ins_data_cnt_mh).request_id := gn_conc_request_id;
      -- �R���J�����g�v���O�����A�v���P�[�V����ID
      gr_move_header_tbl(gn_ins_data_cnt_mh).program_application_id := gn_prog_appl_id;
      -- �R���J�����g�v���O����ID
      gr_move_header_tbl(gn_ins_data_cnt_mh).program_id := gn_conc_program_id;
      -- �v���O�����X�V��
      gr_move_header_tbl(gn_ins_data_cnt_mh).program_update_date := SYSDATE;
--
--
      -- �w�b�_�쐬�P�ʂ̍��ڕێ�
      -- ������ʂ��u�o�ׁv
      IF (iv_action_type = gv_cons_t_deliv) THEN
        gv_stock_rep_origin_m      := gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin;
                                                                               -- �݌ɕ�[��
        gv_stock_rep_rule_m        := gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule;
                                                                               -- �݌ɕ�[���[��
        gv_deliver_from_m          := gr_deliv_data_tbl(in_shori_cnt).deliver_from;
                                                                               -- �o�׌��R�[�h
        gv_prod_class_code_m       := gr_deliv_data_tbl(in_shori_cnt).prod_class_code;
                                                                               -- ���i�敪
        gv_weight_capacity_class_m := gr_deliv_data_tbl(in_shori_cnt).weight_capacity_class;
                                                                               -- �d�ʗe�ϋ敪
        gv_product_flg_m           := gr_deliv_data_tbl(in_shori_cnt).product_flg;
                                                                               -- ���i���ʋ敪
      ELSE
        gv_stock_rep_origin_m      := gr_move_data_tbl(in_shori_cnt).stock_rep_origin;
                                                                               -- �݌ɕ�[��
        gv_stock_rep_rule_m        := gr_move_data_tbl(in_shori_cnt).stock_rep_rule;
                                                                               -- �݌ɕ�[���[��
        gv_deliver_from_m          := gr_move_data_tbl(in_shori_cnt).shipped_locat_code;
                                                                               -- �o�׌��R�[�h
        gv_prod_class_code_m       := gr_move_data_tbl(in_shori_cnt).prod_class_code;
                                                                               -- ���i�敪
        gv_weight_capacity_class_m := gr_move_data_tbl(in_shori_cnt).weight_capacity_class;
                                                                               -- �d�ʗe�ϋ敪
        gv_product_flg_m           := gr_move_data_tbl(in_shori_cnt).product_flg;
                                                                               -- ���i���ʋ敪
      END IF;
--
    END IF; -- �w�b�_�f�[�^�Z�b�g�I��(���v�l����)
--
-- #############################################################################################
-- ���׃f�[�^�Z�b�g
-- #############################################################################################
--
    -- ���ׂ��쐬���邩�𔻒f����(�i�ڃR�[�h���قȂ�ꍇ)
    -- ������ʂ��u�o�ׁv
    IF (iv_action_type = gv_cons_t_deliv) THEN
--
      IF ((gv_item_code_ml IS NULL)
           OR (lv_header_create_flg = gv_cons_flg_y)
           OR (gv_item_code_ml <> gr_deliv_data_tbl(in_shori_cnt).shipping_item_code)) THEN
--
        -- �w�����ʖ��׍��v�ϐ��𖾍גP�ʂŏ�����
        gn_sum_inst_line_quantity  := 0;
        -- ���׍쐬�t���O 'Y'
        lv_line_create_flg := gv_cons_flg_y;
        -- ���הԍ��C���N�������g
        gn_line_number := gn_line_number + 1;
--
      ELSE
        -- ���׍쐬�t���O 'N'
        lv_line_create_flg := gv_cons_flg_n;
--
      END IF;
--
    -- ������ʂ��u�ړ��v
    ELSE
      IF ((gv_item_code_ml IS NULL)
           OR (lv_header_create_flg = gv_cons_flg_y)
           OR (gv_item_code_ml <> gr_move_data_tbl(in_shori_cnt).item_code)) THEN
--
        -- �w�����ʖ��׍��v�ϐ��𖾍גP�ʂŏ�����
        gn_sum_inst_line_quantity  := 0;
        -- ���׍쐬�t���O 'Y'
        lv_line_create_flg := gv_cons_flg_y;
        -- ���הԍ��C���N�������g
        gn_line_number := gn_line_number + 1;
--
      ELSE
        -- ���׍쐬�t���O 'N'
        lv_line_create_flg := gv_cons_flg_n;
--
      END IF;
--
    END IF;
--
    -- �p�����[�^�̏�����ʂŒl�̎擾��(�o��/�ړ�)��؂蕪����
    IF (iv_action_type = gv_cons_t_deliv) THEN      -- �o��
      lv_item_code := gr_deliv_data_tbl(in_shori_cnt).shipping_item_code;  -- �i�ڃR�[�h
      ln_item_id := gr_deliv_data_tbl(in_shori_cnt).item_id;               -- OPM�i��ID
      lv_item_um := gr_deliv_data_tbl(in_shori_cnt).item_um;               -- �P��
      ln_num_of_deliver := gr_deliv_data_tbl(in_shori_cnt).num_of_deliver; -- �o�ד���
      lv_conv_unit := gr_deliv_data_tbl(in_shori_cnt).conv_unit;           -- ���o�Ɋ��Z�P��
      ln_num_of_cases := gr_deliv_data_tbl(in_shori_cnt).num_of_cases;     -- �P�[�X����
--
      -- �w�����ʎZ�o�̂��ߏo�׈˗����ʂ̑�������(�w�b�_)
      gn_sum_inst_quantity := gn_sum_inst_quantity  + gr_deliv_data_tbl(in_shori_cnt).quantity;
      -- �w�����ʎZ�o�̂��ߏo�׈˗����ʂ̑�������(����)
      gn_sum_inst_line_quantity  :=
                         gn_sum_inst_line_quantity  + gr_deliv_data_tbl(in_shori_cnt).quantity;
--
    ELSE                                            -- �ړ�
      lv_item_code := gr_move_data_tbl(in_shori_cnt).item_code;            -- �i�ڃR�[�h
      ln_item_id := gr_move_data_tbl(in_shori_cnt).item_id;                -- OPM�i��ID
      lv_item_um := gr_move_data_tbl(in_shori_cnt).item_um;                -- �P��
      ln_num_of_deliver := gr_move_data_tbl(in_shori_cnt).num_of_deliver;  -- �o�ד���
      lv_conv_unit := gr_move_data_tbl(in_shori_cnt).conv_unit;            -- ���o�Ɋ��Z�P��
      ln_num_of_cases := gr_move_data_tbl(in_shori_cnt).num_of_cases;      -- �P�[�X����
--
      -- �w�����ʎZ�o�̂��߈ړ��w�����ʂ̑�������(�w�b�_)
      gn_sum_inst_quantity := gn_sum_inst_quantity + gr_move_data_tbl(in_shori_cnt).instruct_qty;
      -- �w�����ʎZ�o�̂��߈ړ��w�����ʂ̑�������(����)
      gn_sum_inst_line_quantity :=
                         gn_sum_inst_line_quantity + gr_move_data_tbl(in_shori_cnt).instruct_qty;
--
    END IF;
--
    -- ���׃f�[�^�쐬�v�Ȃ�Ζ��ׂ��쐬
    IF (lv_line_create_flg = gv_cons_flg_y) THEN
--
      -- **************************************************
      -- �ړ��˗�/�w�����דo�^�p�ϐ��Ƀf�[�^���Z�b�g����
      -- **************************************************
--
      -- �z��ԍ����{�P����
      gn_ins_data_cnt_ml := gn_ins_data_cnt_ml + 1;
--
debug_log(FND_FILE.LOG,'  �ړ����׍쐬......................');
debug_log(FND_FILE.LOG,'    gn_ins_data_cnt_ml = ' || gn_ins_data_cnt_ml);
debug_log(FND_FILE.LOG,'    ���הԍ� = ' || TO_CHAR(gn_line_number));
debug_log(FND_FILE.LOG,'    �i�ڃR�[�h = ' || lv_item_code);
debug_log(FND_FILE.LOG,'    �P�� = ' || lv_item_um);
debug_log(FND_FILE.LOG,'    �o�ד��� = ' || TO_CHAR(ln_num_of_deliver));
debug_log(FND_FILE.LOG,'    ���o�Ɋ��Z�P�� = ' || lv_conv_unit);
debug_log(FND_FILE.LOG,'    �P�[�X���� = ' || TO_CHAR(ln_num_of_cases));
debug_log(FND_FILE.LOG,'    ���א��ʍ��v(���Z�o��) = ' || TO_CHAR(gn_sum_inst_line_quantity));
debug_log(FND_FILE.LOG,'    �w�b�_���ʍ��v(���Z�o��) = ' || TO_CHAR(gn_sum_inst_quantity));
--
      BEGIN
        -- �V�[�P���X���ړ�����ID�����߂�
        SELECT xxinv_mov_line_s1.NEXTVAL
        INTO   lv_mov_line_id
        FROM   DUAL;
--
      EXCEPTION
        WHEN OTHERS THEN
          ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
          ov_retcode := gv_status_error;
          RAISE global_api_expt;
      END;
--
      -- ##########################################################################
      -- �ϐ��Ɋi�[���� ###########################################################
      -- ##########################################################################
      -- �ړ�����ID
      gr_move_lines_tbl(gn_ins_data_cnt_ml).mov_line_id := lv_mov_line_id;
      -- �ړ��w�b�_ID
      gr_move_lines_tbl(gn_ins_data_cnt_ml).mov_hdr_id := gn_mov_hdr_id;
      -- ���הԍ�
      gr_move_lines_tbl(gn_ins_data_cnt_ml).line_number := gn_line_number;
      -- �g�DID
      gr_move_lines_tbl(gn_ins_data_cnt_ml).organization_id := gn_organization_id;
      -- OPM�i��ID
      gr_move_lines_tbl(gn_ins_data_cnt_ml).item_id := ln_item_id;
      -- �i�ڃR�[�h
      gr_move_lines_tbl(gn_ins_data_cnt_ml).item_code := lv_item_code;
      -- �w������
      gr_move_lines_tbl(gn_ins_data_cnt_ml).instruct_qty := gn_sum_inst_line_quantity;
      -- ����w������
      gr_move_lines_tbl(gn_ins_data_cnt_ml).first_instruct_qty := gn_sum_inst_line_quantity;
      -- �P��
      gr_move_lines_tbl(gn_ins_data_cnt_ml).uom_code := lv_item_um;
      -- �d��
      gr_move_lines_tbl(gn_ins_data_cnt_ml).weight := NULL;
      -- �e��
      gr_move_lines_tbl(gn_ins_data_cnt_ml).capacity := NULL;
      -- ����t���O
      gr_move_lines_tbl(gn_ins_data_cnt_ml).delete_flg := gv_cons_flg_n; -- 'N'���Z�b�g;
      -- �쐬��
      gr_move_lines_tbl(gn_ins_data_cnt_ml).created_by := gn_created_by;
      -- �쐬��
      gr_move_lines_tbl(gn_ins_data_cnt_ml).creation_date := SYSDATE;
      -- �ŏI�X�V��
      gr_move_lines_tbl(gn_ins_data_cnt_ml).last_updated_by := gn_created_by;
      -- �ŏI�X�V��
      gr_move_lines_tbl(gn_ins_data_cnt_ml).last_update_date := SYSDATE;
      -- �ŏI�X�V���O�C��
      gr_move_lines_tbl(gn_ins_data_cnt_ml).last_update_login := gn_login_user;
      -- �v��ID
      gr_move_lines_tbl(gn_ins_data_cnt_ml).request_id := gn_conc_request_id;
      -- �R���J�����g�v���O�����A�v���P�[�V����ID
      gr_move_lines_tbl(gn_ins_data_cnt_ml).program_application_id := gn_prog_appl_id;
      -- �R���J�����g�v���O����ID
      gr_move_lines_tbl(gn_ins_data_cnt_ml).program_id := gn_conc_program_id;
      -- �v���O�����X�V��
      gr_move_lines_tbl(gn_ins_data_cnt_ml).program_update_date := SYSDATE;
--
      -- ���׍쐬�P�ʂ̍��ڕێ�
      gv_item_code_ml := lv_item_code;
--
    ELSE
--
debug_log(FND_FILE.LOG,'  �ړ����׍쐬�s�v..................');
debug_log(FND_FILE.LOG,'    ���א��ʍ��v(���Z�o��) = ' || TO_CHAR(gn_sum_inst_line_quantity));
debug_log(FND_FILE.LOG,'    �w�b�_���ʍ��v(���Z�o��) = ' || TO_CHAR(gn_sum_inst_quantity));
      -- �w������
      gr_move_lines_tbl(gn_ins_data_cnt_ml).instruct_qty := gn_sum_inst_line_quantity;
      -- ����w������
      gr_move_lines_tbl(gn_ins_data_cnt_ml).first_instruct_qty := gn_sum_inst_line_quantity;
--
    END IF; -- ���׃f�[�^�쐬�I��
--
--
-- ############################################################################################
-- �w�b�_�f�[�^�⊮
-- ############################################################################################
--
    -- �w�b�_���v�w�����ʂ̍X�V
    gr_move_header_tbl(gn_ins_data_cnt_mh).sum_quantity := gn_sum_inst_quantity; -- ���v�w������
--
    -- �������A���x�������̎Z�o
    -- �o�ד����ɒl���Z�b�g����Ă�����
    IF (ln_num_of_deliver > 0) THEN
      gn_sum_quantity := gn_sum_inst_quantity / ln_num_of_deliver;  -- ���v���� / �o�ד���
--
    -- ���o�Ɋ��Z�P�ʂɒl���Z�b�g����Ă�����
    ELSE
      IF (lv_conv_unit IS NOT NULL) THEN
        gn_sum_quantity := gn_sum_inst_quantity / NVL(ln_num_of_cases, 1); -- ���v���� / �P�[�X����
      ELSE
        gn_sum_quantity := gn_sum_inst_quantity;
      END IF;
    END IF;
--
    -- �������̍X�V
    gr_move_header_tbl(gn_ins_data_cnt_mh).small_quantity := gn_sum_quantity;
--
    -- ���x�������̍X�V
    gr_move_header_tbl(gn_ins_data_cnt_mh).label_quantity := gn_sum_quantity;
--
--
debug_log(FND_FILE.LOG,'    ������(�v�Z�o��) = ' || gn_sum_quantity);
debug_log(FND_FILE.LOG,'(C-10)' || cv_prg_name || ' End�����');
--
--
  EXCEPTION
    -- *** ���ʊ֐��G���[�n���h�� (�x����Ԃ�)***
    WHEN common_warn_expt THEN
--
debug_log(FND_FILE.LOG,'(C-10)' || cv_prg_name || ' End with Warnning�����');
--
      IF ( lc_il_id_cur%ISOPEN ) THEN
        CLOSE lc_il_id_cur;
      END IF;
      IF ( lc_carrier_id_cur%ISOPEN ) THEN
        CLOSE lc_carrier_id_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
--
      IF ( lc_il_id_cur%ISOPEN ) THEN
        CLOSE lc_il_id_cur;
      END IF;
      IF ( lc_carrier_id_cur%ISOPEN ) THEN
        CLOSE lc_carrier_id_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
--
      IF ( lc_il_id_cur%ISOPEN ) THEN
        CLOSE lc_il_id_cur;
      END IF;
      IF ( lc_carrier_id_cur%ISOPEN ) THEN
        CLOSE lc_carrier_id_cur;
      END IF;
--
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--
      IF ( lc_il_id_cur%ISOPEN ) THEN
        CLOSE lc_il_id_cur;
      END IF;
      IF ( lc_carrier_id_cur%ISOPEN ) THEN
        CLOSE lc_carrier_id_cur;
      END IF;
--
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END regi_move_data;
--
   /**********************************************************************************
   * Procedure Name   : regi_poreq_data
   * Description      : C-11 �����˗��o�^
   ***********************************************************************************/
  PROCEDURE regi_poreq_data(
    in_shori_cnt             IN         NUMBER,     -- �����J�E���^
    iv_action_type           IN         VARCHAR2,   -- �������
    iv_shipped_date          IN         VARCHAR2,   -- �o�ɓ��w��
    iv_arrival_date          IN         VARCHAR2,   -- �����w��
    iv_instruction_post_code IN         VARCHAR2,   -- �w�������w��
    ov_errbuf                OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'regi_poreq_data'; -- �v���O������
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
    ln_ret_code                 NUMBER;  -- ���ʊ֐��̃��^�[���l
    ln_po_line_id               xxpo_requisition_lines.requisition_line_id%TYPE;         --��������ID
    lv_seq_no                   VARCHAR2(12);                                       --�̔Ԋ֐��ł�OUT
    ln_vendor_id                xxcmn_vendors2_v.vendor_id%TYPE;                           --�d����ID
    lv_vendor_no                xxcmn_vendors2_v.segment1%TYPE;                          --�d����ԍ�
    ln_vendor_site_id           xxcmn_vendor_sites2_v.vendor_site_id%TYPE;           --�d����T�C�gID
    lv_employee_number          per_all_people_f.employee_number%TYPE;                   --�]�ƈ��ԍ�
    lv_emp_dept_code            xxcmn_locations2_v.location_code%TYPE;                 --���Ə��R�[�h
    ln_odr_line_seq_no          xxpo_requisition_lines.requisition_line_number%TYPE;      -- ���הԍ�
    lv_stock_rep_origin         xxwsh_shipping_stock_rep_tmp.stock_rep_origin%TYPE;  --�d����(��[��)
    lv_location_code            xxpo_requisition_headers.location_code%TYPE;         --���ɐ�(�o�Ɍ�)
    ln_inventory_location_id    xxpo_requisition_headers.location_id%TYPE;       --���ɐ�ID(�o�Ɍ�ID)
    lv_department       xxpo_requisition_headers.requested_to_department_code%TYPE;  --�d����Ǘ�����
    lv_drop_ship_type           xxpo_requisition_headers.drop_ship_type%TYPE;              --�����敪
    lv_delivery_code            xxpo_requisition_headers.delivery_code%TYPE;                 --�z����
    lv_item_code                xxpo_requisition_lines.item_code%TYPE;                  -- �i�ڃR�[�h
    ln_item_id                  xxpo_requisition_lines.item_id%TYPE;                     -- OPM�i��ID
    lv_requested_quantity_uom   xxpo_requisition_lines.requested_quantity_uom%TYPE;   -- �˗����ʒP��
    ln_pack_quantity            xxpo_requisition_lines.pack_quantity%TYPE;                -- �݌ɓ���
--
    lv_header_create_flg        VARCHAR2(1);                                   -- �w�b�_�쐬�t���O
    lv_line_create_flg          VARCHAR2(1);                                   -- ���׍쐬�t���O
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR lc_vendor_cur  -- �d����ID,�d����T�C�gID,�d����ԍ�,��������������
    IS
      SELECT xvv.vendor_id,                      -- �d����ID(No.4�Ŏg�p)
             xvsv.vendor_site_id,                -- �d����T�C�gID(No.6�Ŏg�p)
             xvv.segment1,                       -- �d����ԍ�(No.5�Ŏg�p)
             xvv.department                      -- ����(No.14�Ŏg�p)
      FROM   xxcmn_vendor_sites2_v  xvsv,        -- �d����T�C�g���View2
             xxcmn_vendors2_v       xvv          -- �d������View2
      WHERE  xvsv.vendor_site_code   = lv_stock_rep_origin -- �݌ɕ�[��=�d����T�C�g��
        AND  xvsv.vendor_id          = xvv.vendor_id         -- �d����ID
        AND  xvsv.start_date_active <= TO_DATE(iv_arrival_date,'YYYY/MM/DD') -- �����w��
        AND  ((xvsv.end_date_active >= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))-- �Ŕ͈͓��ł��邱��
              OR
              (xvsv.end_date_active IS NULL))
        AND  xvv.start_date_active  <= TO_DATE(iv_arrival_date,'YYYY/MM/DD') -- �����w��
        AND  ((xvv.end_date_active  >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')) -- �Ŕ͈͓��ł��邱��
             OR
              (xvv.end_date_active  IS NULL))
        AND  ROWNUM        = 1;
--
    CURSOR lc_il_id_cur  -- �ۊǒIID����������
    IS
      SELECT xilv.inventory_location_id            -- �ۊǒIID(No.8�Ŏg�p)
      FROM   xxcmn_item_locations2_v  xilv         -- OPM�ۊǏꏊ���View2
      WHERE  xilv.segment1   = lv_location_code    -- ���ɐ�(�o�Ɍ�)
        AND  xilv.date_from <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')     -- �����w��
        AND  ((xilv.date_to   >= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))  --
               OR                                                        --
              (xilv.date_to   IS NULL))                                  -- �Ŕ͈͓��ł��邱��
        AND  ROWNUM          = 1;
--
    CURSOR lc_user_cur  -- �]�ƈ��ԍ��Ǝ��Ə��R�[�h����������
    IS
      SELECT papf.employee_number,  -- �]�ƈ��ԍ�(No.12�Ŏg�p)
             xlv.location_code      -- ���Ə��R�[�h(No.13�Ŏg�p)
      FROM   fnd_user               fu,     -- ���[�U�}�X�^
             per_all_people_f       papf,   -- �]�ƈ��}�X�^
             per_all_assignments_f  paaf,   -- �]�ƈ��A�T�C�����g�}�X�^
             xxcmn_locations2_v     xlv     -- ���Ə����VIEW2
      WHERE  fu.user_id           =  gn_created_by
        AND  fu.employee_id       =  papf.person_id
        AND  papf.person_id       =  paaf.person_id
        AND  paaf.location_id     =  xlv.location_id
        AND  xlv.location_id      <> xlv.parent_location_id
        AND  xlv.parent_location_id IS NOT NULL
        AND  ((papf.effective_start_date <= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))
               OR
              (papf.effective_start_date IS NULL))
        AND  ((papf.effective_end_date >= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))
               OR
              (papf.effective_end_date IS NULL))
        AND  ((paaf.effective_start_date <= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))
               OR
              (paaf.effective_start_date IS NULL))
        AND  ((paaf.effective_end_date >= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))
               OR
              (paaf.effective_end_date IS NULL))
        AND  ((xlv.start_date_active <= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))
               OR
              (xlv.start_date_active IS NULL))
        AND  ((xlv.end_date_active >= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))
               OR
              (xlv.end_date_active IS NULL))
        AND  ROWNUM           = 1;
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
--
debug_log(FND_FILE.LOG,'(C-11)' || cv_prg_name || ' Start���');
--
-- ############################################################################################
-- �w�b�_�f�[�^�Z�b�g
-- ############################################################################################
--
    -- �w�b�_���쐬���邩�𔻒f����(�݌ɕ�[���A�o�׌��R�[�h�̂��Âꂩ���قȂ�ꍇ)
    -- ������ʂ��o�ׂŁA�o�׌��̒����q�ɋ敪=�����̏ꍇ�ɂ́A�z���悪�قȂ�ꍇ���Ώ�
    -- ������ʂ��u�o�ׁv�� �����̏ꍇ
    IF ((iv_action_type = gv_cons_t_deliv)
         AND
        (gr_deliv_data_tbl(in_shori_cnt).drop_ship_wsh_div = gv_cons_ds_type_d)) THEN
--
      -- �w�b�_���쐬����
      IF ((gv_stock_rep_origin_p IS NULL)                 -- 1���ڂ̃w�b�_�쐬��
         OR                                              -- �ȉ��̂ǂꂩ�̍��ڂ��قȂ�
         ((gv_stock_rep_origin_p      <> gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin)
          OR
          (gv_stock_rep_rule_p        <> gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule)
          OR
          (gv_deliver_from_p          <> gr_deliv_data_tbl(in_shori_cnt).deliver_from)
          OR
          (gv_deliver_to_p            <> gr_deliv_data_tbl(in_shori_cnt).deliver_to)))
      THEN
--
        lv_header_create_flg := gv_cons_flg_y;
--
debug_log(FND_FILE.LOG,'  �����˗��w�b�_�쐬(�o�� ����)......................');
debug_log(FND_FILE.LOG,'    �݌ɕ�[�� = ' || gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin);
debug_log(FND_FILE.LOG,'    �݌ɕ�[���[�� = ' || gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule);
debug_log(FND_FILE.LOG,'    �o�׌�(��[��) = ' || gr_deliv_data_tbl(in_shori_cnt).deliver_from);
debug_log(FND_FILE.LOG,'    �����q�ɋ敪 = ' || gr_deliv_data_tbl(in_shori_cnt).drop_ship_wsh_div);
debug_log(FND_FILE.LOG,'    �o�א� = ' || gr_deliv_data_tbl(in_shori_cnt).deliver_to);
--
      -- �w�b�_���쐬���Ȃ�
      ELSE
--
        lv_header_create_flg := gv_cons_flg_n;
--
debug_log(FND_FILE.LOG,'  �����˗��w�b�_�쐬�s�v(�o�� ����)..................');
--
      END IF;
--
    -- ������ʂ��u�o�ׁv�� �ʏ�̏ꍇ
    ELSIF ((iv_action_type = gv_cons_t_deliv)
         AND
        (gr_deliv_data_tbl(in_shori_cnt).drop_ship_wsh_div <> gv_cons_ds_type_d)) THEN
--
      -- �w�b�_���쐬����
      IF ((gv_stock_rep_origin_p IS NULL)                 -- 1���ڂ̃w�b�_�쐬��
          OR                                              -- �ȉ��̂ǂꂩ�̍��ڂ��قȂ�
         ((gv_stock_rep_origin_p      <> gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin)
          OR
          (gv_stock_rep_rule_p        <> gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule)
          OR
          (gv_deliver_from_p          <> gr_deliv_data_tbl(in_shori_cnt).deliver_from)))
      THEN
--
        lv_header_create_flg := gv_cons_flg_y;
--
debug_log(FND_FILE.LOG,'  �����˗��w�b�_�쐬(�o�� �ʏ�)......................');
debug_log(FND_FILE.LOG,'    �݌ɕ�[�� = ' || gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin);
debug_log(FND_FILE.LOG,'    �݌ɕ�[���[�� = ' || gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule);
debug_log(FND_FILE.LOG,'    �o�׌�(��[��) = ' || gr_deliv_data_tbl(in_shori_cnt).deliver_from);
debug_log(FND_FILE.LOG,'    �����q�ɋ敪 = ' || gr_deliv_data_tbl(in_shori_cnt).drop_ship_wsh_div);
debug_log(FND_FILE.LOG,'    �o�א� = ' || gr_deliv_data_tbl(in_shori_cnt).deliver_to);
--
      -- �w�b�_���쐬���Ȃ�
      ELSE
--
        lv_header_create_flg := gv_cons_flg_n;
--
debug_log(FND_FILE.LOG,'  �����˗��w�b�_�쐬�s�v(�o�� �ʏ�)..................');
--
      END IF;
--
    -- ������ʂ��u�ړ��v�̏ꍇ
    ELSE
      -- �w�b�_���쐬����
      IF ((gv_stock_rep_origin_p IS NULL)                -- 1���ڂ̃w�b�_�쐬��
         OR                                              -- �ȉ��̂ǂꂩ�̍��ڂ��قȂ�
         ((gv_stock_rep_origin_p      <> gr_move_data_tbl(in_shori_cnt).stock_rep_origin)
           OR
          (gv_stock_rep_rule_p        <> gr_move_data_tbl(in_shori_cnt).stock_rep_rule)
           OR
          (gv_deliver_from_p          <> gr_move_data_tbl(in_shori_cnt).shipped_locat_code)))
      THEN
--
        lv_header_create_flg := gv_cons_flg_y;
--
debug_log(FND_FILE.LOG,'  �����˗��w�b�_�쐬(�ړ�)......................');
debug_log(FND_FILE.LOG,'    �݌ɕ�[�� = ' || gr_move_data_tbl(in_shori_cnt).stock_rep_origin);
debug_log(FND_FILE.LOG,'    �݌ɕ�[���[�� = ' || gr_move_data_tbl(in_shori_cnt).stock_rep_rule);
debug_log(FND_FILE.LOG,'    �o�׌�(��[��) = ' || gr_move_data_tbl(in_shori_cnt).shipped_locat_code);
--
      -- �w�b�_���쐬���Ȃ�
      ELSE
        lv_header_create_flg := gv_cons_flg_n;
--
debug_log(FND_FILE.LOG,'  �����˗��w�b�_�쐬�s�v(�ړ�)..................');
--
      END IF;
--
    END IF;
--
    -- �w�b�_�쐬�v�̏ꍇ
    IF (lv_header_create_flg = gv_cons_flg_y) THEN
      -- **************************************************
      -- �����˗��w�b�_�o�^�p�ϐ��Ƀf�[�^���Z�b�g����
      -- **************************************************
--
      -- ���הԍ�������
      gn_line_number      := 0;
--
--
      BEGIN
        -- �V�[�P���X��蔭���˗��w�b�_ID�����߂�
        SELECT xxpo_requisition_headers_s1.NEXTVAL
        INTO   gn_poreq_hdr_id
        FROM   DUAL;
--
      EXCEPTION
        WHEN OTHERS THEN
          ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
          ov_retcode := gv_status_error;
          RAISE global_api_expt;
      END;
--
      -- �̔Ԋ֐�
      xxcmn_common_pkg.get_seq_no( gv_cons_seq_order,
                                   lv_seq_no,
                                   lv_errbuf,
                                   lv_retcode,
                                   lv_errmsg);
--
debug_log(FND_FILE.LOG,'    �����˗��ԍ� = ' || lv_seq_no);
--
      -- �G���[�̏ꍇ  �����������͌p�����A�x���I���ƂȂ� #######################3
      IF (lv_retcode <> gv_status_normal) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                      ,gv_msg_wsh_13008     -- �̔Ԋ֐��G���[
                                                      ,gv_tkn_table_name    -- �g�[�N��'TABLE_NAME'
                                                      ,gv_cons_odr_hdr_tbl  -- �����˗��w�b�_
                                                      ,gv_tkn_param1        -- �g�[�N��'PARAM1'
                                                      ,gv_cons_seq_move     -- �̔ԋ敪�u�ړ��v
                                                      ,gv_tkn_param2        -- �g�[�N��'PARAM2'
                                                      ,lv_retcode           -- ���^�[���R�[�h
                                                      ,gv_tkn_param3        -- �g�[�N��'PARAM3'
                                                      ,lv_errmsg)           -- ���b�Z�[�W
                                                      ,1
                                                      ,5000);
--
        gn_warn_cnt := gn_warn_cnt + 1;
        RAISE common_warn_expt;
--
      END IF;
--
      -- �p�����[�^�̏�����ʂŒl�̎擾��(�o��/�ړ�)��؂蕪����
      IF (iv_action_type = gv_cons_t_deliv) THEN -- �o�ׂ̏ꍇ
--
        lv_stock_rep_origin := gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin; -- �d����(��[��)
        lv_location_code    := gr_deliv_data_tbl(in_shori_cnt).deliver_from;     -- �o�׌�(��[��)
--
        -- �����敪���u�����v��������u�o�ׁv���Z�b�g
        IF (gr_deliv_data_tbl(in_shori_cnt).drop_ship_wsh_div = gv_cons_ds_type_d) THEN
          lv_drop_ship_type := gv_cons_ds_deliv;                                  -- �����敪(�o��)
          lv_delivery_code  := gr_deliv_data_tbl(in_shori_cnt).deliver_to;        -- �����z����
--
        -- �����敪���u�����ȊO�v��NULL�Ȃ�΁u�ʏ�v���Z�b�g
        ELSE
          lv_drop_ship_type := gv_cons_ds_normal;                                 -- �����敪(�ʏ�)
          lv_delivery_code  := '';                                                -- �����z����
--
        END IF;
--
      ELSE  -- �ړ��̏ꍇ
--
        lv_stock_rep_origin := gr_move_data_tbl(in_shori_cnt).stock_rep_origin;   -- �d����(��[��)
        lv_location_code    := gr_move_data_tbl(in_shori_cnt).shipped_locat_code; -- �o�Ɍ�(��[��)
        lv_drop_ship_type   := gv_cons_ds_normal;                                 -- �����敪(�ʏ�)
        lv_delivery_code    := '';                                                -- �����z����
--
      END IF;
--
      -- �d����ID, �d����T�C�gID, �d����ԍ�, ��������������
      OPEN  lc_vendor_cur;
      FETCH lc_vendor_cur INTO ln_vendor_id, ln_vendor_site_id, lv_vendor_no, lv_department;
      CLOSE lc_vendor_cur;
--
debug_log(FND_FILE.LOG,'    �d����ID =' || TO_CHAR(ln_vendor_id));
debug_log(FND_FILE.LOG,'    �d����ԍ� =' || lv_vendor_no);
debug_log(FND_FILE.LOG,'    �d����T�C�gID =' || TO_CHAR(ln_vendor_site_id));
debug_log(FND_FILE.LOG,'    �d����Ǘ����� =' || lv_department);
--
      -- �ۊǒIID������
      OPEN  lc_il_id_cur;
      FETCH lc_il_id_cur INTO ln_inventory_location_id;
      CLOSE lc_il_id_cur;
--
debug_log(FND_FILE.LOG,'  �[����ID(��[��) =' || TO_CHAR(ln_inventory_location_id));
--
      -- �]�ƈ��ԍ��Ǝ��Ə��R�[�h������
      OPEN  lc_user_cur;
      FETCH lc_user_cur INTO lv_employee_number, lv_emp_dept_code;
      CLOSE lc_user_cur;
--
debug_log(FND_FILE.LOG,'    �˗��҃R�[�h =' || lv_employee_number);
debug_log(FND_FILE.LOG,'    �˗��ҕ����R�[�h =' || lv_emp_dept_code);
--
      -- ##########################################################################
      -- �ϐ��Ɋi�[���� ###########################################################
      -- ##########################################################################
      -- �z��ԍ����{�P����
      gn_ins_data_cnt_ph := gn_ins_data_cnt_ph + 1;
      -- �����˗��w�b�_ID
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).requisition_header_id := gn_poreq_hdr_id;
      -- �����ԍ�
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).po_header_number := lv_seq_no;
      -- �X�e�[�^�X
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).status := gv_cons_po_sts; --�˗��쐬��'10'
      -- �d����ID
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).vendor_id := ln_vendor_id;
      -- �d����R�[�h
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).vendor_code := lv_vendor_no;
      -- �d����T�C�gID
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).vendor_site_id := ln_vendor_site_id;
      -- �[����
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).promised_date :=
                                            TO_DATE(iv_arrival_date,'YYYY/MM/DD'); -- �����w��
      -- �[����ID
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).location_id := ln_inventory_location_id;
      -- �[����R�[�h
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).location_code := lv_location_code;
      --�����敪
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).drop_ship_type := lv_drop_ship_type;
      --�z����
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).delivery_code := lv_delivery_code;
      -- �˗��҃R�[�h
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).requested_by_code := lv_employee_number;
      -- �˗��ҕ����R�[�h
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).requested_dept_code := lv_emp_dept_code;
      -- �˗��敔���R�[�h
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).requested_to_department_code := lv_department;
      -- �ύX�t���O
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).change_flag := gv_change_flag_n;
      -- �쐬��
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).created_by := gn_created_by;
      -- �쐬��
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).creation_date := SYSDATE;
      -- �ŏI�X�V��
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).last_updated_by := gn_created_by;
      -- �ŏI�X�V��
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).last_update_date := SYSDATE;
      -- �ŏI�X�V���O�C��
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).last_update_login := gn_login_user;
      -- �v��ID
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).request_id := gn_conc_request_id;
      -- �A�v���P�[�V����ID
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).program_application_id := gn_prog_appl_id;
      -- �v���O����ID
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).program_id := gn_conc_program_id;
      -- �v���O�����X�V��
      gr_requisition_header_tbl(gn_ins_data_cnt_ph).program_update_date := SYSDATE;
--
      -- �w�b�_�쐬�P�ʂ̍��ڕێ�
      -- ������ʂ��u�o�ׁv
      IF (iv_action_type = gv_cons_t_deliv) THEN
        gv_stock_rep_origin_p      := gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin;
                                                                                 -- �݌ɕ�[��
        gv_deliver_from_p          := gr_deliv_data_tbl(in_shori_cnt).deliver_from;
                                                                                 -- �o�׌��R�[�h
        gv_deliver_to_p            := gr_deliv_data_tbl(in_shori_cnt).deliver_to;
                                                                                 -- �o�א�R�[�h
        gv_stock_rep_rule_p        := gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule;
                                                                                 -- �݌ɕ�[���[��
      ELSE
        gv_stock_rep_origin_p      := gr_move_data_tbl(in_shori_cnt).stock_rep_origin;
                                                                                 -- �݌ɕ�[��
        gv_deliver_from_p          := gr_move_data_tbl(in_shori_cnt).shipped_locat_code;
                                                                                 -- �o�׌��R�[�h
        gv_stock_rep_rule_p        := gr_move_data_tbl(in_shori_cnt).stock_rep_rule;
                                                                                 -- �݌ɕ�[���[��
      END IF;
--
    END IF;  -- �w�b�_�f�[�^�Z�b�g�I��
--
-- #############################################################################################
-- ���׃f�[�^�Z�b�g
-- #############################################################################################
--
    -- ���ׂ��쐬���邩�𔻒f����(�i�ڃR�[�h���قȂ�ꍇ)
    -- ������ʂ��u�o�ׁv
    IF (iv_action_type = gv_cons_t_deliv) THEN
--
      IF ((gv_item_code_pl IS NULL)
           OR (lv_header_create_flg = gv_cons_flg_y)
           OR (gv_item_code_pl <> gr_deliv_data_tbl(in_shori_cnt).shipping_item_code)) THEN
--
        -- �˗����ʖ��׍��v�ϐ��𖾍גP�ʂŏ�����
        gn_sum_req_line_quantity  := 0;
        -- ���׍쐬�t���O 'Y'
        lv_line_create_flg := gv_cons_flg_y;
        -- ���הԍ��C���N�������g
        gn_line_number := gn_line_number + 1;
--
      ELSE
--
        -- ���׍쐬�t���O 'N'
        lv_line_create_flg := gv_cons_flg_n;
--
      END IF;
--
    -- ������ʂ��u�ړ��v
    ELSE
      IF ((gv_item_code_pl IS NULL)
           OR (lv_header_create_flg = gv_cons_flg_y)
           OR (gv_item_code_pl <> gr_move_data_tbl(in_shori_cnt).item_code)) THEN
--
        -- �˗����ʖ��׍��v�ϐ��𖾍גP�ʂŏ�����
        gn_sum_req_line_quantity  := 0;
        -- ���׍쐬�t���O 'Y'
        lv_line_create_flg := gv_cons_flg_y;
        -- ���הԍ��C���N�������g
        gn_line_number := gn_line_number + 1;
--
      ELSE
        -- ���׍쐬�t���O 'N'
        lv_line_create_flg := gv_cons_flg_n;
--
      END IF;
--
    END IF;
--
    -- �p�����[�^�̏�����ʂŒl�̎擾��(�o��/�ړ�)��؂蕪����
    IF (iv_action_type = gv_cons_t_deliv) THEN      -- �o��
      lv_item_code := gr_deliv_data_tbl(in_shori_cnt).shipping_item_code;   -- �i�ڃR�[�h
      ln_item_id := gr_deliv_data_tbl(in_shori_cnt).item_id;                -- OPM�i��ID
      lv_requested_quantity_uom := gr_deliv_data_tbl(in_shori_cnt).item_um; -- �P��
      ln_pack_quantity := gr_deliv_data_tbl(in_shori_cnt).frequent_qty;  -- ��\����
--
      -- �˗����ʎZ�o�̂��߂̏o�׈˗����ʂ̑�������(����)
      gn_sum_req_line_quantity :=
              gn_sum_req_line_quantity  + gr_deliv_data_tbl(in_shori_cnt).quantity;
--
    ELSE                                            -- �ړ�
      lv_item_code := gr_move_data_tbl(in_shori_cnt).item_code;            -- �i�ڃR�[�h
      ln_item_id := gr_move_data_tbl(in_shori_cnt).item_id;                -- OPM�i��ID
      lv_requested_quantity_uom := gr_move_data_tbl(in_shori_cnt).item_um; -- �P��
      ln_pack_quantity := gr_move_data_tbl(in_shori_cnt).frequent_qty;  -- ��\����
--
      -- �˗����ʎZ�o�̂��߂̈ړ��w�����ʂ̑�������(����)
      gn_sum_req_line_quantity :=
              gn_sum_req_line_quantity + gr_move_data_tbl(in_shori_cnt).instruct_qty;
--
    END IF;
--
    -- ���׃f�[�^�쐬�v�Ȃ�Ζ��ׂ��쐬
    IF (lv_line_create_flg = gv_cons_flg_y) THEN
--
      -- **************************************************
      -- �����˗����דo�^�p�ϐ��Ƀf�[�^���Z�b�g����
      -- **************************************************
--
      -- �z��ԍ����{�P����
      gn_ins_data_cnt_pl := gn_ins_data_cnt_pl + 1;
--
debug_log(FND_FILE.LOG,'  �����˗����׍쐬......................');
debug_log(FND_FILE.LOG,'    gn_ins_data_cnt_pl = ' || gn_ins_data_cnt_pl);
debug_log(FND_FILE.LOG,'    ���הԍ� = ' || TO_CHAR(gn_line_number));
debug_log(FND_FILE.LOG,'    �i�ڃR�[�h = ' || lv_item_code);
debug_log(FND_FILE.LOG,'    �P�� = ' || lv_requested_quantity_uom);
debug_log(FND_FILE.LOG,'    ���א��ʍ��v(���Z�o��) = ' || TO_CHAR(gn_sum_req_line_quantity));
--
      BEGIN
        -- �V�[�P���X��蔭���˗�����ID�����߂�
        SELECT xxpo_requisition_lines_s1.NEXTVAL
        INTO   ln_po_line_id
        FROM   DUAL;
--
      EXCEPTION
        WHEN OTHERS THEN
          ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
          ov_retcode := gv_status_error;
          RAISE global_api_expt;
      END;
--
      -- ##########################################################################
      -- �ϐ��Ɋi�[���� ###########################################################
      -- ##########################################################################
      -- �����˗����דo�^�p�ϐ��Ƀf�[�^���Z�b�g����
      -- �����˗�����ID
      gr_requisition_lines_tbl(gn_ins_data_cnt_pl).requisition_line_id := ln_po_line_id;
      -- �����˗��w�b�_ID
      gr_requisition_lines_tbl(gn_ins_data_cnt_pl).requisition_header_id := gn_poreq_hdr_id;
      -- ���הԍ�
      gr_requisition_lines_tbl(gn_ins_data_cnt_pl).requisition_line_number := gn_line_number;
      -- �i��ID
      gr_requisition_lines_tbl(gn_ins_data_cnt_pl).item_id := ln_item_id;
      -- �i�ڃR�[�h
      gr_requisition_lines_tbl(gn_ins_data_cnt_pl).item_code := lv_item_code;
      -- �݌ɓ���
      gr_requisition_lines_tbl(gn_ins_data_cnt_pl).pack_quantity := ln_pack_quantity;
      -- �˗�����
      gr_requisition_lines_tbl(gn_ins_data_cnt_pl).requested_quantity := gn_sum_req_line_quantity;
      -- �˗����ʒP�ʃR�[�h
      gr_requisition_lines_tbl(gn_ins_data_cnt_pl).requested_quantity_uom
                                                         := lv_requested_quantity_uom;
      -- ����t���O
      gr_requisition_lines_tbl(gn_ins_data_cnt_pl).cancelled_flg := gv_cons_flg_n; -- 'N'���Z�b�g
      -- �쐬��
      gr_requisition_lines_tbl(gn_ins_data_cnt_pl).created_by := gn_created_by;
      -- �쐬��
      gr_requisition_lines_tbl(gn_ins_data_cnt_pl).creation_date := SYSDATE;
      -- �ŏI�X�V��
      gr_requisition_lines_tbl(gn_ins_data_cnt_pl).last_updated_by := gn_created_by;
      -- �ŏI�X�V��
      gr_requisition_lines_tbl(gn_ins_data_cnt_pl).last_update_date := SYSDATE;
      -- �ŏI�X�V���O�C��
      gr_requisition_lines_tbl(gn_ins_data_cnt_pl).last_update_login := gn_login_user;
      -- �v��ID
      gr_requisition_lines_tbl(gn_ins_data_cnt_pl).request_id := gn_conc_request_id;
      -- �A�v���P�[�V����ID
      gr_requisition_lines_tbl(gn_ins_data_cnt_pl).program_application_id := gn_prog_appl_id;
      -- �v���O����ID
      gr_requisition_lines_tbl(gn_ins_data_cnt_pl).program_id := gn_conc_program_id;
      -- �v���O�����X�V��
      gr_requisition_lines_tbl(gn_ins_data_cnt_pl).program_update_date := SYSDATE;
--
      -- ���׍쐬�P�ʂ̍��ڕێ�
      gv_item_code_pl := lv_item_code;
--
    ELSE
--
debug_log(FND_FILE.LOG,'  �����˗����׍쐬�s�v..................');
debug_log(FND_FILE.LOG,'    ���א��ʍ��v(���Z�o��) = ' || TO_CHAR(gn_sum_req_line_quantity));
      -- �˗�����
      gr_requisition_lines_tbl(gn_ins_data_cnt_pl).requested_quantity := gn_sum_req_line_quantity;
--
    END IF;   -- ���׃f�[�^�쐬�I��
--
--
debug_log(FND_FILE.LOG,'(C-11)' || cv_prg_name || ' End�����');
--
--
  EXCEPTION
    -- *** ���ʊ֐��G���[�n���h�� (�x����Ԃ�)***
    WHEN common_warn_expt THEN
--
debug_log(FND_FILE.LOG,'(C-11)' || cv_prg_name || ' End with Warnning�����');
--
      IF ( lc_vendor_cur%ISOPEN ) THEN
        CLOSE lc_vendor_cur;
      END IF;
      IF ( lc_il_id_cur%ISOPEN ) THEN
        CLOSE lc_il_id_cur;
      END IF;
      IF ( lc_user_cur%ISOPEN ) THEN
        CLOSE lc_user_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
--
      IF ( lc_vendor_cur%ISOPEN ) THEN
        CLOSE lc_vendor_cur;
      END IF;
      IF ( lc_il_id_cur%ISOPEN ) THEN
        CLOSE lc_il_id_cur;
      END IF;
      IF ( lc_user_cur%ISOPEN ) THEN
        CLOSE lc_user_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
--
      IF ( lc_vendor_cur%ISOPEN ) THEN
        CLOSE lc_vendor_cur;
      END IF;
      IF ( lc_il_id_cur%ISOPEN ) THEN
        CLOSE lc_il_id_cur;
      END IF;
      IF ( lc_user_cur%ISOPEN ) THEN
        CLOSE lc_user_cur;
      END IF;
--
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--
      IF ( lc_vendor_cur%ISOPEN ) THEN
        CLOSE lc_vendor_cur;
      END IF;
      IF ( lc_il_id_cur%ISOPEN ) THEN
        CLOSE lc_il_id_cur;
      END IF;
      IF ( lc_user_cur%ISOPEN ) THEN
        CLOSE lc_user_cur;
      END IF;
--
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END regi_poreq_data;
--
   /**********************************************************************************
   * Procedure Name   : regi_order_detail
   * Description      : C-12 �󒍖��׍X�V
   ***********************************************************************************/
  PROCEDURE regi_order_detail(
    in_shori_cnt           IN         NUMBER,     -- �����J�E���^
    iv_move_number         IN        VARCHAR2,     -- �ړ��ԍ�
    iv_po_number           IN        VARCHAR2,     -- �����ԍ�
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'regi_order_detail'; -- �v���O������
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
--
debug_log(FND_FILE.LOG,'(C-12)' || cv_prg_name || ' Start���');
--
    -- �󒍖��׍X�V�Ώی������{�P����
    gn_upd_data_cnt_ol := gn_upd_data_cnt_ol + 1;
--
    -- �e���R�[�h�ϐ��Ƀf�[�^���Z�b�g����
    -- �L�[���ڂ��Z�b�g����
    gt_ol_request_no(gn_upd_data_cnt_ol) :=
                       gr_deliv_data_tbl(in_shori_cnt).request_no;          -- �˗�No�i�L�[�j
    gt_ol_shipping_item_code(gn_upd_data_cnt_ol) :=
                       gr_deliv_data_tbl(in_shori_cnt).shipping_item_code;  -- �i�ڃR�[�h�i�L�[�j
--
    gt_ol_move_number(gn_upd_data_cnt_ol)            := iv_move_number;     -- �ړ�No
    gt_ol_po_number(gn_upd_data_cnt_ol)              := iv_po_number;       -- ����No
    gt_ol_last_updated_by(gn_upd_data_cnt_ol)        := gn_created_by;      -- �ŏI�X�V��
    gt_ol_last_update_date(gn_upd_data_cnt_ol)       := SYSDATE;            -- �ŏI�X�V��
    gt_ol_last_update_login(gn_upd_data_cnt_ol)      := gn_login_user;      -- �ŏI�X�V���O�C��
    gt_ol_request_id(gn_upd_data_cnt_ol)             := gn_conc_request_id; -- �v��ID
    gt_ol_program_application_id(gn_upd_data_cnt_ol) := gn_prog_appl_id;    -- �A�v���P�[�V����ID
    gt_ol_program_id(gn_upd_data_cnt_ol)             := gn_conc_program_id; -- �v���O����ID
    gt_ol_program_update_date(gn_upd_data_cnt_ol)    := SYSDATE;            -- �v���O�����X�V��
--
--
debug_log(FND_FILE.LOG,'  �󒍖��׍X�V�ΏۃJ�E���g = ' || TO_CHAR(gn_upd_data_cnt_ol) || '����');
debug_log(FND_FILE.LOG,'  �˗�NO = ' || gt_ol_request_no(gn_upd_data_cnt_ol));
debug_log(FND_FILE.LOG,'  �i�ڃR�[�h = ' || gt_ol_shipping_item_code(gn_upd_data_cnt_ol));
debug_log(FND_FILE.LOG,'  �ړ�No = ' || gt_ol_move_number(gn_upd_data_cnt_ol));
debug_log(FND_FILE.LOG,'  ����No = ' || gt_ol_po_number(gn_upd_data_cnt_ol));
debug_log(FND_FILE.LOG,'(C-12)' || cv_prg_name || ' End�����');
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
  END regi_order_detail;
--
   /**********************************************************************************
   * Procedure Name   : regi_move_detail
   * Description      : C-13 �ړ��w��/�w�����׍X�V
   ***********************************************************************************/
  PROCEDURE regi_move_detail(
    in_shori_cnt           IN         NUMBER,     -- �����J�E���^
    iv_move_number         IN        VARCHAR2,     -- �ړ��ԍ�
    iv_po_number           IN        VARCHAR2,     -- �����ԍ�
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'regi_move_detail'; -- �v���O������
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
--
debug_log(FND_FILE.LOG,'(C-13)' || cv_prg_name || ' Start���');
--
    -- �ړ��˗�/�w�����׍X�V�Ώی������{�P����
    gn_upd_data_cnt_ml := gn_upd_data_cnt_ml + 1;
--
    -- �e���R�[�h�ϐ��Ƀf�[�^���Z�b�g����
    -- �L�[���ڂ��Z�b�g����
    gt_ml_mov_num(gn_upd_data_cnt_ml) :=
                       gr_move_data_tbl(in_shori_cnt).mov_num;  -- �ړ��ԍ��i�L�[�j
    gt_ml_item_code(gn_upd_data_cnt_ml) :=
                       gr_move_data_tbl(in_shori_cnt).item_code;  -- �i�ڃR�[�h�i�L�[�j
--
    gt_ml_move_num(gn_upd_data_cnt_ml)               := iv_move_number;     -- �Q�ƈړ��ԍ�
    gt_ml_po_num(gn_upd_data_cnt_ml)                 := iv_po_number;       -- �Q�Ɣ����ԍ�
    gt_ml_last_updated_by(gn_upd_data_cnt_ml)        := gn_created_by;      -- �ŏI�X�V��
    gt_ml_last_update_date(gn_upd_data_cnt_ml)       := SYSDATE;            -- �ŏI�X�V��
    gt_ml_last_update_login(gn_upd_data_cnt_ml)      := gn_login_user;      -- �ŏI�X�V���O�C��
    gt_ml_request_id(gn_upd_data_cnt_ml)             := gn_conc_request_id; -- �v��ID
    gt_ml_program_application_id(gn_upd_data_cnt_ml) := gn_prog_appl_id;    -- �A�v���P�[�V����ID
    gt_ml_program_id(gn_upd_data_cnt_ml)             := gn_conc_program_id; -- �v���O����ID
    gt_ml_program_update_date(gn_upd_data_cnt_ml)    := SYSDATE;            -- �v���O�����X�V��
--
--
debug_log(FND_FILE.LOG,'  �ړ����׍X�V�ΏۃJ�E���g = ' || TO_CHAR(gn_upd_data_cnt_ml) || '����');
debug_log(FND_FILE.LOG,'  �ړ��ԍ� = ' || gt_ml_mov_num(gn_upd_data_cnt_ml));
debug_log(FND_FILE.LOG,'  �i�ڃR�[�h = ' || gt_ml_item_code(gn_upd_data_cnt_ml));
debug_log(FND_FILE.LOG,'  �Q�ƈړ��ԍ� = ' || gt_ml_move_num(gn_upd_data_cnt_ml));
debug_log(FND_FILE.LOG,'  �Q�Ɣ����ԍ� = ' || gt_ml_po_num(gn_upd_data_cnt_ml));
debug_log(FND_FILE.LOG,'(C-13)' || cv_prg_name || ' End�����');
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
  END regi_move_detail;
--
--
   /**********************************************************************************
   * Procedure Name   : calc_weight_capacity
   * Description      : C-15 �d�ʗe�όv�Z/�ύڌ����Z�o
   ***********************************************************************************/
  PROCEDURE calc_weight_capacity(
    iv_arrival_date       IN         VARCHAR2,     -- �����w��
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_weight_capacity'; -- �v���O������
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
    ln_line_cnt             NUMBER := 0;
    ln_weight               NUMBER := 0;       --���׏d�ʍ��v�W�v�p
    ln_p_weight             NUMBER := 0;       --���׃p���b�g�d�ʏW�v�p
    ln_sum_weight           NUMBER := 0;       --�w�b�_�d�ʏW�v�p
    ln_sum_p_weight         NUMBER := 0;       --�w�b�_�p���b�g�d�ʏW�v�p
    ln_capacity             NUMBER := 0;       --���חe�ϏW�v�p
    ln_sum_capacity         NUMBER := 0;       --�w�b�_�e�ϏW�v�p
    lv_item_code            xxinv_mov_req_instr_lines.item_code%TYPE; --�d�ʍ��v�Z�o�Ώەi��
    ln_instruct_qty         xxinv_mov_req_instr_lines.instruct_qty%TYPE; --�d�ʍ��v�Z�o�Ώې���
    ln_mov_hdr_id           xxinv_mov_req_instr_headers.mov_hdr_id%TYPE;
--
    lv_loading_over_class          VARCHAR2(1); -- �ύڃI�[�o�[�敪
    lv_ship_methods                xxcmn_ship_methods.ship_method%TYPE;        -- �o�ו��@
    ln_load_efficiency_weight      NUMBER;      -- �d�ʐύڌ���
    ln_load_efficiency_capacity    NUMBER;      -- �e�ϐύڌ���
    lv_mixed_ship_method     xxwsh_ship_method2_v.mixed_ship_method_code%TYPE; -- ���ڔz���敪
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
debug_log(FND_FILE.LOG,'(C-15)' || cv_prg_name || ' Start���');
--
-- ############################################################################################
-- �ړ����׏d��/�e�ϕ⊮���[�v
-- ############################################################################################
    <<move_line_weight_capacityloop>>
    FOR ln_line_cnt IN 1..gr_move_lines_tbl.COUNT LOOP
      ln_weight := 0;
      ln_capacity := 0;
      ln_p_weight := 0;
--
      --�e���ׂ̏d�ʗe�ώZ�o�Ώۂ̕i�ڃR�[�h���i�[
      lv_item_code := gr_move_lines_tbl(ln_line_cnt).item_code;
      --�e���ׂ̏d�ʗe�ώZ�o�Ώۂ̐��ʂ��i�[
      ln_instruct_qty := gr_move_lines_tbl(ln_line_cnt).instruct_qty;
--
      -- �ύڌ����`�F�b�N(���v�l�Z�o)
      xxwsh_common910_pkg.calc_total_value(
                                         lv_item_code,        -- 1.�i�ڃR�[�h I
                                         ln_instruct_qty,     -- 2.���� I
                                         lv_retcode,          -- 3.���^�[���R�[�h O
                                         lv_errbuf,           -- 4.�G���[���b�Z�[�W�R�[�h O
                                         lv_errmsg,           -- 5.�G���[���b�Z�[�W O
                                         ln_weight,           -- 6.���v�d�� O
                                         ln_capacity,         -- 7.���v�e�� O
                                         ln_p_weight);        -- 8.���v�p���b�g�d�� O
--
debug_log(FND_FILE.LOG,'  �ړ����� ���v�l�Z�o(�d��/�e��)');
debug_log(FND_FILE.LOG,'    �i�ڃR�[�h  = ' || lv_item_code);
debug_log(FND_FILE.LOG,'    ���א��� = ' || ln_instruct_qty);
debug_log(FND_FILE.LOG,'    ���^�[���R�[�h = ' || lv_retcode);
debug_log(FND_FILE.LOG,'    �G���[���b�Z�[�W�R�[�h = ' || lv_errbuf);
debug_log(FND_FILE.LOG,'    �G���[���b�Z�[�W = ' || lv_errmsg);
debug_log(FND_FILE.LOG,'    ���v�d�� = ' || ln_weight);
debug_log(FND_FILE.LOG,'    ���v�e�� = ' || ln_capacity);
debug_log(FND_FILE.LOG,'    ���v�p���b�g�d��t = ' || ln_p_weight);
--
      -- �G���[�̏ꍇ  �����������͌p�����A�x���I���ƂȂ� #######################3
      IF (lv_retcode <> gv_status_normal) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                   ,gv_msg_wsh_13124     -- �ύڌ����֐��G���[
                                                   ,gv_tkn_table_name    -- �g�[�N��'TABLE_NAME'
                                                   ,gv_cons_mov_hdr_tbl  -- �ړ��˗�/�w���w�b�_
                                                   ,gv_tkn_param1        -- �g�[�N��'PARAM1'
                                                   ,lv_item_code         -- �i�ڃR�[�h
                                                   ,gv_tkn_param2        -- �g�[�N��'PARAM2'
                                                   ,ln_instruct_qty          -- ���v����
                                                   ,gv_tkn_param3        -- �g�[�N��'PARAM3'
                                                   ,lv_errbuf            -- �G���[���b�Z�[�W�R�[�h
                                                   ,gv_tkn_param4        -- �g�[�N��'PARAM4'
                                                   ,lv_errmsg            -- �G���[���b�Z�[�W
                                                   )
                                                   ,1
                                                   ,5000);
--
        -- �x���̏o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
        -- �x�������̃J�E���g
        gn_warn_cnt := gn_warn_cnt + 1;
        ov_retcode := gv_status_warn;
--
        -- �C���T�[�g�Ώۂ��珜�O����t���O��ON�ɂ���B
        gr_move_lines_tbl(ln_line_cnt).not_insert_flg := gv_cons_flg_on;
--
      ELSE
        gr_move_lines_tbl(ln_line_cnt).not_insert_flg := gv_cons_flg_off;
--
      END IF;
--
debug_log(FND_FILE.LOG,'  ���׉��Z����');
debug_log(FND_FILE.LOG,'    ���v�d�� = ' || ln_weight);
debug_log(FND_FILE.LOG,'    �p���b�g���v�d�� = ' || ln_p_weight);
debug_log(FND_FILE.LOG,'    ���v�e�� = ' || ln_capacity);
      --���ז��̏d�ʂ��Z�b�g
      gr_move_lines_tbl(ln_line_cnt).weight := ln_weight;
      --���ז��̃p���b�g�d�ʂ��Z�b�g
      gr_move_lines_tbl(ln_line_cnt).pallet_weight := ln_p_weight;
      --���ז��̗e�ς��Z�b�g
      gr_move_lines_tbl(ln_line_cnt).capacity := ln_capacity;
--
    END LOOP move_line_weight_capacityloop;
--
--
-- ############################################################################################
-- �ړ��w�b�_�d��/�e�ϕ⊮���[�v
-- ############################################################################################
--
    --�w�b�_�P�ʂɕR�Â����ׂ̏d��/�e�ς����v����
    <<move_hdr_weight_capacity_loop>>
    FOR ln_hdr_cnt IN 1..gr_move_header_tbl.COUNT LOOP
--
      ln_sum_weight := 0;
      ln_sum_p_weight := 0;
      ln_sum_capacity := 0;
--
      FOR ln_line_cnt IN 1..gr_move_lines_tbl.COUNT LOOP
--
        -- �����w�b�_ID�Ȃ�΍��Z����
        IF (gr_move_header_tbl(ln_hdr_cnt).mov_hdr_id =
            gr_move_lines_tbl(ln_line_cnt).mov_hdr_id)
        THEN
          ln_sum_weight := ln_sum_weight + NVL(gr_move_lines_tbl(ln_line_cnt).weight, 0);
          ln_sum_p_weight := ln_sum_p_weight + NVL(gr_move_lines_tbl(ln_line_cnt).pallet_weight, 0);
          ln_sum_capacity := ln_sum_capacity + NVL(gr_move_lines_tbl(ln_line_cnt).capacity, 0);
        END IF;
--
      END LOOP;
--
debug_log(FND_FILE.LOG,'  �w�b�_���Z����');
debug_log(FND_FILE.LOG,'    ���v�d�� = ' || ln_sum_weight);
debug_log(FND_FILE.LOG,'    �p���b�g���v�d�� = ' || ln_sum_p_weight);
debug_log(FND_FILE.LOG,'    ���v�e�� = ' || ln_sum_capacity);
      gr_move_header_tbl(ln_hdr_cnt).sum_weight := ln_sum_weight;
      gr_move_header_tbl(ln_hdr_cnt).sum_pallet_weight := ln_sum_p_weight;
      gr_move_header_tbl(ln_hdr_cnt).sum_capacity := ln_sum_capacity;
--
    END LOOP move_hdr_weight_capacity_loop;
--
-- ############################################################################################
-- �ړ��w�b�_�ύڌ����⊮���[�v
-- ############################################################################################
--
    ln_mov_hdr_id := NULL;
--
    -- �d�ʗe�ϋ敪�ɉ����āA�d�ʐύڌ����܂��͗e�ϐύڌ������Z�b�g����
    <<move_header_le_loop>>
    FOR ln_hdr_cnt IN 1..gr_move_header_tbl.COUNT LOOP
--
      ln_sum_weight := 0;
      ln_sum_capacity := 0;
      ln_load_efficiency_weight := 0;
      ln_load_efficiency_capacity := 0;
--
      -- �d�ʗe�ϋ敪=�d�ʂ̏ꍇ�ɁA�d�ʐύڌ������Z�o����
      IF gr_move_header_tbl(ln_hdr_cnt).weight_capacity_class = gv_cons_weight THEN
--
        --�d�ʎZ�o�̂��߁A���v�d�ʂɃp���b�g�d�ʂ����Z����
        ln_sum_weight := NVL(gr_move_header_tbl(ln_hdr_cnt).sum_weight,0) +
                         NVL(gr_move_header_tbl(ln_hdr_cnt).sum_pallet_weight,0);
--
        -- �P�w�b�_������̐ύڌ������Z�o���ăw�b�_�ɃZ�b�g����
        -- �ύڌ����`�F�b�N(�ύڌ����Z�o)
        xxwsh_common910_pkg.calc_load_efficiency(
             ln_sum_weight,                                       -- 1.���v�d�� I
             NULL,                                                -- 2.���v�e�� I
             gv_cons_wh,                                          -- 3.�R�[�h�敪�P I '4'
             gr_move_header_tbl(ln_hdr_cnt).shipped_locat_code,   -- 4.���o�ɏꏊ�R�[�h�P I
               gv_cons_wh,                                          -- 5.�R�[�h�敪�Q I '4'
             gr_move_header_tbl(ln_hdr_cnt).ship_to_locat_code,   -- 6.���o�ɏꏊ�R�[�h�Q I
             gr_move_header_tbl(ln_hdr_cnt).shipping_method_code, -- 7.�o�ו��@ I
             gr_move_header_tbl(ln_hdr_cnt).item_class,           -- 8.���i�敪 I
             NULL,                                                -- 9.�����z�ԑΏۋ敪 I
             TO_DATE(iv_arrival_date,'YYYY/MM/DD'),               -- 10.���(�K�p�����) I
             lv_retcode,                                          -- 11.���^�[���R�[�h O
             lv_errbuf,                                           -- 12.�G���[���b�Z�[�W�R�[�h O
             lv_errmsg,                                           -- 13.�G���[���b�Z�[�W O
             lv_loading_over_class,                               -- 14.�ύڃI�[�o�[�敪 O
             lv_ship_methods,                                     -- 15.�o�ו��@ O
             ln_load_efficiency_weight,                           -- 16.�d�ʐύڌ��� O
             ln_load_efficiency_capacity,                         -- 17.�e�ϐύڌ��� O
             lv_mixed_ship_method);                               -- 18.���ڔz���敪 O
--
debug_log(FND_FILE.LOG,'  �ړ��w�b�_�ύڌ���(�d��)-----------------');
debug_log(FND_FILE.LOG,'    ���v�d�� = ' || gr_move_header_tbl(ln_hdr_cnt).sum_weight);
debug_log(FND_FILE.LOG,'    ���o�ɏꏊ�R�[�h�P = ' || gr_move_header_tbl(ln_hdr_cnt).shipped_locat_code);
debug_log(FND_FILE.LOG,'    ���o�ɏꏊ�R�[�h�Q = ' || gr_move_header_tbl(ln_hdr_cnt).ship_to_locat_code);
debug_log(FND_FILE.LOG,'    �o�ו��@ = ' || gr_move_header_tbl(ln_hdr_cnt).shipping_method_code);
debug_log(FND_FILE.LOG,'    ���i�敪 = ' ||  gr_move_header_tbl(ln_hdr_cnt).item_class);
debug_log(FND_FILE.LOG,'    ���(�K�p�����) = ' ||  iv_arrival_date);
debug_log(FND_FILE.LOG,'    ���^�[���R�[�h = ' || lv_retcode);
debug_log(FND_FILE.LOG,'    �G���[���b�Z�[�W�R�[�h = ' || lv_errbuf);
debug_log(FND_FILE.LOG,'    �G���[���b�Z�[�W = ' || lv_errmsg);
debug_log(FND_FILE.LOG,'    �ύڃI�[�o�[�敪 = ' || lv_loading_over_class);
debug_log(FND_FILE.LOG,'    �o�ו��@ = ' || lv_ship_methods);
debug_log(FND_FILE.LOG,'    �d�ʐύڌ��� = ' || ln_load_efficiency_weight);
debug_log(FND_FILE.LOG,'    �e�ϐύڌ��� = ' || ln_load_efficiency_capacity);
debug_log(FND_FILE.LOG,'    ���ڔz���敪 = ' || lv_mixed_ship_method);
--
        -- �G���[�̏ꍇ  �����������͌p�����A�x���I���ƂȂ� #######################3
        IF (lv_retcode <> gv_status_normal) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                        ,gv_msg_wsh_13172                                   -- �ύڌ����֐��G���[
                        ,gv_tkn_table_name                                  -- �g�[�N��'TABLE_NAME'
                        ,gv_cons_mov_hdr_tbl                                -- �ړ��˗�/�w���w�b�_
                        ,gv_tkn_param1                                      -- �g�[�N��'PARAM1'
                        ,gr_move_header_tbl(ln_hdr_cnt).sum_weight          -- ���v�d��
                        ,gv_tkn_param2                                      -- �g�[�N��'PARAM2'
                        ,gv_cons_wh                                         -- �R�[�h�敪
                        ,gv_tkn_param3                                      -- �g�[�N��'PARAM3'
                        ,gr_move_header_tbl(ln_hdr_cnt).shipped_locat_code  -- ���o�ɏꏊ�R�[�h
                        ,gv_tkn_param4                                      -- �g�[�N��'PARAM4'
                        ,gv_cons_wh                                         -- �R�[�h�敪
                        ,gv_tkn_param5                                      -- �g�[�N��'PARAM5'
                        ,gr_move_header_tbl(ln_hdr_cnt).ship_to_locat_code  -- ���o�ɏꏊ�R�[�h
                        ,gv_tkn_param6                                      -- �g�[�N��'PARAM6'
                        ,gr_move_header_tbl(ln_hdr_cnt).shipping_method_code -- �o�ו��@
                        ,gv_tkn_param7                                      -- �g�[�N��'PARAM7'
                        ,gr_move_header_tbl(ln_hdr_cnt).item_class          -- ���i�敪
                        ,gv_tkn_param8                                      -- �g�[�N��'PARAM8'
                        ,lv_errbuf                                    -- �G���[���b�Z�[�W�R�[�h
                        ,gv_tkn_param9                                      -- �g�[�N��'PARAM9'
                        ,lv_errmsg                                          -- �G���[���b�Z�[�W
                        )
                        ,1
                        ,5000);
--
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
        -- �x�������̃J�E���g
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode := gv_status_warn;
          -- �C���T�[�g�Ώۂ��珜�O����t���O��ON�ɂ���B
          gr_move_header_tbl(ln_hdr_cnt).not_insert_flg := gv_cons_flg_on;
--
        ELSE
          gr_move_header_tbl(ln_hdr_cnt).not_insert_flg := gv_cons_flg_off;
        END IF;
--
        -- �ύڃI�[�o�[�敪��'1'��������
        IF (lv_loading_over_class = gv_cons_over_1y) THEN
--
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                               gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                              ,gv_msg_wsh_13001     -- �ύڃI�[�o�[�G���[
                                              ,gr_move_header_tbl(ln_hdr_cnt).mov_num -- �ړ��ԍ�
                                              ,lv_errmsg)           -- ���b�Z�[�W
                                              ,1
                                              ,5000);
--
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode := gv_status_warn;
--
        END IF;
--
      -- �d�ʗe�ϋ敪=�e�ς̏ꍇ�ɁA�e�ϐύڌ������Z�o����
      ELSIF gr_move_header_tbl(ln_hdr_cnt).weight_capacity_class = gv_cons_capacity THEN
--
        --�e�ς̎擾
        ln_sum_capacity := NVL(gr_move_header_tbl(ln_hdr_cnt).sum_capacity,0);
--
        -- �P�w�b�_������̐ύڌ������Z�o���ăw�b�_�ɃZ�b�g����
        -- �ύڌ����`�F�b�N(�ύڌ����Z�o)
        xxwsh_common910_pkg.calc_load_efficiency(
             NULL,                                                -- 1.���v�d�� I
             ln_sum_capacity,                                     -- 2.���v�e�� I
             gv_cons_wh,                                          -- 3.�R�[�h�敪�P I '4'
             gr_move_header_tbl(ln_hdr_cnt).shipped_locat_code,   -- 4.���o�ɏꏊ�R�[�h�P I
             gv_cons_wh,                                          -- 5.�R�[�h�敪�Q I '4'
             gr_move_header_tbl(ln_hdr_cnt).ship_to_locat_code,   -- 6.���o�ɏꏊ�R�[�h�Q I
             gr_move_header_tbl(ln_hdr_cnt).shipping_method_code, -- 7.�o�ו��@ I
             gr_move_header_tbl(ln_hdr_cnt).item_class,           -- 8.���i�敪 I
             NULL,                                                -- 9.�����z�ԑΏۋ敪 I
             TO_DATE(iv_arrival_date,'YYYY/MM/DD'),               -- 10.���(�K�p�����) I
             lv_retcode,                                          -- 11.���^�[���R�[�h O
             lv_errbuf,                                           -- 12.�G���[���b�Z�[�W�R�[�h O
             lv_errmsg,                                           -- 13.�G���[���b�Z�[�W O
             lv_loading_over_class,                               -- 14.�ύڃI�[�o�[�敪 O
             lv_ship_methods,                                     -- 15.�o�ו��@ O
             ln_load_efficiency_weight,                           -- 16.�d�ʐύڌ��� O
             ln_load_efficiency_capacity,                         -- 17.�e�ϐύڌ��� O
             lv_mixed_ship_method);                               -- 18.���ڔz���敪 O
--
debug_log(FND_FILE.LOG,'  �ړ��w�b�_�ύڌ���(�e��)-----------------');
debug_log(FND_FILE.LOG,'    ���v�d�� = ' || gr_move_header_tbl(ln_hdr_cnt).sum_capacity);
debug_log(FND_FILE.LOG,'    ���o�ɏꏊ�R�[�h�P = ' || gr_move_header_tbl(ln_hdr_cnt).shipped_locat_code);
debug_log(FND_FILE.LOG,'    ���o�ɏꏊ�R�[�h�Q = ' || gr_move_header_tbl(ln_hdr_cnt).ship_to_locat_code);
debug_log(FND_FILE.LOG,'    �o�ו��@ = ' || gr_move_header_tbl(ln_hdr_cnt).shipping_method_code);
debug_log(FND_FILE.LOG,'    ���i�敪 = ' ||  gr_move_header_tbl(ln_hdr_cnt).item_class);
debug_log(FND_FILE.LOG,'    ���(�K�p�����) = ' ||  iv_arrival_date);
debug_log(FND_FILE.LOG,'    ���^�[���R�[�h = ' || lv_retcode);
debug_log(FND_FILE.LOG,'    �G���[���b�Z�[�W�R�[�h = ' || lv_errbuf);
debug_log(FND_FILE.LOG,'    �G���[���b�Z�[�W = ' || lv_errmsg);
debug_log(FND_FILE.LOG,'    �ύڃI�[�o�[�敪 = ' || lv_loading_over_class);
debug_log(FND_FILE.LOG,'    �o�ו��@ = ' || lv_ship_methods);
debug_log(FND_FILE.LOG,'    �d�ʐύڌ��� = ' || ln_load_efficiency_weight);
debug_log(FND_FILE.LOG,'    �e�ϐύڌ��� = ' || ln_load_efficiency_capacity);
debug_log(FND_FILE.LOG,'    ���ڔz���敪 = ' || lv_mixed_ship_method);
--
        -- �G���[�̏ꍇ  �����������͌p�����A�x���I���ƂȂ� #######################3
        IF (lv_retcode <> gv_status_normal) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                          ,gv_msg_wsh_13172                                   -- �ύڌ����֐��G���[
                          ,gv_tkn_table_name                                  -- �g�[�N��'TABLE_NAME'
                          ,gv_cons_mov_hdr_tbl                                -- �ړ��˗�/�w���w�b�_
                          ,gv_tkn_param1                                      -- �g�[�N��'PARAM1'
                          ,gr_move_header_tbl(ln_hdr_cnt).sum_capacity        -- ���v�e��
                          ,gv_tkn_param2                                      -- �g�[�N��'PARAM2'
                          ,gv_cons_wh                                         -- �R�[�h�敪
                          ,gv_tkn_param3                                      -- �g�[�N��'PARAM3'
                          ,gr_move_header_tbl(ln_hdr_cnt).shipped_locat_code  -- ���o�ɏꏊ�R�[�h
                          ,gv_tkn_param4                                      -- �g�[�N��'PARAM4'
                          ,gv_cons_wh                                         -- �R�[�h�敪
                          ,gv_tkn_param5                                      -- �g�[�N��'PARAM5'
                          ,gr_move_header_tbl(ln_hdr_cnt).ship_to_locat_code  -- ���o�ɏꏊ�R�[�h
                          ,gv_tkn_param6                                      -- �g�[�N��'PARAM6'
                          ,gr_move_header_tbl(ln_hdr_cnt).shipping_method_code -- �o�ו��@
                          ,gv_tkn_param7                                      -- �g�[�N��'PARAM7'
                          ,gr_move_header_tbl(ln_hdr_cnt).item_class          -- ���i�敪
                          ,gv_tkn_param8                                      -- �g�[�N��'PARAM8'
                          ,lv_errbuf                                    -- �G���[���b�Z�[�W�R�[�h
                          ,gv_tkn_param9                                      -- �g�[�N��'PARAM9'
                          ,lv_errmsg                                          -- �G���[���b�Z�[�W
                          )
                          ,1
                          ,5000);
--
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode := gv_status_warn;
          -- �C���T�[�g�Ώۂ��珜�O����t���O��ON�ɂ���B
          gr_move_header_tbl(ln_hdr_cnt).not_insert_flg := gv_cons_flg_on;
--
        ELSE
          gr_move_header_tbl(ln_hdr_cnt).not_insert_flg := gv_cons_flg_off;
        END IF;
--
        -- �ύڃI�[�o�[�敪��'1'��������
        IF (lv_loading_over_class = gv_cons_over_1y) THEN
--
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                               gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                              ,gv_msg_wsh_13001     -- �ύڃI�[�o�[�G���[
                                              ,gr_move_header_tbl(ln_hdr_cnt).mov_num -- �ړ��ԍ�
                                              ,lv_errmsg)           -- ���b�Z�[�W
                                              ,1
                                              ,5000);
--
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode := gv_status_warn;
--
        END IF;
--
      END IF;
--
      -- �w�b�_�ɃZ�b�g
      gr_move_header_tbl(ln_hdr_cnt).loading_efficiency_weight := ln_load_efficiency_weight;
      gr_move_header_tbl(ln_hdr_cnt).loading_efficiency_capacity := ln_load_efficiency_capacity;
--
    END LOOP;
--
debug_log(FND_FILE.LOG,'(C-15)' || cv_prg_name || ' End�����');
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
  END calc_weight_capacity;
--
--
   /**********************************************************************************
   * Procedure Name   : insert_tables
   * Description      : C-14 �o�^�X�V����
   ***********************************************************************************/
  PROCEDURE insert_tables(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_tables'; -- �v���O������
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
    ln_data_cnt           NUMBER;         -- INSERT���[�v�p�J�E���^(���L)
--
    ln_mh_data_cnt        NUMBER;         -- ���O�Ώۂ��܂ވړ��w�b�_�o�^�Ώی����p�̃J�E���^
    ln_ml_data_cnt        NUMBER;         -- ���O�Ώۂ��܂ވړ����דo�^�Ώی����p�̃J�E���^
    ln_mh_ins_data_cnt    NUMBER := 0;    -- �ړ��w�b�_�o�^�p�̃J�E���^
    ln_ml_ins_data_cnt    NUMBER := 0;    -- �ړ����דo�^�p�̃J�E���^
    ln_search_cnt         NUMBER;
    lv_line_ins_flg       VARCHAR2(1);
--
    ln_ph_data_cnt        NUMBER;         -- �����˗��w�b�_�o�^�Ώی����p�̃J�E���^
    ln_pl_data_cnt        NUMBER;         -- �����˗����דo�^�Ώی����p�̃J�E���^
    ln_ph_ins_data_cnt    NUMBER := 0;    -- �ړ��w�b�_�o�^�p�̃J�E���^
    ln_pl_ins_data_cnt    NUMBER := 0;    -- �ړ����דo�^�p�̃J�E���^
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
debug_log(FND_FILE.LOG,'(C-14)' || cv_prg_name || ' Start���');
debug_log(FND_FILE.LOG,'  �ړ��w�b�_�o�^����(�x���ɂ�鏜�O�Ώۊ܂�) = ' || TO_CHAR(gn_ins_data_cnt_mh));
debug_log(FND_FILE.LOG,'  �ړ����דo�^����(�x���ɂ�鏜�O�Ώۊ܂�) = ' || TO_CHAR(gn_ins_data_cnt_ml));
debug_log(FND_FILE.LOG,'  �����˗��w�b�_�o�^���� = ' || TO_CHAR(gn_ins_data_cnt_ph));
debug_log(FND_FILE.LOG,'  �����˗����דo�^���� = ' || TO_CHAR(gn_ins_data_cnt_pl));
debug_log(FND_FILE.LOG,'  �ړ����׍X�V����(�x���ɂ�鏜�O�Ώۊ܂�) = ' || TO_CHAR(gn_upd_data_cnt_ml));
debug_log(FND_FILE.LOG,'  �󒍖��׍X�V����(�x���ɂ�鏜�O�Ώۊ܂�) = ' || TO_CHAR(gn_upd_data_cnt_ol));
--
    -- FORALL�Ŏg�p�ł���悤�Ƀ��R�[�h�ϐ��𕪊��i�[���� �ړ��w�b�_
    <<ln_mh_ins_cnt_loop>>
    FOR ln_mh_data_cnt IN 1..gn_ins_data_cnt_mh LOOP
--
debug_log(FND_FILE.LOG,'  �o�^���O�t���O = '|| gr_move_header_tbl(ln_mh_data_cnt).not_insert_flg);
debug_log(FND_FILE.LOG,'  �ړ��w�b�_ID = ' || gr_move_header_tbl(ln_mh_data_cnt).mov_hdr_id);
debug_log(FND_FILE.LOG,'  �ړ��ԍ� = ' || gr_move_header_tbl(ln_mh_data_cnt).mov_num);
--
      IF (gr_move_header_tbl(ln_mh_data_cnt).not_insert_flg <> gv_cons_flg_on) THEN
--
        -- �w�b�_�C���T�[�g�p�ϐ��̃C���N�������g
        ln_mh_ins_data_cnt := ln_mh_ins_data_cnt + 1;
--
        gt_h_mov_hdr_id(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).mov_hdr_id;                  -- �ړ��w�b�_ID
        gt_h_mov_num(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).mov_num;                     -- �ړ��ԍ�
        gt_h_mov_type(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).mov_type;                    -- �ړ��^�C�v
        gt_h_entered_date(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).entered_date;                -- ���͓�
        gt_h_instruction_post_code(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).instruction_post_code;       -- �w������
        gt_h_status(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).status;                      -- �X�e�[�^�X
        gt_h_notif_status(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).notif_status;                -- �ʒm�X�e�[�^�X
        gt_h_shipped_locat_id(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).shipped_locat_id;            -- �o�Ɍ�ID
        gt_h_shipped_locat_code(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).shipped_locat_code;          -- �o�Ɍ��ۊǏꏊ
        gt_h_ship_to_locat_id(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).ship_to_locat_id;            -- ���ɐ�ID
        gt_h_ship_to_locat_code(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).ship_to_locat_code;          -- ���ɐ�ۊǏꏊ
        gt_h_schedule_ship_date(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).schedule_ship_date;          -- �o�ɗ\���
        gt_h_schedule_arrival_date(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).schedule_arrival_date;       -- ���ɗ\���
        gt_h_freight_charge_class(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).freight_charge_class;        -- �^���敪
        gt_h_collected_pallet_qty(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).collected_pallet_qty;        -- �p���b�g�������
        gt_h_out_pallet_qty(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).out_pallet_qty;              -- �p���b�g����(�o)
        gt_h_in_pallet_qty(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).in_pallet_qty;               -- �p���b�g����(��)
        gt_h_no_cont_freight_class(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).no_cont_freight_class;       -- �_��O�^���敪
        gt_h_delivery_no(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).delivery_no;                 -- �z��No
        gt_h_description(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).description;                 -- �E�v
        gt_h_loading_efficiency_weight(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).loading_efficiency_weight;   -- �ύڗ�(�d��)
        gt_h_loading_efficiency_capa(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).loading_efficiency_capacity; -- �ύڗ�(�e��)
        gt_h_organization_id(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).organization_id;             -- �g�DID
        gt_h_career_id(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).career_id;                   -- �^���Ǝ�ID
        gt_h_freight_carrier_code(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).freight_carrier_code;        -- �^���Ǝ�
        gt_h_shipping_method_code(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).shipping_method_code;        -- �z���敪
        gt_h_actual_career_id(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).actual_career_id;            -- �^���Ǝ�ID_����
        gt_h_actual_freight_carrier_cd(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).actual_freight_carrier_code; -- �^���Ǝ�_����
        gt_h_actual_shipping_method_cd(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).actual_shipping_method_code; -- �z���敪_����
        gt_h_arrival_time_from(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).arrival_time_from;           -- ���׎���FROM
        gt_h_arrival_time_to(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).arrival_time_to;             -- ���׎���TO
        gt_h_slip_number(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).slip_number;                 -- �����No
        gt_h_sum_quantity(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).sum_quantity;                -- ���v����
        gt_h_small_quantity(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).small_quantity;              -- ������
        gt_h_label_quantity(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).label_quantity;              -- ���x������
        gt_h_based_weight(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).based_weight;                -- ��{�d��
        gt_h_based_capacity(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).based_capacity;              -- ��{�e��
        gt_h_sum_weight(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).sum_weight;                  -- ���ڏd�ʍ��v
        gt_h_sum_capacity(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).sum_capacity;                -- ���ڗe�ύ��v
        gt_h_sum_pallet_weight(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).sum_pallet_weight;           -- ���v�p���b�g�d��
        gt_h_pallet_sum_quantity(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).pallet_sum_quantity;         -- �p���b�g���v����
        gt_h_mixed_ratio(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).mixed_ratio;                 -- ���ڗ�
        gt_h_weight_capacity_class(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).weight_capacity_class;       -- �d�ʗe�ϋ敪
        gt_h_actual_ship_date(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).actual_ship_date;            -- �o�Ɏ��ѓ�
        gt_h_actual_arrival_date(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).actual_arrival_date;         -- ���Ɏ��ѓ�
        gt_h_mixed_sign(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).mixed_sign;                  -- ���ڋL��
        gt_h_batch_no(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).batch_no;                    -- ��zNo
        gt_h_item_class(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).item_class;                  -- ���i�敪
        gt_h_product_flg(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).product_flg;                 -- ���i���ʋ敪
        gt_h_no_instr_actual_class(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).no_instr_actual_class;       -- �w���Ȃ����ы敪
        gt_h_comp_actual_flg(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).comp_actual_flg;             -- ���ьv��σt���O
        gt_h_correct_actual_flg(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).correct_actual_flg;          -- ���ђ����t���O
        gt_h_prev_notif_status(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).prev_notif_status;           -- �O��ʒm�X�e�[�^�X
        gt_h_notif_date(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).notif_date;                  -- �m��ʒm���ѓ���
        gt_h_prev_delivery_no(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).prev_delivery_no;            -- �O��z��No
        gt_h_new_modify_flg(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).new_modify_flg;              -- �V�K�C���t���O
        gt_h_screen_update_by(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).screen_update_by;            -- ��ʍX�V��
        gt_h_screen_update_date(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).screen_update_date;          -- ��ʍX�V����
        gt_h_created_by(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).created_by;                  -- �쐬��
        gt_h_creation_date(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).creation_date;               -- �쐬��
        gt_h_last_updated_by(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).last_updated_by;             -- �ŏI�X�V��
        gt_h_last_update_date(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).last_update_date;            -- �ŏI�X�V��
        gt_h_last_update_login(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).last_update_login;           -- �ŏI�X�V���O�C��
        gt_h_request_id(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).request_id;                  -- �v��ID
        gt_h_program_application_id(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).program_application_id;
                                                         -- �R���J�����g�v���O�����A�v���P�[�V����ID
        gt_h_program_id(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).program_id;                  -- �R���J�����g�v���O����ID
        gt_h_program_update_date(ln_mh_ins_data_cnt) :=
            gr_move_header_tbl(ln_mh_data_cnt).program_update_date;         -- �v���O�����X�V��
--
      END IF;
--
    END LOOP ln_mh_ins_cnt_loop;
--
--
debug_log(FND_FILE.LOG,'  �ړ��w�b�_�o�^���� = ' || TO_CHAR(ln_mh_ins_data_cnt));
--
    -- FORALL�ɂĈړ��˗�/�w���w�b�_��INSERT����
    FORALL ln_data_cnt IN 1..ln_mh_ins_data_cnt
--
      INSERT INTO xxinv_mov_req_instr_headers(
        mov_hdr_id,                  -- �ړ��w�b�_ID
        mov_num,                     -- �ړ��ԍ�
        mov_type,                    -- �ړ��^�C�v
        entered_date,                -- ���͓�
        instruction_post_code,       -- �w������
        status,                      -- �X�e�[�^�X
        notif_status,                -- �ʒm�X�e�[�^�X
        shipped_locat_id,            -- �o�Ɍ�ID
        shipped_locat_code,          -- �o�Ɍ��ۊǏꏊ
        ship_to_locat_id,            -- ���ɐ�ID
        ship_to_locat_code,          -- ���ɐ�ۊǏꏊ
        schedule_ship_date,          -- �o�ɗ\���
        schedule_arrival_date,       -- ���ɗ\���
        freight_charge_class,        -- �^���敪
        collected_pallet_qty,        -- �p���b�g�������
        out_pallet_qty,              -- �p���b�g����(�o)
        in_pallet_qty,               -- �p���b�g����(��)
        no_cont_freight_class,       -- �_��O�^���敪
        delivery_no,                 -- �z��No
        description,                 -- �E�v
        loading_efficiency_weight,   -- �ύڗ�(�d��)
        loading_efficiency_capacity, -- �ύڗ�(�e��)
        organization_id,             -- �g�DID
        career_id,                   -- �^���Ǝ�ID
        freight_carrier_code,        -- �^���Ǝ�
        shipping_method_code,        -- �z���敪
        actual_career_id,            -- �^���Ǝ�ID_����
        actual_freight_carrier_code, -- �^���Ǝ�_����
        actual_shipping_method_code, -- �z���敪_����
        arrival_time_from,           -- ���׎���FROM
        arrival_time_to,             -- ���׎���TO
        slip_number,                 -- �����No
        sum_quantity,                -- ���v����
        small_quantity,              -- ������
        label_quantity,              -- ���x������
        based_weight,                -- ��{�d��
        based_capacity,              -- ��{�e��
        sum_weight,                  -- ���ڏd�ʍ��v
        sum_capacity,                -- ���ڗe�ύ��v
        sum_pallet_weight,           -- ���v�p���b�g�d��
        pallet_sum_quantity,         -- �p���b�g���v����
        mixed_ratio,                 -- ���ڗ�
        weight_capacity_class,       -- �d�ʗe�ϋ敪
        actual_ship_date,            -- �o�Ɏ��ѓ�
        actual_arrival_date,         -- ���Ɏ��ѓ�
        mixed_sign,                  -- ���ڋL��
        batch_no,                    -- ��zNo
        item_class,                  -- ���i�敪
        product_flg,                 -- ���i���ʋ敪
        no_instr_actual_class,       -- �w���Ȃ����ы敪
        comp_actual_flg,             -- ���ьv��σt���O
        correct_actual_flg,          -- ���ђ����t���O
        prev_notif_status,           -- �O��ʒm�X�e�[�^�X
        notif_date,                  -- �m��ʒm���ѓ���
        prev_delivery_no,            -- �O��z��No
        new_modify_flg,              -- �V�K�C���t���O
        screen_update_by,            -- ��ʍX�V��
        screen_update_date,          -- ��ʍX�V����
        created_by,                  -- �쐬��
        creation_date,               -- �쐬��
        last_updated_by,             -- �ŏI�X�V��
        last_update_date,            -- �ŏI�X�V��
        last_update_login,           -- �ŏI�X�V���O�C��
        request_id,                  -- �v��ID
        program_application_id,      -- �R���J�����g�v���O�����A�v���P�[�V����ID
        program_id,                  -- �R���J�����g�v���O����ID
        program_update_date          -- �v���O�����X�V��
      )VALUES(
        gt_h_mov_hdr_id(ln_data_cnt),                  -- �ړ��w�b�_ID
        gt_h_mov_num(ln_data_cnt),                     -- �ړ��ԍ�
        gt_h_mov_type(ln_data_cnt),                    -- �ړ��^�C�v
        gt_h_entered_date(ln_data_cnt),                -- ���͓�
        gt_h_instruction_post_code(ln_data_cnt),       -- �w������
        gt_h_status(ln_data_cnt),                      -- �X�e�[�^�X
        gt_h_notif_status(ln_data_cnt),                -- �ʒm�X�e�[�^�X
        gt_h_shipped_locat_id(ln_data_cnt),            -- �o�Ɍ�ID
        gt_h_shipped_locat_code(ln_data_cnt),          -- �o�Ɍ��ۊǏꏊ
        gt_h_ship_to_locat_id(ln_data_cnt),            -- ���ɐ�ID
        gt_h_ship_to_locat_code(ln_data_cnt),          -- ���ɐ�ۊǏꏊ
        gt_h_schedule_ship_date(ln_data_cnt),          -- �o�ɗ\���
        gt_h_schedule_arrival_date(ln_data_cnt),       -- ���ɗ\���
        gt_h_freight_charge_class(ln_data_cnt),        -- �^���敪
        gt_h_collected_pallet_qty(ln_data_cnt),        -- �p���b�g�������
        gt_h_out_pallet_qty(ln_data_cnt),              -- �p���b�g����(�o)
        gt_h_in_pallet_qty(ln_data_cnt),               -- �p���b�g����(��)
        gt_h_no_cont_freight_class(ln_data_cnt),       -- �_��O�^���敪
        gt_h_delivery_no(ln_data_cnt),                 -- �z��No
        gt_h_description(ln_data_cnt),                 -- �E�v
        gt_h_loading_efficiency_weight(ln_data_cnt),   -- �ύڗ�(�d��)
        gt_h_loading_efficiency_capa(ln_data_cnt),     -- �ύڗ�(�e��)
        gt_h_organization_id(ln_data_cnt),             -- �g�DID
        gt_h_career_id(ln_data_cnt),                   -- �^���Ǝ�ID
        gt_h_freight_carrier_code(ln_data_cnt),        -- �^���Ǝ�
        gt_h_shipping_method_code(ln_data_cnt),        -- �z���敪
        gt_h_actual_career_id(ln_data_cnt),            -- �^���Ǝ�ID_����
        gt_h_actual_freight_carrier_cd(ln_data_cnt),   -- �^���Ǝ�_����
        gt_h_actual_shipping_method_cd(ln_data_cnt),   -- �z���敪_����
        gt_h_arrival_time_from(ln_data_cnt),           -- ���׎���FROM
        gt_h_arrival_time_to(ln_data_cnt),             -- ���׎���TO
        gt_h_slip_number(ln_data_cnt),                 -- �����No
        gt_h_sum_quantity(ln_data_cnt),                -- ���v����
        gt_h_small_quantity(ln_data_cnt),              -- ������
        gt_h_label_quantity(ln_data_cnt),              -- ���x������
        gt_h_based_weight(ln_data_cnt),                -- ��{�d��
        gt_h_based_capacity(ln_data_cnt),              -- ��{�e��
        gt_h_sum_weight(ln_data_cnt),                  -- ���ڏd�ʍ��v
        gt_h_sum_capacity(ln_data_cnt),                -- ���ڗe�ύ��v
        gt_h_sum_pallet_weight(ln_data_cnt),           -- ���v�p���b�g�d��
        gt_h_pallet_sum_quantity(ln_data_cnt),         -- �p���b�g���v����
        gt_h_mixed_ratio(ln_data_cnt),                 -- ���ڗ�
        gt_h_weight_capacity_class(ln_data_cnt),       -- �d�ʗe�ϋ敪
        gt_h_actual_ship_date(ln_data_cnt),            -- �o�Ɏ��ѓ�
        gt_h_actual_arrival_date(ln_data_cnt),         -- ���Ɏ��ѓ�
        gt_h_mixed_sign(ln_data_cnt),                  -- ���ڋL��
        gt_h_batch_no(ln_data_cnt),                    -- ��zNo
        gt_h_item_class(ln_data_cnt),                  -- ���i�敪
        gt_h_product_flg(ln_data_cnt),                 -- ���i���ʋ敪
        gt_h_no_instr_actual_class(ln_data_cnt),       -- �w���Ȃ����ы敪
        gt_h_comp_actual_flg(ln_data_cnt),             -- ���ьv��σt���O
        gt_h_correct_actual_flg(ln_data_cnt),          -- ���ђ����t���O
        gt_h_prev_notif_status(ln_data_cnt),           -- �O��ʒm�X�e�[�^�X
        gt_h_notif_date(ln_data_cnt),                  -- �m��ʒm���ѓ���
        gt_h_prev_delivery_no(ln_data_cnt),            -- �O��z��No
        gt_h_new_modify_flg(ln_data_cnt),              -- �V�K�C���t���O
        gt_h_screen_update_by(ln_data_cnt),            -- ��ʍX�V��
        gt_h_screen_update_date(ln_data_cnt),          -- ��ʍX�V����
        gt_h_created_by(ln_data_cnt),                  -- �쐬��
        gt_h_creation_date(ln_data_cnt),               -- �쐬��
        gt_h_last_updated_by(ln_data_cnt),             -- �ŏI�X�V��
        gt_h_last_update_date(ln_data_cnt),            -- �ŏI�X�V��
        gt_h_last_update_login(ln_data_cnt),           -- �ŏI�X�V���O�C��
        gt_h_request_id(ln_data_cnt),                  -- �v��ID
        gt_h_program_application_id(ln_data_cnt),      -- �R���J�����g�v���O�����A�v���P�[�V����ID
        gt_h_program_id(ln_data_cnt),                  -- �R���J�����g�v���O����ID
        gt_h_program_update_date(ln_data_cnt)          -- �v���O�����X�V��
      );
--
--
    -- FORALL�Ŏg�p�ł���悤�Ƀ��R�[�h�ϐ��𕪊��i�[����  �ړ�����
    <<ln_ml_ins_cnt_loop>>
    FOR ln_ml_data_cnt IN 1..gn_ins_data_cnt_ml LOOP
--
      -- �w�b�_�p�ϐ��ɂ��邩�ǂ�������������΂��̂܂܁A�Ȃ���΍쐬���Ȃ����ׂƂ���
      <<search_loop>>
      FOR ln_search_cnt IN 1..ln_mh_ins_data_cnt LOOP
--
        IF (gr_move_lines_tbl(ln_ml_data_cnt).mov_hdr_id = gt_h_mov_hdr_id(ln_search_cnt)) THEN
          lv_line_ins_flg := gv_cons_flg_on;
          EXIT;
        END IF;
--
      END LOOP search_loop;
--
debug_log(FND_FILE.LOG,'  �o�^���O�t���O(����) = ' || gr_move_lines_tbl(ln_ml_data_cnt).not_insert_flg);
debug_log(FND_FILE.LOG,'  �o�^���O�t���O(�w�b�_) = ' || lv_line_ins_flg);
debug_log(FND_FILE.LOG,'  �ړ��w�b�_ID = ' || gr_move_lines_tbl(ln_ml_data_cnt).mov_hdr_id);
debug_log(FND_FILE.LOG,'  �ړ�����ID = ' || gr_move_lines_tbl(ln_ml_data_cnt).mov_line_id);
debug_log(FND_FILE.LOG,'  �i�ڃR�[�h = ' || gr_move_lines_tbl(ln_ml_data_cnt).item_code);
--
      IF (lv_line_ins_flg = gv_cons_flg_on )
         OR (gr_move_lines_tbl(ln_ml_data_cnt).not_insert_flg <> gv_cons_flg_on) THEN
--
        -- ���׃C���T�[�g�p�ϐ��̃C���N�������g
        ln_ml_ins_data_cnt := ln_ml_ins_data_cnt + 1;
--
        gt_m_mov_line_id(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).mov_line_id;                -- �ړ�����ID
        gt_m_mov_hdr_id(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).mov_hdr_id;                 -- �ړ��w�b�_ID
        gt_m_line_number(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).line_number;                -- ���הԍ�
        gt_m_organization_id(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).organization_id;            -- �g�DID
        gt_m_item_id(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).item_id;                    -- OPM�i��ID
        gt_m_item_code(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).item_code;                  -- �i��
        gt_m_request_qty(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).request_qty;                -- �˗�����
        gt_m_pallet_quantity(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).pallet_quantity;            -- �p���b�g��
        gt_m_layer_quantity(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).layer_quantity;             -- �i��
        gt_m_case_quantity(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).case_quantity;              -- �P�[�X��
        gt_m_instruct_qty(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).instruct_qty;               -- �w������
        gt_m_reserved_quantity(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).reserved_quantity;          -- ������
        gt_m_uom_code(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).uom_code;                   -- �P��
        gt_m_designated_pdt_date(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).designated_production_date; -- �w�萻����
        gt_m_pallet_qty(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).pallet_qty;                 -- �p���b�g����
        gt_m_move_num(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).move_num;                   -- �Q�ƈړ��ԍ�
        gt_m_po_num(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).po_num;                     -- �Q�Ɣ����ԍ�
        gt_m_first_instruct_qty(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).first_instruct_qty;         -- ����w������
        gt_m_shipped_quantity(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).shipped_quantity;           -- �o�Ɏ��ѐ���
        gt_m_ship_to_quantity(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).ship_to_quantity;           -- ���Ɏ��ѐ���
        gt_m_weight(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).weight;                     -- �d��
        gt_m_capacity(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).capacity;                   -- �e��
        gt_m_pallet_weight(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).pallet_weight;              -- �p���b�g�d��
        gt_m_automanual_reserve_class(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).automanual_reserve_class;   -- �����蓮�����敪
        gt_m_delete_flg(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).delete_flg;                 -- ����t���O
        gt_m_warning_date(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).warning_date;               -- �x�����t
        gt_m_warning_class(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).warning_class;              -- �x���敪
        gt_m_created_by(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).created_by;                 -- �쐬��
        gt_m_creation_date(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).creation_date;              -- �쐬��
        gt_m_last_updated_by(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).last_updated_by;            -- �ŏI�X�V��
        gt_m_last_update_date(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).last_update_date;           -- �ŏI�X�V��
        gt_m_last_update_login(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).last_update_login;          -- �ŏI�X�V���O�C��
        gt_m_request_id(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).request_id;                 -- �v��ID
        gt_m_program_application_id(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).program_application_id;
                                                       -- �R���J�����g�v���O�����A�v���P�[�V����ID
        gt_m_program_id(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).program_id;                -- �R���J�����g�v���O����ID
        gt_m_program_update_date(ln_ml_ins_data_cnt) :=
                gr_move_lines_tbl(ln_ml_data_cnt).program_update_date;       -- �v���O�����X�V��
--
      END IF;
--
      lv_line_ins_flg := gv_cons_flg_off;
--
    END LOOP ln_ml_ins_cnt_loop;
--
--
debug_log(FND_FILE.LOG,'  �ړ����דo�^���� = ' || TO_CHAR(ln_ml_ins_data_cnt));
--
    -- FORALL�ɂĈړ��˗�/�w�����ׂ�INSERT����
    FORALL ln_data_cnt IN 1..ln_ml_ins_data_cnt
--
      INSERT INTO xxinv_mov_req_instr_lines(
        mov_line_id,                -- �ړ�����ID
        mov_hdr_id,                 -- �ړ��w�b�_ID
        line_number,                -- ���הԍ�
        organization_id,            -- �g�DID
        item_id,                    -- OPM�i��ID
        item_code,                  -- �i��
        request_qty,                -- �˗�����
        pallet_quantity,            -- �p���b�g��
        layer_quantity,             -- �i��
        case_quantity,              -- �P�[�X��
        instruct_qty,               -- �w������
        reserved_quantity,          -- ������
        uom_code,                   -- �P��
        designated_production_date, -- �w�萻����
        pallet_qty,                 -- �p���b�g����
        move_num,                   -- �Q�ƈړ��ԍ�
        po_num,                     -- �Q�Ɣ����ԍ�
        first_instruct_qty,         -- ����w������
        shipped_quantity,           -- �o�Ɏ��ѐ���
        ship_to_quantity,           -- ���Ɏ��ѐ���
        weight,                     -- �d��
        capacity,                   -- �e��
        pallet_weight,              -- �p���b�g�d��
        automanual_reserve_class,   -- �����蓮�����敪
        delete_flg,                 -- ����t���O
        warning_date,               -- �x�����t
        warning_class,              -- �x���敪
        created_by,                 -- �쐬��
        creation_date,              -- �쐬��
        last_updated_by,            -- �ŏI�X�V��
        last_update_date,           -- �ŏI�X�V��
        last_update_login,          -- �ŏI�X�V���O�C��
        request_id,                 -- �v��ID
        program_application_id,     -- �R���J�����g�v���O�����A�v���P�[�V����ID
        program_id,                 -- �R���J�����g�v���O����ID
        program_update_date         -- �v���O�����X�V��
      )VALUES(
        gt_m_mov_line_id(ln_data_cnt),                -- �ړ�����ID
        gt_m_mov_hdr_id(ln_data_cnt),                 -- �ړ��w�b�_ID
        gt_m_line_number(ln_data_cnt),                -- ���הԍ�
        gt_m_organization_id(ln_data_cnt),            -- �g�DID
        gt_m_item_id(ln_data_cnt),                    -- OPM�i��ID
        gt_m_item_code(ln_data_cnt),                  -- �i��
        gt_m_request_qty(ln_data_cnt),                -- �˗�����
        gt_m_pallet_quantity(ln_data_cnt),            -- �p���b�g��
        gt_m_layer_quantity(ln_data_cnt),             -- �i��
        gt_m_case_quantity(ln_data_cnt),              -- �P�[�X��
        gt_m_instruct_qty(ln_data_cnt),               -- �w������
        gt_m_reserved_quantity(ln_data_cnt),          -- ������
        gt_m_uom_code(ln_data_cnt),                   -- �P��
        gt_m_designated_pdt_date(ln_data_cnt),        -- �w�萻����
        gt_m_pallet_qty(ln_data_cnt),                 -- �p���b�g����
        gt_m_move_num(ln_data_cnt),                   -- �Q�ƈړ��ԍ�
        gt_m_po_num(ln_data_cnt),                     -- �Q�Ɣ����ԍ�
        gt_m_first_instruct_qty(ln_data_cnt),         -- ����w������
        gt_m_shipped_quantity(ln_data_cnt),           -- �o�Ɏ��ѐ���
        gt_m_ship_to_quantity(ln_data_cnt),           -- ���Ɏ��ѐ���
        gt_m_weight(ln_data_cnt),                     -- �d��
        gt_m_capacity(ln_data_cnt),                   -- �e��
        gt_m_pallet_weight(ln_data_cnt),              -- �p���b�g�d��
        gt_m_automanual_reserve_class(ln_data_cnt),   -- �����蓮�����敪
        gt_m_delete_flg(ln_data_cnt),                 -- ����t���O
        gt_m_warning_date(ln_data_cnt),               -- �x�����t
        gt_m_warning_class(ln_data_cnt),              -- �x���敪
        gt_m_created_by(ln_data_cnt),                 -- �쐬��
        gt_m_creation_date(ln_data_cnt),              -- �쐬��
        gt_m_last_updated_by(ln_data_cnt),            -- �ŏI�X�V��
        gt_m_last_update_date(ln_data_cnt),           -- �ŏI�X�V��
        gt_m_last_update_login(ln_data_cnt),          -- �ŏI�X�V���O�C��
        gt_m_request_id(ln_data_cnt),                 -- �v��ID
        gt_m_program_application_id(ln_data_cnt),     -- �R���J�����g�v���O�����A�v���P�[�V����ID
        gt_m_program_id(ln_data_cnt),                 -- �R���J�����g�v���O����ID
        gt_m_program_update_date(ln_data_cnt)         -- �v���O�����X�V��
      );
--
--
    -- FORALL�Ŏg�p�ł���悤�Ƀ��R�[�h�ϐ��𕪊��i�[����  �����˗��w�b�_
    <<ln_ph_ins_cnt_loop>>
    FOR ln_ph_data_cnt IN 1..gn_ins_data_cnt_ph LOOP
--
debug_log(FND_FILE.LOG,'  �����˗��w�b�_ID = '
                        || gr_requisition_header_tbl(ln_ph_data_cnt).requisition_header_id);
debug_log(FND_FILE.LOG,'  �����˗��ԍ� = '
                        || gr_requisition_header_tbl(ln_ph_data_cnt).po_header_number);
--
        -- �w�b�_�C���T�[�g�p�ϐ��̃C���N�������g
        ln_ph_ins_data_cnt := ln_ph_ins_data_cnt + 1;
--
      gt_rh_requisition_header_id(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).requisition_header_id;-- �����˗��w�b�_ID
      gt_rh_po_header_number(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).po_header_number;     -- �����ԍ�
      gt_rh_status(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).status;               -- �X�e�[�^�X
      gt_rh_vendor_id(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).vendor_id;            -- �d����ID
      gt_rh_vendor_code(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).vendor_code;          -- �d����R�[�h
      gt_rh_vendor_site_id(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).vendor_site_id;       -- �d����T�C�gID
      gt_rh_promised_date(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).promised_date;        -- �[����
      gt_rh_location_id(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).location_id;          -- �[����ID
      gt_rh_location_code(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).location_code;        -- �[����R�[�h
      gt_rh_drop_ship_type(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).drop_ship_type;       -- �����敪
      gt_rh_delivery_code(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).delivery_code;        -- �z����R�[�h
      gt_rh_requested_by_code(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).requested_by_code;    -- �˗��҃R�[�h
      gt_rh_requested_dept_code(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).requested_dept_code;  -- �˗��ҕ����R�[�h
      gt_rh_requested_to_dpt_code(ln_ph_ins_data_cnt) :=
           gr_requisition_header_tbl(ln_ph_data_cnt).requested_to_department_code;-- �˗��敔���R�[�h
      gt_rh_description(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).description;          -- �E�v
      gt_rh_change_flag(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).change_flag;          -- �ύX�t���O
      gt_rh_created_by(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).created_by;            -- �쐬��
      gt_rh_creation_date(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).creation_date;         -- �쐬��
      gt_rh_last_updated_by(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).last_updated_by;       -- �ŏI�X�V��
      gt_rh_last_update_date(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).last_update_date;      -- �ŏI�X�V��
      gt_rh_last_update_login(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).last_update_login;     -- �ŏI�X�V���O�C��
      gt_rh_request_id(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).request_id;            -- �v��ID
      gt_rh_program_application_id(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).program_application_id;-- �A�v���P�[�V����ID
      gt_rh_program_id(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).program_id;            -- �v���O����ID
      gt_rh_program_update_date(ln_ph_ins_data_cnt) :=
                gr_requisition_header_tbl(ln_ph_data_cnt).program_update_date;   -- �v���O�����X�V��
    END LOOP ln_ph_ins_cnt_loop;
--
--
debug_log(FND_FILE.LOG,'  �����˗��w�b�_�o�^���� = ' || TO_CHAR(ln_ph_ins_data_cnt));
--
    -- FORALL�ɂĔ����˗��w�b�_��INSERT����
    FORALL ln_data_cnt IN 1..ln_ph_ins_data_cnt
      INSERT INTO xxpo_requisition_headers(
        requisition_header_id,         -- �����˗��w�b�_ID
        po_header_number,              -- �����ԍ�
        status,                        -- �X�e�[�^�X
        vendor_id,                     -- �d����ID
        vendor_code,                   -- �d����R�[�h
        vendor_site_id,                -- �d����T�C�gID
        promised_date,                 -- �[����
        location_id,                   -- �[����ID
        location_code,                 -- �[����R�[�h
        drop_ship_type,                -- �����敪
        delivery_code,                 -- �z����R�[�h
        requested_by_code,             -- �˗��҃R�[�h
        requested_dept_code,           -- �˗��ҕ����R�[�h
        requested_to_department_code,  -- �˗��敔���R�[�h
        description,                   -- �E�v
        change_flag,                   -- �ύX�t���O
        created_by,                    -- �쐬��
        creation_date,                 -- �쐬��
        last_updated_by,               -- �ŏI�X�V��
        last_update_date,              -- �ŏI�X�V��
        last_update_login,             -- �ŏI�X�V���O�C��
        request_id,                    -- �v��ID
        program_application_id,        -- �A�v���P�[�V����ID
        program_id,                    -- �v���O����ID
        program_update_date            -- �v���O�����X�V��
      )VALUES(
        gt_rh_requisition_header_id(ln_data_cnt),         -- �����˗��w�b�_ID
        gt_rh_po_header_number(ln_data_cnt),              -- �����ԍ�
        gt_rh_status(ln_data_cnt),                        -- �X�e�[�^�X
        gt_rh_vendor_id(ln_data_cnt),                     -- �d����ID
        gt_rh_vendor_code(ln_data_cnt),                   -- �d����R�[�h
        gt_rh_vendor_site_id(ln_data_cnt),                -- �d����T�C�gID
        gt_rh_promised_date(ln_data_cnt),                 -- �[����
        gt_rh_location_id(ln_data_cnt),                   -- �[����ID
        gt_rh_location_code(ln_data_cnt),                 -- �[����R�[�h
        gt_rh_drop_ship_type(ln_data_cnt),                -- �����敪
        gt_rh_delivery_code(ln_data_cnt),                 -- �z����R�[�h
        gt_rh_requested_by_code(ln_data_cnt),             -- �˗��҃R�[�h
        gt_rh_requested_dept_code(ln_data_cnt),           -- �˗��ҕ����R�[�h
        gt_rh_requested_to_dpt_code(ln_data_cnt),         -- �˗��敔���R�[�h
        gt_rh_description(ln_data_cnt),                   -- �E�v
        gt_rh_change_flag(ln_data_cnt),                   -- �ύX�t���O
        gt_rh_created_by(ln_data_cnt),                    -- �쐬��
        gt_rh_creation_date(ln_data_cnt),                 -- �쐬��
        gt_rh_last_updated_by(ln_data_cnt),               -- �ŏI�X�V��
        gt_rh_last_update_date(ln_data_cnt),              -- �ŏI�X�V��
        gt_rh_last_update_login(ln_data_cnt),             -- �ŏI�X�V���O�C��
        gt_rh_request_id(ln_data_cnt),                    -- �v��ID
        gt_rh_program_application_id(ln_data_cnt),        -- �A�v���P�[�V����ID
        gt_rh_program_id(ln_data_cnt),                    -- �v���O����ID
        gt_rh_program_update_date(ln_data_cnt)            -- �v���O�����X�V��
      );
--
    -- FORALL�Ŏg�p�ł���悤�Ƀ��R�[�h�ϐ��𕪊��i�[����  �����˗�����
    <<ln_pl_ins_cnt_loop>>
    FOR ln_pl_data_cnt IN 1..gn_ins_data_cnt_pl LOOP
--
debug_log(FND_FILE.LOG,'  �����˗��w�b�_ID = '
                        || gr_requisition_lines_tbl(ln_pl_data_cnt).requisition_header_id);
debug_log(FND_FILE.LOG,'  �����˗�����ID = '
                        || gr_requisition_lines_tbl(ln_pl_data_cnt).requisition_line_id);
debug_log(FND_FILE.LOG,'  �i�ڃR�[�h = ' || gr_requisition_lines_tbl(ln_pl_data_cnt).item_code);
--
        -- ���׃C���T�[�g�p�ϐ��̃C���N�������g
        ln_pl_ins_data_cnt := ln_pl_ins_data_cnt + 1;
--
      gt_rl_requisition_line_id(ln_pl_ins_data_cnt) :=
              gr_requisition_lines_tbl(ln_pl_data_cnt).requisition_line_id;    -- �����˗�����ID
      gt_rl_requisition_header_id(ln_pl_ins_data_cnt) :=
              gr_requisition_lines_tbl(ln_pl_data_cnt).requisition_header_id;  -- �����˗��w�b�_ID
      gt_rl_requisition_line_number(ln_pl_ins_data_cnt) :=
              gr_requisition_lines_tbl(ln_pl_data_cnt).requisition_line_number;-- ���הԍ�
      gt_rl_item_id(ln_pl_ins_data_cnt) :=
              gr_requisition_lines_tbl(ln_pl_data_cnt).item_id;                -- �i��ID
      gt_rl_item_code(ln_pl_ins_data_cnt) :=
              gr_requisition_lines_tbl(ln_pl_data_cnt).item_code;              -- �i�ڃR�[�h
      gt_rl_pack_quantity(ln_pl_ins_data_cnt) :=
              gr_requisition_lines_tbl(ln_pl_data_cnt).pack_quantity;          -- �݌ɓ���
      gt_rl_requested_quantity(ln_pl_ins_data_cnt) :=
              gr_requisition_lines_tbl(ln_pl_data_cnt).requested_quantity;     -- �˗�����
      gt_rl_requested_quantity_uom(ln_pl_ins_data_cnt) :=
              gr_requisition_lines_tbl(ln_pl_data_cnt).requested_quantity_uom; -- �˗����ʒP�ʃR�[�h
      gt_rl_requested_date(ln_pl_ins_data_cnt) :=
              gr_requisition_lines_tbl(ln_pl_data_cnt).requested_date;         -- ���t�w��
      gt_rl_ordered_quantity(ln_pl_ins_data_cnt) :=
              gr_requisition_lines_tbl(ln_pl_data_cnt).ordered_quantity;       -- ��������
      gt_rl_description(ln_pl_ins_data_cnt) :=
              gr_requisition_lines_tbl(ln_pl_data_cnt).description;            -- �E�v
      gt_rl_cancelled_flg(ln_pl_ins_data_cnt) :=
              gr_requisition_lines_tbl(ln_pl_data_cnt).cancelled_flg;          -- ����t���O
      gt_rl_created_by(ln_pl_ins_data_cnt) :=
              gr_requisition_lines_tbl(ln_pl_data_cnt).created_by;             -- �쐬��
      gt_rl_creation_date(ln_pl_ins_data_cnt) :=
              gr_requisition_lines_tbl(ln_pl_data_cnt).creation_date;          -- �쐬��
      gt_rl_last_updated_by(ln_pl_ins_data_cnt) :=
              gr_requisition_lines_tbl(ln_pl_data_cnt).last_updated_by;        -- �ŏI�X�V��
      gt_rl_last_update_date(ln_pl_ins_data_cnt) :=
              gr_requisition_lines_tbl(ln_pl_data_cnt).last_update_date;       -- �ŏI�X�V��
      gt_rl_last_update_login(ln_pl_ins_data_cnt) :=
              gr_requisition_lines_tbl(ln_pl_data_cnt).last_update_login;      -- �ŏI�X�V���O�C��
      gt_rl_request_id(ln_pl_ins_data_cnt) :=
              gr_requisition_lines_tbl(ln_pl_data_cnt).request_id;             -- �v��ID
      gt_rl_program_application_id(ln_pl_ins_data_cnt) :=
              gr_requisition_lines_tbl(ln_pl_data_cnt).program_application_id; -- �A�v���P�[�V����ID
      gt_rl_program_id(ln_pl_ins_data_cnt) :=
              gr_requisition_lines_tbl(ln_pl_data_cnt).program_id;             -- �v���O����ID
      gt_rl_program_update_date(ln_pl_ins_data_cnt) :=
              gr_requisition_lines_tbl(ln_pl_data_cnt).program_update_date;    -- �v���O�����X�V��
    END LOOP ln_pl_ins_cnt_loop;
--
--
debug_log(FND_FILE.LOG,'  �����˗����דo�^���� = ' || TO_CHAR(ln_pl_ins_data_cnt));
--
    -- FORALL�ɂĔ����˗����ׂ�INSERT����
    FORALL ln_data_cnt IN 1..ln_pl_ins_data_cnt
      INSERT INTO xxpo_requisition_lines(
        requisition_line_id,    -- �����˗�����ID
        requisition_header_id,  -- �����˗��w�b�_ID
        requisition_line_number,-- ���הԍ�
        item_id,                -- �i��ID
        item_code,              -- �i�ڃR�[�h
        pack_quantity,          -- �݌ɓ���
        requested_quantity,     -- �˗�����
        requested_quantity_uom, -- �˗����ʒP�ʃR�[�h
        requested_date,         -- ���t�w��
        ordered_quantity,       -- ��������
        description,            -- �E�v
        cancelled_flg,          -- ����t���O
        created_by,             -- �쐬��
        creation_date,          -- �쐬��
        last_updated_by,        -- �ŏI�X�V��
        last_update_date,       -- �ŏI�X�V��
        last_update_login,      -- �ŏI�X�V���O�C��
        request_id,             -- �v��ID
        program_application_id, -- �A�v���P�[�V����ID
        program_id,             -- �v���O����ID
        program_update_date     -- �v���O�����X�V��
      )VALUES(
        gt_rl_requisition_line_id(ln_data_cnt),    -- �����˗�����ID
        gt_rl_requisition_header_id(ln_data_cnt),  -- �����˗��w�b�_ID
        gt_rl_requisition_line_number(ln_data_cnt),-- ���הԍ�
        gt_rl_item_id(ln_data_cnt),                -- �i��ID
        gt_rl_item_code(ln_data_cnt),              -- �i�ڃR�[�h
        gt_rl_pack_quantity(ln_data_cnt),          -- �݌ɓ���
        gt_rl_requested_quantity(ln_data_cnt),     -- �˗�����
        gt_rl_requested_quantity_uom(ln_data_cnt), -- �˗����ʒP�ʃR�[�h
        gt_rl_requested_date(ln_data_cnt),         -- ���t�w��
        gt_rl_ordered_quantity(ln_data_cnt),       -- ��������
        gt_rl_description(ln_data_cnt),            -- �E�v
        gt_rl_cancelled_flg(ln_data_cnt),          -- ����t���O
        gt_rl_created_by(ln_data_cnt),             -- �쐬��
        gt_rl_creation_date(ln_data_cnt),          -- �쐬��
        gt_rl_last_updated_by(ln_data_cnt),        -- �ŏI�X�V��
        gt_rl_last_update_date(ln_data_cnt),       -- �ŏI�X�V��
        gt_rl_last_update_login(ln_data_cnt),      -- �ŏI�X�V���O�C��
        gt_rl_request_id(ln_data_cnt),             -- �v��ID
        gt_rl_program_application_id(ln_data_cnt), -- �A�v���P�[�V����ID
        gt_rl_program_id(ln_data_cnt),             -- �v���O����ID
        gt_rl_program_update_date(ln_data_cnt)     -- �v���O�����X�V��
      );
--
debug_log(FND_FILE.LOG,'  �󒍖��׍X�V����l = ' || gn_upd_data_cnt_ol);
--
    -- FORALL�ɂĎ󒍖��ׂ�UPDATE����
    FORALL ln_data_cnt IN 1..gn_upd_data_cnt_ol
      UPDATE xxwsh_order_lines_all xola
      SET   xola.move_number            = gt_ol_move_number(ln_data_cnt),       -- �ړ�No
            xola.po_number              = gt_ol_po_number(ln_data_cnt),         -- ����No
            xola.last_updated_by        = gt_ol_last_updated_by(ln_data_cnt),   -- �ŏI�X�V��
            xola.last_update_date       = gt_ol_last_update_date(ln_data_cnt),  -- �ŏI�X�V��
            xola.last_update_login      = gt_ol_last_update_login(ln_data_cnt), -- �ŏI�X�V���O�C��
            xola.request_id             = gt_ol_request_id(ln_data_cnt),        -- �v��ID
            xola.program_application_id = gt_ol_program_application_id(ln_data_cnt),
                                                                            --�A�v���P�[�V����ID
            xola.program_id             = gt_ol_program_id(ln_data_cnt),        -- �v���O����ID
            xola.program_update_date    = gt_ol_program_update_date(ln_data_cnt)-- �v���O�����X�V��
      WHERE xola.shipping_item_code   = gt_ol_shipping_item_code(ln_data_cnt)   -- �i�ڃR�[�h
        AND EXISTS
            (SELECT 'REQUEST_NO'
             FROM  xxwsh_order_headers_all xoha
             WHERE xoha.order_header_id = xola.order_header_id
               AND xoha.latest_external_flag   = gv_cons_flg_y                  -- �ŐV�t���O 'Y'
               AND xoha.request_no = gt_ol_request_no(ln_data_cnt));            -- �˗�No
--
--
--
debug_log(FND_FILE.LOG,'  �ړ����׍X�V����l = ' || gn_upd_data_cnt_ml);
--
    -- FORALL�ɂĈړ��˗�/�w�����ׂ�UPDATE����
    FORALL ln_data_cnt IN 1..gn_upd_data_cnt_ml
      UPDATE xxinv_mov_req_instr_lines xmril
      SET   xmril.move_num               = gt_ml_move_num(ln_data_cnt),          -- �Q�ƈړ��ԍ�
            xmril.po_num                 = gt_ml_po_num(ln_data_cnt),            -- �Q�Ɣ����ԍ�
            xmril.last_updated_by        = gt_ml_last_updated_by(ln_data_cnt),   -- �ŏI�X�V��
            xmril.last_update_date       = gt_ml_last_update_date(ln_data_cnt),  -- �ŏI�X�V��
            xmril.last_update_login      = gt_ml_last_update_login(ln_data_cnt), -- �ŏI�X�V���O�C��
            xmril.request_id             = gt_ml_request_id(ln_data_cnt),        -- �v��ID
            xmril.program_application_id = gt_ml_program_application_id(ln_data_cnt),
                                                                              --�A�v���P�[�V����ID
            xmril.program_id             = gt_ml_program_id(ln_data_cnt),        -- �v���O����ID
            xmril.program_update_date    = gt_ml_program_update_date(ln_data_cnt)-- �v���O�����X�V��
      WHERE xmril.item_code   = gt_ml_item_code(ln_data_cnt)                     -- �i�ڃR�[�h
        AND EXISTS
            (SELECT 'MOV_NUM'
             FROM  xxinv_mov_req_instr_headers xmrih
             WHERE xmrih.mov_hdr_id = xmril.mov_hdr_id
               AND xmrih.mov_num = gt_ml_mov_num(ln_data_cnt));                  -- �ړ��ԍ�
--
debug_log(FND_FILE.LOG,'(C-14)' || cv_prg_name || ' End�����');
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
  END insert_tables;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_action_type           IN         VARCHAR2,   -- �������
    iv_req_mov_no            IN         VARCHAR2,   -- �˗�/�ړ�No
    iv_deliver_from          IN         VARCHAR2,   -- �o�Ɍ��ۊǏꏊ
    iv_deliver_type          IN         VARCHAR2,   -- �o�Ɍ`��
    iv_object_date_from      IN         VARCHAR2,   -- �Ώۊ���From
    iv_object_date_to        IN         VARCHAR2,   -- �Ώۊ���To
    iv_shipped_date          IN         VARCHAR2,   -- �o�ɓ��w��
    iv_arrival_date          IN         VARCHAR2,   -- �����w��
    iv_instruction_post_code IN         VARCHAR2,   -- �w�������w��
    ov_errbuf               OUT NOCOPY  VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY  VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY  VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_ret_code VARCHAR2(1);     -- ���^�[���E�R�[�h
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
    lc_out_param            VARCHAR2(1000);   -- ���̓p�����[�^�̏������ʃ��|�[�g�o�͗p
    ln_get_data_loop_cnt    NUMBER := 0;      -- C-4�f�[�^���[�v�J�E���^
    ln_get_zaiko_loop_cnt   NUMBER := 0;      -- �݌ɕ�[���擾���[�v�J�E���^
    ln_max_cnt              NUMBER := 0;      -- ���[�v�ő�J�E���g
    lv_move_number          xxwsh_order_lines_all.move_number%TYPE;
    lv_po_number            xxwsh_order_lines_all.po_number%TYPE;
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
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
--
debug_log(FND_FILE.LOG,'(Submain)' || cv_prg_name || ' Start���');
--
    -- ���̓p�����[�^���������ďo��
    lc_out_param := gv_cons_input_param || gv_msg_part ||
                    iv_action_type      || gv_msg_pnt || iv_req_mov_no     || gv_msg_pnt ||
                    iv_deliver_from     || gv_msg_pnt || iv_deliver_type   || gv_msg_pnt ||
                    iv_object_date_from || gv_msg_pnt || iv_object_date_to || gv_msg_pnt ||
                    iv_shipped_date     || gv_msg_pnt || iv_arrival_date   || gv_msg_pnt ||
                    iv_instruction_post_code;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_param);
--
    -- ===============================================
    -- C-1  �p�����[�^�`�F�b�N check_parameter
    -- ===============================================
    check_parameter(iv_action_type,           -- �������
                    iv_req_mov_no,            -- �˗�/�ړ�No
                    iv_deliver_from,          -- �o�Ɍ��ۊǏꏊ
                    iv_deliver_type,          -- �o�Ɍ`��
                    iv_object_date_from,      -- �Ώۊ���From
                    iv_object_date_to,        -- �Ώۊ���To
                    iv_shipped_date,          -- �o�ɓ��w��
                    iv_arrival_date,          -- �����w��
                    iv_instruction_post_code, -- �w�������w��
                    lv_errbuf,             -- �G���[�E���b�Z�[�W           --# �Œ� #
                    lv_retcode,            -- ���^�[���E�R�[�h             --# �Œ� #
                    lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[����
    IF (lv_retcode = gv_status_error) THEN
--
      RAISE global_process_expt;
--
    -- ���[�j���O����
    ELSIF (lv_retcode = gv_status_warn) THEN
--
      ov_retcode := gv_status_warn;
--
    END IF;
--
    -- ===============================================
    -- C-2  �v���t�@�C���l�擾 get_profile
    -- ===============================================
    get_profile(lv_errbuf,             -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,            -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- �G���[����
    IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--
    -- ���[�j���O����
    ELSIF (lv_retcode = gv_status_warn) THEN
--
      ov_retcode := gv_status_warn;
--
    END IF;
--
    -- ===============================================
    -- C-3   �p�[�W���� purge_table
    -- ===============================================
    purge_table(iv_action_type,        -- �������
                lv_errbuf,             -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,            -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- �G���[����
    IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--
    -- ���[�j���O����
    ELSIF (lv_retcode = gv_status_warn) THEN
--
      ov_retcode := gv_status_warn;
--
    END IF;
--
--
    -- ===============================================
    -- C-4   ��񒊏o get_data
    -- ===============================================
    get_data( iv_action_type,        -- �������
              iv_req_mov_no,         -- �˗�/�ړ�No
              iv_deliver_from,       -- �o�Ɍ��ۊǏꏊ
              iv_deliver_type,       -- �o�Ɍ`��
              iv_object_date_from,   -- �Ώۊ���From
              iv_object_date_to,     -- �Ώۊ���To
              iv_arrival_date,       -- �����w��
              lv_errbuf,             -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,            -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- �G���[����
    IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--
    -- ���[�j���O����
    ELSIF (lv_retcode = gv_status_warn) THEN
--
      ov_retcode := gv_status_warn;
--
    END IF;
--
--
    <<get_data_loop>> -- ���o���[�v
    FOR ln_get_data_loop_cnt IN 1..gn_target_cnt LOOP
--
      -- ===============================================
      -- C-5   ���[���擾 get_rule
      -- ===============================================
      get_rule(ln_get_data_loop_cnt,      -- �����J�E���^
               iv_action_type,            -- �������
               iv_arrival_date,           -- �����w��
               lv_errbuf,                 -- �G���[�E���b�Z�[�W           --# �Œ� #
               lv_retcode,                -- ���^�[���E�R�[�h             --# �Œ� #
               lv_errmsg);                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[����
      IF (lv_retcode = gv_status_error) THEN
--
debug_log(FND_FILE.LOG,'(submain)get_data_loop_out' || to_char(ln_get_data_loop_cnt));
debug_log(FND_FILE.LOG,'  ' || lv_ret_code);
debug_log(FND_FILE.LOG,'  ' || lv_errmsg);
debug_log(FND_FILE.LOG,'  ' || lv_errbuf);
          RAISE global_process_expt;
--
      -- �x������
      ELSIF (lv_retcode = gv_status_warn) THEN
--
debug_log(FND_FILE.LOG,'(submain)get_data_loop_out' || to_char(ln_get_data_loop_cnt));
debug_log(FND_FILE.LOG,'  ' || lv_ret_code);
debug_log(FND_FILE.LOG,'  ' || lv_errmsg);
debug_log(FND_FILE.LOG,'  ' || lv_errbuf);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errbuf);
          ov_retcode := gv_status_warn;
--
      END IF;
--
    END LOOP get_data_loop;
--
--
    -- ������ʂ��u�o�ׁv�̏ꍇ
    IF (iv_action_type = gv_cons_t_deliv) THEN
      -- ===============================================
      -- C-6   ���ԃe�[�u���o�^(�o��) ins_ints_table
      -- ===============================================
      ins_ints_table(lv_errbuf,             -- �G���[�E���b�Z�[�W           --# �Œ� #
                     lv_retcode,            -- ���^�[���E�R�[�h             --# �Œ� #
                     lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      -- �G���[����
      IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
      -- ���[�j���O����
      ELSIF (lv_retcode = gv_status_warn) THEN
--
        ov_retcode := gv_status_warn;
--
        END IF;
--
    -- ������ʂ��u�ړ��v�̏ꍇ
    ELSIF (iv_action_type = gv_cons_t_move) THEN
      -- ===============================================
      -- C-7   ���ԃe�[�u���o�^(�ړ�) ins_intm_table
      -- ===============================================
      ins_intm_table(lv_errbuf,             -- �G���[�E���b�Z�[�W           --# �Œ� #
                     lv_retcode,            -- ���^�[���E�R�[�h             --# �Œ� #
                     lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      -- �G���[����
      IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
      -- ���[�j���O����
      ELSIF (lv_retcode = gv_status_warn) THEN
--
        ov_retcode := gv_status_warn;
--
      END IF;
--
    END IF;
--
--
    -- ������ʂ��u�o�ׁv�̏ꍇ
    IF (iv_action_type = gv_cons_t_deliv) THEN
      -- ===============================================
      -- C-8   ���ԃe�[�u�����o(�o��) get_ints_data
      -- ===============================================
      get_ints_data(lv_errbuf,             -- �G���[�E���b�Z�[�W           --# �Œ� #
                    lv_retcode,            -- ���^�[���E�R�[�h             --# �Œ� #
                    lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      -- �G���[����
      IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
      -- ���[�j���O����
      ELSIF (lv_retcode = gv_status_warn) THEN
--
        ov_retcode := gv_status_warn;
--
      END IF;
--
      ln_max_cnt := gn_target_cnt_deliv;
--
    -- ������ʂ��u�ړ��v�̏ꍇ
    ELSE
      -- ===============================================
      -- C-9   ���ԃe�[�u�����o(�ړ�) get_intm_data
      -- ===============================================
      get_intm_data(lv_errbuf,             -- �G���[�E���b�Z�[�W           --# �Œ� #
                    lv_retcode,            -- ���^�[���E�R�[�h             --# �Œ� #
                    lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      -- �G���[����
      IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
      -- ���[�j���O����
      ELSIF (lv_retcode = gv_status_warn) THEN
--
        ov_retcode := gv_status_warn;
--
      END IF;
--
      ln_max_cnt := gn_target_cnt_move;
--
    END IF;
--
--
    <<get_zaiko_loop>> -- �݌ɕ�[���擾���[�v
    FOR ln_get_zaiko_loop_cnt IN 1..ln_max_cnt LOOP
--
      -- �ړ��ԍ��A�����ԍ��̏�����
      lv_move_number := NULL;
      lv_po_number   := NULL;
--
      -- �݌ɕ�[���[�����u�ړ��v�ł���A������ʂ��u�o�ׁv�܂��́u�ړ��v
      IF (((iv_action_type = gv_cons_t_deliv)
           AND
          (gr_deliv_data_tbl(ln_get_zaiko_loop_cnt).stock_rep_rule = gv_cons_rule_move))
        OR
         ((iv_action_type = gv_cons_t_move)
           AND
          (gr_move_data_tbl(ln_get_zaiko_loop_cnt).stock_rep_rule = gv_cons_rule_move)))
      THEN
        -- ===============================================
        -- C-10  �ړ��˗�/�w���o�^ regi_move_data
        -- ===============================================
        regi_move_data(ln_get_zaiko_loop_cnt,     -- �����J�E���^
                       iv_action_type,            -- �������
                       iv_shipped_date,           -- �o�ɓ��w��
                       iv_arrival_date,           -- �����w��
                       iv_instruction_post_code,  -- �w�������w��
                       lv_errbuf,                 -- �G���[�E���b�Z�[�W           --# �Œ� #
                       lv_ret_code,                -- ���^�[���E�R�[�h             --# �Œ� #
                       lv_errmsg);                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- �G���[����
        IF (lv_retcode = gv_status_error) THEN
--
debug_log(FND_FILE.LOG,'(submain)regi_move_data  ' || to_char(ln_get_zaiko_loop_cnt) || '����');
debug_log(FND_FILE.LOG,'  ' || lv_ret_code);
debug_log(FND_FILE.LOG,'  ' || lv_errmsg);
debug_log(FND_FILE.LOG,'  ' || lv_errbuf);
--
          RAISE global_process_expt;
--
        -- �x������(���O���o�͂��A�����R�[�h�ցj
        ELSIF (lv_retcode = gv_status_warn) THEN
--
          ov_retcode := gv_status_warn;
--
debug_log(FND_FILE.LOG,'(submain)regi_move_data  ' || to_char(ln_get_zaiko_loop_cnt) || '����');
debug_log(FND_FILE.LOG,'  ' || lv_ret_code);
debug_log(FND_FILE.LOG,'  ' || lv_errmsg);
debug_log(FND_FILE.LOG,'  ' || lv_errbuf);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errbuf);
--
        ELSE
--
          lv_move_number := gr_move_header_tbl(gn_ins_data_cnt_mh).mov_num;
--
        END IF;
--
--
      -- �݌ɕ�[���[�����u�����v
      ELSE
        -- ===============================================
        -- C-11  �����˗��o�^ regi_po_data
        -- ===============================================
        regi_poreq_data(ln_get_zaiko_loop_cnt,     -- �����J�E���^
                        iv_action_type,            -- �������
                        iv_shipped_date,           -- �o�ɓ��w��
                        iv_arrival_date,           -- �����w��
                        iv_instruction_post_code,  -- �w�������w��
                        lv_errbuf,                 -- �G���[�E���b�Z�[�W           --# �Œ� #
                        lv_ret_code,               -- ���^�[���E�R�[�h             --# �Œ� #
                        lv_errmsg);                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- �G���[����
        IF (lv_retcode = gv_status_error) THEN
--
debug_log(FND_FILE.LOG,'(submain)regi_poreq_data  ' || to_char(ln_get_zaiko_loop_cnt) || '����');
debug_log(FND_FILE.LOG,'  ' || lv_ret_code);
debug_log(FND_FILE.LOG,'  ' || lv_errmsg);
debug_log(FND_FILE.LOG,'  ' || lv_errbuf);
--
          RAISE global_process_expt;
--
        -- �x������(���O���o�͂��A�����R�[�h�ցj
        ELSIF (lv_retcode = gv_status_warn) THEN
--
          ov_retcode := gv_status_warn;
--
debug_log(FND_FILE.LOG,'(submain)regi_poreq_data  ' || to_char(ln_get_zaiko_loop_cnt) || '����');
debug_log(FND_FILE.LOG,'  ' || lv_ret_code);
debug_log(FND_FILE.LOG,'  ' || lv_errmsg);
debug_log(FND_FILE.LOG,'  ' || lv_errbuf);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errbuf);
--
        ELSE
--
          lv_po_number := gr_requisition_header_tbl(gn_ins_data_cnt_ph).po_header_number;
--
        END IF;
--
      END IF;
--
      -- ������ʂ��u�o�ׁv�̏ꍇ
      IF ((iv_action_type = gv_cons_t_deliv) AND (lv_ret_code = gv_status_normal)) THEN
        -- ===============================================
        -- C-12  �󒍖��׍X�V regi_order_detail
        -- ===============================================
        regi_order_detail(ln_get_zaiko_loop_cnt, -- �����J�E���^
                          lv_move_number,        -- �ړ��ԍ�
                          lv_po_number,          -- �����ԍ�
                          lv_errbuf,             -- �G���[�E���b�Z�[�W           --# �Œ� #
                          lv_retcode,            -- ���^�[���E�R�[�h             --# �Œ� #
                          lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        -- �G���[����
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- ���[�j���O����
        ELSIF (lv_retcode = gv_status_warn) THEN
--
          ov_retcode := gv_status_warn;
--
        END IF;
--
--
      -- ������ʂ��u�ړ��v�̏ꍇ
      ELSIF ((iv_action_type = gv_cons_t_move) AND (lv_ret_code = gv_status_normal)) THEN
        -- ===============================================
        -- C-13  �ړ��w��/�w�����׍X�V regi_move_detail
        -- ===============================================
        regi_move_detail(ln_get_zaiko_loop_cnt, -- �����J�E���^
                        lv_move_number,         -- �ړ��ԍ�
                        lv_po_number,           -- �����ԍ�
                        lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                        lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                        lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        -- �G���[����
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- ���[�j���O����
        ELSIF (lv_retcode = gv_status_warn) THEN
--
          ov_retcode := gv_status_warn;
--
        END IF;
--
      END IF;
--
    END LOOP get_zaiko_loop;
--
--
    -- ======================================================
    -- C-15  �d�ʗe�όv�Z/�ύڌ����Z�o calc_weight_capacity
    -- ======================================================
    calc_weight_capacity(iv_arrival_date,        -- �����w��
                         lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                         lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                         lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- �G���[����
    IF (lv_retcode = gv_status_error) THEN
--
      RAISE global_process_expt;
--
    -- ���[�j���O����
    ELSIF (lv_retcode = gv_status_warn) THEN
--
      ov_retcode := gv_status_warn;
--
    END IF;
--
--
    -- ===============================================
    -- C-14  �o�^�X�V���� insert_tables
    -- ===============================================
    insert_tables(lv_errbuf,             -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,            -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- �G���[����
    IF (lv_retcode = gv_status_error) THEN
--
      RAISE global_process_expt;
--
    -- ���[�j���O����
    ELSIF (lv_retcode = gv_status_warn) THEN
--
      ov_retcode := gv_status_warn;
--
    END IF;
--
--
debug_log(FND_FILE.LOG,'(Submain)' || cv_prg_name || ' End�����');
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
    errbuf                   OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                  OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h    --# �Œ� #
    iv_action_type           IN         VARCHAR2,   -- �������
    iv_req_mov_no            IN         VARCHAR2,   -- �˗�/�ړ�No
    iv_deliver_from          IN         VARCHAR2,   -- �o�Ɍ�
    iv_deliver_type          IN         VARCHAR2,   -- �o�Ɍ`��
    iv_object_date_from      IN         VARCHAR2,   -- �Ώۊ���From
    iv_object_date_to        IN         VARCHAR2,   -- �Ώۊ���To
    iv_shipped_date          IN         VARCHAR2,   -- �o�ɓ��w��
    iv_arrival_date          IN         VARCHAR2,   -- �����w��
    iv_instruction_post_code IN         VARCHAR2    -- �w�������w��
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
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
  -- �f�o�b�O�o�͗v�۔��f
  set_debug_switch;
debug_log(FND_FILE.LOG,'(Main)' || cv_prg_name || ' Start���');
--
--
--###########################  �Œ蕔 START   #####################################################
--
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
    -- WHO�J�������̎擾
    gn_login_user       := FND_GLOBAL.LOGIN_ID;         -- ���O�C��ID
    gn_created_by       := FND_GLOBAL.USER_ID;          -- ���O�C�����[�UID
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;  -- �v��ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID; -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;  -- �R���J�����g�E�v���O����ID
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;   -- �Ώی���
    gn_normal_cnt := 0;   -- ���팏��
    gn_warn_cnt   := 0;   -- �x������
    gn_error_cnt  := 0;   -- �G���[����
--
    submain(
      iv_action_type,           -- �������
      iv_req_mov_no,            -- �˗�/�ړ�No
      iv_deliver_from,          -- �o�Ɍ�
      iv_deliver_type,          -- �o�Ɍ`��
      iv_object_date_from,      -- �Ώۊ���From
      iv_object_date_to,        -- �Ώۊ���To
      iv_shipped_date,          -- �o�ɓ��w��
      iv_arrival_date,          -- �����w��
      iv_instruction_post_code, -- �w�������w��
      lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- ���������̃Z�b�g
    -- ���������͒��ԃe�[�u���̑�����
    IF (iv_action_type = gv_cons_t_deliv) THEN
      gn_target_cnt := gn_target_cnt_deliv;
    ELSE
      gn_target_cnt := gn_target_cnt_move;
    END IF;
    -- ���������̓w�b�_�e�[�u���̏o�͌���
    IF (lv_retcode = gv_status_error) THEN
      gn_normal_cnt := 0;
    ELSE
      gn_normal_cnt   := gn_ins_data_cnt_mh + gn_ins_data_cnt_ph;
    END IF;
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
      gn_error_cnt  := gn_error_cnt + 1;
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
--
debug_log(FND_FILE.LOG,'(C-xx)' || cv_prg_name || ' End�����');
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
END XXWSH920003C;
/
