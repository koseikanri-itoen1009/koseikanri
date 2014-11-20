CREATE OR REPLACE PACKAGE BODY XXINV500002C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXINV500002C(body)
 * Description      : �ړ��w�����捞
 * MD.050           : �ړ��˗� T_MD050_BPO_500
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ----------------------------------------------------------
 *  Name                      Description
 * ------------------------- ----------------------------------------------------------
 *  init                      ��������(B-1)
 *  get_interface_data        �ړ��w��IF���擾(B-2)
 *  chk_if_header_data        �ړ��w���w�b�_���`�F�b�N(B-3)
 *  get_max_ship_method       �ő�z���敪�E�����敪�擾(B-4,B-5)
 *  get_relating_data         �֘A�f�[�^�擾����(B-6,B-7)
 *  get_item_info             �i�ڏ��擾(B-9)
 *  chk_item_mst              �i�ڃ}�X�^�`�F�b�N(B-10)
 *  calc_best_amount          �œK���ʂ̎Z�o(B-11,B-12)
 *  calc_instruct_amount      �w�����ʂ̎Z�o(B-13,B-14,B-15)
 *  chk_loading_effic         �ύڌ����I�[�o�[�`�F�b�N(B-16)
 *  chk_sum_palette_sheets    �p���b�g���v�����`�F�b�N(B-17)
 *  chk_operating_day         �ғ����`�F�b�N(B-19)
 *  set_line_data             �ړ��w�����׏��ݒ�(B-18)
 *  set_header_data           �ړ��w���w�b�_���ݒ�(B-20)
 *  make_err_list             �G���[���X�g�쐬(B-21)
 *  ins_mov_req_instr_header  �ړ��w���w�b�_�o�^����(B-22)
 *  ins_mov_req_instr_line    �ړ��w�����דo�^����(B-23)
 *  purge_processing          �p�[�W����(B-24)
 *  put_err_list              �G���[���X�g�o��
 *  submain                   ���C�������v���V�[�W��
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 *  2011/03/04    1.0   SCS Y.Kanami     �V�K�쐬
 *
 ******************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal    CONSTANT VARCHAR2(1)  := '0';
  cv_status_warn      CONSTANT VARCHAR2(1)  := '1';
  cv_status_error     CONSTANT VARCHAR2(1)  := '2';
--
  cv_sts_cd_normal    CONSTANT VARCHAR2(1)  := 'C';
  cv_sts_cd_warn      CONSTANT VARCHAR2(1)  := 'G';
  cv_sts_cd_error     CONSTANT VARCHAR2(1)  := 'E';
--
  cv_msg_part         CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont         CONSTANT VARCHAR2(3)  := '.';
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
  lock_error_expt               EXCEPTION;     -- ���b�N�擾�G���[8
  no_data_if_expt               EXCEPTION;     -- �Ώۃf�[�^�Ȃ�
  err_header_expt               EXCEPTION;     -- �G���[���b�Z�[�W�쐬�㔻��
  PRAGMA EXCEPTION_INIT(lock_error_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT  VARCHAR2(100)   := 'XXINV500002C';            -- �p�b�P�[�W��
  cv_appl_short_name          CONSTANT  VARCHAR2(5)     := 'XXINV';                   -- ���b�Z�[�W
  cv_msg_kbn                  CONSTANT  VARCHAR2(5)     := 'XXCMN';                   -- ���b�Z�[�W
  cv_prod_cls_drink           CONSTANT  VARCHAR2(8)     := '�h�����N';
  cv_prod_cls_leaf            CONSTANT  VARCHAR2(6)     := '���[�t';
  cv_off                      CONSTANT  VARCHAR2(1)     := 'N';                       -- ���ьv��t���O�FN

  -- ���b�Z�[�W
  cv_msg_get_profile          CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10025';         -- �v���t�@�C���擾�G���[
  cv_msg_user_org             CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10083';         -- �����R�[�h�擾�G���[
  cv_msg_ng_rock              CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10032';         -- ���b�N�G���[
  cv_msg_no_data_1            CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10009';         -- �f�[�^�擾�G���[1
  cv_msg_no_data_2            CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10211';         -- �f�[�^�擾�G���[2
  cv_msg_get_seq              CONSTANT  VARCHAR2(15)    := 'APP-XXCMN-10029';         -- �̔ԃG���[
  cv_msg_user_org_id          CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10193';         -- ���[�U���������R�[�h
  cv_msg_shipped_loc          CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10194';         -- �o�ɑq��
  cv_err_msg_1                CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10061';         -- �K�{�`�F�b�N
  cv_err_msg_2                CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10199';         -- �ߋ����G���[
  cv_err_msg_3                CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10200';         -- �����G���[
  cv_err_msg_4                CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10210';         -- ���t�t�]�G���[
  cv_err_msg_5                CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10120';         -- �݌Ɋ��ԃG���[
  cv_err_msg_6                CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10208';         -- �ۊǑq�ɓ���G���[
  cv_err_msg_7                CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10201';         -- �Ó����G���[
  cv_err_msg_8                CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10202';         -- �i�ڃ}�X�^���ݒ�G���[
  cv_err_msg_9                CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10207';         -- ��ғ������b�Z�[�W
  cv_err_msg_10               CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10209';         -- �ύڌ����I�[�o�[�G���[
  cv_err_msg_11               CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10023';         -- �p���b�g�ő喇�����߃��b�Z�[�W
  cv_err_msg_12               CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10203';         -- �ғ����Z�o�֐��G���[
  cv_err_msg_13               CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10204';         -- �ړ��w��_�i�ڏd���G���[���b�Z�[�W
  cv_err_msg_14               CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10205';         -- �h�����N�E���[�t���ڃG���[
  cv_err_msg_15               CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10206';         -- �w�������ݒ�G���[
  cv_err_msg_16               CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10212';         -- ���ʊ֐��G���[
--
  -- �g�[�N��
  cv_tkn_profile_name         CONSTANT  VARCHAR2(100)   := 'XXCMN:�}�X�^�g�D';        -- �}�X�^�g�D
  cv_tkn_prf_prod_cls         CONSTANT  VARCHAR2(100)   := 'XXCMN:���i�敪';          -- ���i�敪(�Z�L�����e�B)
  cv_tkn_table                CONSTANT  VARCHAR2(15)    := 'TABLE';
  cv_tkn_mov_num              CONSTANT  VARCHAR2(8)     := '�ړ��ԍ�';
  cv_tkn_value                CONSTANT  VARCHAR2(5)     := 'VALUE';
  cv_tkn_msg                  CONSTANT  VARCHAR2(3)     := 'MSG';
  cv_tkn_item                 CONSTANT  VARCHAR2(4)     := 'ITEM';
  cv_tkv_name                 CONSTANT  VARCHAR2(4)     := 'NAME';
  cv_tkn_shipped_date         CONSTANT  VARCHAR2(9)     := 'SHIP_DATE';
  cv_tkn_ship_to_date         CONSTANT  VARCHAR2(12)    := 'ARRIVAL_DATE';
  cv_tkn_target_date          CONSTANT  VARCHAR2(11)    := 'TARGET_DATE';
  cv_tkn_seq_name             CONSTANT  VARCHAR2(10)    := 'SEQ_NAME';
  cv_tkn_user                 CONSTANT  VARCHAR2(4)     := 'USER';
  cv_tkn_chk                  CONSTANT  VARCHAR2(3)     := 'CHK';
  cv_tkn_err_msg              CONSTANT  VARCHAR2(7)     := 'ERR_MSG';
--
  -- �v���t�@�C��
  cv_prf_mst_org_id           CONSTANT  VARCHAR2(25)    := 'XXCMN_MASTER_ORG_ID';     -- XXCMN:�}�X�^�g�DID
  cv_prf_prod_class           CONSTANT  VARCHAR2(25)    := 'XXCMN_ITEM_DIV_SECURITY'; -- XXCMN:���i�敪(�Z�L�����e�B)
  -- ���b�N�Ώ�
  cv_rock_table               CONSTANT  VARCHAR2(100)   := '�ړ��w��IF���';
  -- �N�C�b�N�R�[�h
  cv_ship_method              CONSTANT  VARCHAR2(20)    := 'XXCMN_SHIP_METHOD';       -- �ő�z���敪
  cv_tab                      CONSTANT  VARCHAR2(2)     :=  CHR(9);                   -- �^�u
--
  -- �G���[���X�g���ږ�
  cv_kind                     CONSTANT  VARCHAR2(15)    := '���';
  cv_hdr_mov_if_id            CONSTANT  VARCHAR2(15)    := '�ړ��w�b�_IF_ID';
  cv_hdr_temp_ship_num        CONSTANT  VARCHAR2(15)    := '���`�[�ԍ�';
  cv_hdr_mov_type             CONSTANT  VARCHAR2(15)    := '�ړ��^�C�v';
  cv_hdr_instr_post_code      CONSTANT  VARCHAR2(15)    := '�w������';
  cv_hdr_shipped_code         CONSTANT  VARCHAR2(15)    := '�o�Ɍ��ۊǏꏊ';
  cv_hdr_ship_to_code         CONSTANT  VARCHAR2(15)    := '���ɐ�ۊǏꏊ';
  cv_hdr_sch_ship_date        CONSTANT  VARCHAR2(15)    := '�o�ɗ\���';
  cv_hdr_sch_arrival_date     CONSTANT  VARCHAR2(15)    := '���ɗ\���';
  cv_hdr_freight_charge_cls   CONSTANT  VARCHAR2(15)    := '�^���敪';
  cv_hdr_freight_carrier_cd   CONSTANT  VARCHAR2(15)    := '�^���Ǝ�';
  cv_hdr_weight_capacity_cls  CONSTANT  VARCHAR2(15)    := '�d�ʗe�ϋ敪';
  cv_hdr_product_flg          CONSTANT  VARCHAR2(15)    := '���i���ʋ敪';
  cv_hdr_mov_line_if_id       CONSTANT  VARCHAR2(15)    := '�ړ�����IF_ID';
  cv_hdr_item_code            CONSTANT  VARCHAR2(15)    := '�i��';
  cv_hdr_desined_prod_date    CONSTANT  VARCHAR2(15)    := '�w�萻����';
  cv_hdr_first_instruct_qty   CONSTANT  VARCHAR2(15)    := '����w������';
  cv_hdr_err_msg              CONSTANT  VARCHAR2(16)    := '�G���[���b�Z�[�W';
  cv_hdr_err_clm              CONSTANT  VARCHAR2(16)    := '�G���[����';
  cv_line                     CONSTANT  VARCHAR2(50)    := '--------------------------------------------------';
--
  -- ���b�Z�[�W����
  cv_max_shopped_method       CONSTANT  VARCHAR2(12)    := '�ő�z���敪';
  cv_small_amount_cls         CONSTANT  VARCHAR2(8)     := '�����敪';
  cv_shpped_loc_id            CONSTANT  VARCHAR2(10)    := '�o�Ɍ����';
  cv_shp_to_loc_id            CONSTANT  VARCHAR2(10)    := '���ɐ���';
  cv_freight_carrier_id       CONSTANT  VARCHAR2(12)    := '�^���Ǝҏ��';
  cv_max_pallet               CONSTANT  VARCHAR2(16)    := '�ő�p���b�g����';
  cv_delivery_qty             CONSTANT  VARCHAR2(4)     := '�z��';
  cv_max_pallet_steps         CONSTANT  VARCHAR2(20)    := '�p���b�g����ő�i��';
  cv_num_of_cases             CONSTANT  VARCHAR2(10)    := '�P�[�X����';
  cv_over_check_1             CONSTANT  VARCHAR2(30)    := '�ύڌ����`�F�b�N(�ύڌ����Z�o)';
  cv_over_check_2             CONSTANT  VARCHAR2(30)    := '�ύڌ����`�F�b�N(���v�l�Z�o)';
--
  -- �G���[���X�g�\�����e
  cv_msg_hfn                  CONSTANT  VARCHAR2(2)     := '�|';
  cv_msg_err                  CONSTANT  VARCHAR2(6)     := '�G���[';
  cv_msg_war                  CONSTANT  VARCHAR2(4)     := '�x��';
--
  -- ���ʊ֐��F�G���[����p
  cv_error                    CONSTANT  VARCHAR2(1)     :=  '1';  -- �G���[
  cv_normal                   CONSTANT  VARCHAR2(1)     :=  '0';  -- ����
--
  cn_pre_data_cnt             CONSTANT  NUMBER          :=  1;    -- 1���R�[�h�O�̃f�[�^CNT
  cn_status_error             CONSTANT  NUMBER          :=  1;    -- ���ʊ֐��F�G���[
  cn_status_normal            CONSTANT  NUMBER          :=  0;    -- ���ʊ֐��F����
  cv_warehouses               CONSTANT  VARCHAR2(1)     :=  '4';  -- �q��
  cv_own_warehouse            CONSTANT  VARCHAR2(1)     :=  '0';  -- ���Бq��
  cv_prod_cls_prod            CONSTANT  VARCHAR2(1)     :=  '1';  -- ���i���ʋ敪�F���i
  cv_prod_cls_others          CONSTANT  VARCHAR2(1)     :=  '2';  -- ���i���ʋ敪�F���i�ȊO
  cv_product                  CONSTANT  VARCHAR2(1)     :=  '5';  -- ���i
  cv_drink                    CONSTANT  VARCHAR2(1)     :=  '2';  -- ���i�敪�F�h�����N
  cv_on                       CONSTANT  VARCHAR2(1)     :=  '1';  -- �t���O�FON
  cn_on                       CONSTANT  NUMBER          :=  1;    -- �t���O�FON
  cv_object                   CONSTANT  VARCHAR2(1)     :=  '1';  -- �Ώ�
  cv_not_object               CONSTANT  VARCHAR2(1)     :=  '0';  -- �ΏۊO
  cv_nodata                   CONSTANT  VARCHAR2(1)     :=  '1';  -- �Ώۃf�[�^�Ȃ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �ړ��w��IF�擾�p
  TYPE mod_instr_rtype IS RECORD (
      mov_hdr_if_id             xxinv_mov_instr_headers_if.mov_hdr_if_id%TYPE                 -- �ړ��w�b�_IF_ID
    , temp_ship_num             xxinv_mov_instr_headers_if.temp_ship_num%TYPE                 -- ���`�[�ԍ�
    , mov_type                  xxinv_mov_instr_headers_if.mov_type%TYPE                      -- �ړ��^�C�v
    , instr_post_code           xxinv_mov_instr_headers_if.instruction_post_code%TYPE         -- �w������
    , shipped_locat_code        xxinv_mov_instr_headers_if.shipped_locat_code%TYPE            -- �o�Ɍ��ۊǏꏊ
    , ship_to_locat_code        xxinv_mov_instr_headers_if.ship_to_locat_code%TYPE            -- ���ɐ�ۊǏꏊ
    , schedule_ship_date        xxinv_mov_instr_headers_if.schedule_ship_date%TYPE            -- �o�ɗ\���
    , schedule_arrival_date     xxinv_mov_instr_headers_if.schedule_arrival_date%TYPE         -- ���ɗ\���
    , freight_charge_class      xxinv_mov_instr_headers_if.freight_charge_class%TYPE          -- �^���敪
    , freight_carrier_code      xxinv_mov_instr_headers_if.freight_carrier_code%TYPE          -- �^���Ǝ�
    , weight_capacity_class     xxinv_mov_instr_headers_if.weight_capacity_class%TYPE         -- �d�ʗe�ϋ敪
    , product_flg               xxinv_mov_instr_headers_if.product_flg%TYPE                   -- ���i���ʋ敪
    , mov_line_if_id            xxinv_mov_instr_lines_if.mov_line_if_id%TYPE                  -- �ړ�����IF_ID
    , item_code                 xxinv_mov_instr_lines_if.item_code%TYPE                       -- �i��
    , designated_prod_date      xxinv_mov_instr_lines_if.designated_production_date%TYPE      -- �w�萻����
    , first_instruct_qty        xxinv_mov_instr_lines_if.first_instruct_qty%TYPE              -- ����w������
  );
--
  TYPE mod_instr_ttype  IS TABLE OF mod_instr_rtype INDEX BY BINARY_INTEGER;
--
  g_mov_instr_tab   mod_instr_ttype;
--
  -- �ړ��w�����o�^�p
  -- �w�b�_����
  TYPE mov_hdr_id_ttype             IS TABLE OF
      xxinv_mov_req_instr_headers.mov_hdr_id%TYPE                   INDEX BY BINARY_INTEGER;  -- �ړ��w�b�__ID
  TYPE mov_num_ttype                IS TABLE OF
      xxinv_mov_req_instr_headers.mov_num%TYPE                      INDEX BY BINARY_INTEGER;  -- �ړ��ԍ�
  TYPE mov_type_ttype               IS TABLE OF
      xxinv_mov_req_instr_headers.mov_type%TYPE                     INDEX BY BINARY_INTEGER;  -- �ړ��^�C�v
  TYPE instruction_post_code_ttype  IS TABLE OF
      xxinv_mov_req_instr_headers.instruction_post_code%TYPE        INDEX BY BINARY_INTEGER;  -- �w������
  TYPE shipped_locat_code_ttype     IS TABLE OF
      xxinv_mov_req_instr_headers.shipped_locat_code%TYPE           INDEX BY BINARY_INTEGER;  -- �o�Ɍ��ۊǏꏊ
  TYPE ship_to_locat_code_ttype     IS TABLE OF
      xxinv_mov_req_instr_headers.ship_to_locat_code%TYPE           INDEX BY BINARY_INTEGER;  -- ���ɐ�ۊǏꏊ
  TYPE schedule_ship_date_ttype     IS TABLE OF
      xxinv_mov_req_instr_headers.schedule_ship_date%TYPE           INDEX BY BINARY_INTEGER;  -- �o�ɗ\���
  TYPE schedule_arrival_date_ttype  IS TABLE OF
      xxinv_mov_req_instr_headers.schedule_arrival_date%TYPE        INDEX BY BINARY_INTEGER;  -- ���ɗ\���
  TYPE freight_charge_class_ttype   IS TABLE OF
      xxinv_mov_req_instr_headers.freight_charge_class%TYPE         INDEX BY BINARY_INTEGER;  -- �^���敪
  TYPE freight_carrier_code_ttype   IS TABLE OF
      xxinv_mov_req_instr_headers.freight_carrier_code%TYPE         INDEX BY BINARY_INTEGER;  -- �^���Ǝ�
  TYPE weight_capacity_class_ttype  IS TABLE OF
      xxinv_mov_req_instr_headers.weight_capacity_class%TYPE        INDEX BY BINARY_INTEGER;  -- �d�ʗe�ϋ敪
  TYPE item_class_ttype             IS TABLE OF
      xxinv_mov_req_instr_headers.item_class%TYPE                   INDEX BY BINARY_INTEGER;  -- ���i�敪
  TYPE product_flg_ttype            IS TABLE OF
      xxinv_mov_req_instr_headers.product_flg%TYPE                  INDEX BY BINARY_INTEGER;  -- ���i���ʋ敪
  TYPE shipped_locat_id_ttype       IS TABLE OF
      xxinv_mov_req_instr_headers.shipped_locat_id%TYPE             INDEX BY BINARY_INTEGER;  -- �o�Ɍ�ID
  TYPE ship_to_locat_id_ttype       IS TABLE OF
      xxinv_mov_req_instr_headers.ship_to_locat_id%TYPE             INDEX BY BINARY_INTEGER;  -- ���ɐ�ID
  TYPE loading_weight_ttype         IS TABLE OF
      xxinv_mov_req_instr_headers.loading_efficiency_weight%TYPE    INDEX BY BINARY_INTEGER;  -- �ύڗ�(�d��)
  TYPE loading_capacity_ttype       IS TABLE OF
      xxinv_mov_req_instr_headers.loading_efficiency_capacity%TYPE  INDEX BY BINARY_INTEGER;  -- �ύڗ�(�e��)
  TYPE career_id_ttype              IS TABLE OF
      xxinv_mov_req_instr_headers.career_id%TYPE                    INDEX BY BINARY_INTEGER;  -- �^���Ǝ�ID
  TYPE shipping_method_code_ttype   IS TABLE OF
      xxinv_mov_req_instr_headers.shipping_method_code%TYPE         INDEX BY BINARY_INTEGER;  -- �z���敪
  TYPE sum_quantity_ttype           IS TABLE OF
      xxinv_mov_req_instr_headers.sum_quantity%TYPE                 INDEX BY BINARY_INTEGER;  -- ���v����
  TYPE small_quantity_ttype         IS TABLE OF
      xxinv_mov_req_instr_headers.small_quantity%TYPE               INDEX BY BINARY_INTEGER;  -- ������
  TYPE label_quantity_ttype         IS TABLE OF
      xxinv_mov_req_instr_headers.label_quantity%TYPE               INDEX BY BINARY_INTEGER;  -- ���x������
  TYPE based_weight_ttype           IS TABLE OF
      xxinv_mov_req_instr_headers.based_weight%TYPE                 INDEX BY BINARY_INTEGER;  -- ��{�d��
  TYPE based_capacity_ttype         IS TABLE OF
      xxinv_mov_req_instr_headers.based_capacity%TYPE               INDEX BY BINARY_INTEGER;  -- ��{�e��
  TYPE sum_weight_ttype             IS TABLE OF
      xxinv_mov_req_instr_headers.sum_weight%TYPE                   INDEX BY BINARY_INTEGER;  -- �ύڏd�ʍ��v
  TYPE sum_capacity_ttype           IS TABLE OF
      xxinv_mov_req_instr_headers.sum_capacity%TYPE                 INDEX BY BINARY_INTEGER;  -- �ύڗe�ύ��v
  TYPE sum_pallet_weight_ttype      IS TABLE OF
      xxinv_mov_req_instr_headers.sum_pallet_weight%TYPE            INDEX BY BINARY_INTEGER;  -- ���v�p���b�g�d��
  TYPE pallet_sum_qty_ttype         IS TABLE OF
      xxinv_mov_req_instr_headers.pallet_sum_quantity%TYPE          INDEX BY BINARY_INTEGER;  -- �p���b�g���v����
--
  -- ���׍���
  TYPE mov_line_id_ttype            IS TABLE OF
      xxinv_mov_req_instr_lines.mov_line_id%TYPE                    INDEX BY BINARY_INTEGER;  -- �ړ��w������ID
  TYPE mov_line_hdr_id_ttype        IS TABLE OF
      xxinv_mov_req_instr_lines.mov_hdr_id%TYPE                     INDEX BY BINARY_INTEGER;  -- �ړ��w�b�_ID
  TYPE line_number_ttype            IS TABLE OF
      xxinv_mov_req_instr_lines.line_number%TYPE                    INDEX BY BINARY_INTEGER;  -- ���הԍ�
  TYPE item_code_ttype              IS TABLE OF
      xxinv_mov_req_instr_lines.item_code%TYPE                      INDEX BY BINARY_INTEGER;  -- �i��
  TYPE designated_prod_date_ttype   IS TABLE OF
      xxinv_mov_req_instr_lines.designated_production_date%TYPE     INDEX BY BINARY_INTEGER;  -- �w�萻����
  TYPE first_instruct_qty_ttype     IS TABLE OF
      xxinv_mov_req_instr_lines.first_instruct_qty%TYPE             INDEX BY BINARY_INTEGER;  -- ����w������
  TYPE item_id_ttype                IS TABLE OF
      xxinv_mov_req_instr_lines.item_id%TYPE                        INDEX BY BINARY_INTEGER;  -- �i��ID
  TYPE pallet_quantity_ttype        IS TABLE OF
      xxinv_mov_req_instr_lines.pallet_quantity%TYPE                INDEX BY BINARY_INTEGER;  -- �p���b�g��
  TYPE layer_qty_ttype              IS TABLE OF
      xxinv_mov_req_instr_lines.layer_quantity%TYPE                 INDEX BY BINARY_INTEGER;  -- �i��
  TYPE case_qty_ttype               IS TABLE OF
      xxinv_mov_req_instr_lines.case_quantity%TYPE                  INDEX BY BINARY_INTEGER;  -- �P�[�X��
  TYPE instr_qty_ttype              IS TABLE OF
      xxinv_mov_req_instr_lines.instruct_qty%TYPE                   INDEX BY BINARY_INTEGER;  -- �w������
  TYPE uom_code_ttype               IS TABLE OF
      xxinv_mov_req_instr_lines.uom_code%TYPE                       INDEX BY BINARY_INTEGER;  -- �P��
  TYPE pallet_qty_ttype             IS TABLE OF
      xxinv_mov_req_instr_lines.pallet_qty%TYPE                     INDEX BY BINARY_INTEGER;  -- �p���b�g����
  TYPE weight_ttype                 IS TABLE OF
      xxinv_mov_req_instr_lines.weight%TYPE                         INDEX BY BINARY_INTEGER;  -- �d��
  TYPE capacity_ttype               IS TABLE OF
      xxinv_mov_req_instr_lines.capacity%TYPE                       INDEX BY BINARY_INTEGER;  -- �e��
  TYPE pallet_weight_ttype          IS TABLE OF
      xxinv_mov_req_instr_lines.pallet_weight%TYPE                  INDEX BY BINARY_INTEGER;  -- �p���b�g�d��
--
  -- �ړ��w�����o�^�pPL/SQL�\
  -- �w�b�_����
  g_mov_hdr_id_tab                mov_hdr_id_ttype;               -- �ړ��w�b�_ID
  g_mov_type_tab                  mov_type_ttype;                 -- �ړ��^�C�v
  g_mov_num_tab                   mov_num_ttype;                  -- �ړ��ԍ�
  g_instruction_post_code_tab     instruction_post_code_ttype;    -- �w������
  g_shipped_locat_code_tab        shipped_locat_code_ttype;       -- �o�Ɍ��ۊǏꏊ
  g_ship_to_locat_code_tab        ship_to_locat_code_ttype;       -- ���ɐ�ۊǏꏊ
  g_schedule_ship_date_tab        schedule_ship_date_ttype;       -- �o�ɗ\���
  g_schedule_arrival_date_tab     schedule_arrival_date_ttype;    -- ���ɗ\���
  g_freight_charge_class_tab      freight_charge_class_ttype;     -- �^���敪
  g_freight_carrier_code_tab      freight_carrier_code_ttype;     -- �^���Ǝ�
  g_weight_capacity_class_tab     weight_capacity_class_ttype;    -- �d�ʗe�ϋ敪
  g_product_flg_tab               product_flg_ttype;              -- ���i���ʋ敪
  g_item_class_tab                item_class_ttype;               -- ���i�敪
  g_shipped_locat_id_tab          shipped_locat_id_ttype;         -- �o�Ɍ�ID
  g_ship_to_locat_id_tab          ship_to_locat_id_ttype;         -- ���ɐ�ID
  g_loading_weight_tab            loading_weight_ttype;           -- �ύڗ�(�d��)
  g_loading_capacity_tab          loading_capacity_ttype;         -- �ύڗ�(�e��)
  g_career_id_tab                 career_id_ttype;                -- �^���Ǝ�ID
  g_shipping_method_code_tab      shipping_method_code_ttype;     -- �z���敪
  g_sum_qty_tab                   sum_quantity_ttype;             -- ���v����
  g_small_qty_tab                 small_quantity_ttype;           -- ������
  g_label_qty_tab                 label_quantity_ttype;           -- ���x������
  g_based_weight_tab              based_weight_ttype;             -- ��{�d��
  g_based_capacity_tab            based_capacity_ttype;           -- ��{�e��
  g_sum_weight_tab                sum_weight_ttype;               -- �ύڏd�ʍ��v
  g_sum_capacity_tab              sum_capacity_ttype;             -- �ύڗe�ύ��v
  g_sum_pallet_weight_tab         sum_pallet_weight_ttype;        -- ���v�p���b�g�d��
  g_sum_pallet_qty                pallet_sum_qty_ttype;           -- �p���b�g���v����
--
  -- ���׍���
  g_mov_line_id_tab               mov_line_id_ttype;              -- �ړ�����ID
  g_mov_line_hdr_id_tab           mov_line_hdr_id_ttype;          -- �ړ��w�b�_ID
  g_mov_number_tab                line_number_ttype;              -- ���הԍ�
  g_item_code_tab                 item_code_ttype;                -- �i��
  g_designated_prod_date_tab      designated_prod_date_ttype;     -- �w�萻����
  g_first_instruct_qty_tab        first_instruct_qty_ttype;       -- ����w������
  g_item_id_tab                   item_id_ttype;                  -- �i��ID
  g_pallet_qty_tab                pallet_quantity_ttype;          -- �p���b�g��
  g_layer_qty_tab                 layer_qty_ttype;                -- �i��
  g_case_qty_tab                  case_qty_ttype;                 -- �P�[�X��
  g_instr_qty_tab                 instr_qty_ttype;                -- �w������
  g_uom_code_tab                  uom_code_ttype;                 -- �P��
  g_pallet_num_of_sheet_tab       pallet_qty_ttype;               -- �p���b�g����
  g_weight_tab                    weight_ttype;                   -- �d��
  g_capacity_tab                  capacity_ttype;                 -- �e��
  g_pallet_weight_tab             pallet_weight_ttype;            -- �p���b�g�d��
--
  -- �G���[���X�g�p�z��
  TYPE err_list_rtype IS RECORD(
    err_msg VARCHAR2(10000)
  );
--
  TYPE err_list_ttype IS TABLE OF err_list_rtype INDEX BY BINARY_INTEGER;
--
  g_err_list_tab  err_list_ttype;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_sysdate                DATE;             -- �V�X�e�����t
  -- WHO�J����
  gn_user_id                NUMBER;           -- ���[�UID
  gv_user_name              VARCHAR2(100);    -- ���[�U��
  gn_login_id               NUMBER;           -- �ŏI�X�V���O�C��
  gn_conc_request_id        NUMBER;           -- �v��ID
  gn_prog_appl_id           NUMBER;           -- �R���J�����g�̃A�v���P�[�V����ID
  gn_conc_program_id        NUMBER;           -- �R���J�����g�E�v���O����ID
--
  gv_master_org_id          VARCHAR2(100);    -- �}�X�^�g�D
  gv_user_dept_id           VARCHAR2(100);    -- ���O�C�����[�U��������
  gv_err_status             VARCHAR2(1);      -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X�m�F�p
  gv_err_line_status        VARCHAR2(1);      -- ���׃G���[�X�e�[�^�X
--
  gn_if_data_cnt            NUMBER;           -- �C���^�t�F�[�X�o�^�p�J�E���^
  gn_cnt                    NUMBER;           -- �����p�J�E���^
  gn_err_set_cnt            NUMBER;           -- �G���[���X�g�p�J�E���^
  gv_err_report             VARCHAR2(5000);   -- �G���[���X�g�w�b�_�p
--
  gv_err_flg                VARCHAR2(1);      -- 
--
  gn_header_id              NUMBER;           -- �ړ��w���w�b�_ID
  gn_line_id                NUMBER;           -- �ړ��w������ID
  gn_mov_instr_hdr_cnt      NUMBER;           -- �w�b�_����
  gn_mov_instr_line_cnt     NUMBER;           -- ���׌���
  gn_line_number_cnt        NUMBER;           -- �w�b�_�P�ʖ��׌���
--
  gv_secur_prod_class       VARCHAR2(1);      -- ���i�敪(�Z�L�����e�B)
  gv_max_ship_method        VARCHAR2(2);      -- �ő�z���敪
  gn_drink_deadweight       NUMBER;           -- �h�����N��{�d��
  gn_leaf_deadweight        NUMBER;           -- ���[�t��{�d��
  gn_drink_loading_capa     NUMBER;           -- �h�����N��{�e��
  gn_leaf_loading_capa      NUMBER;           -- ���[�t��{�e��
  gn_palette_max_qty        NUMBER;           -- �p���b�g�ő喇��
  gv_small_amount_cls       VARCHAR2(1);      -- �����敪
  gv_shipped_id             VARCHAR2(4);      -- �o�Ɍ�ID
  gv_ship_to_id             VARCHAR2(4);      -- ���ɐ�ID
  gn_carrier_id             NUMBER;           -- �^���Ǝ�ID
  gn_item_id                NUMBER;           -- �i��ID
  gv_item_desc              VARCHAR2(70);     -- �i�ڂ̓K�p
  gv_item_um                VARCHAR2(4);      -- �P��
  gv_conv_unit              VARCHAR2(240);    -- ���o�Ɋ��Z�P��
  gn_delivery_qty           NUMBER;           -- �z��
  gn_max_palette_steps      NUMBER;           -- �p���b�g����ő�i��
  gn_num_of_cases           NUMBER;           -- �P�[�X����
  gn_num_of_deliver         NUMBER;           -- �o�ד���
  gv_prod_cls               VARCHAR2(1);      -- ���i�敪
  gn_max_case_for_palette   NUMBER;           -- �p���b�g����̍ő�P�[�X��
  gn_best_num_palette       NUMBER;           -- �œK���ʁF�p���b�g��
  gn_best_num_steps         NUMBER;           -- �œK���ʁF�i��
  gn_best_num_cases         NUMBER;           -- �œK���ʁF�P�[�X��
  gv_item_mst_chk_sts       VARCHAR2(1);      -- �i�ڃ}�X�^�`�F�b�N�X�e�[�^�X
  gn_palette_num            NUMBER;           -- �p���b�g����
  gn_sum_palette_num        NUMBER;           -- �p���b�g���v����
  gn_instruct_qty           NUMBER;           -- �w������
  gn_ttl_instruct_qty       NUMBER;           -- �w�����ʍ��v
  gn_ttl_weight             NUMBER;           -- ���v�d��
  gn_ttl_capacity           NUMBER;           -- ���v�e��
  gn_ttl_palette_weight     NUMBER;           -- ���v�p���b�g�d��
  gn_sum_ttl_weight         NUMBER;           -- �����v�d��
  gn_sum_ttl_capacity       NUMBER;           -- �����v�e��
  gn_sum_ttl_palette_weight NUMBER;           -- �����v�p���b�g�d��
  gn_sml_amnt_num           NUMBER;           -- ������
  gn_ttl_sml_amnt_num       NUMBER;           -- ���������v
  gn_label_num              NUMBER;           -- ���x������
  gn_ttl_label_num          NUMBER;           -- ���x���������v
  gv_shipped_locat_code     VARCHAR2(4);      -- �o�Ɍ��R�[�h[�ύڌ����`�F�b�N�p]
  gv_ship_to_locat_code     VARCHAR2(4);      -- ���ɐ�R�[�h[�ύڌ����`�F�b�N�p]
  gd_schedule_ship_date     DATE;             -- �o�ɓ�[�ύڌ����`�F�b�N�p]
  gn_we_loading             NUMBER;           -- �ύڗ�(�d��)
  gn_ca_loading             NUMBER;           -- �ύڗ�(�e��)
  gv_msg_prod_cls           VARCHAR2(8);      -- ���b�Z�[�W�p���i�敪
  gv_nodata_error           VARCHAR2(1);      -- �Ώۃf�[�^�擾�G���[
  gb_get_item_flg           BOOLEAN;          -- �i�ڎ擾�t���O(TRUE:�擾,FALSE:���擾)
  gv_carrier_code           VARCHAR2(4);      -- �^���Ǝ҃R�[�h
--
  /**********************************************************************************
   * Procedure Name   : make_err_list
   * Description      : �G���[���X�g�쐬(B-21)
   ***********************************************************************************/
  PROCEDURE make_err_list(
      iv_kind       IN  VARCHAR2  --    �G���[���
    , iv_err_info   IN  VARCHAR2  --    �G���[���b�Z�[�W
    , in_rec_cnt    IN  NUMBER    --    �o�͑Ώۃ��R�[�h�J�E���g
    , ov_errbuf     OUT VARCHAR2  --    �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2  --    ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2  --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'make_err_list';  -- �v���O������
    cv_dt_fmt_yyyymmdd  CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';     -- ���t�����FYYYY/MM/DD
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
    lv_err_list VARCHAR2(10000);
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ------------------------------
    -- ���ʃG���[���b�Z�[�W�̍쐬
    ------------------------------
    lv_err_list :=             iv_kind                                                              -- ���
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).mov_hdr_if_id                            -- �ړ��w��IF_ID
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).temp_ship_num                            -- ���`�[�ԍ�
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).mov_type                                 -- �ړ��^�C�v
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).instr_post_code                          -- �w������
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).shipped_locat_code                       -- �o�Ɍ��ۊǏꏊ
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).ship_to_locat_code                       -- ���ɐ�ۊǏꏊ
                  || cv_tab || TO_CHAR(g_mov_instr_tab(in_rec_cnt).schedule_ship_date, cv_dt_fmt_yyyymmdd)    
                                                                                                    -- �o�ɗ\���
                  || cv_tab || TO_CHAR(g_mov_instr_tab(in_rec_cnt).schedule_arrival_date, cv_dt_fmt_yyyymmdd) 
                                                                                                    -- ���ɗ\���
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).freight_charge_class                     -- �^���敪
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).freight_carrier_code                     -- �^���Ǝ�
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).weight_capacity_class                    -- �d�ʗe�ϋ敪
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).product_flg                              -- ���i���ʋ敪
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).mov_line_if_id                           -- ����ID
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).item_code                                -- �i��
                  || cv_tab || TO_CHAR(g_mov_instr_tab(in_rec_cnt).designated_prod_date, cv_dt_fmt_yyyymmdd)   
                                                                                                    -- �w�萻����
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).first_instruct_qty                       -- ����w������
                  || cv_tab || iv_err_info                                                          -- �G���[���b�Z�[�W
    ;
--
    -- �G���[�Z�b�g�J�E���g
    gn_err_set_cnt := gn_err_set_cnt + 1;
--
    -- ���ʃG���[���b�Z�[�W�i�[
    g_err_list_tab(gn_err_set_cnt).err_msg  := lv_err_list;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <��O�R�����g> ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
  END make_err_list;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(B-1)
   ***********************************************************************************/
  PROCEDURE init(
      ov_errbuf     OUT VARCHAR2  --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2  --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -----------------------
    -- �V�X�e�����t���擾
    -----------------------
    gd_sysdate := SYSDATE;
--
    -----------------------
    -- WHO�J�����擾
    -----------------------
    gn_user_id          :=  fnd_global.user_id;         -- ���[�UID
    gv_user_name        :=  fnd_global.user_name;       -- ���[�U��
    gn_login_id         :=  fnd_global.login_id;        -- �ŏI�X�V���O�C��
    gn_conc_request_id  :=  fnd_global.conc_request_id; -- �v��ID
    gn_prog_appl_id     :=  fnd_global.prog_appl_id;    -- �R���J�����g�̃A�v���P�[�V����ID
    gn_conc_program_id  :=  fnd_global.conc_program_id; -- �R���J�����g�E�v���O����ID
--
    -----------------------
    -- �}�X�^�g�DID�擾
    -----------------------
    gv_master_org_id := FND_PROFILE.VALUE(cv_prf_mst_org_id);
--
    -- �}�X�^�g�DID���擾�ł��Ȃ��ꍇ
    IF (gv_master_org_id IS NULL) THEN
--
      lv_errmsg := xxcmn_common_pkg.get_msg ( cv_appl_short_name
                                            , cv_msg_get_profile
                                            , cv_tkv_name
                                            , cv_tkn_profile_name
                                            );
      lv_errbuf := lv_errmsg;
--
      -- �K�{���ڏo�͗p
      gv_nodata_error := cv_nodata;
--
      RAISE global_api_expt;
--
    END IF;
--
    -------------------------------
    -- ���i�敪(�Z�L�����e�B)�擾
    -------------------------------
    gv_secur_prod_class := FND_PROFILE.VALUE(cv_prf_prod_class);
--
    IF (gv_secur_prod_class IS NULL) THEN
--
      lv_errmsg := xxcmn_common_pkg.get_msg ( cv_appl_short_name
                                            , cv_msg_get_profile
                                            , cv_tkv_name
                                            , cv_tkn_prf_prod_cls
                                            );
      lv_errbuf := lv_errmsg;
--
      -- �K�{���ڏo�͗p
      gv_nodata_error := cv_nodata;
--
      RAISE global_api_expt;
--
    END IF;
--
    --------------------------------
    -- ���O�C�����[�U�����������擾
    --------------------------------
    gv_user_dept_id  :=  xxcmn_common_pkg.get_user_dept_code(gn_user_id);
    IF (gv_user_dept_id IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg ( cv_appl_short_name
                                            , cv_msg_user_org
                                            , cv_tkn_user
                                            , gv_user_name
                                            );
      lv_errbuf := lv_errmsg;
--
      -- �K�{���ڏo�͗p
      gv_nodata_error := cv_nodata;
--
      RAISE global_api_expt;
--
    END IF;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <��O�R�����g> ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_interface_data
   * Description      : �ړ��w��IF���擾(B-2)
   ***********************************************************************************/
  PROCEDURE get_interface_data(
      in_shipped_locat_cd  IN VARCHAR2 DEFAULT NULL  -- �o�Ɍ��R�[�h(�C��)
    , ov_errbuf               OUT VARCHAR2              -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode              OUT VARCHAR2              -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg               OUT VARCHAR2              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_interface_data'; -- �v���O������
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
    -- �ړ��w��IF�擾�J�[�\��
    CURSOR mov_instr_if_cur IS
      SELECT  xmihi.mov_hdr_if_id                             -- �ړ��w�b�_IF_ID
            , xmihi.temp_ship_num                             -- ���`�[�ԍ�
            , xmihi.mov_type                                  -- �ړ��^�C�v
            , xmihi.instruction_post_code                     -- �w������
            , xmihi.shipped_locat_code                        -- �o�Ɍ��ۊǏꏊ
            , xmihi.ship_to_locat_code                        -- ���ɐ�ۊǏꏊ
            , xmihi.schedule_ship_date                        -- �o�ɗ\���
            , xmihi.schedule_arrival_date                     -- ���ɗ\���
            , xmihi.freight_charge_class                      -- �^���敪
            , xmihi.freight_carrier_code                      -- �^���Ǝ�
            , xmihi.weight_capacity_class                     -- �d�ʗe�ϋ敪
            , xmihi.product_flg                               -- ���i���ʋ敪
            , xmili.mov_line_if_id                            -- ����ID
            , xmili.item_code                                 -- �i��
            , xmili.designated_production_date                -- �w�萻����
            , NVL(xmili.first_instruct_qty, 0)                -- ����w������
      FROM    xxinv_mov_instr_headers_if  xmihi               -- �ړ��w���w�b�_�C���^�t�F�[�X(�A�h�I��)
            , xxinv_mov_instr_lines_if    xmili               -- �ړ��w�����׃C���^�t�F�[�X(�A�h�I��)
      WHERE xmihi.mov_hdr_if_id         = xmili.mov_hdr_if_id -- �ړ��w�b�_IF_ID
      AND   xmihi.instruction_post_code = gv_user_dept_id     -- �ړ��w�������R�[�h
      AND   ((in_shipped_locat_cd IS NULL)                    -- �o�Ɍ��ۊǏꏊ
          OR (shipped_locat_code = in_shipped_locat_cd))
      ORDER BY xmihi.mov_hdr_if_id
             , xmili.item_code
      FOR UPDATE OF xmihi.mov_hdr_if_id NOWAIT
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ----------------------------------
    -- �ړ��w���C���^�t�F�[�X���擾
    ----------------------------------
    -- �J�[�\���I�[�v��
    OPEN mov_instr_if_cur;
    -- �o���N�t�F�b�`
    FETCH mov_instr_if_cur BULK COLLECT INTO g_mov_instr_tab;
    -- �J�[�\���N���[�Y
    CLOSE mov_instr_if_cur;
--
    -- �f�[�^���擾�o���Ȃ������ꍇ
    IF (g_mov_instr_tab.COUNT = 0) THEN
--
      lv_errmsg := xxcmn_common_pkg.get_msg(  cv_appl_short_name
                                            , cv_msg_no_data_1
                                            , cv_tkn_msg
                                            , cv_rock_table
                                            );
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      ov_retcode := cv_status_warn;
--
      -- �K�{���ڏo�͗p
      gv_nodata_error := cv_nodata;
--
      RETURN;
--
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    WHEN lock_error_expt THEN                           --*** ���b�N�擾�G���[ ***
      -- �J�[�\���I�[�v�����N���[�Y����
      IF (mov_instr_if_cur%ISOPEN) THEN
        CLOSE mov_instr_if_cur;
      END IF;
--
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxcmn_common_pkg.get_msg(  cv_appl_short_name
                                            , cv_msg_ng_rock
                                            , cv_tkn_table
                                            , cv_rock_table
                                            );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      IF (mov_instr_if_cur%ISOPEN) THEN
        CLOSE mov_instr_if_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���I�[�v�����N���[�Y����
      IF (mov_instr_if_cur%ISOPEN) THEN
        CLOSE mov_instr_if_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���I�[�v�����N���[�Y����
      IF (mov_instr_if_cur%ISOPEN) THEN
        CLOSE mov_instr_if_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_interface_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_if_header_data
   * Description      : �ړ��w���w�b�_���`�F�b�N(B-3)
   ***********************************************************************************/
  PROCEDURE chk_if_header_data(
      ov_errbuf               OUT VARCHAR2              -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode              OUT VARCHAR2              -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg               OUT VARCHAR2              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_if_header_data'; -- �v���O������
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
    cv_not_inclueded    CONSTANT VARCHAR2(1)  :=  '2';                            -- �ϑ��Ȃ�
    cv_mov_type         CONSTANT VARCHAR2(15) :=  'XXINV_MOVE_TYPE';              -- �ړ��^�C�v
    cv_pres_cls         CONSTANT VARCHAR2(20) :=  'XXINV_PRESENCE_CLASS';         -- �^���敪
    cv_wht_capa_cls     CONSTANT VARCHAR2(27) :=  'XXCMN_WEIGHT_CAPACITY_CLASS';  -- �d�ʗe�ϋ敪
    cv_prod_cls         CONSTANT VARCHAR2(20) :=  'XXINV_PRODUCT_CLASS';          -- ���i���ʋ敪
    cv_dt_fmt_yyyymm    CONSTANT VARCHAR2(6)  :=  'YYYYMM';                       -- ���t�����FYYYYMM
--
    -- *** ���[�J���ϐ� ***
    lv_mov_type         VARCHAR2(1);    -- �ړ��^�C�v
    lv_pres_cls         VARCHAR2(1);    -- �^���敪
    lv_wht_capa_cls     VARCHAR2(1);    -- �d�ʗe�ϋ敪
    gv_prod_cls         VARCHAR2(1);    -- ���i���ʋ敪
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -----------------------------
    -- �ړ��^�C�v�Ó����`�F�b�N
    -----------------------------
    BEGIN
      SELECT xlvv.lookup_code
      INTO   lv_mov_type
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = cv_mov_type
      AND    xlvv.lookup_code = g_mov_instr_tab(gn_cnt).mov_type
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_7
                                              , cv_tkn_item
                                              , cv_hdr_mov_type
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                      , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                      , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
        -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
        gv_err_status := cv_status_error;
--
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
--
    END;
--
    -----------------------------
    -- �^���敪�Ó����`�F�b�N
    -----------------------------
    BEGIN
      SELECT xlvv.lookup_code
      INTO   lv_pres_cls
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = cv_pres_cls
      AND    xlvv.lookup_code = g_mov_instr_tab(gn_cnt).freight_charge_class
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_7
                                              , cv_tkn_item
                                              , cv_hdr_freight_charge_cls
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                      , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                      , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
       -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
        gv_err_status := cv_status_error;
--
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
--
    END; 
--
    -----------------------------
    -- �d�ʗe�ϋ敪�Ó����`�F�b�N
    -----------------------------
    BEGIN
      SELECT xlvv.lookup_code
      INTO   lv_wht_capa_cls
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = cv_wht_capa_cls
      AND    xlvv.lookup_code = g_mov_instr_tab(gn_cnt).weight_capacity_class
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_7
                                              , cv_tkn_item
                                              , cv_hdr_weight_capacity_cls
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                      , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                      , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
        -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
        gv_err_status := cv_status_error;
--
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
--
    END; 
--
    -----------------------------
    -- ���i���ʋ敪�Ó����`�F�b�N
    -----------------------------
    BEGIN
      SELECT xlvv.lookup_code
      INTO   lv_pres_cls
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = cv_prod_cls
      AND    xlvv.lookup_code = g_mov_instr_tab(gn_cnt).weight_capacity_class
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_7
                                              , cv_tkn_item
                                              , cv_hdr_product_flg
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                      , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                      , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
        -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
        gv_err_status := cv_status_error;
--
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
--
    END;
--
    -----------------------------
    -- �ߋ����`�F�b�N
    -----------------------------
    -- �o�ɗ\������V�X�e�����t���ߋ��ł͂Ȃ�����
    IF (g_mov_instr_tab(gn_cnt).schedule_ship_date < TRUNC(gd_sysdate)) THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_2
                                            );
--
      make_err_list(  iv_kind     => cv_msg_war       -- �G���[���
                    , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                    , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
      -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
      IF (gv_err_status <> cv_status_error) THEN
        gv_err_status := cv_status_warn;
      END IF;
--
    END IF;
--
    -----------------------------
    -- �ϑ��Ȃ������`�F�b�N
    -----------------------------
    IF (g_mov_instr_tab(gn_cnt).mov_type = cv_not_inclueded) THEN
--
      IF (g_mov_instr_tab(gn_cnt).schedule_ship_date        -- �o�ɓ�
          <> g_mov_instr_tab(gn_cnt).schedule_arrival_date) -- ����
      THEN
--
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_3
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                      , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                      , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
        -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
        gv_err_status := cv_status_error;
--
      END IF;
--
    END IF;
--
    -----------------------------
    -- ���t�t�]�`�F�b�N
    -----------------------------
    IF (g_mov_instr_tab(gn_cnt).schedule_ship_date        -- �o�ɓ�
        > g_mov_instr_tab(gn_cnt).schedule_arrival_date)  -- ����
    THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_4
                                            );
--
      make_err_list(  iv_kind     => cv_msg_war       -- �G���[���
                    , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                    , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
      -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
      IF (gv_err_status <> cv_status_error) THEN
        gv_err_status := cv_status_warn;
      END IF;
--
    END IF;
--
    -----------------------------
    -- �݌Ɋ��ԃN���[�Y�`�F�b�N
    -----------------------------
    -- �o�ɓ�
    IF (TO_CHAR(g_mov_instr_tab(gn_cnt).schedule_ship_date, cv_dt_fmt_yyyymm)   -- �o�ɓ�
        <= xxcmn_common_pkg.get_opminv_close_period)                     -- �N���[�Y�ő�N��
    THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_5
                                            , cv_tkn_target_date
                                            , cv_hdr_sch_ship_date
                                            );
--
      make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                    , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                    , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
      -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
      gv_err_status := cv_status_error;
--
    END IF;
--
    -- ����
    IF (TO_CHAR(g_mov_instr_tab(gn_cnt).schedule_arrival_date, cv_dt_fmt_yyyymm)  -- �o�ɓ�
        <= xxcmn_common_pkg.get_opminv_close_period)                              -- �N���[�Y�ő�N��
    THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_5
                                            , cv_tkn_target_date
                                            , cv_hdr_sch_arrival_date
                                            );
--
      make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                    , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                    , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
      -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
      gv_err_status := cv_status_error;
--
    END IF;
--
    -----------------------------
    -- �o�Ɍ��A���ɐ擯��`�F�b�N
    -----------------------------
    IF (g_mov_instr_tab(gn_cnt).shipped_locat_code      -- �o�Ɍ�
        = g_mov_instr_tab(gn_cnt).ship_to_locat_code)   -- ���ɐ�
    THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_6
                                            );
--
      make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                    , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                    , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
      -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
      gv_err_status := cv_status_error;
--
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    WHEN global_api_expt THEN                           --*** <��O�R�����g> ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
  END chk_if_header_data;
--
  /**********************************************************************************
   * Procedure Name   : get_max_ship_method
   * Description      : �ő�z���敪�E�����敪�擾(B-4,B-5)
   ***********************************************************************************/
  PROCEDURE get_max_ship_method(
      ov_errbuf               OUT VARCHAR2              -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode              OUT VARCHAR2              -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg               OUT VARCHAR2              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_max_ship_method'; -- �v���O������
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
    ln_result           NUMBER;         -- ���ʊ֐��߂�l
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �ϐ�������
    ln_result             := 0;           -- ���ʊ֐��߂�l
--
    -- ==================================
    --  B-4.�ő�z���敪�擾
    -- ==================================
    -- ���ʊ֐��u�ő�z���敪�Z�o�֐��v
    ln_result := xxwsh_common_pkg.get_max_ship_method(
                    iv_code_class1                => cv_warehouses                                    -- 4:�q��
                  , iv_entering_despatching_code1 => g_mov_instr_tab(gn_cnt).shipped_locat_code       -- �o�Ɍ��R�[�h
                  , iv_code_class2                => cv_warehouses                                    -- 4:�q��
                  , iv_entering_despatching_code2 => g_mov_instr_tab(gn_cnt).ship_to_locat_code       -- ���ɐ�R�[�h
                  , iv_prod_class                 => gv_secur_prod_class                              -- ���i�敪
                  , iv_weight_capacity_class      => g_mov_instr_tab(gn_cnt).weight_capacity_class    -- �d�ʗe�ϋ敪
                  , iv_auto_process_type          => NULL
                  , id_standard_date              => g_mov_instr_tab(gn_cnt).schedule_ship_date       -- �o�ɓ�
                  , ov_max_ship_methods           => gv_max_ship_method                               -- �ő�z���敪
                  , on_drink_deadweight           => gn_drink_deadweight                              -- �h�����N��{�d��
                  , on_leaf_deadweight            => gn_leaf_deadweight                               -- ���[�t��{�d��
                  , on_drink_loading_capacity     => gn_drink_loading_capa                            -- �h�����N��{�e��
                  , on_leaf_loading_capacity      => gn_leaf_loading_capa                             -- ���[�t��{�e��
                  , on_palette_max_qty            => gn_palette_max_qty                               -- �p���b�g�ő喇��
                  );
    IF (ln_result = cn_status_error) THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_msg_no_data_1
                                            , cv_tkn_msg
                                            , cv_max_shopped_method
                                            );
--
      make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                    , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                    , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
--
      -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
      gv_err_status := cv_status_error;
--
    END IF;
--
    -- ==================================
    --  B-5.�����敪�擾
    -- ==================================
    BEGIN
      SELECT  xlvv.attribute6
      INTO    gv_small_amount_cls   -- �����敪
      FROM    xxcmn_lookup_values_v xlvv
      WHERE   xlvv.lookup_type = cv_ship_method
      AND     xlvv.lookup_code = gv_max_ship_method
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
--
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_msg_no_data_1
                                              , cv_tkn_msg
                                              , cv_small_amount_cls
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                      , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                      , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
        -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
        gv_err_status := cv_status_error;
--
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
--
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <��O�R�����g> ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
  END get_max_ship_method;
--
  /**********************************************************************************
   * Procedure Name   : get_relating_data
   * Description      : �֘A�f�[�^�擾����(B-6,B-7)
   ***********************************************************************************/
  PROCEDURE get_relating_data(
      ov_errbuf               OUT VARCHAR2              -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode              OUT VARCHAR2              -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg               OUT VARCHAR2              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_relating_data'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ===========================
    -- B-6.�o�Ɍ�ID/���ɐ�ID�擾
    -- ===========================
    -- �o�Ɍ�ID�擾
    BEGIN
      SELECT xilv.inventory_location_id   -- �ۊǑq��ID
      INTO   gv_shipped_id                -- �o�Ɍ�ID
      FROM   xxcmn_item_locations_v xilv
      WHERE  xilv.customer_stock_whse = cv_own_warehouse  -- ���Бq��
      AND    xilv.segment1 = g_mov_instr_tab(gn_cnt).shipped_locat_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_msg_no_data_2
                                              , cv_tkn_item
                                              , cv_shpped_loc_id
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                      , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                      , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
--
        -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
        gv_err_status := cv_status_error;
--
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
--
    END;
--
    -- ���ɐ�ID�擾
    BEGIN
      SELECT xilv.inventory_location_id   -- �ۊǑq��ID
      INTO   gv_ship_to_id                -- ���ɐ�ID
      FROM   xxcmn_item_locations_v xilv
      WHERE  xilv.customer_stock_whse = cv_own_warehouse -- ���Бq��
      AND    xilv.segment1 = g_mov_instr_tab(gn_cnt).ship_to_locat_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN 
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_msg_no_data_2
                                              , cv_tkn_item
                                              , cv_shp_to_loc_id
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                      , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                      , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
--
        -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
        gv_err_status := cv_status_error;
--
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
--
    END;
--
    -- �^���Ǝ҂��ݒ肳��Ă���ꍇ
    IF (g_mov_instr_tab(gn_cnt).freight_carrier_code IS NOT NULL) THEN
--
      gv_carrier_code := g_mov_instr_tab(gn_cnt).freight_carrier_code;
--
      -- ===========================
      -- B-7.�^���Ǝ�ID�擾
      -- ===========================
      BEGIN
        SELECT  xpv.party_id
        INTO    gn_carrier_id
        FROM    xxcmn_parties2_v xpv
        WHERE   xpv.freight_code      =   gv_carrier_code
        AND     xpv.start_date_active <=  TRUNC(g_mov_instr_tab(gn_cnt).schedule_ship_date)
        AND     xpv.end_date_active   >=  TRUNC(g_mov_instr_tab(gn_cnt).schedule_ship_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN 
          gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                                , cv_msg_no_data_2
                                                , cv_tkn_item
                                                , cv_freight_carrier_id
                                                );
--
          make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                        , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                        , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                        , ov_errbuf   => lv_errbuf        
                        , ov_retcode  => lv_retcode       
                        , ov_errmsg   => lv_errmsg        
                       ); 
--
          -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
          gv_err_status := cv_status_error;
--
        WHEN OTHERS THEN
--
          RAISE global_api_others_expt;
--
      END;
--
    -- �^���敪������A���o�Ɍ�ID���擾�ł��ĉ^���Ǝ҂��ݒ肳��Ă��Ȃ��ꍇ
    ELSIF (g_mov_instr_tab(gn_cnt).freight_charge_class = cv_on)
      AND (g_mov_instr_tab(gn_cnt).freight_carrier_code IS NULL)
      AND (gv_shipped_id IS NOT NULL)
    THEN
--
      -- OPM�ۊǏꏊ�����\�^���Ǝ҂��擾
      BEGIN
        SELECT  xcv.party_number      -- �^���Ǝ҃R�[�h
              , xcv.party_id          -- �^���Ǝ�ID
        INTO    gv_carrier_code       -- �^���Ǝ҃R�[�h
              , gn_carrier_id         -- �^���Ǝ�ID
        FROM    xxcmn_carriers_v        xcv   -- �^���Ǝҏ��View
              , xxcmn_item_locations_v  xilv  -- OPM�ۊǏꏊ�}�X�^
        WHERE xilv.frequent_mover         = xcv.party_number
        AND   xilv.inventory_location_id  = gv_shipped_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
--
          gv_carrier_code :=  NULL;   -- �^���Ǝ҃R�[�h
          gn_carrier_id   :=  NULL;   -- �^���Ǝ�ID
--
        WHEN OTHERS THEN
--
          RAISE global_api_others_expt;
--
      END;
--
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <��O�R�����g> ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
  END get_relating_data;
--
  /**********************************************************************************
   * Procedure Name   : get_item_info
   * Description      : �i�ڏ��擾(B-9)
   ***********************************************************************************/
  PROCEDURE get_item_info(
      ov_errbuf               OUT VARCHAR2              -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode              OUT VARCHAR2              -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg               OUT VARCHAR2              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_info'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �i�ڎ擾�t���O�ݒ�
    gb_get_item_flg := TRUE;
--
    -- �擾�p�ϐ�������
    gn_item_id            := NULL;
    gv_item_desc          := NULL;
    gv_item_um            := NULL;
    gv_conv_unit          := NULL;
    gn_delivery_qty       := NULL;
    gn_max_palette_steps  := NULL;
    gn_num_of_cases       := NULL;
    gn_num_of_deliver     := NULL;
    gv_prod_cls           := NULL;
--
    -- ===========================
    -- B-9.�i�ڏ��擾
    -- ===========================
    BEGIN
      SELECT  ximv.item_id                              -- �i��ID
            , ximv.item_desc1                           -- �K�p
            , ximv.item_um                              -- �P��
            , ximv.conv_unit                            -- ���o�Ɋ��Z�P��
            , NVL(ximv.delivery_qty, 0)                 -- �z��
            , NVL(TO_NUMBER(ximv.max_palette_steps), 0) -- �p���b�g����ő�i��
            , NVL(TO_NUMBER(ximv.num_of_cases), 0)      -- �P�[�X����
            , NVL(ximv.num_of_deliver, 0)               -- �o�ד���
            , xicv.prod_class_code                      -- ���i�敪
      INTO    gn_item_id                                -- �i��ID
            , gv_item_desc                              -- �K�p
            , gv_item_um                                -- �P��
            , gv_conv_unit                              -- ���o�Ɋ��Z�P��
            , gn_delivery_qty                           -- �z��
            , gn_max_palette_steps                      -- �p���b�g����ő�i��
            , gn_num_of_cases                           -- �P�[�X����
            , gn_num_of_deliver                         -- �o�ד���
            , gv_prod_cls                               -- ���i�敪
      FROM    xxcmn_item_categories5_v  xicv            -- OPM�i�ڃJ�e�S���������VIEW5
            , xxcmn_item_mst2_v         ximv            -- OPM�i�ڃ}�X�^2
      WHERE   xicv.item_id = ximv.item_id 
      AND     ximv.weight_capacity_class          = g_mov_instr_tab(gn_cnt).weight_capacity_class   -- �d�ʗe�ϋ敪
      AND     xicv.item_no                        = g_mov_instr_tab(gn_cnt).item_code               -- �i��
      AND     ximv.start_date_active              <= TRUNC(g_mov_instr_tab(gn_cnt).schedule_ship_date)
      AND     ximv.end_date_active                >= TRUNC(g_mov_instr_tab(gn_cnt).schedule_ship_date)
      AND     (((g_mov_instr_tab(gn_cnt).product_flg = cv_prod_cls_prod)        -- ���i���ʋ敪(1:���i)
              AND (xicv.item_class_code           = cv_product))
          OR  ((g_mov_instr_tab(gn_cnt).product_flg = cv_prod_cls_others)       -- ���i���ʋ敪(2:���i�ȊO)
              AND (xicv.item_class_code           <> cv_product)))
      AND     ximv.inactive_ind                   <> cn_on                      -- �����t���O
      AND     ximv.obsolete_class                 <> cv_on                      -- �p�~�敪
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_msg_no_data_1
                                              , cv_tkn_msg
                                              , cv_hdr_item_code
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                      , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                      , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
--
        gb_get_item_flg := FALSE;
--
        -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
        gv_err_status := cv_status_error;
--
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
--
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    WHEN global_api_expt THEN                           --*** <��O�R�����g> ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
  END get_item_info;
--
  /**********************************************************************************
   * Procedure Name   : chk_item_mst
   * Description      : �i�ڃ}�X�^�`�F�b�N(B-10)
   ***********************************************************************************/
  PROCEDURE chk_item_mst(
      ov_errbuf               OUT VARCHAR2              -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode              OUT VARCHAR2              -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg               OUT VARCHAR2              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_item_mst'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ===========================
    -- B-10.�i�ڃ}�X�^�`�F�b�N
    -- ===========================
    -- ���o�Ɋ��Z�P�ʂ��ݒ�ς݂̏ꍇ
    IF (gv_conv_unit IS NOT NULL) THEN
--
      -- �z���`�F�b�N
      IF (gn_delivery_qty IS NULL) 
        OR (gn_delivery_qty = 0)
      THEN
--
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_8
                                              , cv_tkn_item
                                              , cv_delivery_qty
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                      , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                      , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
--
        -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
        gv_err_status := cv_status_error;
--
        -- �i�ڃ}�X�^�`�F�b�N�X�e�[�^�X
        gv_item_mst_chk_sts := cv_status_error;
--
      END IF;
--
      -- �p���b�g����ő�i���`�F�b�N
      IF (gn_max_palette_steps IS NULL) 
        OR (gn_max_palette_steps = 0)
      THEN
--
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_8
                                              , cv_tkn_item
                                              , cv_max_pallet_steps
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                      , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                      , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
--
        -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
        gv_err_status := cv_status_error;
--
        -- �i�ڃ}�X�^�`�F�b�N�X�e�[�^�X
        gv_item_mst_chk_sts := cv_status_error;
--
      END IF;
--
      -- �P�[�X�����`�F�b�N
      IF (gn_num_of_cases IS NULL) 
        OR (gn_num_of_cases = 0)
      THEN
--
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_8
                                              , cv_tkn_item
                                              , cv_num_of_cases
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                      , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                      , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
--
        -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
        gv_err_status := cv_status_error;
--
        -- �i�ڃ}�X�^�`�F�b�N�X�e�[�^�X
        gv_item_mst_chk_sts := cv_status_error;
--
      END IF;
--
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <��O�R�����g> ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
  END chk_item_mst;
--
  /**********************************************************************************
   * Procedure Name   : calc_best_amount
   * Description      : �œK���ʂ̎Z�o(B-11, B-12)
   ***********************************************************************************/
  PROCEDURE calc_best_amount(
      ov_errbuf               OUT VARCHAR2              -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode              OUT VARCHAR2              -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg               OUT VARCHAR2              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_best_amount'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ===========================
    -- B-11.�œK���ʂ̎Z�o
    -- ===========================
--
    -- ���o�Ɋ��Z�P�ʂ��ݒ�ς݂̏ꍇ�̂�
    IF (gv_conv_unit IS NOT NULL) THEN
--
      -- �p���b�g����̍ő�P�[�X�����Z�o
      gn_max_case_for_palette := gn_max_palette_steps * gn_delivery_qty;          -- �p���b�g����ő�i�� * �z��
--
      -- �œK���ʂ��Z�o
      -- 1.�p���b�g��
      gn_best_num_palette := TRUNC(g_mov_instr_tab(gn_cnt).first_instruct_qty     -- �w������
                                    / gn_max_case_for_palette                     -- �p���b�g����ő�P�[�X��
                             );
--
      -- 2.�i��
      gn_best_num_steps   := TRUNC(MOD(g_mov_instr_tab(gn_cnt).first_instruct_qty -- �w������
                                , gn_max_case_for_palette)                        -- �p���b�g����ő�P�[�X��
                                / gn_delivery_qty)                                -- �z��
                             ;
--
      -- 3.�P�[�X��
      gn_best_num_cases   := MOD(g_mov_instr_tab(gn_cnt).first_instruct_qty       -- �w������
                                , gn_delivery_qty)                                -- �z��
                             ;
--
    END IF;
--
    -- ===========================
    -- B-12.�p���b�g�����̎Z�o
    -- ===========================
    -- �p���b�g����
    IF (MOD(g_mov_instr_tab(gn_cnt).first_instruct_qty, gn_max_case_for_palette) = 0) THEN
--
      gn_palette_num := gn_best_num_palette;
--
    ELSE
--
      gn_palette_num := gn_best_num_palette + 1;
--
    END IF;
--
    -- �p���b�g���v����
    gn_sum_palette_num := gn_sum_palette_num + gn_palette_num;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <��O�R�����g> ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
  END calc_best_amount;
--
  /**********************************************************************************
   * Procedure Name   : calc_instruct_amount
   * Description      : �w�����ʂ̎Z�o(B-13,B-14,B-15)
   ***********************************************************************************/
  PROCEDURE calc_instruct_amount(
      ov_errbuf               OUT VARCHAR2              -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode              OUT VARCHAR2              -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg               OUT VARCHAR2              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_instruct_amount'; -- �v���O������
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
    lv_errmsg_code  VARCHAR2(30);
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ===========================
    -- B-13.�w�����ʂ̎Z�o
    -- ===========================
    IF ((gv_prod_cls = cv_drink)                                      -- ���i�敪�F�h�����N
      AND (g_mov_instr_tab(gn_cnt).product_flg = cv_prod_cls_prod)    -- ���i���ʋ敪�F���i
      AND (gv_conv_unit IS NOT NULL))                                 -- ���o�Ɋ��Z�P�ʐݒ�ς�
    THEN
      -- �w������
      gn_instruct_qty := g_mov_instr_tab(gn_cnt).first_instruct_qty   -- �w������
                          * gn_num_of_cases                           -- �P�[�X����
                         ;
--
    ELSE
--
      -- �w������
      gn_instruct_qty := g_mov_instr_tab(gn_cnt).first_instruct_qty;  -- �w������
--
    END IF;
--
    -- �w�����ʍ��v(�w�b�_�P��)
    gn_ttl_instruct_qty := gn_ttl_instruct_qty + gn_instruct_qty;
--
    -- ===========================
    -- B-14.���v�d�ʁE�e�ς̎Z�o
    -- ===========================
    xxwsh_common910_pkg.calc_total_value(
          g_mov_instr_tab(gn_cnt).item_code           -- �i��
        , gn_instruct_qty                             -- �w������
        , lv_retcode                                  -- ���^�[���R�[�h
        , lv_errmsg_code                              -- �G���[���b�Z�[�W�R�[�h
        , lv_errmsg                                   -- �G���[���b�Z�[�W
        , gn_ttl_weight                               -- ���v�d��
        , gn_ttl_capacity                             -- ���v�e��
        , gn_ttl_palette_weight                       -- ���v�p���b�g�d��
        , g_mov_instr_tab(gn_cnt).schedule_ship_date  -- �o�ɓ�
    );
    IF (lv_retcode = cv_error) THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_16
                                            , cv_tkn_chk
                                            , cv_over_check_2
                                            , cv_tkn_err_msg
                                            , lv_errmsg
                                            );
--
      make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                    , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                    , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
--
      -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
      gv_err_status := cv_status_error;
    END IF;
--
    -- �����敪�Ώۂ̏ꍇ
    IF ((gv_small_amount_cls = cv_object)   -- �����敪�Ώ�
      OR (gv_max_ship_method IS NULL))      -- �ő�z���敪�ݒ�Ȃ�
    THEN
      NULL;
    ELSE
--
      -- �p���b�g�d�ʂ����Z
      gn_ttl_weight := gn_ttl_weight + gn_ttl_palette_weight;
--
    END IF;
--
    -- �����v�d��
    gn_sum_ttl_weight     := gn_sum_ttl_weight + gn_ttl_weight;
--
    -- �����v�e��
    gn_sum_ttl_capacity   := gn_sum_ttl_capacity + gn_ttl_capacity;
    
    -- �����v�p���b�g�d��
    gn_sum_ttl_palette_weight := gn_sum_ttl_palette_weight + gn_ttl_palette_weight;
--
    -- ================================
    -- B-15.�������E���x�������̎Z�o
    -- ================================
    -- �������̎Z�o
    IF (gn_num_of_deliver > 0) THEN -- �o�ד�����0�ȏ�̏ꍇ
--
      gn_sml_amnt_num := CEIL(gn_instruct_qty       -- �w������
                            / gn_num_of_deliver     -- �o�ד���
                             );
--
    ELSIF ((gn_num_of_deliver = 0)          -- �o�ד��������ݒ�
        AND (gv_conv_unit IS NOT NULL))     -- ���o�Ɋ��Z�P�ʂ��ݒ��
    THEN
--
      gn_sml_amnt_num := CEIL(gn_instruct_qty       -- �w������
                            / gn_num_of_cases       -- �P�[�X����
                            );
--
    ELSIF ((gn_num_of_deliver = 0)          -- �o�ד��������ݒ�
        AND (gv_conv_unit IS NULL))         -- ���o�Ɋ��Z�P�ʂ����ݒ�
    THEN
--
      gn_sml_amnt_num := gn_instruct_qty;           -- �w������
--
    END IF;
--
    -- ���x�������ݒ�
    gn_label_num := gn_sml_amnt_num;
--
    -- �w�b�_�P�ʂ̏��������v
    gn_ttl_sml_amnt_num := gn_ttl_sml_amnt_num + gn_sml_amnt_num;
--
    -- �w�b�_�P�ʂ̃��x���������v
    gn_ttl_label_num    := gn_ttl_label_num + gn_label_num;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <��O�R�����g> ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
  END calc_instruct_amount;
--
  /**********************************************************************************
   * Procedure Name   : chk_loading_effic
   * Description      : �ύڌ����I�[�o�[�`�F�b�N(B-16)
   ***********************************************************************************/
  PROCEDURE chk_loading_effic(
      in_object_cnt   IN  NUMBER    -- �Ώۃf�[�^�J�E���^
    , ov_errbuf       OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_loading_effic'; -- �v���O������
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
    cv_loading_over         CONSTANT VARCHAR2(1)  := '1';         -- �ύڃI�[�o�[
--
    -- *** ���[�J���ϐ� ***
    lv_over_kbn             VARCHAR2(1);                          -- �ύڃI�[�o�[�敪
    lv_ship_way             xxcmn_ship_methods.ship_method%TYPE;  -- �o�ו��@
    lv_mix_ship             VARCHAR2(2);                          -- ���ڔz���敪
    lv_errmsg_code          VARCHAR2(30);                         -- �G���[�E���b�Z�[�W�E�R�[�h
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �d�ʁF�h�����N
    IF (gv_prod_cls = cv_drink) THEN
--
      xxwsh_common910_pkg.calc_load_efficiency(
              gn_sum_ttl_weight           -- ���v�d��
            , NULL                        -- ���v�e��
            , cv_warehouses               -- �q��:4
            , gv_shipped_locat_code       -- �o�Ɍ��R�[�h
            , cv_warehouses               -- �q��:4
            , gv_ship_to_locat_code       -- ���ɐ�R�[�h
            , gv_max_ship_method          -- �ő�z���敪
            , gv_prod_cls                 -- ���i�敪
            , NULL                        -- �����z�ԑΏۋ敪
            , gd_schedule_ship_date       -- �o�ɓ�
            , lv_retcode                  -- ���^�[���E�R�[�h
            , lv_errmsg_code              -- �G���[�E���b�Z�[�W�E�R�[�h
            , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
            , lv_over_kbn                 -- �ύڃI�[�o�[�敪 0:����,1:�I�[�o�[
            , lv_ship_way                 -- �o�ו��@
            , gn_we_loading               -- �d�ʐύڌ���
            , gn_ca_loading               -- �e�ϐύڌ���
            , lv_mix_ship                 -- ���ڔz���敪
      );
      IF (lv_retcode = cv_error) THEN           
--
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_16
                                              , cv_tkn_chk
                                              , cv_over_check_1
                                              , cv_tkn_err_msg
                                              , lv_errmsg
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err     -- �G���[���
                      , iv_err_info => gv_out_msg     -- �G���[���b�Z�[�W
                      , in_rec_cnt  => in_object_cnt  -- �G���[�Ώۃ��R�[�h�J�E���g
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
--
        -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
        gv_err_status := cv_status_error;
--
      END IF;
--
    -- �e�ρF���[�t
    ELSE
      xxwsh_common910_pkg.calc_load_efficiency(
              NULL                        -- ���v�d��
            , gn_sum_ttl_capacity         -- ���v�e��
            , cv_warehouses               -- �q��:4
            , gv_shipped_locat_code       -- �o�Ɍ��R�[�h
            , cv_warehouses               -- �q��:4
            , gv_ship_to_locat_code       -- ���ɐ�R�[�h
            , gv_max_ship_method          -- �ő�z���敪
            , gv_prod_cls                 -- ���i�敪
            , NULL                        -- �����z�ԑΏۋ敪
            , gd_schedule_ship_date       -- �o�ɓ�
            , lv_retcode                  -- ���^�[���E�R�[�h
            , lv_errmsg_code              -- �G���[�E���b�Z�[�W�E�R�[�h
            , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
            , lv_over_kbn                 -- �ύڃI�[�o�[�敪 0:����,1:�I�[�o�[
            , lv_ship_way                 -- �o�ו��@
            , gn_we_loading               -- �d�ʐύڌ���
            , gn_ca_loading               -- �e�ϐύڌ���
            , lv_mix_ship                 -- ���ڔz���敪
      );
      IF (lv_retcode = cv_error) THEN           
--
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_16
                                              , cv_tkn_chk
                                              , cv_over_check_1
                                              , cv_tkn_err_msg
                                              , lv_errmsg
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err     -- �G���[���
                      , iv_err_info => gv_out_msg     -- �G���[���b�Z�[�W
                      , in_rec_cnt  => in_object_cnt  -- �G���[�Ώۃ��R�[�h�J�E���g
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
--
        -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
        gv_err_status := cv_status_error;
--
      END IF;
--
    END IF;
--
    -- �ύڃI�[�o�[�敪���I�[�o�[�̏ꍇ
    IF (lv_over_kbn = cv_loading_over) THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_10
                                            );
--
      make_err_list(  iv_kind     => cv_msg_err     -- �G���[���
                    , iv_err_info => gv_out_msg     -- �G���[���b�Z�[�W
                    , in_rec_cnt  => in_object_cnt  -- �G���[�Ώۃ��R�[�h�J�E���g
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
--
      -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X(normal�̏ꍇ�̂ݏ㏑��)
      gv_err_status := cv_status_error;
--
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <��O�R�����g> ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
  END chk_loading_effic;
--
  /**********************************************************************************
   * Procedure Name   : chk_sum_palette_sheets
   * Description      : �p���b�g���v�����`�F�b�N(B-17)
   ***********************************************************************************/
  PROCEDURE chk_sum_palette_sheets(
      in_object_cnt   IN  NUMBER    -- �Ώۃf�[�^�J�E���^
    , ov_errbuf       OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_sum_palette_sheets'; -- �v���O������
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
    ln_result     NUMBER;   -- ���ʊ֐��߂�l
    ln_drink_we   NUMBER;   -- �h�����N�ύڏd��
    ln_leaf_we    NUMBER;   -- ���[�t�ύڏd��
    ln_drink_ca   NUMBER;   -- �h�����N�ύڗe��
    ln_leaf_ca    NUMBER;   -- ���[�t�ύڗe��
    ln_prt_max    NUMBER;   -- �p���b�g�ő喇��
--
    -- *** ���[�J���E�J�[�\�� ***
    lv_max_ship_method    VARCHAR2(2);
    ln_drink_deadweight   NUMBER;
    ln_leaf_deadweight    NUMBER;
    ln_drink_loading_capa NUMBER;
    ln_leaf_loading_capa  NUMBER;
    ln_palette_max_qty    NUMBER;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �ő�z���敪��NULL�̏ꍇ�A���ʊ֐��u�ő�z���敪�Z�o�֐��v�ɂāw�ő�z���敪�x�Z�o
    IF (gv_max_ship_method IS NOT NULL) THEN
--
      lv_max_ship_method  := gv_max_ship_method;
--
    ELSE
--
      -- ���ʊ֐��u�ő�z���敪�Z�o�֐��v
      ln_result := xxwsh_common_pkg.get_max_ship_method(
                      iv_code_class1                => cv_warehouses                                        -- 4:�q��
                    , iv_entering_despatching_code1 => g_mov_instr_tab(in_object_cnt).shipped_locat_code    -- �o�Ɍ��R�[�h
                    , iv_code_class2                => cv_warehouses                                        -- 4:�q��
                    , iv_entering_despatching_code2 => g_mov_instr_tab(in_object_cnt).ship_to_locat_code    -- ���ɐ�R�[�h
                    , iv_prod_class                 => gv_prod_cls                                          -- ���i�敪
                    , iv_weight_capacity_class      => g_mov_instr_tab(in_object_cnt).weight_capacity_class -- �d�ʗe�ϋ敪
                    , iv_auto_process_type          => NULL
                    , id_standard_date              => g_mov_instr_tab(in_object_cnt).schedule_ship_date    -- �o�ɓ�
                    , ov_max_ship_methods           => lv_max_ship_method                                   -- �ő�z���敪
                    , on_drink_deadweight           => ln_drink_deadweight                                  -- �h�����N��{�d��
                    , on_leaf_deadweight            => ln_leaf_deadweight                                   -- ���[�t��{�d��
                    , on_drink_loading_capacity     => ln_drink_loading_capa                                -- �h�����N��{�e��
                    , on_leaf_loading_capacity      => ln_leaf_loading_capa                                 -- ���[�t��{�e��
                    , on_palette_max_qty            => ln_palette_max_qty                                   -- �p���b�g�ő喇��
                    );
      IF (ln_result = cn_status_error) THEN
--
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_msg_no_data_1
                                              , cv_tkn_msg
                                              , cv_max_shopped_method
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                      , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                      , in_rec_cnt  => in_object_cnt    -- �G���[�Ώۃ��R�[�h�J�E���g
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
--
        -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
        gv_err_status := cv_status_error;
--
      END IF;
--
    END IF;
--
    -- ���ʊ֐��u�ő�p���b�g�����Z�o�֐��v
    ln_result := xxwsh_common_pkg.get_max_pallet_qty(
                      cv_warehouses               -- �q�ɁF4
                    , gv_shipped_locat_code       -- �o�Ɍ��R�[�h
                    , cv_warehouses               -- �q�ɁF4
                    , gv_ship_to_locat_code       -- ���ɐ�R�[�h
                    , gd_schedule_ship_date       -- �o�ɓ�
                    , lv_max_ship_method          -- �ő�z���敪
                    , ln_drink_we                 -- �h�����N�ύڏd�� out �h�����N�ύڏd��
                    , ln_leaf_we                  -- ���[�t�ύڏd��   out ���[�t�ύڏd��
                    , ln_drink_ca                 -- �h�����N�ύڗe�� out �h�����N�ύڗe��
                    , ln_leaf_ca                  -- ���[�t�ύڗe��   out ���[�t�ύڗe��
                    , ln_prt_max                  -- �p���b�g�ő喇�� out �p���b�g�ő喇��
                   );
    IF (ln_result = cn_status_error) THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_msg_no_data_1
                                            , cv_tkn_msg
                                            , cv_max_pallet
                                            );
--
      make_err_list(  iv_kind     => cv_msg_err     -- �G���[���
                    , iv_err_info => gv_out_msg     -- �G���[���b�Z�[�W
                    , in_rec_cnt  => in_object_cnt  -- �G���[�Ώۃ��R�[�h�J�E���g
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
--
      -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
      gv_err_status := cv_status_error;
--
    END IF;
    -- �p���b�g���v�������p���b�g�ő喇���𒴂����ꍇ�͌x��
    IF (gn_sum_palette_num > ln_prt_max) THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_11
                                            );
--
      make_err_list(  iv_kind     => cv_msg_err     -- �G���[���
                    , iv_err_info => gv_out_msg     -- �G���[���b�Z�[�W
                    , in_rec_cnt  => in_object_cnt  -- �G���[�Ώۃ��R�[�h�J�E���g
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
--
      gv_err_status := cv_status_error;
--
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <��O�R�����g> ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
  END chk_sum_palette_sheets;
--
  /**********************************************************************************
   * Procedure Name   : chk_operating_day
   * Description      : �ғ����`�F�b�N(B-19)
   ***********************************************************************************/
  PROCEDURE chk_operating_day(
      ov_errbuf               OUT VARCHAR2              -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode              OUT VARCHAR2              -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg               OUT VARCHAR2              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_operating_day'; -- �v���O������
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
    ln_result       NUMBER;       -- ���ʊ֐��߂�l
    ld_work_day     DATE;         -- �ғ������t
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �ғ����`�F�b�N ���ʊ֐��u�ғ����Z�o�֐��v
    -- �o�ɓ�
    ln_result := xxwsh_common_pkg.get_oprtn_day(
                                  g_mov_instr_tab(gn_cnt).schedule_ship_date  -- �o�ɓ�
                                 ,g_mov_instr_tab(gn_cnt).shipped_locat_code  -- �o�Ɍ�
                                 ,NULL                                        -- �z����R�[�h
                                 ,0                                           -- ���[�h�^�C��
                                 ,gv_secur_prod_class                         -- ���i�敪
                                 ,ld_work_day                                 -- �ғ������t
                                );
--
    -- ���ʊ֐��G���[
    IF (ln_result = cn_status_error) THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_12
                                            , cv_tkn_item
                                            , cv_hdr_sch_ship_date
                                            );
--
      make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                    , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                    , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
--
      -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
      gv_err_status := cv_status_error;
--
    END IF;
--
    -- �o�ɓ��Ɖғ������t����v���Ȃ��ꍇ
    IF (g_mov_instr_tab(gn_cnt).schedule_ship_date <> ld_work_day) THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_9
                                            , cv_tkn_target_date
                                            , cv_hdr_sch_ship_date
                                            );
--
      make_err_list(  iv_kind     => cv_msg_war       -- �G���[���
                    , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                    , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
--
      -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X(normal�̏ꍇ�̂ݏ㏑��)
      IF (gv_err_status <> cv_status_error) THEN
        gv_err_status := cv_status_warn;
      END IF;
--
    END IF;
--
    -- ����
    ln_result := xxwsh_common_pkg.get_oprtn_day(
                                  g_mov_instr_tab(gn_cnt).schedule_arrival_date -- ����
                                 ,g_mov_instr_tab(gn_cnt).ship_to_locat_code    -- ���ɐ�
                                 ,NULL                                          -- �z����R�[�h
                                 ,0                                             -- ���[�h�^�C��
                                 ,gv_secur_prod_class                           -- ���i�敪
                                 ,ld_work_day                                   -- �ғ������t
                                );
--
    -- ���ʊ֐��G���[
    IF (ln_result = cn_status_error) THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_12
                                            , cv_tkn_item
                                            , cv_hdr_sch_arrival_date
                                            );
--
      make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                    , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                    , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
--
      -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
      gv_err_status := cv_status_error;
--
    END IF;
--
    -- �����Ɖғ������t����v���Ȃ��ꍇ
    IF (g_mov_instr_tab(gn_cnt).schedule_arrival_date <> ld_work_day) THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_9
                                            , cv_tkn_target_date
                                            , cv_hdr_sch_arrival_date
                                            );
--
      make_err_list(  iv_kind     => cv_msg_war       -- �G���[���
                    , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                    , in_rec_cnt  => gn_cnt           -- �G���[�Ώۃ��R�[�h�J�E���g
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); --
      -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X(normal�̏ꍇ�̂ݏ㏑��)
      IF (gv_err_status <> cv_status_error) THEN
        gv_err_status := cv_status_warn;
      END IF;
--
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <��O�R�����g> ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
  END chk_operating_day;
--
  /**********************************************************************************
   * Procedure Name   : set_line_data
   * Description      : �ړ��w�����׏��ݒ�(B-18)
   ***********************************************************************************/
  PROCEDURE set_line_data(
      ov_errbuf               OUT VARCHAR2              -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode              OUT VARCHAR2              -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg               OUT VARCHAR2              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_line_data'; -- �v���O������
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
    ln_first_data   CONSTANT NUMBER := 1;   -- 1���R�[�h��
--
    -- *** ���[�J���ϐ� ***
    ln_line_seq     NUMBER;     -- �ړ��w������ID
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ---------------------------
    -- �ړ��w�����ׂ�ݒ�
    ---------------------------
--
    -- �ړ��w������ID���擾
    BEGIN
      SELECT  xxinv_mov_line_s1.NEXTVAL
      INTO    ln_line_seq
      FROM    dual
      ;
    EXCEPTION
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
--
    END;
--
    -- �o�^�p�ϐ��Ɋi�[
    g_mov_line_id_tab(gn_mov_instr_line_cnt)          := ln_line_seq;                                   -- �ړ��w������ID
    g_mov_line_hdr_id_tab(gn_mov_instr_line_cnt)      := gn_header_id;                                  -- �ړ��w�b�_ID
    g_mov_number_tab(gn_mov_instr_line_cnt)           := gn_line_number_cnt;                            -- �w�b�_�P�ʖ��׌���
    g_item_code_tab(gn_mov_instr_line_cnt)            := g_mov_instr_tab(gn_cnt).item_code;             -- �i��
    g_designated_prod_date_tab(gn_mov_instr_line_cnt) := g_mov_instr_tab(gn_cnt).designated_prod_date;  -- �w�萻����
    g_first_instruct_qty_tab(gn_mov_instr_line_cnt)   := g_mov_instr_tab(gn_cnt).first_instruct_qty;    -- ����w������
    g_item_id_tab(gn_mov_instr_line_cnt)              := gn_item_id;                                    -- �i��ID
    g_pallet_qty_tab(gn_mov_instr_line_cnt)           := gn_best_num_palette;                           -- �p���b�g��
    g_layer_qty_tab(gn_mov_instr_line_cnt)            := gn_best_num_steps;                             -- �i��
    g_case_qty_tab(gn_mov_instr_line_cnt)             := gn_best_num_cases;                             -- �P�[�X��
    g_instr_qty_tab(gn_mov_instr_line_cnt)            := gn_instruct_qty;                               -- �w������
--
    IF ((gv_prod_cls = cv_drink)                                    -- ���i�敪�F�h�����N
       AND (g_mov_instr_tab(gn_cnt).product_flg = cv_prod_cls_prod) -- ���i���ʋ敪�F���i
       AND (gv_conv_unit IS NOT NULL))                              -- ���o�Ɋ��Z�P�ʐݒ��
    THEN
--
      g_uom_code_tab(gn_mov_instr_line_cnt)           := gv_conv_unit;                                  -- ���o�Ɋ��Z�P��
--
    ELSE
      g_uom_code_tab(gn_mov_instr_line_cnt)           := gv_item_um;                                    -- �P��
    END IF;
--
    g_pallet_num_of_sheet_tab(gn_mov_instr_line_cnt)  := gn_palette_num;                                -- �p���b�g����
    g_weight_tab(gn_mov_instr_line_cnt)               := gn_ttl_weight;                                 -- �d��
    g_capacity_tab(gn_mov_instr_line_cnt)             := gn_ttl_capacity;                               -- �e��
    g_pallet_weight_tab(gn_mov_instr_line_cnt)        := gn_ttl_palette_weight;                         -- �p���b�g�d��
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
  END set_line_data;
--
  /**********************************************************************************
   * Procedure Name   : set_header_data
   * Description      : �ړ��w���w�b�_���쐬(B-20)
   ***********************************************************************************/
  PROCEDURE set_header_data(
      in_object_cnt           IN  NUMBER                -- �o�^�ΏۃJ�E���^
    , ov_errbuf               OUT VARCHAR2              -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode              OUT VARCHAR2              -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg               OUT VARCHAR2              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_header_data'; -- �v���O������
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
    cv_req_no_cls   CONSTANT VARCHAR2(1) := '4';    -- �˗�No
--
    -- *** ���[�J���ϐ� ***
    ln_line_seq     NUMBER;         -- �ړ��w������ID
    lv_mov_num      VARCHAR2(12);   -- �ړ��ԍ�
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -------------------------
    -- �ړ��ԍ��擾�֐�
    -------------------------
    xxcmn_common_pkg.get_seq_no( 
                                  cv_req_no_cls     -- �̔Ԕԍ��敪
                                , lv_mov_num        -- �̔Ԃ���No
                                , lv_errbuf         -- �G���[�E���b�Z�[�W
                                , lv_retcode        -- ���^�[���E�R�[�h
                                , lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W
                                );
    IF (lv_retcode = cv_status_error) THEN
--
      lv_errmsg := xxcmn_common_pkg.get_msg( cv_msg_kbn
                                            , cv_msg_get_seq
                                            , cv_tkn_seq_name
                                            , cv_tkn_mov_num
                                            );
--
      lv_errbuf := lv_errmsg;
--
      -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
      gv_nodata_error := cv_nodata;
--
      RAISE global_api_expt;
--
    END IF;
--
    ---------------------------
    -- �ړ��w���w�b�_��ݒ�
    ---------------------------
--
    -- �o�^�p�ϐ��Ɋi�[
    g_mov_hdr_id_tab(gn_mov_instr_hdr_cnt)              := gn_header_id;                                          -- �ړ��w�b�_ID
    g_mov_num_tab(gn_mov_instr_hdr_cnt)                 := lv_mov_num;                                            -- �ړ��ԍ�
    g_mov_type_tab(gn_mov_instr_hdr_cnt)                := g_mov_instr_tab(in_object_cnt).mov_type;               -- �ړ��^�C�v
    g_instruction_post_code_tab(gn_mov_instr_hdr_cnt)   := g_mov_instr_tab(in_object_cnt).instr_post_code;        -- �w������
    g_shipped_locat_code_tab(gn_mov_instr_hdr_cnt)      := g_mov_instr_tab(in_object_cnt).shipped_locat_code;     -- �o�Ɍ��ۊǏꏊ
    g_ship_to_locat_code_tab(gn_mov_instr_hdr_cnt)      := g_mov_instr_tab(in_object_cnt).ship_to_locat_code;     -- ���ɐ�ۊǏꏊ
    g_schedule_ship_date_tab(gn_mov_instr_hdr_cnt)      := g_mov_instr_tab(in_object_cnt).schedule_ship_date;     -- �o�ɗ\���
    g_schedule_arrival_date_tab(gn_mov_instr_hdr_cnt)   := g_mov_instr_tab(in_object_cnt).schedule_arrival_date;  -- ���ɗ\���
    g_freight_charge_class_tab(gn_mov_instr_hdr_cnt)    := g_mov_instr_tab(in_object_cnt).freight_charge_class;   -- �^���敪
    g_freight_carrier_code_tab(gn_mov_instr_hdr_cnt)    := gv_carrier_code;                                       -- �^���Ǝ�
    g_weight_capacity_class_tab(gn_mov_instr_hdr_cnt)   := g_mov_instr_tab(in_object_cnt).weight_capacity_class;  -- �d�ʗe�ϋ敪
    g_item_class_tab(gn_mov_instr_hdr_cnt)              := gv_secur_prod_class;                                   -- ���i�敪
    g_product_flg_tab(gn_mov_instr_hdr_cnt)             := g_mov_instr_tab(in_object_cnt).product_flg;            -- ���i���ʋ敪
    g_shipped_locat_id_tab(gn_mov_instr_hdr_cnt)        := gv_shipped_id;                                         -- �o�Ɍ�ID
    g_ship_to_locat_id_tab(gn_mov_instr_hdr_cnt)        := gv_ship_to_id;                                         -- ���ɐ�ID
    g_loading_weight_tab(gn_mov_instr_hdr_cnt)          := gn_we_loading;                                         -- �ύڗ�(�d��)
    g_loading_capacity_tab(gn_mov_instr_hdr_cnt)        := gn_ca_loading;                                         -- �ύڗ�(�e��)
    g_career_id_tab(gn_mov_instr_hdr_cnt)               := gn_carrier_id;                                         -- �^���Ǝ�ID
    g_shipping_method_code_tab(gn_mov_instr_hdr_cnt)    := gv_max_ship_method;                                    -- �ő�z���敪
    g_sum_qty_tab(gn_mov_instr_hdr_cnt)                 := gn_ttl_instruct_qty;                                   -- ���v����
    g_small_qty_tab(gn_mov_instr_hdr_cnt)               := gn_ttl_sml_amnt_num;                                   -- ������
    g_label_qty_tab(gn_mov_instr_hdr_cnt)               := gn_ttl_label_num;                                      -- ���x������
--
    IF (gv_secur_prod_class = cv_drink) THEN
      g_based_weight_tab(gn_mov_instr_hdr_cnt)          := gn_drink_deadweight;         -- �h�����N��{�d��
      g_based_capacity_tab(gn_mov_instr_hdr_cnt)        := gn_drink_loading_capa;       -- �h�����N��{�e��
    ELSE
      g_based_weight_tab(gn_mov_instr_hdr_cnt)          := gn_leaf_deadweight;          -- ���[�t��{�d��
      g_based_capacity_tab(gn_mov_instr_hdr_cnt)        := gn_leaf_loading_capa;        -- ���[�t��{�e��
    END IF;
--
    g_sum_weight_tab(gn_mov_instr_hdr_cnt)              := gn_sum_ttl_weight;           -- �ύڏd�ʍ��v
    g_sum_capacity_tab(gn_mov_instr_hdr_cnt)            := gn_sum_ttl_capacity;         -- �ύڗe�ύ��v
    g_sum_pallet_weight_tab(gn_mov_instr_hdr_cnt)       := gn_sum_ttl_palette_weight;   -- ���v�p���b�g�d��
    g_sum_pallet_qty(gn_mov_instr_hdr_cnt)              := gn_sum_palette_num;          -- �p���b�g���v����
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
  END set_header_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_mov_req_instr_header
   * Description      : �ړ��w���w�b�_���o�^(B-22)
   ***********************************************************************************/
  PROCEDURE ins_mov_req_instr_header(
      ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_mov_req_instr_header'; -- �v���O������
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
    cv_status_adjusting   CONSTANT VARCHAR2(2)  :=  '03';   -- �X�e�[�^�X�F������
    cv_status_un_notif    CONSTANT VARCHAR2(2)  :=  '10';   -- �ʒm�X�e�[�^�X�F���ʒm
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�ړ��˗��E�w���w�b�_(�A�h�I��)�o�^����
    FORALL rec_cnt IN 1..g_mov_hdr_id_tab.COUNT
      INSERT INTO xxinv_mov_req_instr_headers(
          mov_hdr_id	                              -- �ړ��w�b�_ID
        , mov_num	                                  -- �ړ��ԍ�
        , mov_type	                                -- �ړ��^�C�v
        , entered_date	                            -- ���͓�
        , instruction_post_code                     -- �w������
        , status	                                  -- �X�e�[�^�X
        , notif_status	                            -- �ʒm�X�e�[�^�X
        , shipped_locat_id	                        -- �o�Ɍ�ID
        , shipped_locat_code	                      -- �o�Ɍ��ۊǏꏊ
        , ship_to_locat_id	                        -- ���ɐ�ID
        , ship_to_locat_code	                      -- ���ɐ�ۊǏꏊ
        , schedule_ship_date	                      -- �o�ɗ\���
        , schedule_arrival_date	                    -- ���ɗ\���
        , freight_charge_class	                    -- �^���敪
        , collected_pallet_qty	                    -- �p���b�g�������
        , no_cont_freight_class	                    -- �_��O�^���敪
        , description	                              -- �E�v
        , loading_efficiency_weight	                -- �ύڗ��i�d�ʁj
        , loading_efficiency_capacity	              -- �ύڗ��i�e�ρj
        , organization_id	                          -- �g�DID
        , career_id	                                -- �^���Ǝ�_ID
        , freight_carrier_code	                    -- �^���Ǝ�
        , shipping_method_code	                    -- �z���敪
        , sum_quantity	                            -- ���v����
        , small_quantity	                          -- ������
        , label_quantity	                          -- ���x������
        , based_weight	                            -- ��{�d��
        , based_capacity	                          -- ��{�e��
        , sum_weight	                              -- �ύڏd�ʍ��v
        , sum_capacity	                            -- �ύڗe�ύ��v
        , sum_pallet_weight	                        -- ���v�p���b�g�d��
        , pallet_sum_quantity	                      -- �p���b�g���v����
        , weight_capacity_class	                    -- �d�ʗe�ϋ敪
        , item_class	                              -- ���i�敪
        , product_flg	                              -- ���i���ʋ敪
        , comp_actual_flg                           -- ���ьv��σt���O
        , correct_actual_flg                        -- ���ђ����t���O
        , new_modify_flg                            -- �V�K�C���t���O
        , created_by                                -- �쐬��
        , creation_date                             -- �쐬��
        , last_updated_by                           -- �ŏI�X�V��
        , last_update_date                          -- �ŏI�X�V��
        , last_update_login                         -- �ŏI�X�V���O�C��
        , request_id                                -- �v��ID
        , program_application_id                    -- �R���J�����g�E�A�v���P�[�V����ID
        , program_id                                -- �R���J�����g�E�v���O����ID
        , program_update_date                       -- �v���O�����X�V��
      ) VALUES (
          g_mov_hdr_id_tab(rec_cnt)                 -- �ړ��w�b�_ID
        , g_mov_num_tab(rec_cnt)                    -- �ړ��ԍ�
        , g_mov_type_tab(rec_cnt)                   -- �ړ��^�C�v
        , gd_sysdate                                -- ���͓�
        , g_instruction_post_code_tab(rec_cnt)      -- �w������
        , cv_status_adjusting                       -- �X�e�[�^�X
        , cv_status_un_notif                        -- �ʒm�X�e�[�^�X
        , g_shipped_locat_id_tab(rec_cnt)           -- �o�Ɍ�ID
        , g_shipped_locat_code_tab(rec_cnt)         -- �o�Ɍ��ۊǏꏊ
        , g_ship_to_locat_id_tab(rec_cnt)           -- ���ɐ�ID
        , g_ship_to_locat_code_tab(rec_cnt)         -- ���ɐ�ۊǏꏊ
        , g_schedule_ship_date_tab(rec_cnt)         -- �o�ɗ\���
        , g_schedule_arrival_date_tab(rec_cnt)      -- ���ɗ\���
        , g_freight_charge_class_tab(rec_cnt)       -- �^���敪
        , NULL                                      -- �p���b�g�������
        , cv_not_object                             -- �_��O�^���敪
        , NULL                                      -- �E�v
        , g_loading_weight_tab(rec_cnt)             -- �ύڗ��i�d�ʁj
        , g_loading_capacity_tab(rec_cnt)           -- �ύڗ��i�e�ρj
        , gv_master_org_id                          -- �g�DID
        , g_career_id_tab(rec_cnt)                  -- �^���Ǝ�_ID
        , g_freight_carrier_code_tab(rec_cnt)       -- �^���Ǝ�
        , g_shipping_method_code_tab(rec_cnt)       -- �z���敪
        , g_sum_qty_tab(rec_cnt)                    -- ���v����
        , g_small_qty_tab(rec_cnt)                  -- ������
        , g_label_qty_tab(rec_cnt)                  -- ���x������
        , g_based_weight_tab(rec_cnt)               -- ��{�d��
        , g_based_capacity_tab(rec_cnt)             -- ��{�e��
        , g_sum_weight_tab(rec_cnt)                 -- �ύڏd�ʍ��v
        , g_sum_capacity_tab(rec_cnt)               -- �ύڗe�ύ��v
        , g_sum_pallet_weight_tab(rec_cnt)          -- ���v�p���b�g�d��
        , g_sum_pallet_qty(rec_cnt)                 -- �p���b�g���v����
        , g_weight_capacity_class_tab(rec_cnt)      -- �d�ʗe�ϋ敪
        , g_item_class_tab(rec_cnt)                 -- ���i�敪
        , g_product_flg_tab(rec_cnt)                -- ���i���ʋ敪
        , cv_off                                    -- ���ьv��σt���O
        , cv_off                                    -- ���ђ����t���O
        , cv_off                                    -- �V�K�C���t���O
        , gn_user_id                                -- �쐬��
        , gd_sysdate                                -- �쐬��
        , gn_user_id                                -- �ŏI�X�V��
        , gd_sysdate                                -- �ŏI�X�V��
        , gn_login_id                               -- �ŏI�X�V���O�C��
        , gn_conc_request_id                        -- �v��ID
        , gn_prog_appl_id                           -- �R���J�����g�E�A�v���P�[�V����ID
        , gn_conc_program_id                        -- �R���J�����g�E�v���O����ID
        , gd_sysdate                                -- �v���O�����X�V��
      );
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
  END ins_mov_req_instr_header;
--
  /**********************************************************************************
   * Procedure Name   : ins_mov_req_instr_line
   * Description      : �ړ��w�����׏��o�^(B-23)
   ***********************************************************************************/
  PROCEDURE ins_mov_req_instr_line(
      ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_mov_req_instr_line'; -- �v���O������
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
    cv_no     CONSTANT VARCHAR2(1)  :=  'N';    -- ����t���O�FN
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�ړ��˗��E�w������(�A�h�I��)�o�^����
    FORALL rec_cnt IN 1..g_mov_line_id_tab.COUNT
      INSERT INTO xxinv_mov_req_instr_lines(
          mov_line_id	                              -- �ړ�����ID
        , mov_hdr_id	                              -- �ړ��w�b�_ID
        , line_number	                              -- ���הԍ�
        , organization_id	                          -- �g�DID
        , item_id	                                  -- OPM�i��ID
        , item_code	                                -- �i��
        , pallet_quantity	                          -- �p���b�g��
        , layer_quantity	                          -- �i��
        , case_quantity	                            -- �P�[�X��
        , instruct_qty	                            -- �w������
        , uom_code	                                -- �P��
        , designated_production_date	              -- �w�萻����
        , pallet_qty	                              -- �p���b�g����
        , first_instruct_qty	                      -- ����w������
        , weight	                                  -- �d��
        , capacity	                                -- �e��
        , pallet_weight	                            -- �p���b�g�d��
        , delete_flg	                              -- ����t���O
        , created_by                                -- �쐬��
        , creation_date                             -- �쐬��
        , last_updated_by                           -- �ŏI�X�V��
        , last_update_date                          -- �ŏI�X�V��
        , last_update_login                         -- �ŏI�X�V���O�C��
        , request_id                                -- �v��ID
        , program_application_id                    -- �R���J�����g�E�A�v���P�[�V����ID
        , program_id                                -- �R���J�����g�E�v���O����ID
        , program_update_date                       -- �v���O�����X�V��
      ) VALUES (
          g_mov_line_id_tab(rec_cnt)                -- �ړ�����ID
        , g_mov_line_hdr_id_tab(rec_cnt)            -- �ړ��w�b�_ID
        , g_mov_number_tab(rec_cnt)                 -- ���הԍ�
        , gv_master_org_id                          -- �g�DID
        , g_item_id_tab(rec_cnt)                    -- OPM�i��ID
        , g_item_code_tab(rec_cnt)                  -- �i��
        , g_pallet_qty_tab(rec_cnt)                 -- �p���b�g��
        , g_layer_qty_tab(rec_cnt)                  -- �i��
        , g_case_qty_tab(rec_cnt)                   -- �P�[�X��
        , g_instr_qty_tab(rec_cnt)                  -- �w������
        , g_uom_code_tab(rec_cnt)                   -- �P��
        , g_designated_prod_date_tab(rec_cnt)       -- �w�萻����
        , g_pallet_num_of_sheet_tab(rec_cnt)        -- �p���b�g����
        , g_first_instruct_qty_tab(rec_cnt)         -- ����w������
        , g_weight_tab(rec_cnt)                     -- �d��
        , g_capacity_tab(rec_cnt)                   -- �e��
        , g_pallet_weight_tab(rec_cnt)              -- �p���b�g�d��
        , cv_no                                     -- ����t���O
        , gn_user_id                                -- �쐬��
        , gd_sysdate                                -- �쐬��
        , gn_user_id                                -- �ŏI�X�V��
        , gd_sysdate                                -- �ŏI�X�V��
        , gn_login_id                               -- �ŏI�X�V���O�C��
        , gn_conc_request_id                        -- �v��ID
        , gn_prog_appl_id                           -- �R���J�����g�E�A�v���P�[�V����ID
        , gn_conc_program_id                        -- �R���J�����g�E�v���O����ID
        , gd_sysdate                                -- �v���O�����X�V��
      );
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
  END ins_mov_req_instr_line;
--
  /**********************************************************************************
   * Procedure Name   : purge_processing
   * Description      : �p�[�W����(B-24)
   ***********************************************************************************/
  PROCEDURE purge_processing(
      in_shipped_locat_cd     IN  VARCHAR2  -- �o�Ɍ��R�[�h
    , ov_errbuf               OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode              OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg               OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'purge_processing'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ----------------------------------
    -- �ړ��w�����׃C���^�t�F�[�X�폜
    ----------------------------------
    BEGIN
      DELETE FROM xxinv_mov_instr_lines_if xmili
      WHERE xmili.mov_hdr_if_id IN ( 
              SELECT xmihi.mov_hdr_if_id
              FROM   xxinv_mov_instr_headers_if xmihi
              WHERE  xmihi.instruction_post_code = gv_user_dept_id    -- �ړ��w�������R�[�h
              AND   ((in_shipped_locat_cd IS NULL)                    -- �o�Ɍ��ۊǏꏊ
                     OR (shipped_locat_code = in_shipped_locat_cd))
            )
      ;
    EXCEPTION
--
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
    END;
--
    ----------------------------------
    -- �ړ��w���w�b�_�C���^�t�F�[�X�폜
    ----------------------------------
    BEGIN
      DELETE FROM xxinv_mov_instr_headers_if xmihi
      WHERE  xmihi.instruction_post_code = gv_user_dept_id    -- �ړ��w�������R�[�h
      AND   ((in_shipped_locat_cd IS NULL)                    -- �o�Ɍ��ۊǏꏊ
          OR (shipped_locat_code = in_shipped_locat_cd))
      ;
--
    EXCEPTION
--
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--
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
  END purge_processing;
--
  /**********************************************************************************
   * Procedure Name   : put_err_list
   * Description      : �G���[���X�g�o��
   ***********************************************************************************/
  PROCEDURE put_err_list(
      in_shipped_locat_cd   IN  VARCHAR2  -- �o�Ɍ��R�[�h
    , ov_errbuf             OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode            OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg             OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_err_list'; -- �v���O������
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
    lv_err_list VARCHAR2(10000);
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -------------------------------------
    -- �o�͍���                        --
    -------------------------------------
    -- ���O�C�����[�U�̏��������R�[�h
    gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                          , cv_msg_user_org_id
                                          , cv_tkn_value
                                          , gv_user_dept_id
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�o�ɑq�Ɂv
    gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                          , cv_msg_shipped_loc
                                          , cv_tkn_value
                                          , in_shipped_locat_cd
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- �G���[���L��ꍇ�̓G���[�o��
    IF (g_err_list_tab.COUNT > 0) THEN
--
          --��؂蕶����o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
      -- �G���[���X�g�w�b�_�o��
      gv_err_report :=             cv_kind                      -- ���
                      || cv_tab || cv_hdr_mov_if_id             -- �ړ��w�b�_IF_ID
                      || cv_tab || cv_hdr_temp_ship_num         -- ���`�[�ԍ�
                      || cv_tab || cv_hdr_mov_type              -- �ړ��^�C�v
                      || cv_tab || cv_hdr_instr_post_code       -- �w������
                      || cv_tab || cv_hdr_shipped_code          -- �o�Ɍ��ۊǏꏊ
                      || cv_tab || cv_hdr_ship_to_code          -- ���ɐ�ۊǏꏊ
                      || cv_tab || cv_hdr_sch_ship_date         -- �o�ɗ\���
                      || cv_tab || cv_hdr_sch_arrival_date      -- ���ɗ\���
                      || cv_tab || cv_hdr_freight_charge_cls    -- �^���敪
                      || cv_tab || cv_hdr_freight_carrier_cd    -- �^���Ǝ�
                      || cv_tab || cv_hdr_weight_capacity_cls   -- �d�ʗe�ϋ敪
                      || cv_tab || cv_hdr_product_flg           -- ���i���ʋ敪
                      || cv_tab || cv_hdr_mov_line_if_id        -- �ړ�����IF_ID
                      || cv_tab || cv_hdr_item_code             -- �i��
                      || cv_tab || cv_hdr_desined_prod_date     -- �萻����
                      || cv_tab || cv_hdr_first_instruct_qty    -- ����w������
                      || cv_tab || cv_hdr_err_msg               -- �G���[���b�Z�[�W
      ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_err_report);
--
      -- ���ڋ�؂���o��
      gv_err_report := cv_line || cv_line || cv_line || cv_line || cv_line || cv_line;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_err_report);
--
      -- �G���[���X�g���e�o��
      <<err_list_loop>>
      FOR i IN 1..g_err_list_tab.COUNT LOOP
        -- �_�~�[�G���[���b�Z�[�W�͏o�͂��Ȃ�
        IF (g_err_list_tab(i).err_msg IS NOT NULL) THEN
--
          FND_FILE.PUT_LINE(  FND_FILE.OUTPUT
                            , g_err_list_tab(i).err_msg
                            );
        END IF;
--
      END LOOP err_list_loop;
--
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <��O�R�����g> ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
  END put_err_list;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      in_shipped_locat_cd   IN  VARCHAR2 DEFAULT NULL -- �o�Ɍ��R�[�h�i�C�Ӂj
    , ov_errbuf             OUT VARCHAR2              -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode            OUT VARCHAR2              -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg             OUT VARCHAR2              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100)  := 'submain'; -- �v���O������
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
    lv_pre_tmp_ship_num     xxinv_mov_instr_headers_if.temp_ship_num%TYPE;  -- �O�񏈗��F���`�[�ԍ�
    lv_pre_item_code        xxinv_mov_instr_lines_if.item_code%TYPE;        -- �O�񏈗��F�i�ڃR�[�h
    lv_pre_prod_cls         VARCHAR2(1);                                    -- �O�񏈗��F���i�敪
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    ln_object_cnt           NUMBER;     -- �o�^�ΏۃJ�E���^
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
    gn_target_cnt             := 0;
    gn_normal_cnt             := 0;
    gn_error_cnt              := 0;
    gn_warn_cnt               := 0;
--
    gv_nodata_error           := 0;           -- �Ώۃf�[�^�擾�G���[
    gv_err_status             := cv_normal;   -- ���ʃG���[���b�Z�[�W �I��ST
    gn_cnt                    := 0;           -- �����p�J�E���^
    gn_err_set_cnt            := 0;           -- �G���[���X�g�p�J�E���^
    gn_mov_instr_hdr_cnt      := 0;           -- �w�b�_����
    gn_mov_instr_line_cnt     := 0;           -- ���C������
    gn_header_id              := 0;           -- �ړ��w���w�b�_ID
    gn_line_id                := 0;           -- �ړ��w������ID
    gn_line_number_cnt        := 0;           -- �w�b�_�P�ʖ��׌���
--
    gv_max_ship_method        := NULL;        -- �ő�z���敪
    gn_drink_deadweight       := 0;           -- �h�����N��{�d��
    gn_leaf_deadweight        := 0;           -- ���[�t��{�d��
    gn_drink_loading_capa     := 0;           -- �h�����N��{�e��
    gn_leaf_loading_capa      := 0;           -- ���[�t��{�e��
    gn_palette_max_qty        := 0;           -- �p���b�g�ő喇��
    gn_carrier_id             := NULL;        -- �^���Ǝ�ID
    gn_item_id                := 0;           -- �i��ID
    gv_item_um                := 0;           -- �P��
    gv_conv_unit              := 0;           -- ���o�Ɋ��Z�P��
    gn_delivery_qty           := 0;           -- �z��
    gn_max_palette_steps      := 0;           -- �p���b�g����ő�i��
    gn_num_of_cases           := 0;           -- �P�[�X����
    gn_num_of_deliver         := 0;           -- �o�ד���
    gn_max_case_for_palette   := 0;           -- �p���b�g����̍ő�P�[�X��
    gn_best_num_palette       := 0;           -- �œK���ʁF�p���b�g��
    gn_best_num_steps         := 0;           -- �œK���ʁF�i��
    gn_best_num_cases         := 0;           -- �œK���ʁF�P�[�X��
    gn_palette_num            := 0;           -- �p���b�g����
    gn_sum_palette_num        := 0;           -- �p���b�g���v����
    gn_instruct_qty           := 0;           -- �w������
    gn_ttl_instruct_qty       := 0;           -- �w�����ʍ��v
    gn_ttl_weight             := 0;           -- ���v�d��
    gn_ttl_capacity           := 0;           -- ���v�e��
    gn_ttl_palette_weight     := 0;           -- ���v�p���b�g�d��
    gn_sum_ttl_palette_weight := 0;           -- �����v�p���b�g�d��
    gn_sum_ttl_weight         := 0;           -- �����v�d��
    gn_sum_ttl_capacity       := 0;           -- �����v�e��
    gn_sml_amnt_num           := 0;           -- ������
    gn_ttl_sml_amnt_num       := 0;           -- ���������v
    gn_label_num              := 0;           -- ���x������
    gn_ttl_label_num          := 0;           -- ���x���������v
    ln_object_cnt             := 0;           -- �o�^�ΏۃJ�E���^
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    --  B-1.��������
    -- ===============================
    init(
        lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    --  B-2.�ړ��w��IF���擾
    -- ===============================
    get_interface_data(
        in_shipped_locat_cd -- �o�Ɍ��R�[�h
      , lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      RAISE no_data_if_expt;
    END IF;
--
    <<header_data_loop>>
    FOR i IN 1..g_mov_instr_tab.LAST LOOP
--
      -- �i�ڃ}�X�^�`�F�b�N�X�e�[�^�X������
      gv_item_mst_chk_sts := cv_status_normal;
--
      -- LOOP�J�E���g�C���N�������g
      gn_cnt := gn_cnt + 1;
--
      -- �ŏ��̃��R�[�h�܂��͉��`�[�ԍ����u���C�N�����ꍇ�A�w�b�_���ڂ̃`�F�b�N���s��
      IF ((lv_pre_tmp_ship_num IS NULL)
        OR  (lv_pre_tmp_ship_num <> g_mov_instr_tab(gn_cnt).temp_ship_num))
      THEN
--
        -- �w�b�_�P�ʖ��׌���������
        gn_line_number_cnt := 0;
--
        -- �O�񏈗����̃`�F�b�N�y�уw�b�_�o�^���s��
        IF (lv_pre_tmp_ship_num IS NOT NULL) THEN
--
          -- �O�񏈗��̃J�E���^���Z�b�g
          ln_object_cnt := gn_cnt - 1;
--
          -- �^���敪�ݒ肠�芎�ő�z���敪������ꍇ�̂�
          IF (g_mov_instr_tab(ln_object_cnt).freight_charge_class = cv_object) 
            AND (gv_max_ship_method IS NOT NULL)
          THEN
--
            -- ================================
            --  �ύڌ����I�[�o�[�`�F�b�N(B-16)
            -- ================================
            chk_loading_effic(
                in_object_cnt   => ln_object_cnt  -- �Ώۃf�[�^�J�E���^
              , ov_errbuf       => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
              , ov_retcode      => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
              , ov_errmsg       => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;
--
          -- ���i�敪�F�h�����N�A���i���ʋ敪�F���i�̏ꍇ�̂�
          IF ((gv_prod_cls = cv_drink)                                      -- ���i�敪�F�h�����N
            AND (g_mov_instr_tab(gn_cnt).product_flg = cv_prod_cls_prod))   -- ���i���ʋ敪�F���i
          THEN
--
            -- ================================
            --  �p���b�g���v�����`�F�b�N(B-17)
            -- ================================
            chk_sum_palette_sheets(
                in_object_cnt  => ln_object_cnt -- �Ώۃf�[�^�J�E���^
              , ov_errbuf       => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
              , ov_retcode      => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
              , ov_errmsg       => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;
--
          -- �G���[�������ꍇ�A�O�񏈗����̓o�^���s��
          IF (gv_err_status <> cv_status_error) THEN
--
            -- =============================
            -- �ړ��w���w�b�_���ݒ�(B-20)
            -- =============================
            set_header_data(
                in_object_cnt => ln_object_cnt  -- �o�^�ΏۃJ�E���^
              , ov_errbuf     => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
              , ov_retcode    => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
              , ov_errmsg     => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;
--
          -- �w�b�_���p�̕ϐ����������s��
          gn_we_loading             :=  0;    -- �ύڗ�(�d��)
          gn_ca_loading             :=  0;    -- �ύڗ�(�e��)
          gn_ttl_weight             :=  0;    -- ���v�d��
          gn_ttl_sml_amnt_num       :=  0;    -- ������
          gn_ttl_label_num          :=  0;    -- ���x������
          gn_drink_deadweight       :=  0;    -- �h�����N��{�d��
          gn_drink_loading_capa     :=  0;    -- �h�����N��{�e��
          gn_leaf_deadweight        :=  0;    -- ���[�t��{�d��
          gn_leaf_loading_capa      :=  0;    -- ���[�t��{�e��
          gn_sum_ttl_weight         :=  0;    -- �ύڏd�ʍ��v
          gn_sum_ttl_capacity       :=  0;    -- �ύڗe�ύ��v
          gn_sum_ttl_palette_weight :=  0;    -- �����v�p���b�g�d��
          gn_ttl_palette_weight     :=  0;    -- ���v�p���b�g�d��
          gn_sum_palette_num        :=  0;    -- �p���b�g���v����
          gn_ttl_instruct_qty       :=  0;    -- �w�����ʍ��v
          gv_carrier_code           :=  NULL; -- �^���Ǝ�
          gn_carrier_id             :=  NULL; -- �^���Ǝ�ID
          gv_max_ship_method        :=  NULL; -- �ő�z���敪
          lv_pre_item_code          :=  NULL; -- �i�ڃR�[�h
--
        END IF;
--
        -- �ύڌ����`�F�b�N�p�Ƀw�b�_���ڂ��m��
        gv_shipped_locat_code :=  g_mov_instr_tab(gn_cnt).shipped_locat_code; -- �o�Ɍ��R�[�h
        gv_ship_to_locat_code :=  g_mov_instr_tab(gn_cnt).ship_to_locat_code; -- ���ɐ�R�[�h
        gd_schedule_ship_date :=  g_mov_instr_tab(gn_cnt).schedule_ship_date; -- �o�ɓ�
--
        -- ==================================
        --  B-3.�ړ��w���w�b�_IF���`�F�b�N
        -- ==================================
        chk_if_header_data(
            lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
          , lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
          , lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- �^���敪�F�L��̏ꍇ�̂�
        IF (g_mov_instr_tab(gn_cnt).freight_charge_class = cv_on) THEN
--
          -- =====================================
          --  �ő�z���敪�E�����敪�擾(B-4,B-5)
          -- =====================================
          get_max_ship_method(
              lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
            , lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
            , lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
        -- ==================================
        --  �ғ����`�F�b�N(B-19)
        -- ==================================
        chk_operating_day(
            lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
          , lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
          , lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =============================
        -- �֘A�f�[�^�擾����(B-6, B-7)
        -- =============================
        get_relating_data(
              lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
            , lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
            , lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        ------------------------------
        -- �ړ��w���w�b�_�h�c�擾
        ------------------------------
        BEGIN
          SELECT xxinv_mov_hdr_s1.NEXTVAL
          INTO   gn_header_id
          FROM   dual
          ;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
--
        -- �w�b�_�����J�E���g
        gn_mov_instr_hdr_cnt  := gn_mov_instr_hdr_cnt + 1;
--
      END IF; -- �w�b�_���ڃ`�F�b�N�I��
--
      -- ============================================
      -- B-8.�ړ��w�����׃C���^�t�F�[�X���`�F�b�N
      -- ============================================
      -- ���׌����J�E���^ �C���N�������g
      gn_mov_instr_line_cnt := gn_mov_instr_line_cnt + 1;
--
      -- �w�b�_�P�ʖ��׌��� �C���N�������g
      gn_line_number_cnt := gn_line_number_cnt + 1;
--
      -- �w�������`�F�b�N
      IF (g_mov_instr_tab(gn_cnt).first_instruct_qty = 0) THEN
--
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_15
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                      , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                      , in_rec_cnt  => gn_cnt
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); --
--
        -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
        gv_err_status := cv_status_error;
--
      END IF;
--
      -- ===========================
      -- B-9.�i�ڏ��擾
      -- ===========================
      get_item_info(
          lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      IF (gb_get_item_flg) THEN
--
        ---------------------------------
        -- �h�����N�E���[�t���ڃ`�F�b�N
        ---------------------------------
        IF (gv_secur_prod_class <> gv_prod_cls) THEN
--
          IF (gv_secur_prod_class = cv_drink) THEN
--
            gv_msg_prod_cls := cv_prod_cls_drink; -- �h�����N
--
          ELSE
--
            gv_msg_prod_cls := cv_prod_cls_leaf;  -- ���[�t
--
          END IF;
--
          gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                                , cv_err_msg_14
                                                , cv_tkn_item
                                                , gv_msg_prod_cls
                                                );
--
          make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                        , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                        , in_rec_cnt  => gn_cnt
                        , ov_errbuf   => lv_errbuf        
                        , ov_retcode  => lv_retcode       
                        , ov_errmsg   => lv_errmsg        
                       ); --
--
          -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
          gv_err_status := cv_status_error;
--
        END IF;
--
        ---------------------
        -- �i�ڏd���`�F�b�N
        ---------------------
        IF (lv_pre_item_code = g_mov_instr_tab(gn_cnt).item_code) THEN
--
          gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                                , cv_err_msg_13
                                                );
--
          make_err_list(  iv_kind     => cv_msg_err       -- �G���[���
                        , iv_err_info => gv_out_msg       -- �G���[���b�Z�[�W
                        , in_rec_cnt  => gn_cnt
                        , ov_errbuf   => lv_errbuf        
                        , ov_retcode  => lv_retcode       
                        , ov_errmsg   => lv_errmsg        
                       ); --
--
          -- ���ʃG���[���b�Z�[�W�I���X�e�[�^�X
          gv_err_status := cv_status_error;
--
        END IF;
--
        -- ���i�敪�F�h�����N�A���i���ʋ敪�F���i�̏ꍇ�̂�
        IF ((gv_prod_cls = cv_drink)                                      -- ���i�敪�F�h�����N
          AND (g_mov_instr_tab(gn_cnt).product_flg = cv_prod_cls_prod))   -- ���i���ʋ敪�F���i
        THEN
          -- ===========================
          -- B-10.�i�ڃ}�X�^�`�F�b�N
          -- ===========================
          chk_item_mst(
              lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
            , lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
            , lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �i�ڃ}�X�^�`�F�b�N������̏ꍇ
          IF (gv_item_mst_chk_sts = cv_status_normal) THEN
--
            -- ===========================
            -- �œK���ʂ̎Z�o(B-11,B-12)
            -- ===========================
            calc_best_amount(
                lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
              , lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
              , lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;
--
        END IF;
--
        -- =================================
        --  �w�����ʂ̎Z�o(B-13,B-14,B-15)
        -- =================================
        calc_instruct_amount(
            lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
          , lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
          , lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
      -- �G���[���Ȃ��ꍇ�̂�
      IF (gv_err_status <> cv_status_error) THEN
--
        -- ===========================
        -- �ړ��w�����׏��ݒ�
        -- ===========================
        set_line_data(
            lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
          , lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
          , lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
--
          RAISE global_process_expt;
--
        END IF;
--
      END IF;
--
      -- ���חp�̕ϐ�������
      gn_best_num_palette   := 0;   -- �i��ID
      gn_item_id            := 0;   -- �p���b�g��
      gn_best_num_steps     := 0;   -- �i��
      gn_best_num_cases     := 0;   -- �P�[�X��
      gn_instruct_qty       := 0;   -- �w������
      gv_conv_unit          := 0;   -- �P��
      gn_palette_num        := 0;   -- �p���b�g����
      gn_ttl_weight         := 0;   -- �d��
      gn_ttl_capacity       := 0;   -- �e��
      gn_ttl_palette_weight := 0;   -- �p���b�g�d��
--
      -- �����ς݂̉��`�[�ԍ����Z�b�g
      lv_pre_tmp_ship_num := g_mov_instr_tab(gn_cnt).temp_ship_num;
      -- �����ς݂̕i�ڃR�[�h���Z�b�g
      lv_pre_item_code    := g_mov_instr_tab(gn_cnt).item_code;
      -- �����ς݂̏��i�敪���Z�b�g
      lv_pre_prod_cls     := gv_prod_cls;
--
    END LOOP header_data_loop;
--
    --�Ō�ɏ��������w�b�_�f�[�^��o�^�p�e�[�u���Ɋi�[����B
    -- �^����X���ݒ肠��̏ꍇ�̂�
    IF (g_mov_instr_tab(gn_cnt).freight_charge_class = cv_object) 
      AND (gv_max_ship_method IS NOT NULL)
    THEN
      -- ================================
      --  �ύڌ����I�[�o�[�`�F�b�N(B-16)
      -- ================================
      chk_loading_effic(
          in_object_cnt   => gn_cnt     -- �Ώۃf�[�^�J�E���^
        , ov_errbuf       => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode      => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg       => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ���i�敪�F�h�����N�A���i���ʋ敪�F���i�̏ꍇ�̂�
    IF ((gv_prod_cls = cv_drink)                                      -- ���i�敪�F�h�����N
      AND (g_mov_instr_tab(gn_cnt).product_flg = cv_prod_cls_prod))   -- ���i���ʋ敪�F���i
    THEN
--
      -- ================================
      --  �p���b�g���v�����`�F�b�N(B-17)
      -- ================================
      chk_sum_palette_sheets(
          in_object_cnt => gn_cnt   -- �Ώۃf�[�^�J�E���^
          , ov_errbuf       => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode      => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg       => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- �G���[�������ꍇ�A�O�񏈗����̓o�^���s��
    IF (gv_err_status <> cv_status_error) THEN
--
      ln_object_cnt := gn_cnt;
--
      -- =============================
      -- �ړ��w���w�b�_���ݒ�(B-20)
      -- =============================
      set_header_data(
          in_object_cnt   => gn_cnt     -- �Ώۃf�[�^�J�E���^
        , ov_errbuf       => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode      => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg       => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =================================
      --  �ړ��w���w�b�_�o�^����(B-22)
      -- =================================
      ins_mov_req_instr_header(
          lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =================================
      --  �ړ��w�����דo�^����(B-23)
      -- =================================
      ins_mov_req_instr_line(
          lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- �X�e�[�^�X�ݒ�
    IF (gv_err_status = cv_status_error)    -- �G���[
      OR (gv_err_status = cv_status_warn)   -- �x��
    THEN
--
      ov_retcode := gv_err_status;
--
    END IF;
--
    -- �X�e�[�^�X���G���[�̏ꍇ�̓��[���o�b�N����
    IF (ov_retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
    -- ==============================
    --  �p�[�W����(B-24)
    -- ==============================
    purge_processing(
        in_shipped_locat_cd   -- �o�Ɍ��R�[�h
      , lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    COMMIT;
--
    ---------------------
    -- �G���[���X�g�o��
    ---------------------
    put_err_list(
       in_shipped_locat_cd  -- �o�Ɍ��R�[�h
      ,lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
    WHEN no_data_if_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
      -- �J�[�\���̃N���[�Y�������ɋL�q����
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
      errbuf              OUT VARCHAR2              -- �G���[�E���b�Z�[�W  --# �Œ� #
    , retcode             OUT VARCHAR2              -- ���^�[���E�R�[�h    --# �Œ� #
    , in_shipped_locat_cd IN  VARCHAR2 DEFAULT NULL -- �o�Ɍ��R�[�h
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
    cv_prg_name           CONSTANT  VARCHAR2(100) :=  'main';             -- �v���O������
    cv_userenv            CONSTANT  VARCHAR2(4)   :=  userenv('LANG');    -- USERENV
    cv_appl_id            CONSTANT  NUMBER        :=  0;                  -- �A�v���P�[�V����ID
    cv_status_code        CONSTANT  VARCHAR2(14)  :=  'CP_STATUS_CODE';   -- �X�e�[�^�X�R�[�h
--
    cv_msg_user_name      CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00001';  -- ���[�U��
    cv_msg_conc_name      CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00002';  -- �R���J�����g��
    cv_msg_start_time     CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-10118';  -- �N������
    cv_msg_separater      CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00003';  -- �Z�p���[�^
    cv_msg_standard       CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-10030';  -- �R���J�����g��^���b�Z�[�W
    cv_msg_process_cnt    CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00008';  -- ��������
    cv_msg_success_cnt    CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00009';  -- ��������
    cv_msg_error_cnt      CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00010';  -- �G���[����
    cv_msg_skip_cnt       CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00011';  -- �X�L�b�v����
    cv_msg_proc_status    CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00012';  -- �����X�e�[�^�X
    cv_msg_header_cnt     CONSTANT  VARCHAR2(15)  :=  'APP-XXINV-10195';  -- �ړ��w���w�b�_����
    cv_msg_line_cnt       CONSTANT  VARCHAR2(15)  :=  'APP-XXINV-10196';  -- �ړ��w�����׌���
    cv_msg_header_if_cnt  CONSTANT  VARCHAR2(15)  :=  'APP-XXINV-10197';  -- �ړ��w���w�b�_IF����
    cv_msg_line_if_cnt    CONSTANT  VARCHAR2(15)  :=  'APP-XXINV-10198';  -- �ړ��w������IF����
--
    -- �g�[�N��
    cv_tkn_user           CONSTANT  VARCHAR2(4)   :=  'USER';
    cv_tkn_conc           CONSTANT  VARCHAR2(4)   :=  'CONC';
    cv_tkn_count          CONSTANT  VARCHAR2(3)   :=  'CNT';
    cv_tkn_status         CONSTANT  VARCHAR2(6)   :=  'STATUS';
    cv_tkn_time           CONSTANT  VARCHAR2(4)   :=  'TIME';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    ln_ins_hdr_cnt     NUMBER;          -- �w�b�_�o�^����
    ln_ins_line_cnt    NUMBER;          -- ���דo�^����
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
    gv_out_msg := xxcmn_common_pkg.get_msg( cv_msg_kbn
                                          , cv_msg_user_name
                                          , cv_tkn_user
                                          , gv_exec_user
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg( cv_msg_kbn
                                          , cv_msg_conc_name
                                          , cv_tkn_conc
                                          , gv_conc_name
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg( cv_msg_kbn
                                          , cv_msg_separater
                                          );
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       in_shipped_locat_cd  -- �o�Ɍ��R�[�h
      ,lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
--
    -- �G���[���X�g���o�͂��Ȃ��ꍇ�A�ȉ��̍��ڂ��o��
    IF (gv_nodata_error = cv_nodata) THEN
--
      -------------------------------------
      -- �o�͍���                        --
      -------------------------------------
      -- ���O�C�����[�U�̏��������R�[�h
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_msg_user_org_id
                                            , cv_tkn_value
                                            , gv_user_dept_id
                                            );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
      -- ���̓p�����[�^�u�o�ɑq�Ɂv
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_msg_shipped_loc
                                            , cv_tkn_value
                                            , in_shipped_locat_cd
                                            );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    END IF;
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��(�ړ��w��IF�w�b�_����)
    gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                          , cv_msg_header_if_cnt
                                          , cv_tkn_count
                                          , TO_CHAR(gn_mov_instr_hdr_cnt)
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��(�ړ��w��IF���׌���)
    gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                          , cv_msg_line_if_cnt
                                          , cv_tkn_count
                                          , TO_CHAR(gn_mov_instr_line_cnt)
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    IF (gv_err_status = cv_status_error) 
      OR (lv_retcode = cv_status_error)
    THEN
--
      ln_ins_hdr_cnt  := 0;
      ln_ins_line_cnt := 0;
--
    ELSE
--
      ln_ins_hdr_cnt  := TO_CHAR(g_mov_hdr_id_tab.COUNT);
      ln_ins_line_cnt := TO_CHAR(g_mov_line_id_tab.COUNT);
--
    END IF;
--
    --���������o��(�ړ��w���w�b�_����)
    gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                          , cv_msg_header_cnt
                                          , cv_tkn_count
                                          , ln_ins_hdr_cnt
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��(�ړ��w�����׌���)
    gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                          , cv_msg_line_cnt
                                          , cv_tkn_count
                                          , ln_ins_line_cnt
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = cv_userenv
    AND    flv.view_application_id = cv_appl_id
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = cv_status_code
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            cv_status_normal,cv_sts_cd_normal,
                                            cv_status_warn,cv_sts_cd_warn,
                                            cv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg( cv_msg_kbn
                                          , cv_msg_proc_status
                                          , cv_tkn_status,gv_conc_status
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;

   --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    ELSE
      COMMIT;
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
END XXINV500002C;
/
