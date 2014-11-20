CREATE OR REPLACE PACKAGE BODY xxwsh600005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh600005c(body)
 * Description      : �m��u���b�N����
 * MD.050           : �o�׈˗� T_MD050_BPO_601
 * MD.070           : �m��u���b�N����  T_MD070_BPO_60D
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *  check_parameter        ���̓p�����[�^�`�F�b�N
 *  get_profile            �v���t�@�C���擾
 *  ins_temp_data          ���ԃe�[�u���o�^
 *  get_confirm_block_header �o�ׁE�x���E�ړ����w�b�_���o����
 *  get_confirm_block_line   �o�ׁE�x���E�ړ���񖾍ג��o����
 *  chk_reserved           ���������σ`�F�b�N����
 *  chk_mixed_prod         �o�ז��� ���i���݃`�F�b�N����
 *  chk_carrier            �z�ԍσ`�F�b�N����
 *  set_checked_data       �`�F�b�N�σf�[�^ PL/SQL�\�i�[����
 *  set_upd_data           �ʒm�X�e�[�^�X�X�V�pPL�^SQL�\ �i�[����
 *  upd_notif_status       �ʒm�X�e�[�^�X �ꊇ�X�V����
 *  purge_tbl              ���ԃe�[�u���p�[�W����
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/18    1.0  Oracle �㌴���D   ����쐬
 *  2008/06/16    1.1  Oracle �쑺���K   ������Q #9�Ή�
 *  2008/06/19    1.2  Oracle �㌴���D   ST��Q #178�Ή�
 *  2008/06/24    1.3  Oracle �㌴���D   �z��L/T�A�h�I���̃����[�V�����ɔz���敪��ǉ�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0'; -- ����
  gv_status_warn   CONSTANT VARCHAR2(1) := '1'; -- �x��
  gv_status_error  CONSTANT VARCHAR2(1) := '2'; -- �G���[
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C'; -- �X�e�[�^�X(����)
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G'; -- �X�e�[�^�X(�x��)
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E'; -- �X�e�[�^�X(�G���[)
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
  --*** �����Ώۃf�[�^�Ȃ���O ***
  global_no_data_found_expt EXCEPTION;
-- ##### 20080616 1.1 ������Q #9�Ή� START #####
  ex_worn                   EXCEPTION ;
-- ##### 20080616 1.1 ������Q #9�Ή� END   #####
  --*** ���b�N�G���[��O ***
  global_lock_error_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_lock_error_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name                 CONSTANT VARCHAR2(100) := 'xxwsh600005c';
                                                                 -- �p�b�P�[�W��
  gv_cons_msg_kbn_wsh         CONSTANT VARCHAR2(100) := 'XXWSH';
                                                                 -- �A�v���P�[�V�����Z�k��
  gv_prof_item_div_security   CONSTANT VARCHAR2(100) := 'XXCMN_ITEM_DIV_SECURITY';
                                                                 -- XXCMN�F���i�敪(�Z�L�����e�B)
  gv_line_feed                CONSTANT VARCHAR2(1)   := CHR(10);
                                                                 -- ���s�R�[�h
  gv_single_quote             CONSTANT VARCHAR2(2)   := '''';
                                                                 -- �V���O���R�[�g
  gv_ship_class_1             CONSTANT VARCHAR2(15)  := '1';
                                                                 -- �o�׈˗�
  gv_ship_class_2             CONSTANT VARCHAR2(15)  := '2';
                                                                 -- �x���w��
  -- �󒍃J�e�S��
  gv_order_cat_o              CONSTANT VARCHAR2(10) := 'ORDER' ;
  -- �o�׎x���敪
  gv_sp_class_ship            CONSTANT VARCHAR2(1)  := '1' ;    -- �o�׈˗�
  gv_sp_class_prov            CONSTANT VARCHAR2(1)  := '2' ;    -- �x���w��
  -- �ړ��X�e�[�^�X
  gv_mov_status_req           CONSTANT VARCHAR2(2)  := '01' ;   -- �˗���
  gv_mov_status_cmp           CONSTANT VARCHAR2(2)  := '02' ;   -- �˗���
  gv_mov_status_adj           CONSTANT VARCHAR2(2)  := '03' ;   -- ������
  gv_mov_status_del           CONSTANT VARCHAR2(2)  := '04' ;   -- �o�ɕ񍐗L
  gv_mov_status_stc           CONSTANT VARCHAR2(2)  := '05' ;   -- ���ɕ񍐗L
  gv_mov_status_dsr           CONSTANT VARCHAR2(2)  := '06' ;   -- ���o�ɕ񍐗L
  gv_mov_status_ccl           CONSTANT VARCHAR2(2)  := '99' ;   -- ���
  -- �ړ��^�C�v
  gc_mov_type_y               CONSTANT VARCHAR2(1)  := '1' ;    -- �ϑ�����
  gc_mov_type_n               CONSTANT VARCHAR2(1)  := '2' ;    -- �ϑ��Ȃ�
  -- �o�Ɍ`��
--  gv_transaction_type_id_ship CONSTANT VARCHAR2(100)  := '1033' ;    -- �o�׈˗�
  gv_transaction_type_name_ship CONSTANT VARCHAR2(100)  := '�o�׈˗�' ;    -- �o�׈˗�
  -- ������ʁi�m��u���b�N�j
  gv_proc_fix_block_ship      CONSTANT VARCHAR2(1) := '1';    -- �o�׈˗�
  gv_proc_fix_block_prov      CONSTANT VARCHAR2(1) := '2';    -- �x���w��
  gv_proc_fix_block_move      CONSTANT VARCHAR2(1) := '3';    -- �ړ��w��
  gv_proc_fix_block_ship_move CONSTANT VARCHAR2(1) := '4';    -- �o�׈˗�/�ړ��w��
  gv_proc_fix_block_prov_move CONSTANT VARCHAR2(1) := '5';    -- �x���w��/�ړ��w��
  gv_sales_code               CONSTANT VARCHAR2(1) := '1'; -- �N�C�b�N�R�[�h�u�R�[�h�敪�v�u���_�v
  gv_whse_code                CONSTANT VARCHAR2(1) := '4'; -- �N�C�b�N�R�[�h�u�R�[�h�敪�v�u�q�Ɂv
  gv_deliver_to               CONSTANT VARCHAR2(1) := '9'; -- �N�C�b�N�R�[�h�u�R�[�h�敪�v�u�z����v
  -- YesNo�敪
  gc_yn_div_y                 CONSTANT VARCHAR2(1)  := 'Y' ;    -- YES
  gc_yn_div_n                 CONSTANT VARCHAR2(1)  := 'N' ;    -- NO
  -- OnOff�敪
  gc_onoff_div_on             CONSTANT VARCHAR2(3)  := 'ON' ;    -- ON
  gc_onoff_div_off            CONSTANT VARCHAR2(3)  := 'OFF' ;    -- OFF
  -- �X�e�[�^�X
  gc_req_status_s_inp         CONSTANT VARCHAR2(2)  := '01' ;   -- ���͒�
  gc_req_status_s_cmpa        CONSTANT VARCHAR2(2)  := '02' ;   -- ���_�m��
  gc_req_status_s_cmpb        CONSTANT VARCHAR2(2)  := '03' ;   -- ���ߍς�
  gc_req_status_s_cmpc        CONSTANT VARCHAR2(2)  := '04' ;   -- �o�׎��ьv���
  gc_req_status_p_inp         CONSTANT VARCHAR2(2)  := '05' ;   -- ���͒�
  gc_req_status_p_cmpa        CONSTANT VARCHAR2(2)  := '06' ;   -- ���͊���
  gc_req_status_p_cmpb        CONSTANT VARCHAR2(2)  := '07' ;   -- ��̍�
  gc_req_status_p_cmpc        CONSTANT VARCHAR2(2)  := '08' ;   -- �o�׎��ьv���
  gc_req_status_p_ccl         CONSTANT VARCHAR2(2)  := '99' ;   -- ���
  -- �ʒm�X�e�[�^�X
  gc_notif_status_unnotif     CONSTANT VARCHAR2(2)  := '10' ;   -- ���ʒm
  gc_notif_status_renotif     CONSTANT VARCHAR2(2)  := '20' ;   -- �Ēʒm�v
  gc_notif_status_notifed     CONSTANT VARCHAR2(2)  := '40' ;   -- �m��ʒm��
 -- �i�ڋ敪
  gv_cons_item_product        CONSTANT VARCHAR2(1)   := '5';    -- �u���i�v
 -- ���i���ʋ敪
  gv_cons_product_class       CONSTANT VARCHAR2(1)   := '1';    -- �u���i�v
  -- ���i�敪
  gv_prod_class_leaf          CONSTANT VARCHAR2(1) :=  '1';    -- ���i�敪�u���[�t�v
  gv_prod_class_drink         CONSTANT VARCHAR2(1) :=  '2';    -- ���i�敪�u�h�����N�v
  -- �f�[�^�敪
  gc_data_class_order         CONSTANT VARCHAR2(1)  := '1' ;   -- �o�׈˗�
  gc_data_class_prov          CONSTANT VARCHAR2(1)  := '2' ;   -- �x���w��
  gc_data_class_move          CONSTANT VARCHAR2(1)  := '3' ;   -- �ړ��w��
  gc_data_class_order_cncl    CONSTANT VARCHAR2(1)  := '8' ;   -- �o�׎��
  gc_data_class_prov_cncl     CONSTANT VARCHAR2(1)  := '9' ;   -- �x�����
  -- �^���敪
  gv_freight_charge_class_on  CONSTANT VARCHAR2(1) :=  '1';    -- �^���敪�u�Ώہv
  gv_freight_charge_class_off CONSTANT VARCHAR2(1) :=  '0';    -- �^���敪�u�ΏۊO�v
  -- �G���[���b�Z�[�W
  gv_output_msg               CONSTANT VARCHAR2(100) := 'APP-XXWSH-01701';
                                                             -- �o�͌���
  gv_input_date_err           CONSTANT VARCHAR2(100) := 'APP-XXWSH-11851';
                                                             -- ���̓p�����[�^�o�ɗ\������̓G���[
  gv_input_format_err         CONSTANT VARCHAR2(100) := 'APP-XXWSH-11852';
                                                             -- ���̓p�����[�^�����G���[
  gv_check_line_err           CONSTANT VARCHAR2(100) := 'APP-XXWSH-11853';
                                                             -- �z�ԍρE���������σ`�F�b�N�G���[
  gv_need_input_err           CONSTANT VARCHAR2(100) := 'APP-XXWSH-11854';
                                                             -- ���̓p�����[�^�����̓G���[
  gv_lock_err                 CONSTANT VARCHAR2(100) := 'APP-XXWSH-11855';
                                                             -- ���b�N�G���[
  gv_no_data_found_err        CONSTANT VARCHAR2(100) := 'APP-XXWSH-11856';
                                                             -- �����Ώۃf�[�^�Ȃ��G���[
  gv_profile_err              CONSTANT VARCHAR2(100) := 'APP-XXWSH-11857';
                                                             -- �v���t�@�C���擾�G���[
  gv_cnst_tkn_para            CONSTANT VARCHAR2(100) := 'PARAMETER';
                                                             -- ���̓p�����[�^��
  gv_cnst_tkn_para2           CONSTANT VARCHAR2(100) := 'PARAMETER2';
                                                             -- ���̓p�����[�^��2
  gv_cnst_tkn_date            CONSTANT VARCHAR2(100) := 'DATE';
                                                             -- �o�ɓ�
  gv_cnst_tkn_prof            CONSTANT VARCHAR2(100) := 'PROF_NAME';
                                                             -- �v���t�@�C����
  gv_cnst_tkn_check_kbn       CONSTANT VARCHAR2(100) := 'CHECK_KBN';
                                                             -- �`�F�b�N�敪
  gv_cnst_tkn_delivery_no     CONSTANT VARCHAR2(100) := 'DELIVERY_NO';
                                                             -- �z��No
  gv_cnst_tkn_request_no      CONSTANT VARCHAR2(100) := 'REQUEST_NO';
                                                             -- �˗�No
  -- �g�[�N��
  gv_tkn_item_div_security    CONSTANT VARCHAR2(100) := 'XXCMN�F���i�敪(�Z�L�����e�B)';
  gv_tkn_dept_code            CONSTANT VARCHAR2(100) := '����';
  gv_tkn_shipping_biz_type    CONSTANT VARCHAR2(100) := '�������';
  gv_tkn_transaction_type_id  CONSTANT VARCHAR2(100) := '�o�Ɍ`��';
  gv_tkn_lead_time_day_01     CONSTANT VARCHAR2(100) := '���Y����LT1';
  gv_tkn_lt1_ship_date_from   CONSTANT VARCHAR2(100) := '���Y����LT1/�o�׈˗�/�o�ɓ�From';
  gv_tkn_lt1_ship_date_to     CONSTANT VARCHAR2(100) := '���Y����LT1/�o�׈˗�/�o�ɓ�To';
  gv_tkn_lead_time_day_02     CONSTANT VARCHAR2(100) := '���Y����LT2';
  gv_tkn_lt2_ship_date_from   CONSTANT VARCHAR2(100) := '���Y����LT2/�o�׈˗�/�o�ɓ�From';
  gv_tkn_lt2_ship_date_to     CONSTANT VARCHAR2(100) := '���Y����LT2/�o�׈˗�/�o�ɓ�To';
  gv_tkn_ship_date_from       CONSTANT VARCHAR2(100) := '�o�ɓ�From';
  gv_tkn_ship_date_to         CONSTANT VARCHAR2(100) := '�o�ɓ�To';
  gv_tkn_move_ship_date_from  CONSTANT VARCHAR2(100) := '�ړ�/�o�ɓ�From';
  gv_tkn_move_ship_date_to    CONSTANT VARCHAR2(100) := '�ړ�/�o�ɓ�To';
  gv_tkn_prov_ship_date_from  CONSTANT VARCHAR2(100) := '�x��/�o�ɓ�From';
  gv_tkn_prov_ship_date_to    CONSTANT VARCHAR2(100) := '�x��/�o�ɓ�To';
  gv_tkn_reserved_err         CONSTANT VARCHAR2(100) := '�����G���[';
  gv_tkn_carrier_err          CONSTANT VARCHAR2(100) := '�z�ԃG���[';
  gv_tkn_reserved_carrier_err CONSTANT VARCHAR2(100) := '�����y�єz�ԃG���[';
  gv_tkn_mixed_prod_err       CONSTANT VARCHAR2(100) := '�o�׈˗����i����';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD
    (
      dept_code              VARCHAR2(4),  -- ����
      shipping_biz_type      VARCHAR2(2),  -- �������
      transaction_type_id    VARCHAR2(4),  -- �o�Ɍ`��
      lead_time_day_01       NUMBER,       -- ���Y����LT1
      lt1_ship_date_from     DATE,         -- ���Y����LT1/�o�׈˗�/�o�ɓ�From
      lt1_ship_date_to       DATE,         -- ���Y����LT1/�o�׈˗�/�o�ɓ�To
      lead_time_day_02       NUMBER,       -- ���Y����LT2
      lt2_ship_date_from     DATE,         -- ���Y����LT2/�o�׈˗�/�o�ɓ�From
      lt2_ship_date_to       DATE,         -- ���Y����LT2/�o�׈˗�/�o�ɓ�To
      ship_date_from         DATE,         -- �o�ɓ�From
      ship_date_to           DATE,         -- �o�ɓ�To
      move_ship_date_from    DATE,         -- �ړ�/�o�ɓ�From
      move_ship_date_to      DATE,         -- �ړ�/�o�ɓ�To
      prov_ship_date_from    DATE,         -- �x��/�o�ɓ�From
      prov_ship_date_to      DATE,         -- �x��/�o�ɓ�To
      block_01               VARCHAR2(2),  -- �u���b�N�P
      block_02               VARCHAR2(2),  -- �u���b�N�Q
      block_03               VARCHAR2(2),  -- �u���b�N�R
      shipped_locat_code     VARCHAR2(4)   -- �o�Ɍ�
    ) ;
  -- �w�b�_���ԃe�[�u���o�^�p���R�[�h�ϐ�
  TYPE rec_temp_tab_data IS RECORD
    (
     data_class           xxwsh.xxwsh_confirm_block_tmp.data_class%TYPE           -- �f�[�^�敪
    ,whse_code            xxwsh.xxwsh_confirm_block_tmp.whse_code%TYPE          -- �ۊǑq�ɃR�[�h
    ,header_id            xxwsh.xxwsh_confirm_block_tmp.header_id%TYPE            -- �w�b�_ID
    ,notif_status         xxwsh.xxwsh_confirm_block_tmp.notif_status%TYPE         -- �ʒm�X�e�[�^�X
    ,prod_class           xxwsh.xxwsh_confirm_block_tmp.prod_class%TYPE           -- ���i�敪
    ,item_class           xxwsh.xxwsh_confirm_block_tmp.item_class%TYPE           -- �i�ڋ敪
    ,delivery_no          xxwsh.xxwsh_confirm_block_tmp.delivery_no%TYPE          -- �z��No
    ,request_no           xxwsh.xxwsh_confirm_block_tmp.request_no%TYPE           -- �˗�No
    ,freight_charge_class xxwsh.xxwsh_confirm_block_tmp.freight_charge_class%TYPE  -- �^���敪
    ,d1_whse_code         xxwsh.xxwsh_confirm_block_tmp.d1_whse_code%TYPE         -- D+1�q�Ƀt���O
    ,base_date            xxwsh.xxwsh_confirm_block_tmp.base_date%TYPE            -- ���
    ) ;
  TYPE rec_temp_tab_data_tab IS TABLE OF rec_temp_tab_data INDEX BY PLS_INTEGER;
--
  -- ���ג��o�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_get_data_line IS RECORD
    (
      order_header_id   NUMBER     -- �󒍃w�b�_ID
     ,order_line_id     NUMBER     -- �󒍖���ID
     ,quantity          NUMBER     -- ����
     ,reserved_quantity NUMBER     -- ������
     ,lot_ctl           VARCHAR2(2)   -- ���b�g�Ǘ��敪
     ,item_class_code   VARCHAR2(2)   -- �i�ڋ敪
    ) ;
  TYPE rec_get_data_line_tab IS TABLE OF rec_get_data_line INDEX BY PLS_INTEGER;
--
  -- �`�F�b�N�σf�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_checked_data IS RECORD
    (
     data_class            xxwsh.xxwsh_confirm_block_tmp.data_class%TYPE       -- �f�[�^�敪
    ,delivery_no           xxwsh.xxwsh_confirm_block_tmp.delivery_no%TYPE      -- �z��No
    ,request_no            xxwsh.xxwsh_confirm_block_tmp.request_no%TYPE       -- �˗�No
    ,notif_status          xxwsh.xxwsh_confirm_block_tmp.notif_status%TYPE     -- �ʒm�X�e�[�^�X
    ) ;
  TYPE rec_checked_data_tab IS TABLE OF rec_checked_data INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gr_param                rec_param_data ;      -- �p�����[�^
  gr_chk_header_data_tab  rec_temp_tab_data_tab; -- �`�F�b�N�p�w�b�_�f�[�^�Q
  gr_chk_line_data_tab    rec_get_data_line_tab; -- �`�F�b�N�p���׃f�[�^�Q
  gr_checked_data_tab     rec_checked_data_tab;   -- �`�F�b�N�σf�[�^�i�[�p�f�[�^�Q
  gr_upd_data_tab         rec_checked_data_tab;   -- �X�V�f�[�^�i�[�p�f�[�^�Q
  -- ���̓p�����[�^�i�[�p
  gv_lt1_ship_date_from   VARCHAR2(20);     -- ���Y����LT1/�o�׈˗�/�o�ɓ�From
  gv_lt1_ship_date_to     VARCHAR2(20);     -- ���Y����LT1/�o�׈˗�/�o�ɓ�To
  gv_lt2_ship_date_from   VARCHAR2(20);     -- ���Y����LT2/�o�׈˗�/�o�ɓ�From
  gv_lt2_ship_date_to     VARCHAR2(20);     -- ���Y����LT2/�o�׈˗�/�o�ɓ�To
  gv_ship_date_from       VARCHAR2(20);     -- �o�ɓ�From
  gv_ship_date_to         VARCHAR2(20);     -- �o�ɓ�To
  gv_move_ship_date_from  VARCHAR2(20);     -- �ړ�/�o�ɓ�From
  gv_move_ship_date_to    VARCHAR2(20);     -- �ړ�/�o�ɓ�To
  gv_prov_ship_date_from  VARCHAR2(20);     -- �x��/�o�ɓ�From
  gv_prov_ship_date_to    VARCHAR2(20);     -- �x��/�o�ɓ�To
  gn_cnt_line             NUMBER ;   -- ���׌���
  gn_cnt_prod             NUMBER ;   -- ���i����
  gn_cnt_no_prod          NUMBER ;   -- ���i�ȊO����
  gn_cnt_upd              NUMBER ;   -- �X�V�p�f�[�^����
  gn_cnt_upd_ship         NUMBER ;   -- �o�׍X�V����
  gn_cnt_upd_prov         NUMBER ;   -- �x���X�V����
  gn_cnt_upd_move         NUMBER ;   -- �ړ��X�V����
  gv_data_found_flg       VARCHAR2(3) ;   -- �����Ώۃf�[�^����t���O
  gv_err_flg_resv         VARCHAR2(3) ;   -- �����G���[�t���O
  gv_err_flg_whse         VARCHAR2(3) ;   -- �q�ɃG���[�t���O
  gv_err_flg_carr         VARCHAR2(3) ;   -- �z�ԃG���[�t���O
  gv_war_flg_carr_mixed   VARCHAR2(3) ;   -- �z�ԏo�׈˗����i���݃��[�j���O�t���O
  -- WHO�J����
  gt_user_id          xxcmn_txn_lot_cost.created_by%TYPE;             -- �쐬�ҁA�ŏI�X�V��
  gt_login_id         xxcmn_txn_lot_cost.last_update_login%TYPE;      -- �ŏI�X�V���O�C��
  gt_conc_request_id  xxcmn_txn_lot_cost.request_id%TYPE;             -- �v��ID
  gt_prog_appl_id     xxcmn_txn_lot_cost.program_application_id%TYPE; -- �A�v���P�[�V����ID
  gt_conc_program_id  xxcmn_txn_lot_cost.program_id%TYPE;             -- �v���O����ID
--
  gv_transaction_type_id_ship VARCHAR2(4) ;   -- �o�Ɍ`��
  gv_item_div_security       VARCHAR2(100);
  -- �o�׈˗����ߊǗ���񒊏o�p
  gt_order_type_id           XXWSH_TIGHTENING_CONTROL.ORDER_TYPE_ID%TYPE;
                                                                         -- �󒍃^�C�vID
  gt_deliver_from            XXWSH_TIGHTENING_CONTROL.DELIVER_FROM%TYPE;
                                                                         -- �o�׌��ۊǏꏊ
  gt_prod_class_type         XXWSH_TIGHTENING_CONTROL.PROD_CLASS%TYPE;
                                                                         -- ���i�敪
  gt_sales_branch_category   XXWSH_TIGHTENING_CONTROL.SALES_BRANCH_CATEGORY%TYPE;
                                                                         -- ���_�J�e�S��
  gt_lead_time_day           XXWSH_TIGHTENING_CONTROL.LEAD_TIME_DAY%TYPE;
                                                                         -- ���Y����LT/����ύXLT
  gt_schedule_ship_date      XXWSH_TIGHTENING_CONTROL.SCHEDULE_SHIP_DATE%TYPE;
                                                                         -- �o�ח\���
  gt_tighten_release_class   XXWSH_TIGHTENING_CONTROL.TIGHTEN_RELEASE_CLASS%TYPE;
                                                                         -- ���߁^�����敪
  gt_base_record_class       XXWSH_TIGHTENING_CONTROL.BASE_RECORD_CLASS%TYPE;
                                                                         -- ����R�[�h�敪
  gt_system_date             DATE;                                       -- �V�X�e�����t
--
  /**********************************************************************************
   * Procedure Name   : check_parameter
   * Description      : D-1  ���̓p�����[�^�`�F�b�N
   ***********************************************************************************/
  PROCEDURE check_parameter(
    ov_errbuf               OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ************************************
    -- ***  �o�Ɍ`��(�o�׈˗�)�擾      ***
    -- ************************************
    SELECT transaction_type_id 
      INTO gv_transaction_type_id_ship 
      FROM XXWSH_OE_TRANSACTION_TYPES2_V
      WHERE transaction_type_name = gv_transaction_type_name_ship;
    IF gv_transaction_type_id_ship IS NULL THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                ,gv_profile_err   -- �v���t�@�C���擾�G���[
                                                ,gv_cnst_tkn_prof    -- �g�[�N��'PROF_NAME'
                                                ,gv_tkn_transaction_type_id)   -- '�o�Ɍ`��'
                                                ,1
                                                ,5000);
          -- �G���[���^�[�����������~
          RAISE global_api_expt;
        END IF;
--
    -- ************************************
    -- ***  ���̓p�����[�^�K�{�`�F�b�N  ***
    -- ************************************
    -- �����̓��͂��Ȃ��ꍇ�̓G���[�Ƃ���
    IF (gr_param.dept_code IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                ,gv_need_input_err   -- ���̓p�����[�^�����̓G���[
                                                ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                                ,gv_tkn_dept_code)   -- '����'
                                                ,1
                                                ,5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- ������ʂ̓��͂��Ȃ��ꍇ�̓G���[�Ƃ���
    IF (gr_param.shipping_biz_type IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                ,gv_need_input_err   -- ���̓p�����[�^�����̓G���[
                                                ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                                ,gv_tkn_shipping_biz_type)   -- '�������'
                                                ,1
                                                ,5000);
      -- �G���[���^�[�����������~
      RAISE global_api_expt;
    END IF;
--
    -- -----------------------------------------------------
    -- ������ʂ��u�o�׈˗��v���́u�o�׈˗�/�ړ��`�[�v�̏ꍇ
    -- -----------------------------------------------------
    IF (gr_param.shipping_biz_type IN (gv_proc_fix_block_ship,gv_proc_fix_block_ship_move)) THEN
      -- �o�Ɍ`�Ԃ̓��͂��Ȃ��ꍇ�̓G���[�Ƃ���
      IF (gr_param.transaction_type_id IS NULL) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                ,gv_need_input_err   -- ���̓p�����[�^�����̓G���[
                                ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                ,gv_tkn_transaction_type_id)   -- '�o�Ɍ`��'
                                ,1
                                ,5000);
        -- �G���[���^�[�����������~
        RAISE global_api_expt;
      -- -----------------------------------------------------
      -- �o�Ɍ`�Ԃ��u�o�׈˗��v�̏ꍇ
      -- -----------------------------------------------------
      ELSIF (gr_param.transaction_type_id = gv_transaction_type_id_ship) THEN
        -- ���Y����LT1�܂��͐��Y����LT2�̂ǂ��炩�����͂���Ă��Ȃ��ꍇ�̓G���[�Ƃ���
        IF (gr_param.lead_time_day_01 IS NULL AND gr_param.lead_time_day_02 IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                ,gv_need_input_err   -- ���̓p�����[�^�����̓G���[
                                                ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                                ,gv_tkn_lead_time_day_01)   -- '���Y����LT1'
                                                ,1
                                                ,5000);
          -- �G���[���^�[�����������~
          RAISE global_api_expt;
        END IF;
      END IF;
      -- -----------------------------------------------------
      -- ���Y����LT1�����͂���Ă���ꍇ
      -- -----------------------------------------------------
      IF (gr_param.lead_time_day_01 IS NOT NULL) THEN
        -- ���Y����LT1/�o�׈˗�/�o�ɓ�From�����͂���Ă��Ȃ��ꍇ�̓G���[�Ƃ���
        IF (gv_lt1_ship_date_from IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_need_input_err   -- ���̓p�����[�^�����̓G���[
                                 ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                 ,gv_tkn_lt1_ship_date_from)  -- '���Y����LT1/�o�׈˗�/�o�ɓ�From'
                                 ,1
                                 ,5000);
          -- �G���[���^�[�����������~
          RAISE global_api_expt;
        ELSE
          -- ==============================================================
          -- ���t�^(YYYY/MM/DD)�ɕϊ����Ċi�[
          -- ==============================================================
          gr_param.lt1_ship_date_from := FND_DATE.STRING_TO_DATE( gv_lt1_ship_date_from
                                                                                  ,'YYYY/MM/DD');
          IF (gr_param.lt1_ship_date_from IS NULL) THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                   ,gv_input_format_err   -- ���̓p�����[�^�����̓G���[
                                   ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                   ,gv_tkn_lt1_ship_date_from
                                                               -- '���Y����LT1/�o�׈˗�/�o�ɓ�From'
                                   ,gv_cnst_tkn_date    -- �g�[�N��'DATE'
                                   ,TO_CHAR(gv_lt1_ship_date_from))
                                                               -- '���Y����LT1/�o�׈˗�/�o�ɓ�From'
                                   ,1
                                   ,5000);
            -- �G���[���^�[�����������~
            RAISE global_api_expt;
          END IF;
        END IF;
        -- ���Y����LT1/�o�׈˗�/�o�ɓ�To�����͂���Ă��Ȃ��ꍇ�̓G���[�Ƃ���
        IF (gv_lt1_ship_date_to IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_need_input_err   -- ���̓p�����[�^�����̓G���[
                                 ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                 ,gv_tkn_lt1_ship_date_to)  -- '���Y����LT1/�o�׈˗�/�o�ɓ�To'
                                 ,1
                                 ,5000);
          -- �G���[���^�[�����������~
          RAISE global_api_expt;
        ELSE
          -- ==============================================================
          -- ���t�^(YYYY/MM/DD)�ɕϊ����Ċi�[
          -- ==============================================================
          gr_param.lt1_ship_date_to  := FND_DATE.STRING_TO_DATE( gv_lt1_ship_date_to
                                                                                ,'YYYY/MM/DD');
          IF (gr_param.lt1_ship_date_to IS NULL) THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                   ,gv_input_format_err   -- ���̓p�����[�^�����̓G���[
                                   ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                   ,gv_tkn_lt1_ship_date_to  -- '���Y����LT1/�o�׈˗�/�o�ɓ�To'
                                   ,gv_cnst_tkn_date    -- �g�[�N��'DATE'
                                   ,TO_CHAR(gv_lt1_ship_date_to))
                                                             -- '���Y����LT1/�o�׈˗�/�o�ɓ�To'
                                   ,1
                                   ,5000);
            -- �G���[���^�[�����������~
            RAISE global_api_expt;
          END IF;
        END IF;
        -- ���Y����LT1/�o�׈˗�/�o�ɓ�From�Ɛ��Y����LT1/�o�׈˗�/�o�ɓ�To���t�]���Ă�����G���[
        IF (gr_param.lt1_ship_date_from > gr_param.lt1_ship_date_to) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_input_date_err    -- ���̓p�����[�^�����G���[
                                 ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                 ,gv_tkn_lt1_ship_date_to  -- '���Y����LT1/�o�׈˗�/�o�ɓ�To'
                                 ,gv_cnst_tkn_para2    -- �g�[�N��'PRAMETER2'
                                 ,gv_tkn_lt1_ship_date_from)  -- '���Y����LT1/�o�׈˗�/�o�ɓ�From'
                                 ,1
                                 ,5000);
          -- �G���[���^�[�����������~
          RAISE global_api_expt;
        END IF;
      END IF;
      -- -----------------------------------------------------
      -- ���Y����LT2�����͂���Ă���ꍇ
      -- -----------------------------------------------------
      IF (gr_param.lead_time_day_02 IS NOT NULL) THEN
        -- ���Y����LT2/�o�׈˗�/�o�ɓ�From�����͂���Ă��Ȃ��ꍇ�̓G���[�Ƃ���
        IF (gv_lt2_ship_date_from IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_need_input_err   -- ���̓p�����[�^�����̓G���[
                                 ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                 ,gv_tkn_lt2_ship_date_from)  -- '���Y����LT2/�o�׈˗�/�o�ɓ�From'
                                 ,1
                                 ,5000);
          -- �G���[���^�[�����������~
          RAISE global_api_expt;
        ELSE
          -- ==============================================================
          -- ���t�^(YYYY/MM/DD)�ɕϊ����Ċi�[
          -- ==============================================================
          gr_param.lt2_ship_date_from := FND_DATE.STRING_TO_DATE( gv_lt2_ship_date_from
                                                                                  ,'YYYY/MM/DD');
          IF (gr_param.lt2_ship_date_from IS NULL) THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                   ,gv_input_format_err   -- ���̓p�����[�^�����̓G���[
                                   ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                   ,gv_tkn_lt2_ship_date_from
                                                               -- '���Y����LT2/�o�׈˗�/�o�ɓ�From'
                                   ,gv_cnst_tkn_date    -- �g�[�N��'DATE'
                                   ,TO_CHAR(gv_lt2_ship_date_from))
                                                               -- '���Y����LT2/�o�׈˗�/�o�ɓ�From'
                                   ,1
                                   ,5000);
            -- �G���[���^�[�����������~
            RAISE global_api_expt;
          END IF;
        END IF;
        -- ���Y����LT2/�o�׈˗�/�o�ɓ�To�����͂���Ă��Ȃ��ꍇ�̓G���[�Ƃ���
        IF (gv_lt2_ship_date_to IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_need_input_err   -- ���̓p�����[�^�����̓G���[
                                 ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                 ,gv_tkn_lt2_ship_date_to)  -- '���Y����LT2/�o�׈˗�/�o�ɓ�To'
                                 ,1
                                 ,5000);
          -- �G���[���^�[�����������~
          RAISE global_api_expt;
        ELSE
          -- ==============================================================
          -- ���t�^(YYYY/MM/DD)�ɕϊ����Ċi�[
          -- ==============================================================
          gr_param.lt2_ship_date_to  := FND_DATE.STRING_TO_DATE( gv_lt2_ship_date_to
                                                                                ,'YYYY/MM/DD');
          IF (gr_param.lt2_ship_date_to IS NULL) THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                   ,gv_input_format_err   -- ���̓p�����[�^�����̓G���[
                                   ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                   ,gv_tkn_lt2_ship_date_to  -- '���Y����LT2/�o�׈˗�/�o�ɓ�To'
                                   ,gv_cnst_tkn_date    -- �g�[�N��'DATE'
                                   ,TO_CHAR(gv_lt2_ship_date_to))
                                                             -- '���Y����LT2/�o�׈˗�/�o�ɓ�To'
                                   ,1
                                   ,5000);
            -- �G���[���^�[�����������~
            RAISE global_api_expt;
          END IF;
        END IF;
        -- ���Y����LT2/�o�׈˗�/�o�ɓ�From�Ɛ��Y����LT2/�o�׈˗�/�o�ɓ�To���t�]���Ă�����G���[
        IF (gr_param.lt2_ship_date_from > gr_param.lt2_ship_date_to) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_input_date_err    -- ���̓p�����[�^�����G���[
                                 ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                 ,gv_tkn_lt2_ship_date_to  -- '���Y����LT2/�o�׈˗�/�o�ɓ�T0'
                                 ,gv_cnst_tkn_para2    -- �g�[�N��'PRAMETER2'
                                 ,gv_tkn_lt2_ship_date_from)  -- '���Y����LT2/�o�׈˗�/�o�ɓ�From'
                                 ,1
                                 ,5000);
          -- �G���[���^�[�����������~
          RAISE global_api_expt;
        END IF;
      END IF;
      -- -----------------------------------------------------
      -- �o�Ɍ`�Ԃ��u�o�׈˗��v�ȊO�̏ꍇ
      -- -----------------------------------------------------
      IF (gr_param.transaction_type_id <> gv_transaction_type_id_ship) THEN
        -- �o�ɓ�From�����͂���Ă��Ȃ��ꍇ�̓G���[�Ƃ���
        IF (gv_ship_date_from IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_need_input_err   -- ���̓p�����[�^�����̓G���[
                                 ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                 ,gv_tkn_ship_date_from)  -- '�o�ɓ�From'
                                 ,1
                                 ,5000);
          -- �G���[���^�[�����������~
          RAISE global_api_expt;
        ELSE
          -- ==============================================================
          -- ���t�^(YYYY/MM/DD)�ɕϊ����Ċi�[
          -- ==============================================================
          gr_param.ship_date_from := FND_DATE.STRING_TO_DATE( gv_ship_date_from,'YYYY/MM/DD');
          IF (gr_param.ship_date_from IS NULL) THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                   ,gv_input_format_err   -- ���̓p�����[�^�����̓G���[
                                   ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                   ,gv_tkn_ship_date_from        -- '�o�ɓ�From'
                                   ,gv_cnst_tkn_date    -- �g�[�N��'DATE'
                                   ,TO_CHAR(gv_ship_date_from))  -- '�o�ɓ�From'
                                   ,1
                                   ,5000);
            -- �G���[���^�[�����������~
            RAISE global_api_expt;
          END IF;
        END IF;
        -- �o�ɓ�To�����͂���Ă��Ȃ��ꍇ�̓G���[�Ƃ���
        IF (gv_ship_date_to IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_need_input_err   -- ���̓p�����[�^�����̓G���[
                                 ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                 ,gv_tkn_ship_date_to)  -- '�o�ɓ�To'
                                 ,1
                                 ,5000);
          -- �G���[���^�[�����������~
          RAISE global_api_expt;
        ELSE
          -- ==============================================================
          -- ���t�^(YYYY/MM/DD)�ɕϊ����Ċi�[
          -- ==============================================================
          gr_param.ship_date_to := FND_DATE.STRING_TO_DATE( gv_ship_date_to,'YYYY/MM/DD');
          IF (gr_param.ship_date_to IS NULL) THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                   ,gv_input_format_err   -- ���̓p�����[�^�����̓G���[
                                   ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                   ,gv_tkn_ship_date_to        -- '�o�ɓ�To'
                                   ,gv_cnst_tkn_date    -- �g�[�N��'DATE'
                                   ,TO_CHAR(gv_ship_date_to))  -- '�o�ɓ�To'
                                   ,1
                                   ,5000);
            -- �G���[���^�[�����������~
            RAISE global_api_expt;
          END IF;
        END IF;
        -- �o�ɓ�From�Əo�ɓ�To���t�]���Ă�����G���[
        IF (gr_param.ship_date_from > gr_param.ship_date_to) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_input_date_err    -- ���̓p�����[�^�����G���[
                                 ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                 ,gv_tkn_ship_date_to  -- '�o�ɓ�From'
                                 ,gv_cnst_tkn_para2    -- �g�[�N��'PRAMETER2'
                                 ,gv_tkn_ship_date_from)  -- '�o�ɓ�To'
                                 ,1
                                 ,5000);
          -- �G���[���^�[�����������~
          RAISE global_api_expt;
        END IF;
      END IF;
    END IF;
    -- -----------------------------------------------------
    -- ������ʂ��u�x���w���v���́u�x���w��/�ړ��w���v�̏ꍇ
    -- -----------------------------------------------------
    IF (gr_param.shipping_biz_type IN (gv_proc_fix_block_prov,gv_proc_fix_block_prov_move)) THEN
      -- �x��/�o�ɓ�From�����͂���Ă��Ȃ��ꍇ�̓G���[�Ƃ���
      IF (gv_prov_ship_date_from IS NULL) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                               ,gv_need_input_err   -- ���̓p�����[�^�����̓G���[
                               ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                               ,gv_tkn_prov_ship_date_from)  -- '�x��/�o�ɓ�From'
                               ,1
                               ,5000);
        -- �G���[���^�[�����������~
        RAISE global_api_expt;
      ELSE
        -- ==============================================================
        -- ���t�^(YYYY/MM/DD)�ɕϊ����Ċi�[
        -- ==============================================================
        gr_param.prov_ship_date_from := FND_DATE.STRING_TO_DATE( gv_prov_ship_date_from
                                                                               ,'YYYY/MM/DD');
        IF (gr_param.prov_ship_date_from IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_input_format_err   -- ���̓p�����[�^�����̓G���[
                                 ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                 ,gv_tkn_prov_ship_date_from        -- '�x��/�o�ɓ�From'
                                 ,gv_cnst_tkn_date    -- �g�[�N��'DATE'
                                 ,TO_CHAR(gv_prov_ship_date_from))  -- '�x��/�o�ɓ�From'
                                 ,1
                                 ,5000);
          -- �G���[���^�[�����������~
          RAISE global_api_expt;
        END IF;
      END IF;
      -- �x��/�o�ɓ�To�����͂���Ă��Ȃ��ꍇ�̓G���[�Ƃ���
      IF (gv_prov_ship_date_to IS NULL) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                               ,gv_need_input_err   -- ���̓p�����[�^�����̓G���[
                               ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                               ,gv_tkn_prov_ship_date_to)  -- '�x��/�o�ɓ�To'
                               ,1
                               ,5000);
        -- �G���[���^�[�����������~
        RAISE global_api_expt;
      ELSE
        -- ==============================================================
        -- ���t�^(YYYY/MM/DD)�ɕϊ����Ċi�[
        -- ==============================================================
        gr_param.prov_ship_date_to := FND_DATE.STRING_TO_DATE( gv_prov_ship_date_to
                                                                               ,'YYYY/MM/DD');
        IF (gr_param.prov_ship_date_to IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_input_format_err   -- ���̓p�����[�^�����̓G���[
                                 ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                 ,gv_tkn_prov_ship_date_to        -- '�x��/�o�ɓ�To'
                                 ,gv_cnst_tkn_date    -- �g�[�N��'DATE'
                                 ,TO_CHAR(gv_prov_ship_date_to))  -- '�x��/�o�ɓ�To'
                                 ,1
                                 ,5000);
          -- �G���[���^�[�����������~
          RAISE global_api_expt;
        END IF;
      END IF;
      -- �x��/�o�ɓ�From�Ǝx��/�o�ɓ�To���t�]���Ă�����G���[
      IF (gr_param.prov_ship_date_from > gr_param.prov_ship_date_to) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                               ,gv_input_date_err    -- ���̓p�����[�^�����G���[
                               ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                               ,gv_tkn_prov_ship_date_to  -- '�x��/�o�ɓ�To'
                               ,gv_cnst_tkn_para2    -- �g�[�N��'PRAMETER2'
                               ,gv_tkn_prov_ship_date_from)  -- '�x��/�o�ɓ�From'
                               ,1
                               ,5000);
        -- �G���[���^�[�����������~
        RAISE global_api_expt;
      END IF;
    END IF;
    -- -----------------------------------------------------
    -- ������ʂ��u�ړ��w���v���͖��́u�o�׈˗�/�ړ��w���u�x���w��/�ړ��w���v�̏ꍇ
    -- -----------------------------------------------------
    IF (gr_param.shipping_biz_type IN (gv_proc_fix_block_move,gv_proc_fix_block_ship_move
                                                             ,gv_proc_fix_block_prov_move)) THEN
      -- �ړ�/�o�ɓ�From�����͂���Ă��Ȃ��ꍇ�̓G���[�Ƃ���
      IF (gv_move_ship_date_from IS NULL) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                               ,gv_need_input_err   -- ���̓p�����[�^�����̓G���[
                               ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                               ,gv_tkn_move_ship_date_from)  -- '�ړ�/�o�ɓ�From'
                               ,1
                               ,5000);
        -- �G���[���^�[�����������~
        RAISE global_api_expt;
      ELSE
        -- ==============================================================
        -- ���t�^(YYYY/MM/DD)�ɕϊ����Ċi�[
        -- ==============================================================
        gr_param.move_ship_date_from := FND_DATE.STRING_TO_DATE( gv_move_ship_date_from
                                                                               ,'YYYY/MM/DD');
        IF (gr_param.move_ship_date_from IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_input_format_err   -- ���̓p�����[�^�����̓G���[
                                 ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                 ,gv_tkn_move_ship_date_from        -- '�ړ�/�o�ɓ�From'
                                 ,gv_cnst_tkn_date    -- �g�[�N��'DATE'
                                 ,TO_CHAR(gv_move_ship_date_from))  -- '�ړ�/�o�ɓ�From'
                                 ,1
                                 ,5000);
          -- �G���[���^�[�����������~
          RAISE global_api_expt;
        END IF;
      END IF;
      -- �ړ�/�o�ɓ�To�����͂���Ă��Ȃ��ꍇ�̓G���[�Ƃ���
      IF (gv_move_ship_date_to IS NULL) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                               ,gv_need_input_err   -- ���̓p�����[�^�����̓G���[
                               ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                               ,gv_tkn_move_ship_date_to)  -- '�ړ�/�o�ɓ�To'
                               ,1
                               ,5000);
        -- �G���[���^�[�����������~
        RAISE global_api_expt;
      ELSE
        -- ==============================================================
        -- ���t�^(YYYY/MM/DD)�ɕϊ����Ċi�[
        -- ==============================================================
        gr_param.move_ship_date_to := FND_DATE.STRING_TO_DATE( gv_move_ship_date_to
                                                                               ,'YYYY/MM/DD');
        IF (gr_param.move_ship_date_to IS NULL) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                 ,gv_input_format_err   -- ���̓p�����[�^�����̓G���[
                                 ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                                 ,gv_tkn_move_ship_date_to        -- '�ړ�/�o�ɓ�To'
                                 ,gv_cnst_tkn_date    -- �g�[�N��'DATE'
                                 ,TO_CHAR(gv_move_ship_date_to))  -- '�ړ�/�o�ɓ�To'
                                 ,1
                                 ,5000);
          -- �G���[���^�[�����������~
          RAISE global_api_expt;
        END IF;
      END IF;
      -- �ړ�/�o�ɓ�From�ƈړ�/�o�ɓ�To���t�]���Ă�����G���[
      IF (gr_param.move_ship_date_from > gr_param.move_ship_date_to) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                               ,gv_input_date_err    -- ���̓p�����[�^�����G���[
                               ,gv_cnst_tkn_para    -- �g�[�N��'PRAMETER'
                               ,gv_tkn_move_ship_date_to  -- '�ړ�/�o�ɓ�To'
                               ,gv_cnst_tkn_para2    -- �g�[�N��'PRAMETER2'
                               ,gv_tkn_move_ship_date_from)  -- '�ړ�/�o�ɓ�From'
                               ,1
                               ,5000);
        -- �G���[���^�[�����������~
        RAISE global_api_expt;
      END IF;
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
--
  /**********************************************************************************
   * Procedure Name   : get_profile
   * Description      : D-2 �v���t�@�C���擾
   ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ���i�敪�i�Z�L�����e�B�j�擾
    gv_item_div_security := FND_PROFILE.VALUE(gv_prof_item_div_security);
    IF (gv_item_div_security IS NULL) THEN
      lv_errmsg  := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh,gv_profile_err
                                                         ,'PROF_NAME',gv_tkn_item_div_security);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
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
  /***********************************************************************************************
   * Procedure Name   : ins_temp_data
   * Description      : ���ԃe�[�u���o�^
   ***********************************************************************************************/
  PROCEDURE ins_temp_data
    (
      ir_temp_tab_tab   IN     rec_temp_tab_data_tab -- ���ԃe�[�u���o�^�f�[�^�Q
     ,ov_errbuf         OUT    VARCHAR2             -- �G���[�E���b�Z�[�W
     ,ov_retcode        OUT    VARCHAR2             -- ���^�[���E�R�[�h
     ,ov_errmsg         OUT    VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'ins_temp_data' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- ���ԃe�[�u���o�^
    -- ====================================================
    <<ins_temp_loop>>
    FOR i IN ir_temp_tab_tab.FIRST .. ir_temp_tab_tab.LAST LOOP
      INSERT INTO xxwsh.xxwsh_confirm_block_tmp
        (
          data_class              -- �f�[�^�敪
         ,whse_code               -- �ۊǑq�ɃR�[�h
         ,header_id               -- �w�b�_ID
         ,notif_status            -- �ʒm�X�e�[�^�X
         ,prod_class              -- ���i�敪
         ,item_class              -- �i�ڋ敪
         ,delivery_no             -- �z��No
         ,request_no              -- �˗�No
         ,freight_charge_class    -- �^���敪
         ,d1_whse_code            -- D+1�q�Ƀt���O
         ,base_date               -- ���
         ,created_by              -- �쐬��
         ,creation_date           -- �쐬��
         ,last_updated_by         -- �ŏI�X�V��
         ,last_update_date        -- �ŏI�X�V��
         ,request_id              -- �v��ID
         ,program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id              -- �R���J�����g�E�v���O����ID
        )
      VALUES
        (
          SUBSTRB( ir_temp_tab_tab(i).data_class  , 1, 1  )   -- �f�[�^�敪
         ,SUBSTRB( ir_temp_tab_tab(i).whse_code  , 1, 4  )   -- �ۊǑq�ɃR�[�h
         ,ir_temp_tab_tab(i).header_id    -- �w�b�_ID
         ,SUBSTRB( ir_temp_tab_tab(i).notif_status  , 1, 3  )  -- �ʒm�X�e�[�^�X
         ,SUBSTRB( ir_temp_tab_tab(i).prod_class    , 1, 2  )  -- ���i�敪
         ,SUBSTRB( ir_temp_tab_tab(i).item_class    , 1, 2  ) -- �i�ڋ敪
         ,SUBSTRB( ir_temp_tab_tab(i).delivery_no   , 1, 12  ) -- �z��No
         ,SUBSTRB( ir_temp_tab_tab(i).request_no    , 1, 12  ) -- �˗�No
         ,SUBSTRB( ir_temp_tab_tab(i).freight_charge_class , 1, 1  ) -- �^���敪
         ,SUBSTRB( ir_temp_tab_tab(i).d1_whse_code   , 1, 1  ) -- D+1�q�Ƀt���O
         ,ir_temp_tab_tab(i).base_date                         -- ���
         ,gt_user_id                                           -- �쐬��
         ,gt_system_date                                       -- �쐬��
         ,gt_user_id                                           -- �ŏI�X�V��
         ,gt_system_date                                       -- �X�V��
         ,gt_conc_request_id                                   -- �v��ID
         ,gt_prog_appl_id                                      -- �A�v���P�[�V����ID
         ,gt_conc_program_id                                   -- �v���O����ID
        ) ;
    END LOOP ins_temp_loop;
--
    -- ====================================================
    -- �A�E�g�p�����[�^�Z�b�g
    -- ====================================================
    ov_errbuf  := lv_errbuf ;     --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode := lv_retcode ;    --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg  := lv_errmsg ;     --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  EXCEPTION
--##### �Œ��O������ START ######################################################################
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
--##### �Œ��O������ END   ######################################################################
  END ins_temp_data;
--
  /**********************************************************************************
   * Procedure Name   : get_confirm_block_header
   * Description      : D-3  �o�ׁE�x���E�ړ����w�b�_���o����
   ***********************************************************************************/
  PROCEDURE get_confirm_block_header(
    ov_errbuf               OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_confirm_block_header'; -- �v���O������
    cv_order_category_code   CONSTANT VARCHAR2(5)    := 'ORDER'; -- �󒍃J�e�S���u�󒍁v
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
    lr_temp_tab             rec_temp_tab_data ;   -- ���ԃe�[�u���o�^�p���R�[�h�ϐ�
    lr_temp_tab_tab       rec_temp_tab_data_tab ;   -- ���ԃe�[�u���o�^�p���R�[�h�ϐ�
--
    -- *** ���[�J���E�J�[�\�� ***
    ----------------------------------------------------------------------------------------------
    -- �����o����(A)���o�׈˗� ���Y����LT1�w��̏ꍇ
    ----------------------------------------------------------------------------------------------
    CURSOR cur_sel_order_a(lv_code_class2 VARCHAR2)
    IS
      SELECT
        CASE WHEN xoha.req_status = gc_req_status_s_cmpb THEN gc_data_class_order
             WHEN xoha.req_status = gc_req_status_p_ccl THEN gc_data_class_order_cncl
        END                              AS data_class -- �f�[�^�敪�u�o�׈˗��F1�v�u�o�׎���F8�v
           , xil2v.segment1              AS whse_code       -- �ۊǑq�ɃR�[�h
           , xoha.order_header_id        AS order_header_id  -- �󒍃w�b�_�A�h�I��ID
           , xoha.notif_status           AS notif_status    -- �ʒm�X�e�[�^�X
           , xoha.prod_class             AS prod_class    -- ���i�敪
           , NULL                        AS item_class      -- �i�ڋ敪
           , xoha.delivery_no            AS delivery_no      -- �z��NO
           , xoha.request_no             AS request_no      -- �˗�NO
           , xoha.freight_charge_class   AS freight_charge_class      -- �^���敪
           , xil2v.d1_whse_code          AS d1_whse_code      -- D+1�q�Ƀt���O
           , gr_param.lt1_ship_date_from AS base_date      -- ���
      FROM xxwsh_order_headers_all            xoha,       -- �󒍃w�b�_�A�h�I��
           xxwsh_oe_transaction_types2_v      xott2v,       -- �󒍃^�C�v
           xxcmn_item_locations2_v            xil2v,    -- OPM�ۊǏꏊ���
           xxcmn_delivery_lt2_v               xdl2v       -- �z��L/T�A�h�I��
      WHERE
      -- �v���t�@�C���D���i�敪
           xoha.prod_class               = gv_item_div_security
      -- �p�����[�^�����D����
      AND  xoha.instruction_dept         = NVL( gr_param.dept_code, xoha.instruction_dept )
      ---------------------------------------------------------------------------------------------
      -- �n�o�l�ۊǏꏊ
      ---------------------------------------------------------------------------------------------
      AND  xoha.deliver_from          = xil2v.segment1
      -- �K�p��
      AND   gr_param.lt1_ship_date_from BETWEEN xil2v.date_from
                                  AND NVL( xil2v.date_to, gr_param.lt1_ship_date_from )
      -- �p�����[�^�����D�o�Ɍ�
      AND   ( xil2v.segment1          = gr_param.shipped_locat_code
      -- �p�����[�^�����D�u���b�N�P�E�Q�E�R
      OR      xil2v.distribution_block = gr_param.block_01
      OR      xil2v.distribution_block = gr_param.block_02
      OR      xil2v.distribution_block = gr_param.block_03
      OR    (   gr_param.shipped_locat_code IS NULL
            AND gr_param.block_01           IS NULL
            AND gr_param.block_02           IS NULL
            AND gr_param.block_03           IS NULL))
      ---------------------------------------------------------------------------------------------
      -- �󒍃^�C�v
      ---------------------------------------------------------------------------------------------
      AND   xott2v.order_category_code  = gv_order_cat_o
      AND   xott2v.shipping_shikyu_class = gv_sp_class_ship     -- �o�׈˗�
      AND   xott2v.transaction_type_id  = gv_transaction_type_id_ship     -- �o�׈˗�
      AND   xoha.order_type_id          = xott2v.transaction_type_id
      ---------------------------------------------------------------------------------------------
      -- �󒍃w�b�_�A�h�I��
      ---------------------------------------------------------------------------------------------
      AND ((  xoha.req_status             = gc_req_status_s_cmpb    -- �o�ׁF���ς�
          AND (     xoha.notif_status           = gc_notif_status_unnotif    -- ���ʒm
              OR    xoha.notif_status           = gc_notif_status_renotif ))   -- �Ēʒm�v
      OR  (  xoha.req_status             = gc_req_status_p_ccl      -- �o�ׁF���
          AND   xoha.notif_status           = gc_notif_status_renotif )   -- �Ēʒm�v
          )
      -- �p�����[�^�����D���Y����LT1/�o�׈˗�/�o�ɓ�FromTo
      AND   xoha.schedule_ship_date BETWEEN gr_param.lt1_ship_date_from
                                    AND  NVL( gr_param.lt1_ship_date_to, xoha.schedule_ship_date )
      ---------------------------------------------------------------------------------------------
      -- �z��L/T�A�h�I��
      ---------------------------------------------------------------------------------------------
      AND   xoha.deliver_from       =  xdl2v.entering_despatching_code1
      AND   xoha.deliver_to         =  xdl2v.entering_despatching_code2
      -- Add start 2008/06/24 uehara
      AND   xoha.shipping_method_code = xdl2v.ship_method
      -- Add end 2008/06/24 uehara
      AND   xdl2v.code_class1          =  gv_whse_code
      AND   xdl2v.code_class2          =  lv_code_class2 -- �R�[�h�敪(1:���_ 9:�z����)
      -- �p�����[�^�����D���Y����LT1
      AND   CASE gv_item_div_security
              WHEN gv_prod_class_leaf  THEN xdl2v.leaf_lead_time_day
              WHEN gv_prod_class_drink THEN xdl2v.drink_lead_time_day
            END = gr_param.lead_time_day_01
      -- �K�p��
      AND   gr_param.lt1_ship_date_from BETWEEN xdl2v.lt_start_date_active
                                  AND NVL( xdl2v.lt_end_date_active, gr_param.lt1_ship_date_from )
      FOR UPDATE OF xoha.order_header_id NOWAIT
     ;
    ----------------------------------------------------------------------------------------------
    -- �����o����(B)���o�׈˗� ���Y����LT2�w��̏ꍇ
    ----------------------------------------------------------------------------------------------
    CURSOR cur_sel_order_b(lv_code_class2 VARCHAR2)
    IS
      SELECT
        CASE WHEN xoha.req_status = gc_req_status_s_cmpb THEN gc_data_class_order
             WHEN xoha.req_status = gc_req_status_p_ccl THEN gc_data_class_order_cncl
        END                              AS data_class -- �f�[�^�敪�u�o�׈˗��F1�v�u�o�׎���F8�v
           , xil2v.segment1              AS whse_code       -- �ۊǑq�ɃR�[�h
           , xoha.order_header_id        AS order_header_id  -- �󒍃w�b�_�A�h�I��ID
           , xoha.notif_status           AS notif_status    -- �ʒm�X�e�[�^�X
           , xoha.prod_class             AS prod_class    -- ���i�敪
           , NULL                        AS item_class      -- �i�ڋ敪
           , xoha.delivery_no            AS delivery_no      -- �z��NO
           , xoha.request_no             AS request_no      -- �˗�NO
           , xoha.freight_charge_class   AS freight_charge_class      -- �^���敪
           , xil2v.d1_whse_code           AS d1_whse_code      -- D+1�q�Ƀt���O
           , gr_param.lt2_ship_date_from AS base_date      -- ���
      FROM xxwsh_order_headers_all            xoha,       -- �󒍃w�b�_�A�h�I��
           xxwsh_oe_transaction_types2_v      xott2v,       -- �󒍃^�C�v
           xxcmn_item_locations2_v            xil2v,    -- OPM�ۊǏꏊ���
           xxcmn_delivery_lt2_v               xdl2v       -- �z��L/T�A�h�I��
      WHERE
      -- �v���t�@�C���D���i�敪
           xoha.prod_class               = gv_item_div_security
      -- �p�����[�^�����D����
      AND  xoha.instruction_dept         = NVL( gr_param.dept_code, xoha.instruction_dept )
      ---------------------------------------------------------------------------------------------
      -- �n�o�l�ۊǏꏊ
      ---------------------------------------------------------------------------------------------
      AND  xoha.deliver_from          = xil2v.segment1
      -- �K�p��
      AND   gr_param.lt2_ship_date_from BETWEEN xil2v.date_from
                                  AND NVL( xil2v.date_to, gr_param.lt2_ship_date_from )
      -- �p�����[�^�����D�o�Ɍ�
      AND   ( xil2v.segment1          = gr_param.shipped_locat_code
      -- �p�����[�^�����D�u���b�N�P�E�Q�E�R
      OR      xil2v.distribution_block = gr_param.block_01
      OR      xil2v.distribution_block = gr_param.block_02
      OR      xil2v.distribution_block = gr_param.block_03
      OR    (   gr_param.shipped_locat_code IS NULL
            AND gr_param.block_01           IS NULL
            AND gr_param.block_02           IS NULL
            AND gr_param.block_03           IS NULL))
      ---------------------------------------------------------------------------------------------
      -- �󒍃^�C�v
      ---------------------------------------------------------------------------------------------
      AND   xott2v.order_category_code  = gv_order_cat_o
      AND   xott2v.shipping_shikyu_class = gv_sp_class_ship     -- �o�׈˗�
      AND   xott2v.transaction_type_id  = gv_transaction_type_id_ship     -- �o�׈˗�
      AND   xoha.order_type_id          = xott2v.transaction_type_id
      ---------------------------------------------------------------------------------------------
      -- �󒍃w�b�_�A�h�I��
      ---------------------------------------------------------------------------------------------
      AND ((  xoha.req_status             = gc_req_status_s_cmpb    -- �o�ׁF���ς�
          AND (     xoha.notif_status           = gc_notif_status_unnotif    -- ���ʒm
              OR    xoha.notif_status           = gc_notif_status_renotif ))   -- �Ēʒm�v
      OR  (  xoha.req_status             = gc_req_status_p_ccl      -- �o�ׁF���
          AND   xoha.notif_status           = gc_notif_status_renotif )   -- �Ēʒm�v
          )
      -- �p�����[�^�����D���Y����LT2/�o�׈˗�/�o�ɓ�FromTo
      AND   xoha.schedule_ship_date BETWEEN gr_param.lt2_ship_date_from
                                    AND  NVL( gr_param.lt2_ship_date_to, xoha.schedule_ship_date )
      ---------------------------------------------------------------------------------------------
      -- �z��L/T�A�h�I��
      ---------------------------------------------------------------------------------------------
      AND   xoha.deliver_from       =  xdl2v.entering_despatching_code1
      AND   xoha.deliver_to         =  xdl2v.entering_despatching_code2
      -- Add start 2008/06/24 uehara
      AND   xoha.shipping_method_code = xdl2v.ship_method
      -- Add end 2008/06/24 uehara
      AND   xdl2v.code_class1          =  gv_whse_code
      AND   xdl2v.code_class2          =  lv_code_class2 -- �R�[�h�敪(1:���_ 9:�z����)
      -- �p�����[�^�����D���Y����LT2
      AND   CASE gv_item_div_security
              WHEN gv_prod_class_leaf  THEN xdl2v.leaf_lead_time_day
              WHEN gv_prod_class_drink THEN xdl2v.drink_lead_time_day
            END = gr_param.lead_time_day_02
      -- �K�p��
      AND   gr_param.lt2_ship_date_from BETWEEN xdl2v.lt_start_date_active
                                  AND NVL( xdl2v.lt_end_date_active, gr_param.lt2_ship_date_from )
      FOR UPDATE OF xoha.order_header_id NOWAIT
     ;
    ----------------------------------------------------------------------------------------------
    -- �����o����(C)���o�Ɍ`�Ԃ��o�׈˗��ȊO�̏ꍇ
    ----------------------------------------------------------------------------------------------
    CURSOR cur_sel_order_c
    IS
      SELECT
        CASE WHEN xoha.req_status = gc_req_status_s_cmpb THEN gc_data_class_order
             WHEN xoha.req_status = gc_req_status_p_ccl THEN gc_data_class_order_cncl
        END                             AS data_class   -- �f�[�^�敪�u�o�׈˗��F1�v�u�o�׎���F8�v
           , xil2v.segment1             AS whse_code       -- �ۊǑq�ɃR�[�h
           , xoha.order_header_id       AS order_header_id  -- �󒍃w�b�_�A�h�I��ID
           , xoha.notif_status          AS notif_status    -- �ʒm�X�e�[�^�X
           , xoha.prod_class            AS prod_class    -- ���i�敪
           , NULL                       AS item_class      -- �i�ڋ敪
           , xoha.delivery_no           AS delivery_no      -- �z��NO
           , xoha.request_no            AS request_no      -- �˗�NO
           , xoha.freight_charge_class  AS freight_charge_class      -- �^���敪
           , xil2v.d1_whse_code         AS d1_whse_code      -- D+1�q�Ƀt���O
           , gr_param.ship_date_from    AS base_date      -- ���
      FROM xxwsh_order_headers_all            xoha,       -- �󒍃w�b�_�A�h�I��
           xxwsh_oe_transaction_types2_v      xott2v,       -- �󒍃^�C�v
           xxcmn_item_locations2_v             xil2v    -- OPM�ۊǏꏊ���
      WHERE
      -- �v���t�@�C���D���i�敪
           xoha.prod_class               = gv_item_div_security
      -- �p�����[�^�����D����
      AND  xoha.instruction_dept         = NVL( gr_param.dept_code, xoha.instruction_dept )
      ---------------------------------------------------------------------------------------------
      -- �n�o�l�ۊǏꏊ
      ---------------------------------------------------------------------------------------------
      AND  xoha.deliver_from          = xil2v.segment1
      -- �K�p��
      AND   gr_param.ship_date_from BETWEEN xil2v.date_from
                                  AND NVL( xil2v.date_to, gr_param.ship_date_from )
      -- �p�����[�^�����D�o�Ɍ�
      AND   ( xil2v.segment1          = gr_param.shipped_locat_code
      -- �p�����[�^�����D�u���b�N�P�E�Q�E�R
      OR      xil2v.distribution_block = gr_param.block_01
      OR      xil2v.distribution_block = gr_param.block_02
      OR      xil2v.distribution_block = gr_param.block_03
      OR    (   gr_param.shipped_locat_code IS NULL
            AND gr_param.block_01           IS NULL
            AND gr_param.block_02           IS NULL
            AND gr_param.block_03           IS NULL))
      ---------------------------------------------------------------------------------------------
      -- �󒍃^�C�v
      ---------------------------------------------------------------------------------------------
      AND   xott2v.order_category_code  = gv_order_cat_o
      AND   xott2v.shipping_shikyu_class = gv_sp_class_ship     -- �o�׈˗�
      AND   xott2v.transaction_type_id  = gr_param.transaction_type_id -- �p�����[�^�����D�o�Ɍ`��
      AND   xoha.order_type_id          = xott2v.transaction_type_id
      ---------------------------------------------------------------------------------------------
      -- �󒍃w�b�_�A�h�I��
      ---------------------------------------------------------------------------------------------
      AND ((  xoha.req_status             = gc_req_status_s_cmpb    -- �o�ׁF���ς�
          AND (     xoha.notif_status           = gc_notif_status_unnotif    -- ���ʒm
              OR    xoha.notif_status           = gc_notif_status_renotif ))   -- �Ēʒm�v
      OR  (  xoha.req_status             = gc_req_status_p_ccl      -- �o�ׁF���
          AND   xoha.notif_status           = gc_notif_status_renotif )   -- �Ēʒm�v
          )
      -- �p�����[�^�����D�o�ɓ�FromTo
      AND   xoha.schedule_ship_date BETWEEN gr_param.ship_date_from
                                    AND     NVL( gr_param.ship_date_to, xoha.schedule_ship_date )
      FOR UPDATE OF xoha.order_header_id NOWAIT
     ;
    ----------------------------------------------------------------------------------------------
    -- �����o����(D)���x���w���̏ꍇ
    ----------------------------------------------------------------------------------------------
    CURSOR cur_sel_prov_d
    IS
      SELECT
        CASE WHEN xoha.req_status = gc_req_status_p_cmpb THEN gc_data_class_prov
             WHEN xoha.req_status = gc_req_status_p_ccl THEN gc_data_class_prov_cncl
        END                               AS data_class -- �f�[�^�敪�u�x���w���F2�v�u�x������F9�v
           , xil2v.segment1               AS whse_code       -- �ۊǑq�ɃR�[�h
           , xoha.order_header_id         AS order_header_id  -- �󒍃w�b�_�A�h�I��ID
           , xoha.notif_status            AS notif_status    -- �ʒm�X�e�[�^�X
           , xoha.prod_class              AS prod_class    -- ���i�敪
           , NULL                         AS item_class      -- �i�ڋ敪
           , xoha.delivery_no             AS delivery_no      -- �z��NO
           , xoha.request_no              AS request_no      -- �˗�NO
           , xoha.freight_charge_class    AS freight_charge_class      -- �^���敪
           , xil2v.d1_whse_code           AS d1_whse_code      -- D+1�q�Ƀt���O
           , gr_param.prov_ship_date_from AS base_date      -- ���
      FROM xxwsh_order_headers_all            xoha,       -- �󒍃w�b�_�A�h�I��
           xxwsh_oe_transaction_types2_v      xott2v,       -- �󒍃^�C�v
           xxcmn_item_locations2_v             xil2v    -- OPM�ۊǏꏊ���
      WHERE
      -- �v���t�@�C���D���i�敪
           xoha.prod_class               = gv_item_div_security
      -- �p�����[�^�����D����
      AND  xoha.instruction_dept         = NVL( gr_param.dept_code, xoha.instruction_dept )
      ---------------------------------------------------------------------------------------------
      -- �n�o�l�ۊǏꏊ
      ---------------------------------------------------------------------------------------------
      AND  xoha.deliver_from          = xil2v.segment1
      -- �K�p��
      AND   gr_param.prov_ship_date_from BETWEEN xil2v.date_from
                                  AND NVL( xil2v.date_to, gr_param.prov_ship_date_from )
      -- �p�����[�^�����D�o�Ɍ�
      AND   ( xil2v.segment1          = gr_param.shipped_locat_code
      -- �p�����[�^�����D�u���b�N�P�E�Q�E�R
      OR      xil2v.distribution_block = gr_param.block_01
      OR      xil2v.distribution_block = gr_param.block_02
      OR      xil2v.distribution_block = gr_param.block_03
      OR    (   gr_param.shipped_locat_code IS NULL
            AND gr_param.block_01           IS NULL
            AND gr_param.block_02           IS NULL
            AND gr_param.block_03           IS NULL))
      ---------------------------------------------------------------------------------------------
      -- �󒍃^�C�v
      ---------------------------------------------------------------------------------------------
      AND   xott2v.order_category_code  = gv_order_cat_o
      AND   xott2v.shipping_shikyu_class = gv_sp_class_prov     -- �x���w��
      AND   xoha.order_type_id          = xott2v.transaction_type_id
      ---------------------------------------------------------------------------------------------
      -- �󒍃w�b�_�A�h�I��
      ---------------------------------------------------------------------------------------------
      AND ((  xoha.req_status             = gc_req_status_p_cmpb    -- �x���F��̍�
          AND (     xoha.notif_status           = gc_notif_status_unnotif    -- ���ʒm
              OR    xoha.notif_status           = gc_notif_status_renotif ))   -- �Ēʒm�v
      OR  (  xoha.req_status             = gc_req_status_p_ccl      -- �x���F���
          AND   xoha.notif_status           = gc_notif_status_renotif )   -- �Ēʒm�v
          )
      -- �p�����[�^�����D�x��/�o�ɓ�FromTo
      AND   xoha.schedule_ship_date BETWEEN gr_param.prov_ship_date_from
                                    AND NVL( gr_param.prov_ship_date_to, xoha.schedule_ship_date )
      FOR UPDATE OF xoha.order_header_id NOWAIT
     ;
    ----------------------------------------------------------------------------------------------
    -- �ړ����̏ꍇ
    ----------------------------------------------------------------------------------------------
    CURSOR cur_sel_move
    IS
      SELECT gc_data_class_move           AS data_class       -- �f�[�^�敪�F3
           , xil2v.segment1               AS whse_code       -- �ۊǑq�ɃR�[�h
           , xmrih.mov_hdr_id             AS order_header_id  -- �󒍃w�b�_�A�h�I��ID
           , xmrih.notif_status           AS notif_status    -- �ʒm�X�e�[�^�X
           , xmrih.item_class             AS prod_class    -- ���i�敪
           , xmrih.product_flg            AS item_class      -- �i�ڋ敪(���i���ʋ敪)
           , xmrih.delivery_no            AS delivery_no      -- �z��NO
           , xmrih.mov_num                AS request_no      -- �˗�NO
           , xmrih.freight_charge_class   AS freight_charge_class      -- �^���敪
           , xil2v.d1_whse_code           AS d1_whse_code      -- D+1�q�Ƀt���O
           , gr_param.move_ship_date_from AS base_date      -- ���
      FROM xxinv_mov_req_instr_headers    xmrih   -- �ړ��˗�/�w���w�b�_�A�h�I��
          ,xxcmn_item_locations2_v        xil2v     -- �n�o�l�ۊǏꏊ�}�X�^
      WHERE
      -- �v���t�@�C���D���i�敪
           xmrih.item_class               = gv_item_div_security
      -- �p�����[�^�����D�w������
      AND   xmrih.instruction_post_code = NVL( gr_param.dept_code, xmrih.instruction_post_code )
      ---------------------------------------------------------------------------------------------
      -- �n�o�l�ۊǏꏊ
      ---------------------------------------------------------------------------------------------
      AND  xmrih.shipped_locat_code          = xil2v.segment1
      -- �K�p��
      AND   gr_param.move_ship_date_from BETWEEN xil2v.date_from
                                  AND NVL( xil2v.date_to, gr_param.move_ship_date_from )
      -- �p�����[�^�����D�o�Ɍ�
      AND   ( xil2v.segment1          = gr_param.shipped_locat_code
      -- �p�����[�^�����D�u���b�N�P�E�Q�E�R
      OR      xil2v.distribution_block = gr_param.block_01
      OR      xil2v.distribution_block = gr_param.block_02
      OR      xil2v.distribution_block = gr_param.block_03
      OR    (   gr_param.shipped_locat_code IS NULL
            AND gr_param.block_01           IS NULL
            AND gr_param.block_02           IS NULL
            AND gr_param.block_03           IS NULL))
      ---------------------------------------------------------------------------------------------
      -- �ړ��˗�/�w���w�b�_�A�h�I��
      ---------------------------------------------------------------------------------------------
      AND (( xmrih.status              IN( gv_mov_status_cmp       -- �˗���
                                         ,gv_mov_status_adj )     -- ������
      AND   xmrih.mov_type              = gc_mov_type_y           -- �ϑ�����
          AND (     xmrih.notif_status           = gc_notif_status_unnotif    -- ���ʒm
              OR    xmrih.notif_status           = gc_notif_status_renotif ))   -- �Ēʒm�v
      OR  (  xmrih.status             = gc_req_status_p_ccl      -- ���
          AND   xmrih.mov_type              = gc_mov_type_y           -- �ϑ�����
          AND   xmrih.notif_status           = gc_notif_status_renotif )   -- �Ēʒm�v
      )
      -- �p�����[�^�����D�ړ�/�o�ɓ�FromTo
      AND   xmrih.schedule_ship_date BETWEEN gr_param.move_ship_date_from
                                    AND NVL( gr_param.move_ship_date_to, xmrih.schedule_ship_date )
      FOR UPDATE OF xmrih.mov_hdr_id NOWAIT
     ;
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
    -- ***************************************
    --------------------------------------------------
    -- ���̓p�����[�^[�������]���o�׈˗��܂��͏o�׈˗�/�ړ��w���̏ꍇ
    --------------------------------------------------
    IF (gr_param.shipping_biz_type IN ( gv_proc_fix_block_ship,gv_proc_fix_block_ship_move )) THEN
      --------------------------------------------------
      -- ���̓p�����[�^[�o�Ɍ`��]���o�׈˗��̏ꍇ
      --------------------------------------------------
      IF (gr_param.transaction_type_id = gv_transaction_type_id_ship) THEN
        --------------------------------------------------
        -- ���̓p�����[�^[���Y����LT1]���w�肠��̏ꍇ
        --------------------------------------------------
        IF (gr_param.lead_time_day_01 IS NOT NULL) THEN
          --------------------------------------------------
          --�����o����(A)��
          --------------------------------------------------
          -- �J�[�\���I�[�v��(�R�[�h�敪�F�z����)
          OPEN cur_sel_order_a(gv_deliver_to);
          -- �o���N�t�F�b�`
          FETCH cur_sel_order_a BULK COLLECT INTO lr_temp_tab_tab;
          -- �J�[�\���N���[�Y
          CLOSE cur_sel_order_a;
          -- �R�[�h�敪�F�z����Ŏ擾������0�̏ꍇ�A�R�[�h�敪�F���_�Ō���
          IF lr_temp_tab_tab.COUNT = 0 THEN
            -- �J�[�\���I�[�v��(�R�[�h�敪�F���_)
            OPEN cur_sel_order_a(gv_sales_code);
            -- �o���N�t�F�b�`
            FETCH cur_sel_order_a BULK COLLECT INTO lr_temp_tab_tab;
            -- �J�[�\���N���[�Y
            CLOSE cur_sel_order_a;
          END IF;
          -- �����Ώۃf�[�^����̏ꍇ
          IF lr_temp_tab_tab.COUNT > 0 THEN
            gv_data_found_flg := gc_onoff_div_on;   -- �����Ώۃf�[�^����
            --------------------------------------------------
            -- ���ԃe�[�u���o�^
            --------------------------------------------------
            ins_temp_data
              (
                ir_temp_tab_tab   => lr_temp_tab_tab
               ,ov_errbuf         => lv_errbuf
               ,ov_retcode        => lv_retcode
               ,ov_errmsg         => lv_errmsg
              ) ;
          END IF;
            IF ( lv_retcode = gv_status_error ) THEN
              -- MOD START 2008/06/23 UEHARA
--              RAISE global_process_expt ;
              RAISE global_api_others_expt ;
              -- MOD END 2008/06/23
            END IF ;
        END IF;
        --------------------------------------------------
        -- ���̓p�����[�^[���Y����LT2]���w�肠��̏ꍇ
        --------------------------------------------------
        IF (gr_param.lead_time_day_02 IS NOT NULL) THEN
          --------------------------------------------------
          --�����o����(B)��
          --------------------------------------------------
          -- �J�[�\���I�[�v��(�R�[�h�敪�F�z����)
          OPEN cur_sel_order_b(gv_deliver_to);
          -- �o���N�t�F�b�`
          FETCH cur_sel_order_b BULK COLLECT INTO lr_temp_tab_tab;
          -- �J�[�\���N���[�Y
          CLOSE cur_sel_order_b;
          -- �R�[�h�敪�F�z����Ŏ擾������0�̏ꍇ�A�R�[�h�敪�F���_�Ō���
          IF lr_temp_tab_tab.COUNT = 0 THEN
            -- �J�[�\���I�[�v��(�R�[�h�敪�F���_)
            OPEN cur_sel_order_b(gv_sales_code);
            -- �o���N�t�F�b�`
            FETCH cur_sel_order_b BULK COLLECT INTO lr_temp_tab_tab;
            -- �J�[�\���N���[�Y
            CLOSE cur_sel_order_b;
          END IF;
          -- �����Ώۃf�[�^����̏ꍇ
          IF lr_temp_tab_tab.COUNT > 0 THEN
            gv_data_found_flg := gc_onoff_div_on;   -- �����Ώۃf�[�^����
            --------------------------------------------------
            -- ���ԃe�[�u���o�^
            --------------------------------------------------
            ins_temp_data
              (
                ir_temp_tab_tab   => lr_temp_tab_tab
               ,ov_errbuf         => lv_errbuf
               ,ov_retcode        => lv_retcode
               ,ov_errmsg         => lv_errmsg
              ) ;
            IF ( lv_retcode = gv_status_error ) THEN
              -- MOD START 2008/06/23 UEHARA
--              RAISE global_process_expt ;
              RAISE global_api_others_expt ;
              -- MOD END 2008/06/23
            END IF ;
          END IF;
        END IF;
      --------------------------------------------------
      -- ���̓p�����[�^[�o�Ɍ`��]���o�׈˗��ȊO�̏ꍇ
      --------------------------------------------------
      ELSIF (gr_param.transaction_type_id <> gv_transaction_type_id_ship) THEN
        --------------------------------------------------
        --�����o����(C)��
        --------------------------------------------------
        -- �J�[�\���I�[�v��
        OPEN cur_sel_order_c;
        -- �o���N�t�F�b�`
        FETCH cur_sel_order_c BULK COLLECT INTO lr_temp_tab_tab;
        -- �J�[�\���N���[�Y
        CLOSE cur_sel_order_c;
          -- �����Ώۃf�[�^����̏ꍇ
          IF lr_temp_tab_tab.COUNT > 0 THEN
            gv_data_found_flg := gc_onoff_div_on;   -- �����Ώۃf�[�^����
          --------------------------------------------------
          -- ���ԃe�[�u���o�^
          --------------------------------------------------
          ins_temp_data
            (
              ir_temp_tab_tab   => lr_temp_tab_tab
             ,ov_errbuf         => lv_errbuf
             ,ov_retcode        => lv_retcode
             ,ov_errmsg         => lv_errmsg
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            -- MOD START 2008/06/23 UEHARA
--            RAISE global_process_expt ;
            RAISE global_api_others_expt ;
            -- MOD END 2008/06/23
          END IF ;
        END IF;
      END IF;
    --------------------------------------------------
    -- ���̓p�����[�^[�������]���x���w���܂��͎x���w��/�ړ��w���̏ꍇ
    --------------------------------------------------
    ELSIF (gr_param.shipping_biz_type IN (gv_proc_fix_block_prov,gv_proc_fix_block_prov_move)) THEN
      --------------------------------------------------
      --�����o����(D)��
      --------------------------------------------------
      -- �J�[�\���I�[�v��
      OPEN cur_sel_prov_d;
      -- �o���N�t�F�b�`
      FETCH cur_sel_prov_d BULK COLLECT INTO lr_temp_tab_tab;
      -- �J�[�\���N���[�Y
      CLOSE cur_sel_prov_d;
      -- �����Ώۃf�[�^����̏ꍇ
      IF lr_temp_tab_tab.COUNT > 0 THEN
        gv_data_found_flg := gc_onoff_div_on;   -- �����Ώۃf�[�^����
        --------------------------------------------------
        -- ���ԃe�[�u���o�^
        --------------------------------------------------
        ins_temp_data
          (
            ir_temp_tab_tab   => lr_temp_tab_tab
           ,ov_errbuf         => lv_errbuf
           ,ov_retcode        => lv_retcode
           ,ov_errmsg         => lv_errmsg
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          -- MOD START 2008/06/23 UEHARA
--          RAISE global_process_expt ;
          RAISE global_api_others_expt ;
          -- MOD END 2008/06/23
        END IF;
      END IF;
    END IF;
    --------------------------------------------------
    -- ���̓p�����[�^[�������]���ړ��w���܂��͏o�׈˗�/�ړ��w���܂��͎x���w��/�ړ��w���̏ꍇ
    --------------------------------------------------
    IF (gr_param.shipping_biz_type IN ( gv_proc_fix_block_move,gv_proc_fix_block_ship_move
                                                              ,gv_proc_fix_block_prov_move )) THEN
      --------------------------------------------------
      --�ړ���� �w�b�_���o����
      --------------------------------------------------
      -- �J�[�\���I�[�v��
      OPEN cur_sel_move;
      -- �o���N�t�F�b�`
      FETCH cur_sel_move BULK COLLECT INTO lr_temp_tab_tab;
      -- �J�[�\���N���[�Y
      CLOSE cur_sel_move;
      -- �����Ώۃf�[�^����̏ꍇ
      IF lr_temp_tab_tab.COUNT > 0 THEN
        gv_data_found_flg := gc_onoff_div_on;   -- �����Ώۃf�[�^����
        --------------------------------------------------
        -- ���ԃe�[�u���o�^
        --------------------------------------------------
        ins_temp_data
          (
            ir_temp_tab_tab   => lr_temp_tab_tab
           ,ov_errbuf         => lv_errbuf
           ,ov_retcode        => lv_retcode
           ,ov_errmsg         => lv_errmsg
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          -- MOD START 2008/06/23 UEHARA
--          RAISE global_process_expt ;
          RAISE global_api_others_expt ;
          -- MOD END 2008/06/23
        END IF;
      END IF;
    END IF;
    -- �����Ώۃf�[�^�Ȃ��̏ꍇ
    IF (gv_data_found_flg = gc_onoff_div_off) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                             ,gv_no_data_found_err)   -- �����Ώۃf�[�^�Ȃ��G���[
                             ,1
                             ,5000);
      -- �G���[���^�[�����������~
      RAISE global_no_data_found_expt;
    END IF;
--
  EXCEPTION
    -- *** �����Ώۃf�[�^�Ȃ���O�n���h�� ***
    WHEN global_no_data_found_expt THEN
      IF ( cur_sel_order_a%ISOPEN ) THEN
        CLOSE cur_sel_order_a ;
      END IF ;
      IF ( cur_sel_order_b%ISOPEN ) THEN
        CLOSE cur_sel_order_b ;
      END IF ;
      IF ( cur_sel_order_c%ISOPEN ) THEN
        CLOSE cur_sel_order_c ;
      END IF ;
      IF ( cur_sel_prov_d%ISOPEN ) THEN
        CLOSE cur_sel_prov_d ;
      END IF ;
      IF ( cur_sel_move%ISOPEN ) THEN
        CLOSE cur_sel_move ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
-- ##### 20080616 1.1 ������Q #9�Ή� START #####
--      ov_retcode := gv_status_error;
      ov_retcode := gv_status_warn;
-- ##### 20080616 1.1 ������Q #9�Ή� END   #####
--
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_lock_error_expt THEN
      IF ( cur_sel_order_a%ISOPEN ) THEN
        CLOSE cur_sel_order_a ;
      END IF ;
      IF ( cur_sel_order_b%ISOPEN ) THEN
        CLOSE cur_sel_order_b ;
      END IF ;
      IF ( cur_sel_order_c%ISOPEN ) THEN
        CLOSE cur_sel_order_c ;
      END IF ;
      IF ( cur_sel_prov_d%ISOPEN ) THEN
        CLOSE cur_sel_prov_d ;
      END IF ;
      IF ( cur_sel_move%ISOPEN ) THEN
        CLOSE cur_sel_move ;
      END IF ;
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                             ,gv_lock_err)   -- ���b�N�G���[
                             ,1
                             ,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( cur_sel_order_a%ISOPEN ) THEN
        CLOSE cur_sel_order_a ;
      END IF ;
      IF ( cur_sel_order_b%ISOPEN ) THEN
        CLOSE cur_sel_order_b ;
      END IF ;
      IF ( cur_sel_order_c%ISOPEN ) THEN
        CLOSE cur_sel_order_c ;
      END IF ;
      IF ( cur_sel_prov_d%ISOPEN ) THEN
        CLOSE cur_sel_prov_d ;
      END IF ;
      IF ( cur_sel_move%ISOPEN ) THEN
        CLOSE cur_sel_move ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( cur_sel_order_a%ISOPEN ) THEN
        CLOSE cur_sel_order_a ;
      END IF ;
      IF ( cur_sel_order_b%ISOPEN ) THEN
        CLOSE cur_sel_order_b ;
      END IF ;
      IF ( cur_sel_order_c%ISOPEN ) THEN
        CLOSE cur_sel_order_c ;
      END IF ;
      IF ( cur_sel_prov_d%ISOPEN ) THEN
        CLOSE cur_sel_prov_d ;
      END IF ;
      IF ( cur_sel_move%ISOPEN ) THEN
        CLOSE cur_sel_move ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
--      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( cur_sel_order_a%ISOPEN ) THEN
        CLOSE cur_sel_order_a ;
      END IF ;
      IF ( cur_sel_order_b%ISOPEN ) THEN
        CLOSE cur_sel_order_b ;
      END IF ;
      IF ( cur_sel_order_c%ISOPEN ) THEN
        CLOSE cur_sel_order_c ;
      END IF ;
      IF ( cur_sel_prov_d%ISOPEN ) THEN
        CLOSE cur_sel_prov_d ;
      END IF ;
      IF ( cur_sel_move%ISOPEN ) THEN
        CLOSE cur_sel_move ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_confirm_block_header;
--
  /**********************************************************************************
   * Procedure Name   : get_confirm_block_line
   * Description      : D-4  �o�ׁE�x���E�ړ���񖾍ג��o����
   ***********************************************************************************/
  PROCEDURE get_confirm_block_line(
    ln_cnt                  IN  NUMBER,
    ov_errbuf               OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_confirm_block_line'; -- �v���O������
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
    lr_temp_tab             rec_temp_tab_data ;   -- ���ԃe�[�u���o�^�p���R�[�h�ϐ�
    lr_temp_tab_tab       rec_temp_tab_data_tab ;   -- ���ԃe�[�u���o�^�p���R�[�h�ϐ�
--
    -- *** ���[�J���E�J�[�\�� ***
    --------------------------------------------------
    -- �o�ׁE�x����� ���ג��o�J�[�\��
    --------------------------------------------------
    CURSOR cur_sel_order_line(ln_cnt NUMBER)
    IS
      SELECT
             xola.order_header_id       AS order_header_id      -- �󒍃w�b�_ID
           , xola.order_line_id         AS order_line_id        -- �󒍖���ID
--           , xola.quantity              AS quantity             -- ����
--           , xola.reserved_quantity     AS reserved_quantity    -- ������
           , NVL(xola.quantity,0)       AS quantity             -- ����
           , NVL(xola.reserved_quantity,0) AS reserved_quantity    -- ������
           , ximv.lot_ctl               AS lot_ctl    -- ���b�g�Ǘ��敪
           , xicv.item_class_code       AS item_class_code      -- �i�ڋ敪
      FROM xxwsh_order_lines_all      xola      -- �󒍖��׃A�h�I��
          ,xxcmn_item_mst2_v          ximv      -- �n�o�l�i�ڏ��VIEW2
          ,xxcmn_item_categories4_v   xicv      -- �n�o�l�i�ڃJ�e�S���������VIEW4
      WHERE
      ---------------------------------------------------------------------------------------------
      -- �n�o�l�i��
      ---------------------------------------------------------------------------------------------
      -- �p�����[�^�����D�i�ڋ敪
            ximv.item_id            = xicv.item_id
      AND   trunc(gr_chk_header_data_tab(ln_cnt).base_date) BETWEEN ximv.start_date_active
                AND NVL( ximv.end_date_active, trunc(gr_chk_header_data_tab(ln_cnt).base_date) )
      AND   xola.shipping_item_code = ximv.item_no
      ---------------------------------------------------------------------------------------------
      -- �󒍖��׃A�h�I��
      ---------------------------------------------------------------------------------------------
      AND   NVL(xola.delete_flag,gc_yn_div_n) <> gc_yn_div_y          -- ���폜
      AND   xola.order_header_id                 = gr_chk_header_data_tab(ln_cnt).header_id
      FOR UPDATE OF xola.order_line_id NOWAIT
     ;
    --------------------------------------------------
    -- �ړ���� ���ג��o�J�[�\��
    --------------------------------------------------
    CURSOR cur_sel_move_line(ln_cnt NUMBER)
    IS
      SELECT
             xmril.mov_hdr_id                          AS order_header_id      -- �ړ��w�b�_ID
           , xmril.mov_line_id                         AS order_line_id        -- �ړ�����ID
--           , xmril.instruct_qty                        AS quantity             -- �w������
--           , xmril.reserved_quantity                   AS reserved_quantity    -- ������
           , NVL(xmril.instruct_qty,0)                 AS quantity             -- �w������
           , NVL(xmril.reserved_quantity,0)            AS reserved_quantity    -- ������
           , ximv.lot_ctl                              AS lot_ctl              -- ���b�g�Ǘ��敪
           , gr_chk_header_data_tab(ln_cnt).item_class AS item_class_code      -- �i�ڋ敪
      FROM xxinv_mov_req_instr_lines    xmril     -- �ړ��˗�/�w�����׃A�h�I��
          ,xxcmn_item_mst2_v            ximv      -- �n�o�l�i�ڏ��VIEW2
      WHERE
      ---------------------------------------------------------------------------------------------
      -- �n�o�l�i��
      ---------------------------------------------------------------------------------------------
      -- �p�����[�^�����D�i�ڋ敪
            xmril.item_id            = ximv.item_id
      AND   trunc(gr_chk_header_data_tab(ln_cnt).base_date) BETWEEN ximv.start_date_active
                    AND NVL( ximv.end_date_active, trunc(gr_chk_header_data_tab(ln_cnt).base_date))
      ---------------------------------------------------------------------------------------------
      -- �ړ��˗�/�w�����׃A�h�I��
      ---------------------------------------------------------------------------------------------
      AND   NVL(xmril.delete_flg,gc_yn_div_n) <> gc_yn_div_y          -- ���폜
      AND   xmril.mov_hdr_id                 = gr_chk_header_data_tab(ln_cnt).header_id
      FOR UPDATE OF xmril.mov_line_id NOWAIT
     ;
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
    -- ***************************************
    --------------------------------------------------
    -- �f�[�^�敪���o�׈˗��E�x���w���̏ꍇ
    --------------------------------------------------
    IF (gr_chk_header_data_tab(ln_cnt).data_class IN
                               ( gc_data_class_order,gc_data_class_prov )) THEN
      -- �J�[�\���I�[�v��
      OPEN cur_sel_order_line(ln_cnt);
      -- �o���N�t�F�b�`
      FETCH cur_sel_order_line BULK COLLECT INTO gr_chk_line_data_tab;
      -- �J�[�\���N���[�Y
      CLOSE cur_sel_order_line;
    --------------------------------------------------
    -- �f�[�^�敪���ړ��w���̏ꍇ
    --------------------------------------------------
    ELSIF (gr_chk_header_data_tab(ln_cnt).data_class = gc_data_class_move) THEN
      -- �J�[�\���I�[�v��
      OPEN cur_sel_move_line(ln_cnt);
      -- �o���N�t�F�b�`
      FETCH cur_sel_move_line BULK COLLECT INTO gr_chk_line_data_tab;
      -- �J�[�\���N���[�Y
      CLOSE cur_sel_move_line;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( cur_sel_order_line%ISOPEN ) THEN
        CLOSE cur_sel_order_line ;
      END IF ;
      IF ( cur_sel_move_line%ISOPEN ) THEN
        CLOSE cur_sel_move_line ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( cur_sel_order_line%ISOPEN ) THEN
        CLOSE cur_sel_order_line ;
      END IF ;
      IF ( cur_sel_move_line%ISOPEN ) THEN
        CLOSE cur_sel_move_line ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( cur_sel_order_line%ISOPEN ) THEN
        CLOSE cur_sel_order_line ;
      END IF ;
      IF ( cur_sel_move_line%ISOPEN ) THEN
        CLOSE cur_sel_move_line ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_confirm_block_line;
--
  /**********************************************************************************
   * Procedure Name   : chk_reserved
   * Description      : D-5  ���������σ`�F�b�N����
   ***********************************************************************************/
  PROCEDURE chk_reserved(
    ln_cnt                  IN  NUMBER,
    ov_errbuf               OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_reserved'; -- �v���O������
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
    -- ***************************************
    -- �f�[�^�敪��'1'�o�׈˗�
    IF (((gr_chk_header_data_tab(ln_cnt).data_class = gc_data_class_order)
      -- �i�ڋ敪��'5'���i
      AND (gr_chk_line_data_tab(gn_cnt_line).item_class_code = gv_cons_item_product)
      -- ���i�敪��'2'�h�����N
      AND ((gr_chk_header_data_tab(ln_cnt).prod_class = gv_prod_class_drink)
      -- �������́A���i�敪��'1'���[�t��D+1�q�Ƀt���O��'Y'
      OR  (gr_chk_header_data_tab(ln_cnt).prod_class = gv_prod_class_leaf)
        AND (gr_chk_header_data_tab(ln_cnt).d1_whse_code = gc_yn_div_y)))
    -- �f�[�^�敪��'2'�x���w��
    OR (gr_chk_header_data_tab(ln_cnt).data_class = gc_data_class_prov)
    -- �f�[�^�敪��'3'�ړ��w��
    OR ((gr_chk_header_data_tab(ln_cnt).data_class = gc_data_class_move)
      -- �i�ڋ敪(���i���ʋ敪)��'1'���i
      AND (gr_chk_line_data_tab(gn_cnt_line).item_class_code = gv_cons_product_class)
      -- ���i�敪��'2'�h�����N
      AND (gr_chk_header_data_tab(ln_cnt).prod_class = gv_prod_class_drink))
    ) THEN
      -- ���ʂƈ������ʂ��قȂ�ꍇ�̓G���[�t���O�����Z����B
      IF (gr_chk_line_data_tab(gn_cnt_line).quantity
          <> gr_chk_line_data_tab(gn_cnt_line).reserved_quantity) THEN
        gv_err_flg_resv := gc_onoff_div_on; -- �����G���[�t���O��ON�ɂ���B
        gv_err_flg_whse := gc_onoff_div_on; -- �q�ɃG���[�t���O��ON�ɂ���B
      END IF;
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
  END chk_reserved;
--
  /**********************************************************************************
   * Procedure Name   : chk_mixed_prod
   * Description      : D-6  �o�ז��� ���i���݃`�F�b�N����
   ***********************************************************************************/
  PROCEDURE chk_mixed_prod(
    ln_cnt                  IN  NUMBER,
    ov_errbuf               OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_mixed_prod'; -- �v���O������
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
    -- ***************************************
    IF (gr_chk_header_data_tab(ln_cnt).data_class = gc_data_class_order) THEN
      --------------------------------------------------
      -- �i�ڋ敪��'5'���i�̏ꍇ�͐��i���������Z
      --------------------------------------------------
      IF (gr_chk_line_data_tab(gn_cnt_line).item_class_code = gv_cons_item_product) THEN
        gn_cnt_prod    := gn_cnt_prod +1;
      --------------------------------------------------
      -- �i�ڋ敪��'5'���i�ȊO�̏ꍇ�͐��i�ȊO���������Z
      --------------------------------------------------
      ELSE
        gn_cnt_no_prod := gn_cnt_no_prod +1;
      END IF;
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
  END chk_mixed_prod;
--
  /**********************************************************************************
   * Procedure Name   : chk_carrier
   * Description      : D-7  �z�ԍσ`�F�b�N����
   ***********************************************************************************/
  PROCEDURE chk_carrier(
    ln_cnt                  IN  NUMBER,
    ov_errbuf               OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_carrier'; -- �v���O������
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
    -- ***************************************
    ---------------------------------------------------------
    -- �f�[�^�敪��'1'�o�׈˗�'2'�x���w��'3'�ړ��w���̏ꍇ
    ---------------------------------------------------------
    IF ((gr_chk_header_data_tab(ln_cnt).data_class IN (gc_data_class_order,gc_data_class_prov
                                                                          ,gc_data_class_move))
    ---------------------------------------------------------
    -- �^���敪=�Ώۂ̏ꍇ
    ---------------------------------------------------------
    AND (gr_chk_header_data_tab(ln_cnt).freight_charge_class = gv_freight_charge_class_on)
    ---------------------------------------------------------
    -- �z��NO��NULL�܂���'0'�̏ꍇ
    ---------------------------------------------------------
    AND (NVL(gr_chk_header_data_tab(ln_cnt).delivery_no,'0') = '0')) THEN
      -- �z�ԃG���[�t���O��ON�ɂ���B
      gv_err_flg_carr := gc_onoff_div_on;
      -- �q�ɃG���[�t���O��ON�ɂ���B
      gv_err_flg_whse := gc_onoff_div_on;
    END IF;
    ---------------------------------------------------------
    -- �f�[�^�敪��'1'�o�׈˗�'�̏ꍇ
    ---------------------------------------------------------
    IF ((gr_chk_header_data_tab(ln_cnt).data_class in (gc_data_class_order))
    ---------------------------------------------------------
    -- ���i����>0�����i�ȊO>0�̏ꍇ
    ---------------------------------------------------------
    AND (gn_cnt_prod > 0) AND (gn_cnt_no_prod > 0)) THEN
      -- �z�ԏo�׈˗����i���݃��[�j���O�t���O��ON�ɂ���B
      gv_war_flg_carr_mixed := gc_onoff_div_on;
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
  END chk_carrier;
--
  /**********************************************************************************
   * Procedure Name   : set_checked_data
   * Description      : D-8  �`�F�b�N�σf�[�^ PL/SQL�\�i�[����
   ***********************************************************************************/
  PROCEDURE set_checked_data(
    ln_cnt                  IN  NUMBER,
    ov_errbuf               OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_checked_data'; -- �v���O������
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
    -- ***************************************
    ---------------------------------------------------------
    -- �`�F�b�N�σf�[�^�i�[�p���R�[�h�ϐ��Ɋi�[
    ---------------------------------------------------------
    gr_checked_data_tab(ln_cnt).data_class   := gr_chk_header_data_tab(ln_cnt).data_class;
                                                                                  -- �f�[�^�敪
    gr_checked_data_tab(ln_cnt).delivery_no  := gr_chk_header_data_tab(ln_cnt).delivery_no;
                                                                                  -- �z��NO
    gr_checked_data_tab(ln_cnt).request_no   := gr_chk_header_data_tab(ln_cnt).request_no;
                                                                                  -- �˗�NO
    gr_checked_data_tab(ln_cnt).notif_status := gr_chk_header_data_tab(ln_cnt).notif_status;
                                                                                  -- �ʒm�X�e�[�^�X
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
  END set_checked_data;
--
  /**********************************************************************************
   * Procedure Name   : set_upd_data
   * Description      : D-10  �ʒm�X�e�[�^�X�X�V�pPL�^SQL�\ �i�[����
   ***********************************************************************************/
  PROCEDURE set_upd_data(
    ov_errbuf               OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_upd_data'; -- �v���O������
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
    ln_cnt   NUMBER;
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
    -- ***************************************
    ln_cnt := 1;
    <<set_upd_data_loop>>
    FOR ln_cnt IN gr_checked_data_tab.FIRST .. gr_checked_data_tab.LAST LOOP
      -- �X�V�p�f�[�^���������Z
      gn_cnt_upd := gn_cnt_upd + 1 ;
      ---------------------------------------------------------
      -- �X�V�f�[�^�i�[�p���R�[�h�Ɋi�[
      ---------------------------------------------------------
      gr_upd_data_tab(gn_cnt_upd).data_class   := gr_checked_data_tab(ln_cnt).data_class;
                                                                                  -- �f�[�^�敪
      gr_upd_data_tab(gn_cnt_upd).delivery_no  := gr_checked_data_tab(ln_cnt).delivery_no;
                                                                                  -- �z��NO
      gr_upd_data_tab(gn_cnt_upd).request_no   := gr_checked_data_tab(ln_cnt).request_no;
                                                                                  -- �˗�NO
      gr_upd_data_tab(gn_cnt_upd).notif_status := gr_checked_data_tab(ln_cnt).notif_status;
                                                                                  -- �ʒm�X�e�[�^�X
    END LOOP set_upd_data_loop;
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
  END set_upd_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_notif_status
   * Description      : D-12  �ʒm�X�e�[�^�X �ꊇ�X�V����
   ***********************************************************************************/
  PROCEDURE upd_notif_status(
    ov_errbuf               OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_notif_status'; -- �v���O������
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
    ln_cnt   NUMBER;
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
    -- ***************************************
    ln_cnt := 1;
    <<upd_notif_status_loop>>
    FOR ln_cnt IN gr_upd_data_tab.FIRST .. gr_upd_data_tab.LAST LOOP
      ---------------------------------------------------------
      -- �f�[�^�敪��'1'�o�׈˗�'2'�x���w��'8''9'����f�[�^�̏ꍇ
      ---------------------------------------------------------
      IF (gr_upd_data_tab(ln_cnt).data_class
        IN (gc_data_class_order,gc_data_class_prov,
            gc_data_class_order_cncl,gc_data_class_prov_cncl)) THEN
        ---------------------------------------------------------
        -- �󒍃w�b�_�A�h�I���X�V
        ---------------------------------------------------------
        UPDATE xxwsh_order_headers_all
        SET    notif_status            = gc_notif_status_notifed      -- �ʒm�X�e�[�^�X�F�m��ʒm��
              ,prev_notif_status       = gr_upd_data_tab(ln_cnt).notif_status -- �O��ʒm�X�e�[�^�X
              ,notif_date              = gt_system_date          -- �m��ʒm���{����
              ,last_updated_by         = gt_user_id     -- �ŏI�X�V��
              ,last_update_date        = gt_system_date    -- �ŏI�X�V��
              ,last_update_login       = gt_login_id   -- �ŏI�X�V���O�C��
              ,request_id              = gt_conc_request_id          -- �v��ID
              ,program_application_id  = gt_prog_appl_id
                                                    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              ,program_id              = gt_conc_program_id   -- �R���J�����g�E�v���O����ID
              ,program_update_date     = gt_system_date   -- �v���O�����X�V��
        WHERE  (delivery_no         = gr_upd_data_tab(ln_cnt).delivery_no   -- �z��NO
            OR NVL(gr_upd_data_tab(ln_cnt).delivery_no,0) = 0)
           AND request_no          = gr_upd_data_tab(ln_cnt).request_no     -- �˗�NO
        ;
        -- �X�V���������Z
        IF (gr_upd_data_tab(ln_cnt).data_class
              IN (gc_data_class_order,gc_data_class_order_cncl) ) THEN
          gn_cnt_upd_ship := gn_cnt_upd_ship + 1;  -- �o�׍X�V����
        ELSIF (gr_upd_data_tab(ln_cnt).data_class
              IN (gc_data_class_prov,gc_data_class_prov_cncl) ) THEN
          gn_cnt_upd_prov := gn_cnt_upd_prov + 1;  -- �x���X�V����
        END IF;
      ---------------------------------------------------------
      -- �f�[�^�敪��'3'�ړ��w���̏ꍇ
      ---------------------------------------------------------
      ELSIF (gr_upd_data_tab(ln_cnt).data_class IN (gc_data_class_move)) THEN
        ---------------------------------------------------------
        -- �ړ��˗�/�w���w�b�_�A�h�I���X�V
        ---------------------------------------------------------
        UPDATE xxinv_mov_req_instr_headers
        SET    notif_status            = gc_notif_status_notifed      -- �ʒm�X�e�[�^�X�F�m��ʒm��
              ,prev_notif_status       = gr_upd_data_tab(ln_cnt).notif_status -- �O��ʒm�X�e�[�^�X
              ,notif_date              = gt_system_date          -- �m��ʒm���{����
              ,last_updated_by         = gt_user_id     -- �ŏI�X�V��
              ,last_update_date        = gt_system_date    -- �ŏI�X�V��
              ,last_update_login       = gt_login_id   -- �ŏI�X�V���O�C��
              ,request_id              = gt_conc_request_id          -- �v��ID
              ,program_application_id  = gt_prog_appl_id
                                                    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              ,program_id              = gt_conc_program_id   -- �R���J�����g�E�v���O����ID
              ,program_update_date     = gt_system_date   -- �v���O�����X�V��
        WHERE  (delivery_no         = gr_upd_data_tab(ln_cnt).delivery_no   -- �z��NO
            OR NVL(gr_upd_data_tab(ln_cnt).delivery_no,0) = 0)
           AND mov_num             = gr_upd_data_tab(ln_cnt).request_no     -- �ړ��ԍ�
        ;
        -- �X�V���������Z
        gn_cnt_upd_move := gn_cnt_upd_move + 1;  -- �ړ��X�V����
      END IF;
    END LOOP upd_notif_status_loop;
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
  END upd_notif_status;
--
  /**********************************************************************************
   * Procedure Name   : purge_tbl
   * Description      : D-13  ���ԃe�[�u���p�[�W����
   ***********************************************************************************/
  PROCEDURE purge_tbl
    (
      ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'purge_tbl'; -- �v���O������
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
      -- �m��u���b�N�p���ԃe�[�u�� �Ώۃf�[�^�폜
      DELETE FROM   xxwsh.xxwsh_confirm_block_tmp -- �m��u���b�N�p���ԃe�[�u��
      WHERE created_by = gt_user_id                    -- �쐬�ҁA�ŏI�X�V��
        AND request_id = gt_conc_request_id            -- �v��ID
        AND program_application_id = gt_prog_appl_id   -- �A�v���P�[�V����ID
        AND program_id = gt_conc_program_id            -- �v���O����ID
      ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END purge_tbl;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_dept_code              IN VARCHAR2,          -- ����
    iv_shipping_biz_type      IN VARCHAR2,          -- �������
    iv_transaction_type_id    IN VARCHAR2,          -- �o�Ɍ`��
    iv_lead_time_day_01       IN VARCHAR2,          -- ���Y����LT1
    iv_lt1_ship_date_from     IN VARCHAR2,          -- ���Y����LT1/�o�׈˗�/�o�ɓ�From
    iv_lt1_ship_date_to       IN VARCHAR2,          -- ���Y����LT1/�o�׈˗�/�o�ɓ�To
    iv_lead_time_day_02       IN VARCHAR2,          -- ���Y����LT2
    iv_lt2_ship_date_from     IN VARCHAR2,          -- ���Y����LT2/�o�׈˗�/�o�ɓ�From
    iv_lt2_ship_date_to       IN VARCHAR2,          -- ���Y����LT2/�o�׈˗�/�o�ɓ�To
    iv_ship_date_from         IN VARCHAR2,          -- �o�ɓ�From
    iv_ship_date_to           IN VARCHAR2,          -- �o�ɓ�To
    iv_move_ship_date_from    IN VARCHAR2,          -- �ړ�/�o�ɓ�From
    iv_move_ship_date_to      IN VARCHAR2,          -- �ړ�/�o�ɓ�To
    iv_prov_ship_date_from    IN VARCHAR2,          -- �x��/�o�ɓ�From
    iv_prov_ship_date_to      IN VARCHAR2,          -- �x��/�o�ɓ�To
    iv_block_01               IN VARCHAR2,          -- �u���b�N�P
    iv_block_02               IN VARCHAR2,          -- �u���b�N�Q
    iv_block_03               IN VARCHAR2,          -- �u���b�N�R
    iv_shipped_locat_code     IN VARCHAR2,          -- �o�Ɍ�
    ov_errbuf                 OUT VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���ϐ� ***
    ln_cnt NUMBER;
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �w�b�_�擾�p�J�[�\��
    CURSOR cur_get_confirm_block_tmp
    IS
      SELECT *
      FROM  xxwsh.xxwsh_confirm_block_tmp -- �m��u���b�N�p���ԃe�[�u��
      WHERE created_by = gt_user_id                    -- �쐬�ҁA�ŏI�X�V��
        AND request_id = gt_conc_request_id            -- �v��ID
        AND program_application_id = gt_prog_appl_id   -- �A�v���P�[�V����ID
        AND program_id = gt_conc_program_id            -- �v���O����ID
      ORDER BY whse_code,header_id
      FOR UPDATE NOWAIT
      ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ��������
    -- =====================================================
    -- �O���[�o���ϐ��̏�����
    gv_lt1_ship_date_from        := 0;
    gv_lt1_ship_date_to          := 0;
    gv_lt2_ship_date_from        := 0;
    gv_lt2_ship_date_to          := 0;
    gv_ship_date_from            := 0;
    gv_ship_date_to              := 0;
    gv_move_ship_date_from       := 0;
    gv_move_ship_date_to         := 0;
    gv_prov_ship_date_from       := 0;
    gv_prov_ship_date_to         := 0;
    gn_cnt_upd         := 0;                    -- �X�V�p�f�[�^����
    gn_cnt_upd_ship    := 0;                    -- �o�׍X�V����
    gn_cnt_upd_prov    := 0;                    -- �x���X�V����
    gn_cnt_upd_move    := 0;                    -- �ړ��X�V����
    gr_chk_header_data_tab.DELETE;
    -- �G���[�t���O�̏�����
    gv_data_found_flg     := gc_onoff_div_off;   -- �����Ώۃf�[�^����t���O
    gv_err_flg_resv       := gc_onoff_div_off;   -- �����G���[�t���O
    gv_err_flg_carr       := gc_onoff_div_off;   -- �z�ԃG���[�t���O
    gv_war_flg_carr_mixed := gc_onoff_div_off;   -- �z�ԏo�׈˗����i���݃��[�j���O�t���O
    gv_err_flg_whse       := gc_onoff_div_off;   -- �q�ɃG���[�t���O
    -- -----------------------------------------------------
    -- �p�����[�^�i�[
    -- -----------------------------------------------------
    gr_param.dept_code           := iv_dept_code;           -- ����
    gr_param.shipping_biz_type   := iv_shipping_biz_type;   -- �������
    gr_param.transaction_type_id := iv_transaction_type_id; -- �o�Ɍ`��
    gr_param.lead_time_day_01    := TO_NUMBER(iv_lead_time_day_01);    -- ���Y����LT1
    gv_lt1_ship_date_from        := iv_lt1_ship_date_from;  -- ���Y����LT1/�o�׈˗�/�o�ɓ�From
    gv_lt1_ship_date_to          := iv_lt1_ship_date_to;    -- ���Y����LT1/�o�׈˗�/�o�ɓ�To
    gr_param.lead_time_day_02    := TO_NUMBER(iv_lead_time_day_02);    -- ���Y����LT2
    gv_lt2_ship_date_from        := iv_lt2_ship_date_from;  -- ���Y����LT2/�o�׈˗�/�o�ɓ�From
    gv_lt2_ship_date_to          := iv_lt2_ship_date_to;    -- ���Y����LT2/�o�׈˗�/�o�ɓ�To
    gv_ship_date_from            := iv_ship_date_from;      -- �o�ɓ�From
    gv_ship_date_to              := iv_ship_date_to;        -- �o�ɓ�To
    gv_move_ship_date_from       := iv_move_ship_date_from; -- �ړ�/�o�ɓ�From
    gv_move_ship_date_to         := iv_move_ship_date_to;   -- �ړ�/�o�ɓ�To
    gv_prov_ship_date_from       := iv_prov_ship_date_from; -- �x��/�o�ɓ�From
    gv_prov_ship_date_to         := iv_prov_ship_date_to;   -- �x��/�o�ɓ�To
    gr_param.block_01            := iv_block_01;            -- �u���b�N�P
    gr_param.block_02            := iv_block_02;            -- �u���b�N�Q
    gr_param.block_03            := iv_block_03;            -- �u���b�N�R
    gr_param.shipped_locat_code  := iv_shipped_locat_code;  -- �o�Ɍ�
--
    -- WHO�J�����擾
    gt_user_id          := FND_GLOBAL.USER_ID;          -- �쐬�ҁA�ŏI�X�V��
    gt_login_id         := FND_GLOBAL.LOGIN_ID;         -- �ŏI�X�V���O�C��
    gt_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;  -- �v��ID
    gt_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;     -- �A�v���P�[�V����ID
    gt_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;  -- �v���O����ID
--
    gt_system_date      := SYSDATE;                     -- �V�X�e�����t
--
    ln_cnt := 0;
    -- ===============================================
    -- D-1  ���̓p�����[�^�`�F�b�N
    -- ===============================================
    check_parameter(
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- �G���[����
    IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- D-2  �v���t�@�C���擾����
    -- ===============================================
    get_profile(
      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    -- ===============================================
    -- D-3  �o�ׁE�x���E�ړ����w�b�_���o����
    -- ===============================================
    get_confirm_block_header(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = gv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    <<header_loop>>
    FOR re_header IN cur_get_confirm_block_tmp LOOP
      --------------------------------------------------
      -- �ۊǑq�ɃR�[�h���u���C�N���i��O�Ŏ擾�̕ۊǑq�ɃR�[�h�ƈقȂ�ꍇ�j
      --------------------------------------------------
      IF (ln_cnt > 0 ) THEN
        IF (re_header.whse_code <> gr_chk_header_data_tab(ln_cnt).whse_code) THEN
          --------------------------------------------------
          -- ����q�ɓ��ɃG���[���Ȃ��ꍇ
          --------------------------------------------------
          IF (gv_err_flg_whse = gc_onoff_div_off) THEN
          -- ===============================================
          -- D-10  �ʒm�X�e�[�^�X�X�V�pPL�^SQL�\ �i�[����
          -- ===============================================
            set_upd_data(
              lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF (lv_retcode = gv_status_error) THEN
              --(�G���[����)
              RAISE global_process_expt;
            ELSIF (lv_retcode = gv_status_warn) THEN
              ov_retcode := lv_retcode;
            END IF;
          END IF;
          -- ===============================================
          -- D-11  �`�F�b�N�σf�[�^�i�[�pPL�^SQL�\ ����������
          -- ===============================================
          gr_checked_data_tab.DELETE;
          gv_err_flg_whse := gc_onoff_div_off; -- �q�ɃG���[�t���O
        END IF;
      END IF;
--
      ln_cnt := ln_cnt + 1;
      --------------------------------------------------
      -- ���o�f�[�^�i�[
      --------------------------------------------------
      gr_chk_header_data_tab(ln_cnt).data_class           := re_header.data_class          ;
      gr_chk_header_data_tab(ln_cnt).whse_code            := re_header.whse_code           ;
      gr_chk_header_data_tab(ln_cnt).header_id            := re_header.header_id           ;
      gr_chk_header_data_tab(ln_cnt).notif_status         := re_header.notif_status        ;
      gr_chk_header_data_tab(ln_cnt).prod_class           := re_header.prod_class          ;
      gr_chk_header_data_tab(ln_cnt).item_class           := re_header.item_class          ;
      gr_chk_header_data_tab(ln_cnt).delivery_no          := re_header.delivery_no         ;
      gr_chk_header_data_tab(ln_cnt).request_no           := re_header.request_no          ;
      gr_chk_header_data_tab(ln_cnt).freight_charge_class := re_header.freight_charge_class;
      gr_chk_header_data_tab(ln_cnt).d1_whse_code         := re_header.d1_whse_code        ;
      gr_chk_header_data_tab(ln_cnt).base_date            := re_header.base_date           ;
--
      -- ===============================================
      -- D-4  �o�ׁE�x���E�ړ���񖾍ג��o����
      -- ===============================================
      get_confirm_block_line(
        ln_cnt,             --
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = gv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      ELSIF (lv_retcode = gv_status_warn) THEN
        ov_retcode := lv_retcode;
-- ##### 20080616 1.1 ������Q #9�Ή� START #####
        RAISE ex_worn ;
-- ##### 20080616 1.1 ������Q #9�Ή� END   #####
      END IF;
--
      -- �G���[�t���O�̏�����
      gv_err_flg_resv := gc_onoff_div_off;       -- �����G���[�t���O
      gv_err_flg_carr := gc_onoff_div_off;       -- �z�ԃG���[�t���O
      gv_war_flg_carr_mixed := gc_onoff_div_off; -- �z�ԏo�׈˗����i���݃��[�j���O�t���O
--
      -- ���׌����̏�����
      gn_cnt_line    := 0; -- ���׌���
      gn_cnt_prod    := 0; -- ���i����
      gn_cnt_no_prod := 0; -- ���i�ȊO����
      IF gr_chk_line_data_tab.COUNT > 0 THEN
        <<line_loop>>
        FOR i IN gr_chk_line_data_tab.FIRST .. gr_chk_line_data_tab.LAST LOOP
          gn_cnt_line := gn_cnt_line + 1;
          -- ===============================================
          -- D-5  ���������σ`�F�b�N����
          -- ===============================================
          chk_reserved(
            ln_cnt,             --
            lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF (lv_retcode = gv_status_error) THEN
            --(�G���[����)
            RAISE global_process_expt;
          ELSIF (lv_retcode = gv_status_warn) THEN
            ov_retcode := lv_retcode;
          END IF;
--
          -- ===============================================
          -- D-6  �o�ז��� ���i���݃`�F�b�N����
          -- ===============================================
          chk_mixed_prod(
            ln_cnt,             --
            lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF (lv_retcode = gv_status_error) THEN
            --(�G���[����)
            RAISE global_process_expt;
          ELSIF (lv_retcode = gv_status_warn) THEN
            ov_retcode := lv_retcode;
          END IF;
        END LOOP line_loop;
      END IF;
--
      -- ===============================================
      -- D-7  �z�ԍσ`�F�b�N����
      -- ===============================================
      chk_carrier(
        ln_cnt,             --
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = gv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      ELSIF (lv_retcode = gv_status_warn) THEN
        ov_retcode := lv_retcode;
      END IF;
--
      ---------------------------------------------------------
      -- �����G���[�t���O��OFF���z�ԃG���[�t���O��OFF�̏ꍇ
      ---------------------------------------------------------
      IF ((gv_err_flg_resv = gc_onoff_div_off) AND (gv_err_flg_carr = gc_onoff_div_off)) THEN
        -- ===============================================
        -- D-8  �`�F�b�N�σf�[�^ PL/SQL�\�i�[����
        -- ===============================================
        set_checked_data(
          ln_cnt,             --
          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = gv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        ELSIF (lv_retcode = gv_status_warn) THEN
          ov_retcode := lv_retcode;
        END IF;
      -- ===============================================
      -- D-9  �`�F�b�N�G���[���O �o�͏���
      -- ===============================================
      ---------------------------------------------------------
      -- �����G���[�t���O��ON�̏ꍇ
      ---------------------------------------------------------
      ELSIF ((gv_err_flg_resv = gc_onoff_div_on) AND (gv_err_flg_carr = gc_onoff_div_off)) THEN
        lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                                     gv_cons_msg_kbn_wsh -- 'XXWSH'
                                    ,gv_check_line_err   -- ���������σ`�F�b�N�G���[
                                    ,gv_cnst_tkn_check_kbn    -- �g�[�N��'CHECK_KBN'
                                    ,gv_tkn_reserved_err   -- '�����G���['
                                    ,gv_cnst_tkn_delivery_no -- �g�[�N��'DELIVERY_NO'
                                    ,gr_chk_header_data_tab(ln_cnt).delivery_no   -- '�z��No'
                                    ,gv_cnst_tkn_request_no  -- �g�[�N��'REQUEST_NO'
                                    ,gr_chk_header_data_tab(ln_cnt).request_no)   -- '�˗�No'
                                    ,1
                                    ,5000);
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_errmsg );
        ov_retcode := gv_status_warn; -- �I���X�e�[�^�X�F�x��
      ---------------------------------------------------------
      -- �z�ԃG���[�t���O��ON�̏ꍇ
      ---------------------------------------------------------
      ELSIF ((gv_err_flg_resv = gc_onoff_div_off) AND (gv_err_flg_carr = gc_onoff_div_on)) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                     gv_cons_msg_kbn_wsh -- 'XXWSH'
                                    ,gv_check_line_err   -- ���������σ`�F�b�N�G���[
                                    ,gv_cnst_tkn_check_kbn    -- �g�[�N��'CHECK_KBN'
                                    ,gv_tkn_carrier_err   -- '�z�ԃG���['
                                    ,gv_cnst_tkn_delivery_no -- �g�[�N��'DELIVERY_NO'
                                    ,gr_chk_header_data_tab(ln_cnt).delivery_no   -- '�z��No'
                                    ,gv_cnst_tkn_request_no  -- �g�[�N��'REQUEST_NO'
                                    ,gr_chk_header_data_tab(ln_cnt).request_no)   -- '�˗�No'
                                    ,1
                                    ,5000);
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_errmsg );
        ov_retcode := gv_status_warn; -- �I���X�e�[�^�X�F�x��
      ---------------------------------------------------------
      -- �����G���[�t���O��ON���z�ԃG���[�t���O��ON�̏ꍇ
      ---------------------------------------------------------
      ELSIF ((gv_err_flg_resv = gc_onoff_div_on) AND (gv_err_flg_carr = gc_onoff_div_on)) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                     gv_cons_msg_kbn_wsh -- 'XXWSH'
                                    ,gv_check_line_err   -- ���������σ`�F�b�N�G���[
                                    ,gv_cnst_tkn_check_kbn    -- �g�[�N��'CHECK_KBN'
                                    ,gv_tkn_reserved_carrier_err   -- '�����y�єz�ԃG���['
                                    ,gv_cnst_tkn_delivery_no -- �g�[�N��'DELIVERY_NO'
                                    ,gr_chk_header_data_tab(ln_cnt).delivery_no   -- '�z��No'
                                    ,gv_cnst_tkn_request_no  -- �g�[�N��'REQUEST_NO'
                                    ,gr_chk_header_data_tab(ln_cnt).request_no)   -- '�˗�No'
                                    ,1
                                    ,5000);
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_errmsg );
        ov_retcode := gv_status_warn; -- �I���X�e�[�^�X�F�x��
      END IF;
      ---------------------------------------------------------
      -- �z�ԏo�׈˗����i���݃��[�j���O�t���O��ON�̏ꍇ
      ---------------------------------------------------------
      IF (gv_war_flg_carr_mixed = gc_onoff_div_on) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                     gv_cons_msg_kbn_wsh -- 'XXWSH'
                                    ,gv_check_line_err   -- ���������σ`�F�b�N�G���[
                                    ,gv_cnst_tkn_check_kbn    -- �g�[�N��'CHECK_KBN'
                                    ,gv_tkn_mixed_prod_err   -- '�o�׈˗����i����'
                                    ,gv_cnst_tkn_delivery_no -- �g�[�N��'DELIVERY_NO'
                                    ,gr_chk_header_data_tab(ln_cnt).delivery_no   -- '�z��No'
                                    ,gv_cnst_tkn_request_no  -- �g�[�N��'REQUEST_NO'
                                    ,gr_chk_header_data_tab(ln_cnt).request_no)   -- '�˗�No'
                                    ,1
                                    ,5000);
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_errmsg );
        ov_retcode := gv_status_warn; -- �I���X�e�[�^�X�F�x��
      END IF;
--
    END LOOP header_loop;
--
    IF gr_checked_data_tab.COUNT > 0 THEN
      --------------------------------------------------
      -- ����q�ɓ��ɃG���[���Ȃ��ꍇ
      --------------------------------------------------
      IF (gv_err_flg_whse = gc_onoff_div_off) THEN
        -- ===============================================
        -- D-10  �ʒm�X�e�[�^�X�X�V�pPL�^SQL�\ �i�[����
        -- ===============================================
        set_upd_data(
          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = gv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        ELSIF (lv_retcode = gv_status_warn) THEN
          ov_retcode := lv_retcode;
        END IF;
      END IF;
    END IF;
--
    IF gr_upd_data_tab.COUNT > 0 THEN
      -- ===============================================
      -- D-12  �ʒm�X�e�[�^�X �ꊇ�X�V����
      -- ===============================================
      upd_notif_status(
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = gv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      ELSIF (lv_retcode = gv_status_warn) THEN
        ov_retcode := lv_retcode;
      END IF;
    END IF;
--
    -- ===============================================
    -- D-13  ���ԃe�[�u���p�[�W����
    -- ===============================================
    purge_tbl(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = gv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
  EXCEPTION
--
-- ##### 20080616 1.1 ������Q #9�Ή� START #####
    -- =============================================================================================
    -- �x������
    -- =============================================================================================
    WHEN ex_worn THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf ;
      ov_retcode := gv_status_warn;
-- ##### 20080616 1.1 ������Q #9�Ή� END   #####
--
    --*** ���l�^�ɕϊ��ł��Ȃ������ꍇ=TO_NUMBER() ***
    WHEN VALUE_ERROR THEN
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode :=   gv_status_error;
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
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                    OUT NOCOPY VARCHAR2,  -- �G���[���b�Z�[�W #�Œ�#
    retcode                   OUT NOCOPY VARCHAR2,  -- �G���[�R�[�h     #�Œ�#
    iv_dept_code              IN VARCHAR2,          -- ����
    iv_shipping_biz_type      IN VARCHAR2,          -- �������
    iv_transaction_type_id    IN VARCHAR2,          -- �o�Ɍ`��
    iv_lead_time_day_01       IN VARCHAR2,          -- ���Y����LT1
    iv_lt1_ship_date_from     IN VARCHAR2,          -- ���Y����LT1/�o�׈˗�/�o�ɓ�From
    iv_lt1_ship_date_to       IN VARCHAR2,          -- ���Y����LT1/�o�׈˗�/�o�ɓ�To
    iv_lead_time_day_02       IN VARCHAR2,          -- ���Y����LT2
    iv_lt2_ship_date_from     IN VARCHAR2,          -- ���Y����LT2/�o�׈˗�/�o�ɓ�From
    iv_lt2_ship_date_to       IN VARCHAR2,          -- ���Y����LT2/�o�׈˗�/�o�ɓ�To
    iv_ship_date_from         IN VARCHAR2,          -- �o�ɓ�From
    iv_ship_date_to           IN VARCHAR2,          -- �o�ɓ�To
    iv_move_ship_date_from    IN VARCHAR2,          -- �ړ�/�o�ɓ�From
    iv_move_ship_date_to      IN VARCHAR2,          -- �ړ�/�o�ɓ�To
    iv_prov_ship_date_from    IN VARCHAR2,          -- �x��/�o�ɓ�From
    iv_prov_ship_date_to      IN VARCHAR2,          -- �x��/�o�ɓ�To
    iv_block_01               IN VARCHAR2,          -- �u���b�N�P
    iv_block_02               IN VARCHAR2,          -- �u���b�N�Q
    iv_block_03               IN VARCHAR2,          -- �u���b�N�R
    iv_shipped_locat_code     IN VARCHAR2           -- �o�Ɍ�
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
    iv_dept_code,           -- ����
    iv_shipping_biz_type,   -- �������
    iv_transaction_type_id, -- �o�Ɍ`��
    iv_lead_time_day_01,    -- ���Y����LT1
    iv_lt1_ship_date_from,  -- ���Y����LT1/�o�׈˗�/�o�ɓ�From
    iv_lt1_ship_date_to,    -- ���Y����LT1/�o�׈˗�/�o�ɓ�To
    iv_lead_time_day_02,    -- ���Y����LT2
    iv_lt2_ship_date_from,  -- ���Y����LT2/�o�׈˗�/�o�ɓ�From
    iv_lt2_ship_date_to,    -- ���Y����LT2/�o�׈˗�/�o�ɓ�To
    iv_ship_date_from,      -- �o�ɓ�From
    iv_ship_date_to,        -- �o�ɓ�To
    iv_move_ship_date_from, -- �ړ�/�o�ɓ�From
    iv_move_ship_date_to,   -- �ړ�/�o�ɓ�To
    iv_prov_ship_date_from, -- �x��/�o�ɓ�From
    iv_prov_ship_date_to,   -- �x��/�o�ɓ�To
    iv_block_01,            -- �u���b�N�P
    iv_block_02,            -- �u���b�N�Q
    iv_block_03,            -- �u���b�N�R
    iv_shipped_locat_code,  -- �o�Ɍ�
    lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
    lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
    lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
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
    -- ====================================================
    -- �R���J�����g���O�̏o��
    -- ====================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;   --��؂蕶����o��
--
    -------------------------------------------------------
    -- ���̓p�����[�^
    -------------------------------------------------------
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '���̓p�����[�^' );
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '����                            �F' || iv_dept_code           ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '�������                        �F' || iv_shipping_biz_type   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '�o�Ɍ`��                        �F' || iv_transaction_type_id ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '���Y����LT1                     �F' || iv_lead_time_day_01    ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '���Y����LT1/�o�׈˗�/�o�ɓ�From �F' || iv_lt1_ship_date_from  ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '���Y����LT1/�o�׈˗�/�o�ɓ�To   �F' || iv_lt1_ship_date_to    ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '���Y����LT2                     �F' || iv_lead_time_day_02    ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '���Y����LT2/�o�׈˗�/�o�ɓ�From �F' || iv_lt2_ship_date_from  ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '���Y����LT2/�o�׈˗�/�o�ɓ�To   �F' || iv_lt2_ship_date_to    ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '�o�ɓ�From                      �F' || iv_ship_date_from      ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '�o�ɓ�To                        �F' || iv_ship_date_to        ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '�ړ�/�o�ɓ�From                 �F' || iv_move_ship_date_from ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '�ړ�/�o�ɓ�To                   �F' || iv_move_ship_date_to   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '�x��/�o�ɓ�From                 �F' || iv_prov_ship_date_from ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '�x��/�o�ɓ�To                   �F' || iv_prov_ship_date_to   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '�u���b�N�P                      �F' || iv_block_01            ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '�u���b�N�Q                      �F' || iv_block_02            ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '�u���b�N�R                      �F' || iv_block_03            ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,
                                '�o�Ɍ�                          �F' || iv_shipped_locat_code  ) ;
--
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;   --��؂蕶����o��
--
    -------------------------------------------------------
    -- ��������
    -------------------------------------------------------
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '��������' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'  �o�ׁF' || TO_CHAR( gn_cnt_upd_ship,'FM999,999,990' ) ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'  �x���F' || TO_CHAR( gn_cnt_upd_prov,'FM999,999,990' ) ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'  �ړ��F' || TO_CHAR( gn_cnt_upd_move,'FM999,999,990' ) ) ;
--
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;   --��؂蕶����o��
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
END xxwsh600005c;
/
