create or replace PACKAGE BODY XXWSH920008C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920008C(body)
 * Description      : ���Y����(�����A�z��)
 * MD.050           : �o�ׁE����/�z�ԁF���Y�������ʁi�o�ׁE�ړ��������j T_MD050_BPO_920
 * MD.070           : �o�ׁE����/�z�ԁF���Y�������ʁi�o�ׁE�ړ��������j T_MD070_BPO_92J
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_can_enc_in_time_qty2 �L�����x�[�X�����\���Z�oAPI
 *  get_can_enc_qty2       �����\���Z�o����
 *  check_sql_pattern      �����p�^�[���`�F�b�N
 *  check_parameter        A-1  ���̓p�����[�^�`�F�b�N
 *  get_item_code_list     A-2  �i�ڃ��X�g�擾
 *  fwd_sql_create         A-3  �o�חpSQL���쐬
 *  get_demand_inf_fwd     A-4  ���v���擾(�o��)
 *  mov_sql_create         A-5  �ړ��pSQL���쐬
 *  get_demand_inf_mov     A-6  ���v���擾(�ړ�)
 *  get_supply_inf         A-7  �������擾
 *  check_lot_allot        A-8  ���b�g�����`�F�b�N
 *  make_allot_inf         A-9  �������쐬����
 *  regist_allot_inf       A-10 �������o�^����
 *  make_line_allot        A-11 ���׈������쐬����
 *  update_line_inf        A-12 ���׏��X�V����
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/20   1.0   SCS�k����         ����쐬
 *  2008/11/28   1.1   Oracle �k�������v �{�ԏ�Q246�Ή�
 *  2008/11/29   1.2   SCS�{�c           ���b�N�Ή�
 *  2008/12/02   1.3   SCS��r           �{�ԏ�Q#251�Ή��i�����ǉ��j
 *  2008/12/15   1.4   SCS�ɓ�           �{�ԏ�Q#645�Ή��i�����\���擾������\���������ѓ��ɕύX�j
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
  lock_expt              EXCEPTION;     -- ���b�N(�r�W�[)�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'XXWSH920008C';        -- �p�b�P�[�W��
  --���b�Z�[�W�ԍ�
  gv_msg_92a_002       CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10033';    -- �p�����[�^������
  gv_msg_92a_003       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-12857';    -- �p�����[�^����
  gv_msg_92a_004       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-12953';    -- FromTo�t�]
  gv_msg_92a_005       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13306';    -- ���b�N�r�W�[
  gv_msg_92a_006       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-12858';    -- ���ʊ֐��G���[
  gv_msg_92a_007       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-12854';    -- ���b�g�t�]�G���[
  gv_msg_92a_008       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-12855';    -- �N�x�s���G���[
  gv_msg_92a_009       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11222';    -- �p�����[�^����
  gv_msg_92a_010       CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10604';    -- �P�[�X�����G���[
  --�萔
  gv_cons_msg_kbn_wsh  CONSTANT VARCHAR2(5)   := 'XXWSH';              -- ���b�Z�[�W�敪XXWSH
  gv_cons_msg_kbn_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN';              -- ���b�Z�[�W�敪XXCMN
  gv_cons_item_class   CONSTANT VARCHAR2(100) := '���i�敪';
  gv_cons_deliv_from   CONSTANT VARCHAR2(100) := '�o�ɓ�From';
  gv_cons_deliv_to     CONSTANT VARCHAR2(100) := '�o�ɓ�To';
  gv_cons_item_no      CONSTANT VARCHAR2(100) := '�i�ڃR�[�h';
  gv_cons_t_move       CONSTANT VARCHAR2(1)   := '5';                  -- '�ړ��w��'(�������)
  gv_cons_t_deliv      CONSTANT VARCHAR2(1)   := '1';                  -- '�o�׈˗�'
  gv_cons_biz_t_move   CONSTANT VARCHAR2(2)   := '20';                 -- '�ړ��w��'(�����^�C�v)
  gv_cons_biz_t_deliv  CONSTANT VARCHAR2(2)   := '10';                 -- '�o�׈˗�'
  gv_cons_input_param  CONSTANT VARCHAR2(100) := '���̓p�����[�^�l';   -- '���̓p�����[�^�l'
  gv_cons_flg_yes      CONSTANT VARCHAR2(1)   := 'Y';                  -- �t���O 'Y'
  gv_cons_flg_no       CONSTANT VARCHAR2(1)   := 'N';                  -- �t���O 'N'
  gv_cons_notif_status CONSTANT VARCHAR2(3)   := '40';                 -- �u�m��ʒm�ρv
  gv_cons_status       CONSTANT VARCHAR2(2)   := '03';                 -- �u���ߍς݁v
  gv_cons_lot_ctl      CONSTANT VARCHAR2(1)   := '1';                  -- �u���b�g�Ǘ��i�v
  gv_cons_item_product CONSTANT VARCHAR2(1)   := '5';                  -- �u���i�v
  gv_cons_move_type    CONSTANT VARCHAR2(1)   := '1';                  -- �u�ϑ�����v
  gv_cons_mov_sts_c    CONSTANT VARCHAR2(2)   := '03';                 -- �u�������v
  gv_cons_mov_sts_e    CONSTANT VARCHAR2(2)   := '02';                 -- �u�˗��ρv
  gv_cons_order_lines  CONSTANT VARCHAR2(50)  := '�󒍖��׃A�h�I��';
  gv_cons_instr_lines  CONSTANT VARCHAR2(50)  := '�ړ��˗�/�w������(�A�h�I��)';
  gv_cons_wrn_reversal CONSTANT VARCHAR2(2)   := '30';                 -- �u���b�g�t�]�v
  gv_cons_wrn_fresh    CONSTANT VARCHAR2(2)   := '40';                 -- �u�N�x�s���v
  gv_cons_error        CONSTANT VARCHAR2(1)   := '1';                  -- ���ʊ֐��ł̃G���[
  gv_cons_no_judge     CONSTANT VARCHAR2(2)   := '10';                 -- �u������v
  gv_cons_am_auto      CONSTANT VARCHAR2(2)   := '10';                 -- �u���������v
  gv_cons_rec_type     CONSTANT VARCHAR2(2)   := '10';                 -- �u�w���v
  gv_cons_id_drink     CONSTANT VARCHAR2(1)   := '2';                  -- ���i�敪�E�h�����N
  gv_cons_id_leaf      CONSTANT VARCHAR2(1)   := '1';                  -- ���i�敪�E���[�t
  gv_cons_deliv_fm     CONSTANT VARCHAR2(50)  := '�o�׌�';             -- �o�׌�
  gv_cons_deliv_tp     CONSTANT VARCHAR2(50)  := '�o�׌`��';           -- �o�׌`��^
  gv_cons_number       CONSTANT VARCHAR2(50)  := '���l';               -- ���l^
  --�g�[�N��
  gv_tkn_parm_name     CONSTANT VARCHAR2(15)  := 'PARM_NAME';          -- �p�����[�^
  gv_tkn_param_name    CONSTANT VARCHAR2(15)  := 'PARAM_NAME';         -- �p�����[�^
  gv_tkn_parameter     CONSTANT VARCHAR2(15)  := 'PARAMETER';          -- �p�����[�^��
  gv_tkn_type          CONSTANT VARCHAR2(15)  := 'TYPE';               -- �����^�C�v
  gv_tkn_table         CONSTANT VARCHAR2(15)  := 'TABLE';              -- �e�[�u��
  gv_tkn_err_code      CONSTANT VARCHAR2(15)  := 'ERR_CODE';           -- �G���[�R�[�h
  gv_tkn_err_msg       CONSTANT VARCHAR2(15)  := 'ERR_MSG';            -- �G���[���b�Z�[�W
  gv_tkn_ship_type     CONSTANT VARCHAR2(15)  := 'SHIP_TYPE';          -- �z����
  gv_tkn_item          CONSTANT VARCHAR2(15)  := 'ITEM';               -- �i��
  gv_tkn_lot           CONSTANT VARCHAR2(15)  := 'LOT';                -- ���b�gNo
  gv_tkn_request_type  CONSTANT VARCHAR2(15)  := 'REQUEST_TYPE';       -- �˗�No/�ړ��ԍ�_�敪
  gv_tkn_p_date        CONSTANT VARCHAR2(15)  := 'P_DATE';             -- ������
  gv_tkn_use_by_date   CONSTANT VARCHAR2(15)  := 'USE_BY_DATE';        -- �ܖ�����
  gv_tkn_fix_no        CONSTANT VARCHAR2(15)  := 'FIX_NO';             -- �ŗL�L��
  gv_tkn_request_no    CONSTANT VARCHAR2(15)  := 'REQUEST_NO';         -- �˗�No
  gv_tkn_item_no       CONSTANT VARCHAR2(15)  := 'ITEM_NO';            -- �i�ڃR�[�h
  gv_tkn_reverse_date  CONSTANT VARCHAR2(15)  := 'REVDATE';            -- �t�]���t
  gv_tkn_arrival_date  CONSTANT VARCHAR2(15)  := 'ARRIVAL_DATE';       -- ���ד��t
  gv_tkn_ship_to       CONSTANT VARCHAR2(15)  := 'SHIP_TO';            -- �z����
  gv_tkn_standard_date CONSTANT VARCHAR2(15)  := 'STANDARD_DATE';      -- ����t
  gv_request_name_ship CONSTANT VARCHAR2(15)  := '�˗�No';             -- �˗�No
  gv_request_name_move CONSTANT VARCHAR2(15)  := '�ړ��ԍ�';           -- �ړ��ԍ�
  gv_ship_name_ship    CONSTANT VARCHAR2(15)  := '�z����';             -- �z����
  gv_ship_name_move    CONSTANT VARCHAR2(15)  := '���ɐ�';             -- ���ɐ�
  --�v���t�@�C��
  gv_prf_item_div      CONSTANT VARCHAR2(100) := 'XXCMN_ITEM_DIV';     -- ���i�敪
  gv_prf_article_div   CONSTANT VARCHAR2(100) := 'XXCMN_ARTICLE_DIV';  -- �i�ڋ敪
  gv_action_type_ship  CONSTANT VARCHAR2(2)   := '1';                  -- �o��
  gv_action_type_move  CONSTANT VARCHAR2(2)   := '3';                  -- �ړ�
  gv_min_default_date  CONSTANT VARCHAR2(10)  := '1900/01/01';         --MINDATE
  gv_base              CONSTANT VARCHAR2(1)   := '1'; -- ���_
  gv_wzero             CONSTANT VARCHAR2(2)   := '00';
  gv_flg_no            CONSTANT VARCHAR2(1)   := 'N';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_target_cnt_deliv  NUMBER :=0;           -- �Ώی���(�o��)
  gn_target_cnt_move   NUMBER :=0;           -- �Ώی���(�ړ�)
  gn_target_cnt_total  NUMBER :=0;           -- �Ώی���(�o��+�ړ�)
  gd_yyyymmdd_from     DATE;                 -- ���̓p�����[�^�o�ɓ�From
  gd_yyyymmdd_to       DATE;                 -- ���̓p�����[�^�o�ɓ�To
  gv_yyyymmdd_from     VARCHAR2(10);         -- ���̓p�����[�^�o�ɓ�From
  gv_yyyymmdd_to       VARCHAR2(10);         -- ���̓p�����[�^�o�ɓ�To
  gv_item_div          VARCHAR2(10);         -- �v���t�@�C������擾����'���i�敪'
  gv_article_div       VARCHAR2(10);         -- �v���t�@�C������擾����'�i���敪'
  gn_organization_id   NUMBER;               -- �}�X�^�g�DID
  gn_login_user        NUMBER;               -- ���O�C��ID
  gn_created_by        NUMBER;               -- ���O�C�����[�UID
  gn_conc_request_id   NUMBER;               -- �v��ID
  gn_prog_appl_id      NUMBER;               -- �A�v���P�[�V����ID
  gn_conc_program_id   NUMBER;               -- �v���O����ID
  gv_item_class        xxcmn_lot_status_v.prod_class_code%TYPE;  -- ���i�敪
--
  gn_move_rec_cnt      NUMBER := 0;          -- ������񏈗��J�E���^
  gn_odr_cnt           NUMBER := 0;          -- �󒍖��׃A�h�I���ϐ��J�E���^(gr_order_tbl)
  gn_mov_cnt           NUMBER := 0;          -- �󒍖��׃A�h�I���ϐ��J�E���^(gr_req_tbl)
--
  gv_request_type      VARCHAR2(20);         -- �˗�No/�ړ��ԍ�_�敪
--
-- 2008/11/13 M.Hokkanji PT START
  gv_item_code_list    VARCHAR2(4000);
-- 2008/11/13 M.Hokkanji PT END
  -- ���v���̈˗�No,�ړ��ԍ����i�[����(���������Z�o�̂���)
  TYPE number_rec IS RECORD(
    request_no                 xxwsh_order_headers_all.request_no%TYPE
     -- �˗�No or �ړ��ԍ�
  );
  TYPE number_tbl IS TABLE OF number_rec INDEX BY PLS_INTEGER;
  gr_number_tbl  number_tbl;
--
  -- ���v���̃f�[�^���i�[���郌�R�[�h
  TYPE demand_rec IS RECORD(
    document_type_code         xxinv_mov_lot_details.document_type_code%TYPE,           -- �����^�C�v V
    request_no                 xxwsh_order_headers_all.request_no%TYPE,                 -- �˗�No
    distribution_block         xxcmn_item_locations2_v.distribution_block%TYPE,         -- �u���b�N V
    deliver_from               xxwsh_order_headers_all.deliver_from%TYPE,               -- �o�Ɍ� V
    deliver_from_id            xxwsh_order_headers_all.deliver_from_id%TYPE,            -- �o�Ɍ�ID N
    schedule_ship_date         xxwsh_order_headers_all.schedule_ship_date%TYPE,         -- �o�ɗ\��� D
    schedule_arrival_date      xxwsh_order_headers_all.schedule_arrival_date%TYPE,      -- ���ɗ\��� D
    header_id                  xxwsh_order_headers_all.header_id%TYPE,                  -- �w�b�_ID N
    deliver_to                 xxwsh_order_headers_all.deliver_to%TYPE,                 -- �z���� V
    deliver_to_id              xxwsh_order_headers_all.deliver_to_id%TYPE,              -- �z����ID N
    reserve_order              xxcmn_cust_accounts2_v.reserve_order%TYPE,               -- ���_������ N
    order_line_id              xxwsh_order_lines_all.order_line_id%TYPE,                -- ����ID N
    shipping_item_code         xxwsh_order_lines_all.shipping_item_code%TYPE,           -- �i��(�R�[�h) V
    item_id                    xxcmn_item_mst2_v.item_id%TYPE,                          -- OPM�i��ID N
    ordered_quantity           xxwsh_order_lines_all.quantity%TYPE,                     -- �w������ N
    rest_quantity              xxwsh_order_lines_all.quantity%TYPE,                     -- �����c���� N
    reserved_quantity          xxwsh_order_lines_all.reserved_quantity%TYPE,            -- �������� N
    designated_production_date xxwsh_order_headers_all.designated_production_date%TYPE, -- �w�萻���� D
    frequent_whse_class        xxwsh_carriers_schedule.weight_capacity_class%TYPE,      -- ��\�q�ɋ敪 V
    frequent_whse              xxcmn_item_locations2_v.frequent_whse%TYPE,              -- ��\�q�� V
    inventory_location_id      xxcmn_item_locations2_v.inventory_location_id%TYPE,      -- ��\�ۊǒIID
    num_of_cases               xxcmn_item_mst2_v.num_of_cases%TYPE,                     -- �P�[�X���� N
    conv_unit                  xxcmn_item_mst2_v.conv_unit%TYPE                         -- ���o�Ɋ��Z�P�� V
  );
  TYPE demand_tbl IS TABLE OF demand_rec INDEX BY PLS_INTEGER;
  gr_demand_tbl  demand_tbl;
--
  -- ���v���̃f�[�^���i�[���郌�R�[�h(�ړ��p�ˌ��demand_rec�ɍ��̂���)
  TYPE demand_rec2 IS RECORD(
    document_type_code         xxinv_mov_lot_details.document_type_code%TYPE,           -- �����^�C�v V
    mov_num                    xxinv_mov_req_instr_headers.mov_num%TYPE,                -- �ړ��ԍ�
    distribution_block         xxcmn_item_locations2_v.distribution_block%TYPE,         -- �u���b�N V
    deliver_from               xxwsh_order_headers_all.deliver_from%TYPE,               -- �o�Ɍ� V
    deliver_from_id            xxwsh_order_headers_all.deliver_from_id%TYPE,            -- �o�Ɍ�ID N
    schedule_ship_date         xxwsh_order_headers_all.schedule_ship_date%TYPE,         -- �o�ɗ\��� D
    schedule_arrival_date      xxwsh_order_headers_all.schedule_arrival_date%TYPE,      -- ���ɗ\��� D
    header_id                  xxwsh_order_headers_all.header_id%TYPE,                  -- �w�b�_ID N
    deliver_to                 xxwsh_order_headers_all.deliver_to%TYPE,                 -- �z���� V
    deliver_to_id              xxwsh_order_headers_all.deliver_to_id%TYPE,              -- �z����ID N
    reserve_order              xxcmn_cust_accounts2_v.reserve_order%TYPE,               -- ���_������ N
    order_line_id              xxwsh_order_lines_all.order_line_id%TYPE,                -- ����ID N
    shipping_item_code         xxwsh_order_lines_all.shipping_item_code%TYPE,           -- �i��(�R�[�h) V
    item_id                    xxcmn_item_mst2_v.item_id%TYPE,                          -- OPM�i��ID N
    ordered_quantity           xxwsh_order_lines_all.quantity%TYPE,                     -- �w������ N
    rest_quantity              xxwsh_order_lines_all.quantity%TYPE,                     -- �����c���� N
    reserved_quantity          xxwsh_order_lines_all.reserved_quantity%TYPE,            -- �������� N
    designated_production_date xxwsh_order_headers_all.designated_production_date%TYPE, -- �w�萻���� D
    frequent_whse_class        xxwsh_carriers_schedule.weight_capacity_class%TYPE,      -- ��\�q�ɋ敪 V
    frequent_whse              xxcmn_item_locations2_v.frequent_whse%TYPE,              -- ��\�q�� V
    inventory_location_id      xxcmn_item_locations2_v.inventory_location_id%TYPE,      -- ��\�ۊǒIID
    num_of_cases               xxcmn_item_mst2_v.num_of_cases%TYPE,                     -- �P�[�X���� N
    conv_unit                  xxcmn_item_mst2_v.conv_unit%TYPE                         -- ���o�Ɋ��Z�P�� V
  );
  TYPE demand_tbl2 IS TABLE OF demand_rec2 INDEX BY PLS_INTEGER;
  gr_demand_tbl2  demand_tbl2;
--
  -- �������̃f�[�^���i�[���郌�R�[�h
  TYPE supply_rec IS RECORD(
    lot_id      ic_lots_mst.lot_id%TYPE,                                 -- ���b�gID
    lot_no      ic_lots_mst.lot_no%TYPE,                                 -- ���b�gNo
    lot_status  ic_lots_mst.attribute23%TYPE,                            -- ���b�g�X�e�[�^�X
    p_date      ic_lots_mst.attribute1%TYPE,                             -- �����N����
    fix_no      ic_lots_mst.attribute2%TYPE,                             -- �ŗL�ԍ�
    use_by_date ic_lots_mst.attribute3%TYPE,                             -- �ܖ�����
    r_quantity  xxwsh_order_lines_all.reserved_quantity%TYPE             -- �����\��
  );
  TYPE supply_tbl IS TABLE OF supply_rec INDEX BY PLS_INTEGER;
  gr_supply_tbl  supply_tbl;
--
  -- �`�F�b�N�������ʂ��i�[���郌�R�[�h
  TYPE check_rec IS RECORD(
    warnning_class VARCHAR2(2),                 -- �x���敪
    warnning_date  DATE,                        -- �x�����t
    lot_no         ic_lots_mst.lot_no%TYPE,     -- ���b�gNo
    p_date         ic_lots_mst.attribute1%TYPE, -- �����N����
    fix_no         ic_lots_mst.attribute2%TYPE, -- �ŗL�ԍ�
    use_by_date    ic_lots_mst.attribute3%TYPE, -- �ܖ�����
-- Ver1.01 M.Hokkanji Start
    max_rev_qty    NUMBER,                      -- �ő�����\��
    max_lot_no     ic_lots_mst.lot_no%TYPE,     -- ���b�gNo
    rev_qty        NUMBER                       -- ������������
-- Ver1.01 M.Hokkanji End
  );
  TYPE check_tbl IS TABLE OF check_rec INDEX BY PLS_INTEGER;
  gr_check_tbl  check_tbl;
-- Ver1.01 M.Hokkanji Start
   gv_ship_sql VARCHAR2(8000); --�o��SQL
   gv_move_sql VARCHAR2(8000); --�ړ�SQL
-- Ver1.01 M.Hokkanji End
--
  -- �ړ����b�g�ڍ׃f�[�^���i�[���郌�R�[�h
  TYPE move_rec IS RECORD(
    mov_lot_dtl_id           xxinv_mov_lot_details.mov_lot_dtl_id%TYPE,           -- ���b�g�ڍ�ID
    mov_line_id              xxinv_mov_lot_details.mov_line_id%TYPE,              -- ����ID
    document_type_code       xxinv_mov_lot_details.document_type_code%TYPE,       -- �����^�C�v
    record_type_code         xxinv_mov_lot_details.record_type_code%TYPE,         -- ���R�[�h�^�C�v
    item_id                  xxinv_mov_lot_details.item_id%TYPE,                  -- OPM�i��ID
    item_code                xxinv_mov_lot_details.item_code%TYPE,                -- �i��
    lot_id                   xxinv_mov_lot_details.lot_id%TYPE,                   -- ���b�gID
    lot_no                   xxinv_mov_lot_details.lot_no%TYPE,                   -- ���b�gNo
    actual_date              xxinv_mov_lot_details.actual_date%TYPE,              -- ���ѓ�
    actual_quantity          xxinv_mov_lot_details.actual_quantity%TYPE,          -- ���ѐ���
    automanual_reserve_class xxinv_mov_lot_details.automanual_reserve_class%TYPE, -- �����蓮�����敪
    created_by               xxinv_mov_lot_details.created_by%TYPE,               -- �쐬��
    creation_date            xxinv_mov_lot_details.creation_date%TYPE,            -- �쐬��
    last_updated_by          xxinv_mov_lot_details.last_updated_by%TYPE,          -- �ŏI�X�V��
    last_update_date         xxinv_mov_lot_details.last_update_date%TYPE,         -- �ŏI�X�V��
    last_update_login        xxinv_mov_lot_details.last_update_login%TYPE,        -- �ŏI�X�V���O�C��
    request_id               xxinv_mov_lot_details.request_id%TYPE,               -- �v��ID
    program_application_id   xxinv_mov_lot_details.program_application_id%TYPE,   -- �A�v���P�[�V����ID
    program_id               xxinv_mov_lot_details.program_id%TYPE,               -- �v���O����ID
    program_update_date      xxinv_mov_lot_details.program_update_date%TYPE       -- �v���O�����X�V��
  );
  TYPE move_tbl IS TABLE OF move_rec INDEX BY PLS_INTEGER;
  gr_move_tbl  move_tbl;
--
  -- �󒍖��׃A�h�I���f�[�^���i�[���郌�R�[�h
  TYPE order_rec IS RECORD(
    order_line_id            xxwsh_order_lines_all.order_line_id%TYPE,            -- �󒍖��׃A�h�I��ID
    reserved_quantity        xxwsh_order_lines_all.reserved_quantity%TYPE,        -- ������
    warning_class            xxwsh_order_lines_all.warning_class%TYPE,            -- �x���敪
    warning_date             xxwsh_order_lines_all.warning_date%TYPE,             -- �x�����t
    automanual_reserve_class xxwsh_order_lines_all.automanual_reserve_class%TYPE, -- �����蓮�����敪
    last_updated_by          xxwsh_order_lines_all.last_updated_by%TYPE,          -- �ŏI�X�V��
    last_update_date         xxwsh_order_lines_all.last_update_date%TYPE,         -- �ŏI�X�V��
    last_update_login        xxwsh_order_lines_all.last_update_login%TYPE,        -- �ŏI�X�V���O�C��
    request_id               xxwsh_order_lines_all.request_id%TYPE,               -- �v��ID
    program_application_id   xxwsh_order_lines_all.program_application_id%TYPE,   -- �A�v���P�[�V����ID
    program_id               xxwsh_order_lines_all.program_id%TYPE,               -- �v���O����ID
    program_update_date      xxwsh_order_lines_all.program_update_date%TYPE       -- �v���O�����X�V��
  );
  TYPE order_tbl IS TABLE OF order_rec INDEX BY PLS_INTEGER;
  gr_order_tbl  order_tbl;
--
  -- �ړ��˗�/�w�����׃A�h�I���f�[�^���i�[���郌�R�[�h
  TYPE req_rec IS RECORD(
    mov_line_id              xxinv_mov_req_instr_lines.mov_line_id%TYPE,              -- �ړ�����ID
    reserved_quantity        xxinv_mov_req_instr_lines.reserved_quantity%TYPE,        -- ��������
    warning_class            xxinv_mov_req_instr_lines.warning_class%TYPE,            -- �x���敪
    warning_date             xxinv_mov_req_instr_lines.warning_date%TYPE,             -- �x�����t
    automanual_reserve_class xxinv_mov_req_instr_lines.automanual_reserve_class%TYPE, -- �����蓮�����敪
    last_updated_by          xxinv_mov_req_instr_lines.last_updated_by%TYPE,          -- �ŏI�X�V��
    last_update_date         xxinv_mov_req_instr_lines.last_update_date%TYPE,         -- �ŏI�X�V��
    last_update_login        xxinv_mov_req_instr_lines.last_update_login%TYPE,        -- �ŏI�X�V���O�C��
    request_id               xxinv_mov_req_instr_lines.request_id%TYPE,               -- �v��ID
    program_application_id   xxinv_mov_req_instr_lines.program_application_id%TYPE,   -- �A�v���P�[�V����ID
    program_id               xxinv_mov_req_instr_lines.program_id%TYPE,               -- �v���O����ID
    program_update_date      xxinv_mov_req_instr_lines.program_update_date%TYPE       -- �v���O�����X�V��
  );
  TYPE req_tbl IS TABLE OF req_rec INDEX BY PLS_INTEGER;
  gr_req_tbl  req_tbl;
--
  -- �ړ����b�g�ڍ׏��(FORALL�ł�INSERT�p)
  TYPE i_mov_lot_dtl_id              -- ���b�g�ڍ�ID
    IS TABLE OF xxinv_mov_lot_details.mov_lot_dtl_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_mov_line_id                 -- ����ID
    IS TABLE OF xxinv_mov_lot_details.mov_line_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_document_type_code          -- �����^�C�v
    IS TABLE OF xxinv_mov_lot_details.document_type_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_record_type_code            -- ���R�[�h�^�C�v
    IS TABLE OF xxinv_mov_lot_details.record_type_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_item_id                     -- OPM�i��ID
    IS TABLE OF xxinv_mov_lot_details.item_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_item_code                   -- �i��
    IS TABLE OF xxinv_mov_lot_details.item_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_lot_id                      -- ���b�gID
    IS TABLE OF xxinv_mov_lot_details.lot_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_lot_no                      -- ���b�gNo
    IS TABLE OF xxinv_mov_lot_details.lot_no%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_actual_date                 -- ���ѓ�
    IS TABLE OF xxinv_mov_lot_details.actual_date%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_actual_quantity             -- ���ѐ���
    IS TABLE OF xxinv_mov_lot_details.actual_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_automanual_reserve_class    -- �����蓮�����敪
    IS TABLE OF xxinv_mov_lot_details.automanual_reserve_class%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_created_by                  -- �쐬��
    IS TABLE OF xxinv_mov_lot_details.created_by%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_creation_date               -- �쐬��
    IS TABLE OF xxinv_mov_lot_details.creation_date%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_last_updated_by             -- �ŏI�X�V��
    IS TABLE OF xxinv_mov_lot_details.last_updated_by%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_last_update_date            -- �ŏI�X�V��
    IS TABLE OF xxinv_mov_lot_details.last_update_date%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_last_update_login           -- �ŏI�X�V���O�C��
    IS TABLE OF xxinv_mov_lot_details.last_update_login%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_request_id                  -- �v��ID
    IS TABLE OF xxinv_mov_lot_details.request_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_program_application_id      -- �A�v���P�[�V����ID
    IS TABLE OF xxinv_mov_lot_details.program_application_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_program_id                  -- �v���O����ID
    IS TABLE OF xxinv_mov_lot_details.program_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_program_update_date         -- �v���O�����X�V��
    IS TABLE OF xxinv_mov_lot_details.program_update_date%TYPE
    INDEX BY BINARY_INTEGER;
--
  -- �󒍃A�h�I���f�[�^���(FORALL�ł�INSERT�p)
  TYPE j_order_line_id               -- �󒍖��׃A�h�I��ID
    IS TABLE OF xxwsh_order_lines_all.order_line_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_reserved_quantity           -- ������
    IS TABLE OF xxwsh_order_lines_all.reserved_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_warning_class               -- �x���敪
    IS TABLE OF xxwsh_order_lines_all.warning_class%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_warning_date                -- �x�����t
    IS TABLE OF xxwsh_order_lines_all.warning_date%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_automanual_reserve_class    -- �����蓮�����敪
    IS TABLE OF xxwsh_order_lines_all.automanual_reserve_class%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_last_updated_by             -- �ŏI�X�V��
    IS TABLE OF xxwsh_order_lines_all.last_updated_by%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_last_update_date            -- �ŏI�X�V��
    IS TABLE OF xxwsh_order_lines_all.last_update_date%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_last_update_login           -- �ŏI�X�V���O�C��
    IS TABLE OF xxwsh_order_lines_all.last_update_login%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_request_id                  -- �v��ID
    IS TABLE OF xxwsh_order_lines_all.request_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_program_application_id      -- �A�v���P�[�V����ID
    IS TABLE OF xxwsh_order_lines_all.program_application_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_program_id                  -- �v���O����ID
    IS TABLE OF xxwsh_order_lines_all.program_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_program_update_date         -- �v���O�����X�V��
    IS TABLE OF xxwsh_order_lines_all.program_update_date%TYPE
    INDEX BY BINARY_INTEGER;
--
  -- �ړ��˗�/�w�����׃A�h�I���f�[�^���(FORALL�ł�INSERT�p)
  TYPE m_mov_line_id                 -- �ړ�����ID
    IS TABLE OF xxinv_mov_req_instr_lines.mov_line_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_reserved_quantity             -- ��������
    IS TABLE OF xxinv_mov_req_instr_lines.reserved_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_warning_class               -- �x���敪
    IS TABLE OF xxinv_mov_req_instr_lines.warning_class%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_warning_date                -- �x�����t
    IS TABLE OF xxinv_mov_req_instr_lines.warning_date%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_automanual_reserve_class    -- �����蓮�����敪
    IS TABLE OF xxinv_mov_req_instr_lines.automanual_reserve_class%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_last_updated_by             -- �ŏI�X�V��
    IS TABLE OF xxinv_mov_req_instr_lines.last_updated_by%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_last_update_date            -- �ŏI�X�V��
    IS TABLE OF xxinv_mov_req_instr_lines.last_update_date%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_last_update_login           -- �ŏI�X�V���O�C��
    IS TABLE OF xxinv_mov_req_instr_lines.last_update_login%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_request_id                  -- �v��ID
    IS TABLE OF xxinv_mov_req_instr_lines.request_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_program_application_id      -- �A�v���P�[�V����ID
    IS TABLE OF xxinv_mov_req_instr_lines.program_application_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_program_id                  -- �v���O����ID
    IS TABLE OF xxinv_mov_req_instr_lines.program_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_program_update_date         -- �v���O�����X�V��
    IS TABLE OF xxinv_mov_req_instr_lines.program_update_date%TYPE
    INDEX BY BINARY_INTEGER;
--
  -- �ړ����b�g�ڍ׏��(FORALL�ł�INSERT�p)
  gt_i_mov_lot_dtl_id           i_mov_lot_dtl_id;             -- ���b�g�ڍ�ID
  gt_i_mov_line_id              i_mov_line_id;                -- ����ID
  gt_i_document_type_code       i_document_type_code;         -- �����^�C�v
  gt_i_record_type_code         i_record_type_code;           -- ���R�[�h�^�C�v
  gt_i_item_id                  i_item_id;                    -- OPM�i��ID
  gt_i_item_code                i_item_code;                  -- �i��
  gt_i_lot_id                   i_lot_id;                     -- ���b�gID
  gt_i_lot_no                   i_lot_no;                     -- ���b�gNo
  gt_i_actual_date              i_actual_date;                -- ���ѓ�
  gt_i_actual_quantity          i_actual_quantity;            -- ���ѐ���
  gt_i_automanual_reserve_class i_automanual_reserve_class;   -- �����蓮�����敪
  gt_i_created_by               i_created_by;                 -- �쐬��
  gt_i_creation_date            i_creation_date;              -- �쐬��
  gt_i_last_updated_by          i_last_updated_by;            -- �ŏI�X�V��
  gt_i_last_update_date         i_last_update_date;           -- �ŏI�X�V��
  gt_i_last_update_login        i_last_update_login;          -- �ŏI�X�V���O�C��
  gt_i_request_id               i_request_id;                 -- �v��ID
  gt_i_program_application_id   i_program_application_id;     -- �A�v���P�[�V����ID
  gt_i_program_id               i_program_id;                 -- �v���O����ID
  gt_i_program_update_date      i_program_update_date;        -- �v���O�����X�V��
--
  -- �󒍃A�h�I���f�[�^���(FORALL�ł�INSERT�p)
  gt_j_order_line_id            j_order_line_id;              -- �󒍖��׃A�h�I��ID
  gt_j_reserved_quantity        j_reserved_quantity;          -- ������
  gt_j_warning_class            j_warning_class;              -- �x���敪
  gt_j_warning_date             j_warning_date;               -- �x�����t
  gt_j_automanual_reserve_class j_automanual_reserve_class;   -- �����蓮�����敪
  gt_j_last_updated_by          j_last_updated_by;            -- �ŏI�X�V��
  gt_j_last_update_date         j_last_update_date;           -- �ŏI�X�V��
  gt_j_last_update_login        j_last_update_login;          -- �ŏI�X�V���O�C��
  gt_j_request_id               j_request_id;                 -- �v��ID
  gt_j_program_application_id   j_program_application_id;     -- �A�v���P�[�V����ID
  gt_j_program_id               j_program_id;                 -- �v���O����ID
  gt_j_program_update_date      j_program_update_date;        -- �v���O�����X�V��
--
  -- �ړ��˗�/�w�����׃A�h�I���f�[�^���(FORALL�ł�INSERT�p)
  gt_m_mov_line_id              m_mov_line_id;                -- �ړ�����ID
  gt_m_reserved_quantity        m_reserved_quantity;          -- ��������
  gt_m_warning_class            m_warning_class;              -- �x���敪
  gt_m_warning_date             m_warning_date;               -- �x�����t
  gt_m_automanual_reserve_class m_automanual_reserve_class;   -- �����蓮�����敪
  gt_m_last_updated_by          m_last_updated_by;            -- �ŏI�X�V��
  gt_m_last_update_date         m_last_update_date;           -- �ŏI�X�V��
  gt_m_last_update_login        m_last_update_login;          -- �ŏI�X�V���O�C��
  gt_m_request_id               m_request_id;                 -- �v��ID
  gt_m_program_application_id   m_program_application_id;     -- �A�v���P�[�V����ID
  gt_m_program_id               m_program_id;                 -- �v���O����ID
  gt_m_program_update_date      m_program_update_date;        -- �v���O�����X�V��
--
  /**********************************************************************************
   * Function Name    : check_number_tbl
   * Description      : �ړ�No�z�񑶍݃`�F�b�N
   * Return           : 0=���݂��Ȃ��A0>���݂���(�Y��)
   ***********************************************************************************/
  FUNCTION check_number_tbl(
    iv_request_no      IN VARCHAR2)       -- �ړ��ԍ� or �˗�No
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_number_tbl'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    process_exp               EXCEPTION;     -- �e�����ŃG���[�����������ꍇ
    PRAGMA EXCEPTION_INIT(process_exp, -20001);
--
    -- *** ���[�J���ϐ� ***
    ln_cnt      NUMBER := 0;
--
  BEGIN
--
    -- �˗�No�z�񌟍����[�v
    <<number_loop>>
    FOR ln_cnt IN 1..NVL(gr_number_tbl.LAST,0) LOOP
      -- �z��ɑ��݂���
      IF ( gr_number_tbl(ln_cnt).request_no = iv_request_no ) THEN
        RETURN 0;
      END IF;
    END LOOP number_loop;
--
    -- ���������J�E���g�A�b�v
    gn_target_cnt := gn_target_cnt + 1;
--
    -- �z��ɑ��݂��Ȃ��̂Ŋi�[���ēY������Ԃ�
-- Ver1.01 M.Hokkanji Start
   FND_FILE.PUT_LINE(FND_FILE.LOG,'�����˗�NO�F' || iv_request_no);
-- Ver1.01 M.Hokkanji End
    gr_number_tbl(NVL(gr_number_tbl.LAST,0) + 1).request_no := iv_request_no;
    RETURN ln_cnt;
--
  EXCEPTION
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
       (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part,1,5000),TRUE);
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END check_number_tbl;
--
  /**********************************************************************************
   * Function Name    : get_can_enc_in_time_qty2
   * Description      : �L�����x�[�X�����\���Z�oAPI
   ***********************************************************************************/
  FUNCTION get_can_enc_in_time_qty2(
      in_whse_id          IN NUMBER                    -- OPM�ۊǑq��ID
    , iv_whse_code        IN VARCHAR2                  -- OPM�ۊǑq�ɃR�[�h
    , in_item_id          IN NUMBER                    -- OPM�i��ID
    , iv_item_code        IN VARCHAR2                  -- OPM�i�ڃR�[�h
    , in_lot_id           IN NUMBER DEFAULT NULL       -- ���b�gID
    , in_active_date      IN DATE   DEFAULT NULL)      -- �L����
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_can_enc_in_time_qty2'; --�v���O������
    cv_flag_off       CONSTANT VARCHAR2(1)   := 'N';                        -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1)   := 'Y';                        -- ON
    cv_cate_order     CONSTANT VARCHAR2(10)  := 'ORDER';                    -- ��
    cv_cate_return    CONSTANT VARCHAR2(10)  := 'RETURN';                   -- �ԕi
    cv_doc_ship       CONSTANT VARCHAR2(2)   := '10';                       -- �����^�C�v�u�o�ׁv
    cv_doc_mov        CONSTANT VARCHAR2(2)   := '20';                       -- �����^�C�v�u�ړ��v
    cv_doc_prov       CONSTANT VARCHAR2(2)   := '30';                       -- �����^�C�v�u�x���w���v
    cv_doc_prod       CONSTANT VARCHAR2(2)   := '40';                       -- �����^�C�v�u���Y�w���v
    cv_doc_po         CONSTANT VARCHAR2(2)   := '50';                       -- �����^�C�v�u�����v
    cv_rec_instruct   CONSTANT VARCHAR2(2)   := '10';                       -- ���R�[�h�^�C�v�u�w���v
    cv_rec_shipped    CONSTANT VARCHAR2(2)   := '20';                       -- ���R�[�h�^�C�v�u�o�Ɏ��сv
    cv_rec_ship_to    CONSTANT VARCHAR2(2)   := '30';                       -- ���R�[�h�^�C�v�u���Ɏ��сv
    cv_rec_invest     CONSTANT VARCHAR2(2)   := '40';                       -- ���R�[�h�^�C�v�u�����ρv
    cv_status_02      CONSTANT VARCHAR2(2)   := '02';                       -- �˗��ς�
    cv_status_03      CONSTANT VARCHAR2(2)   := '03';                       -- ������
    cv_status_04      CONSTANT VARCHAR2(2)   := '04';                       -- �o�ɕ񍐗L
    cv_status_05      CONSTANT VARCHAR2(2)   := '05';                       -- ���ɕ񍐗L
    cv_status_06      CONSTANT VARCHAR2(2)   := '06';                       -- ���o�ɕ񍐗L
    cv_status_07      CONSTANT VARCHAR2(2)   := '07';                       -- ��̍�
    cv_status_08      CONSTANT VARCHAR2(2)   := '08';                       -- �o�׎��ьv���
    cv_type_ship      CONSTANT VARCHAR2(1)   := '1';                        -- �o�׈˗�
    cv_type_prov      CONSTANT VARCHAR2(1)   := '2';                        -- �x���˗�
    cv_type_whse      CONSTANT VARCHAR2(1)   := '3';                        -- �q��
    cn_line_material  CONSTANT NUMBER(5,0)   := -1;                         -- �����i
    cn_status_wip     CONSTANT NUMBER(5,0)   := 2;                          -- WIP
    cn_status_pnd     CONSTANT NUMBER(5,0)   := 1;                          -- �ۗ�
    cv_po_order_fin   CONSTANT VARCHAR2(2)   := '20';                       -- �����쐬��
    cv_po_accept      CONSTANT VARCHAR2(2)   := '25';                       -- �������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
--
    -- *** ���[�J���ϐ� ***
    ln_whse_id     NUMBER;        -- �ۊǑq��ID
    ln_item_id     NUMBER;        -- �i��ID
    ln_lot_id      NUMBER;        -- ���b�gID
    ln_item_code   VARCHAR2(40);  -- �i�ڃR�[�h
    lv_whse_code   VARCHAR2(40);  -- �ۊǑq�ɃR�[�h
    lv_rep_whse    VARCHAR2(150); -- ��\�q��
    lv_item_code   VARCHAR2(32);  -- �i�ڃR�[�h
    lv_lot_no      VARCHAR2(32);  -- ���b�gNO
    ld_eff_date    DATE;          -- �L����
    lv_errbuf      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- *** ���[�J���萔 ***
    cv_prf_max_date_name CONSTANT VARCHAR2(15)  := 'MAX���t'; --�v���t�@�C����
--
    ln_inv_lot_onhand             NUMBER; -- ���b�g I0)���ʐ���
    ln_inv_lot_in_inout_rpt_qty   NUMBER; -- ���b�g I1)���ʐ���
    ln_inv_lot_in_in_rpt_qty      NUMBER; -- ���b�g I2)���ʐ���
    ln_inv_lot_out_inout_rpt_qty  NUMBER; -- ���b�g I3)���ʐ���
    ln_inv_lot_out_out_rpt_qty    NUMBER; -- ���b�g I4)���ʐ���
    ln_inv_lot_ship_qty           NUMBER; -- ���b�g I5)���ʐ���
    ln_inv_lot_provide_qty        NUMBER; -- ���b�g I6)���ʐ���
    ln_inv_lot_in_inout_bef_qty   NUMBER; -- ���b�g I7)���ʐ���(�����O)
    ln_inv_lot_in_inout_cor_qty   NUMBER; -- ���b�g I7)���ʐ���(������)
    ln_inv_lot_out_inout_bef_qty  NUMBER; -- ���b�g I8)���ʐ���(�����O)
    ln_inv_lot_out_inout_cor_qty  NUMBER; -- ���b�g I8)���ʐ���(������)
    ln_sup_lot_inv_in_qty         NUMBER; -- ���b�g S1)���ʐ���
    ln_sup_lot_inv_out_qty        NUMBER; -- ���b�g S4)���ʐ���
    ln_dem_lot_ship_qty           NUMBER; -- ���b�g D1)���ʐ���
    ln_dem_lot_provide_qty        NUMBER; -- ���b�g D2)���ʐ���
    ln_dem_lot_inv_out_qty        NUMBER; -- ���b�g D3)���ʐ���
    ln_dem_lot_inv_in_qty         NUMBER; -- ���b�g D4)���ʐ���
    ln_dem_lot_produce_qty        NUMBER; -- ���b�g D5)���ʐ���
    ln_dem_lot_order_qty          NUMBER; -- ���b�g D6)���ʐ���
--
    ln_stock_qty  NUMBER; -- �݌ɐ�
    ln_supply_qty NUMBER; -- ������
    ln_demand_qty NUMBER; -- ���v��
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    process_exp               EXCEPTION;     -- �e�����ŃG���[�����������ꍇ
    PRAGMA EXCEPTION_INIT(process_exp, -20001);
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    ln_stock_qty  := 0;
    ln_supply_qty := 0;
    ln_demand_qty := 0;
--
    -- �L�������擾
    IF ( in_active_date IS NULL ) THEN
        -- MAX���t���擾
      ld_eff_date := FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'),'YYYY/MM/DD');
      IF ( ld_eff_date IS NULL ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN',
                                              'APP-XXCMN-10002',
                                              'NG_PROFILE',
                                              cv_prf_max_date_name);
        RAISE process_exp;
      END IF;
    ELSE
      ld_eff_date := in_active_date;
    END IF;
--
    -- ���b�g I0 EBS�莝�݌�
    SELECT NVL(SUM(ili.loct_onhand), 0)
    INTO   ln_inv_lot_onhand
    FROM   ic_loct_inv ili  -- �莝����
    WHERE  ili.location = iv_whse_code
    AND    ili.item_id  = in_item_id
    AND    ili.lot_id   = in_lot_id
    ;
--
    -- ���b�g I1 ���і���݌ɐ�  �ړ����Ɂi���o�ɕ񍐗L�j
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_inv_lot_in_inout_rpt_qty
    FROM    xxinv_mov_req_instr_headers mrih   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
          , xxinv_mov_req_instr_lines   mril   -- �ړ��˗�/�w�����ׁi�A�h�I���j
          , xxinv_mov_lot_details       mld    -- �ړ����b�g�ڍׁi�A�h�I���j
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_status_06
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_mov
    AND     mld.record_type_code    = cv_rec_ship_to
    ;
--
    -- ���b�g I2 ���і���݌ɐ�  �ړ����Ɂi���ɕ񍐗L�j
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_inv_lot_in_in_rpt_qty
    FROM    xxinv_mov_req_instr_headers mrih   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
          , xxinv_mov_req_instr_lines   mril   -- �ړ��˗�/�w�����ׁi�A�h�I���j
          , xxinv_mov_lot_details       mld    -- �ړ����b�g�ڍׁi�A�h�I���j
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_status_05
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_mov
    AND     mld.record_type_code    = cv_rec_ship_to
    ;
--
    -- ���b�g I3 ���і���݌ɐ�  �ړ��o�Ɂi���o�ɕ񍐗L�j
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_inv_lot_out_inout_rpt_qty
    FROM    xxinv_mov_req_instr_headers mrih   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
          , xxinv_mov_req_instr_lines   mril   -- �ړ��˗�/�w�����ׁi�A�h�I���j
          , xxinv_mov_lot_details       mld    -- �ړ����b�g�ڍׁi�A�h�I���j
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_status_06
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_mov
    AND     mld.record_type_code    = cv_rec_ship_to
    ;
--
    -- ���b�g I4 ���і���݌ɐ�  �ړ��o�Ɂi�o�ɕ񍐗L�j
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_inv_lot_out_out_rpt_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
            xxinv_mov_req_instr_lines   mril,   -- �ړ��˗�/�w�����ׁi�A�h�I���j
            xxinv_mov_lot_details       mld     -- �ړ����b�g�ڍׁi�A�h�I���j
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_status_04
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_mov
    AND     mld.record_type_code    = cv_rec_shipped
    ;
--
    -- ���b�g I5 ���і���݌ɐ�  �o��
    SELECT  /*+ leading(oha otta ola mld) */
            NVL(SUM(CASE
                      WHEN (otta.order_category_code = cv_cate_order) THEN
                        mld.actual_quantity
                      WHEN (otta.order_category_code = cv_cate_return) THEN
                        mld.actual_quantity * -1
                    END), 0)
    INTO    ln_inv_lot_ship_qty
    FROM    xxwsh_order_headers_all    oha  -- �󒍃w�b�_�i�A�h�I���j
          , xxwsh_order_lines_all      ola  -- �󒍖��ׁi�A�h�I���j
          , xxinv_mov_lot_details      mld  -- �ړ����b�g�ڍׁi�A�h�I���j
          , oe_transaction_types_all   otta -- �󒍃^�C�v
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_status_04
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
    AND     mld.item_id               = in_item_id
    AND     mld.lot_id                = in_lot_id
    AND     mld.document_type_code    = cv_doc_ship
    AND     mld.record_type_code      = cv_rec_shipped
    AND     otta.attribute1           IN (cv_type_ship, cv_type_whse)
    AND     otta.transaction_type_id  = oha.order_type_id
    ;
--
    -- ���b�g I6 ���і���݌ɐ�  �x��
    SELECT  /*+ leading(oha otta ola mld) */
            NVL(SUM(CASE
                      WHEN (otta.order_category_code = cv_cate_order) THEN
                        mld.actual_quantity
                      WHEN (otta.order_category_code = cv_cate_return) THEN
                        mld.actual_quantity * -1
                    END), 0)
    INTO    ln_inv_lot_provide_qty
    FROM    xxwsh_order_headers_all    oha  -- �󒍃w�b�_�i�A�h�I���j
          , xxwsh_order_lines_all      ola  -- �󒍖��ׁi�A�h�I���j
          , xxinv_mov_lot_details      mld  -- �ړ����b�g�ڍׁi�A�h�I���j
          , oe_transaction_types_all   otta -- �󒍃^�C�v
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_status_08
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
    AND     mld.item_id               = in_item_id
    AND     mld.lot_id                = in_lot_id
    AND     mld.document_type_code    = cv_doc_prov
    AND     mld.record_type_code      = cv_rec_shipped
    AND     otta.attribute1           = cv_type_prov
    AND     otta.transaction_type_id  = oha.order_type_id
    ;
--
    -- ���b�g I7 ���і���݌ɐ�  �ړ����ɒ����i���o�ɕ񍐗L�j
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.before_actual_quantity),0),
            NVL(SUM(mld.actual_quantity),0)
    INTO    ln_inv_lot_in_inout_bef_qty,
            ln_inv_lot_in_inout_cor_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
            xxinv_mov_req_instr_lines   mril,   -- �ړ��˗�/�w�����ׁi�A�h�I���j
            xxinv_mov_lot_details       mld     -- �ړ����b�g�ڍׁi�A�h�I���j
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_on
    AND     mrih.correct_actual_flg = cv_flag_on
    AND     mrih.status             = cv_status_06
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_mov
    AND     mld.record_type_code    = cv_rec_ship_to
    ;
--
    -- ���b�g I8 ���і���݌ɐ�  �ړ��o�ɒ����i���o�ɕ񍐗L�j
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.before_actual_quantity),0),
            NVL(SUM(mld.actual_quantity),0)
    INTO    ln_inv_lot_out_inout_bef_qty,
            ln_inv_lot_out_inout_cor_qty
    FROM    xxinv_mov_req_instr_headers mrih   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
          , xxinv_mov_req_instr_lines   mril   -- �ړ��˗�/�w�����ׁi�A�h�I���j
          , xxinv_mov_lot_details       mld    -- �ړ����b�g�ڍׁi�A�h�I���j
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_on
    and     mrih.correct_actual_flg = cv_flag_on
    AND     mrih.status             = cv_status_06
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_mov
    AND     mld.record_type_code    = cv_rec_shipped
    ;
--
    -- ���b�g S1)������  �ړ����ɗ\��
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_sup_lot_inv_in_qty
    FROM    xxinv_mov_req_instr_headers mrih   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
          , xxinv_mov_req_instr_lines   mril   -- �ړ��˗�/�w�����ׁi�A�h�I���j
          , xxinv_mov_lot_details       mld    -- �ړ����b�g�ڍׁi�A�h�I���j
    WHERE   mrih.ship_to_locat_id        = in_whse_id
    AND     mrih.comp_actual_flg         = cv_flag_off
    AND     mrih.status                 IN (cv_status_02, cv_status_03)
    AND     mrih.schedule_arrival_date  <= ld_eff_date
    AND     mrih.mov_hdr_id              = mril.mov_hdr_id
    AND     mril.mov_line_id             = mld.mov_line_id
    AND     mril.delete_flg              = cv_flag_off
    AND     mld.item_id                  = in_item_id
    AND     mld.lot_id                   = in_lot_id
    AND     mld.document_type_code       = cv_doc_mov
    AND     mld.record_type_code         = cv_rec_instruct
    ;
--
    -- ���b�g S4)������  ���ьv��ς̈ړ��o�Ɏ���
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_sup_lot_inv_out_qty
    FROM    xxinv_mov_req_instr_headers mrih   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
          , xxinv_mov_req_instr_lines   mril   -- �ړ��˗�/�w�����ׁi�A�h�I���j
          , xxinv_mov_lot_details       mld    -- �ړ����b�g�ڍׁi�A�h�I���j
    WHERE   mrih.ship_to_locat_id        = in_whse_id
    AND     mrih.comp_actual_flg         = cv_flag_off
    AND     mrih.status                  = cv_status_04
-- 2008/12/15 h.Itou Mod Start �{�ԏ�Q#645
--    AND     mrih.schedule_arrival_date  <= ld_eff_date
    AND     NVL(mrih.actual_arrival_date, mrih.schedule_arrival_date) <= ld_eff_date
-- 2008/12/15 h.Itou Mod End
    AND     mrih.mov_hdr_id              = mril.mov_hdr_id
    AND     mril.mov_line_id             = mld.mov_line_id
    AND     mril.delete_flg              = cv_flag_off
    AND     mld.item_id                  = in_item_id
    AND     mld.lot_id                   = in_lot_id
    AND     mld.document_type_code       = cv_doc_mov
    AND     mld.record_type_code         = cv_rec_shipped
    ;
--
    -- ���b�g D1)���v��  ���і��v��̏o�׈˗�
    SELECT  /*+ leading(oha otta ola mld) */ 
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_dem_lot_ship_qty
    FROM    xxwsh_order_headers_all    oha,  -- �󒍃w�b�_�i�A�h�I���j
            xxwsh_order_lines_all      ola,  -- �󒍖��ׁi�A�h�I���j
            xxinv_mov_lot_details      mld,  -- �ړ����b�g�ڍׁi�A�h�I���j
            oe_transaction_types_all  otta   -- �󒍃^�C�v
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_status_03
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.schedule_ship_date   <= ld_eff_date
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
    AND     ola.shipping_item_code    = mld.item_code
    AND     ola.shipping_item_code    = iv_item_code
    AND     mld.lot_id                = in_lot_id
    AND     mld.document_type_code    = cv_doc_ship
    AND     mld.record_type_code      = cv_rec_instruct
    AND     otta.attribute1           = cv_type_ship
    AND     otta.transaction_type_id  = oha.order_type_id
    ;
--
    -- ���b�g D2)���v��  ���і��v��̎x���w��
    SELECT  /*+ leading(oha otta ola mld) */ 
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_dem_lot_provide_qty
    FROM    xxwsh_order_headers_all    oha  -- �󒍃w�b�_�i�A�h�I���j
          , xxwsh_order_lines_all      ola  -- �󒍖��ׁi�A�h�I���j
          , xxinv_mov_lot_details      mld  -- �ړ����b�g�ڍׁi�A�h�I���j
          , oe_transaction_types_all   otta -- �󒍃^�C�v
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_status_07
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.schedule_ship_date   <= ld_eff_date
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
    AND     ola.shipping_item_code    = mld.item_code
    AND     ola.shipping_item_code    = iv_item_code
    AND     mld.lot_id                = in_lot_id
    AND     mld.document_type_code    = cv_doc_prov
    AND     mld.record_type_code      = cv_rec_instruct
    AND     otta.attribute1           = cv_type_prov
    AND     otta.transaction_type_id  = oha.order_type_id
    ;
--
    -- ���b�g D3)���v��  ���і��v��̈ړ��w��
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_dem_lot_inv_out_qty
    FROM    xxinv_mov_req_instr_headers mrih   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
          , xxinv_mov_req_instr_lines   mril   -- �ړ��˗�/�w�����ׁi�A�h�I���j
          , xxinv_mov_lot_details       mld    -- �ړ����b�g�ڍׁi�A�h�I���j
    WHERE   mrih.shipped_locat_id    = in_whse_id
    AND     mrih.comp_actual_flg     = cv_flag_off
    AND     mrih.status             IN (cv_status_02, cv_status_03)
    AND     mrih.schedule_ship_date <= ld_eff_date
    AND     mrih.mov_hdr_id          = mril.mov_hdr_id
    AND     mril.mov_line_id         = mld.mov_line_id
    AND     mril.delete_flg          = cv_flag_off
    AND     mld.item_id              = in_item_id
    AND     mld.lot_id               = in_lot_id
    AND     mld.document_type_code   = cv_doc_mov
    AND     mld.record_type_code     = cv_rec_instruct
    ;
--
    -- ���b�g D4)���v��  ���ьv��ς̈ړ����Ɏ���
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_dem_lot_inv_in_qty
    FROM    xxinv_mov_req_instr_headers mrih   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
          , xxinv_mov_req_instr_lines   mril   -- �ړ��˗�/�w�����ׁi�A�h�I���j
          , xxinv_mov_lot_details       mld    -- �ړ����b�g�ڍׁi�A�h�I���j
    WHERE   mrih.shipped_locat_id    = in_whse_id
    AND     mrih.comp_actual_flg     = cv_flag_off
    AND     mrih.status              = cv_status_05
-- 2008/12/15 h.Itou Mod Start �{�ԏ�Q#645
--    AND     mrih.schedule_ship_date <= ld_eff_date
    AND     NVL(mrih.actual_ship_date, mrih.schedule_ship_date) <= ld_eff_date
-- 2008/12/15 h.Itou Mod End
    AND     mrih.mov_hdr_id          = mril.mov_hdr_id
    AND     mril.mov_line_id         = mld.mov_line_id
    AND     mril.delete_flg          = cv_flag_off
    AND     mld.item_id              = in_item_id
    AND     mld.lot_id               = in_lot_id
    AND     mld.document_type_code   = cv_doc_mov
    AND     mld.record_type_code     = cv_rec_ship_to
    ;
--
    -- ���b�g D5)���v��  ���і��v��̐��Y�����\��
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_dem_lot_produce_qty
    FROM    gme_batch_header      gbh -- ���Y�o�b�`
          , gme_material_details  gmd -- ���Y�����ڍ�
          , xxinv_mov_lot_details mld -- �ړ����b�g�ڍׁi�A�h�I���j
          , gmd_routings_b        grb -- �H���}�X�^
          , ic_tran_pnd           itp -- �ۗ��݌Ƀg�����U�N�V����
    WHERE   gbh.batch_status      IN (cn_status_wip, cn_status_pnd)
    AND     gbh.plan_start_date   <= ld_eff_date
    AND     gbh.batch_id           = gmd.batch_id
    AND     gmd.line_type          = cn_line_material
    AND     gmd.item_id            = in_item_id
    AND     gmd.material_detail_id = mld.mov_line_id
    AND     mld.lot_id             = in_lot_id
    AND     gbh.routing_id         = grb.routing_id
    AND     grb.attribute9         = iv_whse_code       -- �[�i�ꏊ
    AND     mld.document_type_code = cv_doc_prod
    AND     mld.record_type_code   = cv_rec_instruct
    AND     itp.doc_type           = 'PROD'
-- add start ver1.3
    AND     itp.delete_mark        = 0
-- add end ver1.3
    AND     itp.line_id            = gmd.material_detail_id 
    AND     itp.item_id            = gmd.item_id
    AND     itp.lot_id             = mld.lot_id
    AND     itp.completed_ind      = 0
    ;
--
    -- ���b�g D6)���v��  ���і��v��̑����q�ɔ������ɗ\��
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_dem_lot_order_qty
    FROM    mtl_system_items_b    msib   -- �i�ڃ}�X�^
          , po_lines_all          pla    -- ��������
          , po_headers_all        pha    -- �����w�b�_
          , xxinv_mov_lot_details mld    -- �ړ����b�g�ڍׁi�A�h�I���j
    WHERE   msib.segment1          = iv_item_code
    AND     msib.organization_id   = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
    AND     msib.inventory_item_id = pla.item_id
    AND     pla.attribute13        = cv_flag_off  -- ���ʊm��t���O
    AND     pla.cancel_flag        = cv_flag_off
    AND     pla.attribute12        = iv_whse_code -- �����݌ɓ��ɐ�
    AND     pla.po_header_id       = pha.po_header_id
    AND     pha.attribute1        IN (cv_po_order_fin, cv_po_accept)
    AND     pha.attribute4        <= TO_CHAR(ld_eff_date, 'YYYY/MM/DD') -- �[����
    AND     pla.po_line_id         = mld.mov_line_id
    AND     mld.lot_id             = in_lot_id
    AND     mld.document_type_code = cv_doc_po
    AND     mld.record_type_code   = cv_rec_instruct
    ;
--
    -- ���b�g�Ǘ��i�݌ɐ�
    ln_stock_qty := ln_inv_lot_onhand 
                  + ln_inv_lot_in_inout_rpt_qty
                  + ln_inv_lot_in_in_rpt_qty
                  - ln_inv_lot_out_inout_rpt_qty
                  - ln_inv_lot_out_out_rpt_qty
                  - ln_inv_lot_ship_qty
                  - ln_inv_lot_provide_qty
                  - ln_inv_lot_in_inout_bef_qty
                  + ln_inv_lot_in_inout_cor_qty
                  + ln_inv_lot_out_inout_bef_qty
                  - ln_inv_lot_out_inout_cor_qty;
--
    -- ���b�g�Ǘ��i������
    ln_supply_qty := ln_sup_lot_inv_in_qty
                   + ln_sup_lot_inv_out_qty;
--
    -- ���b�g�Ǘ��i���v��
    ln_demand_qty := ln_dem_lot_ship_qty
                   + ln_dem_lot_provide_qty
                   + ln_dem_lot_inv_out_qty
                   + ln_dem_lot_inv_in_qty
                   + ln_dem_lot_produce_qty
                   + ln_dem_lot_order_qty;
--
    -- �L�����x�[�X�����\��
    RETURN ln_stock_qty + ln_supply_qty - ln_demand_qty;
--
  EXCEPTION
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
       (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000),TRUE);
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_can_enc_in_time_qty2;
--
--
  /**********************************************************************************
   * Function Name    : get_can_enc_qty2
   * Description      : �����\���Z�oAPI2
   ***********************************************************************************/
  FUNCTION get_can_enc_qty2(
      in_whse_id          IN  NUMBER                    -- OPM�ۊǑq��ID
    , iv_whse_code        IN  VARCHAR2                  -- OPM�ۊǑq�ɃR�[�h
    , in_item_id          IN  NUMBER                    -- OPM�i��ID
    , iv_item_code        IN  VARCHAR2                  -- OPM�i�ڃR�[�h
    , in_lot_id           IN  NUMBER DEFAULT NULL       -- ���b�gID
    , in_active_date      IN  DATE)                      -- �L����
    RETURN NUMBER                                      -- �����\��
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'get_can_enc_qty2';           -- �v���O������
    cv_xxcmn                CONSTANT VARCHAR2(10)  := 'XXCMN';
    cv_dummy_frequent_whse  CONSTANT VARCHAR2(100) := 'XXCMN_DUMMY_FREQUENT_WHSE';  -- 
    cv_error_10002          CONSTANT VARCHAR2(30)  := 'APP-XXCMN-10002';            -- �v���t�@�C���擾�G���[
    cv_tkn_ng_profile       CONSTANT VARCHAR2(30)  := 'NG_PROFILE';                 -- �g�[�N��
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_whse_id              NUMBER;           -- �ۊǑq��ID
    ln_item_id              NUMBER;           -- �i��ID
    ln_lot_id               NUMBER;           -- ���b�gID
    lv_whse_code            VARCHAR2(40);     -- �ۊǑq�ɃR�[�h
    lv_rep_whse             VARCHAR2(150);    -- ��\�q��
    lv_item_code            VARCHAR2(32);     -- �i�ڃR�[�h
    lv_lot_no               VARCHAR2(32);     -- ���b�gNO
    ld_eff_date             DATE;             -- �L����
    lv_errbuf               VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_all_enc_qty          NUMBER;           -- �Ώۂ̑������\��
    ln_in_time_enc_qty      NUMBER;           -- �Ώۂ̗L�����x�[�X�����\��
    ln_enc_qty              NUMBER;           -- �����\��
    ln_ref_all_enc_qty      NUMBER;           -- �Ώېe��q�̑������\��
    ln_ref_in_time_enc_qty  NUMBER;           -- �Ώېe��q�̗L�����x�[�X�����\��
--
    ln_inventory_location_id       mtl_item_locations.inventory_location_id%TYPE;
    lv_inv_whse_code               mtl_item_locations.segment5%TYPE;
    lt_dummy_frequent_whse  mtl_item_locations.segment1%TYPE; --�_�~�[��\�q��
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR lc_child_cur  -- �q�q�ɂ̍��v���Z�o����ׁA���ʊ֐��ɓn���q�q�ɂ𒊏o����
    IS
      SELECT  mil.inventory_location_id
            , mil.segment1  whse_code
      FROM    mtl_item_locations  mil    -- �ۊǏꏊ
      WHERE   mil.attribute5      = lv_rep_whse -- ��\�q��
        AND   mil.segment1       <> mil.attribute5;
--
    -- ��\�q��(�q)(�q�ɁE�i�ڒP��)�̍��v�擾�p�J�[�\��
    CURSOR lc_item_child_cur
    IS
      SELECT  xfil.item_location_id
            , xfil.item_location_code whse_code
      FROM    xxwsh_frq_item_locations xfil
      WHERE   xfil.frq_item_location_code = lv_rep_whse -- ��\�q�ɃR�[�h
      AND     xfil.item_id = in_item_id;                -- OPM�i��ID
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    process_exp               EXCEPTION;     -- �e�����ŃG���[�����������ꍇ
    profile_exp               EXCEPTION;     -- �v���t�@�C���擾���s
    PRAGMA EXCEPTION_INIT(process_exp, -20001);
    PRAGMA EXCEPTION_INIT(profile_exp, -20002);
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
--
    -- ���ʂ̏�����
    ln_all_enc_qty     := 0;
    ln_in_time_enc_qty := 0;
--
    BEGIN
      -- ��\�q�ɂ��擾
      SELECT  mil.segment1               -- �ۊǑq�ɃR�[�h
            , mil.attribute5             -- ��\�q��
      INTO    lv_whse_code
            , lv_rep_whse
      FROM    mtl_item_locations  mil    -- �ۊǏꏊ
      WHERE   mil.inventory_location_id = in_whse_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE process_exp;
    END;
--
    -- �P�̂̈����\�����Z�o
    ln_all_enc_qty     := get_can_enc_in_time_qty2(in_whse_id
                                                 , iv_whse_code
                                                 , in_item_id
                                                 , iv_item_code
                                                 , in_lot_id
                                                 , NULL);
    ln_in_time_enc_qty := get_can_enc_in_time_qty2(in_whse_id
                                                 , iv_whse_code
                                                 , in_item_id
                                                 , iv_item_code
                                                 , in_lot_id
                                                 , in_active_date);
--
    -- ��\�q�ɂłȂ��ꍇ
    IF ( lv_rep_whse IS NULL ) THEN
      ln_ref_all_enc_qty      := 0;
      ln_ref_in_time_enc_qty  := 0;
--
    -- ��\�q�Ɂi�e�j�̏ꍇ
    ELSIF ( lv_rep_whse = lv_whse_code ) THEN
      -- ��\�q�Ɂi�q�j�̍��v���擾
      -- �f�[�^�̎擾
      <<get_child_loop>>
      FOR r_location_id IN lc_child_cur LOOP
        ln_ref_all_enc_qty := NVL(get_can_enc_in_time_qty2(r_location_id.inventory_location_id
                                                         , r_location_id.whse_code
                                                         , in_item_id
                                                         , iv_item_code
                                                         , in_lot_id), 0);
        ln_ref_in_time_enc_qty := NVL(get_can_enc_in_time_qty2(
                                                           r_location_id.inventory_location_id
                                                         , r_location_id.whse_code
                                                         , in_item_id
                                                         , iv_item_code
                                                         , in_lot_id
                                                         , in_active_date), 0);
        -- ��������
        ln_all_enc_qty      := ln_all_enc_qty     + ln_ref_all_enc_qty;
        ln_in_time_enc_qty  := ln_in_time_enc_qty + ln_ref_in_time_enc_qty;
      END LOOP get_child_loop;
      -- ��\�q�Ɏq(�q�ɁE�i�ڒP��)�̍��v���擾
      -- �f�[�^�̎擾
      <<get_item_child_loop>>
      FOR r_item_location_id IN lc_item_child_cur LOOP
        ln_ref_all_enc_qty := NVL(get_can_enc_in_time_qty2(r_item_location_id.item_location_id
                                                         , r_item_location_id.whse_code
                                                         , in_item_id
                                                         , iv_item_code
                                                         , in_lot_id), 0);
        ln_ref_in_time_enc_qty := NVL(get_can_enc_in_time_qty2(
                                                           r_item_location_id.item_location_id
                                                         , r_item_location_id.whse_code
                                                         , in_item_id
                                                         , iv_item_code
                                                         , in_lot_id
                                                         , in_active_date), 0);
        -- ��������
        ln_all_enc_qty      := ln_all_enc_qty     + ln_ref_all_enc_qty;
        ln_in_time_enc_qty  := ln_in_time_enc_qty + ln_ref_in_time_enc_qty;
      END LOOP get_child_loop;
--
    -- ��\�q�Ɂi�q�j�̏ꍇ
    ELSE
      -- �_�~�[��\�q�ɂ��擾
      lt_dummy_frequent_whse := FND_PROFILE.VALUE(cv_dummy_frequent_whse);
      -- �擾�Ɏ��s�����ꍇ
      IF ( lt_dummy_frequent_whse IS NULL ) THEN
        RAISE profile_exp ;
      END IF ;
      IF ( lv_rep_whse = lt_dummy_frequent_whse ) THEN
        BEGIN
          SELECT  xfil.frq_item_location_id
                , xfil.frq_item_location_code whse_code
          INTO    ln_inventory_location_id
                , lv_inv_whse_code
          FROM    xxwsh_frq_item_locations xfil
          WHERE   xfil.item_location_code = lv_whse_code         -- ���q��
          AND     xfil.item_id            = in_item_id           -- OPM�i��ID
          ;
--
          ln_ref_all_enc_qty := NVL(get_can_enc_in_time_qty2(ln_inventory_location_id
                                                           , lv_inv_whse_code
                                                           , in_item_id
                                                           , iv_item_code
                                                           , in_lot_id), 0);
          ln_ref_in_time_enc_qty := NVL(get_can_enc_in_time_qty2(ln_inventory_location_id
                                                               , lv_inv_whse_code
                                                               , in_item_id
                                                               , iv_item_code
                                                               , in_lot_id
                                                               , in_active_date), 0);
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_ref_all_enc_qty     := 0;
            ln_ref_in_time_enc_qty := 0;
        END;
      ELSE
        BEGIN
          SELECT  mil.inventory_location_id
                , mil.segment1 whse_code
          INTO    ln_inventory_location_id
                , lv_inv_whse_code
          FROM    mtl_item_locations  mil      -- �ۊǏꏊ
          WHERE   mil.attribute5 = lv_rep_whse -- ��\�q��
          AND     mil.segment1   = mil.attribute5
          ;
  --
          ln_ref_all_enc_qty := NVL(get_can_enc_in_time_qty2(ln_inventory_location_id
                                                           , lv_inv_whse_code
                                                           , in_item_id
                                                           , iv_item_code
                                                           , in_lot_id), 0);
          ln_ref_in_time_enc_qty := NVL(get_can_enc_in_time_qty2(ln_inventory_location_id
                                                               , lv_inv_whse_code
                                                               , in_item_id
                                                               , iv_item_code
                                                               , in_lot_id
                                                               , in_active_date), 0);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_ref_all_enc_qty := 0;
            ln_ref_in_time_enc_qty := 0;
        END;
      END IF;
--
      -- �e�P�̂̈����\�����}�C�i�X�̏ꍇ�̂ݑ�������
      IF ( ln_ref_all_enc_qty < 0 ) THEN
        ln_all_enc_qty      := ln_all_enc_qty     + ln_ref_all_enc_qty;
      END IF;
      IF ( ln_ref_in_time_enc_qty < 0 ) THEN
        ln_in_time_enc_qty  := ln_in_time_enc_qty + ln_ref_in_time_enc_qty;
      END IF;
    END IF;
--
    -- ���Ȃ����������\��
    IF ( ln_all_enc_qty < ln_in_time_enc_qty ) THEN
      ln_enc_qty := ln_all_enc_qty;
    ELSE
      ln_enc_qty := ln_in_time_enc_qty;
    END IF;
--
    -- �����\��
    RETURN ln_enc_qty;
--
  EXCEPTION
    WHEN profile_exp THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( cv_xxcmn
                                            ,cv_error_10002
                                            ,cv_tkn_ng_profile
                                            ,cv_dummy_frequent_whse
                                           ) ;
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000),TRUE);
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_can_enc_qty2;
--
  /**********************************************************************************
  * Function Name    : check_sql_pattern
  * Description      : SQL�����p�^�[���`�F�b�N�֐�
  ***********************************************************************************/
  FUNCTION check_sql_pattern(iv_kubun           IN  VARCHAR2               -- �o�ׁE�ړ��敪
                           , iv_block1          IN  VARCHAR2 DEFAULT NULL  -- �u���b�N�P
                           , iv_block2          IN  VARCHAR2 DEFAULT NULL  -- �u���b�N�Q
                           , iv_block3          IN  VARCHAR2 DEFAULT NULL  -- �u���b�N�R
                           , in_deliver_from_id IN  NUMBER   DEFAULT NULL  -- �o�Ɍ�
                           , in_deliver_type    IN  NUMBER   DEFAULT NULL) -- �o�Ɍ`��
                             RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_sql_pattern'; --�v���O������
--
    -- *** ���[�J���ϐ� ***
    ln_pattern1         NUMBER := 0;
    ln_return_pattern   NUMBER := 0;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    process_exp               EXCEPTION;     -- �e�����ŃG���[�����������ꍇ
    PRAGMA EXCEPTION_INIT(process_exp, -20001);
--
  BEGIN
    --==============================================================
    -- �C�ӓ��͂𔻒f(�o�ׂ̏ꍇ�j
    --   1 = �u���b�N1�`3 ���S��NULL
    --   2 = �o�׌� ��NULL
    --   3 = �󒍃^�C�v ��NULL
    -- �����̑g�ݍ��킹�ł̏�������у��^�[���l�͉��L�̂悤�ɂȂ�
    --   1<>, 2<>, 3<> �� (1 or 2) and 3 �� 1
    --   1= , 2= , 3<> �� 3              �� 2
    --   1= , 2<>, 3<> �� 2 and 3        �� 3
    --   1<>, 2= , 3<> �� 1 and 3        �� 4
    --   1<>, 2<>, 3=  �� 1 or 2         �� 5
    --   1= , 2= , 3=  �� �Ȃ�           �� 6
    --   1= , 2<>, 3=  �� 2              �� 7
    --   1<>, 2= , 3=  �� 1              �� 8
    -- �C�ӓ��͂𔻒f(�ړ��̏ꍇ�j===================================
    --   1 = �u���b�N1�`3 ���S��NULL
    --   2 = �o�׌� ��NULL
    -- �����̑g�ݍ��킹�ł̏�������у��^�[���l�͉��L�̂悤�ɂȂ�
    --   1<>, 2<>      �� (1 or 2)       �� 5
    --   1= , 2=       �� �Ȃ�           �� 6
    --   1= , 2<>      �� 2              �� 7
    --   1<>, 2=       �� 1              �� 8
    --==============================================================
--
    -- �u���b�N�P�`�R�S�Ă�NULL���H
    IF ((iv_block1 IS NULL) AND (iv_block2 IS NULL) AND (iv_block3 IS NULL)) THEN
      ln_pattern1 := 1;
    END IF;
--
    -- �u�o�ׁv�̏ꍇ
    IF( iv_kubun = gv_cons_biz_t_deliv) THEN
      -- �p�^�[���P
      IF ((ln_pattern1 <> 1 ) AND
          (in_deliver_from_id IS NOT NULL) AND
          (in_deliver_type IS NOT NULL))
      THEN
        RETURN 1;
      END IF;
--
      -- �p�^�[���Q
      IF ( ( ln_pattern1 = 1 ) AND ( in_deliver_from_id IS NULL ) AND ( in_deliver_type IS NOT NULL ) )
      THEN
        RETURN 2;
      END IF;
--
      -- �p�^�[���R
      IF ( ( ln_pattern1 = 1 ) AND ( in_deliver_from_id IS NOT NULL ) AND ( in_deliver_type IS NOT NULL ) )
      THEN
        RETURN 3;
      END IF;
--
      -- �p�^�[���S
      IF ( ( ln_pattern1 <> 1 ) AND ( in_deliver_from_id IS NULL ) AND ( in_deliver_type IS NOT NULL ) )
      THEN
        RETURN 4;
      END IF;
--
      -- �p�^�[���T
      IF ( ( ln_pattern1 <> 1 ) AND ( in_deliver_from_id IS NOT NULL ) AND ( in_deliver_type IS NULL ) )
      THEN
        RETURN 5;
      END IF;
--
      -- �p�^�[���U
      IF ( ( ln_pattern1 = 1 ) AND ( in_deliver_from_id IS NULL ) AND ( in_deliver_type IS NULL ) )
      THEN
        RETURN 6;
      END IF;
--
      -- �p�^�[���V
      IF ( ( ln_pattern1 = 1) AND ( in_deliver_from_id IS NOT NULL ) AND ( in_deliver_type IS NULL ) )
      THEN
        RETURN 7;
      END IF;
--
      -- �p�^�[���W
      IF ( (ln_pattern1 <> 1) AND ( in_deliver_from_id IS NULL ) AND ( in_deliver_type IS NULL ) )
      THEN
        RETURN 8;
      END IF;
--
    -- �u�ړ��v�̏ꍇ
    ELSE
      -- �p�^�[���T
      IF ( ( ln_pattern1 <> 1 ) AND ( in_deliver_from_id IS NOT NULL ) )
      THEN
        RETURN 5;
      END IF;
--
      -- �p�^�[���U
      IF ( ( ln_pattern1 = 1 ) AND ( in_deliver_from_id IS NULL ) )
      THEN
        RETURN 6;
      END IF;
--
      -- �p�^�[���V
      IF ( ( ln_pattern1 = 1 ) AND ( in_deliver_from_id IS NOT NULL ) )
      THEN
        RETURN 7;
      END IF;
--
      -- �p�^�[���W
      IF ( ( ln_pattern1 <> 1 ) AND ( in_deliver_from_id IS NULL ) )
      THEN
        RETURN 8;
      END IF;
    END IF;
    RAISE process_exp;
--
  EXCEPTION
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END check_sql_pattern;
--
  /**********************************************************************************
  * Function Name    : fwd_sql_create
  * Description      : A-3  �o�חpSQL���쐬�֐�
  ***********************************************************************************/
  FUNCTION fwd_sql_create(iv_block1          IN  VARCHAR2 DEFAULT NULL -- �u���b�N�P
                        , iv_block2          IN  VARCHAR2 DEFAULT NULL -- �u���b�N�Q
                        , iv_block3          IN  VARCHAR2 DEFAULT NULL -- �u���b�N�R
                        , in_deliver_from_id IN  NUMBER   DEFAULT NULL -- �o�Ɍ�
                        , in_deliver_type    IN  NUMBER   DEFAULT NULL -- �o�Ɍ`��
                        , iv_item_code       IN  VARCHAR2)             -- �i�ڃR�[�h
                          RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'fwd_sql_create'; --�v���O������
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    process_exp               EXCEPTION;     -- �e�����ŃG���[�����������ꍇ
    PRAGMA EXCEPTION_INIT(process_exp, -20001);
-- 
    -- *** ���[�J���ϐ� ***
    ln_pattern     NUMBER := 0;
    lv_fwd_sql     VARCHAR2(5000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_fwd_sql1    VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_fwd_sql2    VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_fwd_sql3    VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_fwd_sql4    VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_fwd_sql5    VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_fwd_sql6    VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_fwd_sql7    VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_fwd_sql8    VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_fwd_sql9    VARCHAR2(2000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_fwd_sql10   VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_fwd_sql11   VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_fwd_sql12   VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_fwd_sql13   VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
--
  BEGIN
    -- SQL�����p�^�[���`�F�b�N
    ln_pattern := check_sql_pattern(gv_cons_biz_t_deliv
                                  , iv_block1
                                  , iv_block2
                                  , iv_block3
                                  , in_deliver_from_id
                                  , in_deliver_type);
    -- SQL���g�ݗ���(1�`10�܂ł��Œ蕔��)
    lv_fwd_sql1 := 'SELECT ' || ' :para_cons_biz_t_deliv, ' || -- �u�o�׈˗��v
                          'oh.request_no, '                 || -- �˗�No
                          'il.distribution_block, '         || -- �����u���b�N
                          'oh.deliver_from, '               || -- �o�Ɍ�
                          'oh.deliver_from_id, '            || -- �o�Ɍ�ID
                          'oh.schedule_ship_date,';            -- �o�ɗ\���
    lv_fwd_sql2 :=        'oh.schedule_arrival_date, '      || -- ���ɗ\���
                          'oh.order_header_id, '            || -- �w�b�_�A�h�I��ID
                          'oh.deliver_to, '                 || -- �z����
                          'oh.deliver_to_id, '              || -- �z����ID
                          'p.reserve_order, ';                 -- ���_������
    lv_fwd_sql3 :=        'ol.order_line_id,         '      || -- �󒍖��׃A�h�I��ID
                          'ol.shipping_item_code, '         || -- �i��(�R�[�h)
                          ' im.item_id, '                   || -- OPM�i��ID
                          'ol.quantity, '                   || -- �w������
                          'ol.quantity - NVL(ol.reserved_quantity,0), '; -- �����c����
    lv_fwd_sql4 :=        'NVL(ol.reserved_quantity,0), '          || -- ��������
                          'ol.designated_production_date, ' || -- �w�萻����
                          'NULL, '                          || -- ��\�q�ɋ敪
                          'NULL, '                          || -- ��\�q��
                          'NULL, ';                            -- ��\�ۊǒIID
    lv_fwd_sql5 :=        'im.num_of_cases, '               || -- �P�[�X����
                          'im.conv_unit '                   || -- ���o�Ɋ��Z�P��
                   'FROM   xxcmn_item_locations2_v       il, ' || -- OPM�ۊǏꏊ�}�X�^
                          'xxwsh_order_headers_all       oh, ' || -- �󒍃w�b�_�A�h�I��
                          'xxcmn_cust_accounts2_v        p,  ';
                                                        -- �p�[�e�B�A�h�I���}�X�^ , �p�[�e�B�}�X�^
    lv_fwd_sql6 :=        'xxwsh_oe_transaction_types2_v tt, ' || -- �󒍃^�C�v
                          'xxwsh_order_lines_all         ol, ' || -- �󒍖��׃A�h�I��
                          'xxcmn_item_mst2_v             im, ' || -- OPM�i�ڃ}�X�^
                          'xxcmn_item_categories5_v      ic ';
          -- �i�ڃJ�e�S���Z�b�g , �i�ڃJ�e�S���}�X�^ , OPM�i�ڃJ�e�S������ , OPM�i�ڃJ�e�S���}�X�^
    lv_fwd_sql7 := 'WHERE  il.inventory_location_id = oh.deliver_from_id ' ||
                     'AND  oh.schedule_ship_date >= TO_DATE('
                        || ' :para_yyyymmdd_from, ''YYYY/MM/DD'') ' ||
                     'AND  oh.schedule_ship_date <= TO_DATE('
                        || ' :para_yyyymmdd_to, ''YYYY/MM/DD'') ' ||
                     'AND  p.party_number = oh.head_sales_branch '   ||
                     'AND  p.start_date_active <= oh.schedule_ship_date ';
    lv_fwd_sql8 :=   'AND  p.end_date_active >= oh.schedule_ship_date '  ||
                     'AND  p.customer_class_code = :para_base ' ||
                     'AND  oh.order_type_id = tt.transaction_type_id ' ||
                     'AND  tt.shipping_shikyu_class = :para_cons_t_deliv ' ||
                     'AND  oh.req_status = :para_cons_status ' ||
                     'AND  NVL(oh.notif_status, :para_wzero ) <> :para_cons_notif_status ';
    lv_fwd_sql9 :=   'AND  oh.latest_external_flag = :para_cons_flg_yes ' ||
                     'AND  ol.order_header_id = oh.order_header_id '     ||
                     'AND  ol.shipping_item_code IN (' || gv_item_code_list || ')' ||
                     'AND NVL(ol.delete_flag, :para_flg_no ) <> :para_cons_flg_yes ' ||
                     'AND  il.date_from             <= oh.schedule_ship_date ' ||
          'AND ((il.date_to >= oh.schedule_ship_date) OR (il.date_to IS NULL)) ' ||
                     'AND  tt.start_date_active     <= oh.schedule_ship_date ' ||
          'AND ((tt.end_date_active >= oh.schedule_ship_date) OR (tt.end_date_active IS NULL)) ' ||
                     'AND  im.start_date_active     <= oh.schedule_ship_date ' ||
          'AND ((im.end_date_active >= oh.schedule_ship_date) OR (im.end_date_active IS NULL)) ' ||
                     'AND  ol.automanual_reserve_class IS NULL '               ||
                     'AND  im.item_id = ic.item_id '                           ||
                     'AND  im.item_no = ol.shipping_item_code ';
    lv_fwd_sql10 :=  'AND  im.lot_ctl = :para_cons_lot_ctl ' ||
                     'AND  ic.item_class_code = :para_cons_item_product ' ||
                     'AND  ic.prod_class_code = :para_item_class ';
    -- sql�ϐ��̍���1
    lv_fwd_sql := lv_fwd_sql1 || lv_fwd_sql2 || lv_fwd_sql3 || lv_fwd_sql4 || lv_fwd_sql5  ||
                  lv_fwd_sql6 || lv_fwd_sql7 || lv_fwd_sql8 || lv_fwd_sql9 || lv_fwd_sql10;
    -- SQL���g�ݗ���(11�`13�܂ł��ϓ�����)
    CASE ln_pattern
      WHEN 1 THEN
        lv_fwd_sql11 := 'AND ((il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                               '''' || iv_block2 || '''' || ',' ||
                                                               '''' || iv_block3 || '''' || '))';
        lv_fwd_sql12 := '  OR (oh.deliver_from = ' || in_deliver_from_id || ')) ';
        lv_fwd_sql13 := 'AND oh.order_type_id  = ' || in_deliver_type ;
        -- sql�ϐ��̍���2
        lv_fwd_sql := lv_fwd_sql || lv_fwd_sql11 || lv_fwd_sql12 || lv_fwd_sql13;
      WHEN 2 THEN
        lv_fwd_sql13 := 'AND oh.order_type_id  = ' || in_deliver_type ;
        -- sql�ϐ��̍���2
        lv_fwd_sql := lv_fwd_sql || lv_fwd_sql13;
      WHEN 3 THEN
        lv_fwd_sql12 := 'AND oh.deliver_from   = ' || in_deliver_from_id || ' ';
        lv_fwd_sql13 := 'AND oh.order_type_id  = ' || in_deliver_type ;
        -- sql�ϐ��̍���2
        lv_fwd_sql := lv_fwd_sql || lv_fwd_sql12 || lv_fwd_sql13;
      WHEN 4 THEN
        lv_fwd_sql11 := 'AND il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                             '''' || iv_block2 || '''' || ',' ||
                                                             '''' || iv_block3 || '''' || ') ';
        lv_fwd_sql13 := 'AND oh.order_type_id  = ' || in_deliver_type ;
        -- sql�ϐ��̍���2
        lv_fwd_sql := lv_fwd_sql || lv_fwd_sql11 || lv_fwd_sql13;
      WHEN 5 THEN
        lv_fwd_sql11 := 'AND ((il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                               '''' || iv_block2 || '''' || ',' ||
                                                               '''' || iv_block3 || '''' || '))';
        lv_fwd_sql12 := '  OR (oh.deliver_from = ' || in_deliver_from_id || ')) ';
        -- sql�ϐ��̍���2
        lv_fwd_sql := lv_fwd_sql || lv_fwd_sql11 || lv_fwd_sql12;
      --WHEN 6 �͏����ǉ��Ȃ�
      WHEN 7 THEN
        lv_fwd_sql12 := 'AND oh.deliver_from   = ' || in_deliver_from_id ;
        -- sql�ϐ��̍���2
        lv_fwd_sql := lv_fwd_sql || lv_fwd_sql12;
      WHEN 8 THEN
        lv_fwd_sql11 := 'AND il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                             '''' || iv_block2 || '''' || ',' ||
                                                             '''' || iv_block3 || '''' || ') ';
        -- sql�ϐ��̍���2
        lv_fwd_sql := lv_fwd_sql || lv_fwd_sql11;
      ELSE NULL;
    END CASE;
--
    -- ORDER��̍���3
    lv_fwd_sql := lv_fwd_sql || ' ORDER BY ol.shipping_item_code, oh.schedule_ship_date,' ||
                                ' oh.schedule_arrival_date, il.distribution_block, '      ||
                                'oh.deliver_from, NVL(ol.designated_production_date,TO_DATE(''' || gv_min_default_date || ''',''YYYY/MM/DD'')) DESC, ' ||
                                ' p.reserve_order, oh.head_sales_branch, oh.deliver_to,oh.arrival_time_from, ' ||
                                ' oh.request_no ';
    -- FOR��̍���4
-- 2008/11/29 v1.2 mod start
--    lv_fwd_sql := lv_fwd_sql || ' FOR UPDATE OF ol.order_line_id NOWAIT';
    lv_fwd_sql := lv_fwd_sql || ' FOR UPDATE OF ol.order_line_id ';
-- 2008/11/29 v1.2 mod end
--
    -- �쐬����SQL����Ԃ�
    RETURN lv_fwd_sql;
--
  EXCEPTION
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END fwd_sql_create;
--
  /**********************************************************************************
  * Function Name    : mov_sql_create
  * Description      : A-5  �ړ��pSQL���쐬�֐�
  ***********************************************************************************/
  FUNCTION mov_sql_create(iv_block1          IN  VARCHAR2 DEFAULT NULL -- �u���b�N�P
                        , iv_block2          IN  VARCHAR2 DEFAULT NULL -- �u���b�N�Q
                        , iv_block3          IN  VARCHAR2 DEFAULT NULL -- �u���b�N�R
                        , in_deliver_from_id IN  NUMBER   DEFAULT NULL -- �o�Ɍ�
                        , in_deliver_type    IN  NUMBER   DEFAULT NULL -- �o�Ɍ`��
                        , iv_item_code       IN  VARCHAR2)             -- �i�ڃR�[�h
                          RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mov_sql_create'; --�v���O������
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    process_exp               EXCEPTION;     -- �e�����ŃG���[�����������ꍇ
    PRAGMA EXCEPTION_INIT(process_exp, -20001);
--
    -- *** ���[�J���ϐ� ***
    ln_pattern     NUMBER := 0;
    lv_mov_sql     VARCHAR2(5000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_mov_sql1    VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_mov_sql2    VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_mov_sql3    VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_mov_sql4    VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_mov_sql5    VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_mov_sql6    VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_mov_sql7    VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_mov_sql8    VARCHAR2(2000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_mov_sql9    VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_mov_sql11   VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_mov_sql12   VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
    lv_mov_sql13   VARCHAR2(1000);    -- �o�חpSQL���i�[�o�b�t�@
--
  BEGIN
    -- SQL�����p�^�[���`�F�b�N
    ln_pattern := check_sql_pattern(gv_cons_biz_t_move
                                  , iv_block1
                                  , iv_block2
                                  , iv_block3
                                  , in_deliver_from_id
                                  , in_deliver_type);
    -- SQL���g�ݗ���(1�`10�܂ł��Œ蕔��)
    lv_mov_sql1 := 'SELECT ' || ' :para_cons_biz_t_move, '  || -- �u�ړ��w���v
                          'ih.mov_num, '                    || -- �ړ��ԍ�
                          'il.distribution_block, '         || -- �����u���b�N
                          'ih.shipped_locat_code, '         || -- �o�Ɍ�
                          'ih.shipped_locat_id, '           || -- �o�Ɍ�ID
                          'ih.schedule_ship_date,';            -- �o�ɗ\���
    lv_mov_sql2 :=        'ih.schedule_arrival_date, '      || -- ���ɗ\���
                          'ih.mov_hdr_id, '                 || -- �ړ��w�b�_ID
                          'ih.ship_to_locat_code, '         || -- ���ɐ�
                          'ih.ship_to_locat_id, '           || -- ���ɐ�ID
                          'NULL, ';                            -- ���_������
    lv_mov_sql3 :=        'ml.mov_line_id, '                || -- �ړ�����ID
                          'ml.item_code, '                  || -- �i��(�R�[�h)
                          'im.item_id, '                    || -- OPM�i��ID
                          'ml.instruct_qty, '               || -- �w������
                          'ml.instruct_qty - NVL(ml.reserved_quantity,0), '; -- �����c����
    lv_mov_sql4 :=        'NVL(ml.reserved_quantity,0), '          || -- ��������
                          'ml.designated_production_date, ' || -- �w�萻����
                          'NULL, '                          || -- ��\�q�ɋ敪
                          'NULL, '                          || -- ��\�q��
                          'NULL, ';                            -- ��\�ۊǒIID
    lv_mov_sql5 :=        'im.num_of_cases, '               || -- �P�[�X����
                          'im.conv_unit '                   || -- ���o�Ɋ��Z�P��
                   'FROM   xxcmn_item_locations2_v       il, ' || -- OPM�ۊǏꏊ�}�X�^
                          'xxinv_mov_req_instr_headers   ih, ';   -- �ړ��˗�/�w���w�b�_�A�h�I��
    lv_mov_sql6 :=        'xxinv_mov_req_instr_lines     ml, ' || -- �ړ��˗�/�w�����׃A�h�I��
                          'xxcmn_item_mst2_v             im, ' || -- OPM�i�ڃ}�X�^
                          'xxcmn_item_categories5_v      ic ';
    lv_mov_sql7 := 'WHERE  il.inventory_location_id = ih.shipped_locat_id ' ||
                     'AND  ih.mov_type = :para_cons_move_type ' ||
                     'AND  ih.schedule_ship_date >= TO_DATE('
                        || ' :para_yyyymmdd_from, ''YYYY/MM/DD'') ' ||
                     'AND  ih.schedule_ship_date <= TO_DATE('
                        || ' :para_yyyymmdd_to, ''YYYY/MM/DD'') ' ||
                     'AND  ((ih.status = :para_cons_mov_sts_c ) ';
    lv_mov_sql8 :=   '   OR (ih.status = :para_cons_mov_sts_e )) ' ||
                     'AND  NVL(ih.notif_status, :para_wzero ) <> :para_cons_notif_status ' ||
                     'AND  ml.mov_hdr_id = ih.mov_hdr_id '         ||
                     'AND  ml.item_code IN (' || gv_item_code_list || ')' ||
                     'AND NVL(ml.delete_flg, :para_flg_no ) <> :para_cons_flg_yes ' ||
                     'AND  il.date_from             <= ih.schedule_ship_date ' ||
          'AND ((il.date_to >= ih.schedule_ship_date) OR (il.date_to IS NULL)) ' ||
                     'AND  im.start_date_active     <= ih.schedule_ship_date ' ||
          'AND ((im.end_date_active >= ih.schedule_ship_date) OR (im.end_date_active IS NULL)) ' ||
                     'AND  ml.automanual_reserve_class IS NULL ';
    lv_mov_sql9 :=   'AND  im.item_no         = ml.item_code '          ||
                     'AND  im.item_id = ic.item_id '                           ||
                     'AND  im.lot_ctl         = :para_cons_lot_ctl ' ||
                     'AND  ic.item_class_code = :para_cons_item_product ' ||
                     'AND  ic.prod_class_code = :para_item_class ';
    -- sql�ϐ��̍���1
    lv_mov_sql := lv_mov_sql1 || lv_mov_sql2 || lv_mov_sql3 || lv_mov_sql4 || lv_mov_sql5  ||
                  lv_mov_sql6 || lv_mov_sql7 || lv_mov_sql8 || lv_mov_sql9;
    -- SQL���g�ݗ���(11�`13�܂ł��ϓ�����)
    CASE ln_pattern
      WHEN 5 THEN
        lv_mov_sql11 := 'AND ((il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                               '''' || iv_block2 || '''' || ',' ||
                                                               '''' || iv_block3 || '''' || '))';
        lv_mov_sql12 := '  OR (ih.shipped_locat_id = ' || in_deliver_from_id || ')) ';
        -- sql�ϐ��̍���2
        lv_mov_sql := lv_mov_sql || lv_mov_sql11 || lv_mov_sql12;
      --WHEN 6 �͏����ǉ��Ȃ�
      WHEN 7 THEN
         lv_mov_sql12 := 'AND ih.shipped_locat_code   = ' || in_deliver_from_id ;
        -- sql�ϐ��̍���2
        lv_mov_sql := lv_mov_sql || lv_mov_sql12;
      WHEN 8 THEN
        lv_mov_sql11 := 'AND il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                             '''' || iv_block2 || '''' || ',' ||
                                                             '''' || iv_block3 || '''' || ') ';
        -- sql�ϐ��̍���2
        lv_mov_sql := lv_mov_sql || lv_mov_sql11;
      ELSE NULL;
    END CASE;
--
    lv_mov_sql := lv_mov_sql || ' ORDER BY ml.item_code, ih.schedule_ship_date,' ||
                                ' ih.schedule_arrival_date, il.distribution_block, '      ||
                                ' ih.shipped_locat_code, NVL(ml.designated_production_date,TO_DATE(''' || gv_min_default_date || ''',''YYYY/MM/DD'')) DESC, ' ||
                                ' ih.arrival_time_from, ih.mov_num ';
    -- FOR��̍���4
-- 2008/11/29 v1.2 mod start
--    lv_mov_sql := lv_mov_sql || ' FOR UPDATE OF ml.mov_line_id NOWAIT';
    lv_mov_sql := lv_mov_sql || ' FOR UPDATE OF ml.mov_line_id ';
-- 2008/11/29 v1.2 mod end
--
    -- �쐬����SQL����Ԃ�
    RETURN lv_mov_sql;
--
  EXCEPTION
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END mov_sql_create;
--
  /**********************************************************************************
   * Procedure Name   : check_parameter
   * Description      : A-1  ���̓p�����[�^�`�F�b�N
   ***********************************************************************************/
  PROCEDURE check_parameter(
      iv_item_class         IN         VARCHAR2     -- ���i�敪
    , iv_deliver_date_from  IN         VARCHAR2     -- �o�ɓ�From
    , iv_deliver_date_to    IN         VARCHAR2     -- �o�ɓ�To
    , iv_item_code          IN         VARCHAR2     -- �i�ڃR�[�h
    , ov_errbuf             OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode            OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg             OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ************************************
    -- ***  ���̓p�����[�^�K�{�`�F�b�N  ***
    -- ************************************
    -- ���i�敪�̓��͂��Ȃ��ꍇ�̓G���[�Ƃ���
    IF ( iv_item_class IS NULL ) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn -- 'XXCMN'
                                                   , gv_msg_92a_002    -- �K�{���̓p�����[�^�G���[
                                                   , gv_tkn_param_name    -- �g�[�N��'PARAM_NAME'
                                                   , gv_cons_item_class) -- '���i�敪'
                                                   , 1
                                                   , 5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- �o�ɓ�From�̓��͂��Ȃ��ꍇ�̓G���[�Ƃ���
    IF ( iv_deliver_date_from IS NULL ) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn -- 'XXCMN'
                                                   , gv_msg_92a_002    -- �K�{���̓p�����[�^�G���[
                                                   , gv_tkn_param_name    -- �g�[�N��'PARAM_NAME'
                                                   , gv_cons_deliv_from) -- '�o�ɓ�From'
                                                   , 1
                                                   , 5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- �o�ɓ�To�̓��͂��Ȃ��ꍇ�̓G���[�Ƃ���
    IF ( iv_deliver_date_to IS NULL ) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn -- 'XXCMN'
                                                   , gv_msg_92a_002    -- �K�{���̓p�����[�^�G���[
                                                   , gv_tkn_param_name  -- �g�[�N��'PARAM_NAME'
                                                   , gv_cons_deliv_to) -- '�o�ɓ�To'
                                                   , 1
                                                   , 5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
    -- �i�ڃR�[�h�̓��͂��Ȃ��ꍇ�̓G���[�Ƃ���
    IF ( iv_item_code IS NULL ) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn -- 'XXCMN'
                                                   , gv_msg_92a_002    -- �K�{���̓p�����[�^�G���[
                                                   , gv_tkn_param_name  -- �g�[�N��'PARAM_NAME'
                                                   , gv_cons_item_no) -- '�i�ڃR�[�h'
                                                   , 1
                                                   , 5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- ******************************
    -- ***  �Ώۊ��ԏ����`�F�b�N  ***
    -- ******************************
    -- �o�ɓ�From��YYYY/MM/DD�̌^�ɕϊ�(NULL���A���Ă�����G���[�j
    gv_yyyymmdd_from := iv_deliver_date_from;
    gd_yyyymmdd_from := FND_DATE.STRING_TO_DATE(iv_deliver_date_from, 'YYYY/MM/DD');
    IF ( gd_yyyymmdd_from IS NULL ) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                   , gv_msg_92a_003    -- ���̓p�����[�^�����G���[
                                                   , gv_tkn_parm_name  -- �g�[�N��'PARM_NAME'
                                                   , gv_cons_deliv_from) -- '�o�ɓ�From'
                                                   , 1
                                                   , 5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- �o�ɓ�From��YYYY/MM/DD�̌^�ɕϊ�(NULL���A���Ă�����G���[�j
    gv_yyyymmdd_to := iv_deliver_date_to;
    gd_yyyymmdd_to := FND_DATE.STRING_TO_DATE(iv_deliver_date_to, 'YYYY/MM/DD');
    IF ( gd_yyyymmdd_to IS NULL ) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                   , gv_msg_92a_003    -- ���̓p�����[�^�����G���[
                                                   , gv_tkn_parm_name  -- �g�[�N��'PARM_NAME'
                                                   , gv_cons_deliv_to)   -- '�o�ɓ�To'
                                                   , 1
                                                   , 5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- ******************************
    -- ***  �Ώۊ��ԋt�]�`�F�b�N  ***
    -- ******************************
    -- �o�ɓ�From�Əo�ɓ�To���t�]���Ă�����G���[
    IF ( gd_yyyymmdd_from > gd_yyyymmdd_to ) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                   , gv_msg_92a_004)    -- ���̓p�����[�^�����G���[
                                                   , 1
                                                   , 5000);
      -- �G���[���^�[�����������~
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
  END check_parameter;
-- 2008/11/13 M.Hokkanji START
--
  /**********************************************************************************
   * Procedure Name   : get_item_code_list
   * Description      : A-2  �i�ڃ��X�g�擾
   ***********************************************************************************/
  PROCEDURE get_item_code_list(
    iv_item_code       IN  VARCHAR2,            -- �i�ڃR�[�h
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_code_list'; -- �v���O������
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
    cn_max_cnt  CONSTANT NUMBER := 100; -- MAXCOUNT
    cn_cnt_0    CONSTANT NUMBER := 0;   -- �Ώەi�ڌ���0
--
    -- *** ���[�J���ϐ� ***
    ln_cnt      NUMBER := 0;            -- �����J�E���g�p
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cur_item_list IS
      SELECT ximv.item_no
      FROM   xxcmn_item_mst_v ximv
      WHERE  LEVEL <= 2
      START WITH ximv.item_no = iv_item_code
     CONNECT BY NOCYCLE PRIOR ximv.item_id = ximv.parent_item_id;
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
    gv_item_code_list := NULL;
    FOR rec_item_list IN cur_item_list LOOP
      ln_cnt := ln_cnt + 1;
      IF ( gv_item_code_list IS NULL ) THEN
        gv_item_code_list := '''' || rec_item_list.item_no || '''';
      ELSE
        gv_item_code_list := gv_item_code_list || ',' || '''' || rec_item_list.item_no || '''';
      END IF;
    END LOOP;
--
    -- �Ώەi�ڂ�0��
    IF ( ln_cnt = cn_cnt_0 ) THEN
      -- TODO �G���[���b�Z�[�W��`
      lv_errmsg := '�Ώی�����0���ł��B';
      RAISE global_api_expt;
--
    -- �Ώەi�ڂ�100�����傫���ꍇ
    ELSIF ( ln_cnt > cn_max_cnt ) THEN
      -- TODO �G���[���b�Z�[�W��`
      lv_errmsg := '�Ώی�����100���𒴂��Ă��܂��B';
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
  END get_item_code_list;
--
-- 2008/11/13 M.Hokkanji End
--
  /**********************************************************************************
   * Procedure Name   : get_demand_inf_fwd
   * Description      : A-4  ���v���擾(�o��)
   ***********************************************************************************/
  PROCEDURE get_demand_inf_fwd(
    iv_fwd_sql    IN  VARCHAR2,     -- �o�חpSQL��
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_demand_inf_fwd'; -- �v���O������
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
    lr_demand_tbl  demand_tbl;
--
    -- *** ���[�J���E�J�[�\�� ***
    TYPE cursor_type IS REF CURSOR;
    fwd_cur cursor_type;
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
-- Ver1.01 M.Hokkanji Start
    FND_FILE.PUT_LINE(FND_FILE.LOG,iv_fwd_sql);
-- Ver1.01 M.Hokkanji End
    -- �J�[�\���I�[�v��
    OPEN fwd_cur FOR iv_fwd_sql USING gv_cons_biz_t_deliv
                                    , gv_yyyymmdd_from
                                    , gv_yyyymmdd_to
                                    , gv_base
                                    , gv_cons_t_deliv
                                    , gv_cons_status
                                    , gv_wzero
                                    , gv_cons_notif_status
                                    , gv_cons_flg_yes
                                    , gv_flg_no
                                    , gv_cons_flg_yes
                                    , gv_cons_lot_ctl
                                    , gv_cons_item_product
                                    , gv_item_class
                                      ;
    -- �f�[�^�̈ꊇ�擾
    FETCH fwd_cur BULK COLLECT INTO gr_demand_tbl;
--
    -- ���������̃Z�b�g
    gn_target_cnt_deliv := gr_demand_tbl.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE fwd_cur;
--
  EXCEPTION
    WHEN lock_expt THEN                           --*** ���b�N�r�W�[ ***
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh        -- 'XXWSH'
                                                   , gv_msg_92a_005       -- �e�[�u�����b�N�G���[
                                                   , gv_tkn_table         -- �g�[�N��'TABLE'
                                                   , gv_cons_order_lines) -- �󒍖��׃A�h�I��
                                                   , 1
                                                   , 5000);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
      CLOSE fwd_cur;  -- �J�[�\���N���[�Y
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      CLOSE fwd_cur;  -- �J�[�\���N���[�Y
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      CLOSE fwd_cur;  -- �J�[�\���N���[�Y
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      CLOSE fwd_cur;  -- �J�[�\���N���[�Y
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_demand_inf_fwd;
--
  /**********************************************************************************
   * Procedure Name   : get_demand_inf_mov
   * Description      : A-4  ���v���擾(�ړ�)
   ***********************************************************************************/
  PROCEDURE get_demand_inf_mov(
    iv_mov_sql    IN  VARCHAR2,     -- �ړ��pSQL��
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_demand_inf_mov'; -- �v���O������
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
    lr_demand_tbl  demand_tbl2;
--
    -- *** ���[�J���E�J�[�\�� ***
    TYPE cursor_type IS REF CURSOR;
    mov_cur cursor_type;
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
-- Ver1.01 M.Hokkanji Start
    FND_FILE.PUT_LINE(FND_FILE.LOG,iv_mov_sql);
-- Ver1.01 M.Hokkanji End
    -- �J�[�\���I�[�v��
    OPEN mov_cur FOR iv_mov_sql USING gv_cons_biz_t_move
                                    , gv_cons_move_type
                                    , gv_yyyymmdd_from
                                    , gv_yyyymmdd_to
                                    , gv_cons_mov_sts_c
                                    , gv_cons_mov_sts_e
                                    , gv_wzero
                                    , gv_cons_notif_status
                                    , gv_flg_no
                                    , gv_cons_flg_yes
                                    , gv_cons_lot_ctl
                                    , gv_cons_item_product
                                    , gv_item_class
                                      ;
--
    -- �o�ׂ̏�񂪂������ꍇ�͈�Ugr_demand_tbl2�Ƀf�[�^���i�[����
    -- ���gr_demand_tbl�ɍ��̂���B
    -- �f�[�^�̈ꊇ�擾
    FETCH mov_cur BULK COLLECT INTO gr_demand_tbl2;
    -- ���������̃Z�b�g
    gn_target_cnt_move := gr_demand_tbl2.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE mov_cur;
--
  EXCEPTION
    WHEN lock_expt THEN                           --*** ���b�N�r�W�[ ***
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                    ,gv_msg_92a_005       -- �e�[�u�����b�N�G���[
                                                    ,gv_tkn_table         -- �g�[�N��'TABLE'
                                                    ,gv_cons_instr_lines) -- �ړ��˗�/�w�����׃A�h�I��
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
      CLOSE mov_cur;  -- �J�[�\���N���[�Y
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      CLOSE mov_cur;  -- �J�[�\���N���[�Y
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      CLOSE mov_cur;  -- �J�[�\���N���[�Y
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      CLOSE mov_cur;  -- �J�[�\���N���[�Y
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_demand_inf_mov;
--
  /**********************************************************************************
   * Procedure Name   : get_supply_inf
   * Description      : A-5  �������擾
   ***********************************************************************************/
  PROCEDURE get_supply_inf(
    in_opm_whse_id   IN  NUMBER,       -- OPM�ۊǑq��ID
    iv_whse_code     IN  VARCHAR2,     -- OPM�ۊǑq�ɃR�[�h
    in_opm_item_id   IN  NUMBER,       -- OPM�i��ID
    iv_item_code     IN  VARCHAR2,     -- OPM�i�ڃR�[�h
    in_lot_id        IN  NUMBER,       -- ���b�gID
    id_active_date   IN  DATE,         -- �L����
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_supply_inf'; -- �v���O������
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
    ln_cnt         NUMBER := 0;
    ln_supply_cnt  NUMBER := 0;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR lc_supply_cur
    IS
      SELECT lm.lot_id               -- ���b�gID
           , lm.lot_no               -- ���b�gNo
           , lm.attribute23          -- ���b�g�X�e�[�^�X
           , lm.attribute1           -- �����N����
           , lm.attribute2           -- �ŗL�L��
           , lm.attribute3           -- �ܖ�����
           , NULL                    -- �����\��(��ŃZ�b�g����)
      FROM   ic_lots_mst         lm  -- ���b�g�}�X�^
           , xxcmn_lot_status_v  ls  -- ���b�g�X�e�[�^�XView
      WHERE  lm.item_id           = in_opm_item_id          -- ���v���.OPM�i��ID
        AND  lm.attribute23       = ls.lot_status           -- ���b�g�X�e�[�^�X
        AND  ls.prod_class_code   = gv_item_class           -- ���̓p�����[�^.���i�敪
        AND  ((ls.move_inst_a_reserve = 'Y') OR (ls.ship_req_a_reserve = 'Y')) -- �o��(����)���ړ�(����)��'Y'
      ORDER BY lm.attribute1 ASC,
               lm.attribute2 ASC; 
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
    -- �J�[�\���I�[�v��
    OPEN lc_supply_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH lc_supply_cur BULK COLLECT INTO gr_supply_tbl;
--
    -- �J�[�\���N���[�Y
    CLOSE lc_supply_cur;
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
      CLOSE lc_supply_cur;  -- �J�[�\���N���[�Y
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      CLOSE lc_supply_cur;  -- �J�[�\���N���[�Y
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      CLOSE lc_supply_cur;  -- �J�[�\���N���[�Y
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_supply_inf;
--
  /**********************************************************************************
   * Function Name   : check_lot_allot
   * Description     : A-6  ���b�g�����`�F�b�N
   **********************************************************************************/
  FUNCTION check_lot_allot(in_d_cnt   IN  NUMBER,    -- ���v��񏈗��J�E���^
                           in_s_cnt   IN  NUMBER)    -- ������񏈗��J�E���^
           RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_lot_allot'; --�v���O������
--
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_case_num  NUMBER := 0;
    lv_ship_req   xxcmn_lot_status_v.ship_req_a_reserve%TYPE;
    lv_move_inst  xxcmn_lot_status_v.move_inst_a_reserve%TYPE;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    process_exp               EXCEPTION;     -- �e�����ŃG���[�����������ꍇ
    PRAGMA EXCEPTION_INIT(process_exp, -20001);
--
  BEGIN
--
-- Ver1.01 M.Hokkanji Start
    -- �w�����ʂ�0�̏ꍇ
    IF (gr_demand_tbl(in_d_cnt).ordered_quantity = 0)THEN
      -- �����͂����Ȃ�Ȃ�
      RETURN 1;
    END IF;
-- Ver1.01 M.Hokkanji End
    BEGIN
      -- �o�׎w��(����)�A�ړ��w��(����)����������
      SELECT ls.ship_req_a_reserve
           , ls.move_inst_a_reserve
      INTO   lv_ship_req,
             lv_move_inst
      FROM   xxcmn_lot_status_v  ls
      WHERE  ls.lot_status      = gr_supply_tbl(in_s_cnt).lot_status  -- ���b�g�X�e�[�^�X
      AND    ls.prod_class_code = gv_item_class                       -- ���i�敪
      ;  
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE process_exp;
    END;
--
    -- ���v��񂪏o�ׂ̏ꍇ
    IF ( gr_demand_tbl(in_d_cnt).document_type_code = gv_cons_biz_t_deliv ) THEN
      -- 'Y'�ȊO�̏ꍇ
      IF ( lv_ship_req <> gv_cons_flg_yes ) THEN
        -- �����͂����Ȃ�Ȃ�
        RETURN 1;
      END IF;
    -- ���v��񂪈ړ��̏ꍇ
    ELSIF ( gr_demand_tbl(in_d_cnt).document_type_code = gv_cons_biz_t_move ) THEN
      -- 'Y'�ȊO�̏ꍇ
      IF ( lv_move_inst <> gv_cons_flg_yes ) THEN
        -- �����͂����Ȃ�Ȃ�
        RETURN 1;
      END IF;
    END IF;
--
    -- ���b�g�́u�w�萻�����v�����v�́u�w�萻�����v���O�̓��t�̏ꍇ
    IF ( TO_DATE(gr_supply_tbl(in_s_cnt).p_date,'YYYY/MM/DD') < 
           gr_demand_tbl(in_d_cnt).designated_production_date )
    THEN
      -- �����͂����Ȃ�Ȃ�
      RETURN 1;
    END IF;
--
    IF ( gr_supply_tbl(in_s_cnt).r_quantity IS NULL ) THEN
      -- �����\�����擾����
      gr_supply_tbl(in_s_cnt).r_quantity := get_can_enc_qty2(gr_demand_tbl(in_d_cnt).deliver_from_id      -- OPM�ۊǑq��ID
                                                           , gr_demand_tbl(in_d_cnt).deliver_from         -- OPM�ۊǑq�ɃR�[�h
                                                           , gr_demand_tbl(in_d_cnt).item_id              -- OPM�i��ID
                                                           , gr_demand_tbl(in_d_cnt).shipping_item_code   -- OPM�i�ڃR�[�h
                                                           , gr_supply_tbl(in_s_cnt).lot_id               -- ���b�gID
                                                           , gr_demand_tbl(in_d_cnt).schedule_ship_date); -- �L����
    END IF;
-- Ver1.01 M.Hokkanji Start
   -- �b�荡�ێ����Ă���������ʂ��傫���ꍇ�ɍő�����\����n��
   IF (NVL(gr_check_tbl(1).max_rev_qty,0) < NVL(gr_supply_tbl(in_s_cnt).r_quantity,0)) THEN
     gr_check_tbl(1).max_rev_qty := gr_supply_tbl(in_s_cnt).r_quantity;
     gr_check_tbl(1).max_lot_no  :=  gr_supply_tbl(in_s_cnt).lot_no;
   END IF;
-- Ver1.01 M.Hokkanji End
    -- �����\�����O�ȉ��̏ꍇ
    IF ( gr_supply_tbl(in_s_cnt).r_quantity <= 0 ) THEN
      -- �����͂����Ȃ�Ȃ�
      RETURN 1;
    END IF;
--
    -- �ŏ��ɃP�[�X�����̂��̂̓P�[�X�P�ʈ����ł��邩�𔻒f����
    -- �����c��24�ň����\��25�̏ꍇ��24�݈̂������Ă�
    -- �����c��24�ň����\��5�̏ꍇ�͂��̃��b�g�ł̈����͍s��Ȃ��̂�
    -- �ړ����b�g�ڍׂɂ��f�[�^���Z�b�g���Ȃ��Ń��^�[������
    -- ���v���u�����c���ʁv>= �������u�����\���v�̏ꍇ
    IF ( gr_demand_tbl(in_d_cnt).rest_quantity >= gr_supply_tbl(in_s_cnt).r_quantity ) 
    THEN
      IF ( ( gr_demand_tbl(in_d_cnt).conv_unit IS NOT NULL )
       AND ( ( gr_demand_tbl(in_d_cnt).document_type_code = gv_cons_biz_t_deliv )   -- �o�׈˗�
          OR ( gr_demand_tbl(in_d_cnt).document_type_code = gv_cons_biz_t_move  ) ) -- �ړ��w��
       AND ( gv_item_class = gv_cons_id_drink ) )
      THEN
        ln_case_num := 
          (FLOOR(gr_supply_tbl(in_s_cnt).r_quantity / gr_demand_tbl(in_d_cnt).num_of_cases))
            * gr_demand_tbl(in_d_cnt).num_of_cases;                            -- ���ѐ���
        IF ( ( gr_demand_tbl(in_d_cnt).conv_unit IS NOT NULL ) AND ( ln_case_num = 0 ) ) THEN
          RETURN 1;
        END IF;
      END IF;
    END IF;
--
    RETURN 0;
--
  EXCEPTION
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END check_lot_allot;
--
  /**********************************************************************************
   * Procedure Name   : make_allot_inf
   * Description      : A-9  �������쐬����
   ***********************************************************************************/
  PROCEDURE make_allot_inf(
               iv_item_class IN  VARCHAR2,         -- ���̓p�����[�^�̏��i�敪
               in_d_cnt      IN  NUMBER,           -- ���v��񏈗��J�E���^
               in_s_cnt      IN  NUMBER,           -- ������񏈗��J�E���^
               ov_exit_flg   OUT NOCOPY VARCHAR2,  -- �����I���t���O
               ov_errbuf     OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
               ov_retcode    OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
               ov_errmsg     OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_allot_inf'; -- �v���O������
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
    -- <�J�[�\����>
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
    -- ������񏈗��J�E���^�̃J�E���g�A�b�v
    gn_move_rec_cnt := gn_move_rec_cnt + 1;
--
    -- �ړ����b�g�ڍ׏��Z�b�g
    SELECT xxinv_mov_lot_s1.NEXTVAL
    INTO   gr_move_tbl(gn_move_rec_cnt).mov_lot_dtl_id
    FROM   dual;                                    --���b�g�ڍ�ID
    gr_move_tbl(gn_move_rec_cnt).mov_line_id := gr_demand_tbl(in_d_cnt).order_line_id;             -- ����ID
    gr_move_tbl(gn_move_rec_cnt).document_type_code := gr_demand_tbl(in_d_cnt).document_type_code; -- �����^�C�v
    gr_move_tbl(gn_move_rec_cnt).record_type_code := gv_cons_rec_type;                             -- ���R�[�h�^�C�v(�w��)
    gr_move_tbl(gn_move_rec_cnt).item_id := gr_demand_tbl(in_d_cnt).item_id;                       -- OPM�i��ID
    gr_move_tbl(gn_move_rec_cnt).item_code := gr_demand_tbl(in_d_cnt).shipping_item_code;          -- �i��
    gr_move_tbl(gn_move_rec_cnt).lot_id := gr_supply_tbl(in_s_cnt).lot_id;                         -- ���b�gID
    gr_move_tbl(gn_move_rec_cnt).lot_no := gr_supply_tbl(in_s_cnt).lot_no;                         -- ���b�gNo
    gr_move_tbl(gn_move_rec_cnt).actual_date := NULL;                                              -- ���ѓ�
    gr_move_tbl(gn_move_rec_cnt).automanual_reserve_class := gv_cons_am_auto;                      -- �����蓮�����敪(����)
    -- ���v���u�����c���ʁv>= �������u�����\���v�̏ꍇ
    IF ( gr_demand_tbl(in_d_cnt).rest_quantity >= gr_supply_tbl(in_s_cnt).r_quantity ) 
    THEN
      IF ( ( gr_demand_tbl(in_d_cnt).conv_unit IS NOT NULL )
       AND ( ( gr_demand_tbl(in_d_cnt).document_type_code = gv_cons_biz_t_deliv )   -- �o�׈˗�
          OR ( gr_demand_tbl(in_d_cnt).document_type_code = gv_cons_biz_t_move  ) ) -- �ړ��w��
       AND ( iv_item_class = gv_cons_id_drink) )
      THEN
        gr_move_tbl(gn_move_rec_cnt).actual_quantity :=
          (FLOOR(gr_supply_tbl(in_s_cnt).r_quantity / gr_demand_tbl(in_d_cnt).num_of_cases))
            * gr_demand_tbl(in_d_cnt).num_of_cases;                            -- ���ѐ���
      END IF;
      IF ( ( gr_demand_tbl(in_d_cnt).conv_unit IS NULL )
        OR (  ( gr_demand_tbl(in_d_cnt).document_type_code = gv_cons_biz_t_move ) -- �ړ��w��
          AND (iv_item_class <> gv_cons_id_drink ) ) )
      THEN
        gr_move_tbl(gn_move_rec_cnt).actual_quantity := gr_supply_tbl(in_s_cnt).r_quantity; 
                                                                               -- ���ѐ���
      END IF;
    -- ���v���u�����c���ʁv< �������u�����\���v�̏ꍇ
    ELSE
      gr_move_tbl(gn_move_rec_cnt).actual_quantity := gr_demand_tbl(in_d_cnt).rest_quantity;
                                                                               -- ���ѐ���
    END IF;
--
    -- WHO�J�������̃Z�b�g
    gr_move_tbl(gn_move_rec_cnt).created_by          := gn_created_by;      -- �쐬��
    gr_move_tbl(gn_move_rec_cnt).creation_date       := SYSDATE;            -- �쐬��
    gr_move_tbl(gn_move_rec_cnt).last_updated_by     := gn_created_by;      -- �ŏI�X�V��
    gr_move_tbl(gn_move_rec_cnt).last_update_date    := SYSDATE;            -- �ŏI�X�V��
    gr_move_tbl(gn_move_rec_cnt).last_update_login   := gn_login_user;      -- �ŏI�X�V���O�C��
    gr_move_tbl(gn_move_rec_cnt).request_id          := gn_conc_request_id; -- �v��ID
    gr_move_tbl(gn_move_rec_cnt).program_application_id := gn_prog_appl_id; -- �A�v���P�[�V����ID
    gr_move_tbl(gn_move_rec_cnt).program_id          := gn_conc_program_id; -- �v���O����ID
    gr_move_tbl(gn_move_rec_cnt).program_update_date := SYSDATE;            -- �v���O�����X�V��
--
    -- ���v���A�������̒���
    gr_demand_tbl(in_d_cnt).reserved_quantity :=
          NVL(gr_demand_tbl(in_d_cnt).reserved_quantity,0) +
              gr_move_tbl(gn_move_rec_cnt).actual_quantity;
    gr_supply_tbl(in_s_cnt).r_quantity        :=
          NVL(gr_supply_tbl(in_s_cnt).r_quantity,0) -
              gr_move_tbl(gn_move_rec_cnt).actual_quantity;
    -- �����c���� = �����c���� - ���ѐ��ʁi���������)
    gr_demand_tbl(in_d_cnt).rest_quantity     := NVL(gr_demand_tbl(in_d_cnt).rest_quantity,0) -
                                                 gr_move_tbl(gn_move_rec_cnt).actual_quantity;
    -- �w�����ʂ�������(���v)���傫���ꍇ
    IF ( gr_demand_tbl(in_d_cnt).ordered_quantity > gr_demand_tbl(in_d_cnt).reserved_quantity) THEN
      ov_exit_flg := gv_cons_flg_no;
    -- ����̃��b�g�őS���������Ă�ꂽ�ꍇ�A�������̃��[�v�𔲂���
    ELSE
--
      ov_exit_flg := gv_cons_flg_yes;
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
  END make_allot_inf;
--
  /**********************************************************************************
   * Procedure Name   : regist_allot_inf
   * Description      : A-10 �������o�^����
   ***********************************************************************************/
  PROCEDURE regist_allot_inf(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'regist_allot_inf'; -- �v���O������
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
    ln_move_cnt  NUMBER;
    ln_cnt       NUMBER;
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
    -- �ړ����b�g�ڍ׏����e�[�u���ɓo�^����
    -- FORALL��gr_move_tbl.FIRST�Agr_move_tbl.LAST�������Ŏg�p�ł��Ȃ�
    ln_cnt := NVL(gr_move_tbl.LAST,0);
--
    -- FORALL�Ŏg�p�ł���悤�Ƀ��R�[�h�ϐ��𕪊��i�[����
    <<ln_move_cnt_loop>>
    FOR ln_move_cnt IN 1..ln_cnt LOOP
      gt_i_mov_lot_dtl_id(ln_move_cnt)                      -- ���b�g�ڍ�ID
        := gr_move_tbl(ln_move_cnt).mov_lot_dtl_id;
      gt_i_mov_line_id(ln_move_cnt)                         -- ����ID
        := gr_move_tbl(ln_move_cnt).mov_line_id;
      gt_i_document_type_code(ln_move_cnt)                  -- �����^�C�v
        := gr_move_tbl(ln_move_cnt).document_type_code;
      gt_i_record_type_code(ln_move_cnt)                    -- ���R�[�h�^�C�v
        := gr_move_tbl(ln_move_cnt).record_type_code;
      gt_i_item_id(ln_move_cnt)                             -- OPM�i��ID
        := gr_move_tbl(ln_move_cnt).item_id;
      gt_i_item_code(ln_move_cnt)                           -- �i��
        := gr_move_tbl(ln_move_cnt).item_code;
      gt_i_lot_id(ln_move_cnt)                              -- ���b�gID
        := gr_move_tbl(ln_move_cnt).lot_id;
      gt_i_lot_no(ln_move_cnt)                              -- ���b�gNo
        := gr_move_tbl(ln_move_cnt).lot_no;
      gt_i_actual_date(ln_move_cnt)                         -- ���ѓ�
        := gr_move_tbl(ln_move_cnt).actual_date;
      gt_i_actual_quantity(ln_move_cnt)                     -- ���ѐ���
        := gr_move_tbl(ln_move_cnt).actual_quantity;
      gt_i_automanual_reserve_class(ln_move_cnt)            -- �����蓮�����敪
        := gr_move_tbl(ln_move_cnt).automanual_reserve_class;
      gt_i_created_by(ln_move_cnt)                          -- �쐬��
        := gr_move_tbl(ln_move_cnt).created_by;
      gt_i_creation_date(ln_move_cnt)                       -- �쐬��
        := gr_move_tbl(ln_move_cnt).creation_date;
      gt_i_last_updated_by(ln_move_cnt)                     -- �ŏI�X�V��
        := gr_move_tbl(ln_move_cnt).last_updated_by;
      gt_i_last_update_date(ln_move_cnt)                    -- �ŏI�X�V��
        := gr_move_tbl(ln_move_cnt).last_update_date;
      gt_i_last_update_login(ln_move_cnt)                   -- �ŏI�X�V���O�C��
        := gr_move_tbl(ln_move_cnt).last_update_login;
      gt_i_request_id(ln_move_cnt)                          -- �v��ID
        := gr_move_tbl(ln_move_cnt).request_id;
      gt_i_program_application_id(ln_move_cnt)              -- �A�v���P�[�V����ID
        := gr_move_tbl(ln_move_cnt).program_application_id;
      gt_i_program_id(ln_move_cnt)                          -- �v���O����ID
        := gr_move_tbl(ln_move_cnt).program_id;
      gt_i_program_update_date(ln_move_cnt)                 -- �v���O�����X�V��
        := gr_move_tbl(ln_move_cnt).program_update_date;
    END LOOP ln_move_cnt_loop;
--
    FORALL ln_move_cnt IN 1..ln_cnt
      INSERT INTO xxinv_mov_lot_details(
        mov_lot_dtl_id,            -- ���b�g�ڍ�ID
        mov_line_id,               -- ����ID
        document_type_code,        -- �����^�C�v
        record_type_code,          -- ���R�[�h�^�C�v
        item_id,                   -- OPM�i��ID
        item_code,                 -- �i��
        lot_id,                    -- ���b�gID
        lot_no,                    -- ���b�gNo
        actual_date,               -- ���ѓ�
        actual_quantity,           -- ���ѐ���
        automanual_reserve_class,  -- �����蓮�����敪
        created_by,                -- �쐬��
        creation_date,             -- �쐬��
        last_updated_by,           -- �ŏI�X�V��
        last_update_date,          -- �ŏI�X�V��
        last_update_login,         -- �ŏI�X�V���O�C��
        request_id,                -- �v��ID
        program_application_id,    -- �A�v���P�[�V����ID
        program_id,                -- �v���O����ID
        program_update_date        -- �v���O�����X�V��
      )VALUES(
        gt_i_mov_lot_dtl_id(ln_move_cnt),          -- ���b�g�ڍ�ID
        gt_i_mov_line_id(ln_move_cnt),             -- ����ID
        gt_i_document_type_code(ln_move_cnt),      -- �����^�C�v
        gt_i_record_type_code(ln_move_cnt),        -- ���R�[�h�^�C�v
        gt_i_item_id(ln_move_cnt),                 -- OPM�i��ID
        gt_i_item_code(ln_move_cnt),               -- �i��
        gt_i_lot_id(ln_move_cnt),                  -- ���b�gID
        gt_i_lot_no(ln_move_cnt),                  -- ���b�gNo
        gt_i_actual_date(ln_move_cnt),             -- ���ѓ�
        gt_i_actual_quantity(ln_move_cnt),         -- ���ѐ���
        gt_i_automanual_reserve_class(ln_move_cnt),-- �����蓮�����敪
        gt_i_created_by(ln_move_cnt),              -- �쐬��
        gt_i_creation_date(ln_move_cnt),           -- �쐬��
        gt_i_last_updated_by(ln_move_cnt),         -- �ŏI�X�V��
        gt_i_last_update_date(ln_move_cnt),        -- �ŏI�X�V��
        gt_i_last_update_login(ln_move_cnt),       -- �ŏI�X�V���O�C��
        gt_i_request_id(ln_move_cnt),              -- �v��ID
        gt_i_program_application_id(ln_move_cnt),  -- �A�v���P�[�V����ID
        gt_i_program_id(ln_move_cnt),              -- �v���O����ID
        gt_i_program_update_date(ln_move_cnt)      -- �v���O�����X�V��
      );
    gn_move_rec_cnt := 0;
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
  END regist_allot_inf;
--
  /**********************************************************************************
   * Procedure Name   : make_line_allot
   * Description      : A-11 ���׈������쐬����
   ***********************************************************************************/
  PROCEDURE make_line_allot(
               in_d_cnt      IN  NUMBER,           -- ���v��񏈗��J�E���^
               ov_errbuf     OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
               ov_retcode    OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
               ov_errmsg     OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_line_allot'; -- �v���O������
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
    lv_msgbuf    VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    ln_cnt       NUMBER := 0;
    lv_ship_type VARCHAR2(20);    -- �o�א�^�C�v
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
    -- 1.�u���b�g�t�]�v�G���[���b�Z�[�W�A�u�N�x�s���v�G���[���b�Z�[�W�\��
    -- �������ʂ��w�����ʂƈ�v���Ȃ��Ōx��������ꍇ
-- Ver1.01 M.Hokkanji Start
--    IF ( ( gr_demand_tbl(in_d_cnt).reserved_quantity = 0 )
--     AND ( gr_check_tbl(1).warnning_class IS NOT NULL    ) )
     IF  ( NVL(gr_demand_tbl(in_d_cnt).reserved_quantity,0) <> NVL(gr_demand_tbl(in_d_cnt).ordered_quantity,0))
     AND (NVL(gr_demand_tbl(in_d_cnt).ordered_quantity,0) > 0)
     THEN
-- Ver1.01 M.Hokkanji End
--
      -- �x���敪���u���b�g�t�]�v�̏ꍇ
      IF ( gr_check_tbl(1).warnning_class = gv_cons_wrn_reversal ) THEN
        -- �����^�C�v���u�o�׈˗��v�������ꍇ
        IF ( gr_demand_tbl(in_d_cnt).document_type_code = gv_cons_biz_t_deliv ) THEN
          lv_ship_type := gv_ship_name_ship;
          gv_request_type := gv_request_name_ship;
        ELSE
          lv_ship_type := gv_ship_name_move;
          gv_request_type := gv_request_name_move;
        END IF;
        -- �u���b�g�t�]�v�G���[���b�Z�[�W�\��
        lv_msgbuf := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                     , gv_msg_92a_007       -- ���b�g�t�]�G���[
                                                     , gv_tkn_request_type  -- �g�[�N��'REQUEST_TYPE'
                                                     , gv_request_type
                                                     , gv_tkn_request_no    -- �g�[�N��'REQUEST_NO'
                                                     , gr_demand_tbl(in_d_cnt).request_no
                                                     , gv_tkn_ship_type     -- �g�[�N��'SHIP_TYPE'
                                                     , lv_ship_type
                                                     , gv_tkn_ship_to       -- �g�[�N��'SHIP_TO'
                                                     , gr_demand_tbl(in_d_cnt).deliver_to
                                                     , gv_tkn_item          -- �g�[�N��'ITEM'
                                                     , gr_demand_tbl(in_d_cnt).shipping_item_code
                                                     , gv_tkn_lot           -- �g�[�N��'LOT'
                                                     , gr_check_tbl(1).lot_no
                                                     , gv_tkn_p_date        -- �g�[�N��'P_DATE'
                                                     , gr_check_tbl(1).p_date
                                                     , gv_tkn_use_by_date   -- �g�[�N��'USE_BY_DATE'
                                                     , gr_check_tbl(1).use_by_date
                                                     , gv_tkn_fix_no        -- �g�[�N��'FIX_NO'
                                                     , gr_check_tbl(1).fix_no
                                                     , gv_tkn_reverse_date  -- �g�[�N��'REVDATE'
                                                     , TO_CHAR(gr_check_tbl(1).warnning_date,'YYYY/MM/DD'))
                                                     , 1
                                                     , 5000);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msgbuf);
      -- �x���敪���u�N�x�s���v�̏ꍇ
      ELSIF( gr_check_tbl(1).warnning_class = gv_cons_wrn_fresh ) THEN
        -- �u�N�x�s���v�G���[���b�Z�[�W�\��
        lv_msgbuf := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh   -- 'XXWSH'
                                                     , gv_msg_92a_008        -- �N�x�s���G���[
                                                     , gv_tkn_request_no     -- �g�[�N��'REQUEST_NO'
                                                     , gr_demand_tbl(in_d_cnt).request_no
                                                     , gv_tkn_ship_to        -- �g�[�N��'SHIP_TO'
                                                     , gr_demand_tbl(in_d_cnt).deliver_to
                                                     , gv_tkn_lot            -- �g�[�N��'LOT'
                                                     , gr_check_tbl(1).lot_no
                                                     , gv_tkn_p_date         -- �g�[�N��'P_DATE'
                                                     , gr_check_tbl(1).p_date
                                                     , gv_tkn_use_by_date    -- �g�[�N��'USE_BY_DATE'
                                                     , gr_check_tbl(1).use_by_date
                                                     , gv_tkn_fix_no         -- �g�[�N��'FIX_NO'
                                                     , gr_check_tbl(1).fix_no
                                                     , gv_tkn_arrival_date   -- �g�[�N��'ARRIVAL_DATE'
                                                     , TO_CHAR(gr_demand_tbl(in_d_cnt).schedule_arrival_date, 'YYYY/MM/DD')
                                                     , gv_tkn_standard_date  --�g�[�N��'STANDARD_DATE'
                                                     , TO_CHAR(gr_check_tbl(1).warnning_date,'YYYY/MM/DD'))
                                                     , 1
                                                     , 5000);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msgbuf);
-- Ver1.01 M.Hokkanji Start
      ELSE
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'�������ʂ������ł��܂���ł���'
                                       || ' �˗�No:' || gr_demand_tbl(in_d_cnt).request_no
                                       || ' �o�וi��:' || gr_demand_tbl(in_d_cnt).shipping_item_code
                                       || ' �������ʁF' || TO_CHAR(NVL(gr_demand_tbl(in_d_cnt).reserved_quantity,0))
                                       || ' 1���b�g�ő�����\��:' || NVL(TO_CHAR(gr_check_tbl(1).max_rev_qty),0)
                                       || ' 1���b�g�ő�������b�gNo:' || gr_check_tbl(1).max_lot_no
                                       || ' �K�v�w������:' ||  gr_demand_tbl(in_d_cnt).ordered_quantity);
-- Ver1.01 M.Hokkanji End
      END IF;
-- 2008/11/13 M.Hokkanji START
      ov_retcode := gv_status_warn;
-- 2008/11/13 M.Hokkanji END
    END IF;
--
    -- ���v���̕����^�C�v�ɂ��o�^����ϐ��𔻒f����
    -- �����^�C�v���u�o�׈˗��v�������ꍇ
    IF ( gr_demand_tbl(in_d_cnt).document_type_code = gv_cons_biz_t_deliv ) THEN
--
      -- 2.�󒍖��׃A�h�I���ϐ��o�^
      gn_odr_cnt := gn_odr_cnt + 1;
      gr_order_tbl(gn_odr_cnt).order_line_id            :=
                            gr_demand_tbl(in_d_cnt).order_line_id;       -- �󒍖��׃A�h�I��ID
      gr_order_tbl(gn_odr_cnt).reserved_quantity        :=
                            gr_demand_tbl(in_d_cnt).reserved_quantity;   -- ������
      -- ���v���̈������ʂ��O���傫��
      IF  ( gr_demand_tbl(in_d_cnt).reserved_quantity > 0 ) THEN
        gr_order_tbl(gn_odr_cnt).warning_class            :=
                            NULL;                                        -- �x���敪
        gr_order_tbl(gn_odr_cnt).warning_date             :=
                            NULL;                                        -- �x�����t
        gr_order_tbl(gn_odr_cnt).automanual_reserve_class :=
                            gv_cons_am_auto;                             -- �����蓮�����敪
      -- ���v���̈������ʂ��O
-- Ver1.01 M.Hokkanji Start
      ELSIF ( NVL(gr_demand_tbl(in_d_cnt).reserved_quantity,0) = 0 ) THEN
-- Ver1.01 M.Hokkanji End
        gr_order_tbl(gn_odr_cnt).warning_class            :=
                            gr_check_tbl(1).warnning_class;                 -- �x���敪
        gr_order_tbl(gn_odr_cnt).warning_date             :=
                            gr_check_tbl(1).warnning_date;                  -- �x�����t
        gr_order_tbl(gn_odr_cnt).automanual_reserve_class :=
                            NULL;                                        -- �����蓮�����敪
        gr_order_tbl(gn_odr_cnt).reserved_quantity        := NULL;       -- ������
      END IF;
--
      -- WHO�J�������̃Z�b�g
      gr_order_tbl(gn_odr_cnt).last_updated_by     := gn_created_by;      -- �ŏI�X�V��
      gr_order_tbl(gn_odr_cnt).last_update_date    := SYSDATE;            -- �ŏI�X�V��
      gr_order_tbl(gn_odr_cnt).last_update_login   := gn_login_user;      -- �ŏI�X�V���O�C��
      gr_order_tbl(gn_odr_cnt).request_id          := gn_conc_request_id; -- �v��ID
      gr_order_tbl(gn_odr_cnt).program_application_id := gn_prog_appl_id; -- �A�v���P�[�V����ID
      gr_order_tbl(gn_odr_cnt).program_id          := gn_conc_program_id; -- �v���O����ID
      gr_order_tbl(gn_odr_cnt).program_update_date := SYSDATE;            -- �v���O�����X�V��
--
    -- �����^�C�v���u�ړ��v�������ꍇ
    ELSIF ( gr_demand_tbl(in_d_cnt).document_type_code = gv_cons_biz_t_move ) THEN
--
      -- 3.�ړ��˗�/�w�����׃A�h�I���ϐ��o�^
      gn_mov_cnt := gn_mov_cnt + 1;
      gr_req_tbl(gn_mov_cnt).mov_line_id       := gr_demand_tbl(in_d_cnt).order_line_id;     -- �ړ�����ID
      gr_req_tbl(gn_mov_cnt).reserved_quantity := gr_demand_tbl(in_d_cnt).reserved_quantity; -- ��������
      -- ���v���̈������ʂ��O���傫��
      IF ( gr_demand_tbl(in_d_cnt).reserved_quantity > 0 ) THEN
        gr_req_tbl(gn_mov_cnt).warning_class            := NULL;                -- �x���敪
        gr_req_tbl(gn_mov_cnt).warning_date             := NULL;                -- �x�����t
        gr_req_tbl(gn_mov_cnt).automanual_reserve_class := gv_cons_am_auto;     -- �����蓮�����敪
      -- ���v���̈������ʂ��O
-- Ver1.01 M.Hokkanji Start
      ELSIF ( NVL(gr_demand_tbl(in_d_cnt).reserved_quantity,0) = 0 ) THEN
--      ELSIF ( gr_demand_tbl(in_d_cnt).reserved_quantity = 0 ) THEN
-- Ver1.01 M.Hokkanji End
        gr_req_tbl(gn_mov_cnt).warning_class := gr_check_tbl(1).warnning_class; -- �x���敪
        gr_req_tbl(gn_mov_cnt).warning_date  := gr_check_tbl(1).warnning_date;  -- �x�����t
        gr_req_tbl(gn_mov_cnt).automanual_reserve_class := NULL;                -- �����蓮�����敪
        gr_req_tbl(gn_mov_cnt).reserved_quantity        := NULL;                -- ��������
      END IF;
--
      -- WHO�J�������̃Z�b�g
      gr_req_tbl(gn_mov_cnt).last_updated_by        := gn_created_by;      -- �ŏI�X�V��
      gr_req_tbl(gn_mov_cnt).last_update_date       := SYSDATE;            -- �ŏI�X�V��
      gr_req_tbl(gn_mov_cnt).last_update_login      := gn_login_user;      -- �ŏI�X�V���O�C��
      gr_req_tbl(gn_mov_cnt).request_id             := gn_conc_request_id; -- �v��ID
      gr_req_tbl(gn_mov_cnt).program_application_id := gn_prog_appl_id;    -- �A�v���P�[�V����ID
      gr_req_tbl(gn_mov_cnt).program_id             := gn_conc_program_id; -- �v���O����ID
      gr_req_tbl(gn_mov_cnt).program_update_date    := SYSDATE;            -- �v���O�����X�V��
    END IF;
--
    -- �������ʌ����J�E���g
    ln_cnt := check_number_tbl( gr_demand_tbl(in_d_cnt).request_no );
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
  END make_line_allot;
--
  /**********************************************************************************
   * Procedure Name   : update_line_inf
   * Description      : A-12 ���׏��X�V����
   ***********************************************************************************/
  PROCEDURE update_line_inf(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_line_inf'; -- �v���O������
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
    ln_ins_cnt  NUMBER;
    ln_cnt      NUMBER;
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
    -- �󒍖��׃A�h�I���f�[�^���e�[�u���ɓo�^����
    ln_cnt := NVL(gr_order_tbl.LAST,0);
    -- FORALL��gr_move_tbl.FIRST�Agr_move_tbl.LAST�������Ŏg�p�ł��Ȃ�
    -- FORALL�Ŏg�p�ł���悤�Ƀ��R�[�h�ϐ��𕪊��i�[����
--
    <<ln_ins_cnt_loop1>>
    FOR ln_ins_cnt IN 1..ln_cnt LOOP
--
      gt_j_order_line_id(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).order_line_id;              -- �󒍖��׃A�h�I��ID
      gt_j_reserved_quantity(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).reserved_quantity;          -- ������
      gt_j_warning_class(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).warning_class;              -- �x���敪
      gt_j_warning_date(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).warning_date;               -- �x�����t
      gt_j_automanual_reserve_class(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).automanual_reserve_class;   -- �����蓮�����敪
      gt_j_last_updated_by(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).last_updated_by;            -- �ŏI�X�V��
      gt_j_last_update_date(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).last_update_date;           -- �ŏI�X�V��
      gt_j_last_update_login(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).last_update_login;          -- �ŏI�X�V���O�C��
      gt_j_request_id(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).request_id;                 -- �v��ID
      gt_j_program_application_id(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).program_application_id;     -- �A�v���P�[�V����ID
      gt_j_program_id(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).program_id;                 -- �v���O����ID
      gt_j_program_update_date(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).program_update_date;        -- �v���O�����X�V��
    END LOOP ln_ins_cnt_loop1;
--
    FORALL ln_ins_cnt IN 1..ln_cnt
      UPDATE xxwsh_order_lines_all
      SET reserved_quantity        = gt_j_reserved_quantity(ln_ins_cnt),       -- ������
          warning_class            = gt_j_warning_class(ln_ins_cnt),           -- �x���敪
          warning_date             = gt_j_warning_date(ln_ins_cnt),            -- �x�����t
          automanual_reserve_class = gt_j_automanual_reserve_class(ln_ins_cnt), -- �����蓮�����敪
          last_updated_by          = gt_j_last_updated_by(ln_ins_cnt),         -- �ŏI�X�V��
          last_update_date         = gt_j_last_update_date(ln_ins_cnt),        -- �ŏI�X�V��
          last_update_login        = gt_j_last_update_login(ln_ins_cnt),       -- �ŏI�X�V���O�C��
          request_id               = gt_j_request_id(ln_ins_cnt),              -- �v��ID
          program_application_id   = gt_j_program_application_id(ln_ins_cnt), -- �A�v���P�[�V����ID
          program_id               = gt_j_program_id(ln_ins_cnt),              -- �v���O����ID
          program_update_date      = gt_j_program_update_date(ln_ins_cnt)      -- �v���O�����X�V��
      WHERE  order_line_id = gt_j_order_line_id(ln_ins_cnt)
      ;
--
    -- �ړ��˗�/�w�����׃A�h�I���f�[�^���e�[�u���ɓo�^����
    -- FORALL��gr_move_tbl.FIRST�Agr_move_tbl.LAST�������Ŏg�p�ł��Ȃ�
    ln_cnt :=  NVL(gr_req_tbl.LAST,0);
--
    -- FORALL�Ŏg�p�ł���悤�Ƀ��R�[�h�ϐ��𕪊��i�[����
    <<ln_ins_cnt_loop2>>
    FOR ln_ins_cnt IN 1..ln_cnt LOOP
--
      gt_m_mov_line_id(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).mov_line_id;                -- �ړ�����ID
      gt_m_reserved_quantity(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).reserved_quantity;          -- ��������
      gt_m_warning_class(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).warning_class;              -- �x���敪
      gt_m_warning_date(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).warning_date;               -- �x�����t
      gt_m_automanual_reserve_class(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).automanual_reserve_class;   -- �����蓮�����敪
      gt_m_last_updated_by(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).last_updated_by;            -- �ŏI�X�V��
      gt_m_last_update_date(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).last_update_date;           -- �ŏI�X�V��
      gt_m_last_update_login(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).last_update_login;          -- �ŏI�X�V���O�C��
      gt_m_request_id(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).request_id;                 -- �v��ID
      gt_m_program_application_id(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).program_application_id;     -- �A�v���P�[�V����ID
      gt_m_program_id(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).program_id;                 -- �v���O����ID
      gt_m_program_update_date(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).program_update_date;        -- �v���O�����X�V��
    END LOOP ln_ins_cnt_loop2;
--
    FORALL ln_ins_cnt IN 1..ln_cnt
      UPDATE xxinv_mov_req_instr_lines
      SET reserved_quantity        = gt_m_reserved_quantity(ln_ins_cnt),        -- ��������
          warning_class            = gt_m_warning_class(ln_ins_cnt),            -- �x���敪
          warning_date             = gt_m_warning_date(ln_ins_cnt),             -- �x�����t
          automanual_reserve_class = gt_m_automanual_reserve_class(ln_ins_cnt), -- �����蓮�����敪
          last_updated_by          = gt_m_last_updated_by(ln_ins_cnt),          -- �ŏI�X�V��
          last_update_date         = gt_m_last_update_date(ln_ins_cnt),         -- �ŏI�X�V��
          last_update_login        = gt_m_last_update_login(ln_ins_cnt),        -- �ŏI�X�V���O�C��
          request_id               = gt_m_request_id(ln_ins_cnt),               -- �v��ID
          program_application_id   = gt_m_program_application_id(ln_ins_cnt), -- �A�v���P�[�V����ID
          program_id               = gt_m_program_id(ln_ins_cnt),               -- �v���O����ID
          program_update_date      = gt_m_program_update_date(ln_ins_cnt)       -- �v���O�����X�V��
      WHERE mov_line_id = gt_m_mov_line_id(ln_ins_cnt)
      ;
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
  END update_line_inf;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_item_class         IN     VARCHAR2,     -- ���i�敪
    iv_action_type        IN     VARCHAR2,     -- �������
    iv_block1             IN     VARCHAR2,     -- �u���b�N�P
    iv_block2             IN     VARCHAR2,     -- �u���b�N�Q
    iv_block3             IN     VARCHAR2,     -- �u���b�N�R
    in_deliver_from_id    IN     NUMBER,       -- �o�Ɍ�
    in_deliver_type       IN     NUMBER,       -- �o�Ɍ`��
    iv_deliver_date_from  IN     VARCHAR2,     -- �o�ɓ�From
    iv_deliver_date_to    IN     VARCHAR2,     -- �o�ɓ�To
    iv_item_code          IN     VARCHAR2,     -- �i�ڃR�[�h
    ov_errbuf             OUT  NOCOPY   VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT  NOCOPY   VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT  NOCOPY   VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lc_out_param     VARCHAR2(1000);   -- ���̓p�����[�^�̏������ʃ��|�[�g�o�͗p
    lv_fwd_sql       VARCHAR2(5000);   -- �o�חpSQL���i�[�o�b�t�@
    lv_mov_sql       VARCHAR2(5000);   -- �ړ��pSQL���i�[�o�b�t�@
--
    ln_d_cnt         NUMBER := 0;      -- ���v��񃋁[�v�J�E���^
    ln_s_cnt         NUMBER := 0;      -- ������񃋁[�v�J�E���^
    ln_k_cnt         NUMBER := 0;
    lv_exit_flg      VARCHAR2(1);      -- �����I���t���O
    lv_no_check_flg  VARCHAR2(1);      -- �`�F�b�N�Ȃ��t���O('Y'�Ō㑱�̃`�F�b�N�͂��Ȃ�)
    lv_no_meisai_flg VARCHAR2(1);      -- A-10�R�[���t���O
    ln_s_max         NUMBER := 0;
    ln_i_cnt         NUMBER := 0;      -- ���v��񍇑̗p�J�E���^
--
    lv_lot_biz_class VARCHAR2(1);      -- ���b�g�t�]�������
    ld_reversal_date DATE;             -- �t�]���t
    ln_result        NUMBER;           -- ��������(0:����A1:�ُ�)
    ld_standard_date DATE;             -- ����t
    ln_cnt           NUMBER := 0;
--
    -- �������擾�̔��f�Ɏg�p����
    lv_item_code   xxwsh_order_lines_all.shipping_item_code%TYPE;      -- �i��(�R�[�h)
    ld_ship_date   xxwsh_order_headers_all.schedule_ship_date%TYPE;    -- �o�ɗ\���
    ld_ariv_date   xxwsh_order_headers_all.schedule_arrival_date%TYPE; -- ���ɗ\���
    lv_dist_block  xxcmn_item_locations2_v.distribution_block%TYPE;    -- �u���b�N
    lv_delv_from   xxwsh_order_headers_all.deliver_from%TYPE;          -- �o�Ɍ�
    lv_delv_to     xxwsh_order_headers_all.deliver_to%TYPE;            -- �z����
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
    gv_item_class := iv_item_class;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================================
    -- A-1  ���̓p�����[�^�`�F�b�N check_parameter
    -- ===============================================
    check_parameter(iv_item_class         -- ���̓p�����[�^���i�敪
                  , iv_deliver_date_from  -- ���̓p�����[�^�o�ɓ�From
                  , iv_deliver_date_to    -- ���̓p�����[�^�o�ɓ�To
                  , iv_item_code          -- ���̓p�����[�^�i�ڃR�[�h
                  , lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
                  , lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
                  , lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                    );
    -- �G���[����
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := 1;
      RAISE global_process_expt;
    END IF;
-- 2008/11/13 M.Hokkanji START
    -- ===============================================
    -- A-2  �i�ڃ��X�g�擾 get_item_code_list
    -- ===============================================
    get_item_code_list(iv_item_code          -- ���̓p�����[�^�i�ڃR�[�h
                     , lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
                     , lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
                     , lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                       );
    -- �G���[����
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := 1;
      RAISE global_process_expt;
    END IF;
-- 2008/11/13 M.Hokkanji END
--
    -- ���̓p�����[�^�́u������ʁv�ɂ����v���̎擾��U�蕪����(�w��Ȃ��͗���)
    -- �u�o�ׁv�܂��́u�w��Ȃ��v�̏ꍇ
    IF ( ( iv_action_type = gv_action_type_ship ) OR ( iv_action_type IS NULL ) ) THEN
      -- ===============================================
      -- A-3  �o�חpSQL�쐬 fwd_sql_create
      -- ===============================================
      lv_fwd_sql := fwd_sql_create(iv_block1          -- �u���b�N�P
                                 , iv_block2          -- �u���b�N�Q
                                 , iv_block3          -- �u���b�N�R
                                 , in_deliver_from_id -- �o�Ɍ�
                                 , in_deliver_type    -- �o�Ɍ`��
                                 , iv_item_code       -- �i�ڃR�[�h
                                   );   
      -- ===============================================
      -- A-4  ���v���擾(�o��) get_demand_inf_fwd
      -- ===============================================
      get_demand_inf_fwd(lv_fwd_sql     -- �o�חpSQL��
                       , lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
                       , lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
                       , lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                         );
      -- �G���[����
      IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := 1;
          RAISE global_process_expt;
      END IF;
    END IF;
--
    -- �u�ړ��v�܂��́u�w��Ȃ��v�̏ꍇ
    IF ( ( iv_action_type = gv_action_type_move ) OR ( iv_action_type IS NULL ) ) THEN
      -- ===============================================
      -- A-5  �ړ��pSQL�쐬 mov_sql_create
      -- ===============================================
      lv_mov_sql := mov_sql_create(iv_block1          -- �u���b�N�P
                                 , iv_block2          -- �u���b�N�Q
                                 , iv_block3          -- �u���b�N�R
                                 , in_deliver_from_id -- �o�Ɍ�
                                 , in_deliver_type    -- �o�Ɍ`��
                                 , iv_item_code       -- �i�ڃR�[�h
                                   );
      -- ===============================================
      -- A-6  ���v���擾(�ړ�) get_demand_inf_mov
      -- ===============================================
      get_demand_inf_mov(lv_mov_sql     -- �ړ��pSQL��
                       , lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
                       , lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
                       , lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                         );
      -- �G���[����
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := 1;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    --���v�������̂���
    <<deliv_plus_move_loop>>
    FOR ln_i_cnt IN 1..gn_target_cnt_move LOOP
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).document_type_code :=
                    gr_demand_tbl2(ln_i_cnt).document_type_code;    -- �����^�C�v V
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).request_no :=
                    gr_demand_tbl2(ln_i_cnt).mov_num;               -- �ړ��ԍ� V
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).distribution_block :=
                    gr_demand_tbl2(ln_i_cnt).distribution_block;    -- �u���b�N V
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).deliver_from :=
                    gr_demand_tbl2(ln_i_cnt).deliver_from;          -- �o�Ɍ� V
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).deliver_from_id :=
                    gr_demand_tbl2(ln_i_cnt).deliver_from_id;       -- �o�Ɍ�ID N
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).schedule_ship_date :=
                    gr_demand_tbl2(ln_i_cnt).schedule_ship_date;    -- �o�ɗ\��� D
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).schedule_arrival_date :=
                    gr_demand_tbl2(ln_i_cnt).schedule_arrival_date; -- ���ɗ\��� D
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).header_id :=
                    gr_demand_tbl2(ln_i_cnt).header_id;             -- �w�b�_ID N
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).deliver_to :=
                    gr_demand_tbl2(ln_i_cnt).deliver_to;            -- �z���� V
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).deliver_to_id :=
                    gr_demand_tbl2(ln_i_cnt).deliver_to_id;         -- �z����ID N
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).reserve_order :=
                    gr_demand_tbl2(ln_i_cnt).reserve_order;         -- ���_������ N
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).order_line_id :=
                    gr_demand_tbl2(ln_i_cnt).order_line_id;         -- ����ID N
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).shipping_item_code :=
                    gr_demand_tbl2(ln_i_cnt).shipping_item_code;    -- �i��(�R�[�h) V
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).item_id :=
                    gr_demand_tbl2(ln_i_cnt).item_id;               -- OPM�i��ID N
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).ordered_quantity :=
                    gr_demand_tbl2(ln_i_cnt).ordered_quantity;      -- �w������ N
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).rest_quantity :=
                    gr_demand_tbl2(ln_i_cnt).rest_quantity;         -- �����c���� N
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).reserved_quantity :=
                    gr_demand_tbl2(ln_i_cnt).reserved_quantity;     -- �������� N
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).designated_production_date :=
                    gr_demand_tbl2(ln_i_cnt).designated_production_date;    -- �w�萻���� D
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).frequent_whse_class :=
                    gr_demand_tbl2(ln_i_cnt).frequent_whse_class;   -- ��\�q�ɋ敪 V
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).frequent_whse :=
                    gr_demand_tbl2(ln_i_cnt).frequent_whse;         -- ��\�q�� V
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).inventory_location_id :=
                    gr_demand_tbl2(ln_i_cnt).inventory_location_id; -- ��\�ۊǒIID
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).num_of_cases :=
                    gr_demand_tbl2(ln_i_cnt).num_of_cases;          -- �P�[�X���� N
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).conv_unit :=
                    gr_demand_tbl2(ln_i_cnt).conv_unit;             -- ���o�Ɋ��Z�P�� V
    END LOOP deliv_plus_move_loop;
--
    -- ���v��񃋁[�v
    gn_target_cnt_total := gn_target_cnt_deliv + gn_target_cnt_move;
    <<demand_inf_loop>>
    FOR ln_d_cnt IN 1..gn_target_cnt_total LOOP
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�y�˗�No�z' || gr_demand_tbl(ln_d_cnt).request_no || '�y�o�ߎ��ԁz' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      -- �P�[�X�����`�F�b�N�ȉ��̏�����S�Ė������Ă���ꍇ�̓G���[
      -- ���o�Ɋ��Z�P�ʂ��ݒ肳��Ă���
      -- �o�׈˗��������͈ړ��w���ŏ��i�敪���h�����N
      -- �P�[�X������0��������NULL
      IF (  (gr_demand_tbl(ln_d_cnt).conv_unit IS NOT NULL )
        AND ( ( gr_demand_tbl(ln_d_cnt).document_type_code = gv_cons_biz_t_deliv ) -- �o�׈˗�
             OR (  ( gr_demand_tbl(ln_d_cnt).document_type_code = gv_cons_biz_t_move ) -- �ړ��w��
               AND ( gv_item_class = gv_cons_id_drink ) ) )
        AND ( NVL(gr_demand_tbl(ln_d_cnt).num_of_cases,0) = 0 ) ) THEN
        -- �P�[�X�����G���[���o��
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn  -- 'XXCMN'
                                                     , gv_msg_92a_010       -- �P�[�X�����G���[
                                                     , gv_tkn_request_no    -- �g�[�N��'REQUEST_NO'
                                                     , gr_demand_tbl(ln_d_cnt).request_no
                                                     , gv_tkn_item_no       -- �g�[�N��'ITEM_NO'
                                                     , gr_demand_tbl(ln_d_cnt).shipping_item_code) -- �˗�NO/�ړ��ԍ�
                                                     , 1
                                                     , 5000
                                                       );
        RAISE global_process_expt;
      END IF;
      -- �i�ڃR�[�h�A�o�ɗ\����A���ɗ\����A�u���b�N�A�o�Ɍ��̂ǂꂩ���قȂ�����
      -- ����������������
      IF ( ( gr_demand_tbl(ln_d_cnt).shipping_item_code    <> lv_item_code  )   -- �i�ڃR�[�h
        OR ( gr_demand_tbl(ln_d_cnt).schedule_ship_date    <> ld_ship_date  )   -- �o�ɗ\���
        OR ( gr_demand_tbl(ln_d_cnt).schedule_arrival_date <> ld_ariv_date  )   -- ���ɗ\���
        OR ( gr_demand_tbl(ln_d_cnt).distribution_block    <> lv_dist_block )   -- �u���b�N
        OR ( gr_demand_tbl(ln_d_cnt).deliver_from          <> lv_delv_from  )   -- �o�Ɍ�
        OR ( lv_item_code IS NULL ) ) 
      THEN
        -- ��r�p�ϐ��ɕۑ�����
        lv_item_code  := gr_demand_tbl(ln_d_cnt).shipping_item_code;      -- �i��(�R�[�h)
        ld_ship_date  := gr_demand_tbl(ln_d_cnt).schedule_ship_date;      -- �o�ɗ\���
        ld_ariv_date  := gr_demand_tbl(ln_d_cnt).schedule_arrival_date;   -- ���ɗ\���
        lv_dist_block := gr_demand_tbl(ln_d_cnt).distribution_block;      -- �u���b�N
        lv_delv_from  := gr_demand_tbl(ln_d_cnt).deliver_from;            -- �o�Ɍ�
        lv_delv_to    := gr_demand_tbl(ln_d_cnt).deliver_to;              -- �o�Ɍ�
--
        -- ===============================================
        -- A-7  �������擾 get_supply_inf
        -- ===============================================
        -- �������ϐ��̏�����
        gr_supply_tbl.delete;
        ln_cnt := ln_cnt + 1;
        get_supply_inf(gr_demand_tbl(ln_d_cnt).deliver_from_id    -- OPM�ۊǑq��ID
                     , gr_demand_tbl(ln_d_cnt).deliver_from       -- OPM�ۊǑq�ɃR�[�h
                     , gr_demand_tbl(ln_d_cnt).item_id            -- OPM�i��ID
                     , gr_demand_tbl(ln_d_cnt).shipping_item_code -- OPM�i�ڃR�[�h
                     , NULL                                       -- ���b�gID
                     , gr_demand_tbl(ln_d_cnt).schedule_ship_date -- �L����
                     , lv_errbuf                                  -- �G���[�E���b�Z�[�W           
                     , lv_retcode                                 -- ���^�[���E�R�[�h             
                     , lv_errmsg                                  -- ���[�U�[�E�G���[�E���b�Z�[�W 
                       );
        -- �G���[����
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := 1;
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- A-11�������Ȃ��ׂ̃t���O������
      lv_no_meisai_flg := gv_cons_flg_no;
      ln_s_max := NVL(gr_supply_tbl.LAST,0);
      ln_s_cnt := 0;
      -- �ړ����b�g�ڍדo�^�p�ϐ��y�ь�����������
      gr_move_tbl.DELETE;
      gn_move_rec_cnt := 0;
      -- �x���`�F�b�N�p�̕ϐ���������
      gr_check_tbl(1).warnning_class := NULL;
      gr_check_tbl(1).warnning_date  := NULL;
      gr_check_tbl(1).lot_no         := NULL;
-- Ver1.01 M.Hokkanji Start
      gr_check_tbl(1).max_rev_qty    := NULL;
      gr_check_tbl(1).max_lot_no     := NULL;
-- Ver1.01 M.Hokkanji End
      lv_no_meisai_flg               := gv_cons_flg_yes;
      -- ������񃋁[�v
      <<supply_inf_loop>>
      FOR ln_s_cnt IN 1..ln_s_max LOOP
        -- �`�F�b�N�Ȃ��t���O�̏�����
        lv_no_check_flg := gv_cons_flg_no;
        -- ===============================================
        -- A-8  ���b�g�����`�F�b�N check_lot_allot
        -- ===============================================
        ln_result := check_lot_allot(ln_d_cnt
                                   , ln_s_cnt
                                     );
--
        -- ���̃��b�g�ł͈��������Ȃ�
        IF (ln_result = 1) THEN
          -- �㑱�̑��̃`�F�b�N���p�X���邽�߂Ƀt���OON
          lv_no_check_flg := gv_cons_flg_yes;
        END IF;
--
        IF ( lv_no_check_flg = gv_cons_flg_no ) THEN
--
          -- ���v��񂪁u�o�ׁv�ŁA���̓p�����[�^�̏��i�敪���u���[�t�v���u�h�����N�v�̏ꍇ�A
          -- �܂���
          -- ���v��񂪁u�ړ��v�ŁA���̓p�����[�^�̏��i�敪���u�h�����N�v�̏ꍇ
          -- �ɁA���b�g�t�]�h�~�`�F�b�N���R�[������
          IF ( ( gr_demand_tbl(ln_d_cnt).document_type_code = gv_cons_biz_t_deliv )
           AND ( ( iv_item_class = gv_cons_id_leaf ) OR ( iv_item_class = gv_cons_id_drink ) )
           OR  ( gr_demand_tbl(ln_d_cnt).document_type_code = gv_cons_biz_t_move )
           AND ( iv_item_class = gv_cons_id_drink ) )
          THEN
--
            -- �p�����[�^(���b�g�t�]�������)����
            -- ���v�̕����^�C�v���u�o�׈˗��v
            IF ( gr_demand_tbl(ln_d_cnt).document_type_code = gv_cons_biz_t_deliv ) THEN
              lv_lot_biz_class := gv_cons_t_deliv;
              gv_request_type  := gv_request_name_ship;
            -- ����ȊO�́u�ړ��w���v
            ELSE
              lv_lot_biz_class := gv_cons_t_move;
              gv_request_type  := gv_request_name_move;
            END IF;
            -- =========================================
            -- ���b�g�t�]�h�~�`�F�b�N ���ʊ֐�
            -- =========================================
            xxwsh_common910_pkg.check_lot_reversal(
                           lv_lot_biz_class                              -- 1.���b�g�t�]�������
                         , gr_demand_tbl(ln_d_cnt).shipping_item_code    -- 2.�i�ڃR�[�h
                         , gr_supply_tbl(ln_s_cnt).lot_no                -- 3.���b�gNo
                         , gr_demand_tbl(ln_d_cnt).deliver_to_id         -- 4.�z����ID/�����T�C�gID/���ɐ�ID
                         , gr_demand_tbl(ln_d_cnt).schedule_arrival_date -- 5.����
                         , gr_demand_tbl(ln_d_cnt).schedule_ship_date    -- 6.���(�K�p�����)
                         , lv_retcode                                    -- 7.���^�[���E�R�[�h
                         , lv_errbuf                                     -- 8.�G���[�E���b�Z�[�W
                         , lv_errmsg                                     -- 9.���[�U�[�E�G���[�E���b�Z�[�W 
                         , ln_result                                     -- 10.��������
                         , ld_reversal_date                              -- 11.�t�]���t
                           );
            -- ���ʊ֐��̃G���[
            IF (lv_retcode = gv_cons_error) THEN
              -- ���b�Z�[�W�̃Z�b�g
              lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh   -- 'XXWSH'
                                     , gv_msg_92a_006    -- ���ʊ֐��G���[
                                     , gv_tkn_request_type -- �g�[�N��'REQUEST_TYPE'
                                     , gv_request_type
                                     , gv_tkn_request_no   -- �g�[�N��'REQUEST_NO'
                                     , gr_demand_tbl(ln_d_cnt).request_no
                                     , gv_tkn_p_date       -- �g�[�N��'P_DATE'
                                     , gr_supply_tbl(ln_s_cnt).p_date
                                     , gv_tkn_use_by_date  -- �g�[�N��'USE_BY_DATE'
                                     , gr_supply_tbl(ln_s_cnt).use_by_date
                                     , gv_tkn_fix_no       -- �g�[�N��'FIX_NO'
                                     , gr_supply_tbl(ln_s_cnt).fix_no
                                     , gv_tkn_err_code   -- �g�[�N��'ERR_CODE'
                                     , lv_errbuf         -- �G���[���b�Z�[�W
                                     , gv_tkn_err_msg    -- �g�[�N��'ERR_MSG'
                                     , lv_errmsg)        -- ���[�U�[�E�G���[�E���b�Z�[�W
                                     , 1
                                     , 5000
                                       );
              -- �㑱�����͒��~����
              gn_error_cnt := 1;
              RAISE global_process_expt;
            END IF;
--
            -- ���b�g�̋t�]���������ꍇ
            IF (ln_result = 1) THEN
              -- �`�F�b�N�������ʂ��i�[����
              IF ( (gr_check_tbl(1).warnning_date IS NULL)
                OR (gr_check_tbl(1).warnning_date <= ld_reversal_date ))
              THEN
                ln_k_cnt := ln_k_cnt + 1;
                gr_check_tbl(1).warnning_class := gv_cons_wrn_reversal;           -- �x���敪
                gr_check_tbl(1).warnning_date  := ld_reversal_date;               -- �x�����t
                gr_check_tbl(1).lot_no         := gr_supply_tbl(ln_s_cnt).lot_no; -- ���b�gNo
                gr_check_tbl(1).p_date         := gr_supply_tbl(ln_s_cnt).p_date;      -- �����N����
                gr_check_tbl(1).fix_no         := gr_supply_tbl(ln_s_cnt).fix_no;      -- �ŗL�ԍ�
                gr_check_tbl(1).use_by_date    := gr_supply_tbl(ln_s_cnt).use_by_date; -- �ܖ�����
              END IF;
--
              -- �㑱�̑��̃`�F�b�N���p�X���邽�߂Ƀt���OON
              lv_no_check_flg := gv_cons_flg_yes;
              -- �x���I��
            END IF;
            -- ���[�v�̊Ԉ�x�ł�������ʂ��A-11�̓R�[������
            lv_no_meisai_flg := gv_cons_flg_yes;
--
          END IF;
--
          -- �����Ώۂ̎��v���u�o�ׁv�̏ꍇ
          IF (gr_demand_tbl(ln_d_cnt).document_type_code = gv_cons_biz_t_deliv)
          THEN
            -- =======================================
            -- �N�x�����`�F�b�N ���ʊ֐�
            -- =======================================
            xxwsh_common910_pkg.check_fresh_condition(
                gr_demand_tbl(ln_d_cnt).deliver_to_id          -- 1.�z����ID
              , gr_supply_tbl(ln_s_cnt).lot_id                 -- 2.���b�gID
              , gr_demand_tbl(ln_d_cnt).schedule_arrival_date  -- 3.���ד�
              , gr_demand_tbl(ln_d_cnt).schedule_ship_date     -- 4.�o�ɗ\���
              , lv_retcode                                     -- 5.���^�[���E�R�[�h
              , lv_errbuf                                      -- 6.�G���[�E���b�Z�[�W
              , lv_errmsg                                      -- 7.���[�U�[�E�G���[�E���b�Z�[�W
              , ln_result                                      -- 8.��������
              , ld_standard_date                               -- 9.����t
                );
            -- ���ʊ֐��̃G���[
            IF (lv_retcode = gv_cons_error) THEN
              -- ���b�Z�[�W�̃Z�b�g
              lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                       gv_cons_msg_kbn_wsh    -- 'XXWSH'
                                     , gv_msg_92a_006         -- ���ʊ֐��G���[
                                     , gv_tkn_request_type    -- �g�[�N��'REQUEST_TYPE'
                                     , gv_request_name_ship
                                     , gv_tkn_request_no      -- �g�[�N��'REQUEST_NO'
                                     , gr_demand_tbl(ln_d_cnt).request_no
                                     , gv_tkn_p_date          -- �g�[�N��'P_DATE'
                                     , gr_supply_tbl(ln_s_cnt).p_date
                                     , gv_tkn_use_by_date     -- �g�[�N��'USE_BY_DATE'
                                     , gr_supply_tbl(ln_s_cnt).use_by_date
                                     , gv_tkn_fix_no          -- �g�[�N��'FIX_NO'
                                     , gr_supply_tbl(ln_s_cnt).fix_no
                                     , gv_tkn_err_code        -- �g�[�N��'ERR_CODE'
                                     , lv_errbuf              -- �G���[���b�Z�[�W
                                     , gv_tkn_err_msg         -- �g�[�N��'ERR_MSG'
                                     , lv_errmsg)             -- ���[�U�[�E�G���[�E���b�Z�[�W
                                     , 1
                                     , 5000
                                       );
              -- �㑱�����͒��~����
              gn_error_cnt := 1;
              RAISE global_process_expt;
            END IF;
--
            -- �N�x�����ُ�̏ꍇ
            IF ( ln_result = 1 ) THEN
              -- �`�F�b�N�������ʂ��i�[����
              IF ( ( gr_check_tbl(1).warnning_date IS NULL )
                OR ( gr_check_tbl(1).warnning_date <= ld_standard_date ))
              THEN
                gr_check_tbl(1).warnning_class := gv_cons_wrn_fresh;                   -- �x���敪
                gr_check_tbl(1).warnning_date  := ld_standard_date;                    -- �x�����t
                gr_check_tbl(1).lot_no         := gr_supply_tbl(ln_s_cnt).lot_no;      -- ���b�gNo
                gr_check_tbl(1).p_date         := gr_supply_tbl(ln_s_cnt).p_date;      -- �����N����
                gr_check_tbl(1).fix_no         := gr_supply_tbl(ln_s_cnt).fix_no;      -- �ŗL�ԍ�
                gr_check_tbl(1).use_by_date    := gr_supply_tbl(ln_s_cnt).use_by_date; -- �ܖ�����
              END IF;
--
              -- �㑱�̑��̃`�F�b�N���p�X���邽�߂Ƀt���OON
              lv_no_check_flg := gv_cons_flg_yes;
              -- �x���I��
            END IF;
            -- ���[�v�̊Ԉ�x�ł�������ʂ��A-11�̓R�[������
            lv_no_meisai_flg := gv_cons_flg_yes;
--
          END IF;
--
          IF ( lv_no_check_flg = gv_cons_flg_no ) THEN
            -- ===============================================
            -- A-9  �������쐬���� make_allot_inf
            -- ===============================================
            make_allot_inf(iv_item_class        -- ���̓p�����[�^�̏��i�敪
                         , ln_d_cnt
                         , ln_s_cnt
                         , lv_exit_flg
                         , lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
                         , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
                         , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                           );
            -- �G���[����
            IF ( lv_retcode = gv_status_error ) THEN
              gn_error_cnt := 1;
              RAISE global_process_expt;
            END IF;
--
            -- �S�������ł����ꍇ�͋������̃��[�v�𔲂���
            IF ( lv_exit_flg = gv_cons_flg_yes ) THEN
              EXIT;
            END IF;
          END IF;
--
        END IF;
-- 
      END LOOP supply_inf_loop; -- ������񃋁[�v�I���
--
      -- ===============================================
      -- A-10 �������o�^���� regist_allot_inf
      -- ===============================================
      IF (ln_s_max > 0) THEN
        regist_allot_inf(lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
                       , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
                       , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                         );
        -- �G���[����
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := 1;
          RAISE global_process_expt;
        END IF;
      END IF;
--
      IF ( lv_no_meisai_flg = gv_cons_flg_yes ) THEN
        -- ===============================================
        -- A-11 ���׈������쐬���� make_line_allot
        -- ===============================================
        make_line_allot(ln_d_cnt             -- ���v���̏����J�E���^
                      , lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
                      , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
                      , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                        );
        -- �G���[����
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := 1;
          RAISE global_process_expt;
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ov_retcode := gv_status_warn;
        END IF;
      END IF;
--
    END LOOP demand_inf_loop; -- ���v��񃋁[�v�I���
--
    -- ===============================================
    -- A-12 ���׏��X�V���� update_line_inf
    -- ===============================================
    update_line_inf(lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
                  , lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
                  , lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                    );
    -- �G���[����
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := 1;
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
    errbuf                OUT NOCOPY   VARCHAR2,      -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode               OUT NOCOPY   VARCHAR2,      -- ���^�[���E�R�[�h    --# �Œ� #
    iv_item_class         IN           VARCHAR2,      -- ���i�敪
    iv_action_type        IN           VARCHAR2,      -- �������
    iv_block1             IN           VARCHAR2,      -- �u���b�N�P
    iv_block2             IN           VARCHAR2,      -- �u���b�N�Q
    iv_block3             IN           VARCHAR2,      -- �u���b�N�R
    iv_deliver_from_id    IN           VARCHAR2,      -- �o�Ɍ�
    iv_deliver_type       IN           VARCHAR2,      -- �o�Ɍ`��
    iv_deliver_date_from  IN           VARCHAR2,      -- �o�ɓ�From
    iv_deliver_date_to    IN           VARCHAR2,      -- �o�ɓ�To
    iv_item_code          IN           VARCHAR2       -- �i�ڃR�[�h
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
    ln_deliver_from_id   NUMBER; -- �o�Ɍ�
    ln_deliver_type      NUMBER; -- �o�Ɍ`��
--
  BEGIN
--
    -- ���l�^�ɕϊ�����
    lv_retcode := gv_cons_flg_yes;
    ln_deliver_from_id := TO_NUMBER(iv_deliver_from_id);
    lv_retcode := gv_cons_flg_no;
    ln_deliver_type    := TO_NUMBER(iv_deliver_type);
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
    -----------------------------------------------
    -- ���̓p�����[�^�o��                        --
    -----------------------------------------------
    -- ���̓p�����[�^�u���i�敪�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-02851','ITEM',iv_item_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u������ʁv�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-02852','AC_TYPE',iv_action_type);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�u���b�N1�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-02853','IN_BLOCK1',iv_block1);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�u���b�N2�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-02854','IN_BLOCK2',iv_block2);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�u���b�N3�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-02855','IN_BLOCK3',iv_block3);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�o�Ɍ��v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-02856','FROM_ID',iv_deliver_from_id);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�o�Ɍ`�ԁv�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-02857','TYPE',iv_deliver_type);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�o�ɓ�From�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-02858','D_FROM',iv_deliver_date_from);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�o�ɓ�To�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-02859','D_TO',iv_deliver_date_to);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
--�b��START
    -- ���̓p�����[�^�u�i�ڃR�[�h�v�o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'�i�ڃR�[�h�F ' || iv_item_code);
--�b��END
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
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
      iv_item_class,        -- ���i�敪
      iv_action_type,       -- �������
      iv_block1,            -- �u���b�N�P
      iv_block2,            -- �u���b�N�Q
      iv_block3,            -- �u���b�N�R
      ln_deliver_from_id,   -- �o�Ɍ�
      ln_deliver_type,      -- �o�Ɍ`��
      iv_deliver_date_from, -- �o�ɓ�From
      iv_deliver_date_to,   -- �o�ɓ�To
      iv_item_code,         -- �i�ڃR�[�h
      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_target_cnt));
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
    WHEN INVALID_NUMBER THEN
      -- ���b�Z�[�W�̃Z�b�g
      -- �o�׌��ɕs���f�[�^����
      IF (lv_retcode = gv_cons_flg_yes) THEN
        lv_errbuf := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                      ,gv_msg_92a_009      -- �p�����[�^�����G���[
                                                      ,gv_tkn_parameter    -- �g�[�N��'PARAMETER'
                                                      ,gv_cons_deliv_fm    -- '�o�׌�'
                                                      ,gv_tkn_type         -- �g�[�N��'TYPE'
                                                      ,gv_cons_number)     -- '���l'
                                                      ,1
                                                      ,5000);
      -- �o�׌`�Ԃɕs���f�[�^����
      ELSE
        lv_errbuf := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                      ,gv_msg_92a_009      -- �p�����[�^�����G���[
                                                      ,gv_tkn_parameter    -- �g�[�N��'PARAMETER'
                                                      ,gv_cons_deliv_tp    -- '�o�׌`��'
                                                      ,gv_tkn_type         -- �g�[�N��'TYPE'
                                                      ,gv_cons_number)     -- '���l'
                                                      ,1
                                                      ,5000);
      END IF;
      errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      retcode := gv_status_error;                                            --# �C�� #
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
END XXWSH920008C;
/

