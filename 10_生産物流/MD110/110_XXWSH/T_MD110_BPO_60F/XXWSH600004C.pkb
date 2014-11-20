create or replace PACKAGE BODY xxwsh600004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH600004C(body)
 * Description      : �g�g�s���o�ɔz�Ԋm���񒊏o����
 * MD.050           : T_MD050_BPO_601_�z�Ԕz���v��
 * MD.070           : T_MD070_BPO_60F_�g�g�s���o�ɔz�Ԋm���񒊏o����
 * Version          : 1.10
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  prc_chk_param          �p�����[�^�`�F�b�N             (F-01)
 *  prc_get_profile        �v���t�@�C���擾               (F-02)
 *  prc_del_temp_data      �e�[�u���폜                   (F-03)
 *  prc_get_main_data      ���C���f�[�^���o               (F-04)
 *  prc_cre_head_data      �w�b�_�f�[�^�쐬
 *  prc_cre_dtl_data       ���׃f�[�^�쐬
 *  prc_create_ins_data    �ʒm�Ϗ��쐬����             (F-05)
 *  prc_create_can_data    �ύX�O������f�[�^�쐬����   (F-06)
 *  prc_ins_temp_data      �ꊇ�o�^����                   (F-07)
 *  prc_out_csv_data       �b�r�u�o�͏���                 (F-08)
 *  prc_ins_out_data       �ʒm�ς݃f�[�^�o�^����         (F-09,F-10)
 *  prc_put_err_log        ���ڃG���[���O�o�͏���         (F-11)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/05/02    1.0   M.Ikeda          �V�K�쐬
 *  2008/06/04    1.1   N.Yoshida        �ړ����b�g�ڍוR�t���Ή�
 *  2008/06/11    1.2   M.Hokkanji       �z�Ԃ��g�܂�Ă��Ȃ��ꍇ�ł��o�͂����悤�ɏC��
 *  2008/06/12    1.3   M.Nomura         �����e�X�g �s��Ή�#7
 *  2008/06/17    1.4   M.Hokkanji       �V�X�e���e�X�g �s��Ή�#153
 *  2008/06/19    1.5   M.Nomura         �V�X�e���e�X�g �s��Ή�#193
 *  2008/06/27    1.6   M.Nomura         �V�X�e���e�X�g �s��Ή�#303
 *  2008/07/04    1.7   M.Nomura         �V�X�e���e�X�g �s��Ή�#193 2���
 *  2008/07/17    1.8   Oracle �R�� ��_ I_S_001,I_S_192,T_S_443,�w�E240�Ή�
 *  2008/07/22    1.9   N.Fukuda         I_S_001�Ή�(�\��1������/����敪�Ŏg�p����)
 *  2008/08/08    1.10  Oracle �R�� ��_ TE080_400�w�E#83,�ۑ�#32
 *  2008/08/11    1.10  N.Fukuda         �w�������̒��o����SQL�̕s��Ή�
 *  2008/08/12    1.10  N.Fukuda         �ۑ�#48(�ύX�v��#164)�Ή�
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
  gv_msg_comma     CONSTANT VARCHAR2(3) := ',';
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
  -- ==============================================================================================
  -- ���[�U�[��`��O
  -- ==============================================================================================
  -- ���b�N�擾��O
  ex_lock_error    EXCEPTION ;
  file_exists_expt EXCEPTION ;
  PRAGMA EXCEPTION_INIT( ex_lock_error, -54 ) ;
--
  -- ==============================================================================================
  -- �O���[�o���萔
  -- ==============================================================================================
  --------------------------------------------------
  -- �p�b�P�[�W��
  --------------------------------------------------
  gc_pkg_name           CONSTANT VARCHAR2(100)  := 'XXWSH600004C';
--
  --------------------------------------------------
  -- �A�v���P�[�V�����Z�k��
  --------------------------------------------------
  gc_appl_sname_cmn     CONSTANT VARCHAR2(100)  := 'XXCMN' ;    -- �}�X�^����
  gc_appl_sname_wsh     CONSTANT VARCHAR2(100)  := 'XXWSH' ;    -- �o��
--
  --------------------------------------------------
  -- �N�C�b�N�R�[�h�i�^�C�v�j
  --------------------------------------------------
  gc_lookup_ship_method     CONSTANT VARCHAR2(50) := 'XXCMN_SHIP_METHOD' ; -- �z���敪
  --------------------------------------------------
  -- �N�C�b�N�R�[�h�i�l�j
  --------------------------------------------------
  -- �X�e�[�^�X
  gc_req_status_syu_1   CONSTANT VARCHAR2(2) := '01' ;  -- ���͒�
  gc_req_status_syu_2   CONSTANT VARCHAR2(2) := '02' ;  -- ���_�m��
  gc_req_status_syu_3   CONSTANT VARCHAR2(2) := '03' ;  -- ���ߍς�
  gc_req_status_syu_4   CONSTANT VARCHAR2(2) := '04' ;  -- �o�׎��ьv���
  gc_req_status_syu_5   CONSTANT VARCHAR2(2) := '99' ;  -- ���
  -- �ʒm�X�e�[�^�X
  gc_notif_status_n     CONSTANT VARCHAR2(2) := '10' ;  -- ���ʒm
  gc_notif_status_r     CONSTANT VARCHAR2(2) := '20' ;  -- �Ēʒm�v
  gc_notif_status_c     CONSTANT VARCHAR2(2) := '40' ;  -- �m��ʒm��
  -- �d�ʗe�ϋ敪
  gc_wc_class_j         CONSTANT VARCHAR2(1) := '1' ;   -- �d��
  gc_wc_class_y         CONSTANT VARCHAR2(1) := '2' ;   -- �e��
  -- �����敪
  gc_small_method_y     CONSTANT VARCHAR2(1) := '1' ;   -- ����
  gc_small_method_n     CONSTANT VARCHAR2(1) := '0' ;   -- �����ȊO
/* 2008/08/08 Mod ��
  -- 2008/07/22 Start
  -- ����/����敪�i�\���P�j
  gc_small_class        CONSTANT VARCHAR2(1) := '1' ;   -- ����
  gc_takeback_class     CONSTANT VARCHAR2(1) := '2' ;   -- ����
  -- 2008/07/22 End
2008/08/08 Mod �� */
  -- ����/����敪�i�\���P�j
  gc_small_class        CONSTANT VARCHAR2(1) := '0' ;   -- ����
  gc_takeback_class     CONSTANT VARCHAR2(1) := '1' ;   -- ����
  -- �x�^�m�t���O
  gc_yes_no_y           CONSTANT VARCHAR2(1) := 'Y' ;   -- �x
  gc_yes_no_n           CONSTANT VARCHAR2(1) := 'N' ;   -- �m
  -- �^���敪
-- M.Hokkanji Ver1.2 START
  gc_freight_class_y    CONSTANT VARCHAR2(1) := '1' ;   -- �Ώ�
  gc_freight_class_n    CONSTANT VARCHAR2(1) := '0' ;   -- �ΏۊO
--  gc_freight_class_y    CONSTANT VARCHAR2(1) := 'Y' ;   -- �Ώ�
--  gc_freight_class_n    CONSTANT VARCHAR2(1) := 'N' ;   -- �ΏۊO
-- M.Hokkanji Ver1.2 END
  --�o�׎x���敪
  gc_sp_class_ship      CONSTANT VARCHAR2(1)  := '1' ;    -- �o�׈˗�
  gc_sp_class_move      CONSTANT VARCHAR2(1)  := '3' ;    -- �ړ��i�v���O����������j
  -- ���O�q�ɋ敪
  gc_whse_io_div_i      CONSTANT VARCHAR2(1)  := '1' ;    -- �����q��
  -- �ړ��X�e�[�^�X
  gc_mov_status_req       CONSTANT VARCHAR2(2)  := '01' ;   -- �˗���
  gc_mov_status_cmp       CONSTANT VARCHAR2(2)  := '02' ;   -- �˗���
  gc_mov_status_adj       CONSTANT VARCHAR2(2)  := '03' ;   -- ������
  gc_mov_status_del       CONSTANT VARCHAR2(2)  := '04' ;   -- �o�ɕ񍐗L
  gc_mov_status_stc       CONSTANT VARCHAR2(2)  := '05' ;   -- ���ɕ񍐗L
  gc_mov_status_dsr       CONSTANT VARCHAR2(2)  := '06' ;   -- ���o�ɕ񍐗L
  gc_mov_status_ccl       CONSTANT VARCHAR2(2)  := '99' ;   -- ���
  -- �ړ��^�C�v
  gc_mov_type_y           CONSTANT VARCHAR2(1)  := '1' ;    -- �ϑ�����
  gc_mov_type_n           CONSTANT VARCHAR2(1)  := '2' ;    -- �ϑ��Ȃ�
  -- ���i�敪
  gc_prod_class_r         CONSTANT VARCHAR2(1)  := '1' ;    -- ���[�t
  gc_prod_class_d         CONSTANT VARCHAR2(1)  := '2' ;    -- �h�����N
  -- �i�ڋ敪
  gc_item_class_g         CONSTANT VARCHAR2(1)  := '1' ;    -- ����
  gc_item_class_s         CONSTANT VARCHAR2(1)  := '2' ;    -- ����
  gc_item_class_h         CONSTANT VARCHAR2(1)  := '4' ;    -- �����i
  gc_item_class_i         CONSTANT VARCHAR2(1)  := '5' ;    -- ���i
  -- ���b�g�Ǘ�
  gc_lot_ctl_y            CONSTANT VARCHAR2(1) := '1' ;     -- ���b�g�Ǘ�����
  gc_lot_ctl_n            CONSTANT VARCHAR2(1) := '0' ;     -- ���b�g�Ǘ��Ȃ�
  -- �ړ����b�g�ڍ׃A�h�I���F�����^�C�v
  gc_doc_type_ship        CONSTANT VARCHAR2(2) := '10' ;    -- �o�׎w��
  gc_doc_type_move        CONSTANT VARCHAR2(2) := '20' ;    -- �ړ�
  gc_doc_type_prov        CONSTANT VARCHAR2(2) := '30' ;    -- �x���w��
  gc_doc_type_prod        CONSTANT VARCHAR2(2) := '40' ;    -- ���Y�w��
  -- �ړ����b�g�ڍ׃A�h�I���F���R�[�h�^�C�v
  gc_rec_type_inst        CONSTANT VARCHAR2(2) := '10' ;    -- �w��
  gc_rec_type_stck        CONSTANT VARCHAR2(2) := '20' ;    -- �o�Ɏ���
  gc_rec_type_dlvr        CONSTANT VARCHAR2(2) := '30' ;    -- ���Ɏ���
  gc_rec_type_tron        CONSTANT VARCHAR2(2) := '40' ;    -- ������
  -- ���b�g�}�X�^�F�L���t���O
  gc_inactive_ind_y       CONSTANT VARCHAR2(1) := '0' ;     -- �L��
  -- ���b�g�}�X�^�F�폜�t���O
  gc_delete_mark_y        CONSTANT VARCHAR2(1) := '0' ;     -- ���폜
--
  --------------------------------------------------
  -- �o�^�l
  --------------------------------------------------
  gc_corporation_name       CONSTANT VARCHAR2(100) := 'ITOEN' ;
  gc_reserve                CONSTANT VARCHAR2(100) := '000000000000' ;
  -- ���׍폜�t���O
  gc_delete_flag_y          CONSTANT VARCHAR2(1) := '1' ;   -- �폜
  gc_delete_flag_n          CONSTANT VARCHAR2(1) := '0' ;   -- ���폜
  -- �f�[�^�^�C�v
  gc_data_type_syu_ins      CONSTANT VARCHAR2(1) := '1' ;   -- �o�ׁF�o�^
  gc_data_type_mov_ins      CONSTANT VARCHAR2(1) := '3' ;   -- �ړ��F�o�^
  -- �^���敪
  gc_freight_class_ins_y    CONSTANT VARCHAR2(1) := '1' ;   -- �Ώ�
  gc_freight_class_ins_n    CONSTANT VARCHAR2(1) := '0' ;   -- �ΏۊO
  -- �f�[�^���
  gc_data_class_syu_s       CONSTANT VARCHAR2(3) := '110' ;   -- �o�ׁF�o�׈˗�
  gc_data_class_mov_s       CONSTANT VARCHAR2(3) := '120' ;   -- �ړ��F�o�׈˗�
  gc_data_class_mov_n       CONSTANT VARCHAR2(3) := '130' ;   -- �ړ��F�ړ�����
  -- �X�e�[�^�X
  gc_status_y               CONSTANT VARCHAR2(2) := '01' ;    -- �\��
  gc_status_k               CONSTANT VARCHAR2(2) := '02' ;    -- �m��
  -- �f�[�^�敪
  gc_data_class_ins         CONSTANT VARCHAR2(1) := '0' ;     -- �ǉ�
-- M.Hokkanji Ver1.2 START
--  gc_data_class_del         CONSTANT VARCHAR2(1) := '2' ;     -- �폜
-- ##### 20080612 Ver.1.2 �f�[�^�敪�폜�R�[�h�Ή� START #####
--  gc_data_class_del         CONSTANT VARCHAR2(1) := '2' ;     -- �폜
  gc_data_class_del         CONSTANT VARCHAR2(1) := '1' ;     -- �폜
-- ##### 20080612 Ver.1.2 �f�[�^�敪�폜�R�[�h�Ή� START #####
  gc_product_flg_1          CONSTANT VARCHAR2(1) := '1' ;     -- ���i
  gc_product_flg_0          CONSTANT VARCHAR2(1) := '0' ;     -- ���i�ȊO
-- M.Hokkanji Ver1.2 END
  -- ���[�N�t���[�敪
  gc_wf_class_gai           CONSTANT VARCHAR2(1) := '1' ;     -- �O���q��
  gc_wf_class_uns           CONSTANT VARCHAR2(1) := '2' ;     -- �^���Ǝ�
  gc_wf_class_tor           CONSTANT VARCHAR2(1) := '3' ;     -- �����
  gc_wf_class_hht           CONSTANT VARCHAR2(1) := '4' ;     -- HHT�T�[�o�[
  gc_wf_class_sys           CONSTANT VARCHAR2(1) := '5' ;     -- ���c�ƃV�X�e��
  gc_wf_class_syo           CONSTANT VARCHAR2(1) := '6' ;     -- �E��
--
  --------------------------------------------------
  -- ���̑�
  --------------------------------------------------
  gc_time_default           CONSTANT VARCHAR2(4) := '0000' ;    -- ���ԃf�t�H���g�l
  gc_time_min               CONSTANT VARCHAR2(5) := '00:00' ;   -- ���ԍŏ��l
  gc_time_max               CONSTANT VARCHAR2(5) := '23:59' ;   -- ���ԍő�l
--
  -- ==============================================================================================
  -- �O���[�o���ϐ�
  -- ==============================================================================================
  gd_effective_date   DATE ;    -- �}�X�^�i���ݓ��t
  gd_date_from        DATE ;    -- ����tFrom
  gd_date_to          DATE ;    -- ����tTo
--
  --------------------------------------------------
  -- �v���t�@�C��
  --------------------------------------------------
  gn_prof_del_date            NUMBER ;          -- �폜�����
  gv_prof_put_file_name       VARCHAR2(100) ;   -- �o�̓t�@�C����
  gv_prof_put_file_path       VARCHAR2(100) ;   -- �o�̓t�@�C���f�B���N�g��
  gv_prof_type_plan           VARCHAR2(100) ;   -- ����ύX --2008/07/22 ADD
--
  gr_outbound_rec     xxcmn_common_pkg.outbound_rec ;   -- �t�@�C�����̃��R�[�h�̒�`
--
  --------------------------------------------------
  -- �v�g�n�J����
  --------------------------------------------------
  gn_created_by               NUMBER ;  -- �쐬��
  gn_last_updated_by          NUMBER ;  -- �ŏI�X�V��
  gn_last_update_login        NUMBER ;  -- �ŏI�X�V���O�C��
  gn_request_id               NUMBER ;  -- �v��ID
  gn_program_application_id   NUMBER ;  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  gn_program_id               NUMBER ;  -- �R���J�����g�E�v���O����ID
--
  gn_out_cnt_syu              NUMBER DEFAULT 0 ;   -- �o�͌����F�o��
  gn_out_cnt_mov              NUMBER DEFAULT 0 ;   -- �o�͌����F�ړ�
--
  --------------------------------------------------
  -- �f�o�b�O�p
  --------------------------------------------------
  gv_debug_txt                VARCHAR2(1000) ;
  gv_debug_cnt                NUMBER DEFAULT 0 ;
--
  -- ==============================================================================================
  -- ���R�[�h�^�錾
  -- ==============================================================================================
  --------------------------------------------------
  -- ���̓p�����[�^�i�[�p
  --------------------------------------------------
  TYPE rec_param_data  IS RECORD
    (
      dept_code_01      VARCHAR2(4)   -- 01 : ����
     ,dept_code_02      VARCHAR2(4)   -- 02 : ����(2008/07/17 Add)
     ,dept_code_03      VARCHAR2(4)   -- 03 : ����(2008/07/17 Add)
     ,dept_code_04      VARCHAR2(4)   -- 04 : ����(2008/07/17 Add)
     ,dept_code_05      VARCHAR2(4)   -- 05 : ����(2008/07/17 Add)
     ,dept_code_06      VARCHAR2(4)   -- 06 : ����(2008/07/17 Add)
     ,dept_code_07      VARCHAR2(4)   -- 07 : ����(2008/07/17 Add)
     ,dept_code_08      VARCHAR2(4)   -- 08 : ����(2008/07/17 Add)
     ,dept_code_09      VARCHAR2(4)   -- 09 : ����(2008/07/17 Add)
     ,dept_code_10      VARCHAR2(4)   -- 10 : ����(2008/07/17 Add)
     ,date_fix          VARCHAR2(20)  -- 11 : �m��ʒm���{��
     ,fix_from          VARCHAR2(10)  -- 12 : �m��ʒm���{����From
     ,fix_to            VARCHAR2(10)  -- 13 : �m��ʒm���{����To
    ) ;
  gr_param              rec_param_data ;
--
  --------------------------------------------------
  -- ���ԃe�[�u���i�[�p
  --------------------------------------------------
  TYPE rec_main_data  IS RECORD
    (
      line_number               xxwsh_hht_stock_deliv_info_tmp.line_number%TYPE
     ,line_id                   xxinv_mov_lot_details.mov_line_id%TYPE
     ,prev_notif_status         VARCHAR2(2)
     ,data_type                 xxwsh_hht_stock_deliv_info_tmp.data_type%TYPE
     ,delivery_no               xxwsh_hht_stock_deliv_info_tmp.delivery_no%TYPE
     ,request_no                xxwsh_hht_stock_deliv_info_tmp.request_no%TYPE
     ,head_sales_branch         xxwsh_hht_stock_deliv_info_tmp.head_sales_branch%TYPE
     ,head_sales_branch_name    xxwsh_hht_stock_deliv_info_tmp.head_sales_branch_name%TYPE
     ,shipped_locat_code        xxwsh_hht_stock_deliv_info_tmp.shipped_locat_code%TYPE
     ,shipped_locat_name        xxwsh_hht_stock_deliv_info_tmp.shipped_locat_name%TYPE
     ,ship_to_locat_code        xxwsh_hht_stock_deliv_info_tmp.ship_to_locat_code%TYPE
     ,ship_to_locat_name        xxwsh_hht_stock_deliv_info_tmp.ship_to_locat_name%TYPE
     ,freight_carrier_code      xxwsh_hht_stock_deliv_info_tmp.freight_carrier_code%TYPE
     ,freight_carrier_name      xxwsh_hht_stock_deliv_info_tmp.freight_carrier_name%TYPE
     ,deliver_to                xxwsh_hht_stock_deliv_info_tmp.deliver_to%TYPE
     ,deliver_to_name           xxwsh_hht_stock_deliv_info_tmp.deliver_to_name%TYPE
     ,schedule_ship_date        xxwsh_hht_stock_deliv_info_tmp.schedule_ship_date%TYPE
     ,schedule_arrival_date     xxwsh_hht_stock_deliv_info_tmp.schedule_arrival_date%TYPE
     ,shipping_method_code      xxwsh_hht_stock_deliv_info_tmp.shipping_method_code%TYPE
     ,weight                    xxwsh_hht_stock_deliv_info_tmp.weight%TYPE
     ,mixed_no                  xxwsh_hht_stock_deliv_info_tmp.mixed_no%TYPE
     ,collected_pallet_qty      xxwsh_hht_stock_deliv_info_tmp.collected_pallet_qty%TYPE
     ,freight_charge_class      xxwsh_hht_stock_deliv_info_tmp.freight_charge_class%TYPE
     ,arrival_time_from         xxwsh_hht_stock_deliv_info_tmp.arrival_time_from%TYPE
     ,arrival_time_to           xxwsh_hht_stock_deliv_info_tmp.arrival_time_to%TYPE
     ,cust_po_number            xxwsh_hht_stock_deliv_info_tmp.cust_po_number%TYPE
     ,description               xxwsh_hht_stock_deliv_info_tmp.description%TYPE
     ,pallet_quantity_o         xxwsh_hht_stock_deliv_info_tmp.pallet_sum_quantity%TYPE
     ,pallet_quantity_i         xxwsh_hht_stock_deliv_info_tmp.pallet_sum_quantity%TYPE
     ,report_dept               xxwsh_hht_stock_deliv_info_tmp.report_dept%TYPE
     ,item_code                 xxwsh_hht_stock_deliv_info_tmp.item_code%TYPE
     ,item_id                   xxinv_mov_lot_details.item_id%TYPE
     ,item_name                 xxwsh_hht_stock_deliv_info_tmp.item_name%TYPE
     ,item_uom_code             xxwsh_hht_stock_deliv_info_tmp.item_uom_code%TYPE
     ,conv_unit                 xxcmn_item_mst2_v.conv_unit%TYPE
     ,item_quantity             xxwsh_hht_stock_deliv_info_tmp.item_quantity%TYPE
     ,num_of_cases              xxcmn_item_mst2_v.num_of_cases%TYPE
     ,lot_ctl                   xxcmn_item_mst2_v.lot_ctl%TYPE
     ,line_delete_flag          VARCHAR2(1)
     ,mov_lot_dtl_id            xxinv_mov_lot_details.mov_lot_dtl_id%TYPE
-- ##### 20080619 1.5 ST�s�#193 START #####
     ,out_whse_inout_div        xxcmn_item_locations_v.whse_inside_outside_div%TYPE   -- �o �q�� ���O�q�ɋ敪
     ,in_whse_inout_div         xxcmn_item_locations_v.whse_inside_outside_div%TYPE   -- �� �q�� ���O�q�ɋ敪
-- ##### 20080619 1.5 ST�s�#193 END   #####
-- 2008/07/22 Start
     ,reserve1         xxwsh_hht_stock_deliv_info_tmp.reserve1%TYPE   -- ����/����敪�i�\���P�j
-- 2008/07/22 End
    ) ;
  TYPE tab_main_data IS TABLE OF rec_main_data INDEX BY BINARY_INTEGER ;
  gt_main_data  tab_main_data ;
--
  --------------------------------------------------
  -- �ʒm�Ϗ��i�[�p
  --------------------------------------------------
  TYPE t_corporation_name        IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.corporation_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_data_class              IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.data_class%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_transfer_branch_no      IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.transfer_branch_no%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_delivery_no             IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.delivery_no%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_request_no              IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.request_no%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_reserve                 IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.reserve%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_head_sales_branch       IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.head_sales_branch%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_head_sales_branch_name  IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.head_sales_branch_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_shipped_locat_code      IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.shipped_locat_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_shipped_locat_name      IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.shipped_locat_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_ship_to_locat_code      IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.ship_to_locat_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_ship_to_locat_name      IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.ship_to_locat_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_freight_carrier_code    IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.freight_carrier_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_freight_carrier_name    IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.freight_carrier_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_deliver_to              IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.deliver_to%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_deliver_to_name         IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.deliver_to_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_schedule_ship_date      IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.schedule_ship_date%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_schedule_arrival_date   IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_shipping_method_code    IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.shipping_method_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_weight                  IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.weight%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_mixed_no                IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.mixed_no%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_collected_pallet_qty    IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.collected_pallet_qty%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_arrival_time_from       IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.arrival_time_from%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_arrival_time_to         IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.arrival_time_to%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_cust_po_number          IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.cust_po_number%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_description             IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.description%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_status                  IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.status%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_freight_charge_class    IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.freight_charge_class%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_pallet_sum_quantity     IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.pallet_sum_quantity%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_reserve1                IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.reserve1%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_reserve2                IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.reserve2%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_reserve3                IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.reserve3%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_reserve4                IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.reserve4%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_report_dept             IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.report_dept%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_item_code               IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.item_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_item_name               IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.item_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_item_uom_code           IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.item_uom_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_item_quantity           IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.item_quantity%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_lot_no                  IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.lot_no%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_lot_date                IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.lot_date%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_lot_sign                IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.lot_sign%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_best_bfr_date           IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.best_bfr_date%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_lot_quantity            IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.lot_quantity%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_new_modify_del_class    IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.new_modify_del_class%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_update_date             IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.update_date%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_line_number             IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.line_number%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_data_type               IS TABLE OF
       xxwsh_hht_stock_deliv_info_tmp.data_type%TYPE INDEX BY BINARY_INTEGER ;
  gt_corporation_name         t_corporation_name ;
  gt_data_class               t_data_class ;
  gt_transfer_branch_no       t_transfer_branch_no ;
  gt_delivery_no              t_delivery_no ;
  gt_requesgt_no              t_request_no ;
  gt_reserve                  t_reserve ;
  gt_head_sales_branch        t_head_sales_branch ;
  gt_head_sales_branch_name   t_head_sales_branch_name ;
  gt_shipped_locat_code       t_shipped_locat_code ;
  gt_shipped_locat_name       t_shipped_locat_name ;
  gt_ship_to_locat_code       t_ship_to_locat_code ;
  gt_ship_to_locat_name       t_ship_to_locat_name ;
  gt_freight_carrier_code     t_freight_carrier_code ;
  gt_freight_carrier_name     t_freight_carrier_name ;
  gt_deliver_to               t_deliver_to ;
  gt_deliver_to_name          t_deliver_to_name ;
  gt_schedule_ship_date       t_schedule_ship_date ;
  gt_schedule_arrival_date    t_schedule_arrival_date ;
  gt_shipping_method_code     t_shipping_method_code ;
  gt_weight                   t_weight ;
  gt_mixed_no                 t_mixed_no ;
  gt_collected_pallet_qty     t_collected_pallet_qty ;
  gt_arrival_time_from        t_arrival_time_from ;
  gt_arrival_time_to          t_arrival_time_to ;
  gt_cust_po_number           t_cust_po_number ;
  gt_description              t_description ;
  gt_status                   t_status ;
  gt_freight_charge_class     t_freight_charge_class ;
  gt_pallet_sum_quantity      t_pallet_sum_quantity ;
  gt_reserve1                 t_reserve1 ;
  gt_reserve2                 t_reserve2 ;
  gt_reserve3                 t_reserve3 ;
  gt_reserve4                 t_reserve4 ;
  gt_report_dept              t_report_dept ;
  gt_item_code                t_item_code ;
  gt_item_name                t_item_name ;
  gt_item_uom_code            t_item_uom_code ;
  gt_item_quantity            t_item_quantity ;
  gt_lot_no                   t_lot_no ;
  gt_lot_date                 t_lot_date ;
  gt_lot_sign                 t_lot_sign ;
  gt_best_bfr_date            t_best_bfr_date ;
  gt_lot_quantity             t_lot_quantity ;
  gt_new_modify_del_class     t_new_modify_del_class ;
  gt_update_date              t_update_date ;
  gt_line_number              t_line_number ;
  gt_data_type                t_data_type ;
  gn_cre_idx                  NUMBER DEFAULT 0 ;
--
  -- �x�����b�Z�[�W�p�z��ϐ�
  TYPE t_worm_msg IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER ;
  gt_worm_msg     t_worm_msg ;
  gn_wrm_idx      NUMBER := 0 ;
--
  /************************************************************************************************
   * Procedure Name   : prc_chk_param
   * Description      : �p�����[�^�`�F�b�N(F-01)
   ***********************************************************************************************/
  PROCEDURE prc_chk_param
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_chk_param' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_p_name_time_fix      CONSTANT VARCHAR2(50) := '�m��ʒm���{����' ;
    lc_msg_code_02          CONSTANT VARCHAR2(50) := 'APP-XXWSH-11905' ;  -- ���ԋt�]
    lc_tok_name             CONSTANT VARCHAR2(50) := 'PARAMETER' ;
--
    lc_date_format          CONSTANT VARCHAR2(50) := 'YYYY/MM/DD HH24:MI:SS' ;
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    lv_msg_code       VARCHAR2(100) ;
    lv_tok_val        VARCHAR2(100) ;
--
    -- ==================================================
    -- ��O�錾
    -- ==================================================
    ex_param_error    EXCEPTION ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �t�]�`�F�b�N
    -- ====================================================
    lv_msg_code := lc_msg_code_02 ;
    IF ( gd_date_from > gd_date_to ) THEN
      lv_tok_val := lc_p_name_time_fix ;
      RAISE ex_param_error ;
    END IF ;
--
  EXCEPTION
    -- ============================================================================================
    -- �p�����[�^�G���[
    -- ============================================================================================
    WHEN ex_param_error THEN
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_appl_sname_wsh
                     ,iv_name           => lv_msg_code
                     ,iv_token_name1    => lc_tok_name
                     ,iv_token_value1   => lv_tok_val
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--##### �Œ��O������ START ######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   ######################################################################
  END prc_chk_param ;
--
  /************************************************************************************************
   * Procedure Name   : prc_get_profile
   * Description      : �v���t�@�C���擾(F-02)
   ***********************************************************************************************/
  PROCEDURE prc_get_profile
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_profile' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_prof_name_period       CONSTANT VARCHAR2(50) := 'XXWSH_PURGE_PERIOD_601' ;
    lc_prof_name_file_name    CONSTANT VARCHAR2(50) := 'XXWSH_OB_IF_FILENAME_601F' ;
    lc_prof_name_file_path    CONSTANT VARCHAR2(50) := 'XXWSH_OB_IF_DEST_PATH_601F' ;
    lc_prof_name_type_plan    CONSTANT VARCHAR2(50) := 'XXWSH_TRAN_TYPE_PLAN' ;  -- 2008/07/22 ADD
--
    lc_msg_code               CONSTANT VARCHAR2(50) := 'APP-XXWSH-11953' ;
    lc_tok_name               CONSTANT VARCHAR2(50) := 'PROF_NAME' ;
    lc_tok_val_period         CONSTANT VARCHAR2(100)
        := 'XXWSH: �ʒm�Ϗ��p�[�W�����Ώۊ���_�z�Ԕz���v��' ;
    lc_tok_val_name           CONSTANT VARCHAR2(100)
        := 'XXWSH:CSV�t�@�C����_HHT���o�ɔz�Ԋm���񒊏o' ;
    lc_tok_val_path           CONSTANT VARCHAR2(100)
        := 'XXWSH:CSV�t�@�C���o�͐�f�B���N�g���p�X_HHT���o�ɔz�Ԋm���񒊏o' ;
    -- 2008/07/22 Start
    lc_tok_val_type_plan      CONSTANT VARCHAR2(100)
        := 'XXWSH:����ύX' ;
    -- 2008/07/22 End
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    lv_toc_val        VARCHAR2(100) ;
--
    -- ==================================================
    -- ��O�錾
    -- ==================================================
    ex_prof_error     EXCEPTION ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �v���t�@�C���擾
    -- ====================================================
    -------------------------------------------------------
    -- �폜�����
    -------------------------------------------------------
    gn_prof_del_date := FND_PROFILE.VALUE( lc_prof_name_period ) ;
    IF ( gn_prof_del_date IS NULL ) THEN
      lv_toc_val := lc_tok_val_period ;
      RAISE ex_prof_error ;
    END IF ;
    -------------------------------------------------------
    -- �o�̓t�@�C����
    -------------------------------------------------------
    gv_prof_put_file_name := FND_PROFILE.VALUE( lc_prof_name_file_name ) ;
    IF ( gv_prof_put_file_name IS NULL ) THEN
      lv_toc_val := lc_tok_val_name ;
      RAISE ex_prof_error ;
    END IF ;
    -------------------------------------------------------
    -- �o�̓t�@�C���f�B���N�g��
    -------------------------------------------------------
    gv_prof_put_file_path := FND_PROFILE.VALUE( lc_prof_name_file_path ) ;
    IF ( gv_prof_put_file_path IS NULL ) THEN
      lv_toc_val := lc_tok_val_path ;
      RAISE ex_prof_error ;
    END IF ;
    --
    -- 2008/07/22 Start
    -------------------------------------------------------
    -- ����ύX
    -------------------------------------------------------
    gv_prof_type_plan := FND_PROFILE.VALUE( lc_prof_name_type_plan ) ;
    IF ( gv_prof_type_plan IS NULL ) THEN
      lv_toc_val := lc_tok_val_type_plan ;
      RAISE ex_prof_error ;
    END IF ;
    -- 2008/07/22 End
--
  EXCEPTION
    -- ============================================================================================
    -- �v���t�@�C���擾�G���[
    -- ============================================================================================
    WHEN ex_prof_error THEN
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_appl_sname_wsh
                     ,iv_name           => lc_msg_code
                     ,iv_token_name1    => lc_tok_name
                     ,iv_token_value1   => lv_toc_val
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--##### �Œ��O������ START ######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   ######################################################################
  END prc_get_profile ;
--
  /************************************************************************************************
   * Procedure Name   : prc_del_temp_data
   * Description      : �f�[�^�폜(F-03)
   ***********************************************************************************************/
  PROCEDURE prc_del_temp_data
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_del_temp_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_msg_code     CONSTANT VARCHAR2(50) := 'APP-XXWSH-12853' ;
--
    -- ==================================================
    -- �J�[�\���錾
    -- ==================================================
    ----------------------------------------
    -- HHT���o�ɔz�Ԋm���񒆊ԃe�[�u��
    ----------------------------------------
    CURSOR cu_del_table_01
    IS
      SELECT xhsdit.request_no
      FROM xxwsh_hht_stock_deliv_info_tmp xhsdit
      FOR UPDATE NOWAIT
    ;
    ----------------------------------------
    -- HHT�ʒm�ϓ��o�ɔz�Ԋm����
    ----------------------------------------
    CURSOR cu_del_table_02
    IS
      SELECT xhdi.hht_delivery_info_id
      FROM xxwsh_hht_delivery_info xhdi
      WHERE TRUNC( xhdi.last_update_date ) <= TRUNC( SYSDATE ) - gn_prof_del_date
      FOR UPDATE NOWAIT
    ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- ���b�N�擾
    -- ====================================================
    <<get_lock_01>>
    FOR re_del_table_01 IN cu_del_table_01 LOOP
      EXIT ;
    END LOOP get_lock_01 ;
    <<get_lock_02>>
    FOR re_del_table_02 IN cu_del_table_02 LOOP
      EXIT ;
    END LOOP get_lock_02 ;
--
    -- ====================================================
    -- �f�[�^�폜
    -- ====================================================
    DELETE FROM xxwsh_hht_stock_deliv_info_tmp ;
    DELETE FROM xxwsh_hht_delivery_info
    WHERE TRUNC( last_update_date ) <= TRUNC( SYSDATE ) - gn_prof_del_date ;
--
  EXCEPTION
    -- ============================================================================================
    -- ���b�N�擾�G���[
    -- ============================================================================================
    WHEN ex_lock_error THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := xxcmn_common_pkg.get_msg
                      (
                        iv_application    => gc_appl_sname_wsh
                       ,iv_name           => lc_msg_code
                      ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--##### �Œ��O������ START ######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   ######################################################################
  END prc_del_temp_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_get_main_data
   * Description      : ���C���f�[�^���o(F-04)
   ***********************************************************************************************/
  PROCEDURE prc_get_main_data
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_main_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_msg_code       CONSTANT VARCHAR2(30) := 'APP-XXWSH-11856' ;
--
    -- ==================================================
    -- �J�[�\����`
    -- ==================================================
    CURSOR cu_main
    IS
      SELECT main.line_number                 -- 01:���הԍ�
            ,main.line_id                     -- 02:���ׂh�c
            ,main.prev_notif_status           -- 03:�O��ʒm�X�e�[�^�X
            ,main.data_type                   -- 04:�f�[�^�^�C�v
            ,main.delivery_no                 -- 05:�z��No
            ,main.request_no                  -- 06:�˗�No
            ,main.head_sales_branch           -- 07:���_�R�[�h
            ,main.head_sales_branch_name      -- 08:�Ǌ����_����
            ,main.shipped_locat_code          -- 09:�o�ɑq�ɃR�[�h
            ,main.shipped_locat_name          -- 10:�o�ɑq�ɖ���
            ,main.ship_to_locat_code          -- 11:���ɑq�ɃR�[�h
            ,main.ship_to_locat_name          -- 12:���ɑq�ɖ���
            ,main.freight_carrier_code        -- 13:�^���Ǝ҃R�[�h
            ,main.freight_carrier_name        -- 14:�^���ƎҖ�
            ,main.deliver_to                  -- 15:�z����R�[�h
            ,main.deliver_to_name             -- 16:�z���於
            ,main.schedule_ship_date          -- 17:����
            ,main.schedule_arrival_date       -- 18:����
            ,main.shipping_method_code        -- 19:�z���敪
            ,main.weight                      -- 20:�d�ʁ^�e��
            ,main.mixed_no                    -- 21:���ڌ��˗�No
            ,main.collected_pallet_qty        -- 22:��گĉ������
            ,main.freight_charge_class        -- 23:�^���敪
            ,main.arrival_time_from           -- 24:���׎��Ԏw��From
            ,main.arrival_time_to             -- 25:���׎��Ԏw��To
            ,main.cust_po_number              -- 26:�ڋq�����ԍ�
            ,main.description                 -- 27:�E�v
            ,main.pallet_quantity_o           -- 28:��گĎg�p�����F�o
            ,main.pallet_quantity_i           -- 29:��گĎg�p�����F��
            ,main.report_dept                 -- 30:�񍐕���
            ,main.item_code                   -- 31:�i�ڃR�[�h
            ,main.item_id                     -- 32:�i��ID
            ,main.item_name                   -- 33:�i�ږ�
            ,main.item_uom_code               -- 34:�P��
            ,main.conv_unit                   -- 35:���o�Ɋ��Z�P��
            ,main.item_quantity               -- 36:�i�ڐ���
            ,main.num_of_cases                -- 37:�P�[�X����
            ,main.lot_ctl                     -- 38:���b�g�g�p
            ,main.line_delete_flag            -- 39:���׍폜�t���O
            ,main.mov_lot_dtl_id              -- 40:���b�g�ڍ�ID
-- ##### 20080619 1.5 ST�s�#193 START #####
            ,out_whse_inout_div               -- 42:���O�q�ɋ敪�F�o
            ,in_whse_inout_div                -- 41:���O�q�ɋ敪�F��
-- ##### 20080619 1.5 ST�s�#193 END   #####
            ,reserve1                         -- 43:����/����敪�i�\���P�j
      FROM
        (
        -- ========================================================================================
        -- �o�׃f�[�^�r�p�k
        -- ========================================================================================
        SELECT xola.order_line_number             AS line_number
              ,xola.order_line_id                 AS line_id
              ,xoha.prev_notif_status             AS prev_notif_status
              ,gc_data_type_syu_ins               AS data_type
              ,xoha.delivery_no                   AS delivery_no
              ,xoha.request_no                    AS request_no
              ,xp.party_number                    AS head_sales_branch
              ,xp.party_name                      AS head_sales_branch_name
              ,xil.segment1                       AS shipped_locat_code
              ,SUBSTRB( xil.description, 1, 20 )  AS shipped_locat_name
              ,NULL                               AS ship_to_locat_code
              ,NULL                               AS ship_to_locat_name
              ,xc.party_number                    AS freight_carrier_code
              ,xc.party_name                      AS freight_carrier_name
              ,xps.party_site_number              AS deliver_to
              ,xps.party_site_full_name           AS deliver_to_name
              ,xoha.schedule_ship_date            AS schedule_ship_date
              ,xoha.schedule_arrival_date         AS schedule_arrival_date
              ,xlv.lookup_code                    AS shipping_method_code
              ,CASE
                 WHEN xoha.weight_capacity_class  = gc_wc_class_j
                 --AND  xlv.attribute6              = gc_small_method_y THEN xoha.sum_weight      -- 2008/08/12 Del
                 AND  xlv.attribute6              = gc_small_method_y THEN NVL(xoha.sum_weight,0) -- 2008/08/12 Add
                 WHEN xoha.weight_capacity_class  = gc_wc_class_j
-- M.Hokkanji Ver1.2 START
                 AND  NVL(xlv.attribute6,gc_small_method_n) <> gc_small_method_y THEN NVL(xoha.sum_weight,0)
                                                                                   + NVL(xoha.sum_pallet_weight,0)
--                 AND  xlv.attribute6             <> gc_small_method_y THEN xoha.sum_weight
--                                                                         + xoha.sum_pallet_weight
-- M.Hokkanji Ver1.2 END

                 --WHEN xoha.weight_capacity_class  = gc_wc_class_y     THEN xoha.sum_capacity      -- 2008/08/12 Del
                 WHEN xoha.weight_capacity_class  = gc_wc_class_y     THEN NVL(xoha.sum_capacity,0) -- 2008/08/12 Add
               END                                AS weight
              ,xoha.mixed_no                      AS mixed_no
              ,xoha.collected_pallet_qty          AS collected_pallet_qty
              ,CASE xoha.freight_charge_class
                 WHEN gc_freight_class_y THEN gc_freight_class_ins_y
                 ELSE                         gc_freight_class_ins_n
               END                                AS freight_charge_class
              ,NVL( xoha.arrival_time_from, gc_time_default ) AS arrival_time_from
              ,NVL( xoha.arrival_time_to  , gc_time_default ) AS arrival_time_to
              ,xoha.cust_po_number                AS cust_po_number
              ,xoha.shipping_instructions         AS description
              ,xoha.pallet_sum_quantity           AS pallet_quantity_o
              ,NULL                               AS pallet_quantity_i
              ,xoha.instruction_dept              AS report_dept
              ,xim.item_no                        AS item_code
              ,xim.item_id                        AS item_id
              ,xim.item_name                      AS item_name
              ,xim.item_um                        AS item_uom_code
              ,xim.conv_unit                      AS conv_unit
              ,xola.quantity                      AS item_quantity
              ,xim.num_of_cases                   AS num_of_cases
              ,xim.lot_ctl                        AS lot_ctl
              ,CASE xola.delete_flag
                 WHEN gc_yes_no_y THEN gc_delete_flag_y
                 ELSE                  gc_delete_flag_n
               END                                AS line_delete_flag
              ,imld.mov_lot_dtl_id                AS mov_lot_dtl_id
-- ##### 20080619 1.5 ST�s�#193 START #####
              ,NULL                                 AS out_whse_inout_div   -- ���O�q�ɋ敪�F�o
              ,NULL                                 AS in_whse_inout_div    -- ���O�q�ɋ敪�F��
-- ##### 20080619 1.5 ST�s�#193 END   #####
-- 2008/07/22 Start
              ,CASE xottv.transaction_type_name
                 WHEN gv_prof_type_plan THEN gc_takeback_class       --����
                 ELSE                  gc_small_class                --����
               END                                AS reserve1        -- ����/����敪�i�\���P�j
-- 2008/07/22 END
        FROM xxwsh_order_headers_all    xoha      -- �󒍃w�b�_�A�h�I��
            ,xxwsh_order_lines_all      xola      -- �󒍖��׃A�h�I��
            -- 2008/07/22 Start
            --,oe_transaction_types_all   otta      -- �󒍃^�C�v
            ,xxwsh_oe_transaction_types2_v   xottv      -- �󒍃^�C�v���View�Q
            -- 2008/07/22 End
            ,xxcmn_item_locations_v     xil       -- OPM�ۊǏꏊ���VIEW
            ,xxcmn_carriers2_v          xc        -- �^���Ǝҏ��VIEW2
            ,xxcmn_party_sites2_v       xps       -- �p�[�e�B�T�C�g���VIEW2�i�z����j
            ,xxcmn_parties2_v           xp        -- �p�[�e�B���VIEW2�i���_�j
            ,xxwsh_carriers_schedule    xcs       -- �z�Ԕz���v��A�h�I��
-- M.HOKKANJI Ver1.2 START
--            ,xxcmn_lookup_values_v      xlv       -- �N�C�b�N�R�[�h���VIEW
            ,xxcmn_lookup_values2_v     xlv       -- �N�C�b�N�R�[�h���VIEW2
-- M.HOKKANJI Ver1.2 END
            ,xxcmn_item_mst2_v          xim       -- OPM�i�ڏ��VIEW2
            ,xxinv_mov_lot_details      imld      -- �ړ����b�g�ڍ�
        WHERE
        --------------------------------------------------------------------------------------------
        -- �i��
              gd_effective_date       BETWEEN xim.start_date_active
                                      AND     NVL( xim.end_date_active, gd_effective_date )
        AND   xola.shipping_item_code = xim.item_no
        -------------------------------------------------------------------------------------------
        -- �󒍖���
        AND   xoha.order_header_id = xola.order_header_id
        -------------------------------------------------------------------------------------------
        -- �z���z�Ԍv��
-- M.HOKKANJI Ver1.2 START
/*
        AND   xlv.lookup_type   = gc_lookup_ship_method
        AND   xcs.delivery_type = xlv.lookup_code
        AND   xoha.delivery_no  = xcs.delivery_no
*/
        AND   gd_effective_date BETWEEN xlv.start_date_active(+)
                                AND     NVL( xlv.end_date_active(+), gd_effective_date )
        AND   xlv.enabled_flag(+)  = gc_yes_no_y
        AND   xlv.lookup_type(+)   = gc_lookup_ship_method
        AND   xcs.delivery_type    = xlv.lookup_code(+)
        AND   xoha.delivery_no     = xcs.delivery_no(+)
-- M.HOKKANJI Ver1.2 END
        -------------------------------------------------------------------------------------------
        -- �z����
        AND   gd_effective_date  BETWEEN xp.start_date_active
                                 AND     NVL( xp.end_date_active, gd_effective_date )
        AND   xps.base_code      = xp.party_number
        AND   gd_effective_date  BETWEEN xps.start_date_active
                                 AND     NVL( xps.end_date_active, gd_effective_date )
        AND   xoha.deliver_to_id = xps.party_site_id
        -------------------------------------------------------------------------------------------
        -- �^���Ǝ�
-- M.HOKKANJI Ver1.2 START
--        AND   gd_effective_date BETWEEN xc.start_date_active
--                                AND     NVL( xc.end_date_active, gd_effective_date )
--        AND   xoha.career_id    = xc.party_id
        AND   gd_effective_date BETWEEN xc.start_date_active(+)
                                AND     NVL( xc.end_date_active(+), gd_effective_date )
        AND   xoha.career_id    = xc.party_id(+)
-- M.HOKKANJI Ver1.2 END
        -------------------------------------------------------------------------------------------
        -- �ۊǏꏊ
        AND   xil.whse_inside_outside_div = gc_whse_io_div_i            -- �����q��
        AND   xoha.deliver_from_id        = xil.inventory_location_id
        -------------------------------------------------------------------------------------------
        -- �󒍃^�C�v
        -- 2008/07/22 Start
        --AND   otta.attribute1    = gc_sp_class_ship                     -- �o�׈˗�
        --AND   xoha.order_type_id = otta.transaction_type_id
        AND   xottv.shipping_shikyu_class  = gc_sp_class_ship                     -- �o�׈˗�
        AND   xoha.order_type_id = xottv.transaction_type_id
        -- 2008/07/22 End
        -------------------------------------------------------------------------------------------
        -- �󒍃w�b�_�A�h�I��
        AND   NOT EXISTS
                ( SELECT 1
                  FROM xxwsh_order_lines_all      xola_w  -- �󒍖��׃A�h�I��
                      ,xxcmn_item_mst2_v          xim_w   -- OPM�i�ڏ��VIEW2
                      ,xxcmn_item_categories4_v   xic_w   -- OPM�i�ڃJ�e�S������VIEW4
                  WHERE xola_w.order_header_id = xoha.order_header_id
                  AND   xim_w.item_no          = xola_w.shipping_item_code
                  AND   gd_effective_date      BETWEEN xim_w.start_date_active
                                               AND     NVL( xim_w.end_date_active
                                                           ,gd_effective_date )
                  AND   xic_w.item_id          = xim_w.item_id
                  AND   xic_w.prod_class_code  = gc_prod_class_r
                  AND   xic_w.item_class_code <> gc_item_class_i  -- ���i�ȊO
                )
        AND   (
                (   xoha.notif_status          = gc_notif_status_c      -- �m��ʒm��
                AND xoha.prev_notif_status     = gc_notif_status_n      -- ���ʒm
                AND NOT EXISTS
                      ( SELECT 1
                        FROM xxwsh_hht_delivery_info  xhdi
                        WHERE xhdi.request_no = xoha.request_no )
                )
              OR
                (   xoha.notif_status          = gc_notif_status_c      -- �m��ʒm��
                AND xoha.prev_notif_status     = gc_notif_status_r   )  -- �Ēʒm�v
              )
        AND   xoha.req_status                  = gc_req_status_syu_3    -- ���ߍ�
        AND   xoha.notif_date           BETWEEN gd_date_from AND gd_date_to
        AND   xoha.latest_external_flag = gc_yes_no_y             -- �ŐV
        AND   xoha.prod_class           = gc_prod_class_r         -- ���[�t
        -- 2008/08/11 Start �w�������̒��o����SQL�̕s��Ή� -----------------------------------------------
        --AND   ((xoha.instruction_dept   = gr_param.dept_code_01)  -- �w������
        -- OR   ((gr_param.dept_code_02 IS NULL) OR (xoha.instruction_dept = gr_param.dept_code_02))
        -- OR   ((gr_param.dept_code_03 IS NULL) OR (xoha.instruction_dept = gr_param.dept_code_03))
        -- OR   ((gr_param.dept_code_04 IS NULL) OR (xoha.instruction_dept = gr_param.dept_code_04))
        -- OR   ((gr_param.dept_code_05 IS NULL) OR (xoha.instruction_dept = gr_param.dept_code_05))
        -- OR   ((gr_param.dept_code_06 IS NULL) OR (xoha.instruction_dept = gr_param.dept_code_06))
        -- OR   ((gr_param.dept_code_07 IS NULL) OR (xoha.instruction_dept = gr_param.dept_code_07))
        -- OR   ((gr_param.dept_code_08 IS NULL) OR (xoha.instruction_dept = gr_param.dept_code_08))
        -- OR   ((gr_param.dept_code_09 IS NULL) OR (xoha.instruction_dept = gr_param.dept_code_09))
        -- OR   ((gr_param.dept_code_10 IS NULL) OR (xoha.instruction_dept = gr_param.dept_code_10)))
        AND xoha.instruction_dept IN (gr_param.dept_code_01,   -- 01�͕K�{����
                                      gr_param.dept_code_02,   -- 02�`10�͔C�ӓ���
                                      gr_param.dept_code_03,
                                      gr_param.dept_code_04,
                                      gr_param.dept_code_05,
                                      gr_param.dept_code_06,
                                      gr_param.dept_code_07,
                                      gr_param.dept_code_08,
                                      gr_param.dept_code_09,
                                      gr_param.dept_code_10)
        -- 2008/08/11 End �w�������̒��o����SQL�̕s��Ή� -----------------------------------------------
        AND   xola.order_line_id        = imld.mov_line_id (+)    -- ���b�g�ڍ�ID
-- ##### 20080704 Ver.1.7 ST��QNo193 2��� START #####
        AND   gc_doc_type_ship          = imld.document_type_code (+)   -- �����^�C�v
-- ##### 20080704 Ver.1.7 ST��QNo193 2��� END   #####
        UNION ALL
        -- ========================================================================================
        -- �ړ��f�[�^�r�p�k
        -- ========================================================================================
        SELECT xmril.line_number                  AS line_number
              ,xmril.mov_line_id                  AS line_id
              ,xmrih.prev_notif_status            AS prev_notif_status
              ,gc_data_type_mov_ins               AS data_type
              ,xmrih.delivery_no                  AS delivery_no
              ,xmrih.mov_num                      AS request_no
              ,NULL                               AS head_sales_branch
              ,NULL                               AS head_sales_branch_name
              ,xil1.segment1                      AS shipped_locat_code
              ,SUBSTRB( xil1.description, 1, 20 ) AS shipped_locat_name
              ,xil2.segment1                      AS ship_to_locat_code
              ,SUBSTRB( xil2.description, 1, 20 ) AS ship_to_locat_name
              ,xc.party_number                    AS freight_carrier_code
              ,xc.party_name                      AS freight_carrier_name
              ,NULL                               AS deliver_to
              ,NULL                               AS deliver_to_name
              ,xmrih.schedule_ship_date           AS schedule_ship_date
              ,xmrih.schedule_arrival_date        AS schedule_arrival_date
              ,xlv.lookup_code                    AS shipping_method_code
              ,CASE
-- M.Hokkanji Ver1.2 START
--                 WHEN xmrih.weight_capacity_class  = gc_wc_class_j
--                 AND  xlv.attribute6               = gc_wc_class_j THEN xmrih.sum_weight
--                 WHEN xmrih.weight_capacity_class  = gc_wc_class_j
--                 AND  xlv.attribute6              <> gc_wc_class_j THEN xmrih.sum_weight
--                                                                      + xmrih.sum_pallet_weight
                 WHEN xmrih.weight_capacity_class  = gc_wc_class_j
                 --AND  xlv.attribute6               = gc_small_method_y THEN xmrih.sum_weight      --2008/08/12 Del
                 AND  xlv.attribute6               = gc_small_method_y THEN NVL(xmrih.sum_weight,0) --2008/08/12 Add
                 WHEN xmrih.weight_capacity_class  = gc_wc_class_j
                 AND  NVL(xlv.attribute6,gc_small_method_n) <> gc_small_method_y THEN NVL(xmrih.sum_weight,0)
                                                                      + NVL(xmrih.sum_pallet_weight,0)
-- M.Hokkanji Ver1.2 END
                 --WHEN xmrih.weight_capacity_class  = gc_wc_class_y THEN xmrih.sum_capacity       --2008/08/12 Del
                 WHEN xmrih.weight_capacity_class  = gc_wc_class_y THEN NVL(xmrih.sum_capacity,0)  --2008/08/12 Add
               END                                AS weight
              ,NULL                               AS mixed_no
              ,xmrih.collected_pallet_qty         AS collected_pallet_qty
              ,CASE xmrih.freight_charge_class
                 WHEN gc_freight_class_y THEN gc_freight_class_ins_y
                 ELSE                         gc_freight_class_ins_n
               END                                AS freight_charge_class
              ,NVL( xmrih.arrival_time_from, gc_time_default ) AS arrival_time_from
              ,NVL( xmrih.arrival_time_to  , gc_time_default ) AS arrival_time_to
              ,NULL                               AS cust_po_number
              ,xmrih.description                  AS description
              ,xmrih.out_pallet_qty               AS pallet_quantity_o
              ,xmrih.in_pallet_qty                AS pallet_quantity_i
              ,xmrih.instruction_post_code        AS report_dept
              ,xim.item_no                        AS item_code
              ,xim.item_id                        AS item_id
              ,xim.item_name                      AS item_name
              ,xim.item_um                        AS item_uom_code
              ,NULL                               AS conv_unit
              ,xmril.instruct_qty                 AS item_quantity
              ,NULL                               AS num_of_cases
              ,xim.lot_ctl                        AS lot_ctl
              ,CASE xmril.delete_flg
                 WHEN  gc_yes_no_y THEN gc_delete_flag_y
                 ELSE                   gc_delete_flag_n
               END                                AS line_delete_flag
              ,imld.mov_lot_dtl_id                AS mov_lot_dtl_id
-- ##### 20080619 1.5 ST�s�#193 START #####
              ,xil1.whse_inside_outside_div       AS out_whse_inout_div   -- ���O�q�ɋ敪�F�o
              ,xil2.whse_inside_outside_div       AS in_whse_inout_div    -- ���O�q�ɋ敪�F��
-- ##### 20080619 1.5 ST�s�#193 END   #####
-- 2008/07/22 Start
              ,NULL                               AS reserve1        -- ����/����敪�i�\���P�j
-- 2008/07/22 END
        FROM xxinv_mov_req_instr_headers    xmrih     -- �ړ��˗��w���w�b�_�A�h�I��
            ,xxinv_mov_req_instr_lines      xmril     -- �ړ��˗��w�����׃A�h�I��
            ,xxcmn_item_locations_v         xil1      -- OPM�ۊǏꏊ���VIEW�i�z�����j
            ,xxcmn_item_locations_v         xil2      -- OPM�ۊǏꏊ���VIEW�i�z����j
            ,xxcmn_carriers2_v              xc        -- �^���Ǝҏ��VIEW2
            ,xxwsh_carriers_schedule        xcs       -- �z�Ԕz���v��A�h�I��
-- M.Hokkanji Ver1,2 START
--            ,xxcmn_lookup_values_v          xlv       -- �N�C�b�N�R�[�h���VIEW2
            ,xxcmn_lookup_values2_v         xlv       -- �N�C�b�N�R�[�h���VIEW2
-- M.Hokkanji Ver1,2 END
            ,xxcmn_item_mst2_v              xim       -- OPM�i�ڏ��VIEW2
            ,xxinv_mov_lot_details         imld       -- �ړ����b�g�ڍ�
        WHERE
        -------------------------------------------------------------------------------------------
        -- �i��
              gd_effective_date   BETWEEN xim.start_date_active
                                  AND     NVL( xim.end_date_active, gd_effective_date )
        AND   xmril.item_id       = xim.item_id
        -------------------------------------------------------------------------------------------
        -- �ړ��˗��w������
        AND   xmrih.mov_hdr_id = xmril.mov_hdr_id
        -------------------------------------------------------------------------------------------
        -- �z���z�Ԍv��
-- M.Hokkanji Ver1.2 START
--        AND   xlv.lookup_type   = gc_lookup_ship_method
--        AND   xcs.delivery_type = xlv.lookup_code
--        AND   xmrih.delivery_no = xcs.delivery_no
        AND   gd_effective_date BETWEEN xlv.start_date_active(+)
                              AND     NVL( xlv.end_date_active(+), gd_effective_date )
        AND   xlv.enabled_flag(+)  = gc_yes_no_y
        AND   xlv.lookup_type(+)   = gc_lookup_ship_method
        AND   xcs.delivery_type    = xlv.lookup_code(+)
        AND   xmrih.delivery_no    = xcs.delivery_no(+)
        -------------------------------------------------------------------------------------------
        -- �^���Ǝ�
--        AND   gd_effective_date BETWEEN xc.start_date_active
--                                AND     NVL( xc.end_date_active, gd_effective_date )
--        AND   xmrih.career_id   = xc.party_id
        AND   gd_effective_date BETWEEN xc.start_date_active(+)
                                AND     NVL( xc.end_date_active(+), gd_effective_date )
        AND   xmrih.career_id   = xc.party_id(+)
-- M.Hokkanji Ver1.2 END
--
        -------------------------------------------------------------------------------------------
        -- �ۊǏꏊ�i�z����j
        AND   xmrih.ship_to_locat_id = xil2.inventory_location_id
        -------------------------------------------------------------------------------------------
        -- �ۊǏꏊ�i�z�����j
        AND   xmrih.shipped_locat_id = xil1.inventory_location_id
        -------------------------------------------------------------------------------------------
-- ##### 20080619 1.5 ST�s�#193 START #####
        AND
        (
          (xil2.whse_inside_outside_div = gc_whse_io_div_i)
          OR
          (xil1.whse_inside_outside_div = gc_whse_io_div_i)
        )
-- ##### 20080619 1.5 ST�s�#193 END   #####
        -------------------------------------------------------------------------------------------
--
        -- �ړ��˗��w���w�b�_
        AND   NOT EXISTS
                ( SELECT 1
                  FROM xxinv_mov_req_instr_lines  xmril_w   -- �󒍖��׃A�h�I��
                      ,xxcmn_item_mst2_v          xim_w     -- OPM�i�ڏ��VIEW2
                      ,xxcmn_item_categories4_v   xic_w     -- OPM�i�ڃJ�e�S������VIEW4
                  WHERE xmril_w.mov_hdr_id     = xmrih.mov_hdr_id
                  AND   xim_w.item_id          = xmril_w.item_id
                  AND   gd_effective_date      BETWEEN xim_w.start_date_active
                                               AND     NVL( xim_w.end_date_active
                                                           ,gd_effective_date )
                  AND   xic_w.item_id          = xim_w.item_id
                  AND   xic_w.prod_class_code  = gc_prod_class_r
                  AND   xic_w.item_class_code <> gc_item_class_i  -- ���i�ȊO
                )
        AND   (
                (   xmrih.notif_status        = gc_notif_status_c       -- �m��ʒm��
                AND xmrih.prev_notif_status   = gc_notif_status_n       -- ���ʒm
                AND NOT EXISTS
                      ( SELECT 1
                        FROM xxwsh_hht_delivery_info  xhdi
                        WHERE xhdi.request_no = xmrih.mov_num )
                )
              OR
                (   xmrih.notif_status        = gc_notif_status_c       -- �m��ʒm��
                AND xmrih.prev_notif_status   = gc_notif_status_r   )   -- �Ēʒm�v
              )
        AND   xmrih.status               IN( gc_mov_status_cmp      -- �˗���
                                            ,gc_mov_status_adj )    -- ������
        AND   xmrih.notif_date            BETWEEN gd_date_from AND gd_date_to
        AND   xmrih.mov_type              = gc_mov_type_y           -- �ϑ�����
        AND   xmrih.item_class            = gc_prod_class_r         -- ���[�t
-- M.Hokkanji Ver1.2 START
--        AND   xmrih.product_flg           = gc_yes_no_y             -- ���i����
        AND   xmrih.product_flg           = gc_product_flg_1        -- ���i����(���i)
-- M.Hokkanji Ver1.2 END
        -- 2008/08/11 Start �w�������̒��o����SQL�̕s��Ή� -------------------------------------
        --AND   ((xmrih.instruction_post_code = gr_param.dept_code_01) -- �w������
        -- OR   ((gr_param.dept_code_02 IS NULL)
        -- OR    (xmrih.instruction_post_code = gr_param.dept_code_02))
        -- OR   ((gr_param.dept_code_03 IS NULL)
        -- OR    (xmrih.instruction_post_code = gr_param.dept_code_03))
        -- OR   ((gr_param.dept_code_04 IS NULL)
        -- OR    (xmrih.instruction_post_code = gr_param.dept_code_04))
        -- OR   ((gr_param.dept_code_05 IS NULL)
        -- OR    (xmrih.instruction_post_code = gr_param.dept_code_05))
        -- OR   ((gr_param.dept_code_06 IS NULL)
        -- OR    (xmrih.instruction_post_code = gr_param.dept_code_06))
        -- OR   ((gr_param.dept_code_07 IS NULL)
        -- OR    (xmrih.instruction_post_code = gr_param.dept_code_07))
        -- OR   ((gr_param.dept_code_08 IS NULL)
        -- OR    (xmrih.instruction_post_code = gr_param.dept_code_08))
        -- OR   ((gr_param.dept_code_09 IS NULL)
        -- OR    (xmrih.instruction_post_code = gr_param.dept_code_09))
        -- OR   ((gr_param.dept_code_10 IS NULL)
        -- OR    (xmrih.instruction_post_code = gr_param.dept_code_10)))
        AND xmrih.instruction_post_code IN (gr_param.dept_code_01,  -- 01�͕K�{����
                                            gr_param.dept_code_02,  -- 02�`10�͔C�ӓ���
                                            gr_param.dept_code_03,
                                            gr_param.dept_code_04,
                                            gr_param.dept_code_05,
                                            gr_param.dept_code_06,
                                            gr_param.dept_code_07,
                                            gr_param.dept_code_08,
                                            gr_param.dept_code_09,
                                            gr_param.dept_code_10)
        -- 2008/08/11 End �w�������̒��o����SQL�̕s��Ή� -------------------------------------
        AND   xmril.mov_line_id           = imld.mov_line_id (+)    -- ���b�g�ڍ�ID
-- ##### 20080704 Ver.1.7 ST��QNo193 2��� START #####
        AND   gc_doc_type_move            = imld.document_type_code (+) -- �����^�C�v
-- ##### 20080704 Ver.1.7 ST��QNo193 2��� END   #####
        ) main
    ;
--
    -- ==================================================
    -- ��O�錾
    -- ==================================================
    ex_no_data        EXCEPTION ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    OPEN cu_main ;
    FETCH cu_main BULK COLLECT INTO gt_main_data ;
    CLOSE cu_main ;
--
    IF ( gt_main_data.COUNT = 0 ) THEN
      RAISE ex_no_data ;
    END IF ;
--
  EXCEPTION
    -- ============================================================================================
    -- �Ώۃf�[�^�Ȃ�
    -- ============================================================================================
    WHEN ex_no_data THEN
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_appl_sname_wsh
                     ,iv_name           => lc_msg_code
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_warn ;
--
--##### �Œ��O������ START ######################################################################
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF cu_main%ISOPEN THEN
        CLOSE cu_main ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF cu_main%ISOPEN THEN
        CLOSE cu_main ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF cu_main%ISOPEN THEN
        CLOSE cu_main ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   ######################################################################
  END prc_get_main_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_cre_head_data
   * Description      : �w�b�_�f�[�^�쐬
   ***********************************************************************************************/
  PROCEDURE prc_cre_head_data
    (
      ir_main_data            IN  rec_main_data
     ,iv_data_class           IN  xxwsh_hht_stock_deliv_info_tmp.data_class%TYPE
     ,iv_pallet_sum_quantity  IN  xxwsh_hht_stock_deliv_info_tmp.pallet_sum_quantity%TYPE
     ,ov_errbuf               OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode              OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg               OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_cre_head_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
-- M.Hokkanji Ver 1.2 START
    lc_transfer_branch_no_h CONSTANT VARCHAR2(100) := '10' ;    -- �w�b�_
-- M.Hokkanji Ver 1.2 END
--
--
  BEGIN
    -- ==================================================
    -- �z��C���f�b�N�X�ҏW
    -- ==================================================
    gn_cre_idx := gn_cre_idx + 1 ;
--
    -- ==================================================
    -- ���ڕҏW����
    -- ==================================================
    gt_corporation_name(gn_cre_idx)       := gc_corporation_name ;                -- ��Ж�
    gt_data_class(gn_cre_idx)             := iv_data_class ;                      -- �f�[�^���
-- M.Hokkanji Ver 1.2 START
--    gt_transfer_branch_no(gn_cre_idx)     := '10' ;                               -- �`���p�}��
    gt_transfer_branch_no(gn_cre_idx)     := lc_transfer_branch_no_h ;            -- �`���p�}��
-- M.Hokkanji Ver 1.2 END
    gt_delivery_no(gn_cre_idx)            := ir_main_data.delivery_no ;           -- �z��No
    gt_requesgt_no(gn_cre_idx)            := ir_main_data.request_no ;            -- �˗�No
    gt_reserve(gn_cre_idx)                := gc_reserve ;                         -- �\��
    gt_head_sales_branch(gn_cre_idx)      := ir_main_data.head_sales_branch ;     -- ���_�R�[�h
    gt_head_sales_branch_name(gn_cre_idx) := ir_main_data.head_sales_branch_name ;-- �Ǌ����_����
    gt_shipped_locat_code(gn_cre_idx)     := ir_main_data.shipped_locat_code ;    -- �o�ɑq�ɃR�[�h
    gt_shipped_locat_name(gn_cre_idx)     := ir_main_data.shipped_locat_name ;    -- �o�ɑq�ɖ���
    gt_ship_to_locat_code(gn_cre_idx)     := ir_main_data.ship_to_locat_code ;    -- ���ɑq�ɃR�[�h
    gt_ship_to_locat_name(gn_cre_idx)     := ir_main_data.ship_to_locat_name ;    -- ���ɑq�ɖ���
    gt_freight_carrier_code(gn_cre_idx)   := ir_main_data.freight_carrier_code ;  -- �^���Ǝ҃R�[�h
    gt_freight_carrier_name(gn_cre_idx)   := ir_main_data.freight_carrier_name ;  -- �^���ƎҖ�
    gt_deliver_to(gn_cre_idx)             := ir_main_data.deliver_to ;            -- �z����R�[�h
    gt_deliver_to_name(gn_cre_idx)        := ir_main_data.deliver_to_name ;       -- �z���於
    gt_schedule_ship_date(gn_cre_idx)     := ir_main_data.schedule_ship_date ;    -- ����
    gt_schedule_arrival_date(gn_cre_idx)  := ir_main_data.schedule_arrival_date ; -- ����
    gt_shipping_method_code(gn_cre_idx)   := ir_main_data.shipping_method_code ;  -- �z���敪
    gt_weight(gn_cre_idx)                 := ir_main_data.weight ;                -- �d��/�e��
    gt_mixed_no(gn_cre_idx)               := ir_main_data.mixed_no ;              -- ���ڌ��˗���
    gt_collected_pallet_qty(gn_cre_idx)   := ir_main_data.collected_pallet_qty ;  -- ��گĉ������
    gt_arrival_time_from(gn_cre_idx)      := ir_main_data.arrival_time_from ;     -- ���׎���FROM
    gt_arrival_time_to(gn_cre_idx)        := ir_main_data.arrival_time_to ;       -- ���׎���TO
    gt_cust_po_number(gn_cre_idx)         := ir_main_data.cust_po_number ;        -- �ڋq�����ԍ�
    gt_description(gn_cre_idx)            := ir_main_data.description ;           -- �E�v
    gt_status(gn_cre_idx)                 := '02' ;                               -- �X�e�[�^�X
    gt_freight_charge_class(gn_cre_idx)   := ir_main_data.freight_charge_class ;  -- �^���敪
    gt_pallet_sum_quantity(gn_cre_idx)    := iv_pallet_sum_quantity ;             -- ��گĎg�p����
    -- 2008/07/22 Start
    --gt_reserve1(gn_cre_idx)               := NULL ;                               -- �\���P
    gt_reserve1(gn_cre_idx)               := ir_main_data.reserve1;                 -- ����/����敪�i�\���P�j
    -- 2008/07/22 End
    gt_reserve2(gn_cre_idx)               := NULL ;                               -- �\���Q
    gt_reserve3(gn_cre_idx)               := NULL ;                               -- �\���R
    gt_reserve4(gn_cre_idx)               := NULL ;                               -- �\���S
    gt_report_dept(gn_cre_idx)            := ir_main_data.report_dept ;           -- �񍐕���
    gt_item_code(gn_cre_idx)              := NULL ;                               -- �i�ڃR�[�h
    gt_item_name(gn_cre_idx)              := NULL ;                               -- �i�ږ�
    gt_item_uom_code(gn_cre_idx)          := NULL ;                               -- �i�ڒP��
    gt_item_quantity(gn_cre_idx)          := NULL ;                               -- �i�ڐ���
    gt_lot_no(gn_cre_idx)                 := NULL ;                               -- ���b�g�ԍ�
    gt_lot_date(gn_cre_idx)               := NULL ;                               -- ������
    gt_lot_sign(gn_cre_idx)               := NULL ;                               -- �ŗL�L��
    gt_best_bfr_date(gn_cre_idx)          := NULL ;                               -- �ܖ�����
    gt_lot_quantity(gn_cre_idx)           := NULL ;                               -- ���b�g����
-- M.Hokkanji Ver1.2 START
--    gt_new_modify_del_class(gn_cre_idx)   := '0' ;                                -- �f�[�^�敪
    gt_new_modify_del_class(gn_cre_idx)   := gc_data_class_ins ;                  -- �f�[�^�敪
-- M.Hokkanji Ver1.2 END
    gt_update_date(gn_cre_idx)            := SYSDATE ;                            -- �X�V����
    gt_line_number(gn_cre_idx)            := NULL ;                               -- ���הԍ�
    gt_data_type(gn_cre_idx)              := ir_main_data.data_type ;             -- �f�[�^�^�C�v
--
  EXCEPTION
--##### �Œ��O������ START ######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   ######################################################################
  END prc_cre_head_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_cre_dtl_data
   * Description      : ���׃f�[�^�쐬
   ***********************************************************************************************/
  PROCEDURE prc_cre_dtl_data
    (
      ir_main_data            IN  rec_main_data
     ,iv_data_class           IN  xxwsh_stock_delivery_info_tmp.data_class%TYPE
     ,iv_item_uom_code        IN  xxwsh_stock_delivery_info_tmp.item_uom_code%TYPE
     ,iv_item_quantity        IN  xxwsh_stock_delivery_info_tmp.item_quantity%TYPE
     ,ov_errbuf               OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode              OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg               OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_cre_dtl_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    lv_doc_type             xxinv_mov_lot_details.document_type_code%TYPE ;
-- M.Hokkanji Ver1.2 START
    lc_transfer_branch_no_d CONSTANT VARCHAR2(100) := '20' ;    -- ����
-- M.Hokkanji Ver1.2 END
--
  BEGIN
    -- ==================================================
    -- �z��C���f�b�N�X�ҏW
    -- ==================================================
    gn_cre_idx := gn_cre_idx + 1 ;
--
    -- ==================================================
    -- ���ڕҏW����
    -- ==================================================
    gt_corporation_name(gn_cre_idx)       := gc_corporation_name ;      -- ��Ж�
    gt_data_class(gn_cre_idx)             := iv_data_class ;            -- �f�[�^���
-- M.Hokkanji Ver1.2 START
--    gt_transfer_branch_no(gn_cre_idx)     := '20' ;                     -- �`���p�}��
    gt_transfer_branch_no(gn_cre_idx)     := lc_transfer_branch_no_d ;  -- �`���p�}��
-- M.Hokkanji Ver1.2 END
    gt_delivery_no(gn_cre_idx)            := ir_main_data.delivery_no ; -- �z��No
    gt_requesgt_no(gn_cre_idx)            := ir_main_data.request_no ;  -- �˗�No
-- M.Hokkanji Ver1.4 START
--    gt_reserve(gn_cre_idx)                := gc_reserve ;               -- �\��
    gt_reserve(gn_cre_idx)                := NULL ;                     -- �\��
-- M.Hokkanji Ver1.4 END
    gt_head_sales_branch(gn_cre_idx)      := NULL ;                     -- ���_�R�[�h
    gt_head_sales_branch_name(gn_cre_idx) := NULL ;                     -- �Ǌ����_����
    gt_shipped_locat_code(gn_cre_idx)     := NULL ;                     -- �o�ɑq�ɃR�[�h
    gt_shipped_locat_name(gn_cre_idx)     := NULL ;                     -- �o�ɑq�ɖ���
    gt_ship_to_locat_code(gn_cre_idx)     := NULL ;                     -- ���ɑq�ɃR�[�h
    gt_ship_to_locat_name(gn_cre_idx)     := NULL ;                     -- ���ɑq�ɖ���
    gt_freight_carrier_code(gn_cre_idx)   := NULL ;                     -- �^���Ǝ҃R�[�h
    gt_freight_carrier_name(gn_cre_idx)   := NULL ;                     -- �^���ƎҖ�
    gt_deliver_to(gn_cre_idx)             := NULL ;                     -- �z����R�[�h
    gt_deliver_to_name(gn_cre_idx)        := NULL ;                     -- �z���於
    gt_schedule_ship_date(gn_cre_idx)     := NULL ;                     -- ����
    gt_schedule_arrival_date(gn_cre_idx)  := NULL ;                     -- ����
    gt_shipping_method_code(gn_cre_idx)   := NULL ;                     -- �z���敪
    gt_weight(gn_cre_idx)                 := NULL ;                     -- �d��/�e��
    gt_mixed_no(gn_cre_idx)               := NULL ;                     -- ���ڌ��˗���
    gt_collected_pallet_qty(gn_cre_idx)   := NULL ;                     -- ��گĉ������
    gt_arrival_time_from(gn_cre_idx)      := NULL ;                     -- ���׎��Ԏw��(FROM)
    gt_arrival_time_to(gn_cre_idx)        := NULL ;                     -- ���׎��Ԏw��(TO)
    gt_cust_po_number(gn_cre_idx)         := NULL ;                     -- �ڋq�����ԍ�
    gt_description(gn_cre_idx)            := NULL ;                     -- �E�v
    gt_status(gn_cre_idx)                 := NULL ;                     -- �X�e�[�^�X
    gt_freight_charge_class(gn_cre_idx)   := NULL ;                     -- �^���敪
    gt_pallet_sum_quantity(gn_cre_idx)    := NULL ;                     -- ��گĎg�p����
    gt_reserve1(gn_cre_idx)               := NULL ;                     -- �\���P
    gt_reserve2(gn_cre_idx)               := NULL ;                     -- �\���Q
    gt_reserve3(gn_cre_idx)               := NULL ;                     -- �\���R
    gt_reserve4(gn_cre_idx)               := NULL ;                     -- �\���S
    gt_report_dept(gn_cre_idx)            := NULL ;                     -- �񍐕���
    gt_item_code(gn_cre_idx)              := ir_main_data.item_code ;   -- �i�ڃR�[�h
    gt_item_name(gn_cre_idx)              := ir_main_data.item_name ;   -- �i�ږ�
    gt_item_uom_code(gn_cre_idx)          := iv_item_uom_code ;         -- �i�ڒP��
    gt_item_quantity(gn_cre_idx)          := iv_item_quantity ;         -- �i�ڐ���
    gt_lot_no(gn_cre_idx)                 := NULL ;                     -- ���b�g�ԍ�
    gt_lot_date(gn_cre_idx)               := NULL ;                     -- ������
    gt_lot_sign(gn_cre_idx)               := NULL ;                     -- �ŗL�L��
    gt_best_bfr_date(gn_cre_idx)          := NULL ;                     -- �ܖ�����
    gt_lot_quantity(gn_cre_idx)           := NULL ;                     -- ���b�g����
-- M.Hokkanji Ver1.2 START
--    gt_new_modify_del_class(gn_cre_idx)   := '0' ;                      -- �f�[�^�敪
    gt_new_modify_del_class(gn_cre_idx)   := gc_data_class_ins ;        -- �f�[�^�敪
-- M.Hokkanji Ver1.2 END
    gt_update_date(gn_cre_idx)            := SYSDATE ;                  -- �X�V����
    gt_line_number(gn_cre_idx)            := ir_main_data.line_number ; -- ���הԍ�
    gt_data_type(gn_cre_idx)              := ir_main_data.data_type ;   -- �f�[�^�^�C�v
--
    -------------------------------------------------------
    -- ���b�g�Ǘ��i�̏ꍇ
    -------------------------------------------------------
    IF ( ir_main_data.lot_ctl = gc_lot_ctl_y ) THEN
      -- �o�׃f�[�^�̏ꍇ
      IF ( iv_data_class = gc_data_class_syu_s ) THEN
        lv_doc_type := gc_doc_type_ship ;
--
      -- �ړ��f�[�^�̏ꍇ
      ELSE
        lv_doc_type := gc_doc_type_move ;
--
      END IF ;
--
      -- ���b�g��񒊏o
      BEGIN
        SELECT ilm.lot_no
              ,FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )
              ,FND_DATE.CANONICAL_TO_DATE( ilm.attribute3 )
              ,ilm.attribute2
              ,xmld.actual_quantity
        INTO   gt_lot_no(gn_cre_idx)           -- ���b�g�ԍ�
              ,gt_lot_date(gn_cre_idx)         -- ������
              ,gt_best_bfr_date(gn_cre_idx)    -- �ܖ�����
              ,gt_lot_sign(gn_cre_idx)         -- �ŗL�L��
              ,gt_lot_quantity(gn_cre_idx)     -- ���b�g����
        FROM xxinv_mov_lot_details    xmld    -- �ړ����b�g�ڍ׃A�h�I��
            ,ic_lots_mst              ilm     -- �n�o�l���b�g�}�X�^
        WHERE ilm.inactive_ind  = gc_inactive_ind_y   -- 0�F�L��
        AND   ilm.delete_mark   = gc_delete_mark_y    -- 0�F���폜
        AND   xmld.lot_id       = ilm.lot_id
        AND   xmld.document_type_code = lv_doc_type
        AND   xmld.record_type_code   = gc_rec_type_inst    -- 10�F�w��
        AND   xmld.item_id            = ir_main_data.item_id
        AND   xmld.mov_line_id        = ir_main_data.line_id
        AND   xmld.mov_lot_dtl_id     = ir_main_data.mov_lot_dtl_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gt_lot_no(gn_cre_idx)        := NULL ;     -- ���b�g�ԍ�
          gt_lot_date(gn_cre_idx)      := NULL ;     -- ������
          gt_best_bfr_date(gn_cre_idx) := NULL ;     -- �ܖ�����
          gt_lot_sign(gn_cre_idx)      := NULL ;     -- �ŗL�L��
          gt_lot_quantity(gn_cre_idx)  := NULL ;     -- ���b�g����
      END ;
--
-- ##### 20080627 Ver.1.6 ���b�g���ʊ��Z�Ή� START #####
      -------------------------------------------------------
      -- ���b�g���ʊ��Z
      -------------------------------------------------------
    -- �o�ׂ̏ꍇ
    IF ( ir_main_data.data_type = gc_data_type_syu_ins ) THEN
--
        -- ���o�Ɋ��Z�P�ʁ�NULL�̏ꍇ
        IF (ir_main_data.conv_unit IS NOT NULL) THEN
          -- ���b�g���� �� �P�[�X���萔
          gt_lot_quantity(gn_cre_idx) := gt_lot_quantity(gn_cre_idx)
                                           / ir_main_data.num_of_cases ;
--2008/08/08 Mod ��
--          gt_lot_quantity(gn_cre_idx) := TRUNC( gt_lot_quantity(gn_cre_idx), 3 ) ;
--2008/08/08 Mod ��
        END IF ;
    END IF ;
-- ##### 20080627 Ver.1.6 ���b�g���ʊ��Z�Ή� END   #####
--
    END IF ;
--
  EXCEPTION
--##### �Œ��O������ START ######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   ######################################################################
  END prc_cre_dtl_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_ins_data
   * Description      : �ʒm�Ϗ��쐬����(F-05)
   ***********************************************************************************************/
  PROCEDURE prc_create_ins_data
    (
      in_idx          IN  NUMBER            -- �Ώۃf�[�^�z��C���f�b�N�X
     ,iv_break_flg    IN  VARCHAR2          -- �˗��m���u���C�N�t���O
     ,ov_errbuf       OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode      OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg       OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_ins_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_msg_code_case        CONSTANT VARCHAR2(50) := 'APP-XXWSH-11904' ;
    lc_tok_name_case        CONSTANT VARCHAR2(50) := 'ITEM_ID' ;
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    lv_pallet_sum_quantity  xxwsh_stock_delivery_info_tmp.pallet_sum_quantity%TYPE ;
    lv_item_uom_code        xxwsh_stock_delivery_info_tmp.item_uom_code%TYPE ;
    lv_item_quantity        xxwsh_stock_delivery_info_tmp.item_quantity%TYPE ;
--
    lv_tok_val              VARCHAR2(50) ;
--
    -- ==================================================
    -- ��O�錾
    -- ==================================================
    ex_case_quant_error     EXCEPTION ;   -- �P�[�X���萔�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ============================================================================================
    -- �G���[�n���h�����O
    -- ============================================================================================
    -------------------------------------------------------
    -- �P�[�X���萔�`�F�b�N
    -------------------------------------------------------
    -- �o�ׂ̏ꍇ�ŁA���o�Ɋ��Z�P�ʂ̐ݒ肪����ꍇ
    IF (   ( gt_main_data(in_idx).data_type = gc_data_type_syu_ins )
       AND ( gt_main_data(in_idx).conv_unit IS NOT NULL            ) ) THEN
      -- �P�[�X���萔�̒l���Ȃ��ꍇ
      IF ( NVL( gt_main_data(in_idx).num_of_cases, 0 ) = 0 ) THEN
        lv_tok_val := gt_main_data(in_idx).item_code ;
        RAISE ex_case_quant_error ;
      END IF ;
    END IF ;
--
    -- ============================================================================================
    -- �f�[�^�^�C�v�F�o��
    -- ============================================================================================
    IF ( gt_main_data(in_idx).data_type = gc_data_type_syu_ins ) THEN
      -------------------------------------------------------
      -- �ύ��ڕҏW
      -------------------------------------------------------
      -- �p���b�g�g�p����
      lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_quantity_o ;
--
      -- �i�ڒP��
      lv_item_uom_code := NVL( gt_main_data(in_idx).conv_unit
                              ,gt_main_data(in_idx).item_uom_code ) ;
      -- �i�ڐ���
      IF gt_main_data(in_idx).conv_unit IS NULL THEN
        lv_item_quantity := gt_main_data(in_idx).item_quantity ;
      ELSE
        lv_item_quantity := gt_main_data(in_idx).item_quantity
                          / gt_main_data(in_idx).num_of_cases ;
--2008/08/08 Mod ��
--        lv_item_quantity := TRUNC( lv_item_quantity, 3 ) ;
--2008/08/08 Mod ��
      END IF ;
--
      -------------------------------------------------------
      -- �w�b�_�f�[�^�̍쐬
      -------------------------------------------------------
      IF ( iv_break_flg = gc_yes_no_y ) THEN
        prc_cre_head_data
          (
            ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
           ,iv_data_class           => gc_data_class_syu_s      -- �f�[�^���
           ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- �p���b�g�g�p����
           ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
           ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
           ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_api_expt;
        END IF ;
      END IF ;
      -------------------------------------------------------
      -- ���׃f�[�^�̍쐬
      -------------------------------------------------------
      prc_cre_dtl_data
        (
          ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
         ,iv_data_class           => gc_data_class_syu_s      -- �f�[�^���
         ,iv_item_uom_code        => lv_item_uom_code         -- �i�ڒP��
         ,iv_item_quantity        => lv_item_quantity         -- �i�ڐ���
         ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
         ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
         ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF ;
--
    -- ============================================================================================
    -- �f�[�^�^�C�v�F�ړ�
    -- ============================================================================================
    ELSIF ( gt_main_data(in_idx).data_type = gc_data_type_mov_ins ) THEN
      -------------------------------------------------------
      -- �ύ��ڕҏW
      -------------------------------------------------------
      lv_item_uom_code := gt_main_data(in_idx).item_uom_code  ;   -- �i�ڒP��
      lv_item_quantity := gt_main_data(in_idx).item_quantity  ;   -- �i�ڐ���
--
      -------------------------------------------------------
      -- �w�b�_�f�[�^�̍쐬
      -------------------------------------------------------
      IF ( iv_break_flg = gc_yes_no_y ) THEN
-- ##### 20080619 1.5 ST�s�#193 START #####
        -- ���O�q�ɋ敪�������q�ɂ̏ꍇ
        IF (gt_main_data(in_idx).out_whse_inout_div = gc_whse_io_div_i) THEN
-- ##### 20080619 1.5 ST�s�#193 END   #####
          -------------------------------------------------------
          -- �ړ��o�ɂ̍쐬
          -------------------------------------------------------
          lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_quantity_o ;
          prc_cre_head_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
             ,iv_data_class           => gc_data_class_mov_s      -- �f�[�^���
             ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- �p���b�g�g�p����
             ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
             ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
             ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
-- ##### 20080619 1.5 ST�s�#193 START #####
        END IF;
-- ##### 20080619 1.5 ST�s�#193 END   #####
--
-- ##### 20080619 1.5 ST�s�#193 START #####
        -- ���O�q�ɋ敪�������q�ɂ̏ꍇ
        IF (gt_main_data(in_idx).in_whse_inout_div = gc_whse_io_div_i) THEN
-- ##### 20080619 1.5 ST�s�#193 END   #####
          -------------------------------------------------------
          -- �ړ����ɂ̍쐬
          -------------------------------------------------------
          lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_quantity_i ;
          prc_cre_head_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
             ,iv_data_class           => gc_data_class_mov_n      -- �f�[�^���
             ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- �p���b�g�g�p����
             ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
             ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
             ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
-- ##### 20080619 1.5 ST�s�#193 START #####
        END IF;
-- ##### 20080619 1.5 ST�s�#193 END   #####
--
      END IF ;
--
-- ##### 20080619 1.5 ST�s�#193 START #####
      -- ���O�q�ɋ敪�������q�ɂ̏ꍇ
      IF (gt_main_data(in_idx).out_whse_inout_div = gc_whse_io_div_i) THEN
-- ##### 20080619 1.5 ST�s�#193 END   #####
        -------------------------------------------------------
        -- ���׃f�[�^�̍쐬�i�ړ��o�Ɂj
        -------------------------------------------------------
        prc_cre_dtl_data
          (
            ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
           ,iv_data_class           => gc_data_class_mov_s      -- �f�[�^���
           ,iv_item_uom_code        => lv_item_uom_code         -- �i�ڒP��
           ,iv_item_quantity        => lv_item_quantity         -- �i�ڐ���
           ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
           ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
           ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_api_expt;
        END IF ;
-- ##### 20080619 1.5 ST�s�#193 START #####
      END IF;
-- ##### 20080619 1.5 ST�s�#193 END   #####
--
-- ##### 20080619 1.5 ST�s�#193 START #####
        -- ���O�q�ɋ敪�������q�ɂ̏ꍇ
        IF (gt_main_data(in_idx).in_whse_inout_div = gc_whse_io_div_i) THEN
-- ##### 20080619 1.5 ST�s�#193 END   #####
      -------------------------------------------------------
      -- ���׃f�[�^�̍쐬�i�ړ����Ɂj
      -------------------------------------------------------
      prc_cre_dtl_data
        (
          ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
         ,iv_data_class           => gc_data_class_mov_n      -- �f�[�^���
         ,iv_item_uom_code        => lv_item_uom_code         -- �i�ڒP��
         ,iv_item_quantity        => lv_item_quantity         -- �i�ڐ���
         ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
         ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
         ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF ;
-- ##### 20080619 1.5 ST�s�#193 START #####
      END IF;
-- ##### 20080619 1.5 ST�s�#193 END   #####
--
    END IF ;
--
  EXCEPTION
    -- ============================================================================================
    -- �P�[�X���萔�G���[
    -- ============================================================================================
    WHEN ex_case_quant_error THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := xxcmn_common_pkg.get_msg
                      (
                        iv_application    => gc_appl_sname_wsh
                       ,iv_name           => lc_msg_code_case
                       ,iv_token_name1    => lc_tok_name_case
                       ,iv_token_value1   => lv_tok_val
                      ) ;
      ov_errmsg    := lv_errmsg ;
      ov_errbuf    := lv_errmsg ;
      ov_retcode   := gv_status_error ;
--##### �Œ��O������ START ######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   ######################################################################
  END prc_create_ins_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_can_data
   * Description      : �ύX�O������f�[�^�쐬����(F-06)
   ***********************************************************************************************/
  PROCEDURE prc_create_can_data
    (
      iv_request_no           IN  xxwsh_stock_delivery_info_tmp.request_no%TYPE
     ,ov_errbuf               OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode              OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg               OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_can_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �J�[�\���錾
    -- ==================================================
    CURSOR cu_can_data
      ( p_request_no  xxwsh_hht_delivery_info.request_no%TYPE )
    IS
      SELECT xhdi.corporation_name
            ,xhdi.data_class
            ,xhdi.transfer_branch_no
            ,xhdi.delivery_no
            ,xhdi.request_no
            ,xhdi.reserve
            ,xhdi.head_sales_branch
            ,xhdi.head_sales_branch_name
            ,xhdi.shipped_locat_code
            ,xhdi.shipped_locat_name
            ,xhdi.ship_to_locat_code
            ,xhdi.ship_to_locat_name
            ,xhdi.freight_carrier_code
            ,xhdi.freight_carrier_name
            ,xhdi.deliver_to
            ,xhdi.deliver_to_name
            ,xhdi.schedule_ship_date
            ,xhdi.schedule_arrival_date
            ,xhdi.shipping_method_code
            ,xhdi.weight
            ,xhdi.mixed_no
            ,xhdi.collected_pallet_qty
            ,xhdi.arrival_time_from
            ,xhdi.arrival_time_to
            ,xhdi.cust_po_number
            ,xhdi.description
            ,xhdi.status
            ,xhdi.freight_charge_class
            ,xhdi.pallet_sum_quantity
            ,xhdi.reserve1
            ,xhdi.reserve2
            ,xhdi.reserve3
            ,xhdi.reserve4
            ,xhdi.report_dept
            ,xhdi.item_code
            ,xhdi.item_name
            ,xhdi.item_uom_code
            ,xhdi.item_quantity
            ,xhdi.lot_no
            ,xhdi.lot_date
            ,xhdi.best_bfr_date
            ,xhdi.lot_sign
            ,xhdi.lot_quantity
            ,xhdi.new_modify_del_class
            ,xhdi.update_date
            ,xhdi.line_number
            ,xhdi.data_type
      FROM xxwsh_hht_delivery_info    xhdi
      WHERE xhdi.request_no = p_request_no
      ORDER BY xhdi.request_no                -- �˗�No
              ,xhdi.transfer_branch_no        -- �`���p�}��
              ,xhdi.line_number               -- ���הԍ�
    ;
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- ����f�[�^�쐬
    -- ====================================================
    <<can_data_loop>>
    FOR re_can_data IN cu_can_data
      ( p_request_no            => iv_request_no ) LOOP
--
      gn_cre_idx := gn_cre_idx + 1 ;
--
      gt_corporation_name(gn_cre_idx)       := re_can_data.corporation_name ;
      gt_data_class(gn_cre_idx)             := re_can_data.data_class ;
      gt_transfer_branch_no(gn_cre_idx)     := re_can_data.transfer_branch_no ;
      gt_delivery_no(gn_cre_idx)            := re_can_data.delivery_no ;
      gt_requesgt_no(gn_cre_idx)            := re_can_data.request_no ;
      gt_reserve(gn_cre_idx)                := re_can_data.reserve ;
      gt_head_sales_branch(gn_cre_idx)      := re_can_data.head_sales_branch ;
      gt_head_sales_branch_name(gn_cre_idx) := re_can_data.head_sales_branch_name ;
      gt_shipped_locat_code(gn_cre_idx)     := re_can_data.shipped_locat_code ;
      gt_shipped_locat_name(gn_cre_idx)     := re_can_data.shipped_locat_name ;
      gt_ship_to_locat_code(gn_cre_idx)     := re_can_data.ship_to_locat_code ;
      gt_ship_to_locat_name(gn_cre_idx)     := re_can_data.ship_to_locat_name ;
      gt_freight_carrier_code(gn_cre_idx)   := re_can_data.freight_carrier_code ;
      gt_freight_carrier_name(gn_cre_idx)   := re_can_data.freight_carrier_name ;
      gt_deliver_to(gn_cre_idx)             := re_can_data.deliver_to ;
      gt_deliver_to_name(gn_cre_idx)        := re_can_data.deliver_to_name ;
      gt_schedule_ship_date(gn_cre_idx)     := re_can_data.schedule_ship_date ;
      gt_schedule_arrival_date(gn_cre_idx)  := re_can_data.schedule_arrival_date ;
      gt_shipping_method_code(gn_cre_idx)   := re_can_data.shipping_method_code ;
      gt_weight(gn_cre_idx)                 := re_can_data.weight ;
      gt_mixed_no(gn_cre_idx)               := re_can_data.mixed_no ;
      gt_collected_pallet_qty(gn_cre_idx)   := re_can_data.collected_pallet_qty ;
      gt_arrival_time_from(gn_cre_idx)      := re_can_data.arrival_time_from ;
      gt_arrival_time_to(gn_cre_idx)        := re_can_data.arrival_time_to ;
      gt_cust_po_number(gn_cre_idx)         := re_can_data.cust_po_number ;
      gt_description(gn_cre_idx)            := re_can_data.description ;
      gt_status(gn_cre_idx)                 := re_can_data.status ;
      gt_freight_charge_class(gn_cre_idx)   := re_can_data.freight_charge_class ;
      gt_pallet_sum_quantity(gn_cre_idx)    := re_can_data.pallet_sum_quantity ;
      gt_reserve1(gn_cre_idx)               := re_can_data.reserve1 ;
      gt_reserve2(gn_cre_idx)               := re_can_data.reserve2 ;
      gt_reserve3(gn_cre_idx)               := re_can_data.reserve3 ;
      gt_reserve4(gn_cre_idx)               := re_can_data.reserve4 ;
      gt_report_dept(gn_cre_idx)            := re_can_data.report_dept ;
      gt_item_code(gn_cre_idx)              := re_can_data.item_code ;
      gt_item_name(gn_cre_idx)              := re_can_data.item_name ;
      gt_item_uom_code(gn_cre_idx)          := re_can_data.item_uom_code ;
      gt_item_quantity(gn_cre_idx)          := 0 ;
      gt_lot_no(gn_cre_idx)                 := re_can_data.lot_no ;
      gt_lot_date(gn_cre_idx)               := re_can_data.lot_date ;
      gt_lot_sign(gn_cre_idx)               := re_can_data.lot_sign ;
      gt_best_bfr_date(gn_cre_idx)          := re_can_data.best_bfr_date ;
      gt_lot_quantity(gn_cre_idx)           := 0 ;
-- M.Hokkanji Ver1.2 START
--      gt_new_modify_del_class(gn_cre_idx)   := '2' ;
      gt_new_modify_del_class(gn_cre_idx)   := gc_data_class_del ;
-- M.Hokkanji Ver1.2 END
      gt_update_date(gn_cre_idx)            := SYSDATE ;
      gt_line_number(gn_cre_idx)            := re_can_data.line_number ;
      gt_data_type(gn_cre_idx)              := re_can_data.data_type ;
--
    END LOOP can_data_loop ;
--
  EXCEPTION
--##### �Œ��O������ START ######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   ######################################################################
  END prc_create_can_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_ins_temp_data
   * Description      : �ꊇ�o�^����(F-07)
   ***********************************************************************************************/
  PROCEDURE prc_ins_temp_data
    (
      ov_errbuf               OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode              OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg               OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_ins_temp_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    ln_cnt    NUMBER := 0 ;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �ꊇ�o�^����
    -- ====================================================
    FORALL ln_cnt IN 1..gn_cre_idx
      INSERT INTO xxwsh_hht_stock_deliv_info_tmp
        (
          corporation_name                        -- ��Ж�
         ,data_class                              -- �f�[�^���
         ,transfer_branch_no                      -- �`���p�}��
         ,delivery_no                             -- �z��No
         ,request_no                              -- �˗�No
         ,reserve                                 -- �\��
         ,head_sales_branch                       -- ���_�R�[�h
         ,head_sales_branch_name                  -- �Ǌ����_����
         ,shipped_locat_code                      -- �o�ɑq�ɃR�[�h
         ,shipped_locat_name                      -- �o�ɑq�ɖ���
         ,ship_to_locat_code                      -- ���ɑq�ɃR�[�h
         ,ship_to_locat_name                      -- ���ɑq�ɖ���
         ,freight_carrier_code                    -- �^���Ǝ҃R�[�h
         ,freight_carrier_name                    -- �^���ƎҖ�
         ,deliver_to                              -- �z����R�[�h
         ,deliver_to_name                         -- �z���於
         ,schedule_ship_date                      -- ����
         ,schedule_arrival_date                   -- ����
         ,shipping_method_code                    -- �z���敪
         ,weight                                  -- �d��/�e��
         ,mixed_no                                -- ���ڌ��˗���
         ,collected_pallet_qty                    -- �p���b�g�������
         ,arrival_time_from                       -- ���׎��Ԏw��(FROM)
         ,arrival_time_to                         -- ���׎��Ԏw��(TO)
         ,cust_po_number                          -- �ڋq�����ԍ�
         ,description                             -- �E�v
         ,status                                  -- �X�e�[�^�X
         ,freight_charge_class                    -- �^���敪
         ,pallet_sum_quantity                     -- �p���b�g�g�p����
         ,reserve1                                -- �\���P
         ,reserve2                                -- �\���Q
         ,reserve3                                -- �\���R
         ,reserve4                                -- �\���S
         ,report_dept                             -- �񍐕���
         ,item_code                               -- �i�ڃR�[�h
         ,item_name                               -- �i�ږ�
         ,item_uom_code                           -- �i�ڒP��
         ,item_quantity                           -- �i�ڐ���
         ,lot_no                                  -- ���b�g�ԍ�
         ,lot_date                                -- ������
         ,lot_sign                                -- �ŗL�L��
         ,best_bfr_date                           -- �ܖ�����
         ,lot_quantity                            -- ���b�g����
         ,new_modify_del_class                    -- �f�[�^�敪
         ,update_date                             -- �X�V����
         ,line_number                             -- ���הԍ�
         ,data_type                               -- �f�[�^�^�C�v
        )
      VALUES
        (
          gt_corporation_name(ln_cnt)             -- ��Ж�
         ,gt_data_class(ln_cnt)                   -- �f�[�^���
         ,gt_transfer_branch_no(ln_cnt)           -- �`���p�}��
         ,gt_delivery_no(ln_cnt)                  -- �z��No
         ,gt_requesgt_no(ln_cnt)                  -- �˗�No
         ,gt_reserve(ln_cnt)                      -- �\��
         ,gt_head_sales_branch(ln_cnt)            -- ���_�R�[�h
         ,gt_head_sales_branch_name(ln_cnt)       -- �Ǌ����_����
         ,gt_shipped_locat_code(ln_cnt)           -- �o�ɑq�ɃR�[�h
         ,gt_shipped_locat_name(ln_cnt)           -- �o�ɑq�ɖ���
         ,gt_ship_to_locat_code(ln_cnt)           -- ���ɑq�ɃR�[�h
         ,gt_ship_to_locat_name(ln_cnt)           -- ���ɑq�ɖ���
         ,gt_freight_carrier_code(ln_cnt)         -- �^���Ǝ҃R�[�h
         ,gt_freight_carrier_name(ln_cnt)         -- �^���ƎҖ�
         ,gt_deliver_to(ln_cnt)                   -- �z����R�[�h
         ,gt_deliver_to_name(ln_cnt)              -- �z���於
         ,gt_schedule_ship_date(ln_cnt)           -- ����
         ,gt_schedule_arrival_date(ln_cnt)        -- ����
         ,gt_shipping_method_code(ln_cnt)         -- �z���敪
         ,gt_weight(ln_cnt)                       -- �d��/�e��
         ,gt_mixed_no(ln_cnt)                     -- ���ڌ��˗���
         ,gt_collected_pallet_qty(ln_cnt)         -- �p���b�g�������
         ,gt_arrival_time_from(ln_cnt)            -- ���׎��Ԏw��(FROM)
         ,gt_arrival_time_to(ln_cnt)              -- ���׎��Ԏw��(TO)
         ,gt_cust_po_number(ln_cnt)               -- �ڋq�����ԍ�
         ,gt_description(ln_cnt)                  -- �E�v
         ,gt_status(ln_cnt)                       -- �X�e�[�^�X
         ,gt_freight_charge_class(ln_cnt)         -- �^���敪
         ,gt_pallet_sum_quantity(ln_cnt)          -- �p���b�g�g�p����
         ,gt_reserve1(ln_cnt)                     -- �\���P
         ,gt_reserve2(ln_cnt)                     -- �\���Q
         ,gt_reserve3(ln_cnt)                     -- �\���R
         ,gt_reserve4(ln_cnt)                     -- �\���S
         ,gt_report_dept(ln_cnt)                  -- �񍐕���
         ,gt_item_code(ln_cnt)                    -- �i�ڃR�[�h
         ,gt_item_name(ln_cnt)                    -- �i�ږ�
         ,gt_item_uom_code(ln_cnt)                -- �i�ڒP��
         ,gt_item_quantity(ln_cnt)                -- �i�ڐ���
         ,gt_lot_no(ln_cnt)                       -- ���b�g�ԍ�
         ,gt_lot_date(ln_cnt)                     -- ������
         ,gt_lot_sign(ln_cnt)                     -- �ŗL�L��
         ,gt_best_bfr_date(ln_cnt)                -- �ܖ�����
         ,gt_lot_quantity(ln_cnt)                 -- ���b�g����
         ,gt_new_modify_del_class(ln_cnt)         -- �f�[�^�敪
         ,gt_update_date(ln_cnt)                  -- �X�V����
         ,gt_line_number(ln_cnt)                  -- ���הԍ�
         ,gt_data_type(ln_cnt)                    -- �f�[�^�^�C�v
        ) ;
--
  EXCEPTION
--##### �Œ��O������ START ######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   ######################################################################
  END prc_ins_temp_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_out_csv_data
   * Description      : �b�r�u�o�͏���(F-08)
   ***********************************************************************************************/
  PROCEDURE prc_out_csv_data
    (
      ov_errbuf               OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode              OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg               OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_out_csv_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_lookup_wf_notif    CONSTANT VARCHAR2(100) := 'XXCMN_WF_NOTIFICATION' ;   -- Workflow�ʒm��
    lc_lookup_wf_info     CONSTANT VARCHAR2(100) := 'XXCMN_WF_INFO' ;           -- Workflow���
-- M.Hokkanji Ver1.2 START
    lc_transfer_branch_no_d CONSTANT VARCHAR2(100) := '20' ;    -- ����
-- M.Hokkanji Ver1.2 END
--
    -- 2008/07/17 Add ��
    lv_file_name    CONSTANT VARCHAR2(200) := 'HHT���o�ɔz�Ԋm����t�@�C��';
    lv_tkn_name     CONSTANT VARCHAR2(100) := 'NAME';
    -- 2008/07/17 Add ��
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    -- ���[�N�t���[�֘A
    lv_wf_ope_div       VARCHAR2(100) ;         -- �����敪
    lv_wf_class         VARCHAR2(100) ;         -- �Ώ�
    lv_wf_notification  VARCHAR2(100) ;         -- ����
    -- �t�@�C���o�͊֘A
    lf_file_hand        UTL_FILE.FILE_TYPE ;    -- �t�@�C���E�n���h���̐錾
    lv_csv_text         VARCHAR2(32000) ;
-- M.Hokkanji Ver1.2 START
    lt_new_modify_del_class xxwsh_stock_delivery_info_tmp.new_modify_del_class%TYPE;
-- M.Hokkanji Ver1.2 END
--
    -- 2008/07/17 Add ��
    lb_retcd        BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
    -- 2008/07/17 Add ��
--
    -- ==================================================
    -- �J�[�\���錾
    -- ==================================================
    CURSOR cu_out_data
    IS
      SELECT xhsdit.corporation_name          -- ��Ж�
            ,xhsdit.data_class                -- �f�[�^���
            ,xhsdit.transfer_branch_no        -- �`���p�}��
            ,xhsdit.delivery_no               -- �z��No
            ,xhsdit.request_no                -- �˗�No
            ,xhsdit.reserve                   -- �\��
            ,xhsdit.head_sales_branch         -- ���_�R�[�h
            ,xhsdit.head_sales_branch_name    -- �Ǌ����_����
            ,xhsdit.shipped_locat_code        -- �o�ɑq�ɃR�[�h
            ,xhsdit.shipped_locat_name        -- �o�ɑq�ɖ���
            ,xhsdit.ship_to_locat_code        -- ���ɑq�ɃR�[�h
            ,xhsdit.ship_to_locat_name        -- ���ɑq�ɖ���
            ,xhsdit.freight_carrier_code      -- �^���Ǝ҃R�[�h
            ,xhsdit.freight_carrier_name      -- �^���ƎҖ�
            ,xhsdit.deliver_to                -- �z����R�[�h
            ,xhsdit.deliver_to_name           -- �z���於
            ,xhsdit.schedule_ship_date        -- ����
            ,xhsdit.schedule_arrival_date     -- ����
            ,xhsdit.shipping_method_code      -- �z���敪
            ,xhsdit.weight                    -- �d��/�e��
            ,xhsdit.mixed_no                  -- ���ڌ��˗���
            ,xhsdit.collected_pallet_qty      -- �p���b�g�������
            ,xhsdit.arrival_time_from         -- ���׎��Ԏw��(FROM)
            ,xhsdit.arrival_time_to           -- ���׎��Ԏw��(TO)
            ,xhsdit.cust_po_number            -- �ڋq�����ԍ�
            ,xhsdit.description               -- �E�v
            ,xhsdit.status                    -- �X�e�[�^�X
            ,xhsdit.freight_charge_class      -- �^���敪
            ,xhsdit.pallet_sum_quantity       -- �p���b�g�g�p����
            ,xhsdit.reserve1                  -- �\���P
            ,xhsdit.reserve2                  -- �\���Q
            ,xhsdit.reserve3                  -- �\���R
            ,xhsdit.reserve4                  -- �\���S
            ,xhsdit.report_dept               -- �񍐕���
            ,xhsdit.item_code                 -- �i�ڃR�[�h
            ,xhsdit.item_name                 -- �i�ږ�
            ,xhsdit.item_uom_code             -- �i�ڒP��
            ,xhsdit.item_quantity             -- �i�ڐ���
            ,xhsdit.lot_no                    -- ���b�g�ԍ�
            ,xhsdit.lot_date                  -- ������
            ,xhsdit.lot_sign                  -- �ŗL�L��
            ,xhsdit.best_bfr_date             -- �ܖ�����
            ,xhsdit.lot_quantity              -- ���b�g����
            ,xhsdit.new_modify_del_class      -- �f�[�^�敪
            ,xhsdit.update_date               -- �X�V����
            ,xhsdit.line_number               -- ���הԍ�
            ,xhsdit.data_type                 -- �f�[�^�^�C�v
      FROM xxwsh_hht_stock_deliv_info_tmp   xhsdit
      ORDER BY xhsdit.new_modify_del_class   DESC   -- �f�[�^�敪   �i�~���j
              ,xhsdit.data_type                     -- �f�[�^�^�C�v �i�����j
              ,xhsdit.data_class                    -- �f�[�^���   �i�����j
              ,xhsdit.request_no                    -- �˗�No       �i�����j
              ,xhsdit.transfer_branch_no            -- �`���p�}��   �i�����j
              ,xhsdit.line_number                   -- ���הԍ�     �i�����j
    ;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- 2008/07/17 Add ��
    -- ====================================================
    -- �t�s�k�t�@�C�����݃`�F�b�N
    -- ====================================================
    UTL_FILE.FGETATTR(gv_prof_put_file_path,
                      gv_prof_put_file_name,
                      lb_retcd,
                      ln_file_size,
                      ln_block_size);
--
    -- �t�@�C������
    IF (lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN',
                                            'APP-XXCMN-10602',
                                            lv_tkn_name,
                                            lv_file_name);
      lv_errbuf := lv_errmsg;
      RAISE file_exists_expt;
    END IF;
    -- 2008/07/17 Add ��
    -- ====================================================
    -- �t�s�k�t�@�C���I�[�v��
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN
                      (
                        gv_prof_put_file_path
                       ,gv_prof_put_file_name
                       ,'w'
                      ) ;
--
    -- ====================================================
    -- �o�̓f�[�^���o
    -- ====================================================
    <<out_loop>>
    FOR re_out_data IN cu_out_data LOOP
-- M.Hokkanji Ver1.2 START
        IF (re_out_data.transfer_branch_no = lc_transfer_branch_no_d ) THEN
          lt_new_modify_del_class := re_out_data.new_modify_del_class;
        ELSE
          lt_new_modify_del_class := NULL;
        END IF;
-- M.Hokkanji Ver1.2 END
      -- ====================================================
      -- �o�͕�����ҏW
      -- ====================================================
      lv_csv_text := re_out_data.corporation_name         || ','  -- ��Ж�
                  || re_out_data.data_class               || ','  -- �f�[�^���
                  || re_out_data.transfer_branch_no       || ','  -- �`���p�}��
                  || re_out_data.delivery_no              || ','  -- �z��No
                  || re_out_data.request_no               || ','  -- �˗�No
                  || re_out_data.reserve                  || ','  -- �\��
                  || re_out_data.head_sales_branch        || ','  -- ���_�R�[�h
                  || REPLACE(re_out_data.head_sales_branch_name,',')   || ','  -- �Ǌ����_����
                  || re_out_data.shipped_locat_code       || ','  -- �o�ɑq�ɃR�[�h
                  || REPLACE(re_out_data.shipped_locat_name,',')       || ','  -- �o�ɑq�ɖ���
                  || re_out_data.ship_to_locat_code       || ','  -- ���ɑq�ɃR�[�h
                  || REPLACE(re_out_data.ship_to_locat_name,',')       || ','  -- ���ɑq�ɖ���
                  || re_out_data.freight_carrier_code     || ','  -- �^���Ǝ҃R�[�h
                  || REPLACE(re_out_data.freight_carrier_name,',')     || ','  -- �^���ƎҖ�
                  || re_out_data.deliver_to               || ','  -- �z����R�[�h
                  || REPLACE(re_out_data.deliver_to_name,',')          || ','  -- �z���於
                  || TO_CHAR( re_out_data.schedule_ship_date   , 'YYYY/MM/DD' ) || ','  -- ����
                  || TO_CHAR( re_out_data.schedule_arrival_date, 'YYYY/MM/DD' ) || ','  -- ����
                  || re_out_data.shipping_method_code     || ','  -- �z���敪
                  -- 2008/08/12 Start ----------------------------------------------
                  --|| re_out_data.weight                   || ','  -- �d��/�e��
                  || CEIL(TRUNC(re_out_data.weight,3))    || ','  -- �d��/�e��
                  -- 2008/08/12 End ----------------------------------------------
                  || re_out_data.mixed_no                 || ','  -- ���ڌ��˗���
                  || re_out_data.collected_pallet_qty     || ','  -- �p���b�g�������
                  || re_out_data.arrival_time_from        || ','  -- ���׎��Ԏw��(FROM)
                  || re_out_data.arrival_time_to          || ','  -- ���׎��Ԏw��(TO)
                  || re_out_data.cust_po_number           || ','  -- �ڋq�����ԍ�
                  || REPLACE(re_out_data.description,',')              || ','  -- �E�v
                  || re_out_data.status                   || ','  -- �X�e�[�^�X
                  || re_out_data.freight_charge_class     || ','  -- �^���敪
                  || re_out_data.pallet_sum_quantity      || ','  -- �p���b�g�g�p����
                  || re_out_data.reserve1                 || ','  -- �\���P
                  || re_out_data.reserve2                 || ','  -- �\���Q
                  || re_out_data.reserve3                 || ','  -- �\���R
                  || re_out_data.reserve4                 || ','  -- �\���S
                  || re_out_data.report_dept              || ','  -- �񍐕���
                  || re_out_data.item_code                || ','  -- �i�ڃR�[�h
                  || REPLACE(re_out_data.item_name,',')                || ','  -- �i�ږ�
                  || re_out_data.item_uom_code            || ','  -- �i�ڒP��
--2008/08/08 Mod ��
--                  || re_out_data.item_quantity            || ','  -- �i�ڐ���
                  || CEIL(TRUNC(re_out_data.item_quantity,3))            || ','  -- �i�ڐ���
--2008/08/08 Mod ��
                  || re_out_data.lot_no                   || ','                -- ���b�g�ԍ�
-- M.Hokkanji Ver1.4 START
                  || TO_CHAR( re_out_data.lot_date     , 'YYYY/MM/DD' ) || ','  -- ������
                  || TO_CHAR( re_out_data.best_bfr_date, 'YYYY/MM/DD' ) || ','  -- �ܖ�����
                  || re_out_data.lot_sign                 || ','                -- �ŗL�L��
--                  || TO_CHAR( re_out_data.lot_date     , 'YYYY/MM/DD' ) || ','  -- ������
--                  || re_out_data.lot_sign                 || ','                -- �ŗL�L��
--                  || TO_CHAR( re_out_data.best_bfr_date, 'YYYY/MM/DD' ) || ','  -- �ܖ�����
--2008/08/08 Mod ��
--                  || re_out_data.lot_quantity             || ','                -- ���b�g����
                  || CEIL(TRUNC(re_out_data.lot_quantity,3)) || ','                -- ���b�g����
--2008/08/08 Mod ��
-- M.Hokkanji Ver1.4 END
-- M.Hokkanji Ver1.2 START
--                  || re_out_data.new_modify_del_class     || ','  -- �f�[�^�敪
                  || lt_new_modify_del_class              || ','  -- �f�[�^�敪
                  || TO_CHAR( re_out_data.update_date, 'YYYY/MM/DD HH24:MI:SS' ) ;
--                  || TO_CHAR( re_out_data.update_date, 'YYYY/MM/DD HH24:MI:SS' ) || ','
--                  || re_out_data.line_number              || ','  -- ���הԍ�
--                  || re_out_data.data_type                        -- �f�[�^�^�C�v
--                  ;
-- M.Hokkanji Ver1.2 END
--
      -- ====================================================
      -- �b�r�u�o��
      -- ====================================================
      UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text ) ;
--
      -- ====================================================
      -- ���������J�E���g�A�b�v
      -- ====================================================
      -------------------------------------------------------
      -- �o�׃f�[�^
      -------------------------------------------------------
      IF ( re_out_data.data_type = gc_data_type_syu_ins ) THEN
        gn_out_cnt_syu := gn_out_cnt_syu + 1 ;
--
      -------------------------------------------------------
      -- �ړ��f�[�^
      -------------------------------------------------------
      ELSE
        gn_out_cnt_mov := gn_out_cnt_mov + 1 ;
--
      END IF ;
--
    END LOOP out_loop ;
--
    -- ====================================================
    -- �t�s�k�t�@�C���N���[�Y
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand ) ;
--
  EXCEPTION
    WHEN file_exists_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--##### �Œ��O������ START ######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      UTL_FILE.FCLOSE_ALL ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      UTL_FILE.FCLOSE_ALL ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      UTL_FILE.FCLOSE_ALL ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   ######################################################################
  END prc_out_csv_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_ins_out_data
   * Description      : �ʒm�ς݃f�[�^�o�^����(F-09,F-10)
   ***********************************************************************************************/
  PROCEDURE prc_ins_out_data
    (
      ov_errbuf               OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode              OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg               OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_ins_out_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_msg_code     CONSTANT VARCHAR2(50) := 'APP-XXWSH-12853' ;
--
    -- ==================================================
    -- �J�[�\���錾
    -- ==================================================
    ----------------------------------------
    -- �폜�Ώۃf�[�^
    ----------------------------------------
    CURSOR cu_del_data
    IS
      SELECT xhdi.request_no
      FROM xxwsh_hht_delivery_info    xhdi
      WHERE xhdi.request_no IN
        ( SELECT DISTINCT xhsdit.request_no
          FROM   xxwsh_hht_stock_deliv_info_tmp   xhsdit
          WHERE  xhsdit.new_modify_del_class = gc_data_class_del )
      FOR UPDATE NOWAIT
    ;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- ���b�N�擾�E�ύX�O�f�[�^�폜
    -- ====================================================
    <<delete_loop>>
    FOR re_del_data IN cu_del_data LOOP
      DELETE
      FROM xxwsh_hht_delivery_info    xhdi
      WHERE xhdi.request_no = re_del_data.request_no
      ;
    END LOOP delete_loop ;
--
    -- ====================================================
    -- �b�r�u�o�̓f�[�^�o�^
    -- ====================================================
    INSERT INTO xxwsh_hht_delivery_info
      SELECT xxwsh_hht_delivery_info_s1.NEXTVAL
            ,xhsdit.corporation_name          -- ��Ж�
            ,xhsdit.data_class                -- �f�[�^���
            ,xhsdit.transfer_branch_no        -- �`���p�}��
            ,xhsdit.delivery_no               -- �z��No
            ,xhsdit.request_no                -- �˗�No
            ,xhsdit.reserve                   -- �\��
            ,xhsdit.head_sales_branch         -- ���_�R�[�h
            ,xhsdit.head_sales_branch_name    -- �Ǌ����_����
            ,xhsdit.shipped_locat_code        -- �o�ɑq�ɃR�[�h
            ,xhsdit.shipped_locat_name        -- �o�ɑq�ɖ���
            ,xhsdit.ship_to_locat_code        -- ���ɑq�ɃR�[�h
            ,xhsdit.ship_to_locat_name        -- ���ɑq�ɖ���
            ,xhsdit.freight_carrier_code      -- �^���Ǝ҃R�[�h
            ,xhsdit.freight_carrier_name      -- �^���ƎҖ�
            ,xhsdit.deliver_to                -- �z����R�[�h
            ,xhsdit.deliver_to_name           -- �z���於
            ,xhsdit.schedule_ship_date        -- ����
            ,xhsdit.schedule_arrival_date     -- ����
            ,xhsdit.shipping_method_code      -- �z���敪
            ,xhsdit.weight                    -- �d��/�e��
            ,xhsdit.mixed_no                  -- ���ڌ��˗���
            ,xhsdit.collected_pallet_qty      -- �p���b�g�������
            ,xhsdit.arrival_time_from         -- ���׎��Ԏw��(FROM)
            ,xhsdit.arrival_time_to           -- ���׎��Ԏw��(TO)
            ,xhsdit.cust_po_number            -- �ڋq�����ԍ�
            ,xhsdit.description               -- �E�v
            ,xhsdit.status                    -- �X�e�[�^�X
            ,xhsdit.freight_charge_class      -- �^���敪
            ,xhsdit.pallet_sum_quantity       -- �p���b�g�g�p����
            ,xhsdit.reserve1                  -- �\���P
            ,xhsdit.reserve2                  -- �\���Q
            ,xhsdit.reserve3                  -- �\���R
            ,xhsdit.reserve4                  -- �\���S
            ,xhsdit.report_dept               -- �񍐕���
            ,xhsdit.item_code                 -- �i�ڃR�[�h
            ,xhsdit.item_name                 -- �i�ږ�
            ,xhsdit.item_uom_code             -- �i�ڒP��
            ,xhsdit.item_quantity             -- �i�ڐ���
            ,xhsdit.lot_no                    -- ���b�g�ԍ�
            ,xhsdit.lot_date                  -- ������
            ,xhsdit.best_bfr_date             -- �ܖ�����
            ,xhsdit.lot_sign                  -- �ŗL�L��
            ,xhsdit.lot_quantity              -- ���b�g����
            ,xhsdit.new_modify_del_class      -- �f�[�^�敪
            ,xhsdit.update_date               -- �X�V����
            ,xhsdit.line_number               -- ���הԍ�
            ,xhsdit.data_type                 -- �f�[�^�^�C�v
            ,gn_created_by                    -- �쐬��
            ,SYSDATE                          -- �쐬��
            ,gn_last_updated_by               -- �ŏI�X�V��
            ,SYSDATE                          -- �ŏI�X�V��
            ,gn_last_update_login             -- �ŏI�X�V���O�C��
            ,gn_request_id                    -- �v��ID
            ,gn_program_application_id        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,gn_program_id                    -- �R���J�����g�E�v���O����ID
            ,SYSDATE                          -- �v���O�����X�V��
      FROM xxwsh_hht_stock_deliv_info_tmp   xhsdit
      WHERE xhsdit.new_modify_del_class = gc_data_class_ins
    ;
--
  EXCEPTION
    -- ============================================================================================
    -- ���b�N�擾�G���[
    -- ============================================================================================
    WHEN ex_lock_error THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := xxcmn_common_pkg.get_msg
                      (
                        iv_application    => gc_appl_sname_wsh
                       ,iv_name           => lc_msg_code
                      ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--##### �Œ��O������ START ######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   ######################################################################
  END prc_ins_out_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_put_err_log
   * Description      : ���ڃG���[���O�o�͏���(F-11)
   ***********************************************************************************************/
  PROCEDURE prc_put_err_log
    (
      ov_errbuf               OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode              OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg               OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_put_err_log' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_msg_code     CONSTANT VARCHAR2(50) := 'APP-XXWSH-11958' ;
    lc_tok_name_1   CONSTANT VARCHAR2(50) := 'DELI_NO' ;
    lc_tok_name_2   CONSTANT VARCHAR2(50) := 'REQ_NO' ;
--
    -- ==================================================
    -- �J�[�\���錾
    -- ==================================================
    ----------------------------------------
    -- ���O�o�͑Ώۃf�[�^
    ----------------------------------------
    CURSOR cu_log_data
    IS
      SELECT main.delivery_no
            ,main.request_no
      FROM
        (
          SELECT xoha.delivery_no             AS delivery_no          -- �z���m��
                ,xoha.request_no              AS request_no           -- �˗��m��
                ,SUM( CASE xic.item_class_code
                        WHEN gc_item_class_i THEN 1
                        ELSE 0
                      END )                   AS cnt_item             -- ���i�̌���
                ,SUM( CASE xic.item_class_code
                        WHEN gc_item_class_i THEN 0
                        ELSE 1
                      END )                   AS cnt_else             -- ���i�ȊO�̌���
          FROM xxwsh_order_headers_all    xoha      -- �󒍃w�b�_�A�h�I��
              ,xxwsh_order_lines_all      xola    -- �󒍖��׃A�h�I��
              ,xxcmn_item_mst2_v          xim     -- OPM�i�ڏ��VIEW2
              ,xxcmn_item_categories4_v   xic     -- OPM�i�ڃJ�e�S������VIEW4
          WHERE
          -----------------------------------------------------------------------------------------
          -- �i��
          -----------------------------------------------------------------------------------------
                xim.item_id             = xic.item_id
          AND   gd_effective_date       BETWEEN xim.start_date_active
                                        AND     NVL( xim.end_date_active ,gd_effective_date )
          AND   xola.shipping_item_code = xim.item_no
          -----------------------------------------------------------------------------------------
          -- �󒍖���
          -----------------------------------------------------------------------------------------
          AND   xoha.order_header_id = xola.order_header_id
          -----------------------------------------------------------------------------------------
          -- �󒍃w�b�_�A�h�I��
          -----------------------------------------------------------------------------------------
          AND   (
                  (   xoha.req_status            = gc_req_status_syu_3    -- ���ߍ�
                  AND xoha.notif_status          = gc_notif_status_c      -- �m��ʒm��
                  AND xoha.prev_notif_status     = gc_notif_status_n      -- ���ʒm
                  AND NOT EXISTS
                        ( SELECT 1
                          FROM xxwsh_hht_delivery_info  xhdi
                          WHERE xhdi.request_no = xoha.request_no )
                  )
                OR
                  (   xoha.notif_status          = gc_notif_status_c      -- �m��ʒm��
                  AND xoha.prev_notif_status     = gc_notif_status_r   )  -- �Ēʒm�v
                )
          AND   xoha.req_status                 = gc_req_status_syu_3   -- ���ߍ�
          AND   xoha.notif_date           BETWEEN gd_date_from AND gd_date_to
          AND   xoha.latest_external_flag = gc_yes_no_y             -- �ŐV
          AND   xoha.prod_class           = gc_prod_class_r         -- ���[�t
          AND   ((xoha.instruction_dept   = gr_param.dept_code_01)  -- �w������
          OR     (xoha.instruction_dept   = NVL(gr_param.dept_code_02,xoha.instruction_dept))
          OR     (xoha.instruction_dept   = NVL(gr_param.dept_code_03,xoha.instruction_dept))
          OR     (xoha.instruction_dept   = NVL(gr_param.dept_code_04,xoha.instruction_dept))
          OR     (xoha.instruction_dept   = NVL(gr_param.dept_code_05,xoha.instruction_dept))
          OR     (xoha.instruction_dept   = NVL(gr_param.dept_code_06,xoha.instruction_dept))
          OR     (xoha.instruction_dept   = NVL(gr_param.dept_code_07,xoha.instruction_dept))
          OR     (xoha.instruction_dept   = NVL(gr_param.dept_code_08,xoha.instruction_dept))
          OR     (xoha.instruction_dept   = NVL(gr_param.dept_code_09,xoha.instruction_dept))
          OR     (xoha.instruction_dept   = NVL(gr_param.dept_code_10,xoha.instruction_dept)))
          GROUP BY xoha.delivery_no
                  ,xoha.request_no
          ORDER BY xoha.delivery_no
                  ,xoha.request_no
        ) main
      WHERE main.cnt_item > 0
      AND   main.cnt_else > 0
    ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- ���O�o��
    -- ====================================================
    <<log_loop>>
    FOR re_log_data IN cu_log_data LOOP
      lv_errmsg  := xxcmn_common_pkg.get_msg
                      (
                        iv_application    => gc_appl_sname_wsh
                       ,iv_name           => lc_msg_code
                       ,iv_token_name1    => lc_tok_name_1
                       ,iv_token_name2    => lc_tok_name_2
                       ,iv_token_value1   => re_log_data.delivery_no
                       ,iv_token_value2   => re_log_data.request_no
                      ) ;
      gn_wrm_idx              := gn_wrm_idx + 1 ;
      gt_worm_msg(gn_wrm_idx) := lv_errmsg ;
      ov_retcode              := gv_status_warn ;
    END LOOP log_loop ;
--
  EXCEPTION
--##### �Œ��O������ START ######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   ######################################################################
  END prc_put_err_log ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_dept_code_01     IN  VARCHAR2          -- 01 : ����_01
     ,iv_dept_code_02     IN  VARCHAR2          -- 02 : ����_02(2008/07/17 Add)
     ,iv_dept_code_03     IN  VARCHAR2          -- 03 : ����_03(2008/07/17 Add)
     ,iv_dept_code_04     IN  VARCHAR2          -- 04 : ����_04(2008/07/17 Add)
     ,iv_dept_code_05     IN  VARCHAR2          -- 05 : ����_05(2008/07/17 Add)
     ,iv_dept_code_06     IN  VARCHAR2          -- 06 : ����_06(2008/07/17 Add)
     ,iv_dept_code_07     IN  VARCHAR2          -- 07 : ����_07(2008/07/17 Add)
     ,iv_dept_code_08     IN  VARCHAR2          -- 08 : ����_08(2008/07/17 Add)
     ,iv_dept_code_09     IN  VARCHAR2          -- 09 : ����_09(2008/07/17 Add)
     ,iv_dept_code_10     IN  VARCHAR2          -- 10 : ����_10(2008/07/17 Add)
     ,iv_date_fix         IN  VARCHAR2          -- 11 : �m��ʒm���{��
     ,iv_fix_from         IN  VARCHAR2          -- 12 : �m��ʒm���{����From
     ,iv_fix_to           IN  VARCHAR2          -- 13 : �m��ʒm���{����To
     ,ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
--
    -- ==================================================
    -- ���[�J���ϐ�
    -- ==================================================
    lv_temp_request_no    xxwsh_stock_delivery_info_tmp2.request_no%TYPE := '*' ;
    lv_break_flg          VARCHAR2(1) := gc_yes_no_n ;
    lv_error_flg          VARCHAR2(1) := gc_yes_no_n ;
--
    lv_errbuf             VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode            VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg             VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- ==================================================
    -- ��O�錾
    -- ==================================================
    ex_worn               EXCEPTION ;
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
    ov_retcode := gv_status_normal;
--###########################  �Œ蕔 END   ############################
--
    -- ============================================================================================
    -- ��������
    -- ============================================================================================
    --------------------------------------------------
    -- �O���[�o���ϐ��̏�����
    --------------------------------------------------
    gn_out_cnt_syu := 0 ;   -- �o�͌����F�o��
    gn_out_cnt_mov := 0 ;   -- �o�͌����F�ړ�
--
    --------------------------------------------------
    -- �p�����[�^�i�[
    --------------------------------------------------
    gr_param.dept_code_01 := iv_dept_code_01 ;                  -- 01 : ����_01
    gr_param.dept_code_02 := iv_dept_code_02 ;                  -- 02 : ����_02(2008/07/17 Add)
    gr_param.dept_code_03 := iv_dept_code_03 ;                  -- 03 : ����_03(2008/07/17 Add)
    gr_param.dept_code_04 := iv_dept_code_04 ;                  -- 04 : ����_04(2008/07/17 Add)
    gr_param.dept_code_05 := iv_dept_code_05 ;                  -- 05 : ����_05(2008/07/17 Add)
    gr_param.dept_code_06 := iv_dept_code_06 ;                  -- 06 : ����_06(2008/07/17 Add)
    gr_param.dept_code_07 := iv_dept_code_07 ;                  -- 07 : ����_07(2008/07/17 Add)
    gr_param.dept_code_08 := iv_dept_code_08 ;                  -- 08 : ����_08(2008/07/17 Add)
    gr_param.dept_code_09 := iv_dept_code_09 ;                  -- 09 : ����_09(2008/07/17 Add)
    gr_param.dept_code_10 := iv_dept_code_10 ;                  -- 10 : ����_10(2008/07/17 Add)
    gr_param.date_fix     := SUBSTR( iv_date_fix   , 1, 10 ) ;  -- 11 : �m��ʒm���{��
    gr_param.fix_from     := NVL( iv_fix_from, gc_time_min ) ;  -- 12 : �m��ʒm���{����From
    gr_param.fix_to       := NVL( iv_fix_to  , gc_time_max ) ;  -- 13 : �m��ʒm���{����To
--
    gr_param.fix_from     := ' ' || gr_param.fix_from    || ':00' ;
    gr_param.fix_to       := ' ' || gr_param.fix_to      || ':59' ;
--
    --------------------------------------------------
    -- ����̐ݒ�
    --------------------------------------------------
    gd_effective_date := FND_DATE.CANONICAL_TO_DATE( gr_param.date_fix ) ;
    gd_date_from  := FND_DATE.CANONICAL_TO_DATE( gr_param.date_fix || gr_param.fix_from ) ;
    gd_date_to    := FND_DATE.CANONICAL_TO_DATE( gr_param.date_fix || gr_param.fix_to ) ;
--
    --------------------------------------------------
    -- �v�g�n�J�����擾
    --------------------------------------------------
    gn_created_by             := FND_GLOBAL.USER_ID ;           -- �쐬��
    gn_last_updated_by        := FND_GLOBAL.USER_ID ;           -- �ŏI�X�V��
    gn_last_update_login      := FND_GLOBAL.LOGIN_ID ;          -- �ŏI�X�V���O�C��
    gn_request_id             := FND_GLOBAL.CONC_REQUEST_ID ;   -- �v��ID
    gn_program_application_id := FND_GLOBAL.PROG_APPL_ID ;      -- �b�o�E�A�v���P�[�V����ID
    gn_program_id             := FND_GLOBAL.CONC_PROGRAM_ID ;   -- �R���J�����g�E�v���O����ID
--
    -- ============================================================================================
    -- F-01 �p�����[�^�`�F�b�N
    -- ============================================================================================
    prc_chk_param
      (
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
    END IF ;
--
    -- ============================================================================================
    -- F-02 �v���t�@�C���擾
    -- ============================================================================================
    prc_get_profile
      (
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
    END IF ;
--
    -- ============================================================================================
    -- F-03 �f�[�^�폜
    -- ============================================================================================
    prc_del_temp_data
      (
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
    END IF ;
--
    -- ============================================================================================
    -- F-04 ���C���f�[�^���o
    -- ============================================================================================
    prc_get_main_data
      (
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      ) ;
    -- �G���[������
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
--
    -- �x��������
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      gn_warn_cnt := gn_warn_cnt + 1 ;
      RAISE ex_worn ;
--
    END IF ;
--
    <<main_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      gn_target_cnt := gn_target_cnt + 1 ;
--
      ---------------------------------------------------------------------------------------------
      -- �˗��m���u���C�N�t���O�̐ݒ�
      ---------------------------------------------------------------------------------------------
      IF ( lv_temp_request_no = gt_main_data(i).request_no ) THEN
        lv_break_flg := gc_yes_no_n ;
      ELSE
        lv_break_flg       := gc_yes_no_y ;
        lv_temp_request_no := gt_main_data(i).request_no ;
      END IF ;
--
      -- ==========================================================================================
      -- F-05 �ʒm�Ϗ��쐬����
      -- ==========================================================================================
      IF ( gt_main_data(i).line_delete_flag = gc_delete_flag_n ) THEN
        prc_create_ins_data
          (
            in_idx        => i
           ,iv_break_flg  => lv_break_flg
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1 ;
          RAISE global_process_expt;
        END IF ;
      END IF ;
--
      -- ==========================================================================================
      -- F-06 �ύX�O������f�[�^�쐬����
      -- ==========================================================================================
      IF (   ( lv_break_flg                      = gc_yes_no_y       )        -- �˗��m���u���C�N
         AND ( gt_main_data(i).prev_notif_status = gc_notif_status_r ) ) THEN -- �O��ʒm�F�Ēʒm�v
        prc_create_can_data
          (
            iv_request_no           => gt_main_data(i).request_no
           ,ov_errbuf               => lv_errbuf
           ,ov_retcode              => lv_retcode
           ,ov_errmsg               => lv_errmsg
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1 ;
          RAISE global_process_expt;
        END IF ;
--
      END IF ;
--
    END LOOP main_loop ;
--
    -- ============================================================================================
    -- F-07 �ꊇ�o�^����
    -- ============================================================================================
    prc_ins_temp_data
      (
        ov_errbuf               => lv_errbuf
       ,ov_retcode              => lv_retcode
       ,ov_errmsg               => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
    END IF ;
--
    -- ============================================================================================
    -- F-08 �b�r�u�o�͏���
    -- ============================================================================================
    prc_out_csv_data
      (
        ov_errbuf               => lv_errbuf
       ,ov_retcode              => lv_retcode
       ,ov_errmsg               => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
    END IF ;
--
    -- ===========================================================================================
    -- F-09,F-10 �ʒm�ς݃f�[�^�o�^����
    -- ===========================================================================================
    prc_ins_out_data
      (
        ov_errbuf               => lv_errbuf
       ,ov_retcode              => lv_retcode
       ,ov_errmsg               => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
    END IF ;
--
    -- ===========================================================================================
    -- F-11 ���ڃG���[���O�o�͏���
    -- ===========================================================================================
    prc_put_err_log
      (
        ov_errbuf               => lv_errbuf
       ,ov_retcode              => lv_retcode
       ,ov_errmsg               => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
--
    -- �x��������
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      gn_warn_cnt := gn_warn_cnt + 1 ;
      RAISE ex_worn ;
--
    END IF ;
--
  EXCEPTION
    -- ============================================================================================
    -- �x������
    -- ============================================================================================
    WHEN ex_worn THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf ;
      ov_retcode := gv_status_warn;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
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
  PROCEDURE main
    (
      errbuf              OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W  --# �Œ� #
     ,retcode             OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h    --# �Œ� #
     ,iv_dept_code_01     IN  VARCHAR2          -- 01 : ����_01
     ,iv_dept_code_02     IN  VARCHAR2          -- 02 : ����_02(2008/07/17 Add)
     ,iv_dept_code_03     IN  VARCHAR2          -- 03 : ����_03(2008/07/17 Add)
     ,iv_dept_code_04     IN  VARCHAR2          -- 04 : ����_04(2008/07/17 Add)
     ,iv_dept_code_05     IN  VARCHAR2          -- 05 : ����_05(2008/07/17 Add)
     ,iv_dept_code_06     IN  VARCHAR2          -- 06 : ����_06(2008/07/17 Add)
     ,iv_dept_code_07     IN  VARCHAR2          -- 07 : ����_07(2008/07/17 Add)
     ,iv_dept_code_08     IN  VARCHAR2          -- 08 : ����_08(2008/07/17 Add)
     ,iv_dept_code_09     IN  VARCHAR2          -- 09 : ����_09(2008/07/17 Add)
     ,iv_dept_code_10     IN  VARCHAR2          -- 10 : ����_10(2008/07/17 Add)
     ,iv_date_fix         IN  VARCHAR2          -- 02 : �m��ʒm���{��
     ,iv_fix_from         IN  VARCHAR2          -- 03 : �m��ʒm���{����From
     ,iv_fix_to           IN  VARCHAR2          -- 04 : �m��ʒm���{����To
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
    submain
      (
        iv_dept_code_01     => iv_dept_code_01 -- 01 : ����
       ,iv_dept_code_02     => iv_dept_code_02 -- 02 : ����(2008/07/17 Add)
       ,iv_dept_code_03     => iv_dept_code_03 -- 03 : ����(2008/07/17 Add)
       ,iv_dept_code_04     => iv_dept_code_04 -- 04 : ����(2008/07/17 Add)
       ,iv_dept_code_05     => iv_dept_code_05 -- 05 : ����(2008/07/17 Add)
       ,iv_dept_code_06     => iv_dept_code_06 -- 06 : ����(2008/07/17 Add)
       ,iv_dept_code_07     => iv_dept_code_07 -- 07 : ����(2008/07/17 Add)
       ,iv_dept_code_08     => iv_dept_code_08 -- 08 : ����(2008/07/17 Add)
       ,iv_dept_code_09     => iv_dept_code_09 -- 09 : ����(2008/07/17 Add)
       ,iv_dept_code_10     => iv_dept_code_10 -- 10 : ����(2008/07/17 Add)
       ,iv_date_fix         => iv_date_fix     -- 11 : �m��ʒm���{��
       ,iv_fix_from         => iv_fix_from     -- 12 : �m��ʒm���{����From
       ,iv_fix_to           => iv_fix_to       -- 13 : �m��ʒm���{����To
       ,ov_errbuf           => lv_errbuf       -- �G���[�E���b�Z�[�W
       ,ov_retcode          => lv_retcode      -- ���^�[���E�R�[�h
       ,ov_errmsg           => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W
      ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    -- �G���[������
    IF ( lv_retcode = gv_status_error ) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
--
    -- �x��������
    IF (   ( lv_retcode = gv_status_warn )
       AND ( lv_errmsg IS NOT NULL       ) ) THEN
      FND_FILE.PUT_LINE( FND_FILE.LOG   , lv_errbuf ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_errmsg ) ;
    END IF;
--
    -- ====================================================
    -- �R���J�����g���O�̏o��
    -- ====================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;   --��؂蕶����o��
--
    -------------------------------------------------------
    -- ���̓p�����[�^
    -------------------------------------------------------
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '���̓p�����[�^' );
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@����_01 �@�@�@�@�@�@�F' || iv_dept_code_01) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@����_02 �@�@�@�@�@�@�F' || iv_dept_code_02) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@����_03 �@�@�@�@�@�@�F' || iv_dept_code_03) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@����_04 �@�@�@�@�@�@�F' || iv_dept_code_04) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@����_05 �@�@�@�@�@�@�F' || iv_dept_code_05) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@����_06 �@�@�@�@�@�@�F' || iv_dept_code_06) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@����_07 �@�@�@�@�@�@�F' || iv_dept_code_07) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@����_08 �@�@�@�@�@�@�F' || iv_dept_code_08) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@����_09 �@�@�@�@�@�@�F' || iv_dept_code_09) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@����_10 �@�@�@�@�@�@�F' || iv_dept_code_10) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@�m��ʒm���{���@�@�@�F' || iv_date_fix    ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@�m��ʒm���{����From�F' || iv_fix_from    ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@�m��ʒm���{����To�@�F' || iv_fix_to      ) ;
--
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;   --��؂蕶����o��
--
    -------------------------------------------------------
    -- �x�����b�Z�[�W
    -------------------------------------------------------
    IF ( gn_wrm_idx <> 0 ) THEN
      FOR i IN 1..gn_wrm_idx LOOP
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gt_worm_msg(i) ) ;
      END LOOP ;
--
      lv_retcode := gv_status_warn ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;   --��؂蕶����o��
--
    END IF ;
--
    -------------------------------------------------------
    -- ��������
    -------------------------------------------------------
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�b�r�u�o�͌���' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@�o�ׁF' || TO_CHAR( gn_out_cnt_syu, 'FM999,999,990' ));
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@�ړ��F' || TO_CHAR( gn_out_cnt_mov, 'FM999,999,990' ));
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
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
END xxwsh600004c ;
/
