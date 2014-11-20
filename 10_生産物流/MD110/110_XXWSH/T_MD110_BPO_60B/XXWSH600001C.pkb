CREATE OR REPLACE PACKAGE BODY xxwsh600001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh600001c(body)
 * Description      : �����z�Ԕz���v��쐬����
 * MD.050           : �z�Ԕz���v�� T_MD050_BPO_600
 * MD.070           : �����z�Ԕz���v��쐬���� T_MD070_BPO_60B
 * Version          : 1.17
 *
 * Program List
 * ----------------------------- ---------------------------------------------------------
 *  Name                          Description
 * ----------------------------- ---------------------------------------------------------
 *  del_table_purge               �p�[�W����(B-1)
 *  get_req_inst_info             �˗��E�w����񒊏o(B-3)
 *  ins_hub_mixed_info            ���_���ڏ��o�^����(B-4)
 *  chk_loading_efficiency        �ύڌ����`�F�b�N����(B-5)
 *  set_weight_capacity_add       ���v�d��/�e�ώ擾 ���Z����(B-7)
 *  ins_intensive_carriers_tmp    �W�񒆊ԃe�[�u���o�͏���(B-8)
 *  get_max_shipping_method       �ő�z���敪�E�d�ʗe�ϋ敪�擾����(B-6)
 *  set_delivery_no               �z��No�ݒ菈��
 *  set_small_sam_class           �����z�����쐬����
 *  get_intensive_tmp             �W�񒆊ԏ�񒊏o����(B-9)
 *  ins_xxwsh_carriers_schedule   �z�Ԕz���v��A�h�I���o��(B-14)
 *  upd_req_inst_info             �˗��E�w�����X�V����(B-15)
 *  submain                       ���C�������v���V�[�W��
 *  main                          �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/11    1.0   Y.Kanami         �V�K�쐬
 *  2008/06/26    1.1  Oracle D.Sugahara ST��Q #297�Ή� *
 *  2008/07/02    1.2  Oracle M.Hokkanji ST��Q #321�A#351�Ή� *
 *  2008/07/10    1.3  Oracle M.Hokkanji TE080�w�E03�Ή��A�w�b�_�ύڗ��Čv�Z�Ή�
 *  2008/07/14    1.4  Oracle �R����_   �d�l�ύXNo.95�Ή�
 *  2008/08/04    1.5  Oracle M.Hokkanji �����ăe�X�g�s��Ή�(400TE080_159����2)ST#513�Ή�
 *  2008/08/06    1.6  Oracle M.Hokkanji ST�s�493�Ή�
 *  2008/08/08    1.7  Oracle M.Hokkanji ST�s�510�Ή��A�����ύX173�Ή�
 *  2008/09/05    1.8  Oracle A.Shiina   PT 6-1_27 �w�E41-2 �Ή�
 *  2008/10/01    1.9  Oracle H.Itou     PT 6-1_27 �w�E18 �Ή�
 *  2008/10/16    1.10 Oracle H.Itou     T_S_625,�����e�X�g�w�E369
 *  2008/10/24    1.11 Oracle H.Itou     T_TE080_BPO_600�w�E26
 *  2008/10/30    1.12 Oracle H.Itou     �����e�X�g�w�E526
 *  2008/11/19    1.13 SCS    H.Itou     �����e�X�g�w�E666
 *  2008/11/29    1.14 SCS    MIYATA     ���b�N�Ή� NO WAIT�@���폜����WAIT�ɂ���
 *  2008/12/02    1.15 SCS    H.Itou     �{�ԏ�Q#220�Ή�
 *  2008/12/07    1.16 SCS    D.Sugahara �{�ԏ�Q#524�b��Ή�
 *  2009/01/05    1.17 SCS    H.Itou     �{�ԏ�Q#879�Ή�
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
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  lock_expt       EXCEPTION;  -- ���b�N�擾��O
  no_data         EXCEPTION;  -- �f�[�^�擾��O
  to_date_expt    EXCEPTION;  -- ���t�ϊ��G���[
  to_date_expt_m  EXCEPTION;  -- ���t�ϊ��G���[m
  to_date_expt_d  EXCEPTION;  -- ���t�ϊ��G���[d
  to_date_expt_y  EXCEPTION;  -- ���t�ϊ��G���[y
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);        -- ���b�N�擾��O
  PRAGMA EXCEPTION_INIT(to_date_expt_m, -1843); -- ���t�ϊ��G���[m
  PRAGMA EXCEPTION_INIT(to_date_expt_d, -1847); -- ���t�ϊ��G���[d
  PRAGMA EXCEPTION_INIT(to_date_expt_y, -1861); -- ���t�ϊ��G���[y
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name           CONSTANT VARCHAR2(100)  :=  'xxwsh600001c'; -- �p�b�P�[�W��
  gv_xxwsh              CONSTANT VARCHAR2(100)  :=  'XXWSH';
                                                      -- ���W���[�����̗��F�o�ׁE����/�z��
  -- ���b�Z�[�W
  gv_msg_xxwsh_13151    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-13151';
                                                      -- ���b�Z�[�W�F�K�{�p�����[�^�����̓��b�Z�[�W
  gv_msg_xxwsh_11113    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11113';
                                                      -- ���b�Z�[�W�F���t�t�]�G���[���b�Z�[�W
  gv_msg_xxwsh_11052    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11052';
                                                      -- ���b�Z�[�W�F���b�N�擾�G���[
  gv_msg_xxwsh_11804    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11804';
                                                      -- ���b�Z�[�W�F�Ώۃf�[�^����
  gv_msg_xxwsh_11802    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11802';
                                                      -- ���b�Z�[�W�F�ő�z���敪�擾�G���[
  gv_msg_xxwsh_11803    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11803';
                                                      -- ���b�Z�[�W�F�ύڃI�[�o�[���b�Z�[�W
  gv_msg_xxwsh_11805    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11805';
                                                      -- ���b�Z�[�W�F�z��No�擾�G���[
  gv_msg_xxwsh_11806    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11806';
                                                      -- ���b�Z�[�W�F���̓p�����[�^(���o��)
  gv_msg_xxwsh_11807    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11807';
                                                      -- ���b�Z�[�W�F�o�׈˗�����
  gv_msg_xxwsh_11808    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11808';
                                                      -- ���b�Z�[�W�F�ړ��w������
  gv_msg_xxwsh_11809    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11809';
                                                      -- ���b�Z�[�W�F���̓p�����[�^�����G���[
  gv_msg_xxwsh_11810    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11810';
                                                      -- ���b�Z�[�W�F���ʊ֐��G���[
  gv_msg_xxwsh_11813    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11813';
                                                      -- ���b�Z�[�W�F�^���`�Ԏ擾�G���[
-- Ver1.3 M.Hokkanji Start
  gv_msg_xxwsh_11814    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11814';
                                                      -- ���b�Z�[�W�F�z���敪�擾�G���[
-- Ver1.3 M.Hokkanji End
--
  -- �g�[�N��
  gv_tkn_item           CONSTANT VARCHAR2(100)  :=  'ITEM';       -- �g�[�N���FITEM
  gv_tkn_table          CONSTANT VARCHAR2(100)  :=  'TABLE';      -- �g�[�N���FTABLE
  gv_tkn_key            CONSTANT VARCHAR2(100)  :=  'KEY';        -- �g�[�N���FKEY
  gv_tkn_from           CONSTANT VARCHAR2(100)  :=  'FROM';       -- �g�[�N���FFROM
  gv_tkn_to             CONSTANT VARCHAR2(100)  :=  'TO';         -- �g�[�N���FTO
  gv_tkn_codekbn1       CONSTANT VARCHAR2(100)  :=  'CODEKBN1';   -- �g�[�N���FCODEKBN1
  gv_tkn_codekbn2       CONSTANT VARCHAR2(100)  :=  'CODEKBN2';   -- �g�[�N���FCODEKBN2
  gv_tkn_req_no         CONSTANT VARCHAR2(100)  :=  'REQ_NO';     -- �g�[�N���FREQ_NO
  gv_tkn_errmsg         CONSTANT VARCHAR2(100)  :=  'ERRMSG';     -- �g�[�N���FERRMSG
  gv_tkn_count          CONSTANT VARCHAR2(100)  :=  'COUNT';      -- �g�[�N���FCOUNT
  gv_tkn_parm_name      CONSTANT VARCHAR2(100)  :=  'PARM_NAME';  -- �g�[�N���FPARM_NAME
  gv_tkn_delivry_no     CONSTANT VARCHAR2(100)  :=  'DELIVERY_NO';-- �g�[�N���FDELIVERY_NO
  gv_tkn_branch         CONSTANT VARCHAR2(100)  :=  'BRANCH';     -- �g�[�N���FBRANCH
  gv_fnc_name           CONSTANT VARCHAR2(100)  :=  'FNC_NAME';   -- �g�[�N���FFNC_NAME
-- Ver1.3 M.Hokkanji Start
  gv_tkn_ship_method    CONSTANT VARCHAR2(100)  := 'SHIP_METHOD'; -- �g�[�N���FSHIP_METHOD
  gv_tkn_source_no      CONSTANT VARCHAR2(100)  := 'SOURCE_NO';   -- �g�[�N���FSOURCE_NO
-- Ver1.3 M.Hokkanji END
--
  gv_prod_cls_leaf      CONSTANT VARCHAR2(1)    :=  '1';          -- ���i�敪�F���[�t
  gv_prod_cls_drink     CONSTANT VARCHAR2(1)    :=  '2';          -- ���i�敪�F�h�����N
  gv_ship_type_ship     CONSTANT VARCHAR2(30)   :=  '1';          -- ������ʁF�o��
  gv_ship_type_move     CONSTANT VARCHAR2(30)   :=  '3';          -- ������ʁF�ړ�
  gv_weight             CONSTANT VARCHAR2(30)   :=  '1';          -- �d�ʗe�ϋ敪�F�d��
  gv_capacity           CONSTANT VARCHAR2(30)   :=  '2';          -- �d�ʗe�ϋ敪�F�e��
  gv_cdkbn_storage      CONSTANT VARCHAR2(30)   :=  '4';          -- �R�[�h�敪�F�q��
  gv_cdkbn_ship_to      CONSTANT VARCHAR2(30)   :=  '9';          -- �R�[�h�敪�F�z����
  gv_on                 CONSTANT VARCHAR2(1)    :=  '1';          -- ON
  gv_off                CONSTANT VARCHAR2(1)    :=  '0';          -- OFF
  gv_mixed_class_mixed  CONSTANT VARCHAR2(1)    :=  '2';          -- ���ڎ�ʁF����
  gv_mixed_class_int    CONSTANT VARCHAR2(1)    :=  '1';          -- ���ڎ�ʁF�W��
  gv_frt_chrg_type_set  CONSTANT VARCHAR2(1)    :=  '1';          -- �^���`�ԁF�ݒ�U��
  gv_frt_chrg_type_act  CONSTANT VARCHAR2(1)    :=  '2';          -- �^���`�ԁF����U��
  gv_error              CONSTANT NUMBER         :=  1;            -- �֐��߂�l�F�G���[
  gv_normal             CONSTANT NUMBER         :=  0;            -- �֐��߂�l�F����
--
  -- 2008/07/14 Add
  gv_all_z4             CONSTANT VARCHAR2(4)    :=  'ZZZZ';
  gv_all_z9             CONSTANT VARCHAR2(9)    :=  'ZZZZZZZZZ';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �˗�/�w�����擾�p���R�[�h�^
  TYPE ship_move_rtype IS RECORD(
      deliver_no            xxwsh_order_headers_all.delivery_no%TYPE            -- �z��No
    , pre_deliver_no        xxwsh_order_headers_all.prev_delivery_no%TYPE       -- �O��z��No
    , req_mov_no            xxwsh_order_headers_all.request_no%TYPE             -- �˗�No/�ړ�No
    , mixed_no              xxwsh_order_headers_all.mixed_no%TYPE               -- ���ڌ�No
    , carrier_code          xxwsh_order_headers_all.freight_carrier_code%TYPE   -- �^���Ǝ�
    , carrier_id            xxwsh_order_headers_all.career_id%TYPE              -- �^���Ǝ�ID
    , ship_from             xxwsh_order_headers_all.deliver_from%TYPE           -- �o�׌��ۊǏꏊ
    , ship_from_id          xxwsh_order_headers_all.deliver_from_id%TYPE        -- �o�׌�ID
    , ship_to               xxwsh_order_headers_all.deliver_to%TYPE             -- �o�א�
    , ship_to_id            xxwsh_order_headers_all.deliver_to_id%TYPE          -- �o�א�ID
    , ship_method_code      xxwsh_order_headers_all.shipping_method_code%TYPE   -- �z���敪
    , small_div             xxcmn_lookup_values2_v.attribute6%TYPE              -- �����敪
    , ship_date             xxwsh_order_headers_all.schedule_ship_date%TYPE     -- �o�ɓ�
    , arrival_date          xxwsh_order_headers_all.schedule_arrival_date%TYPE  -- ���ד�
    , based_weight          xxwsh_order_headers_all.based_weight%TYPE           -- ��{�d��
    , based_capacity        xxwsh_order_headers_all.based_capacity%TYPE         -- ��{�e��
    , sum_weight            xxwsh_order_headers_all.sum_weight%TYPE             -- �ύڏd�ʍ��v
    , sum_capacity          xxwsh_order_headers_all.sum_capacity%TYPE           -- �ύڗe�ύ��v
    , weight_capacity_cls   xxwsh_order_headers_all.weight_capacity_class%TYPE  -- �d�ʗe�ϋ敪
    , sum_pallet_weight     xxwsh_order_headers_all.sum_pallet_weight%TYPE      -- ���v�p���b�g�d��
    , item_class            xxwsh_order_headers_all.prod_class%TYPE             -- ���i�敪
    , business_type_id    xxwsh_oe_transaction_types2_v.transaction_type_id%TYPE
                                                                                -- ����^�C�v
    , reserve_order         xxcmn_parties.reserve_order%TYPE                    -- ������
    , sales_branch          xxwsh_order_headers_all.head_sales_branch%TYPE      -- �Ǌ����_
    );
--
  -- �˗�/�w�����擾�p�e�[�u���^
  TYPE ship_move_ttype IS TABLE OF ship_move_rtype INDEX BY BINARY_INTEGER;
--
  -- �\�[�g�p���ԃe�[�u�����R�[�h�^
  TYPE grp_sum_add_rtype IS RECORD(
      transaction_id      xxwsh_carriers_sort_tmp.transaction_id%TYPE           -- �g�����U�N�V����ID
    , tran_type           xxwsh_carriers_sort_tmp.transaction_type%TYPE         -- �������
    , req_mov_no          xxwsh_carriers_sort_tmp.request_no%TYPE               -- �˗�No/�ړ�No
    , mixed_no            xxwsh_carriers_sort_tmp.mixed_no%TYPE                 -- ���ڌ�No
    , ship_from           xxwsh_carriers_sort_tmp.deliver_from%TYPE             -- �o�׌��ۊǏꏊ
    , ship_from_id        xxwsh_carriers_sort_tmp.deliver_from_id%TYPE          -- �o�׌�ID
    , ship_to             xxwsh_carriers_sort_tmp.deliver_to%TYPE               -- �o�א�
    , ship_to_id          xxwsh_carriers_sort_tmp.deliver_to_id%TYPE            -- �o�א�ID
    , ship_method_code    xxwsh_carriers_sort_tmp.shipping_method_code%TYPE     -- �z���敪
    , ship_date           xxwsh_carriers_sort_tmp.schedule_ship_date%TYPE       -- �o�ɓ�
    , arrival_date        xxwsh_carriers_sort_tmp.schedule_arrival_date%TYPE    -- ���ד�
    , order_type_id       xxwsh_carriers_sort_tmp.order_type_id%TYPE            -- ����^�C�v
    , carrier_code        xxwsh_carriers_sort_tmp.freight_carrier_code%TYPE     -- �^���Ǝ�
    , carrier_id          xxwsh_carriers_sort_tmp.career_id%TYPE                -- �^���Ǝ�ID
    , based_weight        xxwsh_carriers_sort_tmp.based_weight%TYPE             -- ��{�d��
    , based_capacity      xxwsh_carriers_sort_tmp.based_capacity%TYPE           -- ��{�e��
    , sum_weight          xxwsh_carriers_sort_tmp.sum_weight%TYPE               -- �ύڏd�ʍ��v
    , sum_capacity        xxwsh_carriers_sort_tmp.sum_capacity%TYPE             -- �ύڗe�ύ��v
    , sum_pallet_weight   xxwsh_carriers_sort_tmp.sum_pallet_weight%TYPE        -- ���v�p���b�g�d��
    , max_shipping_method  xxwsh_carriers_sort_tmp.max_shipping_method_code%TYPE -- �ő�z���敪
    , weight_capacity_cls xxwsh_carriers_sort_tmp.weight_capacity_class%TYPE    -- �d�ʗe�ϋ敪
    , reserve_order       xxwsh_carriers_sort_tmp.reserve_order%TYPE            -- ������
    , head_sales_branch   xxwsh_carriers_sort_tmp.head_sales_branch%TYPE        -- �Ǌ����_
    , finish_sum_flag     VARCHAR2(1)                                           -- �W��σt���O
    );
--
  --
  TYPE pre_saved_flg_ttype IS
    TABLE OF xxwsh_carriers_sort_tmp.pre_saved_flg%TYPE INDEX BY BINARY_INTEGER;
                                                                          -- ���_���ړo�^�σt���O
  TYPE finish_sum_flag_ttype IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;
                                                                          -- �W��σt���O
--
  -- ���Z�����p�e�[�u���^
  TYPE grp_sum_add_ttype IS TABLE OF grp_sum_add_rtype INDEX BY BINARY_INTEGER;
--
  -- �����z�ԏW�񒆊ԃe�[�u���p���R�[�h
  TYPE intensive_carriers_tmp_rtype IS RECORD(
      intensive_no              xxwsh_intensive_carriers_tmp.intensive_no%TYPE  -- �W��No
    , transaction_type          xxwsh_intensive_carriers_tmp.transaction_type%TYPE
                                                                                -- ������ʁi�z�ԁj
    , intensive_source_no       xxwsh_intensive_carriers_tmp.intensive_source_no%TYPE
                                                                                -- �W��No
    , deliver_from              xxwsh_intensive_carriers_tmp.deliver_from%TYPE  -- �z����
    , deliver_from_id           xxwsh_intensive_carriers_tmp.deliver_from_id%TYPE
                                                                                -- �z����ID
    , deliver_to                xxwsh_intensive_carriers_tmp.deliver_to%TYPE    -- �z����
    , deliver_to_id             xxwsh_intensive_carriers_tmp.deliver_to_id%TYPE -- �z����ID
    , schedule_ship_date        xxwsh_intensive_carriers_tmp.schedule_ship_date%TYPE
                                                                                -- �o�ɗ\���
    , schedule_arrival_date     xxwsh_intensive_carriers_tmp.schedule_arrival_date%TYPE
                                                                                -- ���ח\���
    , transaction_type_name     xxwsh_intensive_carriers_tmp.transaction_type_name%TYPE
                                                                                -- �o�Ɍ`��
    , freight_carrier_code      xxwsh_intensive_carriers_tmp.freight_carrier_code%TYPE
                                                                                -- �^���Ǝ�
    , carrier_id                xxwsh_intensive_carriers_tmp.carrier_id%TYPE    -- �^���Ǝ�ID
    , head_sales_branch         xxwsh_intensive_carriers_tmp.head_sales_branch%TYPE
                                                                                -- �Ǌ����_
    , reserve_order             xxwsh_intensive_carriers_tmp.reserve_order%TYPE -- ������
    , intensive_sum_weight      xxwsh_intensive_carriers_tmp.intensive_sum_weight%TYPE
                                                                                -- �W�񍇌v�d��
    , intensive_sum_capacity    xxwsh_intensive_carriers_tmp.intensive_sum_capacity%TYPE
                                                                                -- �W�񍇌v�e��
    , max_shipping_method_code  xxwsh_intensive_carriers_tmp.max_shipping_method_code%TYPE
                                                                                -- �ő�z���敪
    , weight_capacity_class     xxwsh_intensive_carriers_tmp.weight_capacity_class%TYPE
                                                                                -- �d�ʗe�ϋ敪
    , max_weight                xxwsh_intensive_carriers_tmp.max_weight%TYPE    -- �ő�ύڏd��
    , max_capacity              xxwsh_intensive_carriers_tmp.max_capacity%TYPE  -- �ő�ύڗe��
    , finish_sum_flag           VARCHAR2(1)                                     -- �W��σt���O
    );
--
  -- �����z�ԏW�񒆊ԃe�[�u���p�e�[�u���^
  TYPE int_carr_tmp_ttype IS TABLE OF intensive_carriers_tmp_rtype INDEX BY BINARY_INTEGER;
--
  -- �z��No�U�蒼���p���R�[�h
  TYPE reset_delivery_no_rtype IS RECORD(
      int_no            xxwsh_mixed_carriers_tmp.intensive_no%TYPE      -- �W��No
    , req_no            xxwsh_intensive_carrier_ln_tmp.request_no%TYPE  -- �˗�No/�ړ�No
    , delivery_no       xxwsh_mixed_carriers_tmp.delivery_no%TYPE       -- �z��No
    , prev_delivery_no  xxwsh_carriers_sort_tmp.prev_delivery_no%TYPE   -- �O��z��No
-- Ver1.2 M.Hokkanji Start
    , use_delivery_no   xxwsh_carriers_sort_tmp.delivery_no%TYPE        -- ���z��No
-- Ver1.2 M.Hokkanji End
  );
--
  -- �z��No�U�蒼���pPL/SQL�\�^
  TYPE reset_delivery_no_ttype IS TABLE OF reset_delivery_no_rtype INDEX BY BINARY_INTEGER;
--
  -- �\�[�g�e�[�u���o�^�p
  TYPE transaction_id_ttype   IS
    TABLE OF xxwsh_carriers_sort_tmp.transaction_id%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �g�����U�N�V����ID
  TYPE deliver_no_ttype           IS
    TABLE OF xxwsh_carriers_sort_tmp.delivery_no%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �z��No
  TYPE pre_deliver_no_ttype       IS
    TABLE OF xxwsh_carriers_sort_tmp.prev_delivery_no%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �O��z��No
  TYPE req_mov_no_ttype           IS
    TABLE OF xxwsh_carriers_sort_tmp.request_no%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �˗�No/�ړ�No
  TYPE mixed_no_ttype             IS
    TABLE OF xxwsh_carriers_sort_tmp.mixed_no%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- ���ڌ�No
  TYPE carrier_code_ttype         IS
    TABLE OF xxwsh_carriers_sort_tmp.freight_carrier_code%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �^���Ǝ�
  TYPE carrier_id_ttype           IS
    TABLE OF xxwsh_carriers_sort_tmp.career_id%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �^���Ǝ�ID
  TYPE ship_from_ttype            IS
    TABLE OF xxwsh_carriers_sort_tmp.deliver_from%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �o�׌��ۊǏꏊ
  TYPE ship_to_ttype              IS
    TABLE OF xxwsh_carriers_sort_tmp.deliver_to%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �o�א�
  TYPE ship_method_code_ttype     IS
    TABLE OF xxwsh_carriers_sort_tmp.shipping_method_code%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �z���敪
  TYPE small_div_ttype            IS
    TABLE OF xxwsh_carriers_sort_tmp.small_sum_class%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �����敪
  TYPE ship_date_ttype            IS
    TABLE OF xxwsh_carriers_sort_tmp.schedule_ship_date%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �o�ɓ�
  TYPE arrival_date_ttype         IS
    TABLE OF xxwsh_carriers_sort_tmp.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- ���ד�
  TYPE sum_weight_ttype           IS
    TABLE OF xxwsh_carriers_sort_tmp.sum_weight%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �ύڏd�ʍ��v
  TYPE sum_capacity_ttype         IS
    TABLE OF xxwsh_carriers_sort_tmp.sum_capacity%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �ύڗe�ύ��v
  TYPE weight_capacity_cls_ttype  IS
    TABLE OF xxwsh_carriers_sort_tmp.weight_capacity_class%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �d�ʗe�ϋ敪
  TYPE sum_pallet_weight_ttype    IS
    TABLE OF xxwsh_carriers_sort_tmp.sum_pallet_weight%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- ���v�p���b�g�d��
  TYPE item_class_ttype           IS
    TABLE OF xxwsh_carriers_sort_tmp.prod_class%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- ���i�敪
  TYPE business_type_ttype        IS
    TABLE OF xxwsh_carriers_sort_tmp.order_type_id%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- ����^�C�v
  TYPE reserve_order_ttype        IS
    TABLE OF xxwsh_carriers_sort_tmp.reserve_order%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- ������
  TYPE max_shipping_method_ttype   IS
    TABLE OF xxwsh_carriers_sort_tmp.max_shipping_method_code%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �ő�z���敪
  TYPE head_sales_branch_ttype    IS
    TABLE OF xxwsh_carriers_sort_tmp.head_sales_branch%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �Ǌ����_
  TYPE pre_saved_flag_ttype       IS
    TABLE OF xxwsh_carriers_sort_tmp.pre_saved_flg%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- ���_���ړo�^��
--
  -- �����z�ԏW�񒆊ԃe�[�u���o�^�p
  TYPE intensive_no_ttype     IS
    TABLE OF xxwsh_intensive_carriers_tmp.intensive_no%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �W��No
  TYPE transaction_type_ttype IS
    TABLE OF xxwsh_intensive_carriers_tmp.transaction_type%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �������
  TYPE int_source_no_ttype    IS
    TABLE OF xxwsh_intensive_carriers_tmp.intensive_source_no%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �W��No
  TYPE deliver_from_ttype     IS
    TABLE OF xxwsh_intensive_carriers_tmp.deliver_from%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �z����
  TYPE deliver_from_id_ttype  IS
    TABLE OF xxwsh_intensive_carriers_tmp.deliver_from_id%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �z����ID
  TYPE deliver_to_ttype       IS
    TABLE OF xxwsh_intensive_carriers_tmp.deliver_to%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �z����
  TYPE deliver_to_id_ttype    IS
    TABLE OF xxwsh_intensive_carriers_tmp.deliver_to_id%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �z����ID
  TYPE sche_ship_date_ttype   IS
    TABLE OF xxwsh_intensive_carriers_tmp.schedule_ship_date%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �o�ɗ\���
  TYPE sche_arvl_date_ttype   IS
    TABLE OF xxwsh_intensive_carriers_tmp.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- ���ח\���
  TYPE tran_type_name_ttype   IS
    TABLE OF xxwsh_intensive_carriers_tmp.transaction_type_name%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �o�Ɍ`��
  TYPE freight_carry_cd_ttype IS
    TABLE OF xxwsh_intensive_carriers_tmp.freight_carrier_code%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �^���Ǝ�
  TYPE int_sum_weight_ttype   IS
    TABLE OF xxwsh_intensive_carriers_tmp.intensive_sum_weight%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �W�񍇌v�d��
  TYPE int_sum_capa_ttype     IS
    TABLE OF xxwsh_intensive_carriers_tmp.intensive_sum_capacity%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �W�񍇌v�e��
  TYPE max_ship_cd_ttype      IS
    TABLE OF xxwsh_intensive_carriers_tmp.max_shipping_method_code%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �ő�z���敪
  TYPE weight_capa_cls_ttype  IS
    TABLE OF xxwsh_intensive_carriers_tmp.weight_capacity_class%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �d�ʗe�ϋ敪
  TYPE max_weight_ttype       IS
    TABLE OF xxwsh_intensive_carriers_tmp.max_weight%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �ő�ύڏd��
  TYPE max_capacity_ttype     IS
    TABLE OF xxwsh_intensive_carriers_tmp.max_capacity%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �ő�ύڗe��
  TYPE based_weight_ttype     IS
    TABLE OF xxwsh_intensive_carriers_tmp.based_weight%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- ��{�d��
  TYPE based_capa_ttype       IS
    TABLE OF xxwsh_intensive_carriers_tmp.based_capacity%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- ��{�e��
  TYPE ship_to_id_ttype       IS
    TABLE OF xxwsh_intensive_carriers_tmp.deliver_to_id%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �o�א�ID
  TYPE ship_from_id_ttype     IS
    TABLE OF xxwsh_intensive_carriers_tmp.deliver_from_id%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �o�׌�ID
--
  -- �����z�ԏW�񒆊Ԗ��׃e�[�u���o�^�p
  TYPE request_no_ttype IS
    TABLE OF xxwsh_intensive_carrier_ln_tmp.request_no%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �˗�No
--
  -- �����z�ԍ��ڒ��ԃe�[�u���o�^�p
  TYPE delivery_no_ttype IS
    TABLE OF xxwsh_mixed_carriers_tmp.delivery_no%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �z��No
  TYPE default_line_number_ttype IS
    TABLE OF xxwsh_mixed_carriers_tmp.default_line_number%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �����No
  TYPE fixed_ship_code_ttype IS
    TABLE OF xxwsh_mixed_carriers_tmp.fixed_shipping_method_code%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �C���z���敪
  TYPE mixed_class_ttype IS
    TABLE OF xxwsh_mixed_carriers_tmp.mixed_class%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- ���ڎ��
  TYPE mixed_total_weight_ttype IS
    TABLE OF xxwsh_mixed_carriers_tmp.mixed_total_weight%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- ���ڍ��v�d��
  TYPE mixed_total_capacity_ttype IS
    TABLE OF xxwsh_mixed_carriers_tmp.mixed_total_capacity%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- ���ڍ��v�e��
  TYPE case_quantity_ttype IS
    TABLE OF xxwsh_order_lines_all.case_quantity%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �P�[�X��
--
  -- �z�Ԕz���v��A�h�I���o�^�p
  TYPE delivery_to_cd_cls_ttype IS
    TABLE OF xxwsh_carriers_schedule.deliver_to_code_class%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �z����R�[�h�敪
  TYPE loading_weight_ttype IS
    TABLE OF xxwsh_carriers_schedule.loading_efficiency_weight%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �d�ʐύڌ���
  TYPE loading_capacity_ttype IS
    TABLE OF xxwsh_carriers_schedule.loading_efficiency_capacity%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �e�ϐύڌ���
  TYPE based_capacity_ttype IS
    TABLE OF xxwsh_carriers_schedule.based_capacity%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- ��{�e��
  TYPE freight_charge_type_ttype IS
    TABLE OF xxwsh_carriers_schedule.freight_charge_type%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- �^���`��
-- Ver1.3 M.Hokkanji Start
  TYPE mixed_ratio_ttype is
    TABLE OF xxwsh_order_headers_all.mixed_ratio%TYPE INDEX BY BINARY_INTEGER;
                                                                            -- ���ڗ�
-- Ver1.3 M.Hokkanji End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �p�����[�^
  gv_prod_class         VARCHAR2(1);          -- ���i�敪
  gv_ship_biz_type      VARCHAR2(1);          -- �������
  gd_date_from          DATE;                 -- �o�ɓ�From
  gv_parameters         VARCHAR2(5000);       -- �G���[�o�͗p
--
  -- �o�͗p����
  gn_ship_cnt           NUMBER;               -- �o�׈˗�����
  gn_move_cnt           NUMBER;               -- �ړ��w������
--
  -- �˗�/�w�����擾�pPL/SQL�\
  gt_ship_data_tab    ship_move_ttype;        -- �o�׈˗��p
  gt_move_data_tab    ship_move_ttype;        -- �ړ��w���p
--
  -- �\�[�g�p�e�[�u���o�^�pPL/SQL�\
  -- �o�׈˗��p
  gt_deliver_no_s           deliver_no_ttype;           -- �z��No
  gt_pre_deliver_no_s       pre_deliver_no_ttype;       -- �O��z��No
  gt_req_mov_no_s           req_mov_no_ttype;           -- �˗�No/�ړ�No
  gt_mixed_no_s             mixed_no_ttype;             -- ���ڌ�No
  gt_carrier_code_s         carrier_code_ttype;         -- �^���Ǝ�
  gt_carrier_id_s           carrier_id_ttype;           -- �^���Ǝ�ID
  gt_ship_from_s            ship_from_ttype;            -- �o�׌��ۊǏꏊ
  gt_ship_to_s              ship_to_ttype;              -- �o�א�
  gt_ship_method_code_s     ship_method_code_ttype;     -- �z���敪
  gt_small_div_s            small_div_ttype;            -- �����敪
  gt_ship_date_s            ship_date_ttype;            -- �o�ɓ�
  gt_arrival_date_s         arrival_date_ttype;         -- ���ד�
  gt_sum_weight_s           sum_weight_ttype;           -- �ύڏd�ʍ��v
  gt_sum_capacity_s         sum_capacity_ttype;         -- �ύڗe�ύ��v
  gt_weight_capacity_cls_s  weight_capacity_cls_ttype;  -- �d�ʗe�ϋ敪
  gt_sum_pallet_weight_s    sum_pallet_weight_ttype;    -- ���v�p���b�g�d��
  gt_item_class_s           item_class_ttype;           -- ���i�敪
  gt_business_type_s        business_type_ttype;        -- ����^�C�v
  gt_reserve_order_s        reserve_order_ttype;        -- ������
  gt_max_shipping_method_s   max_shipping_method_ttype; -- �ő�z���敪
  gt_head_sales_branch_s    head_sales_branch_ttype;    -- �Ǌ����_
  gt_ship_from_id_s         ship_from_id_ttype;         -- �o�׌�ID
  gt_ship_to_id_s           ship_to_id_ttype;           -- �o�א�ID
  gt_based_weight_s         based_weight_ttype;         -- ��{�d��
  gt_based_capacity_s       based_capa_ttype;           -- ��{�e��
  gt_pre_saved_flag_s       pre_saved_flag_ttype;       -- ���_���ړo�^�σt���O
--
  -- �ړ��w���p
  gt_deliver_no_m           deliver_no_ttype;           -- �z��No
  gt_pre_deliver_no_m       pre_deliver_no_ttype;       -- �O��z��No
  gt_req_mov_no_m           req_mov_no_ttype;           -- �˗�No/�ړ�No
  gt_mixed_no_m             mixed_no_ttype;             -- ���ڌ�No
  gt_carrier_code_m         carrier_code_ttype;         -- �^���Ǝ�
  gt_carrier_id_m           carrier_id_ttype;           -- �^���Ǝ�ID
  gt_ship_from_m            ship_from_ttype;            -- �o�׌��ۊǏꏊ
  gt_ship_to_m              ship_to_ttype;              -- �o�א�
  gt_ship_method_code_m     ship_method_code_ttype;     -- �z���敪
  gt_small_div_m            small_div_ttype;            -- �����敪
  gt_ship_date_m            ship_date_ttype;            -- �o�ɓ�
  gt_arrival_date_m         arrival_date_ttype;         -- ���ד�
  gt_sum_weight_m           sum_weight_ttype;           -- �ύڏd�ʍ��v
  gt_sum_capacity_m         sum_capacity_ttype;         -- �ύڗe�ύ��v
  gt_weight_capacity_cls_m  weight_capacity_cls_ttype;  -- �d�ʗe�ϋ敪
  gt_sum_pallet_weight_m    sum_pallet_weight_ttype;    -- ���v�p���b�g�d��
  gt_item_class_m           item_class_ttype;           -- ���i�敪
  gt_business_type_m        business_type_ttype;        -- ����^�C�v
  gt_reserve_order_m        reserve_order_ttype;        -- ������
  gt_max_shipping_method_m   max_shipping_method_ttype; -- �ő�z���敪
  gt_head_sales_branch_m    head_sales_branch_ttype;    -- �Ǌ����_
  gt_ship_from_id_m         ship_from_id_ttype;         -- �o�׌�ID
  gt_ship_to_id_m           ship_to_id_ttype;           -- �o�א�ID
  gt_based_weight_m         based_weight_ttype;         -- ��{�d��
  gt_based_capacity_m       based_capa_ttype;           -- ��{�e��
  gt_pre_saved_flag_m       pre_saved_flag_ttype;       -- ���_���ړo�^�σt���O
--
  -- ����O���[�v���Z�����pPL/SQL�\
  gt_grp_sum_add_tab_ship   grp_sum_add_ttype;          -- �o�׈˗��p
  gt_grp_sum_add_tab_move   grp_sum_add_ttype;          -- �ړ��w���p
  gt_pre_saved_flg_tab      pre_saved_flg_ttype;        -- ���_���ړo�^�σt���O
  gt_finish_sum_flag_tab    finish_sum_flag_ttype;      -- �W��σt���O
--
  -- �����z�ԏW�񒆊ԃe�[�u���o�^�pPL/SQL�\
  gt_int_no_tab         intensive_no_ttype;             -- �W��No
  gt_tran_type_tab      transaction_type_ttype;         -- �������
  gt_int_source_tab     int_source_no_ttype;            -- �W��No
  gt_deli_from_tab      deliver_from_ttype;             -- �z����
  gt_deli_from_id_tab   deliver_from_id_ttype;          -- �z����ID
  gt_deli_to_tab        deliver_to_ttype;               -- �z����
  gt_deli_to_id_tab     deliver_to_id_ttype;            -- �z����ID
  gt_ship_date_tab      sche_ship_date_ttype;           -- �o�ɗ\���
  gt_arvl_date_tab      sche_arvl_date_ttype;           -- ���ח\���
  gt_tran_type_nm_tab   tran_type_name_ttype;           -- �o�Ɍ`��
  gt_carrier_code_tab   freight_carry_cd_ttype;         -- �^���Ǝ�
  gt_carrier_id_tab     carrier_id_ttype;               -- �^���Ǝ�ID
  gt_sum_weight_tab     int_sum_weight_ttype;           -- �W�񍇌v�d��
  gt_sum_capa_tab       int_sum_capa_ttype;             -- �W�񍇌v�e��
  gt_max_ship_cd_tab    max_ship_cd_ttype;              -- �ő�z���敪
  gt_weight_capa_tab    weight_capa_cls_ttype;          -- �d�ʗe�ϋ敪
  gt_max_weight_tab     max_weight_ttype;               -- �ő�ύڏd��
  gt_max_capa_tab       max_capacity_ttype;             -- �ő�ύڗe��
  gt_base_weight_tab    based_weight_ttype;             -- ��{�d��
  gt_base_capa_tab      based_capa_ttype;               -- ��{�e��
  gt_reserve_order_tab  reserve_order_ttype;            -- ������
  gt_head_sales_tab     head_sales_branch_ttype;        -- �Ǌ����_
--
  -- �����z�ԏW�񒆊Ԗ��׃e�[�u���o�^�pPL/SQL�\
  gt_int_no_lines_tab intensive_no_ttype;               -- �W��No
  gt_request_no_tab   request_no_ttype;                 -- �˗�No
--
  -- �����z�ԍ��ڒ��ԃe�[�u���o�^�pPL/SQL�\
  gt_intensive_no_tab           intensive_no_ttype;         -- �W��No
  gt_delivery_no_tab            delivery_no_ttype;          -- �z��No
  gt_default_line_number_tab    default_line_number_ttype;  -- �����No
  gt_fixed_ship_code_tab        fixed_ship_code_ttype;      -- �C���z���敪
  gt_mixed_class_tab            mixed_class_ttype;          -- ���ڎ��
  gt_mixed_total_weight_tab     mixed_total_weight_ttype;   -- ���ڍ��v�d��
  gt_mixed_total_capacity_tab   mixed_total_capacity_ttype; -- ���ڍ��v�e��
  gt_mixed_no_tab               mixed_no_ttype;             -- ���ڌ�No
--
  -- �G���[�L�[
  gv_err_key  VARCHAR2(2000);
  -- �f�o�b�O�p
  gb_debug    BOOLEAN DEFAULT FALSE;    --�f�o�b�O���O�o�͗p�X�C�b�`
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
    cv_debug_switch_prof_name CONSTANT VARCHAR2(30) := 'XXWSH_60B_DEBUG_SWITCH';  -- ���ޯ���׸�
    cv_debug_switch_ON        CONSTANT VARCHAR2(1)  := '1';   --�f�o�b�O�o�͂���
    cv_debug_switch_OFF       CONSTANT VARCHAR2(1)  := '0';   --�f�o�b�O�o�͂��Ȃ�
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    --�f�o�b�O�؂�ւ��v���t�@�C���擾
    IF (FND_PROFILE.VALUE(cv_debug_switch_prof_name) = cv_debug_switch_ON ) THEN
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
  /**********************************************************************************
   * Procedure Name   : del_table_purge
   * Description      : �p�[�W����(B-1)
   ***********************************************************************************/
  PROCEDURE del_table_purge(
    ov_errbuf   OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_table_purge'; -- �v���O������
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
    cv_tab_carriers_tmp       CONSTANT VARCHAR2(30) := 'xxwsh_intensive_carriers_tmp';
                                                            -- �����z�ԏW�񒆊ԃe�[�u��
    cv_tab_carrier_ln_tmp     CONSTANT VARCHAR2(30) := 'xxwsh_intensive_carrier_ln_tmp';
                                                            -- �����z�ԏW�񒆊Ԗ��׃e�[�u��
    cv_tab_mixed_carriers_tmp CONSTANT VARCHAR2(30) := 'xxwsh_mixed_carriers_tmp';
                                                            -- �����z�ԍ��ڒ��ԃe�[�u��
    cv_tab_carriers_sort_tmp  CONSTANT VARCHAR2(30) := 'xxwsh_carriers_sort_tmp';
                                                            -- �\�[�g�p���ԃe�[�u��
--
    -- *** ���[�J���ϐ� ***
    lb_retcode    BOOLEAN;    -- ���ʊ֐��߂�l
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
debug_log(FND_FILE.LOG,'�y�p�[�W����(B-1)�z');
    -- ===============================
    -- ���ԃe�[�u��TRANCATE����
    -- ===============================
    lb_retcode := xxcmn_common_pkg.del_all_data(gv_xxwsh, cv_tab_carriers_tmp);
                                                          -- �����z�ԏW�񒆊ԃe�[�u��
    IF (lb_retcode = FALSE) THEN
      RAISE global_api_expt;
    END IF;
--
    lb_retcode := xxcmn_common_pkg.del_all_data(gv_xxwsh, cv_tab_carrier_ln_tmp);
                                                          -- �����z�ԏW�񒆊Ԗ��׃e�[�u��
    IF (lb_retcode = FALSE) THEN
      RAISE global_api_expt;
    END IF;
--
    lb_retcode := xxcmn_common_pkg.del_all_data(gv_xxwsh, cv_tab_mixed_carriers_tmp);
                                                          -- �����z�ԍ��ڒ��ԃe�[�u��
    IF (lb_retcode = FALSE) THEN
      RAISE global_api_expt;
    END IF;
--
    lb_retcode := xxcmn_common_pkg.del_all_data(gv_xxwsh, cv_tab_carriers_sort_tmp);
                                                          -- �\�[�g�p���ԃe�[�u��
    IF (lb_retcode = FALSE) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
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
  END del_table_purge;
--
  /**********************************************************************************
   * Procedure Name   : get_req_inst_info
   * Description      : �˗��E�w����񒊏o(B-3)
   ***********************************************************************************/
  PROCEDURE get_req_inst_info(
      iv_prod_class           IN  VARCHAR2        --  1.���i�敪
    , iv_shipping_biz_type    IN  VARCHAR2        --  2.�������
    , iv_block_1              IN  VARCHAR2        --  3.�u���b�N�P
    , iv_block_2              IN  VARCHAR2        --  4.�u���b�N�Q
    , iv_block_3              IN  VARCHAR2        --  5.�u���b�N�R
    , iv_storage_code         IN  VARCHAR2        --  6.�o�Ɍ�
    , iv_transaction_type_id  IN  NUMBER          --  7.�o�Ɍ`��ID
    , id_date_from            IN  DATE            --  8.�o�ɓ�From
    , id_date_to              IN  DATE            --  9.�o�ɓ�To
    , iv_forwarder            IN  NUMBER          -- 10.�^���Ǝ�ID
    , ov_errbuf               OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode              OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg               OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_req_inst_info'; -- �v���O������
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
    cv_close            CONSTANT VARCHAR2(30) := '03';                -- �X�e�[�^�X�F���ߍς�
    cv_non_notice       CONSTANT VARCHAR2(30) := '10';                -- �ʒm�X�e�[�^�X�F���ʒm
    cv_re_notice        CONSTANT VARCHAR2(30) := '20';                -- �ʒm�X�e�[�^�X�F�Ēʒm�v
    cv_an_object        CONSTANT VARCHAR2(30) := '1';                 -- �����z�ԑΏۋ敪:�Ώ�
    cv_cat_order        CONSTANT VARCHAR2(30) := 'ORDER';             -- �󒍃J�e�S���F��
    cv_ship_shikyu_cls  CONSTANT VARCHAR2(30) := '1';                 -- �o�׎x���敪�F�o�׈˗�
    cv_ship_method      CONSTANT VARCHAR2(30) := 'XXCMN_SHIP_METHOD'; -- �z���敪
    cv_yes              CONSTANT VARCHAR2(30) := 'Y';                 -- YES
    cv_sts_fin_req      CONSTANT VARCHAR2(30) := '02';                -- �X�e�[�^�X�F�˗���
    cv_sts_adjust       CONSTANT VARCHAR2(30) := '03';                -- �X�e�[�^�X�F������
    cv_tab_name         CONSTANT VARCHAR2(30) := '�˗��^�w���f�[�^';  -- �e�[�u����
    cv_move_type_1      CONSTANT VARCHAR2(30) := '1';                 -- �ϑ�����
--
    -- *** ���[�J���ϐ� ***
    TYPE cur_type IS REF CURSOR;
    exec_cur cur_type;
--
    -- �o�׈˗��p
    lv_sql_0          VARCHAR2(5000);     -- SQL������p(�Œ蕔)
    lv_sql_1          VARCHAR2(5000);     -- SQL������p(�ϓ���)
    lv_sql_2          VARCHAR2(5000);     -- SQL������p(�Œ蕔)
    lv_sql_3          VARCHAR2(5000);     -- SQL������p(�ϓ���)
    lv_sql_4          VARCHAR2(5000);     -- SQL������p(�Œ蕔)
    lv_sql_buff_ship  VARCHAR2(10000);    -- ���s�pSQL
    -- �ړ��w���p
    lv_sql_m0         VARCHAR2(5000);     -- SQL������p(�Œ蕔)
    lv_sql_m1         VARCHAR2(5000);     -- SQL������p(�ϓ���)
    lv_sql_m2         VARCHAR2(5000);     -- SQL������p(�Œ蕔)
    lv_sql_m3         VARCHAR2(5000);     -- SQL������p(�ϓ���)
    lv_sql_m4         VARCHAR2(5000);     -- SQL������p(�Œ蕔)
    lv_sql_buff_move  VARCHAR2(10000);    -- ���s�pSQL
    -- �o��/�ړ��p
    lv_sql_ship_move  VARCHAR2(10000);    -- ���s�pSQL
--
    -- �ő�z���敪�擾�p
    return_cd                   NUMBER;   -- �߂�l
    lv_max_ship_methods_s       xxcmn_ship_methods.ship_method%TYPE;            -- �ő�z���敪
    ln_drink_deadweight_s       xxcmn_ship_methods.drink_deadweight%TYPE;       -- �h�����N�ύڏd��
    ln_leaf_deadweight_s        xxcmn_ship_methods.leaf_deadweight%TYPE;        -- ���[�t�ύڏd��
    ln_drink_loading_capacity_s xxcmn_ship_methods.drink_loading_capacity%TYPE; -- �h�����N�ύڗe��
    ln_leaf_loading_capacity_s  xxcmn_ship_methods.leaf_loading_capacity%TYPE;  -- ���[�t�ύڗe��
    ln_palette_max_qty_s        xxcmn_ship_methods.palette_max_qty%TYPE;        -- �p���b�g�ő喇��
    lv_max_ship_methods_m       xxcmn_ship_methods.ship_method%TYPE;            -- �ő�z���敪
    ln_drink_deadweight_m       xxcmn_ship_methods.drink_deadweight%TYPE;       -- �h�����N�ύڏd��
    ln_leaf_deadweight_m        xxcmn_ship_methods.leaf_deadweight%TYPE;        -- ���[�t�ύڏd��
    ln_drink_loading_capacity_m xxcmn_ship_methods.drink_loading_capacity%TYPE; -- �h�����N�ύڗe��
    ln_leaf_loading_capacity_m  xxcmn_ship_methods.leaf_loading_capacity%TYPE;  -- ���[�t�ύڗe��
    ln_palette_max_qty_m        xxcmn_ship_methods.palette_max_qty%TYPE;        -- �p���b�g�ő喇��
--
    -- *** ���[�J���E�J�[�\�� ***
    TYPE cursor_type IS REF CURSOR; -- �J�[�\���ϐ�
--
    get_ship_cur cursor_type;
    get_move_cur cursor_type;
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
debug_log(FND_FILE.LOG,'�y�˗��E�w����񒊏o(B-3)�z');
debug_log(FND_FILE.LOG,'������ʁF'|| iv_shipping_biz_type);
    -- ===============================
    -- �p�����[�^KEY�ݒ�
    -- ===============================
    gv_parameters:= iv_prod_class                                   -- ���i�敪
                    || gv_msg_comma ||
                    iv_shipping_biz_type                            -- �������
                    || gv_msg_comma ||
                    iv_block_1                                      -- �u���b�N�P
                    || gv_msg_comma ||
                    iv_block_2                                      -- �u���b�N�Q
                    || gv_msg_comma ||
                    iv_block_3                                      -- �u���b�N�R
                    || gv_msg_comma ||
                    iv_storage_code                                 -- �o�Ɍ�
                    || gv_msg_comma ||
                    iv_transaction_type_id                          -- �o�Ɍ`��
                    || gv_msg_comma ||
                    TO_CHAR(id_date_from, 'YYYY/MM/DD HH24:MI:SS')  -- �o�ɓ�From
                    || gv_msg_comma ||
                    TO_CHAR(id_date_to, 'YYYY/MM/DD HH24:MI:SS')    -- �o�ɓ�To
                    || gv_msg_comma ||
                    TO_CHAR(iv_forwarder);                          -- �^���Ǝ�
--
    -- ===============================
    -- SQL������쐬(�o�׈˗�)
    -- ===============================
    -- �Œ蕔
    lv_sql_0 := 'SELECT xoha.delivery_no deliver_no';                           -- �z��No
    lv_sql_0 := lv_sql_0 || ', xoha.prev_delivery_no pre_deliver_no';           -- �O��z��No
    lv_sql_0 := lv_sql_0 || ', xoha.request_no req_mov_no';                     -- �˗�No
    lv_sql_0 := lv_sql_0 || ', xoha.mixed_no mixed_no';                         -- ���ڌ�No
    lv_sql_0 := lv_sql_0 || ', xoha.freight_carrier_code carrier_code';         -- �^���Ǝ�
    lv_sql_0 := lv_sql_0 || ', xoha.career_id carrier_id';                      -- �^���Ǝ�ID
    lv_sql_0 := lv_sql_0 || ', xoha.deliver_from ship_from';                    -- �o�׌��ۊǏꏊ
    lv_sql_0 := lv_sql_0 || ', xoha.deliver_from_id ship_from_id';              -- �o�׌�ID
    lv_sql_0 := lv_sql_0 || ', xoha.deliver_to ship_to';                        -- �o�א�
    lv_sql_0 := lv_sql_0 || ', xoha.deliver_to_id ship_to_id';                  -- �o�א�ID
    lv_sql_0 := lv_sql_0 || ', xoha.shipping_method_code ship_method_code';     -- �z���敪
    lv_sql_0 := lv_sql_0 || ', xlv.attribute6 small_div';                       -- �����敪
    lv_sql_0 := lv_sql_0 || ', xoha.schedule_ship_date ship_date';              -- �o�ɓ�
    lv_sql_0 := lv_sql_0 || ', xoha.schedule_arrival_date arrival_date';        -- ���ד�
    lv_sql_0 := lv_sql_0 || ', xoha.based_weight based_weight';                 -- ��{�d��
    lv_sql_0 := lv_sql_0 || ', xoha.based_capacity based_capacity';             -- ��{�e��
    lv_sql_0 := lv_sql_0 || ', xoha.sum_weight sum_weight';                     -- �ύڏd�ʍ��v
    lv_sql_0 := lv_sql_0 || ', xoha.sum_capacity sum_capacity';                 -- �ύڗe�ύ��v
    lv_sql_0 := lv_sql_0 || ', xoha.weight_capacity_class weight_capacity_cls'; -- �d�ʗe�ϋ敪
    lv_sql_0 := lv_sql_0 || ', xoha.sum_pallet_weight sum_pallet_weight';       -- ���v�p���b�g�d��
    lv_sql_0 := lv_sql_0 || ', xoha.prod_class  item_class';                    -- ���i�敪
    lv_sql_0 := lv_sql_0 || ', xotv.transaction_type_id business_type_id';      -- ����^�C�v
    lv_sql_0 := lv_sql_0 || ', xcav.reserve_order reserve_order';               -- ������
    lv_sql_0 := lv_sql_0 || ', xoha.head_sales_branch sales_branch';            -- �Ǌ����_
    lv_sql_0 := lv_sql_0 || ' FROM xxwsh_order_headers_all xoha';   -- �󒍃w�b�_�A�h�I��
    lv_sql_0 := lv_sql_0 || ', xxwsh_carriers_schedule xcs';        -- �z�Ԕz���v��A�h�I��
    lv_sql_0 := lv_sql_0 || ', xxcmn_item_locations2_v xilv';       -- OPM�ۊǏꏊ���VIEW2
    lv_sql_0 := lv_sql_0 || ', xxcmn_cust_acct_sites2_v xcasv';     -- �ڋq�T�C�g���VIEW2
    lv_sql_0 := lv_sql_0 || ', xxcmn_cust_accounts2_v xcav';        -- �ڋq���VIEW2
    lv_sql_0 := lv_sql_0 || ', xxwsh_oe_transaction_types2_v xotv'; -- �󒍃^�C�v���VIEW2
    lv_sql_0 := lv_sql_0 || ', xxcmn_lookup_values2_v xlv';         -- �N�C�b�N�R�[�h���VIEW2
    lv_sql_0 := lv_sql_0 || ' WHERE xoha.order_type_id = xotv.transaction_type_id';
                                                                                -- �󒍃^�C�vID
    lv_sql_0 := lv_sql_0 || ' AND xoha.req_status = '''|| cv_close ||'''';      -- �X�e�[�^�X
    lv_sql_0 := lv_sql_0 || ' AND xoha.notif_status IN ('''|| cv_non_notice||''',
                                    '''|| cv_re_notice ||''')';                 -- �ʒm�X�e�[�^�X
    lv_sql_0 := lv_sql_0 || ' AND xoha.delivery_no = xcs.delivery_no(+)';       -- �z��NO
--    lv_sql_0 := lv_sql_0 || ' AND (xoha.delivery_no IS NULL';                   -- �z��NO
--    lv_sql_0 := lv_sql_0 || '  OR xoha.delivery_no = xcs.delivery_no)';            -- �z��NO
    lv_sql_0 := lv_sql_0 || ' AND (xcs.auto_process_type IS NULL';
    lv_sql_0 := lv_sql_0 || '  OR xcs.auto_process_type = '''|| cv_an_object ||''')';
                                                                                -- �����z�ԑΏۋ敪
    lv_sql_0 := lv_sql_0 || ' AND xoha.freight_charge_class = '''|| cv_an_object ||'''';
                                                                                -- �^���敪
    lv_sql_0 := lv_sql_0 || ' AND xoha.prod_class = '''|| iv_prod_class ||'''';
                                                                                -- ���i�敪
    lv_sql_0 := lv_sql_0 || ' AND xoha.deliver_from_id = xilv.inventory_location_id';
                                                                                -- �o�׌�ID
    lv_sql_0 := lv_sql_0 || ' AND xilv.disable_date IS NULL';                   -- ������
--
    -- �ϓ���(�����u���b�N)
      lv_sql_1 := ' AND ((xilv.distribution_block IN (                           -- �����u���b�N
                          '''|| iv_block_1 ||''',                                 -- �u���b�N�P
                          '''|| iv_block_2 ||''',                                 -- �u���b�N�Q
                          '''|| iv_block_3 ||''')';                               -- �u���b�N�R
      lv_sql_1 := lv_sql_1 || ' OR xoha.deliver_from = '''|| iv_storage_code ||''')'; -- �o�Ɍ�
      lv_sql_1 := lv_sql_1 || ' OR  (('''|| iv_block_1 ||''' IS NULL) AND ('''|| iv_block_2 ||''' IS NULL) AND ('''|| iv_block_3 ||''' IS NULL) AND ('''|| iv_storage_code ||''' IS NULL)))';
--
    -- �ϓ���(�o�Ɍ`��)
    IF (iv_transaction_type_id IS NOT NULL) THEN
      lv_sql_1 := lv_sql_1 ||' AND xotv.transaction_type_id = '|| iv_transaction_type_id ||' ';
    END IF;
--
    -- �Œ蕔(�o�ח\���)
    lv_sql_2 := ' AND xoha.schedule_ship_date >= TO_DATE(
                      '''|| TO_CHAR(id_date_from, 'YYYY/MM/DD') ||''',''YYYY/MM/DD'')';    -- �o�ɓ�From
    lv_sql_2 := lv_sql_2 || ' AND xoha.schedule_ship_date <= TO_DATE(
                      '''|| TO_CHAR(id_date_to, 'YYYY/MM/DD') ||''',''YYYY/MM/DD'')';      -- �o�ɓ�To
--
    -- �ϓ���(�^���Ǝ�ID)
    IF (iv_forwarder IS NOT NULL) THEN
      lv_sql_3 := ' AND xoha.career_id = '|| iv_forwarder ||'';
    END IF;
--
    -- �Œ蕔
    lv_sql_4 := ' AND xotv.order_category_code = '''|| cv_cat_order ||'''';     -- �󒍃J�e�S��
    lv_sql_4 := lv_sql_4 || ' AND xotv.shipping_shikyu_class =
                                      '''|| cv_ship_shikyu_cls ||'''';          -- �o�׎x���敪
    lv_sql_4 := lv_sql_4 || ' AND xotv.start_date_active <= TO_DATE(
                              '''|| TO_CHAR(id_date_from,'YYYY/MM/DD')  ||''',''YYYY/MM/DD'')';
                                                                -- �󒍃^�C�v���VIEW2�F�K�p�J�n��
    lv_sql_4 := lv_sql_4 || ' AND (xotv.end_date_active IS NULL';
    lv_sql_4 := lv_sql_4 || ' OR xotv.end_date_active >= TO_DATE(
                              '''|| TO_CHAR(id_date_from, 'YYYY/MM/DD') ||''',''YYYY/MM/DD''))';
                                                                -- �󒍃^�C�v���VIEW2�F�K�p�I����
    lv_sql_4 := lv_sql_4 || ' AND xoha.shipping_method_code = xlv.lookup_code'; -- �z���敪
    lv_sql_4 := lv_sql_4 || ' AND xlv.lookup_type = '''|| cv_ship_method ||'''';
    lv_sql_4 := lv_sql_4 || ' AND (xlv.start_date_active IS NULL';
    lv_sql_4 := lv_sql_4 || ' OR xlv.start_date_active <= TO_DATE(
                              '''|| TO_CHAR(id_date_from,'YYYY/MM/DD')  ||''',''YYYY/MM/DD''))';
                                                                -- �N�C�b�N�R�[�h�F�K�p�J�n��
    lv_sql_4 := lv_sql_4 || ' AND (xlv.end_date_active IS NULL';
    lv_sql_4 := lv_sql_4 || ' OR xlv.end_date_active >= TO_DATE(
                              '''|| TO_CHAR(id_date_from, 'YYYY/MM/DD') ||''',''YYYY/MM/DD''))';
                                                                -- �N�C�b�N�R�[�h�F�K�p�I����
    lv_sql_4 := lv_sql_4 || ' AND xlv.enabled_flag = '''|| cv_yes ||'''';
                                                                -- �N�C�b�N�R�[�h�F�L���t���O
    lv_sql_4 := lv_sql_4 || ' AND xoha.head_sales_branch = xcav.party_number';   -- �Ǌ����_
    lv_sql_4 := lv_sql_4 || ' AND xcasv.start_date_active <= TO_DATE(
                              '''|| TO_CHAR(id_date_from, 'YYYY/MM/DD') ||''',''YYYY/MM/DD'')';
                                                                -- �ڋq�T�C�g���VIEW2�F�K�p�J�n��
    lv_sql_4 := lv_sql_4 || ' AND xcasv.end_date_active >= TO_DATE(
                              '''|| TO_CHAR(id_date_from, 'YYYY/MM/DD') ||''',''YYYY/MM/DD'')';
                                                                -- �ڋq�T�C�g���VIEW2�F�K�p�I����
    lv_sql_4 := lv_sql_4 || ' AND xcasv.party_site_id = xoha.deliver_to_id';      -- �o�א�ID
    lv_sql_4 := lv_sql_4 || ' AND xcav.party_id = xcav.party_id';                  -- �p�[�e�BID
    lv_sql_4 := lv_sql_4 || ' AND xcav.start_date_active <= TO_DATE(
                              '''|| TO_CHAR(id_date_from, 'YYYY/MM/DD') ||''',''YYYY/MM/DD'')';
                                                                -- �ڋq���VIEW2�F�K�p�J�n��
    lv_sql_4 := lv_sql_4 || ' AND xcav.end_date_active >= TO_DATE(
                              '''|| TO_CHAR(id_date_from, 'YYYY/MM/DD') ||''',''YYYY/MM/DD'')';
                                                                -- �ڋq���VIEW2�F�K�p�I����
    lv_sql_4 := lv_sql_4 || ' AND xoha.latest_external_flag = '''|| cv_yes ||'''';
                                                                                -- �ŐV�t���O
-- Ver1.14 MIYATA Start
    lv_sql_4 := lv_sql_4 || ' FOR UPDATE OF xoha.delivery_no ';
-- Ver1.14 MIYATA End
--
    -- SQL���A��(�o�׈˗�)
    lv_sql_buff_ship := lv_sql_0 || lv_sql_1 || lv_sql_2 || lv_sql_3 || lv_sql_4;
--
debug_log(FND_FILE.LOG,'�o�׈˗�SQL: '||lv_sql_buff_ship);
--
    -- ===============================
    -- SQL������쐬(�ړ��w��)
    -- ===============================
    -- �Œ蕔
    lv_sql_m0 := 'SELECT  xmrh.delivery_no deliver_no';                           -- �z��No
    lv_sql_m0 := lv_sql_m0 || ', xmrh.prev_delivery_no pre_deliver_no';           -- �O��z��No
    lv_sql_m0 := lv_sql_m0 || ', xmrh.mov_num req_mov_no';                        -- �ړ��ԍ�
    lv_sql_m0 := lv_sql_m0 || ', NULL mixed_no';                                  -- ���ڌ�No
    lv_sql_m0 := lv_sql_m0 || ', xmrh.freight_carrier_code carrier_code';         -- �^���Ǝ�
    lv_sql_m0 := lv_sql_m0 || ', xmrh.career_id carrier_id';                      -- �^���Ǝ�ID
    lv_sql_m0 := lv_sql_m0 || ', xmrh.shipped_locat_code ship_from';              -- �o�׌��ۊǏꏊ
    lv_sql_m0 := lv_sql_m0 || ', xmrh.shipped_locat_id ship_from_id';             -- �o�׌�ID
    lv_sql_m0 := lv_sql_m0 || ', xmrh.ship_to_locat_code ship_to';                -- �o�א�
    lv_sql_m0 := lv_sql_m0 || ', xmrh.ship_to_locat_id ship_to_id';               -- �o�א�ID
    lv_sql_m0 := lv_sql_m0 || ', xmrh.shipping_method_code ship_method_code';     -- �z���敪
    lv_sql_m0 := lv_sql_m0 || ', xlv.attribute6 small_div';                       -- �����敪
    lv_sql_m0 := lv_sql_m0 || ', xmrh.schedule_ship_date ship_date';              -- �o�ɓ�
    lv_sql_m0 := lv_sql_m0 || ', xmrh.schedule_arrival_date arrival_date';        -- ���ד�
    lv_sql_m0 := lv_sql_m0 || ', xmrh.based_weight based_weight';                 -- ��{�d��
    lv_sql_m0 := lv_sql_m0 || ', xmrh.based_capacity based_capacity';             -- ��{�e��
    lv_sql_m0 := lv_sql_m0 || ', xmrh.sum_weight sum_weight';                     -- �ύڏd�ʍ��v
    lv_sql_m0 := lv_sql_m0 || ', xmrh.sum_capacity sum_capacity';                 -- �ύڗe�ύ��v
    lv_sql_m0 := lv_sql_m0 || ', xmrh.weight_capacity_class weight_capacity_cls'; -- �d�ʗe�ϋ敪
    lv_sql_m0 := lv_sql_m0 || ', xmrh.sum_pallet_weight sum_pallet_weight';       -- ���v�p���b�g�d��
    lv_sql_m0 := lv_sql_m0 || ', xmrh.item_class  item_class';                    -- ���i�敪
    lv_sql_m0 := lv_sql_m0 || ', xmrh.mov_type business_type_id';                 -- ����^�C�v
    lv_sql_m0 := lv_sql_m0 || ', NULL reserve_order';                             -- ������
    lv_sql_m0 := lv_sql_m0 || ', NULL sales_branch';                              -- �Ǌ����_
    lv_sql_m0 := lv_sql_m0 || ' FROM xxinv_mov_req_instr_headers xmrh';   -- �ړ��˗�/�w���w�b�_
    lv_sql_m0 := lv_sql_m0 || ', xxwsh_carriers_schedule xcs';            -- �z�Ԕz���v��A�h�I��
    lv_sql_m0 := lv_sql_m0 || ', xxcmn_item_locations2_v xilv';           -- OPM�ۊǏꏊ���VIEW2
    lv_sql_m0 := lv_sql_m0 || ', xxcmn_lookup_values2_v xlv';             -- �N�C�b�N�R�[�h���VIEW2
    lv_sql_m0 := lv_sql_m0 || ' WHERE xmrh.status IN ('''|| cv_sts_fin_req ||''',';
    lv_sql_m0 := lv_sql_m0 || ' '''|| cv_sts_adjust||''')';                     -- �X�e�[�^�X
    lv_sql_m0 := lv_sql_m0 || ' AND xmrh.notif_status IN ('''|| cv_non_notice||''',';
    lv_sql_m0 := lv_sql_m0 || ' '''|| cv_re_notice ||''')';                     -- �ʒm�X�e�[�^�X
    lv_sql_m0 := lv_sql_m0 || ' AND xmrh.mov_type = '''|| cv_move_type_1 ||'''';  -- �ړ��^�C�v
    lv_sql_m0 := lv_sql_m0 || ' AND xmrh.delivery_no = xcs.delivery_no(+)';     -- �z��NO
--    lv_sql_m0 := lv_sql_m0 || ' AND (xmrh.delivery_no = NULL';     -- �z��NO
--    lv_sql_m0 := lv_sql_m0 || '  OR xmrh.delivery_no = xcs.delivery_no)';     -- �z��NO
    lv_sql_m0 := lv_sql_m0 || ' AND (xcs.auto_process_type IS NULL';
    lv_sql_m0 := lv_sql_m0 || '  OR xcs.auto_process_type = '''|| cv_an_object ||''')';
                                                                                -- �����z�ԑΏۋ敪
    lv_sql_m0 := lv_sql_m0 || ' AND xmrh.freight_charge_class = '''|| cv_an_object ||'''';
                                                                                -- �^���敪
    lv_sql_m0 := lv_sql_m0 || ' AND xmrh.item_class = '''|| iv_prod_class ||'''';
                                                                                -- ���i�敪
    lv_sql_m0 := lv_sql_m0 || ' AND xmrh.shipped_locat_id = xilv.inventory_location_id';
                                                                                -- �o�׌�ID
    lv_sql_m0 := lv_sql_m0 || ' AND xilv.disable_date IS NULL';                 -- ������
--
    -- �ϓ���(�����u���b�N)
    lv_sql_m1 := ' AND ((xilv.distribution_block IN (
                        '''|| iv_block_1 ||''',                                       -- �u���b�N�P
                        '''|| iv_block_2 ||''',                                       -- �u���b�N�Q
                        '''|| iv_block_3 ||''')';                                     -- �u���b�N�R
    lv_sql_m1 := lv_sql_m1 || ' OR xmrh.shipped_locat_code = '''|| iv_storage_code ||''')';
    lv_sql_m1 := lv_sql_m1 || ' OR (('''|| iv_block_1 ||''' IS NULL) AND ('''|| iv_block_2 ||''' IS NULL) AND ('''|| iv_block_3 ||''' IS NULL) AND ('''|| iv_storage_code ||''' IS NULL)))';
--
    -- �Œ蕔(�o�ɗ\���)
    lv_sql_m2 := ' AND xmrh.schedule_ship_date >= TO_DATE(
                      '''|| TO_CHAR(id_date_from, 'YYYY/MM/DD') ||''',''YYYY/MM/DD'')';    -- �o�ɓ�From
    lv_sql_m2 := lv_sql_m2 || ' AND xmrh.schedule_ship_date <= TO_DATE(
                      '''|| TO_CHAR(id_date_to, 'YYYY/MM/DD') ||''',''YYYY/MM/DD'')';      -- �o�ɓ�To
--
    -- �ϓ���(�^���Ǝ�ID)
    IF (iv_forwarder IS NOT NULL) THEN
      lv_sql_m3 := ' AND xmrh.career_id = '|| iv_forwarder ||'';
    END IF;
--
    -- �Œ蕔
    lv_sql_m4 := ' AND xmrh.shipping_method_code = xlv.lookup_code';          -- �z���敪
    lv_sql_m4 := lv_sql_m4 || ' AND xlv.lookup_type = '''|| cv_ship_method ||'''';  --
    lv_sql_m4 := lv_sql_m4 || ' AND (xlv.start_date_active IS NULL';
    lv_sql_m4 := lv_sql_m4 || ' OR xlv.start_date_active <= TO_DATE(
                              '''|| TO_CHAR(id_date_from, 'YYYY/MM/DD') ||''',''YYYY/MM/DD''))';
                                                                -- �N�C�b�N�R�[�h�F�K�p�J�n��
    lv_sql_m4 := lv_sql_m4 || ' AND (xlv.end_date_active IS NULL';
    lv_sql_m4 := lv_sql_m4 || ' OR xlv.end_date_active >= TO_DATE(
                              '''|| TO_CHAR(id_date_from, 'YYYY/MM/DD') ||''',''YYYY/MM/DD''))';
                                                                -- �N�C�b�N�R�[�h�F�K�p�I����
    lv_sql_m4 := lv_sql_m4 || ' AND xlv.enabled_flag = '''|| cv_yes ||'''';
                                                                -- �N�C�b�N�R�[�h�F�L���t���O
-- Ver1.14 MIYATA Start
    lv_sql_m4 := lv_sql_m4 || ' FOR UPDATE OF xmrh.delivery_no ';
-- Ver1.14 MIYATA End
--
    -- SQL���A��(�ړ��w��)
    lv_sql_buff_move := lv_sql_m0 || lv_sql_m1 || lv_sql_m2 || lv_sql_m3 || lv_sql_m4;
--
debug_log(FND_FILE.LOG,'�ړ��w��SQL�F'||lv_sql_buff_move);
--
    -- ===============================
    -- �o�׈˗�/�ړ��w���f�[�^���o
    -- ===============================
    IF (iv_shipping_biz_type = gv_ship_type_ship) THEN    -- �o�׈˗�
--
      -- �J�[�\���I�[�v��
      OPEN get_ship_cur FOR lv_sql_buff_ship;
--
      -- �ꊇ�擾
      FETCH get_ship_cur BULK COLLECT INTO gt_ship_data_tab;
--
--debug_log(FND_FILE.LOG,'�o�׈˗��ꊇ�擾�F������'||gt_ship_data_tab.count);
--
      -- �J�[�\���N���[�Y
      CLOSE get_ship_cur;
--
    ELSIF (iv_shipping_biz_type = gv_ship_type_move) THEN  -- �ړ��w��
--
      -- �J�[�\���I�[�v��
      OPEN get_move_cur FOR lv_sql_buff_move;
--
      -- �ꊇ�擾
      FETCH get_move_cur BULK COLLECT INTO gt_move_data_tab;
--
--debug_log(FND_FILE.LOG,'�ړ��w���ꊇ�擾�F������'||gt_move_data_tab.count);
      -- �J�[�\���N���[�Y
      CLOSE get_move_cur;
--
    ELSIF (iv_shipping_biz_type IS NULL) THEN             -- �w��Ȃ�
      -- �o�׈˗��J�[�\���I�[�v��
      OPEN get_ship_cur FOR lv_sql_buff_ship;
--
      -- �ꊇ�擾
      FETCH get_ship_cur BULK COLLECT INTO gt_ship_data_tab;
--
      -- �J�[�\���N���[�Y
      CLOSE get_ship_cur;
--
      -- �ړ��w���J�[�\���I�[�v��
      OPEN get_move_cur FOR lv_sql_buff_move;
--
      -- �ꊇ�擾
      FETCH get_move_cur BULK COLLECT INTO gt_move_data_tab;
--
      -- �J�[�\���N���[�Y
      CLOSE get_move_cur;
--
    END IF;
--
    -- ===============================
    -- �f�[�^���o�m�F
    -- ===============================
    IF (iv_shipping_biz_type = gv_ship_type_ship) THEN  -- �o�׈˗�
--
debug_log(FND_FILE.LOG,'B-3 �o�׈˗������F'||gt_ship_data_tab.COUNT);
--
      IF (gt_ship_data_tab.COUNT = 0) THEN
--
debug_log(FND_FILE.LOG,'B-3 �o�׈˗�0������');
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                      gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                     ,gv_msg_xxwsh_11804  -- �Ώۃf�[�^�Ȃ�
                     ,gv_tkn_table        -- �g�[�N��'TABLE'
                     ,cv_tab_name         -- �e�[�u�����F�˗��^�w���f�[�^
                     ,gv_tkn_key          -- �g�[�N��'KEY'
                     ,gv_parameters       -- �G���[�f�[�^
                     ) ,1 ,5000);
       lv_errbuf := lv_errmsg;
--
        RAISE no_data;
--
      END IF;
--
      -- �o�׈˗�����
      gn_ship_cnt := gt_ship_data_tab.COUNT;
--
    ELSIF (iv_shipping_biz_type = gv_ship_type_move) THEN  -- �ړ��w��
--
debug_log(FND_FILE.LOG,'B-3 �ړ��w�������F'||gt_move_data_tab.COUNT);
--
      IF (gt_move_data_tab.COUNT = 0) THEN
debug_log(FND_FILE.LOG,'B-3 �ړ��w��0������');
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                      gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                     ,gv_msg_xxwsh_11804  -- �Ώۃf�[�^�Ȃ�
                     ,gv_tkn_table        -- �g�[�N��'TABLE'
                     ,cv_tab_name         -- �e�[�u�����F�˗��^�w���f�[�^
                     ,gv_tkn_key          -- �g�[�N��'KEY'
                     ,gv_parameters       -- �G���[�f�[�^
                     ) ,1 ,5000);
        lv_errbuf := lv_errmsg;
--
        RAISE no_data;
--
      END IF;
--
      -- �ړ��w������
      gn_move_cnt := gt_move_data_tab.COUNT;
--
    ELSIF (iv_shipping_biz_type IS NULL) THEN  -- ������ʎw��Ȃ�
--
debug_log(FND_FILE.LOG,'B-3 �o�׈˗������F'||gt_ship_data_tab.COUNT);
debug_log(FND_FILE.LOG,'B-3 �ړ��w�������F'||gt_move_data_tab.COUNT);
--
      IF ((gt_ship_data_tab.COUNT = 0)
          AND
          (gt_move_data_tab.COUNT = 0)) THEN
--
debug_log(FND_FILE.LOG,'B-3 �o�׈˗��E�ړ��w��0�������i������ʎw��Ȃ�)');
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                      gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                     ,gv_msg_xxwsh_11804  -- �Ώۃf�[�^�Ȃ�
                     ,gv_tkn_table        -- �g�[�N��'TABLE'
                     ,cv_tab_name         -- �e�[�u�����F�˗��^�w���f�[�^
                     ,gv_tkn_key          -- �g�[�N��'KEY'
                     ,gv_parameters       -- �G���[�f�[�^
                     ) ,1 ,5000);
        lv_errbuf := lv_errmsg;
--
        RAISE no_data;
--
      END IF;
--
      -- �o�͌���
      gn_ship_cnt := gt_ship_data_tab.COUNT;  -- �o�׈˗�����
      gn_move_cnt := gt_move_data_tab.COUNT;  -- �ړ��w������
--
    END IF;
--
    -- ===============================
    -- �ő�z���敪�擾/PLSQL�\�Z�b�g
    -- ===============================
    -- �o�׈˗��f�[�^
    IF (gt_ship_data_tab.COUNT > 0) THEN
--
debug_log(FND_FILE.LOG,'B3_1.0 �ő�z���敪�擾:�o�׈˗�');
      <<get_max_ship_method_1>>
      FOR ln_cnt_1 IN 1..gt_ship_data_tab.COUNT LOOP
--
        -- ���ʊ֐��F�ő�z���敪�Z�o�֐�
        return_cd := xxwsh_common_pkg.get_max_ship_method(
                    iv_code_class1
                          => gv_cdkbn_storage,                      -- �R�[�h�敪1
                    iv_entering_despatching_code1
                          => gt_ship_data_tab(ln_cnt_1).ship_from,  -- ���o�ɏꏊ1
                    iv_code_class2
                          => gv_cdkbn_ship_to,                      -- �R�[�h�敪2
                    iv_entering_despatching_code2
                          => gt_ship_data_tab(ln_cnt_1).ship_to,    -- ���o�ɏꏊ2
                    iv_prod_class
                          => iv_prod_class,                         -- ���i�敪
                    iv_weight_capacity_class
                          => gt_ship_data_tab(ln_cnt_1).weight_capacity_cls,
                                                                    -- �d�ʗe�ϋ敪
                    iv_auto_process_type
                          => cv_an_object,                          -- �����z�ԑΏۋ敪
                    id_standard_date
                          => gt_ship_data_tab(ln_cnt_1).ship_date,  -- ���
                    ov_max_ship_methods
                          => lv_max_ship_methods_s,                 -- �ő�z���敪
                    on_drink_deadweight
                          => ln_drink_deadweight_s,                 -- �h�����N�ύڏd��
                    on_leaf_deadweight
                          => ln_leaf_deadweight_s,                  -- ���[�t�ύڏd��
                    on_drink_loading_capacity
                          => ln_drink_loading_capacity_s,           -- �h�����N�ύڗe��
                    on_leaf_loading_capacity
                          => ln_leaf_loading_capacity_s,            -- ���[�t�ύڗe��
                    on_palette_max_qty
                          => ln_palette_max_qty_s                   -- �p���b�g�ő喇��
                    );
--
debug_log(FND_FILE.LOG,'B3_1.1 �o�׈˗�No:'|| gt_ship_data_tab(ln_cnt_1).req_mov_no);
debug_log(FND_FILE.LOG,' �R�[�h�敪1:' || gv_cdkbn_storage);
debug_log(FND_FILE.LOG,' ���o�ɏꏊ1:' || gt_ship_data_tab(ln_cnt_1).ship_from);
debug_log(FND_FILE.LOG,' �R�[�h�敪2:' || gv_cdkbn_ship_to);
debug_log(FND_FILE.LOG,' ���o�ɏꏊ2:' || gt_ship_data_tab(ln_cnt_1).ship_to);
debug_log(FND_FILE.LOG,' ���i�敪   :' || iv_prod_class);
debug_log(FND_FILE.LOG,' �d�ʗe�ϋ敪:'|| gt_ship_data_tab(ln_cnt_1).weight_capacity_cls);
debug_log(FND_FILE.LOG,' �����z�ԑΏۋ敪:'|| cv_an_object);
debug_log(FND_FILE.LOG,' ���:' || TO_CHAR(gt_ship_data_tab(ln_cnt_1).ship_date,'YYYYMMDD'));
debug_log(FND_FILE.LOG,' �ő�z���敪:'    || lv_max_ship_methods_s);
debug_log(FND_FILE.LOG,' �h�����N�ύڏd��:'|| ln_drink_deadweight_s);
debug_log(FND_FILE.LOG,' ���[�t�ύڏd��:'  || ln_leaf_deadweight_s);
debug_log(FND_FILE.LOG,' �h�����N�ύڗe��:'|| ln_drink_loading_capacity_s);
debug_log(FND_FILE.LOG,' ���[�t�ύڗe��:'  || ln_leaf_loading_capacity_s);
debug_log(FND_FILE.LOG,' �p���b�g�ő喇��:'|| ln_palette_max_qty_s);
--
        IF  (return_cd = gv_error)
          OR (lv_max_ship_methods_s IS NULL)
        THEN
--
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                        gv_xxwsh                      -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                       ,gv_msg_xxwsh_11802            -- �ő�z���敪�擾�G���[
                       ,gv_tkn_from                   -- �g�[�N��'FROM'
                       ,gt_ship_data_tab(ln_cnt_1).ship_from
                                                      -- ���o�ɏꏊ1
                       ,gv_tkn_to                     -- �g�[�N��'TO'
                       ,gt_ship_data_tab(ln_cnt_1).ship_to
                                                      -- ���o�ɏꏊ2
                       ,gv_tkn_codekbn1               -- �g�[�N��'CODEKBN1'
                       ,gv_cdkbn_storage              -- �R�[�h�敪1
                       ,gv_tkn_codekbn2               -- �g�[�N��'CODEKBN2'
                       ,gv_cdkbn_ship_to              -- �R�[�h�敪2
                      ) ,1 ,5000);
--
          RAISE global_api_expt;
--
        END IF;
--
--debug_log(FND_FILE.LOG,'�\�[�g�e�[�u���o�^�pPL/SQL�ɃZ�b�g');
--
        -- ==================================
        -- �\�[�g�e�[�u���o�^�pPL/SQL�ɃZ�b�g
        -- ==================================
        gt_deliver_no_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).deliver_no;             -- �z��No
        gt_pre_deliver_no_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).pre_deliver_no;         -- �O��z��No
        gt_req_mov_no_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).req_mov_no;             -- �˗�No/�ړ�No
        gt_mixed_no_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).mixed_no;               -- ���ڌ�No
        gt_carrier_code_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).carrier_code;           -- �^���Ǝ�
        gt_carrier_id_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).carrier_id;             -- �^���Ǝ�ID
        gt_ship_from_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).ship_from;              -- �o�׌��ۊǏꏊ
        gt_ship_from_id_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).ship_from_id;           -- �o�׌�ID
        gt_ship_to_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).ship_to;                -- �o�א�
        gt_ship_to_id_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).ship_to_id;             -- �o�א�ID
        gt_ship_method_code_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).ship_method_code;       -- �z���敪
        gt_small_div_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).small_div;              -- �����敪
        gt_ship_date_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).ship_date;              -- �o�ɓ�
        gt_arrival_date_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).arrival_date;           -- ���ד�
--20080517:DSugahara�C���s�No1 ��{�d�ʁA��{�e�ς̐ݒ�->
--        gt_based_weight_s(ln_cnt_1)
--            := gt_ship_data_tab(ln_cnt_1).based_weight;           -- ��{�d��
--        gt_based_capacity_s(ln_cnt_1)
--            := gt_ship_data_tab(ln_cnt_1).based_capacity;         -- ��{�e��
        -- ��{�d��
        IF (gt_ship_data_tab(ln_cnt_1).item_class = gv_prod_cls_leaf) THEN
          gt_based_weight_s(ln_cnt_1) := ln_leaf_deadweight_s;    -- ���[�t�ύڏd��
        ELSE
          gt_based_weight_s(ln_cnt_1) := ln_drink_deadweight_s;   -- �h�����N�ύڏd��
        END IF;
        -- ��{�e��
        IF (gt_ship_data_tab(ln_cnt_1).item_class = gv_prod_cls_leaf) THEN
          gt_based_capacity_s(ln_cnt_1) := ln_leaf_loading_capacity_s;  -- ���[�t�ύڗe��
        ELSE
          gt_based_capacity_s(ln_cnt_1) := ln_drink_loading_capacity_s; -- �h�����N�ύڗe��
        END IF;
--20080517:DSugahara�C���s�No1 ��{�d�ʁA��{�e�ς̐ݒ�<-
        gt_sum_weight_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).sum_weight;             -- �ύڏd�ʍ��v
        gt_sum_capacity_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).sum_capacity;           -- �ύڗe�ύ��v
        gt_weight_capacity_cls_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).weight_capacity_cls;    -- �d�ʗe�ϋ敪
        gt_sum_pallet_weight_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).sum_pallet_weight;      -- ���v�p���b�g�d��
        gt_item_class_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).item_class;             -- ���i�敪
        gt_business_type_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).business_type_id;     -- ����^�C�v
        gt_reserve_order_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).reserve_order;          -- ������
        gt_max_shipping_method_s(ln_cnt_1)
            := lv_max_ship_methods_s;                             -- �ő�z���敪
        gt_head_sales_branch_s(ln_cnt_1)
            := gt_ship_data_tab(ln_cnt_1).sales_branch;           -- �Ǌ����_
        gt_pre_saved_flag_s(ln_cnt_1)     := 0;                   -- ���_���ړo�^�σt���O
--
--
--debug_log(FND_FILE.LOG,'�˗�No:'|| gt_req_mov_no_s(ln_cnt_1));
--debug_log(FND_FILE.LOG,'��{�d��:'|| gt_based_weight_s(ln_cnt_1));
--debug_log(FND_FILE.LOG,'��{�e��:'|| gt_based_capacity_s(ln_cnt_1));
--
      END LOOP get_max_ship_method_1;
--
    END IF;
--
    -- �ړ��w���f�[�^
    IF (gt_move_data_tab.COUNT > 0) THEN
--
debug_log(FND_FILE.LOG,'B3_1.2 �ő�z���敪�擾:�ړ��w��');
--
      <<get_max_ship_method_2>>
      FOR ln_cnt_2 IN 1..gt_move_data_tab.COUNT LOOP
--
debug_log(FND_FILE.LOG,'B3_1.2 �ړ��w��No:'|| gt_move_data_tab(ln_cnt_2).req_mov_no);
debug_log(FND_FILE.LOG,' �R�[�h�敪1:'     || gv_cdkbn_storage);
debug_log(FND_FILE.LOG,' ���o�ɏꏊ1:'     || gt_move_data_tab(ln_cnt_2).ship_from);
debug_log(FND_FILE.LOG,' �R�[�h�敪2:'     || gv_cdkbn_storage);
debug_log(FND_FILE.LOG,' ���o�ɏꏊ2:'     || gt_move_data_tab(ln_cnt_2).ship_to);
debug_log(FND_FILE.LOG,' ���i�敪:'        || iv_prod_class);
debug_log(FND_FILE.LOG,' �d�ʗe�ϋ敪:'    || gt_move_data_tab(ln_cnt_2).weight_capacity_cls);
debug_log(FND_FILE.LOG,' �����z�ԑΏۋ敪:'|| cv_an_object);
debug_log(FND_FILE.LOG,' ���:'|| to_char(gt_move_data_tab(ln_cnt_2).ship_date,'YYYYMMDD'));
--
        -- ���ʊ֐��F�ő�z���敪�Z�o�֐�
        return_cd := xxwsh_common_pkg.get_max_ship_method(
                  iv_code_class1                => gv_cdkbn_storage,          -- �R�[�h�敪1
                  iv_entering_despatching_code1 => gt_move_data_tab(ln_cnt_2).ship_from,
                                                                              -- ���o�ɏꏊ1
                  iv_code_class2                => gv_cdkbn_storage,          -- �R�[�h�敪2
                  iv_entering_despatching_code2 => gt_move_data_tab(ln_cnt_2).ship_to,
                                                                              -- ���o�ɏꏊ2
                  iv_prod_class                 => iv_prod_class,             -- ���i�敪
                  iv_weight_capacity_class      => gt_move_data_tab(ln_cnt_2).weight_capacity_cls,
                                                                              -- �d�ʗe�ϋ敪
                  iv_auto_process_type          => cv_an_object,              -- �����z�ԑΏۋ敪
                  id_standard_date              => gt_move_data_tab(ln_cnt_2).ship_date,
                                                                              -- ���
                  ov_max_ship_methods           => lv_max_ship_methods_m,     -- �ő�z���敪
                  on_drink_deadweight           => ln_drink_deadweight_m,     -- �h�����N�ύڏd��
                  on_leaf_deadweight            => ln_leaf_deadweight_m,      -- ���[�t�ύڏd��
                  on_drink_loading_capacity     => ln_drink_loading_capacity_m,
                                                                              -- �h�����N�ύڗe��
                  on_leaf_loading_capacity      => ln_leaf_loading_capacity_m,-- ���[�t�ύڗe��
                  on_palette_max_qty            => ln_palette_max_qty_m       -- �p���b�g�ő喇��
                  );
--
debug_log(FND_FILE.LOG,' �ő�z���敪:'    || lv_max_ship_methods_m);
debug_log(FND_FILE.LOG,' �h�����N�ύڏd��:'|| ln_drink_deadweight_m);
debug_log(FND_FILE.LOG,' ���[�t�ύڏd��:'  || ln_leaf_deadweight_m);
debug_log(FND_FILE.LOG,' �h�����N�ύڗe��:'|| ln_drink_loading_capacity_m);
debug_log(FND_FILE.LOG,' ���[�t�ύڗe��:'  || ln_leaf_loading_capacity_m);
debug_log(FND_FILE.LOG,' �p���b�g�ő喇��:'|| ln_palette_max_qty_m);
--
        IF  (return_cd = gv_error)
          OR (lv_max_ship_methods_m IS NULL)
        THEN
--
debug_log(FND_FILE.LOG,' gv_msg_xxwsh_11802 2');
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                        gv_xxwsh                        -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                       ,gv_msg_xxwsh_11802              -- �ő�z���敪�擾�G���[
                       ,gv_tkn_from                     -- �g�[�N��'FROM'
                       ,gt_move_data_tab(ln_cnt_2).ship_from
                                                        -- ���o�ɏꏊ1
                       ,gv_tkn_to                       -- �g�[�N��'TO'
                       ,gt_move_data_tab(ln_cnt_2).ship_to
                                                        -- ���o�ɏꏊ2
                       ,gv_tkn_codekbn1                 -- �g�[�N��'CODEKBN1'
                       ,gv_cdkbn_storage                -- �R�[�h�敪1
                       ,gv_tkn_codekbn2                 -- �g�[�N��'CODEKBN2'
                       ,gv_cdkbn_storage                -- �R�[�h�敪2
                      ) ,1 ,5000);
--
          RAISE global_api_expt;
--
        END IF;
--
        -- ==================================
        -- �\�[�g�e�[�u���o�^�pPL/SQL�ɃZ�b�g
        -- ==================================
        gt_deliver_no_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).deliver_no;           -- �z��No
        gt_pre_deliver_no_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).pre_deliver_no;       -- �O��z��No
        gt_req_mov_no_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).req_mov_no;           -- �˗�No/�ړ�No
        gt_mixed_no_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).mixed_no;             -- ���ڌ�No
        gt_carrier_code_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).carrier_code;         -- �^���Ǝ�
        gt_carrier_id_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).carrier_id;           -- �^���Ǝ�ID
        gt_ship_from_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).ship_from;            -- �o�׌��ۊǏꏊ
        gt_ship_from_id_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).ship_from_id;         -- �o�׌�ID
        gt_ship_to_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).ship_to;              -- �o�א�
        gt_ship_to_id_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).ship_to_id;           -- �o�א�ID
        gt_ship_method_code_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).ship_method_code;     -- �z���敪
        gt_small_div_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).small_div;            -- �����敪
        gt_ship_date_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).ship_date;            -- �o�ɓ�
        gt_arrival_date_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).arrival_date;         -- ���ד�
--
--20080517:DSugahara�C���s�No1 ��{�d�ʁA��{�e�ς̐ݒ�->
--        gt_based_weight_m(ln_cnt_2)
--            := gt_move_data_tab(ln_cnt_2).based_weight;         -- ��{�d��
--        gt_based_capacity_m(ln_cnt_2)
--            := gt_move_data_tab(ln_cnt_2).based_capacity;       -- ��{�e��
        -- ��{�d��
        IF (gt_move_data_tab(ln_cnt_2).item_class = gv_prod_cls_leaf) THEN
          gt_based_weight_m(ln_cnt_2) := ln_leaf_deadweight_m;    -- ���[�t�ύڏd��
        ELSE
          gt_based_weight_m(ln_cnt_2) := ln_drink_deadweight_m;   -- �h�����N�ύڏd��
        END IF;
        -- ��{�e��
        IF (gt_move_data_tab(ln_cnt_2).item_class = gv_prod_cls_leaf) THEN
          gt_based_capacity_m(ln_cnt_2) := ln_leaf_loading_capacity_m;  -- ���[�t�ύڗe��
        ELSE
          gt_based_capacity_m(ln_cnt_2) := ln_drink_loading_capacity_m; -- �h�����N�ύڗe��
        END IF;
--20080517:DSugahara�C���s�No1 ��{�d�ʁA��{�e�ς̐ݒ�<-
--
        gt_sum_weight_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).sum_weight;           -- �ύڏd�ʍ��v
        gt_sum_capacity_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).sum_capacity;         -- �ύڗe�ύ��v
        gt_weight_capacity_cls_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).weight_capacity_cls;  -- �d�ʗe�ϋ敪
        gt_sum_pallet_weight_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).sum_pallet_weight;    -- ���v�p���b�g�d��
        gt_item_class_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).item_class;           -- ���i�敪
        gt_business_type_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).business_type_id;     -- ����^�C�v
        gt_reserve_order_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).reserve_order;        -- ������
        gt_max_shipping_method_m(ln_cnt_2)
            := lv_max_ship_methods_m;                           -- �ő�z���敪
        gt_head_sales_branch_m(ln_cnt_2)
            := gt_move_data_tab(ln_cnt_2).sales_branch;         -- �Ǌ����_
        gt_pre_saved_flag_m(ln_cnt_2)     := 0;                 -- ���_���ړo�^�σt���O
--
      END LOOP get_max_ship_method_2;
--
    END IF;
--
    -- ===============================
    -- �\�[�g�p���ԃe�[�u���ɓo�^
    -- ===============================
--
--debug_log(FND_FILE.LOG,'�\�[�g�e�[�u���o�^');
--
    -- �o�׈˗��f�[�^����
    IF (gt_deliver_no_s.COUNT > 0) THEN
--
debug_log(FND_FILE.LOG,'�o�׈˗��f�[�^�o�^');
      -- �o�׈˗�
      FORALL ln_cnt_1 IN 1..gt_deliver_no_s.COUNT
        INSERT INTO xxwsh_carriers_sort_tmp(      -- �����z�ԃ\�[�g�p���ԃe�[�u��
              transaction_id                      -- �g�����U�N�V����ID
            , transaction_type                    -- �������(�z��)
            , delivery_no                         -- �z��No
            , prev_delivery_no                    -- �O��z��No
            , request_no                          -- �˗�No/�ړ�No
            , mixed_no                            -- ���ڌ�No
            , freight_carrier_code                -- �^���Ǝ�
            , career_id                           -- �^���Ǝ�ID
            , deliver_from                        -- �o�׌��ۊǏꏊ
            , deliver_from_id                     -- �o�׌�ID
            , deliver_to                          -- �o�א�
            , deliver_to_id                       -- �o�א�ID
            , shipping_method_code                -- �z���敪
            , small_sum_class                     -- �����敪
            , schedule_ship_date                  -- �o�ɓ�
            , schedule_arrival_date               -- ���ד�
            , based_weight                        -- ��{�d��
            , based_capacity                      -- ��{�e��
            , sum_weight                          -- �ύڏd�ʍ��v
            , sum_capacity                        -- �ύڗe�ύ��v
            , weight_capacity_class               -- �d�ʗe�ϋ敪
            , sum_pallet_weight                   -- ���v�p���b�g�d��
            , prod_class                          -- ���i�敪
            , order_type_id                       -- ����^�C�v
            , reserve_order                       -- ������
            , max_shipping_method_code            -- �ő�z���敪
            , head_sales_branch                   -- �Ǌ����_
            , pre_saved_flg                       -- ���_���ړo�^�σt���O
            )
            VALUES
            (
              xxwsh_carriers_sort_tmp_s1.NEXTVAL  -- �g�����U�N�V����ID
            , gv_ship_type_ship                   -- �������(�z��)
            , gt_deliver_no_s(ln_cnt_1)           -- �z��No
            , gt_pre_deliver_no_s(ln_cnt_1)       -- �O��z��No
            , gt_req_mov_no_s(ln_cnt_1)           -- �˗�No/�ړ�No
            , gt_mixed_no_s(ln_cnt_1)             -- ���ڌ�No
            , gt_carrier_code_s(ln_cnt_1)         -- �^���Ǝ�
            , gt_carrier_id_s(ln_cnt_1)           -- �^���Ǝ�ID
            , gt_ship_from_s(ln_cnt_1)            -- �o�׌��ۊǏꏊ
            , gt_ship_from_id_s(ln_cnt_1)         -- �o�׌�ID
            , gt_ship_to_s(ln_cnt_1)              -- �o�א�
            , gt_ship_to_id_s(ln_cnt_1)           -- �o�א�ID
            , gt_ship_method_code_s(ln_cnt_1)     -- �z���敪
            , gt_small_div_s(ln_cnt_1)            -- �����敪
            , gt_ship_date_s(ln_cnt_1)            -- �o�ɓ�
            , gt_arrival_date_s(ln_cnt_1)         -- ���ד�
            , gt_based_weight_s(ln_cnt_1)         -- ��{�d��
            , gt_based_capacity_s(ln_cnt_1)       -- ��{�e��
            , gt_sum_weight_s(ln_cnt_1)           -- �ύڏd�ʍ��v
            , gt_sum_capacity_s(ln_cnt_1)         -- �ύڗe�ύ��v
            , gt_weight_capacity_cls_s(ln_cnt_1)  -- �d�ʗe�ϋ敪
            , gt_sum_pallet_weight_s(ln_cnt_1)    -- ���v�p���b�g�d��
            , gt_item_class_s(ln_cnt_1)           -- ���i�敪
            , gt_business_type_s(ln_cnt_1)        -- ����^�C�v
            , gt_reserve_order_s(ln_cnt_1)        -- ������
            , gt_max_shipping_method_s(ln_cnt_1)  -- �ő�z���敪
            , gt_head_sales_branch_s(ln_cnt_1)    -- �Ǌ����_
            , gt_pre_saved_flag_s(ln_cnt_1)       -- ���_���ړo�^�σt���O
            );
--
    END IF;
--
    -- �ړ��w���f�[�^����
    IF (gt_deliver_no_m.COUNT > 0) THEN
--
debug_log(FND_FILE.LOG,'�ړ��w���f�[�^�o�^');
--
      -- �ړ��w��
      FORALL ln_cnt_2 IN 1..gt_deliver_no_m.COUNT
        INSERT INTO xxwsh_carriers_sort_tmp(      -- �����z�ԃ\�[�g�p���ԃe�[�u��
              transaction_id                      -- �g�����U�N�V����ID
            , transaction_type                    -- �������(�z��)
            , delivery_no                         -- �z��No
            , prev_delivery_no                    -- �O��z��No
            , request_no                          -- �˗�No/�ړ�No
            , mixed_no                            -- ���ڌ�No
            , freight_carrier_code                -- �^���Ǝ�
            , career_id                           -- �^���Ǝ�ID
            , deliver_from                        -- �o�׌��ۊǏꏊ
            , deliver_from_id                     -- �o�׌�ID
            , deliver_to                          -- �o�א�
            , deliver_to_id                       -- �o�א�ID
            , shipping_method_code                -- �z���敪
            , small_sum_class                     -- �����敪
            , schedule_ship_date                  -- �o�ɓ�
            , schedule_arrival_date               -- ���ד�
            , based_weight                        -- ��{�d��
            , based_capacity                      -- ��{�e��
            , sum_weight                          -- �ύڏd�ʍ��v
            , sum_capacity                        -- �ύڗe�ύ��v
            , weight_capacity_class               -- �d�ʗe�ϋ敪
            , sum_pallet_weight                   -- ���v�p���b�g�d��
            , prod_class                          -- ���i�敪
            , order_type_id                       -- ����^�C�v
            , reserve_order                       -- ������
            , max_shipping_method_code            -- �ő�z���敪
            , head_sales_branch                   -- �Ǌ����_
            , pre_saved_flg                       -- ���_���ړo�^�σt���O
            )
            VALUES
            ( xxwsh_carriers_sort_tmp_s1.NEXTVAL  -- �g�����U�N�V����ID
            , gv_ship_type_move                   -- �������(�z��)
            , gt_deliver_no_m(ln_cnt_2)           -- �z��No
            , gt_pre_deliver_no_m(ln_cnt_2)       -- �O��z��No
            , gt_req_mov_no_m(ln_cnt_2)           -- �˗�No/�ړ�No
            , gt_mixed_no_m(ln_cnt_2)             -- ���ڌ�No
            , gt_carrier_code_m(ln_cnt_2)         -- �^���Ǝ�
            , gt_carrier_id_m(ln_cnt_2)           -- �^���Ǝ�ID
            , gt_ship_from_m(ln_cnt_2)            -- �o�׌��ۊǏꏊ
            , gt_ship_from_id_m(ln_cnt_2)         -- �o�׌�ID
            , gt_ship_to_m(ln_cnt_2)              -- �o�א�
            , gt_ship_to_id_m(ln_cnt_2)           -- �o�א�ID
            , gt_ship_method_code_m(ln_cnt_2)     -- �z���敪
            , gt_small_div_m(ln_cnt_2)            -- �����敪
            , gt_ship_date_m(ln_cnt_2)            -- �o�ɓ�
            , gt_arrival_date_m(ln_cnt_2)         -- ���ד�
            , gt_based_weight_m(ln_cnt_2)         -- ��{�d��
            , gt_based_capacity_m(ln_cnt_2)       -- ��{�e��
            , gt_sum_weight_m(ln_cnt_2)           -- �ύڏd�ʍ��v
            , gt_sum_capacity_m(ln_cnt_2)         -- �ύڗe�ύ��v
            , gt_weight_capacity_cls_m(ln_cnt_2)  -- �d�ʗe�ϋ敪
            , gt_sum_pallet_weight_m(ln_cnt_2)    -- ���v�p���b�g�d��
            , gt_item_class_m(ln_cnt_2)           -- ���i�敪
            , gt_business_type_m(ln_cnt_2)        -- ����^�C�v
            , gt_reserve_order_m(ln_cnt_2)        -- ������
            , gt_max_shipping_method_m(ln_cnt_2)  -- �ő�z���敪
            , gt_head_sales_branch_m(ln_cnt_2)    -- �Ǌ����_
            , gt_pre_saved_flag_m(ln_cnt_2)       -- ���_���ړo�^�σt���O
            );
--
--
--debug_log(FND_FILE.LOG,'�\�[�g�e�[�u���o�^����');
--
    END IF;
-- Ver1.5 M.Hokkanji Start
    debug_log(FND_FILE.LOG,'�\�[�g�e�[�u���o�^�����������߃R�~�b�g');
    COMMIT;
-- Ver1.5 M.Hokkanji End
--
  EXCEPTION
    -- ���b�N�擾�G���[
    WHEN lock_expt THEN
      IF (get_ship_cur%ISOPEN) THEN
        CLOSE get_ship_cur;
      END IF;
      IF (get_move_cur%ISOPEN) THEN
        CLOSE get_move_cur;
      END IF;
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                   ,gv_msg_xxwsh_11052  -- ���b�Z�[�W�F���b�N�擾�G���[
                   ),1,5000);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
    WHEN no_data THEN
      IF (get_ship_cur%ISOPEN) THEN
        CLOSE get_ship_cur;
      END IF;
      IF (get_move_cur%ISOPEN) THEN
        CLOSE get_move_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (get_ship_cur%ISOPEN) THEN
        CLOSE get_ship_cur;
      END IF;
      IF (get_move_cur%ISOPEN) THEN
        CLOSE get_move_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (get_ship_cur%ISOPEN) THEN
        CLOSE get_ship_cur;
      END IF;
      IF (get_move_cur%ISOPEN) THEN
        CLOSE get_move_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (get_ship_cur%ISOPEN) THEN
        CLOSE get_ship_cur;
      END IF;
      IF (get_move_cur%ISOPEN) THEN
        CLOSE get_move_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_req_inst_info;
--
  /**********************************************************************************
   * Procedure Name   : ins_hub_mixed_info
   * Description      : ���_���ڏ��o�^����(B-4)
   ***********************************************************************************/
  PROCEDURE ins_hub_mixed_info(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_hub_mixed_info'; -- �v���O������
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
    cv_pre_save             CONSTANT VARCHAR2(1) := '1';    -- ���_���ڍ�
--
    -- *** ���[�J���ϐ� ***
    -- ��r�p�ϐ�
    lt_prev_ship_date       xxwsh_carriers_sort_tmp.schedule_ship_date%TYPE;    -- �o�ɓ�
    lt_prev_arrival_date    xxwsh_carriers_sort_tmp.schedule_arrival_date%TYPE; -- ���ד�
    lt_prev_order_type      xxwsh_carriers_sort_tmp.order_type_id%TYPE;         -- �o�Ɍ`��
    lt_prev_freight_carrier xxwsh_carriers_sort_tmp.freight_carrier_code%TYPE;  -- �^���Ǝ�
    lt_prev_ship_from       xxwsh_carriers_sort_tmp.deliver_from%TYPE;          -- �O�o�׌�
    lt_prev_ship_to         xxwsh_carriers_sort_tmp.deliver_to%TYPE;            -- �O�o�א�
    lt_prev_mixed_no        xxwsh_carriers_sort_tmp.mixed_no%TYPE;              -- �O���ڌ�No
--
    ln_sum_weight           NUMBER DEFAULT 0;                       -- �W��d��(1�ӏ��ڂ̔z����)
    ln_sum_capacity         NUMBER DEFAULT 0;                       -- �W��e��(1�ӏ��ڂ̔z����)
-- 2009/01/05 H.Itou Add Start �{�ԏ�Q#879
    ln_sum_weight_2         NUMBER DEFAULT 0;                       -- �W��d��(2�ӏ��ڂ̔z����)
    ln_sum_capacity_2       NUMBER DEFAULT 0;                       -- �W��e��(2�ӏ��ڂ̔z����)
-- 2009/01/05 H.Itou Add End
--
    ln_mixed_cnt            NUMBER DEFAULT 0;                       -- ���ڃJ�E���g
    ln_mixed_loop_cnt       NUMBER DEFAULT 0;                       -- ���[�v�J�E���g
    ln_ins_cnt              NUMBER DEFAULT 0;                       -- ���ԃe�[�u���o�^�p�J�E���g
    ln_work_cnt             NUMBER DEFAULT 0;                       -- ���ڃ��[�N�e�[�u���p�J�E���g
    lt_request_no_tab       req_mov_no_ttype;                       -- �˗�No�i�[�p�e�[�u��
    lt_trans_id_tab         transaction_id_ttype;                   -- �g�����U�N�V����ID�i�[�p
--
    ln_intensive_no         NUMBER DEFAULT NULL;                    -- �W��No(1�ӏ��ڂ̔z����)
-- 2009/01/05 H.Itou Add Start �{�ԏ�Q#879
    ln_intensive_no_2       NUMBER DEFAULT NULL;                    -- �W��No(2�ӏ��ڂ̔z����)
-- 2009/01/05 H.Itou Add End
    ln_grp_cnt              NUMBER DEFAULT 0;                       -- ����L�[�O���[�v�J�E���g
    ln_detail_ins_cnt       NUMBER DEFAULT 0;                       -- ���דo�^�J�E���g
    ln_start_cnt            NUMBER DEFAULT 0;                       -- �����J�n�J�E���g
    ln_end_cnt              NUMBER DEFAULT 0;                       -- �����I���J�E���g
    lb_exit_flag            BOOLEAN DEFAULT FALSE;                  -- �I���t���O
--
    -- �����z�ԃ\�[�g�p���ԃe�[�u���擾�p���R�[�h�^
    TYPE mixed_info_rtype IS RECORD(
        transaction_id            xxwsh_carriers_sort_tmp.transaction_id%TYPE           -- �g�����U�N�V����ID
      , transaction_type          xxwsh_carriers_sort_tmp.transaction_type%TYPE         -- �������
      , request_no                xxwsh_carriers_sort_tmp.request_no%TYPE               -- �o�׈˗�NO
      , mixed_no                  xxwsh_carriers_sort_tmp.mixed_no%TYPE                 -- ���ڌ�NO
      , deliver_from              xxwsh_carriers_sort_tmp.deliver_from%TYPE             -- �o�׌��ۊǏꏊ
      , deliver_from_id           xxwsh_carriers_sort_tmp.deliver_from_id%TYPE          -- �o�׌�ID
      , deliver_to                xxwsh_carriers_sort_tmp.deliver_to%TYPE               -- �o�א�
      , deliver_to_id             xxwsh_carriers_sort_tmp.deliver_to_id%TYPE            -- �o�א�ID
      , shipping_method_code      xxwsh_carriers_sort_tmp.shipping_method_code%TYPE     -- �z���敪
      , schedule_ship_date        xxwsh_carriers_sort_tmp.schedule_ship_date%TYPE       -- �o�ɓ�
      , schedule_arrival_date     xxwsh_carriers_sort_tmp.schedule_arrival_date%TYPE    -- ���ד�
      , order_type_id             xxwsh_carriers_sort_tmp.order_type_id%TYPE            -- �o�Ɍ`��
      , freight_carrier_code      xxwsh_carriers_sort_tmp.freight_carrier_code%TYPE     -- �^���Ǝ�
      , career_id                 xxwsh_carriers_sort_tmp.career_id%TYPE                -- �^���Ǝ�ID
      , based_weight              xxwsh_carriers_sort_tmp.based_weight%TYPE             -- ��{�d��
      , based_capacity            xxwsh_carriers_sort_tmp.based_capacity%TYPE           -- ��{�e��
      , sum_weight                xxwsh_carriers_sort_tmp.sum_weight%TYPE               -- �ύڏd�ʍ��v
      , sum_capacity              xxwsh_carriers_sort_tmp.sum_capacity%TYPE             -- �ύڗe�ύ��v
      , sum_pallet_weight         xxwsh_carriers_sort_tmp.sum_pallet_weight%TYPE        -- ���v�p���b�g�d��
      , max_shipping_method_code  xxwsh_carriers_sort_tmp.max_shipping_method_code%TYPE -- �ő�z���敪
      , weight_capacity_class     xxwsh_carriers_sort_tmp.weight_capacity_class%TYPE    -- �d�ʗe�ϋ敪
      , reserve_order             xxwsh_carriers_sort_tmp.reserve_order%TYPE            -- ������
    );
--
    -- �����z�ԃ\�[�g�p���ԃe�[�u���擾�p�\�^
    TYPE mixed_info_ttype IS TABLE OF mixed_info_rtype INDEX BY BINARY_INTEGER;
--
    -- �����z�ԃ\�[�g�p���ԃe�[�u���擾�pPLSQL�\
    mixed_info_tab  mixed_info_ttype;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR mixed_info_cur IS
      SELECT  xcst.transaction_id                     -- �g�����U�N�V����ID
            , xcst.transaction_type                   -- �������
            , xcst.request_no                         -- �o�׈˗�NO
            , xcst.mixed_no                           -- ���ڌ�NO
            , xcst.deliver_from                       -- �o�׌��ۊǏꏊ
            , xcst.deliver_from_id                    -- �o�׌�ID
            , xcst.deliver_to                         -- �o�א�
            , xcst.deliver_to_id                      -- �o�א�ID
            , xcst.shipping_method_code               -- �z���敪
            , xcst.schedule_ship_date                 -- �o�ɓ�
            , xcst.schedule_arrival_date              -- ���ד�
            , xcst.order_type_id                      -- �o�Ɍ`��
            , xcst.freight_carrier_code               -- �^���Ǝ�
            , xcst.career_id                          -- �^���Ǝ�ID
            , xcst.based_weight                       -- ��{�d��
            , xcst.based_capacity                     -- ��{�e��
            , xcst.sum_weight                         -- �ύڏd�ʍ��v
            , xcst.sum_capacity                       -- �ύڗe�ύ��v
            , xcst.sum_pallet_weight                  -- ���v�p���b�g�d��
            , xcst.max_shipping_method_code           -- �ő�z���敪
            , xcst.weight_capacity_class              -- �d�ʗe�ϋ敪
            , DECODE(xcst.reserve_order, NULL, 99999, xcst.reserve_order)
                                                      -- ������
      FROM xxwsh_carriers_sort_tmp xcst               -- �����z�ԃ\�[�g�p���ԃe�[�u��
      WHERE xcst.transaction_type = gv_ship_type_ship -- ������ʁF�o�׈˗��̂�
        AND xcst.mixed_no IS NOT NULL                 -- ���ڌ�NO
      ORDER BY  xcst.schedule_ship_date               -- �o�ɓ�
              , xcst.schedule_arrival_date            -- ���ד�
              , xcst.mixed_no                         -- ���ڌ�NO
              , xcst.order_type_id                    -- �o�Ɍ`��
              , xcst.deliver_from                     -- �o�׌��ۊǏꏊ
              , xcst.freight_carrier_code             -- �^���Ǝ�
              , xcst.weight_capacity_class            -- �d�ʗe�ϋ敪
              , xcst.reserve_order                    -- ������
              , xcst.head_sales_branch                -- �Ǌ����_
              , xcst.deliver_to                       -- �o�א�
              , DECODE (xcst.weight_capacity_class, gv_weight
                        , xcst.sum_weight             -- �W��d�ʍ��v
                        , xcst.sum_capacity) DESC     -- �W�񍇌v�e��
      ;
--
    -- *** ���[�J���E���R�[�h ***
    lr_mixed_info     mixed_info_cur%ROWTYPE;               -- �J�[�\�����R�[�h
    lr_intensive_tmp  xxwsh_intensive_carriers_tmp%ROWTYPE; -- �����z�ԏW�񒆊ԃe�[�u�����R�[�h(1�ӏ��ڂ̔z����p)
-- 2009/01/05 H.Itou Add Start �{�ԏ�Q#879
    lr_intensive_tmp_2  xxwsh_intensive_carriers_tmp%ROWTYPE; -- �����z�ԏW�񒆊ԃe�[�u�����R�[�h(2�ӏ��ڂ̔z����p)
-- 2009/01/05 H.Itou Add End
--
debug_cnt number default 0;
--
    -- *** �T�u�v���O���� ***
    --=========================
    -- �L�[�u���C�N����
    --=========================
    PROCEDURE ins_temp_table(
        ov_errbuf     OUT NOCOPY VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode    OUT NOCOPY VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg     OUT NOCOPY VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
    IS
      -- *** ���[�J���萔 ***
      cv_sub_prg_name   CONSTANT VARCHAR2(100) := '[ins_temp_table]'; -- �T�u�v���O������
--
    BEGIN
debug_log(FND_FILE.LOG,'B4_1.5�y�L�[�u���C�N�����z');
--
            ----------------------------------------------------------------
            -- �����z�ԏW�񒆊ԃe�[�u���pPL/SQL�\�ɃZ�b�g(1�ӏ��ڂ̔z����)
            ----------------------------------------------------------------
            -- �C���T�[�g�J�E���g
            ln_ins_cnt  :=  ln_ins_cnt + 1;
--
            -- �W��NO�擾
            SELECT xxwsh_intensive_no_s1.NEXTVAL
            INTO   ln_intensive_no
            FROM   dual;
debug_log(FND_FILE.LOG,'B4_1.51 �W��NO�擾�F'||ln_intensive_no);
--
            -- �����z�ԏW�񒆊ԃe�[�u���pPL/SQL�\�ɃZ�b�g
            gt_int_no_tab(ln_ins_cnt)
                    := ln_intensive_no;                             -- �W��NO
            gt_tran_type_tab(ln_ins_cnt)
                    :=  lr_intensive_tmp.transaction_type;          -- �������
            gt_int_source_tab(ln_ins_cnt)
                    :=  lr_intensive_tmp.intensive_source_no;       -- �W��No
            gt_deli_from_tab(ln_ins_cnt)
                    :=  lr_intensive_tmp.deliver_from;              -- �z����
            gt_deli_from_id_tab(ln_ins_cnt)
                    :=  lr_intensive_tmp.deliver_from_id;           -- �z����ID
            gt_deli_to_tab(ln_ins_cnt)
                    :=  lr_intensive_tmp.deliver_to;                -- �z����
            gt_deli_to_id_tab(ln_ins_cnt)
                    :=  lr_intensive_tmp.deliver_to_id;             -- �z����ID
            gt_ship_date_tab(ln_ins_cnt)
                    :=  lr_intensive_tmp.schedule_ship_date;        -- �o�ɗ\���
            gt_arvl_date_tab(ln_ins_cnt)
                    :=  lr_intensive_tmp.schedule_arrival_date;     -- ���ח\���
            gt_tran_type_nm_tab(ln_ins_cnt)
                    :=  lr_intensive_tmp.transaction_type_name;     -- �o�Ɍ`��
            gt_carrier_code_tab(ln_ins_cnt)
                    :=  lr_intensive_tmp.freight_carrier_code;      -- �^���Ǝ�
            gt_carrier_id_tab(ln_ins_cnt)
                    :=  lr_intensive_tmp.carrier_id;                -- �^���Ǝ�ID
            gt_sum_weight_tab(ln_ins_cnt)
                    :=  ln_sum_weight;                              -- �W�񍇌v�d��
            gt_sum_capa_tab(ln_ins_cnt)
                    :=  ln_sum_capacity;                            -- �W�񍇌v�e��
            gt_max_ship_cd_tab(ln_ins_cnt)
                    :=  lr_intensive_tmp.max_shipping_method_code;  -- �ő�z���敪
            gt_weight_capa_tab(ln_ins_cnt)
                    :=  lr_intensive_tmp.weight_capacity_class;     -- �d�ʗe�ϋ敪
            gt_max_weight_tab(ln_ins_cnt)
                    :=  lr_intensive_tmp.max_weight;                -- �ő�ύڏd��
            gt_max_capa_tab(ln_ins_cnt)
                    :=  lr_intensive_tmp.max_capacity;              -- �ő�ύڗe��
--
-- 2009/01/05 H.Itou Add Start �{�ԏ�Q#879
            ----------------------------------------------------------------
            -- �����z�ԏW�񒆊ԃe�[�u���pPL/SQL�\�ɃZ�b�g(2�ӏ��ڂ̔z����)
            ----------------------------------------------------------------
            -- �C���T�[�g�J�E���g
            ln_ins_cnt  :=  ln_ins_cnt + 1;
--
            -- �W��NO�擾
            SELECT xxwsh_intensive_no_s1.NEXTVAL
            INTO   ln_intensive_no_2
            FROM   dual;
debug_log(FND_FILE.LOG,'B4_1.51 2�ӏ��ڂ̔z����̏W��NO�擾�F'||ln_intensive_no_2);
--
            -- �����z�ԏW�񒆊ԃe�[�u���pPL/SQL�\�ɃZ�b�g
            gt_int_no_tab(ln_ins_cnt)       := ln_intensive_no_2;                            -- �W��NO
            gt_tran_type_tab(ln_ins_cnt)    := lr_intensive_tmp_2.transaction_type;          -- �������
            gt_int_source_tab(ln_ins_cnt)   := lr_intensive_tmp_2.intensive_source_no;       -- �W��No
            gt_deli_from_tab(ln_ins_cnt)    := lr_intensive_tmp_2.deliver_from;              -- �z����
            gt_deli_from_id_tab(ln_ins_cnt) := lr_intensive_tmp_2.deliver_from_id;           -- �z����ID
            gt_deli_to_tab(ln_ins_cnt)      := lr_intensive_tmp_2.deliver_to;                -- �z����
            gt_deli_to_id_tab(ln_ins_cnt)   := lr_intensive_tmp_2.deliver_to_id;             -- �z����ID
            gt_ship_date_tab(ln_ins_cnt)    := lr_intensive_tmp_2.schedule_ship_date;        -- �o�ɗ\���
            gt_arvl_date_tab(ln_ins_cnt)    := lr_intensive_tmp_2.schedule_arrival_date;     -- ���ח\���
            gt_tran_type_nm_tab(ln_ins_cnt) := lr_intensive_tmp_2.transaction_type_name;     -- �o�Ɍ`��
            gt_carrier_code_tab(ln_ins_cnt) := lr_intensive_tmp_2.freight_carrier_code;      -- �^���Ǝ�
            gt_carrier_id_tab(ln_ins_cnt)   := lr_intensive_tmp_2.carrier_id;                -- �^���Ǝ�ID
            gt_sum_weight_tab(ln_ins_cnt)   := ln_sum_weight_2;                              -- �W�񍇌v�d��
            gt_sum_capa_tab(ln_ins_cnt)     := ln_sum_capacity_2;                            -- �W�񍇌v�e��
            gt_max_ship_cd_tab(ln_ins_cnt)  := lr_intensive_tmp_2.max_shipping_method_code;  -- �ő�z���敪
            gt_weight_capa_tab(ln_ins_cnt)  := lr_intensive_tmp_2.weight_capacity_class;     -- �d�ʗe�ϋ敪
            gt_max_weight_tab(ln_ins_cnt)   := lr_intensive_tmp_2.max_weight;                -- �ő�ύڏd��
            gt_max_capa_tab(ln_ins_cnt)     := lr_intensive_tmp_2.max_capacity;              -- �ő�ύڗe��
-- 2009/01/05 H.Itou Add End
--
debug_log(FND_FILE.LOG,'(B-4)gt_sum_weight_tab�F'||gt_sum_weight_tab(ln_ins_cnt));
--
debug_log(FND_FILE.LOG,'-------------------------------------');
debug_log(FND_FILE.LOG,'B4_1.52 ���׃e�[�u���f�[�^���F'||lt_request_no_tab.COUNT);
debug_log(FND_FILE.LOG,' �J�n�ʒu ln_start_cnt�F'||ln_start_cnt);
debug_log(FND_FILE.LOG,' �I���ʒu ln_end_cnt�F'  ||ln_end_cnt);
debug_log(FND_FILE.LOG,' ���חp�o�^�J�E���gln_detail_ins_cnt�F'||ln_detail_ins_cnt);
            -- �����z�ԏW�񒆊Ԗ��׃e�[�u���pPL/SQL�\�Ɋi�[
            <<set_lines_request_id_loop>>
            FOR loop_cnt IN ln_start_cnt..ln_end_cnt LOOP
--
              -- ���חp�o�^�J�E���g
              ln_detail_ins_cnt := ln_detail_ins_cnt + 1;
debug_log(FND_FILE.LOG,'���חp�o�^�J�E���g�F'||ln_detail_ins_cnt);
--
              -- �W��NO
-- 2009/01/05 H.Itou Add Start �{�ԏ�Q#879
              -- 1�ӏ��ڂ̔z����Ɠ����ꍇ
              IF (lr_intensive_tmp.deliver_to = mixed_info_tab(loop_cnt).deliver_to) THEN
-- 2009/01/05 H.Itou Add End
                gt_int_no_lines_tab(ln_detail_ins_cnt) := ln_intensive_no;
-- 2009/01/05 H.Itou Add Start �{�ԏ�Q#879
              -- 2�ӏ��ڂ̔z����Ɠ����ꍇ
              ELSE
                gt_int_no_lines_tab(ln_detail_ins_cnt) := ln_intensive_no_2;
              END IF;
-- 2009/01/05 H.Itou Add End
--
              -- �˗�NO
              gt_request_no_tab(ln_detail_ins_cnt) := lt_request_no_tab(loop_cnt);
--20080519 D.Sugahara Add �s�No3�Ή�->
              -- �g�����U�N�V����ID�i�\�[�g�e�[�u���X�V�p�j
-- 2008/12/02 H.Itou Mod Start �{�ԏ�Q#220 �\�[�g�e�[�u���X�V�g�����U�N�V����ID������Ă��邽�ߏC���B
--              lt_trans_id_tab(ln_detail_ins_cnt) := mixed_info_tab(ln_detail_ins_cnt).transaction_id;
              lt_trans_id_tab(ln_detail_ins_cnt) := mixed_info_tab(loop_cnt).transaction_id;
-- 2008/12/02 H.Itou Mod End
--20080519 D.Sugahara Add �s�No3�Ή�<-              
--
debug_log(FND_FILE.LOG,'�W��NO�F'||gt_int_no_lines_tab(ln_detail_ins_cnt));
debug_log(FND_FILE.LOG,'�˗�NO�F'||gt_request_no_tab(ln_detail_ins_cnt));
--
            END LOOP set_lines_request_id_loop;
--debug_log(FND_FILE.LOG,'�����z�ԏW�񒆊Ԗ���PLSQL�ɃZ�b�g');
/*for i in 1..gt_int_no_lines_tab.count loop
      debug_log(FND_FILE.LOG,'�W��NO:'||gt_int_no_lines_tab(i));
      debug_log(FND_FILE.LOG,'�˗�NO:'||gt_request_no_tab(i));
      debug_log(FND_FILE.LOG,'---------------------------------');
end loop;
*/
--debug_log(FND_FILE.LOG,'���׃e�[�u��������');
    EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
      -- *** ���ʊ֐���O�n���h�� ***
      WHEN global_api_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||lv_errbuf,1,5000);
        ov_retcode := gv_status_error;
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      WHEN global_api_others_expt THEN
        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
    END;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
debug_log(FND_FILE.LOG,'-----------------------------------');
debug_log(FND_FILE.LOG,'B-4�y���_���ڏ��o�^����(B-4)�z');
    -- �ϐ�������
    lt_request_no_tab.DELETE;   -- �˗�No�i�[�p�e�[�u��
    lt_trans_id_tab.DELETE;     -- �g�����U�N�V����ID�i�[�p
    gt_int_no_tab.DELETE;       -- �W��No
    gt_tran_type_tab.DELETE;    -- �������
    gt_int_source_tab.DELETE;   -- �W��No
    gt_deli_from_tab.DELETE;    -- �z����
    gt_deli_from_id_tab.DELETE; -- �z����ID
    gt_deli_to_tab.DELETE;      -- �z����
    gt_deli_to_id_tab.DELETE;   -- �z����ID
    gt_ship_date_tab.DELETE;    -- �o�ɗ\���
    gt_arvl_date_tab.DELETE;    -- ���ח\���
    gt_tran_type_nm_tab.DELETE; -- �o�Ɍ`��
    gt_carrier_code_tab.DELETE; -- �^���Ǝ�
    gt_carrier_id_tab.DELETE;   -- �^���Ǝ�ID
    gt_sum_weight_tab.DELETE;   -- �W�񍇌v�d��
    gt_sum_capa_tab.DELETE;     -- �W�񍇌v�e��
    gt_max_ship_cd_tab.DELETE;  -- �ő�z���敪
    gt_weight_capa_tab.DELETE;  -- �d�ʗe�ϋ敪
    gt_max_weight_tab.DELETE;   -- �ő�ύڏd��
    gt_max_capa_tab.DELETE;     -- �ő�ύڗe��
    gt_base_weight_tab.DELETE;  -- ��{�d��
    gt_base_capa_tab.DELETE;    -- ��{�e��
    gt_int_no_lines_tab.DELETE; -- �W��No
    gt_request_no_tab.DELETE;   -- �˗�No
--
    -- ===============================
    -- ���_���ڏW�񏈗�
    -- ===============================
    -- �����z�ԃ\�[�g�p���ԃe�[�u���ꊇ�擾
    OPEN mixed_info_cur;
    FETCH mixed_info_cur BULK COLLECT INTO mixed_info_tab;
    CLOSE mixed_info_cur;
--
    IF (mixed_info_tab.COUNT > 0) THEN
      <<get_mixed_no_loop>>
      LOOP
--
debug_log(FND_FILE.LOG,'�Ώی����F'||mixed_info_tab.COUNT);
debug_cnt := debug_cnt + 1;
--
        -- ���[�N�J�E���g
        ln_work_cnt := ln_work_cnt + 1;
        ln_grp_cnt  := ln_grp_cnt + 1;
--
debug_log(FND_FILE.LOG,'B4_1.0-----------------------------------');
debug_log(FND_FILE.LOG,' ���[�N�J�E���g'||ln_work_cnt);
debug_log(FND_FILE.LOG,' �O���[�v�J�E���g'||ln_grp_cnt);
debug_log(FND_FILE.LOG,'-----------------------------------');
--
        IF (ln_grp_cnt = 1) THEN
--
          -- �J�n�J�E���g�m��
          ln_start_cnt := ln_work_cnt;
          -- 1���R�[�h�ڊi�[(����R�[�h)
--
debug_log(FND_FILE.LOG,'B4_1.1����R�[�h�ݒ�');
          lr_intensive_tmp.transaction_type := gv_ship_type_ship;                     -- �������
          lr_intensive_tmp.intensive_source_no := mixed_info_tab(ln_work_cnt).mixed_no;
                                                                                      -- �W��No
          lr_intensive_tmp.schedule_ship_date :=  mixed_info_tab(ln_work_cnt).schedule_ship_date;
                                                                                      -- �o�ɓ�
          lr_intensive_tmp.schedule_arrival_date := mixed_info_tab(ln_work_cnt).schedule_arrival_date;
                                                                                      -- ���ד�
          lr_intensive_tmp.freight_carrier_code := mixed_info_tab(ln_work_cnt).freight_carrier_code;
                                                                                      -- �^���Ǝ�
          lr_intensive_tmp.carrier_id := mixed_info_tab(ln_work_cnt).career_id;       -- �^���Ǝ�ID
          lr_intensive_tmp.deliver_to := mixed_info_tab(ln_work_cnt).deliver_to;      -- �z����
          lr_intensive_tmp.deliver_to_id := mixed_info_tab(ln_work_cnt).deliver_to_id;-- �z����ID
          lr_intensive_tmp.deliver_from := mixed_info_tab(ln_work_cnt).deliver_from;  -- �z����
          lr_intensive_tmp.deliver_from_id := mixed_info_tab(ln_work_cnt).deliver_from_id;
                                                                                      -- �z����ID
          lr_intensive_tmp.transaction_type_name := mixed_info_tab(ln_work_cnt).order_type_id;
                                                                                      -- �o�Ɍ`��
          lr_intensive_tmp.max_shipping_method_code := mixed_info_tab(ln_work_cnt).shipping_method_code;
                                                                                      -- �ő�z���敪
          lr_intensive_tmp.weight_capacity_class := mixed_info_tab(ln_work_cnt).weight_capacity_class;
                                                                                      -- �d�ʗe�ϋ敪
          lr_intensive_tmp.max_weight := mixed_info_tab(ln_work_cnt).based_weight;    -- ��{�d��
          lr_intensive_tmp.max_capacity := mixed_info_tab(ln_work_cnt).based_capacity;-- ��{�e��
--
          -- ��r�p�ϐ��Ɋi�[
          lt_prev_mixed_no        :=  mixed_info_tab(ln_work_cnt).mixed_no;               -- ���ڌ�
          lt_prev_ship_date       :=  mixed_info_tab(ln_work_cnt).schedule_ship_date;     -- �o�ɓ�
          lt_prev_arrival_date    :=  mixed_info_tab(ln_work_cnt).schedule_arrival_date;  -- ���ד�
          lt_prev_freight_carrier :=  mixed_info_tab(ln_work_cnt).freight_carrier_code;   -- �^���Ǝ�
          lt_prev_ship_from       :=  mixed_info_tab(ln_work_cnt).deliver_from;           -- �o�׌�
          lt_prev_ship_to         :=  mixed_info_tab(ln_work_cnt).deliver_to;             -- �o�א�
          lt_prev_order_type      :=  mixed_info_tab(ln_work_cnt).order_type_id;          -- �o�Ɍ`��
--
debug_log(FND_FILE.LOG,'  ���ڌ��F  '||lt_prev_mixed_no);
debug_log(FND_FILE.LOG,'  �˗�No�F  '||mixed_info_tab(ln_work_cnt).request_no);
debug_log(FND_FILE.LOG,'  �o�ɓ��F  '||lt_prev_ship_date);
debug_log(FND_FILE.LOG,'  ���ד��F  '||lt_prev_arrival_date);
debug_log(FND_FILE.LOG,'  �^���ƎҁF'||lt_prev_freight_carrier);
debug_log(FND_FILE.LOG,'  �o�׌��F  '||lt_prev_ship_from);
debug_log(FND_FILE.LOG,'  �o�א�F  '||lt_prev_ship_to);
debug_log(FND_FILE.LOG,'  �o�Ɍ`�ԁF'||lt_prev_order_type);
--
        END IF;
--
debug_log(FND_FILE.LOG,'B4_1.2��r�f�[�^-------');
debug_log(FND_FILE.LOG,'  ���ڌ��F'||mixed_info_tab(ln_work_cnt).mixed_no);
debug_log(FND_FILE.LOG,'  �˗�No�F'||mixed_info_tab(ln_work_cnt).request_no);
debug_log(FND_FILE.LOG,'  �o�ɓ��F'||mixed_info_tab(ln_work_cnt).schedule_ship_date);
debug_log(FND_FILE.LOG,'  ���ד��F'||mixed_info_tab(ln_work_cnt).schedule_arrival_date);
debug_log(FND_FILE.LOG,'  �^���ƎҁF'||mixed_info_tab(ln_work_cnt).freight_carrier_code);
debug_log(FND_FILE.LOG,'  �o�׌��ۊǏꏊ�F'||mixed_info_tab(ln_work_cnt).deliver_from);
        -- �L�[�u���C�N���Ȃ�
        IF ((lt_prev_mixed_no = mixed_info_tab(ln_work_cnt).mixed_no)                       -- ���ڌ�No
          AND (lt_prev_ship_date = mixed_info_tab(ln_work_cnt).schedule_ship_date)          -- �o�ɓ�
          AND (lt_prev_arrival_date = mixed_info_tab(ln_work_cnt).schedule_arrival_date)    -- ���ד�
          AND (lt_prev_freight_carrier = mixed_info_tab(ln_work_cnt).freight_carrier_code)  -- �^���Ǝ�
          AND (lt_prev_ship_from = mixed_info_tab(ln_work_cnt).deliver_from))               -- �o�׌��ۊǏꏊ
        THEN
--
debug_log(FND_FILE.LOG,'B4_1.3�L�[�u���C�N���Ȃ� Req_No: '||mixed_info_tab(ln_work_cnt).request_no);
          --�z���擯��i�W��j
-- 2009/01/05 H.Itou Add Start �{�ԏ�Q#879
--          IF (lt_prev_ship_to = mixed_info_tab(ln_work_cnt).deliver_to) THEN
          IF (lr_intensive_tmp.deliver_to = mixed_info_tab(ln_work_cnt).deliver_to) THEN
-- 2009/01/05 H.Itou Add End
--
debug_log(FND_FILE.LOG,'B4_1.31 �z���擯��');
            -- �d�ʁ^�e�ϏW��
            IF (mixed_info_tab(ln_work_cnt).weight_capacity_class = gv_weight) THEN
--
                -- �d��
                ln_sum_weight := ln_sum_weight
                                + mixed_info_tab(ln_work_cnt).sum_weight          -- �ύڏd�ʍ��v
                                + mixed_info_tab(ln_work_cnt).sum_pallet_weight;  -- ���v�p���b�g�d��
--
            ELSE
--
                -- �e��
                ln_sum_capacity := ln_sum_capacity
                                  + mixed_info_tab(ln_work_cnt).sum_capacity;     -- �ύڗe�ύ��v
--
            END IF;
--
          -- �z���悪�قȂ�
-- 2009/01/05 H.Itou Add Start �{�ԏ�Q#879
--          ELSIF (lt_prev_ship_to <> mixed_info_tab(ln_work_cnt).deliver_to) THEN -- ����
          ELSIF (lr_intensive_tmp.deliver_to <> mixed_info_tab(ln_work_cnt).deliver_to) THEN -- ����
-- 2009/01/05 H.Itou Add End
debug_log(FND_FILE.LOG,'B4_1.32 �z����قȂ�');
-- 2009/01/05 H.Itou Add Start �{�ԏ�Q#879
            -- 2�ӏ��ڂ̔z�������ݒ�
            IF (ln_mixed_cnt = 0) THEN
              lr_intensive_tmp_2.transaction_type         := gv_ship_type_ship;                                 -- �������
              lr_intensive_tmp_2.intensive_source_no      := mixed_info_tab(ln_work_cnt).mixed_no;              -- �W��No
              lr_intensive_tmp_2.schedule_ship_date       := mixed_info_tab(ln_work_cnt).schedule_ship_date;    -- �o�ɓ�
              lr_intensive_tmp_2.schedule_arrival_date    := mixed_info_tab(ln_work_cnt).schedule_arrival_date; -- ���ד�
              lr_intensive_tmp_2.freight_carrier_code     := mixed_info_tab(ln_work_cnt).freight_carrier_code;  -- �^���Ǝ�
              lr_intensive_tmp_2.carrier_id               := mixed_info_tab(ln_work_cnt).career_id;             -- �^���Ǝ�ID
              lr_intensive_tmp_2.deliver_to               := mixed_info_tab(ln_work_cnt).deliver_to;            -- �z����
              lr_intensive_tmp_2.deliver_to_id            := mixed_info_tab(ln_work_cnt).deliver_to_id;         -- �z����ID
              lr_intensive_tmp_2.deliver_from             := mixed_info_tab(ln_work_cnt).deliver_from;          -- �z����
              lr_intensive_tmp_2.deliver_from_id          := mixed_info_tab(ln_work_cnt).deliver_from_id;       -- �z����ID
              lr_intensive_tmp_2.transaction_type_name    := mixed_info_tab(ln_work_cnt).order_type_id;         -- �o�Ɍ`��
              lr_intensive_tmp_2.max_shipping_method_code := mixed_info_tab(ln_work_cnt).shipping_method_code;  -- �ő�z���敪
              lr_intensive_tmp_2.weight_capacity_class    := mixed_info_tab(ln_work_cnt).weight_capacity_class; -- �d�ʗe�ϋ敪
              lr_intensive_tmp_2.max_weight               := mixed_info_tab(ln_work_cnt).based_weight;          -- ��{�d��
              lr_intensive_tmp_2.max_capacity             := mixed_info_tab(ln_work_cnt).based_capacity;        -- ��{�e��
            END IF;
-- 2009/01/05 H.Itou Add Start �{�ԏ�Q#879
            -- ���ڃJ�E���g
            ln_mixed_cnt := ln_mixed_cnt + 1;
debug_log(FND_FILE.LOG,'���ڃJ�E���g�F'||ln_mixed_cnt);
--
            -- �d�ʁ^�e�ϏW��
            IF (mixed_info_tab(ln_work_cnt).weight_capacity_class = gv_weight) THEN
--
              -- �d��
-- 2009/01/05 H.Itou Add Start �{�ԏ�Q#879
              ln_sum_weight_2 := ln_sum_weight_2
-- 2009/01/05 H.Itou Add End
                              + mixed_info_tab(ln_work_cnt).sum_weight          -- �ύڏd�ʍ��v
                              + mixed_info_tab(ln_work_cnt).sum_pallet_weight;  -- ���v�p���b�g�d��
--
            ELSE
              -- �e��
-- 2009/01/05 H.Itou Add Start �{�ԏ�Q#879
--              ln_sum_capacity := ln_sum_capacity + mixed_info_tab(ln_work_cnt).sum_capacity;
              ln_sum_capacity_2 := ln_sum_capacity_2 + mixed_info_tab(ln_work_cnt).sum_capacity;
-- 2009/01/05 H.Itou Add End
--
            END IF;
--
          END IF;
--
debug_log(FND_FILE.LOG,'�d�ʍ��v(1�ӏ��ڂ̔z����)�F'||ln_sum_weight);
debug_log(FND_FILE.LOG,'�e�ύ��v(1�ӏ��ڂ̔z����)�F'||ln_sum_capacity);
debug_log(FND_FILE.LOG,'�d�ʍ��v(2�ӏ��ڂ̔z����)�F'||ln_sum_weight_2);
debug_log(FND_FILE.LOG,'�e�ύ��v(2�ӏ��ڂ̔z����)�F'||ln_sum_capacity_2);
--20080519 D.Sugahara Del �s�No3�Ή�->
          -- �g�����U�N�V����ID�i�\�[�g�e�[�u���X�V�p�j
--          lt_trans_id_tab(ln_work_cnt) := mixed_info_tab(ln_work_cnt).transaction_id;
--20080519 D.Sugahara Del �s�No3�Ή�->
--
          -- �˗�No
          lt_request_no_tab(ln_work_cnt) := mixed_info_tab(ln_work_cnt).request_no;
--
          -- ���݂̒l���r�p�ϐ��ɃZ�b�g����
          lt_prev_mixed_no        :=  mixed_info_tab(ln_work_cnt).mixed_no;               -- ���ڌ�
          lt_prev_ship_date       :=  mixed_info_tab(ln_work_cnt).schedule_ship_date;     -- �o�ɓ�
          lt_prev_arrival_date    :=  mixed_info_tab(ln_work_cnt).schedule_arrival_date;  -- ���ד�
          lt_prev_freight_carrier :=  mixed_info_tab(ln_work_cnt).freight_carrier_code;   -- �^���Ǝ�
          lt_prev_ship_from       :=  mixed_info_tab(ln_work_cnt).deliver_from;           -- �o�׌�
          lt_prev_ship_to         :=  mixed_info_tab(ln_work_cnt).deliver_to;             -- �o�א�
          lt_prev_order_type      :=  mixed_info_tab(ln_work_cnt).order_type_id;          -- �o�Ɍ`��
--
        -- �L�[�u���C�N�������ŏI���R�[�h�̏ꍇ
        ELSE
debug_log(FND_FILE.LOG,'B4_1.4�L�[�u���C�N�������ŏI���R�[�h�̏ꍇ');
--
          -- ���ڂ̏ꍇ�́A���ԃe�[�u���ɓo�^�pPL/SQL�\�ɃZ�b�g
          IF (ln_mixed_cnt > 0) THEN  -- ���ڃJ�E���g
debug_log(FND_FILE.LOG,'���ڃJ�E���g����');
            -- �I���J�E���g�m��
            ln_end_cnt := ln_work_cnt - 1;
--
debug_log(FND_FILE.LOG,'B4_1.41�L�[�u���C�N�����Ăяo��');
            -- �L�[�u���C�N������
            ins_temp_table(
                  ov_errbuf     => lv_errbuf
                , ov_retcode    => lv_retcode
                , ov_errmsg     => lv_errmsg
            );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--
debug_log(FND_FILE.LOG,'�L�[�u���C�N�����I���@');
--
          END IF;
          -- ���[�N�e�[�u���p�J�E���^���Z�b�g(�L�[�u���C�N���̃��R�[�h������R�[�h�ɂ���j
          ln_work_cnt := ln_work_cnt - 1;
--
debug_log(FND_FILE.LOG,'���[�N�J�E���g���Z�b�g�F'||ln_work_cnt);
--
          -- ���ڃJ�E���g���Z�b�g
          ln_mixed_cnt := 0;
--
debug_log(FND_FILE.LOG,'���ڃJ�E���g���Z�b�g�F'||ln_mixed_cnt);
--
          -- �O���[�v�J�E���g�����Z�b�g
          ln_grp_cnt := 0;
--
debug_log(FND_FILE.LOG,'�O���[�v�J�E���g���Z�b�g�F'||ln_grp_cnt);
--
          -- �W��l�����Z�b�g
          ln_sum_weight   := 0;
          ln_sum_capacity := 0;
-- 2009/01/05 H.Itou Add Start �{�ԏ�Q#879
          ln_sum_weight_2   := 0;
          ln_sum_capacity_2 := 0;
-- 2009/01/05 H.Itou Add End
--
debug_log(FND_FILE.LOG,'�W��l���Z�b�g');
--
        END IF;
--
debug_log(FND_FILE.LOG,'ln_work_cnt(�I��?)�F'|| ln_work_cnt);
--
        -- �I������
        IF ln_work_cnt >= mixed_info_tab.COUNT THEN
          -- ���ڂ̏ꍇ�́A���ԃe�[�u���ɓo�^�pPL/SQL�\�ɃZ�b�g
          IF (ln_mixed_cnt = 0) THEN
--
            lb_exit_flag := TRUE;
--
          ELSIF (ln_mixed_cnt > 0) THEN  -- ���ڃJ�E���g
--
debug_log(FND_FILE.LOG,'�I������');
            -- �I���J�E���g�m��
            ln_end_cnt := ln_work_cnt;
--
            -- �L�[�u���C�N������
            ins_temp_table(
                  ov_errbuf     => lv_errbuf
                , ov_retcode    => lv_retcode
                , ov_errmsg     => lv_errmsg
            );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--
debug_log(FND_FILE.LOG,'�L�[�u���C�N�����I���A');
--
            lb_exit_flag := TRUE;
--
          END IF;
--
        END IF;
--
        EXIT WHEN lb_exit_flag;
--@DS ���[�v�ی��K�v�H
      END LOOP get_mixed_no_loop;
--
--debug_log(FND_FILE.LOG,'���ԃe�[�u��PLSQL�f�[�^��:'||gt_int_no_tab.count);
--
debug_log(FND_FILE.LOG,'�������z�ԏW�񒆊ԃe�[�u���o�^�F���_���ڏ��o�^����');
debug_log(FND_FILE.LOG,'�o�^���F'||gt_tran_type_tab.COUNT);
debug_log(FND_FILE.LOG,'PLSQL�\�Fgt_tran_type_tab');
      -- ===============================
      -- ���ԃe�[�u���ꊇ�o�^����
      -- ===============================
      FORALL ln_cnt IN 1..gt_tran_type_tab.COUNT
        INSERT INTO xxwsh_intensive_carriers_tmp(   -- �����z�ԏW�񒆊ԃe�[�u��
            intensive_no              -- �W��No
          , transaction_type          -- �������
          , intensive_source_no       -- �W��No
          , deliver_from              -- �z����
          , deliver_from_id           -- �z����ID
          , deliver_to                -- �z����
          , deliver_to_id             -- �z����ID
          , schedule_ship_date        -- �o�ɗ\���
          , schedule_arrival_date     -- ���ח\���
          , transaction_type_name     -- �o�Ɍ`��
          , freight_carrier_code      -- �^���Ǝ�
          , carrier_id                -- �^���Ǝ�ID
          , intensive_sum_weight      -- �W�񍇌v�d��
          , intensive_sum_capacity    -- �W�񍇌v�e��
          , max_shipping_method_code  -- �ő�z���敪
          , weight_capacity_class     -- �d�ʗe�ϋ敪
          , max_weight                -- �ő�ύڏd��
          , max_capacity              -- �ő�ύڗe��
          )
          VALUES
          (
            gt_int_no_tab(ln_cnt)         -- �W��No
          , gt_tran_type_tab(ln_cnt)      -- �������
          , gt_int_source_tab(ln_cnt)     -- �W��No
          , gt_deli_from_tab(ln_cnt)      -- �z����
          , gt_deli_from_id_tab(ln_cnt)   -- �z����ID
          , gt_deli_to_tab(ln_cnt)        -- �z����
          , gt_deli_to_id_tab(ln_cnt)     -- �z����ID
          , gt_ship_date_tab(ln_cnt)      -- �o�ɗ\���
          , gt_arvl_date_tab(ln_cnt)      -- ���ח\���
          , gt_tran_type_nm_tab(ln_cnt)   -- �o�Ɍ`��
          , gt_carrier_code_tab(ln_cnt)   -- �^���Ǝ�
          , gt_carrier_id_tab(ln_cnt)     -- �^���Ǝ�ID
          , gt_sum_weight_tab(ln_cnt)     -- �W�񍇌v�d��
          , gt_sum_capa_tab(ln_cnt)       -- �W�񍇌v�e��
          , gt_max_ship_cd_tab(ln_cnt)    -- �ő�z���敪
          , gt_weight_capa_tab(ln_cnt)    -- �d�ʗe�ϋ敪
          , gt_max_weight_tab(ln_cnt)     -- �ő�ύڏd��
          , gt_max_capa_tab(ln_cnt)       -- �ő�ύڗe��
          );
--
debug_log(FND_FILE.LOG,'�����z�ԏW�񒆊ԃe�[�u���o�^���F'||gt_tran_type_tab.COUNT);
-------------------------------------------
/*for i in 1.. gt_tran_type_tab.count loop
      debug_log(FND_FILE.LOG,'�W��NO:'||gt_int_no_tab(i));
      debug_log(FND_FILE.LOG,'�������:'||gt_tran_type_tab(i));
      debug_log(FND_FILE.LOG,'�W��No:'||gt_int_source_tab(i));
      debug_log(FND_FILE.LOG,'�z����:'||gt_deli_from_tab(i));
      debug_log(FND_FILE.LOG,'�z����ID:'||gt_deli_from_id_tab(i));
      debug_log(FND_FILE.LOG,'�z����:'||gt_deli_to_tab(i));
      debug_log(FND_FILE.LOG,'�z����ID:'||gt_deli_to_id_tab(i));
      debug_log(FND_FILE.LOG,'�o�ɗ\���:'||gt_ship_date_tab(i));
      debug_log(FND_FILE.LOG,'���ח\���:'||gt_arvl_date_tab(i));
      debug_log(FND_FILE.LOG,'�o�Ɍ`��:'||gt_tran_type_nm_tab(i));
      debug_log(FND_FILE.LOG,'�^���Ǝ�:'||gt_carrier_code_tab(i));
      debug_log(FND_FILE.LOG,'�^���Ǝ�ID:'||gt_carrier_id_tab(i));
      debug_log(FND_FILE.LOG,'�W�񍇌v�d��:'||gt_sum_weight_tab(i));
      debug_log(FND_FILE.LOG,'�W�񍇌v�e��:'||gt_sum_capa_tab(i));
      debug_log(FND_FILE.LOG,'�ő�z���敪:'||gt_max_ship_cd_tab(i));
      debug_log(FND_FILE.LOG,'�d�ʗe�ϋ敪:'||gt_weight_capa_tab(i));
      debug_log(FND_FILE.LOG,'�ő�ύڏd��:'||gt_max_weight_tab(i));
      debug_log(FND_FILE.LOG,'�ő�ύڗe��:'||gt_max_capa_tab(i));
      debug_log(FND_FILE.LOG,'---------------------------------');
end loop;
*/
--------------------------------------------
debug_log(FND_FILE.LOG,'�W��No���F'|| gt_int_no_lines_tab.COUNT);
debug_log(FND_FILE.LOG,'�˗�No���F'|| gt_request_no_tab.COUNT);
debug_log(FND_FILE.LOG,'���׃e�[�u���o�^���F'||gt_request_no_tab.COUNT);
debug_log(FND_FILE.LOG,'PLSQL�\�Fgt_request_no_tab');
      FORALL ln_cnt_2 IN 1..gt_request_no_tab.COUNT
        INSERT INTO xxwsh_intensive_carrier_ln_tmp(  -- �����z�ԏW�񒆊Ԗ��׃e�[�u��
            intensive_no
          , request_no
          )
          VALUES
          (
            gt_int_no_lines_tab(ln_cnt_2) -- �W��NO
          , gt_request_no_tab(ln_cnt_2)   -- �˗�NO
          );
debug_log(FND_FILE.LOG,'�����z�ԏW�񒆊Ԗ��׃e�[�u���o�^���F'|| gt_request_no_tab.COUNT);
--for i in 1..gt_request_no_tab.count loop
--debug_log(FND_FILE.LOG,'���[�v��');
--      debug_log(FND_FILE.LOG,'�W��NO:'||gt_int_no_lines_tab(i));
--      debug_log(FND_FILE.LOG,'�˗�NO:'||gt_request_no_tab(i));
--      debug_log(FND_FILE.LOG,'---------------------------------');
--end loop;
--
      -- =================================
      -- ���_���ړo�^�σt���O�ꊇ�X�V����
      -- =================================
      FORALL ln_cnt_3 IN 1..lt_trans_id_tab.COUNT
        UPDATE xxwsh_carriers_sort_tmp                    -- �����z�ԃ\�[�g�p���ԃe�[�u��
          SET pre_saved_flg = cv_pre_save                 -- ���_���ړo�^�σt���O
        WHERE transaction_id = lt_trans_id_tab(ln_cnt_3)  -- �g�����U�N�V����ID
        ;
debug_log(FND_FILE.LOG,'�����z�ԃ\�[�g�p���ԃe�[�u���X�V���F'|| lt_trans_id_tab.COUNT);
    END IF;
-- Ver1.5 M.Hokkanji Start
    debug_log(FND_FILE.LOG,'�����z�ԏW�񒆊ԃe�[�u���o�^��R�~�b�g');
    COMMIT;
-- Ver1.5 M.Hokkanji End
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
  END ins_hub_mixed_info;
--
  /**********************************************************************************
   * Procedure Name   : chk_loading_efficiency
   * Description      : �ύڌ����`�F�b�N����(B-5)
   ***********************************************************************************/
  PROCEDURE chk_loading_efficiency(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_loading_efficiency'; -- �v���O������
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
    cv_pre_save     CONSTANT VARCHAR2(1) := '1';           -- ���_���ړo�^�F�o�^��
    cv_loading_over CONSTANT VARCHAR2(1) := '1';           -- �ύڃI�[�o�[�敪�F�I�[�o�[
    cv_allocation   CONSTANT VARCHAR2(1) := '1';           -- �����z�ԑΏۋ敪�F�Ώ�
--
    -- *** ���[�J���ϐ� ***
    lv_loading_over_class       VARCHAR2(1);                          -- �ύڃI�[�o�[�敪
    lv_ship_methods             xxcmn_ship_methods.ship_method%TYPE;  -- �o�ו��@
    ln_load_efficiency_weight   NUMBER;                               -- �d�ʐύڌ���
    ln_load_efficiency_capacity NUMBER;                               -- �e�ϐύڌ���
    lv_mixed_ship_method        VARCHAR2(2);                          -- ���ڔz���敪
    ln_err_cnt                  NUMBER DEFAULT 0;                     -- ���[�v�J�E���g
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR mixed_info_cur IS
      SELECT  xcst.transaction_id                     -- �g�����U�N�V����ID
            , xcst.transaction_type                   -- �������
            , xcst.request_no                         -- �o�׈˗�NO
            , xcst.mixed_no                           -- ���ڌ�NO
            , xcst.deliver_from                       -- �o�׌��ۊǏꏊ
            , xcst.deliver_from_id                    -- �o�׌�ID
            , xcst.deliver_to                         -- �o�א�
            , xcst.deliver_to_id                      -- �o�א�ID
            , xcst.shipping_method_code               -- �z���敪
            , xcst.schedule_ship_date                 -- �o�ɓ�
            , xcst.schedule_arrival_date              -- ���ד�
            , xcst.order_type_id                      -- �o�Ɍ`��
            , xcst.freight_carrier_code               -- �^���Ǝ�
            , xcst.career_id                          -- �^���Ǝ�ID
            , xcst.based_weight                       -- ��{�d��
            , xcst.based_capacity                     -- ��{�e��
            , xcst.sum_weight                         -- �ύڏd�ʍ��v
            , xcst.sum_capacity                       -- �ύڗe�ύ��v
            , xcst.sum_pallet_weight                  -- ���v�p���b�g�d��
            , xcst.max_shipping_method_code           -- �ő�z���敪
            , xcst.weight_capacity_class              -- �d�ʗe�ϋ敪
            , DECODE(reserve_order, NULL, 99999, reserve_order)
                                                      -- ������
      FROM xxwsh_carriers_sort_tmp xcst               -- �����z�ԃ\�[�g�p���ԃe�[�u��
      WHERE xcst.transaction_type = gv_ship_type_ship -- ������ʁF�o�׈˗�
        AND xcst.mixed_no IS NOT NULL                 -- ���ڌ�NO
      ORDER BY  xcst.schedule_ship_date          -- �o�ɓ�
              , xcst.schedule_arrival_date       -- ���ד�
              , xcst.mixed_no                    -- ���ڌ�NO
              , xcst.max_shipping_method_code    -- �ő�z���敪
              , xcst.order_type_id               -- �o�Ɍ`��
              , xcst.deliver_from                -- �o�׌��ۊǏꏊ
              , xcst.freight_carrier_code        -- �^���Ǝ�
              , xcst.weight_capacity_class       -- �d�ʗe�ϋ敪
              , xcst.reserve_order               -- ������
              , xcst.head_sales_branch           -- �Ǌ����_
              , xcst.deliver_to                  -- �o�א�
              , DECODE (xcst.weight_capacity_class, gv_weight
                        , xcst.sum_weight             -- �W��d�ʍ��v
                        , xcst.sum_capacity) DESC     -- �W�񍇌v�e��
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
debug_log(FND_FILE.LOG,'�y�ύڌ����`�F�b�N����(B-5)�z');
    -- ==================================
    -- �ύڌ����`�F�b�N
    -- ==================================
    <<chk_efficiency_loop>>
    FOR rec_cnt IN mixed_info_cur LOOP
--
      -- �ϐ�������
      lv_errmsg                   := NULL;
      lv_errbuf                   := NULL;
      lv_loading_over_class       := NULL;
      lv_ship_methods             := NULL;
      ln_load_efficiency_weight   := NULL;
      ln_load_efficiency_capacity := NULL;
      lv_mixed_ship_method        := NULL;
--
      -- �d��
      IF (rec_cnt.weight_capacity_class = gv_weight) THEN
--
debug_log(FND_FILE.LOG,'�ύڌ����`�F�b�N�F�d��');
debug_log(FND_FILE.LOG,'-----------------------------------');
debug_log(FND_FILE.LOG,'���v�d��:'||rec_cnt.sum_weight);
debug_log(FND_FILE.LOG,'���v�e��:'||NULL);
debug_log(FND_FILE.LOG,'�R�[�h�敪�P:'||gv_cdkbn_storage);
debug_log(FND_FILE.LOG,'���o�ɏꏊ�R�[�h�P:'||rec_cnt.deliver_from);
debug_log(FND_FILE.LOG,'�R�[�h�敪�Q:'||gv_cdkbn_ship_to);
debug_log(FND_FILE.LOG,'���o�ɏꏊ�R�[�h�Q:'||rec_cnt.deliver_to);
debug_log(FND_FILE.LOG,'�o�ו��@:'||rec_cnt.shipping_method_code);
debug_log(FND_FILE.LOG,'���i�敪:'||gv_prod_class);
debug_log(FND_FILE.LOG,'�����z�ԑΏۋ敪:'||cv_allocation);
debug_log(FND_FILE.LOG,'���(�K�p�����):'||TO_char(rec_cnt.schedule_ship_date,'yyyymmdd'));

--
        -- ���ʊ֐��F�ύڌ����`�F�b�N(�ύڌ���)
        xxwsh_common910_pkg.calc_load_efficiency(
            in_sum_weight                  => rec_cnt.sum_weight        -- 1.���v�d��
          , in_sum_capacity                => NULL                      -- 2.���v�e��
          , iv_code_class1                 => gv_cdkbn_storage          -- 3.�R�[�h�敪�P
          , iv_entering_despatching_code1  => rec_cnt.deliver_from      -- 4.���o�ɏꏊ�R�[�h�P
          , iv_code_class2                 => gv_cdkbn_ship_to          -- 5.�R�[�h�敪�Q
          , iv_entering_despatching_code2  => rec_cnt.deliver_to        -- 6.���o�ɏꏊ�R�[�h�Q
--          , iv_ship_method                 => rec_cnt.shipping_method_code --2008.05.16 D.sugahara
          , iv_ship_method                 => rec_cnt.max_shipping_method_code
                                                                        -- 7.�o�ו��@
          , iv_prod_class                  => gv_prod_class             -- 8.���i�敪
          , iv_auto_process_type           => cv_allocation             -- 9.�����z�ԑΏۋ敪
          , id_standard_date               => rec_cnt.schedule_ship_date
                                                                        -- 10.���(�K�p�����)
          , ov_retcode                     => lv_retcode                -- 11.���^�[���R�[�h
          , ov_errmsg_code                 => lv_errmsg                 -- 12.�G���[���b�Z�[�W�R�[�h
          , ov_errmsg                      => lv_errbuf                 -- 13.�G���[���b�Z�[�W
          , ov_loading_over_class          => lv_loading_over_class     -- 14.�ύڃI�[�o�[�敪
          , ov_ship_methods                => lv_ship_methods           -- 15.�o�ו��@
          , on_load_efficiency_weight      => ln_load_efficiency_weight -- 16.�d�ʐύڌ���
          , on_load_efficiency_capacity    => ln_load_efficiency_capacity
                                                                        -- 17.�e�ϐύڌ���
          , ov_mixed_ship_method           => lv_mixed_ship_method      -- 18.���ڔz���敪
        );
--

debug_log(FND_FILE.LOG,'���^�[���R�[�h:'||lv_retcode);
debug_log(FND_FILE.LOG,'�G���[���b�Z�[�W�R�[�h:'||lv_errmsg);
debug_log(FND_FILE.LOG,'�G���[���b�Z�[�W:'||lv_errbuf);
debug_log(FND_FILE.LOG,'�ύڃI�[�o�[�敪:'||lv_loading_over_class);
debug_log(FND_FILE.LOG,'�o�ו��@:'||lv_ship_methods);
debug_log(FND_FILE.LOG,'�d�ʐύڌ���:'||ln_load_efficiency_weight);
debug_log(FND_FILE.LOG,'�e�ϐύڌ���:'||ln_load_efficiency_capacity);
debug_log(FND_FILE.LOG,'���ڔz���敪:'||lv_mixed_ship_method);

--
        -- ���ʊ֐����G���[�̏ꍇ
-- Ver1.7 M.Hokkanji START
        IF (lv_retcode <> gv_status_normal) THEN
--        IF (lv_retcode = gv_status_error) THEN
-- Ver1.16 2008/12/07 START
--          lv_errmsg := lv_errbuf;
        BEGIN
          lv_errmsg  :=  to_char(rec_cnt.sum_weight) -- 1.���v�d��
                          || gv_msg_comma ||
                          NULL                -- 2.���v�e��
                          || gv_msg_comma ||
                          gv_cdkbn_storage    -- 3.�R�[�h�敪�P
                          || gv_msg_comma ||
                          rec_cnt.deliver_from  -- 4.���o�ɏꏊ�R�[�h�P
                          || gv_msg_comma ||
                          gv_cdkbn_ship_to      -- 5.�R�[�h�敪�Q
                          || gv_msg_comma ||
                          rec_cnt.deliver_to    -- 6.���o�ɏꏊ�R�[�h�Q
                          || gv_msg_comma ||
                          rec_cnt.max_shipping_method_code -- 7.�o�ו��@
                          || gv_msg_comma ||
                          gv_prod_class       -- 8.���i�敪
                          || gv_msg_comma ||
                          cv_allocation       -- 9.�����z�ԑΏۋ敪
                          || gv_msg_comma ||
                          TO_CHAR(rec_cnt.schedule_ship_date, 'YYYY/MM/DD'); -- 10.���
          lv_errmsg := lv_errmsg|| '(�d��,�e��,�R�[�h�敪1,�R�[�h1,�R�[�h�敪2,�R�[�h2';
          lv_errmsg := lv_errmsg|| ',�z���敪,���i�敪,�����z�ԑΏۋ敪,���'; -- msg
          lv_errmsg := lv_errmsg||lv_errbuf ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := lv_errbuf ;
        END;
-- Ver1.16 2008/12/07 END
-- Ver1.7 M.Hokkanji End
--
debug_log(FND_FILE.LOG,'�֐��G���[');
--
          RAISE global_api_expt;
        END IF;
--
        -- �ύڃI�[�o�[�̏ꍇ
        IF (lv_loading_over_class = cv_loading_over) THEN
--
          -- �G���[�J�E���g
          ln_err_cnt := ln_err_cnt + 1;
--
debug_log(FND_FILE.LOG,'�ύڃI�[�o�[�J�E���g:'||ln_err_cnt);
--
          -- �G���[���b�Z�[�W�擾
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                      , gv_msg_xxwsh_11803  -- ���b�Z�[�W�FAPP-XXWSH-11803 �ύڃI�[�o�[���b�Z�[�W
                      , gv_tkn_req_no       -- �g�[�N���FREQ_NO
                      , rec_cnt.request_no  -- �o�׈˗�No
                     ),1,5000);
--
          -- �G���[���b�Z�[�W�o��
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
debug_log(FND_FILE.LOG,'�G���[���b�Z�[�W:'||lv_errmsg);
--
        END IF;
--
      -- �e��
      ELSE
--
        -- ���ʊ֐��F�ύڌ����`�F�b�N(�ύڌ���)
        xxwsh_common910_pkg.calc_load_efficiency(
            in_sum_weight                  => NULL                      -- 1.���v�d��
          , in_sum_capacity                => rec_cnt.sum_capacity      -- 2.���v�e��
          , iv_code_class1                 => gv_cdkbn_storage          -- 3.�R�[�h�敪�P
          , iv_entering_despatching_code1  => rec_cnt.deliver_from      -- 4.���o�ɏꏊ�R�[�h�P
          , iv_code_class2                 => gv_cdkbn_ship_to          -- 5.�R�[�h�敪�Q
          , iv_entering_despatching_code2  => rec_cnt.deliver_to        -- 6.���o�ɏꏊ�R�[�h�Q
--          , iv_ship_method                 => rec_cnt.shipping_method_code --2008.05.16 D.sugahara
          , iv_ship_method                 => rec_cnt.max_shipping_method_code
                                                                        -- 7.�o�ו��@
          , iv_prod_class                  => gv_prod_class             -- 8.���i�敪
          , iv_auto_process_type           => cv_allocation             -- 9.�����z�ԑΏۋ敪
          , id_standard_date               => rec_cnt.schedule_ship_date
                                                                        -- 10.���(�K�p�����)
          , ov_retcode                     => lv_retcode                -- 11.���^�[���R�[�h
          , ov_errmsg_code                 => lv_errmsg                 -- 12.�G���[���b�Z�[�W�R�[�h
          , ov_errmsg                      => lv_errbuf                 -- 13.�G���[���b�Z�[�W
          , ov_loading_over_class          => lv_loading_over_class     -- 14.�ύڃI�[�o�[�敪
          , ov_ship_methods                => lv_ship_methods           -- 15.�o�ו��@
          , on_load_efficiency_weight      => ln_load_efficiency_weight -- 16.�d�ʐύڌ���
          , on_load_efficiency_capacity    => ln_load_efficiency_capacity
                                                                        -- 17.�e�ϐύڌ���
          , ov_mixed_ship_method           => lv_mixed_ship_method      -- 18.���ڔz���敪
        );
        -- ���ʊ֐����G���[�̏ꍇ
-- Ver1.7 M.Hokkanji START
        IF (lv_retcode <> gv_status_normal) THEN
-- Ver1.16 2008/12/07 START
--          lv_errmsg := lv_errbuf;
--        IF (lv_retcode = gv_status_error) THEN
--          lv_errmsg := lv_errbuf;
        BEGIN
          lv_errmsg  :=  NULL -- 1.���v�d��
                          || gv_msg_comma ||
                          rec_cnt.sum_capacity                -- 2.���v�e��
                          || gv_msg_comma ||
                          gv_cdkbn_storage    -- 3.�R�[�h�敪�P
                          || gv_msg_comma ||
                          rec_cnt.deliver_from  -- 4.���o�ɏꏊ�R�[�h�P
                          || gv_msg_comma ||
                          gv_cdkbn_ship_to      -- 5.�R�[�h�敪�Q
                          || gv_msg_comma ||
                          rec_cnt.deliver_to    -- 6.���o�ɏꏊ�R�[�h�Q
                          || gv_msg_comma ||
                          rec_cnt.max_shipping_method_code -- 7.�o�ו��@
                          || gv_msg_comma ||
                          gv_prod_class       -- 8.���i�敪
                          || gv_msg_comma ||
                          cv_allocation       -- 9.�����z�ԑΏۋ敪
                          || gv_msg_comma ||
                          TO_CHAR(rec_cnt.schedule_ship_date, 'YYYY/MM/DD'); -- 10.���
          lv_errmsg := lv_errmsg|| '(�d��,�e��,�R�[�h�敪1,�R�[�h1,�R�[�h�敪2,�R�[�h2';
          lv_errmsg := lv_errmsg|| ',�z���敪,���i�敪,�����z�ԑΏۋ敪,���'; -- msg
          lv_errmsg := lv_errmsg||lv_errbuf ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := lv_errbuf ;
        END;
-- Ver1.16 2008/12/07 End
-- Ver1.7 M.Hokkanji End
          RAISE global_api_expt;
        END IF;
--
        -- �ύڃI�[�o�[�̏ꍇ
        IF (lv_loading_over_class = cv_loading_over) THEN
--
          -- �G���[�J�E���g
          ln_err_cnt := ln_err_cnt + 1;
--
          -- �G���[���b�Z�[�W�擾
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                      , gv_msg_xxwsh_11803  -- ���b�Z�[�W�FAPP-XXWSH-11803 �ύڃI�[�o�[���b�Z�[�W
                      , gv_tkn_req_no       -- �g�[�N���FREQ_NO
                      , rec_cnt.request_no  -- �o�׈˗�No
                     ),1,5000);
--
          -- �G���[���b�Z�[�W�o��
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
        END IF;
--
      END IF;
--
    END LOOP chk_efficiency_loop;
--
    -- ==================================
    -- �G���[����
    -- ==================================
    IF (ln_err_cnt > 0) THEN
      -- �ύڃI�[�o�[�����݂���΃G���[
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
  END chk_loading_efficiency;
--
  /**********************************************************************************
   * Procedure Name   : set_weight_capacity_add
   * Description      : ���v�d��/�e�ώ擾 ���Z����(B-7)
   ***********************************************************************************/
  PROCEDURE set_weight_capacity_add(
    it_group_sum_add_tab  IN  grp_sum_add_ttype,   -- �����Ώۃe�[�u��
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_weight_capacity_add'; -- �v���O������
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
    cv_finish_proc            CONSTANT VARCHAR2(1) := '1';  -- �W���
    cv_over_loading           CONSTANT VARCHAR2(1) := '2';  -- �ύڃI�[�o�[�i�z��p�j
    cv_object                 CONSTANT VARCHAR2(1) := '1';  -- �����z�ԑΏ�
--20080517:DSugahara Add�s�1�Ή�
    cv_loading_over CONSTANT VARCHAR2(1) := '1';            -- �֐��p�ύڃI�[�o�[�敪�F�I�[�o�[    
--
    -- *** ���[�J���ϐ� ***
    -- �����ΏۊOPL/SQL�\�^
    TYPE over_loading_ttype IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;
--
    -- �ύڌ����I�[�o�[�Ώۊi�[�pPL/SQL�\
    lt_skip_process_tab       finish_sum_flag_ttype;
    -- �ύڌ����I�[�o�[�t���O
    lb_over_loading           BOOLEAN DEFAULT FALSE;
--
    -- ��r�p�ϐ�
    lt_prev_ship_date         xxwsh_carriers_sort_tmp.schedule_ship_date%TYPE;    -- �o�ɓ�
    lt_prev_arrival_date      xxwsh_carriers_sort_tmp.schedule_arrival_date%TYPE; -- ���ד�
    lt_prev_order_type        xxwsh_carriers_sort_tmp.order_type_id%TYPE;         -- �o�Ɍ`��
    lt_prev_freight_carrier   xxwsh_carriers_sort_tmp.freight_carrier_code%TYPE;  -- �^���Ǝ�
    lt_prev_ship_from         xxwsh_carriers_sort_tmp.deliver_from%TYPE;          -- �o�׌�
    lt_prev_ship_to           xxwsh_carriers_sort_tmp.deliver_to%TYPE;            -- �o�א�
    lt_prev_w_c_class         xxwsh_carriers_sort_tmp.weight_capacity_class%TYPE; -- �d�ʗe�ϋ敪
    lt_prev_fin_proc          VARCHAR2(1);                                        -- �W��σt���O
--
    lt_request_no_tab         req_mov_no_ttype;                               -- �˗�No�ݒ�p�e�[�u��
    lt_trans_id_tab           transaction_id_ttype;                           -- �g�����U�N�V����ID
    ln_pre_reqno_cnt          NUMBER DEFAULT 0;                               -- �˗�No�i�[�p�J�E���g
    lb_last_data_flag         BOOLEAN DEFAULT FALSE;                          -- �ŏI���R�[�h�t���O
    ln_ins_reqno_cnt          NUMBER DEFAULT 0;                               -- �˗�No�i�[�p�J�E���g
--
    -- �O���[�v1���ڂ̃f�[�^�i�[�p
    first_tran_type           xxwsh_carriers_sort_tmp.transaction_type%TYPE;      -- �������
    first_req_no              xxwsh_carriers_sort_tmp.request_no%TYPE;            -- �˗�/�w��No
    first_ship_date           xxwsh_carriers_sort_tmp.schedule_ship_date%TYPE;    -- �o�ɓ�
    first_arrival_date        xxwsh_carriers_sort_tmp.schedule_arrival_date%TYPE; -- ���ד�
    first_order_type          xxwsh_carriers_sort_tmp.order_type_id%TYPE;         -- �o�Ɍ`��
    first_freight_carrier     xxwsh_carriers_sort_tmp.freight_carrier_code%TYPE;  -- �^���Ǝ�
    first_freight_carrier_id  xxwsh_carriers_sort_tmp.career_id%TYPE;             -- �^���Ǝ�ID
    first_ship_from           xxwsh_carriers_sort_tmp.deliver_from%TYPE;          -- �o�׌�
    first_ship_from_id        xxwsh_carriers_sort_tmp.deliver_from_id%TYPE;       -- �o�׌�ID
    first_ship_to             xxwsh_carriers_sort_tmp.deliver_to%TYPE;            -- �o�א�
    first_ship_to_id          xxwsh_carriers_sort_tmp.deliver_to_id%TYPE;         -- �o�א�ID
    first_w_c_class           xxwsh_carriers_sort_tmp.weight_capacity_class%TYPE; -- �d�ʗe�ϋ敪
    first_head_sales          xxwsh_carriers_sort_tmp.head_sales_branch%TYPE;     -- �Ǌ����_
    first_reserve_order       xxwsh_carriers_sort_tmp.reserve_order%TYPE;         -- ������
--
    ln_grp_sum_cnt            NUMBER DEFAULT 0;                               -- �W��O���[�v�J�E���g
    ln_ship_loop_cnt          NUMBER DEFAULT 0;                               -- ���[�v�J�E���g
    lv_grp_max_ship_methods   xxcmn_ship_methods.ship_method%TYPE;            -- group�ő�z���敪
    ln_drink_deadweight       xxcmn_ship_methods.drink_deadweight%TYPE;       -- �h�����N�ύڏd��
    ln_leaf_deadweight        xxcmn_ship_methods.leaf_deadweight%TYPE;        -- ���[�t�ύڏd��
    ln_drink_loading_capacity xxcmn_ship_methods.drink_loading_capacity%TYPE; -- �h�����N�ύڗe��
    ln_leaf_loading_capacity  xxcmn_ship_methods.leaf_loading_capacity%TYPE;  -- ���[�t�ύڗe��
    ln_palette_max_qty        xxcmn_ship_methods.palette_max_qty%TYPE;        -- �p���b�g�ő喇��
    return_cd                 VARCHAR2(1);                                    -- ���ʊ֐��߂�l
    ln_sum_weight             NUMBER DEFAULT 0;                               -- �W��d��
    ln_sum_capacity           NUMBER DEFAULT 0;                               -- �W��e��
    ln_sum_cnt                NUMBER DEFAULT 0;                               -- �W��σJ�E���g
    ln_loop_cnt_1             NUMBER DEFAULT 0;                               -- ���[�v�J�E���g
    ln_err_cnt                NUMBER DEFAULT 0;                               -- �G���[�J�E���g
    lb_finish_proc            BOOLEAN DEFAULT FALSE;                          -- �����σt���O
    ln_start_no               NUMBER;                                         -- �W��J�nNo
    ln_end_no                 NUMBER;                                         -- �W��I��No
    ln_intensive_no           NUMBER;                                         -- �W��No
    lv_cdkbn_2                VARCHAR2(1);                                    -- �R�[�h�敪�Q
    lv_rerun_flag             VARCHAR2(1) DEFAULT gv_off;                     -- �Ď��s�t���O
    ln_ins_cnt                NUMBER DEFAULT 0;                               -- �C���T�[�g�J�E���g
    ln_end_chk_cnt            NUMBER DEFAULT 0;                               -- �I���m�F�J�E���^
--20080517:DSugahara Add �s�No1
    --�ύڌ����`�F�b�N�֐��p
    lv_loading_over_class       VARCHAR2(1);                         -- �ύڃI�[�o�[�敪
    lv_ship_methods             xxcmn_ship_methods.ship_method%TYPE; -- �o�ו��@
    ln_load_efficiency_weight   xxwsh_carriers_schedule.loading_efficiency_weight%TYPE;   -- �d�ʐύڌ���
    ln_load_efficiency_capacity xxwsh_carriers_schedule.loading_efficiency_capacity%TYPE; -- �e�ϐύڌ���
    lv_mixed_ship_method        xxcmn_ship_methods.ship_method%TYPE; -- ���ڔz���敪
--
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
-- debug
exit_cnt number default 0;
debug_cnt number default 0;
    -- *** �T�u�v���O���� ***
    -- ==========================
    -- �L�[�u���C�N����
    -- ==========================
    PROCEDURE lproc_keybrake_proc_B7(
        ov_errbuf     OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W --# �Œ� #
      , ov_retcode    OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h   --# �Œ� #
      , ov_errmsg     OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
    IS
    -- *** ���[�J���萔 ***
      cv_sub_prg_name   CONSTANT VARCHAR2(100) := '[lproc_keybrake_proc_B7]'; -- �T�u�v���O������
--
    BEGIN
      -- ============================
      -- ����R�[�h�I���m�F
      -- ============================
      -- �L�[�u���C�N���A����R�[�h�����W��̏ꍇ�A�����ςƂ���
      IF (lt_skip_process_tab(ln_start_no) = 0) THEN
--
          -- ����R�[�h�������ςƂ���
          lt_skip_process_tab(ln_start_no) := cv_finish_proc;
--
      END IF;
--
      -- ============================
      -- �o�^�p�e�[�u���ɃZ�b�g
      -- ============================
      -- �C���T�[�g�J�E���g
      ln_ins_cnt := ln_ins_cnt + 1;
--
debug_log(FND_FILE.LOG,'B7_0.01 �C���T�[�g�J�E���g:'||ln_ins_cnt);
--
      -- �W��NO�擾
      SELECT xxwsh_intensive_no_s1.NEXTVAL
      INTO   ln_intensive_no
      FROM   dual;
--
debug_log(FND_FILE.LOG,'B7_0.02 �W��NO�擾:'||ln_intensive_no);
--
      -- �����z�ԏW�񒆊ԃe�[�u���o�^�pPL/SQL�\�ɃZ�b�g
      gt_int_no_tab(ln_ins_cnt)         :=  ln_intensive_no;          -- �W��NO
      gt_tran_type_tab(ln_ins_cnt)      :=  first_tran_type;          -- �������
      gt_int_source_tab(ln_ins_cnt)     :=  first_req_no;             -- �W��No�F�˗�No
      gt_deli_from_tab(ln_ins_cnt)      :=  first_ship_from;          -- �z����
      gt_deli_from_id_tab(ln_ins_cnt)   :=  first_ship_from_id;       -- �z����ID
      gt_deli_to_tab(ln_ins_cnt)        :=  first_ship_to;            -- �z����
      gt_deli_to_id_tab(ln_ins_cnt)     :=  first_ship_to_id;         -- �z����ID
      gt_ship_date_tab(ln_ins_cnt)      :=  first_ship_date;          -- �o�ɗ\���
      gt_arvl_date_tab(ln_ins_cnt)      :=  first_arrival_date;       -- ���ח\���
      gt_tran_type_nm_tab(ln_ins_cnt)   :=  first_order_type;         -- �o�Ɍ`��
      gt_carrier_code_tab(ln_ins_cnt)   :=  first_freight_carrier;    -- �^���Ǝ�
      gt_carrier_id_tab(ln_ins_cnt)     :=  first_freight_carrier_id; -- �^���Ǝ�ID
      gt_sum_weight_tab(ln_ins_cnt)     :=  ln_sum_weight;            -- �W�񍇌v�d��
      gt_sum_capa_tab(ln_ins_cnt)       :=  ln_sum_capacity;          -- �W�񍇌v�e��
      gt_max_ship_cd_tab(ln_ins_cnt)    :=  lv_grp_max_ship_methods;  -- �ő�z���敪
      gt_weight_capa_tab(ln_ins_cnt)    :=  first_w_c_class;          -- �d�ʗe�ϋ敪
      gt_head_sales_tab(ln_ins_cnt)     :=  first_head_sales;         -- �Ǌ����_
      gt_reserve_order_tab(ln_ins_cnt)  :=  first_reserve_order;      -- ������
--
debug_log(FND_FILE.LOG,'(B-7)gt_sum_weight_tab�F'||gt_sum_weight_tab(ln_ins_cnt));
--
debug_log(FND_FILE.LOG,'B7_0.03 �����z�ԏW�񒆊ԃe�[�u���o�^�pPL/SQL�\�ɃZ�b�g');
--
      IF (gv_prod_class = gv_prod_cls_leaf) THEN
debug_log(FND_FILE.LOG,'B7_0.04 ���i�敪�F���[�t');
        -- ���i�敪�F���[�t
        IF (first_w_c_class = gv_weight) THEN
--
          gt_max_weight_tab(ln_ins_cnt) := ln_leaf_deadweight;        -- �ő�ύڏd��
          gt_max_capa_tab(ln_ins_cnt)   := NULL;                      -- �ő�ύڗe��
        ELSE
--
          gt_max_weight_tab(ln_ins_cnt) := NULL;                      -- �ő�ύڏd��
          gt_max_capa_tab(ln_ins_cnt)   := ln_leaf_loading_capacity;  -- �ő�ύڗe��
        END IF;
--
      ELSE
debug_log(FND_FILE.LOG,'B7_0.05 ���i�敪�F�h�����N');
        -- ���i�敪�F�h�����N
        IF (first_w_c_class = gv_weight) THEN
--
          gt_max_weight_tab(ln_ins_cnt) := ln_drink_deadweight;       -- �ő�ύڏd��
          gt_max_capa_tab(ln_ins_cnt)   := NULL;                      -- �ő�ύڗe��
--
        ELSE
--
          gt_max_weight_tab(ln_ins_cnt) := NULL;                      -- �ő�ύڏd��
          gt_max_capa_tab(ln_ins_cnt)   := ln_drink_loading_capacity; -- �ő�ύڗe��
--
        END IF;
--
      END IF;
--
        -- �����z�ԏW�񒆊Ԗ��׃e�[�u���pPL/SQL�\�Ɋi�[
debug_log(FND_FILE.LOG,'B7_0.06 �����z�ԏW�񒆊Ԗ��׃e�[�u���pPL/SQL�\�Ɋi�[');
--debug_log(FND_FILE.LOG,'�f�[�^���F'|| lt_request_no_tab.COUNT);
--debug_log(FND_FILE.LOG,'ln_loop_cnt_1�F'|| ln_loop_cnt_1);
      -- =============================================
      -- �����z�ԏW�񒆊Ԗ��׃e�[�u���pPL/SQL�\�Ɋi�[
      -- =============================================
      <<set_lines_request_id_loop>>
      FOR loop_cnt IN 1..lt_request_no_tab.COUNT LOOP
--
        ln_ins_reqno_cnt := ln_ins_reqno_cnt + 1;
        -- �W��NO
        gt_int_no_lines_tab(ln_ins_reqno_cnt) := ln_intensive_no;
--
        -- �˗�NO
        gt_request_no_tab(ln_ins_reqno_cnt) := lt_request_no_tab(loop_cnt);
debug_log(FND_FILE.LOG,'B7_0.07 �˗�NO�F'|| gt_request_no_tab(loop_cnt));
--
      END LOOP set_lines_request_id_loop;
--
      -- �W�񍇌v�d�ʁA�W�񍇌v�e�ς����Z�b�g
      ln_sum_weight   := 0;
      ln_sum_capacity := 0;
--
      -- �˗�No�ݒ�p�e�[�u���A�J�E���^�����Z�b�g
      lt_request_no_tab.DELETE;
      ln_pre_reqno_cnt := 0;
--
--debug_log(FND_FILE.LOG,'�W�񍇌v�d�ʁA�W�񍇌v�e�ς����Z�b�g');
--
--debug_log(FND_FILE.LOG,'ln_start_no:'||ln_start_no);
--debug_log(FND_FILE.LOG,'ln_end_no:'||ln_end_no);
--
      -- �O���[�v�̑S�f�[�^���W�񂵂����m�F
      <<finish_chk_loop>>
      FOR ln_cnt IN ln_start_no..ln_end_no LOOP
--
debug_log(FND_FILE.LOG,'B7_0.08 �O���[�v�̑S�f�[�^���W�񂵂����m�F');
--
        -- ���W��̃f�[�^���������ꍇ�́A�ēx�A��������
        IF (lt_skip_process_tab(ln_cnt) = 0) THEN
--
debug_log(FND_FILE.LOG,'B7_0.09 �ēx�����F�Ď��s�t���OON');
--
          -- ���[�v�J�E���g�ɏW��J�nNo���Z�b�g����
          ln_loop_cnt_1 := ln_start_no;
          -- �Ď��s�t���O�FON
          lv_rerun_flag := gv_on;
--
debug_log(FND_FILE.LOG,'B7_0.10 Exit finish_chk_loop');
          EXIT;
--
        END IF;
--
      END LOOP finish_chk_loop;
--
    EXCEPTION
      -- *** ���ʊ֐���O�n���h�� ***
      WHEN global_api_expt THEN
debug_log(FND_FILE.LOG,'B7_0.11 global_api_expt');
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||lv_errbuf,1,5000);
        ov_retcode := gv_status_error;
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      WHEN global_api_others_expt THEN
debug_log(FND_FILE.LOG,'B7_0.12 global_api_others_expt');
        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
debug_log(FND_FILE.LOG,'B7_0.13 OTHERS');
        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
--
    END lproc_keybrake_proc_B7;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
debug_log(FND_FILE.LOG,'�y���v�d��/�e�ώ擾 ���Z����(B-7)�z');
--
    -- �ϐ�������
    lt_request_no_tab.DELETE;       -- �˗�No�i�[�p�e�[�u��
    lt_trans_id_tab.DELETE;         -- �g�����U�N�V����ID�i�[�p
    gt_int_no_tab.DELETE;           -- �W��No
    gt_tran_type_tab.DELETE;        -- �������
    gt_int_source_tab.DELETE;       -- �W��No
    gt_deli_from_tab.DELETE;        -- �z����
    gt_deli_from_id_tab.DELETE;     -- �z����ID
    gt_deli_to_tab.DELETE;          -- �z����
    gt_deli_to_id_tab.DELETE;       -- �z����ID
    gt_ship_date_tab.DELETE;        -- �o�ɗ\���
    gt_arvl_date_tab.DELETE;        -- ���ח\���
    gt_tran_type_nm_tab.DELETE;     -- �o�Ɍ`��
    gt_carrier_code_tab.DELETE;     -- �^���Ǝ�
    gt_carrier_id_tab.DELETE;       -- �^���Ǝ�ID
    gt_sum_weight_tab.DELETE;       -- �W�񍇌v�d��
    gt_sum_capa_tab.DELETE;         -- �W�񍇌v�e��
    gt_max_ship_cd_tab.DELETE;      -- �ő�z���敪
    gt_weight_capa_tab.DELETE;      -- �d�ʗe�ϋ敪
    gt_max_weight_tab.DELETE;       -- �ő�ύڏd��
    gt_max_capa_tab.DELETE;         -- �ő�ύڗe��
    gt_base_weight_tab.DELETE;      -- ��{�d��
    gt_base_capa_tab.DELETE;        -- ��{�e��
    gt_reserve_order_tab.DELETE;    -- ������
    gt_head_sales_tab.DELETE;       -- �Ǌ����_
    gt_pre_saved_flg_tab.DELETE;    -- ���_���ړo�^�σt���O
    lt_skip_process_tab.DELETE;     -- �����ΏۊO(������:1�A�ύڌ����I�[�o�[:2)
    gt_int_no_lines_tab.DELETE;     -- �W��No(���חp)
    gt_request_no_tab.DELETE;       -- �˗�No(���חp)
--
debug_log(FND_FILE.LOG,'B7_1.01 ���������F'||it_group_sum_add_tab.COUNT);
    -- �����ΏۊO�e�[�u���̏�����
    IF (it_group_sum_add_tab.COUNT > 0) THEN
debug_log(FND_FILE.LOG,'B7_1.02 �����ΏۊO�e�[�u���̏�����P');
      FOR loop_cnt IN 1..it_group_sum_add_tab.COUNT LOOP
        lt_skip_process_tab(loop_cnt) := 0;
      END LOOP;
--
    END IF;
--
debug_log(FND_FILE.LOG,'loop begin');
debug_log(FND_FILE.LOG,'ln_sum_weight:'|| ln_sum_weight);
--
    <<get_max_ship_cd>>
    LOOP
      -- ���[�v�J�E���g
      ln_loop_cnt_1 := ln_loop_cnt_1 + 1;
--
debug_log(FND_FILE.LOG,'B7_1.03 get_max_ship_cd LOOP');
debug_log(FND_FILE.LOG,'----------------------------------------');
debug_log(FND_FILE.LOG,'���[�v�J�E���g:'|| ln_loop_cnt_1);
--
--debug_log(FND_FILE.LOG,'�˗�No�F'|| it_group_sum_add_tab(ln_loop_cnt_1).req_mov_no);
--debug_log(FND_FILE.LOG,'�����ΏۊO�t���O�F'|| lt_skip_process_tab(ln_loop_cnt_1));
      -- �������Őύڌ����I�[�o�[���Ă��Ȃ��f�[�^�̂ݏ���
      IF (lt_skip_process_tab(ln_loop_cnt_1) = 0) THEN
--
debug_log(FND_FILE.LOG,'B7_1.04 �������Őύڌ����I�[�o�[���Ă��Ȃ��f�[�^�̂ݏ���');
debug_log(FND_FILE.LOG,'�˗�No�F'|| it_group_sum_add_tab(ln_loop_cnt_1).req_mov_no);
--debug_log(FND_FILE.LOG,'�����Ώ�');
--
        -- �O���[�v�J�E���g
        ln_grp_sum_cnt := ln_grp_sum_cnt + 1;
debug_log(FND_FILE.LOG,'�O���[�v�J�E���g�F'||ln_grp_sum_cnt);
--
        -- 1���ڂ̍ő�z���敪���擾����
        IF (ln_grp_sum_cnt = 1) THEN
debug_log(FND_FILE.LOG,'B7_1.05 1���ڂ̍ő�z���敪���擾����');
--
--debug_log(FND_FILE.LOG,'1���ڂ̍ő�z���敪�擾');
--
          -- �X�^�[�gNO���i�[
          ln_start_no := ln_loop_cnt_1;
--debug_log(FND_FILE.LOG,'�X�^�[�gNO�m�ہF'|| ln_start_no);
--
          -- �R�[�h�敪�Q�ݒ�
          IF (it_group_sum_add_tab(ln_loop_cnt_1).tran_type = gv_ship_type_ship) THEN -- �o�׈˗�
            lv_cdkbn_2  :=  gv_cdkbn_ship_to; -- �z����
          ELSE
            lv_cdkbn_2  :=  gv_cdkbn_storage; -- �q��
          END IF;
--
debug_log(FND_FILE.LOG,'B7_1.06 �ő�z���敪�Z�o�֐�Call');
debug_log(FND_FILE.LOG,'�R�[�h�敪1:'||gv_cdkbn_storage);
debug_log(FND_FILE.LOG,'���o�ɏꏊ1:'||it_group_sum_add_tab(ln_loop_cnt_1).ship_from);
debug_log(FND_FILE.LOG,'�R�[�h�敪2:'||lv_cdkbn_2);
debug_log(FND_FILE.LOG,'���o�ɏꏊ2:'||it_group_sum_add_tab(ln_loop_cnt_1).ship_to);
debug_log(FND_FILE.LOG,'���i�敪:'||gv_prod_class);
debug_log(FND_FILE.LOG,'�d�ʗe�ϋ敪:'||it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls);
debug_log(FND_FILE.LOG,'�����z�ԑΏۋ敪:'||cv_object);
debug_log(FND_FILE.LOG,'���:'||to_char(it_group_sum_add_tab(ln_loop_cnt_1).ship_date,'YYYYMMDD'));
--
          -- ���ʊ֐��F�ő�z���敪�Z�o�֐�
          return_cd := xxwsh_common_pkg.get_max_ship_method(
                      iv_code_class1                => gv_cdkbn_storage,          -- �R�[�h�敪1
                      iv_entering_despatching_code1 => it_group_sum_add_tab(ln_loop_cnt_1).ship_from,
                                                                                  -- ���o�ɏꏊ1
                      iv_code_class2                => lv_cdkbn_2,                -- �R�[�h�敪2
                      iv_entering_despatching_code2 => it_group_sum_add_tab(ln_loop_cnt_1).ship_to,
                                                                                  -- ���o�ɏꏊ2
                      iv_prod_class                 => gv_prod_class,             -- ���i�敪
                      iv_weight_capacity_class      => it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls,                      -- �d�ʗe�ϋ敪
                      iv_auto_process_type          => cv_object,                 -- �����z�ԑΏۋ敪
                      id_standard_date              => it_group_sum_add_tab(ln_loop_cnt_1).ship_date,
                                                                                  -- ���
                      ov_max_ship_methods           => lv_grp_max_ship_methods,   -- �ő�z���敪
                      on_drink_deadweight           => ln_drink_deadweight,       -- �h�����N�ύڏd��
                      on_leaf_deadweight            => ln_leaf_deadweight,        -- ���[�t�ύڏd��
                      on_drink_loading_capacity     => ln_drink_loading_capacity, -- �h�����N�ύڗe��
                      on_leaf_loading_capacity      => ln_leaf_loading_capacity,  -- ���[�t�ύڗe��
                      on_palette_max_qty            => ln_palette_max_qty         -- �p���b�g�ő喇��
                      );
--
debug_log(FND_FILE.LOG,'�ő�z���敪:'||lv_grp_max_ship_methods);
debug_log(FND_FILE.LOG,'�h�����N�ύڏd��:'||ln_drink_deadweight);
debug_log(FND_FILE.LOG,'���[�t�ύڏd��:'||ln_leaf_deadweight);
debug_log(FND_FILE.LOG,'�h�����N�ύڗe��:'||ln_drink_loading_capacity);
debug_log(FND_FILE.LOG,'���[�t�ύڗe��:'||ln_leaf_loading_capacity);
debug_log(FND_FILE.LOG,'�p���b�g�ő喇��:'||ln_palette_max_qty);
--
          IF  (return_cd = gv_error)
            OR (lv_grp_max_ship_methods IS NULL)
          THEN
--
debug_log(FND_FILE.LOG,'B7_1.07 �ő�z���敪�Z�o�֐���O');
            -- �G���[���b�Z�[�W�擾
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_xxwsh                      -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                         , gv_msg_xxwsh_11802            -- �ő�z���敪�擾�G���[
                         , gv_tkn_from                   -- �g�[�N��'FROM'
                         , it_group_sum_add_tab(ln_loop_cnt_1).ship_from
                                                         -- ���o�ɏꏊ1
                         , gv_tkn_to                     -- �g�[�N��'TO'
                         , it_group_sum_add_tab(ln_loop_cnt_1).ship_to
                                                        -- ���o�ɏꏊ2
                         , gv_tkn_codekbn1               -- �g�[�N��'CODEKBN1'
                         , gv_cdkbn_storage              -- �R�[�h�敪1
                         , gv_tkn_codekbn2               -- �g�[�N��'CODEKBN2'
                         , gv_cdkbn_ship_to              -- �R�[�h�敪2
                        ) ,1 ,5000);
--
             RAISE global_api_expt;
--
          END IF;
--debug_log(FND_FILE.LOG,'�ő�z���敪�擾�F'|| lv_grp_max_ship_methods);
--
          -- �O���[�v1���ڃf�[�^��ێ�
          first_tran_type           := it_group_sum_add_tab(ln_loop_cnt_1).tran_type;
                                                                                -- �������
          first_req_no              := it_group_sum_add_tab(ln_loop_cnt_1).req_mov_no;
                                                                                -- �˗�No/�w��No
          first_ship_date           := it_group_sum_add_tab(ln_loop_cnt_1).ship_date;
                                                                                -- �o�ɓ�
          first_arrival_date        := it_group_sum_add_tab(ln_loop_cnt_1).arrival_date;
                                                                                -- ���ד�
          first_order_type          := it_group_sum_add_tab(ln_loop_cnt_1).order_type_id;
                                                                                -- �o�Ɍ`��
          first_freight_carrier     := it_group_sum_add_tab(ln_loop_cnt_1).carrier_code;
                                                                                -- �z���Ǝ�
          first_freight_carrier_id  := it_group_sum_add_tab(ln_loop_cnt_1).carrier_id;
                                                                                -- �z���Ǝ�ID
          first_ship_from           := it_group_sum_add_tab(ln_loop_cnt_1).ship_from;
                                                                                -- �o�׌�
          first_ship_from_id        := it_group_sum_add_tab(ln_loop_cnt_1).ship_from_id;
                                                                                -- �o�׌�ID
          first_ship_to             := it_group_sum_add_tab(ln_loop_cnt_1).ship_to;
                                                                                -- �o�א�
          first_ship_to_id          := it_group_sum_add_tab(ln_loop_cnt_1).ship_to_id;
                                                                                -- �o�א�ID
          first_w_c_class           := it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls;
                                                                                -- �d�ʗe�ϋ敪
          first_head_sales          := it_group_sum_add_tab(ln_loop_cnt_1).head_sales_branch;
                                                                                -- �Ǌ����_
          first_reserve_order       := it_group_sum_add_tab(ln_loop_cnt_1).reserve_order;
                                                                                -- ������
--
          -- ��r�p�ϐ��Ɋi�[
          lt_prev_ship_date       := it_group_sum_add_tab(ln_loop_cnt_1).ship_date; -- �o�ɓ�
          lt_prev_arrival_date    := it_group_sum_add_tab(ln_loop_cnt_1).arrival_date;
                                                                                    -- ���ד�
          lt_prev_order_type      := it_group_sum_add_tab(ln_loop_cnt_1).order_type_id;
                                                                                    -- �o�Ɍ`��
          lt_prev_freight_carrier := it_group_sum_add_tab(ln_loop_cnt_1).carrier_code;
                                                                                    -- �z���Ǝ�
          lt_prev_ship_from       := it_group_sum_add_tab(ln_loop_cnt_1).ship_from; -- �o�׌�
          lt_prev_ship_to         := it_group_sum_add_tab(ln_loop_cnt_1).ship_to;   -- �o�א�
          lt_prev_w_c_class       := it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls;
                                                                                    -- �d�ʗe�ϋ敪
debug_log(FND_FILE.LOG,'B7_1.08 ����R�[�h�ێ�');
--
        END IF;
--
debug_log(FND_FILE.LOG,'B7_1.09 �L�[�u���C�N���Ȃ� �O');
        -- �L�[�u���C�N���Ȃ�
        IF  (lt_prev_ship_date       = it_group_sum_add_tab(ln_loop_cnt_1).ship_date)
                                                                                  -- �o�ɓ�
          AND (lt_prev_arrival_date    = it_group_sum_add_tab(ln_loop_cnt_1).arrival_date)
                                                                                  -- ���ד�
          AND (NVL(lt_prev_order_type,0)      = NVL(it_group_sum_add_tab(ln_loop_cnt_1).order_type_id, 0))
                                                                                  -- �o�Ɍ`��
          AND (NVL(lt_prev_freight_carrier,0) = NVL(it_group_sum_add_tab(ln_loop_cnt_1).carrier_code, 0))
                                                                                  -- �z���Ǝ�
          AND (NVL(lt_prev_ship_from,0)       = NVL(it_group_sum_add_tab(ln_loop_cnt_1).ship_from, 0))
                                                                                  -- �o�׌�
          AND (NVL(lt_prev_ship_to,0)         = NVL(it_group_sum_add_tab(ln_loop_cnt_1).ship_to, 0))
                                                                                  -- �o�א�
          AND (NVL(lt_prev_w_c_class,0)       = NVL(it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls, 0))
                                                                                  -- �d�ʗe�ϋ敪
        THEN
--
debug_log(FND_FILE.LOG,'B7_1.10 �L�[�u���C�N�Ȃ�');
          --========================================
          -- �ύڌ����I�[�o�[�`�F�b�N(�ړ��w���̂�)
          --========================================
          IF (it_group_sum_add_tab(ln_loop_cnt_1).tran_type = gv_ship_type_move) THEN -- �ړ��w��
--
debug_log(FND_FILE.LOG,'B7_1.11 �ύڌ����I�[�o�[�`�F�b�N(�ړ��w���̂�)');
--
            -- �d�ʂ̏ꍇ
            IF (it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls = gv_weight) THEN
--
--20080517:DSugahara �s�No1�Ή�->
--              IF (it_group_sum_add_tab(ln_loop_cnt_1).based_weight <  -- ��{�d��
--                  it_group_sum_add_tab(ln_loop_cnt_1).sum_weight)     -- �ύڏd�ʍ��v
--              THEN
              -- ���ʊ֐��F�ύڌ����`�F�b�N(�ύڌ���)
              xxwsh_common910_pkg.calc_load_efficiency(
                  in_sum_weight                  => 
                        it_group_sum_add_tab(ln_loop_cnt_1).sum_weight        -- 1.���v�d��
                , in_sum_capacity                => NULL                      -- 2.���v�e��
                , iv_code_class1                 => gv_cdkbn_storage          -- 3.�R�[�h�敪�P
                , iv_entering_despatching_code1  => 
                        it_group_sum_add_tab(ln_loop_cnt_1).ship_from         -- 4.���o�ɏꏊ�R�[�h�P
                , iv_code_class2                 => lv_cdkbn_2                -- 5.�R�[�h�敪�Q
                , iv_entering_despatching_code2  => 
                        it_group_sum_add_tab(ln_loop_cnt_1).ship_to           -- 6.���o�ɏꏊ�R�[�h�Q
                , iv_ship_method                 => 
                        it_group_sum_add_tab(ln_loop_cnt_1).max_shipping_method -- 7.�o�ו��@
                , iv_prod_class                  => gv_prod_class             -- 8.���i�敪
                , iv_auto_process_type           => cv_object                 -- 9.�����z�ԑΏۋ敪
                , id_standard_date               => 
                        it_group_sum_add_tab(ln_loop_cnt_1).ship_date         -- 10.���(�K�p�����)
                , ov_retcode                     => lv_retcode                -- 11.���^�[���R�[�h
                , ov_errmsg_code                 => lv_errmsg                 -- 12.�G���[���b�Z�[�W�R�[�h
                , ov_errmsg                      => lv_errbuf                 -- 13.�G���[���b�Z�[�W
                , ov_loading_over_class          => lv_loading_over_class     -- 14.�ύڃI�[�o�[�敪
                , ov_ship_methods                => lv_ship_methods           -- 15.�o�ו��@
                , on_load_efficiency_weight      => ln_load_efficiency_weight -- 16.�d�ʐύڌ���
                , on_load_efficiency_capacity    => ln_load_efficiency_capacity
                                                                              -- 17.�e�ϐύڌ���
                , ov_mixed_ship_method           => lv_mixed_ship_method      -- 18.���ڔz���敪
              );
              -- ���ʊ֐����G���[�̏ꍇ
-- Ver1.7 M.Hokkanji START
              IF (lv_retcode <> gv_status_normal) THEN
--              IF (lv_retcode = gv_status_error) THEN
-- Ver1.16 2008/12/07 START
--          lv_errmsg := lv_errbuf;
--        IF (lv_retcode = gv_status_error) THEN
--          lv_errmsg := lv_errbuf;
        BEGIN
          lv_errmsg  :=  it_group_sum_add_tab(ln_loop_cnt_1).sum_weight -- 1.���v�d��
                          || gv_msg_comma ||
                          NULL                -- 2.���v�e��
                          || gv_msg_comma ||
                          gv_cdkbn_storage    -- 3.�R�[�h�敪�P
                          || gv_msg_comma ||
                          it_group_sum_add_tab(ln_loop_cnt_1).ship_from  -- 4.���o�ɏꏊ�R�[�h�P
                          || gv_msg_comma ||
                          lv_cdkbn_2      -- 5.�R�[�h�敪�Q
                          || gv_msg_comma ||
                          it_group_sum_add_tab(ln_loop_cnt_1).ship_to    -- 6.���o�ɏꏊ�R�[�h�Q
                          || gv_msg_comma ||
                          it_group_sum_add_tab(ln_loop_cnt_1).max_shipping_method -- 7.�o�ו��@
                          || gv_msg_comma ||
                          gv_prod_class       -- 8.���i�敪
                          || gv_msg_comma ||
                          cv_object       -- 9.�����z�ԑΏۋ敪
                          || gv_msg_comma ||
                          TO_CHAR(it_group_sum_add_tab(ln_loop_cnt_1).ship_date, 'YYYY/MM/DD'); -- 10.���
          lv_errmsg := lv_errmsg|| '(�d��,�e��,�R�[�h�敪1,�R�[�h1,�R�[�h�敪2,�R�[�h2';
          lv_errmsg := lv_errmsg|| ',�z���敪,���i�敪,�����z�ԑΏۋ敪,���'; -- msg
          lv_errmsg := lv_errbuf ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := lv_errbuf ;
        END;
-- Ver1.16 2008/12/07 End
-- Ver1.7 M.Hokkanji End
debug_log(FND_FILE.LOG,'B7_1.111�@�ړ��ύڌ����I�[�o�[�`�F�b�N�֐��G���[(�d��)');
                RAISE global_api_expt;
              END IF;
--
              -- �ύڃI�[�o�[�̏ꍇ
              IF (lv_loading_over_class = cv_loading_over) THEN
--20080517:DSugahara �s�No1�Ή�<-
--
                ln_err_cnt := ln_err_cnt + 1;
--
                -- �����ΏۊO�e�[�u���ɐύڃI�[�o�[��ݒ�
                lt_skip_process_tab(ln_loop_cnt_1) := cv_over_loading;
debug_log(FND_FILE.LOG,'B7_1.12 �ύڃI�[�o�[�d�ʂ̏ꍇlt_skip_process_tab:'||lt_skip_process_tab(ln_loop_cnt_1));
debug_log(FND_FILE.LOG,'first_req_no:'|| first_req_no);
--
                -- �ύڃI�[�o�[�Ώۃt���O�ݒ�
                lb_over_loading := TRUE;
--
                -- �G���[���b�Z�[�W�擾
                lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                              gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                            , gv_msg_xxwsh_11803  -- ���b�Z�[�W�FAPP-XXWSH-11803 �ύڃI�[�o�[���b�Z�[�W
                            , gv_tkn_req_no       -- �g�[�N���FREQ_NO
                            , it_group_sum_add_tab(ln_loop_cnt_1).req_mov_no
                                                  -- �ړ��ԍ�
                           ),1,5000);
--
                -- �G���[���b�Z�[�W�o��
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--2008.06.05 K.Yamane
                ln_grp_sum_cnt := 0;
--
              END IF;
--
            -- �e�ς̏ꍇ
            ELSIF (it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls = gv_capacity) THEN
--
debug_log(FND_FILE.LOG,'B7_1.13.0 ��{�e��:'||it_group_sum_add_tab(ln_loop_cnt_1).based_capacity);
debug_log(FND_FILE.LOG,'B7_1.13.0 �ύڗe�ύ��v:'||it_group_sum_add_tab(ln_loop_cnt_1).sum_capacity);
--
--
--20080517:DSugahara �s�No1�Ή�->
--              IF (it_group_sum_add_tab(ln_loop_cnt_1).based_capacity <  -- ��{�e��
--                  it_group_sum_add_tab(ln_loop_cnt_1).sum_capacity)     -- �ύڗe�ύ��v
--              THEN
              -- ���ʊ֐��F�ύڌ����`�F�b�N(�ύڌ���)
              xxwsh_common910_pkg.calc_load_efficiency(
                  in_sum_weight                  => NULL                      -- 1.���v�d��
                , in_sum_capacity                => 
                        it_group_sum_add_tab(ln_loop_cnt_1).sum_capacity      -- 2.���v�e��
                , iv_code_class1                 => gv_cdkbn_storage          -- 3.�R�[�h�敪�P
                , iv_entering_despatching_code1  => 
                        it_group_sum_add_tab(ln_loop_cnt_1).ship_from         -- 4.���o�ɏꏊ�R�[�h�P
                , iv_code_class2                 => lv_cdkbn_2                -- 5.�R�[�h�敪�Q
                , iv_entering_despatching_code2  => 
                        it_group_sum_add_tab(ln_loop_cnt_1).ship_to           -- 6.���o�ɏꏊ�R�[�h�Q
                , iv_ship_method                 => 
                        it_group_sum_add_tab(ln_loop_cnt_1).max_shipping_method -- 7.�o�ו��@
                , iv_prod_class                  => gv_prod_class             -- 8.���i�敪
                , iv_auto_process_type           => cv_object                 -- 9.�����z�ԑΏۋ敪
                , id_standard_date               => 
                        it_group_sum_add_tab(ln_loop_cnt_1).ship_date         -- 10.���(�K�p�����)
                , ov_retcode                     => lv_retcode                -- 11.���^�[���R�[�h
                , ov_errmsg_code                 => lv_errmsg                 -- 12.�G���[���b�Z�[�W�R�[�h
                , ov_errmsg                      => lv_errbuf                 -- 13.�G���[���b�Z�[�W
                , ov_loading_over_class          => lv_loading_over_class     -- 14.�ύڃI�[�o�[�敪
                , ov_ship_methods                => lv_ship_methods           -- 15.�o�ו��@
                , on_load_efficiency_weight      => ln_load_efficiency_weight -- 16.�d�ʐύڌ���
                , on_load_efficiency_capacity    => ln_load_efficiency_capacity
                                                                              -- 17.�e�ϐύڌ���
                , ov_mixed_ship_method           => lv_mixed_ship_method      -- 18.���ڔz���敪
              );
              -- ���ʊ֐����G���[�̏ꍇ
-- Ver1.7 M.Hokkanji START
              IF (lv_retcode <> gv_status_normal) THEN
--              IF (lv_retcode = gv_status_error) THEN
-- Ver1.16 2008/12/07 START
--          lv_errmsg := lv_errbuf;
          lv_errmsg  :=  NULL -- 1.���v�d��
                          || gv_msg_comma ||
                          it_group_sum_add_tab(ln_loop_cnt_1).sum_capacity                -- 2.���v�e��
                          || gv_msg_comma ||
                          gv_cdkbn_storage    -- 3.�R�[�h�敪�P
                          || gv_msg_comma ||
                          it_group_sum_add_tab(ln_loop_cnt_1).ship_from  -- 4.���o�ɏꏊ�R�[�h�P
                          || gv_msg_comma ||
                          lv_cdkbn_2      -- 5.�R�[�h�敪�Q
                          || gv_msg_comma ||
                          it_group_sum_add_tab(ln_loop_cnt_1).ship_to    -- 6.���o�ɏꏊ�R�[�h�Q
                          || gv_msg_comma ||
                          it_group_sum_add_tab(ln_loop_cnt_1).max_shipping_method -- 7.�o�ו��@
                          || gv_msg_comma ||
                          gv_prod_class       -- 8.���i�敪
                          || gv_msg_comma ||
                          cv_object       -- 9.�����z�ԑΏۋ敪
                          || gv_msg_comma ||
                          TO_CHAR( it_group_sum_add_tab(ln_loop_cnt_1).ship_date, 'YYYY/MM/DD'); -- 10.���
          lv_errmsg := lv_errmsg|| '(�d��,�e��,�R�[�h�敪1,�R�[�h1,�R�[�h�敪2,�R�[�h2';
          lv_errmsg := lv_errmsg|| ',�z���敪,���i�敪,�����z�ԑΏۋ敪,���'; -- msg
          lv_errmsg := lv_errmsg||lv_errbuf ;
-- Ver1.16 2008/12/07 End          
-- Ver1.7 M.Hokkanji End
debug_log(FND_FILE.LOG,'B7_1.131�@�ړ��ύڌ����I�[�o�[�`�F�b�N�֐��G���[(�e��)');
                RAISE global_api_expt;
              END IF;
--
              -- �ύڃI�[�o�[�̏ꍇ
              IF (lv_loading_over_class = cv_loading_over) THEN
--20080517:DSugahara �s�No1�Ή�<-
--
                ln_err_cnt := ln_err_cnt + 1;
--
                -- �����ΏۊO�e�[�u���ɐύڃI�[�o�[��ݒ�
                lt_skip_process_tab(ln_loop_cnt_1) := cv_over_loading;
debug_log(FND_FILE.LOG,'B7_1.13 �ύڃI�[�o�[�e�ς̏ꍇlt_skip_process_tab:'||lt_skip_process_tab(ln_loop_cnt_1));
debug_log(FND_FILE.LOG,'first_req_no:'|| first_req_no);
--
                -- �ύڃI�[�o�[�Ώۃt���O�ݒ�
                lb_over_loading := TRUE;
--
                -- �G���[���b�Z�[�W�擾
                lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                              gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                            , gv_msg_xxwsh_11803  -- ���b�Z�[�W�FAPP-XXWSH-11803 �ύڃI�[�o�[���b�Z�[�W
                            , gv_tkn_req_no       -- �g�[�N���FREQ_NO
                            , it_group_sum_add_tab(ln_loop_cnt_1).req_mov_no    -- �ړ��ԍ�
                           ),1,5000);
--
                -- �G���[���b�Z�[�W�o��
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--2008.06.05 K.Yamane
                ln_grp_sum_cnt := 0;
--
              END IF;
--
            END IF;
--
          END IF;
--
--if (lb_over_loading) then
--debug_log(FND_FILE.LOG,'�ύڌ����I�[�o�[:TRUE');
--else
--debug_log(FND_FILE.LOG,'�ύڌ����I�[�o�[:FALSE');
--end if;

          -- �ύڌ����I�[�o�[���Ă��Ȃ�
--          IF (lb_over_loading = FALSE) THEN
          IF ( lt_skip_process_tab(ln_loop_cnt_1) != cv_over_loading ) THEN
--
--debug_log(FND_FILE.LOG,'�ύڌ����I�[�o�[�Ȃ�');
            --======================================
            -- B-7.���v�d�ʁ^�e�ώ擾 ���Z����
            --======================================
debug_log(FND_FILE.LOG,'B7_1.14 ���v�d�ʁ^�e�ώ擾 ���Z����');
            lb_finish_proc := TRUE;
--
            -- �d�ʂ̏ꍇ
            IF (it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls = gv_weight) THEN
--
debug_log(FND_FILE.LOG,'B7_1.14.2 ln_sum_weight�F'|| ln_sum_weight);
debug_log(FND_FILE.LOG,'B7_1.14.2 sum_weight�F'|| it_group_sum_add_tab(ln_loop_cnt_1).sum_weight);
debug_log(FND_FILE.LOG,'B7_1.14.2 sum_pallet_weight�F'|| it_group_sum_add_tab(ln_loop_cnt_1).sum_pallet_weight);
--
              -- �W�񂷂�
              ln_sum_weight := ln_sum_weight
                              + NVL(it_group_sum_add_tab(ln_loop_cnt_1).sum_weight,0)
                                                                                -- �ύڏd�ʍ��v
                              + NVL(it_group_sum_add_tab(ln_loop_cnt_1).sum_pallet_weight,0);
                                                                                -- ���v�p���b�g�d��
--
debug_log(FND_FILE.LOG,'B7_1.14.2 �ύڏd�ʍ��v�F'|| ln_sum_weight);
--
            ELSE  -- �e��
--
              -- �W�񂷂�
              ln_sum_capacity := ln_sum_capacity
                                + NVL(it_group_sum_add_tab(ln_loop_cnt_1).sum_capacity,0);
                                                                                -- �ύڗe�ύ��v
--
debug_log(FND_FILE.LOG,'B7_1.14.2 �ύڗe�ύ��v���Z�F'|| ln_sum_capacity);
--
            END IF;
--
            --======================================
            -- �ύڏd�ʃI�[�o�[�`�F�b�N
            --======================================
debug_log(FND_FILE.LOG,'B7_1.15 �ύڏd�ʃI�[�o�[�`�F�b�N');
            IF (gv_prod_class = gv_prod_cls_leaf) THEN  -- ���i�敪�F���[�t
--
debug_log(FND_FILE.LOG,'B7_1.16 ���i�敪�F���[�t');
--
              IF (it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls = gv_weight) THEN -- �d��
--
debug_log(FND_FILE.LOG,'B7_1.17 �d��');
--
                IF (ln_leaf_deadweight < ln_sum_weight) THEN  -- ���[�t�ύڏd��
debug_log(FND_FILE.LOG,'B7_1.18 ���Z������');
                  -- ���Z������߂�
                  ln_sum_weight := ln_sum_weight
                                  - NVL(it_group_sum_add_tab(ln_loop_cnt_1).sum_weight,0)
                                                                              -- �ύڏd�ʍ��v
                                  - NVL(it_group_sum_add_tab(ln_loop_cnt_1).sum_pallet_weight,0);
                                                                              -- ���v�p���b�g�d��
--
                  -- �W��σt���O
                  lb_finish_proc := FALSE; -- ���W��
--
--
debug_log(FND_FILE.LOG,'B7_1.18 �ύڏd�ʍ��v�F'|| ln_sum_weight);
                END IF;
--
              ELSE
--
debug_log(FND_FILE.LOG,'B7_1.19 �e��');
                IF (ln_leaf_loading_capacity < ln_sum_capacity) THEN  -- ���[�t�ύڗe��
debug_log(FND_FILE.LOG,'B7_1.20 ���Z������');
                  -- ���Z������߂�
                  ln_sum_capacity := ln_sum_capacity
                                  - NVL(it_group_sum_add_tab(ln_loop_cnt_1).sum_capacity,0);
                                                                              -- �ύڗe�ύ��v
--
                  -- �W��σt���O
                  lb_finish_proc := FALSE; -- ���W��
--
                END IF;
--
              END IF;
--
            ELSIF (gv_prod_class = gv_prod_cls_drink) THEN  -- ���i�敪�F�h�����N
--
debug_log(FND_FILE.LOG,'B7_1.21 ���i�敪�F�h�����N');
--
              IF (it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls = gv_weight) THEN -- �d��
--
debug_log(FND_FILE.LOG,'B7_1.22 �d��');
--
                IF (ln_drink_deadweight < ln_sum_weight) THEN  -- �h�����N�ύڏd��
debug_log(FND_FILE.LOG,'B7_1.23 ���Z������');
                  -- ���Z������߂�
                  ln_sum_weight := ln_sum_weight
                                  - NVL(it_group_sum_add_tab(ln_loop_cnt_1).sum_weight,0)
                                                                              -- �ύڏd�ʍ��v
                                  - NVL(it_group_sum_add_tab(ln_loop_cnt_1).sum_pallet_weight,0);
                                                                              -- ���v�p���b�g�d��
--
                  -- �W��σt���O
                  lb_finish_proc := FALSE; -- ���W��
--
debug_log(FND_FILE.LOG,'B7_1.23 �ύڏd�ʍ��v�F'|| ln_sum_weight);
--
                END IF;
--
              ELSE
--
debug_log(FND_FILE.LOG,'B7_1.24 �e��');
--
                IF (ln_drink_loading_capacity < ln_sum_capacity) THEN  -- �h�����N�ύڗe��
debug_log(FND_FILE.LOG,'B7_1.25.1 �ő�e�ρ��ύڗe�ϏW�v�F'||ln_drink_loading_capacity||'��'||ln_sum_capacity);
debug_log(FND_FILE.LOG,'B7_1.25.2 ���Z������');
                  -- ���Z������߂�
                  ln_sum_capacity := ln_sum_capacity
                                  - NVL(it_group_sum_add_tab(ln_loop_cnt_1).sum_capacity,0);
                                                                              -- �ύڏd�ʍ��v
--
                  -- �W��σt���O
                  lb_finish_proc := FALSE; -- ���W��
--
                END IF;
--
              END IF;
--
            END IF;
--
            IF (lb_finish_proc) THEN  -- �W��σt���O�F�W���
--
debug_log(FND_FILE.LOG,'B7_1.26 lt_skip_process_tab(����R�[�h):'||lt_skip_process_tab(ln_start_no));
--
              IF (lt_skip_process_tab(ln_start_no) = 0) THEN
                -- ����R�[�h�̏W��σt���O(�ΏۊO)���Z�b�g����
                lt_skip_process_tab(ln_loop_cnt_1) := cv_finish_proc;
--
              END IF;
--
              -- ��r���R�[�h�̏W��σt���O(�ΏۊO)���Z�b�g����
              lt_skip_process_tab(ln_loop_cnt_1) := cv_finish_proc;
debug_log(FND_FILE.LOG,'B7_1.27 lt_skip_process_tab:'||lt_skip_process_tab(ln_loop_cnt_1));
--
--debug_log(FND_FILE.LOG,'�W��σt���O���Z�b�g');
--
              -- �˗�No�i�[�p�J�E���^
              ln_pre_reqno_cnt := ln_pre_reqno_cnt + 1;
--
              -- �˗�No���i�[
              lt_request_no_tab(ln_pre_reqno_cnt)  := it_group_sum_add_tab(ln_loop_cnt_1).req_mov_no;
debug_log(FND_FILE.LOG,'B7_1.28 �˗�No�F'||lt_request_no_tab(ln_pre_reqno_cnt));
--
              -- �����σt���O��������
              lb_finish_proc := FALSE;
--
--debug_log(FND_FILE.LOG,'�����σt���O��������');
--
            END IF;
--
--
          END IF;
--
        -- �L�[�u���C�N�����ꍇ
        ELSE
--
debug_log(FND_FILE.LOG,'B7_1.30 �L�[�u���C�N');
--
          -- �I�����J�E���g���i�[
          ln_end_no := ln_loop_cnt_1 - 1;
--
debug_log(FND_FILE.LOG,'B7_1.31 �I�����J�E���g�i�[:'|| ln_end_no);
debug_log(FND_FILE.LOG,'first_req_no:'|| first_req_no);
--
          -- ==============================
          -- �L�[�u���C�N����
          -- ==============================
          lproc_keybrake_proc_B7(
              ov_errbuf      => lv_errbuf
            , ov_retcode     => lv_retcode
            , ov_errmsg      => lv_errmsg
          );
          -- �������G���[�̏ꍇ
          IF (lv_retcode = gv_status_error) THEN
debug_log(FND_FILE.LOG,'B7_1.32 �L�[�u���C�N������O');
            RAISE global_api_expt;
          END IF;
--
          -- ���̃O���[�v�̏����Ɉڍs
          IF (lv_rerun_flag = gv_off) THEN
debug_log(FND_FILE.LOG,'B7_1.33 ���O���[�v�̏����Ɉڍs');
--
              -- �L�[�u���C�N�������R�[�h���ēǍ����邽�߃��[�v�J�E���g��߂�
              ln_loop_cnt_1 := ln_loop_cnt_1 - 1;
--
              -- �O���[�v�J�E���g�����Z�b�g����
              ln_grp_sum_cnt := 0;
--
          ELSIF (lv_rerun_flag = gv_on) THEN
debug_log(FND_FILE.LOG,'B7_1.34 ���O���[�v�̏����Ɉڍs���Ȃ�');
            -- ����L�[�O���[�v���̖������̃f�[�^����������
            -- ���[�v�J�E���^���X�^�[�g�ɖ߂�
            ln_loop_cnt_1 := ln_start_no - 1;
--
            -- �O���[�v�J�E���g�����Z�b�g����
            ln_grp_sum_cnt := 0;
--
          END IF;
debug_log(FND_FILE.LOG,'B7_1.35 ��r�p�ϐ��Ɋi�[ ln_loop_cnt_1='|| to_char(ln_loop_cnt_1));
debug_log(FND_FILE.LOG,'B7_1.351 ��r�p�ϐ�Count ='|| to_char(it_group_sum_add_tab.count));
--
          IF (ln_loop_cnt_1 > 0) THEN
--
            -- ��r�p�ϐ��Ɋi�[
            lt_prev_ship_date       := it_group_sum_add_tab(ln_loop_cnt_1).ship_date;   -- �o�ɓ�
            lt_prev_arrival_date    := it_group_sum_add_tab(ln_loop_cnt_1).arrival_date;
                                                                                        -- ���ד�
            lt_prev_order_type      := it_group_sum_add_tab(ln_loop_cnt_1).order_type_id;
                                                                                        -- �o�Ɍ`��
            lt_prev_freight_carrier := it_group_sum_add_tab(ln_loop_cnt_1).carrier_code;
                                                                                        -- �z���Ǝ�
            lt_prev_ship_from       := it_group_sum_add_tab(ln_loop_cnt_1).ship_from;   -- �o�׌�
            lt_prev_ship_to         := it_group_sum_add_tab(ln_loop_cnt_1).ship_to;     -- �o�א�
            lt_prev_w_c_class       := it_group_sum_add_tab(ln_loop_cnt_1).weight_capacity_cls;
--
          END IF;
--
        END IF;
debug_log(FND_FILE.LOG,'B7_1.36');
--
      END IF; -- �������f�[�^�̂ݑΏ�
--
--if (lb_last_data_flag) then
--debug_log(FND_FILE.LOG,'�ŏI���R�[�h�t���O�FTRUE');
--else
--debug_log(FND_FILE.LOG,'�ŏI���R�[�h�t���O�FFALSE');
--end if;
debug_log(FND_FILE.LOG,'B7_1.36.1 ln_loop_cnt_1�F'|| ln_loop_cnt_1);
      -- ==============================
      -- �ŏI���R�[�h����
      -- ==============================
      IF (ln_loop_cnt_1 >= it_group_sum_add_tab.COUNT)  -- �J�E���g�F�ŏI���R�[�h
--        AND (lb_last_data_flag = FALSE)             -- �ŏI���R�[�h�t���O FALSE
      THEN
debug_log(FND_FILE.LOG,'B7_1.37 �ŏI���R�[�h����');
--
        -- �I�����J�E���g���i�[
        ln_end_no := ln_loop_cnt_1;
debug_log(FND_FILE.LOG,'�y�ŏI���R�[�h�����z');
--
debug_log(FND_FILE.LOG,'�I�����J�E���g�i�[:'|| ln_loop_cnt_1);
debug_log(FND_FILE.LOG,'first_req_no:'|| first_req_no);
--
        -- ==============================
        -- �L�[�u���C�N����
        -- ==============================
        lproc_keybrake_proc_B7(
            ov_errbuf      => lv_errbuf
          , ov_retcode     => lv_retcode
          , ov_errmsg      => lv_errmsg
        );
        -- �������G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
debug_log(FND_FILE.LOG,'B7_1.38 �ŏI���R�[�h���� �L�[�u���C�N������O');
          RAISE global_api_expt;
        END IF;
--
--debug_log(FND_FILE.LOG,'�ēx�����F'||lv_rerun_flag);
--
        -- �Ď��s�t���O�FOFF
        IF lv_rerun_flag = gv_off THEN
debug_log(FND_FILE.LOG,'B7_1.39 �����I��');
          EXIT;
--
        ELSIF lv_rerun_flag = gv_on THEN
          -- ����L�[�O���[�v���̖������̃f�[�^����������
          -- ���[�v�J�E���^���X�^�[�g�ɖ߂�
debug_log(FND_FILE.LOG,'B7_1.40  �����I��');
          ln_loop_cnt_1 := ln_start_no - 1;
--
          -- �O���[�v�J�E���g�����Z�b�g����
          ln_grp_sum_cnt := 0;
--
        END IF;
--
        -- �ŏI�f�[�^�t���O���Z�b�g
        lb_last_data_flag := TRUE;
--debug_log(FND_FILE.LOG,'�ŏI�f�[�^�t���O���Z�b�g');
        --============================
        -- �I���`�F�b�N
        --============================
        ln_end_chk_cnt := 0;
--
        FOR end_chk IN 1..lt_skip_process_tab.COUNT LOOP
  debug_log(FND_FILE.LOG,'B7_1.41 �I���`�F�b�N');
--
          IF (lt_skip_process_tab(end_chk) = 0) THEN
--
            ln_end_chk_cnt := ln_end_chk_cnt + 1;
--
          END IF;
--
        END LOOP;
--
        IF ln_end_chk_cnt = 0 THEN
  debug_log(FND_FILE.LOG,'B7_1.42 �I��');
          -- �I��
          EXIT;
--
        END IF;
      END IF;
--
    END LOOP get_max_ship_cd;
--
    --�ړ��ύڃI�[�o�[����̏ꍇ
    IF ( lb_over_loading ) THEN          
debug_log(FND_FILE.LOG,'B7_1.43 �ړ��ύڃI�[�o�[����̏ꍇ�x��');
      ov_retcode := gv_status_warn; --�x��
      gn_warn_cnt := NVL(gn_warn_cnt,0) + NVL(ln_err_cnt,0);
    END IF;
--
debug_log(FND_FILE.LOG,'���v�d��/�e�ώ擾 ���Z�����I��');
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
  END set_weight_capacity_add;
--
  /**********************************************************************************
   * Procedure Name   : ins_intensive_carriers_tmp
   * Description      : �W�񒆊ԃe�[�u���o�͏���(B-8)
   ***********************************************************************************/
  PROCEDURE ins_intensive_carriers_tmp(
    ov_errbuf   OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_intensive_carriers_tmp'; -- �v���O������
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
debug_log(FND_FILE.LOG,'�y�W�񒆊ԃe�[�u���o�͏���(B-8)�z');
debug_log(FND_FILE.LOG,'�W�񌏐�  �F'||gt_int_no_tab.count);
debug_log(FND_FILE.LOG,'������ʌ����F'||gt_tran_type_tab.count);
debug_log(FND_FILE.LOG,'�W�񌳌����F'||gt_int_source_tab.count);
debug_log(FND_FILE.LOG,'�z���������F'||gt_deli_from_tab.count);
debug_log(FND_FILE.LOG,'�z����ID�����F'||gt_deli_from_id_tab.count);
debug_log(FND_FILE.LOG,'�z���挏���F'||gt_deli_to_tab.count);
debug_log(FND_FILE.LOG,'�z����ID�����F'||gt_deli_to_id_tab.count);
debug_log(FND_FILE.LOG,'�o�ɗ\��������F'||gt_ship_date_tab.count);
debug_log(FND_FILE.LOG,'���ח\��������F'||gt_arvl_date_tab.count);
debug_log(FND_FILE.LOG,'�o�Ɍ`�Ԍ����F'||gt_tran_type_nm_tab.count);
debug_log(FND_FILE.LOG,'�^���ƎҌ����F'||gt_carrier_code_tab.count);
debug_log(FND_FILE.LOG,'�^���Ǝ�ID�����F'||gt_carrier_id_tab.count);
debug_log(FND_FILE.LOG,'�Ǌ����_�����F'||gt_head_sales_tab.count);
debug_log(FND_FILE.LOG,'�����������F'||gt_reserve_order_tab.count);
debug_log(FND_FILE.LOG,'�W�񍇌v�d�ʌ����F'||gt_sum_weight_tab.count);
debug_log(FND_FILE.LOG,'�W�񍇌v�e�ό����F'||gt_sum_capa_tab.count);
debug_log(FND_FILE.LOG,'�ő�z���敪�����F'||gt_max_ship_cd_tab.count);
debug_log(FND_FILE.LOG,'�d�ʗe�ϋ敪�����F'||gt_weight_capa_tab.count);
debug_log(FND_FILE.LOG,'�ő�ύڏd�ʌ����F'||gt_max_weight_tab.count);
debug_log(FND_FILE.LOG,'�ő�ύڗe�ό����F'||gt_max_capa_tab.count);
--
-- 2008/10/01 H.Itou Del Start PT 6-1_27 �w�E18
--for i in 1..gt_int_no_tab.count loop
--debug_log(FND_FILE.LOG,'---------------------------');
--debug_log(FND_FILE.LOG,'�W��No  �F'||gt_int_no_tab(i));
--debug_log(FND_FILE.LOG,'������ʁF'||gt_tran_type_tab(i));
--debug_log(FND_FILE.LOG,'�W��No�F'||gt_int_source_tab(i));
--debug_log(FND_FILE.LOG,'�z�����F'||gt_deli_from_tab(i));
--debug_log(FND_FILE.LOG,'�z����ID�F'||gt_deli_from_id_tab(i));
--debug_log(FND_FILE.LOG,'�z����F'||gt_deli_to_tab(i));
--debug_log(FND_FILE.LOG,'�z����ID�F'||gt_deli_to_id_tab(i));
--debug_log(FND_FILE.LOG,'�o�ɗ\����F'||gt_ship_date_tab(i));
--debug_log(FND_FILE.LOG,'���ח\����F'||gt_arvl_date_tab(i));
--debug_log(FND_FILE.LOG,'�o�Ɍ`�ԁF'||gt_tran_type_nm_tab(i));
--debug_log(FND_FILE.LOG,'�^���ƎҁF'||gt_carrier_code_tab(i));
--debug_log(FND_FILE.LOG,'�^���Ǝ�ID�F'||gt_carrier_id_tab(i));
--debug_log(FND_FILE.LOG,'�Ǌ����_�F'||gt_head_sales_tab(i));
--debug_log(FND_FILE.LOG,'�������F'||gt_reserve_order_tab(i));
--debug_log(FND_FILE.LOG,'�W�񍇌v�d�ʁF'||gt_sum_weight_tab(i));
--debug_log(FND_FILE.LOG,'�W�񍇌v�e�ρF'||gt_sum_capa_tab(i));
--debug_log(FND_FILE.LOG,'�ő�z���敪�F'||gt_max_ship_cd_tab(i));
--debug_log(FND_FILE.LOG,'�d�ʗe�ϋ敪�F'||gt_weight_capa_tab(i));
--debug_log(FND_FILE.LOG,'�ő�ύڏd�ʁF'||gt_max_weight_tab(i));
--debug_log(FND_FILE.LOG,'�ő�ύڗe�ρF'||gt_max_capa_tab(i));
--end loop;
-- 2008/10/01 H.Itou Del End
debug_log(FND_FILE.LOG,'�������z�ԏW�񒆊ԃe�[�u���o�^�F�W�񒆊ԃe�[�u���o�͏���(B-8)');
debug_log(FND_FILE.LOG,'�o�^���F'||gt_int_no_tab.COUNT);
debug_log(FND_FILE.LOG,'PLSQL�\�Fgt_int_no_tab');
    --======================================
    -- B-8.�W�񒆊ԃe�[�u���o�͏���
    --======================================
    FORALL ln_cnt IN 1..gt_int_no_tab.COUNT
      INSERT INTO xxwsh_intensive_carriers_tmp(   -- �����z�ԏW�񒆊ԃe�[�u��
          intensive_no              -- �W��No
        , transaction_type          -- �������
        , intensive_source_no       -- �W��No
        , deliver_from              -- �z����
        , deliver_from_id           -- �z����ID
        , deliver_to                -- �z����
        , deliver_to_id             -- �z����ID
        , schedule_ship_date        -- �o�ɗ\���
        , schedule_arrival_date     -- ���ח\���
        , transaction_type_name     -- �o�Ɍ`��
        , freight_carrier_code      -- �^���Ǝ�
        , carrier_id                -- �^���Ǝ�ID
        , head_sales_branch         -- �Ǌ����_
        , reserve_order             -- ������
        , intensive_sum_weight      -- �W�񍇌v�d��
        , intensive_sum_capacity    -- �W�񍇌v�e��
        , max_shipping_method_code  -- �ő�z���敪
        , weight_capacity_class     -- �d�ʗe�ϋ敪
        , max_weight                -- �ő�ύڏd��
        , max_capacity              -- �ő�ύڗe��
        )
        VALUES
        (
          gt_int_no_tab(ln_cnt)         -- �W��No
        , gt_tran_type_tab(ln_cnt)      -- �������
        , gt_int_source_tab(ln_cnt)     -- �W��No
        , gt_deli_from_tab(ln_cnt)      -- �z����
        , gt_deli_from_id_tab(ln_cnt)   -- �z����ID
        , gt_deli_to_tab(ln_cnt)        -- �z����
        , gt_deli_to_id_tab(ln_cnt)     -- �z����ID
        , gt_ship_date_tab(ln_cnt)      -- �o�ɗ\���
        , gt_arvl_date_tab(ln_cnt)      -- ���ח\���
        , gt_tran_type_nm_tab(ln_cnt)   -- �o�Ɍ`��
        , gt_carrier_code_tab(ln_cnt)   -- �^���Ǝ�
        , gt_carrier_id_tab(ln_cnt)     -- �^���Ǝ�ID
        , gt_head_sales_tab(ln_cnt)     -- �Ǌ����_
        , gt_reserve_order_tab(ln_cnt)  -- ������
        , gt_sum_weight_tab(ln_cnt)     -- �W�񍇌v�d��
        , gt_sum_capa_tab(ln_cnt)       -- �W�񍇌v�e��
        , gt_max_ship_cd_tab(ln_cnt)    -- �ő�z���敪
        , gt_weight_capa_tab(ln_cnt)    -- �d�ʗe�ϋ敪
        , gt_max_weight_tab(ln_cnt)     -- �ő�ύڏd��
        , gt_max_capa_tab(ln_cnt)       -- �ő�ύڗe��
        );
--
debug_log(FND_FILE.LOG,'�W��No  �F'||gt_int_no_lines_tab.count);
debug_log(FND_FILE.LOG,'�˗�No�F'||gt_request_no_tab.count);
-- 2008/10/01 H.Itou Del Start PT 6-1_27 �w�E18
--for i in 1..gt_int_no_lines_tab.count loop
--debug_log(FND_FILE.LOG,'�W��No  �F'||gt_int_no_lines_tab(i));
--debug_log(FND_FILE.LOG,'�˗�No�F'||gt_request_no_tab(i));
--end loop;
-- 2008/10/01 H.Itou Del End
debug_log(FND_FILE.LOG,'�����z�ԏW�񒆊Ԗ��׃e�[�u���o�^���F'||gt_request_no_tab.COUNT);
debug_log(FND_FILE.LOG,'PLSQL�\�Fgt_int_no_lines_tab');
    FORALL ln_cnt_2 IN 1..gt_int_no_lines_tab.COUNT
      INSERT INTO xxwsh_intensive_carrier_ln_tmp(  -- �����z�ԏW�񒆊Ԗ��׃e�[�u��
          intensive_no
        , request_no
        )
        VALUES
        (
          gt_int_no_lines_tab(ln_cnt_2)   -- �W��No
        , gt_request_no_tab(ln_cnt_2)     -- �˗�No
        );
-- Ver1.5 M.Hokkanji Start
   debug_log(FND_FILE.LOG,'�����z�ԏW�񒆊Ԗ��׃e�[�u���o�^��R�~�b�g');
   COMMIT;
-- Ver1.5 M.Hokkanji End
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
  END ins_intensive_carriers_tmp;
--
  /**********************************************************************************
   * Procedure Name   : get_max_shipping_method
   * Description      : �ő�z���敪�E�d�ʗe�ϋ敪�擾����(B-6)
   ***********************************************************************************/
  PROCEDURE get_max_shipping_method(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_max_shipping_method'; -- �v���O������
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
    cv_not_save       CONSTANT VARCHAR2(1)  := '0';       -- ���_���ړo�^�σt���O�F���o�^
    cv_finish_proc    CONSTANT VARCHAR2(1)  := '1';       -- ������
--
    -- *** ���[�J���ϐ� ***
    lb_warning_flg  BOOLEAN DEFAULT FALSE; -- �x���t���O�i�x���̏ꍇ�FTRUE)
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �o�׈˗�
    CURSOR ship_cur IS
      SELECT  xcst.transaction_id           transaction_id      -- �g�����U�N�V����ID
            , xcst.transaction_type         tran_type           -- �������
            , xcst.request_no               req_mov_no          -- �˗�NO
            , xcst.mixed_no                 mixed_no            -- ���ڌ�NO
            , xcst.deliver_from             ship_from           -- �o�׌��ۊǏꏊ
            , xcst.deliver_from_id          ship_from_id        -- �o�׌�ID
            , xcst.deliver_to               ship_to             -- �o�א�
            , xcst.deliver_to_id            ship_to_id          -- �o�א�ID
            , xcst.shipping_method_code     ship_method_code    -- �z���敪
            , xcst.schedule_ship_date       ship_date           -- �o�ɓ�
            , xcst.schedule_arrival_date    arrival_date        -- ���ד�
            , xcst.order_type_id            order_type_id       -- �o�Ɍ`��
            , xcst.freight_carrier_code     carrier_code        -- �^���Ǝ�
            , xcst.career_id                carrier_id          -- �^���Ǝ�ID
            , xcst.based_weight             based_weight        -- ��{�d��
            , xcst.based_capacity           based_capacity      -- ��{�e��
            , xcst.sum_weight               sum_weight          -- �ύڏd�ʍ��v
            , xcst.sum_capacity             sum_capacity        -- �ύڗe�ύ��v
            , xcst.sum_pallet_weight        sum_pallet_weight   -- ���v�p���b�g�d��
            , xcst.max_shipping_method_code max_shipping_method -- �ő�z���敪
            , xcst.weight_capacity_class    weight_capacity_cls -- �d�ʗe�ϋ敪
            , DECODE(reserve_order, NULL, 99999, reserve_order) reserve_order
                                                                -- ������
            , xcst.head_sales_branch        head_sales_branch   -- �Ǌ����_
            , NULL                          finish_sum_flag     -- �W��σt���O
      FROM xxwsh_carriers_sort_tmp xcst               -- �����z�ԃ\�[�g�p���ԃe�[�u��
      WHERE xcst.transaction_type = gv_ship_type_ship -- ������ʁF�o�׈˗�
        AND xcst.pre_saved_flg = cv_not_save          -- ���_���ړo�^�t���O:���o�^
      ORDER BY  ship_date                       -- �o�ɓ�
              , arrival_date                    -- ���ד�
              , mixed_no                        -- ���ڌ�NO
              , order_type_id                   -- �o�Ɍ`��
              , ship_from                       -- �o�׌��ۊǏꏊ
              , carrier_code                    -- �^���Ǝ�
              , weight_capacity_cls             -- �d�ʗe�ϋ敪
              , reserve_order                   -- ������
              , head_sales_branch               -- �Ǌ����_
              , ship_to                         -- �o�א�
              , DECODE (weight_capacity_cls, gv_weight
                        , sum_weight            -- �W��d�ʍ��v
                        , sum_capacity) DESC    -- �W�񍇌v�e��
      ;
--
    -- �ړ��w��
    CURSOR move_cur IS
      SELECT  xcst.transaction_id           transaction_id      -- �g�����U�N�V����ID
            , xcst.transaction_type         tran_type           -- �������
            , xcst.request_no               req_mov_no          -- �ړ�No
            , xcst.mixed_no                 mixed_no            -- ���ڌ�NO
            , xcst.deliver_from             ship_from           -- �o�׌��ۊǏꏊ
            , xcst.deliver_from_id          ship_from_id        -- �o�׌�ID
            , xcst.deliver_to               ship_to             -- �o�א�
            , xcst.deliver_to_id            ship_to_id          -- �o�א�ID
            , xcst.shipping_method_code     ship_method_code    -- �z���敪
            , xcst.schedule_ship_date       ship_date           -- �o�ɓ�
            , xcst.schedule_arrival_date    arrival_date        -- ���ד�
            , xcst.order_type_id            order_type_id       -- �o�Ɍ`��
            , xcst.freight_carrier_code     carrier_code        -- �^���Ǝ�
            , xcst.career_id                carrier_id          -- �^���Ǝ�ID
            , xcst.based_weight             based_weight        -- ��{�d��
            , xcst.based_capacity           based_capacity      -- ��{�e��
            , xcst.sum_weight               sum_weight          -- �ύڏd�ʍ��v
            , xcst.sum_capacity             sum_capacity        -- �ύڗe�ύ��v
            , xcst.sum_pallet_weight        sum_pallet_weight   -- ���v�p���b�g�d��
            , xcst.max_shipping_method_code max_shipping_method -- �ő�z���敪
            , xcst.weight_capacity_class    weight_capacity_cls -- �d�ʗe�ϋ敪
            , DECODE(reserve_order, NULL, 99999, reserve_order) reserve_order
                                                                -- ������
            , xcst.head_sales_branch        head_sales_branch   -- �Ǌ����_
            , NULL                          finish_sum_flag     -- �W��σt���O
      FROM xxwsh_carriers_sort_tmp xcst                     -- �����z�ԃ\�[�g�p���ԃe�[�u��
      WHERE xcst.transaction_type = gv_ship_type_move       -- ������ʁF�ړ��w��
      ORDER BY  ship_date                       -- �o�ɓ�
              , arrival_date                    -- ���ד�
              , ship_from                       -- �o�׌��ۊǏꏊ
              , carrier_code                    -- �^���Ǝ�
              , weight_capacity_cls             -- �d�ʗe�ϋ敪
              , ship_to                         -- �o�א�
              , DECODE (weight_capacity_cls, gv_weight
                        , sum_weight            -- �W��d�ʍ��v
                        , sum_capacity) DESC    -- �W�񍇌v�e��
      ;
--
    -- *** ���[�J���E���R�[�h ***
    lr_ship_info  ship_cur%ROWTYPE;   -- �o�׈˗����
    lr_move_info  move_cur%ROWTYPE;   -- �ړ��w�����
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
debug_log(FND_FILE.LOG,'�y�ő�z���敪�E�d�ʗe�ϋ敪�擾����(B-6)�z');
    -- �e�[�u��������
    gt_grp_sum_add_tab_ship.DELETE; -- �o�׈˗��p
    gt_grp_sum_add_tab_move.DELETE; -- �ړ��w���p
--
    --======================================
    -- B-6.�ő�z���敪�A�d�ʗe�ϋ敪�擾����
    --======================================
    -- �o�׈˗�
    OPEN ship_cur;
    FETCH ship_cur BULK COLLECT INTO gt_grp_sum_add_tab_ship;
    CLOSE ship_cur;
--
    IF (gt_grp_sum_add_tab_ship.COUNT > 0) THEN
--
debug_log(FND_FILE.LOG,'�o�׈˗�����:'|| gt_grp_sum_add_tab_ship.COUNT);
--
      -- ================================
      -- ���v�d��/�e�ώ擾 ���Z����(B-7)
      -- ================================
      set_weight_capacity_add(
           it_group_sum_add_tab => gt_grp_sum_add_tab_ship  -- �����e�[�u��
         , ov_errbuf            => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
         , ov_retcode           => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
         , ov_errmsg            => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �������G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      ELSIF lv_retcode = gv_status_warn THEN
        lb_warning_flg := TRUE;
      END IF;
--
      -- ================================
      -- �W�񒆊ԃe�[�u���o�͏���(B-8)
      -- ================================
      ins_intensive_carriers_tmp(
           ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
         , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
         , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �������G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
    OPEN move_cur;
    FETCH move_cur BULK COLLECT INTO gt_grp_sum_add_tab_move;
    CLOSE move_cur;
--
    IF (gt_grp_sum_add_tab_move.COUNT > 0) THEN
--
debug_log(FND_FILE.LOG,'�ړ��w������:'|| gt_grp_sum_add_tab_move.COUNT);
      -- ================================
      -- ���v�d��/�e�ώ擾 ���Z����(B-7)
      -- ================================
      set_weight_capacity_add(
           it_group_sum_add_tab => gt_grp_sum_add_tab_move  -- �����e�[�u��
         , ov_errbuf            => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
         , ov_retcode           => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
         , ov_errmsg            => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �������G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      ELSIF (lv_retcode = gv_status_warn) THEN
        --�������x���̏ꍇ
debug_log(FND_FILE.LOG,'B-7.���v�d��/�e�ώ擾 ���Z���� �x�����b�Z�[�W�F'||lv_errmsg);
        lb_warning_flg := TRUE;
      END IF;
--
      -- ================================
      -- �W�񒆊ԃe�[�u���o�͏���(B-8)
      -- ================================
      ins_intensive_carriers_tmp(
           ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
         , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
         , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �������G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
    --�x������̏ꍇ�X�e�[�^�X�x��
    IF ( lb_warning_flg ) THEN
      ov_retcode := gv_status_warn;
    END IF;


  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (ship_cur%ISOPEN) THEN
        CLOSE ship_cur;
      END IF;
      IF (move_cur%ISOPEN) THEN
        CLOSE move_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (ship_cur%ISOPEN) THEN
        CLOSE ship_cur;
      END IF;
      IF (move_cur%ISOPEN) THEN
        CLOSE move_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (ship_cur%ISOPEN) THEN
        CLOSE ship_cur;
      END IF;
      IF (move_cur%ISOPEN) THEN
        CLOSE move_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_max_shipping_method;
--
  /**********************************************************************************
   * Procedure Name   : set_delivery_no
   * Description      : �z��No�ݒ菈��
   ***********************************************************************************/
  PROCEDURE set_delivery_no(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_delivery_no'; -- �v���O������
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
    cv_possibility    CONSTANT VARCHAR2(1) := '0';    -- �g�p��
    cv_impossibility  CONSTANT VARCHAR2(1) := '1';    -- �g�p�s��
    cv_delivery_kbn   CONSTANT VARCHAR2(1) := '5';    -- �̔Ԕԍ��敪�F�z��No
--
    -- *** ���[�J���ϐ� ***
    -- ��r�p�ϐ�
    lt_bf_request_no        xxwsh_intensive_carrier_ln_tmp.request_no%TYPE; -- �˗�No/�ړ�No
    lt_bf_delivery_no       xxwsh_mixed_carriers_tmp.delivery_no%TYPE;      -- �z��No
    lt_bf_prev_request_no   xxwsh_carriers_sort_tmp.request_no%TYPE;        -- �W��O�˗�No
    lt_bf_prev_delivery_no  xxwsh_carriers_sort_tmp.prev_delivery_no%TYPE;  -- �O��z��No
--
    -- PL/SQL�\
    lt_delivery_no_dat      reset_delivery_no_ttype;    -- �J�[�\���f�[�^�擾�p
    lt_intensive_no_tab     intensive_no_ttype;         -- �W��No
    lt_delivery_no_tab      deliver_no_ttype;           -- �z��No
    lt_upd_delivery_no_tab  deliver_no_ttype;           -- �X�V�p�z��No
    lt_request_no_tab       req_mov_no_ttype;           -- �˗�No/�ړ�No
    lt_prev_delivery_no_tab pre_deliver_no_ttype;       -- �O��z��No
    lt_prev_request_no_tab  req_mov_no_ttype;           -- �W��O�˗�No/�ړ�No
    lt_fin_delivery_no_tab  deliver_no_ttype;           -- �g�p�ϔz��No
--
    ln_loop_cnt             NUMBER DEFAULT 0;                               -- ���[�v�J�E���^
    ln_cnt                  NUMBER DEFAULT 0;                               -- ���[�v�J�E���^
    ln_chk_1                NUMBER DEFAULT 0;                               -- �`�F�b�N�J�E���^�P
    ln_chk_2                NUMBER DEFAULT 0;                               -- �`�F�b�N�J�E���^�Q
    ln_reg_cnt              NUMBER DEFAULT 0;                               -- �z��No�ݒ�p�J�E���^
    ln_delivery_grp_cnt     NUMBER DEFAULT 0;                               -- �z���O���[�v�J�E���^
    ln_start_cnt            NUMBER DEFAULT 0;                               -- �J�n�J�E���g
    ln_end_cnt              NUMBER DEFAULT 0;                               -- �I���J�E���g
    ln_fin_cnt              NUMBER DEFAULT 0;                               -- �g�p�ϔz��No�o�^�p
    lt_delivery_no_tmp      xxwsh_mixed_carriers_tmp.delivery_no%TYPE;      -- �z��No(TEMP)
    lt_decision_delivery_no xxwsh_mixed_carriers_tmp.delivery_no%TYPE;      -- �z��No(�m��)
    lb_new_ins_flag         BOOLEAN DEFAULT FALSE;                          -- �V�K�o�^�t���O
    lv_possible_flag        VARCHAR2(1);                                    -- �z��No�g�p��
    lb_last_data_flag       BOOLEAN DEFAULT FALSE;                          -- �ŏI�f�[�^�t���O
    lt_chk_delivery_no      xxwsh_mixed_carriers_tmp.delivery_no%TYPE;      -- �z��No(�g�p�m�F�p)
    lb_used_flag            BOOLEAN DEFAULT FALSE;                          -- �g�p�σt���O
    ln_use_chk_cnt          NUMBER DEFAULT 0;
debug_cnt number default 0;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    CURSOR set_delivery_no_cur IS
      SELECT  xmct.intensive_no     int_no                  -- �W��No
            , xcst.request_no       req_no                  -- �˗�No
            , xmct.delivery_no      delivery_no             -- �z��No
            , xcst.prev_delivery_no prev_delivery_no        -- �O��z��No
-- Ver1.2 M.Hokkanji Start
            , xcst.delivery_no      use_delivery_no         -- ���z��No
-- Ver1.2 M.Hokkanji End
        FROM  xxwsh_intensive_carriers_tmp   xict           -- �����z�ԏW�񒆊ԃe�[�u��
            , xxwsh_intensive_carrier_ln_tmp xiclt          -- �����z�ԏW�񒆊Ԗ��׃e�[�u��
            , xxwsh_mixed_carriers_tmp       xmct           -- �����z�ԍ��ڒ��ԃe�[�u��
            , xxwsh_carriers_sort_tmp        xcst           -- �����z�ԃ\�[�g�p���ԃe�[�u��
       WHERE  xict.intensive_no = xiclt.intensive_no        -- �W��No
         AND  xict.intensive_no = xmct.intensive_no         -- �W��No
         AND  xiclt.request_no  = xcst.request_no           -- �˗�No
-- Ver1.3 M.Hokkanji Start
-- TE080�w�E����08�Ή�
--      ORDER BY  xmct.delivery_no ASC                        -- �z��No
      ORDER BY  xict.transaction_type ASC                     -- �Ɩ����
              , xmct.delivery_no ASC                          -- �z��No
-- Ver1.3 M.Hokkanji End
-- Ver1.2 M.Hokkanji Start
--              , xcst.prev_delivery_no ASC                   -- �O��z��No
              , NVL(xcst.delivery_no,xcst.prev_delivery_no) ASC -- �O��z��No
-- Ver1.2 M.Hokkanji End
    ;
--
    -- *** ���[�J���E���R�[�h ***
    lr_set_deliver_no   set_delivery_no_cur%ROWTYPE;
--
    -- *** �T�u�E�v���O���� ***
    -- ======================
    -- �O��z��No�g�p�ϊm�F
    -- ======================
    PROCEDURE chk_finish_delivery_no(
        in_delivery_no IN  xxwsh_carriers_schedule.delivery_no%TYPE
      , ov_finish_flag OUT NOCOPY VARCHAR2    -- �g�p�ۃt���O(1:�g�p�s�A0:�g�p��)
      , ov_errbuf      OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode     OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg      OUT NOCOPY VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
    IS
      -- *** ���[�J���萔 ***
      ln_deliv_cnt NUMBER DEFAULT 0;  --�z��No�g�p�m�F�p�J�E���^
-- Ver1.2 M.Hokkanji Start
      ln_header_cnt NUMBER DEFAULT 0; -- �Ώ۔z��No�g�p�w�b�_�m�F�p�J�E���^
-- Ver1.2 M.Hokkanji End
      -- *** ���[�J���萔 ***
      cv_sub_prg_name   CONSTANT VARCHAR2(100) := '[chk_finish_delivery_no]'; -- �T�u�v���O������
-- Ver1.2 M.Hokkanji Start
      cv_yes            CONSTANT VARCHAR2(1) := 'Y';    -- YES
-- Ver1.2 M.Hokkanji End
--
      -- ���[�J���J�[�\��
      CURSOR get_delivery_no(in_delivery_no xxwsh_carriers_schedule.delivery_no%TYPE) IS
        SELECT  COUNT(xcs.delivery_no) delivery_no_cnt  -- �z��No
          FROM  xxwsh_carriers_schedule xcs             -- �z�Ԕz���v��A�h�I��
         WHERE  xcs.delivery_no = in_delivery_no
           AND  ROWNUM          = 1
        ;
    BEGIN
debug_log(FND_FILE.LOG,'�O��z��No�g�p�m�F');
      -- �g�p�ۃt���O������
      ov_finish_flag := cv_possibility;
      --�z��No�g�p�m�F�J�[�\���I�[�v��
      OPEN get_delivery_no(in_delivery_no);
      FETCH get_delivery_no  INTO ln_deliv_cnt;
      CLOSE get_delivery_no;
      IF (ln_deliv_cnt > 0) THEN
-- Ver1.2 M.Hokkanji Start
--debug_log(FND_FILE.LOG,'�O��z��No:'||in_delivery_no||' �g�p�s��');
debug_log(FND_FILE.LOG,'�O��z��No:'||in_delivery_no||' �z�Ԕz���v�摶�ݗL');
-- �Ώۂ̔z��No���g�p���Ă���e�w�b�_���A�����z�ԃ\�[�g�p���ԃe�[�u���ɑS��
-- ���݂���ꍇ�́A�����̔z��No�͍č̔Ԃ���邽�ߎg�p�Ƃ���B
-- 
        SELECT COUNT(a.request_no)
          INTO ln_header_cnt
          FROM ( SELECT xoh.delivery_no delivery_no,
                        xoh.request_no request_no
                   FROM xxwsh_order_headers_all xoh
                  WHERE xoh.delivery_no = in_delivery_no
                    AND xoh.latest_external_flag = cv_yes
                 UNION ALL
                 SELECT xmrih.delivery_no delivery_no,
                        xmrih.mov_num request_no
                   FROM xxinv_mov_req_instr_headers xmrih
                  WHERE xmrih.delivery_no = in_delivery_no
               ) a
        WHERE NOT EXISTS (
                SELECT xcst.request_no
                  FROM xxwsh_carriers_sort_tmp xcst
                 WHERE xcst.request_no = a.request_no
              )
          AND ROWNUM = 1;
        IF (ln_header_cnt > 0) THEN
debug_log(FND_FILE.LOG,'�O��z��No:'||in_delivery_no||' �g�p�s��');
          ov_finish_flag := cv_impossibility; -- �g�p�s��
        END IF;
      END IF;
-- Ver1.2 M.Hokkanji End
--
--      <<chk_delivery_no_loop>>
--      FOR ln_cnt IN get_delivery_no(in_delivery_no) LOOP
--
--        IF (ln_cnt.delivery_no_cnt > 0) THEN
--
--debug_log(FND_FILE.LOG,'�O��z��No�g�p�s��');
--          ov_finish_flag := cv_impossibility; -- �g�p�s��
--
--        END IF;
--
--      END LOOP chk_delivery_no_loop;
--
    EXCEPTION
      -- *** ���ʊ֐���O�n���h�� ***
      WHEN global_api_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||
                              lv_errbuf,1,5000);
        ov_retcode := gv_status_error;
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      WHEN global_api_others_expt THEN
        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
    END  chk_finish_delivery_no;
--
    -- ======================
    -- �L�[�u���C�N����
    -- ======================
    PROCEDURE lproc_keybrake_process(
        ov_errbuf      OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode     OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg      OUT NOCOPY VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
    IS
      -- *** ���[�J���萔 ***
      cv_sub_prg_name   CONSTANT VARCHAR2(100) := '[lproc_keybrake_process]'; -- �T�u�v���O������
    BEGIN
--
debug_log(FND_FILE.LOG,'�L�[�u���C�N����');
debug_log(FND_FILE.LOG,'�z���O���[�v���̑O��z��No��:'||lt_prev_delivery_no_tab.COUNT);
--2008.05.22 D.Sugahara �s�No10�Ή�->
          ln_chk_1 := ln_start_cnt - 1; --�O��z��No�z��̊J�n�ʒu��ݒ�(-1����)
--2008.05.22 D.Sugahara �s�No10�Ή�<-
          -- �z���O���[�v���̑S�O��z��No���g�p�ϊm�F����
          <<prev_delivery_no_chk>>
          FOR i IN 1..lt_prev_delivery_no_tab.COUNT LOOP
--
            -- �J�E���^
            ln_chk_1 := ln_chk_1 + 1;
            IF (ln_chk_1 > lt_prev_delivery_no_tab.COUNT) THEN
              EXIT;
            END IF;
debug_log(FND_FILE.LOG,'1 �O��z��No:'|| lt_prev_delivery_no_tab(ln_chk_1));
debug_log(FND_FILE.LOG,'�J�E���^:'|| ln_chk_1);
            IF lt_prev_delivery_no_tab(ln_chk_1) IS NOT NULL THEN
--
debug_log(FND_FILE.LOG,'1-2�O��z��No�g�p�ϊm�F(�z�Ԕz���A�h�I��)');
              -- �O��z��No�g�p�ϊm�F(�z�Ԕz���A�h�I��)
              chk_finish_delivery_no(
                  in_delivery_no => lt_prev_delivery_no_tab(ln_chk_1)
                , ov_finish_flag => lv_possible_flag
                , ov_errbuf      => lv_errbuf
                , ov_retcode     => lv_retcode
                , ov_errmsg      => lv_errmsg
              );
              -- �������G���[�̏ꍇ
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_api_expt;
              END IF;
--
              -- �z�Ԕz���A�h�I���Ŏg�p����Ă��Ȃ��ꍇ�A
              IF (lv_possible_flag = cv_possibility) THEN
debug_log(FND_FILE.LOG,'1-1-1�O��z��No�g�p�\�i�z�Ԕz���A�h�I���`�F�b�N�j');
--
                -- ���ݏ������O���[�v���̔z��No�����ɏ����ς̔z��No�Əd�����Ȃ����m�F
debug_log(FND_FILE.LOG,'���ݏ������O���[�v���̔z��No��:'||lt_upd_delivery_no_tab.COUNT);
                lb_used_flag := FALSE;
                FOR cnt_2 IN 1..lt_upd_delivery_no_tab.COUNT LOOP
--
debug_log(FND_FILE.LOG,'2-1-1-1���ݏ������O���[�v���m�F');
debug_log(FND_FILE.LOG,'cnt_2   :'||cnt_2);
debug_log(FND_FILE.LOG,'ln_chk_1:'||ln_chk_1);
debug_log(FND_FILE.LOG,'2 �Ώ۔z��No:'|| lt_upd_delivery_no_tab(cnt_2));
                  IF (lt_upd_delivery_no_tab(cnt_2) = lt_prev_delivery_no_tab(ln_chk_1)) THEN
--
debug_log(FND_FILE.LOG,'2-1-1-2���ݏ������O���[�v�g�p�ς�');
                    lb_used_flag := TRUE;
                    EXIT;
--
                  END IF;
--
                END LOOP;
debug_log(FND_FILE.LOG,'���[�v�I��');
--
                -- �z�Ԕz���v��A�h�I���ł��������f�[�^�Ŏg�p����Ă��Ȃ��ꍇ�͍̗p
                IF (NOT lb_used_flag) THEN
debug_log(FND_FILE.LOG,'3 �̗p�F'||lt_prev_delivery_no_tab(ln_chk_1));
                  -- �m��z��No�ɃZ�b�g
                  lt_decision_delivery_no := lt_prev_delivery_no_tab(ln_chk_1);
                  EXIT;
                END IF;
--
              END IF;
--
            END IF;
--
          END LOOP prev_delivery_no_chk;
--
--debug_log(FND_FILE.LOG,'��2���ݏ������O���[�v���̔z���`�F�b�N�����F'||lt_prev_delivery_no_tab.COUNT);
--
          -- �m��z��No��NULL�̏ꍇ�͍̔Ԃ���
          IF (lt_decision_delivery_no IS NULL) THEN
--
debug_log(FND_FILE.LOG,'4 �z��No�̔�');
            -- ���ʊ֐��F�̔Ԋ֐�
            xxcmn_common_pkg.get_seq_no(
                  iv_seq_class  => cv_delivery_kbn
                , ov_seq_no     => lt_decision_delivery_no
                , ov_errbuf     => lv_errbuf
                , ov_retcode    => lv_retcode
                , ov_errmsg     => lv_errmsg
            );
            -- �������G���[�̏ꍇ
            IF (lv_retcode = gv_status_error) THEN
              -- �G���[���b�Z�[�W�擾
              lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                              gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                            , gv_msg_xxwsh_11805  -- ���b�Z�[�W�FAPP-XXWSH-11805 �z��No�擾�G���[
                            , gv_tkn_errmsg       -- �g�[�N���FERRMSG
                            , lv_errmsg           -- ���ʊ֐��̃G���[���b�Z�[�W
                           ),1,5000);
              RAISE global_process_expt;
            END IF;
debug_log(FND_FILE.LOG,'3-1');
-- Ver1.2 M.Hokkanji Start
          -- �����̔z��No���g�p����ꍇ�͔z�Ԕz���v��ɑ��݂���z�����폜����B
          ELSE
debug_log(FND_FILE.LOG,'4a �����z��No�폜����');
            BEGIN
              DELETE xxwsh_carriers_schedule xcs
               WHERE xcs.delivery_no = lt_decision_delivery_no;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                NULL; -- �폜�f�[�^�����݂��Ȃ��ꍇ�͏������s
            END;
debug_log(FND_FILE.LOG,'4b �����z��No�폜�����I��');
-- Ver1.2 M.Hokkanji End
--
          END IF;
--
debug_log(FND_FILE.LOG,'5 �̔Ԍ��ʁF'||lt_decision_delivery_no);
          -- �X�V�pPL/SQL�\�ɃZ�b�g����
--
          -- �z��No�ݒ�p�J�E���^�Z�b�g
          ln_reg_cnt := ln_start_cnt - 1;
--
debug_log(FND_FILE.LOG,'5a�z��No�ݒ�p�J�E���^�J�n='||ln_start_cnt);
debug_log(FND_FILE.LOG,'5b�z��No�ݒ�p�J�E���^�I��='||ln_end_cnt);
          <<deliver_no_decision_loop>>
          FOR i IN ln_start_cnt..ln_end_cnt LOOP
--
            ln_reg_cnt := ln_reg_cnt + 1;
debug_log(FND_FILE.LOG,'6-1�z��NO��PLSQL�\�ɐݒ�F'||lt_decision_delivery_no);
            -- �z��NO��ݒ肷��
            lt_upd_delivery_no_tab(ln_reg_cnt)  := lt_decision_delivery_no;
--
          END LOOP deliver_no_decision_loop;
--
-- 20080603 K.Yamane �s�No11->
--debug_log(FND_FILE.LOG,'6�O��z��No�pPL/SQL�\������');
          -- �O��z��No�pPL/SQL�\������
--          lt_prev_delivery_no_tab.DELETE;
--debug_log(FND_FILE.LOG,'7�O��z��No�pPL/SQL�\��������J�E���g�F'||lt_prev_delivery_no_tab.count);
-- 20080603 K.Yamane �s�No11<-
debug_log(FND_FILE.LOG,'7�O��z��No�pPL/SQL�\�J�E���g�F'||lt_prev_delivery_no_tab.count);
    EXCEPTION
      -- *** ���ʊ֐���O�n���h�� ***
      WHEN global_api_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||
                              lv_errbuf,1,5000);
        ov_retcode := gv_status_error;
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      WHEN global_api_others_expt THEN
        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
    END  lproc_keybrake_process;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
debug_log(FND_FILE.LOG,'�yB-13 �z��No�ݒ菈���z');
--
    -- �ϐ�������
    lt_decision_delivery_no   := NULL;  -- �m��z��No
--
    -- PL/SQL�\������
    lt_delivery_no_dat.DELETE;        -- �J�[�\���f�[�^�擾�p
    lt_intensive_no_tab.DELETE;       -- �W��No
    lt_delivery_no_tab.DELETE;        -- �z��No
    lt_request_no_tab.DELETE;         -- �˗�No/�ړ�No
    lt_upd_delivery_no_tab.DELETE;    -- �X�V�p�z��No
    lt_prev_delivery_no_tab.DELETE;   -- �O��z��No
    lt_prev_request_no_tab.DELETE;    -- �W��O�˗�No/�ړ�No
    lt_fin_delivery_no_tab.DELETE;    -- �g�p�ϔz��No
--
    -- ==========================
    --  �z��No�Z�b�g
    -- ==========================
    -- �I�[�v���J�[�\��
    OPEN  set_delivery_no_cur;
    FETCH set_delivery_no_cur BULK COLLECT INTO lt_delivery_no_dat;
    CLOSE set_delivery_no_cur;
--
    IF (lt_delivery_no_dat.COUNT > 0) THEN
debug_log(FND_FILE.LOG,'�J�[�\���f�[�^�J�E���g�F'|| lt_delivery_no_dat.COUNT);
      <<set_delivery_no_loop>>
      LOOP
--
        -- ���[�v�J�E���g
        ln_loop_cnt := ln_loop_cnt + 1;
debug_log(FND_FILE.LOG,'���[�v�J�E���g�F'|| ln_loop_cnt);
debug_cnt := debug_cnt +1;
--
        -- �z���O���[�v���J�E���g
        ln_delivery_grp_cnt := ln_delivery_grp_cnt + 1;
debug_log(FND_FILE.LOG,'�z���O���[�v�J�E���^�F'||ln_delivery_grp_cnt);
--
        -- �z���O���[�v1���ڂ̏����m�ۂ���
        IF (ln_delivery_grp_cnt = 1) THEN
--
debug_log(FND_FILE.LOG,'����R�[�h���Z�b�g');
--
          -- �O���[�v�J�n�J�E���g��ێ�
          ln_start_cnt := ln_loop_cnt;
--
          -- ��r�p�ϐ��Ɋi�[
          lt_bf_request_no        := lt_delivery_no_dat(ln_loop_cnt).req_no;      -- �˗�No/�ړ�No
          lt_bf_delivery_no       := lt_delivery_no_dat(ln_loop_cnt).delivery_no; -- �z��No(�z���O���[�v)
          lt_bf_prev_delivery_no  := lt_delivery_no_dat(ln_loop_cnt).prev_delivery_no; -- �O��z��No
debug_log(FND_FILE.LOG,'�˗�No/�ړ�No:'||lt_bf_request_no);
debug_log(FND_FILE.LOG,'�z��No(�z���O���[�v):'||lt_bf_delivery_no);
debug_log(FND_FILE.LOG,'�O��z��No:'||lt_bf_prev_delivery_no);
debug_log(FND_FILE.LOG,'---------------------------');
--
        END IF;
--
--
        -- �L�[�u���C�N���Ȃ�
        IF (NVL(lt_bf_delivery_no, 0) = NVL(lt_delivery_no_dat(ln_loop_cnt).delivery_no, 0))
          AND (lb_last_data_flag = FALSE)
        THEN
                                                                                -- ����z���O���[�v
debug_log(FND_FILE.LOG,'����z���O���[�v');
--
-- Ver1.2 M.Hokkanji Start
          -- ���ݔz��No���ݒ肳��Ă���ꍇ�͌��݂̔z��No���g�p
          IF (lt_delivery_no_dat(ln_loop_cnt).use_delivery_no IS NOT NULL ) THEN
            lt_prev_delivery_no_tab(ln_loop_cnt) := lt_delivery_no_dat(ln_loop_cnt).use_delivery_no;
          ELSE
            -- �O��z��No��PL/SQL�\�Ɋi�[
            lt_prev_delivery_no_tab(ln_loop_cnt) := lt_delivery_no_dat(ln_loop_cnt).prev_delivery_no;
          END IF;
debug_log(FND_FILE.LOG,'��r�p�z��No:'||lt_prev_delivery_no_tab(ln_loop_cnt));
--debug_log(FND_FILE.LOG,'�O��z��No:'||lt_prev_delivery_no_tab(ln_loop_cnt));
-- Ver1.2 M.Hokkanji End
--
          -- �W��No
          lt_intensive_no_tab(ln_loop_cnt) := lt_delivery_no_dat(ln_loop_cnt).int_no;
debug_log(FND_FILE.LOG,'�W��No:'||lt_delivery_no_dat(ln_loop_cnt).int_no);
--
          -- �z��No
          lt_delivery_no_tab(ln_loop_cnt)  := lt_delivery_no_dat(ln_loop_cnt).delivery_no;
debug_log(FND_FILE.LOG,'���z��No:'||lt_delivery_no_dat(ln_loop_cnt).delivery_no);
debug_log(FND_FILE.LOG,'---------------------------');
--
        -- �L�[�u���C�N
        ELSE
--
debug_log(FND_FILE.LOG,'�L�[�u���C�N');
          -- �I���J�E���g���m��
          ln_end_cnt := ln_loop_cnt - 1;
--
          -- �L�[�u���C�N����
          lproc_keybrake_process(
              ov_errbuf      => lv_errbuf
            , ov_retcode     => lv_retcode
            , ov_errmsg      => lv_errmsg
          );
          -- �������G���[�̏ꍇ
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          -- �z���O���[�v�J�E���g������
          ln_delivery_grp_cnt := 0;
--
          -- ���[�v�J�E���g������(���̔z���O���[�v������)
          ln_loop_cnt := ln_end_cnt;
          -- �z��No������
          lt_decision_delivery_no := NULL;
--
          -- ��r�p�ϐ��Ɋi�[
          lt_bf_request_no        := lt_delivery_no_dat(ln_loop_cnt).req_no;            -- �˗�No/�ړ�No
          lt_bf_delivery_no       := lt_delivery_no_dat(ln_loop_cnt).delivery_no;       -- �z��No
          lt_bf_prev_delivery_no  := lt_delivery_no_dat(ln_loop_cnt).prev_delivery_no;  -- �O��z��No
--
        END IF;
--
        IF (ln_loop_cnt = lt_delivery_no_dat.COUNT) THEN
debug_log(FND_FILE.LOG,'�ŏI���R�[�h����');
          ln_end_cnt := ln_loop_cnt;
          -- �L�[�u���C�N����
          lproc_keybrake_process(
              ov_errbuf      => lv_errbuf
            , ov_retcode     => lv_retcode
            , ov_errmsg      => lv_errmsg
          );
          -- �������G���[�̏ꍇ
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
debug_log(FND_FILE.LOG,'�I���t���O�FTRUE');
          lb_last_data_flag := TRUE;
--
        END IF;
--
        EXIT WHEN lb_last_data_flag;
/*if (debug_cnt >= 100) then
  exit;
debug_log(FND_FILE.LOG,'������EXIT');
end if;
*/
      END LOOP set_delivery_no_loop;
--
debug_log(FND_FILE.LOG,'���[�v����');
    END IF;
--
    -- ==========================
    --  �z��No.�ꊇ�X�V����
    -- ==========================
debug_log(FND_FILE.LOG,'�z��No.�ꊇ�X�V����');
debug_log(FND_FILE.LOG,'�o�^���F'||lt_intensive_no_tab.COUNT);
/*
for i in 1..lt_intensive_no_tab.COUNT loop
debug_log(FND_FILE.LOG,'�W��No�F'|| lt_intensive_no_tab(i));
debug_log(FND_FILE.LOG,'�z��No�F'|| lt_delivery_no_tab(i));
debug_log(FND_FILE.LOG,'�m��z��No�F'|| lt_upd_delivery_no_tab(i));
debug_log(FND_FILE.LOG,'-------------------------------');
end loop;
*/
    FORALL upd_cnt IN 1..lt_intensive_no_tab.COUNT
      UPDATE  xxwsh_mixed_carriers_tmp                      -- �����z�ԍ��ڒ��ԃe�[�u��
         SET  delivery_no = lt_upd_delivery_no_tab(upd_cnt) -- �z��No
       WHERE  intensive_no = lt_intensive_no_tab(upd_cnt)   -- �W��No
         AND  delivery_no = lt_delivery_no_tab(upd_cnt)     -- �z��No
      ;
--
debug_log(FND_FILE.LOG,'�z��No�ݒ菈���I��');
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
  END set_delivery_no;
--
  /**********************************************************************************
   * Procedure Name   : set_small_sam_class
   * Description      : �����z�����쐬����
   ***********************************************************************************/
  PROCEDURE set_small_sam_class(
-- 2008/10/16 H.Itou Add Start T_S_625 �W��No���Ƃɏ������s���悤�ɕύX
    iv_intensive_no IN VARCHAR2,           -- �W��No
-- 2008/10/16 H.Itou Add End
-- 2008/10/30 H.Itou Add Start �����e�X�g�w�E526 ���[�t�̏ꍇ�̔z���敪���w��
    iv_ship_method  IN VARCHAR2,           -- �z���敪
-- 2008/10/30 H.Itou Add End
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_small_sam_class'; -- �v���O������
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
    cv_an_object      CONSTANT VARCHAR2(1)  := '1';     -- �Ώ�
    cv_yes            CONSTANT VARCHAR2(1)  := 'Y';     -- YES
    cv_small_amount_b CONSTANT VARCHAR2(2)  := '11';    -- ����B
    cv_small_amount_a CONSTANT VARCHAR2(2)  := '12';    -- ����A
--
    -- *** ���[�J���ϐ� ***
    -- �����z�ԏW�񒆊ԃe�[�u���o�^�pPL/SQL�\
    lt_int_no_tab         intensive_no_ttype;     -- �W��No(�폜�p)
    lt_tran_type_tab      transaction_type_ttype; -- �������
    lt_int_source_tab     int_source_no_ttype;    -- �W��No
    lt_deli_from_tab      deliver_from_ttype;     -- �z����
    lt_deli_from_id_tab   deliver_from_id_ttype;  -- �z����ID
    lt_deli_to_tab        deliver_to_ttype;       -- �z����
    lt_deli_to_id_tab     deliver_to_id_ttype;    -- �z����ID
    lt_ship_date_tab      sche_ship_date_ttype;   -- �o�ɗ\���
    lt_arvl_date_tab      sche_arvl_date_ttype;   -- ���ח\���
    lt_tran_type_nm_tab   tran_type_name_ttype;   -- �o�Ɍ`��
    lt_carrier_code_tab   freight_carry_cd_ttype; -- �^���Ǝ�
    lt_carrier_id_tab     carrier_id_ttype;       -- �^���Ǝ�ID
    lt_sum_weight_tab     int_sum_weight_ttype;   -- �W�񍇌v�d��
    lt_sum_capa_tab       int_sum_capa_ttype;     -- �W�񍇌v�e��
    lt_max_ship_cd_tab    max_ship_cd_ttype;      -- �ő�z���敪
    lt_weight_capa_tab    weight_capa_cls_ttype;  -- �d�ʗe�ϋ敪
    lt_max_weight_tab     max_weight_ttype;       -- �ő�ύڏd��
    lt_max_capa_tab       max_capacity_ttype;     -- �ő�ύڗe��
    lt_base_weight_tab    based_weight_ttype;     -- ��{�d��
    lt_base_capa_tab      based_capa_ttype;       -- ��{�e��
    lt_delivery_no_tab    delivery_no_ttype;      -- �z��No
    lt_fix_ship_method_cd fixed_ship_code_ttype;  -- �C���z���敪
    lt_sum_case_qty_tab   case_quantity_ttype;    -- �P�[�X��
    lt_ins_int_no_tab     intensive_no_ttype;     -- �W��No(�o�^�p)
--
    -- �����z�ԏW�񒆊Ԗ��׃e�[�u���o�^�pPL/SQL�\
    lt_int_no_lines_tab intensive_no_ttype;     -- �W��No
    lt_request_no_tab   request_no_ttype;       -- �˗�No
--
    -- �����z�ԍ��ڒ��ԃe�[�u���o�^�pPL/SQL�\
    lt_intensive_no_tab           intensive_no_ttype;         -- �W��No
    lt_mixed_delivery_no_tab      delivery_no_ttype;          -- �z��No
    lt_fixed_ship_code_tab        fixed_ship_code_ttype;      -- �C���z���敪
    lt_mixed_class_tab            mixed_class_ttype;          -- ���ڎ��
    lt_mixed_total_weight_tab     mixed_total_weight_ttype;   -- ���ڍ��v�d��
    lt_mixed_total_capacity_tab   mixed_total_capacity_ttype; -- ���ڍ��v�e��
    lt_mixed_no_tab               mixed_no_ttype;             -- ���ڌ�No
--
    ln_loop_cnt       NUMBER DEFAULT 0;                           -- ���[�v�J�E���g(�W��)
    ln_loop_cnt_2     NUMBER DEFAULT 0;                           -- ���[�v�J�E���g(����)
    ln_intensive_no   NUMBER DEFAULT 0;                           -- �W��No�V�[�P���X�p
    lt_max_case_qty   xxwsh_ship_method_v.max_case_quantity%TYPE; -- �ő�P�[�X��
    ln_temp_ship_no   NUMBER;                                     -- ���z��No
--
    TYPE get_cur_rtype IS RECORD(
        int_no              xxwsh_intensive_carriers_tmp.intensive_no%TYPE             -- �W��No
      , ship_type           xxwsh_intensive_carriers_tmp.transaction_type%TYPE         -- �������:�o�׈˗�
      , int_source_no       xxwsh_intensive_carriers_tmp.intensive_source_no%TYPE      -- �W��No
-- 2008/10/16 H.Itou Del Start T_S_625
--      , delivery_no         xxwsh_mixed_carriers_tmp.delivery_no%TYPE                  -- �z��No
-- 2008/10/16 H.Itou Del End
      , req_no              xxwsh_order_headers_all.request_no%TYPE                    -- �˗�No
      , deliver_from        xxwsh_order_headers_all.deliver_from%TYPE                  -- �o�׌��ۊǏꏊ
      , deliver_from_id     xxwsh_order_headers_all.deliver_from_id%TYPE               -- �o�׌�ID
      , deliver_to          xxwsh_order_headers_all.deliver_to%TYPE                    -- �o�א�
      , deliver_to_id       xxwsh_order_headers_all.deliver_to_id%TYPE                 -- �o�א�ID
      , ship_date           xxwsh_order_headers_all.schedule_ship_date%TYPE            -- �o�ח\���
      , arrival_date        xxwsh_order_headers_all.schedule_arrival_date%TYPE         -- ���ח\���
      , tran_type           xxwsh_order_headers_all.order_type_id%TYPE                 -- �o�Ɍ`��ID
      , tran_type_name      xxwsh_oe_transaction_types_v.transaction_type_name%TYPE    -- �o�Ɍ`�Ԗ�
      , carry_code          xxwsh_order_headers_all.freight_carrier_code%TYPE          -- �^���Ǝ�
      , career_id           xxwsh_order_headers_all.career_id%TYPE                     -- �^���Ǝ�ID
      , sum_weight          xxwsh_order_headers_all.sum_weight%TYPE                    -- �ύڏd�ʍ��v
      , sum_capacity        xxwsh_order_headers_all.sum_capacity%TYPE                  -- �ύڗe�ύ��v
      , max_ship_method     xxwsh_intensive_carriers_tmp.max_shipping_method_code%TYPE -- �ő�z���敪
      , w_c_class           xxwsh_order_headers_all.weight_capacity_class%TYPE         -- �d�ʗe�ϋ敪
      , max_weight          xxwsh_intensive_carriers_tmp.max_weight%TYPE               -- �ő�ύڏd��
      , max_capacity        xxwsh_intensive_carriers_tmp.max_capacity%TYPE             -- �ő�ύڗe��
-- 2008/10/16 H.Itou Del Start T_S_625
--      , fix_ship_method_cd  xxwsh_mixed_carriers_tmp.fixed_shipping_method_code%TYPE   -- �C���z���敪
-- 2008/10/16 H.Itou Del End
      , small_quantity      xxwsh_order_headers_all.small_quantity%TYPE                -- ������
    );
--
    TYPE get_cur_ttype IS TABLE OF get_cur_rtype INDEX BY BINARY_INTEGER;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR small_amount_cur IS
      SELECT  xict.intensive_no               int_no              -- �W��No
            , xict.transaction_type           ship_type           -- �������:�o�׈˗�
            , xict.intensive_source_no        int_source_no       -- �W��No
-- 2008/10/16 H.Itou Del Start T_S_625
--            , xmct.delivery_no                delivery_no         -- �z��No
-- 2008/10/16 H.Itou Del End
            , xoha.request_no                 req_no              -- �˗�No
            , xoha.deliver_from               deliver_from        -- �o�׌��ۊǏꏊ
            , xoha.deliver_from_id            deliver_from_id     -- �o�׌�ID
            , xoha.deliver_to                 deliver_to          -- �o�א�
            , xoha.deliver_to_id              deliver_to_id       -- �o�א�ID
            , xoha.schedule_ship_date         ship_date           -- �o�ח\���
            , xoha.schedule_arrival_date      arrival_date        -- ���ח\���
            , xoha.order_type_id              tran_type           -- �o�Ɍ`��ID
            , xotv.transaction_type_name      tran_type_name      -- �o�Ɍ`�Ԗ�
            , xoha.freight_carrier_code       carry_code          -- �^���Ǝ�
            , xoha.career_id                  career_id           -- �^���Ǝ�ID
            , xoha.sum_weight                 sum_weight          -- �ύڏd�ʍ��v
            , xoha.sum_capacity               sum_capacity        -- �ύڗe�ύ��v
            , xict.max_shipping_method_code   max_ship_method     -- �ő�z���敪
            , xoha.weight_capacity_class      w_c_class           -- �d�ʗe�ϋ敪
            , xict.max_weight                 max_weight          -- �ő�ύڏd��
            , xict.max_capacity               max_capacity        -- �ő�ύڗe��
-- 2008/10/16 H.Itou Del Start T_S_625
--            , xmct.fixed_shipping_method_code fix_ship_method_cd  -- �C���z���敪
-- 2008/10/16 H.Itou Del End
            , xoha.small_quantity             small_quantity      -- ������
-- 2008/10/16 H.Itou Del Start T_S_625
--        FROM  xxwsh_mixed_carriers_tmp        xmct                -- �����z�ԍ��ڒ��ԃe�[�u��
-- 2008/10/16 H.Itou Del End
-- 2008/10/16 H.Itou Mod Start T_S_625
--            , xxwsh_intensive_carriers_tmp    xict                -- �����z�ԏW�񒆊ԃe�[�u��
         FROM xxwsh_intensive_carriers_tmp   xict                -- �����z�ԏW�񒆊ԃe�[�u��
-- 2008/10/16 H.Itou Mod End
            , xxwsh_intensive_carrier_ln_tmp  xicl                -- �����z�ԏW�񒆊Ԗ��׃e�[�u��
            , xxwsh_order_headers_all         xoha                -- �󒍃w�b�_�A�h�I��
-- 2008/10/16 H.Itou Del Start T_S_625
--            , xxwsh_ship_method_v             xsmv                -- �z���敪���View
-- 2008/10/16 H.Itou Del End
            , xxwsh_oe_transaction_types_v    xotv                -- �󒍃^�C�v���View
-- 2008/10/16 H.Itou Del Start T_S_625
--       WHERE  xict.intensive_no = xmct.intensive_no               -- �W��No
-- 2008/10/16 H.Itou Del End
-- 2008/10/16 H.Itou Mod Start T_S_625
--         AND  xict.intensive_no = xicl.intensive_no               -- �W��No
       WHERE  xict.intensive_no = xicl.intensive_no               -- �W��No
-- 2008/10/16 H.Itou Mod End
-- 2008/10/16 H.Itou Del Start T_S_625
--         AND  xmct.fixed_shipping_method_code = xsmv.ship_method_code
--                                                                  -- �z���敪
--         AND  xsmv.small_amount_class = cv_an_object              -- �����敪
-- 2008/10/16 H.Itou Del End
         AND  xicl.request_no = xoha.request_no                   -- �˗�No
         AND  xoha.latest_external_flag = cv_yes                  -- �ŐV�t���O
         AND  xoha.order_type_id = xotv.transaction_type_id       -- ����^�C�vID
-- 2008/10/16 H.Itou Add Start T_S_625
         AND  xict.intensive_no = iv_intensive_no                 -- �W��No
-- 2008/10/16 H.Itou Add End
-- Ver1.7 M.Hokkanji START
--         AND  xoha.mixed_no IS NULL                               -- ���ڌ�No
-- Ver1.7 M.Hokkanji END
      UNION ALL
      SELECT  xict.intensive_no               int_no              -- �W��No
            , xict.transaction_type           ship_type           -- �������:�o�׈˗�
            , xict.intensive_source_no        int_source_no       -- �W��No
-- 2008/10/16 H.Itou Del Start T_S_625
--            , xmct.delivery_no                delivery_no         -- �z��No
-- 2008/10/16 H.Itou Del End
            , xmrih.mov_num                   req_no              -- �˗�No
            , xmrih.shipped_locat_code        deliver_from        -- �o�׌��ۊǏꏊ
            , xmrih.shipped_locat_id          deliver_from_id     -- �o�׌�ID
            , xmrih.ship_to_locat_code        deliver_to          -- �o�א�
            , xmrih.ship_to_locat_id          deliver_to_id       -- �o�א�ID
            , xmrih.schedule_ship_date        ship_date           -- �o�ח\���
            , xmrih.schedule_arrival_date     arrival_date        -- ���ח\���
            , NULL                            tran_type           -- �o�Ɍ`��ID
            , NULL                            tran_type_name      -- �o�Ɍ`�Ԗ�
            , xmrih.freight_carrier_code      carry_code          -- �^���Ǝ�
            , xmrih.career_id                 career_id           -- �^���Ǝ�ID
            , xmrih.sum_weight                sum_weight          -- �ύڏd�ʍ��v
            , xmrih.sum_capacity              sum_capacity        -- �ύڗe�ύ��v
            , xict.max_shipping_method_code   max_ship_method     -- �ő�z���敪
            , xmrih.weight_capacity_class     w_c_class           -- �d�ʗe�ϋ敪
            , xict.max_weight                 max_weight          -- �ő�ύڏd��
            , xict.max_capacity               max_capacity        -- �ő�ύڗe��
-- 2008/10/16 H.Itou Del Start T_S_625
--            , xmct.fixed_shipping_method_code fix_ship_method_cd  -- �C���z���敪
-- 2008/10/16 H.Itou Del End
            , xmrih.small_quantity            small_quantity      -- ������
-- 2008/10/16 H.Itou Del Start T_S_625
--        FROM  xxwsh_mixed_carriers_tmp        xmct                -- �����z�ԍ��ڒ��ԃe�[�u��
-- 2008/10/16 H.Itou Del End
-- 2008/10/16 H.Itou Mod Start T_S_625
         FROM xxwsh_intensive_carriers_tmp    xict                -- �����z�ԏW�񒆊ԃe�[�u��
-- 2008/10/16 H.Itou Mod End
            , xxwsh_intensive_carrier_ln_tmp  xicl                -- �����z�ԏW�񒆊Ԗ��׃e�[�u��
            , xxinv_mov_req_instr_headers     xmrih               -- �ړ��˗�/�w���w�b�_�A�h�I��
-- 2008/10/16 H.Itou Del Start T_S_625
--            , xxwsh_ship_method_v             xsmv                -- �z���敪���View
-- 2008/10/16 H.Itou Del End
-- 2008/10/16 H.Itou Del Start T_S_625
--       WHERE  xict.intensive_no = xmct.intensive_no               -- �W��No
-- 2008/10/16 H.Itou Del End
-- 2008/10/16 H.Itou Mod Start T_S_625
--         AND  xict.intensive_no = xicl.intensive_no               -- �W��No
       WHERE  xict.intensive_no = xicl.intensive_no               -- �W��No
-- 2008/10/16 H.Itou Mod End
-- 2008/10/16 H.Itou Del Start T_S_625
--         AND  xmct.fixed_shipping_method_code = xsmv.ship_method_code
--                                                                  -- �z���敪
--         AND  xsmv.small_amount_class = cv_an_object              -- �����敪
-- 2008/10/16 H.Itou Del End
         AND  xicl.request_no = xmrih.mov_num                     -- �˗�No
-- 2008/10/16 H.Itou Add Start T_S_625
         AND  xict.intensive_no = iv_intensive_no                 -- �W��No
-- 2008/10/16 H.Itou Add End
      ;
--
    -- *** ���[�J���E���R�[�h ***
    lt_get_tab get_cur_ttype;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
debug_log(FND_FILE.LOG,'�y�����z�����쐬�����z');
--
    -- PL/SQL�\������
    lt_int_no_tab.DELETE;         -- �W��No
    lt_tran_type_tab.DELETE;      -- �������
    lt_int_source_tab.DELETE;     -- �W��No
    lt_deli_from_tab.DELETE;      -- �z����
    lt_deli_from_id_tab.DELETE;   -- �z����ID
    lt_deli_to_tab.DELETE;        -- �z����
    lt_deli_to_id_tab.DELETE;     -- �z����ID
    lt_ship_date_tab.DELETE;      -- �o�ɗ\���
    lt_arvl_date_tab.DELETE;      -- ���ח\���
    lt_tran_type_nm_tab.DELETE;   -- �o�Ɍ`��
    lt_carrier_code_tab.DELETE;   -- �^���Ǝ�
    lt_carrier_id_tab.DELETE;     -- �^���Ǝ�ID
    lt_sum_weight_tab.DELETE;     -- �W�񍇌v�d��
    lt_sum_capa_tab.DELETE;       -- �W�񍇌v�e��
    lt_max_ship_cd_tab.DELETE;    -- �ő�z���敪
    lt_weight_capa_tab.DELETE;    -- �d�ʗe�ϋ敪
    lt_max_weight_tab.DELETE;     -- �ő�ύڏd��
    lt_max_capa_tab.DELETE;       -- �ő�ύڗe��
    lt_fix_ship_method_cd.DELETE; -- �C���z���敪
    lt_delivery_no_tab.DELETE;    -- �z��No
    lt_int_no_lines_tab.DELETE;   -- �W��No
    lt_request_no_tab.DELETE;     -- �˗�No
    lt_sum_case_qty_tab.DELETE;   -- �P�[�X��
--
    -- �����z�ԍ��ڒ��ԃe�[�u���o�^�pPL/SQL�\
    lt_intensive_no_tab.DELETE;         -- �W��No
    lt_mixed_delivery_no_tab.DELETE;    -- �z��No
    lt_fixed_ship_code_tab.DELETE;      -- �C���z���敪
    lt_mixed_class_tab.DELETE;          -- ���ڎ��
    lt_mixed_total_weight_tab.DELETE;   -- ���ڍ��v�d��
    lt_mixed_total_capacity_tab.DELETE; -- ���ڍ��v�e��
    lt_mixed_no_tab.DELETE;             -- ���ڌ�No
--
    OPEN small_amount_cur;
    FETCH small_amount_cur BULK COLLECT INTO lt_get_tab;
    CLOSE small_amount_cur;
--
    <<small_amount_loop>>
    FOR ln_cnt IN 1..lt_get_tab.COUNT LOOP
--
debug_log(FND_FILE.LOG,'�����J�n');
--
      ln_loop_cnt := ln_loop_cnt + 1;
--
debug_log(FND_FILE.LOG,'���[�v�J�E���g�F'||ln_loop_cnt);
--
      -- PL/SQL�\�Ɋi�[
      lt_int_no_tab(ln_loop_cnt)          := lt_get_tab(ln_loop_cnt).int_no;          -- �W��No
      lt_tran_type_tab(ln_loop_cnt)       := lt_get_tab(ln_loop_cnt).ship_type;       -- �������
      lt_int_source_tab(ln_loop_cnt)      := lt_get_tab(ln_loop_cnt).int_source_no;   -- �W��No
      lt_deli_from_tab(ln_loop_cnt)       := lt_get_tab(ln_loop_cnt).deliver_from;    -- �z����
      lt_deli_from_id_tab(ln_loop_cnt)    := lt_get_tab(ln_loop_cnt).deliver_from_id; -- �z����ID
      lt_deli_to_tab(ln_loop_cnt)         := lt_get_tab(ln_loop_cnt).deliver_to;      -- �z����
      lt_deli_to_id_tab(ln_loop_cnt)      := lt_get_tab(ln_loop_cnt).deliver_to_id;   -- �z����ID
      lt_ship_date_tab(ln_loop_cnt)       := lt_get_tab(ln_loop_cnt).ship_date;       -- �o�ɗ\���
      lt_arvl_date_tab(ln_loop_cnt)       := lt_get_tab(ln_loop_cnt).arrival_date;    -- ���ח\���
      lt_tran_type_nm_tab(ln_loop_cnt)    := lt_get_tab(ln_loop_cnt).tran_type;       -- �o�Ɍ`��
      lt_carrier_code_tab(ln_loop_cnt)    := lt_get_tab(ln_loop_cnt).carry_code;      -- �^���Ǝ�
      lt_carrier_id_tab(ln_loop_cnt)      := lt_get_tab(ln_loop_cnt).career_id;       -- �^���Ǝ�ID
      lt_sum_weight_tab(ln_loop_cnt)      := lt_get_tab(ln_loop_cnt).sum_weight;      -- �ύڍ��v�d��
      lt_sum_capa_tab(ln_loop_cnt)        := lt_get_tab(ln_loop_cnt).sum_capacity;    -- �ύڍ��v�e��
      lt_max_ship_cd_tab(ln_loop_cnt)     := lt_get_tab(ln_loop_cnt).max_ship_method; -- �ő�z���敪
      lt_weight_capa_tab(ln_loop_cnt)     := lt_get_tab(ln_loop_cnt).w_c_class;       -- �d�ʗe�ϋ敪
      lt_max_weight_tab(ln_loop_cnt)      := lt_get_tab(ln_loop_cnt).max_weight;      -- �ő�ύڏd��
      lt_max_capa_tab(ln_loop_cnt)        := lt_get_tab(ln_loop_cnt).max_capacity;    -- �ő�ύڗe��
-- 2008/10/16 H.Itou Del Start T_S_625
--      lt_fix_ship_method_cd(ln_loop_cnt)  := lt_get_tab(ln_loop_cnt).fix_ship_method_cd;
--                                                                                      -- �C���z���敪
--      lt_delivery_no_tab(ln_loop_cnt)     := lt_get_tab(ln_loop_cnt).delivery_no;     -- �z��No
-- 2008/10/16 H.Itou Del End
-- 2008/10/30 H.Itou Mod Start �����e�X�g�w�E526 ���[�t�̏ꍇ�̔z���敪���ݒ肳��Ȃ��̂ŁAIN�p�����[�^�œn���ꂽ�l���Z�b�g����
      lt_fix_ship_method_cd(ln_loop_cnt)  := iv_ship_method;                          -- �C���z���敪
-- 2008/10/30 H.Itou Mod End
      lt_request_no_tab(ln_loop_cnt)      := lt_get_tab(ln_loop_cnt).req_no;          -- �˗�No
      lt_sum_case_qty_tab(ln_loop_cnt)    := lt_get_tab(ln_loop_cnt).small_quantity;   -- �P�[�X��
--
debug_log(FND_FILE.LOG,'PL/SQL�\�Ɋi�[');
debug_log(FND_FILE.LOG,'�W��No:'||lt_int_no_tab(ln_loop_cnt) );
--
      -- �W��NO�擾
      SELECT xxwsh_intensive_no_s1.NEXTVAL
      INTO   ln_intensive_no
      FROM   dual;
--
      lt_ins_int_no_tab(ln_loop_cnt)    := ln_intensive_no;         -- �W��No(�o�^�p)
--
debug_log(FND_FILE.LOG,'�o�^�p�W��No:'||lt_ins_int_no_tab(ln_loop_cnt));
--
    END LOOP small_amount_loop;
--
    -- ==============================
    --  �����z�Ԓ��ԃe�[�u���폜����
    -- ==============================
    -- �擾�����W��No�Ŋe���ԃe�[�u�����폜����
    -- �����z�ԏW�񒆊ԃe�[�u��
    FORALL ln_cnt_1 IN 1..lt_int_no_tab.COUNT
      DELETE FROM xxwsh_intensive_carriers_tmp
        WHERE intensive_no = lt_int_no_tab(ln_cnt_1)
    ;
--
debug_log(FND_FILE.LOG,'�����z�ԏW�񒆊ԃe�[�u���폜');
--
    -- �����z�ԏW�񒆊Ԗ��׃e�[�u��
    FORALL ln_cnt_2 IN 1..lt_int_no_tab.COUNT
      DELETE FROM xxwsh_intensive_carrier_ln_tmp
        WHERE intensive_no = lt_int_no_tab(ln_cnt_2)
    ;
--
debug_log(FND_FILE.LOG,'�����z�ԏW�񒆊Ԗ��׃e�[�u���폜');
--
    -- �����z�ԍ��ڒ��ԃe�[�u��
    FORALL ln_cnt_3 IN 1..lt_int_no_tab.COUNT
      DELETE FROM xxwsh_mixed_carriers_tmp
        WHERE intensive_no = lt_int_no_tab(ln_cnt_3)
    ;
--
debug_log(FND_FILE.LOG,'�����z�ԍ��ڒ��ԃe�[�u���폜');
--
--
debug_log(FND_FILE.LOG,'�������z�ԏW�񒆊ԃe�[�u���o�^�F�����z�����쐬����');
debug_log(FND_FILE.LOG,'�o�^���F'||lt_ins_int_no_tab.count);
debug_log(FND_FILE.LOG,'PLSQL�\�Flt_ins_int_no_tab');
    -- ==================================
    --  �����z�ԏW�񒆊ԃe�[�u���o�^����
    -- ==================================
    FORALL ln_cnt IN 1..lt_ins_int_no_tab.COUNT
      INSERT INTO xxwsh_intensive_carriers_tmp(   -- �����z�ԏW�񒆊ԃe�[�u��
          intensive_no              -- �W��No
        , transaction_type          -- �������
        , intensive_source_no       -- �W��No
        , deliver_from              -- �z����
        , deliver_from_id           -- �z����ID
        , deliver_to                -- �z����
        , deliver_to_id             -- �z����ID
        , schedule_ship_date        -- �o�ɗ\���
        , schedule_arrival_date     -- ���ח\���
        , transaction_type_name     -- �o�Ɍ`��
        , freight_carrier_code      -- �^���Ǝ�
        , carrier_id                -- �^���Ǝ�ID
        , intensive_sum_weight      -- �W�񍇌v�d��
        , intensive_sum_capacity    -- �W�񍇌v�e��
        , max_shipping_method_code  -- �ő�z���敪
        , weight_capacity_class     -- �d�ʗe�ϋ敪
        , max_weight                -- �ő�ύڏd��
        , max_capacity              -- �ő�ύڗe��
        )
        VALUES
        (
          lt_ins_int_no_tab(ln_cnt)     -- �W��No
        , lt_tran_type_tab(ln_cnt)      -- �������
        , lt_int_source_tab(ln_cnt)     -- �W��No
        , lt_deli_from_tab(ln_cnt)      -- �z����
        , lt_deli_from_id_tab(ln_cnt)   -- �z����ID
        , lt_deli_to_tab(ln_cnt)        -- �z����
        , lt_deli_to_id_tab(ln_cnt)     -- �z����ID
        , lt_ship_date_tab(ln_cnt)      -- �o�ɗ\���
        , lt_arvl_date_tab(ln_cnt)      -- ���ח\���
        , lt_tran_type_nm_tab(ln_cnt)   -- �o�Ɍ`��
        , lt_carrier_code_tab(ln_cnt)   -- �^���Ǝ�
        , lt_carrier_id_tab(ln_cnt)     -- �^���Ǝ�ID
        , lt_sum_weight_tab(ln_cnt)     -- �W�񍇌v�d��
        , lt_sum_capa_tab(ln_cnt)       -- �W�񍇌v�e��
        , lt_max_ship_cd_tab(ln_cnt)    -- �ő�z���敪
        , lt_weight_capa_tab(ln_cnt)    -- �d�ʗe�ϋ敪
        , lt_max_weight_tab(ln_cnt)     -- �ő�ύڏd��
        , lt_max_capa_tab(ln_cnt)       -- �ő�ύڗe��
        );
--
debug_log(FND_FILE.LOG,'�����z�ԏW�񒆊Ԗ��׃e�[�u���o�^���F'||lt_ins_int_no_tab.COUNT);
debug_log(FND_FILE.LOG,'PLSQL�\�Flt_ins_int_no_tab');
--
    FORALL ln_cnt_2 IN 1..lt_ins_int_no_tab.COUNT
      INSERT INTO xxwsh_intensive_carrier_ln_tmp(  -- �����z�ԏW�񒆊Ԗ��׃e�[�u��
          intensive_no                -- �W��No
        , request_no                  -- �˗�No
        )
        VALUES
        (
          lt_ins_int_no_tab(ln_cnt_2) -- �W��No
        , lt_request_no_tab(ln_cnt_2) -- �˗�No
        );
debug_log(FND_FILE.LOG,'�����z�ԏW�񒆊Ԗ��׃e�[�u���o�^');
--
    -- ���i�敪���h�����N�̏ꍇ�̂ݔz���敪�ݒ���s��
    IF (gv_prod_class = gv_prod_cls_drink) THEN
debug_log(FND_FILE.LOG,'�ő�P�[�X���`�F�b�N�F���i�敪�F�h�����N');
      -- ==================================
      --  �z���敪�ݒ�
      -- ==================================
      -- �ő�P�[�X���擾
      SELECT  xsmv.max_case_quantity    -- �ő�P�[�X��
      INTO    lt_max_case_qty
      FROM    xxwsh_ship_method_v xsmv  -- �N�C�b�N�R�[�h
      WHERE   xsmv.ship_method_code = cv_small_amount_b
      ;
debug_log(FND_FILE.LOG,'����B�P�[�X��:'||lt_max_case_qty);
debug_log(FND_FILE.LOG,'lt_intensive_no_tab.COUNT:'||lt_intensive_no_tab.COUNT);
--
      <<reset_ship_method>>
--2008.05.27 D.Sugahara �s�No9�Ή�->
--      FOR rec_cnt IN 1..lt_intensive_no_tab.COUNT LOOP
      FOR rec_cnt IN 1..lt_ins_int_no_tab.COUNT LOOP
--2008.05.27 D.Sugahara �s�No9�Ή�<-
--
        ln_loop_cnt_2 := ln_loop_cnt_2 + 1;
--
        lt_intensive_no_tab(ln_loop_cnt_2)  := lt_int_no_tab(ln_loop_cnt_2);  -- �W��No
--
debug_log(FND_FILE.LOG,'�P�[�X�����v:'||lt_sum_case_qty_tab(ln_loop_cnt_2));
        -- �C���z���敪
        IF (lt_sum_case_qty_tab(ln_loop_cnt_2) > lt_max_case_qty) THEN
--
          lt_fix_ship_method_cd(ln_loop_cnt_2)     := cv_small_amount_a;    -- ����A
--
        ELSIF (lt_sum_case_qty_tab(ln_loop_cnt_2) <= lt_max_case_qty) THEN
--
          lt_fix_ship_method_cd(ln_loop_cnt_2)     := cv_small_amount_b;    -- ����B
--
        END IF;
--
      END LOOP reset_ship_method;
--
    END IF;
--
-- 2008/10/01 H.Itou Del Start PT 6-1_27 �w�E18
--for ln_cnt_3 in 1.. lt_ins_int_no_tab.COUNT loop
--debug_log(FND_FILE.LOG,'�W��No:'||lt_ins_int_no_tab(ln_cnt_3));           -- �W��No
--debug_log(FND_FILE.LOG,'�z��No:'||lt_delivery_no_tab(ln_cnt_3));          -- �z��No
--debug_log(FND_FILE.LOG,'�����No:'||lt_int_source_tab(ln_cnt_3));           -- �����No
--debug_log(FND_FILE.LOG,'�C���z���敪:'||lt_fix_ship_method_cd(ln_cnt_3));      -- �C���z���敪
--debug_log(FND_FILE.LOG,'���ڍ��v�d��:'||lt_sum_weight_tab(ln_cnt_3));   -- ���ڍ��v�d��
--debug_log(FND_FILE.LOG,'���ڍ��v�e��:'||lt_sum_capa_tab(ln_cnt_3)); -- ���ڍ��v�e��
--end loop;
-- 2008/10/01 H.Itou Del End
    -- ==================================
    --  ���z��NO�擾
    -- ==================================
    FOR loop_cnt IN 1..lt_ins_int_no_tab.COUNT LOOP
--
      SELECT xxwsh_temp_delivery_no_s1.NEXTVAL
      INTO   ln_temp_ship_no
      FROM   dual;
--
      lt_mixed_delivery_no_tab(loop_cnt)  := ln_temp_ship_no;
--
    END LOOP;
--
    -- ==================================
    --  �����z�ԍ��ڒ��ԃe�[�u���o�^
    -- ==================================
    FORALL ln_cnt_3 IN 1..lt_ins_int_no_tab.COUNT
      INSERT INTO xxwsh_mixed_carriers_tmp(
          intensive_no                -- �W��No
        , delivery_no                 -- �z��No
        , default_line_number         -- �����No
        , fixed_shipping_method_code  -- �C���z���敪
        , mixed_class                 -- ���ڎ��
        , mixed_total_weight          -- ���ڍ��v�d��
        , mixed_total_capacity        -- ���ڍ��v�e��
        , mixed_no                    -- ���ڌ�No
      )
       VALUES
      (
          lt_ins_int_no_tab(ln_cnt_3)         -- �W��No
        , lt_mixed_delivery_no_tab(ln_cnt_3)  -- ���z��No
--2008.5.26 D.Sugahara �s�No9�Ή�->        
--        , lt_int_source_tab(ln_cnt_3)         -- �����No
        , lt_request_no_tab(ln_cnt_3)         -- �����No (1�z��1�˗��̂��߁A���̈˗�/�ړ�No�j
--2008.5.26 D.Sugahara �s�No9�Ή�<-
        , lt_fix_ship_method_cd(ln_cnt_3)     -- �C���z���敪
        , gv_mixed_class_int                  -- ���ڎ��
        , lt_sum_weight_tab(ln_cnt_3)         -- ���ڍ��v�d��
        , lt_sum_capa_tab(ln_cnt_3)           -- ���ڍ��v�e��
        , NULL                                -- ���ڌ�No
      );
debug_log(FND_FILE.LOG,'�����z�ԍ��ڒ��ԃe�[�u���o�^');
--
debug_log(FND_FILE.LOG,'�����z�����쐬�����I��');
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
  END set_small_sam_class;
--
  /**********************************************************************************
   * Procedure Name   : get_intensive_tmp
   * Description      : �W�񒆊ԏ�񒊏o����(B-9)
   ***********************************************************************************/
  PROCEDURE get_intensive_tmp(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_intensive_tmp'; -- �v���O������
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
    cn_consolid_parmit    CONSTANT NUMBER       := 1;   -- ���ڋ��t���O�F����
    cv_finish_intensive   CONSTANT VARCHAR2(1)  := '1'; -- �W���
    cv_consolid           CONSTANT VARCHAR2(1)  := '1'; -- ���ډۃt���O�擾
    cv_ship_method        CONSTANT VARCHAR2(1)  := '2'; -- �z���敪�擾
    cv_allocation         CONSTANT VARCHAR2(1)  := '1'; -- �����z�ԑΏۋ敪�F�Ώ�
    cv_judge_ship_method  CONSTANT VARCHAR2(1)  := '0'; -- �z���敪���ڔ���
--2008.05.27 D.Sugahara�s�No9 �Ή�->
    cv_an_object          CONSTANT VARCHAR2(1)  := '1'; -- �Ώ�    
--2008.05.27 D.Sugahara�s�No9 �Ή�<-
-- Ver1.3 M.Hokkanji Start
    cv_table_name_con     CONSTANT VARCHAR2(30) := '�z���敪���VIEW2';
    cv_ship_method_name   CONSTANT VARCHAR2(30) := '���ڔz���敪';
    cv_effective_date     CONSTANT VARCHAR2(30) := '���';
    cv_consolid_false     CONSTANT NUMBER       := 0;   -- ���ڋ��t���O�F�s����
-- Ver1.3 M.Hokkanji End
-- 2009/01/05 H.Itou Add Start �{�ԏ�Q#879
    cv_pre_save           CONSTANT VARCHAR2(1) := '1';           -- ���_���ړo�^�F�o�^��
    cv_not_save           CONSTANT VARCHAR2(1) := '0';           -- ���_���ړo�^�F���o�^
-- 2009/01/05 H.Itou Add End
--
    -- *** ���[�J���ϐ� ***
    TYPE get_intensive_tmp_rtype IS RECORD(
        intensive_no              xxwsh_intensive_carriers_tmp.intensive_no%TYPE  -- �W��No
      , transaction_type          xxwsh_intensive_carriers_tmp.transaction_type%TYPE
                                                                                  -- ������ʁi�z�ԁj
      , intensive_source_no       xxwsh_intensive_carriers_tmp.intensive_source_no%TYPE
                                                                                  -- �W��No
      , deliver_from              xxwsh_intensive_carriers_tmp.deliver_from%TYPE  -- �z����
      , deliver_to                xxwsh_intensive_carriers_tmp.deliver_to%TYPE    -- �z����
      , schedule_ship_date        xxwsh_intensive_carriers_tmp.schedule_ship_date%TYPE
                                                                                  -- �o�ɗ\���
      , schedule_arrival_date     xxwsh_intensive_carriers_tmp.schedule_arrival_date%TYPE
                                                                                  -- ���ח\���
      , transaction_type_name     xxwsh_intensive_carriers_tmp.transaction_type_name%TYPE
                                                                                  -- �o�Ɍ`��
      , freight_carrier_code      xxwsh_intensive_carriers_tmp.freight_carrier_code%TYPE
                                                                                  -- �^���Ǝ�
      , head_sales_branch         xxwsh_intensive_carriers_tmp.head_sales_branch%TYPE
                                                                                  -- �Ǌ����_
      , reserve_order             xxwsh_intensive_carriers_tmp.reserve_order%TYPE -- ������
      , intensive_sum_weight      xxwsh_intensive_carriers_tmp.intensive_sum_weight%TYPE
                                                                                  -- �W�񍇌v�d��
      , intensive_sum_capacity    xxwsh_intensive_carriers_tmp.intensive_sum_capacity%TYPE
                                                                                  -- �W�񍇌v�e��
      , max_shipping_method_code  xxwsh_intensive_carriers_tmp.max_shipping_method_code%TYPE
                                                                                  -- �ő�z���敪
      , weight_capacity_class     xxwsh_intensive_carriers_tmp.weight_capacity_class%TYPE
                                                                                  -- �d�ʗe�ϋ敪
      , max_weight                xxwsh_intensive_carriers_tmp.max_weight%TYPE    -- �ő�ύڏd��
      , max_capacity              xxwsh_intensive_carriers_tmp.max_capacity%TYPE  -- �ő�ύڗe��
      , finish_sum_flag           VARCHAR2(1)                                     -- �W��σt���O
-- 2009/01/05 H.Itou Add Start �{�ԏ�Q#879
      , pre_saved_flg             xxwsh_carriers_sort_tmp.pre_saved_flg%TYPE      -- ���_���ړo�^�σt���O
-- 2009/01/05 H.Itou Add End
      );
--
    -- �����z�ԏW�񒆊ԃe�[�u���pPLSQL�\�^
    TYPE get_intensive_tmp_ttype IS TABLE OF get_intensive_tmp_rtype INDEX BY BINARY_INTEGER;
--
    lt_intensive_tab            get_intensive_tmp_ttype;    -- �����z�ԏW�񒆊ԃe�[�u���pPLSQL�\
--
    -- ���ڍσf�[�^�J�E���g�ێ��p
    TYPE mixed_cnt_ttype IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    lt_mixed_cnt_tab  mixed_cnt_ttype;    -- ���ڍσf�[�^�J�E���g�ێ��p�e�[�u��
--
    -- �����z�ԍ��ڃe�[�u���o�^�pPLSQL�\
    lt_intensive_no_tab         intensive_no_ttype;         -- �W��No�p
    lt_mixed_class_tab          mixed_class_ttype;          -- ���ڎ�ʗp
    lt_mix_total_weight         mixed_total_weight_ttype;   -- ���ڍ��v�d��
    lt_mix_total_capacity       mixed_total_capacity_ttype; -- ���ڍ��v�e��
--
    -- ���ʊ֐��p
    lv_loading_over_class       VARCHAR2(1);                          -- �ύڃI�[�o�[�敪
    lv_ship_optimization        xxcmn_ship_methods.ship_method%TYPE;  -- �o�ו��@
    ln_load_efficiency_weight   NUMBER;                               -- �d�ʐύڌ���
    ln_load_efficiency_capacity NUMBER;                               -- �e�ϐύڌ���
    lv_mixed_ship_method        VARCHAR2(2);                          -- ���ڔz���敪
--
    -- ��r�p�ϐ�
    lt_prev_ship_date       xxwsh_carriers_sort_tmp.schedule_ship_date%TYPE;    -- �o�ɓ�
    lt_prev_arrival_date    xxwsh_carriers_sort_tmp.schedule_arrival_date%TYPE; -- ���ד�
    lt_prev_ship_from       xxwsh_carriers_sort_tmp.deliver_from%TYPE;          -- �o�׌�
    lt_prev_ship_to         xxwsh_carriers_sort_tmp.deliver_to%TYPE;            -- �o�א�
    lt_prev_freight_carrier xxwsh_carriers_sort_tmp.freight_carrier_code%TYPE;  -- �^���Ǝ�
    lt_prev_w_c_class       xxwsh_carriers_sort_tmp.weight_capacity_class%TYPE; -- �d�ʗe�ϋ敪
--
    -- �O���[�v1���ڃf�[�^�i�[�p
    first_intensive_no              xxwsh_intensive_carriers_tmp.intensive_no%TYPE;
                                                                                -- �W��No
    first_transaction_type          xxwsh_intensive_carriers_tmp.transaction_type%TYPE;
                                                                                -- �������
    first_intensive_source_no       xxwsh_intensive_carriers_tmp.intensive_source_no%TYPE;
                                                                                -- �W��No
    first_deliver_from              xxwsh_intensive_carriers_tmp.deliver_from%TYPE;
                                                                                -- �z����
    first_deliver_to                xxwsh_intensive_carriers_tmp.deliver_to%TYPE;
                                                                                -- �z����
    first_schedule_ship_date        xxwsh_intensive_carriers_tmp.schedule_ship_date%TYPE;
                                                                                -- �o�ɗ\���
    first_schedule_arrival_date     xxwsh_intensive_carriers_tmp.schedule_arrival_date%TYPE;
                                                                                -- ���ח\���
    first_transaction_type_name     xxwsh_intensive_carriers_tmp.transaction_type_name%TYPE;
                                                                                -- �o�Ɍ`��
    first_freight_carrier_code      xxwsh_intensive_carriers_tmp.freight_carrier_code%TYPE;
                                                                                -- �^���Ǝ�
    first_intensive_sum_weight      xxwsh_intensive_carriers_tmp.intensive_sum_weight%TYPE;
                                                                                -- �W�񍇌v�d��
    first_intensive_sum_capacity    xxwsh_intensive_carriers_tmp.intensive_sum_capacity%TYPE;
                                                                                -- �W�񍇌v�e��
    first_max_shipping_method_code  xxwsh_intensive_carriers_tmp.max_shipping_method_code%TYPE;
                                                                                -- �ő�z���敪
    first_weight_capacity_class     xxwsh_intensive_carriers_tmp.weight_capacity_class%TYPE;
                                                                                -- �d�ʗe�ϋ敪
    first_max_weight                xxwsh_intensive_carriers_tmp.max_weight%TYPE;
                                                                                -- �ő�ύڏd��
    first_max_capacity              xxwsh_intensive_carriers_tmp.max_capacity%TYPE;
                                                                                -- �ő�ύڗe��
-- 2009/01/05 H.Itou Mod Start �{�ԏ�Q#879
    first_pre_saved_flg             xxwsh_carriers_sort_tmp.pre_saved_flg%TYPE; -- ���_���ړo�^�σt���O
-- 2009/01/05 H.Itou Mod End
--
    ln_intensive_weight       NUMBER DEFAULT 0;                                 -- ���ڍ��v�d��
    ln_intensive_capacity     NUMBER DEFAULT 0;                                 -- ���ڍ��v�e��
    lv_consolid_flag          VARCHAR2(1);                                  -- ���ډۃt���O:���[�g
    lv_consolid_flag_ships    VARCHAR2(1);                                  -- ���ډۃt���O:�z���敪
    lv_cdkbn_1                xxcmn_delivery_lt2_v.code_class1%TYPE;        -- �R�[�h�敪�P
    lv_cdkbn_2                xxcmn_delivery_lt2_v.code_class2%TYPE;        -- �R�[�h�敪�Q
    lv_cdkbn_2_opt            VARCHAR2(1);                                  -- �R�[�h�敪�Q(�œK���p)
-- Ver1.3 M.Hokkanji Start
    lv_cdkbn_2_con            VARCHAR2(1);                                  -- �R�[�h�敪�Q(���ڃ`�F�b�N�p)
-- Ver1.3 M.Hokkanji End
    lv_mixed_flag             VARCHAR2(1) DEFAULT NULL;                     -- ���ڍσt���O
    lv_second_ship_to         xxwsh_intensive_carriers_tmp.deliver_to%TYPE; -- 2���ڂ̏o�א�
    lv_brake_flag             BOOLEAN DEFAULT FALSE;                        -- �u���C�N�t���O
    lv_next_ship_method_flag  BOOLEAN DEFAULT FALSE;                        -- ���̔z���敪�t���O
    lt_ship_method_cls        xxwsh_intensive_carriers_tmp.max_shipping_method_code%TYPE;
                                                                            -- ���̔z���敪
--
    ln_temp_ship_no           NUMBER;                 -- ���z��No
    lv_rerun_flag             VARCHAR2(1);            -- �Ď��s�t���O
    lb_finish_flag            BOOLEAN DEFAULT FALSE;  -- �I���t���O
    ln_finish_judge_cnt       NUMBER DEFAULT 0;       -- �I������J�E���g
    lb_last_data_flag         BOOLEAN DEFAULT FALSE;  -- �ŏI���R�[�h�t���O
    ln_for_ins_cnt            NUMBER;                 -- PLSQL�\�i�[�p�J�E���g(���ڎ��)
--
    ln_next_weight_capacity   NUMBER;                 -- ���̔z���敪�̏d�ʁE�e��
--
    ln_grp_sum_cnt            NUMBER DEFAULT 0;   -- �O���[�v�J�E���^
    ln_intensive_no_cnt       NUMBER DEFAULT 0;   -- ���ڃ��R�[�h�o�^�p�J�E���^
--
    ln_loop_cnt               NUMBER DEFAULT 0;   -- ���[�v�J�E���^
    ln_order_num_cnt          NUMBER DEFAULT 1;   -- �z���敪������
    ln_parent_no              NUMBER;             -- ����R�[�h�J�E���^
    ln_child_no               NUMBER;             -- ���ڑ��背�R�[�h�J�E���^
    ln_tab_ins_idx            NUMBER DEFAULT 0;   -- �����z�ԍ��ڒ��ԃe�[�u���o�^�p�J�E���^
--
debug_cnt number default 0;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_intensive_cur IS
      SELECT  xict.intensive_no             intensive_no              -- �W��No
            , xict.transaction_type         transaction_type          -- �������
            , xict.intensive_source_no      intensive_source_no       -- �W��No
            , xict.deliver_from             deliver_from              -- �z����
            , xict.deliver_to               deliver_to                -- �z����
            , xict.schedule_ship_date       schedule_ship_date        -- �o�ɗ\���
            , xict.schedule_arrival_date    schedule_arrival_date     -- ���ח\���
            , xict.transaction_type_name    transaction_type_name     -- �o�Ɍ`��
            , xict.freight_carrier_code     freight_carrier_code      -- �^���Ǝ�
            , xict.head_sales_branch        head_sales_branch         -- �Ǌ����_
            , DECODE(xict.reserve_order, NULL, 99999, xict.reserve_order) reserve_order
                                                                      -- ������
            , xict.intensive_sum_weight     intensive_sum_weight      -- �W�񍇌v�d��
            , xict.intensive_sum_capacity   intensive_sum_capacity    -- �W�񍇌v�e��
            , xict.max_shipping_method_code max_shipping_method_code  -- �ő�z���敪
            , xict.weight_capacity_class    weight_capacity_class     -- �d�ʗe�ϋ敪
            , xict.max_weight               max_weight                -- �ő�ύڏd��
            , xict.max_capacity             max_capacity              -- �ő�ύڗe��
            , NULL                          finish_sum_flag           -- �W��σt���O
-- 2009/01/05 H.Itou Add Start �{�ԏ�Q#879
            , xcst.pre_saved_flg            pre_saved_flg             -- ���_���ړo�^�σt���O
-- 2009/01/05 H.Itou Add End
      FROM    xxwsh_intensive_carriers_tmp xict  -- �����z�ԏW�񒆊ԃe�[�u��
-- 2009/01/05 H.Itou Add Start �{�ԏ�Q#879
            , xxwsh_carriers_sort_tmp      xcst  -- �����z�ԃ\�[�g�p���ԃe�[�u��
      WHERE   xict.intensive_source_no = xcst.request_no
-- 2009/01/05 H.Itou Add End
      ORDER BY  xict.schedule_ship_date       -- �o�ɗ\���
              , xict.schedule_arrival_date    -- ���ח\���
              , xict.deliver_from             -- �z����
              , xict.freight_carrier_code     -- �^���Ǝ�
              , xict.weight_capacity_class    -- �d�ʗe�ϋ敪
              , xict.reserve_order            -- ������
              , xict.head_sales_branch        -- �Ǌ����_
              , DECODE (xict.weight_capacity_class, gv_weight
                        , xict.intensive_sum_weight         -- �W��d�ʍ��v
-- 2009/01/05 H.Itou Add Start �{�ԏ�Q#879
--                        , xict.weight_capacity_class) DESC  -- �W�񍇌v�e��
                        , xict.intensive_sum_capacity) DESC  -- �W�񍇌v�e��
-- 2009/01/05 H.Itou Add End
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** �T�u�v���O���� ***
    -- ============================
    -- ���ډۃt���O/�z���敪�擾
    -- ============================
    PROCEDURE get_consolidated_flag(
        iv_code_class1                IN xxcmn_delivery_lt2_v.code_class1%TYPE
      , iv_entering_despatching_code1 IN xxcmn_delivery_lt2_v.entering_despatching_code1%TYPE
      , iv_code_class2                IN xxcmn_delivery_lt2_v.code_class2%TYPE
      , iv_entering_despatching_code2 IN xxcmn_delivery_lt2_v.entering_despatching_code2%TYPE
      , iv_ship_method                IN xxwsh_intensive_carriers_tmp.max_shipping_method_code%TYPE
      , ov_consolidate_flag           OUT NOCOPY xxcmn_delivery_lt2_v.consolidated_flag%TYPE
      , ov_errbuf                     OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W --# �Œ� #
      , ov_retcode                    OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h   --# �Œ� #
      , ov_errmsg                     OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
    IS
      -- ===============================
      -- �Œ胍�[�J���萔
      -- ===============================
      cv_sub_prg_name   CONSTANT VARCHAR2(100) := '[get_consolidated_flag]'; -- �T�u�v���O������
--
      -- ���[�J���ϐ�
      lt_consolid_flag  xxcmn_delivery_lt2_v.consolidated_flag%TYPE;   -- ���ډۃt���O
      lv_ship_method    xxcmn_delivery_lt2_v.ship_method%TYPE;         -- �z���敪
--
    BEGIN
--
debug_log(FND_FILE.LOG,'�s���ډۃt���O�擾�t');
      -- �ϐ�������
      lt_consolid_flag  := NULL;
      lv_ship_method    := NULL;
--
debug_log(FND_FILE.LOG,'gd_date_from:'|| TO_CHAR(gd_date_from,'yyyy/mm/dd'));
debug_log(FND_FILE.LOG,'�R�[�h�敪1:'|| iv_code_class1);
debug_log(FND_FILE.LOG,'���o�ɏꏊ1:'|| iv_entering_despatching_code1);
debug_log(FND_FILE.LOG,'�R�[�h�敪2:'|| iv_code_class2);
debug_log(FND_FILE.LOG,'���o�ɏꏊ2:'|| iv_entering_despatching_code2);
      IF (iv_ship_method IS NULL) THEN
--
        -- ���[�g����
        BEGIN
--
-- 2008/10/24 H.Itou Mod Start T_TE080_BPO_600�w�E26
--          SELECT xdlv.consolidated_flag
          SELECT CASE 
                   -- ���i�敪���h�����N�̏ꍇ�A�h�����N���ډۃt���O
                   WHEN (gv_prod_class = gv_prod_cls_drink) THEN xdlv.consolidated_flag
                   -- ���i�敪�����[�t�̏ꍇ�A���[�t���ډۃt���O
                   ELSE                                          xdlv.leaf_consolidated_flag
                 END  consolidated_flag
-- 2008/10/24 H.Itou Mod End
            INTO lt_consolid_flag
-- 2008/10/01 H.Itou Mod Start PT 6-1_27 �w�E18 �o�ו��@LT�̊O�������̂Ȃ�xxcmn_delivery_lt3_v�ɕύX�B
--            FROM xxcmn_delivery_lt2_v xdlv                                        -- �z��L/T���VIEW2
            FROM xxcmn_delivery_lt3_v   xdlv
-- 2008/10/01 H.Itou Mod End PT 6-1_27 �w�E18
           WHERE xdlv.code_class1 = iv_code_class1                                -- �R�[�h�敪�P
             AND xdlv.entering_despatching_code1 = iv_entering_despatching_code1  -- ���o�ɏꏊ�P
             AND xdlv.code_class2 = iv_code_class2                                -- �R�[�h�敪�Q
             AND xdlv.entering_despatching_code2 = iv_entering_despatching_code2  -- ���o�ɏꏊ�Q
             AND xdlv.lt_start_date_active <= gd_date_from                        -- �z��LT�K�p�J�n��
             AND (xdlv.lt_end_date_active IS NULL
                  OR xdlv.lt_end_date_active   >= gd_date_from)               -- �z��LT�K�p�I����
-- 2008.05.21 D.Sugahara �s�No7�Ή�->
--  ���ډ۔��莞�͏o�ו��@�̓K�p�������Ȃ�
--             AND xdlv.sm_start_date_active <= gd_date_from                  -- �o�ו��@�K�p�J�n��
--             AND (xdlv.sm_end_date_active IS NULL
--                  OR xdlv.sm_end_date_active >= gd_date_from)               -- �o�ו��@�K�p�I����
-- 2008.05.21 D.Sugahara �s�No7�Ή�<-
-- 2008/10/24 H.Itou Del Start T_TE080_BPO_600�w�E26
--             AND xdlv.consolidated_flag = cn_consolid_parmit                  -- ���ډۃt���O�F��
--             AND ROWNUM = 1
-- 2008/10/24 H.Itou Del End
          ;
--
        EXCEPTION
--
          -- �f�[�^���Ȃ��ꍇ
          WHEN NO_DATA_FOUND THEN
            NULL;
debug_log(FND_FILE.LOG,'���[�g����:NO_DATA_FOUND');
        END;
--
-- 2008/10/24 H.Itou Mod Start T_TE080_BPO_600�w�E26
--        IF (lt_consolid_flag IS NOT NULL) THEN
        -- ���ډۃt���O���u�v�̏ꍇ�A�u�v��Ԃ��B
        IF (lt_consolid_flag = cn_consolid_parmit) THEN
-- 2008/10/24 H.Itou Mod End
          -- ���_���ځF����
          ov_consolidate_flag := cn_consolid_parmit;
--
-- 2008/10/24 H.Itou Add Start T_TE080_BPO_600�w�E26
        -- ���ډۃt���O���u�v�łȂ��ꍇ�ANULL��Ԃ��B
        ELSE
          ov_consolidate_flag := NULL;
-- 2008/10/24 H.Itou Add End
        END IF;
--
      ELSE
        -- �z���敪����
        BEGIN
          SELECT xdl.ship_method
            INTO lv_ship_method
            FROM xxcmn_delivery_lt2_v xdl                                   -- �z��L/T���VIEW2
           WHERE xdl.code_class1 = iv_code_class1                           -- �R�[�h�敪�P
             AND (xdl.entering_despatching_code1 = iv_entering_despatching_code1 -- ���o�ɏꏊ�P
              OR  xdl.entering_despatching_code1 = gv_all_z4)               -- 2008/07/14 Add
             AND xdl.code_class2 = iv_code_class2                           -- �R�[�h�敪�Q
             AND (xdl.entering_despatching_code2 = iv_entering_despatching_code2 -- ���o�ɏꏊ�Q
              OR  xdl.entering_despatching_code2 = DECODE(iv_code_class2,
                                                          gv_cdkbn_ship_to,
                                                          gv_all_z9,
                                                          gv_all_z4))       -- 2008/07/14 Add
             AND xdl.ship_method = iv_ship_method                           -- �z���敪
             AND xdl.lt_start_date_active <= gd_date_from                   -- �z��LT�K�p�J�n��
             AND (xdl.lt_end_date_active IS NULL
                  OR xdl.lt_end_date_active   >= gd_date_from)              -- �z��LT�K�p�I����
             AND xdl.sm_start_date_active <= gd_date_from                   -- �o�ו��@�K�p�J�n��
             AND (xdl.sm_end_date_active IS NULL
                  OR xdl.sm_end_date_active >= gd_date_from)                -- �o�ו��@�K�p�I����
             AND ROWNUM = 1
           ;
        EXCEPTION
          -- �f�[�^���Ȃ��ꍇ
          WHEN NO_DATA_FOUND THEN
            NULL;
--
debug_log(FND_FILE.LOG,'�z���敪����:NO_DATA_FOUND');
        END;
--
        IF (lv_ship_method IS NOT NULL) THEN
debug_log(FND_FILE.LOG,'���ڋ��t���O�F����');
          -- ���ڋ��t���O�F����
          ov_consolidate_flag  := cn_consolid_parmit;
        END IF;
--
      END IF;
--
debug_log(FND_FILE.LOG,'--------------------------');
--
    EXCEPTION
      -- *** ���ʊ֐���O�n���h�� ***
      WHEN global_api_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||lv_errbuf,1,5000);
        ov_retcode := gv_status_error;
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      WHEN global_api_others_expt THEN
        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
    END;
--
    -- ============================
    -- �z���敪�擾
    -- ============================
    PROCEDURE get_ship_method_class(
        iv_code_class1                IN xxcmn_delivery_lt_v.code_class1%TYPE
      , iv_entering_despatching_code1 IN xxcmn_delivery_lt_v.entering_despatching_code1%TYPE
      , iv_code_class2                IN xxcmn_delivery_lt_v.code_class2%TYPE
      , iv_entering_despatching_code2 IN xxcmn_delivery_lt_v.entering_despatching_code2%TYPE
      , iv_weight_capa_class          IN xxwsh_intensive_carriers_tmp.weight_capacity_class%TYPE
      , in_order_num                  IN NUMBER
      , ov_ship_method_class          OUT NOCOPY xxcmn_delivery_lt_v.ship_method%TYPE
      , on_next_weight_capacity       OUT NOCOPY NUMBER
      , ov_errbuf                     OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W --# �Œ� #
      , ov_retcode                    OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h   --# �Œ� #
      , ov_errmsg                     OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
    IS
--
      -- ===============================
      -- �Œ胍�[�J���萔
      -- ===============================
      cv_sub_prg_name   CONSTANT VARCHAR2(100) := '[get_ship_method_class]';  -- �T�u�v���O������
      cv_not_mixed      CONSTANT VARCHAR2(100) := '0';                        -- ���ڋ敪:�ΏۊO
--
      -- ���[�J���ϐ�
      lt_ship_method      xxcmn_delivery_lt_v.ship_method%TYPE;
      ln_loop_cnt         NUMBER;
      ln_data_cnt         NUMBER DEFAULT 1;   -- �f�[�^�J�E���^
debug_cnt number default 0;
--
      -- ���[�J���J�[�\��
/*
      CURSOR ship_method_class_cur IS
        SELECT  xdl.ship_method                         -- �o�ו��@
                  , xdl.drink_deadweight                -- �h�����N�ύڏd��
                  , xdl.leaf_deadweight                 -- ���[�t�ύڏd��
                  , xdl.drink_loading_capacity          -- �h�����N�ύڗe��
                  , xdl.leaf_loading_capacity           -- ���[�t�ύڗe��
          FROM  xxcmn_delivery_lt2_v xdl                -- �z��L/T���VIEW2
              , xxwsh_ship_method2_v xsmv               -- �z���敪���View2
         WHERE xdl.ship_method = xsmv.ship_method_code  -- �z���敪
           AND xsmv.mixed_class = cv_not_mixed          -- ���ڋ敪
           AND xdl.code_class1 = iv_code_class1                                 -- �R�[�h�敪�P
           AND xdl.entering_despatching_code1 = iv_entering_despatching_code1   -- ���o�ɏꏊ�P
           AND xdl.code_class2 = iv_code_class2                                 -- �R�[�h�敪�Q
           AND xdl.entering_despatching_code2 = iv_entering_despatching_code2   -- ���o�ɏꏊ�Q
           AND xdl.lt_start_date_active <= gd_date_from                -- �z��LT�K�p�J�n��
           AND (xdl.lt_end_date_active IS NULL
                OR xdl.lt_end_date_active   >= gd_date_from)           -- �z��LT�K�p�I����
           AND xdl.sm_start_date_active <= gd_date_from                -- �o�ו��@�K�p�J�n��
           AND (xdl.sm_end_date_active IS NULL
                OR xdl.sm_end_date_active >= gd_date_from)             -- �o�ו��@�K�p�I����
           AND NVL(xdl.consolidated_flag, '0') = '0'
           AND DECODE(gv_prod_class, gv_prod_cls_drink
                  , xdl.drink_deadweight                     -- �h�����N�ύڏd��
                  , xdl.leaf_deadweight) IS NOT NULL         -- ���[�t�ύڏd��
           AND DECODE(gv_prod_class, gv_prod_cls_drink
                  , xdl.drink_loading_capacity               -- �h�����N�ύڗe��
                  , xdl.leaf_loading_capacity) IS NOT NULL   -- ���[�t�ύڗe��
        ORDER BY xdl.ship_method DESC
*/
      -- 2008/07/14 Mod ��
      CURSOR ship_method_class_cur IS
        SELECT  union_sel.ship_method                     -- �o�ו��@
              , union_sel.drink_deadweight                -- �h�����N�ύڏd��
              , union_sel.leaf_deadweight                 -- ���[�t�ύڏd��
              , union_sel.drink_loading_capacity          -- �h�����N�ύڗe��
              , union_sel.leaf_loading_capacity           -- ���[�t�ύڗe��
        FROM (
          SELECT  '1' as sel_flg                      -- ������
                , xdl.ship_method                     -- �o�ו��@
                , xdl.drink_deadweight                -- �h�����N�ύڏd��
                , xdl.leaf_deadweight                 -- ���[�t�ύڏd��
                , xdl.drink_loading_capacity          -- �h�����N�ύڗe��
                , xdl.leaf_loading_capacity           -- ���[�t�ύڗe��
            FROM  xxcmn_delivery_lt2_v xdl                -- �z��L/T���VIEW2
                , xxwsh_ship_method2_v xsmv               -- �z���敪���View2
           WHERE xdl.ship_method = xsmv.ship_method_code  -- �z���敪
             AND xsmv.mixed_class = cv_not_mixed          -- ���ڋ敪
             AND xdl.code_class1 = iv_code_class1                                 -- �R�[�h�敪�P
             AND xdl.entering_despatching_code1 = iv_entering_despatching_code1   -- ���o�ɏꏊ�P
             AND xdl.code_class2 = iv_code_class2                                 -- �R�[�h�敪�Q
             AND xdl.entering_despatching_code2 = iv_entering_despatching_code2   -- ���o�ɏꏊ�Q
             AND xdl.lt_start_date_active <= gd_date_from       -- �z��LT�K�p�J�n��
             AND (xdl.lt_end_date_active IS NULL
                  OR xdl.lt_end_date_active   >= gd_date_from)  -- �z��LT�K�p�I����
             AND xdl.sm_start_date_active <= gd_date_from       -- �o�ו��@�K�p�J�n��
             AND (xdl.sm_end_date_active IS NULL
                  OR xdl.sm_end_date_active >= gd_date_from)    -- �o�ו��@�K�p�I����
-- Ver1.5 M.Hokkanji Start
--             AND NVL(xdl.consolidated_flag, '0') = '0'         -- ���ڋ��t���O:���ڕs����
-- Ver1.5 M.Hokkanji End
-- 2008/10/16 H.Itou Mod Start �����e�X�g�w�E369 0���傫�����̂�ΏۂƂ���B
--             AND DECODE(gv_prod_class, gv_prod_cls_drink
--                    , xdl.drink_deadweight                     -- �h�����N�ύڏd��
--                    , xdl.leaf_deadweight) IS NOT NULL         -- ���[�t�ύڏd��
--             AND DECODE(gv_prod_class, gv_prod_cls_drink
--                    , xdl.drink_loading_capacity               -- �h�����N�ύڗe��
--                    , xdl.leaf_loading_capacity) IS NOT NULL   -- ���[�t�ύڗe��
             AND (CASE
                    -- �h�����N�ύڏd��
                    WHEN ((gv_prod_class        = gv_prod_cls_drink)
                    AND   (iv_weight_capa_class = gv_weight)) THEN
                      xdl.drink_deadweight
                    -- ���[�t�ύڏd��
                    WHEN ((gv_prod_class        = gv_prod_cls_leaf)
                    AND   (iv_weight_capa_class = gv_weight)) THEN
                      xdl.leaf_deadweight
                    -- �h�����N�ύڗe��
                    WHEN ((gv_prod_class        = gv_prod_cls_drink)
                    AND   (iv_weight_capa_class = gv_capacity)) THEN
                      xdl.drink_loading_capacity
                    -- ���[�t�ύڗe��
                    WHEN ((gv_prod_class        = gv_prod_cls_leaf)
                    AND   (iv_weight_capa_class = gv_capacity)) THEN
                      xdl.leaf_loading_capacity
                  END) > 0
--2008/10/16 H.Itou Mod End
          UNION
          SELECT  '2' as sel_flg                      -- ������
                , xdl.ship_method                     -- �o�ו��@
                , xdl.drink_deadweight                -- �h�����N�ύڏd��
                , xdl.leaf_deadweight                 -- ���[�t�ύڏd��
                , xdl.drink_loading_capacity          -- �h�����N�ύڗe��
                , xdl.leaf_loading_capacity           -- ���[�t�ύڗe��
            FROM  xxcmn_delivery_lt2_v xdl                -- �z��L/T���VIEW2
                , xxwsh_ship_method2_v xsmv               -- �z���敪���View2
           WHERE xdl.ship_method = xsmv.ship_method_code  -- �z���敪
             AND xsmv.mixed_class = cv_not_mixed          -- ���ڋ敪
             AND xdl.code_class1 = iv_code_class1                                 -- �R�[�h�敪�P
             AND xdl.entering_despatching_code1 = gv_all_z4   -- ���o�ɏꏊ�P
             AND xdl.code_class2 = iv_code_class2                                 -- �R�[�h�敪�Q
             AND xdl.entering_despatching_code2 = iv_entering_despatching_code2   -- ���o�ɏꏊ�Q
             AND xdl.lt_start_date_active <= gd_date_from       -- �z��LT�K�p�J�n��
             AND (xdl.lt_end_date_active IS NULL
                  OR xdl.lt_end_date_active   >= gd_date_from)  -- �z��LT�K�p�I����
             AND xdl.sm_start_date_active <= gd_date_from       -- �o�ו��@�K�p�J�n��
             AND (xdl.sm_end_date_active IS NULL
                  OR xdl.sm_end_date_active >= gd_date_from)    -- �o�ו��@�K�p�I����
-- Ver1.5 M.Hokkanji Start
--             AND NVL(xdl.consolidated_flag, '0') = '0'         -- ���ڋ��t���O:���ڕs����
-- Ver1.5 M.Hokkanji End
-- 2008/10/16 H.Itou Mod Start �����e�X�g�w�E369 0���傫�����̂�ΏۂƂ���B
--             AND DECODE(gv_prod_class, gv_prod_cls_drink
--                    , xdl.drink_deadweight                     -- �h�����N�ύڏd��
--                    , xdl.leaf_deadweight) IS NOT NULL         -- ���[�t�ύڏd��
--             AND DECODE(gv_prod_class, gv_prod_cls_drink
--                    , xdl.drink_loading_capacity               -- �h�����N�ύڗe��
--                    , xdl.leaf_loading_capacity) IS NOT NULL   -- ���[�t�ύڗe��
             AND (CASE
                    -- �h�����N�ύڏd��
                    WHEN ((gv_prod_class        = gv_prod_cls_drink)
                    AND   (iv_weight_capa_class = gv_weight)) THEN
                      xdl.drink_deadweight
                    -- ���[�t�ύڏd��
                    WHEN ((gv_prod_class        = gv_prod_cls_leaf)
                    AND   (iv_weight_capa_class = gv_weight)) THEN
                      xdl.leaf_deadweight
                    -- �h�����N�ύڗe��
                    WHEN ((gv_prod_class        = gv_prod_cls_drink)
                    AND   (iv_weight_capa_class = gv_capacity)) THEN
                      xdl.drink_loading_capacity
                    -- ���[�t�ύڗe��
                    WHEN ((gv_prod_class        = gv_prod_cls_leaf)
                    AND   (iv_weight_capa_class = gv_capacity)) THEN
                      xdl.leaf_loading_capacity
                  END) > 0
--2008/10/16 H.Itou Mod End
          UNION
          SELECT  '3' as sel_flg                      -- ������
                , xdl.ship_method                     -- �o�ו��@
                , xdl.drink_deadweight                -- �h�����N�ύڏd��
                , xdl.leaf_deadweight                 -- ���[�t�ύڏd��
                , xdl.drink_loading_capacity          -- �h�����N�ύڗe��
                , xdl.leaf_loading_capacity           -- ���[�t�ύڗe��
            FROM  xxcmn_delivery_lt2_v xdl                -- �z��L/T���VIEW2
                , xxwsh_ship_method2_v xsmv               -- �z���敪���View2
           WHERE xdl.ship_method = xsmv.ship_method_code  -- �z���敪
             AND xsmv.mixed_class = cv_not_mixed          -- ���ڋ敪
             AND xdl.code_class1 = iv_code_class1                                 -- �R�[�h�敪�P
             AND xdl.entering_despatching_code1 = iv_entering_despatching_code1   -- ���o�ɏꏊ�P
             AND xdl.code_class2 = iv_code_class2                                 -- �R�[�h�敪�Q
             AND xdl.entering_despatching_code2 = DECODE(iv_code_class2,
                                                         gv_cdkbn_ship_to,
                                                         gv_all_z9,
                                                         gv_all_z4)     -- ���o�ɏꏊ�Q
             AND xdl.lt_start_date_active <= gd_date_from       -- �z��LT�K�p�J�n��
             AND (xdl.lt_end_date_active IS NULL
                  OR xdl.lt_end_date_active   >= gd_date_from)  -- �z��LT�K�p�I����
             AND xdl.sm_start_date_active <= gd_date_from       -- �o�ו��@�K�p�J�n��
             AND (xdl.sm_end_date_active IS NULL
                  OR xdl.sm_end_date_active >= gd_date_from)    -- �o�ו��@�K�p�I����
-- Ver1.5 M.Hokkanji Start
--             AND NVL(xdl.consolidated_flag, '0') = '0'         -- ���ڋ��t���O:���ڕs����
-- Ver1.5 M.Hokkanji End
-- 2008/10/16 H.Itou Mod Start �����e�X�g�w�E369 0���傫�����̂�ΏۂƂ���B
--             AND DECODE(gv_prod_class, gv_prod_cls_drink
--                    , xdl.drink_deadweight                     -- �h�����N�ύڏd��
--                    , xdl.leaf_deadweight) IS NOT NULL         -- ���[�t�ύڏd��
--             AND DECODE(gv_prod_class, gv_prod_cls_drink
--                    , xdl.drink_loading_capacity               -- �h�����N�ύڗe��
--                    , xdl.leaf_loading_capacity) IS NOT NULL   -- ���[�t�ύڗe��
             AND (CASE
                    -- �h�����N�ύڏd��
                    WHEN ((gv_prod_class        = gv_prod_cls_drink)
                    AND   (iv_weight_capa_class = gv_weight)) THEN
                      xdl.drink_deadweight
                    -- ���[�t�ύڏd��
                    WHEN ((gv_prod_class        = gv_prod_cls_leaf)
                    AND   (iv_weight_capa_class = gv_weight)) THEN
                      xdl.leaf_deadweight
                    -- �h�����N�ύڗe��
                    WHEN ((gv_prod_class        = gv_prod_cls_drink)
                    AND   (iv_weight_capa_class = gv_capacity)) THEN
                      xdl.drink_loading_capacity
                    -- ���[�t�ύڗe��
                    WHEN ((gv_prod_class        = gv_prod_cls_leaf)
                    AND   (iv_weight_capa_class = gv_capacity)) THEN
                      xdl.leaf_loading_capacity
                  END) > 0
--2008/10/16 H.Itou Mod End
          UNION
          SELECT  '4' as sel_flg                      -- ������
                , xdl.ship_method                     -- �o�ו��@
                , xdl.drink_deadweight                -- �h�����N�ύڏd��
                , xdl.leaf_deadweight                 -- ���[�t�ύڏd��
                , xdl.drink_loading_capacity          -- �h�����N�ύڗe��
                , xdl.leaf_loading_capacity           -- ���[�t�ύڗe��
            FROM  xxcmn_delivery_lt2_v xdl                -- �z��L/T���VIEW2
                , xxwsh_ship_method2_v xsmv               -- �z���敪���View2
           WHERE xdl.ship_method = xsmv.ship_method_code  -- �z���敪
             AND xsmv.mixed_class = cv_not_mixed          -- ���ڋ敪
             AND xdl.code_class1 = iv_code_class1               -- �R�[�h�敪�P
             AND xdl.entering_despatching_code1 = gv_all_z4     -- ���o�ɏꏊ�P
             AND xdl.code_class2 = iv_code_class2               -- �R�[�h�敪�Q
             AND xdl.entering_despatching_code2 = DECODE(iv_code_class2,
                                                         gv_cdkbn_ship_to,
                                                         gv_all_z9,
                                                         gv_all_z4)     -- ���o�ɏꏊ�Q
             AND xdl.lt_start_date_active <= gd_date_from       -- �z��LT�K�p�J�n��
             AND (xdl.lt_end_date_active IS NULL
                  OR xdl.lt_end_date_active   >= gd_date_from)  -- �z��LT�K�p�I����
             AND xdl.sm_start_date_active <= gd_date_from       -- �o�ו��@�K�p�J�n��
             AND (xdl.sm_end_date_active IS NULL
                  OR xdl.sm_end_date_active >= gd_date_from)    -- �o�ו��@�K�p�I����
-- Ver1.5 M.Hokkanji Start
--             AND NVL(xdl.consolidated_flag, '0') = '0'         -- ���ڋ��t���O:���ڕs����
-- Ver1.5 M.Hokkanji End
-- 2008/10/16 H.Itou Mod Start �����e�X�g�w�E369 0���傫�����̂�ΏۂƂ���B
--             AND DECODE(gv_prod_class, gv_prod_cls_drink
--                    , xdl.drink_deadweight                     -- �h�����N�ύڏd��
--                    , xdl.leaf_deadweight) IS NOT NULL         -- ���[�t�ύڏd��
--             AND DECODE(gv_prod_class, gv_prod_cls_drink
--                    , xdl.drink_loading_capacity               -- �h�����N�ύڗe��
--                    , xdl.leaf_loading_capacity) IS NOT NULL   -- ���[�t�ύڗe��
             AND (CASE
                    -- �h�����N�ύڏd��
                    WHEN ((gv_prod_class        = gv_prod_cls_drink)
                    AND   (iv_weight_capa_class = gv_weight)) THEN
                      xdl.drink_deadweight
                    -- ���[�t�ύڏd��
                    WHEN ((gv_prod_class        = gv_prod_cls_leaf)
                    AND   (iv_weight_capa_class = gv_weight)) THEN
                      xdl.leaf_deadweight
                    -- �h�����N�ύڗe��
                    WHEN ((gv_prod_class        = gv_prod_cls_drink)
                    AND   (iv_weight_capa_class = gv_capacity)) THEN
                      xdl.drink_loading_capacity
                    -- ���[�t�ύڗe��
                    WHEN ((gv_prod_class        = gv_prod_cls_leaf)
                    AND   (iv_weight_capa_class = gv_capacity)) THEN
                      xdl.leaf_loading_capacity
                  END) > 0
--2008/10/16 H.Itou Mod End
        ) union_sel
       ,(
          SELECT  MIN(union_sel.sel_flg) as min_flg
                , union_sel.ship_method                     -- �o�ו��@
          FROM (
            SELECT  '1' as sel_flg                      -- ������
                  , xdl.ship_method                     -- �o�ו��@
              FROM  xxcmn_delivery_lt2_v xdl                -- �z��L/T���VIEW2
                  , xxwsh_ship_method2_v xsmv               -- �z���敪���View2
             WHERE xdl.ship_method = xsmv.ship_method_code  -- �z���敪
               AND xsmv.mixed_class = cv_not_mixed          -- ���ڋ敪
               AND xdl.code_class1 = iv_code_class1                                -- �R�[�h�敪�P
               AND xdl.entering_despatching_code1 = iv_entering_despatching_code1  -- ���o�ɏꏊ�P
               AND xdl.code_class2 = iv_code_class2                                -- �R�[�h�敪�Q
               AND xdl.entering_despatching_code2 = iv_entering_despatching_code2  -- ���o�ɏꏊ�Q
               AND xdl.lt_start_date_active <= gd_date_from      -- �z��LT�K�p�J�n��
               AND (xdl.lt_end_date_active IS NULL
                    OR xdl.lt_end_date_active   >= gd_date_from) -- �z��LT�K�p�I����
               AND xdl.sm_start_date_active <= gd_date_from      -- �o�ו��@�K�p�J�n��
               AND (xdl.sm_end_date_active IS NULL
                    OR xdl.sm_end_date_active >= gd_date_from)   -- �o�ו��@�K�p�I����
-- Ver1.5 M.Hokkanji Start
--               AND NVL(xdl.consolidated_flag, '0') = '0'         -- ���ڋ��t���O:���ڕs����
-- Ver1.5 M.Hokkanji End
-- 2008/10/16 H.Itou Mod Start �����e�X�g�w�E369 0���傫�����̂�ΏۂƂ���B
--               AND DECODE(gv_prod_class, gv_prod_cls_drink
--                      , xdl.drink_deadweight                     -- �h�����N�ύڏd��
--                      , xdl.leaf_deadweight) IS NOT NULL         -- ���[�t�ύڏd��
--               AND DECODE(gv_prod_class, gv_prod_cls_drink
--                      , xdl.drink_loading_capacity               -- �h�����N�ύڗe��
--                      , xdl.leaf_loading_capacity) IS NOT NULL   -- ���[�t�ύڗe��
               AND (CASE
                      -- �h�����N�ύڏd��
                      WHEN ((gv_prod_class        = gv_prod_cls_drink)
                      AND   (iv_weight_capa_class = gv_weight)) THEN
                        xdl.drink_deadweight
                      -- ���[�t�ύڏd��
                      WHEN ((gv_prod_class        = gv_prod_cls_leaf)
                      AND   (iv_weight_capa_class = gv_weight)) THEN
                        xdl.leaf_deadweight
                      -- �h�����N�ύڗe��
                      WHEN ((gv_prod_class        = gv_prod_cls_drink)
                      AND   (iv_weight_capa_class = gv_capacity)) THEN
                        xdl.drink_loading_capacity
                      -- ���[�t�ύڗe��
                      WHEN ((gv_prod_class        = gv_prod_cls_leaf)
                      AND   (iv_weight_capa_class = gv_capacity)) THEN
                        xdl.leaf_loading_capacity
                    END) > 0
--2008/10/16 H.Itou Mod End
            UNION
            SELECT  '2' as sel_flg                      -- ������
                  , xdl.ship_method                     -- �o�ו��@
              FROM  xxcmn_delivery_lt2_v xdl                -- �z��L/T���VIEW2
                  , xxwsh_ship_method2_v xsmv               -- �z���敪���View2
             WHERE xdl.ship_method = xsmv.ship_method_code  -- �z���敪
               AND xsmv.mixed_class = cv_not_mixed          -- ���ڋ敪
               AND xdl.code_class1 = iv_code_class1              -- �R�[�h�敪�P
               AND xdl.entering_despatching_code1 = gv_all_z4    -- ���o�ɏꏊ�P
               AND xdl.code_class2 = iv_code_class2              -- �R�[�h�敪�Q
               AND xdl.entering_despatching_code2 = iv_entering_despatching_code2  -- ���o�ɏꏊ�Q
               AND xdl.lt_start_date_active <= gd_date_from      -- �z��LT�K�p�J�n��
               AND (xdl.lt_end_date_active IS NULL
                    OR xdl.lt_end_date_active   >= gd_date_from) -- �z��LT�K�p�I����
               AND xdl.sm_start_date_active <= gd_date_from      -- �o�ו��@�K�p�J�n��
               AND (xdl.sm_end_date_active IS NULL
                    OR xdl.sm_end_date_active >= gd_date_from)   -- �o�ו��@�K�p�I����
-- Ver1.5 M.Hokkanji Start
--               AND NVL(xdl.consolidated_flag, '0') = '0'         -- ���ڋ��t���O:���ڕs����
-- Ver1.5 M.Hokkanji End
-- 2008/10/16 H.Itou Mod Start �����e�X�g�w�E369 0���傫�����̂�ΏۂƂ���B
--               AND DECODE(gv_prod_class, gv_prod_cls_drink
--                      , xdl.drink_deadweight                     -- �h�����N�ύڏd��
--                      , xdl.leaf_deadweight) IS NOT NULL         -- ���[�t�ύڏd��
--               AND DECODE(gv_prod_class, gv_prod_cls_drink
--                      , xdl.drink_loading_capacity               -- �h�����N�ύڗe��
--                      , xdl.leaf_loading_capacity) IS NOT NULL   -- ���[�t�ύڗe��
               AND (CASE
                      -- �h�����N�ύڏd��
                      WHEN ((gv_prod_class        = gv_prod_cls_drink)
                      AND   (iv_weight_capa_class = gv_weight)) THEN
                        xdl.drink_deadweight
                      -- ���[�t�ύڏd��
                      WHEN ((gv_prod_class        = gv_prod_cls_leaf)
                      AND   (iv_weight_capa_class = gv_weight)) THEN
                        xdl.leaf_deadweight
                      -- �h�����N�ύڗe��
                      WHEN ((gv_prod_class        = gv_prod_cls_drink)
                      AND   (iv_weight_capa_class = gv_capacity)) THEN
                        xdl.drink_loading_capacity
                      -- ���[�t�ύڗe��
                      WHEN ((gv_prod_class        = gv_prod_cls_leaf)
                      AND   (iv_weight_capa_class = gv_capacity)) THEN
                        xdl.leaf_loading_capacity
                    END) > 0
--2008/10/16 H.Itou Mod End
            UNION
            SELECT  '3' as sel_flg                      -- ������
                  , xdl.ship_method                     -- �o�ו��@
              FROM  xxcmn_delivery_lt2_v xdl                -- �z��L/T���VIEW2
                  , xxwsh_ship_method2_v xsmv               -- �z���敪���View2
             WHERE xdl.ship_method = xsmv.ship_method_code  -- �z���敪
               AND xsmv.mixed_class = cv_not_mixed          -- ���ڋ敪
               AND xdl.code_class1 = iv_code_class1               -- �R�[�h�敪�P
               AND xdl.entering_despatching_code1 = iv_entering_despatching_code1  -- ���o�ɏꏊ�P
               AND xdl.code_class2 = iv_code_class2               -- �R�[�h�敪�Q
               AND xdl.entering_despatching_code2 = DECODE(iv_code_class2,
                                                           gv_cdkbn_ship_to,
                                                           gv_all_z9,
                                                           gv_all_z4)     -- ���o�ɏꏊ�Q
               AND xdl.lt_start_date_active <= gd_date_from       -- �z��LT�K�p�J�n��
               AND (xdl.lt_end_date_active IS NULL
                    OR xdl.lt_end_date_active   >= gd_date_from)  -- �z��LT�K�p�I����
               AND xdl.sm_start_date_active <= gd_date_from       -- �o�ו��@�K�p�J�n��
               AND (xdl.sm_end_date_active IS NULL
                    OR xdl.sm_end_date_active >= gd_date_from)    -- �o�ו��@�K�p�I����
-- Ver1.5 M.Hokkanji Start
--               AND NVL(xdl.consolidated_flag, '0') = '0'         -- ���ڋ��t���O:���ڕs����
-- Ver1.5 M.Hokkanji End
-- 2008/10/16 H.Itou Mod Start �����e�X�g�w�E369 0���傫�����̂�ΏۂƂ���B
--               AND DECODE(gv_prod_class, gv_prod_cls_drink
--                      , xdl.drink_deadweight                     -- �h�����N�ύڏd��
--                      , xdl.leaf_deadweight) IS NOT NULL         -- ���[�t�ύڏd��
--               AND DECODE(gv_prod_class, gv_prod_cls_drink
--                      , xdl.drink_loading_capacity               -- �h�����N�ύڗe��
--                      , xdl.leaf_loading_capacity) IS NOT NULL   -- ���[�t�ύڗe��
               AND (CASE
                      -- �h�����N�ύڏd��
                      WHEN ((gv_prod_class        = gv_prod_cls_drink)
                      AND   (iv_weight_capa_class = gv_weight)) THEN
                        xdl.drink_deadweight
                      -- ���[�t�ύڏd��
                      WHEN ((gv_prod_class        = gv_prod_cls_leaf)
                      AND   (iv_weight_capa_class = gv_weight)) THEN
                        xdl.leaf_deadweight
                      -- �h�����N�ύڗe��
                      WHEN ((gv_prod_class        = gv_prod_cls_drink)
                      AND   (iv_weight_capa_class = gv_capacity)) THEN
                        xdl.drink_loading_capacity
                      -- ���[�t�ύڗe��
                      WHEN ((gv_prod_class        = gv_prod_cls_leaf)
                      AND   (iv_weight_capa_class = gv_capacity)) THEN
                        xdl.leaf_loading_capacity
                    END) > 0
--2008/10/16 H.Itou Mod End
            UNION
            SELECT  '4' as sel_flg                      -- ������
                  , xdl.ship_method                     -- �o�ו��@
              FROM  xxcmn_delivery_lt2_v xdl                -- �z��L/T���VIEW2
                  , xxwsh_ship_method2_v xsmv               -- �z���敪���View2
             WHERE xdl.ship_method = xsmv.ship_method_code  -- �z���敪
               AND xsmv.mixed_class = cv_not_mixed          -- ���ڋ敪
               AND xdl.code_class1 = iv_code_class1             -- �R�[�h�敪�P
               AND xdl.entering_despatching_code1 = gv_all_z4   -- ���o�ɏꏊ�P
               AND xdl.code_class2 = iv_code_class2             -- �R�[�h�敪�Q
               AND xdl.entering_despatching_code2 = DECODE(iv_code_class2,
                                                           gv_cdkbn_ship_to,
                                                           gv_all_z9,
                                                           gv_all_z4)   -- ���o�ɏꏊ�Q
               AND xdl.lt_start_date_active <= gd_date_from     -- �z��LT�K�p�J�n��
               AND (xdl.lt_end_date_active IS NULL
                    OR xdl.lt_end_date_active   >= gd_date_from)  -- �z��LT�K�p�I����
               AND xdl.sm_start_date_active <= gd_date_from       -- �o�ו��@�K�p�J�n��
               AND (xdl.sm_end_date_active IS NULL
                    OR xdl.sm_end_date_active >= gd_date_from)    -- �o�ו��@�K�p�I����
-- Ver1.5 M.Hokkanji Start
--               AND NVL(xdl.consolidated_flag, '0') = '0'         -- ���ڋ��t���O:���ڕs����
-- Ver1.5 M.Hokkanji End
-- 2008/10/16 H.Itou Mod Start �����e�X�g�w�E369 0���傫�����̂�ΏۂƂ���B
--               AND DECODE(gv_prod_class, gv_prod_cls_drink
--                      , xdl.drink_deadweight                     -- �h�����N�ύڏd��
--                      , xdl.leaf_deadweight) IS NOT NULL         -- ���[�t�ύڏd��
--               AND DECODE(gv_prod_class, gv_prod_cls_drink
--                      , xdl.drink_loading_capacity               -- �h�����N�ύڗe��
--                      , xdl.leaf_loading_capacity) IS NOT NULL   -- ���[�t�ύڗe��
               AND (CASE
                      -- �h�����N�ύڏd��
                      WHEN ((gv_prod_class        = gv_prod_cls_drink)
                      AND   (iv_weight_capa_class = gv_weight)) THEN
                        xdl.drink_deadweight
                      -- ���[�t�ύڏd��
                      WHEN ((gv_prod_class        = gv_prod_cls_leaf)
                      AND   (iv_weight_capa_class = gv_weight)) THEN
                        xdl.leaf_deadweight
                      -- �h�����N�ύڗe��
                      WHEN ((gv_prod_class        = gv_prod_cls_drink)
                      AND   (iv_weight_capa_class = gv_capacity)) THEN
                        xdl.drink_loading_capacity
                      -- ���[�t�ύڗe��
                      WHEN ((gv_prod_class        = gv_prod_cls_leaf)
                      AND   (iv_weight_capa_class = gv_capacity)) THEN
                        xdl.leaf_loading_capacity
                    END) > 0
--2008/10/16 H.Itou Mod End
          ) union_sel
          group by union_sel.ship_method
        ) union_flg
        WHERE union_sel.sel_flg = union_flg.min_flg
        AND   union_sel.ship_method = union_flg.ship_method
        ORDER BY union_sel.ship_method DESC
       ;
      -- 2008/07/14 Mod ��
--
       -- ���[�J�����R�[�h
       lr_ship_method_class ship_method_class_cur%ROWTYPE;
--
    BEGIN
--
debug_log(FND_FILE.LOG,'7-2-1�z���敪�擾');
debug_log(FND_FILE.LOG,'7-2-1�d�ʗe�ϋ敪�F' || iv_weight_capa_class);
debug_log(FND_FILE.LOG,'7-2-1�R�[�h�敪�P�F'||iv_code_class1);
debug_log(FND_FILE.LOG,'7-2-1���o�ɏꏊ�R�[�h�P�F'||iv_entering_despatching_code1);
debug_log(FND_FILE.LOG,'7-2-1�R�[�h�敪�Q�F'||iv_code_class2);
debug_log(FND_FILE.LOG,'7-2-1���o�ɏꏊ�R�[�h�Q�F'||iv_entering_despatching_code2);
debug_log(FND_FILE.LOG,'7-2-1����F'||TO_CHAR(gd_date_from,'YYYY/MM/DD'));
debug_log(FND_FILE.LOG,'7-2-1���i�敪�F'||gv_prod_class);
debug_log(FND_FILE.LOG,'7-2-1�������ԁF'||in_order_num);
--
      -- ===================
      -- �z���敪�擾
      -- ===================
      OPEN ship_method_class_cur;
      -- �z���敪
      FETCH ship_method_class_cur INTO lr_ship_method_class;
--
      LOOP
--
debug_cnt := debug_cnt + 1;
        ln_data_cnt := ln_data_cnt + 1;
--
        FETCH ship_method_class_cur INTO lr_ship_method_class;
        EXIT WHEN ship_method_class_cur%NOTFOUND;
--
        IF (ln_data_cnt = in_order_num) THEN
--
          ov_ship_method_class := lr_ship_method_class.ship_method;
--
          -- �d�ʗe�ϋ敪�F�d��
          IF (iv_weight_capa_class = gv_weight) THEN
--
            -- ���i�敪�F���[�t
            IF (gv_prod_class = gv_prod_cls_leaf) THEN
--
              -- ���[�t�ύڏd��
              on_next_weight_capacity := lr_ship_method_class.leaf_deadweight;-- ���[�t�ύڏd��
--
            ELSE
              -- �h�����N�ύڏd��
              on_next_weight_capacity := lr_ship_method_class.drink_deadweight;
--
            END IF;
--
          -- �d�ʗe�ϋ敪�F�e��
          ELSE
--
            -- ���i�敪�F���[�t
            IF (gv_prod_class = gv_prod_cls_leaf) THEN
--
              -- ���[�t�ύڗe��
-- 2009/01/05 H.Itou Mod Start �{�ԏ�Q#879
--              on_next_weight_capacity := lr_ship_method_class.drink_loading_capacity;
              on_next_weight_capacity := lr_ship_method_class.leaf_loading_capacity;
-- 2009/01/05 H.Itou Mod End
--
            ELSE
              -- �h�����N�ύڗe��
              on_next_weight_capacity := lr_ship_method_class.drink_loading_capacity;
--
            END IF;
--
          END IF;
--
          EXIT;
--
        END IF;
--
-- debug -----------------
/*if debug_cnt >= 100 then
  exit;
debug_log(FND_FILE.LOG,'������EXIT');
end if;
--------------------------
*/
      END LOOP;
--
debug_log(FND_FILE.LOG,'���̔z���敪�F'|| ov_ship_method_class);
--
      CLOSE ship_method_class_cur;
--
    EXCEPTION
      -- *** ���ʊ֐���O�n���h�� ***
      WHEN global_api_expt THEN
        IF (ship_method_class_cur%ISOPEN) THEN
          CLOSE ship_method_class_cur;
        END IF;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||lv_errbuf,1,5000);
        ov_retcode := gv_status_error;
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      WHEN global_api_others_expt THEN
        IF (ship_method_class_cur%ISOPEN) THEN
          CLOSE ship_method_class_cur;
        END IF;
        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        IF (ship_method_class_cur%ISOPEN) THEN
          CLOSE ship_method_class_cur;
        END IF;
        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
    END;
--
    -- ============================
    -- �L�[�u���C�N������
    -- ============================
    PROCEDURE lproc_keybrake_process(
        ov_errbuf     OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W --# �Œ� #
      , ov_retcode    OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h   --# �Œ� #
      , ov_errmsg     OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
    IS
      -- ===============================
      -- �Œ胍�[�J���萔
      -- ===============================
      cv_sub_prg_name   CONSTANT VARCHAR2(100) := '[lproc_keybrake_process]'; -- �T�u�v���O������
--
      ln_non_processing_cnt NUMBER DEFAULT 0;   -- �������J�E���g
--
    BEGIN
debug_log(FND_FILE.LOG,'7�L�[�u���C�N����');
debug_log(FND_FILE.LOG,'7-0-1�Ď��s�t���O�������FOFF');
debug_log(FND_FILE.LOG,'7-0-2����R�[�h�J�E���g�F'|| ln_parent_no);
--
      -- ����R�[�h���������̏ꍇ�A���̔z���敪������
      IF (lt_intensive_tab(ln_parent_no).finish_sum_flag IS NULL) THEN
--
debug_log(FND_FILE.LOG,'7-1����R�[�h���������B���̔z���敪������');
        -- ������
        ln_order_num_cnt := ln_order_num_cnt + 1;
debug_log(FND_FILE.LOG,'7-2�����񐔁F'|| ln_order_num_cnt);
--
        -- ���̔z���敪���擾
        get_ship_method_class(
                iv_code_class1                => gv_cdkbn_storage     -- �R�[�h�敪�P�F�q��
              , iv_entering_despatching_code1 => first_deliver_from   -- �z����
              , iv_code_class2                => lv_cdkbn_2     -- �R�[�h�敪�Q�F�q�� or �z����
              , iv_entering_despatching_code2 => first_deliver_to           -- �z����
-- Ver1.5 M.Hokkanji Start
              , iv_weight_capa_class          => first_weight_capacity_class -- �d�ʗe�ϋ敪
--              , iv_weight_capa_class          => first_intensive_sum_weight -- �d�ʗe�ϋ敪
-- Ver1.5 M.Hokkanji End
              , in_order_num                  => ln_order_num_cnt           -- ������
              , ov_ship_method_class          => lt_ship_method_cls         -- ���̔z���敪
              , on_next_weight_capacity       => ln_next_weight_capacity    -- �ύڏd�ʁ^�e��
              , ov_errbuf                     => lv_errbuf
              , ov_retcode                    => lv_retcode
              , ov_errmsg                     => lv_errmsg
        );
--
        IF (lv_retcode = gv_status_error) THEN
          gv_err_key  :=  gv_cdkbn_storage
                          || gv_msg_comma ||
                          first_deliver_from
                          || gv_msg_comma ||
                          lv_cdkbn_2
                          || gv_msg_comma ||
                          first_deliver_to
                          || gv_msg_comma ||
-- Ver1.5 M.Hokkanji Start
--                          first_intensive_sum_weight
                          first_weight_capacity_class
-- Ver1.5 M.Hokkanji End
                          || gv_msg_comma ||
                          ln_order_num_cnt
                          ;
          -- �G���[���b�Z�[�W�擾
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                        , gv_msg_xxwsh_11810  -- ���b�Z�[�W�FAPP-XXWSH-11810 ���ʊ֐��G���[
                        , gv_fnc_name         -- �g�[�N���FFNC_NAME
                        , 'get_ship_method_class' -- �֐���
                        , gv_tkn_key              -- �g�[�N���FKEY
                        , gv_err_key              -- �֐����s�L�[
                       ),1,5000);
          RAISE global_api_expt;
        END IF;
--
        -- ���̔z���敪���擾�ł����ꍇ
        IF (lt_ship_method_cls IS NOT NULL) THEN
--
debug_log(FND_FILE.LOG,'7-3���̔z���敪�擾');
debug_log(FND_FILE.LOG,'7-3���̔z���敪:' || lt_ship_method_cls);
          -- ���̔z���敪������ׂ̏W�񍇌v�𒴂��邩�`�F�b�N����
          IF (first_weight_capacity_class = gv_weight) THEN
debug_log(FND_FILE.LOG,'7-3-1�z���敪������ׂ̏W�񍇌v�𒴂��邩�`�F�b�N:�d��');
debug_log(FND_FILE.LOG,'7-3-1:����׏d�ʁF' || first_intensive_sum_weight);
debug_log(FND_FILE.LOG,'7-3-1:���̔z���敪�d�ʁF' || ln_next_weight_capacity);
--
            -- �d�ʂ̏ꍇ
--
            IF (first_intensive_sum_weight > ln_next_weight_capacity) THEN
--
debug_log(FND_FILE.LOG,'7-3-1-1�d�ʃI�[�o�[');
              -- �W�񍇌v�d�ʂ��ύڏd�ʂ��I�[�o�[���邽�ߍ��ڕs�A�W��Ƃ���
              -- �����σt���O�F������
              lt_intensive_tab(ln_parent_no).finish_sum_flag := cv_finish_intensive;
--
              -- ���ڎ�ʊi�[
              lt_mixed_class_tab(ln_parent_no) := gv_mixed_class_int;  -- �W��
--
              -- ���ڍσf�[�^�J�E���^�i�[
              lt_mixed_cnt_tab(ln_parent_no) := ln_loop_cnt;
--
              -- ���ڍσt���O�ݒ�
              lv_mixed_flag  := gv_mixed_class_int; -- �W��
--
            ELSE
--
debug_log(FND_FILE.LOG,'7-3-1-2�d�ʃI�[�o�[���Ȃ�');
              -- �ύڃI�[�o�[�`�F�b�N�p�ɕϐ��Ɋi�[
              first_max_weight := ln_next_weight_capacity;
--
            END IF;
--
          ELSE
debug_log(FND_FILE.LOG,'7-3-2�z���敪������ׂ̏W�񍇌v�𒴂��邩�`�F�b�N:�e��');
debug_log(FND_FILE.LOG,'7-3-2:����חe�ρF' || first_intensive_sum_capacity);
debug_log(FND_FILE.LOG,'7-3-2:���̔z���敪�e�ρF' || ln_next_weight_capacity);
            -- �e�ς̏ꍇ
            IF (first_intensive_sum_capacity > ln_next_weight_capacity) THEN
--
debug_log(FND_FILE.LOG,'7-3-2-1�e�σI�[�o�[');
              -- �W�񍇌v�d�ʂ��ύڏd�ʂ��I�[�o�[���邽�ߍ��ڕs�A�W��Ƃ���
              lt_intensive_tab(ln_parent_no).finish_sum_flag := cv_finish_intensive;
--
              -- ���ڎ�ʊi�[
              lt_mixed_class_tab(ln_parent_no) := gv_mixed_class_int;  -- �W��
--
              -- ���ڍσf�[�^�J�E���^�i�[
              lt_mixed_cnt_tab(ln_parent_no) := ln_loop_cnt;
--
              -- ���ڍσt���O�ݒ�
              lv_mixed_flag  := gv_mixed_class_int; -- �W��
--
            ELSE
debug_log(FND_FILE.LOG,'7-3-2-2�e�σI�[�o�[���Ȃ�');
--
              -- �ύڃI�[�o�[�`�F�b�N�p�ɕϐ��Ɋi�[
              first_max_capacity := ln_next_weight_capacity;
--
            END IF;
--
          END IF;
--
        -- ���̔z���敪���擾�ł��Ȃ��ꍇ
        ELSE
debug_log(FND_FILE.LOG,'7-4���̔z���敪�擾�ł���');
----
          -- ���ڎ�ʊi�[�ɏW����Z�b�g����
          lt_mixed_class_tab(ln_parent_no) := gv_mixed_class_int;  -- �W��
--
debug_log(FND_FILE.LOG,'7-4-1����R�[�h���W��ɂ���');
debug_log(FND_FILE.LOG,'7-4-1����R�[�h�̃J�E���^�F'||ln_parent_no);
          -- ����R�[�h�������ςɂ���B
          lt_intensive_tab(ln_parent_no).finish_sum_flag := cv_finish_intensive;
                                                                        -- �����σt���O
debug_log(FND_FILE.LOG,'7-4-2����R�[�h�������ςɂ���');
--
          -- ���ڍσt���O�ݒ�
          lv_mixed_flag  := gv_mixed_class_int; -- �W��
debug_log(FND_FILE.LOG,'7-4-3���ڍσt���O�F�W��');
--
        END IF;
--
      END IF;
--
    EXCEPTION
      -- *** ���ʊ֐���O�n���h�� ***
      WHEN global_api_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||lv_errbuf,1,5000);
        ov_retcode := gv_status_error;
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      WHEN global_api_others_expt THEN
        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
--
    END lproc_keybrake_process;
--
    -- =================================
    -- ���ڃe�[�u���o�^�p�f�[�^�ݒ菈��
    -- =================================
    PROCEDURE set_ins_data(
        ov_errbuf     OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W --# �Œ� #
      , ov_retcode    OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h   --# �Œ� #
      , ov_errmsg     OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
    IS
      -- ===============================
      -- �Œ胍�[�J���萔
      -- ===============================
      cv_sub_prg_name   CONSTANT VARCHAR2(100) := '[set_ins_data]'; -- �T�u�v���O������
--
--2008.05.27 D.Sugahara �s�No9�Ή�->
      lv_small_amt_cnt NUMBER DEFAULT 0;   -- �����敪����p�J�E���g
--2008.05.27 D.Sugahara �s�No9�Ή�<-
--
    BEGIN
--
--
debug_log(FND_FILE.LOG,'9-1���ڃe�[�u���o�^�p�f�[�^�ݒ菈��');
debug_log(FND_FILE.LOG,'9-2���z��No�擾');
--2008/10/16 H.Itou Del Start T_S_625
--      -- ���z��NO�擾
--      SELECT xxwsh_temp_delivery_no_s1.NEXTVAL
--      INTO   ln_temp_ship_no
--      FROM   dual;
--2008/10/16 H.Itou Del End T_S_625
debug_log(FND_FILE.LOG,'9-3�œK�z���敪�ݒ�');
      -- ======================
      -- B-12.�œK�z���敪�ݒ�
      -- ======================
      -- �R�[�h�敪�Q�ݒ�i����R�[�h�̏����敪�j
      IF (lt_intensive_tab(ln_parent_no).transaction_type = gv_ship_type_ship) THEN -- �o�׈˗�
debug_log(FND_FILE.LOG,'9-4-0�œK�z���敪�ݒ�lt_intensive_tab(ln_parent_no).transaction_type:'||lt_intensive_tab(ln_parent_no).transaction_type);
        lv_cdkbn_2_opt  :=  gv_cdkbn_ship_to; -- �z����
      ELSE
        lv_cdkbn_2_opt  :=  gv_cdkbn_storage; -- �q��
      END IF;
debug_log(FND_FILE.LOG,'9-4�œK�z���敪�ݒ�');
      -- ���ʊ֐��F�ύڌ����`�F�b�N
      -- �d�ʗe�ϋ敪�F�d��
      IF (first_weight_capacity_class = gv_weight) THEN
debug_log(FND_FILE.LOG,'9-4-1�d��');
debug_log(FND_FILE.LOG,'������������������������������');
debug_log(FND_FILE.LOG,'9-4-1-1:���ڎ�ʁF'|| lt_mixed_class_tab(ln_parent_no));
debug_log(FND_FILE.LOG,'9-4-1-1���v�d�ʁF'||ln_intensive_weight);
debug_log(FND_FILE.LOG,'9-4-1-1�R�[�h�敪�P�F'||gv_cdkbn_storage);
debug_log(FND_FILE.LOG,'9-4-1-1���o�ɏꏊ�R�[�h�P�F'||first_deliver_from);
debug_log(FND_FILE.LOG,'9-4-1-1�R�[�h�敪�Q�F'||lv_cdkbn_2_opt);
debug_log(FND_FILE.LOG,'9-4-1-1���o�ɏꏊ�R�[�h�Q�F'||first_deliver_to);
debug_log(FND_FILE.LOG,'9-4-1-1����F'||TO_CHAR(first_schedule_ship_date,'YYYY/MM/DD'));
debug_log(FND_FILE.LOG,'������������������������������');
        xxwsh_common910_pkg.calc_load_efficiency(
            in_sum_weight                  => ln_intensive_weight
                                                            -- 1.���v�d��
          , in_sum_capacity                => NULL          -- 2.���v�e��
          , iv_code_class1                 => gv_cdkbn_storage
                                                            -- 3.�R�[�h�敪�P
          , iv_entering_despatching_code1  => first_deliver_from
                                                            -- 4.���o�ɏꏊ�R�[�h�P
          , iv_code_class2                 => lv_cdkbn_2_opt
                                                            -- 5.�R�[�h�敪�Q
          , iv_entering_despatching_code2  => first_deliver_to
                                                            -- 6.���o�ɏꏊ�R�[�h�Q
          , iv_ship_method                 => NULL          -- 7.�o�ו��@
          , iv_prod_class                  => gv_prod_class -- 8.���i�敪
          , iv_auto_process_type           => cv_allocation -- 9.�����z�ԑΏۋ敪
          , id_standard_date               => first_schedule_ship_date
                                                            -- 10.���(�K�p�����)
          , ov_retcode                     => lv_retcode    -- 11.���^�[���R�[�h
          , ov_errmsg_code                 => lv_errmsg     -- 12.�G���[���b�Z�[�W�R�[�h
          , ov_errmsg                      => lv_errbuf     -- 13.�G���[���b�Z�[�W
          , ov_loading_over_class          => lv_loading_over_class
                                                            -- 14.�ύڃI�[�o�[�敪
          , ov_ship_methods                => lv_ship_optimization
                                                            -- 15.�o�ו��@(�œK�z���敪)
          , on_load_efficiency_weight      => ln_load_efficiency_weight
                                                            -- 16.�d�ʐύڌ���
          , on_load_efficiency_capacity    => ln_load_efficiency_capacity
                                                            -- 17.�e�ϐύڌ���
          , ov_mixed_ship_method           => lv_mixed_ship_method
                                                            -- 18.���ڔz���敪
        );
        -- ���ʊ֐����G���[�̏ꍇ
-- Ver1.7 M.Hokkanji START
        IF (lv_retcode <> gv_status_normal) THEN
--        IF (lv_retcode = gv_status_error) THEN
-- Ver1.7 M.Hokkanji End
          gv_err_key  :=  ln_intensive_weight -- 1.���v�d��
                          || gv_msg_comma ||
                          NULL                -- 2.���v�e��
                          || gv_msg_comma ||
                          gv_cdkbn_storage    -- 3.�R�[�h�敪�P
                          || gv_msg_comma ||
                          first_deliver_from  -- 4.���o�ɏꏊ�R�[�h�P
                          || gv_msg_comma ||
                          lv_cdkbn_2_opt      -- 5.�R�[�h�敪�Q
                          || gv_msg_comma ||
                          first_deliver_to    -- 6.���o�ɏꏊ�R�[�h�Q
                          || gv_msg_comma ||
                          NULL                -- 7.�o�ו��@
                          || gv_msg_comma ||
                          gv_prod_class       -- 8.���i�敪
                          || gv_msg_comma ||
                          cv_allocation       -- 9.�����z�ԑΏۋ敪
                          || gv_msg_comma ||
                          TO_CHAR(first_schedule_ship_date, 'YYYY/MM/DD') -- 10.���
                          ;
          -- �G���[���b�Z�[�W�擾
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                        , gv_msg_xxwsh_11810  -- ���b�Z�[�W�FAPP-XXWSH-11810 ���ʊ֐��G���[
                        , gv_fnc_name         -- �g�[�N���FFNC_NAME
                        , 'xxwsh_common910_pkg.calc_load_efficiency' -- �֐���
                        , gv_tkn_key              -- �g�[�N���FKEY
                        , gv_err_key              -- �֐����s�L�[
                        ),1,5000);
          RAISE global_api_expt;
        END IF;
debug_log(FND_FILE.LOG,'9-4-1-1�ύڃI�[�o�[�敪�F'||lv_loading_over_class);
debug_log(FND_FILE.LOG,'9-4-1-1�o�ו��@(�œK�z���敪)�F'||lv_ship_optimization);
debug_log(FND_FILE.LOG,'9-4-1-1�d�ʐύڌ����F'||ln_load_efficiency_weight);
debug_log(FND_FILE.LOG,'9-4-1-1�e�ϐύڌ����F'||ln_load_efficiency_capacity);
debug_log(FND_FILE.LOG,'9-4-1-1���ڔz���敪�F'||lv_mixed_ship_method);
      -- �d�ʗe�ϋ敪�F�e��
      ELSE
debug_log(FND_FILE.LOG,'9-4-2�e��');
debug_log(FND_FILE.LOG,'������������������������������');
debug_log(FND_FILE.LOG,'9-4-2-1-0:'|| ln_parent_no);
debug_log(FND_FILE.LOG,'9-4-2-1-1:���ڎ��'|| lt_mixed_class_tab(ln_parent_no));
debug_log(FND_FILE.LOG,'9-4-2-1-2���v�e�ρF'||ln_intensive_capacity);
debug_log(FND_FILE.LOG,'9-4-2-1-3�R�[�h�敪�P�F'||gv_cdkbn_storage);
debug_log(FND_FILE.LOG,'9-4-2-1-4���o�ɏꏊ�R�[�h�P�F'||first_deliver_from);
debug_log(FND_FILE.LOG,'9-4-2-1-5�R�[�h�敪�Q�F'||lv_cdkbn_2_opt);
debug_log(FND_FILE.LOG,'9-4-2-1-6���o�ɏꏊ�R�[�h�Q�F'||first_deliver_to);
debug_log(FND_FILE.LOG,'9-4-1-1-7����F'||TO_CHAR(first_schedule_ship_date,'YYYY/MM/DD'));
debug_log(FND_FILE.LOG,'������������������������������');
        xxwsh_common910_pkg.calc_load_efficiency(
            in_sum_weight                  => NULL          -- 1.���v�d��
          , in_sum_capacity                => ln_intensive_capacity
                                                            -- 2.���v�e��
          , iv_code_class1                 => gv_cdkbn_storage
                                                            -- 3.�R�[�h�敪�P
          , iv_entering_despatching_code1  => first_deliver_from
                                                            -- 4.���o�ɏꏊ�R�[�h�P
          , iv_code_class2                 => lv_cdkbn_2_opt
                                                            -- 5.�R�[�h�敪�Q
          , iv_entering_despatching_code2  => first_deliver_to
                                                            -- 6.���o�ɏꏊ�R�[�h�Q
          , iv_ship_method                 => NULL          -- 7.�o�ו��@
          , iv_prod_class                  => gv_prod_class -- 8.���i�敪
          , iv_auto_process_type           => cv_allocation -- 9.�����z�ԑΏۋ敪
          , id_standard_date               => first_schedule_ship_date
                                                            -- 10.���(�K�p�����)
          , ov_retcode                     => lv_retcode
                                                            -- 11.���^�[���R�[�h
          , ov_errmsg_code                 => lv_errmsg     -- 12.�G���[���b�Z�[�W�R�[�h
          , ov_errmsg                      => lv_errbuf     -- 13.�G���[���b�Z�[�W
          , ov_loading_over_class          => lv_loading_over_class
                                                            -- 14.�ύڃI�[�o�[�敪
          , ov_ship_methods                => lv_ship_optimization
                                                            -- 15.�o�ו��@(�œK�z���敪)
          , on_load_efficiency_weight      => ln_load_efficiency_weight
                                                            -- 16.�d�ʐύڌ���
          , on_load_efficiency_capacity    => ln_load_efficiency_capacity
                                                            -- 17.�e�ϐύڌ���
          , ov_mixed_ship_method           => lv_mixed_ship_method
                                                            -- 18.���ڔz���敪
        );
        -- ���ʊ֐����G���[�̏ꍇ
-- Ver1.7 M.Hokkanji START
        IF (lv_retcode <> gv_status_normal) THEN
--        IF (lv_retcode = gv_status_error) THEN
-- Ver1.7 M.Hokkanji End
          gv_err_key  :=  NULL                  -- 1.���v�d��
                          || gv_msg_comma ||
                          ln_intensive_capacity -- 2.���v�e��
                          || gv_msg_comma ||
                          gv_cdkbn_storage      -- 3.�R�[�h�敪�P
                          || gv_msg_comma ||
                          first_deliver_from    -- 4.���o�ɏꏊ�R�[�h�P
                          || gv_msg_comma ||
                          gv_cdkbn_ship_to      -- 5.�R�[�h�敪�Q
                          || gv_msg_comma ||
                          first_deliver_to      -- 6.���o�ɏꏊ�R�[�h�Q
                          || gv_msg_comma ||
                          NULL                  -- 7.�o�ו��@
                          || gv_msg_comma ||
                          gv_prod_class         -- 8.���i�敪
                          || gv_msg_comma ||
                          cv_allocation         -- 9.�����z�ԑΏۋ敪
                          || gv_msg_comma ||
                          TO_CHAR(first_schedule_ship_date, 'YYYY/MM/DD') -- 10.���
                          ;
          -- �G���[���b�Z�[�W�擾
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                        , gv_msg_xxwsh_11810  -- ���b�Z�[�W�FAPP-XXWSH-11810 ���ʊ֐��G���[
                        , gv_fnc_name         -- �g�[�N���FFNC_NAME
                        , 'xxwsh_common910_pkg.calc_load_efficiency' -- �֐���
                        , gv_tkn_key              -- �g�[�N���FKEY
                        , gv_err_key              -- �֐����s�L�[
                        ),1,5000);
          RAISE global_api_expt;
        END IF;
debug_log(FND_FILE.LOG,'9-4-2-1�ύڃI�[�o�[�敪�F'||lv_loading_over_class);
debug_log(FND_FILE.LOG,'9-4-2-1�o�ו��@(�œK�z���敪)�F'||lv_ship_optimization);
debug_log(FND_FILE.LOG,'9-4-2-1�d�ʐύڌ����F'||ln_load_efficiency_weight);
debug_log(FND_FILE.LOG,'9-4-2-1�e�ϐύڌ����F'||ln_load_efficiency_capacity);
debug_log(FND_FILE.LOG,'9-4-2-1���ڔz���敪�F'||lv_mixed_ship_method);
      END IF;
--
-- 2008/10/01 H.Itou Del Start
--for j in 1..lt_intensive_no_tab.count loop
--debug_log(FND_FILE.LOG,'���ڍ��v�d�ʁF'||lt_mix_total_weight(j));
--debug_log(FND_FILE.LOG,'���ڍ��v�e�ρF'||lt_mix_total_capacity(j));
--end loop;
-- 2008/10/01 H.Itou Del End
--
-- Ver1.3 M.Hokkanji Start
      -- ���ڂ̏ꍇ�A�œK�������z���敪�����ڃf�[�^�ɑ��݂��邩���m�F
      IF (lt_mixed_class_tab(ln_parent_no) = gv_mixed_class_mixed) THEN
        IF (lt_intensive_tab(ln_child_no).transaction_type = gv_ship_type_ship) THEN -- �o�׈˗�
debug_log(FND_FILE.LOG,'9-4-a�œK�z���敪�ݒ�');
          lv_cdkbn_2_con  :=  gv_cdkbn_ship_to; -- �z����
        ELSE
          lv_cdkbn_2_con  :=  gv_cdkbn_storage; -- �q��
        END IF;
debug_log(FND_FILE.LOG,'9-4-b�œK�z���敪���݃`�F�b�N');
        get_consolidated_flag(
            iv_code_class1                => gv_cdkbn_storage         -- �R�[�h�敪�P
          , iv_entering_despatching_code1 => first_deliver_from       -- ���o�ɏꏊ�P
          , iv_code_class2                => lv_cdkbn_2_con           -- �R�[�h�敪�Q
          , iv_entering_despatching_code2 => lt_intensive_tab(ln_child_no).deliver_to
                                                                      -- ���o�ɏꏊ�Q
          , iv_ship_method                => lv_ship_optimization     -- �z���敪
          , ov_consolidate_flag           => lv_consolid_flag_ships
                                                                      -- ���ډۃt���O:�z���敪
          , ov_errbuf                     => lv_errbuf
          , ov_retcode                    => lv_retcode
          , ov_errmsg                     => lv_errmsg
        );
        IF (lv_retcode = gv_status_error) THEN
debug_log(FND_FILE.LOG,'9-4-b�œK�z���敪���݃`�F�b�N�֐��G���[');
          RAISE global_api_expt;
        END IF;
        -- ���ډۃt���O���擾�ł��Ȃ������ꍇ
        IF (NVL(lv_consolid_flag_ships,cv_consolid_false) = cv_consolid_false) THEN
debug_log(FND_FILE.LOG,'9-4-c�œK�z���敪�擾���s');
          lv_ship_optimization := lt_ship_method_cls;
debug_log(FND_FILE.LOG,'9-4-d���ڔz���敪�擾');
debug_log(FND_FILE.LOG,'�z���敪�F'||lv_ship_optimization);
debug_log(FND_FILE.LOG,'����F'||TO_CHAR(first_schedule_ship_date,'YYYY/MM/DD'));
          BEGIN
            SELECT xsmv.mixed_ship_method_code
            INTO   lv_mixed_ship_method
            FROM   xxwsh_ship_method2_v xsmv
            WHERE  xsmv.ship_method_code = lv_ship_optimization
            AND    first_schedule_ship_date
                   BETWEEN xsmv.start_date_active
                       AND NVL(xsmv.end_date_active,first_schedule_ship_date);
          EXCEPTION
            WHEN OTHERS THEN
debug_log(FND_FILE.LOG,'9-4-e���ڔz���敪�擾���s');
            -- �G���[���b�Z�[�W�擾
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                          ,gv_msg_xxwsh_11804  -- �Ώۃf�[�^�Ȃ�
                          ,gv_tkn_table        -- �g�[�N��'TABLE'
                          ,cv_table_name_con   -- �e�[�u�����F�z���敪���VIEW2
                          ,gv_tkn_key          -- �g�[�N��'KEY'
                          ,cv_ship_method_name || ':' || lv_ship_optimization || '�A' ||
                          cv_effective_date || ':' || TO_CHAR(first_schedule_ship_date,'YYYY/MM/DD')
                         ) ,1 ,5000);
            RAISE global_api_expt;
          END;
        END IF;
      END IF;
debug_log(FND_FILE.LOG,'9-4-f�����敪�m�F');
      -- ���ڃf�[�^�����[�g�ɑ��݂��邩�`�F�b�N���锻�f���s������
      -- �����敪�`�F�b�N�����[�v�O�Ɉړ�
      --�����敪�m�F
      BEGIN
        SELECT  COUNT(xsmv.ship_method_code)                 -- �o�ו��@
          INTO  lv_small_amt_cnt
          FROM  xxwsh_ship_method2_v xsmv                    -- �z���敪���View2
         WHERE xsmv.ship_method_code = lv_ship_optimization  -- �z���敪
           AND xsmv.small_amount_class = '1'                 -- �����敪
           AND xsmv.start_date_active <= gd_date_from        -- �o�ו��@�K�p�J�n��
           AND (xsmv.end_date_active IS NULL
                OR xsmv.end_date_active >= gd_date_from)     -- �o�ו��@�K�p�I����
          AND ROWNUM = 1
          ;
      EXCEPTION
        -- *** OTHERS��O�n���h�� ***
        WHEN OTHERS THEN
          lv_small_amt_cnt := 0;
      END;
debug_log(FND_FILE.LOG,'�����敪lv_small_amt_cnt:' || lv_small_amt_cnt);
      -- ���ڂŏ����ł͂Ȃ��ꍇ���ڔz���敪���Y�����[�g�ɑ��݂��邩���`�F�b�N
      IF ((lt_mixed_class_tab(ln_parent_no) = gv_mixed_class_mixed)
        AND (lv_small_amt_cnt = 0 )) THEN
debug_log(FND_FILE.LOG,'9-4-g���ڔz���敪���[�g�`�F�b�N(���)');
debug_log(FND_FILE.LOG,'�R�[�h�敪�P:' || gv_cdkbn_storage);
debug_log(FND_FILE.LOG,'���o�ɏꏊ�P:' || first_deliver_from);
debug_log(FND_FILE.LOG,'�R�[�h�敪�Q:' || lv_cdkbn_2_opt);
debug_log(FND_FILE.LOG,'���o�ɏꏊ�Q:' || first_deliver_to);
debug_log(FND_FILE.LOG,'�z���敪:' || lv_mixed_ship_method );
        get_consolidated_flag(
            iv_code_class1                => gv_cdkbn_storage         -- �R�[�h�敪�P
          , iv_entering_despatching_code1 => first_deliver_from       -- ���o�ɏꏊ�P
          , iv_code_class2                => lv_cdkbn_2_opt           -- �R�[�h�敪�Q
          , iv_entering_despatching_code2 => first_deliver_to
                                                                      -- ���o�ɏꏊ�Q
-- 2008/11/19 H.Itou Mod Start �����e�X�g�w�E666 �o�ו��@�A�h�I���}�X�^�ɍ��ڔz���敪�̃f�[�^�͓o�^���Ȃ��̂ŁA�z���敪�Ń`�F�b�N���{�B
--          , iv_ship_method                => lv_mixed_ship_method     -- �z���敪
          , iv_ship_method                => lv_ship_optimization     -- �z���敪
-- 2008/11/19 H.Itou Mod End
          , ov_consolidate_flag           => lv_consolid_flag_ships
                                                                      -- ���ډۃt���O:�z���敪
          , ov_errbuf                     => lv_errbuf
          , ov_retcode                    => lv_retcode
          , ov_errmsg                     => lv_errmsg
        );
        IF (lv_retcode = gv_status_error) THEN
debug_log(FND_FILE.LOG,'9-4-g���ڔz���敪���[�g�`�F�b�N(���)�֐��G���[');
          RAISE global_api_expt;
        END IF;
        -- ���ډۃt���O���擾�ł��Ȃ������ꍇ
        IF (NVL(lv_consolid_flag_ships,cv_consolid_false) = cv_consolid_false) THEN
debug_log(FND_FILE.LOG,'9-4-g���ڔz���敪���[�g�`�F�b�N(���)�֐��G���[');
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                         gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                        ,gv_msg_xxwsh_11814  -- �z���敪���݃G���[
                        ,gv_tkn_codekbn1     -- �g�[�N��'�R�[�h�敪1'
                        ,gv_cdkbn_storage
                        ,gv_tkn_from         -- �g�[�N��'�ۊǏꏊ1'
                        ,first_deliver_from
                        ,gv_tkn_codekbn2     -- �g�[�N��'�R�[�h�敪2'
                        ,lv_cdkbn_2_opt
                        ,gv_tkn_to           -- �g�[�N��'�ۊǏꏊ2'
                        ,first_deliver_to
                        ,gv_tkn_ship_method  -- �g�[�N��'�z���敪'
                        ,lv_mixed_ship_method
                        ,gv_tkn_source_no    -- �g�[�N��'�W��No'
                        ,first_intensive_source_no
                       ) ,1 ,5000);
          RAISE global_api_expt;
        END IF;
debug_log(FND_FILE.LOG,'9-4-h���ڔz���敪���[�g�`�F�b�N(���ڐ�)');
debug_log(FND_FILE.LOG,'�R�[�h�敪�P:' || gv_cdkbn_storage);
debug_log(FND_FILE.LOG,'���o�ɏꏊ�P:' || first_deliver_from);
debug_log(FND_FILE.LOG,'�R�[�h�敪�Q:' || lv_cdkbn_2_con);
debug_log(FND_FILE.LOG,'���o�ɏꏊ�Q:' || first_deliver_to);
debug_log(FND_FILE.LOG,'�z���敪:' || lv_mixed_ship_method );
        get_consolidated_flag(
            iv_code_class1                => gv_cdkbn_storage         -- �R�[�h�敪�P
          , iv_entering_despatching_code1 => first_deliver_from       -- ���o�ɏꏊ�P
          , iv_code_class2                => lv_cdkbn_2_con           -- �R�[�h�敪�Q
          , iv_entering_despatching_code2 => lt_intensive_tab(ln_child_no).deliver_to
                                                                      -- ���o�ɏꏊ�Q
-- 2008/11/19 H.Itou Mod Start �����e�X�g�w�E666 �o�ו��@�A�h�I���}�X�^�ɍ��ڔz���敪�̃f�[�^�͓o�^���Ȃ��̂ŁA�z���敪�Ń`�F�b�N���{�B
--          , iv_ship_method                => lv_mixed_ship_method     -- �z���敪
          , iv_ship_method                => lv_ship_optimization     -- �z���敪
-- 2008/11/19 H.Itou Mod End
          , ov_consolidate_flag           => lv_consolid_flag_ships
                                                                      -- ���ډۃt���O:�z���敪
          , ov_errbuf                     => lv_errbuf
          , ov_retcode                    => lv_retcode
          , ov_errmsg                     => lv_errmsg
        );
        IF (lv_retcode = gv_status_error) THEN
debug_log(FND_FILE.LOG,'9-4-h���ڔz���敪���[�g�`�F�b�N(���ڐ�)�֐��G���[');
          RAISE global_api_expt;
        END IF;
        -- ���ډۃt���O���擾�ł��Ȃ������ꍇ
        IF (NVL(lv_consolid_flag_ships,cv_consolid_false) = cv_consolid_false) THEN
debug_log(FND_FILE.LOG,'9-4-h���ڔz���敪���[�g�`�F�b�N(���ڐ�)�֐��G���[');
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                         gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                        ,gv_msg_xxwsh_11814  -- �z���敪���݃G���[
                        ,gv_tkn_codekbn1     -- �g�[�N��'�R�[�h�敪1'
                        ,gv_cdkbn_storage
                        ,gv_tkn_from         -- �g�[�N��'�ۊǏꏊ1'
                        ,first_deliver_from
                        ,gv_tkn_codekbn2     -- �g�[�N��'�R�[�h�敪2'
                        ,lv_cdkbn_2_con
                        ,gv_tkn_to           -- �g�[�N��'�ۊǏꏊ2'
                        ,lt_intensive_tab(ln_child_no).deliver_to
                        ,gv_tkn_ship_method  -- �g�[�N��'�z���敪'
                        ,lv_mixed_ship_method
                        ,gv_tkn_source_no    -- �g�[�N��'�W��No'
                        ,first_intensive_source_no
                       ) ,1 ,5000);
          RAISE global_api_expt;
        END IF;
      END IF;
-- Ver1.3 M.Hokkanji End
      <<plsql_tab_setting_loop>>
      FOR rec_idx IN 1..lt_intensive_no_tab.COUNT LOOP
--2008/10/16 H.Itou Add Start T_S_625
        -- �����̏ꍇ�A���ځE�W����������܂��B
        IF (lv_small_amt_cnt <> 0) THEN
          -- ==============================
          --  �����z�����쐬����
          -- ==============================
          set_small_sam_class(
             iv_intensive_no => lt_intensive_no_tab(rec_idx)                 --�W��No
-- 2008/10/30 H.Itou Add Start �����e�X�g�w�E526 ���[�t�̏ꍇ�̔z���敪���w��
           , iv_ship_method  => lv_ship_optimization                         --�z���敪
-- 2008/10/30 H.Itou Add End
           , ov_errbuf       => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
           , ov_retcode      => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
           , ov_errmsg       => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          -- �������G���[�̏ꍇ
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
        ELSE
          -- 1���ڂ̂Ƃ��A���z��No�擾
          IF (rec_idx = 1) THEN
            -- ���z��NO�擾
            SELECT xxwsh_temp_delivery_no_s1.NEXTVAL
            INTO   ln_temp_ship_no
            FROM   dual;
          END IF;
--2008/10/16 H.Itou Add End T_S_625
debug_log(FND_FILE.LOG,'9-5PLSQL�Ɋi�[');
          -- �o�^�p�J�E���g
          ln_tab_ins_idx := ln_tab_ins_idx + 1;
debug_log(FND_FILE.LOG,'9-5-0 �C���T�[�g�J�E���g:'|| ln_tab_ins_idx);
debug_log(FND_FILE.LOG,'9-5-0 rec_idx:'|| rec_idx);
          -- =========================================
          -- �����z�ԍ��ڒ��ԃe�[�u���pPL/SQL�\�Ɋi�[
          -- =========================================
          gt_intensive_no_tab(ln_tab_ins_idx)         := lt_intensive_no_tab(rec_idx);
                                                                              -- �W��No
debug_log(FND_FILE.LOG,'9-5-1-0�W��No(gt_intensive_no_tab):'|| gt_intensive_no_tab(ln_tab_ins_idx));
          gt_delivery_no_tab(ln_tab_ins_idx)          := ln_temp_ship_no;       -- ���z��No
debug_log(FND_FILE.LOG,'9-5-1-0-1���z��Nogt_delivery_no_tab(ln_tab_ins_idx):'|| gt_delivery_no_tab(ln_tab_ins_idx));
          gt_default_line_number_tab(ln_tab_ins_idx)  := first_intensive_source_no;
debug_log(FND_FILE.LOG,'9-5-1-0-2�����No(gt_default_line_number_tab(ln_tab_ins_idx)):'|| gt_default_line_number_tab(ln_tab_ins_idx));
                                                                              -- �����No
debug_log(FND_FILE.LOG,'9-5-1-1-�C���z���敪');
--debug_log(FND_FILE.LOG,'9-5-1-1-1 ln_loop_cnt:'|| ln_loop_cnt);
--debug_log(FND_FILE.LOG,'9-5-1-1-1 ln_first_intensive_cnt:'|| ln_parent_no);
--debug_log(FND_FILE.LOG,'9-5-1-1-1 lt_mixed_class_tab(ln_parent_no):'|| lt_mixed_class_tab(ln_parent_no));
--debug_log(FND_FILE.LOG,'9-5-1-1-1 ln_tab_ins_idx:'|| ln_tab_ins_idx);
debug_log(FND_FILE.LOG,'9-5-1-1-1 ln_parent_no:'|| ln_parent_no);
--2008.05.27 D.Sugahara �s�No9�Ή�->
-- Ver1.3 M.Hokkanji Start
          -- ���ڃf�[�^�����[�g�ɑ��݂��邩�`�F�b�N���锻�f���s������
          -- �����敪�`�F�b�N�����[�v�O�Ɉړ�
/*
          --�����敪�m�F
          BEGIN
            SELECT  COUNT(xsmv.ship_method_code)                 -- �o�ו��@
              INTO  lv_small_amt_cnt
              FROM  xxwsh_ship_method2_v xsmv                    -- �z���敪���View2
             WHERE xsmv.ship_method_code = lv_ship_optimization  -- �z���敪
               AND xsmv.small_amount_class = '1'                 -- �����敪
               AND xsmv.start_date_active <= gd_date_from        -- �o�ו��@�K�p�J�n��
               AND (xsmv.end_date_active IS NULL
                    OR xsmv.end_date_active >= gd_date_from)     -- �o�ו��@�K�p�I����
              AND ROWNUM = 1
              ;
          EXCEPTION
            -- *** OTHERS��O�n���h�� ***
            WHEN OTHERS THEN
              lv_small_amt_cnt := 0;
          END;
*/
-- Ver1.3 M.Hokkanji End
--2008.05.27 D.Sugahara �s�No9�Ή�<-
          -- �C���z���敪
          IF (lt_mixed_class_tab(ln_parent_no) = gv_mixed_class_mixed) THEN
--        IF (lt_mixed_class_tab(ln_first_intensive_cnt) = gv_mixed_class_mixed) THEN
debug_log(FND_FILE.LOG,'9-5-1-1�C���z���敪�F����');
            -- ���ڎ�ʂ��u���ځv�̏ꍇ
--2008.05.27 D.Sugahara �s�No9�Ή�->
            --�����̏ꍇ�͍��ڔz���敪�ł͂Ȃ��ʏ�̔z���敪���Z�b�g����
            --gt_fixed_ship_code_tab(ln_tab_ins_idx)    := lv_mixed_ship_method;  -- ���ڔz���敪
            IF (lv_small_amt_cnt = 0) THEN
              gt_fixed_ship_code_tab(ln_tab_ins_idx)    := lv_mixed_ship_method;  -- ���ڔz���敪
            ELSE
              gt_fixed_ship_code_tab(ln_tab_ins_idx)    := lv_ship_optimization;  -- �o�ו��@
            END IF;
--2008.05.27 D.Sugahara �s�No9�Ή�<-
          ELSE
debug_log(FND_FILE.LOG,'9-5-1-2�C���z���敪�F�W��');
            -- ���ڎ�ʂ��u�W��v�̏ꍇ
            gt_fixed_ship_code_tab(ln_tab_ins_idx)    := lv_ship_optimization;  -- �o�ו��@
          END IF;
debug_log(FND_FILE.LOG,'9-5-1-2�C���z���敪:'||ln_tab_ins_idx);
debug_log(FND_FILE.LOG,'9-5-1-2�C���z���敪:'||gt_fixed_ship_code_tab(ln_tab_ins_idx));
          -- ���ڎ��
          IF lv_mixed_flag = gv_mixed_class_mixed THEN
debug_log(FND_FILE.LOG,'9-5-2-1���ڎ�ʁF����');
debug_log(FND_FILE.LOG,'9-5-2-1-1ln_tab_ins_idx:'||ln_tab_ins_idx);
--
            gt_mixed_class_tab(ln_tab_ins_idx)        := gv_mixed_class_mixed; -- ����
--
          ELSE
debug_log(FND_FILE.LOG,'9-5-2-2���ڎ�ʁF�W��');
--
            gt_mixed_class_tab(ln_tab_ins_idx)        := gv_mixed_class_int;   -- �W��
--
          END IF;
--
          -- ���ڍ��v�d��
          gt_mixed_total_weight_tab(ln_tab_ins_idx)   := lt_mix_total_weight(rec_idx);
debug_log(FND_FILE.LOG,'9-5-3���ڍ��v�d��');
--
          -- ���ڍ��v�e��
          gt_mixed_total_capacity_tab(ln_tab_ins_idx) := lt_mix_total_capacity(rec_idx);
debug_log(FND_FILE.LOG,'9-5-4���ڍ��v�e��');
--
          -- ���ڌ�No
          gt_mixed_no_tab(ln_tab_ins_idx)             := first_intensive_source_no;
debug_log(FND_FILE.LOG,'9-5-5���ڌ�No');
--
--2008/10/16 H.Itou Add Start T_S_625
        END IF;
--2008/10/16 H.Itou Add End
      END LOOP plsql_tab_setting_loop;
debug_log(FND_FILE.LOG,'9-6 ���ڍ��v�d�ʁA���ڍ��v�e�ς����Z�b�g');
      -- ���ڍ��v�d�ʁA���ڍ��v�e�ς����Z�b�g
      ln_intensive_weight   := 0; -- ���ڍ��v�d��
      ln_intensive_capacity := 0; -- ���ڍ��v�e��
      ln_order_num_cnt      := 1; -- �z���敪������
--
      -- ���ڍ��v�d�ʁE�e�ϓo�^�p�J�E���g���Z�b�g
      ln_intensive_no_cnt   := 0;   -- �J�E���^
      lt_intensive_no_tab.DELETE;   -- �W��No�p�e�[�u��
      -- ���ڍ��v�d�ʁE�e�Ϗ�����
      lt_mix_total_weight.DELETE;
      lt_mix_total_capacity.DELETE;
--
debug_log(FND_FILE.LOG,'6-7 PL/SQL�\������');
      -- PL/SQL�\���Z�b�g
      lt_intensive_no_tab.DELETE; -- �W��No
      lt_mixed_class_tab.DELETE;  -- ���ڎ��
--
      -- ���[�v�J�E���g���Z�b�g
--        ln_loop_cnt := ln_start_no - 1;
--debug_log(FND_FILE.LOG,'6-7-1 ���[�v�J�E���g���Z�b�g:'|| ln_loop_cnt);
        -- �O���[�v�J�E���g�����Z�b�g����
--        ln_grp_sum_cnt := 0;
--debug_log(FND_FILE.LOG,'6-7-2 �O���[�v�J�E���g���Z�b�g:'|| ln_grp_sum_cnt);
      -- ���ڍσt���O������
      lv_mixed_flag := NULL;
    EXCEPTION
      -- *** ���ʊ֐���O�n���h�� ***
      WHEN global_api_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||lv_errbuf,1,5000);
        ov_retcode := gv_status_error;
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      WHEN global_api_others_expt THEN
        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||cv_sub_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
--
    END set_ins_data;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
debug_log(FND_FILE.LOG,'�y�W�񒆊ԏ�񒊏o����(B-9)�z');
--
    -- �����z�ԏW�񒆊ԃe�[�u���p�e�[�u��������
    lt_intensive_tab.DELETE;
    lt_mixed_class_tab.DELETE;
    lt_mix_total_weight.DELETE;
    lt_mix_total_capacity.DELETE;
--
    -- �����z�ԍ��ڒ��ԃe�[�u���o�^�pPL/SQL�\������
    gt_intensive_no_tab.DELETE;         -- �W��No
    gt_delivery_no_tab.DELETE;          -- �z��No
    gt_default_line_number_tab.DELETE;  -- �����No
    gt_fixed_ship_code_tab.DELETE;      -- �C���z���敪
    gt_mixed_class_tab.DELETE;          -- ���ڎ��
    gt_mixed_total_weight_tab.DELETE;   -- ���ڍ��v�d��
    gt_mixed_total_capacity_tab.DELETE; -- ���ڍ��v�e��
    gt_mixed_no_tab.DELETE;             -- ���ڌ�No
--
    -- =========================
    -- B-9.�W�񒆊ԏ�񒊏o����
    -- =========================
    OPEN get_intensive_cur;
    FETCH get_intensive_cur BULK COLLECT INTO lt_intensive_tab;
    CLOSE get_intensive_cur;
--
    -- �W��f�[�^�����݂���
    IF (lt_intensive_tab.COUNT > 0) THEN
--
debug_log(FND_FILE.LOG,'�W��START');
--
      <<optimization_loop>>
      LOOP
-----
debug_cnt := debug_cnt + 1;
-----
        -- ���[�v�J�E���g
        ln_loop_cnt := ln_loop_cnt + 1;
--
debug_log(FND_FILE.LOG,'----------------------------');
debug_log(FND_FILE.LOG,'1 ln_loop_cnt1:'|| ln_loop_cnt);
--
        -- �����ڃf�[�^�̂ݑΏ�
        IF (lt_intensive_tab(ln_loop_cnt).finish_sum_flag IS NULL) THEN
--
          -- �O���[�v�J�E���g
          ln_grp_sum_cnt := ln_grp_sum_cnt + 1;
--
debug_log(FND_FILE.LOG,'1-1 �O���[�v�J�E���g:'|| ln_grp_sum_cnt);
debug_log(FND_FILE.LOG,'���[�v�J�E���g'|| ln_loop_cnt);
debug_log(FND_FILE.LOG,'----------------------------------------');
--
          IF  (ln_grp_sum_cnt = 1) THEN
--
            -- ����R�[�h�J�E���g�ێ�
            ln_parent_no  := ln_loop_cnt;
--
debug_log(FND_FILE.LOG,'1-1-1����R�[�h��ݒ�');
debug_log(FND_FILE.LOG,'----------------------------------------');
debug_log(FND_FILE.LOG,'1-1-1 ln_parent_no:'|| ln_parent_no);
debug_log(FND_FILE.LOG,'�W��No:'|| lt_intensive_tab(ln_parent_no).intensive_no);
debug_log(FND_FILE.LOG,'�������:'|| lt_intensive_tab(ln_parent_no).transaction_type);
debug_log(FND_FILE.LOG,'�W��No:'|| lt_intensive_tab(ln_parent_no).intensive_source_no);
debug_log(FND_FILE.LOG,'�z����:'|| lt_intensive_tab(ln_parent_no).deliver_from);
debug_log(FND_FILE.LOG,'�z����:'|| lt_intensive_tab(ln_parent_no).deliver_to);
debug_log(FND_FILE.LOG,'�o�ɗ\���:'|| lt_intensive_tab(ln_parent_no).schedule_ship_date);
debug_log(FND_FILE.LOG,'���ח\���:'|| lt_intensive_tab(ln_parent_no).schedule_arrival_date);
debug_log(FND_FILE.LOG,'�o�Ɍ`��:'|| lt_intensive_tab(ln_parent_no).transaction_type_name);
debug_log(FND_FILE.LOG,'�^���Ǝ�:'|| lt_intensive_tab(ln_parent_no).freight_carrier_code);
debug_log(FND_FILE.LOG,'�Ǌ����_:'|| lt_intensive_tab(ln_parent_no).head_sales_branch);
debug_log(FND_FILE.LOG,'������:'|| lt_intensive_tab(ln_parent_no).reserve_order);
debug_log(FND_FILE.LOG,'�W�񍇌v�d��:'|| lt_intensive_tab(ln_parent_no).intensive_sum_weight);
debug_log(FND_FILE.LOG,'�W�񍇌v�e��:'|| lt_intensive_tab(ln_parent_no).intensive_sum_capacity);
debug_log(FND_FILE.LOG,'�ő�z���敪:'|| lt_intensive_tab(ln_parent_no).max_shipping_method_code);
debug_log(FND_FILE.LOG,'�d�ʗe�ϋ敪:'|| lt_intensive_tab(ln_parent_no).weight_capacity_class);
debug_log(FND_FILE.LOG,'�ő�ύڏd��:'|| lt_intensive_tab(ln_parent_no).max_weight);
debug_log(FND_FILE.LOG,'�ő�ύڗe��:'|| lt_intensive_tab(ln_parent_no).max_capacity);
--
--
            -- �O���[�v��1���R�[�h�ڂ��m��:����R�[�h
            first_intensive_no
                  := lt_intensive_tab(ln_parent_no).intensive_no;              -- �W��No
            first_transaction_type
                  := lt_intensive_tab(ln_parent_no).transaction_type;          -- �������
            first_intensive_source_no
                  := lt_intensive_tab(ln_parent_no).intensive_source_no;       -- �W��No(�����)
            first_deliver_from
                  := lt_intensive_tab(ln_parent_no).deliver_from;              -- �z����
            first_deliver_to
                  := lt_intensive_tab(ln_parent_no).deliver_to;                -- �z����
            first_schedule_ship_date
                  := lt_intensive_tab(ln_parent_no).schedule_ship_date;        -- �o�ɓ�
            first_schedule_arrival_date
                  := lt_intensive_tab(ln_parent_no).schedule_arrival_date;     -- ���ד�
            first_transaction_type_name
                  := lt_intensive_tab(ln_parent_no).transaction_type_name;     -- �o�Ɍ`��
            first_freight_carrier_code
                  := lt_intensive_tab(ln_parent_no).freight_carrier_code;      -- �^���Ǝ�
            first_intensive_sum_weight
                  := lt_intensive_tab(ln_parent_no).intensive_sum_weight;      -- �W�񍇌v�d��
            first_intensive_sum_capacity
                  := lt_intensive_tab(ln_parent_no).intensive_sum_capacity;    -- �W�񍇌v�e��
            first_max_shipping_method_code
                  := lt_intensive_tab(ln_parent_no).max_shipping_method_code;  -- �ő�z���敪
            first_weight_capacity_class
                  := lt_intensive_tab(ln_parent_no).weight_capacity_class;     -- �d�ʗe�ϋ敪
            first_max_weight
                  := lt_intensive_tab(ln_parent_no).max_weight;                -- �ő�ύڏd��
            first_max_capacity
                  := lt_intensive_tab(ln_parent_no).max_capacity;              -- �ő�ύڗe��
-- 2009/01/05 H.Itou Mod Start �{�ԏ�Q#879
            first_pre_saved_flg := lt_intensive_tab(ln_parent_no).pre_saved_flg;  -- ���_���ړo�^�σt���O
-- 2009/01/05 H.Itou Mod End
--
            -- ��r�p�ϐ��ɃL�[���ڂ��i�[
            lt_prev_ship_date       := lt_intensive_tab(ln_parent_no).schedule_ship_date;    -- �o�ɓ�
            lt_prev_arrival_date    := lt_intensive_tab(ln_parent_no).schedule_arrival_date; -- ���ד�
            lt_prev_ship_from       := lt_intensive_tab(ln_parent_no).deliver_from;          -- �o�׌�
            lt_prev_freight_carrier := lt_intensive_tab(ln_parent_no).freight_carrier_code;  -- �^���Ǝ�
            lt_prev_w_c_class       := lt_intensive_tab(ln_parent_no).weight_capacity_class; -- �d�ʗe�ϋ敪
--
            -- ��r�p�z���敪
            lt_ship_method_cls      := first_max_shipping_method_code;  -- �ő�z���敪
--
            -- =========================================
            -- ����R�[�h�̍��ڃe�[�u���p�f�[�^���o�^
            -- =========================================
debug_log(FND_FILE.LOG,'1-2����R�[�h�̃f�[�^���i�[');
--
            -- ���ڃJ�E���^
            ln_intensive_no_cnt := ln_intensive_no_cnt + 1;
--
debug_log(FND_FILE.LOG,'1-2-1���ڃJ�E���^:'|| ln_intensive_no_cnt);
--
            -- �W��No�pPLSQL�\�Ɋi�[
            lt_intensive_no_tab(ln_intensive_no_cnt) := lt_intensive_tab(ln_parent_no).intensive_no;
--
            -- �d��
            IF (lt_intensive_tab(ln_parent_no).weight_capacity_class = gv_weight) THEN
--
debug_log(FND_FILE.LOG,'1-2-1-1�d��');
debug_log(FND_FILE.LOG,'1-2-1-2 �d��:'||lt_intensive_tab(ln_loop_cnt).intensive_sum_weight);
debug_log(FND_FILE.LOG,'1-2-1-3 lt_mix_total_weight.count:'||lt_mix_total_weight.count);
                -- �W�񍇌v�d��
                lt_mix_total_weight(ln_intensive_no_cnt)
                    := lt_intensive_tab(ln_parent_no).intensive_sum_weight;
--
debug_log(FND_FILE.LOG,'1-2-1-4 ���ڍ��v�d�ʃZ�b�g');
                -- �W�񍇌v�e��
                lt_mix_total_capacity(ln_intensive_no_cnt) := NULL;
debug_log(FND_FILE.LOG,'1-2-1-5 ���ڍ��v�e�σZ�b�g');
                -- ���Z�`�F�b�N�p
                ln_intensive_weight := lt_mix_total_weight(ln_intensive_no_cnt);
debug_log(FND_FILE.LOG,'1-2-1-6 ���Z�`�F�b�N�p����R�[�h�d�ʃZ�b�g');
--
debug_log(FND_FILE.LOG,'GRP���ڍ��v�d��:'|| ln_intensive_weight);
debug_log(FND_FILE.LOG,'���ڍσt���O:'|| lv_mixed_flag);
--
              -- �e��
              ELSE
--
debug_log(FND_FILE.LOG,'1-2-2-1�e��');
                -- �W�񍇌v�d��
                lt_mix_total_weight(ln_intensive_no_cnt) := NULL;
--
                -- �W�񍇌v�e��
                lt_mix_total_capacity(ln_intensive_no_cnt)
                    := lt_intensive_tab(ln_parent_no).intensive_sum_capacity;
                -- ���Z�`�F�b�N�p
                ln_intensive_capacity := lt_mix_total_capacity(ln_intensive_no_cnt);
--
              END IF;
--            -- ���ڍσf�[�^�J�E���^�i�[
--            lt_mixed_cnt_tab(ln_intensive_no_cnt) := ln_first_intensive_cnt;
--
debug_log(FND_FILE.LOG,'1-2-2-2�W��No�i�[');
debug_log(FND_FILE.LOG,'1-2-2-4�W��No�i�[�J�E���g(ln_intensive_no_cnt):'|| ln_intensive_no_cnt);
debug_log(FND_FILE.LOG,'1-2-2-5�W��No:'|| lt_intensive_no_tab(ln_intensive_no_cnt));
          END IF;
--
debug_log(FND_FILE.LOG,'----------------------------------------');
debug_log(FND_FILE.LOG,'2�����R�[�h�Ǎ��F��r�Ώ�');
debug_log(FND_FILE.LOG,'----------------------------------------');
debug_log(FND_FILE.LOG,'�o�ɗ\���:'|| lt_intensive_tab(ln_loop_cnt).schedule_ship_date);
debug_log(FND_FILE.LOG,'���ח\���:'|| lt_intensive_tab(ln_loop_cnt).schedule_arrival_date);
debug_log(FND_FILE.LOG,'�z����:'|| lt_intensive_tab(ln_loop_cnt).deliver_from);
debug_log(FND_FILE.LOG,'�^���Ǝ�:'|| lt_intensive_tab(ln_loop_cnt).freight_carrier_code);
debug_log(FND_FILE.LOG,'�d�ʗe�ϋ敪:'|| lt_intensive_tab(ln_loop_cnt).weight_capacity_class);
debug_log(FND_FILE.LOG,'�W��No:'|| lt_intensive_tab(ln_loop_cnt).intensive_source_no);
debug_log(FND_FILE.LOG,'----------------------------------------');
--
          -- �L�[���ڂ̓����f�[�^�����ڂ���i�L�[�u���C�N���Ȃ��j
          IF  (
                (lt_prev_ship_date           = lt_intensive_tab(ln_loop_cnt).schedule_ship_date)
                                                                                      -- �o�ɓ�
                AND (lt_prev_arrival_date    = lt_intensive_tab(ln_loop_cnt).schedule_arrival_date)
                                                                                      -- ���ד�
                AND (lt_prev_ship_from       = lt_intensive_tab(ln_loop_cnt).deliver_from)
                                                                                      -- �o�׌�
                AND (lt_prev_freight_carrier = lt_intensive_tab(ln_loop_cnt).freight_carrier_code)
                                                                                      -- �^���Ǝ�
                AND (lt_prev_w_c_class       = lt_intensive_tab(ln_loop_cnt).weight_capacity_class)
              )                                                                       -- �d�ʗe�ϋ敪
--
          THEN
--
debug_log(FND_FILE.LOG,'3���ڏ���');
            -- �O���[�v��1���ڂ̏d�ʁ^�e�ς��W��ϐ��Ɋi�[
            IF (ln_grp_sum_cnt > 1) THEN
--
debug_log(FND_FILE.LOG,'3-2 ���ڑ���Ǎ�');
debug_log(FND_FILE.LOG,'2���R�[�h�ڈȍ~');
--
              -- �R�[�h�敪�P�A�Q�̐ݒ�
              IF (lt_intensive_tab(ln_loop_cnt).transaction_type = gv_ship_type_ship) THEN -- �o�׈˗�
                lv_cdkbn_1  :=  gv_cdkbn_ship_to; -- �z����
                lv_cdkbn_2  :=  gv_cdkbn_ship_to; -- �z����
              ELSE
                lv_cdkbn_1  :=  gv_cdkbn_storage; -- �q��
                lv_cdkbn_2  :=  gv_cdkbn_storage; -- �q��
              END IF;
--
-- 2008/10/01 H.Itou Add Start PT 6-1_27 �w�E18 ����R�[�h�Ɠ����z����̏ꍇ�͏d�ʃI�[�o�[�ō��ڂł��Ȃ��̂ŁA���ڕs�Ƃ���B
-- 2009/01/05 H.Itou Mod Start �{�ԏ�Q#879 ����R�[�h�����_���ړo�^�ς݂̏ꍇ�A���ꍬ�ڌ�No(�W��No)�ȊO�A���ڕs�Ƃ���B
--              IF (first_deliver_to = lt_intensive_tab(ln_loop_cnt).deliver_to) THEN
              IF   ((first_deliver_to = lt_intensive_tab(ln_loop_cnt).deliver_to) 
                OR ((cv_pre_save IN (first_pre_saved_flg, lt_intensive_tab(ln_loop_cnt).pre_saved_flg))
                AND (first_intensive_source_no <> lt_intensive_tab(ln_loop_cnt).intensive_source_no))) THEN
-- 2009/01/05 H.Itou Mod End
                -- ���ډۃt���O�F�s��
                lv_consolid_flag := NULL;
--
              -- ����R�[�h�ƈႤ�z����̏ꍇ�́A���ډ۔��菈�����ĂсA���ڋ��t���O���擾����B
              ELSE
-- 2008/10/01 H.Itou Add End
debug_log(FND_FILE.LOG,'3-3 ���ډ۔���@');
--
                -- ============================
                -- ���ډ۔��菈���F���[�g�@
                -- ============================
                get_consolidated_flag(
                      iv_code_class1                => lv_cdkbn_1         -- �R�[�h�敪�P
                    , iv_entering_despatching_code1 => first_deliver_to   -- ���o�ɏꏊ�P
                    , iv_code_class2                => lv_cdkbn_2         -- �R�[�h�敪�Q
                    , iv_entering_despatching_code2 => lt_intensive_tab(ln_loop_cnt).deliver_to
                                                                          -- ���o�ɏꏊ�Q
                    , iv_ship_method                => NULL               -- �z���敪����
                    , ov_consolidate_flag           => lv_consolid_flag   -- ���ډۃt���O
                    , ov_errbuf                     => lv_errbuf
                    , ov_retcode                    => lv_retcode
                    , ov_errmsg                     => lv_errmsg
                );
--
debug_log(FND_FILE.LOG,'���ډ۔��菈���F���[�g�@');
debug_log(FND_FILE.LOG,'�R�[�h�敪1�F'|| lv_cdkbn_1);
debug_log(FND_FILE.LOG,'���o�ɏꏊ1�F'|| first_deliver_to);
debug_log(FND_FILE.LOG,'�R�[�h�敪2�F'|| lv_cdkbn_2);
debug_log(FND_FILE.LOG,'���o�ɏꏊ2�F'|| lt_intensive_tab(ln_loop_cnt).deliver_to);
--
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
--
                -- ���ډ۔��菈���@�ō��ډۃt���O���擾�ł��Ȃ��ꍇ�A�t���[�g�Ō�������
                IF (lv_consolid_flag IS NULL) THEN
debug_log(FND_FILE.LOG,'3-4 ���ډ۔���A');
                  -- ============================
                  -- ���ډ۔��菈���F���[�g�A
                  -- ============================
                  get_consolidated_flag(
                        iv_code_class1                => lv_cdkbn_2       -- �R�[�h�敪�Q
                      , iv_entering_despatching_code1 => lt_intensive_tab(ln_loop_cnt).deliver_to
                                                                          -- ���o�ɏꏊ�Q
                      , iv_code_class2                => lv_cdkbn_1       -- �R�[�h�敪�P
                      , iv_entering_despatching_code2 => first_deliver_to -- ���o�ɏꏊ�P
                      , iv_ship_method                => NULL             -- �z���敪����
                      , ov_consolidate_flag           => lv_consolid_flag -- ���ډۃt���O
                      , ov_errbuf                     => lv_errbuf
                      , ov_retcode                    => lv_retcode
                      , ov_errmsg                     => lv_errmsg
                  );
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  END IF;
--
debug_log(FND_FILE.LOG,'���ډ۔��菈���F���[�g�A');
debug_log(FND_FILE.LOG,'�R�[�h�敪1�F'|| lv_cdkbn_2);
debug_log(FND_FILE.LOG,'���o�ɏꏊ1�F'|| lt_intensive_tab(ln_loop_cnt).deliver_to);
debug_log(FND_FILE.LOG,'�R�[�h�敪2�F'|| lv_cdkbn_1);
debug_log(FND_FILE.LOG,'���o�ɏꏊ2�F'|| first_deliver_to);
--
                END IF;
-- 2008/10/01 H.Itou Add Start PT 6-1_27 �w�E18
              END IF;
-- 2008/10/01 H.Itou Add End
--
debug_log(FND_FILE.LOG,'���ڋ��t���O�F'|| lv_consolid_flag);
--
              -- ���ڋ��t���O�i���[�g�j�F����
              IF (lv_consolid_flag = cn_consolid_parmit) THEN
debug_log(FND_FILE.LOG,'3-5 ���ڋ���');
--
                -- �ő�z���敪������̏ꍇ
                IF (lt_ship_method_cls = lt_intensive_tab(ln_loop_cnt).max_shipping_method_code) THEN
debug_log(FND_FILE.LOG,'3-5-1 �ő�z���敪������');
--
                  -- ���ڂ�����
                  lv_consolid_flag_ships := cn_consolid_parmit;
--
                ELSE
--
debug_log(FND_FILE.LOG,'3-5-2 �ő�z���敪������ł͂Ȃ�');
                  -- ============================
                  -- ���ډ۔��菈���F�z���敪
                  -- ===========================
--
debug_log(FND_FILE.LOG,'3-5-2-1���ډ۔��菈���F�z���敪');
--
                  -- �R�[�h�敪�P�A�Q�̐ݒ�
                  IF (lt_intensive_tab(ln_loop_cnt).transaction_type = gv_ship_type_ship) THEN -- �o�׈˗�
                    lv_cdkbn_2  :=  gv_cdkbn_ship_to; -- �z����
                  ELSE
                    lv_cdkbn_2  :=  gv_cdkbn_storage; -- �q��
                  END IF;
--
                  -- �������R�[�h�̔z���敪�Ɋ���ׂ̔z���敪���܂܂�Ă��邩�`�F�b�N
debug_log(FND_FILE.LOG,'3-5-2-2�������R�[�h�̔z���敪�Ɋ���ׂ̔z���敪���܂܂�Ă��邩�`�F�b�N');
debug_log(FND_FILE.LOG,'cdkbn_1(from)= '||gv_cdkbn_storage);
debug_log(FND_FILE.LOG,'despatching_code1(from)= '||first_deliver_from);
debug_log(FND_FILE.LOG,'cdkbn_2(to)= '||lv_cdkbn_2);
debug_log(FND_FILE.LOG,'despatching_code2(to)= '||lt_intensive_tab(ln_loop_cnt).deliver_to);
debug_log(FND_FILE.LOG,'lt_ship_method_cls= '||lt_ship_method_cls);
                  get_consolidated_flag(
                        iv_code_class1                => gv_cdkbn_storage      -- �R�[�h�敪�P
--20080714 mod                      , iv_entering_despatching_code1 => first_deliver_to   -- ���o�ɏꏊ�P
                      , iv_entering_despatching_code1 => first_deliver_from               -- ���o�ɏꏊ�P
                      , iv_code_class2                => lv_cdkbn_2         -- �R�[�h�敪�Q
                      , iv_entering_despatching_code2 => lt_intensive_tab(ln_loop_cnt).deliver_to
                                                                            -- ���o�ɏꏊ�Q
                      , iv_ship_method                => lt_ship_method_cls -- �z���敪
                      , ov_consolidate_flag           => lv_consolid_flag_ships
                                                                            -- ���ډۃt���O:�z���敪
                      , ov_errbuf                     => lv_errbuf
                      , ov_retcode                    => lv_retcode
                      , ov_errmsg                     => lv_errmsg
                  );
                  IF (lv_retcode = gv_status_error) THEN
                    gv_err_key  :=  lv_cdkbn_1
                                    || gv_msg_comma ||
                                    first_deliver_to
                                    || gv_msg_comma ||
                                    lv_cdkbn_2
                                    || gv_msg_comma ||
                                    lt_intensive_tab(ln_loop_cnt).deliver_to
                                    || gv_msg_comma ||
                                    lt_ship_method_cls
                                    ;
                    -- �G���[���b�Z�[�W�擾
                    lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                                    gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                                  , gv_msg_xxwsh_11810  -- ���b�Z�[�W�FAPP-XXWSH-11810 ���ʊ֐��G���[
                                  , gv_fnc_name         -- �g�[�N���FFNC_NAME
                                  , 'get_consolidated_flag' -- �֐���
                                  , gv_tkn_key              -- �g�[�N���FKEY
                                  , gv_err_key              -- �֐����s�L�[
                                 ),1,5000);
                    RAISE global_api_expt;
                  END IF;
--
                END IF;
--
--
debug_log(FND_FILE.LOG,'3-5-3���ڋ��t���O�i�z���敪�j:'|| lv_consolid_flag_ships);
                -- ���ڋ��t���O�i�z���敪�j�F����
                IF (lv_consolid_flag_ships = cn_consolid_parmit) THEN
debug_log(FND_FILE.LOG,'3-6�W�񍇌v�d�ʁ^�e�ω��Z');
--
                  -- ============================
                  -- B-11.�W�񍇌v�d�ʁ^�e�ω��Z
                  -- ============================
                  -- ���ڍ��v�d��
                  IF (lt_intensive_tab(ln_loop_cnt).weight_capacity_class = gv_weight) THEN
debug_log(FND_FILE.LOG,'3-6-1���ڍ��v�d��');
debug_log(FND_FILE.LOG,'����R�[�h�̍ő�ύڏd�ʁF'||first_max_weight);
--
                    -- ����R�[�h�̍ő�ύڏd�ʂƔ�r
                    IF (first_max_weight <
                          ln_intensive_weight + lt_intensive_tab(ln_loop_cnt).intensive_sum_weight)
                    THEN
debug_log(FND_FILE.LOG,'3-6-1-1���ڍ��v�d�ʃI�[�o�[');
                      -- ���ڍσt���O�ݒ�
                      lv_mixed_flag  := NULL;
                    ELSE  -- ���ډ\
debug_log(FND_FILE.LOG,'3-6-1-2���ڍ��v�d�ʉ��Z');
debug_log(FND_FILE.LOG,'3-6-1-2ln_loop_cnt:'||ln_loop_cnt);
                      -- ���ڑ���̃J�E���^�ێ�
                      ln_child_no := ln_loop_cnt;
--
                      -- ���ڃJ�E���^
                      ln_intensive_no_cnt := ln_intensive_no_cnt + 1;
debug_log(FND_FILE.LOG,'3-6-1-2-1 ln_intensive_no_cnt:'||ln_intensive_no_cnt);
                      -- �W�񍇌v�d��(���ڑ���)
                      lt_mix_total_weight(ln_intensive_no_cnt)
                          := lt_intensive_tab(ln_child_no).intensive_sum_weight;
--
                      -- �W�񍇌v�e��(���ڑ���)
                      lt_mix_total_capacity(ln_intensive_no_cnt) := NULL;
--
                      -- ���ڍ��v�d��(����R�[�h�W�񍇌v�d��+���ڑ���̏W�񍇌v�d��)
                      ln_intensive_weight
                          := ln_intensive_weight + lt_intensive_tab(ln_child_no).intensive_sum_weight;
--
                      -- ���ڍσt���O�ݒ�
                      lv_mixed_flag  := gv_mixed_class_mixed; -- ����
                    END IF;
--
debug_log(FND_FILE.LOG,'GRP�W�񍇌v�d��:'|| ln_intensive_weight);
--
                  -- ���ڍ��v�e��
                  ELSE
--
debug_log(FND_FILE.LOG,'3-6-2���ڍ��v�e��');
debug_log(FND_FILE.LOG,'����R�[�h�̍ő�ύڗe�ρF'||first_max_capacity);
debug_log(FND_FILE.LOG,'3-6-2-1 first_max_capacity:'|| first_max_capacity);
debug_log(FND_FILE.LOG,'3-6-2-1 ln_intensive_capacity:'|| ln_intensive_capacity);
debug_log(FND_FILE.LOG,'3-6-2-1 lt_intensive_tab(ln_loop_cnt).intensive_sum_capacity:'|| lt_intensive_tab(ln_loop_cnt).intensive_sum_capacity);
                    -- ����R�[�h�̍ő�ύڗe�ςƔ�r
                    IF (first_max_capacity <
                        ln_intensive_capacity + lt_intensive_tab(ln_loop_cnt).intensive_sum_capacity)
                    THEN
--
debug_log(FND_FILE.LOG,'3-6-2-1 ���ڍ��v�e�σI�[�o�[');
                      -- ���ڍσt���O�ݒ�
                      lv_mixed_flag  := NULL;
--
                    ELSE  -- ���ډ\
debug_log(FND_FILE.LOG,'3-6-2-2 ���ڍ��v�e�ω��Z');
debug_log(FND_FILE.LOG,'3-6-2-2 ln_loop_cnt�F'|| ln_loop_cnt);
                      -- ���ڑ���̃J�E���^�ێ�
                      ln_child_no := ln_loop_cnt;
--
                      -- ���ڃJ�E���^
                      ln_intensive_no_cnt := ln_intensive_no_cnt + 1;
                      -- �W�񍇌v�d��(���ڑ���)
                      lt_mix_total_weight(ln_intensive_no_cnt) := NULL;
--
                      -- �W�񍇌v�e��(���ڑ���)
                      lt_mix_total_capacity(ln_intensive_no_cnt)
                          := lt_intensive_tab(ln_child_no).intensive_sum_capacity;
                      -- ���ڍ��v�e��(����R�[�h�W�񍇌v�e��+���ڑ���̏W�񍇌v�e��)
                      ln_intensive_capacity
                          := ln_intensive_capacity + lt_intensive_tab(ln_child_no).intensive_sum_capacity;
--
                      -- ���ڍσt���O�ݒ�
                      lv_mixed_flag  := gv_mixed_class_mixed; -- ����
--
                    END IF;
--
                  END IF;
--
                  --======================
                  -- ���ڂ����ꍇ
                  --======================
                  IF (lv_mixed_flag = gv_mixed_class_mixed) THEN
--
debug_log(FND_FILE.LOG,'3-7���ڍ�');
--
                    -- ����R�[�h�̍��ڎ�ʊi�[
                    lt_mixed_class_tab(ln_parent_no)  := gv_mixed_class_mixed;  -- ����
--
debug_log(FND_FILE.LOG,'3-7-1����R�[�h�̍��ڎ�ʁF'||lt_mixed_class_tab(ln_parent_no));
--
                    -- ����R�[�h�̏����σt���O�ݒ�
                    lt_intensive_tab(ln_parent_no).finish_sum_flag
                                                                := cv_finish_intensive;   --  ������
--
debug_log(FND_FILE.LOG,'3-7-2����R�[�h�̏����σt���O�F'||lt_intensive_tab(ln_parent_no).finish_sum_flag);
--
                    -- ���ڑ���̍��ڎ�ʊi�[
                    lt_mixed_class_tab(ln_child_no)  := gv_mixed_class_mixed;  -- ����
debug_log(FND_FILE.LOG,'3-7-3���ڑ���̍��ڎ�ʁF'||lt_mixed_class_tab(ln_child_no));
debug_log(FND_FILE.LOG,'ln_child_no�F'||ln_child_no);
--
                    -- ���ڑ���̏����σt���O�ݒ�
                    lt_intensive_tab(ln_child_no).finish_sum_flag
                                                                := cv_finish_intensive;   --  ������
--
debug_log(FND_FILE.LOG,'3-7-4���ڑ���̏����σt���O�F'||lt_intensive_tab(ln_child_no).finish_sum_flag);
--********************************************************************************************
                    -- ���ڑ���̃��R�[�h���Z�b�g����
--
debug_log(FND_FILE.LOG,'3-7-5���ڃJ�E���^:'|| ln_intensive_no_cnt);
                    -- �W��No�pPLSQL�\�ɍ��ڑ�����i�[
                    lt_intensive_no_tab(ln_intensive_no_cnt)
                          := lt_intensive_tab(ln_child_no).intensive_no;
--
--                    -- ���ڍσf�[�^�J�E���^�i�[
--                    lt_mixed_cnt_tab(ln_intensive_no_cnt) := ln_loop_cnt;
--
debug_log(FND_FILE.LOG,'3-7-6�W��σt���O�ݒ�F'||lt_intensive_tab(ln_child_no).finish_sum_flag);
--
                  END IF;
--
                END IF;
--
              END IF;
--
            END IF;
--
          -- =========================
          -- �L�[�u���C�N��
          -- =========================
          ELSE
--
debug_log(FND_FILE.LOG,'4�L�[�u���C�N');
--
              -- �R�[�h�敪�Q�ݒ�
              IF (lt_intensive_tab(ln_loop_cnt).transaction_type = gv_ship_type_ship) THEN -- �o�׈˗�
                lv_cdkbn_2  :=  gv_cdkbn_ship_to; -- �z����
              ELSE
                lv_cdkbn_2  :=  gv_cdkbn_storage; -- �q��
              END IF;
--
            -- �L�[�u���C�N������
            lproc_keybrake_process(
                  ov_errbuf     => lv_errbuf
                , ov_retcode    => lv_retcode
                , ov_errmsg     => lv_errmsg
            );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--
            -- ���[�v�J�E���^������
            ln_loop_cnt := 0;
---------------------
          END IF;
--
debug_log(FND_FILE.LOG,'ln_loop_cnt�F'|| ln_loop_cnt);
debug_log(FND_FILE.LOG,'lt_intensive_tab.COUNT:'|| lt_intensive_tab.COUNT);
--
          -- =================================
          -- ���ڍρA�W��ς̏ꍇ
          -- =================================
          IF (lv_mixed_flag IS NOT NULL) THEN
debug_log(FND_FILE.LOG,'6���ڍρA�W���:PLSQL�ɃZ�b�g');
            set_ins_data(
                  ov_errbuf     => lv_errbuf
                , ov_retcode    => lv_retcode
                , ov_errmsg     => lv_errmsg
            );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--
debug_log(FND_FILE.LOG,'ln_tab_ins_idx:'||ln_tab_ins_idx);
--debug_log(FND_FILE.LOG,'gt_fixed_ship_code_tab:'||gt_fixed_ship_code_tab(ln_tab_ins_idx));
--
debug_log(FND_FILE.LOG,'6-1�Ď��s�t���OON or NULL');
            -- ���[�v�J�E���g���Z�b�g
            ln_loop_cnt := 0;
debug_log(FND_FILE.LOG,'6-1-1���[�v�J�E���g���Z�b�g:'||ln_loop_cnt);
            -- �O���[�v�J�E���^���Z�b�g(�ŏ��̓Ǎ����R�[�h������R�[�h�ɂ���)
            ln_grp_sum_cnt := 0;
debug_log(FND_FILE.LOG,'6-1-2 �O���[�v�J�E���g���Z�b�g:'||ln_grp_sum_cnt);
            -- ���ڍσt���O���Z�b�g
            lv_mixed_flag := NULL;
          END IF;
        END IF;
--
        -- =======================
        -- �ŏI�f�[�^�m�菈��
        -- =======================
        IF (ln_loop_cnt = lt_intensive_tab.COUNT) THEN
debug_log(FND_FILE.LOG,'8�ŏI�f�[�^�m�菈��');
--
          -- �L�[�u���C�N������
          lproc_keybrake_process(
                ov_errbuf     => lv_errbuf
              , ov_retcode    => lv_retcode
              , ov_errmsg     => lv_errmsg
          );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          -- ���[�v�J�E���g���Z�b�g
          ln_loop_cnt := 0;
--
          IF (lv_mixed_flag IS NOT NULL) THEN
            -- ���ڃe�[�u���o�^�p�f�[�^�ݒ菈��
            set_ins_data(
                  ov_errbuf     => lv_errbuf
                , ov_retcode    => lv_retcode
                , ov_errmsg     => lv_errmsg
            );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--
debug_log(FND_FILE.LOG,'ln_tab_ins_idx:'||ln_tab_ins_idx);
--debug_log(FND_FILE.LOG,'gt_fixed_ship_code_tab:'||gt_fixed_ship_code_tab(ln_tab_ins_idx));
--
            -- ���[�v�J�E���g���Z�b�g
            ln_loop_cnt := 0;
debug_log(FND_FILE.LOG,'6-1-1���[�v�J�E���g���Z�b�g:'||ln_loop_cnt);
            -- �O���[�v�J�E���^���Z�b�g(�ŏ��̓Ǎ����R�[�h������R�[�h�ɂ���)
            ln_grp_sum_cnt := 0;
debug_log(FND_FILE.LOG,'6-1-2 �O���[�v�J�E���g���Z�b�g:'||ln_grp_sum_cnt);
            -- ���ڍσt���O���Z�b�g
            lv_mixed_flag := NULL;
          END IF;
--
          -- =======================
          -- �I������
          -- =======================
          -- �I������J�E���g������
          ln_finish_judge_cnt := 0;
--
debug_log(FND_FILE.LOG,'7�I������');
debug_log(FND_FILE.LOG,'7-0 lt_intensive_tab.COUNT:'|| lt_intensive_tab.COUNT);
--
          <<finish_judge_loop>>
          FOR judge_rec IN 1..lt_intensive_tab.COUNT LOOP
--
debug_log(FND_FILE.LOG,'7-1-0 finish_sum_flag:'|| lt_intensive_tab(judge_rec).finish_sum_flag);
            IF (lt_intensive_tab(judge_rec).finish_sum_flag IS NULL) THEN
debug_log(FND_FILE.LOG,'7-1-1 �I��');
--
              -- �I������J�E���g
              ln_finish_judge_cnt := ln_finish_judge_cnt + 1;
--
            END IF;
--
          END LOOP finish_judge_loop;
--
          -- �I��
          EXIT WHEN ln_finish_judge_cnt = 0;
--
        END IF;
debug_log(FND_FILE.LOG,'�E�I������J�E���g:'|| ln_finish_judge_cnt);
--
      END LOOP  optimization_loop;
--
    END IF;
--
    -- ==============================
    -- B-13.���ڒ��ԃe�[�u���o�͏���
    -- ==============================
-- 2008/10/01 H.Itou Del Start PT 6-1_27 �w�E18
-- ��debug
--    debug_log(FND_FILE.LOG,'gt_intensive_no_tab.COUNT:'|| gt_intensive_no_tab.COUNT);
--    debug_log(FND_FILE.LOG,'���ڒ��ԃe�[�u���o�^�p�f�[�^');
--  for ln_cnt in 1..gt_intensive_no_tab.COUNT LOOP
--    debug_cnt := debug_cnt + 1;
--    debug_log(FND_FILE.LOG,'----------------------------------');
--    debug_log(FND_FILE.LOG,'���W��No:'||gt_intensive_no_tab(ln_cnt));
--    debug_log(FND_FILE.LOG,'���z��No:'||gt_delivery_no_tab(ln_cnt));
--    debug_log(FND_FILE.LOG,'�������No:'||gt_default_line_number_tab(ln_cnt));
--    debug_log(FND_FILE.LOG,'���C���z���敪: '||gt_fixed_ship_code_tab(ln_cnt));
--    debug_log(FND_FILE.LOG,'�����ڎ��:'||gt_mixed_class_tab(ln_cnt) );
--    debug_log(FND_FILE.LOG,'�����ڍ��v�d��:'||gt_mixed_total_weight_tab(ln_cnt));
--    debug_log(FND_FILE.LOG,'�����ڍ��v�e��:'||gt_mixed_total_capacity_tab(ln_cnt));
--    debug_log(FND_FILE.LOG,'�����ڌ�No:'||gt_mixed_no_tab(ln_cnt));
----
--  end loop;
---- ��debug
-- 2008/10/01 H.Itou Del End
    FORALL ln_cnt IN 1..gt_intensive_no_tab.COUNT
      INSERT INTO xxwsh_mixed_carriers_tmp(
          intensive_no                  -- �W��No
        , delivery_no                   -- �z��No
        , default_line_number           -- �����No
        , fixed_shipping_method_code    -- �C���z���敪
        , mixed_class                   -- ���ڎ��
        , mixed_total_weight            -- ���ڍ��v�d��
        , mixed_total_capacity          -- ���ڍ��v�e��
        , mixed_no                      -- ���ڌ�No
      )
       VALUES
      (
          gt_intensive_no_tab(ln_cnt)         -- �W��No
        , gt_delivery_no_tab(ln_cnt)          -- �z��No
        , gt_default_line_number_tab(ln_cnt)  -- �����No
        , gt_fixed_ship_code_tab(ln_cnt)      -- �C���z���敪
        , gt_mixed_class_tab(ln_cnt)          -- ���ڎ��
        , gt_mixed_total_weight_tab(ln_cnt)   -- ���ڍ��v�d��
        , gt_mixed_total_capacity_tab(ln_cnt) -- ���ڍ��v�e��
        , gt_mixed_no_tab(ln_cnt)             -- ���ڌ�No
      );
--
-- Ver1.5 M.Hokkanji Start
debug_log(FND_FILE.LOG,'�����z�����쐬�����O�ɃR�~�b�g');
    COMMIT;
-- Ver1.5 M.Hokkanji End
debug_log(FND_FILE.LOG,'�����z�����쐬����');
--
--2008/10/16 H.Itou Del Start T_S_625 �����̔z��No���Ō�ɍ̔Ԃ��Ȃ����߂ɁAset_ins_data�ֈړ�
--    -- ==============================
--    -- �����z�����쐬����
--    -- ==============================
--    set_small_sam_class(
--           ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
--         , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
--         , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--        );
--    -- �������G���[�̏ꍇ
--    IF (lv_retcode = gv_status_error) THEN
--      RAISE global_api_expt;
--    END IF;
--2008/10/16 H.Itou Del End
--
-- Ver1.5 M.Hokkanji Start
-- �z��No�ݒ�ȍ~�̓��[���o�b�N���邽�߃G���[�����ł���悤�����ŃR�~�b�g
debug_log(FND_FILE.LOG,'�z��No�ݒ�Ŋ����z�Ԃ��폜���Ă��邽�߂����ŃR�~�b�g����');
    COMMIT;
-- Ver1.5 M.Hokkanji End
debug_log(FND_FILE.LOG,'�z��No�ݒ�(�U�蒼��)');
    -- ==================================
    --  �z��No�ݒ�(�U�蒼��)
    -- ==================================
    set_delivery_no(
           ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
         , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
         , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
    -- �������G���[�̏ꍇ
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
  END get_intensive_tmp;
--
  /**********************************************************************************
   * Procedure Name   : ins_xxwsh_carriers_schedule
   * Description      : �z�Ԕz���v��A�h�I���o��(B-14)
   ***********************************************************************************/
  PROCEDURE ins_xxwsh_carriers_schedule(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_xxwsh_carriers_schedule'; -- �v���O������
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
    cv_object                   CONSTANT VARCHAR2(2) := '1';  -- �Ώۋ敪�F�Ώ�
    cn_sts_error                CONSTANT NUMBER := 1;         -- ���ʊ֐��G���[
-- Ver1.5 M.Hokkanji Start
    cv_non_slip_class           CONSTANT VARCHAR2(2) := '1';  -- �`�[�����z�ԋ敪
-- Ver1.5 M.Hokkanji End
--
-- 20080603 K.Yamane �s�No4->
    -- *** ���[�J���ϐ� ***
    TYPE lb_over_loading_ttype IS TABLE OF BOOLEAN INDEX BY BINARY_INTEGER;
-- 20080603 K.Yamane �s�No4<-
--
    -- �z�Ԕz���v��A�h�I���o�^�pPL/SQL�\
    lt_tran_type_tab            transaction_type_ttype;       -- �������
    lt_mixed_cls_tab            mixed_class_ttype;            -- ���ڎ��
    lt_delivery_no_tab          delivery_no_ttype;            -- �z��No
    lt_default_line_number_tab  default_line_number_ttype;    -- �����
    lt_carrier_id_tab           carrier_id_ttype;             -- �^���Ǝ�ID
    lt_carry_cd_tab             freight_carry_cd_ttype;       -- �^���Ǝ҃R�[�h
    lt_deliver_from_id_tab      deliver_from_id_ttype;        -- �z����ID
    lt_deliver_from_tab         deliver_from_ttype;           -- �z�����R�[�h
    lt_deliver_to_id_tab        deliver_to_id_ttype;          -- �z����ID
    lt_deliver_to_tab           deliver_to_ttype;             -- �z����R�[�h
    lt_delivery_to_cd_cls_tab   delivery_to_cd_cls_ttype;     -- �z����R�[�h�敪
    lt_fixed_ship_code_tab      fixed_ship_code_ttype;        -- �C���z���敪
    lt_tran_type_name_tab       tran_type_name_ttype;         -- �o�Ɍ`��
    lt_sche_ship_date_tab       sche_ship_date_ttype;         -- �o�ɗ\���
    lt_sche_arvl_date_tab       sche_arvl_date_ttype;         -- ���ח\���
    lt_mixed_total_weight_tab   mixed_total_weight_ttype;     -- ���ڍ��v�d��
    lt_mixed_total_capacity_tab mixed_total_capacity_ttype;   -- ���ڍ��v�e��
    lt_loading_weight_tab       loading_weight_ttype;         -- �d�ʐύڌ���
    lt_loading_capacity_tab     loading_capacity_ttype;       -- �e�ϐύڌ���
    lt_based_weight_tab         based_weight_ttype;           -- ��{�d��
    lt_based_capacity_tab       based_capacity_ttype;         -- ��{�e��
    lt_weight_capa_cls_tab      weight_capa_cls_ttype;        -- �d�ʗe�ϋ敪
    lt_freight_charge_type_tab  freight_charge_type_ttype;    -- �^���`��
--
-- 20080603 K.Yamane �s�No4->
    lt_tran_type_tab2            transaction_type_ttype;       -- �������
    lt_mixed_cls_tab2            mixed_class_ttype;            -- ���ڎ��
    lt_delivery_no_tab2          delivery_no_ttype;            -- �z��No
    lt_default_line_number_tab2  default_line_number_ttype;    -- �����
    lt_carrier_id_tab2           carrier_id_ttype;             -- �^���Ǝ�ID
    lt_carry_cd_tab2             freight_carry_cd_ttype;       -- �^���Ǝ҃R�[�h
    lt_deliver_from_id_tab2      deliver_from_id_ttype;        -- �z����ID
    lt_deliver_from_tab2         deliver_from_ttype;           -- �z�����R�[�h
    lt_deliver_to_id_tab2        deliver_to_id_ttype;          -- �z����ID
    lt_deliver_to_tab2           deliver_to_ttype;             -- �z����R�[�h
    lt_delivery_to_cd_cls_tab2   delivery_to_cd_cls_ttype;     -- �z����R�[�h�敪
    lt_fixed_ship_code_tab2      fixed_ship_code_ttype;        -- �C���z���敪
    lt_tran_type_name_tab2       tran_type_name_ttype;         -- �o�Ɍ`��
    lt_sche_ship_date_tab2       sche_ship_date_ttype;         -- �o�ɗ\���
    lt_sche_arvl_date_tab2       sche_arvl_date_ttype;         -- ���ח\���
    lt_mixed_total_weight_tab2   mixed_total_weight_ttype;     -- ���ڍ��v�d��
    lt_mixed_total_capacity_tab2 mixed_total_capacity_ttype;   -- ���ڍ��v�e��
    lt_loading_weight_tab2       loading_weight_ttype;         -- �d�ʐύڌ���
    lt_loading_capacity_tab2     loading_capacity_ttype;       -- �e�ϐύڌ���
    lt_based_weight_tab2         based_weight_ttype;           -- ��{�d��
    lt_based_capacity_tab2       based_capacity_ttype;         -- ��{�e��
    lt_weight_capa_cls_tab2      weight_capa_cls_ttype;        -- �d�ʗe�ϋ敪
    lt_freight_charge_type_tab2  freight_charge_type_ttype;    -- �^���`��
--
    lt_over_loading_tab         lb_over_loading_ttype;
-- 20080603 K.Yamane �s�No4<-
--
    ln_cnt                      NUMBER DEFAULT 0;             -- ���[�v�J�E���^
--
    lv_cdkbn_1                  xxcmn_delivery_lt2_v.code_class1%TYPE;
                                                              -- �R�[�h�敪�P
    lv_cdkbn_2                  xxcmn_delivery_lt2_v.code_class2%TYPE;
                                                              -- �R�[�h�敪�Q
    lt_tran_type                xxwsh_intensive_carriers_tmp.transaction_type%TYPE;
                                                              -- �������(����חp)
    ln_retnum                   NUMBER;                       -- ���ʊ֐��߂�l
    lv_warning_msg              VARCHAR2(255);                -- �x�����b�Z�[�W
    ln_drink_deadweight         xxcmn_ship_methods.drink_deadweight%TYPE;
                                                              -- �h�����N�ύڏd��
    ln_leaf_deadweight          xxcmn_ship_methods.leaf_deadweight%TYPE;
                                                              -- ���[�t�ύڏd��
    ln_drink_loading_capacity   xxcmn_ship_methods.drink_loading_capacity%TYPE;
                                                              -- �h�����N�ύڗe��
    ln_leaf_loading_capacity    xxcmn_ship_methods.leaf_loading_capacity%TYPE;
                                                              -- ���[�t�ύڗe��
    ln_palette_max_qty          xxcmn_ship_methods.palette_max_qty%TYPE;
                                                              -- �p���b�g�ő喇��
    lv_transfer_standard_drink  xxcmn_cust_accounts2_v.drink_transfer_std%TYPE;
                                                              -- �h�����N�^���U�֊
    lv_transfer_standard_leaf   xxcmn_cust_accounts2_v.leaf_transfer_std%TYPE;
                                                              -- ���[�t�^���U�֊
    lv_party_number             xxcmn_cust_accounts2_v.party_number%TYPE;
                                                              -- �g�D�ԍ�
    lv_delivery_no              xxwsh_mixed_carriers_tmp.delivery_no%TYPE;
                                                              -- �z��No
    lv_default_line_number      xxwsh_mixed_carriers_tmp.default_line_number%TYPE;
                                                              -- �����No
--
    lv_class_code               xxcmn_cust_accounts_v.customer_class_code%TYPE;
--
    -- ���ʊ֐��߂�l�p
    lv_loading_over_class       VARCHAR2(2);                          -- �ύڃI�[�o�[�敪
    lv_ship_methods             xxcmn_ship_methods.ship_method%TYPE;  -- �o�ו��@
    ln_load_efficiency_weight   NUMBER;                               -- �d�ʐύڌ���
    ln_load_efficiency_capacity NUMBER;                               -- �e�ϐύڌ���
    lv_mixed_ship_method        VARCHAR2(2);                          -- ���ڔz���敪
--
    -- WHO�J����
    lt_user_id          xxcmn_txn_lot_cost.created_by%TYPE;             -- �쐬�ҁA�ŏI�X�V��
    lt_login_id         xxcmn_txn_lot_cost.last_update_login%TYPE;      -- �ŏI�X�V���O�C��
    lt_conc_request_id  xxcmn_txn_lot_cost.request_id%TYPE;             -- �v��ID
    lt_prog_appl_id     xxcmn_txn_lot_cost.program_application_id%TYPE; -- �A�v���P�[�V����ID
    lt_conc_program_id  xxcmn_txn_lot_cost.program_id%TYPE;             -- �v���O����ID
--
    -- *** ���[�J���E�J�[�\�� ***
--
    CURSOR get_put_data_cur IS
      SELECT  mixed.transaction_type            tran_type             -- �������
           ,  mixed.mixed_class                 mixed_class           -- ���ڎ��
           ,  mixed.delivery_no                 delivery_no           -- �z��No
           ,  mixed.default_line_number         default_line_number   -- �����No
           ,  mixed.carrier_id                  carrier_id            -- �^���Ǝ�ID
           ,  mixed.freight_carrier_code        freight_carrier_code  -- �^���Ǝ�
           ,  mixed.deliver_from                deliver_from          -- �z����
           ,  mixed.deliver_to                  deliver_to            -- �z����
-- 20080603 K.Yamane �s�No12->
           ,  mixed.deliver_to_id               deliver_to_id         -- �z����ID
-- 20080603 K.Yamane �s�No12<-
           ,  mixed.fixed_shipping_method_code  fix_ship_method_cls   -- �C���z���敪
--2008.06.26 D.Sugahara ST#297�Ή�->                               
           ,  mixed.std_ship_method             std_ship_method       -- �ʏ�z���敪           
--2008.06.26 D.Sugahara ST#297�Ή�<-                               
           ,  mixed.schedule_ship_date          ship_date             -- �o�ɓ�
           ,  mixed.schedule_arrival_date       arrival_date          -- ���ד�
           ,  mixed.transaction_type_name       tran_type_name        -- �o�Ɍ`��
           ,  SUM(mixed.mixed_total_weight)     mix_total_weight      -- ���ڍ��v�d��
           ,  SUM(mixed.mixed_total_capacity)   mix_total_capacity    -- ���ڍ��v�e��
           ,  mixed.weight_capacity_class       m_c_class             -- �d�ʗe�ϋ敪
-- Ver1.5 M.Hokkanji Start
--           ,  mixed.max_weight                  max_weight            -- �ő�ύڏd��
--           ,  mixed.max_capacity                max_capacity          -- �ő�ύڗe��
-- Ver1.5 M.Hokkanji End
        FROM (SELECT  DISTINCT xict.transaction_type  -- �������
                    , xmct.mixed_class                -- ���ڎ��
                    , xmct.delivery_no                -- �z��No
                    , xmct.default_line_number        -- �����No
                    , xict.carrier_id                 -- �^���Ǝ�ID
                    , xict.freight_carrier_code       -- �^���Ǝ�
--2008.05.26 D.Sugahara �s�No9�Ή�->
--                    , xict.deliver_from               -- �z����
--                    , xict.deliver_to                 -- �z����
                    , xcst.deliver_from               -- �z����
                    , xcst.deliver_to                 -- �z����
--2008.05.26 D.Sugahara �s�No9�Ή�<-
-- 20080603 K.Yamane �s�No12->
                    , xcst.deliver_to_id              -- �z����ID
-- 20080603 K.Yamane �s�No12<-
                    , xmct.fixed_shipping_method_code -- �C���z���敪
--2008.06.26 D.Sugahara ST#297�Ή�->                    
                    ,nvl(xcmv.ship_method_code,xmct.fixed_shipping_method_code) std_ship_method
--2008.06.26 D.Sugahara ST#297�Ή�<-                    
                    , xict.schedule_ship_date         -- �o�ɓ�
                    , xict.schedule_arrival_date      -- ���ד�
                    , xict.transaction_type_name      -- �o�Ɍ`��
                    , xmct.mixed_total_weight         -- ���ڍ��v�d��
                    , xmct.mixed_total_capacity       -- ���ڍ��v�e��
                    , xict.weight_capacity_class      -- �d�ʗe�ϋ敪
-- Ver1.5 M.Hokkanji Start
--                    , xict.max_weight                 -- �ő�ύڏd��
--                    , xict.max_capacity               -- �ő�ύڗe��
-- Ver1.5 M.Hokkanji End
               FROM xxwsh_intensive_carriers_tmp xict       -- �����z�ԏW�񒆊ԃe�[�u��
--2008.05.26 D.Sugahara �s�No9�Ή�->
                  , xxwsh_mixed_carriers_tmp     xmct       -- �����z�ԍ��ڒ��ԃe�[�u��
                  , xxwsh_carriers_sort_tmp      xcst       -- �����z�ԃ\�[�g�p���ԃe�[�u��
--2008.06.26 D.Sugahara ST#297�Ή�->
                  ,xxwsh_ship_method_v           xcmv       -- �z���敪�r���[�i�ʏ�z���敪�p�j
--2008.06.26 D.Sugahara ST#297�Ή�<-
--              WHERE xmct.default_line_number = xict.intensive_source_no   -- �����
--                AND xmct.intensive_no = xict.intensive_no   -- �W��No
              WHERE xmct.intensive_no = xict.intensive_no   -- �W��No 
                AND xcst.request_no   = xmct.default_line_number --����׏���
                AND xcmv.mixed_ship_method_code(+) = xmct.fixed_shipping_method_code 
--2008.05.26 D.Sugahara �s�No9�Ή�<-
            ) mixed
         GROUP BY
              mixed.transaction_type            -- �������
            , mixed.mixed_class                 -- ���ڎ��
            , mixed.delivery_no                 -- �z��No
            , mixed.default_line_number         -- �����No
            , mixed.carrier_id                  -- �^���Ǝ�ID
            , mixed.deliver_from                -- �z����
            , mixed.deliver_to                  -- �z����
            , mixed.deliver_to_id               -- �z����ID
            , mixed.freight_carrier_code        -- �^���Ǝ�
            , mixed.fixed_shipping_method_code  -- �C���z���敪
--2008.06.26 D.Sugahara ST#297�Ή�->                                
            , mixed.std_ship_method             -- �ʏ�z���敪
--2008.06.26 D.Sugahara ST#297�Ή�<-            
            , mixed.schedule_ship_date          -- �o�ɓ�
            , mixed.schedule_arrival_date       -- ���ד�
            , mixed.transaction_type_name       -- �o�Ɍ`��
            , mixed.weight_capacity_class       -- �d�ʗe�ϋ敪
-- Ver1.5 M.Hokkanji Start
--            , mixed.max_weight                  -- �ő�ύڏd��
--            , mixed.max_capacity                -- �ő�ύڗe��
-- Ver1.5 M.Hokkanji End
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
    -- �o�^�pPL/SQL�\������
    lt_tran_type_tab.DELETE;            -- �������
    lt_mixed_cls_tab.DELETE;            -- ���ڎ��
    lt_delivery_no_tab.DELETE;          -- �z��No
    lt_default_line_number_tab.DELETE;  -- �����
    lt_carrier_id_tab.DELETE;           -- �^���Ǝ�ID
    lt_carry_cd_tab.DELETE;             -- �^���Ǝ҃R�[�h
--    lt_deliver_from_id_tab.DELETE;      -- �z����ID
--    lt_deliver_from_tab.DELETE;         -- �z�����R�[�h
--    lt_deliver_to_id_tab.DELETE;        -- �z����ID
--    lt_deliver_to_tab.DELETE;           -- �z����R�[�h
    lt_delivery_to_cd_cls_tab.DELETE;   -- �z����R�[�h�敪
    lt_tran_type_name_tab.DELETE;       -- �o�Ɍ`��
    lt_fixed_ship_code_tab.DELETE;      -- �C���z���敪
    lt_sche_ship_date_tab.DELETE;       -- �o�ɗ\���
    lt_sche_arvl_date_tab.DELETE;       -- ���ח\���
    lt_mixed_total_weight_tab.DELETE;   -- ���ڍ��v�d��
    lt_mixed_total_capacity_tab.DELETE; -- ���ڍ��v�e��
    lt_loading_weight_tab.DELETE;       -- �d�ʐύڌ���
    lt_loading_capacity_tab.DELETE;     -- �e�ϐύڌ���
    lt_based_weight_tab.DELETE;         -- ��{�d��
    lt_based_capacity_tab.DELETE;       -- ��{�e��
    lt_weight_capa_cls_tab.DELETE;      -- �d�ʗe�ϋ敪
--
    -- ===========================
    -- �o�^�p�f�[�^�ݒ�
    -- ===========================
--
debug_log(FND_FILE.LOG,'�y�z�Ԕz���v��A�h�I���o�́z');
--
    <<put_date_loop>>
    FOR cur_rec IN get_put_data_cur LOOP
      -- ���[�v�J�E���^
      ln_cnt  := ln_cnt + 1;
--
      lt_tran_type_tab(ln_cnt)            := cur_rec.tran_type;             -- �������
      lt_mixed_cls_tab(ln_cnt)            := cur_rec.mixed_class;           -- ���ڎ��
      lt_delivery_no_tab(ln_cnt)          := cur_rec.delivery_no;           -- �z��No
      lt_default_line_number_tab(ln_cnt)  := cur_rec.default_line_number;   -- �����No
      lt_carrier_id_tab(ln_cnt)           := cur_rec.carrier_id;            -- �^���Ǝ�ID
      lt_carry_cd_tab(ln_cnt)             := cur_rec.freight_carrier_code;  -- �^���Ǝ҃R�[�h
--      lt_deliver_from_id_tab(ln_cnt)      := cur_rec.deliver_from_id;       -- �z����ID
--      lt_deliver_from_tab(ln_cnt)         := cur_rec.deliver_from;          -- �z�����R�[�h
--      lt_deliver_to_id_tab(ln_cnt)        := cur_rec.deliver_to_id;         -- �z����ID
--      lt_deliver_to_tab(ln_cnt)           := cur_rec.deliver_to;            -- �z����R�[�h
      lt_fixed_ship_code_tab(ln_cnt)      := cur_rec.fix_ship_method_cls;   -- �C���z���敪
      lt_sche_ship_date_tab(ln_cnt)       := cur_rec.ship_date;             -- �o�ɗ\���
      lt_sche_arvl_date_tab(ln_cnt)       := cur_rec.arrival_date;          -- ���ח\���
--
-- 20080603 K.Yamane �s�No4->
      lt_over_loading_tab(ln_cnt)         := TRUE;
-- 20080603 K.Yamane �s�No4<-
--
debug_log(FND_FILE.LOG,'1��{�d�ʁA��{�e�ς��擾');
--
      -- �R�[�h�敪�P�A�Q�̐ݒ�
      IF (cur_rec.mixed_class = gv_mixed_class_int) THEN      -- �W��
--
debug_log(FND_FILE.LOG,'1-1�W��');
--
        IF (cur_rec.tran_type = gv_ship_type_ship) THEN
--
debug_log(FND_FILE.LOG,'1-1-1������ʁF�o��');
--
          lv_cdkbn_2  :=  gv_cdkbn_ship_to; -- �z����
        ELSIF (cur_rec.tran_type = gv_ship_type_move) THEN
--
debug_log(FND_FILE.LOG,'1-1-2������ʁF�ړ�');
--
          lv_cdkbn_2  :=  gv_cdkbn_storage; -- �q��
        END IF;
      ELSIF (cur_rec.mixed_class = gv_mixed_class_mixed) THEN -- ����
--
debug_log(FND_FILE.LOG,'1-2����');
--debug_log(FND_FILE.LOG,'�˗�No/�ړ�No:'lt_default_line_number_tab(ln_cnt));
--
debug_log(FND_FILE.LOG,'����ׂ̏�����ʂ��擾:'||lt_tran_type);
--
debug_log(FND_FILE.LOG,'1-2-1�R�[�h�敪1,2�ݒ�:'||lt_tran_type);
        -- �R�[�h�敪�P�A�Q�̐ݒ�
        IF (cur_rec.tran_type = gv_ship_type_ship) THEN -- �o�׈˗�
--
debug_log(FND_FILE.LOG,'1-2-1-1������ʁF�o��');
--
          lv_cdkbn_2  :=  gv_cdkbn_ship_to; -- �z����
        ELSE
--
debug_log(FND_FILE.LOG,'1-2-1-2������ʁF�ړ�');
--
          lv_cdkbn_2  :=  gv_cdkbn_storage; -- �q��
        END IF;
--
      END IF;
debug_log(FND_FILE.LOG,'2�z����R�[�h�敪�A�o�Ɍ`�Ԑݒ�');
      -- �z����R�[�h�敪�A�o�Ɍ`�Ԑݒ�
      IF (cur_rec.mixed_class = gv_mixed_class_int) THEN -- ���ڎ�ʁF�W��
debug_log(FND_FILE.LOG,'2-1���ڎ�ʁF�W��');
--
        -- �z����R�[�h
        IF (cur_rec.tran_type = gv_ship_type_ship) THEN   -- ������ʁF�o�׈˗�
--
debug_log(FND_FILE.LOG,'2-1-1������ʁF�o�׈˗�');
          lt_delivery_to_cd_cls_tab(ln_cnt) := gv_cdkbn_ship_to;  -- �z����
--
        ELSE
--
debug_log(FND_FILE.LOG,'2-1-2������ʁF�ړ��w��');
          lt_delivery_to_cd_cls_tab(ln_cnt) := gv_cdkbn_storage;  -- �q��
--
        END IF;
debug_log(FND_FILE.LOG,'2-1-3�o�Ɍ`��');
        -- �o�Ɍ`��
        lt_tran_type_name_tab(ln_cnt) := cur_rec.tran_type_name;
--
      ELSE  -- ���ڎ�ʁF����
--
debug_log(FND_FILE.LOG,'2-2���ڎ�ʁF����');
--
        -- �z����R�[�h
        lt_delivery_to_cd_cls_tab(ln_cnt) := NULL;
--
        -- �o�Ɍ`��
        lt_tran_type_name_tab(ln_cnt) := NULL;
--
      END IF;
-- 20080603 K.Yamane �s�No12->
debug_log(FND_FILE.LOG,'�E�z����ID:'|| cur_rec.deliver_to_id);
      -- �z����R�[�h�̎擾
      BEGIN
        SELECT xcav.customer_class_code            -- �ڋq�敪
        INTO   lv_class_code
        FROM   xxcmn_cust_acct_sites_v xcsv        -- �ڋq�T�C�g���r���[
              ,xxcmn_cust_accounts_v   xcav        -- �ڋq���r���[
        WHERE xcsv.party_id      = xcav.party_id
        AND   xcsv.party_site_id = cur_rec.deliver_to_id;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_class_code := NULL;
--
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      lt_delivery_to_cd_cls_tab(ln_cnt) := lv_class_code;
-- 20080603 K.Yamane �s�No12<-
--
debug_log(FND_FILE.LOG,'3��{�d�ʁA��{�e�ς��擾');
-- 20080603 K.Yamane �s�No13->
--      lt_delivery_to_cd_cls_tab(ln_cnt)   := lv_cdkbn_2;    -- �z����R�[�h�敪
-- 20080603 K.Yamane �s�No13<-
--
debug_log(FND_FILE.LOG,'3-1 ��{�d�ʁA��{�e�ς��擾');
debug_log(FND_FILE.LOG,'�E�R�[�h�敪�P:'|| gv_cdkbn_storage);
debug_log(FND_FILE.LOG,'�E���o�ɏꏊ�R�[�h:'|| cur_rec.deliver_from);
debug_log(FND_FILE.LOG,'�E�R�[�h�敪�Q:'|| lv_cdkbn_2);
debug_log(FND_FILE.LOG,'�E���o�ɏꏊ�R�[�h�Q:'|| cur_rec.deliver_to);
debug_log(FND_FILE.LOG,'�E���:'||to_char(cur_rec.ship_date,'YYYY/MM/DD'));
debug_log(FND_FILE.LOG,'�E�C���z���敪:'||cur_rec.fix_ship_method_cls);
debug_log(FND_FILE.LOG,'�E�ʏ�z���敪:'||cur_rec.std_ship_method);
--
      -- ��{�d�ʁA��{�e�ς��擾
      ln_retnum :=  xxwsh_common_pkg.get_max_pallet_qty(    -- ���ʊ֐��F�ő�p���b�g�����Z�o�֐�
                        iv_code_class1
                                => gv_cdkbn_storage             -- �R�[�h�敪�P
                      , iv_entering_despatching_code1
                                => cur_rec.deliver_from         -- ���o�ɏꏊ�R�[�h�P
                      , iv_code_class2
                                => lv_cdkbn_2                   -- �R�[�h�敪�Q
                      , iv_entering_despatching_code2
                                => cur_rec.deliver_to           -- ���o�ɏꏊ�R�[�h�Q
                      , id_standard_date
                                => cur_rec.ship_date            -- ���
                      , iv_ship_methods
--2008.06.26 D.Sugahara ST#297�Ή�->                                          
--                                => cur_rec.fix_ship_method_cls  -- �C���z���敪
                                => cur_rec.std_ship_method      -- �ʏ�z���敪                                
--2008.06.26 D.Sugahara ST#297�Ή�<-                                
                      , on_drink_deadweight
                                => ln_drink_deadweight          -- �h�����N�ύڏd��
                      , on_leaf_deadweight
                                => ln_leaf_deadweight           -- ���[�t�ύڏd��
                      , on_drink_loading_capacity
                                => ln_drink_loading_capacity    -- �h�����N�ύڗe��
                      , on_leaf_loading_capacity
                                => ln_leaf_loading_capacity     -- ���[�t�ύڗe��
                      , on_palette_max_qty
                                => ln_palette_max_qty           -- �p���b�g�ő喇��
                   );
debug_log(FND_FILE.LOG,'3-2 ���ʊ֐����{');
debug_log(FND_FILE.LOG,'�E���^�[���R�[�h:'|| ln_retnum);
debug_log(FND_FILE.LOG,'�E�h�����N�ύڏd��:'|| ln_drink_deadweight);
debug_log(FND_FILE.LOG,'�E���[�t�ύڏd��:'|| ln_leaf_deadweight);
debug_log(FND_FILE.LOG,'�E�h�����N�ύڗe��:'|| ln_leaf_loading_capacity);
debug_log(FND_FILE.LOG,'�E���[�t�ύڗe��:'|| ln_leaf_loading_capacity);
debug_log(FND_FILE.LOG,'�E�p���b�g�ő喇��:'|| ln_palette_max_qty);
      -- ���ʊ֐��G���[�̏ꍇ
      IF (ln_retnum = cn_sts_error) THEN
        gv_err_key  :=  gv_cdkbn_storage
                        || gv_msg_comma ||
                        cur_rec.deliver_from
                        || gv_msg_comma ||
                        lv_cdkbn_2
                        || gv_msg_comma ||
                        cur_rec.deliver_to
                        || gv_msg_comma ||
                        TO_CHAR(cur_rec.ship_date, 'YYYY/MM/DD')
                        || gv_msg_comma ||
                        cur_rec.fix_ship_method_cls
                        ;
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        gv_xxwsh                -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                      , gv_msg_xxwsh_11810      -- ���b�Z�[�W�FAPP-XXWSH-11810 ���ʊ֐��G���[
                      , gv_fnc_name             -- �g�[�N���FFNC_NAME
                      , 'xxwsh_common_pkg.get_max_pallet_qty' -- �֐���
                      , gv_tkn_key              -- �g�[�N���FKEY
                      , gv_err_key              -- �֐����s�L�[
                      ),1,5000);
        RAISE global_api_expt;
      END IF;
--
debug_log(FND_FILE.LOG,'�h�����N�ύڏd��:'|| ln_drink_deadweight);
debug_log(FND_FILE.LOG,'���[�t�ύڏd��:'|| ln_leaf_deadweight);
debug_log(FND_FILE.LOG,'�h�����N�ύڗe��:'|| ln_leaf_loading_capacity);
debug_log(FND_FILE.LOG,'���[�t�ύڗe��:'|| ln_leaf_loading_capacity);
debug_log(FND_FILE.LOG,'�p���b�g�ő喇��:'|| ln_palette_max_qty);
--
debug_log(FND_FILE.LOG,'3�ύڌ����`�F�b�N');
      -- �d�ʗe�ϋ敪�F�d��
      IF (cur_rec.m_c_class = gv_weight) THEN
debug_log(FND_FILE.LOG,'3-1�d�ʗe�ϋ敪�F�d��');
        -- �d��
        lt_mixed_total_weight_tab(ln_cnt)   := cur_rec.mix_total_weight;      -- ���ڍ��v�d��
        lt_mixed_total_capacity_tab(ln_cnt) := NULL;                          -- ���ڍ��v�e��
debug_log(FND_FILE.LOG,'3-1-2���ڍ��v�d�ʐݒ�');
--
        -- ���ʊ֐��F�ύڌ����`�F�b�N(�ύڌ����Z�o)
        xxwsh_common910_pkg.calc_load_efficiency(
            in_sum_weight                  => cur_rec.mix_total_weight    --  1.���v�d��
          , in_sum_capacity                => NULL                        --  2.���v�e��
          , iv_code_class1                 => gv_cdkbn_storage            --  3.�R�[�h�敪�P
          , iv_entering_despatching_code1  => cur_rec.deliver_from        --  4.���o�ɏꏊ�R�[�h�P
          , iv_code_class2                 => lv_cdkbn_2                  --  5.�R�[�h�敪�Q
          , iv_entering_despatching_code2  => cur_rec.deliver_to          --  6.���o�ɏꏊ�R�[�h�Q
--2008.06.26 D.Sugahara ST#297�Ή�->                                          
--          , iv_ship_method                 => cur_rec.fix_ship_method_cls --  7.�o�ו��@
          , iv_ship_method                 => cur_rec.std_ship_method      -- �ʏ�z���敪                                
--2008.06.26 D.Sugahara ST#297�Ή�<-                                
          , iv_prod_class                  => gv_prod_class               --  8.���i�敪
          , iv_auto_process_type           => NULL                        --  9.�����z�ԑΏۋ敪
          , id_standard_date               => cur_rec.ship_date           -- 10.���(�K�p�����)
          , ov_retcode                     => lv_retcode                  -- 11.���^�[���R�[�h
          , ov_errmsg_code                 => lv_errmsg                   -- 12.�G���[���b�Z�[�W�R�[�h
          , ov_errmsg                      => lv_errbuf                   -- 13.�G���[���b�Z�[�W
          , ov_loading_over_class          => lv_loading_over_class       -- 14.�ύڃI�[�o�[�敪
          , ov_ship_methods                => lv_ship_methods             -- 15.�o�ו��@
          , on_load_efficiency_weight      => ln_load_efficiency_weight   -- 16.�d�ʐύڌ���
          , on_load_efficiency_capacity    => ln_load_efficiency_capacity -- 17.�e�ϐύڌ���
          , ov_mixed_ship_method           => lv_mixed_ship_method        -- 18.���ڔz���敪
        );
        -- ���ʊ֐����G���[�̏ꍇ
-- Ver1.7 M.Hokkanji START
        IF (lv_retcode <> gv_status_normal) THEN
--        IF (lv_retcode = gv_status_error) THEN
-- Ver1.7 M.Hokkanji END
          gv_err_key  :=  cur_rec.mix_total_weight        --  1.���v�d��
                          || gv_msg_comma ||
                          NULL                            --  2.���v�e��
                          || gv_msg_comma ||
                          gv_cdkbn_storage                --  3.�R�[�h�敪�P
                          || gv_msg_comma ||
                          cur_rec.deliver_from            --  4.���o�ɏꏊ�R�[�h�P
                          || gv_msg_comma ||
                          lv_cdkbn_2                      --  5.�R�[�h�敪�Q
                          || gv_msg_comma ||
                          cur_rec.deliver_to              --  6.���o�ɏꏊ�R�[�h�Q
                          || gv_msg_comma ||
                          cur_rec.fix_ship_method_cls     --  7.�o�ו��@
                          || gv_msg_comma ||
                          gv_prod_class                   --  8.���i�敪
                          || gv_msg_comma ||
                          NULL                                      --  9.�����z�ԑΏۋ敪
                          || gv_msg_comma ||
                          TO_CHAR(cur_rec.ship_date, 'YYYY/MM/DD')  -- 10.���(�K�p�����)
                          ;
          -- �G���[���b�Z�[�W�擾
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                        , gv_msg_xxwsh_11810  -- ���b�Z�[�W�FAPP-XXWSH-11810 ���ʊ֐��G���[
                        , gv_fnc_name         -- �g�[�N���FFNC_NAME
                        , 'xxwsh_common910_pkg.calc_load_efficiency' -- �֐���
                        , gv_tkn_key              -- �g�[�N���FKEY
                        , gv_err_key              -- �֐����s�L�[
                        ),1,5000);
          RAISE global_api_expt;
        END IF;
--
debug_log(FND_FILE.LOG,'3-1-3�ύڌ����Z�o');
        -- �d�ʐύڌ����ݒ�
        lt_loading_weight_tab(ln_cnt)       := ln_load_efficiency_weight; -- �d�ʐύڌ���
        lt_loading_capacity_tab(ln_cnt)     := NULL;                      -- �e�ϐύڌ���
debug_log(FND_FILE.LOG,'3-1-4�d�ʐύڌ����ݒ�');
--
debug_log(FND_FILE.LOG,'3-1-5��{�d�ʐݒ�');
        -- ��{�d�ʐݒ�
        IF (gv_prod_class = gv_prod_cls_leaf) THEN
debug_log(FND_FILE.LOG,'3-1-5-1���[�t');
          -- ���i�敪�F���[�t
          lt_based_weight_tab(ln_cnt)       := ln_leaf_deadweight;        -- ���[�t�ύڏd��
          lt_based_capacity_tab(ln_cnt)     := NULL;                      -- ���[�t�ύڗe��
--
        ELSE
debug_log(FND_FILE.LOG,'3-1-5-2�h�����N');
          -- ���i�敪�F�h�����N
          lt_based_weight_tab(ln_cnt)       := ln_drink_deadweight;       -- �h�����N�ύڏd��
          lt_based_capacity_tab(ln_cnt)     := NULL;                      -- �h�����N�ύڗe��
--
        END IF;
--
debug_log(FND_FILE.LOG,'3-2�d�ʗe�ϋ敪�F�e��');
      -- �d�ʗe�ϋ敪�F�e��
      ELSIF (cur_rec.m_c_class = gv_capacity) THEN
debug_log(FND_FILE.LOG,'3-2-1�d�ʗe�ϋ敪�F�e��');
        -- �e��
        lt_mixed_total_weight_tab(ln_cnt)   := NULL;                          -- ���ڍ��v�d��
        lt_mixed_total_capacity_tab(ln_cnt) := cur_rec.mix_total_capacity;    -- ���ڍ��v�e��
debug_log(FND_FILE.LOG,'3-2-2���ڍ��v�e��');
--
        -- ���ʊ֐��F�ύڌ����`�F�b�N(�ύڌ����Z�o)
        xxwsh_common910_pkg.calc_load_efficiency(
            in_sum_weight                  => NULL                        --  1.���v�d��
          , in_sum_capacity                => cur_rec.mix_total_capacity  --  2.���v�e��
          , iv_code_class1                 => gv_cdkbn_storage            --  3.�R�[�h�敪�P
          , iv_entering_despatching_code1  => cur_rec.deliver_from        --  4.���o�ɏꏊ�R�[�h�P
          , iv_code_class2                 => lv_cdkbn_2                  --  5.�R�[�h�敪�Q
          , iv_entering_despatching_code2  => cur_rec.deliver_to          --  6.���o�ɏꏊ�R�[�h�Q
--2008.06.26 D.Sugahara ST#297�Ή�->                                          
--          , iv_ship_method                 => cur_rec.fix_ship_method_cls --  7.�o�ו��@
          , iv_ship_method                 => cur_rec.std_ship_method      -- �ʏ�z���敪                                
--2008.06.26 D.Sugahara ST#297�Ή�<-                                
          , iv_prod_class                  => gv_prod_class               --  8.���i�敪
          , iv_auto_process_type           => NULL                        --  9.�����z�ԑΏۋ敪
          , id_standard_date               => cur_rec.ship_date           -- 10.���(�K�p�����)
          , ov_retcode                     => lv_retcode                  -- 11.���^�[���R�[�h
          , ov_errmsg_code                 => lv_errmsg                   -- 12.�G���[���b�Z�[�W�R�[�h
          , ov_errmsg                      => lv_errbuf                   -- 13.�G���[���b�Z�[�W
          , ov_loading_over_class          => lv_loading_over_class       -- 14.�ύڃI�[�o�[�敪
          , ov_ship_methods                => lv_ship_methods             -- 15.�o�ו��@
          , on_load_efficiency_weight      => ln_load_efficiency_weight   -- 16.�d�ʐύڌ���
          , on_load_efficiency_capacity    => ln_load_efficiency_capacity -- 17.�e�ϐύڌ���
          , ov_mixed_ship_method           => lv_mixed_ship_method        -- 18.���ڔz���敪
        );
        -- ���ʊ֐����G���[�̏ꍇ
-- Ver1.7 M.Hokkanji START
        IF (lv_retcode <> gv_status_normal) THEN
--        IF (lv_retcode = gv_status_error) THEN
-- Ver1.7 M.Hokkanji END
          gv_err_key  :=  NULL                        --  1.���v�d��
                          || gv_msg_comma ||
                          cur_rec.mix_total_capacity  --  2.���v�e��
                          || gv_msg_comma ||
                          gv_cdkbn_storage            --  3.�R�[�h�敪�P
                          || gv_msg_comma ||
                          cur_rec.deliver_from        --  4.���o�ɏꏊ�R�[�h�P
                          || gv_msg_comma ||
                          lv_cdkbn_2                  --  5.�R�[�h�敪�Q
                          || gv_msg_comma ||
                          cur_rec.deliver_to          --  6.���o�ɏꏊ�R�[�h�Q
                          || gv_msg_comma ||
                          cur_rec.fix_ship_method_cls --  7.�o�ו��@
                          || gv_msg_comma ||
                          gv_prod_class               --  8.���i�敪
                          || gv_msg_comma ||
                          NULL                                      --  9.�����z�ԑΏۋ敪
                          || gv_msg_comma ||
                          TO_CHAR(cur_rec.ship_date, 'YYYY/MM/DD')  -- 10.���(�K�p�����)
                          ;
          -- �G���[���b�Z�[�W�擾
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                        , gv_msg_xxwsh_11810  -- ���b�Z�[�W�FAPP-XXWSH-11810 ���ʊ֐��G���[
                        , gv_fnc_name         -- �g�[�N���FFNC_NAME
                        , 'xxwsh_common910_pkg.calc_load_efficiency' -- �֐���
                        , gv_tkn_key              -- �g�[�N���FKEY
                        , gv_err_key              -- �֐����s�L�[
                        ),1,5000);
--
-- 20080603 K.Yamane �s�No4->
          -- �ύڃI�[�o�[�Ώۃt���O�ݒ�
          lt_over_loading_tab(ln_cnt) := FALSE;
-- 20080603 K.Yamane �s�No4<-
        END IF;
--
debug_log(FND_FILE.LOG,'3-2-3�e�ϐύڌ���');
        -- �e�ϐύڌ����ݒ�
        lt_loading_weight_tab(ln_cnt)     := NULL;                        -- �d�ʐύڌ���
        lt_loading_capacity_tab(ln_cnt)   := ln_load_efficiency_capacity; -- �e�ϐύڌ���
--
debug_log(FND_FILE.LOG,'3-2-4��{�d�ʐݒ�');
        -- ��{�d�ʐݒ�
        IF (gv_prod_class = gv_prod_cls_leaf) THEN
debug_log(FND_FILE.LOG,'3-2-4-1���[�t');
--
          -- ���i�敪�F���[�t
          lt_based_weight_tab(ln_cnt)     := NULL;                        -- ���[�t�ύڏd��
          lt_based_capacity_tab(ln_cnt)   := ln_leaf_loading_capacity;    -- ���[�t�ύڗe��
--
        ELSE
debug_log(FND_FILE.LOG,'3-2-4-1�h�����N');
          -- ���i�敪�F�h�����N
          lt_based_weight_tab(ln_cnt)     := NULL;                        -- �h�����N�ύڏd��
          lt_based_capacity_tab(ln_cnt)   := ln_drink_loading_capacity;   -- �h�����N�ύڗe��
--
        END IF;
--
      END IF;
--
debug_log(FND_FILE.LOG,'3-2-5�d�ʗe�ϋ敪');
      lt_weight_capa_cls_tab(ln_cnt)      := cur_rec.m_c_class;           -- �d�ʗe�ϋ敪
--
debug_log(FND_FILE.LOG,'3-2-6�^���`��');
      --�^���`�Ԃ̎擾
      IF (cur_rec.tran_type = gv_ship_type_ship) THEN
debug_log(FND_FILE.LOG,'3-2-6�^���`��:�o��');
--
        BEGIN
          SELECT xca.drink_transfer_std         --�h�����N�^���U�֊
                ,xca.leaf_transfer_std          --���[�t�^���U�֊
                ,xca.party_number               --�g�D�ԍ�
                ,xmct.delivery_no               --�z��No
                ,xmct.default_line_number       --�����No
            INTO lv_transfer_standard_drink     -- �h�����N�^���U�֊
                ,lv_transfer_standard_leaf      -- ���[�t�^���U�֊
                ,lv_party_number                -- �g�D�ԍ�
                ,lv_delivery_no                 -- �z��No
                ,lv_default_line_number         -- �����No
            FROM xxcmn_cust_accounts2_v    xca                  -- �ڋq���VIEW2
               , xxwsh_mixed_carriers_tmp  xmct                 -- �����z�ԍ��ڒ��ԃe�[�u��
               , xxwsh_order_headers_all   xoha                 -- �󒍃w�b�_�A�h�I��
           WHERE xca.party_number = xoha.head_sales_branch
             AND xca.start_date_active <= TRUNC(cur_rec.ship_date)
             AND (xca.end_date_active IS NULL OR
                  xca.end_date_active >= TRUNC(cur_rec.ship_date))
             AND xoha.request_no  = xmct.default_line_number
             AND xmct.delivery_no = cur_rec.delivery_no
             AND xoha.latest_external_flag = 'Y'
             AND xca.party_status   = 'A'
             AND xca.account_status = 'A'
             AND ROWNUM = 1     --���ڒP��<->�W��No�P�ʂł̏d����r��
           ;
        EXCEPTION
          -- �f�[�^�擾���s��
          WHEN OTHERS THEN
debug_log(FND_FILE.LOG,'3-2-6�^���U�֊�擾1 �G���[�FMSG= ['||SQLERRM||']');
debug_log(FND_FILE.LOG,' �z��NO�A�o�ח\���= ['||cur_rec.delivery_no || ',' || cur_rec.ship_date || ']' );
            --�x�����O�o��
            ov_retcode := gv_status_warn;
            lt_freight_charge_type_tab(ln_cnt) := NULL;    --�^���`�Ԃ�NULL�ݒ�
            lv_warning_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_xxwsh                -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                        , gv_msg_xxwsh_11813      -- ���b�Z�[�W�FAPP-XXWSH-11813 �^���`�Ԏ擾�G���[
                        , gv_tkn_delivry_no       -- �g�[�N���F�z��No
                        , lv_delivery_no
                        , gv_tkn_req_no           -- �g�[�N���F�����No
                        , lv_default_line_number
                        , gv_tkn_branch           -- �g�[�N���F�g�D�ԍ�
                        , lv_party_number
                         ),1,255);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_warning_msg);
        END;
--
        IF (gv_prod_class = gv_prod_cls_leaf  AND lv_transfer_standard_leaf IS NULL) OR
           (gv_prod_class = gv_prod_cls_drink AND lv_transfer_standard_drink IS NULL) THEN
            --�^���U�֊���擾�ł��Ȃ������ꍇ�x�����O�o��
debug_log(FND_FILE.LOG,'3-2-6�^���U�֊�擾�G���[2�i����NULL) ');
debug_log(FND_FILE.LOG,' �z��NO�A�o�ח\���:['||cur_rec.delivery_no || ',' || to_char(cur_rec.ship_date,'YYYYMMDD') || ']' );
            ov_retcode := gv_status_warn;
            lt_freight_charge_type_tab(ln_cnt) := NULL;    --�^���`�Ԃ�NULL�ݒ�
            lv_warning_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_xxwsh                -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                        , gv_msg_xxwsh_11813      -- ���b�Z�[�W�FAPP-XXWSH-11813 �^���`�Ԏ擾�G���[
                        , gv_tkn_delivry_no       -- �g�[�N���F�z��No
                        , lv_delivery_no
                        , gv_tkn_req_no           -- �g�[�N���F�����No
                        , lv_default_line_number
                        , gv_tkn_branch           -- �g�[�N���F�g�D�ԍ�
                        , lv_party_number
                         ),1,255);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_warning_msg);
--
        ELSE
          --�^���U�֊�ݒ�
          IF ( gv_prod_class = gv_prod_cls_leaf ) THEN
            --���[�t
            lt_freight_charge_type_tab(ln_cnt) := lv_transfer_standard_leaf;      -- ���[�t�^���U�֊
debug_log(FND_FILE.LOG,'3-2-6 ���[�t�^���U�֊�ݒ聨 '||lv_transfer_standard_leaf);
          ELSE
            --�h�����N
debug_log(FND_FILE.LOG,'3-2-6 �h�����N�^���U�֊�ݒ聨 '||lv_transfer_standard_drink);
            lt_freight_charge_type_tab(ln_cnt) := lv_transfer_standard_drink;     -- �h�����N�^���U�֊
          END IF;
--
        END IF;
      ELSIF (cur_rec.tran_type = gv_ship_type_move) THEN
--
debug_log(FND_FILE.LOG,'3-2-6�^���`�ԁF�ړ�');
        -- �^���`�ԁF�ړ��̏ꍇ�͎���U��
        lt_freight_charge_type_tab(ln_cnt) := gv_frt_chrg_type_act; -- ����U��
      END IF;
--
    END LOOP;
--
debug_log(FND_FILE.LOG,'4�z�Ԕz���v��A�h�I���ꊇ�o�^����');
    -- =================================
    -- �z�Ԕz���v��A�h�I���ꊇ�o�^����
    -- =================================
debug_log(FND_FILE.LOG,'4-1.1WHO�J�����擾');
    -- WHO�J�����擾
    lt_user_id          := FND_GLOBAL.USER_ID;          -- �쐬�ҁA�ŏI�X�V��
    lt_login_id         := FND_GLOBAL.LOGIN_ID;         -- �ŏI�X�V���O�C��
    lt_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;  -- �v��ID
    lt_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;     -- �A�v���P�[�V����ID
    lt_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;  -- �v���O����ID
--
-- 20080603 K.Yamane �s�No4->
    ln_cnt := 1;
debug_log(FND_FILE.LOG,'4-1.2 ����ւ��J�n:'||lt_tran_type_tab.COUNT);
    <<set_date_loop>>
    FOR ins_cnt IN 1..lt_tran_type_tab.COUNT LOOP
      IF (lt_over_loading_tab(ins_cnt)) THEN
        lt_tran_type_tab2(ln_cnt)            := lt_tran_type_tab(ins_cnt);
        lt_mixed_cls_tab2(ln_cnt)            := lt_mixed_cls_tab(ins_cnt);
        lt_delivery_no_tab2(ln_cnt)          := lt_delivery_no_tab(ins_cnt);
        lt_default_line_number_tab2(ln_cnt)  := lt_default_line_number_tab(ins_cnt);
        lt_carrier_id_tab2(ln_cnt)           := lt_carrier_id_tab(ins_cnt);
        lt_carry_cd_tab2(ln_cnt)             := lt_carry_cd_tab(ins_cnt);
        lt_delivery_to_cd_cls_tab2(ln_cnt)   := lt_delivery_to_cd_cls_tab(ins_cnt);
        lt_fixed_ship_code_tab2(ln_cnt)      := lt_fixed_ship_code_tab(ins_cnt);
        lt_tran_type_name_tab2(ln_cnt)       := lt_tran_type_name_tab(ins_cnt);
        lt_sche_ship_date_tab2(ln_cnt)       := lt_sche_ship_date_tab(ins_cnt);
        lt_sche_arvl_date_tab2(ln_cnt)       := lt_sche_arvl_date_tab(ins_cnt);
        lt_mixed_total_weight_tab2(ln_cnt)   := lt_mixed_total_weight_tab(ins_cnt);
        lt_mixed_total_capacity_tab2(ln_cnt) := lt_mixed_total_capacity_tab(ins_cnt);
        lt_loading_weight_tab2(ln_cnt)       := lt_loading_weight_tab(ins_cnt);
        lt_loading_capacity_tab2(ln_cnt)     := lt_loading_capacity_tab(ins_cnt);
        lt_based_weight_tab2(ln_cnt)         := lt_based_weight_tab(ins_cnt);
        lt_based_capacity_tab2(ln_cnt)       := lt_based_capacity_tab(ins_cnt);
        lt_weight_capa_cls_tab2(ln_cnt)      := lt_weight_capa_cls_tab(ins_cnt);
        lt_freight_charge_type_tab2(ln_cnt)  := lt_freight_charge_type_tab(ins_cnt);
        ln_cnt := ln_cnt + 1;
      END IF;
    END LOOP;
debug_log(FND_FILE.LOG,'4-1.2 ����ւ��I��');
-- 20080603 K.Yamane �s�No4<-
--
debug_log(FND_FILE.LOG,'4-2�ꊇ�o�^�����F������'||lt_tran_type_tab2.COUNT);
debug_log(FND_FILE.LOG,'4-2�ꊇ�o�^����');
    FORALL ins_cnt IN 1..lt_tran_type_tab2.COUNT
      INSERT INTO xxwsh_carriers_schedule( -- �z�Ԕz���v��i�A�h�I���j
          transaction_id                -- �g�����U�N�V����ID
        , transaction_type              -- ������ʁi�z�ԁj
        , mixed_type                    -- ���ڎ��
        , delivery_no                   -- �z��No
        , default_line_number           -- �����No
        , carrier_id                    -- �^���Ǝ�ID
        , carrier_code                  -- �^���Ǝ�
        , deliver_from_id               -- �z����ID
        , deliver_from                  -- �z����
        , deliver_to_id                 -- �z����ID
        , deliver_to                    -- �z����
        , deliver_to_code_class         -- �z����R�[�h�敪
        , delivery_type                 -- �z���敪
        , order_type_id                 -- �o�Ɍ`��
        , auto_process_type             -- �����z�ԑΏۋ敪
        , schedule_ship_date            -- �o�ɗ\���
        , schedule_arrival_date         -- ���ח\���
        , description                   -- �E�v
        , payment_freight_flag          -- �x���^���v�Z�Ώۃt���O
        , demand_freight_flag           -- �����^���v�Z�Ώۃt���O
        , sum_loading_weight            -- �ύڏd�ʍ��v
        , sum_loading_capacity          -- �ύڗe�ύ��v
        , loading_efficiency_weight     -- �d�ʐύڌ���
        , loading_efficiency_capacity   -- �e�ϐύڌ���
        , based_weight                  -- ��{�d��
        , based_capacity                -- ��{�e��
        , result_freight_carrier_id     -- �^���Ǝ�_����ID
        , result_freight_carrier_code   -- �^���Ǝ�_����
        , result_shipping_method_code   -- �z���敪_����
        , shipped_date                  -- �o�ד�
        , arrival_date                  -- ���ד�
        , weight_capacity_class         -- �d�ʗe�ϋ敪
        , freight_charge_type           -- �^���`��
-- Ver1.5 M.Hokkanji Start
        , non_slip_class                -- �`�[�Ȃ��z�ԋ敪
        , prod_class                    -- ���i�敪
-- Ver1.5 M.Hokkanji End
        , created_by                    -- �쐬��
        , creation_date                 -- �쐬��
        , last_updated_by               -- �ŏI�X�V��
        , last_update_date              -- �ŏI�X�V��
        , last_update_login             -- �ŏI�X�V���O�C��
        , request_id                    -- �v��ID
        , program_application_id        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                    -- �R���J�����g�E�v���O����ID
        , program_update_date           -- �v���O�����X�V��
      )
      VALUES
      (
          xxwsh_careers_schedule_s1.NEXTVAL     -- �g�����U�N�V����ID
        , lt_tran_type_tab2(ins_cnt)            -- ������ʁi�z�ԁj
        , lt_mixed_cls_tab2(ins_cnt)            -- ���ڎ��
        , lt_delivery_no_tab2(ins_cnt)          -- �z��No
        , lt_default_line_number_tab2(ins_cnt)  -- �����No
        , lt_carrier_id_tab2(ins_cnt)           -- �^���Ǝ�ID
        , lt_carry_cd_tab2(ins_cnt)             -- �^���Ǝ�
        , NULL                                  -- �z����ID
        , NULL                                  -- �z����
        , NULL                                  -- �z����ID
        , NULL                                  -- �z����
        , lt_delivery_to_cd_cls_tab2(ins_cnt)   -- �z����R�[�h�敪
        , lt_fixed_ship_code_tab2(ins_cnt)      -- �z���敪
        , lt_tran_type_name_tab2(ins_cnt)       -- �o�Ɍ`��
        , cv_object                             -- �����z�ԑΏۋ敪
        , lt_sche_ship_date_tab2(ins_cnt)       -- �o�ɗ\���
        , lt_sche_arvl_date_tab2(ins_cnt)       -- ���ח\���
        , NULL                                  -- �E�v
        , cv_object                             -- �x���^���v�Z�Ώۃt���O
        , cv_object                             -- �����^���v�Z�Ώۃt���O
        , lt_mixed_total_weight_tab2(ins_cnt)   -- �ύڏd�ʍ��v
        , lt_mixed_total_capacity_tab2(ins_cnt) -- �ύڗe�ύ��v
        , lt_loading_weight_tab2(ins_cnt)       -- �d�ʐύڌ���
        , lt_loading_capacity_tab2(ins_cnt)     -- �e�ϐύڌ���
        , lt_based_weight_tab2(ins_cnt)         -- ��{�d��
        , lt_based_capacity_tab2(ins_cnt)       -- ��{�e��
        , NULL                                  -- �^���Ǝ�_����ID
        , NULL                                  -- �^���Ǝ�_����
        , NULL                                  -- �z���敪_����
        , NULL                                  -- �o�ד�
        , NULL                                  -- ���ד�
        , lt_weight_capa_cls_tab2(ins_cnt)      -- �d�ʗe�ϋ敪
        , lt_freight_charge_type_tab2(ins_cnt)  -- �^���`��
-- Ver1.5 M.Hokkanji Start
        , cv_non_slip_class                     -- �`�[�Ȃ��z�ԋ敪
        , gv_prod_class                         -- ���i�敪
-- Ver1.5 M.Hokkanji End
        , lt_user_id                            -- �쐬��
        , SYSDATE                               -- �쐬��
        , lt_user_id                            -- �ŏI�X�V��
        , SYSDATE                               -- �ŏI�X�V��
        , lt_login_id                           -- �ŏI�X�V���O�C��
        , lt_conc_request_id                    -- �v��ID
        , lt_prog_appl_id                       -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , lt_conc_program_id                    -- �R���J�����g�E�v���O����ID
        , SYSDATE                               -- �v���O�����X�V��
      );
--
    -- �o�^�����ݒ�
    gn_target_cnt  := lt_tran_type_tab2.COUNT;
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
  END ins_xxwsh_carriers_schedule;
--
  /**********************************************************************************
   * Procedure Name   : upd_req_inst_info
   * Description      : �˗��E�w�����X�V����(B-15)
   ***********************************************************************************/
  PROCEDURE upd_req_inst_info(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_req_inst_info'; -- �v���O������
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
    cv_yes        CONSTANT VARCHAR2(1) := 'Y';         -- YES
-- Ver1.3 M.Hokkanji Start
    cv_an_object      CONSTANT VARCHAR2(1)   := '1';   -- �Ώ�
    cv_table_name     CONSTANT VARCHAR2(100) := '�����z�ԃ\�[�g�p���ԃe�[�u��';
    cv_parameter_name CONSTANT VARCHAR2(100) := '�˗�No/�ړ�No:';
    cv_0              CONSTANT NUMBER        := 0;     -- ���l����p
    cv_loading_over   CONSTANT VARCHAR2(1) := '1';     -- �ύڃI�[�o�[�敪�F�I�[�o�[
    cn_sts_error      CONSTANT NUMBER := 1;            -- ���ʊ֐��G���[
-- Ver1.3 M.Hokkanji End
--
    -- *** ���[�J���ϐ� ***
    lt_upd_req_no_ship_tab        request_no_ttype;   -- �˗�No
    lt_upd_req_no_move_tab        request_no_ttype;   -- �ړ�No
    lt_upd_delibery_no_ship_tab   delivery_no_ttype;  -- �z��No(�o�׈˗�)
    lt_upd_delibery_no_move_tab   delivery_no_ttype;  -- �z��No(�ړ��w��)
    ln_loop_cnt                   NUMBER DEFAULT 0;   -- ���[�v�J�E���g
--20080517 D.Sugahara �s�No2�Ή�
    ln_loop_cnt_ship              NUMBER DEFAULT 0;   -- ���[�v�J�E���g(�o�׈˗��p�j
    ln_loop_cnt_move              NUMBER DEFAULT 0;   -- ���[�v�J�E���g(�ړ��w���p�j
--
-- Ver1.2 M.Hokkanji Start
    lt_upd_method_code_ship_tab   ship_method_code_ttype; -- �z��No
    lt_upd_method_code_move_tab   ship_method_code_ttype; -- �z��No
-- Ver1.2 M.Hokkanji End
-- 20080603 K.Yamane �s�No4->
    ln_cnt                        NUMBER;
-- 20080603 K.Yamane �s�No4<-
--
    -- WHO�J����
    lt_user_id          xxcmn_txn_lot_cost.created_by%TYPE;             -- �쐬�ҁA�ŏI�X�V��
    lt_login_id         xxcmn_txn_lot_cost.last_update_login%TYPE;      -- �ŏI�X�V���O�C��
-- 20080603 K.Yamane �s�No14->
    lt_conc_request_id  xxcmn_txn_lot_cost.request_id%TYPE;             -- �v��ID
    lt_prog_appl_id     xxcmn_txn_lot_cost.program_application_id%TYPE; -- �A�v���P�[�V����ID
    lt_conc_program_id  xxcmn_txn_lot_cost.program_id%TYPE;             -- �v���O����ID
-- 20080603 K.Yamane �s�No14<-
-- Ver1.3 M.Hokkanji Start
    -- �w�b�_�o�^�p
    lt_ship_based_weight        based_weight_ttype;                                  -- ��{�d��(�o��)
    lt_ship_based_capacity      based_capa_ttype;                                    -- ��{�e��(�o��)
    lt_ship_loading_weight      loading_weight_ttype;                                -- �d�ʐύڌ���(�o��)
    lt_ship_loading_capacity    loading_capacity_ttype;                              -- �e�ϐύڌ���(�o��)
    lt_ship_mixed_ratio         mixed_ratio_ttype;                                   -- ���ڗ�(�o��)
    lt_move_based_weight        based_weight_ttype;                                  -- ��{�d��(�ړ�)
    lt_move_based_capacity      based_capa_ttype;                                    -- ��{�e��(�ړ�)
    lt_move_loading_weight      loading_weight_ttype;                                -- �d�ʐύڌ���(�ړ�)
    lt_move_loading_capacity    loading_capacity_ttype;                              -- �e�ϐύڌ���(�ړ�)
    lt_move_mixed_ratio         mixed_ratio_ttype;                                   -- ���ڗ�(�ړ�)
    -- �z�Ԕz���擾�p
    lt_sum_loading_weight       xxwsh_carriers_schedule.sum_loading_weight%TYPE;     -- �d�ʍ��v
    lt_sum_loading_capacity     xxwsh_carriers_schedule.sum_loading_capacity%TYPE;   -- �e�ύ��v
    lt_small_amount_class       xxwsh_ship_method_v.small_amount_class%TYPE;         -- �����敪
    -- �\�[�g
    lt_sort_sum_weight          xxwsh_carriers_sort_tmp.sum_weight%TYPE;             -- �\�[�g�ύڏd�ʍ��v
    lt_sort_sum_capacity        xxwsh_carriers_sort_tmp.sum_capacity%TYPE;           -- �\�[�g�ύڗe�ύ��v
    lt_sort_pallet_weight       xxwsh_carriers_sort_tmp.sum_pallet_weight%TYPE;      -- �\�[�g�p���b�g�d�ʍ��v
    lt_sort_deliver_from        xxwsh_carriers_sort_tmp.deliver_from%TYPE;           -- �\�[�g�o�Ɍ��ۊǏꏊ
    lt_sort_deliver_to          xxwsh_carriers_sort_tmp.deliver_to%TYPE;             -- �\�[�g�o�ɐ�ۊǏꏊ
    lt_schedule_ship_date       xxwsh_carriers_sort_tmp.schedule_ship_date%TYPE;     -- �\�[�g�o�ɗ\���
    lt_weight_capacity_class    xxwsh_carriers_sort_tmp.weight_capacity_class%TYPE;  -- �d�ʗe�ϋ敪
    lt_prod_class               xxwsh_carriers_sort_tmp.prod_class%TYPE;             -- ���i�敪
    lt_based_weight             xxwsh_carriers_sort_tmp.based_weight%TYPE;           -- ��{�d��
    lt_based_capacity           xxwsh_carriers_sort_tmp.based_capacity%TYPE;         -- ��{�e��
    -- �ꎞ�����p
    lt_mixed_ratio              xxwsh_order_headers_all.mixed_ratio%TYPE;            -- ���ڗ�
    lt_sum_weight               xxwsh_carriers_schedule.sum_loading_weight%TYPE;     -- �d�ʍ��v
    lv_code_kbn                 VARCHAR2(1);                                         -- �R�[�h�敪
    lv_loading_over_class       VARCHAR2(1);                                         -- �ύڃI�[�o�[�敪
    lv_ship_methods             xxcmn_ship_methods.ship_method%TYPE;                 -- �o�ו��@
    ln_load_efficiency_weight   NUMBER;                                              -- �d�ʐύڌ���
    ln_load_efficiency_capacity NUMBER;                                              -- �e�ϐύڌ���
    lv_mixed_ship_method        VARCHAR2(2);                                         -- ���ڔz���敪
    ln_set_efficiency_weight    NUMBER;                                              -- SET�p�d�ʐύڌ���
    ln_set_efficiency_capacity  NUMBER;                                              -- SET�p�e�ϐύڌ���
    ln_drink_deadweight         NUMBER;                                              -- �h�����N�ύڏd��
    ln_leaf_deadweight          NUMBER;                                              -- ���[�t�ύڏd��
    ln_leaf_loading_capacity    NUMBER;                                              -- ���[�t�ύڗe��
    ln_drink_loading_capacity   NUMBER;                                              -- �h�����N�ύڗe��
    ln_palette_max_qty          NUMBER;                                              -- �p���b�g�ő喇��
    ln_retnum                   NUMBER;                                              -- ���ʊ֐��߂�l
-- Ver1.3 M.Hokkanji End
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_upd_key_cur IS
      SELECT  xict.transaction_type transaction_type  -- �������
            , xiclt.request_no      request_no        -- �˗�No/�ړ�No
            , xmct.delivery_no      delivery_no       -- �z��No
-- Ver1.2 M.Hokkanji Start
            , xmct.fixed_shipping_method_code fixed_shipping_method_code -- �C���z���敪
-- Ver1.2 M.Hokkanji End
        FROM  xxwsh_intensive_carriers_tmp   xict     -- �����z�ԏW�񒆊ԃe�[�u��
            , xxwsh_intensive_carrier_ln_tmp xiclt    -- �����z�ԏW�񒆊Ԗ��׃e�[�u��
            , xxwsh_mixed_carriers_tmp       xmct     -- �����z�ԍ��ڒ��ԃe�[�u��
       WHERE  xict.intensive_no = xiclt.intensive_no  -- �W��No
         AND  xict.intensive_no = xmct.intensive_no   -- �W��No
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
debug_log(FND_FILE.LOG,'B-15�y�˗��E�w�����X�V�����z');
    -- ================
    -- �X�V�L�[�擾
    -- ================
    <<get_upd_key_loop>>
    FOR cur_rec IN get_upd_key_cur LOOP
--
--debug_log(FND_FILE.LOG,'�X�V�L�[�擾');
      ln_loop_cnt := ln_loop_cnt + 1;
--
-- 20080603 K.Yamane �s�No4->
      -- �z�Ԕz���v��A�h�I���̑��݃`�F�b�N
-- Ver1.3 M.Hokkanji Start
      -- �z�Ԕz���v�悩��l���擾����K�v�����邽�ߏC��
debug_log(FND_FILE.LOG,'B-15_a�y�z�Ԕz���v����擾�z' || 'delivery_no:' || cur_rec.delivery_no);
      BEGIN
        SELECT  xcs.sum_loading_weight     sum_loading_weight      -- �ύڏd�ʍ��v
               ,xcs.sum_loading_capacity   sum_loading_capacity    -- �ύڗe�ύ��v
               ,xsmv.small_amount_class    small_amount_class      -- �����敪
        INTO   lt_sum_loading_weight,
               lt_sum_loading_capacity,
               lt_small_amount_class
        FROM   xxwsh_carriers_schedule xcs, -- 
               xxwsh_ship_method_v xsmv     -- �z���敪���View
        WHERE  xcs.delivery_no = cur_rec.delivery_no
        AND    xsmv.ship_method_code = xcs.delivery_type;
        ln_cnt := 1;
debug_log(FND_FILE.LOG,'B-15_b1�y�z�Ԕz���v����擾�ΏۗL�z');
debug_log(FND_FILE.LOG,'B-15_b1 lt_sum_loading_weight:' || lt_sum_loading_weight);
debug_log(FND_FILE.LOG,'B-15_b1 lt_sum_loading_capacity:' || lt_sum_loading_capacity);
debug_log(FND_FILE.LOG,'B-15_b1 lt_small_amount_class:' || lt_small_amount_class);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
debug_log(FND_FILE.LOG,'B-15_b2�y�z�Ԕz���v����擾�Ώۃf�[�^���z');
          ln_cnt := 0;
      END;
--      SELECT COUNT(xcs.transaction_id)
--      INTO   ln_cnt
--      FROM   xxwsh_carriers_schedule xcs
--      WHERE  xcs.delivery_no = cur_rec.delivery_no
--      AND    ROWNUM = 1;
--
-- Ver1.3 M.Hokkanji End
      -- �z�Ԕz���v��A�h�I���ɑ��݂����
      IF (ln_cnt > 0) THEN
-- Ver1.3 M.Hokkanji Start
debug_log(FND_FILE.LOG,'B-15_c1�y�����z�ԃ\�[�g�p���ԃe�[�u���f�[�^�擾�zcur_rec.request_no:' || cur_rec.request_no);
        -- �w�b�_���X�V����̂ɕK�v�ȏ����擾
        BEGIN
          SELECT  NVL(xcst.sum_weight,cv_0)        sum_weight             -- �ύڏd�ʍ��v
                 ,NVL(xcst.sum_capacity,cv_0)      sum_capacity           -- �ύڗe�ύ��v
                 ,NVL(xcst.sum_pallet_weight,cv_0) sum_pallet_weight      -- ���v�p���b�g�d��
                 ,xcst.deliver_from                deliver_from           -- �o�Ɍ��ۊǏꏊ
                 ,xcst.deliver_to                  deliver_to             -- �o�א�
                 ,xcst.schedule_ship_date          schedule_ship_date     -- �o�ɗ\���
                 ,xcst.weight_capacity_class       weight_capacity_class  -- �d�ʗe�ϋ敪
                 ,xcst.prod_class                  prod_class             -- ���i�敪
          INTO    lt_sort_sum_weight
                 ,lt_sort_sum_capacity
                 ,lt_sort_pallet_weight
                 ,lt_sort_deliver_from
                 ,lt_sort_deliver_to
                 ,lt_schedule_ship_date
                 ,lt_weight_capacity_class
                 ,lt_prod_class
          FROM    xxwsh_carriers_sort_tmp xcst
          WHERE   xcst.request_no = cur_rec.request_no;
debug_log(FND_FILE.LOG,'B-15_c2�y�����z�ԃ\�[�g�p���ԃe�[�u���f�[�^�擾�����z');
debug_log(FND_FILE.LOG,'B-15_c2 lt_sort_sum_weight:' || lt_sort_sum_weight);
debug_log(FND_FILE.LOG,'B-15_c2 lt_sort_sum_capacity:' || lt_sort_sum_capacity);
debug_log(FND_FILE.LOG,'B-15_c2 lt_sort_pallet_weightt:' || lt_sort_pallet_weight);
debug_log(FND_FILE.LOG,'B-15_c2 lt_sort_deliver_from:' || lt_sort_deliver_from);
debug_log(FND_FILE.LOG,'B-15_c2 lt_sort_deliver_to:' || lt_sort_deliver_to);
debug_log(FND_FILE.LOG,'B-15_c2 lt_schedule_ship_date:' || TO_DATE(lt_schedule_ship_date,'YYYY/MM/DD'));
debug_log(FND_FILE.LOG,'B-15_c2 lt_weight_capacity_class:' || lt_weight_capacity_class);
debug_log(FND_FILE.LOG,'B-15_c2 lt_prod_class:' || lt_prod_class);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
debug_log(FND_FILE.LOG,'B-15_c3�y�����z�ԃ\�[�g�p���ԃe�[�u���f�[�^�擾���s�z');
            -- �G���[���b�Z�[�W�擾
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                          ,gv_msg_xxwsh_11804  -- �Ώۃf�[�^�Ȃ�
                          ,gv_tkn_table        -- �g�[�N��'TABLE'
                          ,cv_table_name       -- �e�[�u�����F�����z�ԃ\�[�g�p���ԃe�[�u��
                          ,gv_tkn_key          -- �g�[�N��'KEY'
                          ,cv_parameter_name || cur_rec.request_no -- �G���[�f�[�^
                         ) ,1 ,5000);
            RAISE global_api_expt;
        END;
debug_log(FND_FILE.LOG,'B-15_d�y�d�ʐݒ�z');
        -- �����̏ꍇ�̓p���b�g�d�ʂ��������Ȃ�
        IF (lt_small_amount_class = cv_an_object) THEN
          lt_sum_weight := lt_sort_sum_weight;
        ELSE
          lt_sum_weight := lt_sort_sum_weight + lt_sort_pallet_weight;
        END IF;
debug_log(FND_FILE.LOG,'B-15_e�y���ڗ��擾�z');
        -- �d�ʗe�ϋ敪���d�ʂ̏ꍇ
        IF (lt_weight_capacity_class = gv_weight) THEN
          -- �擾�����d�ʍ��v��0�̏ꍇ
          IF (lt_sum_loading_weight = cv_0) THEN
            lt_mixed_ratio := cv_0; --���ڗ���0���Z�b�g
          ELSE
            lt_mixed_ratio := ROUND(lt_sum_weight / lt_sum_loading_weight * 100,2);
          END IF;
        ELSE
          -- �擾�����e�ύ��v��0�̏ꍇ
          IF (lt_sum_loading_capacity = cv_0) THEN
            lt_mixed_ratio := cv_0; --���ڗ���0���Z�b�g
          ELSE
            lt_mixed_ratio := ROUND(lt_sort_sum_capacity / lt_sum_loading_capacity * 100,2);
          END IF;
        END IF;
debug_log(FND_FILE.LOG,'B-15_f�y�R�[�h�敪�Z�b�g�z');
        -- ������ʁF�o�ׂ̏ꍇ
        IF (cur_rec.transaction_type = gv_ship_type_ship) THEN
          lv_code_kbn := gv_cdkbn_ship_to;
        ELSE
          lv_code_kbn := gv_cdkbn_storage;
        END IF;
--
debug_log(FND_FILE.LOG,'B-15_g1�y�d�ʐύڌ����Z�o�z');
debug_log(FND_FILE.LOG,'-----------------------------------');
debug_log(FND_FILE.LOG,'B-15_g1 ���v�d��:' || lt_sum_weight);
debug_log(FND_FILE.LOG,'B-15_g1 ���v�e��:NULL');
debug_log(FND_FILE.LOG,'B-15_g1 �R�[�h�敪1:' || gv_cdkbn_storage);
debug_log(FND_FILE.LOG,'B-15_g1 ���o�ɏꏊ�R�[�h�P:' || lt_sort_deliver_from);
debug_log(FND_FILE.LOG,'B-15_g1 �R�[�h�敪2:' || lv_code_kbn);
debug_log(FND_FILE.LOG,'B-15_g1 ���o�ɏꏊ�R�[�h2:' || lt_sort_deliver_to);
debug_log(FND_FILE.LOG,'B-15_g1 �o�ו��@:' || cur_rec.fixed_shipping_method_code);
debug_log(FND_FILE.LOG,'B-15_g1 ���i�敪:' || gv_prod_class);
debug_log(FND_FILE.LOG,'B-15_g1 �����z�ԑΏۋ敪:NULL');
debug_log(FND_FILE.LOG,'B-15_g1 ���(�K�p�����):' || TO_CHAR(lt_schedule_ship_date,'YYYY/MM/DD'));
debug_log(FND_FILE.LOG,'-----------------------------------');
--
        -- ���ʊ֐��F�ύڌ����`�F�b�N(�ύڌ���)
        xxwsh_common910_pkg.calc_load_efficiency(
            in_sum_weight                  => NVL(lt_sum_weight,0)      -- 1.���v�d��
          , in_sum_capacity                => NULL                      -- 2.���v�e��
          , iv_code_class1                 => gv_cdkbn_storage          -- 3.�R�[�h�敪�P
          , iv_entering_despatching_code1  => lt_sort_deliver_from      -- 4.���o�ɏꏊ�R�[�h�P
          , iv_code_class2                 => lv_code_kbn               -- 5.�R�[�h�敪�Q
          , iv_entering_despatching_code2  => lt_sort_deliver_to        -- 6.���o�ɏꏊ�R�[�h�Q
          , iv_ship_method                 => cur_rec.fixed_shipping_method_code
                                                                        -- 7.�o�ו��@
          , iv_prod_class                  => lt_prod_class             -- 8.���i�敪
          , iv_auto_process_type           => NULL                      -- 9.�����z�ԑΏۋ敪
          , id_standard_date               => lt_schedule_ship_date
                                                                        -- 10.���(�K�p�����)
          , ov_retcode                     => lv_retcode                -- 11.���^�[���R�[�h
          , ov_errmsg_code                 => lv_errmsg                 -- 12.�G���[���b�Z�[�W�R�[�h
          , ov_errmsg                      => lv_errbuf                 -- 13.�G���[���b�Z�[�W
          , ov_loading_over_class          => lv_loading_over_class     -- 14.�ύڃI�[�o�[�敪
          , ov_ship_methods                => lv_ship_methods           -- 15.�o�ו��@
          , on_load_efficiency_weight      => ln_load_efficiency_weight -- 16.�d�ʐύڌ���
          , on_load_efficiency_capacity    => ln_load_efficiency_capacity
                                                                        -- 17.�e�ϐύڌ���
          , ov_mixed_ship_method           => lv_mixed_ship_method      -- 18.���ڔz���敪
        );
--
debug_log(FND_FILE.LOG,'-----------------------------------');
debug_log(FND_FILE.LOG,'B-15_g2 ���^�[���R�[�h:' || lv_retcode);
debug_log(FND_FILE.LOG,'B-15_g2 �G���[���b�Z�[�W�R�[�h:' || lv_errmsg);
debug_log(FND_FILE.LOG,'B-15_g2 �G���[���b�Z�[�W:' || lv_errbuf);
debug_log(FND_FILE.LOG,'B-15_g2 �ύڃI�[�o�[�敪:' || lv_loading_over_class);
debug_log(FND_FILE.LOG,'B-15_g2 �o�ו��@:' || lv_ship_methods);
debug_log(FND_FILE.LOG,'B-15_g2 �d�ʐύڌ���:' || ln_load_efficiency_weight);
debug_log(FND_FILE.LOG,'B-15_g2 �e�ϐύڌ���:' || ln_load_efficiency_capacity);
debug_log(FND_FILE.LOG,'B-15_g2 ���ڔz���敪:' || lv_mixed_ship_method);
        -- ���ʊ֐����G���[�̏ꍇ
-- Ver1.7 M.Hokkanji START
        IF (lv_retcode <> gv_status_normal) THEN
--        IF (lv_retcode = gv_status_error) THEN
-- Ver1.16 2008/12/07 START
--          lv_errmsg := lv_errbuf;
--          lv_errmsg := lv_errbuf;
        BEGIN
          lv_errmsg  :=   NVL(lt_sum_weight,0) -- 1.���v�d��
                          || gv_msg_comma ||
                          NULL                -- 2.���v�e��
                          || gv_msg_comma ||
                          gv_cdkbn_storage    -- 3.�R�[�h�敪�P
                          || gv_msg_comma ||
                          lt_sort_deliver_from  -- 4.���o�ɏꏊ�R�[�h�P
                          || gv_msg_comma ||
                          lv_code_kbn      -- 5.�R�[�h�敪�Q
                          || gv_msg_comma ||
                          lt_sort_deliver_to    -- 6.���o�ɏꏊ�R�[�h�Q
                          || gv_msg_comma ||
                          cur_rec.fixed_shipping_method_code -- 7.�o�ו��@
                          || gv_msg_comma ||
                          lt_prod_class       -- 8.���i�敪
                          || gv_msg_comma ||
                          NULL       -- 9.�����z�ԑΏۋ敪
                          || gv_msg_comma ||
                          TO_CHAR(lt_schedule_ship_date, 'YYYY/MM/DD'); -- 10.���
          lv_errmsg := lv_errmsg|| '(�d��,�e��,�R�[�h�敪1,�R�[�h1,�R�[�h�敪2,�R�[�h2';
          lv_errmsg := lv_errmsg|| ',�z���敪,���i�敪,�����z�ԑΏۋ敪,���'; -- msg
          lv_errmsg := lv_errmsg||lv_errbuf ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := lv_errbuf ;
        END;
-- Ver1.16 2008/12/07 End
-- Ver1.7 M.Hokkanji END
--
debug_log(FND_FILE.LOG,'B-15_g3�y�d�ʐύڌ����擾�G���[�z');
--
          RAISE global_api_expt;
        END IF;
--
-- Ver 1.7 M.Hokkanji Start
-- �e�w�b�_�ɐݒ肷��Ƃ��͐ύڃI�[�o�[�����O
-- Ver 1.7 M.Hokkanji End
        -- �ύڃI�[�o�[�̏ꍇ
--        IF (lv_loading_over_class = cv_loading_over) THEN
--debug_log(FND_FILE.LOG,'B-15_g4�y�d�ʐύڌ����ύڃI�[�o�[�z');
          -- �G���[���b�Z�[�W�擾
--          lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
--                           gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
--                         , gv_msg_xxwsh_11803  -- ���b�Z�[�W�FAPP-XXWSH-11803 �ύڃI�[�o�[���b�Z�[�W
--                         , gv_tkn_req_no       -- �g�[�N���FREQ_NO
--                         , cur_rec.request_no  -- �o�׈˗�No
--                        ),1,5000);
--          lv_errbuf := lv_errmsg;
--          RAISE global_api_expt;
--        END IF;
-- Ver 1.7 M.Hokkanji End
debug_log(FND_FILE.LOG,'B-15_g5�y�d�ʐύڌ����Z�b�g�z');
        -- �d�ʐύڌ������Z�b�g
        ln_set_efficiency_weight := ln_load_efficiency_weight;
--
debug_log(FND_FILE.LOG,'B-15_h1�y�e�ϐύڌ����Z�o�z');
debug_log(FND_FILE.LOG,'-----------------------------------');
debug_log(FND_FILE.LOG,'B-15_h1 ���v�d��:NULL');
debug_log(FND_FILE.LOG,'B-15_h1 ���v�e��:'|| lt_sort_sum_capacity);
debug_log(FND_FILE.LOG,'B-15_h1 �R�[�h�敪1:' || gv_cdkbn_storage);
debug_log(FND_FILE.LOG,'B-15_h1 ���o�ɏꏊ�R�[�h�P:' || lt_sort_deliver_from);
debug_log(FND_FILE.LOG,'B-15_h1 �R�[�h�敪2:' || lv_code_kbn);
debug_log(FND_FILE.LOG,'B-15_h1 ���o�ɏꏊ�R�[�h2:' || lt_sort_deliver_to);
debug_log(FND_FILE.LOG,'B-15_h1 �o�ו��@:' || cur_rec.fixed_shipping_method_code);
debug_log(FND_FILE.LOG,'B-15_h1 ���i�敪:' || gv_prod_class);
debug_log(FND_FILE.LOG,'B-15_h1 �����z�ԑΏۋ敪:NULL');
debug_log(FND_FILE.LOG,'B-15_h1 ���(�K�p�����):' || TO_CHAR(lt_schedule_ship_date,'YYYY/MM/DD'));
debug_log(FND_FILE.LOG,'-----------------------------------');
--
        -- ���ʊ֐��F�ύڌ����`�F�b�N(�ύڌ���)
        xxwsh_common910_pkg.calc_load_efficiency(
            in_sum_weight                  => NULL                        -- 1.���v�d��
          , in_sum_capacity                => NVL(lt_sort_sum_capacity,0) -- 2.���v�e��
          , iv_code_class1                 => gv_cdkbn_storage          -- 3.�R�[�h�敪�P
          , iv_entering_despatching_code1  => lt_sort_deliver_from      -- 4.���o�ɏꏊ�R�[�h�P
          , iv_code_class2                 => lv_code_kbn               -- 5.�R�[�h�敪�Q
          , iv_entering_despatching_code2  => lt_sort_deliver_to        -- 6.���o�ɏꏊ�R�[�h�Q
          , iv_ship_method                 => cur_rec.fixed_shipping_method_code
                                                                        -- 7.�o�ו��@
          , iv_prod_class                  => lt_prod_class             -- 8.���i�敪
          , iv_auto_process_type           => NULL                      -- 9.�����z�ԑΏۋ敪
          , id_standard_date               => lt_schedule_ship_date
                                                                        -- 10.���(�K�p�����)
          , ov_retcode                     => lv_retcode                -- 11.���^�[���R�[�h
          , ov_errmsg_code                 => lv_errmsg                 -- 12.�G���[���b�Z�[�W�R�[�h
          , ov_errmsg                      => lv_errbuf                 -- 13.�G���[���b�Z�[�W
          , ov_loading_over_class          => lv_loading_over_class     -- 14.�ύڃI�[�o�[�敪
          , ov_ship_methods                => lv_ship_methods           -- 15.�o�ו��@
          , on_load_efficiency_weight      => ln_load_efficiency_weight -- 16.�d�ʐύڌ���
          , on_load_efficiency_capacity    => ln_load_efficiency_capacity
                                                                        -- 17.�e�ϐύڌ���
          , ov_mixed_ship_method           => lv_mixed_ship_method      -- 18.���ڔz���敪
        );
--
debug_log(FND_FILE.LOG,'-----------------------------------');
debug_log(FND_FILE.LOG,'B-15_h2 ���^�[���R�[�h:' || lv_retcode);
debug_log(FND_FILE.LOG,'B-15_h2 �G���[���b�Z�[�W�R�[�h:' || lv_errmsg);
debug_log(FND_FILE.LOG,'B-15_h2 �G���[���b�Z�[�W:' || lv_errbuf);
debug_log(FND_FILE.LOG,'B-15_h2 �ύڃI�[�o�[�敪:' || lv_loading_over_class);
debug_log(FND_FILE.LOG,'B-15_h2 �o�ו��@:' || lv_ship_methods);
debug_log(FND_FILE.LOG,'B-15_h2 �d�ʐύڌ���:' || ln_load_efficiency_weight);
debug_log(FND_FILE.LOG,'B-15_h2 �e�ϐύڌ���:' || ln_load_efficiency_capacity);
debug_log(FND_FILE.LOG,'B-15_h2 ���ڔz���敪:' || lv_mixed_ship_method);
        -- ���ʊ֐����G���[�̏ꍇ
-- Ver1.7 M.Hokkanji START
        IF (lv_retcode <> gv_status_normal) THEN
--        IF (lv_retcode = gv_status_error) THEN
          lv_errmsg := lv_errbuf;
-- Ver1.7 M.Hokkanji END
--       
debug_log(FND_FILE.LOG,'B-15_h3�y�e�ϐύڌ����擾�G���[�z');
--
          RAISE global_api_expt;
        END IF;
--
-- Ver 1.7 M.Hokkanji Start
-- �e�w�b�_�ɐύڗ���ݒ肷��ꍇ�͐ύڃI�[�o�����O
        -- �ύڃI�[�o�[�̏ꍇ
--        IF (lv_loading_over_class = cv_loading_over) THEN
--debug_log(FND_FILE.LOG,'B-15_h4�y�e�ϐύڌ����ύڃI�[�o�[�z');
          -- �G���[���b�Z�[�W�擾
--          lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
--                           gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
--                         , gv_msg_xxwsh_11803  -- ���b�Z�[�W�FAPP-XXWSH-11803 �ύڃI�[�o�[���b�Z�[�W
--                         , gv_tkn_req_no       -- �g�[�N���FREQ_NO
--                         , cur_rec.request_no  -- �o�׈˗�No
--                        ),1,5000);
--          lv_errbuf := lv_errmsg;
--          RAISE global_api_expt;
--        END IF;
-- Ver 1.7 M.Hokkanji End
debug_log(FND_FILE.LOG,'B-15_h5�y�e�ϐύڌ����Z�b�g�z');
        -- �e�ϐύڌ������Z�b�g
        ln_set_efficiency_capacity := ln_load_efficiency_capacity;
debug_log(FND_FILE.LOG,'B-15_i1�y��{�d�ʊ�{�e�ώ擾�z');
        ln_retnum :=  xxwsh_common_pkg.get_max_pallet_qty(    -- ���ʊ֐��F�ő�p���b�g�����Z�o�֐�
                          iv_code_class1
                                  => gv_cdkbn_storage             -- �R�[�h�敪�P
                        , iv_entering_despatching_code1
                                  => lt_sort_deliver_from         -- ���o�ɏꏊ�R�[�h�P
                        , iv_code_class2
                                  => lv_code_kbn                  -- �R�[�h�敪�Q
                        , iv_entering_despatching_code2
                                  => lt_sort_deliver_to           -- ���o�ɏꏊ�R�[�h�Q
                        , id_standard_date
                                  => lt_schedule_ship_date        -- ���
                        , iv_ship_methods
                                  => cur_rec.fixed_shipping_method_code
                                                                  -- �z���敪                                
                        , on_drink_deadweight
                                  => ln_drink_deadweight          -- �h�����N�ύڏd��
                        , on_leaf_deadweight
                                  => ln_leaf_deadweight           -- ���[�t�ύڏd��
                        , on_drink_loading_capacity
                                  => ln_drink_loading_capacity    -- �h�����N�ύڗe��
                        , on_leaf_loading_capacity
                                  => ln_leaf_loading_capacity     -- ���[�t�ύڗe��
                        , on_palette_max_qty
                                  => ln_palette_max_qty           -- �p���b�g�ő喇��
                     );
debug_log(FND_FILE.LOG,'B-15_i2�y��{�d�ʊ�{�e�ώ擾��z');
debug_log(FND_FILE.LOG,'�E���^�[���R�[�h:'|| ln_retnum);
debug_log(FND_FILE.LOG,'�E�h�����N�ύڏd��:'|| ln_drink_deadweight);
debug_log(FND_FILE.LOG,'�E���[�t�ύڏd��:'|| ln_leaf_deadweight);
debug_log(FND_FILE.LOG,'�E�h�����N�ύڗe��:'|| ln_leaf_loading_capacity);
debug_log(FND_FILE.LOG,'�E���[�t�ύڗe��:'|| ln_leaf_loading_capacity);
debug_log(FND_FILE.LOG,'�E�p���b�g�ő喇��:'|| ln_palette_max_qty);
        -- ���ʊ֐��G���[�̏ꍇ
        IF (ln_retnum = cn_sts_error) THEN
          gv_err_key  :=  gv_cdkbn_storage
                          || gv_msg_comma ||
                          lt_sort_deliver_from
                          || gv_msg_comma ||
                          lv_code_kbn
                          || gv_msg_comma ||
                          lt_sort_deliver_to
                          || gv_msg_comma ||
                          TO_CHAR(lt_schedule_ship_date, 'YYYY/MM/DD')
                          || gv_msg_comma ||
                          cur_rec.fixed_shipping_method_code
                          ;
          -- �G���[���b�Z�[�W�擾
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_xxwsh                -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                        , gv_msg_xxwsh_11810      -- ���b�Z�[�W�FAPP-XXWSH-11810 ���ʊ֐��G���[
                        , gv_fnc_name             -- �g�[�N���FFNC_NAME
                        , 'xxwsh_common_pkg.get_max_pallet_qty' -- �֐���
                        , gv_tkn_key              -- �g�[�N���FKEY
                        , gv_err_key              -- �֐����s�L�[
                        ),1,5000);
          RAISE global_api_expt;
        END IF;
debug_log(FND_FILE.LOG,'B-15_i3�y��{�d�ʊ�{�e�ϓ��菈���z');
        -- ���i�敪�����[�t�̏ꍇ
        IF ( lt_prod_class = gv_prod_cls_leaf) THEN
          lt_based_weight   := ln_leaf_deadweight;
          lt_based_capacity := ln_leaf_loading_capacity;
        ELSE
          lt_based_weight   := ln_drink_deadweight;
          lt_based_capacity := ln_drink_loading_capacity;
        END IF;
--
-- Ver1.3 M.Hokkanji End
--
        -- ������ʁF�o��
        IF (cur_rec.transaction_type = gv_ship_type_ship) THEN
--
debug_log(FND_FILE.LOG,'B15_1.0 ������ʁF�o�� ln_loop_cnt= '||to_char(ln_loop_cnt));
--20080517 D.Sugahara �s�No2�Ή�->
--        lt_upd_req_no_ship_tab(ln_loop_cnt)       := cur_rec.request_no;    -- �˗�No
--        lt_upd_delibery_no_ship_tab(ln_loop_cnt)  := cur_rec.delivery_no;   -- �z��No
          ln_loop_cnt_ship := ln_loop_cnt_ship + 1;                -- ���[�v�J�E���g(�o�׈˗��p�j
          lt_upd_req_no_ship_tab(ln_loop_cnt_ship)       := cur_rec.request_no;    -- �˗�No
          lt_upd_delibery_no_ship_tab(ln_loop_cnt_ship)  := cur_rec.delivery_no;   -- �z��No
--20080517 D.Sugahara �s�No2�Ή�<-
-- Ver1.2 M.Hokkanji Start
          lt_upd_method_code_ship_tab(ln_loop_cnt_ship)  := cur_rec.fixed_shipping_method_code; -- �C���z���敪
-- Ver1.2 M.Hokkanji End
--
-- Ver1.3 M.Hokkanji Start
          lt_ship_based_weight(ln_loop_cnt_ship)         := lt_based_weight;            -- ��{�d��
          lt_ship_based_capacity(ln_loop_cnt_ship)       := lt_based_capacity;          -- ��{�e��
          lt_ship_loading_weight(ln_loop_cnt_ship)       := ln_set_efficiency_weight;   -- �d�ʐύڌ���
          lt_ship_loading_capacity(ln_loop_cnt_ship)     := ln_set_efficiency_capacity; -- �e�ϐύڌ���
          lt_ship_mixed_ratio(ln_loop_cnt_ship)          := lt_mixed_ratio;             -- ���ڗ�
-- Ver1.3 M.Hokkanji End
        -- ������ʁF�ړ�
        ELSE
debug_log(FND_FILE.LOG,'B15_1.1 ������ʁF�ړ� ln_loop_cnt= '||to_char(ln_loop_cnt));
--20080517 D.Sugahara �s�No2�Ή�->
--        lt_upd_req_no_move_tab(ln_loop_cnt)       := cur_rec.request_no;    -- �ړ�No
--        lt_upd_delibery_no_move_tab(ln_loop_cnt)  := cur_rec.delivery_no;   -- �z��No
          ln_loop_cnt_move := ln_loop_cnt_move + 1;                -- ���[�v�J�E���g(�o�׈˗��p�j
          lt_upd_req_no_move_tab(ln_loop_cnt_move)       := cur_rec.request_no;    -- �ړ�No
          lt_upd_delibery_no_move_tab(ln_loop_cnt_move)  := cur_rec.delivery_no;   -- �z��No
--20080517 D.Sugahara �s�No2�Ή�<-
-- Ver1.2 M.Hokkanji Start
          lt_upd_method_code_move_tab(ln_loop_cnt_move)  := cur_rec.fixed_shipping_method_code; -- �C���z���敪
-- Ver1.2 M.Hokkanji End
--
-- Ver1.3 M.Hokkanji Start
          lt_move_based_weight(ln_loop_cnt_move)         := lt_based_weight;            -- ��{�d��
          lt_move_based_capacity(ln_loop_cnt_move)       := lt_based_capacity;          -- ��{�e��
          lt_move_loading_weight(ln_loop_cnt_move)       := ln_set_efficiency_weight;   -- �d�ʐύڌ���
          lt_move_loading_capacity(ln_loop_cnt_move)     := ln_set_efficiency_capacity; -- �e�ϐύڌ���
          lt_move_mixed_ratio(ln_loop_cnt_move)          := lt_mixed_ratio;             -- ���ڗ�
-- Ver1.3 M.Hokkanji End
--
        END IF;
--
      END IF;
-- 20080603 K.Yamane �s�No4<-
--
    END LOOP get_upd_key_loop;
--
    -- ============================
    --  �˗��E�w�����ꊇ�X�V����
    -- ============================
    -- WHO�J�����擾
    lt_user_id          := FND_GLOBAL.USER_ID;          -- �쐬�ҁA�ŏI�X�V��
    lt_login_id         := FND_GLOBAL.LOGIN_ID;         -- �ŏI�X�V���O�C��
-- 20080603 K.Yamane �s�No14->
    lt_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;  -- �v��ID
    lt_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;     -- �A�v���P�[�V����ID
    lt_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;  -- �v���O����ID
-- 20080603 K.Yamane �s�No14<-
--
debug_log(FND_FILE.LOG,'B15_1.2 �o�׍X�V�����F'||to_char(lt_upd_req_no_ship_tab.COUNT));
debug_log(FND_FILE.LOG,'B15_1.2 �ړ��X�V�����F'||to_char(lt_upd_req_no_move_tab.COUNT));
    -- �󒍃w�b�_�A�h�I��
    FORALL upd_cnt_1 IN 1..lt_upd_req_no_ship_tab.COUNT
--debug_log(FND_FILE.LOG,'B15_1.3 �o�׍X�V�F '||to_char(upd_cnt_1)||'����');
      UPDATE xxwsh_order_headers_all
         SET  delivery_no            = lt_upd_delibery_no_ship_tab(upd_cnt_1)  -- �z��No
            , last_updated_by        = lt_user_id                              -- �ŏI�X�V��
            , last_update_date       = SYSDATE                                 -- �ŏI�X�V��
            , last_update_login      = lt_login_id                             -- �ŏI�X�V���O�C��
            , request_id             = lt_conc_request_id                      -- �v��ID
-- Ver1.2 M.Hokkanji Start
            , shipping_method_code   = lt_upd_method_code_ship_tab(upd_cnt_1)  -- �z���敪
-- Ver1.2 M.Hokkanji End
-- Ver1.3 M.Hokkanji Start
            , based_weight           = lt_ship_based_weight(upd_cnt_1)         -- ��{�d��
            , based_capacity         = lt_ship_based_capacity(upd_cnt_1)       -- ��{�e��
            , loading_efficiency_weight
                                     = lt_ship_loading_weight(upd_cnt_1)       -- �d�ʐύڌ���
            , loading_efficiency_capacity
                                     = lt_ship_loading_capacity(upd_cnt_1)     -- �e�ϐύڌ���
            , mixed_ratio            = lt_ship_mixed_ratio(upd_cnt_1)          -- ���ڗ�
-- Ver1.3 M.Hokkanji End
-- 20080603 K.Yamane �s�No14->
            , program_application_id = lt_prog_appl_id                         -- ���ع����ID
            , program_id             = lt_conc_program_id                      -- �v���O����ID
            , program_update_date    = SYSDATE                                 -- �v���O�����X�V��
-- 20080603 K.Yamane �s�No14<-
       WHERE  request_no           = lt_upd_req_no_ship_tab(upd_cnt_1)    -- �˗�No
         AND  latest_external_flag = cv_yes                               -- �ŐV�t���O
      ;
--
    -- �ړ��˗�/�w���w�b�_�A�h�I��
    FORALL upd_cnt_2 IN 1..lt_upd_req_no_move_tab.COUNT
--debug_log(FND_FILE.LOG,'B15_1.4 �ړ��X�V�F '||to_char(upd_cnt_2)||'����');
      UPDATE xxinv_mov_req_instr_headers
         SET  delivery_no            = lt_upd_delibery_no_move_tab(upd_cnt_2)  -- �z��No
            , last_updated_by        = lt_user_id                              -- �ŏI�X�V��
            , last_update_date       = SYSDATE                                 -- �ŏI�X�V��
            , last_update_login      = lt_login_id                             -- �ŏI�X�V���O�C��
-- Ver1.2 M.Hokkanji Start
            , shipping_method_code   = lt_upd_method_code_move_tab(upd_cnt_2)  -- �z���敪
-- Ver1.2 M.Hokkanji End
-- Ver1.3 M.Hokkanji Start
            , based_weight           = lt_move_based_weight(upd_cnt_2)         -- ��{�d��
            , based_capacity         = lt_move_based_capacity(upd_cnt_2)       -- ��{�e��
            , loading_efficiency_weight
                                     = lt_move_loading_weight(upd_cnt_2)       -- �d�ʐύڌ���
            , loading_efficiency_capacity
                                     = lt_move_loading_capacity(upd_cnt_2)     -- �e�ϐύڌ���
            , mixed_ratio            = lt_move_mixed_ratio(upd_cnt_2)          -- ���ڗ�
-- Ver1.3 M.Hokkanji End
-- 20080603 K.Yamane �s�No14->
            , request_id             = lt_conc_request_id                      -- �v��ID
            , program_application_id = lt_prog_appl_id                         -- ���ع����ID
            , program_id             = lt_conc_program_id                      -- �v���O����ID
            , program_update_date    = SYSDATE                                 -- �v���O�����X�V��
-- 20080603 K.Yamane �s�No14<-
       WHERE  mov_num           = lt_upd_req_no_move_tab(upd_cnt_2)       -- �ړ�No
      ;
-- Ver1.2 M.Hokkanji Start
    -- ����ΏۂƂȂ����w�b�_�ɕR�t���z��No�ŕR�t���������Ȃ������̂��폜
    BEGIN
      DELETE xxwsh_carriers_schedule xch
       WHERE xch.delivery_no IN (
-- Ver1.6 M.Hokkanji Start
--               SELECT xcst.delivery_no
               SELECT NVL(xcst.delivery_no,xcst.mixed_no)
-- Ver1.6 M.Hokkanji End
                 FROM xxwsh_carriers_sort_tmp xcst
-- Ver1.6 M.Hokkanji Start
                  WHERE NOT EXISTS (
--                WHERE xcst.delivery_no IS NOT NULL
--                AND NOT EXISTS (
-- Ver1.6 M.Hokkanji End
-- Ver1.8 A.Shiina START
/*
                      SELECT xoh.delivery_no delivery_no
                        FROM xxwsh_order_headers_all xoh
-- Ver1.6 M.Hokkanji Start
--                       WHERE xoh.delivery_no = xcst.delivery_no
                       WHERE NVL(xoh.delivery_no,xoh.mixed_no) = NVL(xcst.delivery_no,xcst.mixed_no)
-- Ver1.6 M.Hokkanji End
                         AND xoh.latest_external_flag = 'Y')
                AND NOT EXISTS (
                      SELECT xmrih.delivery_no delivery_no
                        FROM xxinv_mov_req_instr_headers xmrih
                       WHERE xmrih.delivery_no = xcst.delivery_no
               ));
*/
                    SELECT xoh.delivery_no delivery_no
                    FROM   xxwsh_order_headers_all xoh
                    WHERE  xoh.delivery_no IS NOT NULL
                    AND    xoh.delivery_no = NVL ( xcst.delivery_no , xcst.mixed_no )
                    AND    xoh.latest_external_flag = 'Y'
                    AND    ROWNUM <= 1
                    UNION ALL
                    SELECT xoh.delivery_no delivery_no
                    FROM   xxwsh_order_headers_all xoh
                    WHERE  xoh.delivery_no IS NULL
                    AND    xoh.mixed_no = NVL ( xcst.delivery_no , xcst.mixed_no )
                    AND    xoh.latest_external_flag = 'Y'
                    AND    ROWNUM <= 1)
                  AND NOT EXISTS (
                    SELECT xmrih.delivery_no delivery_no
                    FROM   xxinv_mov_req_instr_headers xmrih
                    WHERE  xmrih.delivery_no = xcst.delivery_no
                    AND    ROWNUM <= 1) ) ;
-- Ver1.8 A.Shiina END
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL; -- �Ώی�����0���̏ꍇ�̓G���[�Ƃ��Ȃ��B
    END;
debug_log(FND_FILE.LOG,'B15_1.3 �z�Ԕz���v��폜�����F'||TO_CHAR(SQL%rowcount));
-- Ver1.2 M.Hokkanji End
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
  END upd_req_inst_info;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_prod_class           IN  VARCHAR2,         --  1.���i�敪
    iv_shipping_biz_type    IN  VARCHAR2,         --  2.�������
    iv_block_1              IN  VARCHAR2,         --  3.�u���b�N1
    iv_block_2              IN  VARCHAR2,         --  4.�u���b�N2
    iv_block_3              IN  VARCHAR2,         --  5.�u���b�N3
    iv_storage_code         IN  VARCHAR2,         --  6.�o�Ɍ�
    iv_transaction_type_id  IN  VARCHAR2,         --  7.�o�Ɍ`��ID
    iv_date_from            IN  VARCHAR2,         --  8.�o�ɓ�From
    iv_date_to              IN  VARCHAR2,         --  9.�o�ɓ�To
    iv_forwarder_id         IN  VARCHAR2,         -- 10.�^���Ǝ�ID
    ov_errbuf               OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_errbuf  VARCHAR2(5000);        -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);           -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);        -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_warning_flg  BOOLEAN DEFAULT FALSE; -- �x���t���O�i�x���̏ꍇ�FTRUE)
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prod_class CONSTANT VARCHAR2(100)  :=  '���i�敪';   -- ���i�敪
    cv_date_from  CONSTANT VARCHAR2(100)  :=  '�o�ɓ�FROM'; -- �o�ɓ�From
    cv_date_to    CONSTANT VARCHAR2(100)  :=  '�o�ɓ�TO';   -- �o�ɓ�To
--
    -- *** ���[�J���ϐ� ***
    lv_msg        VARCHAR2(5000);                           -- ���[�J�����b�Z�[�W
    ld_date_from  DATE;                                     -- �o�ɓ�From
    ld_date_to    DATE;                                     -- �o�ɓ�To
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
debug_log(FND_FILE.LOG,'�y�T�u���C���z');
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================
    -- B-1.�p�[�W����
    -- ===============================
    del_table_purge(
       ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
     , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
     , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �p�[�W�������G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
debug_log(FND_FILE.LOG,'B-1.�p�[�W�����I��');
--
debug_log(FND_FILE.LOG,'B-2.�p�����[�^�`�F�b�N�����J�n');
    -- ===============================
    -- B-2.�p�����[�^�`�F�b�N����
    -- ===============================
    -- ���i�敪������
    IF (iv_prod_class IS NULL) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                    , gv_msg_xxwsh_13151  -- ���b�Z�[�W�FAPP-XXWSH-13151 �K�{�p�����[�^�����̓G���[
                    , gv_tkn_item         -- �g�[�N���FITEM
                    , cv_prod_class       -- �p�����[�^�D���i�敪
                   ),1,5000);
      RAISE global_process_expt;
--
    END IF;
debug_log(FND_FILE.LOG,'�E���i�敪');
--
    -- �o�ɓ�From������
    IF (iv_date_from IS NULL) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                    , gv_msg_xxwsh_13151  -- ���b�Z�[�W�FAPP-XXWSH-13151 �K�{�p�����[�^�����̓G���[
                    , gv_tkn_item         -- �g�[�N���FITEM
                    , cv_date_from        -- �p�����[�^�D�o�ɓ�From
                   ),1,5000);
      RAISE global_process_expt;
    ELSE
      BEGIN
        -- �����`�F�b�N
        SELECT FND_DATE.CANONICAL_TO_DATE(iv_date_from)
        INTO  ld_date_from
        FROM  DUAL
        ;
      EXCEPTION
        WHEN to_date_expt_m THEN
          -- ��������
          RAISE to_date_expt;
        WHEN to_date_expt_d THEN
          -- ��������
          RAISE to_date_expt;
        WHEN to_date_expt_y THEN
          -- ���e�����ƕs��v
          RAISE to_date_expt;
        WHEN OTHERS THEN
          RAISE global_process_expt;
      END;
--
    END IF;
--
debug_log(FND_FILE.LOG,'�E�o�ɓ�FROM');
    -- �o�ɓ�To������
    IF (iv_date_To IS NULL) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                    , gv_msg_xxwsh_13151  -- ���b�Z�[�W�FAPP-XXWSH-13151 �K�{�p�����[�^�����̓G���[
                    , gv_tkn_item         -- �g�[�N���FITEM
                    , cv_date_To          -- �p�����[�^�D�o�ɓ�To
                   ),1,5000);
      RAISE global_process_expt;
--
    ELSE
--
      BEGIN
        -- �����`�F�b�N
        SELECT FND_DATE.CANONICAL_TO_DATE(iv_date_to)
        INTO  ld_date_to
        FROM  DUAL
        ;
      EXCEPTION
        WHEN to_date_expt_m THEN
          -- ��������
          RAISE to_date_expt;
        WHEN to_date_expt_d THEN
          -- ��������
          RAISE to_date_expt;
        WHEN to_date_expt_y THEN
          -- ���e�����ƕs��v
          RAISE to_date_expt;
        WHEN OTHERS THEN
          RAISE global_process_expt;
      END;
--
    END IF;
--
debug_log(FND_FILE.LOG,'�E�o�ɓ�To');
    -- ���t�t�]
    IF (ld_date_from > ld_date_to) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                    , gv_msg_xxwsh_11113  -- ���b�Z�[�W�FAPP-XXWSH-11113 ���t�t�]�G���[
                   ),1,5000);
      RAISE global_process_expt;
    END IF;
--
debug_log(FND_FILE.LOG,'�p�����[�^�`�F�b�N�I��');
    -- �p�����[�^���O���[�o���ϐ��ɃZ�b�g
    gv_prod_class     :=  iv_prod_class;        -- ���i�敪
    gv_ship_biz_type  :=  iv_shipping_biz_type; -- �������
    gd_date_from      :=  ld_date_from;         -- �o�ɓ�From
--
    -- ===============================
    -- B-3.�˗��w����񒊏o
    -- ===============================
    get_req_inst_info(
        iv_prod_class           => iv_prod_class            --  1.���i�敪
      , iv_shipping_biz_type    => iv_shipping_biz_type     --  2.�������
      , iv_block_1              => iv_block_1               --  3.�u���b�N�P
      , iv_block_2              => iv_block_2               --  4.�u���b�N�Q
      , iv_block_3              => iv_block_3               --  5.�u���b�N�R
      , iv_storage_code         => iv_storage_code          --  6.�o�Ɍ�
      , iv_transaction_type_id  => iv_transaction_type_id   --  7.�o�Ɍ`��ID
      , id_date_from            => ld_date_from             --  8.�o�ɓ�From
      , id_date_to              => ld_date_to               --  9.�o�ɓ�To
      , iv_forwarder            => iv_forwarder_id          -- 10.�^���Ǝ�ID
      , ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �G���[����
    IF (lv_retcode = gv_status_error) THEN
      -- �������G���[�̏ꍇ
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      --�������x���̏ꍇ
debug_log(FND_FILE.LOG,'B-3.�˗��w����񒊏o �x�����b�Z�[�W�F'||lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      lb_warning_flg := TRUE;
    END IF;
--
debug_log(FND_FILE.LOG,'B-3.�˗��w����񒊏o �I���X�e�[�^�X��'||lv_retcode);
    --B-3����̏ꍇ�݈̂ȉ��̏������s���i�x���F�f�[�^�Ȃ��̏ꍇ�A�ȉ��̏����͍s��Ȃ��j
    IF (lv_retcode = gv_status_normal) THEN
--
      -- �p�����[�^.������ʂ��u�o�׈˗��v�܂��͎w�薳���̏ꍇ�̂ݎ��{
      IF (iv_shipping_biz_type = gv_ship_type_ship)
        OR (iv_shipping_biz_type IS NULL)
      THEN
--
        -- ===============================
        -- B-4.���_���ڏ��o�^����
        -- ===============================
        ins_hub_mixed_info(
             ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
           , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
           , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
        -- �������G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
debug_log(FND_FILE.LOG,'B-4.���_���ڏ��o�^����');
--
        -- ===============================
        -- B-5.�ύڌ����`�F�b�N����
        -- ===============================
        chk_loading_efficiency(
             ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
           , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
           , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
        -- �������G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
debug_log(FND_FILE.LOG,'B-5.�ύڌ����`�F�b�N����');
--
      -- =======================================
      -- B-6.�ő�z���敪�A�d�ʗe�ϋ敪�擾����
      -- =======================================
        get_max_shipping_method(
             ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
           , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
           , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
      -- �������G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = gv_status_warn) THEN
        --�������x���̏ꍇ
debug_log(FND_FILE.LOG,'B-6.�ő�z���敪�A�d�ʗe�ϋ敪�擾���� �x�����b�Z�[�W�F'||lv_errmsg);
        lb_warning_flg := TRUE;
      END IF;
debug_log(FND_FILE.LOG,'B-6.�ő�z���敪�A�d�ʗe�ϋ敪�擾����');
--
      -- =============================
      -- B-9.�W�񒆊ԏ�񒊏o����
      -- =============================
        get_intensive_tmp(
             ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
           , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
           , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
      -- �������G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
debug_log(FND_FILE.LOG,'B-9.�W�񒆊ԏ�񒊏o����');
      -- ===============================
      -- B-14.�z�Ԕz���v��A�h�I���o��
      -- ===============================
        ins_xxwsh_carriers_schedule(
             ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
           , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
           , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
      -- �������G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = gv_status_warn) THEN
        --�������x���̏ꍇ
        lb_warning_flg := TRUE;
      END IF;
--
debug_log(FND_FILE.LOG,'B-14.�z�Ԕz���v��A�h�I���o�� �X�e�[�^�X�� '||lv_retcode);
      -- ===============================
      -- B-15.�˗��E�w�����X�V����
      -- ===============================
      upd_req_inst_info(
             ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
           , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
           , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
      -- �������G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF; -- B-3����Ȃ�
    --�x������
    IF (lb_warning_flg) THEN
      ov_retcode := gv_status_warn; --�����ꂩ�̏����Ōx���Ȃ�x���I��
    END IF;
--
debug_log(FND_FILE.LOG,'B-15.�˗��E�w�����X�V����');
    -- ===============================
    -- ���|�[�g�o�͏���
    -- ===============================
    -- ��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- ���̓p�����[�^(���o��)
    lv_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                  gv_xxwsh            -- ���W���[�������́FXXCMN ����
                , gv_msg_xxwsh_11806  -- ���b�Z�[�W�FAPP-XXWSH-11806 ���̓p�����[�^(���o��)
                ),1,5000);
--
    -- ���̓p�����[�^���o���o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
    -- ���̓p�����[�^�o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_parameters);
--
    -- ��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- �o�׈˗�����
    IF (gn_ship_cnt > 0) THEN
      lv_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxwsh            -- ���W���[�������́FXXCMN ����
                  , gv_msg_xxwsh_11807  -- ���b�Z�[�W�FAPP-XXWSH-11807 �o�׈˗�����
                  , gv_tkn_count        -- �g�[�N���FCOUNT
                  , gn_ship_cnt         -- �o�׈˗�����
                  ),1,5000);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
    END IF;
--
    IF (gn_move_cnt > 0) THEN
      -- �ړ��w������
      lv_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxwsh            -- ���W���[�������́FXXCMN ����
                  , gv_msg_xxwsh_11808  -- ���b�Z�[�W�FAPP-XXWSH-11808 �o�׈˗�����
                  , gv_tkn_count        -- �g�[�N���FCOUNT
                  , gn_move_cnt         -- �ړ��w������
                  ),1,5000);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
    END IF;
debug_log(FND_FILE.LOG,'���|�[�g�o��');
debug_log(FND_FILE.LOG,'�I���X�e�[�^�X�� '||ov_retcode);
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
    WHEN to_date_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwsh            -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                    , gv_msg_xxwsh_11809  -- ���b�Z�[�W�FAPP-XXWSH-11809 ���̓p�����[�^�����G���[
                    , gv_tkn_parm_name    -- �g�[�N���FPARM_NAME
                    , cv_date_To          -- �p�����[�^�D�o�ɓ�To
                   ),1,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
    errbuf                  OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                 OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h    --# �Œ� #
    iv_prod_class           IN  VARCHAR2,         --  1.���i�敪
    iv_shipping_biz_type    IN  VARCHAR2,         --  2.�������
    iv_block_1              IN  VARCHAR2,         --  3.�u���b�N1
    iv_block_2              IN  VARCHAR2,         --  4.�u���b�N2
    iv_block_3              IN  VARCHAR2,         --  5.�u���b�N3
    iv_storage_code         IN  VARCHAR2,         --  6.�o�Ɍ�
    iv_transaction_type_id  IN  VARCHAR2,         --  7.�o�Ɍ`��ID
    iv_date_from            IN  VARCHAR2,         --  8.�o�ɓ�From
    iv_date_to              IN  VARCHAR2,         --  9.�o�ɓ�To
    iv_forwarder_id         IN  VARCHAR2          -- 10.�^���Ǝ�ID
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
    -- ���O�o�̓t���O�ݒ�
    set_debug_switch();
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
debug_log(FND_FILE.LOG,'MAIN');
debug_log(FND_FILE.LOG,'�T�u���C���ďo');
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_prod_class           => iv_prod_class,          --  1.���i�敪
      iv_shipping_biz_type    => iv_shipping_biz_type,   --  2.�������
      iv_block_1              => iv_block_1,             --  3.�u���b�N1
      iv_block_2              => iv_block_2,             --  4.�u���b�N2
      iv_block_3              => iv_block_3,             --  5.�u���b�N3
      iv_storage_code         => iv_storage_code,        --  6.�o�Ɍ�
      iv_transaction_type_id  => iv_transaction_type_id, --  7.�o�Ɍ`��ID
      iv_date_from            => iv_date_from,           --  8.�o�ɓ�From
      iv_date_to              => iv_date_to,             --  9.�o�ɓ�To
      iv_forwarder_id         => iv_forwarder_id,        -- 10.�^���Ǝ�ID
      ov_errbuf               => lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode              => lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg               => lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
debug_log(FND_FILE.LOG,'�G���[���b�Z�[�W�o��');
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
debug_log(FND_FILE.LOG,'���^�[���R�[�h�Z�b�g�A�I������');
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
--    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
debug_log(FND_FILE.LOG,'�X�e�[�^�X�o��');
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
-- Ver1.5 M.Hokkanji Start
-- �e���ԃe�[�u���쐬�����ŃR�~�b�g����ꂽ���߃��[���o�b�N�����s����悤�ɕύX
--  (�z�Ԕz���v��쐬��������͍폜��ɃG���[�ƂȂ����ꍇ�Ƀ��[���o�b�N���邽��
-- �e�X�g����ROLLBACK�̓R�����g�A�E�g***************************************************
    --COMMIT;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
-- Ver1.5 M.Hokkanji End
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
END xxwsh600001c;
/
