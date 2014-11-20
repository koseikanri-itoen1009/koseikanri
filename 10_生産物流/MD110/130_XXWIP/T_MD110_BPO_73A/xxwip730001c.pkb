CREATE OR REPLACE PACKAGE BODY xxwip730001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip730001a(spec)
 * Description      : �x���^���f�[�^�����쐬
 * MD.050           : �^���v�Z�i�g�����U�N�V�����j T_MD050_BPO_730
 * MD.070           : �x���^���f�[�^�����쐬 T_MD070_BPO_73A
 * Version          : 1.23
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  chk_param_proc         �p�����[�^�`�F�b�N����(A-1)
 *  get_init               �֘A�f�[�^�擾(A-2) �^���p�������擾(A-3)
 *  get_deliv_lock         ���b�N�擾(A-4)
 *  get_delivmst_lock      ���b�N�擾(�^���֘A�}�X�^)   2009/04/07 add
 *
 *  get_order              �󒍎��я�񒊏o(A-5)
 *  get_order_other        �󒍊֘A��񒊏o
 *    get_order_ship         �󒍔z���敪���VIEW���o(A-6)
 *    get_order_distance     �󒍔z�������A�h�I���}�X�^���o(A-7)
 *    get_order_company      �󒍉^���p�^���Ǝ҃A�h�I���}�X�^���o(A-8)
 *
 *  get_order_line         �󒍖��׃A�h�I�����o(A-9)
 *    get_order_line_item    ��OPM�i�ڏ��VIEW���o(A-10)
 *    get_order_line_calc    �󒍌�/���ʎZ�o(A-11)
 *    get_order_line_sum     �󒍌�/���ʏW�v(A-12)
 *  set_order_deliv_line   �󒍉^�����׃A�h�I��PL/SQL�\�i�[(A-13)
 *
 *  get_move               �ړ����я�񒊏o(A-14)
 *  get_move_other         �ړ��֘A��񒊏o
 *    get_move_ship          �ړ��z���敪���VIEW���o(A-15)
 *    get_move_distance      �ړ��z�������A�h�I���}�X�^���o(A-16)
 *    get_move_company       �ړ��^���p�^���Ǝ҃A�h�I���}�X�^���o(A-17)
 *
 *  get_move_line          �ړ����׃A�h�I�����o(A-18)
 *    get_move_line_item     �ړ�OPM�i�ڏ��VIEW���o(A-19)
 *    get_move_line_calc     �ړ���/���ʎZ�o(A-20)
 *    get_move_line_sum      �ړ���/���ʏW�v(A-21)
 *  set_move_deliv_line    �ړ��^�����׃A�h�I��PL/SQL�\�i�[(A-22)
 *
 *  insert_deliv_line      �^�����׃A�h�I���ꊇ�o�^(A-23)
 *  update_deliv_line_calc �^�����׃A�h�I���ꊇ�Čv�Z�X�V(A-24)
 *  update_deliv_line_desc �^�����׃A�h�I���ꊇ�K�p�X�V(A-25)
 *
 *  get_carcan_req_no         �z�ԉ����Ώۈ˗�No���o(A-25-1)
 *  get_carcan_deliv_no       �z�ԉ����z��No���o(A-25-2)
 *  delete_carcan_req_no      �z�ԉ����˗�No�폜(A-25-3)
 *  check_carcan_deliv_no     �z�ԉ����z��No���݊m�F(A-25-4)
 *  update_carcan_deliv_line  �z�ԉ����^�����׃A�h�I���X�V(A-25-4)
 *  delete_carcan_deliv_head  �z�ԉ����^���w�b�_�A�h�I���폜(A-25-5)
 *
 *  get_delinov_line_desc  �^�����׃A�h�I���Ώ۔z��No���o(A-26)
 *  get_deliv_line         �^�����׃A�h�I�����o(A-27)
 *    get_deliv_mix_calc     �^�����׍��ڐ��Z�o(A-28)
 *    get_deliv_fare_calc    �^���Z�o(A-29)
 *  set_deliv_head         �^���w�b�_�A�h�I��PL/SQL�\�i�[(A-30)
 *
 *  get_carriers_schedule  �z�Ԕz���v�撊�o(A-31)
 *     �~set_carri_deliv_head   �z�Ԃ̂݉^���w�b�_�A�h�I��PL/SQL�\�i�[(A-32)
 *  set_carri_deliv_head   �`�[�Ȃ��z��PL/SQL�\�i�[
 *
 *  insert_deliv_head      �^���w�b�_�A�h�I���ꊇ�o�^(A-33)
 *  update_deliv_head      �^���w�b�_�A�h�I���ꊇ�X�V(A-34)
 *  delete_deliv_head      �^���w�b�_�A�h�I���ꊇ�폜(A-35)
 *  update_deliv_cntl      �^���v�Z�R���g���[���X�V����(A-36)
 *
 *  get_exch_deliv_line    ���։^�����׃A�h�I�����o(A-37)
 *  set_exch_deliv_line    ���։^�����׃A�h�I��PL/SQL�\�i�[(A-38)
 *  update_exch_deliv_line ���։^�����׃A�h�I���ꊇ�X�V(A-39)
 *
 *  get_exch_delino        ���։^�����׃A�h�I���Ώ۔z��No���o(A-40)
 *  get_exch_deliv_line_h  ���։^�����׃A�h�I�����o(A-41)
 *  set_exch_deliv_head_h  ���։^���w�b�_�A�h�I�����׍��ڍX�V�pPL/SQL�\�i�[(A-42)
 *
 *  update_exch_deliv_head_h ���։^���w�b�_�A�h�I�����׍��ڈꊇ�X�V(A-43)
 *
 *  get_exch_deliv_other   �^���w�b�_�֘A ���o
 *    get_exch_deliv_head    ���։^���w�b�_�A�h�I�����o(A-44)
 *    get_exch_deliv_charg   ���։^���A�h�I���}�X�^���o(A-45)
 *  set_exch_deliv_hate    ���։^���w�b�_�A�h�I��PL/SQL�\�i�[(A-46)
 *
 *  update_exch_deliv_head ���։^���A�h�I���}�X�^�ꊇ�X�V(A-47)
 *  delete_exch_deliv_head ���։^���A�h�I���}�X�^�ꊇ�폜(A-48)
 *  delete_exch_deliv_mst  ���։^���}�X�^�ꊇ�X�V    2009/04/07 add
 *
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/01    1.0  Oracle �쑺       ����쐬
 *  2008/05/27    1.1  Oracle �쑺       ������Q ���ڏ���
 *  2008/06/25    1.2  Oracle �쑺       TE080�w�E���� ���f
 *  2008/07/15    1.3  Oracle �쑺       ST��Q#452�Ή��i�؏�Ή��܂ށj
 *  2008/07/16    1.4  Oracle �쑺       ST��Q#455�Ή�
 *  2008/07/17    1.5  Oracle �쑺       �ύX�v��#96�A#98�Ή�
 *  2008/08/04    1.6  Oracle �R��       �����ۑ�#187�Ή�
 *  2008/08/25    1.7  Oracle �쑺       ST���O�m�F��Q
 *  2008/09/12    1.8  Oracle �쑺       TE080�w�E����15�Ή� �敪�ݒ茩���Ή�
 *  2008/10/21    1.9  Oracle �쑺       T_S_572 ����#392�Ή�
 *  2008/10/27    1.10 Oracle �쑺       ����#436�Ή�
 *  2008/10/31    1.11 Oracle �쑺       ����#531�Ή�
 *  2008/11/07    1.12 Oracle �쑺       ����#584�Ή�
 *  2008/11/25    1.13 Oracle �g�c       �{��#104�Ή�
 *  2008/11/28    1.14 Oracle �Ŗ�       �{��#201�Ή�
 *  2008/12/09    1.15 Oracle �쑺       �{��#595�Ή�
 *  2008/12/10    1.16 Oracle �쑺       �{��#401�Ή�
 *  2008/12/24    1.17 Oracle �쑺       �{��#323�Ή�
 *  2008/12/26    1.18 Oracle �쑺       �{��#323�Ή��i���O�Ή��j
 *  2008/12/29    1.19 Oracle �쑺       �{��#882�Ή�
 *  2009/01/23    1.20 Oracle �쑺       �{��#1074�Ή�
 *  2009/02/03    1.21 Oracle �쑺       �{��#1017�Ή�
 *  2009/02/09    1.22 Oracle �쑺       �{��#1017�Ή�
 *  2009/04/07    1.23 Oracle �쑺       �{��#432�Ή�
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
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 START #####
  func_inv_expt              EXCEPTION;
  PRAGMA EXCEPTION_INIT(func_inv_expt, -20001);    -- �t�@���N�V�����G���[
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 END   #####
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name                 CONSTANT VARCHAR2(100) := 'xxwip730001c'; -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  gv_xxcmn_msg_kbn            CONSTANT VARCHAR2(5) := 'XXCMN';
  gv_xxwip_msg_kbn            CONSTANT VARCHAR2(5) := 'XXWIP';
--
  -- �v���t�@�C��
  gv_prof_debug_flg   CONSTANT VARCHAR2(50) := 'XXWIP_730001C_DEBUG';  -- �v���t�@�C���F�f�o�b�O�t���O
  gv_debug_on         CONSTANT VARCHAR2(1) := '1';  -- �f�o�b�O ON
  gv_debug_off        CONSTANT VARCHAR2(1) := '0';  -- �f�o�b�O OFF
--
  -- ���b�Z�[�W�ԍ�(XXCMN)
  gv_xxcmn_msg_okcnt          CONSTANT VARCHAR2(15) := 'APP-XXCMN-00009'; -- ��������
  gv_xxcmn_msg_notfnd         CONSTANT VARCHAR2(15) := 'APP-XXCMN-10001'; -- �Ώۃf�[�^�Ȃ�
  gv_xxcmn_msg_toomny         CONSTANT VARCHAR2(15) := 'APP-XXCMN-10137'; -- �Ώۃf�[�^������
  gv_xxcmn_msg_para           CONSTANT VARCHAR2(15) := 'APP-XXCMN-10010'; -- �p�����[�^�G���[
  gv_xxcom_noprof_err         CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002'; -- �v���t�@�C���擾�G���[
  gv_xxwip_msg_lock_err       CONSTANT VARCHAR2(15) := 'APP-XXWIP-10029'; -- �e�[�u�����b�N�G���[
  gv_xxwip_msg_deliv_line     CONSTANT VARCHAR2(15) := 'APP-XXWIP-00009'; -- �^�����׃A�h�I����������
  gv_xxwip_msg_deliv_ins      CONSTANT VARCHAR2(15) := 'APP-XXWIP-00010'; -- �^���w�b�_�A�h�I����������
  gv_xxwip_msg_deliv_del      CONSTANT VARCHAR2(15) := 'APP-XXWIP-00011'; -- �^���w�b�_�A�h�I���폜����
--
  -- ���b�Z�[���e�i���́j
  gv_deliverys_ctrl           CONSTANT VARCHAR2(50) := '�^���v�Z�p�R���g���[���A�h�I��';
  gv_exchange_type            CONSTANT VARCHAR2(50) := '���֋敪';
  gv_deliverys                CONSTANT VARCHAR2(50) := '�^���w�b�_�A�h�I��';
  gv_delivery_lines           CONSTANT VARCHAR2(50) := '�^�����׃A�h�I��';
  gv_item_mst2_v              CONSTANT VARCHAR2(50) := 'OPM�i�ڏ��VIEW2';
  gv_order_headers_all        CONSTANT VARCHAR2(50) := '�󒍖��׃A�h�I��';
  gv_mov_req_instr_lines      CONSTANT VARCHAR2(50) := '�ړ��˗�/�w�����׃A�h�I��';
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
  gv_delivery_company         CONSTANT VARCHAR2(50) := '�^���p�^���Ǝ҃}�X�^';
  gv_delivery_distance        CONSTANT VARCHAR2(50) := '�z�������}�X�^';
  gv_delivery_charges         CONSTANT VARCHAR2(50) := '�^���}�X�^';
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
--
  -- �g�[�N��
  gv_tkn_parameter            CONSTANT VARCHAR2(10) := 'PARAMETER';
  gv_tkn_value                CONSTANT VARCHAR2(10) := 'VALUE';
  gv_tkn_table                CONSTANT VARCHAR2(10) := 'TABLE';
  gv_tkn_key                  CONSTANT VARCHAR2(10) := 'KEY';
  gv_tkn_cnt                  CONSTANT VARCHAR2(10) := 'CNT';
  gv_tkn_ng_profile           CONSTANT VARCHAR2(10) := 'NG_PROFILE';
--
  -- �Ώ�_�ΏۊO�敪
  gv_target_y                 CONSTANT VARCHAR2(1) := '1';
  gv_target_n                 CONSTANT VARCHAR2(1) := '0';
  -- YESNO�敪
  gv_ktg_yes                  CONSTANT VARCHAR2(1) := 'Y';
  gv_ktg_no                   CONSTANT VARCHAR2(1) := 'N';
--
  -- �R���J�����gNo(�^���v�Z�p�R���g���[��)
  gv_con_no_deliv             CONSTANT VARCHAR2(1) := '1';  -- 1:�x���^���f�[�^�����쐬
  -- �x�������敪
  gv_pay                      CONSTANT VARCHAR2(1) := '1';  -- 1:�x��
  gv_claim                    CONSTANT VARCHAR2(1) := '2';  -- 2:����
  -- ���i�敪
  gv_prod_class_lef           CONSTANT VARCHAR2(1) := '1';  -- 1:���[�t
  gv_prod_class_drk           CONSTANT VARCHAR2(1) := '2';  -- 2:�h�����N
  -- �����敪
  gv_small_sum_yes            CONSTANT VARCHAR2(1) := '1';  -- 1:����
  gv_small_sum_no             CONSTANT VARCHAR2(1) := '0';  -- 0:�ԗ�
  -- �x�����f�敪
  gv_pay_judg_g               CONSTANT VARCHAR2(1) := '1';  -- 1:����
  gv_pay_judg_c               CONSTANT VARCHAR2(1) := '2';  -- 2:����
  -- �o�׎x���敪
  gv_shipping                 CONSTANT VARCHAR2(1) := '1';  -- 1:�o�׎w��
  gv_shikyu                   CONSTANT VARCHAR2(1) := '2';  -- 2:�x���˗�
  gv_kuragae                  CONSTANT VARCHAR2(1) := '3';  -- 3:�q�֕ԕi
  -- �d�ʗe�ϋ敪
  gv_weight                   CONSTANT VARCHAR2(1) := '1';  -- 1:�d��
  gv_capacity                 CONSTANT VARCHAR2(1) := '2';  -- 2:�e��
  -- �R�[�h�敪
  gv_code_move                CONSTANT VARCHAR2(1) := '1';  -- 1:�q��
  gv_code_shikyu              CONSTANT VARCHAR2(1) := '2';  -- 2:�����
  gv_code_ship                CONSTANT VARCHAR2(1) := '3';  -- 3:�z����
  -- �^�C�v�i������ʁi�z�ԁj�Ɠ����j
  gv_type_ship                CONSTANT VARCHAR2(1) := '1';  -- 1:�o��
  gv_type_shikyu              CONSTANT VARCHAR2(1) := '2';  -- 2:�x��
  gv_type_move                CONSTANT VARCHAR2(1) := '3';  -- 3:�ړ�
--
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 START #####
--
  -- �z�ԃ^�C�v
  gv_car_normal               CONSTANT VARCHAR2(1) := '1';  -- 1:�ʏ�z��
  gv_carcan_target_y          CONSTANT VARCHAR2(1) := '2';  -- 2:�`�[�Ȃ��z�ԁi���[�t�����j
  gv_carcan_target_n          CONSTANT VARCHAR2(1) := '3';  -- 3:�`�[�Ȃ��z�ԁi���[�t�����ȊO�j
--
  -- �`�[�Ȃ��z�ԋ敪
  gv_non_slip_nml             CONSTANT VARCHAR2(1) := '1';  -- 1:�ʏ�z��
  gv_non_slip_slp             CONSTANT VARCHAR2(1) := '2';  -- 2:�`�[�Ȃ��z��
  gv_non_slip_can             CONSTANT VARCHAR2(1) := '3';  -- 3:�`�[�Ȃ��z�ԉ���
--
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 END   #####
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- *****************************
  -- * �󒍎��� �֘A
  -- *****************************
  -- �󒍎��я�� ���o����
  TYPE order_inf_rec IS RECORD(
      order_header_id               xxwsh_order_headers_all.order_header_id%TYPE              -- �󒍃w�b�_�A�h�I��ID
    , request_no                    xxwsh_order_headers_all.request_no%TYPE                   -- �˗�No
    , slip_number                   xxwsh_order_headers_all.slip_number%TYPE                  -- �����No
    , delivery_no                   xxwsh_order_headers_all.delivery_no%TYPE                  -- �z��No
    , result_freight_carrier_code   xxwsh_order_headers_all.result_freight_carrier_code%TYPE  -- �^���Ǝ�_����
    , deliver_from                  xxwsh_order_headers_all.deliver_from%TYPE                 -- �o�׌��ۊǏꏊ
    , result_shipping_method_code   xxwsh_order_headers_all.result_shipping_method_code%TYPE  -- �z���敪_����
    , deliver_to_code_class         VARCHAR2(1)                                               -- �z����R�[�h�敪
    , result_deliver_to             xxwsh_order_headers_all.result_deliver_to%TYPE            -- �o�א�_����
    , payments_judgment_classe      xxwip_delivery_company.payments_judgment_classe%TYPE      -- �x�����f�敪(�^��)
    , shipped_date                  xxwsh_order_headers_all.shipped_date%TYPE                 -- �o�ד�
    , arrival_date                  xxwsh_order_headers_all.arrival_date%TYPE                 -- ���ד�
    , judgement_date                DATE                                                      -- ���f��
    , prod_class                    xxwsh_order_headers_all.prod_class%TYPE                   -- ���i�敪
    , weight_capacity_class         xxwsh_order_headers_all.weight_capacity_class%TYPE        -- �d�ʗe�ϋ敪
    , small_quantity                xxwsh_order_headers_all.small_quantity%TYPE               -- ������
    , order_type                    VARCHAR2(1)                                               -- �^�C�v
    , no_cont_freight_class         xxwsh_order_headers_all.no_cont_freight_class%TYPE        -- �_��O�^���敪
    , transfer_location_code        xxwsh_order_headers_all.transfer_location_code%TYPE       -- �U�֐�
    , shipping_instructions         VARCHAR2(40)                                              -- �o�׎w��(40)
    , small_amount_class            xxwsh_ship_method_v.small_amount_class%TYPE               -- �z���敪�F�����敪
    , mixed_class                   xxwsh_ship_method_v.mixed_class%TYPE                      -- �z���敪�F���ڋ敪
    , ref_small_amount_class        VARCHAR2(1)                                               -- �z���敪�F���[�t�����敪
    , post_distance                 xxwip_delivery_distance.post_distance%TYPE                -- �z�������F�ԗ�����
    , small_distance                xxwip_delivery_distance.small_distance%TYPE               -- �z�������F��������
    , consolid_add_distance         xxwip_delivery_distance.consolid_add_distance%TYPE        -- �z�������F���ڊ�������
    , actual_distance               xxwip_delivery_distance.actual_distance%TYPE              -- �z�������F���ۋ���
    , small_weight                  xxwip_delivery_company.small_weight%TYPE                  -- �^���ƎҁF�����d��
    , pay_picking_amount            xxwip_delivery_company.pay_picking_amount%TYPE            -- �^���ƎҁF�x���s�b�L���O�P��
    , qty                           xxwip_deliverys.qty1%TYPE                                 -- ��
    , delivery_weight               xxwip_deliverys.delivery_weight1%TYPE                     -- �d��
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
    , sum_pallet_weight             xxwsh_order_headers_all.sum_pallet_weight%TYPE            -- ���v�p���b�g�d��
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
  );
--
  -- �Ώۃf�[�^�����i�[����e�[�u���^�̒�`
  TYPE order_inf_tbl IS TABLE OF order_inf_rec INDEX BY PLS_INTEGER;
  gt_order_inf_tab   order_inf_tbl;
--
  -- �󒍖��׏�� ���o����
  TYPE order_line_inf_rec IS RECORD(
      order_header_id               xxwsh_order_lines_all.order_header_id%TYPE      -- �󒍃w�b�_�A�h�I��ID
    , shipping_item_code            xxwsh_order_lines_all.shipping_item_code%TYPE   -- �o�וi��
    , shipped_quantity              xxwsh_order_lines_all.shipped_quantity%TYPE     -- �o�׎��ѐ���
  );
  TYPE order_line_inf_tbl IS TABLE OF order_line_inf_rec INDEX BY PLS_INTEGER;
--
  -- *****************************
  -- * �ړ����� �֘A
  -- *****************************
  -- �ړ����я�� ���o����
  TYPE move_inf_rec IS RECORD(
      mov_hdr_id                    xxinv_mov_req_instr_headers.mov_hdr_id%TYPE                   -- �ړ��w�b�_ID
    , mov_num                       xxinv_mov_req_instr_headers.mov_num%TYPE                      -- �ړ��ԍ�
    , slip_number                   xxinv_mov_req_instr_headers.slip_number%TYPE                  -- �����No
    , delivery_no                   xxinv_mov_req_instr_headers.delivery_no%TYPE                  -- �z��No
    , actual_freight_carrier_code   xxinv_mov_req_instr_headers.actual_freight_carrier_code%TYPE  -- �^���Ǝ�_����
    , shipped_locat_code            xxinv_mov_req_instr_headers.shipped_locat_code%TYPE           -- �o�Ɍ��ۊǏꏊ
    , shipping_method_code          xxinv_mov_req_instr_headers.shipping_method_code%TYPE         -- �z���敪
    , deliver_to_code_class         VARCHAR2(1)                                                   -- �z����R�[�h�敪
    , ship_to_locat_code            xxinv_mov_req_instr_headers.ship_to_locat_code%TYPE           -- ���ɐ�ۊǏꏊ
    , payments_judgment_classe      xxwip_delivery_company.payments_judgment_classe%TYPE          -- �x�����f�敪(�^��)
    , actual_ship_date              xxinv_mov_req_instr_headers.actual_ship_date%TYPE             -- �o�Ɏ��ѓ�
    , actual_arrival_date           xxinv_mov_req_instr_headers.actual_arrival_date%TYPE          -- ���Ɏ��ѓ�
    , judgement_date                DATE                                                          -- ���f��
    , item_class                    xxinv_mov_req_instr_headers.item_class%TYPE                   -- ���i�敪
    , weight_capacity_class         xxinv_mov_req_instr_headers.weight_capacity_class%TYPE        -- �d�ʗe�ϋ敪
    , small_quantity                xxinv_mov_req_instr_headers.small_quantity%TYPE               -- ������
    , sum_quantity                  xxinv_mov_req_instr_headers.sum_quantity%TYPE                 -- ���v����
    , order_type                    VARCHAR2(1)                                                   -- �^�C�v
    , no_cont_freight_class         xxinv_mov_req_instr_headers.no_cont_freight_class%TYPE        -- �_��O�^���敪
    , transfer_location_code        VARCHAR2(4)                                                   -- �U�֐�
    , description                   VARCHAR2(40)                                                  -- �E�v
    , small_amount_class            xxwsh_ship_method_v.small_amount_class%TYPE               -- �z���敪�F�����敪
    , mixed_class                   xxwsh_ship_method_v.mixed_class%TYPE                      -- �z���敪�F���ڋ敪
    , ref_small_amount_class        VARCHAR2(1)                                               -- �z���敪�F���[�t�����敪
    , post_distance                 xxwip_delivery_distance.post_distance%TYPE                -- �z�������F�ԗ�����
    , small_distance                xxwip_delivery_distance.small_distance%TYPE               -- �z�������F��������
    , consolid_add_distance         xxwip_delivery_distance.consolid_add_distance%TYPE        -- �z�������F���ڊ�������
    , actual_distance               xxwip_delivery_distance.actual_distance%TYPE              -- �z�������F���ۋ���
    , small_weight                  xxwip_delivery_company.small_weight%TYPE                  -- �^���ƎҁF�����d��
    , pay_picking_amount            xxwip_delivery_company.pay_picking_amount%TYPE            -- �^���ƎҁF�x���s�b�L���O�P��
    , qty                           xxwip_deliverys.qty1%TYPE                                 -- ��
    , delivery_weight               xxwip_deliverys.delivery_weight1%TYPE                     -- �d��
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
    , sum_pallet_weight             xxinv_mov_req_instr_headers.sum_pallet_weight%TYPE        -- ���v�p���b�g�d��
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
  );
--
  -- �Ώۃf�[�^�����i�[����e�[�u���^�̒�`
  TYPE move_inf_tbl IS TABLE OF move_inf_rec INDEX BY PLS_INTEGER;
  gt_move_inf_tab   move_inf_tbl;
--
  -- �ړ��˗�/�w�����׏�� ���o����
  TYPE move_line_inf_rec IS RECORD(
      mov_hdr_id                  xxinv_mov_req_instr_lines.mov_hdr_id%TYPE         -- �ړ��w�b�_ID
    , item_id                     xxinv_mov_req_instr_lines.item_id%TYPE            -- OPM�i��ID
    , shipped_quantity            xxinv_mov_req_instr_lines.shipped_quantity%TYPE   -- �o�׎��ѐ���
  );
  TYPE move_line_inf_tbl IS TABLE OF move_line_inf_rec INDEX BY PLS_INTEGER;
--
  -- *****************************
  -- * �^�����׃A�h�I�� �֘A
  -- *****************************
  -- �^�����׃A�h�I�� �z��No ���o����
  TYPE delivno_deliv_line_rec IS RECORD(
      delivery_no         xxwip_delivery_lines.delivery_no%TYPE       -- �z��No
    , distance            xxwip_delivery_lines.actual_distance%TYPE   -- �Œ������i�ő�j
    , qty                 xxwip_delivery_lines.qty%TYPE               -- ���i���v�j
    , delivery_weight     xxwip_delivery_lines.delivery_weight%TYPE   -- �d�ʁi���v�j
  );
  TYPE delivno_deliv_line_tbl IS TABLE OF delivno_deliv_line_rec INDEX BY PLS_INTEGER;
  gt_delivno_deliv_line_tab   delivno_deliv_line_tbl;
--
  -- �^�����׃A�h�I�� ���o����
  TYPE deliv_line_rec IS RECORD(
      delivery_company_code       xxwip_delivery_lines.delivery_company_code%TYPE   -- �^���Ǝ�
    , delivery_no                 xxwip_delivery_lines.delivery_no%TYPE             -- �z��No
    , invoice_no                  xxwip_delivery_lines.invoice_no%TYPE              -- �����No
    , payments_judgment_classe    xxwip_delivery_lines.payments_judgment_classe%TYPE-- �x�����f�敪
    , ship_date                   xxwip_delivery_lines.ship_date%TYPE               -- �o�ɓ�
    , arrival_date                xxwip_delivery_lines.arrival_date%TYPE            -- ������
    , judgement_date              xxwip_delivery_lines.judgement_date%TYPE          -- ���f��
    , goods_classe                xxwip_delivery_lines.goods_classe%TYPE            -- ���i�敪
    , mixed_code                  xxwip_delivery_lines.mixed_code%TYPE              -- ���ڋ敪
    , dellivary_classe            xxwip_delivery_lines.dellivary_classe%TYPE        -- �z���敪
    , whs_code                    xxwip_delivery_lines.whs_code%TYPE                -- ��\�o�ɑq�ɃR�[�h
    , code_division               xxwip_delivery_lines.code_division%TYPE           -- ��\�z����R�[�h�敪
    , shipping_address_code       xxwip_delivery_lines.shipping_address_code%TYPE   -- ��\�z����R�[�h
    , order_type                  xxwip_delivery_lines.order_type%TYPE              -- ��\�^�C�v
    , weight_capacity_class       xxwip_delivery_lines.weight_capacity_class%TYPE   -- �d�ʗe�ϋ敪
    , actual_distance             xxwip_delivery_lines.actual_distance%TYPE         -- �Œ����ۋ���
    , outside_contract            xxwip_delivery_lines.outside_contract%TYPE        -- �_��O�敪
    , description                 xxwip_delivery_lines.description%TYPE             -- �U�֐�
    , consolid_qty                xxwip_deliverys.consolid_qty%TYPE                 -- ���ڐ�
    , small_weight                xxwip_delivery_company.small_weight%TYPE          -- �����d��
    , pay_picking_amount          xxwip_delivery_company.pay_picking_amount%TYPE    -- �x���s�b�L���O�P��
    , shipping_expenses           xxwip_delivery_charges.shipping_expenses%TYPE     -- �^����
    , leaf_consolid_add           xxwip_delivery_charges.leaf_consolid_add%TYPE     -- ���[�t���ڊ���
    , consolid_surcharge          xxwip_deliverys.consolid_surcharge%TYPE           -- ���ڊ������z
    , picking_charge              xxwip_deliverys.picking_charge%TYPE               -- �s�b�L���O��
  );
--
  TYPE deliv_line_tbl IS TABLE OF deliv_line_rec INDEX BY PLS_INTEGER;
  gt_deliv_line_tab   deliv_line_tbl;
--
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 START #####
--
  -- �z�ԉ����Ώۃf�[�^ ���o����
  TYPE carcan_info_rec IS RECORD(
      results_type    VARCHAR2(1)                              -- �^�C�v
    , request_no      xxwsh_order_headers_all.request_no%TYPE  -- �˗�No�i�ړ��ԍ��j
  );
--
  --  �z�ԉ����Ώۃf�[�^�����i�[����e�[�u���^�̒�`
  TYPE carcan_info_tbl IS TABLE OF carcan_info_rec INDEX BY PLS_INTEGER;
  gt_carcan_info_tab   carcan_info_tbl;
--
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 END   #####
--
  -- PL/SQL�\�^
  -- �^�����׃A�h�I��ID
  TYPE line_deliv_lines_id_type   IS TABLE OF xxwip_delivery_lines.delivery_lines_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- �˗�No
  TYPE line_request_no_type       IS TABLE OF xxwip_delivery_lines.request_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- �����No
  TYPE line_invoice_no_type       IS TABLE OF xxwip_delivery_lines.invoice_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- �z��No
  TYPE line_deliv_no_type         IS TABLE OF xxwip_delivery_lines.delivery_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���[�t�����敪
  TYPE line_small_lot_cls_type    IS TABLE OF xxwip_delivery_lines.small_lot_class%TYPE
  INDEX BY BINARY_INTEGER;
  -- �^���Ǝ�
  TYPE line_deliv_cmpny_cd_type   IS TABLE OF xxwip_delivery_lines.delivery_company_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- �o�ɑq�ɃR�[�h
  TYPE line_whs_code_type         IS TABLE OF xxwip_delivery_lines.whs_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- �z���敪
  TYPE line_delliv_cls_type       IS TABLE OF xxwip_delivery_lines.dellivary_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- �z����R�[�h�敪
  TYPE line_code_division_type    IS TABLE OF xxwip_delivery_lines.code_division%TYPE
  INDEX BY BINARY_INTEGER;
  -- �z����R�[�h
  TYPE line_ship_addr_cd_type     IS TABLE OF xxwip_delivery_lines.shipping_address_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- �x�����f�敪
  TYPE line_pay_judg_cls_type     IS TABLE OF xxwip_delivery_lines.payments_judgment_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- �o�ɓ�
  TYPE line_ship_date_type        IS TABLE OF xxwip_delivery_lines.ship_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- ������
  TYPE line_arrival_date_type     IS TABLE OF xxwip_delivery_lines.arrival_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- �񍐓�
  TYPE line_report_date_type      IS TABLE OF xxwip_delivery_lines.report_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���f��
  TYPE line_judg_date_type        IS TABLE OF xxwip_delivery_lines.judgement_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���i�敪
  TYPE line_goods_cls_type        IS TABLE OF xxwip_delivery_lines.goods_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- �d�ʗe�ϋ敪
  TYPE line_weight_cap_cls_type   IS TABLE OF xxwip_delivery_lines.weight_capacity_class%TYPE
  INDEX BY BINARY_INTEGER;
  -- ����
  TYPE line_ditnc_type            IS TABLE OF xxwip_delivery_lines.distance%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���ۋ���
  TYPE line_actual_dstnc_type     IS TABLE OF xxwip_delivery_lines.actual_distance%TYPE
  INDEX BY BINARY_INTEGER;
  -- ��
  TYPE line_qty_type              IS TABLE OF xxwip_delivery_lines.qty%TYPE
  INDEX BY BINARY_INTEGER;
  -- �d��
  TYPE line_deliv_weight_type     IS TABLE OF xxwip_delivery_lines.delivery_weight%TYPE
  INDEX BY BINARY_INTEGER;
  -- �^�C�v
  TYPE line_order_type_type       IS TABLE OF xxwip_delivery_lines.order_type%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���ڋ敪
  TYPE line_mixed_code_type       IS TABLE OF xxwip_delivery_lines.mixed_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- �_��O�敪
  TYPE line_outside_cntrct_type   IS TABLE OF xxwip_delivery_lines.outside_contract%TYPE
  INDEX BY BINARY_INTEGER;
  -- �U�֐�
  TYPE line_trans_locat_type      IS TABLE OF xxwip_delivery_lines.transfer_location%TYPE
  INDEX BY BINARY_INTEGER;
  -- �E�v
  TYPE line_description_type      IS TABLE OF xxwip_delivery_lines.description%TYPE
  INDEX BY BINARY_INTEGER;
--
  -- �^�����׃A�h�I�� �o�^�p�ϐ���`
  i_line_deliv_lines_id_tab   line_deliv_lines_id_type;     -- �^�����׃A�h�I��ID
  i_line_request_no_tab       line_request_no_type;         -- �˗�No
  i_line_invoice_no_tab       line_invoice_no_type;         -- �����No
  i_line_deliv_no_tab         line_deliv_no_type;           -- �z��No
  i_line_small_lot_cls_tab    line_small_lot_cls_type;      -- ���[�t�����敪
  i_line_deliv_cmpny_cd_tab   line_deliv_cmpny_cd_type;     -- �^���Ǝ�
  i_line_whs_code_tab         line_whs_code_type;           -- �o�ɑq�ɃR�[�h
  i_line_delliv_cls_tab       line_delliv_cls_type;         -- �z���敪
  i_line_code_division_tab    line_code_division_type;      -- �z����R�[�h�敪
  i_line_ship_addr_cd_tab     line_ship_addr_cd_type;       -- �z����R�[�h
  i_line_pay_judg_cls_tab     line_pay_judg_cls_type;       -- �x�����f�敪
  i_line_ship_date_tab        line_ship_date_type;          -- �o�ɓ�
  i_line_arrival_date_tab     line_arrival_date_type;       -- ������
  i_line_report_date_tab      line_report_date_type;        -- �񍐓�
  i_line_judg_date_tab        line_judg_date_type;          -- ���f��
  i_line_goods_cls_tab        line_goods_cls_type;          -- ���i�敪
  i_line_weight_cap_cls_tab   line_weight_cap_cls_type;     -- �d�ʗe�ϋ敪
  i_line_ditnc_tab            line_ditnc_type;              -- ����
  i_line_actual_dstnc_tab     line_actual_dstnc_type;       -- ���ۋ���
  i_line_qty_tab              line_qty_type;                -- ��
  i_line_deliv_weight_tab     line_deliv_weight_type;       -- �d��
  i_line_order_tab_tab        line_order_type_type;         -- �^�C�v
  i_line_mixed_code_tab       line_mixed_code_type;         -- ���ڋ敪
  i_line_outside_cntrct_tab   line_outside_cntrct_type;     -- �_��O�敪
  i_line_trans_locat_tab      line_trans_locat_type;        -- �U�֐�
  i_line_description_tab      line_description_type;        -- �E�v
--
  -- �^�����׃A�h�I�� �Čv�Z�X�V�p�ϐ���`
  us_line_request_no_tab       line_request_no_type;         -- �˗�No
  us_line_invoice_no_tab       line_invoice_no_type;         -- �����No
  us_line_deliv_no_tab         line_deliv_no_type;           -- �z��No
  us_line_small_lot_cls_tab    line_small_lot_cls_type;      -- ���[�t�����敪
  us_line_deliv_cmpny_cd_tab   line_deliv_cmpny_cd_type;     -- �^���Ǝ�
  us_line_whs_code_tab         line_whs_code_type;           -- �o�ɑq�ɃR�[�h
  us_line_delliv_cls_tab       line_delliv_cls_type;         -- �z���敪
  us_line_code_division_tab    line_code_division_type;      -- �z����R�[�h�敪
  us_line_ship_addr_cd_tab     line_ship_addr_cd_type;       -- �z����R�[�h
  us_line_pay_judg_cls_tab     line_pay_judg_cls_type;       -- �x�����f�敪
  us_line_ship_date_tab        line_ship_date_type;          -- �o�ɓ�
  us_line_arrival_date_tab     line_arrival_date_type;       -- ������
  us_line_judg_date_tab        line_judg_date_type;          -- ���f��
  us_line_goods_cls_tab        line_goods_cls_type;          -- ���i�敪
  us_line_weight_cap_cls_tab   line_weight_cap_cls_type;     -- �d�ʗe�ϋ敪
  us_line_ditnc_tab            line_ditnc_type;              -- ����
  us_line_actual_dstnc_tab     line_actual_dstnc_type;       -- ���ۋ���
  us_line_qty_tab              line_qty_type;                -- ��
  us_line_deliv_weight_tab     line_deliv_weight_type;       -- �d��
  us_line_order_tab_tab        line_order_type_type;         -- �^�C�v
  us_line_mixed_code_tab       line_mixed_code_type;         -- ���ڋ敪
  us_line_outside_cntrct_tab   line_outside_cntrct_type;     -- �_��O�敪
  us_line_trans_locat_tab      line_trans_locat_type;        -- �U�֐�
  us_line_description_tab      line_description_type;        -- �E�v
--
  -- �^�����׃A�h�I�� �E�v�X�V�p�ϐ���`
  ut_line_request_no_tab       line_request_no_type;         -- �˗�No
  ut_line_description_tab      line_description_type;        -- �E�v
--
  -- *****************************
  -- * �^���w�b�_�A�h�I�� �֘A
  -- *****************************
  -- PL/SQL�\�^
  -- �^���w�b�_�[�A�h�I��ID
  TYPE head_deliv_head_id_type        IS TABLE OF xxwip_deliverys.deliverys_header_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- �^���Ǝ�
  TYPE head_deliv_cmpny_cd_type       IS TABLE OF xxwip_deliverys.delivery_company_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- �z��No
  TYPE head_deliv_no_type             IS TABLE OF xxwip_deliverys.delivery_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- �����No
  TYPE head_invoice_no_type           IS TABLE OF xxwip_deliverys.invoice_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- �x�������敪
  TYPE head_p_b_classe_type           IS TABLE OF xxwip_deliverys.p_b_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- �x�����f�敪
  TYPE head_pay_judg_cls_type         IS TABLE OF xxwip_deliverys.payments_judgment_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- �o�ɓ�
  TYPE head_ship_date_type            IS TABLE OF xxwip_deliverys.ship_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- ������
  TYPE head_arrival_date_type         IS TABLE OF xxwip_deliverys.arrival_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- �񍐓�
  TYPE head_report_date_type          IS TABLE OF xxwip_deliverys.report_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���f��
  TYPE head_judg_date_type            IS TABLE OF xxwip_deliverys.judgement_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���i�敪
  TYPE head_goods_cls_type            IS TABLE OF xxwip_deliverys.goods_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���ڋ敪
  TYPE head_mixed_cd_type             IS TABLE OF xxwip_deliverys.mixed_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- �����^��
  TYPE head_charg_amount_type         IS TABLE OF xxwip_deliverys.charged_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- �_��^��
  TYPE head_contract_rate_type        IS TABLE OF xxwip_deliverys.contract_rate%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���z
  TYPE head_balance_type              IS TABLE OF xxwip_deliverys.balance%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���v
  TYPE head_total_amount_type         IS TABLE OF xxwip_deliverys.total_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- ������
  TYPE head_many_rate_type            IS TABLE OF xxwip_deliverys.many_rate%TYPE
  INDEX BY BINARY_INTEGER;
  -- �Œ�����
  TYPE head_distance_type             IS TABLE OF xxwip_deliverys.distance%TYPE
  INDEX BY BINARY_INTEGER;
  -- �z���敪
  TYPE head_deliv_cls_type            IS TABLE OF xxwip_deliverys.delivery_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- ��\�o�ɑq�ɃR�[�h
  TYPE head_whs_cd_type               IS TABLE OF xxwip_deliverys.whs_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- ��\�z����R�[�h�敪
  TYPE head_cd_dvsn_type              IS TABLE OF xxwip_deliverys.code_division%TYPE
  INDEX BY BINARY_INTEGER;
  -- ��\�z����R�[�h
  TYPE head_ship_addr_cd_type         IS TABLE OF xxwip_deliverys.shipping_address_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���P
  TYPE head_qty1_type                 IS TABLE OF xxwip_deliverys.qty1%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���Q
  TYPE head_qty2_type                 IS TABLE OF xxwip_deliverys.qty2%TYPE
  INDEX BY BINARY_INTEGER;
  -- �d�ʂP
  TYPE head_deliv_wght1_type          IS TABLE OF xxwip_deliverys.delivery_weight1%TYPE
  INDEX BY BINARY_INTEGER;
  -- �d�ʂQ
  TYPE head_deliv_wght2_type          IS TABLE OF xxwip_deliverys.delivery_weight2%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���ڊ������z
  TYPE head_cnsld_srhrg_type          IS TABLE OF xxwip_deliverys.consolid_surcharge%TYPE
  INDEX BY BINARY_INTEGER;
  -- �Œ����ۋ���
  TYPE head_actual_ditnc_type         IS TABLE OF xxwip_deliverys.actual_distance%TYPE
  INDEX BY BINARY_INTEGER;
  -- �ʍs��
  TYPE head_cong_chrg_type            IS TABLE OF xxwip_deliverys.congestion_charge%TYPE
  INDEX BY BINARY_INTEGER;
  -- �s�b�L���O��
  TYPE head_pick_charge_type          IS TABLE OF xxwip_deliverys.picking_charge%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���ڐ�
  TYPE head_consolid_qty_type         IS TABLE OF xxwip_deliverys.consolid_qty%TYPE
  INDEX BY BINARY_INTEGER;
  -- ��\�^�C�v
  TYPE head_order_type_type           IS TABLE OF xxwip_deliverys.order_type%TYPE
  INDEX BY BINARY_INTEGER;
  -- �d�ʗe�ϋ敪
  TYPE head_wigh_cpcty_cls_type       IS TABLE OF xxwip_deliverys.weight_capacity_class%TYPE
  INDEX BY BINARY_INTEGER;
  -- �_��O�敪
  TYPE head_out_cont_type             IS TABLE OF xxwip_deliverys.outside_contract%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���ً敪
  TYPE head_output_flag_type          IS TABLE OF xxwip_deliverys.output_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- �x���m��敪
  TYPE head_defined_flag_type         IS TABLE OF xxwip_deliverys.defined_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- �x���m���
  TYPE head_return_flag_type          IS TABLE OF xxwip_deliverys.return_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- ��ʍX�V�L���敪
  TYPE head_fm_upd_flg_type           IS TABLE OF xxwip_deliverys.form_update_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- �U�֐�
  TYPE head_trans_lcton_type          IS TABLE OF xxwip_deliverys.transfer_location%TYPE
  INDEX BY BINARY_INTEGER;
  -- �O���ƎҕύX��
  TYPE head_out_up_cnt_type           IS TABLE OF xxwip_deliverys.outside_up_count%TYPE
  INDEX BY BINARY_INTEGER;
  -- �^���E�v
  TYPE head_description_type          IS TABLE OF xxwip_deliverys.description%TYPE
  INDEX BY BINARY_INTEGER;
--
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 START #####
  -- �z�ԃ^�C�v
  TYPE head_dispatch_type_type        IS TABLE OF xxwip_deliverys.dispatch_type%TYPE
  INDEX BY BINARY_INTEGER;
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 END   #####
--
  -- �^���w�b�_�A�h�I�� �o�^�p�ϐ���`
  i_head_deliv_head_id_tab      head_deliv_head_id_type;   -- �^���w�b�_�[�A�h�I��ID
  i_head_deliv_cmpny_cd_tab     head_deliv_cmpny_cd_type;  -- �^���Ǝ�
  i_head_deliv_no_tab           head_deliv_no_type;        -- �z��No
  i_head_invoice_no_tab         head_invoice_no_type;      -- �����No
  i_head_p_b_classe_tab         head_p_b_classe_type;      -- �x�������敪
  i_head_pay_judg_cls_tab       head_pay_judg_cls_type;    -- �x�����f�敪
  i_head_ship_date_tab          head_ship_date_type;       -- �o�ɓ�
  i_head_arrival_date_tab       head_arrival_date_type;    -- ������
  i_head_report_date_tab        head_report_date_type;     -- �񍐓�
  i_head_judg_date_tab          head_judg_date_type;       -- ���f��
  i_head_goods_cls_tab          head_goods_cls_type;       -- ���i�敪
  i_head_mixed_cd_tab           head_mixed_cd_type;        -- ���ڋ敪
  i_head_charg_amount_tab       head_charg_amount_type;    -- �����^��
  i_head_contract_rate_tab      head_contract_rate_type;   -- �_��^��
  i_head_balance_tab            head_balance_type;         -- ���z
  i_head_total_amount_tab       head_total_amount_type;    -- ���v
  i_head_many_rate_tab          head_many_rate_type;       -- ������
  i_head_distance_tab           head_distance_type;        -- �Œ�����
  i_head_deliv_cls_tab          head_deliv_cls_type;       -- �z���敪
  i_head_whs_cd_tab             head_whs_cd_type;          -- ��\�o�ɑq�ɃR�[�h
  i_head_cd_dvsn_tab            head_cd_dvsn_type;         -- ��\�z����R�[�h�敪
  i_head_ship_addr_cd_tab       head_ship_addr_cd_type;    -- ��\�z����R�[�h
  i_head_qty1_tab               head_qty1_type;            -- ���P
  i_head_qty2_tab               head_qty2_type;            -- ���Q
  i_head_deliv_wght1_tab        head_deliv_wght1_type;     -- �d�ʂP
  i_head_deliv_wght2_tab        head_deliv_wght2_type;     -- �d�ʂQ
  i_head_cnsld_srhrg_tab        head_cnsld_srhrg_type;     -- ���ڊ������z
  i_head_actual_ditnc_tab       head_actual_ditnc_type;    -- �Œ����ۋ���
  i_head_cong_chrg_tab          head_cong_chrg_type;       -- �ʍs��
  i_head_pick_charge_tab        head_pick_charge_type;     -- �s�b�L���O��
  i_head_consolid_qty_tab       head_consolid_qty_type;    -- ���ڐ�
  i_head_order_type_tab         head_order_type_type;      -- ��\�^�C�v
  i_head_wigh_cpcty_cls_tab     head_wigh_cpcty_cls_type;  -- �d�ʗe�ϋ敪
  i_head_out_cont_tab           head_out_cont_type;        -- �_��O�敪
  i_head_output_flag_tab        head_output_flag_type;     -- ���ً敪
  i_head_defined_flag_tab       head_defined_flag_type;    -- �x���m��敪
  i_head_return_flag_tab        head_return_flag_type;     -- �x���m���
  i_head_fm_upd_flg_tab         head_fm_upd_flg_type;      -- ��ʍX�V�L���敪
  i_head_trans_lcton_tab        head_trans_lcton_type;     -- �U�֐�
  i_head_out_up_cnt_tab         head_out_up_cnt_type;      -- �O���ƎҕύX��
  i_head_description_tab        head_description_type;     -- �^���E�v
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 START #####
  i_head_dispatch_type_tab        head_dispatch_type_type;     -- �z�ԃ^�C�v
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 END   #####
--
  -- �^���w�b�_�A�h�I�� �X�V�p�ϐ���`
  u_head_deliv_cmpny_cd_tab     head_deliv_cmpny_cd_type;  -- �^���Ǝ�
  u_head_deliv_no_tab           head_deliv_no_type;        -- �z��No
  u_head_invoice_no_tab         head_invoice_no_type;      -- �����No
  u_head_pay_judg_cls_tab       head_pay_judg_cls_type;    -- �x�����f�敪
  u_head_ship_date_tab          head_ship_date_type;       -- �o�ɓ�
  u_head_arrival_date_tab       head_arrival_date_type;    -- ������
  u_head_judg_date_tab          head_judg_date_type;       -- ���f��
  u_head_goods_cls_tab          head_goods_cls_type;       -- ���i�敪
  u_head_mixed_cd_tab           head_mixed_cd_type;        -- ���ڋ敪
  u_head_contract_rate_tab      head_contract_rate_type;   -- �_��^��
  u_head_balance_tab            head_balance_type;         -- ���z
  u_head_total_amount_tab       head_total_amount_type;    -- ���v
  u_head_distance_tab           head_distance_type;        -- �Œ�����
  u_head_deliv_cls_tab          head_deliv_cls_type;       -- �z���敪
  u_head_whs_cd_tab             head_whs_cd_type;          -- ��\�o�ɑq�ɃR�[�h
  u_head_cd_dvsn_tab            head_cd_dvsn_type;         -- ��\�z����R�[�h�敪
  u_head_ship_addr_cd_tab       head_ship_addr_cd_type;    -- ��\�z����R�[�h
  u_head_qty1_tab               head_qty1_type;            -- ���P
  u_head_deliv_wght1_tab        head_deliv_wght1_type;     -- �d�ʂP
  u_head_cnsld_srhrg_tab        head_cnsld_srhrg_type;     -- ���ڊ������z
  u_head_actual_ditnc_tab       head_actual_ditnc_type;    -- �Œ����ۋ���
  u_head_pick_charge_tab        head_pick_charge_type;     -- �s�b�L���O��
  u_head_consolid_qty_tab       head_consolid_qty_type;    -- ���ڐ�
  u_head_order_type_tab         head_order_type_type;      -- ��\�^�C�v
  u_head_wigh_cpcty_cls_tab     head_wigh_cpcty_cls_type;  -- �d�ʗe�ϋ敪
  u_head_out_cont_tab           head_out_cont_type;        -- �_��O�敪
  u_head_trans_lcton_tab        head_trans_lcton_type;     -- �U�֐�
  u_head_output_flag_tab        head_output_flag_type;     -- ���ً敪
  u_head_defined_flag_tab       head_defined_flag_type;    -- �x���m��敪
  u_head_return_flag_tab        head_return_flag_type;     -- �x���m���
--
  -- �^���w�b�_�A�h�I�� �폜�p�ϐ���`
  d_head_deliv_no_tab           head_deliv_no_type;        -- �z��No
--
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 START #####
--
  --  �z�ԉ��� ����p�ϐ���`
  carcan_request_no_tab       line_request_no_type;      -- �˗�No
  carcan_deliv_no_tab         line_deliv_no_type;        -- �z��No
  u_can_request_no_tab        line_request_no_type;      -- �˗�No�i�X�V�p�j
  d_can_deliv_no_tab          line_deliv_no_type;        -- �z��No�i�폜�p�j
  -- �`�[�Ȃ��z�� ����
  d_slip_head_deliv_no_tab    head_deliv_no_type;        -- �z��No�i�폜�p�j
--
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 END   #####
--
  -- *****************************
  -- * �z�Ԕz���v�� �֘A
  -- *****************************
  -- �z�Ԕz���v�� ���o����
  TYPE carriers_schedule_rec IS RECORD(
    -- �^���Ǝ�
      delivery_company_code  xxwsh_carriers_schedule.result_freight_carrier_code%TYPE
    -- �z��No
    , delivery_no            xxwsh_carriers_schedule.delivery_no%TYPE
    -- �o�ɓ�
    , ship_date              xxwsh_carriers_schedule.shipped_date%TYPE
    -- ������
    , arrival_date           xxwsh_carriers_schedule.arrival_date%TYPE
    -- �z���敪
    , dellivary_classe       xxwsh_carriers_schedule.result_shipping_method_code%TYPE
    -- ��\�o�ɑq�ɃR�[�h
    , whs_code               xxwsh_carriers_schedule.deliver_from%TYPE
    -- ��\�z����R�[�h�敪
    , code_division          xxwsh_carriers_schedule.deliver_to_code_class%TYPE
    -- ��\�z����R�[�h
    , shipping_address_code  xxwsh_carriers_schedule.deliver_to%TYPE
    -- �d�ʗe�ϋ敪
    , weight_capacity_class  xxwsh_carriers_schedule.weight_capacity_class%TYPE
    -- �x�����f�敪
    , payments_judgment_classe xxwip_deliverys.payments_judgment_classe%TYPE
    -- ���f��
    , judgement_date         xxwip_deliverys.judgement_date%TYPE
    -- ���ڋ敪
    , mixed_code             xxwip_deliverys.mixed_code%TYPE
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 START #####
    , transaction_type      xxwsh_carriers_schedule.transaction_type%TYPE -- ������ʁi�z�ԁj
    , prod_class            xxwip_deliverys.goods_classe%TYPE             -- ���i�敪
    , non_slip_class        xxwsh_carriers_schedule.non_slip_class%TYPE   -- �`�[�Ȃ��z�ԋ敪
    , slip_number           xxwip_deliverys.invoice_no%TYPE               -- �����No
    , small_quantity        xxwsh_carriers_schedule.small_quantity%TYPE   -- ������
    , small_amount_class    xxwsh_ship_method_v.small_amount_class%TYPE   -- �����敪
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 END   #####
  );
--
  TYPE carriers_schedule_tbl IS TABLE OF carriers_schedule_rec INDEX BY PLS_INTEGER;
  gt_carriers_schedule_tab   carriers_schedule_tbl;
--
  -- *****************************
  -- * ���� �֘A
  -- *****************************
  -- ���֎� �^�����׃A�h�I�� ���o����
  TYPE exch_deliv_line_rec IS RECORD(
      request_no             xxwip_delivery_lines.request_no%TYPE                -- �˗�No
    , small_lot_class        xxwip_delivery_lines.small_lot_class%TYPE           -- ���[�t�����敪
    , goods_classe           xxwip_delivery_lines.goods_classe%TYPE              -- ���i�敪
    , weight_capacity_class  xxwip_delivery_lines.weight_capacity_class%TYPE     -- �d�ʗe�ϋ敪
    , qty                    xxwip_delivery_lines.qty%TYPE                       -- ��
    , delivery_weight        xxwip_delivery_lines.delivery_weight%TYPE           -- �d��
    , mixed_code             xxwip_delivery_lines.mixed_code%TYPE                -- ���ڋ敪
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
    , judgement_date         xxwip_delivery_lines.judgement_date%TYPE            -- ���f��
    , distance               xxwip_delivery_lines.distance%TYPE                  -- ����
    , xdl_actual_distance    xxwip_delivery_lines.actual_distance%TYPE           -- ���ۋ���
    , dellivary_classe       xxwip_delivery_lines.dellivary_classe%TYPE          -- �z���敪
    , distance_chk           VARCHAR2(1)                                         -- �z�������t���O
    , company_chk            VARCHAR2(1)                                         -- �^���Ǝ҃t���O
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
    , post_distance          xxwip_delivery_distance.post_distance%TYPE          -- �ԗ�����
    , small_distance         xxwip_delivery_distance.small_distance%TYPE         -- ��������
    , consolid_add_distance  xxwip_delivery_distance.consolid_add_distance%TYPE  -- ���ڋ���
    , actual_distance        xxwip_delivery_distance.actual_distance%TYPE        -- ���ۋ���
    , small_weight           xxwip_delivery_company.small_weight%TYPE            -- �����d��
  );
--
  TYPE exch_deliv_line_tbl IS TABLE OF exch_deliv_line_rec INDEX BY PLS_INTEGER;
  gt_exch_deliv_line_tab   exch_deliv_line_tbl;
--
  -- ���� �^�����׃A�h�I�� �X�V�p�ϐ���`
  ue_line_request_no_tab       line_request_no_type;         -- �˗�No
  ue_line_ditnc_tab            line_ditnc_type;              -- ����
  ue_line_actual_dstnc_tab     line_actual_dstnc_type;       -- ���ۋ���
  ue_line_deliv_weight_tab     line_deliv_weight_type;       -- �d��
--
  -- ���� �^�����׃A�h�I�� �z��No ���o����
  TYPE exch_delivno_line_rec IS RECORD(
      delivery_no         xxwip_delivery_lines.delivery_no%TYPE       -- �z��No
    , distance            xxwip_delivery_lines.distance%TYPE          -- �Œ������i�ő�j
    , actual_distance     xxwip_delivery_lines.actual_distance%TYPE   -- ���ۋ���
    , delivery_weight     xxwip_delivery_lines.delivery_weight%TYPE   -- �d�ʁi���v�j
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
    , invoice_no               xxwip_delivery_lines.invoice_no%TYPE               -- �����No
    , payments_judgment_classe xxwip_delivery_lines.payments_judgment_classe%TYPE -- �x�����f�敪
    , ship_date                xxwip_delivery_lines.ship_date%TYPE                -- �o�ɓ�
    , arrival_date             xxwip_delivery_lines.arrival_date%TYPE             -- ���ɓ�
    , judgement_date           xxwip_delivery_lines.judgement_date%TYPE           -- ���f��
    , mixed_code               xxwip_delivery_lines.mixed_code%TYPE               -- ���ڋ敪
    , dellivary_classe         xxwip_delivery_lines.dellivary_classe%TYPE         -- �z���敪
    , whs_code                 xxwip_delivery_lines.whs_code%TYPE                 -- �o�ɑq�ɃR�[�h
    , code_division            xxwip_delivery_lines.code_division%TYPE            -- �z����R�[�h�敪
    , shipping_address_code    xxwip_delivery_lines.shipping_address_code%TYPE    -- �z����R�[�h
    , order_type               xxwip_delivery_lines.order_type%TYPE               -- �^�C�v
    , outside_contract         xxwip_delivery_lines.outside_contract%TYPE         -- �_��O�敪
    , transfer_location        xxwip_delivery_lines.transfer_location%TYPE        -- �U�֐�
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
  );
  TYPE exch_delivno_line_tbl IS TABLE OF exch_delivno_line_rec INDEX BY PLS_INTEGER;
  gt_exch_delivno_line_tab   exch_delivno_line_tbl;
--
  -- ���� �^���w�b�_�A�h�I�� �X�V�p�ϐ���`
  ue_head_deliv_no_tab           head_deliv_no_type;        -- �z��No
  ue_head_distance_tab           head_distance_type;        -- �Œ�����
  ue_head_deliv_wght1_tab        head_deliv_wght1_type;     -- �d�ʂP
  ue_head_actual_ditnc_tab       head_actual_ditnc_type;    -- �Œ����ۋ���
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
  ue_head_invoice_no_tab         head_invoice_no_type;      -- �����No
  ue_head_pay_judg_cls_tab       head_pay_judg_cls_type;    -- �x�����f�敪
  ue_head_ship_date_tab          head_ship_date_type;       -- �o�ɓ�
  ue_head_arrival_date_tab       head_arrival_date_type;    -- ������
  ue_head_judg_date_tab          head_judg_date_type;       -- ���f��
  ue_head_mixed_cd_tab           head_mixed_cd_type;        -- ���ڋ敪
  ue_head_deliv_cls_tab          head_deliv_cls_type;       -- �z���敪
  ue_head_whs_cd_tab             head_whs_cd_type;          -- ��\�o�ɑq�ɃR�[�h
  ue_head_cd_dvsn_tab            head_cd_dvsn_type;         -- ��\�z����R�[�h�敪
  ue_head_ship_addr_cd_tab       head_ship_addr_cd_type;    -- ��\�z����R�[�h
  ue_head_order_type_tab         head_order_type_type;      -- ��\�^�C�v
  ue_head_out_cont_tab           head_out_cont_type;        -- �_��O�敪
  ue_head_trans_lcton_tab        head_trans_lcton_type;     -- �U�֐�
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
--
  -- ���֎� �^���w�b�_�A�h�I�� ���o����
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
/*****
  TYPE exch_deliv_rec IS RECORD(
      delivery_company_code xxwip_deliverys.delivery_company_code%TYPE  -- �^���Ǝ�
    , delivery_no           xxwip_deliverys.delivery_no%TYPE            -- �z��No
    , p_b_classe            xxwip_deliverys.p_b_classe%TYPE             -- �x�������敪
    , judgement_date        xxwip_deliverys.judgement_date%TYPE         -- ���f��
    , goods_classe          xxwip_deliverys.goods_classe%TYPE           -- ���i�敪
    , mixed_code            xxwip_deliverys.mixed_code%TYPE             -- ���ڋ敪
    , charged_amount        xxwip_deliverys.charged_amount%TYPE         -- �����^��
    , many_rate             xxwip_deliverys.many_rate%TYPE              -- ������
    , distance              xxwip_deliverys.distance%TYPE               -- �Œ�����
    , delivery_classe       xxwip_deliverys.delivery_classe%TYPE        -- �z���敪
    , qty1                  xxwip_deliverys.qty1%TYPE                   -- ���P
    , delivery_weight1      xxwip_deliverys.delivery_weight1%TYPE       -- �d�ʂP
    , consolid_surcharge    xxwip_deliverys.consolid_surcharge%TYPE     -- ���ڊ������z
    , consolid_qty          xxwip_deliverys.consolid_qty%TYPE           -- ���ڐ�
    , output_flag           xxwip_deliverys.output_flag%TYPE            -- ���ً敪
    , defined_flag          xxwip_deliverys.defined_flag%TYPE           -- �x���m��敪
    , return_flag           xxwip_deliverys.return_flag%TYPE            -- �x���m���
    , pay_picking_amount    xxwip_delivery_company.pay_picking_amount%TYPE -- �^���F�x���s�b�L���O�P��
    , shipping_expenses     xxwip_delivery_charges.shipping_expenses%TYPE  -- �^���F�^����
    , leaf_consolid_add     xxwip_delivery_charges.leaf_consolid_add%TYPE  -- �^���F���[�t���ڊ���
--2008/08/04 Add ��
    , actual_distance       xxwip_deliverys.actual_distance%TYPE        -- �Œ����ۋ���
    , whs_code              xxwip_deliverys.whs_code%TYPE               -- ��\�o�ɑq�ɃR�[�h
    , code_division         xxwip_deliverys.code_division%TYPE          -- ��\�z����R�[�h�敪
    , shipping_address_code xxwip_deliverys.shipping_address_code%TYPE  -- ��\�z����R�[�h
    , dispatch_type         xxwip_deliverys.dispatch_type%TYPE          -- �z�ԃ^�C�v
--2008/08/04 Add ��
  );
*****/
  -- ���֎� �^���w�b�_�A�h�I�� ���o����
  TYPE exch_deliv_rec IS RECORD(
      delivery_company_code xxwip_deliverys.delivery_company_code%TYPE  -- �^���Ǝ�
    , delivery_no           xxwip_deliverys.delivery_no%TYPE            -- �z��No
    , p_b_classe            xxwip_deliverys.p_b_classe%TYPE             -- �x�������敪
    , ship_date             xxwip_deliverys.ship_date%TYPE              -- �o�ɓ�
    , judgement_date        xxwip_deliverys.judgement_date%TYPE         -- ���f��
    , goods_classe          xxwip_deliverys.goods_classe%TYPE           -- ���i�敪
    , mixed_code            xxwip_deliverys.mixed_code%TYPE             -- ���ڋ敪
    , charged_amount        xxwip_deliverys.charged_amount%TYPE         -- �����^��
    , many_rate             xxwip_deliverys.many_rate%TYPE              -- ������
    , distance              xxwip_deliverys.distance%TYPE               -- �Œ�����
    , delivery_classe       xxwip_deliverys.delivery_classe%TYPE        -- �z���敪
    , qty1                  xxwip_deliverys.qty1%TYPE                   -- ���P
    , delivery_weight1      xxwip_deliverys.delivery_weight1%TYPE       -- �d�ʂP
    , consolid_surcharge    xxwip_deliverys.consolid_surcharge%TYPE     -- ���ڊ������z
    , consolid_qty          xxwip_deliverys.consolid_qty%TYPE           -- ���ڐ�
    , output_flag           xxwip_deliverys.output_flag%TYPE            -- ���ً敪
    , defined_flag          xxwip_deliverys.defined_flag%TYPE           -- �x���m��敪
    , return_flag           xxwip_deliverys.return_flag%TYPE            -- �x���m���
    , actual_distance       xxwip_deliverys.actual_distance%TYPE        -- �Œ����ۋ���
    , whs_code              xxwip_deliverys.whs_code%TYPE               -- ��\�o�ɑq�ɃR�[�h
    , code_division         xxwip_deliverys.code_division%TYPE          -- ��\�z����R�[�h�敪
    , shipping_address_code xxwip_deliverys.shipping_address_code%TYPE  -- ��\�z����R�[�h
    , dispatch_type         xxwip_deliverys.dispatch_type%TYPE          -- �z�ԃ^�C�v
    , picking_charge        xxwip_deliverys.picking_charge%TYPE         -- �x���s�b�L���O��
    , contract_rate         xxwip_deliverys.contract_rate%TYPE          -- �_��^��
    , last_update_date      xxwip_deliverys.last_update_date%TYPE       -- �ŏI�X�V��
    , pay_picking_amount    xxwip_delivery_company.pay_picking_amount%TYPE      -- �^���F�x���s�b�L���O�P��
    , pay_change_flg        xxwip_delivery_company.pay_change_flg%TYPE          -- �^���F�x���ύX�t���O
    , small_amount_class    xxwsh_ship_method_v.small_amount_class%TYPE         -- �z���敪�F�����敪
    , post_distance         xxwip_delivery_distance.post_distance%TYPE          -- �z���F�ԗ�����
    , small_distance        xxwip_delivery_distance.small_distance%TYPE         -- �z���F��������
    , consolid_add_distance xxwip_delivery_distance.consolid_add_distance%TYPE  -- �z���F���ڋ���
    , dis_actual_distance   xxwip_delivery_distance.actual_distance%TYPE        -- �z���F���ۋ���
    , distance_change_flg   xxwip_delivery_distance.change_flg%TYPE             -- �z���F�ύX�t���O
    , shipping_expenses     xxwip_delivery_charges.shipping_expenses%TYPE       -- �^���F�^����
    , leaf_consolid_add     xxwip_delivery_charges.leaf_consolid_add%TYPE       -- �^���F���[�t���ڊ���
    , charg_shp_change_flg  xxwip_delivery_charges.change_flg%TYPE              -- �^���F�ύX�t���O
    , charg_lrf_change_flg  xxwip_delivery_charges.change_flg%TYPE              -- �^���F�ύX�t���O
  );
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
--
  TYPE exch_deliv_tbl IS TABLE OF exch_deliv_rec INDEX BY PLS_INTEGER;
  gt_exch_deliv_tab   exch_deliv_tbl;
--
  -- ���֎� �^���w�b�_�A�h�I�� �X�V�p�ϐ���`
  ueh_head_deliv_no_tab           head_deliv_no_type;         -- �z��No
  ueh_head_contract_rate_tab      head_contract_rate_type;    -- �_��^��
  ueh_head_balance_tab            head_balance_type;          -- ���z
  ueh_head_total_amount_tab       head_total_amount_type;     -- ���v
  ueh_head_cnsld_srhrg_tab        head_cnsld_srhrg_type;      -- ���ڊ������z
  ueh_head_pick_charge_tab        head_pick_charge_type;      -- �s�b�L���O��
  ueh_head_output_flag_tab        head_output_flag_type;      -- ���ً敪
  ueh_head_defined_flag_tab       head_defined_flag_type;     -- �x���m��敪
  ueh_head_return_flag_tab        head_return_flag_type;      -- �x���m���
--2008/08/04 Add ��
  ueh_head_distance_type_tab      head_distance_type;         -- �Œ�����
  ueh_head_actual_ditnc_type_tab  head_actual_ditnc_type;     -- �Œ����ۋ���
--2008/08/04 Add ��
--
  -- ���֎� �^���w�b�_�A�h�I�� �폜�p�ϐ���`
  deh_head_deliv_no_tab           head_deliv_no_type;          -- �z��No
--
-- ##### 20081226 Ver.1.18 �{��#323�Ή��i���O�Ή��j START #####
  -- �폜�f�[�^�i�[
  TYPE t_delete_data_msg IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER ;
  gt_delete_data_msg     t_delete_data_msg ;
  gn_delete_data_idx     NUMBER := 0 ;
-- ##### 20081226 Ver.1.18 �{��#323�Ή��i���O�Ή��j END   #####
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_debug_flg           VARCHAR2(1);        -- �f�o�b�O�t���O
--
  gd_sysdate             DATE;              -- �V�X�e�����t
  gn_user_id             NUMBER;            -- ���[�UID
  gn_login_id            NUMBER;            -- �ŏI�X�V���O�C��
  gn_conc_request_id     NUMBER;            -- �v��ID
  gn_prog_appl_id        NUMBER;            -- �ݶ��āE��۸��т̱��ع����ID
  gn_conc_program_id     NUMBER;            -- �R���J�����g�E�v���O����ID
--
  gd_last_process_date   DATE;              -- �O�񏈗����t
  gv_closed_day          VARCHAR2(1);       -- ��������
  gd_target_date         DATE;              -- ���ߑO���t
--
  gn_deliv_line_ins_cnt      NUMBER := 0;            -- �^�����׃A�h�I���o�^����
  gn_deliv_ins_cnt           NUMBER := 0;            -- �^���w�b�_�A�h�I���o�^����
  gn_deliv_del_cnt           NUMBER := 0;            -- �^���w�b�_�A�h�I���o�^����
--
  /**********************************************************************************
   * Procedure Name   : chk_param_proc
   * Description      : �p�����[�^�`�F�b�N����(A-1)
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
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                            gv_xxcmn_msg_para,
                                            gv_tkn_parameter,
                                            gv_exchange_type,
                                            gv_tkn_value,
                                           iv_exchange_type);
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
   * Description      : �֘A�f�[�^�擾(A-2,3)
   ***********************************************************************************/
  PROCEDURE get_init(
    iv_exchange_type IN         VARCHAR2,     -- ���֋敪
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
    -- ****************************************************
    -- �v���t�@�C���F�x���^���f�[�^�����쐬 �f�o�b�O�t���O
    -- ****************************************************
    gv_debug_flg := FND_PROFILE.VALUE(gv_prof_debug_flg);
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_debug_flg IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                            gv_xxcom_noprof_err,
                                            gv_tkn_ng_profile,
                                            gv_prof_debug_flg);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gd_sysdate          := SYSDATE;                    -- �V�X�e������
    gn_user_id          := FND_GLOBAL.USER_ID;         -- ���O�C�����[�UID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;        -- ���O�C��ID
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID; -- �R���J�����g�v��ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;    -- �ݶ��āE��۸��сE���ع����ID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID; -- �R���J�����g�E�v���O����ID
--
    -- **************************************************
    -- *** �^���v�Z�p�R���g���[�����O�񏈗����t���擾
    -- **************************************************
    BEGIN
      SELECT xdc.last_process_date    -- �O�񏈗����t
      INTO   gd_last_process_date
      FROM   xxwip_deliverys_ctrl xdc -- �^���v�Z�p�R���g���[���A�h�I��
      WHERE  xdc.concurrent_no = gv_con_no_deliv
      FOR UPDATE NOWAIT;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN   --*** �f�[�^�擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                              gv_xxcmn_msg_notfnd,
                                              gv_tkn_table,
                                              gv_deliverys_ctrl,
                                              gv_tkn_key,
                                              gv_con_no_deliv);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN TOO_MANY_ROWS THEN   --*** �f�[�^�����擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                              gv_xxcmn_msg_toomny,
                                              gv_tkn_table,
                                              gv_deliverys_ctrl,
                                              gv_tkn_key,
                                              gv_con_no_deliv);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN lock_expt THEN       --*** ���b�N�擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwip_msg_kbn,
                                              gv_xxwip_msg_lock_err,
                                              gv_tkn_table,
                                              gv_deliverys_ctrl);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- **************************************************
    -- *** �^���p�����ݒ�
    -- **************************************************
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
    -- ���ߑO���t�ݒ�
    IF (lv_close_type = gv_ktg_yes) THEN
      -- �V�X�e�����t�̑O���̏�����ݒ�
      gd_target_date := ADD_MONTHS(FND_DATE.STRING_TO_DATE(
                          TO_CHAR(gd_sysdate, 'YYYYMM') || '01', 'YYYYMMDD'), -1);
--
    ELSIF (lv_close_type = gv_ktg_no) THEN
      -- �V�X�e�����t�̏�����ݒ�
      gd_target_date := FND_DATE.STRING_TO_DATE(TO_CHAR(gd_sysdate, 'YYYYMM') || '01', 'YYYYMMDD');
    END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_init�F�O�񏈗������F' || 
                                      TO_CHAR(gd_last_process_date, 'YYYY/MM/DD HH24:MI:SS'));
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_init�F����        �F' || 
                                      TO_CHAR(gd_target_date, 'YYYY/MM/DD HH24:MI:SS'));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
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
   * Procedure Name   : get_deliv_lock
   * Description      : ���b�N�擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_deliv_lock(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deliv_lock'; -- �v���O������
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
    lb_retcd          BOOLEAN;
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
    -- **************************************************
    -- *** �e�[�u�����b�N����(�^���w�b�_�A�h�I��)
    -- **************************************************
    lb_retcd := xxcmn_common_pkg.get_tbl_lock(gv_xxwip_msg_kbn,
                                              'xxwip_deliverys');
    -- ���s
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwip_msg_kbn,
                                            gv_xxwip_msg_lock_err,
                                            gv_tkn_table,
                                            gv_deliverys);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- **************************************************
    -- *** �e�[�u�����b�N����(�^�����׃A�h�I��)
    -- **************************************************
    lb_retcd := xxcmn_common_pkg.get_tbl_lock(gv_xxwip_msg_kbn,
                                              'xxwip_delivery_lines');
    -- ���s
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwip_msg_kbn,
                                            gv_xxwip_msg_lock_err,
                                            gv_tkn_table,
                                            gv_delivery_lines);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
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
  END get_deliv_lock;
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
  /**********************************************************************************
   * Procedure Name   : get_delivmst_lock
   * Description      : ���b�N�擾(�^���֘A�}�X�^)
   ***********************************************************************************/
  PROCEDURE get_delivmst_lock(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deliv_lock'; -- �v���O������
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
    lb_retcd          BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
    --�^���p�^���Ǝ҃}�X�^
    CURSOR get_xdco_cur
    IS
      SELECT  delivery_company_id
      FROM    xxwip_delivery_company
      WHERE   pay_change_flg = gv_target_y  -- �x���ύX�t���O
      FOR UPDATE NOWAIT
      ;
--
    -- �z�������}�X�^
    CURSOR get_xddi_cur
    IS
      SELECT  delivery_distance_id
      FROM    xxwip_delivery_distance
      WHERE   change_flg = gv_target_y      -- �ύX�t���O
      FOR UPDATE NOWAIT
      ;
--
    -- �^���}�X�^
    CURSOR get_xdch_cur
    IS
      SELECT  delivery_charges_id
      FROM    xxwip_delivery_charges
      WHERE   p_b_classe = gv_pay
      AND     change_flg = gv_target_y      -- �ύX�t���O
      FOR UPDATE NOWAIT
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
    -- **************************************************
    -- *** ���b�N�擾�i�^���p�^���Ǝ҃}�X�^�j
    -- **************************************************
      BEGIN
        <<get_xdco_loop>>
        FOR loop_cnt IN get_xdco_cur LOOP
          EXIT;
        END LOOP get_xdco_loop;
      EXCEPTION
        --*** ���b�N�擾�G���[ ***
        WHEN lock_expt THEN
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwip_msg_kbn,
                                                gv_xxwip_msg_lock_err,
                                                gv_tkn_table,
                                                gv_delivery_company);
          lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
--
    -- **************************************************
    -- *** ���b�N�擾�i�z�������}�X�^�j
    -- **************************************************
      BEGIN
        <<get_xddi_loop>>
        FOR loop_cnt IN get_xddi_cur LOOP
          EXIT;
        END LOOP get_xddi_loop;
      EXCEPTION
        --*** ���b�N�擾�G���[ ***
        WHEN lock_expt THEN
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwip_msg_kbn,
                                                gv_xxwip_msg_lock_err,
                                                gv_tkn_table,
                                                gv_delivery_distance);
          lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
--
    -- **************************************************
    -- *** ���b�N�擾�i�^���}�X�^�j
    -- **************************************************
      BEGIN
        <<get_xdch_loop>>
        FOR loop_cnt IN get_xdch_cur LOOP
          EXIT;
        END LOOP get_xdch_loop;
      EXCEPTION
        --*** ���b�N�擾�G���[ ***
        WHEN lock_expt THEN
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwip_msg_kbn,
                                                gv_xxwip_msg_lock_err,
                                                gv_tkn_table,
                                                gv_delivery_charges);
          lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
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
  END get_delivmst_lock;
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
--
  /**********************************************************************************
   * Procedure Name   : get_order
   * Description      : �󒍎��я�񒊏o(A-5)
   ***********************************************************************************/
  PROCEDURE get_order(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order'; -- �v���O������
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

-- ##### 20081125 Ver.1.13 �{��#104�Ή� START #####
    -- �󒍎��я�� ���o
    /*SELECT  xoha.order_header_id                  -- �󒍃w�b�_�A�h�I��ID
          , xoha.request_no                       -- �˗�No
          , xoha.slip_number                      -- �����No
          , xoha.delivery_no                      -- �z��No
          , xoha.result_freight_carrier_code      -- �^���Ǝ�_����
          , xoha.deliver_from                     -- �o�׌��ۊǏꏊ
          , xoha.result_shipping_method_code      -- �z���敪_����
          , CASE xotv.shipping_shikyu_class       -- �z���R�[�h�敪
            WHEN gv_shipping THEN gv_code_ship    --   �o�׎x���敪 3�F�z����
            WHEN gv_shikyu   THEN gv_code_shikyu  --                2�F�����
            END
-- ##### 20080625 Ver.1.2 �x���z����Ή� START #####
--          , xoha.result_deliver_to                -- �o�א�_����
          , CASE xotv.shipping_shikyu_class       -- �z���R�[�h�敪
            WHEN gv_shipping THEN xoha.result_deliver_to  -- �o�א�_����
            WHEN gv_shikyu   THEN xoha.vendor_site_code   -- �����T�C�g
            END
-- ##### 20080625 Ver.1.2 �x���z����Ή� END   #####
          , xdec.payments_judgment_classe         -- �x�����f�敪(�^��)
          , xoha.shipped_date                     -- �o�ד�
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
--  ���ד���ݒ�ANULL�̏ꍇ�͒��ח\�����ݒ�
--          , xoha.arrival_date                     -- ���ד�
          , NVL(xoha.arrival_date, xoha.schedule_arrival_date)  -- ���ד�(���ח\���)
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
          , CASE xdec.payments_judgment_classe    -- ���f��
            WHEN gv_pay_judg_g THEN xoha.shipped_date -- ����
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
--            WHEN gv_pay_judg_c THEN xoha.arrival_date -- ����
            WHEN gv_pay_judg_c THEN NVL(xoha.arrival_date, xoha.schedule_arrival_date) -- ����
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
            END
          , xoha.prod_class                       -- ���i�敪
          , xoha.weight_capacity_class            -- �d�ʗe�ϋ敪
          , xoha.small_quantity                   -- ������
          , CASE xotv.shipping_shikyu_class       -- �^�C�v
            WHEN gv_shipping  THEN gv_type_ship   --   �P�F�o��
            WHEN gv_shikyu    THEN gv_type_shikyu --   �Q�F�x��
            END
          , xoha.no_cont_freight_class            -- �_��O�^���敪
          , xoha.transfer_location_code           -- �U�֐�
          , SUBSTRB(xoha.shipping_instructions, 1, 40) -- �o�׎w��(40)
          , NULL                                  -- �����敪
          , NULL                                  -- ���ڋ敪
          , NULL                                  -- ���[�t�����敪
          , NULL                                  -- �z�������F�ԗ�����
          , NULL                                  -- �z�������F��������
          , NULL                                  -- �z�������F���ڊ�������
          , NULL                                  -- �z�������F���ۋ���
          , NULL                                  -- �����d��
          , NULL                                  -- �x���s�b�L���O�P��
          , NULL                                  -- ��
          , NULL                                  -- �d��
    BULK COLLECT INTO gt_order_inf_tab
    FROM  xxwsh_order_headers_all        xoha,      -- �󒍃w�b�_�A�h�I��
          xxwsh_oe_transaction_types2_v  xotv,    -- �󒍃^�C�v���VIEW2
          xxwip_delivery_company         xdec     -- �^���p�^���Ǝ҃A�h�I���}�X�^
    WHERE xoha.latest_external_flag = 'Y'                 -- �ŐV�t���O 'Y'
    AND   xoha.shipped_date IS NOT NULL                   -- �o�ד�
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 START #####
--
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
--  ���ד����ݒ肳��Ă��Ȃ��Ă��A���o�ΏۂƂ���B
-- �i���ח\����������͒��ד����ݒ肳��Ă��邱�Ƃ��O��j
    AND   (xoha.arrival_date           IS NOT NULL    -- ���ד�
      OR   xoha.schedule_arrival_date  IS NOT NULL)   -- ���ח\���
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
--
    AND   xoha.result_shipping_method_code IS NOT NULL    -- �z���敪_����
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 END   #####
    AND   xoha.result_freight_carrier_code IS NOT NULL    -- �^���Ǝ�_����
    AND   xoha.delivery_no  IS NOT NULL                   -- �z��No
    AND   xoha.prod_class = xdec.goods_classe                             -- ���i�敪
    AND   xoha.result_freight_carrier_code = xdec.delivery_company_code   -- �^���Ǝ�
    AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                    -- �K�p�J�n��
    AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                    -- �K�p�I����
    AND   xoha.order_type_id       = xotv.transaction_type_id -- �󒍃^�C�vID
    AND   (
            ((xdec.payments_judgment_classe = gv_pay_judg_g)    -- �x�����f�敪�i�����j
            AND (xoha.shipped_date >=  gd_target_date))         -- �o�ד�
          OR
            ((xdec.payments_judgment_classe = gv_pay_judg_c)    -- �x�����f�敪�i�����j
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
--            AND (xoha.arrival_date >=  gd_target_date))         -- ���ד�
            AND (NVL(xoha.arrival_date, xoha.schedule_arrival_date)
                                             >=  gd_target_date)) -- ���ד�(���ח\���)
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
          )
    AND (
-- ##### 20080625 Ver.1.2 �x���z����Ή� START #####
--          (xotv.shipping_shikyu_class  = gv_shipping)         -- �o�׈˗�
          ((xotv.shipping_shikyu_class  = gv_shipping)         -- �o�׈˗�
          AND  (xoha.result_deliver_to  IS NOT NULL))          -- �o�א�_����
-- ##### 20080625 Ver.1.2 �x���z����Ή� END   #####
        OR
          ((xotv.shipping_shikyu_class  = gv_shikyu)            -- �x���˗�
          AND (xotv.auto_create_po_class = '0'))                -- �����쐬�����敪�uNO�v
        )
    AND (
          ((xoha.last_update_date > gd_last_process_date)  -- �󒍃w�b�_�F�O�񏈗����t
          AND  (xoha.last_update_date <= gd_sysdate))
        OR (xoha.request_no IN (SELECT xola.request_no
                              FROM xxwsh_order_lines_all xola    -- �󒍖��׃A�h�I��
                              WHERE (xola.last_update_date > gd_last_process_date)  -- �󒍖��ׁF�O�񏈗����t
                              AND   (xola.last_update_date <= gd_sysdate)))
        );*/
        
    -- �󒍎��я�� ���o
    SELECT
      order_info.order_header_id
     ,order_info.request_no
     ,order_info.slip_number
     ,order_info.delivery_no
     ,order_info.result_freight_carrier_code
     ,order_info.deliver_from
     ,order_info.result_shipping_method_code
     ,order_info.deliver_to_code_class
     ,order_info.result_deliver_to
     ,order_info.payments_judgment_classe
     ,order_info.shipped_date
     ,order_info.arrival_date
     ,order_info.judgement_date
     ,order_info.prod_class
     ,order_info.weight_capacity_class
     ,order_info.small_quantity
     ,order_info.order_type
     ,order_info.no_cont_freight_class
     ,order_info.transfer_location_code
     ,order_info.shipping_instructions
     ,order_info.small_amount_class
     ,order_info.mixed_class
     ,order_info.ref_small_amount_class
     ,order_info.post_distance
     ,order_info.small_distance
     ,order_info.consolid_add_distance
     ,order_info.actual_distance
     ,order_info.small_weight
     ,order_info.pay_picking_amount
     ,order_info.qty
     ,order_info.delivery_weight
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
     ,order_info.sum_pallet_weight
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
    BULK COLLECT INTO gt_order_inf_tab
    FROM (
      -- �����_�x���˗�
      SELECT /*+ leading(xoha otta xdec) use_nl(xoha otta xdec) */
              xoha.order_header_id                order_header_id              -- �󒍃w�b�_�A�h�I��ID
            , xoha.request_no                     request_no                   -- �˗�No
            , xoha.slip_number                    slip_number                  -- �����No
            , xoha.delivery_no                    delivery_no                  -- �z��No
            , xoha.result_freight_carrier_code    result_freight_carrier_code  -- �^���Ǝ�_����
            , xoha.deliver_from                   deliver_from                 -- �o�׌��ۊǏꏊ
            , xoha.result_shipping_method_code    result_shipping_method_code  -- �z���敪_����
            , gv_code_shikyu                      deliver_to_code_class        -- �z����R�[�h�敪
            , xoha.vendor_site_code               result_deliver_to            -- �o�א�_����
            , xdec.payments_judgment_classe       payments_judgment_classe     -- �x�����f�敪(�^��)
            , xoha.shipped_date                   shipped_date                 -- �o�ד�
            , NVL(xoha.arrival_date, xoha.schedule_arrival_date) arrival_date  -- ���ד�(���ח\���)
            , NVL(xoha.arrival_date, xoha.schedule_arrival_date) judgement_date  -- ���f��
            , xoha.prod_class                     prod_class                   -- ���i�敪
            , xoha.weight_capacity_class          weight_capacity_class        -- �d�ʗe�ϋ敪
-- ##### 20080717 Ver.1.15 �{��#595�Ή� START #####
--            , xoha.small_quantity                 small_quantity               -- ������
            , NVL(xoha.small_quantity, 0)           small_quantity               -- ������
-- ##### 20080717 Ver.1.15 �{��#595�Ή� END   #####
            , gv_type_shikyu                      order_type                   -- �^�C�v
            , xoha.no_cont_freight_class          no_cont_freight_class        -- �_��O�^���敪
            , xoha.transfer_location_code         transfer_location_code       -- �U�֐�
            , SUBSTRB(xoha.shipping_instructions, 1, 40) shipping_instructions -- �o�׎w��(40)
            , NULL                                small_amount_class           -- �����敪
            , NULL                                mixed_class                  -- ���ڋ敪
            , NULL                                ref_small_amount_class       -- ���[�t�����敪
            , NULL                                post_distance                -- �z�������F�ԗ�����
            , NULL                                small_distance               -- �z�������F��������
            , NULL                                consolid_add_distance        -- �z�������F���ڊ�������
            , NULL                                actual_distance              -- �z�������F���ۋ���
            , NULL                                small_weight                 -- �����d��
            , NULL                                pay_picking_amount           -- �x���s�b�L���O�P��
            , NULL                                qty                          -- ��
            , NULL                                delivery_weight              -- �d��
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
            , NVL(xoha.sum_pallet_weight, 0)      sum_pallet_weight            -- ���v�p���b�g�d��
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
      FROM  xxwsh_order_headers_all        xoha,      -- �󒍃w�b�_�A�h�I��
            oe_transaction_types_all       otta,    -- �󒍃^�C�v���VIEW2
            xxwip_delivery_company         xdec     -- �^���p�^���Ǝ҃A�h�I���}�X�^
      WHERE xoha.latest_external_flag = 'Y'                 -- �ŐV�t���O 'Y'
      AND   xoha.shipped_date IS NOT NULL                   -- �o�ד�
--    ���ד����ݒ肳��Ă��Ȃ��Ă��A���o�ΏۂƂ���B
--   �i���ח\����������͒��ד����ݒ肳��Ă��邱�Ƃ��O��j
      AND   (xoha.arrival_date           IS NOT NULL    -- ���ד�
        OR   xoha.schedule_arrival_date  IS NOT NULL)   -- ���ח\���
      AND   xoha.result_shipping_method_code IS NOT NULL    -- �z���敪_����
      AND   xoha.result_freight_carrier_code IS NOT NULL    -- �^���Ǝ�_����
      AND   xoha.delivery_no  IS NOT NULL                   -- �z��No
      AND   xoha.prod_class = xdec.goods_classe                             -- ���i�敪
      AND   xoha.result_freight_carrier_code = xdec.delivery_company_code   -- �^���Ǝ�
      AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                    -- �K�p�J�n��
      AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                    -- �K�p�I����
      AND   xoha.order_type_id       = otta.transaction_type_id -- �󒍃^�C�vID
      AND   xdec.payments_judgment_classe = gv_pay_judg_c    -- �x�����f�敪�i�����j
      AND   NVL(xoha.arrival_date, xoha.schedule_arrival_date)
                                               >=  gd_target_date -- ���ד�(���ח\���)
      AND   otta.attribute1  = gv_shikyu             -- �x���˗�
      AND   otta.attribute3 = '0'                     -- �����쐬�����敪�uNO�v
      AND (
            ((xoha.last_update_date > gd_last_process_date)  -- �󒍃w�b�_�F�O�񏈗����t
            AND  (xoha.last_update_date <= gd_sysdate))
          OR ( EXISTS (SELECT 1
                       FROM   xxwsh_order_lines_all xola    -- �󒍖��׃A�h�I��
                       WHERE  xola.order_header_id = xoha.order_header_id
                       AND    xola.last_update_date > gd_last_process_date -- �󒍖��ׁF�O�񏈗����t
                       AND    xola.last_update_date <= gd_sysdate
                       AND    ROWNUM = 1))
          )
-- 2008/11/28 v1.14 ADD START
      -- �ύڏd�ʍ��v�̐�������7���ȏ�̏ꍇ�͏o�͂��Ȃ�
      AND   LENGTHB(TRUNC(NVL(xoha.sum_weight, 0))) < 7
-- 2008/11/28 v1.14 ADD END
      UNION ALL
      -- �����_�o�׈˗�
      SELECT  /*+ leading(xoha otta xdec) use_nl(xoha otta xdec) */
              xoha.order_header_id                order_header_id              -- �󒍃w�b�_�A�h�I��ID
            , xoha.request_no                     request_no                   -- �˗�No
            , xoha.slip_number                    slip_number                  -- �����No
            , xoha.delivery_no                    delivery_no                  -- �z��No
            , xoha.result_freight_carrier_code    result_freight_carrier_code  -- �^���Ǝ�_����
            , xoha.deliver_from                   deliver_from                 -- �o�׌��ۊǏꏊ
            , xoha.result_shipping_method_code    result_shipping_method_code  -- �z���敪_����
            , gv_code_ship                        deliver_to_code_class        -- �z����R�[�h�敪
            , xoha.result_deliver_to              result_deliver_to-- �o�א�_����
            , xdec.payments_judgment_classe       payments_judgment_classe     -- �x�����f�敪(�^��)
            , xoha.shipped_date                   shipped_date                 -- �o�ד�
            , NVL(xoha.arrival_date, xoha.schedule_arrival_date) arrival_date  -- ���ד�(���ח\���)
            , NVL(xoha.arrival_date, xoha.schedule_arrival_date) judgement_date   -- ���f��
            , xoha.prod_class                     prod_class                   -- ���i�敪
            , xoha.weight_capacity_class          weight_capacity_class        -- �d�ʗe�ϋ敪
-- ##### 20080717 Ver.1.15 �{��#595�Ή� START #####
--            , xoha.small_quantity                 small_quantity               -- ������
            , NVL(xoha.small_quantity, 0)           small_quantity               -- ������
-- ##### 20080717 Ver.1.15 �{��#595�Ή� END   #####
            , gv_type_ship                        order_type                   -- �^�C�v
            , xoha.no_cont_freight_class          no_cont_freight_class        -- �_��O�^���敪
            , xoha.transfer_location_code         transfer_location_code       -- �U�֐�
            , SUBSTRB(xoha.shipping_instructions, 1, 40) shipping_instructions -- �o�׎w��(40)
            , NULL                                small_amount_class           -- �����敪
            , NULL                                mixed_class                  -- ���ڋ敪
            , NULL                                ref_small_amount_class       -- ���[�t�����敪
            , NULL                                post_distance                -- �z�������F�ԗ�����
            , NULL                                small_distance               -- �z�������F��������
            , NULL                                consolid_add_distance        -- �z�������F���ڊ�������
            , NULL                                actual_distance              -- �z�������F���ۋ���
            , NULL                                small_weight                 -- �����d��
            , NULL                                pay_picking_amount           -- �x���s�b�L���O�P��
            , NULL                                qty                          -- ��
            , NULL                                delivery_weight              -- �d��
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
            , NVL(xoha.sum_pallet_weight, 0)      sum_pallet_weight            -- ���v�p���b�g�d��
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
      FROM  xxwsh_order_headers_all        xoha,      -- �󒍃w�b�_�A�h�I��
            oe_transaction_types_all       otta,    -- �󒍃^�C�v���VIEW2
            xxwip_delivery_company         xdec     -- �^���p�^���Ǝ҃A�h�I���}�X�^
      WHERE xoha.latest_external_flag = 'Y'                 -- �ŐV�t���O 'Y'
      AND   xoha.shipped_date IS NOT NULL                   -- �o�ד�
--    ���ד����ݒ肳��Ă��Ȃ��Ă��A���o�ΏۂƂ���B
--   �i���ח\����������͒��ד����ݒ肳��Ă��邱�Ƃ��O��j
      AND   (xoha.arrival_date           IS NOT NULL    -- ���ד�
        OR   xoha.schedule_arrival_date  IS NOT NULL)   -- ���ח\���
      AND   xoha.result_shipping_method_code IS NOT NULL    -- �z���敪_����
      AND   xoha.result_freight_carrier_code IS NOT NULL    -- �^���Ǝ�_����
      AND   xoha.delivery_no  IS NOT NULL                   -- �z��No
      AND   xoha.prod_class = xdec.goods_classe                             -- ���i�敪
      AND   xoha.result_freight_carrier_code = xdec.delivery_company_code   -- �^���Ǝ�
      AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                    -- �K�p�J�n��
      AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                    -- �K�p�I����
      AND   xoha.order_type_id       = otta.transaction_type_id             -- �󒍃^�C�vID
      AND   xdec.payments_judgment_classe = gv_pay_judg_c    -- �x�����f�敪�i�����j
      AND   NVL(xoha.arrival_date, xoha.schedule_arrival_date)
                                               >=  gd_target_date -- ���ד�(���ח\���)
      AND   otta.attribute1   = gv_shipping                       -- �o�׈˗�
      AND   xoha.result_deliver_to  IS NOT NULL                             -- �o�א�_����
      AND (
            ((xoha.last_update_date > gd_last_process_date)  -- �󒍃w�b�_�F�O�񏈗����t
            AND  (xoha.last_update_date <= gd_sysdate))
          OR ( EXISTS (SELECT 1
                       FROM   xxwsh_order_lines_all xola    -- �󒍖��׃A�h�I��
                       WHERE  xola.order_header_id = xoha.order_header_id
                       AND    xola.last_update_date > gd_last_process_date -- �󒍖��ׁF�O�񏈗����t
                       AND    xola.last_update_date <= gd_sysdate
                       AND    ROWNUM = 1))
          )
-- 2008/11/28 v1.14 ADD START
      -- �ύڏd�ʍ��v�̐�������7���ȏ�̏ꍇ�͏o�͂��Ȃ�
      AND   LENGTHB(TRUNC(NVL(xoha.sum_weight, 0))) < 7
-- 2008/11/28 v1.14 ADD END
      UNION ALL
      -- �����_�x���˗�
      SELECT  /*+ leading(xoha otta xdec) use_nl(xoha otta xdec) */
              xoha.order_header_id                order_header_id              -- �󒍃w�b�_�A�h�I��ID
            , xoha.request_no                     request_no                   -- �˗�No
            , xoha.slip_number                    slip_number                  -- �����No
            , xoha.delivery_no                    delivery_no                  -- �z��No
            , xoha.result_freight_carrier_code    result_freight_carrier_code  -- �^���Ǝ�_����
            , xoha.deliver_from                   deliver_from                 -- �o�׌��ۊǏꏊ
            , xoha.result_shipping_method_code    result_shipping_method_code  -- �z���敪_����
            , gv_code_shikyu                      deliver_to_code_class        -- �z����R�[�h�敪
            , xoha.vendor_site_code               result_deliver_to            -- �o�א�_����
            , xdec.payments_judgment_classe       payments_judgment_classe     -- �x�����f�敪(�^��)
            , xoha.shipped_date                   shipped_date                 -- �o�ד�
            , NVL(xoha.arrival_date, xoha.schedule_arrival_date) arrival_date  -- ���ד�(���ח\���)
            ,xoha.shipped_date                    judgement_date               -- ���f��
            , xoha.prod_class                     prod_class                   -- ���i�敪
            , xoha.weight_capacity_class          weight_capacity_class        -- �d�ʗe�ϋ敪
-- ##### 20080717 Ver.1.15 �{��#595�Ή� START #####
--            , xoha.small_quantity                 small_quantity               -- ������
            , NVL(xoha.small_quantity, 0)           small_quantity               -- ������
-- ##### 20080717 Ver.1.15 �{��#595�Ή� END   #####
            , gv_type_shikyu                      order_type                   -- �^�C�v
            , xoha.no_cont_freight_class          no_cont_freight_class        -- �_��O�^���敪
            , xoha.transfer_location_code         transfer_location_code       -- �U�֐�
            , SUBSTRB(xoha.shipping_instructions, 1, 40) shipping_instructions -- �o�׎w��(40)
            , NULL                                small_amount_class           -- �����敪
            , NULL                                mixed_class                  -- ���ڋ敪
            , NULL                                ref_small_amount_class       -- ���[�t�����敪
            , NULL                                post_distance                -- �z�������F�ԗ�����
            , NULL                                small_distance               -- �z�������F��������
            , NULL                                consolid_add_distance        -- �z�������F���ڊ�������
            , NULL                                actual_distance              -- �z�������F���ۋ���
            , NULL                                small_weight                 -- �����d��
            , NULL                                pay_picking_amount           -- �x���s�b�L���O�P��
            , NULL                                qty                          -- ��
            , NULL                                delivery_weight              -- �d��
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
            , NVL(xoha.sum_pallet_weight, 0)      sum_pallet_weight            -- ���v�p���b�g�d��
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
      FROM  xxwsh_order_headers_all        xoha,      -- �󒍃w�b�_�A�h�I��
            oe_transaction_types_all       otta,    -- �󒍃^�C�v���VIEW2
            xxwip_delivery_company         xdec     -- �^���p�^���Ǝ҃A�h�I���}�X�^
      WHERE xoha.latest_external_flag = 'Y'                 -- �ŐV�t���O 'Y'
      AND   xoha.shipped_date IS NOT NULL                   -- �o�ד�
--    ���ד����ݒ肳��Ă��Ȃ��Ă��A���o�ΏۂƂ���B
--   �i���ח\����������͒��ד����ݒ肳��Ă��邱�Ƃ��O��j
      AND   (xoha.arrival_date           IS NOT NULL    -- ���ד�
        OR   xoha.schedule_arrival_date  IS NOT NULL)   -- ���ח\���
      AND   xoha.result_shipping_method_code IS NOT NULL    -- �z���敪_����
      AND   xoha.result_freight_carrier_code IS NOT NULL    -- �^���Ǝ�_����
      AND   xoha.delivery_no  IS NOT NULL                   -- �z��No
      AND   xoha.prod_class = xdec.goods_classe                             -- ���i�敪
      AND   xoha.result_freight_carrier_code = xdec.delivery_company_code   -- �^���Ǝ�
      AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                    -- �K�p�J�n��
      AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                    -- �K�p�I����
      AND   xoha.order_type_id       = otta.transaction_type_id -- �󒍃^�C�vID
      AND   xdec.payments_judgment_classe = gv_pay_judg_g    -- �x�����f�敪�i�����j
      AND   xoha.shipped_date >=  gd_target_date             -- �o�ד�
      AND   otta.attribute1  = gv_shikyu          -- �x���˗�
      AND   otta.attribute3 = '0'                  -- �����쐬�����敪�uNO�v
      AND (
            ((xoha.last_update_date > gd_last_process_date)  -- �󒍃w�b�_�F�O�񏈗����t
            AND  (xoha.last_update_date <= gd_sysdate))
          OR ( EXISTS (SELECT 1
                       FROM   xxwsh_order_lines_all xola    -- �󒍖��׃A�h�I��
                       WHERE  xola.order_header_id = xoha.order_header_id
                       AND    xola.last_update_date > gd_last_process_date -- �󒍖��ׁF�O�񏈗����t
                       AND    xola.last_update_date <= gd_sysdate
                       AND    ROWNUM = 1))
          )
-- 2008/11/28 v1.14 ADD START
      -- �ύڏd�ʍ��v�̐�������7���ȏ�̏ꍇ�͏o�͂��Ȃ�
      AND   LENGTHB(TRUNC(NVL(xoha.sum_weight, 0))) < 7
-- 2008/11/28 v1.14 ADD END
      UNION ALL
      -- �����_�o�׈˗�
      SELECT  /*+ leading(xoha otta xdec) use_nl(xoha otta xdec) */
              xoha.order_header_id                order_header_id              -- �󒍃w�b�_�A�h�I��ID
            , xoha.request_no                     request_no                   -- �˗�No
            , xoha.slip_number                    slip_number                  -- �����No
            , xoha.delivery_no                    delivery_no                  -- �z��No
            , xoha.result_freight_carrier_code    result_freight_carrier_code  -- �^���Ǝ�_����
            , xoha.deliver_from                   deliver_from                 -- �o�׌��ۊǏꏊ
            , xoha.result_shipping_method_code    result_shipping_method_code  -- �z���敪_����
            , gv_code_ship                        deliver_to_code_class        -- �z����R�[�h�敪
            , xoha.result_deliver_to              result_deliver_to            -- �o�א�_����
            , xdec.payments_judgment_classe       payments_judgment_classe     -- �x�����f�敪(�^��)
            , xoha.shipped_date                   shipped_date                 -- �o�ד�
            , NVL(xoha.arrival_date, xoha.schedule_arrival_date) arrival_date  -- ���ד�(���ח\���)
            , xoha.shipped_date                   judgement_date               -- ���f��
            , xoha.prod_class                     prod_class                   -- ���i�敪
            , xoha.weight_capacity_class          weight_capacity_class        -- �d�ʗe�ϋ敪
-- ##### 20080717 Ver.1.15 �{��#595�Ή� START #####
--            , xoha.small_quantity                 small_quantity               -- ������
            , NVL(xoha.small_quantity, 0)           small_quantity               -- ������
-- ##### 20080717 Ver.1.15 �{��#595�Ή� END   #####
            ,gv_type_ship                         order_type                   -- �^�C�v
            , xoha.no_cont_freight_class          no_cont_freight_class        -- �_��O�^���敪
            , xoha.transfer_location_code         transfer_location_code       -- �U�֐�
            , SUBSTRB(xoha.shipping_instructions, 1, 40) shipping_instructions -- �o�׎w��(40)
            , NULL                                small_amount_class           -- �����敪
            , NULL                                mixed_class                  -- ���ڋ敪
            , NULL                                ref_small_amount_class       -- ���[�t�����敪
            , NULL                                post_distance                -- �z�������F�ԗ�����
            , NULL                                small_distance               -- �z�������F��������
            , NULL                                consolid_add_distance        -- �z�������F���ڊ�������
            , NULL                                actual_distance              -- �z�������F���ۋ���
            , NULL                                small_weight                 -- �����d��
            , NULL                                pay_picking_amount           -- �x���s�b�L���O�P��
            , NULL                                qty                          -- ��
            , NULL                                delivery_weight              -- �d��
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
            , NVL(xoha.sum_pallet_weight, 0)      sum_pallet_weight            -- ���v�p���b�g�d��
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
      FROM  xxwsh_order_headers_all        xoha,      -- �󒍃w�b�_�A�h�I��
            oe_transaction_types_all       otta,    -- �󒍃^�C�v���VIEW2
            xxwip_delivery_company         xdec     -- �^���p�^���Ǝ҃A�h�I���}�X�^
      WHERE xoha.latest_external_flag = 'Y'                 -- �ŐV�t���O 'Y'
      AND   xoha.shipped_date IS NOT NULL                   -- �o�ד�
--    ���ד����ݒ肳��Ă��Ȃ��Ă��A���o�ΏۂƂ���B
--   �i���ח\����������͒��ד����ݒ肳��Ă��邱�Ƃ��O��j
      AND   (xoha.arrival_date           IS NOT NULL    -- ���ד�
        OR   xoha.schedule_arrival_date  IS NOT NULL)   -- ���ח\���
      AND   xoha.result_shipping_method_code IS NOT NULL    -- �z���敪_����
      AND   xoha.result_freight_carrier_code IS NOT NULL    -- �^���Ǝ�_����
      AND   xoha.delivery_no  IS NOT NULL                   -- �z��No
      AND   xoha.prod_class = xdec.goods_classe                             -- ���i�敪
      AND   xoha.result_freight_carrier_code = xdec.delivery_company_code   -- �^���Ǝ�
      AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                    -- �K�p�J�n��
      AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                    -- �K�p�I����
      AND   xoha.order_type_id       = otta.transaction_type_id -- �󒍃^�C�vID
      AND   xdec.payments_judgment_classe = gv_pay_judg_g    -- �x�����f�敪�i�����j
      AND   xoha.shipped_date >=  gd_target_date             -- �o�ד�
      AND   otta.attribute1  = gv_shipping        -- �o�׈˗�
      AND   xoha.result_deliver_to  IS NOT NULL              -- �o�א�_����
      AND (
            ((xoha.last_update_date > gd_last_process_date)  -- �󒍃w�b�_�F�O�񏈗����t
            AND  (xoha.last_update_date <= gd_sysdate))
          OR ( EXISTS (SELECT 1
                       FROM   xxwsh_order_lines_all xola    -- �󒍖��׃A�h�I��
                       WHERE  xola.order_header_id = xoha.order_header_id
                       AND    xola.last_update_date > gd_last_process_date -- �󒍖��ׁF�O�񏈗����t
                       AND    xola.last_update_date <= gd_sysdate
                       AND    ROWNUM = 1))
          )
-- 2008/11/28 v1.14 ADD START
      -- �ύڏd�ʍ��v�̐�������7���ȏ�̏ꍇ�͏o�͂��Ȃ�
      AND   LENGTHB(TRUNC(NVL(xoha.sum_weight, 0))) < 7
-- 2008/11/28 v1.14 ADD END
      ) order_info
      ;
-- ##### 20081125 Ver.1.13 �{��#104�Ή� END #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order�F�󒍎��ђ��o�����F' || TO_CHAR(gt_order_inf_tab.COUNT));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
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
  END get_order;
--
  /**********************************************************************************
   * Procedure Name   : get_order_other
   * Description      : �󒍊֘A��񒊏o(A-6)
   ***********************************************************************************/
  PROCEDURE get_order_other(
    ov_errbuf           OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_other'; -- �v���O������
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
    lr_ship_method_tab        xxwip_common3_pkg.ship_method_rec;        -- �z���敪
    lr_delivery_distance_tab  xxwip_common3_pkg.delivery_distance_rec;  -- �z������
    lr_delivery_company_tab   xxwip_common3_pkg.delivery_company_rec;   -- �^���p�^���Ǝ�
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
    -- �Ώۃf�[�^���̏ꍇ
    IF (gt_order_inf_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<order_loop>>
    FOR ln_index IN  gt_order_inf_tab.FIRST.. gt_order_inf_tab.LAST LOOP
--
      -- **************************************************
      -- ***  �z���敪���擾(A-6)
      -- **************************************************
      xxwip_common3_pkg.get_ship_method(
        gt_order_inf_tab(ln_index).result_shipping_method_code, -- �z���敪
        gt_order_inf_tab(ln_index).judgement_date,              -- ���f��
        lr_ship_method_tab,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- �����敪�ݒ�
      gt_order_inf_tab(ln_index).small_amount_class := lr_ship_method_tab.small_amount_class;
      -- ���ڋ敪�ݒ�
      gt_order_inf_tab(ln_index).mixed_class        := lr_ship_method_tab.mixed_class;
      -- ���[�t�����敪�ݒ�i���i�敪�����[�t�A�����敪�������j
      IF ((gt_order_inf_tab(ln_index).prod_class = gv_prod_class_lef)
        AND (gt_order_inf_tab(ln_index).small_amount_class = gv_small_sum_yes)) THEN
        -- YES��ݒ�
        gt_order_inf_tab(ln_index).ref_small_amount_class := gv_ktg_yes;
--
      ELSE
        -- NO��ݒ�
        gt_order_inf_tab(ln_index).ref_small_amount_class := gv_ktg_no;
      END IF;
--
      -- **************************************************
      -- ***  �z�������A�h�I���}�X�^���o(A-7)
      -- **************************************************
      xxwip_common3_pkg.get_delivery_distance(
        gt_order_inf_tab(ln_index).prod_class,                    -- ���i�敪
        gt_order_inf_tab(ln_index).result_freight_carrier_code,   -- �^���Ǝ�
        gt_order_inf_tab(ln_index).deliver_from,                  -- �o�ɑq��
        gt_order_inf_tab(ln_index).deliver_to_code_class ,        -- �R�[�h�敪
        gt_order_inf_tab(ln_index).result_deliver_to,             -- �z����R�[�h
        gt_order_inf_tab(ln_index).judgement_date,                -- ���f��
        lr_delivery_distance_tab,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- �ԗ�����
      gt_order_inf_tab(ln_index).post_distance := lr_delivery_distance_tab.post_distance;
      -- ��������
      gt_order_inf_tab(ln_index).small_distance  := lr_delivery_distance_tab.small_distance;
      -- ���ڊ�������
      gt_order_inf_tab(ln_index).consolid_add_distance  := 
                            lr_delivery_distance_tab.consolid_add_distance;
      -- ���ۋ���
      gt_order_inf_tab(ln_index).actual_distance := lr_delivery_distance_tab.actual_distance;
--
      -- **************************************************
      -- ***  �^���p�^���Ǝ҃A�h�I���}�X�^���o(A-8)
      -- **************************************************
      xxwip_common3_pkg.get_delivery_company(
        gt_order_inf_tab(ln_index).prod_class,                  -- ���i�敪
        gt_order_inf_tab(ln_index).result_freight_carrier_code, -- �^���Ǝ�
        gt_order_inf_tab(ln_index).judgement_date,              -- ���f��
        lr_delivery_company_tab,                                -- �^���p�^���Ǝ҃��R�[�h
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- �����d��
      gt_order_inf_tab(ln_index).small_weight       := lr_delivery_company_tab.small_weight;
      -- �x���s�b�L���O�P��
      gt_order_inf_tab(ln_index).pay_picking_amount := lr_delivery_company_tab.pay_picking_amount;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other�F********** �󒍊֘A��񒊏o **********�F' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other�F***** �˗�No   *****�F' || gt_order_inf_tab(ln_index).request_no);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other�F***** �^���Ǝ� *****�F' || gt_order_inf_tab(ln_index).result_freight_carrier_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other�F***** �z��No   *****�F' || gt_order_inf_tab(ln_index).delivery_no);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other�F�����敪      �F' || gt_order_inf_tab(ln_index).small_amount_class);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other�F���ڋ敪      �F' || gt_order_inf_tab(ln_index).mixed_class);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other�F���[�t�����敪�F' || gt_order_inf_tab(ln_index).ref_small_amount_class);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other�F�ԗ�����      �F' || TO_CHAR(gt_order_inf_tab(ln_index).post_distance));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other�F��������      �F' || TO_CHAR(gt_order_inf_tab(ln_index).small_distance));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other�F���ڊ�������  �F' || TO_CHAR(gt_order_inf_tab(ln_index).consolid_add_distance));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other�F���ۋ���      �F' || TO_CHAR(gt_order_inf_tab(ln_index).actual_distance));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other�F�����d��          �F' || TO_CHAR(gt_order_inf_tab(ln_index).small_weight));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_other�F�x���s�b�L���O�P���F' || TO_CHAR(gt_order_inf_tab(ln_index).pay_picking_amount));
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
    END LOOP order_loop;
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
  END get_order_other;
--
  /**********************************************************************************
   * Procedure Name   : get_order_line
   * Description      : �󒍖��׃A�h�I�����o(A-9)
   ***********************************************************************************/
  PROCEDURE get_order_line(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_line'; -- �v���O������
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
    lt_order_line_inf_tab    order_line_inf_tbl;     --�󒍖���
--
    ln_item_id        xxcmn_item_mst2_v.item_id%TYPE;       -- �i��ID
    ln_num_of_cases   xxcmn_item_mst2_v.num_of_cases%TYPE;  -- �P�[�X���萔
    ln_conv_unit      xxcmn_item_mst2_v.conv_unit%TYPE;     -- ���o�Ɋ��Z�P��
    ln_unit           xxcmn_item_mst2_v.unit%TYPE;          -- �d��
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
    ln_capacity       xxcmn_item_mst2_v.capacity%TYPE;      -- �e��
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
--
    ln_qty                           xxwip_deliverys.qty1%TYPE;             -- ��
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
--    ln_delivery_weight               xxwip_deliverys.delivery_weight1%TYPE; -- �d��
    ln_delivery_weight               NUMBER;                                -- �d��
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
    ln_sum_qty                       xxwip_deliverys.qty1%TYPE;             -- ���i���v�j
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
--    ln_sum_delivery_weight           xxwip_deliverys.delivery_weight1%TYPE; -- �d�ʁi���v�j
    ln_sum_delivery_weight           NUMBER;                                -- �d�ʁi���v�j
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
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
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F********** �󒍖��׃A�h�I�����o **********');
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
    -- �Ώۃf�[�^���̏ꍇ
    IF (gt_order_inf_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<order_loop>>
    FOR ln_index IN  gt_order_inf_tab.FIRST.. gt_order_inf_tab.LAST LOOP
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F********** �󒍃w�b�_�A�h�I�����o **********�F' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F�˗�No   �F' || gt_order_inf_tab(ln_index).request_no);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F�^���Ǝ� �F' || gt_order_inf_tab(ln_index).result_freight_carrier_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F�z��No   �F' || gt_order_inf_tab(ln_index).delivery_no);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- **************************************************
      -- ***  �󒍖��׃A�h�I�����o(A-9)
      -- **************************************************
      -- �ϐ�������
      lt_order_line_inf_tab.DELETE;
--
      SELECT  xola.order_header_id                  -- �󒍃w�b�_�A�h�I��ID
            , xola.shipping_item_code               -- �o�וi��
-- ##### 20080625 Ver.1.2 �o�׎��ѐ���NULL�Ή� START #####
/***
            , xola.shipped_quantity                 -- �o�׎��ѐ���
***/
            , NVL(xola.shipped_quantity, 0)          -- �o�׎��ѐ���
-- ##### 20080625 Ver.1.2 �o�׎��ѐ���NULL�Ή� END   #####
      BULK COLLECT INTO lt_order_line_inf_tab
      FROM  xxwsh_order_lines_all          xola     -- �󒍖��׃A�h�I��
      WHERE xola.order_header_id = 
                gt_order_inf_tab(ln_index).order_header_id  -- �󒍃w�b�_�A�h�I��ID
      AND   NVL(xola.delete_flag, gv_ktg_no)  = gv_ktg_no;  -- �폜�t���O
--
      -- ���v�l ������
      ln_sum_qty             := 0;  -- ���i���v�j
      ln_sum_delivery_weight := 0;  -- �d�ʁi���v�j
--
      -- �Ώۃf�[�^���̏ꍇ
      IF (lt_order_line_inf_tab.COUNT = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                      gv_xxcmn_msg_notfnd,
                                      gv_tkn_table,
                                      gv_order_headers_all,
                                      gv_tkn_key,
                                      gt_order_inf_tab(ln_index).order_header_id);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      <<order_line_loop>>
      FOR ln_line_index IN  lt_order_line_inf_tab.FIRST.. lt_order_line_inf_tab.LAST LOOP
--
        -- **************************************************
        -- ***  ��OPM�i�ڏ��VIEW���o(A-10)
        -- **************************************************
        -- �ϐ�������
        ln_num_of_cases := NULL;        -- �P�[�X���萔
        ln_conv_unit    := NULL;        -- ���o�Ɋ��Z�P��
        ln_unit         := NULL;        -- �d��
--
        -- ���o�Ɋ��Z�P�ʁA�P�[�X���萔�A�d�� �擾
        BEGIN
          SELECT ximv.item_id         -- �i��ID
               , ximv.num_of_cases    -- �P�[�X���萔
               , ximv.conv_unit       -- ���o�Ɋ��Z�P��
               , ximv.unit            -- �d��
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
               , ximv.capacity        -- �e��
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
          INTO   ln_item_id
               , ln_num_of_cases
               , ln_conv_unit
               , ln_unit
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
               , ln_capacity
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
          FROM   xxcmn_item_mst2_v    ximv    -- OPM�i�ڏ��VIEW2
          WHERE  ximv.item_no = 
                 lt_order_line_inf_tab(ln_line_index).shipping_item_code -- �i�ڃR�[�h
          AND    gt_order_inf_tab(ln_index).judgement_date >= ximv.start_date_active  -- �K�p�J�n��
          AND    gt_order_inf_tab(ln_index).judgement_date <= ximv.end_date_active;   -- �K�p�I����
        EXCEPTION
          WHEN NO_DATA_FOUND THEN   -- *** �f�[�^�擾�G���[ ***
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                          gv_xxcmn_msg_notfnd,
                                          gv_tkn_table,
                                          gv_item_mst2_v,
                                          gv_tkn_key,
                                          lt_order_line_inf_tab(ln_line_index).shipping_item_code);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
--
          WHEN TOO_MANY_ROWS THEN   -- *** �f�[�^�����擾�G���[ ***
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                          gv_xxcmn_msg_toomny,
                                          gv_tkn_table,
                                          gv_item_mst2_v,
                                          gv_tkn_key,
                                          lt_order_line_inf_tab(ln_line_index).shipping_item_code);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
        -- **************************************************
        -- ***  �󒍌��^�d�ʎZ�o(A-11)
        -- **************************************************
        -- �ϐ�������
        ln_qty              := 0;
        ln_delivery_weight  := 0;
--
        -- *** �� �Z�o ***
        -- ���[�t�����敪 �� Y �̏ꍇ
        IF (gt_order_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes) THEN
          -- ���ɏ�������ݒ�
          ln_qty := gt_order_inf_tab(ln_index).small_quantity;
--
        -- ���[�t�����敪 �� N �̏ꍇ
        ELSE
          -- ���� deliv_rcv_ship_conv_qty �̖߂�l��ݒ�
          ln_qty := xxwip_common3_pkg.deliv_rcv_ship_conv_qty(
                        lt_order_line_inf_tab(ln_line_index).shipping_item_code -- �i�ڃR�[�h
                      , lt_order_line_inf_tab(ln_line_index).shipped_quantity); -- ����
        END IF;
--
        -- *** �d�� �Z�o ***
        -- ���[�t�����敪 �� Y ���� �d�ʗe�ϋ敪 �� �e�ς̏ꍇ
        IF ((gt_order_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes )
          AND (gt_order_inf_tab(ln_index).weight_capacity_class = gv_capacity )) THEN
          -- ��L�Z�o�̌� �~ �����d��
          ln_delivery_weight :=
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
--                ln_qty * gt_order_inf_tab(ln_index).small_weight;
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
--                CEIL(ln_qty * gt_order_inf_tab(ln_index).small_weight);
                ln_qty * gt_order_inf_tab(ln_index).small_weight;
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
--
        -- ��L�ȊO
        ELSE
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
          -- �d�ʗe�ϋ敪���u�e�ρv�̏ꍇ
          IF (gt_order_inf_tab(ln_index).weight_capacity_class = gv_capacity) THEN
            -- �e�� �~ �o�׎��ѐ��ʁi�؏�j�~1000000
            ln_delivery_weight :=
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
--                  CEIL(ln_capacity * lt_order_line_inf_tab(ln_line_index).shipped_quantity / 1000000);
                  ln_capacity * lt_order_line_inf_tab(ln_line_index).shipped_quantity / 1000000;
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
--
          -- �d�ʗe�ϋ敪���u�d�ʁv�̏ꍇ
          ELSE
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
            -- �d�� �~ �o�׎��ѐ��ʁi�؏�j
            ln_delivery_weight :=
-- ##### 20080715 Ver.1.3 ST��Q#452�Ή� START #####
--                ROUND(ln_unit * lt_order_line_inf_tab(ln_line_index).shipped_quantity / 1000);
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
--                  CEIL(ln_unit * lt_order_line_inf_tab(ln_line_index).shipped_quantity / 1000);
                  ln_unit * lt_order_line_inf_tab(ln_line_index).shipped_quantity / 1000;
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
-- ##### 20080715 Ver.1.3 ST��Q#452�Ή� END   #####
--
          END IF;
        END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F********** �󒍖��׃A�h�I�� **********�F' || TO_CHAR(ln_line_index));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F�󒍃w�b�_�A�h�I��ID �F' || lt_order_line_inf_tab(ln_line_index).order_header_id);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F�o�וi��             �F' || lt_order_line_inf_tab(ln_line_index).shipping_item_code);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F�o�׎��ѐ���         �F' || lt_order_line_inf_tab(ln_line_index).shipped_quantity);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F***** ���� *****');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F���[�t�����敪�F' || gt_order_inf_tab(ln_index).ref_small_amount_class);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F�d�ʗe�ϋ敪  �F' || gt_order_inf_tab(ln_index).weight_capacity_class);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F***** OPM�i�� *****');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F�i��ID        �F' || ln_item_id);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F�P�[�X���萔  �F' || TO_CHAR(ln_num_of_cases));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F���o�Ɋ��Z�P�ʁF' || ln_conv_unit);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F�d��          �F' || TO_CHAR(ln_unit));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F�e��          �F' || TO_CHAR(ln_capacity));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F***** �Z�o���� *****');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F��         �F' || TO_CHAR(ln_qty));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F�d��         �F' || TO_CHAR(ln_delivery_weight));
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- **************************************************
        -- ***  �󒍌��^�d�ʏW�v(A-12)
        -- **************************************************
        -- ���i���v�j
        -- ���[�t�����敪 �� Y �̏ꍇ
        IF (gt_order_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes) THEN
          ln_sum_qty := ln_qty;
        ELSE
          ln_sum_qty := ln_sum_qty + ln_qty;
        END IF;
--
        -- �d�ʁi���v�j
        -- ���[�t�����敪 �� Y ���� �d�ʗe�ϋ敪 �� �e�ς̏ꍇ
        IF ((gt_order_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes )
          AND (gt_order_inf_tab(ln_index).weight_capacity_class = gv_capacity )) THEN
          ln_sum_delivery_weight := ln_delivery_weight;
        ELSE
          ln_sum_delivery_weight := ln_sum_delivery_weight + ln_delivery_weight;
        END IF;
--
      END LOOP order_line_loop;
--
      -- ���v�i���A�d�ʁj�ݒ�
      gt_order_inf_tab(ln_index).qty              := ln_sum_qty;
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
--      gt_order_inf_tab(ln_index).delivery_weight  := ln_sum_delivery_weight;
--
      -- �d�ʗe�ϋ敪���u�d�ʁv�E�����敪���u�ԗ��v�̏ꍇ
      IF   ((gt_order_inf_tab(ln_index).weight_capacity_class = gv_weight)
        AND (gt_order_inf_tab(ln_index).small_amount_class    = gv_small_sum_no)) THEN
        -- ���׏d�ʂ��T�}���������_�ȉ�����؏サ�A���v�p���b�g�d�ʂ����Z
        gt_order_inf_tab(ln_index).delivery_weight  := CEIL(TRUNC(ln_sum_delivery_weight, 1)) + 
                                                     gt_order_inf_tab(ln_index).sum_pallet_weight ;
--
      -- ��L�ȊO
      ELSE
        -- ���׏d�ʂ��T�}���������_�ȉ�����؏�
        gt_order_inf_tab(ln_index).delivery_weight  := CEIL(TRUNC(ln_sum_delivery_weight, 1));
      END IF;
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F********** �󒍌��^�d�ʏW�v **********');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F���i���v�j�F' || TO_CHAR(gt_order_inf_tab(ln_index).qty));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F�d�ʁi���v�j�F' || TO_CHAR(gt_order_inf_tab(ln_index).delivery_weight));
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
    END LOOP order_loop;
--
  EXCEPTION
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 START #####
    WHEN func_inv_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 END   #####
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
  END get_order_line;
--
  /**********************************************************************************
   * Procedure Name   : set_order_deliv_line
   * Description      : �󒍉^�����׃A�h�I��PL/SQL�\�i�[(A-13)
   ***********************************************************************************/
  PROCEDURE set_order_deliv_line(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_order_deliv_line'; -- �v���O������
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
    lv_delivery_company_code  xxwip_delivery_lines.delivery_company_code%TYPE;  -- �^���Ǝ�
    lv_whs_code               xxwip_delivery_lines.whs_code%TYPE;               -- �o�ɑq��
    lv_shipping_address_code  xxwip_delivery_lines.shipping_address_code%TYPE;  -- �z����R�[�h
    lv_dellivary_classe       xxwip_delivery_lines.dellivary_classe%TYPE;       -- �z���敪
    ln_qty                    xxwip_delivery_lines.qty%TYPE;                    -- ��
    ln_delivery_weight        xxwip_delivery_lines.delivery_weight%TYPE;        -- �d��
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
    ld_ship_date              xxwip_delivery_lines.ship_date%TYPE;              -- �o�ד�
    ld_arrival_date           xxwip_delivery_lines.arrival_date%TYPE;           -- ���ד�
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
    lv_payments_judgment_classe   xxwip_delivery_lines.payments_judgment_classe%TYPE; -- �x�����f�敪
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
-- ##### 20081210 Ver.1.16 �{��#401�Ή� START #####
    lv_delivery_no            xxwip_delivery_lines.delivery_no%TYPE;            -- �z��No
    ln_deli_cnt               NUMBER;
-- ##### 20081210 Ver.1.16 �{��#401�Ή� END   #####
--
    ln_deliv_line_flg         VARCHAR2(1);      -- �󒍖��׃A�h�I�� ���݃t���O Y:�L N:��
--
    ln_line_insert_cnt        NUMBER;           -- �o�^�pPL/SQL�\ ����
    ln_line_calc_update_cnt   NUMBER;           -- �Čv�Z�X�V�pPL/SQL�\ ����
    ln_line_des_update_cnt    NUMBER;           -- �E�v�o�^�pPL/SQL�\ ����
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
    -- ����������
    ln_line_insert_cnt      := 0 ;  -- �o�^�pPL/SQL�\ ����
    ln_line_calc_update_cnt := 0 ;  -- �Čv�Z�X�V�pPL/SQL�\ ����
    ln_line_des_update_cnt  := 0 ;  -- �E�v�o�^�pPL/SQL�\ ����
--
    -- �Ώۃf�[�^���̏ꍇ
    IF (gt_order_inf_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<order_loop>>
    FOR ln_index IN  gt_order_inf_tab.FIRST.. gt_order_inf_tab.LAST LOOP
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line�F********** �󒍉^�����׃A�h�I��PL/SQL�\�i�[ **********�F' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line�F�˗�No   �F' || gt_order_inf_tab(ln_index).request_no);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line�F�^���Ǝ� �F' || gt_order_inf_tab(ln_index).result_freight_carrier_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line�F�z��No   �F' || gt_order_inf_tab(ln_index).delivery_no);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
      -- **************************************************
      -- ***  �^���w�b�_�A�h�I�����o
      -- **************************************************
      -- ���݃t���O������
      ln_deliv_line_flg := gv_ktg_yes;
--
      BEGIN
        SELECT  xwdl.delivery_company_code  -- �^���Ǝ�
              , xwdl.whs_code               -- �o�ɑq��
              , xwdl.shipping_address_code  -- �z����R�[�h
              , xwdl.dellivary_classe       -- �z���敪
              , xwdl.qty                    -- ��
              , xwdl.delivery_weight        -- �d��
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
              , xwdl.ship_date              -- �o�ד�
              , xwdl.arrival_date           -- ���ד�
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
-- ##### 20081210 Ver.1.16 �{��#401�Ή� START #####
              , xwdl.delivery_no            -- �z��No
-- ##### 20081210 Ver.1.16 �{��#401�Ή� END   #####
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
              , payments_judgment_classe    -- �x�����f�敪
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
        INTO    lv_delivery_company_code
              , lv_whs_code
              , lv_shipping_address_code
              , lv_dellivary_classe
              , ln_qty
              , ln_delivery_weight
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
              , ld_ship_date                -- �o�ד�
              , ld_arrival_date             -- ���ד�
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
-- ##### 20081210 Ver.1.16 �{��#401�Ή� START #####
              , lv_delivery_no              -- �z��No
-- ##### 20081210 Ver.1.16 �{��#401�Ή� END   #####
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
              , lv_payments_judgment_classe   -- �x�����f�敪
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
        FROM   xxwip_delivery_lines xwdl    -- �^�����׃A�h�I��
        WHERE  xwdl.request_no = gt_order_inf_tab(ln_index).request_no; -- �˗�No
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   -- *** �f�[�^�擾�G���[ ***
          -- ���݃t���O Y ��ݒ�
          ln_deliv_line_flg := gv_ktg_no;
--
        WHEN TOO_MANY_ROWS THEN   -- *** �f�[�^�����擾�G���[ ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                        gv_xxcmn_msg_toomny,
                                        gv_tkn_table,
                                        gv_delivery_lines,
                                        gv_tkn_key,
                                        gt_order_inf_tab(ln_index).request_no);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line�F********** �^���w�b�_�A�h�I�� **********�F' || ln_deliv_line_flg);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line�F�^���Ǝ�     �F' || lv_delivery_company_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line�F�o�ɑq��     �F' || lv_whs_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line�F�z����R�[�h �F' || lv_shipping_address_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line�F�z���敪     �F' || lv_dellivary_classe);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line�F��         �F' || TO_CHAR(ln_qty));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line�F�d��         �F' || TO_CHAR(ln_delivery_weight));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line�F�o�ד�       �F' || TO_CHAR(ld_ship_date    ,'YYYY/MM/DD'));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line�F���ד�       �F' || TO_CHAR(ld_arrival_date ,'YYYY/MM/DD'));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line�F�z��No       �F' || lv_delivery_no);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line�F�x�����f�敪 �F' || lv_payments_judgment_classe);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
-- ##### 20081210 Ver.1.16 �{��#401�Ή� START #####
--
      -- **************************************************
      -- ***  �z��No�̕ύX�ɂ��폜����
      -- **************************************************
      -- �^�����׃A�h�I�������݂���ꍇ
      IF (ln_deliv_line_flg = gv_ktg_yes) THEN
        -- �^�����ׂ̔z��No�Ǝ��т̔z��No���قȂ�ꍇ
        IF (gt_order_inf_tab(ln_index).delivery_no <> lv_delivery_no) THEN
          -- ���z��No�̌����擾
          BEGIN
            SELECT  COUNT(delivery_no)
            INTO    ln_deli_cnt
            FROM    xxwip_delivery_lines xwdl           -- �^�����׃A�h�I��
            WHERE   xwdl.delivery_no = lv_delivery_no;  -- �z��No
          END;
  --
          -- ���z��No���^�����ׂ�1���̏ꍇ
          -- �������̏ꍇ�͍��ځA�W��ł��邽�߁A�폜���Ȃ�
          IF ( ln_deli_cnt = 1 ) THEN
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
            IF (gv_debug_flg = gv_debug_on) THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F�z���g�� ��DELETE�F' ||
                                                                  lv_delivery_no || '->' ||
                                          gt_order_inf_tab(ln_index).delivery_no);
            END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
            -- �^���w�b�_���폜����
            BEGIN
              -- �Ώ۔z��No���폜����
              DELETE FROM xxwip_deliverys
              WHERE delivery_no = lv_delivery_no;
            END;
          END IF;
        END IF;
      END IF;
--
-- ##### 20081210 Ver.1.16 �{��#401�Ή� END   #####
--
      -- **************************************************
      -- ***  �^�����׃A�h�I���Ƀf�[�^�����݂��Ȃ��ꍇ
      -- **************************************************
      IF (ln_deliv_line_flg = gv_ktg_no) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_order_line�F�^�����׃A�h�I�� INSERT');
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- �o�^�pPL/SQL�\ ����
        ln_line_insert_cnt  := ln_line_insert_cnt + 1;
--
        -- �^�����דo�^�pPL/SQL�\ �ݒ�
        -- �^�����׃A�h�I��ID
        i_line_deliv_lines_id_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).order_header_id;
        -- �˗�No
        i_line_request_no_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).request_no;
        -- �����No
        i_line_invoice_no_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).slip_number;
        -- �z��No
        i_line_deliv_no_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).delivery_no;
        -- ���[�t�����敪
        i_line_small_lot_cls_tab(ln_line_insert_cnt)   := 
                        gt_order_inf_tab(ln_index).ref_small_amount_class;
         -- �^���Ǝ�
        i_line_deliv_cmpny_cd_tab(ln_line_insert_cnt)  := 
                        gt_order_inf_tab(ln_index).result_freight_carrier_code;
        -- �o�ɑq�ɃR�[�h
        i_line_whs_code_tab(ln_line_insert_cnt)        := 
                        gt_order_inf_tab(ln_index).deliver_from;
         -- �z���敪
        i_line_delliv_cls_tab(ln_line_insert_cnt) := 
                        gt_order_inf_tab(ln_index).result_shipping_method_code;
        -- �z����R�[�h�敪
        i_line_code_division_tab(ln_line_insert_cnt) := 
                        gt_order_inf_tab(ln_index).deliver_to_code_class;
        -- �z����R�[�h
        i_line_ship_addr_cd_tab(ln_line_insert_cnt) := 
                        gt_order_inf_tab(ln_index).result_deliver_to;
        -- �x�����f�敪
        i_line_pay_judg_cls_tab(ln_line_insert_cnt) := 
                        gt_order_inf_tab(ln_index).payments_judgment_classe;
        -- �o�ɓ�
        i_line_ship_date_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).shipped_date;  
        -- ������
        i_line_arrival_date_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).arrival_date;
        -- �񍐓�
        i_line_report_date_tab(ln_line_insert_cnt)  := NULL;
        -- ���f��
        i_line_judg_date_tab(ln_line_insert_cnt)  := gt_order_inf_tab(ln_index).judgement_date;
        -- ���i�敪
        i_line_goods_cls_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).prod_class;
        -- �d�ʗe�ϋ敪
        i_line_weight_cap_cls_tab(ln_line_insert_cnt)  := 
                      gt_order_inf_tab(ln_index).weight_capacity_class;
--
        -- ���[�t�����敪 �� Y�̏ꍇ
        IF (gt_order_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes) THEN
            -- ��������
            i_line_ditnc_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).small_distance;
--
-- ##### 20090209 Ver.1.22 �{��#1107�Ή� START #####
-- �����敪=�u�����v�͏��������A�u�ԗ��v�͎ԗ�������ݒ�
        -- ���i�敪 �� ���[�t   ���� 
        -- ���i�敪 �� �h�����N ���A���ڋ敪 ���� ���� �̏ꍇ
--        ELSIF (
--                  (gt_order_inf_tab(ln_index).prod_class = gv_prod_class_lef)
--                OR    
--                  ((gt_order_inf_tab(ln_index).prod_class = gv_prod_class_drk)
--                  AND (gt_order_inf_tab(ln_index).mixed_class <> gv_target_y))
--              ) THEN
          -- �ԗ�����
--          i_line_ditnc_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).post_distance;
--
        -- ��L�ȊO
--        ELSE
--
-- ##### 20081027 Ver.1.10 ����#436�Ή� START #####
          -- �ԗ������i���ׂւ͍��ڊ������������Z���Ȃ��j
--          i_line_ditnc_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).post_distance +
--                                                  gt_order_inf_tab(ln_index).consolid_add_distance;
--          i_line_ditnc_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).post_distance;
-- ##### 20081027 Ver.1.10 ����#436�Ή� END   #####
        ELSE
          -- �����敪���u�����v�̏ꍇ
          IF (gt_order_inf_tab(ln_index).small_amount_class = gv_small_sum_yes) THEN
            -- ����������ݒ�
            i_line_ditnc_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).small_distance;
--
          -- �����敪���u�ԗ��v�̏ꍇ
          ELSE
            -- �ԗ��ċ�����ݒ�
            i_line_ditnc_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).post_distance;
          END IF;
--
-- ##### 20090209 Ver.1.22 �{��#1107�Ή� END   #####
        END IF;
--
        -- ���ۋ���
        i_line_actual_dstnc_tab(ln_line_insert_cnt) := 
                                            gt_order_inf_tab(ln_index).actual_distance;
        -- ��
        i_line_qty_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).qty;
        -- �d��
        i_line_deliv_weight_tab(ln_line_insert_cnt) := 
                                            gt_order_inf_tab(ln_index).delivery_weight;
        -- �^�C�v
        i_line_order_tab_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).order_type;
        -- ���ڋ敪
        i_line_mixed_code_tab(ln_line_insert_cnt) := gt_order_inf_tab(ln_index).mixed_class;
        -- �_��O�敪
        i_line_outside_cntrct_tab(ln_line_insert_cnt) := 
                                            gt_order_inf_tab(ln_index).no_cont_freight_class;
        -- �U�֐�
        i_line_trans_locat_tab(ln_line_insert_cnt) := 
                                            gt_order_inf_tab(ln_index).transfer_location_code;
        -- �E�v
        i_line_description_tab(ln_line_insert_cnt) := 
                                            gt_order_inf_tab(ln_index).shipping_instructions;
--
      -- **************************************************
      -- ***  �^�����׃A�h�I���Ƀf�[�^�����݂���ꍇ
      -- **************************************************
      ELSE
        -- **************************************************
        -- ***  �o�^����Ă�����e���Čv�Z���K�v�ȏꍇ
        -- **************************************************
        --   �Ώۍ��ځF�^���ƎҁA�o�ɑq�ɁA�z����R�[�h�A�z���敪�A�z��No�A���A�d�ʁA�o�ɓ��A���ɓ��A�x�����f�敪
-- ##### 20090123 Ver.1.20 �{��#1074 START #####
-- �X�V���̏������Ȃ����A�ύX���������ꍇ�͍X�V����悤�ɏC��
/*****
        IF ((gt_order_inf_tab(ln_index).result_freight_carrier_code  <> lv_delivery_company_code )
          OR (gt_order_inf_tab(ln_index).deliver_from                 <> lv_whs_code              )
          OR (gt_order_inf_tab(ln_index).result_deliver_to            <> lv_shipping_address_code )
          OR (gt_order_inf_tab(ln_index).result_shipping_method_code  <> lv_dellivary_classe      )
-- ##### 20081210 Ver.1.16 �{��#401�Ή� START #####
          OR (gt_order_inf_tab(ln_index).delivery_no                  <> lv_delivery_no           )
-- ##### 20081210 Ver.1.16 �{��#401�Ή� END   #####
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
          OR (gt_order_inf_tab(ln_index).shipped_date  <>  ld_ship_date     )
          OR (gt_order_inf_tab(ln_index).arrival_date  <>  ld_arrival_date  )
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
          OR (gt_order_inf_tab(ln_index).payments_judgment_classe  <>  lv_payments_judgment_classe  )
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
          OR (gt_order_inf_tab(ln_index).qty                          <> ln_qty                   )
          OR (gt_order_inf_tab(ln_index).delivery_weight              <> ln_delivery_weight       )) THEN
*****/
-- ##### 20090123 Ver.1.20 �{��#1074 END   #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line�F�^�����׃A�h�I�� UPDATE �Čv�Z');
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- �Čv�Z�X�V�pPL/SQL�\ ����
          ln_line_calc_update_cnt   := ln_line_calc_update_cnt + 1;
--
          -- �^�����׃A�h�I��
          -- �˗�No
          us_line_request_no_tab(ln_line_calc_update_cnt) := 
                          gt_order_inf_tab(ln_index).request_no;
          -- �����No
          us_line_invoice_no_tab(ln_line_calc_update_cnt) := 
                                          gt_order_inf_tab(ln_index).slip_number;
          -- �z��No
          us_line_deliv_no_tab(ln_line_calc_update_cnt) := gt_order_inf_tab(ln_index).delivery_no;
          -- ���[�t�����敪
          us_line_small_lot_cls_tab(ln_line_calc_update_cnt) := 
                                          gt_order_inf_tab(ln_index).ref_small_amount_class;
          -- �^���Ǝ�
          us_line_deliv_cmpny_cd_tab(ln_line_calc_update_cnt) := 
                                          gt_order_inf_tab(ln_index).result_freight_carrier_code;
          -- �o�ɑq�ɃR�[�h
          us_line_whs_code_tab(ln_line_calc_update_cnt) := 
                                          gt_order_inf_tab(ln_index).deliver_from;
          -- �z���敪
          us_line_delliv_cls_tab(ln_line_calc_update_cnt) := 
                                          gt_order_inf_tab(ln_index).result_shipping_method_code;
          -- �z����R�[�h�敪
          us_line_code_division_tab(ln_line_calc_update_cnt)  :=
                                          gt_order_inf_tab(ln_index).deliver_to_code_class;
          -- �z����R�[�h
          us_line_ship_addr_cd_tab(ln_line_calc_update_cnt) := 
                                          gt_order_inf_tab(ln_index).result_deliver_to;
          -- �x�����f�敪
          us_line_pay_judg_cls_tab(ln_line_calc_update_cnt) := 
                                          gt_order_inf_tab(ln_index).payments_judgment_classe;
          -- �o�ɓ�
          us_line_ship_date_tab(ln_line_calc_update_cnt) := gt_order_inf_tab(ln_index).shipped_date;
          -- ������
          us_line_arrival_date_tab(ln_line_calc_update_cnt) := 
                                          gt_order_inf_tab(ln_index).arrival_date;
          -- ���f��
          us_line_judg_date_tab(ln_line_calc_update_cnt)         := 
                                          gt_order_inf_tab(ln_index).judgement_date;
          -- ���i�敪
          us_line_goods_cls_tab(ln_line_calc_update_cnt)  := 
                                          gt_order_inf_tab(ln_index).prod_class;
          -- �d�ʗe�ϋ敪
          us_line_weight_cap_cls_tab(ln_line_calc_update_cnt) := 
                                          gt_order_inf_tab(ln_index).weight_capacity_class;
--
          -- ���[�t�����敪 �� Y�̏ꍇ
          IF (gt_order_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes) THEN
            -- ��������
            us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_order_inf_tab(ln_index).small_distance;
--
-- ##### 20090209 Ver.1.22 �{��#1107�Ή� START #####
-- �����敪=�u�����v�͏��������A�u�ԗ��v�͎ԗ�������ݒ�
          -- ���i�敪 �� ���[�t   ���� 
          -- ���i�敪 �� �h�����N ���A���ڋ敪 ���� ���� �̏ꍇ
--          ELSIF (
--                    (gt_order_inf_tab(ln_index).prod_class = gv_prod_class_lef)
--                  OR    
--                    ((gt_order_inf_tab(ln_index).prod_class = gv_prod_class_drk)
--                    AND (gt_order_inf_tab(ln_index).mixed_class <> gv_target_y))
--                ) THEN
            -- �ԗ�����
--            us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_order_inf_tab(ln_index).post_distance;
--
          -- ��L�ȊO
--          ELSE
--
-- ##### 20081027 Ver.1.10 ����#436�Ή� START #####
          -- �ԗ������i���ׂւ͍��ڊ������������Z���Ȃ��j
--            us_line_ditnc_tab(ln_line_calc_update_cnt) := 
--                                    gt_order_inf_tab(ln_index).post_distance +
--                                    gt_order_inf_tab(ln_index).consolid_add_distance;
--            us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_order_inf_tab(ln_index).post_distance;
-- ##### 20081027 Ver.1.10 ����#436�Ή� END   #####
          ELSE
            -- �����敪���u�����v�̏ꍇ
            IF (gt_order_inf_tab(ln_index).small_amount_class = gv_small_sum_yes) THEN
              -- ����������ݒ�
              us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_order_inf_tab(ln_index).small_distance;
--
            -- �����敪���u�ԗ��v�̏ꍇ
            ELSE
              -- �ԗ��ċ�����ݒ�
              us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_order_inf_tab(ln_index).post_distance;
            END IF;
--
-- ##### 20090209 Ver.1.22 �{��#1107�Ή� END   #####
          END IF;
--
          -- ���ۋ���
          us_line_actual_dstnc_tab(ln_line_calc_update_cnt) := 
                                            gt_order_inf_tab(ln_index).actual_distance;
          -- ��
          us_line_qty_tab(ln_line_calc_update_cnt) := gt_order_inf_tab(ln_index).qty;
          -- �d��
          us_line_deliv_weight_tab(ln_line_calc_update_cnt) := 
                                            gt_order_inf_tab(ln_index).delivery_weight;
          -- �^�C�v
          us_line_order_tab_tab(ln_line_calc_update_cnt)  := gt_order_inf_tab(ln_index).order_type;
          -- ���ڋ敪
          us_line_mixed_code_tab(ln_line_calc_update_cnt) := gt_order_inf_tab(ln_index).mixed_class;
          -- �_��O�敪
          us_line_outside_cntrct_tab(ln_line_calc_update_cnt) := 
                                                gt_order_inf_tab(ln_index).no_cont_freight_class;
          -- �U�֐�
          us_line_trans_locat_tab(ln_line_calc_update_cnt) := 
                                                gt_order_inf_tab(ln_index).transfer_location_code;
          -- �E�v
          us_line_description_tab(ln_line_calc_update_cnt) := 
                                                gt_order_inf_tab(ln_index).shipping_instructions;
--
        -- **************************************************
        -- ***  �o�^����Ă�����e���Čv�Z���K�v�łȂ��ꍇ
        -- **************************************************
-- ##### 20090123 Ver.1.20 �{��#1074 START #####
-- �K�p�݂̂̍X�V�����͔p�~����
/*****
        ELSE
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_order_deliv_line�F�^�����׃A�h�I�� UPDATE �E�v');
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- �E�v�o�^�pPL/SQL�\ ����
          ln_line_des_update_cnt := ln_line_des_update_cnt + 1;
--
          -- �^�����׃A�h�I��
          -- �˗�No
          ut_line_request_no_tab(ln_line_des_update_cnt)  := gt_order_inf_tab(ln_index).request_no;
          -- �E�v
          ut_line_description_tab(ln_line_des_update_cnt) := 
                                gt_order_inf_tab(ln_index).shipping_instructions;
--
        END IF;
*****/
-- ##### 20090123 Ver.1.20 �{��#1074 END   #####
      END IF;
--
    END LOOP order_loop;
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
  END set_order_deliv_line;
--
  /**********************************************************************************
   * Procedure Name   : get_move
   * Description      : �ړ����я�񒊏o(A-14)
   ***********************************************************************************/
  PROCEDURE get_move(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_move'; -- �v���O������
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
-- ##### 20081125 Ver.1.13 �{��#104�Ή� START #####
    -- �ړ����я�� ���o
    /*SELECT    xmrih.mov_hdr_id                                    -- �ړ��w�b�_ID
            , xmrih.mov_num                                       -- �ړ��ԍ�
            , xmrih.slip_number                                   -- �����No
            , xmrih.delivery_no                                   -- �z��No
            , xmrih.actual_freight_carrier_code                   -- �^���Ǝ�_����
            , xmrih.shipped_locat_code                            -- �o�Ɍ��ۊǏꏊ
            , xmrih.actual_shipping_method_code                   -- �z���敪
            , gv_code_move                                        -- �z����R�[�h�敪�i�R�F�q�Ɂj
            , xmrih.ship_to_locat_code                            -- ���ɐ�ۊǏꏊ
            , xdec.payments_judgment_classe                       -- �x�����f�敪(�^��)
            , xmrih.actual_ship_date                              -- �o�Ɏ��ѓ�
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
--            , xmrih.actual_arrival_date                           -- ���Ɏ��ѓ�
            , NVL(xmrih.actual_arrival_date, xmrih.schedule_arrival_date) -- ���Ɏ��ѓ�(���ɗ\���)
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
            , CASE xdec.payments_judgment_classe                  -- ���f��
              WHEN gv_pay_judg_g  THEN xmrih.actual_ship_date     --   ����
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
--              WHEN gv_pay_judg_c  THEN xmrih.actual_arrival_date  --   ����
              WHEN gv_pay_judg_c  THEN NVL(xmrih.actual_arrival_date, xmrih.schedule_arrival_date)  -- ����
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
              END
            , xmrih.item_class                                    -- ���i�敪
            , xmrih.weight_capacity_class                         -- �d�ʗe�ϋ敪
            , xmrih.small_quantity                                -- ������
            , xmrih.sum_quantity                                  -- ���v����
            , gv_type_move                                        -- �^�C�v�i�R�F�ړ��j
            , xmrih.no_cont_freight_class                         -- �_��O�^���敪
            , NULL                                                -- �U�֐�
            , SUBSTRB(xmrih.description, 1, 40)                   -- �E�v�i40�j
            , NULL                                                -- �z���敪�F�����敪
            , NULL                                                -- �z���敪�F���ڋ敪
            , NULL                                                -- �z���敪�F���[�t�����敪
            , NULL                                                -- �z�������F�ԗ�����
            , NULL                                                -- �z�������F��������
            , NULL                                                -- �z�������F���ڊ�������
            , NULL                                                -- �z�������F���ۋ���
            , NULL                                                -- �^���ƎҁF�����d��
            , NULL                                                -- �^���ƎҁF�x���s�b�L���O�P��
            , NULL                                                -- ��
            , NULL                                                -- �d��
    BULK COLLECT INTO gt_move_inf_tab
    FROM  xxinv_mov_req_instr_headers    xmrih,   -- �ړ��˗�/�w���w�b�_(�A�h�I��)
          xxwip_delivery_company         xdec     -- �^���p�^���Ǝ҃A�h�I���}�X�^
    WHERE xmrih.actual_ship_date IS NOT NULL            -- �o�Ɏ��ѓ�
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 START #####
--
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
--    AND   xmrih.actual_arrival_date IS NOT NULL         -- ���Ɏ��ѓ�
    AND  (xmrih.actual_arrival_date IS NOT NULL           -- ���Ɏ��ѓ�
      OR  xmrih.schedule_arrival_date  IS NOT NULL)       -- ���ɗ\���
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
--
    AND   xmrih.actual_shipping_method_code IS NOT NULL -- �z���敪_����
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 END   #####
    AND   xmrih.actual_freight_carrier_code IS NOT NULL -- �^���Ǝ�_����
    AND   xmrih.delivery_no IS NOT NULL                 -- �z��No
    AND   xmrih.item_class = xdec.goods_classe                              -- ���i�敪
    AND   xmrih.actual_freight_carrier_code = xdec.delivery_company_code    -- �^���Ǝ�
    AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                      -- �K�p�J�n��
    AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                      -- �K�p�I����
    AND   (
            ((xdec.payments_judgment_classe = gv_pay_judg_g)      -- �x�����f�敪�i�����j
            AND (xmrih.actual_ship_date    >=  gd_target_date))   -- �o�Ɏ��ѓ�
          OR
            ((xdec.payments_judgment_classe = gv_pay_judg_c)      -- �x�����f�敪�i�����j
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
--            AND (xmrih.actual_arrival_date >=  gd_target_date))   -- ���Ɏ��ѓ�
            AND (NVL(xmrih.actual_arrival_date, xmrih.schedule_arrival_date) 
                                              >=  gd_target_date)) -- ���Ɏ��ѓ�(���ɗ\���)
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
          )
    AND (
          ((xmrih.last_update_date    > gd_last_process_date)   -- �ړ��w�b�_�F�O�񏈗����t
          AND (xmrih.last_update_date <= gd_sysdate))
        OR (xmrih.mov_hdr_id IN (SELECT xmril.mov_hdr_id
                              FROM xxinv_mov_req_instr_lines  xmril                 -- �ړ��˗�/�w������(�A�h�I��)
                              WHERE (xmril.last_update_date > gd_last_process_date) -- �ړ����ׁF�O�񏈗����t
                              AND   (xmril.last_update_date <= gd_sysdate)))
        )*/
--
    -- �ړ����я�� ���o
    SELECT
      move_info.mov_hdr_id
     ,move_info.mov_num
     ,move_info.slip_number
     ,move_info.delivery_no
     ,move_info.actual_freight_carrier_code
     ,move_info.shipped_locat_code
     ,move_info.shipping_method_code
     ,move_info.deliver_to_code_class
     ,move_info.ship_to_locat_code
     ,move_info.payments_judgment_classe
     ,move_info.actual_ship_date
     ,move_info.actual_arrival_date
     ,move_info.judgement_date
     ,move_info.item_class
     ,move_info.weight_capacity_class
     ,move_info.small_quantity
     ,move_info.sum_quantity
     ,move_info.order_type
     ,move_info.no_cont_freight_class
     ,move_info.transfer_location_code
     ,move_info.description
     ,move_info.small_amount_class
     ,move_info.mixed_class
     ,move_info.ref_small_amount_class
     ,move_info.post_distance
     ,move_info.small_distance
     ,move_info.consolid_add_distance
     ,move_info.actual_distance
     ,move_info.small_weight
     ,move_info.pay_picking_amount
     ,move_info.qty
     ,move_info.delivery_weight
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
     ,move_info.sum_pallet_weight
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
    BULK COLLECT INTO gt_move_inf_tab
    FROM (
      -- ����
      SELECT /*+ leading (xmrih xdec) use_nl (xmrih xdec) */
                xmrih.mov_hdr_id                                  mov_hdr_id                 -- �ړ��w�b�_ID
              , xmrih.mov_num                                     mov_num                    -- �ړ��ԍ�
              , xmrih.slip_number                                 slip_number                -- �����No
              , xmrih.delivery_no                                 delivery_no                -- �z��No
              , xmrih.actual_freight_carrier_code                 actual_freight_carrier_code  -- �^���Ǝ�_����
              , xmrih.shipped_locat_code                          shipped_locat_code         -- �o�Ɍ��ۊǏꏊ
              , xmrih.actual_shipping_method_code                 shipping_method_code       -- �z���敪
              , gv_code_move                                      deliver_to_code_class      -- �z����R�[�h�敪�i�R�F�q�Ɂj
              , xmrih.ship_to_locat_code                          ship_to_locat_code         -- ���ɐ�ۊǏꏊ
              , xdec.payments_judgment_classe                     payments_judgment_classe   -- �x�����f�敪(�^��)
              , xmrih.actual_ship_date                            actual_ship_date           -- �o�Ɏ��ѓ�
              , NVL(xmrih.actual_arrival_date, xmrih.schedule_arrival_date) actual_arrival_date -- ���Ɏ��ѓ�(���ɗ\���)
              , NVL(xmrih.actual_arrival_date, xmrih.schedule_arrival_date) judgement_date   -- ���f��
              , xmrih.item_class                                  item_class                 -- ���i�敪
              , xmrih.weight_capacity_class                       weight_capacity_class      -- �d�ʗe�ϋ敪
-- ##### 20080717 Ver.1.15 �{��#595�Ή� START #####
---              , xmrih.small_quantity                              small_quantity             -- ������
              , NVL(xmrih.small_quantity, 0)                         small_quantity             -- ������
-- ##### 20080717 Ver.1.15 �{��#595�Ή� END   #####
              , xmrih.sum_quantity                                sum_quantity               -- ���v����
              , gv_type_move                                      order_type                 -- �^�C�v�i�R�F�ړ��j
              , xmrih.no_cont_freight_class                       no_cont_freight_class      -- �_��O�^���敪
              , NULL                                              transfer_location_code     -- �U�֐�
              , SUBSTRB(xmrih.description, 1, 40)                 description                -- �E�v�i40�j
              , NULL                                              small_amount_class         -- �z���敪�F�����敪
              , NULL                                              mixed_class                -- �z���敪�F���ڋ敪
              , NULL                                              ref_small_amount_class     -- �z���敪�F���[�t�����敪
              , NULL                                              post_distance              -- �z�������F�ԗ�����
              , NULL                                              small_distance             -- �z�������F��������
              , NULL                                              consolid_add_distance      -- �z�������F���ڊ�������
              , NULL                                              actual_distance            -- �z�������F���ۋ���
              , NULL                                              small_weight               -- �^���ƎҁF�����d��
              , NULL                                              pay_picking_amount         -- �^���ƎҁF�x���s�b�L���O�P��
              , NULL                                              qty                        -- ��
              , NULL                                              delivery_weight            -- �d��
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
              , NVL(xmrih.sum_pallet_weight, 0)                   sum_pallet_weight          -- ���v�p���b�g�d��
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
      FROM  xxinv_mov_req_instr_headers    xmrih,   -- �ړ��˗�/�w���w�b�_(�A�h�I��)
            xxwip_delivery_company         xdec     -- �^���p�^���Ǝ҃A�h�I���}�X�^
      WHERE xmrih.actual_ship_date IS NOT NULL            -- �o�Ɏ��ѓ�
      AND  (xmrih.actual_arrival_date IS NOT NULL           -- ���Ɏ��ѓ�
        OR  xmrih.schedule_arrival_date  IS NOT NULL)       -- ���ɗ\���
      AND   xmrih.actual_shipping_method_code IS NOT NULL -- �z���敪_����
      AND   xmrih.actual_freight_carrier_code IS NOT NULL -- �^���Ǝ�_����
      AND   xmrih.delivery_no IS NOT NULL                 -- �z��No
      AND   xmrih.item_class = xdec.goods_classe                              -- ���i�敪
      AND   xmrih.actual_freight_carrier_code = xdec.delivery_company_code    -- �^���Ǝ�
      AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                      -- �K�p�J�n��
      AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                      -- �K�p�I����
      AND   xdec.payments_judgment_classe = gv_pay_judg_c                     -- �x�����f�敪�i�����j
      AND   NVL(xmrih.actual_arrival_date, xmrih.schedule_arrival_date) 
                                                >=  gd_target_date          -- ���Ɏ��ѓ�(���ɗ\���)
      AND (
            ((xmrih.last_update_date    > gd_last_process_date)   -- �ړ��w�b�_�F�O�񏈗����t
            AND (xmrih.last_update_date <= gd_sysdate))
          OR (EXISTS (SELECT 1
                      FROM   xxinv_mov_req_instr_lines  xmril                 -- �ړ��˗�/�w������(�A�h�I��)
                      WHERE  xmril.mov_hdr_id = xmrih.mov_hdr_id
                      AND    xmril.last_update_date > gd_last_process_date -- �ړ����ׁF�O�񏈗����t
                      AND    xmril.last_update_date <= gd_sysdate
                      AND    ROWNUM = 1))
          )
-- 2008/11/28 v1.14 ADD START
      -- �ύڏd�ʍ��v�̐�������7���ȏ�̏ꍇ�͏o�͂��Ȃ�
      AND   LENGTHB(TRUNC(NVL(xmrih.sum_weight, 0))) < 7
-- 2008/11/28 v1.14 ADD END
      UNION ALL
      -- ����
      SELECT /*+ leading (xmrih xdec) use_nl (xmrih xdec) */
                xmrih.mov_hdr_id                                  mov_hdr_id                 -- �ړ��w�b�_ID
              , xmrih.mov_num                                     mov_num                    -- �ړ��ԍ�
              , xmrih.slip_number                                 slip_number                -- �����No
              , xmrih.delivery_no                                 delivery_no                -- �z��No
              , xmrih.actual_freight_carrier_code                 actual_freight_carrier_code  -- �^���Ǝ�_����
              , xmrih.shipped_locat_code                          shipped_locat_code         -- �o�Ɍ��ۊǏꏊ
              , xmrih.actual_shipping_method_code                 shipping_method_code       -- �z���敪
              , gv_code_move                                      deliver_to_code_class      -- �z����R�[�h�敪�i�R�F�q�Ɂj
              , xmrih.ship_to_locat_code                          ship_to_locat_code         -- ���ɐ�ۊǏꏊ
              , xdec.payments_judgment_classe                     payments_judgment_classe   -- �x�����f�敪(�^��)
              , xmrih.actual_ship_date                            actual_ship_date           -- �o�Ɏ��ѓ�
              , NVL(xmrih.actual_arrival_date, xmrih.schedule_arrival_date) actual_arrival_date -- ���Ɏ��ѓ�(���ɗ\���)
              , xmrih.actual_ship_date                            judgement_date             -- ���f��
              , xmrih.item_class                                  item_class                 -- ���i�敪
              , xmrih.weight_capacity_class                       weight_capacity_class      -- �d�ʗe�ϋ敪
-- ##### 20080717 Ver.1.15 �{��#595�Ή� START #####
--              , xmrih.small_quantity                              small_quantity             -- ������
              , NVL(xmrih.small_quantity, 0)                        small_quantity             -- ������
-- ##### 20080717 Ver.1.15 �{��#595�Ή� END   #####
              , xmrih.sum_quantity                                sum_quantity               -- ���v����
              , gv_type_move                                      order_type                 -- �^�C�v�i�R�F�ړ��j
              , xmrih.no_cont_freight_class                       no_cont_freight_class      -- �_��O�^���敪
              , NULL                                              transfer_location_code     -- �U�֐�
              , SUBSTRB(xmrih.description, 1, 40)                 description                -- �E�v�i40�j
              , NULL                                              small_amount_class         -- �z���敪�F�����敪
              , NULL                                              mixed_class                -- �z���敪�F���ڋ敪
              , NULL                                              ref_small_amount_class     -- �z���敪�F���[�t�����敪
              , NULL                                              post_distance              -- �z�������F�ԗ�����
              , NULL                                              small_distance             -- �z�������F��������
              , NULL                                              consolid_add_distance      -- �z�������F���ڊ�������
              , NULL                                              actual_distance            -- �z�������F���ۋ���
              , NULL                                              small_weight               -- �^���ƎҁF�����d��
              , NULL                                              pay_picking_amount         -- �^���ƎҁF�x���s�b�L���O�P��
              , NULL                                              qty                        -- ��
              , NULL                                              delivery_weight            -- �d��
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
              , NVL(xmrih.sum_pallet_weight, 0)                   sum_pallet_weight          -- ���v�p���b�g�d��
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
      FROM  xxinv_mov_req_instr_headers    xmrih,   -- �ړ��˗�/�w���w�b�_(�A�h�I��)
            xxwip_delivery_company         xdec     -- �^���p�^���Ǝ҃A�h�I���}�X�^
      WHERE xmrih.actual_ship_date IS NOT NULL            -- �o�Ɏ��ѓ�
      AND  (xmrih.actual_arrival_date IS NOT NULL           -- ���Ɏ��ѓ�
        OR  xmrih.schedule_arrival_date  IS NOT NULL)       -- ���ɗ\���
      AND   xmrih.actual_shipping_method_code IS NOT NULL -- �z���敪_����
      AND   xmrih.actual_freight_carrier_code IS NOT NULL -- �^���Ǝ�_����
      AND   xmrih.delivery_no IS NOT NULL                 -- �z��No
      AND   xmrih.item_class = xdec.goods_classe                              -- ���i�敪
      AND   xmrih.actual_freight_carrier_code = xdec.delivery_company_code    -- �^���Ǝ�
      AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                      -- �K�p�J�n��
      AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                      -- �K�p�I����
      AND   xdec.payments_judgment_classe = gv_pay_judg_g                     -- �x�����f�敪�i�����j
      AND   xmrih.actual_ship_date    >=  gd_target_date                      -- �o�Ɏ��ѓ�
      AND (
            ((xmrih.last_update_date    > gd_last_process_date)   -- �ړ��w�b�_�F�O�񏈗����t
            AND (xmrih.last_update_date <= gd_sysdate))
          OR (EXISTS (SELECT 1
                      FROM   xxinv_mov_req_instr_lines  xmril                 -- �ړ��˗�/�w������(�A�h�I��)
                      WHERE  xmril.mov_hdr_id = xmrih.mov_hdr_id
                      AND    xmril.last_update_date > gd_last_process_date -- �ړ����ׁF�O�񏈗����t
                      AND    xmril.last_update_date <= gd_sysdate
                      AND    ROWNUM = 1))
          )
-- 2008/11/28 v1.14 ADD START
      -- �ύڏd�ʍ��v�̐�������7���ȏ�̏ꍇ�͏o�͂��Ȃ�
      AND   LENGTHB(TRUNC(NVL(xmrih.sum_weight, 0))) < 7
-- 2008/11/28 v1.14 ADD END
      ) move_info
      ;
-- ##### 20081125 Ver.1.13 �{��#104�Ή� END #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move�F�ړ����я�񒊏o�F' || TO_CHAR(gt_move_inf_tab.COUNT));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
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
  END get_move;
--
  /**********************************************************************************
   * Procedure Name   : get_move_other
   * Description      : �ړ��֘A��񒊏o
   ***********************************************************************************/
  PROCEDURE get_move_other(
    ov_errbuf           OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_move_other'; -- �v���O������
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
    lr_ship_method_tab        xxwip_common3_pkg.ship_method_rec;        -- �z���敪
    lr_delivery_distance_tab  xxwip_common3_pkg.delivery_distance_rec;  -- �z������
    lr_delivery_company_tab   xxwip_common3_pkg.delivery_company_rec;   -- �^���p�^���Ǝ�
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
    -- �Ώۃf�[�^���̏ꍇ
    IF (gt_move_inf_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<move_loop>>
    FOR ln_index IN  gt_move_inf_tab.FIRST.. gt_move_inf_tab.LAST LOOP
--
      -- **************************************************
      -- ***  �z���敪���擾(A-15)
      -- **************************************************
      xxwip_common3_pkg.get_ship_method(
        gt_move_inf_tab(ln_index).shipping_method_code, -- �z���敪
        gt_move_inf_tab(ln_index).judgement_date,       -- ���f��
        lr_ship_method_tab,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- �����敪�ݒ�
      gt_move_inf_tab(ln_index).small_amount_class := lr_ship_method_tab.small_amount_class;
      -- ���ڋ敪�ݒ�
      gt_move_inf_tab(ln_index).mixed_class        := lr_ship_method_tab.mixed_class;
      -- ���[�t�����敪�ݒ�i���i�敪�����[�t�A�����敪�������j
      IF ((gt_move_inf_tab(ln_index).item_class = gv_prod_class_lef)
        AND (gt_move_inf_tab(ln_index).small_amount_class = gv_small_sum_yes)) THEN
        -- YES��ݒ�
        gt_move_inf_tab(ln_index).ref_small_amount_class := gv_ktg_yes;
--
      ELSE
        -- NO��ݒ�
        gt_move_inf_tab(ln_index).ref_small_amount_class := gv_ktg_no;
      END IF;
--
      -- **************************************************
      -- ***  �z�������A�h�I���}�X�^���o(A-17)
      -- **************************************************
      xxwip_common3_pkg.get_delivery_distance(
        gt_move_inf_tab(ln_index).item_class,                   -- ���i�敪
        gt_move_inf_tab(ln_index).actual_freight_carrier_code,  -- �^���Ǝ�
        gt_move_inf_tab(ln_index).shipped_locat_code,           -- �o�ɑq��
        gt_move_inf_tab(ln_index).deliver_to_code_class ,       -- �R�[�h�敪
        gt_move_inf_tab(ln_index).ship_to_locat_code,           -- �z����R�[�h
        gt_move_inf_tab(ln_index).judgement_date,               -- ���f��
        lr_delivery_distance_tab,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- �ԗ�����
      gt_move_inf_tab(ln_index).post_distance := 
                                      lr_delivery_distance_tab.post_distance;
      -- ��������
      gt_move_inf_tab(ln_index).small_distance := lr_delivery_distance_tab.small_distance;
      -- ���ڊ�������
      gt_move_inf_tab(ln_index).consolid_add_distance  := 
                                      lr_delivery_distance_tab.consolid_add_distance;
      -- ���ۋ���
      gt_move_inf_tab(ln_index).actual_distance := lr_delivery_distance_tab.actual_distance;
--
      -- **************************************************
      -- ***  �^���p�^���Ǝ҃A�h�I���}�X�^���o(A-8)
      -- **************************************************
      xxwip_common3_pkg.get_delivery_company(
        gt_move_inf_tab(ln_index).item_class,                   -- ���i�敪
        gt_move_inf_tab(ln_index).actual_freight_carrier_code,  -- �^���Ǝ�
        gt_move_inf_tab(ln_index).judgement_date,               -- ���f��
        lr_delivery_company_tab,                                -- �^���p�^���Ǝ҃��R�[�h
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- �����d��
      gt_move_inf_tab(ln_index).small_weight  := lr_delivery_company_tab.small_weight;
      -- �x���s�b�L���O�P��
      gt_move_inf_tab(ln_index).pay_picking_amount := lr_delivery_company_tab.pay_picking_amount;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other�F++++++++++ �ړ��֘A��񒊏o ++++++++++�F' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other�F+++++ �ړ��ԍ� +++++�F' || gt_move_inf_tab(ln_index).mov_num);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other�F+++++ �^���Ǝ� +++++�F' || gt_move_inf_tab(ln_index).actual_freight_carrier_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other�F+++++ �z��No   +++++�F' || gt_move_inf_tab(ln_index).delivery_no);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other�F�����敪      �F' || gt_move_inf_tab(ln_index).small_amount_class);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other�F���ڋ敪      �F' || gt_move_inf_tab(ln_index).mixed_class);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other�F���[�t�����敪�F' || gt_move_inf_tab(ln_index).ref_small_amount_class);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other�F�ԗ�����      �F' || TO_CHAR(gt_move_inf_tab(ln_index).post_distance));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other�F��������      �F' || TO_CHAR(gt_move_inf_tab(ln_index).small_distance));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other�F���ڊ�������  �F' || TO_CHAR(gt_move_inf_tab(ln_index).consolid_add_distance));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other�F���ۋ���      �F' || TO_CHAR(gt_move_inf_tab(ln_index).actual_distance));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other�F�����d��          �F' || TO_CHAR(gt_move_inf_tab(ln_index).small_weight));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_other�F�x���s�b�L���O�P���F' || TO_CHAR(gt_move_inf_tab(ln_index).pay_picking_amount));
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
    END LOOP move_loop;
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
  END get_move_other;
--
  /**********************************************************************************
   * Procedure Name   : get_move_line
   * Description      : �ړ����׃A�h�I�����o(A-18)
   ***********************************************************************************/
  PROCEDURE get_move_line(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_move_line'; -- �v���O������
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
    lt_move_line_inf_tab    move_line_inf_tbl;     --�ړ��˗��^�w������
--
    ln_item_id        xxcmn_item_mst2_v.item_id%TYPE;       -- �i��ID
-- ##### 20080715 Ver.1.3 ST��Q#452�Ή� START #####
    ln_item_no        xxcmn_item_mst2_v.item_no%TYPE;       -- �i�ڃR�[�h
-- ##### 20080715 Ver.1.3 ST��Q#452�Ή� END   #####
    ln_num_of_cases   xxcmn_item_mst2_v.num_of_cases%TYPE;  -- �P�[�X���萔
    ln_conv_unit      xxcmn_item_mst2_v.conv_unit%TYPE;     -- ���o�Ɋ��Z�P��
    ln_unit           xxcmn_item_mst2_v.unit%TYPE;          -- �d��
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
    ln_capacity       xxcmn_item_mst2_v.capacity%TYPE;      -- �e��
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
--
    ln_qty                     xxwip_deliverys.qty1%TYPE;             -- ��
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
--    ln_delivery_weight         xxwip_deliverys.delivery_weight1%TYPE; -- �d��
    ln_delivery_weight         NUMBER;                                -- �d��
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
    ln_sum_qty                 xxwip_deliverys.qty1%TYPE;             -- ���i���v�j
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
--    ln_sum_delivery_weight     xxwip_deliverys.delivery_weight1%TYPE; -- �d�ʁi���v�j
    ln_sum_delivery_weight     NUMBER;                                -- �d�ʁi���v�j
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
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
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F++++++++++ �ړ����׃A�h�I�����o ++++++++++');
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
    -- �Ώۃf�[�^���̏ꍇ
    IF (gt_move_inf_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<mover_loop>>
    FOR ln_index IN  gt_move_inf_tab.FIRST.. gt_move_inf_tab.LAST LOOP
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F++++++++++ �ړ��˗�/�w���w�b�_ ++++++++++�F' || TO_CHAR(ln_index));
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F�ړ��ԍ� �F' || gt_move_inf_tab(ln_index).mov_num);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F�^���Ǝ� �F' || gt_move_inf_tab(ln_index).actual_freight_carrier_code);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F�z��No   �F' || gt_move_inf_tab(ln_index).delivery_no);
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- **************************************************
      -- ***  �ړ����׃A�h�I�����o(A-18)
      -- **************************************************
      -- �ϐ�������
      lt_move_line_inf_tab.DELETE;
--
      SELECT  xmril.mov_hdr_id                  -- �ړ��w�b�_ID
            , xmril.item_id                     -- �i��ID
-- ##### 20080625 Ver.1.2 �o�׎��ѐ���NULL�Ή� START #####
/***
            , xmril.shipped_quantity            -- �o�׎��ѐ���
***/
            , NVL(xmril.shipped_quantity, 0)    -- �o�׎��ѐ���
-- ##### 20080625 Ver.1.2 �o�׎��ѐ���NULL�Ή� END   #####
      BULK COLLECT INTO lt_move_line_inf_tab
      FROM  xxinv_mov_req_instr_lines   xmril       -- �ړ��˗�/�w�����׃A�h�I��
      WHERE xmril.mov_hdr_id = gt_move_inf_tab(ln_index).mov_hdr_id -- �ړ��w�b�_ID
      AND   NVL(xmril.delete_flg, gv_ktg_no)  = gv_ktg_no;          -- ����t���O
--
      -- ���v�l ������
      ln_sum_qty             := 0;  -- ���i���v�j
      ln_sum_delivery_weight := 0;  -- �d�ʁi���v�j
--
      -- �Ώۃf�[�^���̏ꍇ
      IF (lt_move_line_inf_tab.COUNT = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                      gv_xxcmn_msg_notfnd,
                                      gv_tkn_table,
                                      gv_mov_req_instr_lines,
                                      gv_tkn_key,
                                      gt_move_inf_tab(ln_index).mov_num);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      <<move_line_loop>>
      FOR ln_line_index IN  lt_move_line_inf_tab.FIRST.. lt_move_line_inf_tab.LAST LOOP
--
        -- **************************************************
        -- ***  �ړ�OPM�i�ڏ��VIEW���o(A-19)
        -- **************************************************
        -- �ϐ�������
        ln_num_of_cases := NULL;        -- �P�[�X���萔
        ln_conv_unit    := NULL;        -- ���o�Ɋ��Z�P��
        ln_unit         := NULL;        -- �d��
--
        -- ���o�Ɋ��Z�P�ʁA�P�[�X���萔�A�d�� �擾
        BEGIN
-- ##### 20080715 Ver.1.3 ST��Q#452�Ή� START #####
--          SELECT ximv.item_id         -- �i��ID
          SELECT ximv.item_no         -- �i�ڃR�[�h
-- ##### 20080715 Ver.1.3 ST��Q#452�Ή� END   #####
               , ximv.num_of_cases    -- �P�[�X���萔
               , ximv.conv_unit       -- ���o�Ɋ��Z�P��
               , ximv.unit            -- �d��
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
               , ximv.capacity        -- �e��
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
 -- ##### 20080715 Ver.1.3 ST��Q#452�Ή� START #####
--         INTO   ln_item_id
         INTO   ln_item_no
-- ##### 20080715 Ver.1.3 ST��Q#452�Ή� END   #####
               , ln_num_of_cases
               , ln_conv_unit
               , ln_unit
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
               , ln_capacity
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
          FROM   xxcmn_item_mst2_v    ximv    -- OPM�i�ڏ��VIEW2
          WHERE  ximv.item_id = lt_move_line_inf_tab(ln_line_index).item_id         -- �i��ID
          AND    gt_move_inf_tab(ln_index).judgement_date >= ximv.start_date_active -- �K�p�J�n��
          AND    gt_move_inf_tab(ln_index).judgement_date <= ximv.end_date_active;  -- �K�p�I����
        EXCEPTION
          WHEN NO_DATA_FOUND THEN   -- *** �f�[�^�擾�G���[ ***
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                  gv_xxcmn_msg_notfnd,
                                                  gv_tkn_table,
                                                  gv_item_mst2_v,
                                                  gv_tkn_key,
                                                  lt_move_line_inf_tab(ln_line_index).item_id);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
--
          WHEN TOO_MANY_ROWS THEN   --*** �f�[�^�����擾�G���[ ***
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                  gv_xxcmn_msg_toomny,
                                                  gv_tkn_table,
                                                  gv_item_mst2_v,
                                                  gv_tkn_key,
                                                  lt_move_line_inf_tab(ln_line_index).item_id);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
        -- **************************************************
        -- ***  �ړ���/���ʎZ�o(A-20)
        -- **************************************************
        -- �ϐ�������
        ln_qty              := 0;
        ln_delivery_weight  := 0;
--
        -- *** �� �Z�o ***
        -- ���[�t�����敪 �� Y �̏ꍇ
        IF (gt_move_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes) THEN
          -- ���ɏ�������ݒ�
          ln_qty := gt_move_inf_tab(ln_index).small_quantity;
--
        -- ���[�t�����敪 �� N �̏ꍇ
        ELSE
          -- ���ɍ��v���ʂ�ݒ�
-- ##### 20080715 Ver.1.3 ST��Q#452�Ή� START #####
--          ln_qty := gt_move_inf_tab(ln_index).sum_quantity;
          ln_qty := xxwip_common3_pkg.deliv_rcv_ship_conv_qty(
                        ln_item_no                                             -- �i�ڃR�[�h
                      , lt_move_line_inf_tab(ln_line_index).shipped_quantity); -- ����
-- ##### 20080715 Ver.1.3 ST��Q#452�Ή� END   #####
        END IF;
--
        -- *** �d�� �Z�o ***
        -- ���[�t�����敪 �� Y ���A�d�ʗe�ϋ敪 �� �e�� �̏ꍇ
        IF ((gt_move_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes)
          AND (gt_move_inf_tab(ln_index).weight_capacity_class = gv_capacity )) THEN
          -- ��L�Z�o�̌� �~ �����d��
          ln_delivery_weight :=
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
--                ln_qty * gt_move_inf_tab(ln_index).small_weight;
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
--                CEIL(ln_qty * gt_move_inf_tab(ln_index).small_weight);
                ln_qty * gt_move_inf_tab(ln_index).small_weight;
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
--
        -- ��L�ȊO
        ELSE
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
          -- �d�ʗe�ϋ敪���u�e�ρv�̏ꍇ
          IF (gt_move_inf_tab(ln_index).weight_capacity_class = gv_capacity) THEN
            -- �e�� �~ �o�׎��ѐ��ʁi�؏�j
            ln_delivery_weight :=
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
--                CEIL(ln_capacity * lt_move_line_inf_tab(ln_line_index).shipped_quantity / 1000000);
                ln_capacity * lt_move_line_inf_tab(ln_line_index).shipped_quantity / 1000000;
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
--
          -- �d�ʗe�ϋ敪���u�d�ʁv�̏ꍇ
          ELSE
            -- �d�� �~ �o�׎��ѐ��ʁi�؏�j
            ln_delivery_weight :=
-- ##### 20080715 Ver.1.3 ST��Q#452�Ή� START #####
--                ROUND(ln_unit * lt_move_line_inf_tab(ln_line_index).shipped_quantity / 1000);
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
--                CEIL(ln_unit * lt_move_line_inf_tab(ln_line_index).shipped_quantity / 1000);
                ln_unit * lt_move_line_inf_tab(ln_line_index).shipped_quantity / 1000;
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
-- ##### 20080715 Ver.1.3 ST��Q#452�Ή� END   #####
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
          END IF;
        END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F++++++++++ �ړ��˗�/�w�����׃A�h�I�� ++++++++++�F' || TO_CHAR(ln_line_index));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F�ړ��w�b�_ID �F' || lt_move_line_inf_tab(ln_line_index).mov_hdr_id);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�FOPM�i��ID    �F' || lt_move_line_inf_tab(ln_line_index).item_id);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F�o�׎��ѐ��� �F' || lt_move_line_inf_tab(ln_line_index).shipped_quantity);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F+++++ ���� +++++');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F���[�t�����敪�F' || gt_move_inf_tab(ln_index).ref_small_amount_class);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F�d�ʗe�ϋ敪  �F' || gt_move_inf_tab(ln_index).weight_capacity_class);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F+++++ OPM�i�� +++++');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F�i��ID        �F' || lt_move_line_inf_tab(ln_line_index).item_id);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F�P�[�X���萔  �F' || TO_CHAR(ln_num_of_cases));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F���o�Ɋ��Z�P�ʁF' || ln_conv_unit);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F�d��          �F' || TO_CHAR(ln_unit));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F�e��          �F' || TO_CHAR(ln_capacity));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F+++++ �Z�o���� +++++');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F��         �F' || TO_CHAR(ln_qty));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F�d��         �F' || TO_CHAR(ln_delivery_weight));
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- **************************************************
        -- ***  �ړ���/���ʏW�v(A-21)
        -- **************************************************
        -- ���i���v�j
-- ##### 20080715 Ver.1.3 ST��Q#452�Ή� START #####
--        ln_sum_qty := ln_qty;
        -- ���[�t�����敪 �� Y �̏ꍇ
        IF (gt_move_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes) THEN
          ln_sum_qty := ln_qty;
        ELSE
          ln_sum_qty := ln_sum_qty + ln_qty;
        END IF;
-- ##### 20080715 Ver.1.3 ST��Q#452�Ή� END   #####
--
        -- �d�ʁi���v�j
        -- ���[�t�����敪 �� Y ���A�d�ʗe�ϋ敪 �� �e�� �̏ꍇ
        IF ((gt_move_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes)
          AND (gt_move_inf_tab(ln_index).weight_capacity_class = gv_capacity )) THEN
          ln_sum_delivery_weight := ln_delivery_weight;
        ELSE
          ln_sum_delivery_weight := ln_sum_delivery_weight + ln_delivery_weight;
        END IF;
--
      END LOOP move_line_loop;
--
      -- ���v�i���A�d�ʁj�ݒ�
      gt_move_inf_tab(ln_index).qty              := ln_sum_qty;
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
--      gt_move_inf_tab(ln_index).delivery_weight  := ln_sum_delivery_weight;
--
      -- �d�ʗe�ϋ敪���u�d�ʁv�����敪���u�ԗ��v�̏ꍇ
      IF   ((gt_move_inf_tab(ln_index).weight_capacity_class = gv_weight)
        AND (gt_move_inf_tab(ln_index).small_amount_class    = gv_small_sum_no)) THEN
        -- ���׏d�ʂ��T�}���������_�ȉ�����؏サ�A���v�p���b�g�d�ʂ����Z
        gt_move_inf_tab(ln_index).delivery_weight  := CEIL(TRUNC(ln_sum_delivery_weight, 1)) + 
                                                      gt_move_inf_tab(ln_index).sum_pallet_weight;
--
      -- ��L�ȊO
      ELSE
        -- ���׏d�ʂ��T�}���������_�ȉ�����؏�
        gt_move_inf_tab(ln_index).delivery_weight  := CEIL(TRUNC(ln_sum_delivery_weight, 1));
      END IF;
--
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F++++++++++ �ړ����^�d�ʏW�v ++++++++++');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F���i���v�j�F' || TO_CHAR(gt_move_inf_tab(ln_index).qty));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_move_line�F�d�ʁi���v�j�F' || TO_CHAR(gt_move_inf_tab(ln_index).delivery_weight));
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
    END LOOP mover_loop;
--
  EXCEPTION
--
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 START #####
    WHEN func_inv_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 END   #####
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
  END get_move_line;
--
  /**********************************************************************************
   * Procedure Name   : set_move_deliv_line
   * Description      : �ړ��^�����׃A�h�I��PL/SQL�\�i�[(A-22)
   ***********************************************************************************/
  PROCEDURE set_move_deliv_line(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_move_deliv_line'; -- �v���O������
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
    lv_delivery_company_code  xxwip_delivery_lines.delivery_company_code%TYPE;  -- �^���Ǝ�
    lv_whs_code               xxwip_delivery_lines.whs_code%TYPE;               -- �o�ɑq��
    lv_shipping_address_code  xxwip_delivery_lines.shipping_address_code%TYPE;  -- �z����R�[�h
    lv_dellivary_classe       xxwip_delivery_lines.dellivary_classe%TYPE;       -- �z���敪
    ln_qty                    xxwip_delivery_lines.qty%TYPE;                    -- ��
    ln_delivery_weight        xxwip_delivery_lines.delivery_weight%TYPE;        -- �d��
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
    ld_ship_date              xxwip_delivery_lines.ship_date%TYPE;              -- �o�ד�
    ld_arrival_date           xxwip_delivery_lines.arrival_date%TYPE;           -- ���ד�
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
    lv_payments_judgment_classe   xxwip_delivery_lines.payments_judgment_classe%TYPE; -- �x�����f�敪
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
-- ##### 20081210 Ver.1.16 �{��#401�Ή� START #####
    lv_delivery_no            xxwip_delivery_lines.delivery_no%TYPE;            -- �z��No
    ln_deli_cnt               NUMBER;
-- ##### 20081210 Ver.1.16 �{��#401�Ή� END   #####
--
    ln_deliv_line_flg         VARCHAR2(1);      -- �󒍖��׃A�h�I�� ���݃t���O Y:�L N:��
--
    ln_line_insert_cnt        NUMBER;           -- �o�^�pPL/SQL�\ ����
    ln_line_calc_update_cnt   NUMBER;           -- �Čv�Z�X�V�pPL/SQL�\ ����
    ln_line_des_update_cnt    NUMBER;           -- �E�v�o�^�pPL/SQL�\ ����
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
    -- ����������
    ln_line_insert_cnt      := i_line_deliv_lines_id_tab.COUNT ;  -- �o�^�pPL/SQL�\ ����
    ln_line_calc_update_cnt := us_line_request_no_tab.COUNT ;     -- �Čv�Z�X�V�pPL/SQL�\ ����
    ln_line_des_update_cnt  := ut_line_request_no_tab.COUNT ;     -- �E�v�o�^�pPL/SQL�\ ����
--
    -- �Ώۃf�[�^���̏ꍇ
    IF (gt_move_inf_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<move_loop>>
    FOR ln_index IN  gt_move_inf_tab.FIRST.. gt_move_inf_tab.LAST LOOP
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line�F++++++++++ �ړ��^�����׃A�h�I��PL/SQL�\�i�[ ++++++++++�F' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line�F�ړ��ԍ� �F' || gt_move_inf_tab(ln_index).mov_num);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line�F�^���Ǝ� �F' || gt_move_inf_tab(ln_index).actual_freight_carrier_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line�F�z��No   �F' || gt_move_inf_tab(ln_index).delivery_no);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- **************************************************
      -- ***  �^���w�b�_�A�h�I�����o
      -- **************************************************
      -- ���݃t���O������
      ln_deliv_line_flg := gv_ktg_yes;
--
      BEGIN
        SELECT  xwdl.delivery_company_code  -- �^���Ǝ�
              , xwdl.whs_code               -- �o�ɑq��
              , xwdl.shipping_address_code  -- �z����R�[�h
              , xwdl.dellivary_classe       -- �z���敪
              , xwdl.qty                    -- ��
              , xwdl.delivery_weight        -- �d��
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
              , xwdl.ship_date              -- �o�ד�
              , xwdl.arrival_date           -- ���ד�
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
-- ##### 20081210 Ver.1.16 �{��#401�Ή� START #####
              , xwdl.delivery_no            -- �z��No
-- ##### 20081210 Ver.1.16 �{��#401�Ή� END   #####
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
              , payments_judgment_classe    -- �x�����f�敪
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
        INTO    lv_delivery_company_code
              , lv_whs_code
              , lv_shipping_address_code
              , lv_dellivary_classe
              , ln_qty
              , ln_delivery_weight
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
              , ld_ship_date                -- �o�ד�
              , ld_arrival_date             -- ���ד�
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
-- ##### 20081210 Ver.1.16 �{��#401�Ή� START #####
              , lv_delivery_no              -- �z��No
-- ##### 20081210 Ver.1.16 �{��#401�Ή� END   #####
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
              , lv_payments_judgment_classe -- �x�����f�敪
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
        FROM   xxwip_delivery_lines xwdl    -- �^�����׃A�h�I��
        WHERE  xwdl.request_no = gt_move_inf_tab(ln_index).mov_num; -- �ړ��ԍ�
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   -- *** �f�[�^�擾�G���[ ***
          -- ���݃t���O Y ��ݒ�
          ln_deliv_line_flg := gv_ktg_no;
--
        WHEN TOO_MANY_ROWS THEN   -- *** �f�[�^�����擾�G���[ ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                gv_xxcmn_msg_toomny,
                                                gv_tkn_table,
                                                gv_delivery_lines,
                                                gv_tkn_key,
                                                gt_move_inf_tab(ln_index).mov_num);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line�F++++++++++ �^���w�b�_�A�h�I�� ++++++++++�F' || ln_deliv_line_flg);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line�F�^���Ǝ�     �F' || lv_delivery_company_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line�F�o�ɑq��     �F' || lv_whs_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line�F�z����R�[�h �F' || lv_shipping_address_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line�F�z���敪     �F' || lv_dellivary_classe);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line�F��         �F' || TO_CHAR(ln_qty));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line�F�d��         �F' || TO_CHAR(ln_delivery_weight));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line�F�o�ד�       �F' || TO_CHAR(ld_ship_date    ,'YYYY/MM/DD'));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line�F���ד�       �F' || TO_CHAR(ld_arrival_date ,'YYYY/MM/DD'));
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
-- ##### 20081210 Ver.1.16 �{��#401�Ή� START #####
--
      -- **************************************************
      -- ***  �z��No�̕ύX�ɂ��폜����
      -- **************************************************
      -- �^�����׃A�h�I�������݂���ꍇ
      IF (ln_deliv_line_flg = gv_ktg_yes) THEN
        -- �^�����ׂ̔z��No�Ǝ��т̔z��No���قȂ�ꍇ
        IF (gt_move_inf_tab(ln_index).delivery_no <> lv_delivery_no) THEN
          -- ���z��No�̌����擾
          BEGIN
            SELECT  COUNT(delivery_no)
            INTO    ln_deli_cnt
            FROM    xxwip_delivery_lines xwdl           -- �^�����׃A�h�I��
            WHERE   xwdl.delivery_no = lv_delivery_no;  -- �z��No
          END;
--
          -- ���z��No���^�����ׂ�1���̏ꍇ
          -- �������̏ꍇ�͍��ځA�W��ł��邽�߁A�폜���Ȃ�
          IF ( ln_deli_cnt = 1 ) THEN
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
            IF (gv_debug_flg = gv_debug_on) THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line�F�z���g�� ��DELETE�F' ||
                                                                  lv_delivery_no || '->' ||
                                          gt_move_inf_tab(ln_index).delivery_no);
            END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
            -- �^���w�b�_���폜����
            BEGIN
              -- �Ώ۔z��No���폜����
              DELETE FROM xxwip_deliverys
              WHERE delivery_no = lv_delivery_no;
            END;
          END IF;
        END IF;
      END IF;
--
-- ##### 20081210 Ver.1.16 �{��#401�Ή� END   #####
      -- **************************************************
      -- ***  �^�����׃A�h�I���Ƀf�[�^�����݂��Ȃ��ꍇ
      -- **************************************************
      IF (ln_deliv_line_flg = gv_ktg_no) THEN
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line�F�^�����׃A�h�I�� INSERT');
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- �o�^�pPL/SQL�\ ����
        ln_line_insert_cnt  := ln_line_insert_cnt + 1;
--
        -- �^�����דo�^�pPL/SQL�\ �ݒ�
        -- �˗�No
        i_line_request_no_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).mov_num;
        -- �����No
        i_line_invoice_no_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).slip_number;
        -- �z��No
        i_line_deliv_no_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).delivery_no;
        -- ���[�t�����敪
        i_line_small_lot_cls_tab(ln_line_insert_cnt) := 
                                            gt_move_inf_tab(ln_index).ref_small_amount_class;
        -- �^���Ǝ�
        i_line_deliv_cmpny_cd_tab(ln_line_insert_cnt) := 
                                            gt_move_inf_tab(ln_index).actual_freight_carrier_code;
        -- �o�ɑq�ɃR�[�h
        i_line_whs_code_tab(ln_line_insert_cnt) := 
                                            gt_move_inf_tab(ln_index).shipped_locat_code;
        -- �z���敪
        i_line_delliv_cls_tab(ln_line_insert_cnt) := 
                                            gt_move_inf_tab(ln_index).shipping_method_code;
        -- �z����R�[�h�敪
        i_line_code_division_tab(ln_line_insert_cnt) := 
                                            gt_move_inf_tab(ln_index).deliver_to_code_class;
        -- �z����R�[�h
        i_line_ship_addr_cd_tab(ln_line_insert_cnt) := 
                                            gt_move_inf_tab(ln_index).ship_to_locat_code;
        -- �x�����f�敪
        i_line_pay_judg_cls_tab(ln_line_insert_cnt) := 
                                            gt_move_inf_tab(ln_index).payments_judgment_classe;
        -- �o�ɓ�
        i_line_ship_date_tab(ln_line_insert_cnt) := 
                                            gt_move_inf_tab(ln_index).actual_ship_date;
        -- ������
        i_line_arrival_date_tab(ln_line_insert_cnt) := 
                                            gt_move_inf_tab(ln_index).actual_arrival_date;
        -- �񍐓�
        i_line_report_date_tab(ln_line_insert_cnt) := NULL;
        -- ���f��
        i_line_judg_date_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).judgement_date;
        -- ���i�敪
        i_line_goods_cls_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).item_class;
        -- �d�ʗe�ϋ敪
        i_line_weight_cap_cls_tab(ln_line_insert_cnt)  := 
                                            gt_move_inf_tab(ln_index).weight_capacity_class;
--
        -- ���[�t�����敪 �� Y�̏ꍇ
        IF (gt_move_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes) THEN
            -- ��������
            i_line_ditnc_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).small_distance;
--
-- ##### 20090209 Ver.1.22 �{��#1107�Ή� START #####
        -- ���i�敪 �� ���[�t   ���� 
        -- ���i�敪 �� �h�����N ���A���ڋ敪 ���� ���� �̏ꍇ
--        ELSIF (
--                  (gt_move_inf_tab(ln_index).item_class = gv_prod_class_lef)
--                OR    
--                  ((gt_move_inf_tab(ln_index).item_class = gv_prod_class_drk)
--                  AND (gt_move_inf_tab(ln_index).mixed_class <> gv_target_y))
--              ) THEN
          -- �ԗ�����
--          i_line_ditnc_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).post_distance;
--
        -- ��L�ȊO
--        ELSE
--
-- ##### 20081027 Ver.1.10 ����#436�Ή� START #####
          -- �ԗ�����1�i���ׂ͍��ڊ������������Z���Ȃ��j
--          i_line_ditnc_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).post_distance +
--                                                  gt_move_inf_tab(ln_index).consolid_add_distance;
--          i_line_ditnc_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).post_distance;
-- ##### 20081027 Ver.1.10 ����#436�Ή� END   #####
--
        ELSE
          -- �����敪���u�����v�̏ꍇ
          IF (gt_move_inf_tab(ln_index).small_amount_class = gv_small_sum_yes) THEN
            -- ����������ݒ�
            i_line_ditnc_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).small_distance;
--
          -- �����敪���u�ԗ��v�̏ꍇ
          ELSE
            -- �ԗ��ċ�����ݒ�
            i_line_ditnc_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).post_distance;
          END IF;
--
-- ##### 20090209 Ver.1.22 �{��#1107�Ή� END   #####
        END IF;
--
        -- ���ۋ���
        i_line_actual_dstnc_tab(ln_line_insert_cnt) := gt_move_inf_tab(ln_index).actual_distance;
        -- ��
        i_line_qty_tab(ln_line_insert_cnt)             := gt_move_inf_tab(ln_index).qty;
        -- �d��
        i_line_deliv_weight_tab(ln_line_insert_cnt)    := gt_move_inf_tab(ln_index).delivery_weight;
        -- �^�C�v
        i_line_order_tab_tab(ln_line_insert_cnt)       := gt_move_inf_tab(ln_index).order_type;
        -- ���ڋ敪
        i_line_mixed_code_tab(ln_line_insert_cnt)      := gt_move_inf_tab(ln_index).mixed_class;
        -- �_��O�敪
        i_line_outside_cntrct_tab(ln_line_insert_cnt)  := 
                                                  gt_move_inf_tab(ln_index).no_cont_freight_class;
        -- �U�֐�
        i_line_trans_locat_tab(ln_line_insert_cnt)     := 
                                                  gt_move_inf_tab(ln_index).transfer_location_code;
        -- �E�v
        i_line_description_tab(ln_line_insert_cnt)     := gt_move_inf_tab(ln_index).description;
--
      -- **************************************************
      -- ***  �^�����׃A�h�I���Ƀf�[�^�����݂���ꍇ
      -- **************************************************
      ELSE
        -- **************************************************
        -- ***  �o�^����Ă�����e���Čv�Z���K�v�ȏꍇ
        -- **************************************************
        --   �Ώۍ��ځF�^���ƎҁA�o�ɑq�ɁA�z����R�[�h�A�z���敪�A���A�d�ʁA�o�ɓ��A���ɓ��A�x�����f�敪
-- ##### 20090123 Ver.1.20 �{��#1074 START #####
-- �X�V���̏������Ȃ����A�ύX���������ꍇ�͍X�V����悤�ɏC��
/*****
        IF ((gt_move_inf_tab(ln_index).actual_freight_carrier_code <> lv_delivery_company_code )
          OR (gt_move_inf_tab(ln_index).shipped_locat_code   <> lv_whs_code              )
          OR (gt_move_inf_tab(ln_index).ship_to_locat_code   <> lv_shipping_address_code )
          OR (gt_move_inf_tab(ln_index).shipping_method_code <> lv_dellivary_classe      )
-- ##### 20081210 Ver.1.16 �{��#401�Ή� START #####
          OR (gt_move_inf_tab(ln_index).delivery_no          <> lv_delivery_no      )
-- ##### 20081210 Ver.1.16 �{��#401�Ή� END   #####
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
          OR (gt_move_inf_tab(ln_index).actual_ship_date     <> ld_ship_date    )
          OR (gt_move_inf_tab(ln_index).actual_arrival_date  <> ld_arrival_date )
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
          OR (gt_move_inf_tab(ln_index).payments_judgment_classe  <> lv_payments_judgment_classe )
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
          OR (gt_move_inf_tab(ln_index).qty                  <> ln_qty                   )
          OR (gt_move_inf_tab(ln_index).delivery_weight      <> ln_delivery_weight       )) THEN
*****/
-- ##### 20090123 Ver.1.20 �{��#1074 END   #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line�F�^�����׃A�h�I�� UPDATE �Čv�Z');
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- �Čv�Z�X�V�pPL/SQL�\ ����
          ln_line_calc_update_cnt   := ln_line_calc_update_cnt + 1;
--
          -- �^�����׃A�h�I��
          -- �˗�No
          us_line_request_no_tab(ln_line_calc_update_cnt)        := 
                                            gt_move_inf_tab(ln_index).mov_num;
          -- �����No
          us_line_invoice_no_tab(ln_line_calc_update_cnt)        := 
                                            gt_move_inf_tab(ln_index).slip_number;
          -- �z��No
          us_line_deliv_no_tab(ln_line_calc_update_cnt)          := 
                                            gt_move_inf_tab(ln_index).delivery_no;
          -- ���[�t�����敪
          us_line_small_lot_cls_tab(ln_line_calc_update_cnt)     := 
                                            gt_move_inf_tab(ln_index).ref_small_amount_class;
          -- �^���Ǝ�
          us_line_deliv_cmpny_cd_tab(ln_line_calc_update_cnt)    := 
                                            gt_move_inf_tab(ln_index).actual_freight_carrier_code;
          -- �o�ɑq�ɃR�[�h
          us_line_whs_code_tab(ln_line_calc_update_cnt)          := 
                                            gt_move_inf_tab(ln_index).shipped_locat_code;
          -- �z���敪
          us_line_delliv_cls_tab(ln_line_calc_update_cnt)        := 
                                            gt_move_inf_tab(ln_index).shipping_method_code;
          -- �z����R�[�h�敪
          us_line_code_division_tab(ln_line_calc_update_cnt)     := 
                                            gt_move_inf_tab(ln_index).deliver_to_code_class;
          -- �z����R�[�h�敪
          us_line_ship_addr_cd_tab(ln_line_calc_update_cnt)      := 
                                            gt_move_inf_tab(ln_index).ship_to_locat_code;
          -- �x�����f�敪
          us_line_pay_judg_cls_tab(ln_line_calc_update_cnt)      := 
                                            gt_move_inf_tab(ln_index).payments_judgment_classe;
          -- �o�ɓ�
          us_line_ship_date_tab(ln_line_calc_update_cnt)         := 
                                            gt_move_inf_tab(ln_index).actual_ship_date;
          -- ������
          us_line_arrival_date_tab(ln_line_calc_update_cnt)      := 
                                            gt_move_inf_tab(ln_index).actual_arrival_date;
          -- ���f��
          us_line_judg_date_tab(ln_line_calc_update_cnt)         := 
                                            gt_move_inf_tab(ln_index).judgement_date;
          -- ���i�敪
          us_line_goods_cls_tab(ln_line_calc_update_cnt)         := 
                                            gt_move_inf_tab(ln_index).item_class;
          -- �d�ʗe�ϋ敪
          us_line_weight_cap_cls_tab(ln_line_calc_update_cnt)    := 
                                            gt_move_inf_tab(ln_index).weight_capacity_class;
--
          -- ���[�t�����敪 �� Y�̏ꍇ
          IF (gt_move_inf_tab(ln_index).ref_small_amount_class = gv_ktg_yes) THEN
              -- ��������
              us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_move_inf_tab(ln_index).small_distance;
--
-- ##### 20090209 Ver.1.22 �{��#1107�Ή� START #####
          -- ���i�敪 �� ���[�t   ���� 
          -- ���i�敪 �� �h�����N ���A���ڋ敪 ���� ���� �̏ꍇ
--          ELSIF (
--                  (gt_move_inf_tab(ln_index).item_class = gv_prod_class_lef)
--                OR    
--                  ((gt_move_inf_tab(ln_index).item_class = gv_prod_class_drk)
--                  AND (gt_move_inf_tab(ln_index).mixed_class <> gv_target_y))
--              ) THEN
            -- �ԗ�����
--            us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_move_inf_tab(ln_index).post_distance;
--
          -- ��L�ȊO
--          ELSE
--
-- ##### 20081027 Ver.1.10 ����#436�Ή� START #####
            -- �ԗ�����1�i���ׂ͍��ڊ������������Z���Ȃ��j
--            us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_move_inf_tab(ln_index).post_distance +
--                                                    gt_move_inf_tab(ln_index).consolid_add_distance;
--            us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_move_inf_tab(ln_index).post_distance;
-- ##### 20081027 Ver.1.10 ����#436�Ή� END   #####
--
          ELSE
            -- �����敪���u�����v�̏ꍇ
            IF (gt_move_inf_tab(ln_index).small_amount_class = gv_small_sum_yes) THEN
              -- ����������ݒ�
              us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_move_inf_tab(ln_index).small_distance;
--
            -- �����敪���u�ԗ��v�̏ꍇ
            ELSE
              -- �ԗ��ċ�����ݒ�
              us_line_ditnc_tab(ln_line_calc_update_cnt) := gt_move_inf_tab(ln_index).post_distance;
            END IF;
--
-- ##### 20090209 Ver.1.22 �{��#1107�Ή� END   #####
          END IF;
--
          -- ���ۋ���
          us_line_actual_dstnc_tab(ln_line_calc_update_cnt)      := 
                                                  gt_move_inf_tab(ln_index).actual_distance;
          -- ��
          us_line_qty_tab(ln_line_calc_update_cnt)               := 
                                                  gt_move_inf_tab(ln_index).qty;
          -- �d��
          us_line_deliv_weight_tab(ln_line_calc_update_cnt)      := 
                                                  gt_move_inf_tab(ln_index).delivery_weight;
          -- �^�C�v
          us_line_order_tab_tab(ln_line_calc_update_cnt)         := 
                                                  gt_move_inf_tab(ln_index).order_type;
          -- ���ڋ敪
          us_line_mixed_code_tab(ln_line_calc_update_cnt)        := 
                                                  gt_move_inf_tab(ln_index).mixed_class;
          -- �_��O�敪
          us_line_outside_cntrct_tab(ln_line_calc_update_cnt)    := 
                                                  gt_move_inf_tab(ln_index).no_cont_freight_class;
          -- �U�֐�
          us_line_trans_locat_tab(ln_line_calc_update_cnt)       := 
                                                  gt_move_inf_tab(ln_index).transfer_location_code;
          -- �E�v
          us_line_description_tab(ln_line_calc_update_cnt)       := 
                                                  gt_move_inf_tab(ln_index).description;
--
        -- **************************************************
        -- ***  �o�^����Ă�����e���Čv�Z���K�v�łȂ��ꍇ
        -- **************************************************
-- ##### 20090123 Ver.1.20 �{��#1074 START #####
-- �K�p�݂̂̍X�V�����͔p�~����
/*****
        ELSE
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_move_deliv_line�F�^�����׃A�h�I�� UPDATE �E�v');
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- �E�v�o�^�pPL/SQL�\ ����
          ln_line_des_update_cnt := ln_line_des_update_cnt + 1;
--
          -- �^�����׃A�h�I��
          -- �˗�No
          ut_line_request_no_tab(ln_line_des_update_cnt)  := 
                              gt_move_inf_tab(ln_index).mov_num;
          -- �E�v
          ut_line_description_tab(ln_line_des_update_cnt) := gt_move_inf_tab(ln_index).description;
--
        END IF;
*****/
-- ##### 20090123 Ver.1.20 �{��#1074 END   #####
      END IF;
--
    END LOOP move_loop;
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
  END set_move_deliv_line;
--
  /**********************************************************************************
   * Procedure Name   : insert_deliv_line
   * Description      : �^�����׃A�h�I���ꊇ�o�^(A-23)
   ***********************************************************************************/
  PROCEDURE insert_deliv_line(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_deliv_line'; -- �v���O������
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
    IF (i_line_request_no_tab.COUNT <> 0) THEN 
--
      -- **************************************************
      -- * �^�����׃A�h�I�� �o�^
      -- **************************************************
      FORALL ln_index IN i_line_request_no_tab.FIRST .. i_line_request_no_tab.LAST
        INSERT INTO xxwip_delivery_lines
        ( delivery_lines_id           -- �^�����׃A�h�I��ID
        , request_no                  -- �˗�No
        , invoice_no                  -- �����No
        , delivery_no                 -- �z��No
        , small_lot_class             -- ���[�t�����敪
        , delivery_company_code       -- �^���Ǝ�
        , whs_code                    -- �o�ɑq�ɃR�[�h
        , dellivary_classe            -- �z���敪
        , code_division               -- �z����R�[�h�敪
        , shipping_address_code       -- �z����R�[�h
        , payments_judgment_classe    -- �x�����f�敪
        , ship_date                   -- �o�ɓ�
        , arrival_date                -- ������
        , report_date                 -- �񍐓�
        , judgement_date              -- ���f��
        , goods_classe                -- ���i�敪
        , weight_capacity_class       -- �d�ʗe�ϋ敪
        , distance                    -- ����
        , actual_distance             -- ���ۋ���
        , qty                         -- ��
        , delivery_weight             -- �d��
        , order_type                  -- �^�C�v
        , mixed_code                  -- ���ڋ敪
        , outside_contract            -- �_��O�敪
        , transfer_location           -- �U�֐�
        , description                 -- �E�v
        , created_by                  -- �쐬��
        , creation_date               -- �쐬��
        , last_updated_by             -- �ŏI�X�V��
        , last_update_date            -- �ŏI�X�V��
        , last_update_login           -- �ŏI�X�V���O�C��
        , request_id                  -- �v��ID
        , program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                  -- �R���J�����g�E�v���O����ID
        , program_update_date         -- �v���O�����X�V��
        ) VALUES (
          xxwip_delivery_lines_id_s1.NEXTVAL    -- �^�����׃A�h�I��ID
        , i_line_request_no_tab(ln_index)       -- �˗�No
        , i_line_invoice_no_tab(ln_index)       -- �����No
        , i_line_deliv_no_tab(ln_index)         -- �z��No
        , i_line_small_lot_cls_tab(ln_index)    -- ���[�t�����敪
        , i_line_deliv_cmpny_cd_tab(ln_index)   -- �^���Ǝ�
        , i_line_whs_code_tab(ln_index)         -- �o�ɑq�ɃR�[�h
        , i_line_delliv_cls_tab(ln_index)       -- �z���敪
        , i_line_code_division_tab(ln_index)    -- �z����R�[�h�敪
        , i_line_ship_addr_cd_tab(ln_index)     -- �z����R�[�h
        , i_line_pay_judg_cls_tab(ln_index)     -- �x�����f�敪
        , i_line_ship_date_tab(ln_index)        -- �o�ɓ�
        , i_line_arrival_date_tab(ln_index)     -- ������
        , i_line_report_date_tab(ln_index)      -- �񍐓�
        , i_line_judg_date_tab(ln_index)        -- ���f��
        , i_line_goods_cls_tab(ln_index)        -- ���i�敪
        , i_line_weight_cap_cls_tab(ln_index)   -- �d�ʗe�ϋ敪
        , i_line_ditnc_tab(ln_index)            -- ����
        , i_line_actual_dstnc_tab(ln_index)     -- ���ۋ���
        , i_line_qty_tab(ln_index)              -- ��
        , i_line_deliv_weight_tab(ln_index)     -- �d��
        , i_line_order_tab_tab(ln_index)        -- �^�C�v
        , i_line_mixed_code_tab(ln_index)       -- ���ڋ敪
        , i_line_outside_cntrct_tab(ln_index)   -- �_��O�敪
        , i_line_trans_locat_tab(ln_index)      -- �U�֐�
        , i_line_description_tab(ln_index)      -- �E�v
        , gn_user_id                            -- �쐬��
        , gd_sysdate                            -- �쐬��
        , gn_user_id                            -- �ŏI�X�V��
        , gd_sysdate                            -- �ŏI�X�V��
        , gn_login_id                           -- �ŏI�X�V���O�C��
        , gn_conc_request_id                    -- �v��ID
        , gn_prog_appl_id                       -- �ݶ��āE��۸��сE���ع����ID
        , gn_conc_program_id                    -- �R���J�����g�E�v���O����ID
        , gd_sysdate);                          -- �v���O�����X�V��
--
      -- **************************************************
      -- �����ݒ�
      -- **************************************************
      gn_deliv_line_ins_cnt := gn_deliv_line_ins_cnt + SQL%ROWCOUNT;
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
  END insert_deliv_line;
--
  /**********************************************************************************
   * Procedure Name   : update_deliv_line_calc
   * Description      : �^�����׃A�h�I���ꊇ�Čv�Z�X�V(A-24)
   ***********************************************************************************/
  PROCEDURE update_deliv_line_calc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_deliv_line_calc'; -- �v���O������
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
    IF (us_line_request_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * �^�����׃A�h�I�� �Čv�Z �X�V
      -- **************************************************
      FORALL ln_index IN us_line_request_no_tab.FIRST .. us_line_request_no_tab.LAST
        UPDATE xxwip_delivery_lines       -- �^�����׃A�h�I��
        SET     invoice_no                = us_line_invoice_no_tab(ln_index)      -- �����No
              , delivery_no               = us_line_deliv_no_tab(ln_index)        -- �z��No
              , small_lot_class           = us_line_small_lot_cls_tab(ln_index)   -- ���[�t�����敪
              , delivery_company_code     = us_line_deliv_cmpny_cd_tab(ln_index)  -- �^���Ǝ�
              , whs_code                  = us_line_whs_code_tab(ln_index)        -- �o�ɑq�ɃR�[�h
              , dellivary_classe          = us_line_delliv_cls_tab(ln_index)      -- �z���敪
              , code_division             = us_line_code_division_tab(ln_index)   -- �z����R�[�h�敪
              , shipping_address_code     = us_line_ship_addr_cd_tab(ln_index)    -- �z����R�[�h
              , payments_judgment_classe  = us_line_pay_judg_cls_tab(ln_index)    -- �x�����f�敪
              , ship_date                 = us_line_ship_date_tab(ln_index)       -- �o�ɓ�
              , arrival_date              = us_line_arrival_date_tab(ln_index)    -- ������
              , judgement_date            = us_line_judg_date_tab(ln_index)       -- ���f��
              , goods_classe              = us_line_goods_cls_tab(ln_index)       -- ���i�敪
              , weight_capacity_class     = us_line_weight_cap_cls_tab(ln_index)  -- �d�ʗe�ϋ敪
              , distance                  = us_line_ditnc_tab(ln_index)           -- ����
              , actual_distance           = us_line_actual_dstnc_tab(ln_index)    -- ���ۋ���
              , qty                       = us_line_qty_tab(ln_index)             -- ��
              , delivery_weight           = us_line_deliv_weight_tab(ln_index)    -- �d��
              , order_type                = us_line_order_tab_tab(ln_index)       -- �^�C�v
              , mixed_code                = us_line_mixed_code_tab(ln_index)      -- ���ڋ敪
              , outside_contract          = us_line_outside_cntrct_tab(ln_index)  -- �_��O�敪
              , transfer_location         = us_line_trans_locat_tab(ln_index)     -- �U�֐�
              , description               = us_line_description_tab(ln_index)     -- �E�v
              , last_updated_by           = gn_user_id                 -- �ŏI�X�V��
              , last_update_date          = gd_sysdate                 -- �ŏI�X�V��
              , last_update_login         = gn_login_id                -- �ŏI�X�V���O�C��
              , request_id                = gn_conc_request_id         -- �v��ID
              , program_application_id    = gn_prog_appl_id            -- �ݶ��āE��۸��сE���ع����ID
              , program_id                = gn_conc_program_id         -- �R���J�����g�E�v���O����ID
              , program_update_date       = gd_sysdate                 -- �v���O�����X�V��
        WHERE  request_no = us_line_request_no_tab(ln_index);
--
      -- **************************************************
      -- �����ݒ�
      -- **************************************************
      gn_deliv_line_ins_cnt := gn_deliv_line_ins_cnt + SQL%ROWCOUNT;
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
  END update_deliv_line_calc;
--
  /**********************************************************************************
   * Procedure Name   : update_deliv_line_desc
   * Description      : �^�����׃A�h�I���ꊇ�K�p�X�V(A-25)
   ***********************************************************************************/
  PROCEDURE update_deliv_line_desc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_deliv_line_desc'; -- �v���O������
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
    IF (ut_line_request_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * �^�����׃A�h�I�� �K�p �X�V
      -- **************************************************
      FORALL ln_index IN ut_line_request_no_tab.FIRST .. ut_line_request_no_tab.LAST
        UPDATE xxwip_delivery_lines       -- �^�����׃A�h�I��
        SET     description               = ut_line_description_tab(ln_index)   -- �E�v
              , last_updated_by           = gn_user_id           -- �ŏI�X�V��
              , last_update_date          = gd_sysdate           -- �ŏI�X�V��
              , last_update_login         = gn_login_id          -- �ŏI�X�V���O�C��
              , request_id                = gn_conc_request_id   -- �v��ID
              , program_application_id    = gn_prog_appl_id      -- �ݶ��āE��۸��сE���ع����ID
              , program_id                = gn_conc_program_id   -- �R���J�����g�E�v���O����ID
              , program_update_date       = gd_sysdate           -- �v���O�����X�V��
        WHERE  request_no = ut_line_request_no_tab(ln_index);
--
      -- **************************************************
      -- �����ݒ�
      -- **************************************************
      gn_deliv_line_ins_cnt := gn_deliv_line_ins_cnt + SQL%ROWCOUNT;
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
  END update_deliv_line_desc;
--
--
--
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 START ##### 
-- �ȍ~�͔z�ԉ����Ή��̐V�K�v���V�[�W���[
  /**********************************************************************************
   * Procedure Name   : get_carcan_req_no
   * Description      : �z�ԉ����Ώۈ˗�No���o(A-25-1)
   ***********************************************************************************/
  PROCEDURE get_carcan_req_no(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_carcan_req_no'; -- �v���O������
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
    -- **************************************************
    -- * �󒍎��сA�x�����сA�ړ����т�
    -- * �z�ԉ������ꂽ�f�[�^���o
    -- * �k�Ώۃf�[�^�l
    -- * ���э��ڂ��ݒ肳��Ă��āA�z��No��NULL�̃f�[�^
    -- **************************************************
-- ##### 20081125 Ver.1.13 �{��#104�Ή� START #####
    /*SELECT  carcan.results_type         -- �^�C�v
          , carcan.request_no           -- �˗�No�i�ړ��ԍ��j
    BULK COLLECT INTO gt_carcan_info_tab
    FROM
      (
        -- ==================================================
        -- �z�ԉ������ꂽ�󒍎��сA�x�����я�� ���o
        -- ==================================================
        SELECT  CASE xotv.shipping_shikyu_class       -- �^�C�v
                WHEN gv_shipping  THEN gv_type_ship   --   �P�F�o��
                WHEN gv_shikyu    THEN gv_type_shikyu --   �Q�F�x��
                END                   AS results_type
              , xoha.request_no       AS request_no   -- �˗�No
        FROM  xxwsh_order_headers_all        xoha,    -- �󒍃w�b�_�A�h�I��
              xxwsh_oe_transaction_types2_v  xotv,    -- �󒍃^�C�v���VIEW2
              xxwip_delivery_company         xdec     -- �^���p�^���Ǝ҃A�h�I���}�X�^
        WHERE xoha.latest_external_flag = 'Y'                 -- �ŐV�t���O 'Y'
        AND   xoha.shipped_date IS NOT NULL                   -- �o�ד�
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
--        AND   xoha.arrival_date IS NOT NULL                   -- ���ד�
-- �i���ח\����������͒��ד����ݒ肳��Ă��邱�Ƃ��O��j
        AND   (xoha.arrival_date           IS NOT NULL    -- ���ד�
          OR   xoha.schedule_arrival_date  IS NOT NULL)   -- ���ח\���
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
        AND   xoha.result_shipping_method_code IS NOT NULL    -- �z���敪_����
        AND   xoha.result_freight_carrier_code IS NOT NULL    -- �^���Ǝ�_����
        AND   xoha.delivery_no  IS NULL                       -- �z��No
        -- �^���p�^���Ǝ�
        AND   xoha.prod_class = xdec.goods_classe                             -- ���i�敪
        AND   xoha.result_freight_carrier_code = xdec.delivery_company_code   -- �^���Ǝ�
        AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                    -- �K�p�J�n��
        AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                    -- �K�p�I����
        AND   (
                ((xdec.payments_judgment_classe = gv_pay_judg_g)    -- �x�����f�敪�i�����j
                AND (xoha.shipped_date >=  gd_target_date))         -- �o�ד�
              OR
                ((xdec.payments_judgment_classe = gv_pay_judg_c)    -- �x�����f�敪�i�����j
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
--                AND (xoha.arrival_date >=  gd_target_date))         -- ���ד�
                AND (NVL(xoha.arrival_date, xoha.schedule_arrival_date)
                                                 >=  gd_target_date)) -- ���ד�(���ח\���)
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
              )
        -- �󒍃^�C�v���VIEW2
        AND   xoha.order_type_id       = xotv.transaction_type_id -- �󒍃^�C�vID
        AND (
              ((xotv.shipping_shikyu_class  = gv_shipping)         -- �o�׈˗�
              AND  (xoha.result_deliver_to  IS NOT NULL))          -- �o�א�_����
            OR
              ((xotv.shipping_shikyu_class  = gv_shikyu)            -- �x���˗�
              AND (xotv.auto_create_po_class = '0'))                -- �����쐬�����敪�uNO�v
            )
        AND (
              ((xoha.last_update_date > gd_last_process_date)  -- �󒍃w�b�_�F�O�񏈗����t
              AND  (xoha.last_update_date <= gd_sysdate))
            OR (xoha.request_no IN (SELECT xola.request_no
                                  FROM xxwsh_order_lines_all xola    -- �󒍖��׃A�h�I��
                                  WHERE (xola.last_update_date > gd_last_process_date)  -- �󒍖��ׁF�O�񏈗����t
                                  AND   (xola.last_update_date <= gd_sysdate)))
            )
        UNION ALL
        -- ==================================================
        -- �z�ԉ������ꂽ�ړ����я�� ���o
        -- ==================================================
        SELECT    gv_type_move        AS results_type   -- �^�C�v�i�ړ��j
                , xmrih.mov_num       AS request_no     -- �ړ��ԍ�
        FROM  xxinv_mov_req_instr_headers    xmrih,     -- �ړ��˗�/�w���w�b�_(�A�h�I��)
              xxwip_delivery_company         xdec       -- �^���p�^���Ǝ҃A�h�I���}�X�^
        WHERE xmrih.actual_ship_date IS NOT NULL            -- �o�Ɏ��ѓ�
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
--        AND   xmrih.actual_arrival_date IS NOT NULL         -- ���Ɏ��ѓ�
        AND  (xmrih.actual_arrival_date IS NOT NULL           -- ���Ɏ��ѓ�
          OR  xmrih.schedule_arrival_date  IS NOT NULL)       -- ���ɗ\���
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
        AND   xmrih.actual_shipping_method_code IS NOT NULL -- �z���敪_����
        AND   xmrih.actual_freight_carrier_code IS NOT NULL -- �^���Ǝ�_����
        AND   xmrih.delivery_no IS NULL                     -- �z��No
        AND   xmrih.item_class = xdec.goods_classe                              -- ���i�敪
        AND   xmrih.actual_freight_carrier_code = xdec.delivery_company_code    -- �^���Ǝ�
        AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                      -- �K�p�J�n��
        AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                      -- �K�p�I����
        AND   (
                ((xdec.payments_judgment_classe = gv_pay_judg_g)      -- �x�����f�敪�i�����j
                AND (xmrih.actual_ship_date    >=  gd_target_date))   -- �o�Ɏ��ѓ�
              OR
                ((xdec.payments_judgment_classe = gv_pay_judg_c)      -- �x�����f�敪�i�����j
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� START #####
--                AND (xmrih.actual_arrival_date >=  gd_target_date))   -- ���Ɏ��ѓ�
                AND (NVL(xmrih.actual_arrival_date, xmrih.schedule_arrival_date) 
                                                  >=  gd_target_date)) -- ���Ɏ��ѓ�(���ɗ\���)
-- ##### 20081021 Ver.1.9 T_S_572 ����#392�Ή� END   #####
              )
       AND (
              ((xmrih.last_update_date    > gd_last_process_date)   -- �ړ��w�b�_�F�O�񏈗����t
              AND (xmrih.last_update_date <= gd_sysdate))
            OR (xmrih.mov_hdr_id IN (SELECT xmril.mov_hdr_id
                                  FROM xxinv_mov_req_instr_lines  xmril                 -- �ړ��˗�/�w������(�A�h�I��)
                                  WHERE (xmril.last_update_date > gd_last_process_date) -- �ړ����ׁF�O�񏈗����t
                                  AND   (xmril.last_update_date <= gd_sysdate)))
            )
      ) carcan;*/
--
    SELECT  carcan.results_type         -- �^�C�v
          , carcan.request_no           -- �˗�No�i�ړ��ԍ��j
    BULK COLLECT INTO gt_carcan_info_tab
    FROM
      (
        -- ==================================================
        -- �z�ԉ������ꂽ�󒍎��сA�x�����я�� ���o
        -- ==================================================
        -- ����_�x���˗�
        SELECT  /*+ leading(xoha otta xdec) use_nl(xoha otta xdec) */
                gv_type_shikyu        AS results_type
              , xoha.request_no       AS request_no   -- �˗�No
        FROM  xxwsh_order_headers_all        xoha,    -- �󒍃w�b�_�A�h�I��
              oe_transaction_types_all       otta,    -- �󒍃^�C�v���VIEW2
              xxwip_delivery_company         xdec     -- �^���p�^���Ǝ҃A�h�I���}�X�^
        WHERE xoha.latest_external_flag = 'Y'                 -- �ŐV�t���O 'Y'
        AND   xoha.shipped_date IS NOT NULL                   -- �o�ד�
-- �i���ח\����������͒��ד����ݒ肳��Ă��邱�Ƃ��O��j
        AND   (xoha.arrival_date           IS NOT NULL    -- ���ד�
          OR   xoha.schedule_arrival_date  IS NOT NULL)   -- ���ח\���
        AND   xoha.result_shipping_method_code IS NOT NULL    -- �z���敪_����
        AND   xoha.result_freight_carrier_code IS NOT NULL    -- �^���Ǝ�_����
        AND   xoha.delivery_no  IS NULL                       -- �z��No
        -- �^���p�^���Ǝ�
        AND   xoha.prod_class = xdec.goods_classe                             -- ���i�敪
        AND   xoha.result_freight_carrier_code = xdec.delivery_company_code   -- �^���Ǝ�
        AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                    -- �K�p�J�n��
        AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                    -- �K�p�I����
        AND   xdec.payments_judgment_classe = gv_pay_judg_c    -- �x�����f�敪�i�����j
        AND   NVL(xoha.arrival_date, xoha.schedule_arrival_date)
                                                 >=  gd_target_date -- ���ד�(���ח\���)
        -- �󒍃^�C�v���VIEW2
        AND   xoha.order_type_id       = otta.transaction_type_id -- �󒍃^�C�vID
        AND   otta.attribute1  = gv_shikyu            -- �x���˗�
        AND   otta.attribute3  = '0'                -- �����쐬�����敪�uNO�v
        AND (
              ((xoha.last_update_date > gd_last_process_date)  -- �󒍃w�b�_�F�O�񏈗����t
              AND  (xoha.last_update_date <= gd_sysdate))
            OR ( EXISTS (SELECT 1
                         FROM   xxwsh_order_lines_all xola    -- �󒍖��׃A�h�I��
                         WHERE  xola.order_header_id = xoha.order_header_id
                         AND    xola.last_update_date > gd_last_process_date -- �󒍖��ׁF�O�񏈗����t
                         AND    xola.last_update_date <= gd_sysdate
                         AND    ROWNUM = 1))
            )
        UNION ALL
        -- ����_�o�׈˗�
        SELECT  /*+ leading(xoha otta xdec) use_nl(xoha otta xdec) */
                gv_type_ship          AS results_type
              , xoha.request_no       AS request_no   -- �˗�No
        FROM  xxwsh_order_headers_all        xoha,    -- �󒍃w�b�_�A�h�I��
              oe_transaction_types_all       otta,    -- �󒍃^�C�v���VIEW2
              xxwip_delivery_company         xdec     -- �^���p�^���Ǝ҃A�h�I���}�X�^
        WHERE xoha.latest_external_flag = 'Y'                 -- �ŐV�t���O 'Y'
        AND   xoha.shipped_date IS NOT NULL                   -- �o�ד�
-- �i���ח\����������͒��ד����ݒ肳��Ă��邱�Ƃ��O��j
        AND   (xoha.arrival_date           IS NOT NULL    -- ���ד�
          OR   xoha.schedule_arrival_date  IS NOT NULL)   -- ���ח\���
        AND   xoha.result_shipping_method_code IS NOT NULL    -- �z���敪_����
        AND   xoha.result_freight_carrier_code IS NOT NULL    -- �^���Ǝ�_����
        AND   xoha.delivery_no  IS NULL                       -- �z��No
        -- �^���p�^���Ǝ�
        AND   xoha.prod_class = xdec.goods_classe                             -- ���i�敪
        AND   xoha.result_freight_carrier_code = xdec.delivery_company_code   -- �^���Ǝ�
        AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                    -- �K�p�J�n��
        AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                    -- �K�p�I����
        AND   xdec.payments_judgment_classe = gv_pay_judg_c                   -- �x�����f�敪�i�����j
        AND   NVL(xoha.arrival_date, xoha.schedule_arrival_date)
                                                 >=  gd_target_date           -- ���ד�(���ח\���)
        -- �󒍃^�C�v���VIEW2
        AND   xoha.order_type_id       = otta.transaction_type_id   -- �󒍃^�C�vID
        AND   otta.attribute1  = gv_shipping             -- �o�׈˗�
        AND   xoha.result_deliver_to  IS NOT NULL                   -- �o�א�_����
        AND (
              ((xoha.last_update_date > gd_last_process_date)  -- �󒍃w�b�_�F�O�񏈗����t
              AND  (xoha.last_update_date <= gd_sysdate))
            OR ( EXISTS (SELECT 1
                         FROM   xxwsh_order_lines_all xola    -- �󒍖��׃A�h�I��
                         WHERE  xola.order_header_id = xoha.order_header_id
                         AND    xola.last_update_date > gd_last_process_date -- �󒍖��ׁF�O�񏈗����t
                         AND    xola.last_update_date <= gd_sysdate
                         AND    ROWNUM = 1))
            )
        UNION ALL
        -- ����_�x���˗�
        SELECT  /*+ leading(xoha otta xdec) use_nl(xoha otta xdec) */
                gv_type_shikyu        AS results_type
              , xoha.request_no       AS request_no   -- �˗�No
        FROM  xxwsh_order_headers_all        xoha,    -- �󒍃w�b�_�A�h�I��
              oe_transaction_types_all       otta,    -- �󒍃^�C�v���VIEW2
              xxwip_delivery_company         xdec     -- �^���p�^���Ǝ҃A�h�I���}�X�^
        WHERE xoha.latest_external_flag = 'Y'                 -- �ŐV�t���O 'Y'
        AND   xoha.shipped_date IS NOT NULL                   -- �o�ד�
-- �i���ח\����������͒��ד����ݒ肳��Ă��邱�Ƃ��O��j
        AND   (xoha.arrival_date           IS NOT NULL    -- ���ד�
          OR   xoha.schedule_arrival_date  IS NOT NULL)   -- ���ח\���
        AND   xoha.result_shipping_method_code IS NOT NULL    -- �z���敪_����
        AND   xoha.result_freight_carrier_code IS NOT NULL    -- �^���Ǝ�_����
        AND   xoha.delivery_no  IS NULL                       -- �z��No
        -- �^���p�^���Ǝ�
        AND   xoha.prod_class = xdec.goods_classe                             -- ���i�敪
        AND   xoha.result_freight_carrier_code = xdec.delivery_company_code   -- �^���Ǝ�
        AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                    -- �K�p�J�n��
        AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                    -- �K�p�I����
        AND   xdec.payments_judgment_classe = gv_pay_judg_g                   -- �x�����f�敪�i�����j
        AND   xoha.shipped_date >=  gd_target_date                            -- �o�ד�
        -- �󒍃^�C�v���VIEW2
        AND   xoha.order_type_id       = otta.transaction_type_id -- �󒍃^�C�vID
        AND   otta.attribute1  = gv_shikyu            -- �x���˗�
        AND   otta.attribute3 = '0'                -- �����쐬�����敪�uNO�v
        AND (
              ((xoha.last_update_date > gd_last_process_date)  -- �󒍃w�b�_�F�O�񏈗����t
              AND  (xoha.last_update_date <= gd_sysdate))
            OR ( EXISTS (SELECT 1
                         FROM   xxwsh_order_lines_all xola    -- �󒍖��׃A�h�I��
                         WHERE  xola.order_header_id = xoha.order_header_id
                         AND    xola.last_update_date > gd_last_process_date -- �󒍖��ׁF�O�񏈗����t
                         AND    xola.last_update_date <= gd_sysdate
                         AND    ROWNUM = 1))
            )
        UNION ALL
        -- ����_�o�׈˗�
        SELECT  /*+ leading(xoha otta xdec) use_nl(xoha otta xdec) */
                gv_type_ship          AS results_type
              , xoha.request_no       AS request_no   -- �˗�No
        FROM  xxwsh_order_headers_all        xoha,    -- �󒍃w�b�_�A�h�I��
              oe_transaction_types_all       otta,    -- �󒍃^�C�v���VIEW2
              xxwip_delivery_company         xdec     -- �^���p�^���Ǝ҃A�h�I���}�X�^
        WHERE xoha.latest_external_flag = 'Y'                 -- �ŐV�t���O 'Y'
        AND   xoha.shipped_date IS NOT NULL                   -- �o�ד�
-- �i���ח\����������͒��ד����ݒ肳��Ă��邱�Ƃ��O��j
        AND   (xoha.arrival_date           IS NOT NULL    -- ���ד�
          OR   xoha.schedule_arrival_date  IS NOT NULL)   -- ���ח\���
        AND   xoha.result_shipping_method_code IS NOT NULL    -- �z���敪_����
        AND   xoha.result_freight_carrier_code IS NOT NULL    -- �^���Ǝ�_����
        AND   xoha.delivery_no  IS NULL                       -- �z��No
        -- �^���p�^���Ǝ�
        AND   xoha.prod_class = xdec.goods_classe                             -- ���i�敪
        AND   xoha.result_freight_carrier_code = xdec.delivery_company_code   -- �^���Ǝ�
        AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                    -- �K�p�J�n��
        AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                    -- �K�p�I����
        AND   xdec.payments_judgment_classe = gv_pay_judg_g                   -- �x�����f�敪�i�����j
        AND   xoha.shipped_date >=  gd_target_date                            -- �o�ד�
        -- �󒍃^�C�v���VIEW2
        AND   xoha.order_type_id       = otta.transaction_type_id -- �󒍃^�C�vID
        AND   otta.attribute1  = gv_shipping           -- �o�׈˗�
        AND   xoha.result_deliver_to  IS NOT NULL                 -- �o�א�_����
        AND (
              ((xoha.last_update_date > gd_last_process_date)  -- �󒍃w�b�_�F�O�񏈗����t
              AND  (xoha.last_update_date <= gd_sysdate))
            OR ( EXISTS (SELECT 1
                         FROM   xxwsh_order_lines_all xola    -- �󒍖��׃A�h�I��
                         WHERE  xola.order_header_id = xoha.order_header_id
                         AND    xola.last_update_date > gd_last_process_date -- �󒍖��ׁF�O�񏈗����t
                         AND    xola.last_update_date <= gd_sysdate
                         AND    ROWNUM = 1))
            )
        UNION ALL
        -- ==================================================
        -- �z�ԉ������ꂽ�ړ����я�� ���o
        -- ==================================================
        -- ����
        SELECT /*+ leading (xmrih xdec) use_nl (xmrih xdec) */
                  gv_type_move        AS results_type   -- �^�C�v�i�ړ��j
                , xmrih.mov_num       AS request_no     -- �ړ��ԍ�
        FROM  xxinv_mov_req_instr_headers    xmrih,     -- �ړ��˗�/�w���w�b�_(�A�h�I��)
              xxwip_delivery_company         xdec       -- �^���p�^���Ǝ҃A�h�I���}�X�^
        WHERE xmrih.actual_ship_date IS NOT NULL            -- �o�Ɏ��ѓ�
        AND  (xmrih.actual_arrival_date IS NOT NULL           -- ���Ɏ��ѓ�
          OR  xmrih.schedule_arrival_date  IS NOT NULL)       -- ���ɗ\���
        AND   xmrih.actual_shipping_method_code IS NOT NULL -- �z���敪_����
        AND   xmrih.actual_freight_carrier_code IS NOT NULL -- �^���Ǝ�_����
        AND   xmrih.delivery_no IS NULL                     -- �z��No
        AND   xmrih.item_class = xdec.goods_classe                              -- ���i�敪
        AND   xmrih.actual_freight_carrier_code = xdec.delivery_company_code    -- �^���Ǝ�
        AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                      -- �K�p�J�n��
        AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                      -- �K�p�I����
        AND   xdec.payments_judgment_classe = gv_pay_judg_c                     -- �x�����f�敪�i�����j
        AND   NVL(xmrih.actual_arrival_date, xmrih.schedule_arrival_date) 
                                                  >=  gd_target_date            -- ���Ɏ��ѓ�(���ɗ\���)
       AND (
              ((xmrih.last_update_date    > gd_last_process_date)   -- �ړ��w�b�_�F�O�񏈗����t
              AND (xmrih.last_update_date <= gd_sysdate))
            OR (EXISTS (SELECT 1
                        FROM   xxinv_mov_req_instr_lines  xmril                 -- �ړ��˗�/�w������(�A�h�I��)
                        WHERE  xmril.mov_hdr_id = xmrih.mov_hdr_id
                        AND    xmril.last_update_date > gd_last_process_date -- �ړ����ׁF�O�񏈗����t
                        AND    xmril.last_update_date <= gd_sysdate
                        AND    ROWNUM = 1))
            )
        UNION ALL
        -- ����
        SELECT  /*+ leading (xmrih xdec) use_nl (xmrih xdec) */
                  gv_type_move        AS results_type   -- �^�C�v�i�ړ��j
                , xmrih.mov_num       AS request_no     -- �ړ��ԍ�
        FROM  xxinv_mov_req_instr_headers    xmrih,     -- �ړ��˗�/�w���w�b�_(�A�h�I��)
              xxwip_delivery_company         xdec       -- �^���p�^���Ǝ҃A�h�I���}�X�^
        WHERE xmrih.actual_ship_date IS NOT NULL            -- �o�Ɏ��ѓ�
        AND  (xmrih.actual_arrival_date IS NOT NULL           -- ���Ɏ��ѓ�
          OR  xmrih.schedule_arrival_date  IS NOT NULL)       -- ���ɗ\���
        AND   xmrih.actual_shipping_method_code IS NOT NULL -- �z���敪_����
        AND   xmrih.actual_freight_carrier_code IS NOT NULL -- �^���Ǝ�_����
        AND   xmrih.delivery_no IS NULL                     -- �z��No
        AND   xmrih.item_class = xdec.goods_classe                              -- ���i�敪
        AND   xmrih.actual_freight_carrier_code = xdec.delivery_company_code    -- �^���Ǝ�
        AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                      -- �K�p�J�n��
        AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                      -- �K�p�I����
        AND   xdec.payments_judgment_classe = gv_pay_judg_g                     -- �x�����f�敪�i�����j
        AND   xmrih.actual_ship_date    >=  gd_target_date                      -- �o�Ɏ��ѓ�
       AND (
              ((xmrih.last_update_date    > gd_last_process_date)   -- �ړ��w�b�_�F�O�񏈗����t
              AND (xmrih.last_update_date <= gd_sysdate))
            OR (EXISTS (SELECT 1
                        FROM   xxinv_mov_req_instr_lines  xmril                 -- �ړ��˗�/�w������(�A�h�I��)
                        WHERE  xmril.mov_hdr_id = xmrih.mov_hdr_id
                        AND    xmril.last_update_date > gd_last_process_date -- �ړ����ׁF�O�񏈗����t
                        AND    xmril.last_update_date <= gd_sysdate
                        AND    ROWNUM = 1))
            )
      ) carcan;
-- ##### 20081125 Ver.1.13 �{��#104�Ή� END #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_carcan_req_no�F�z�ԉ��������F' || TO_CHAR(gt_carcan_info_tab.COUNT));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
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
  END get_carcan_req_no;
--
  /**********************************************************************************
   * Procedure Name   : get_carcan_deliv_no
   * Description      : �z�ԉ����z��No���o(A-25-2)
   ***********************************************************************************/
  PROCEDURE get_carcan_deliv_no(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_carcan_deliv_no'; -- �v���O������
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
    cv_deliv_n    CONSTANT VARCHAR2(1) := '0'; -- �d���Ȃ�
    cv_deliv_y    CONSTANT VARCHAR2(1) := '1'; -- �d������
--
    -- *** ���[�J���ϐ� ***
    ln_deliv        NUMBER;         -- �z��No�̃J�E���^
    ln_deliv_flg    VARCHAR2(1);    -- �z��No�d���t���O
                                    --    0:�d���Ȃ�
                                    --    1:�d������
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cu_carcan_data
      ( p_request_no  xxwip_delivery_lines.request_no%TYPE )
    IS
      SELECT  xdl.delivery_no               -- �z��No
      FROM    xxwip_delivery_lines    xdl   -- �^�����׃A�h�I��
      WHERE   xdl.request_no = p_request_no -- �˗�No
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
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- **************************************************
    -- * �˗�No�ɑΉ������z��No���o
    -- **************************************************
    -- �����ݒ�
    ln_deliv := 0;
--
    -- �z�ԉ����̈˗�No���[�v
    <<req_date_loop>>
    FOR ln_index IN  gt_carcan_info_tab.FIRST.. gt_carcan_info_tab.LAST LOOP
--
        -- �˗�No
        carcan_request_no_tab(ln_index) := gt_carcan_info_tab(ln_index).request_no;
--
      -- �z�ԉ����̔z��No���o���[�v
      <<carcan_data_loop>>
      FOR re_carcan_data IN cu_carcan_data
        ( p_request_no => gt_carcan_info_tab(ln_index).request_no ) LOOP
--
        -- �z��No�d���t���O�������i�d���Ȃ��j
        ln_deliv_flg := cv_deliv_n;

        IF (carcan_deliv_no_tab.COUNT = 0 ) THEN
          -- �z��No�̃J�E���^�C���N�������g
          ln_deliv := ln_deliv + 1;
          -- �z��No��ݒ�
          carcan_deliv_no_tab(ln_deliv) := re_carcan_data.delivery_no ;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
            IF (gv_debug_flg = gv_debug_on) THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_carcan_deliv_no�F�z��No�i' 
                                              || TO_CHAR(ln_deliv) 
                                              || '�j�F' 
                                              || carcan_deliv_no_tab(ln_deliv));
            END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        ELSE
          -- �z��No�d���`�F�b�N���[�v
          <<deliv_data_loop>>
          FOR ln_deliv_ind IN  carcan_deliv_no_tab.FIRST.. carcan_deliv_no_tab.LAST LOOP
--
            -- ���܂ł̔z��No�ƍ���̔z��No���r
            IF (re_carcan_data.delivery_no = carcan_deliv_no_tab(ln_deliv_ind)) THEN
              -- �d�������ݒ�
              ln_deliv_flg := cv_deliv_y;
            END IF;
          END LOOP carcan_data_loop ;
--
          -- �z��No�d���`�F�b�N
          IF (ln_deliv_flg = cv_deliv_n) THEN
            -- �z��No�̃J�E���^�C���N�������g
            ln_deliv := ln_deliv + 1;
            -- �z��No��ݒ�
            carcan_deliv_no_tab(ln_deliv) := re_carcan_data.delivery_no ;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
            IF (gv_debug_flg = gv_debug_on) THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_carcan_deliv_no�F�z��No�i' 
                                              || TO_CHAR(ln_deliv) 
                                              || '�j�F' 
                                              || carcan_deliv_no_tab(ln_deliv));
            END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          END IF;
        END IF;
      END LOOP carcan_data_loop ;
    END LOOP req_date_loop;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_carcan_deliv_no�F�z�ԉ������ꂽ�z��No�̌����F' || TO_CHAR(carcan_deliv_no_tab.COUNT));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
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
  END get_carcan_deliv_no;
--
  /**********************************************************************************
   * Procedure Name   : delete_carcan_req_no
   * Description      : �z�ԉ����˗�No�폜(A-25-3)
   ***********************************************************************************/
  PROCEDURE delete_carcan_req_no(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_carcan_req_no'; -- �v���O������
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
    IF (carcan_request_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * �^�����׃A�h�I�� �z�ԉ��� �˗�No �폜
      -- **************************************************
      FORALL ln_index IN carcan_request_no_tab.FIRST .. carcan_request_no_tab.LAST
        DELETE FROM  xxwip_delivery_lines                     -- �^�����׃A�h�I��
        WHERE   request_no = carcan_request_no_tab(ln_index)  -- �z��No
      ;
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
  END delete_carcan_req_no;
--
  /**********************************************************************************
   * Procedure Name   : check_carcan_deliv_no
   * Description      : �z�ԉ����z��No���݊m�F(A-25-4)
   ***********************************************************************************/
  PROCEDURE check_carcan_deliv_no(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_carcan_deliv_no'; -- �v���O������
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
    ln_deliv_no_cnt       NUMBER;
    ln_del_deliv_no_cnt   NUMBER;
    ln_upd_req_no_cnt     NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cu_carcan_deliv_data
      ( p_delivery_no  xxwip_delivery_lines.delivery_no%TYPE )
    IS
      SELECT  xdl.request_no                    -- �˗�No
      FROM    xxwip_delivery_lines    xdl       -- �^�����׃A�h�I��
      WHERE   xdl.delivery_no = p_delivery_no   -- �z��No
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
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- **************************************************
    -- * �˗�No�ɑΉ������z��No���o
    -- **************************************************
    -- �e�J�E���^������
    ln_deliv_no_cnt     := 0;
    ln_del_deliv_no_cnt := 0;
    ln_upd_req_no_cnt   := 0;
--
    -- 0���̏ꍇ�̓`�F�b�N���Ȃ�
    IF (carcan_deliv_no_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    -- �z�ԉ����̔z��No���[�v
    <<deliv_date_loop>>
    FOR ln_index IN  carcan_deliv_no_tab.FIRST.. carcan_deliv_no_tab.LAST LOOP
--
      -- �^�����׃A�h�I���ɔz��No�����݂��邩�m�F
-- ##### 20081125 MOD �{��#104 START #####
      --SELECT  COUNT(*)
      SELECT  COUNT(1)
-- ##### 20081125 MOD �{��#104 END #####
      INTO    ln_deliv_no_cnt
      FROM    xxwip_delivery_lines
      WHERE   DELIVERY_NO = carcan_deliv_no_tab(ln_index);
--
      -- ���݂��Ȃ��ꍇ
      IF (ln_deliv_no_cnt = 0) THEN
        -- ���݂��Ȃ��ꍇ�A�Ώۂ̔z��No��ݒ�
        ln_del_deliv_no_cnt := ln_del_deliv_no_cnt + 1;
        d_can_deliv_no_tab(ln_del_deliv_no_cnt) := carcan_deliv_no_tab(ln_index);
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_carcan_deliv_no�F�^�����ׂɑ��݂��Ȃ��F�z��No�F' || d_can_deliv_no_tab(ln_del_deliv_no_cnt));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- ���݂���ꍇ
      ELSE
        -- �z�ԉ����̔z��No���o���[�v
        <<carcan_data_loop>>
        FOR re_carcan_deliv_data IN cu_carcan_deliv_data
            ( p_delivery_no => carcan_deliv_no_tab(ln_index) ) LOOP
--
          -- ���݂���ꍇ�A���o�����˗�No��ݒ�
          ln_upd_req_no_cnt := ln_upd_req_no_cnt + 1;
          u_can_request_no_tab(ln_upd_req_no_cnt) := re_carcan_deliv_data.request_no;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_carcan_deliv_no�F�^�����ׂɑ��݂���F�˗�No�F' || u_can_request_no_tab(ln_upd_req_no_cnt));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
--
        END LOOP carcan_data_loop ;
      END IF;


    END LOOP deliv_date_loop;
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
  END check_carcan_deliv_no;
--
  /**********************************************************************************
   * Procedure Name   : update_carcan_deliv_line
   * Description      : �z�ԉ����^�����׃A�h�I���X�V(A-25-5)
   ***********************************************************************************/
  PROCEDURE update_carcan_deliv_line(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_carcan_deliv_line'; -- �v���O������
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
    IF (u_can_request_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * �^�����׃A�h�I�� �ŏI�X�V�� �X�V
      -- **************************************************
      FORALL ln_index IN u_can_request_no_tab.FIRST .. u_can_request_no_tab.LAST
        UPDATE xxwip_delivery_lines       -- �^�����׃A�h�I��
        SET     last_updated_by           = gn_user_id           -- �ŏI�X�V��
              , last_update_date          = gd_sysdate           -- �ŏI�X�V��
              , last_update_login         = gn_login_id          -- �ŏI�X�V���O�C��
              , request_id                = gn_conc_request_id   -- �v��ID
              , program_application_id    = gn_prog_appl_id      -- �ݶ��āE��۸��сE���ع����ID
              , program_id                = gn_conc_program_id   -- �R���J�����g�E�v���O����ID
              , program_update_date       = gd_sysdate           -- �v���O�����X�V��
        WHERE  request_no = u_can_request_no_tab(ln_index);
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
  END update_carcan_deliv_line;
--
  /**********************************************************************************
   * Procedure Name   : delete_carcan_deliv_head
   * Description      : �z�ԉ����^���w�b�_�A�h�I���폜(A-25-6)
   ***********************************************************************************/
  PROCEDURE delete_carcan_deliv_head(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_carcan_deliv_head'; -- �v���O������
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
    IF (d_can_deliv_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * �^���w�b�_�A�h�I�� �z�ԉ��� �z��No �폜
      -- **************************************************
      FORALL ln_index IN d_can_deliv_no_tab.FIRST .. d_can_deliv_no_tab.LAST
        DELETE FROM  xxwip_deliverys                        -- �^���w�b�_�A�h�I��
        WHERE   delivery_no = d_can_deliv_no_tab(ln_index)  -- �z��No
      ;
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
  END delete_carcan_deliv_head;
--
-- �z�ԉ����Ή��̐V�K�v���V�[�W���[�͂����܂�
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 END   #####
--
--
  /**********************************************************************************
   * Procedure Name   : get_delinov_line_desc
   * Description      : �^�����׃A�h�I���Ώ۔z��No���o(A-26)
   ***********************************************************************************/
  PROCEDURE get_delinov_line_desc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deliv_line_delino'; -- �v���O������
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
-- ##### 20080537 MOD ������Q ���ڏ��� START #####
/***
    -- �^�����׃A�h�I�� �z��No���o
    SELECT  xdl.delivery_no             -- �z��No
          , MAX(xdl.distance)           -- �Œ�����
          , SUM(xdl.qty)                -- ��
          , SUM(xdl.delivery_weight)    -- �d��
    BULK COLLECT INTO gt_delivno_deliv_line_tab
    FROM   xxwip_delivery_lines    xdl          -- �^�����׃A�h�I��
    WHERE  xdl.last_update_date =  gd_sysdate   -- �ŏI�X�V��
    GROUP BY xdl.delivery_no                    -- �z��No�i�W��j
    ORDER BY xdl.delivery_no;                   -- �z��No�i�����j
***/
    -- �^�����׃A�h�I�� �z��No���o
    SELECT  xdl.delivery_no             -- �z��No
          , MAX(xdl.distance)           -- �Œ�����
          , SUM(xdl.qty)                -- ��
          , SUM(xdl.delivery_weight)    -- �d��
    BULK COLLECT INTO gt_delivno_deliv_line_tab
    FROM   xxwip_delivery_lines    xdl  -- �^�����׃A�h�I��
    WHERE  xdl.delivery_no IN ( SELECT  xdl.delivery_no                     -- �z��No
                                FROM    xxwip_delivery_lines    xdl         -- �^�����׃A�h�I��
                                WHERE   xdl.last_update_date =  gd_sysdate  -- �ŏI�X�V��
                                GROUP BY xdl.delivery_no)                   -- �z��No
    GROUP BY xdl.delivery_no    -- �z��No�i�W��j
    ORDER BY xdl.delivery_no;   -- �z��No�i�����j
--
-- ##### 20080537 MOD ������Q ���ڏ��� END   #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line_delino�F�^�����׃A�h�I���Ώ۔z��No���o �����F' ||
                                                    TO_CHAR(gt_delivno_deliv_line_tab.COUNT));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
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
  END get_delinov_line_desc;
--
  /**********************************************************************************
   * Procedure Name   : get_deliv_line
   * Description      : �^�����׃A�h�I�����o(A-27)
   ***********************************************************************************/
  PROCEDURE get_deliv_line(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deliv_line'; -- �v���O������
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
    lr_delivery_company_tab   xxwip_common3_pkg.delivery_company_rec;   -- �^���p�^���Ǝ�
    lr_delivery_charges_tab   xxwip_common3_pkg.delivery_charges_rec;   -- �^��
-- ##### 20081027 Ver.1.10 ����#436�Ή� START #####
    lr_delivery_distance_tab  xxwip_common3_pkg.delivery_distance_rec;  -- �z������
-- ##### 20081027 Ver.1.10 ����#436�Ή� END   #####
    ln_deliv_no_cnt           NUMBER;
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
    -- �Ώۃf�[�^���̏ꍇ
    IF (gt_delivno_deliv_line_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<delivno_loop>>
    FOR ln_index IN  gt_delivno_deliv_line_tab.FIRST.. gt_delivno_deliv_line_tab.LAST LOOP
--
      -- **************************************************
      -- * �^�����׃A�h�I�� ���o
      -- **************************************************
        BEGIN
          SELECT   delivery_company_code     -- �^���Ǝ�
                 , delivery_no               -- �z��No
                 , invoice_no                -- �����No
                 , payments_judgment_classe  -- �x�����f�敪
                 , ship_date                 -- �o�ɓ�
                 , arrival_date              -- ������
                 , judgement_date            -- ���f��
                 , goods_classe              -- ���i�敪
                 , mixed_code                -- ���ڋ敪
                 , dellivary_classe          -- �z���敪
                 , whs_code                  -- ��\�o�ɑq�ɃR�[�h
                 , code_division             -- ��\�z����R�[�h�敪
                 , shipping_address_code     -- ��\�z����R�[�h
                 , order_type                -- ��\�^�C�v
                 , weight_capacity_class     -- �d�ʗe�ϋ敪
                 , actual_distance           -- �Œ����ۋ���
                 , outside_contract          -- �_��O�敪
                 , transfer_location         -- �U�֐�
                 , NULL                      -- ���ڐ�
                 , NULL                      -- �����d��
                 , NULL                      -- �x���s�b�L���O�P��
                 , NULL                      -- �^����
                 , NULL                      -- ���[�t���ڊ���
                 , NULL                      -- ���ڊ������z
                 , NULL                      -- �s�b�L���O��
          INTO  gt_deliv_line_tab(ln_index)
          FROM
            (
              SELECT  delivery_company_code     -- �^���Ǝ�
                    , delivery_no               -- �z��No
                    , invoice_no                -- �����No
                    , payments_judgment_classe  -- �x�����f�敪
                    , ship_date                 -- �o�ɓ�
                    , arrival_date              -- ������
                    , judgement_date            -- ���f��
                    , goods_classe              -- ���i�敪
                    , mixed_code                -- ���ڋ敪
                    , dellivary_classe          -- �z���敪
                    , whs_code                  -- ��\�o�ɑq�ɃR�[�h
                    , code_division             -- ��\�z����R�[�h�敪
                    , shipping_address_code     -- ��\�z����R�[�h
                    , order_type                -- ��\�^�C�v
                    , weight_capacity_class     -- �d�ʗe�ϋ敪
                    , actual_distance           -- �Œ����ۋ���
                    , outside_contract          -- �_��O�敪
                    , transfer_location         -- �U�֐�
              FROM   xxwip_delivery_lines    xdl        -- �^�����׃A�h�I��
              WHERE  xdl.delivery_no  = gt_delivno_deliv_line_tab(ln_index).delivery_no -- �z��No
              AND    xdl.distance     = gt_delivno_deliv_line_tab(ln_index).distance    -- �Œ�����
-- ##### 20080715 Ver.1.4 ST��Q#455�Ή� START #####
--              ORDER BY xdl.delivery_no                    -- �z��No�i�����j
              ORDER BY xdl.request_no                       -- �˗�No�i�����j
-- ##### 20080715 Ver.1.4 ST��Q#455�Ή� END   #####
            ) max_deliv_line
        WHERE ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   -- *** �f�[�^�擾�G���[ ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                gv_xxcmn_msg_notfnd,
                                                gv_tkn_table,
                                                gv_delivery_lines,
                                                gv_tkn_key,
                                                gt_delivno_deliv_line_tab(ln_index).delivery_no
                                                || ',' ||
                                                gt_delivno_deliv_line_tab(ln_index).distance);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
        WHEN TOO_MANY_ROWS THEN   -- *** �f�[�^�����擾�G���[ ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                gv_xxcmn_msg_toomny,
                                                gv_tkn_table,
                                                gv_delivery_lines,
                                                gv_tkn_key,
                                                gt_delivno_deliv_line_tab(ln_index).delivery_no
                                                || ',' ||
                                                gt_delivno_deliv_line_tab(ln_index).distance);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F########## �^�����׃A�h�I�����o ##########�F' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F�^���ƎҁF' || gt_deliv_line_tab(ln_index).delivery_company_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F�z��No  �F' || gt_deliv_line_tab(ln_index).delivery_no);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F�Œ������F' || TO_CHAR(gt_delivno_deliv_line_tab(ln_index).distance));
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
-- ##### 20081027 Ver.1.10 ����#436�Ή� START #####
      -- ���i�敪���u�h�����N�v���A���ڋ敪���u���ځv�̏ꍇ
      IF ((gt_deliv_line_tab(ln_index).goods_classe = gv_prod_class_drk)
        AND (gt_deliv_line_tab(ln_index).mixed_code = gv_target_y)) THEN
--
        -- **************************************************
        -- * �z�������}�X�^���o
        -- **************************************************
        xxwip_common3_pkg.get_delivery_distance(
          gt_deliv_line_tab(ln_index).goods_classe,           -- ���i�敪
          gt_deliv_line_tab(ln_index).delivery_company_code,  -- �^���Ǝ�
          gt_deliv_line_tab(ln_index).whs_code,               -- �o�ɑq��
          gt_deliv_line_tab(ln_index).code_division ,         -- �R�[�h�敪
          gt_deliv_line_tab(ln_index).shipping_address_code,  -- �z����R�[�h
          gt_deliv_line_tab(ln_index).judgement_date,         -- ���f��
          lr_delivery_distance_tab,
          lv_errbuf,
          lv_retcode,
          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- �ԗ����� �{ ���ڊ����������Đݒ�
        gt_delivno_deliv_line_tab(ln_index).distance := lr_delivery_distance_tab.post_distance +
                                                        lr_delivery_distance_tab.consolid_add_distance;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F########## �z�������}�X�^���o �h�����N���ڂ̂� ##########�F' || TO_CHAR(ln_index));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F���i�敪      �F' || gt_deliv_line_tab(ln_index).goods_classe);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F���ڋ敪      �F' || gt_deliv_line_tab(ln_index).mixed_code);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F�ԗ�����      �F' || TO_CHAR(lr_delivery_distance_tab.post_distance));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F��������      �F' || TO_CHAR(lr_delivery_distance_tab.small_distance));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F���ڊ�������  �F' || TO_CHAR(lr_delivery_distance_tab.consolid_add_distance));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F���ۋ���      �F' || TO_CHAR(lr_delivery_distance_tab.actual_distance));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F�Œ������i�Đݒ�j�F' || TO_CHAR(gt_delivno_deliv_line_tab(ln_index).distance));
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      END IF;
-- ##### 20081027 Ver.1.10 ����#436�Ή� END   #####
--
      -- **************************************************
      -- * �^�����׍��ڐ��Z�o�iA-28�j
      -- **************************************************
      BEGIN
-- ##### 20081125 Ver.1.13 �{��#104�Ή� START   #####
        --SELECT COUNT(*)
        SELECT COUNT(1)
-- ##### 20081125 Ver.1.13 �{��#104�Ή� START   #####
        INTO   ln_deliv_no_cnt
        FROM
          (
            SELECT  xdl.delivery_no           as delivery_no
                  , xdl.code_division         as code_division
                  , xdl.shipping_address_code as shipping_address_code
            FROM    xxwip_delivery_lines    xdl          -- �^�����׃A�h�I��
            WHERE   xdl.delivery_no = gt_delivno_deliv_line_tab(ln_index).delivery_no    -- �z��No
            GROUP BY  xdl.delivery_no                   -- �z��No          �i�W��j
                    , xdl.code_division                 -- �z����R�[�h�敪�i�W��j
                    , xdl.shipping_address_code        -- �z����R�[�h    �i�W��j
          ) deliv_line;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   -- *** �f�[�^�擾�G���[ ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                gv_xxcmn_msg_notfnd,
                                                gv_tkn_table,
                                                gv_delivery_lines,
                                                gv_tkn_key,
                                                gt_delivno_deliv_line_tab(ln_index).delivery_no);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
        WHEN TOO_MANY_ROWS THEN   -- *** �f�[�^�����擾�G���[ ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                gv_xxcmn_msg_toomny,
                                                gv_tkn_table,
                                                gv_delivery_lines,
                                                gv_tkn_key,
                                                gt_delivno_deliv_line_tab(ln_index).delivery_no);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      -- ���ڋ敪 �� ���� �̏ꍇ
      IF (gt_deliv_line_tab(ln_index).mixed_code = gv_target_y) THEN
        -- ���ڐ��� �擾�����|�P ��ݒ�
        gt_deliv_line_tab(ln_index).consolid_qty := ln_deliv_no_cnt -1;
--
      -- ��L�ȊO�̏ꍇ
      ELSE
        -- ���ڐ��ɂO��ݒ�
        gt_deliv_line_tab(ln_index).consolid_qty := 0;
      END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F##### �^�����׍��ڐ��Z�o #####');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F���ڋ敪�F' || gt_deliv_line_tab(ln_index).mixed_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F���ڐ�  �F' || TO_CHAR(gt_deliv_line_tab(ln_index).consolid_qty));
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- **************************************************
      -- * �^���Z�o�iA-29�j
      -- **************************************************
      -- �^���p�^���Ǝ҃A�h�I���}�X�^ ���o
      xxwip_common3_pkg.get_delivery_company(
        gt_deliv_line_tab(ln_index).goods_classe,           -- ���i�敪
        gt_deliv_line_tab(ln_index).delivery_company_code,  -- �^���Ǝ�
        gt_deliv_line_tab(ln_index).judgement_date,         -- ���f��
        lr_delivery_company_tab,                            -- �^���p�^���Ǝ҃��R�[�h
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- *** �����d�� ***
      gt_deliv_line_tab(ln_index).small_weight      := lr_delivery_company_tab.small_weight;
      -- *** �x���s�b�L���O�P�� ***
      gt_deliv_line_tab(ln_index).pay_picking_amount:= lr_delivery_company_tab.pay_picking_amount;
--
      -- �^���A�h�I���}�X�^���o
      xxwip_common3_pkg.get_delivery_charges(
        gv_pay,                                                 -- �x�������敪
        gt_deliv_line_tab(ln_index).goods_classe,               -- ���i�敪
        gt_deliv_line_tab(ln_index).delivery_company_code,      -- �^���Ǝ�
        gt_deliv_line_tab(ln_index).dellivary_classe,           -- �z���敪
        gt_delivno_deliv_line_tab(ln_index).distance,           -- �^������
        gt_delivno_deliv_line_tab(ln_index).delivery_weight,    -- �d��
        gt_deliv_line_tab(ln_index).judgement_date,             -- ���f��
        lr_delivery_charges_tab,                                -- �^���A�h�I�����R�[�h
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- *** �^���� ***
      gt_deliv_line_tab(ln_index).shipping_expenses := 
                          lr_delivery_charges_tab.shipping_expenses;
      -- *** ���[�t���ڊ��� ***
      gt_deliv_line_tab(ln_index).leaf_consolid_add := 
                          lr_delivery_charges_tab.leaf_consolid_add;
--
      -- *** ���ڊ������z ***
      -- ���i�敪�����[�t�A���A���ڋ敪������ �̏ꍇ
      IF ((gt_deliv_line_tab(ln_index).goods_classe = gv_prod_class_lef)
        AND (gt_deliv_line_tab(ln_index).mixed_code = gv_target_y)) THEN
        -- ���[�t���ڊ��� �~ ���ڐ�
        gt_deliv_line_tab(ln_index).consolid_surcharge  := 
                                    gt_deliv_line_tab(ln_index).leaf_consolid_add *
                                    gt_deliv_line_tab(ln_index).consolid_qty;
      ELSE
        gt_deliv_line_tab(ln_index).consolid_surcharge  := 0;
      END IF;
--
      -- *** �s�b�L���O�� ***
      -- �� �~ �x���s�b�L���O�P��
      gt_deliv_line_tab(ln_index).picking_charge  := 
-- ##### 20080715 Ver.1.3 ST��Q#452�Ή� START #####
--                                    ROUND(gt_delivno_deliv_line_tab(ln_index).qty *
--                                    gt_deliv_line_tab(ln_index).pay_picking_amount);
                                    CEIL(gt_delivno_deliv_line_tab(ln_index).qty *
                                    gt_deliv_line_tab(ln_index).pay_picking_amount);
-- ##### 20080715 Ver.1.3 ST��Q#452�Ή� END   #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F########## �^���Z�o ##########');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F�����d��          �F' || TO_CHAR(gt_deliv_line_tab(ln_index).small_weight));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F�x���s�b�L���O�P���F' || TO_CHAR(gt_deliv_line_tab(ln_index).pay_picking_amount));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F##### �^���A�h�I���}�X�^ #####');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F�^����        �F' || TO_CHAR(gt_deliv_line_tab(ln_index).shipping_expenses));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F���[�t���ڊ����F' || TO_CHAR(gt_deliv_line_tab(ln_index).leaf_consolid_add));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F##### ���� #####');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F���i�敪�F' || gt_deliv_line_tab(ln_index).goods_classe);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F���ڋ敪�F' || gt_deliv_line_tab(ln_index).mixed_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F��    �F' || TO_CHAR(gt_delivno_deliv_line_tab(ln_index).qty));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F##### �Z�o���� #####');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F���ڊ������z�F' || TO_CHAR(gt_deliv_line_tab(ln_index).consolid_surcharge));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_deliv_line�F�s�b�L���O���F' || TO_CHAR(gt_deliv_line_tab(ln_index).picking_charge));
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
    END LOOP delivno_loop;
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
  END get_deliv_line;
--
--
  /**********************************************************************************
   * Procedure Name   : set_deliv_head
   * Description      : �^���w�b�_�A�h�I��PL/SQL�\�i�[(A-30)
   ***********************************************************************************/
  PROCEDURE set_deliv_head(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_deliv_head'; -- �v���O������
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
    lv_charged_amount   xxwip_deliverys.charged_amount%TYPE;  -- �����^��
    lv_many_rate        xxwip_deliverys.many_rate%TYPE;       -- ������
    lv_defined_flag     xxwip_deliverys.defined_flag%TYPE;    -- �x���m��敪
    lv_return_flag      xxwip_deliverys.return_flag%TYPE;     -- �x���m���
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
    lt_delivery_company_code      xxwip_deliverys.delivery_company_code%TYPE;     -- �^���Ǝ�
    lt_delivery_no                xxwip_deliverys.delivery_no%TYPE;               -- �z��No
    lt_payments_judgment_classe   xxwip_deliverys.payments_judgment_classe%TYPE;  -- �x�����f�敪
    lt_ship_date                  xxwip_deliverys.ship_date%TYPE;                 -- �o�ɓ�
    lt_arrival_date               xxwip_deliverys.arrival_date%TYPE;              -- ������
    lt_judgement_date             xxwip_deliverys.judgement_date%TYPE;            -- ���f��
    lt_goods_classe               xxwip_deliverys.goods_classe%TYPE;              -- ���i�敪
    lt_mixed_code                 xxwip_deliverys.mixed_code%TYPE;                -- ���ڋ敪
    lt_contract_rate              xxwip_deliverys.contract_rate%TYPE;             -- �_��^��
    lt_balance                    xxwip_deliverys.balance%TYPE;                   -- ���z
    lt_total_amount               xxwip_deliverys.total_amount%TYPE;              -- ���v
    lt_distance                   xxwip_deliverys.distance%TYPE;                  -- �Œ�����
    lt_delivery_classe            xxwip_deliverys.delivery_classe%TYPE;           -- �z���敪
    lt_whs_code                   xxwip_deliverys.whs_code%TYPE;                  -- ��\�o�ɑq�ɃR�[�h
    lt_code_division              xxwip_deliverys.code_division%TYPE;             -- ��\�z����R�[�h�敪
    lt_shipping_address_code      xxwip_deliverys.shipping_address_code%TYPE;     -- ��\�z����R�[�h
    lt_qty1                       xxwip_deliverys.qty1%TYPE;                      -- ���P
    lt_delivery_weight1           xxwip_deliverys.delivery_weight1%TYPE;          -- �d�ʂP
    lt_consolid_surcharge         xxwip_deliverys.consolid_surcharge%TYPE;        -- ���ڊ������z
    lt_actual_distance            xxwip_deliverys.actual_distance%TYPE;           -- �Œ����ۋ���
    lt_picking_charge             xxwip_deliverys.picking_charge%TYPE;            -- �s�b�L���O��
    lt_consolid_qty               xxwip_deliverys.consolid_qty%TYPE;              -- ���ڐ�
    lt_order_type                 xxwip_deliverys.order_type%TYPE;                -- ��\�^�C�v
    lt_weight_capacity_class      xxwip_deliverys.weight_capacity_class%TYPE;     -- �d�ʗe�ϋ敪
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
--
    ln_deliv_flg        VARCHAR2(1);    -- �󒍃w�b�_�A�h�I�� ���݃t���O Y:�L N:��
--
    ln_insert_cnt   NUMBER;  -- �o�^�pPL/SQL�\ ����
    ln_update_cnt   NUMBER;  -- �X�V�pPL/SQL�\ ����
    ln_delete_cnt   NUMBER;  -- �폜�pPL/SQL�\ ����
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
    -- ����������
    ln_insert_cnt   := 0;
    ln_update_cnt   := 0;
    ln_delete_cnt   := 0;
--
    -- �Ώۃf�[�^���̏ꍇ
    IF (gt_deliv_line_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<deliv_loop>>
    FOR ln_index IN  gt_deliv_line_tab.FIRST.. gt_deliv_line_tab.LAST LOOP
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F########## �󒍖��׃A�h�I�� #####�F' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F�^���ƎҁF' || gt_deliv_line_tab(ln_index).delivery_company_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F�z��No  �F' || gt_deliv_line_tab(ln_index).delivery_no);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- **************************************************
      -- ***  �^���w�b�_�A�h�I�����o
      -- **************************************************
      -- ���݃t���O������
      ln_deliv_flg := gv_ktg_no;
--
      BEGIN
        SELECT  xd.charged_amount   -- �����^��
              , xd.many_rate        -- ������
              , xd.defined_flag     -- �x���m��敪
              , xd.return_flag      -- �x���m���
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
              , xd.delivery_company_code      -- �^���Ǝ�
              , xd.delivery_no                -- �z��No
              , xd.payments_judgment_classe   -- �x�����f�敪
              , xd.ship_date                  -- �o�ɓ�
              , xd.arrival_date               -- ������
              , xd.judgement_date             -- ���f��
              , xd.goods_classe               -- ���i�敪
              , xd.mixed_code                 -- ���ڋ敪
              , xd.contract_rate              -- �_��^��
              , xd.balance                    -- ���z
              , xd.total_amount               -- ���v
              , xd.distance                   -- �Œ�����
              , xd.delivery_classe            -- �z���敪
              , xd.whs_code                   -- ��\�o�ɑq�ɃR�[�h
              , xd.code_division              -- ��\�z����R�[�h�敪
              , xd.shipping_address_code      -- ��\�z����R�[�h
              , xd.qty1                       -- ���P
              , xd.delivery_weight1           -- �d�ʂP
              , xd.consolid_surcharge         -- ���ڊ������z
              , xd.actual_distance            -- �Œ����ۋ���
              , xd.picking_charge             -- �s�b�L���O��
              , xd.consolid_qty               -- ���ڐ�
              , xd.order_type                 -- ��\�^�C�v
              , xd.weight_capacity_class      -- �d�ʗe�ϋ敪
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
        INTO    lv_charged_amount
              , lv_many_rate
              , lv_defined_flag
              , lv_return_flag
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
              , lt_delivery_company_code      -- �^���Ǝ�
              , lt_delivery_no                -- �z��No
              , lt_payments_judgment_classe   -- �x�����f�敪
              , lt_ship_date                  -- �o�ɓ�
              , lt_arrival_date               -- ������
              , lt_judgement_date             -- ���f��
              , lt_goods_classe               -- ���i�敪
              , lt_mixed_code                 -- ���ڋ敪
              , lt_contract_rate              -- �_��^��
              , lt_balance                    -- ���z
              , lt_total_amount               -- ���v
              , lt_distance                   -- �Œ�����
              , lt_delivery_classe            -- �z���敪
              , lt_whs_code                   -- ��\�o�ɑq�ɃR�[�h
              , lt_code_division              -- ��\�z����R�[�h�敪
              , lt_shipping_address_code      -- ��\�z����R�[�h
              , lt_qty1                       -- ���P
              , lt_delivery_weight1           -- �d�ʂP
              , lt_consolid_surcharge         -- ���ڊ������z
              , lt_actual_distance            -- �Œ����ۋ���
              , lt_picking_charge             -- �s�b�L���O��
              , lt_consolid_qty               -- ���ڐ�
              , lt_order_type                 -- ��\�^�C�v
              , lt_weight_capacity_class      -- �d�ʗe�ϋ敪
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
        FROM   xxwip_deliverys      xd      -- �^���w�b�_�A�h�I��
        WHERE  xd.delivery_no = gt_deliv_line_tab(ln_index).delivery_no -- �z��No
        AND    xd.p_b_classe  = gv_pay ;                  -- �x�������敪�i�x���j
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   -- *** �f�[�^�擾�G���[ ***
          -- ���݃t���O Y ��ݒ�
          ln_deliv_flg := gv_ktg_yes;
--
        WHEN TOO_MANY_ROWS THEN   -- *** �f�[�^�����擾�G���[ ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                gv_xxcmn_msg_toomny,
                                                gv_tkn_table,
                                                gv_deliverys,
                                                gv_tkn_key,
                                                gv_pay || ',' ||
                                                gt_deliv_line_tab(ln_index).delivery_no);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F########## �^���w�b�_�A�h�I�����o ##########�F' || ln_deliv_flg);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F�����^��    �F' || TO_CHAR(lv_charged_amount));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F������      �F' || TO_CHAR(lv_many_rate));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F�x���m��敪�F' || lv_defined_flag);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F�x���m���  �F' || lv_return_flag);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- **************************************************
      -- ***  �^���w�b�_�A�h�I���Ƀf�[�^�����݂��Ȃ��ꍇ
      -- **************************************************
      IF (ln_deliv_flg = gv_ktg_yes) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F�^���w�b�_�A�h�I�� INSERT');
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- �o�^�pPL/SQL�\ ����
        ln_insert_cnt  := ln_insert_cnt + 1;
--
        -- �^���Ǝ�
        i_head_deliv_cmpny_cd_tab(ln_insert_cnt) := 
                                    gt_deliv_line_tab(ln_index).delivery_company_code ;
        -- �z��No
        i_head_deliv_no_tab(ln_insert_cnt)       := gt_deliv_line_tab(ln_index).delivery_no ;
        -- �����No
        i_head_invoice_no_tab(ln_insert_cnt)     := gt_deliv_line_tab(ln_index).invoice_no ;
        -- �x�������敪�i�x���j
        i_head_p_b_classe_tab(ln_insert_cnt)     := gv_pay ;
        -- �x�����f�敪
        i_head_pay_judg_cls_tab(ln_insert_cnt)   := 
                                    gt_deliv_line_tab(ln_index).payments_judgment_classe ;
        -- �o�ɓ�
        i_head_ship_date_tab(ln_insert_cnt)      := gt_deliv_line_tab(ln_index).ship_date ;
        -- ������
        i_head_arrival_date_tab(ln_insert_cnt)   := gt_deliv_line_tab(ln_index).arrival_date ;
        -- �񍐓�
        i_head_report_date_tab(ln_insert_cnt)    := NULL ;
        -- ���f��
        i_head_judg_date_tab(ln_insert_cnt)      := gt_deliv_line_tab(ln_index).judgement_date ;
        -- ���i�敪
        i_head_goods_cls_tab(ln_insert_cnt)      := gt_deliv_line_tab(ln_index).goods_classe ;
        -- ���ڋ敪
        i_head_mixed_cd_tab(ln_insert_cnt)       := gt_deliv_line_tab(ln_index).mixed_code ;
        -- �����^��
        i_head_charg_amount_tab(ln_insert_cnt)   := NULL ;
        -- �_��^��
        i_head_contract_rate_tab(ln_insert_cnt)  := gt_deliv_line_tab(ln_index).shipping_expenses ;
        -- ������
        i_head_many_rate_tab(ln_insert_cnt)      := NULL ;
        -- �Œ�����
        i_head_distance_tab(ln_insert_cnt)       := gt_delivno_deliv_line_tab(ln_index).distance ;
        -- �z���敪
        i_head_deliv_cls_tab(ln_insert_cnt)      := gt_deliv_line_tab(ln_index).dellivary_classe ;
        -- ��\�o�ɑq�ɃR�[�h
        i_head_whs_cd_tab(ln_insert_cnt)         := gt_deliv_line_tab(ln_index).whs_code ;
        -- ��\�z����R�[�h�敪
        i_head_cd_dvsn_tab(ln_insert_cnt)        := gt_deliv_line_tab(ln_index).code_division ;
        -- ��\�z����R�[�h
        i_head_ship_addr_cd_tab(ln_insert_cnt)   := 
                                    gt_deliv_line_tab(ln_index).shipping_address_code ;
        -- ���P
        i_head_qty1_tab(ln_insert_cnt)           := gt_delivno_deliv_line_tab(ln_index).qty ;
        -- ���Q
        i_head_qty2_tab(ln_insert_cnt)           := NULL ;
        -- �d�ʂP
        i_head_deliv_wght1_tab(ln_insert_cnt)    := 
                                    gt_delivno_deliv_line_tab(ln_index).delivery_weight ;
        -- �d�ʂQ
        i_head_deliv_wght2_tab(ln_insert_cnt)    := NULL ;
        -- ���ڊ������z
        i_head_cnsld_srhrg_tab(ln_insert_cnt)    := gt_deliv_line_tab(ln_index).consolid_surcharge ;
        -- �Œ����ۋ���
        i_head_actual_ditnc_tab(ln_insert_cnt)   := gt_deliv_line_tab(ln_index).actual_distance ;
        -- �ʍs��
        i_head_cong_chrg_tab(ln_insert_cnt)      := NULL ;
        -- �s�b�L���O��
        i_head_pick_charge_tab(ln_insert_cnt)    := gt_deliv_line_tab(ln_index).picking_charge ;
        -- ���ڐ�
        i_head_consolid_qty_tab(ln_insert_cnt)   := gt_deliv_line_tab(ln_index).consolid_qty ;
        -- ��\�^�C�v
        i_head_order_type_tab(ln_insert_cnt)     := gt_deliv_line_tab(ln_index).order_type ;
        -- �d�ʗe�ϋ敪
        i_head_wigh_cpcty_cls_tab(ln_insert_cnt) := 
                                    gt_deliv_line_tab(ln_index).weight_capacity_class ;
        -- �_��O�敪
        i_head_out_cont_tab(ln_insert_cnt)       := gt_deliv_line_tab(ln_index).outside_contract ;
        i_head_output_flag_tab(ln_insert_cnt)    := gv_ktg_yes ;   -- ���ً敪
        i_head_defined_flag_tab(ln_insert_cnt)   := gv_ktg_no ;    -- �x���m��敪
        i_head_return_flag_tab(ln_insert_cnt)    := gv_ktg_no ;    -- �x���m���
        i_head_fm_upd_flg_tab(ln_insert_cnt)     := gv_ktg_no ;    -- ��ʍX�V�L���敪
        -- �U�֐�
        i_head_trans_lcton_tab(ln_insert_cnt)    := gt_deliv_line_tab(ln_index).description ;
        -- �O���ƎҕύX��
        i_head_out_up_cnt_tab(ln_insert_cnt)     := 0 ;
        -- �^���E�v
        i_head_description_tab(ln_insert_cnt)    := NULL ;
--
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 START #####
        -- �z�ԃ^�C�v�i�ʏ�z�ԁj
        i_head_dispatch_type_tab(ln_insert_cnt) := gv_car_normal;
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 END   #####
--
        -- ���v�i�^����{���ڊ������z�{�s�b�L���O���j
        i_head_total_amount_tab(ln_insert_cnt)   := 
                                      gt_deliv_line_tab(ln_index).shipping_expenses +
                                      gt_deliv_line_tab(ln_index).consolid_surcharge +
                                      gt_deliv_line_tab(ln_index).picking_charge ;
        -- ���z�i���v �~ -1�j
        i_head_balance_tab(ln_insert_cnt)        := 
                                      (gt_deliv_line_tab(ln_index).shipping_expenses +
                                       gt_deliv_line_tab(ln_index).consolid_surcharge +
                                       gt_deliv_line_tab(ln_index).picking_charge) * -1 ;
--
      -- **************************************************
      -- ***  �^���w�b�_�A�h�I���Ƀf�[�^�����݂���ꍇ
      -- **************************************************
      ELSE
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F�^���w�b�_�A�h�I�� UPDATE');
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- �X�V�pPL/SQL�\ ����
        ln_update_cnt   := ln_update_cnt + 1;
--
        -- �^���Ǝ�
        u_head_deliv_cmpny_cd_tab(ln_update_cnt):= 
                              gt_deliv_line_tab(ln_index).delivery_company_code ;
        -- �z��No
        u_head_deliv_no_tab(ln_update_cnt)      := gt_deliv_line_tab(ln_index).delivery_no ;
        -- �����No
        u_head_invoice_no_tab(ln_update_cnt)    := gt_deliv_line_tab(ln_index).invoice_no ;
        -- �x�����f�敪
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
-- ���C��
--        u_head_pay_judg_cls_tab(ln_update_cnt)  := gv_pay ;
        u_head_pay_judg_cls_tab(ln_update_cnt)  := gt_deliv_line_tab(ln_index).payments_judgment_classe ;
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
        -- �o�ɓ�
        u_head_ship_date_tab(ln_update_cnt)     := gt_deliv_line_tab(ln_index).ship_date ;
        -- ������
        u_head_arrival_date_tab(ln_update_cnt)  := gt_deliv_line_tab(ln_index).arrival_date ;
        -- ���f��
        u_head_judg_date_tab(ln_update_cnt)     := gt_deliv_line_tab(ln_index).judgement_date ;
        -- ���i�敪
        u_head_goods_cls_tab(ln_update_cnt)     := gt_deliv_line_tab(ln_index).goods_classe ;
        -- ���ڋ敪
        u_head_mixed_cd_tab(ln_update_cnt)      := gt_deliv_line_tab(ln_index).mixed_code ;
        -- �_��^��
        u_head_contract_rate_tab(ln_update_cnt) := gt_deliv_line_tab(ln_index).shipping_expenses;
        -- �Œ�����
        u_head_distance_tab(ln_update_cnt)      := gt_delivno_deliv_line_tab(ln_index).distance ;
        -- �z���敪
        u_head_deliv_cls_tab(ln_update_cnt)     := gt_deliv_line_tab(ln_index).dellivary_classe ;
        -- ��\�o�ɑq�ɃR�[�h
        u_head_whs_cd_tab(ln_update_cnt)        := gt_deliv_line_tab(ln_index).whs_code ;
        -- ��\�z����R�[�h�敪
        u_head_cd_dvsn_tab(ln_update_cnt)       := gt_deliv_line_tab(ln_index).code_division ;
        -- ��\�z����R�[�h
        u_head_ship_addr_cd_tab(ln_update_cnt)  := 
                              gt_deliv_line_tab(ln_index).shipping_address_code ;
        -- ���P
        u_head_qty1_tab(ln_update_cnt)          := gt_delivno_deliv_line_tab(ln_index).qty ;
        -- �d�ʂP
        u_head_deliv_wght1_tab(ln_update_cnt)   := gt_delivno_deliv_line_tab(ln_index).delivery_weight ;
        -- ���ڊ������z
        u_head_cnsld_srhrg_tab(ln_update_cnt)   := gt_deliv_line_tab(ln_index).consolid_surcharge ;
        -- �Œ����ۋ���
        u_head_actual_ditnc_tab(ln_update_cnt)  := gt_deliv_line_tab(ln_index).actual_distance ;
        -- �s�b�L���O��
        u_head_pick_charge_tab(ln_update_cnt)   := gt_deliv_line_tab(ln_index).picking_charge ;
        -- ���ڐ�
        u_head_consolid_qty_tab(ln_update_cnt)  := gt_deliv_line_tab(ln_index).consolid_qty ;
        -- ��\�^�C�v
        u_head_order_type_tab(ln_update_cnt)    := gt_deliv_line_tab(ln_index).order_type ;
        -- �d�ʗe�ϋ敪
        u_head_wigh_cpcty_cls_tab(ln_update_cnt):= 
                              gt_deliv_line_tab(ln_index).weight_capacity_class ;
        -- �_��O�敪
        u_head_out_cont_tab(ln_update_cnt)      := gt_deliv_line_tab(ln_index).outside_contract ;
        -- �U�֐�
        u_head_trans_lcton_tab(ln_update_cnt)   := gt_deliv_line_tab(ln_index).description ;
--
        -- ���v�i�^����{���ڊ����^���{�s�b�L���O���{�������j
        u_head_total_amount_tab(ln_update_cnt)        := 
                                      gt_deliv_line_tab(ln_index).shipping_expenses +
                                      gt_deliv_line_tab(ln_index).consolid_surcharge +
                                      gt_deliv_line_tab(ln_index).picking_charge +
                                                          NVL(lv_many_rate, 0) ;
        -- ���z�i�����^�� �| ���v�j
        u_head_balance_tab(ln_update_cnt)             := 
                                      NVL(lv_charged_amount, 0) -
                                      (gt_deliv_line_tab(ln_index).shipping_expenses +
                                      gt_deliv_line_tab(ln_index).consolid_surcharge +
                                      gt_deliv_line_tab(ln_index).picking_charge +
                                      NVL(lv_many_rate, 0)) ;
--
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
/*****
        -- �����^�� �� NULL �̏ꍇ
        IF (lv_charged_amount IS NULL) THEN
          -- Y ��ݒ�
          u_head_output_flag_tab(ln_update_cnt)   := gv_ktg_yes ;
--
        -- �����^�� �� NULL�ȊO�A���A���z��0 �ȊO�̏ꍇ
        ELSIF ((lv_charged_amount IS NOT NULL)
          AND (u_head_balance_tab(ln_update_cnt) <> 0)) THEN
          -- Y ��ݒ�
          u_head_output_flag_tab(ln_update_cnt)   := gv_ktg_yes ;
--
        -- ��L�ȊO
        ELSE
          -- N ��ݒ�
          u_head_output_flag_tab(ln_update_cnt)   := gv_ktg_no ;
        END IF;
        -- *** �x���m��敪 ***
        IF (u_head_output_flag_tab(ln_update_cnt) = gv_ktg_yes) THEN
          -- N ��ݒ�
          u_head_defined_flag_tab(ln_update_cnt)  := gv_ktg_no ;
        ELSE
          -- Y ��ݒ�
          u_head_defined_flag_tab(ln_update_cnt)  := gv_ktg_yes ;
        END IF;
*****/
--
        -- *** ���ً敪 ***
        IF (u_head_balance_tab(ln_update_cnt) <> 0) THEN
          u_head_output_flag_tab(ln_update_cnt)   := gv_ktg_yes ;
        ELSE
          u_head_output_flag_tab(ln_update_cnt)   := gv_ktg_no ;
        END IF;
--
        -- *** �x���m��敪 ***
        -- �������z IS NULL �̏ꍇ
        IF (lv_charged_amount IS NULL) THEN
          u_head_defined_flag_tab(ln_update_cnt)  := gv_ktg_no ;
--
        -- ���ً敪 = Y �̏ꍇ
        ELSIF (u_head_output_flag_tab(ln_update_cnt) = gv_ktg_yes) THEN
          u_head_defined_flag_tab(ln_update_cnt)  := gv_ktg_no ;
--
        -- ��L�ȊO�̏ꍇ
        ELSE
          u_head_defined_flag_tab(ln_update_cnt)  := gv_ktg_yes ;
        END IF;
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
--
        -- *** �x���m��� ***
        -- ���̎x���m��敪 �� Y �̏ꍇ
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
--        IF ((lv_defined_flag = gv_ktg_yes) 
--          AND ( u_head_balance_tab(ln_update_cnt) <> 0) ) THEN
        IF (lv_defined_flag = gv_ktg_yes) THEN
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
          -- Y ��ݒ�
          u_head_return_flag_tab(ln_update_cnt)   := gv_ktg_yes ;
--
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
/*****
        -- ���̎x���m��敪 �� Y�A���A����̎x���m��敪 = N �̏ꍇ
        ELSIF ((lv_defined_flag = gv_ktg_yes)
          AND ( u_head_balance_tab(ln_update_cnt) = 0) ) THEN
          -- N ��ݒ�
          u_head_return_flag_tab(ln_update_cnt)   := gv_ktg_no ;
        -- ��L�ȊO�̏ꍇ
        ELSE
          -- �o�^�ς݂̎x���m��� ��ݒ�
          u_head_return_flag_tab(ln_update_cnt)   := lv_return_flag ;
*****/
--
        -- ��L�ȊO�̏ꍇ
        ELSE
          u_head_return_flag_tab(ln_update_cnt)   := gv_ktg_no ;
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
        END IF;
--
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
/*****
        -- �폜�pPL/SQL�\ �o�^
        -- ���z <> 0 �܂��́A�_��^�� = 0 �̏ꍇ
        IF (u_head_balance_tab(ln_update_cnt) <> 0)
          OR (gt_deliv_line_tab(ln_index).shipping_expenses = 0 ) THEN
*****/
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
--
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
        -- �����f�[�^�폜�����̒ǉ�
        IF   (lt_delivery_company_code    <> u_head_deliv_cmpny_cd_tab(ln_update_cnt))    -- �^���Ǝ�
          OR (lt_delivery_no              <> u_head_deliv_no_tab(ln_update_cnt))          -- �z��No
          OR (lt_payments_judgment_classe <> u_head_pay_judg_cls_tab(ln_update_cnt))  -- �x�����f�敪
          OR (lt_ship_date                <> u_head_ship_date_tab(ln_update_cnt))         -- �o�ɓ�
          OR (lt_arrival_date             <> u_head_arrival_date_tab(ln_update_cnt))      -- ������
          OR (lt_judgement_date           <> u_head_judg_date_tab(ln_update_cnt))         -- ���f��
          OR (lt_goods_classe             <> u_head_goods_cls_tab(ln_update_cnt))         -- ���i�敪
          OR (lt_mixed_code               <> u_head_mixed_cd_tab(ln_update_cnt))          -- ���ڋ敪
          OR (lt_contract_rate            <> u_head_contract_rate_tab(ln_update_cnt))     -- �_��^��
          OR (lt_balance                  <> u_head_balance_tab(ln_update_cnt))           -- ���z
          OR (lt_total_amount             <> u_head_total_amount_tab(ln_update_cnt))      -- ���v
          OR (lt_distance                 <> u_head_distance_tab(ln_update_cnt))          -- �Œ�����
          OR (lt_delivery_classe          <> u_head_deliv_cls_tab(ln_update_cnt))         -- �z���敪
          OR (lt_whs_code                 <> u_head_whs_cd_tab(ln_update_cnt))            -- ��\�o�ɑq�ɃR�[�h
          OR (lt_code_division            <> u_head_cd_dvsn_tab(ln_update_cnt))           -- ��\�z����R�[�h�敪
          OR (lt_shipping_address_code    <> u_head_ship_addr_cd_tab(ln_update_cnt))      -- ��\�z����R�[�h
          OR (lt_qty1                     <> u_head_qty1_tab(ln_update_cnt))              -- ���P
          OR (lt_delivery_weight1         <> u_head_deliv_wght1_tab(ln_update_cnt))       -- �d�ʂP
          OR (lt_consolid_surcharge       <> u_head_cnsld_srhrg_tab(ln_update_cnt))       -- ���ڊ������z
          OR (lt_actual_distance          <> u_head_actual_ditnc_tab(ln_update_cnt))      -- �Œ����ۋ���
          OR (lt_picking_charge           <> u_head_pick_charge_tab(ln_update_cnt))       -- �s�b�L���O��
          OR (lt_consolid_qty             <> u_head_consolid_qty_tab(ln_update_cnt))      -- ���ڐ�
          OR (lt_order_type               <> u_head_order_type_tab(ln_update_cnt))        -- ��\�^�C�v
          OR (lt_weight_capacity_class    <> u_head_wigh_cpcty_cls_tab(ln_update_cnt))    -- �d�ʗe�ϋ敪
        THEN
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F�^���w�b�_�A�h�I�� DELETE');
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F�^���Ǝ�             �F' || lt_delivery_company_code   || ' <> ' || u_head_deliv_cmpny_cd_tab(ln_update_cnt));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F�z��No               �F' || lt_delivery_no             || ' <> ' || u_head_deliv_no_tab(ln_update_cnt));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F�x�����f�敪         �F' || lt_payments_judgment_classe|| ' <> ' || u_head_pay_judg_cls_tab(ln_update_cnt));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F�o�ɓ�               �F' || TO_CHAR(lt_ship_date,'YYYY/MM/DD')     || ' <> ' ||
                                                                                         TO_CHAR(u_head_ship_date_tab(ln_update_cnt),'YYYY/MM/DD'));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F������               �F' || TO_CHAR(lt_arrival_date,'YYYY/MM/DD')  || ' <> ' ||  
                                                                                         TO_CHAR(u_head_arrival_date_tab(ln_update_cnt),'YYYY/MM/DD'));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F���f��               �F' || TO_CHAR(lt_judgement_date,'YYYY/MM/DD')|| ' <> ' || 
                                                                                         TO_CHAR(u_head_judg_date_tab(ln_update_cnt),'YYYY/MM/DD'));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F���i�敪             �F' || lt_goods_classe            || ' <> ' ||  u_head_goods_cls_tab(ln_update_cnt));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F���ڋ敪             �F' || lt_mixed_code              || ' <> ' ||  u_head_mixed_cd_tab(ln_update_cnt));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F�_��^��             �F' || TO_CHAR(lt_contract_rate)  || ' <> ' ||  TO_CHAR(u_head_contract_rate_tab(ln_update_cnt)));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F���z                 �F' || TO_CHAR(lt_balance)        || ' <> ' ||  TO_CHAR(u_head_balance_tab(ln_update_cnt)));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F���v                 �F' || TO_CHAR(lt_total_amount)   || ' <> ' ||  TO_CHAR(u_head_total_amount_tab(ln_update_cnt)));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F�Œ�����             �F' || TO_CHAR(lt_distance)       || ' <> ' ||  TO_CHAR(u_head_distance_tab(ln_update_cnt)));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F�z���敪             �F' || lt_delivery_classe         || ' <> ' ||  u_head_deliv_cls_tab(ln_update_cnt));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F��\�o�ɑq�ɃR�[�h   �F' || lt_whs_code                || ' <> ' ||  u_head_whs_cd_tab(ln_update_cnt));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F��\�z����R�[�h�敪 �F' || lt_code_division           || ' <> ' ||  u_head_cd_dvsn_tab(ln_update_cnt));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F��\�z����R�[�h     �F' || lt_shipping_address_code   || ' <> ' ||  u_head_ship_addr_cd_tab(ln_update_cnt));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F���P               �F' || TO_CHAR(lt_qty1)               || ' <> ' ||  TO_CHAR(u_head_qty1_tab(ln_update_cnt)));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F�d�ʂP               �F' || TO_CHAR(lt_delivery_weight1)   || ' <> ' ||  TO_CHAR(u_head_deliv_wght1_tab(ln_update_cnt)));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F���ڊ������z         �F' || TO_CHAR(lt_consolid_surcharge) || ' <> ' ||  TO_CHAR(u_head_cnsld_srhrg_tab(ln_update_cnt)));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F�Œ����ۋ���         �F' || TO_CHAR(lt_actual_distance)    || ' <> ' ||  TO_CHAR(u_head_actual_ditnc_tab(ln_update_cnt)));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F�s�b�L���O��         �F' || TO_CHAR(lt_picking_charge)     || ' <> ' ||  TO_CHAR(u_head_pick_charge_tab(ln_update_cnt)));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F���ڐ�               �F' || TO_CHAR(lt_consolid_qty)       || ' <> ' ||  TO_CHAR(u_head_consolid_qty_tab(ln_update_cnt)));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F��\�^�C�v           �F' || lt_order_type                  || ' <> ' ||  u_head_order_type_tab(ln_update_cnt));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_deliv_head�F�d�ʗe�ϋ敪         �F' || lt_weight_capacity_class       || ' <> ' ||  u_head_wigh_cpcty_cls_tab(ln_update_cnt));
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- �폜�pPL/SQL�\ ����
          ln_delete_cnt   := ln_delete_cnt + 1;
          -- �z��No
          d_head_deliv_no_tab(ln_delete_cnt)  := gt_deliv_line_tab(ln_index).delivery_no ;
--
-- ##### 20081226 Ver.1.18 �{��#323�Ή��i���O�Ή��j START #####
          -- ���ѕύX�ɂ��폜 ���O�o�͗p�̈�i�[
          gn_delete_data_idx := gn_delete_data_idx + 1;
-- ##### 20081229 Ver.1.19 �{��#882�Ή� START #####
--          gt_delete_data_msg(gn_delete_data_idx) :=  d_head_deliv_no_tab(ln_delete_cnt);
          gt_delete_data_msg(gn_delete_data_idx) :=  u_head_deliv_no_tab(ln_update_cnt)     || '  ' ;  -- �z��No
          gt_delete_data_msg(gn_delete_data_idx) :=  gt_delete_data_msg(gn_delete_data_idx) || u_head_deliv_cmpny_cd_tab(ln_update_cnt) || '  ' ; -- �^���Ǝ�
          gt_delete_data_msg(gn_delete_data_idx) :=  gt_delete_data_msg(gn_delete_data_idx) || TO_CHAR(u_head_ship_date_tab(ln_update_cnt),'YYYY/MM/DD'); -- �o�ד�
-- ##### 20081229 Ver.1.19 �{��#882�Ή� END   #####
-- ##### 20081226 Ver.1.18 �{��#323�Ή��i���O�Ή��j END   #####
--
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
        END IF;
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
--
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
/*****
        END IF;
*****/
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
--
      END IF;
--
    END LOOP deliv_loop;
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
  END set_deliv_head;
--
  /**********************************************************************************
   * Procedure Name   : get_carriers_schedule
   * Description      : �z�Ԕz���v�撊�o(A-31)
   ***********************************************************************************/
  PROCEDURE get_carriers_schedule(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_carriers_schedule'; -- �v���O������
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
    -- �z�Ԕz���v�� ���o
    /*SELECT    xcs.result_freight_carrier_code       -- �^���Ǝ�
            , xcs.delivery_no                       -- �z��No
            , xcs.shipped_date                      -- �o�ɓ�
            , xcs.arrival_date                      -- ������
            , xcs.result_shipping_method_code       -- �z���敪
            , xcs.deliver_from                      -- ��\�o�ɑq�ɃR�[�h
            , xcs.deliver_to_code_class             -- ��\�z����R�[�h�敪
            , xcs.deliver_to                        -- ��\�z����R�[�h
            , xcs.weight_capacity_class             -- �d�ʗe�ϋ敪
            , xdec.payments_judgment_classe         -- �x�����f�敪
            , CASE xdec.payments_judgment_classe    -- �x�����f�敪
              WHEN gv_pay_judg_g  THEN xcs.shipped_date -- �����F�o�ד�
              WHEN gv_pay_judg_c  THEN xcs.arrival_date -- �����F���ד�
              END
            , xott2v.mixed_class                    -- ���ڋ敪
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 START #####
            , xcs.transaction_type                  -- �������
            , xcs.prod_class                        -- ���i�敪
            , xcs.non_slip_class                    -- �`�[�Ȃ��z�ԋ敪
            , xcs.slip_number                       -- �����No
-- ##### 20081031 Ver.1.11 ����#531�Ή� START #####
--            , xcs.small_quantity                    -- ������
            , NVL(xcs.small_quantity, 0)            -- ������
-- ##### 20081031 Ver.1.11 ����#531�Ή� END   #####
            , xott2v.small_amount_class             -- �����敪
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 END   #####
    BULK COLLECT INTO gt_carriers_schedule_tab
    FROM  xxwsh_carriers_schedule       xcs,        -- �z�Ԕz���v��i�A�h�I���j
          xxwsh_ship_method2_v          xott2v,     -- �z���敪���VIEW2
          xxwip_delivery_company        xdec        -- �^���p�^���Ǝ҃A�h�I���}�X�^
    WHERE xcs.shipped_date IS NOT NULL              -- �o�ד�
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 START #####
--    AND   gv_prod_class_lef = xdec.goods_classe                         -- ���i�敪�i���[�t�Œ�j
    AND   xcs.arrival_date                IS NOT NULL -- ���ד�
    AND   xcs.result_freight_carrier_code IS NOT NULL -- �^���Ǝ�_����
    AND   xcs.result_shipping_method_code IS NOT NULL -- �z���敪_����
    AND   xcs.non_slip_class IN ( gv_non_slip_slp     --  �`�[�Ȃ��z��
                                , gv_non_slip_can)    --  �`�[�Ȃ��z�ԉ���
    AND   xcs.prod_class          = xdec.goods_classe                   -- ���i�敪
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 END   #####
    AND   xcs.result_freight_carrier_code = xdec.delivery_company_code  -- �^���Ǝ�
    AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                  -- �K�p�J�n��
    AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                  -- �K�p�I����
    AND   xcs.result_shipping_method_code = xott2v.ship_method_code     -- �z���敪
    AND   xott2v.start_date_active  <= TRUNC(gd_sysdate)                -- �L���J�n��
    AND   NVL(xott2v.end_date_active,TO_DATE('99991231','YYYYMMDD'))
                                     >= TRUNC(gd_sysdate)                -- �L���I����
    AND   (
            ((xdec.payments_judgment_classe = gv_pay_judg_g)      -- �x�����f�敪�i�����j
            AND (xcs.shipped_date >=  gd_target_date))            -- �o�ד�
          OR
            ((xdec.payments_judgment_classe = gv_pay_judg_c)      -- �x�����f�敪�i�����j
            AND (xcs.arrival_date >=  gd_target_date))            -- ���ד�
          )
    AND ((xcs.last_update_date > gd_last_process_date)            -- �O�񏈗����t
          AND  (xcs.last_update_date <= gd_sysdate));*/   
--
    SELECT
      car_info.result_freight_carrier_code
     ,car_info.delivery_no
     ,car_info.shipped_date
     ,car_info.arrival_date
     ,car_info.result_shipping_method_code
     ,car_info.deliver_from
     ,car_info.deliver_to_code_class
     ,car_info.deliver_to
     ,car_info.weight_capacity_class
     ,car_info.payments_judgment_classe
     ,car_info.judgment_date
     ,car_info.mixed_class
     ,car_info.transaction_type
     ,car_info.prod_class
     ,car_info.non_slip_class
     ,car_info.slip_number
     ,car_info.small_quantity
     ,car_info.small_amount_class
    BULK COLLECT INTO gt_carriers_schedule_tab
    FROM (
      -- ����
      SELECT    xcs.result_freight_carrier_code      result_freight_carrier_code -- �^���Ǝ�
              , xcs.delivery_no                      delivery_no -- �z��No
              , xcs.shipped_date                     shipped_date -- �o�ɓ�
              , xcs.arrival_date                     arrival_date -- ������
              , xcs.result_shipping_method_code      result_shipping_method_code -- �z���敪
              , xcs.deliver_from                     deliver_from -- ��\�o�ɑq�ɃR�[�h
              , xcs.deliver_to_code_class            deliver_to_code_class -- ��\�z����R�[�h�敪
              , xcs.deliver_to                       deliver_to -- ��\�z����R�[�h
              , xcs.weight_capacity_class            weight_capacity_class -- �d�ʗe�ϋ敪
              , xdec.payments_judgment_classe        payments_judgment_classe -- �x�����f�敪
              , xcs.arrival_date                     judgment_date -- ���f��
              , xott2v.mixed_class                   mixed_class -- ���ڋ敪
              , xcs.transaction_type                 transaction_type -- �������
              , xcs.prod_class                       prod_class -- ���i�敪
              , xcs.non_slip_class                   non_slip_class -- �`�[�Ȃ��z�ԋ敪
              , xcs.slip_number                      slip_number -- �����No
              , NVL(xcs.small_quantity, 0)           small_quantity -- ������
              , xott2v.small_amount_class            small_amount_class -- �����敪
      FROM  xxwsh_carriers_schedule       xcs,        -- �z�Ԕz���v��i�A�h�I���j
            xxwsh_ship_method2_v          xott2v,     -- �z���敪���VIEW2
            xxwip_delivery_company        xdec        -- �^���p�^���Ǝ҃A�h�I���}�X�^
      WHERE xcs.shipped_date IS NOT NULL              -- �o�ד�        -- ���i�敪�i���[�t�Œ�j
      AND   xcs.arrival_date                IS NOT NULL -- ���ד�
      AND   xcs.result_freight_carrier_code IS NOT NULL -- �^���Ǝ�_����
      AND   xcs.result_shipping_method_code IS NOT NULL -- �z���敪_����
      AND   xcs.non_slip_class IN ( gv_non_slip_slp     --  �`�[�Ȃ��z��
                                  , gv_non_slip_can)    --  �`�[�Ȃ��z�ԉ���
      AND   xcs.prod_class          = xdec.goods_classe                   -- ���i�敪
      AND   xcs.result_freight_carrier_code = xdec.delivery_company_code  -- �^���Ǝ�
      AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                  -- �K�p�J�n��
      AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                  -- �K�p�I����
      AND   xcs.result_shipping_method_code = xott2v.ship_method_code     -- �z���敪
      AND   xott2v.start_date_active  <= TRUNC(gd_sysdate)                -- �L���J�n��
      AND   NVL(xott2v.end_date_active,TO_DATE('99991231','YYYYMMDD'))
                                       >= TRUNC(gd_sysdate)                -- �L���I����
      AND   xdec.payments_judgment_classe = gv_pay_judg_c      -- �x�����f�敪�i�����j
      AND   xcs.arrival_date >=  gd_target_date                -- ���ד�
      AND ((xcs.last_update_date > gd_last_process_date)            -- �O�񏈗����t
            AND  (xcs.last_update_date <= gd_sysdate))
      UNION ALL
      -- ����
      SELECT    xcs.result_freight_carrier_code      result_freight_carrier_code -- �^���Ǝ�
              , xcs.delivery_no                      delivery_no -- �z��No
              , xcs.shipped_date                     shipped_date -- �o�ɓ�
              , xcs.arrival_date                     arrival_date -- ������
              , xcs.result_shipping_method_code      result_shipping_method_code -- �z���敪
              , xcs.deliver_from                     deliver_from -- ��\�o�ɑq�ɃR�[�h
              , xcs.deliver_to_code_class            deliver_to_code_class -- ��\�z����R�[�h�敪
              , xcs.deliver_to                       deliver_to -- ��\�z����R�[�h
              , xcs.weight_capacity_class            weight_capacity_class -- �d�ʗe�ϋ敪
              , xdec.payments_judgment_classe        payments_judgment_classe -- �x�����f�敪
              , xcs.shipped_date                     judgment_date-- ���f��
              , xott2v.mixed_class                   mixed_class -- ���ڋ敪
              , xcs.transaction_type                 transaction_type -- �������
              , xcs.prod_class                       prod_class -- ���i�敪
              , xcs.non_slip_class                   non_slip_class -- �`�[�Ȃ��z�ԋ敪
              , xcs.slip_number                      slip_number -- �����No
              , NVL(xcs.small_quantity, 0)           small_quantity -- ������
              , xott2v.small_amount_class            small_amount_class -- �����敪
      FROM  xxwsh_carriers_schedule       xcs,        -- �z�Ԕz���v��i�A�h�I���j
            xxwsh_ship_method2_v          xott2v,     -- �z���敪���VIEW2
            xxwip_delivery_company        xdec        -- �^���p�^���Ǝ҃A�h�I���}�X�^
      WHERE xcs.shipped_date IS NOT NULL              -- �o�ד�        -- ���i�敪�i���[�t�Œ�j
      AND   xcs.arrival_date                IS NOT NULL -- ���ד�
      AND   xcs.result_freight_carrier_code IS NOT NULL -- �^���Ǝ�_����
      AND   xcs.result_shipping_method_code IS NOT NULL -- �z���敪_����
      AND   xcs.non_slip_class IN ( gv_non_slip_slp     --  �`�[�Ȃ��z��
                                  , gv_non_slip_can)    --  �`�[�Ȃ��z�ԉ���
      AND   xcs.prod_class          = xdec.goods_classe                   -- ���i�敪
      AND   xcs.result_freight_carrier_code = xdec.delivery_company_code  -- �^���Ǝ�
      AND   xdec.start_date_active  <= TRUNC(gd_sysdate)                  -- �K�p�J�n��
      AND   xdec.end_date_active    >= TRUNC(gd_sysdate)                  -- �K�p�I����
      AND   xcs.result_shipping_method_code = xott2v.ship_method_code     -- �z���敪
      AND   xott2v.start_date_active  <= TRUNC(gd_sysdate)                -- �L���J�n��
      AND   NVL(xott2v.end_date_active,TO_DATE('99991231','YYYYMMDD'))
                                       >= TRUNC(gd_sysdate)                -- �L���I����
      AND   xdec.payments_judgment_classe = gv_pay_judg_g      -- �x�����f�敪�i�����j
      AND   xcs.shipped_date >=  gd_target_date                -- �o�ד�
      AND ((xcs.last_update_date > gd_last_process_date)            -- �O�񏈗����t
            AND  (xcs.last_update_date <= gd_sysdate))
      ) car_info
    ;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_carriers_schedule�F�`�[�Ȃ��z�� ���o�����F' || TO_CHAR(gt_carriers_schedule_tab.COUNT));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
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
  END get_carriers_schedule;
--
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 START #####
-- A-32�̏�����g����
--
  /**********************************************************************************
   * Procedure Name   : set_carri_deliv_head
   * Description      : �`�[�Ȃ��z��PL/SQL�\�i�[ (A-32)
   ***********************************************************************************/
  PROCEDURE set_carri_deliv_head(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_carri_deliv_head'; -- �v���O������
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
    lv_delivery_no          xxwip_deliverys.delivery_no%TYPE;         -- �z��No
    lv_many_rate            xxwip_deliverys.many_rate%TYPE;           -- ������
    lv_consolid_surcharge   xxwip_deliverys.consolid_surcharge%TYPE;  -- ���ڊ������z
    lv_charged_amount       xxwip_deliverys.charged_amount%TYPE;      -- �������z
    lv_defined_flag         xxwip_deliverys.defined_flag%TYPE;        -- �x���m��敪
    lv_return_flag          xxwip_deliverys.return_flag%TYPE;         -- �x���m���
--
    lv_code_division    xxwip_deliverys.code_division%TYPE;   -- �R�[�h�敪
--
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
    lt_delivery_company_code      xxwip_deliverys.delivery_company_code%TYPE;     -- �^���Ǝ�
    lt_delivery_no                xxwip_deliverys.delivery_no%TYPE;               -- �z��No
    lt_payments_judgment_classe   xxwip_deliverys.payments_judgment_classe%TYPE;  -- �x�����f�敪
    lt_ship_date                  xxwip_deliverys.ship_date%TYPE;                 -- �o�ɓ�
    lt_arrival_date               xxwip_deliverys.arrival_date%TYPE;              -- ������
    lt_judgement_date             xxwip_deliverys.judgement_date%TYPE;            -- ���f��
    lt_goods_classe               xxwip_deliverys.goods_classe%TYPE;              -- ���i�敪
    lt_mixed_code                 xxwip_deliverys.mixed_code%TYPE;                -- ���ڋ敪
    lt_contract_rate              xxwip_deliverys.contract_rate%TYPE;             -- �_��^��
    lt_balance                    xxwip_deliverys.balance%TYPE;                   -- ���z
    lt_total_amount               xxwip_deliverys.total_amount%TYPE;              -- ���v
    lt_distance                   xxwip_deliverys.distance%TYPE;                  -- �Œ�����
    lt_delivery_classe            xxwip_deliverys.delivery_classe%TYPE;           -- �z���敪
    lt_whs_code                   xxwip_deliverys.whs_code%TYPE;                  -- ��\�o�ɑq�ɃR�[�h
    lt_code_division              xxwip_deliverys.code_division%TYPE;             -- ��\�z����R�[�h�敪
    lt_shipping_address_code      xxwip_deliverys.shipping_address_code%TYPE;     -- ��\�z����R�[�h
    lt_qty1                       xxwip_deliverys.qty1%TYPE;                      -- ���P
    lt_delivery_weight1           xxwip_deliverys.delivery_weight1%TYPE;          -- �d�ʂP
    lt_consolid_surcharge         xxwip_deliverys.consolid_surcharge%TYPE;        -- ���ڊ������z
    lt_actual_distance            xxwip_deliverys.actual_distance%TYPE;           -- �Œ����ۋ���
    lt_picking_charge             xxwip_deliverys.picking_charge%TYPE;            -- �s�b�L���O��
    lt_consolid_qty               xxwip_deliverys.consolid_qty%TYPE;              -- ���ڐ�
    lt_order_type                 xxwip_deliverys.order_type%TYPE;                -- ��\�^�C�v
    lt_weight_capacity_class      xxwip_deliverys.weight_capacity_class%TYPE;     -- �d�ʗe�ϋ敪
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
--
    -- �^���n�}�X�^ �擾�p
    lr_delivery_company_tab   xxwip_common3_pkg.delivery_company_rec;   -- �^���p�^���Ǝ�
    lr_delivery_distance_tab  xxwip_common3_pkg.delivery_distance_rec;  -- �z������
    lr_delivery_charges_tab   xxwip_common3_pkg.delivery_charges_rec;   -- �^��
--
-- ##### 20090209 Ver.1.22 �{��#1107�Ή� START #####
    ln_distance                   xxwip_deliverys.distance%TYPE;                  -- �Œ�����
-- ##### 20090209 Ver.1.22 �{��#1107�Ή� END   #####
--
    ln_del_can_cnt    NUMBER;   -- �`�[�Ȃ��z�ԉ��� �J�E���^
    ln_insert_cnt     NUMBER;   -- �o�^�pPL/SQL�\ ����
    ln_update_cnt     NUMBER;   -- �X�V�pPL/SQL�\ ����
    ln_delete_cnt     NUMBER;   -- �폜�pPL/SQL�\ ����
--
    ln_weight         NUMBER;   -- �d��
    ln_deliv_flg      VARCHAR2(1);  -- �^���w�b�_�A�h�I�� ���݃t���O Y:�L N:��
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
    -- �Ώۃf�[�^���̏ꍇ
    IF (gt_carriers_schedule_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    -- �J�E���^�[�����l�ݒ�
    ln_del_can_cnt  := 0;
    ln_insert_cnt   := i_head_deliv_no_tab.COUNT;
    ln_update_cnt   := u_head_deliv_no_tab.COUNT;
    ln_delete_cnt   := d_head_deliv_no_tab.COUNT;
--
    <<deliv_loop>>
    FOR ln_index IN  gt_carriers_schedule_tab.FIRST.. gt_carriers_schedule_tab.LAST LOOP
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F$$$$$$$$$$ �`�[�Ȃ��z�� ���� $$$$$$$$$$�F' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�`�[�Ȃ��z�ԋ敪�F' || gt_carriers_schedule_tab(ln_index).non_slip_class);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F���i�敪        �F' || gt_carriers_schedule_tab(ln_index).prod_class);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�����敪        �F' || gt_carriers_schedule_tab(ln_index).small_amount_class);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�d�ʗe�ϋ敪    �F' || gt_carriers_schedule_tab(ln_index).weight_capacity_class);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- *******************************************************************************************
      -- *** �u�`�[�Ȃ��z�ԉ����v�̏ꍇ
      -- *******************************************************************************************
      IF (gt_carriers_schedule_tab(ln_index).non_slip_class = gv_non_slip_can) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F$$$$$ �`�[�Ȃ��z�ԉ����I $$$$$');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�z��No�F'|| gt_carriers_schedule_tab(ln_index).delivery_no);
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- �^���w�b�_�`�[�Ȃ��z�ԍ폜�pPL/SQL�\�֊i�[
        ln_del_can_cnt := ln_del_can_cnt + 1;
        d_slip_head_deliv_no_tab(ln_del_can_cnt) := gt_carriers_schedule_tab(ln_index).delivery_no;
--
      -- *******************************************************************************************
      -- *** �ȉ��̏����̏ꍇ
      -- ***   �`�[�Ȃ��z�ԋ敪 ���u�`�[�Ȃ��z�ԁv
      -- ***   ���i�敪         ���u���[�t�v
      -- ***   �����敪         ���u�����v
      -- *******************************************************************************************
      ELSIF ((gt_carriers_schedule_tab(ln_index).non_slip_class       = gv_non_slip_slp   )
        AND  (gt_carriers_schedule_tab(ln_index).prod_class           = gv_prod_class_lef )
        AND  (gt_carriers_schedule_tab(ln_index).small_amount_class   = gv_small_sum_yes  )) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F$$$$$ �`�[�Ȃ��z�ԁi���[�t�����j�^���v�Z�ΏہI $$$$$');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�z��No�F'|| gt_carriers_schedule_tab(ln_index).delivery_no);
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- **************************************************
        -- ***  �^���p�^���Ǝ҃A�h�I���}�X�^���o
        -- **************************************************
        xxwip_common3_pkg.get_delivery_company(
          gt_carriers_schedule_tab(ln_index).prod_class,             -- ���i�敪
          gt_carriers_schedule_tab(ln_index).delivery_company_code,  -- �^���Ǝ�
          gt_carriers_schedule_tab(ln_index).judgement_date,         -- ���f��
          lr_delivery_company_tab,                                   -- �^���p�^���Ǝ҃��R�[�h
          lv_errbuf,
          lv_retcode,
          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F$ �^���p�^���Ǝ҃A�h�I���}�X�^���o $');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�����d��          �F'|| TO_CHAR(lr_delivery_company_tab.small_weight));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�x���s�b�L���O�P���F'|| TO_CHAR(lr_delivery_company_tab.pay_picking_amount));
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- **************************************************
        -- ***  �z�������A�h�I���}�X�^���o
        -- **************************************************
        -- ��\�z����R�[�h�敪�ϊ�
        xxwip_common3_pkg.change_code_division(
          gt_carriers_schedule_tab(ln_index).code_division, -- ��\�z����R�[�h�敪
          lv_code_division,                                 -- �R�[�h�敪�i�^���p�j
          lv_errbuf,
          lv_retcode,
          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- �z�������A�h�I���}�X�^���o
        xxwip_common3_pkg.get_delivery_distance(
          gt_carriers_schedule_tab(ln_index).prod_class,            -- ���i�敪
          gt_carriers_schedule_tab(ln_index).delivery_company_code, -- �^���Ǝ�
          gt_carriers_schedule_tab(ln_index).whs_code,              -- �o�ɑq��
          lv_code_division ,                                        -- �R�[�h�敪
          gt_carriers_schedule_tab(ln_index).shipping_address_code, -- �z����R�[�h
          gt_carriers_schedule_tab(ln_index).judgement_date,        -- ���f��
          lr_delivery_distance_tab,                                 -- �z�������A�h�I���}�X�^���R�[�h
          lv_errbuf,
          lv_retcode,
          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F$ �z�������A�h�I���}�X�^���o $');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�ԗ�����    �F'|| TO_CHAR(lr_delivery_distance_tab.post_distance));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F��������    �F'|| TO_CHAR(lr_delivery_distance_tab.small_distance));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F���ڊ��������F'|| TO_CHAR(lr_delivery_distance_tab.consolid_add_distance));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F���ۋ���    �F'|| TO_CHAR(lr_delivery_distance_tab.actual_distance));
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- **************************************************
        -- ***  �^���A�h�I���}�X�^���o
        -- **************************************************
        -- �d�ʎZ�o�i�������~�����d�ʁj
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� START #####
--        ln_weight := gt_carriers_schedule_tab(ln_index).small_quantity *
--                                          lr_delivery_company_tab.small_weight;
        ln_weight := CEIL(TRUNC(gt_carriers_schedule_tab(ln_index).small_quantity *
                                          lr_delivery_company_tab.small_weight, 1));
-- ##### 20090203 Ver.1.21 �{��#1017�Ή� END   #####
--
        xxwip_common3_pkg.get_delivery_charges(
          gv_pay,                                                   -- �x�������敪
          gt_carriers_schedule_tab(ln_index).prod_class,            -- ���i�敪
          gt_carriers_schedule_tab(ln_index).delivery_company_code, -- �^���Ǝ�
          gt_carriers_schedule_tab(ln_index).dellivary_classe,      -- �z���敪
          lr_delivery_distance_tab.small_distance,                  -- �^�������i���������j
          ln_weight,                                                -- �d��
          gt_carriers_schedule_tab(ln_index).judgement_date,        -- ���f��
          lr_delivery_charges_tab,                                  -- �^���A�h�I�����R�[�h
          lv_errbuf,
          lv_retcode,
          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F$ �^���A�h�I���}�X�^���o $');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�^����        �F'|| TO_CHAR(lr_delivery_charges_tab.shipping_expenses));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F���[�t���ڊ����F'|| TO_CHAR(lr_delivery_charges_tab.leaf_consolid_add));
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- **************************************************
        -- ***  �^���w�b�_�A�h�I�����o
        -- **************************************************
        -- ���݃t���O������
        ln_deliv_flg := gv_ktg_yes;
--
        BEGIN
          SELECT  xd.delivery_no        -- �z��No
                , xd.many_rate          -- ������
                , consolid_surcharge    -- ���ڊ������z
                , charged_amount        -- �������z
                , xd.defined_flag       -- �x���m��敪
                , xd.return_flag        -- �x���m���
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
                , xd.delivery_company_code      -- �^���Ǝ�
                , xd.delivery_no                -- �z��No
                , xd.payments_judgment_classe   -- �x�����f�敪
                , xd.ship_date                  -- �o�ɓ�
                , xd.arrival_date               -- ������
                , xd.judgement_date             -- ���f��
                , xd.goods_classe               -- ���i�敪
                , xd.mixed_code                 -- ���ڋ敪
                , xd.contract_rate              -- �_��^��
                , xd.balance                    -- ���z
                , xd.total_amount               -- ���v
                , xd.distance                   -- �Œ�����
                , xd.delivery_classe            -- �z���敪
                , xd.whs_code                   -- ��\�o�ɑq�ɃR�[�h
                , xd.code_division              -- ��\�z����R�[�h�敪
                , xd.shipping_address_code      -- ��\�z����R�[�h
                , xd.qty1                       -- ���P
                , xd.delivery_weight1           -- �d�ʂP
                , xd.consolid_surcharge         -- ���ڊ������z
                , xd.actual_distance            -- �Œ����ۋ���
                , xd.picking_charge             -- �s�b�L���O��
                , xd.consolid_qty               -- ���ڐ�
                , xd.order_type                 -- ��\�^�C�v
                , xd.weight_capacity_class      -- �d�ʗe�ϋ敪
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
          INTO    lv_delivery_no
                , lv_many_rate
                , lv_consolid_surcharge
                , lv_charged_amount
                , lv_defined_flag
                , lv_return_flag
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
                , lt_delivery_company_code      -- �^���Ǝ�
                , lt_delivery_no                -- �z��No
                , lt_payments_judgment_classe   -- �x�����f�敪
                , lt_ship_date                  -- �o�ɓ�
                , lt_arrival_date               -- ������
                , lt_judgement_date             -- ���f��
                , lt_goods_classe               -- ���i�敪
                , lt_mixed_code                 -- ���ڋ敪
                , lt_contract_rate              -- �_��^��
                , lt_balance                    -- ���z
                , lt_total_amount               -- ���v
                , lt_distance                   -- �Œ�����
                , lt_delivery_classe            -- �z���敪
                , lt_whs_code                   -- ��\�o�ɑq�ɃR�[�h
                , lt_code_division              -- ��\�z����R�[�h�敪
                , lt_shipping_address_code      -- ��\�z����R�[�h
                , lt_qty1                       -- ���P
                , lt_delivery_weight1           -- �d�ʂP
                , lt_consolid_surcharge         -- ���ڊ������z
                , lt_actual_distance            -- �Œ����ۋ���
                , lt_picking_charge             -- �s�b�L���O��
                , lt_consolid_qty               -- ���ڐ�
                , lt_order_type                 -- ��\�^�C�v
                , lt_weight_capacity_class      -- �d�ʗe�ϋ敪
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
          FROM   xxwip_deliverys      xd      -- �^���w�b�_�A�h�I��
          WHERE  xd.delivery_no = gt_carriers_schedule_tab(ln_index).delivery_no -- �z��No
          AND    xd.p_b_classe = gv_pay ;                           -- �x�������敪�i�x���j
        EXCEPTION
          WHEN NO_DATA_FOUND THEN   -- *** �f�[�^�擾�G���[ ***
            -- ���݃t���O Y ��ݒ�
            ln_deliv_flg := gv_ktg_no;
--
          WHEN TOO_MANY_ROWS THEN   -- *** �f�[�^�����擾�G���[ ***
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                  gv_xxcmn_msg_toomny,
                                                  gv_tkn_table,
                                                  gv_deliverys,
                                                  gv_tkn_key,
                                                  gv_pay || ',' ||
                                                  gt_carriers_schedule_tab(ln_index).delivery_no);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F$ �^���w�b�_�A�h�I�� $�F' || ln_deliv_flg);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�z��No      �F'|| lv_delivery_no);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F������      �F'|| TO_CHAR(lv_many_rate));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F���ڋ��z    �F'|| TO_CHAR(lv_consolid_surcharge));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�������z    �F'|| TO_CHAR(lv_charged_amount));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�x���m��敪�F'|| lv_defined_flag);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�x���m���  �F'|| lv_return_flag);
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- �^���w�b�_�A�h�I���Ƀf�[�^�����݂��Ȃ��ꍇ
        IF (ln_deliv_flg = gv_ktg_no) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�^���w�b�_�A�h�I�� INSERT');
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- **************************************************
          -- ***  �`�[�Ȃ��z�ԁi���[�t�����j�o�^
          -- **************************************************
          -- �o�^�pPL/SQL�\ ����
          ln_insert_cnt  := ln_insert_cnt + 1;
--
          -- �^���Ǝ�
          i_head_deliv_cmpny_cd_tab(ln_insert_cnt) := gt_carriers_schedule_tab(ln_index).delivery_company_code ;
          -- �z��No
          i_head_deliv_no_tab(ln_insert_cnt)       := gt_carriers_schedule_tab(ln_index).delivery_no ;
          -- �����No
          i_head_invoice_no_tab(ln_insert_cnt)     := gt_carriers_schedule_tab(ln_index).slip_number ;
          -- �x�������敪
          i_head_p_b_classe_tab(ln_insert_cnt)     := gv_pay ;
          -- �x�����f�敪
          i_head_pay_judg_cls_tab(ln_insert_cnt)   := gt_carriers_schedule_tab(ln_index).payments_judgment_classe ;
          -- �o�ɓ�
          i_head_ship_date_tab(ln_insert_cnt)      := gt_carriers_schedule_tab(ln_index).ship_date ;
          -- ������
          i_head_arrival_date_tab(ln_insert_cnt)   := gt_carriers_schedule_tab(ln_index).arrival_date ;
          -- �񍐓�
          i_head_report_date_tab(ln_insert_cnt)    := NULL ;
          -- ���f��
          i_head_judg_date_tab(ln_insert_cnt)      := gt_carriers_schedule_tab(ln_index).judgement_date ;
          -- ���i�敪
          i_head_goods_cls_tab(ln_insert_cnt)      := gt_carriers_schedule_tab(ln_index).prod_class ;
          -- ���ڋ敪
          i_head_mixed_cd_tab(ln_insert_cnt)       := gt_carriers_schedule_tab(ln_index).mixed_code  ;
          -- �����^��
          i_head_charg_amount_tab(ln_insert_cnt)   := NULL ;
          -- �_��^��
          i_head_contract_rate_tab(ln_insert_cnt)  := lr_delivery_charges_tab.shipping_expenses ;
--
          -- �s�b�L���O���i�x���s�b�L���O�P���~�������j
          i_head_pick_charge_tab(ln_insert_cnt)    := lr_delivery_company_tab.pay_picking_amount *  
                                                      gt_carriers_schedule_tab(ln_index).small_quantity ;
--
          -- ���v�i�_��^���{�s�b�L���O���j
          i_head_total_amount_tab(ln_insert_cnt)   := lr_delivery_charges_tab.shipping_expenses +
                                                      i_head_pick_charge_tab(ln_insert_cnt);
--
          -- ���z�i���v �~ -1�j
          i_head_balance_tab(ln_insert_cnt)        := i_head_total_amount_tab(ln_insert_cnt) * -1 ;
--
          i_head_many_rate_tab(ln_insert_cnt)      := NULL ;  -- ������
          -- �Œ�����
          i_head_distance_tab(ln_insert_cnt)       := lr_delivery_distance_tab.small_distance ;
          -- �z���敪
          i_head_deliv_cls_tab(ln_insert_cnt)      := gt_carriers_schedule_tab(ln_index).dellivary_classe ;
          -- ��\�o�ɑq�ɃR�[�h
          i_head_whs_cd_tab(ln_insert_cnt)         := gt_carriers_schedule_tab(ln_index).whs_code;
          -- ��\�z����R�[�h�敪
          i_head_cd_dvsn_tab(ln_insert_cnt)        := lv_code_division;
          -- ��\�z����R�[�h
          i_head_ship_addr_cd_tab(ln_insert_cnt)   := gt_carriers_schedule_tab(ln_index).shipping_address_code;
          -- ���P
          i_head_qty1_tab(ln_insert_cnt)           := gt_carriers_schedule_tab(ln_index).small_quantity ;
          i_head_qty2_tab(ln_insert_cnt)           := NULL ;        -- ���Q
          -- �d�ʂP
          i_head_deliv_wght1_tab(ln_insert_cnt)    := ln_weight ;
          i_head_deliv_wght2_tab(ln_insert_cnt)    := NULL ;        -- �d�ʂQ
          i_head_cnsld_srhrg_tab(ln_insert_cnt)    := 0 ;           -- ���ڊ������z
          -- �Œ����ۋ���
          i_head_actual_ditnc_tab(ln_insert_cnt)   := lr_delivery_distance_tab.actual_distance ;
          i_head_cong_chrg_tab(ln_insert_cnt)      := NULL ;        -- �ʍs��
          i_head_consolid_qty_tab(ln_insert_cnt)   := 0 ;           -- ���ڐ�
          -- ��\�^�C�v
          i_head_order_type_tab(ln_insert_cnt)     := gt_carriers_schedule_tab(ln_index).transaction_type ;
          -- �d�ʗe�ϋ敪
          i_head_wigh_cpcty_cls_tab(ln_insert_cnt) := gt_carriers_schedule_tab(ln_index).weight_capacity_class ;
          i_head_out_cont_tab(ln_insert_cnt)       := NULL ;        -- �_��O�敪
          i_head_output_flag_tab(ln_insert_cnt)    := gv_ktg_yes ;  -- ���ً敪
          i_head_defined_flag_tab(ln_insert_cnt)   := gv_ktg_no  ;  -- �x���m��敪
          i_head_return_flag_tab(ln_insert_cnt)    := gv_ktg_no  ;  -- �x���m���
          i_head_fm_upd_flg_tab(ln_insert_cnt)     := gv_ktg_no  ;  -- ��ʍX�V�L���敪
          i_head_trans_lcton_tab(ln_insert_cnt)    := NULL ;        -- �U�֐�
          i_head_out_up_cnt_tab(ln_insert_cnt)     := 0 ;           -- �O���ƎҕύX��
          i_head_description_tab(ln_insert_cnt)    := NULL ;        -- �^���E�v
          -- �z�ԃ^�C�v�i�`�[�Ȃ��z�ԁi���[�t�����j�j
          i_head_dispatch_type_tab(ln_insert_cnt)  := gv_carcan_target_y;
--
        -- �^���w�b�_�A�h�I���Ƀf�[�^�����݂���ꍇ
        ELSE
          -- **************************************************
          -- ***  �`�[�Ȃ��z�ԁi���[�t�����j�X�V
          -- **************************************************
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�^���w�b�_�A�h�I�� UPDATE');
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- �X�V�pPL/SQL�\ ����
          ln_update_cnt   := ln_update_cnt + 1;
--
          -- �^���Ǝ�
          u_head_deliv_cmpny_cd_tab(ln_update_cnt) := gt_carriers_schedule_tab(ln_index).delivery_company_code ;
          -- �z��No
          u_head_deliv_no_tab(ln_update_cnt)       := gt_carriers_schedule_tab(ln_index).delivery_no ;
          -- �����No
          u_head_invoice_no_tab(ln_update_cnt)     := gt_carriers_schedule_tab(ln_index).slip_number ;
          -- �x�����f�敪
          u_head_pay_judg_cls_tab(ln_update_cnt)   := gt_carriers_schedule_tab(ln_index).payments_judgment_classe ;
          -- �o�ɓ�
          u_head_ship_date_tab(ln_update_cnt)      := gt_carriers_schedule_tab(ln_index).ship_date ;
          -- ������
          u_head_arrival_date_tab(ln_update_cnt)   := gt_carriers_schedule_tab(ln_index).arrival_date ;
          -- ���f��
          u_head_judg_date_tab(ln_update_cnt)      := gt_carriers_schedule_tab(ln_index).judgement_date ;
          -- ���i�敪
          u_head_goods_cls_tab(ln_update_cnt)      := gt_carriers_schedule_tab(ln_index).prod_class ;
          -- ���ڋ敪
          u_head_mixed_cd_tab(ln_update_cnt)       := gt_carriers_schedule_tab(ln_index).mixed_code ;
          -- �_��^��
          u_head_contract_rate_tab(ln_update_cnt)  := lr_delivery_charges_tab.shipping_expenses ;
--
          -- �s�b�L���O���i�x���s�b�L���O�P���~�������j
          u_head_pick_charge_tab(ln_update_cnt)    := lr_delivery_company_tab.pay_picking_amount *  
                                                      gt_carriers_schedule_tab(ln_index).small_quantity ;
--
          -- ���v�i�_��^�� �{ �s�b�L���O�� �{ ���ڊ������z �{ ������ �j
          u_head_total_amount_tab(ln_update_cnt)   := u_head_contract_rate_tab(ln_update_cnt) +
                                                      u_head_pick_charge_tab(ln_update_cnt)   +
                                                      NVL(lv_consolid_surcharge,0)            +
                                                      NVL(lv_many_rate,0) ;
          -- ���z�i�������z �| ���v�j
          u_head_balance_tab(ln_update_cnt)        := NVL(lv_charged_amount,0) -
                                                      u_head_total_amount_tab(ln_update_cnt);
          -- �Œ�����
          u_head_distance_tab(ln_update_cnt)       := lr_delivery_distance_tab.small_distance ;
          -- �z���敪
          u_head_deliv_cls_tab(ln_update_cnt)      := gt_carriers_schedule_tab(ln_index).dellivary_classe ;
          -- ��\�o�ɑq�ɃR�[�h
          u_head_whs_cd_tab(ln_update_cnt)         := gt_carriers_schedule_tab(ln_index).whs_code;
          -- ��\�z����R�[�h�敪
          u_head_cd_dvsn_tab(ln_update_cnt)        := lv_code_division;
          -- ��\�z����R�[�h
          u_head_ship_addr_cd_tab(ln_update_cnt)   := gt_carriers_schedule_tab(ln_index).shipping_address_code;
          -- ���P
          u_head_qty1_tab(ln_update_cnt)           := gt_carriers_schedule_tab(ln_index).small_quantity ;
          -- �d�ʂP
          u_head_deliv_wght1_tab(ln_update_cnt)    := ln_weight ;
          -- ���ڊ������z
          u_head_cnsld_srhrg_tab(ln_update_cnt)    := lv_consolid_surcharge ;
          -- �Œ����ۋ���
          u_head_actual_ditnc_tab(ln_update_cnt)   := lr_delivery_distance_tab.actual_distance  ;
          u_head_consolid_qty_tab(ln_update_cnt)   := 0 ;    -- ���ڐ�
          -- ��\�^�C�v
          u_head_order_type_tab(ln_update_cnt)     := gt_carriers_schedule_tab(ln_index).transaction_type ;
          -- �d�ʗe�ϋ敪
          u_head_wigh_cpcty_cls_tab(ln_update_cnt) := gt_carriers_schedule_tab(ln_index).weight_capacity_class ;
          u_head_out_cont_tab(ln_update_cnt)       := NULL ; -- �_��O�敪
          u_head_trans_lcton_tab(ln_update_cnt)    := NULL ; -- �U�֐�
          -- ���ً敪
          IF (u_head_balance_tab(ln_update_cnt) <> 0 ) THEN
            u_head_output_flag_tab(ln_update_cnt)  := gv_ktg_yes;
          ELSE
            u_head_output_flag_tab(ln_update_cnt)  := gv_ktg_no;
          END IF;
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
/*****
          IF (u_head_balance_tab(ln_update_cnt) <> 0 ) THEN
            u_head_defined_flag_tab(ln_update_cnt)   := gv_ktg_no;
          ELSE
            u_head_defined_flag_tab(ln_update_cnt)   := gv_ktg_yes;
          END IF;
*****/
          -- �x���m��敪
          -- �������z IS NULL �̏ꍇ
          IF (lv_charged_amount IS NULL ) THEN
            u_head_defined_flag_tab(ln_update_cnt)   := gv_ktg_no;
--
          -- ���ً敪 = Y �̏ꍇ
          ELSIF (u_head_output_flag_tab(ln_update_cnt) = gv_ktg_yes) THEN
            u_head_defined_flag_tab(ln_update_cnt)   := gv_ktg_no;
--
          -- ��L�ȊO�̏ꍇ
          ELSE
            u_head_defined_flag_tab(ln_update_cnt)   := gv_ktg_yes;
          END IF;
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
--
-- ##### 20080805 Ver.1.5 ST���O�m�F��Q START #####
--          u_head_return_flag_tab(ln_update_cnt)    := lv_return_flag ;  -- �x���m���
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
--          IF ((lv_defined_flag = gv_ktg_yes) AND (u_head_balance_tab(ln_update_cnt) <> 0)) THEN
          -- ���̎x���m��敪��Y �̏ꍇ
          IF (lv_defined_flag = gv_ktg_yes) THEN
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
            u_head_return_flag_tab(ln_update_cnt)    := gv_ktg_yes ;  -- �x���m���
--
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
/*****
          -- ���̎x���m��敪��Y ���A���z = 0 �̏ꍇ
          ELSIF ((lv_defined_flag = gv_ktg_yes) AND (u_head_balance_tab(ln_update_cnt) = 0)) THEN
            u_head_return_flag_tab(ln_update_cnt)    := gv_ktg_no ;  -- �x���m���
          -- ��L�ȊO�̏ꍇ
          ELSE
            u_head_return_flag_tab(ln_update_cnt)    := lv_return_flag ;  -- �x���m���
*****/
--
          -- ��L�ȊO�̏ꍇ
          ELSE
            u_head_return_flag_tab(ln_update_cnt)    := gv_ktg_no ;  -- �x���m���
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
          END IF;
-- ##### 20080805 Ver.1.5 ST���O�m�F��Q END   #####
--
          -- **************************************************
          -- ** ���z��0�ȊO�̔z��No�̐������͑S�č폜�Ώ�
          -- **************************************************
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
/***** �����폜
          IF (u_head_balance_tab(ln_update_cnt) <> 0 ) THEN
*****/
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
--
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
          -- �����f�[�^�폜�����̒ǉ�
          IF   (lt_delivery_company_code    <> u_head_deliv_cmpny_cd_tab(ln_update_cnt) ) -- �^���Ǝ�
            OR (lt_delivery_no              <> u_head_deliv_no_tab(ln_update_cnt)       ) -- �z��No
            OR (lt_payments_judgment_classe <> u_head_pay_judg_cls_tab(ln_update_cnt)   ) -- �x�����f�敪
            OR (lt_ship_date                <> u_head_ship_date_tab(ln_update_cnt)      ) -- �o�ɓ�
            OR (lt_arrival_date             <> u_head_arrival_date_tab(ln_update_cnt)   ) -- ������
            OR (lt_judgement_date           <> u_head_judg_date_tab(ln_update_cnt)      ) -- ���f��
            OR (lt_goods_classe             <> u_head_goods_cls_tab(ln_update_cnt)      ) -- ���i�敪
            OR (lt_mixed_code               <> u_head_mixed_cd_tab(ln_update_cnt)       ) -- ���ڋ敪
            OR (lt_contract_rate            <> u_head_contract_rate_tab(ln_update_cnt)  ) -- �_��^��
            OR (lt_balance                  <> u_head_balance_tab(ln_update_cnt)        ) -- ���z
            OR (lt_total_amount             <> u_head_total_amount_tab(ln_update_cnt)   ) -- ���v
            OR (lt_distance                 <> u_head_distance_tab(ln_update_cnt)       ) -- �Œ�����
            OR (lt_delivery_classe          <> u_head_deliv_cls_tab(ln_update_cnt)      ) -- �z���敪
            OR (lt_whs_code                 <> u_head_whs_cd_tab(ln_update_cnt)         ) -- ��\�o�ɑq�ɃR�[�h
            OR (lt_code_division            <> u_head_cd_dvsn_tab(ln_update_cnt)        ) -- ��\�z����R�[�h�敪
            OR (lt_shipping_address_code    <> u_head_ship_addr_cd_tab(ln_update_cnt)   ) -- ��\�z����R�[�h
            OR (lt_qty1                     <> u_head_qty1_tab(ln_update_cnt)           ) -- ���P
            OR (lt_delivery_weight1         <> u_head_deliv_wght1_tab(ln_update_cnt)    ) -- �d�ʂP
            OR (lt_consolid_surcharge       <> u_head_cnsld_srhrg_tab(ln_update_cnt)    ) -- ���ڊ������z
            OR (lt_actual_distance          <> u_head_actual_ditnc_tab(ln_update_cnt)   ) -- �Œ����ۋ���
            OR (lt_picking_charge           <> u_head_pick_charge_tab(ln_update_cnt)    ) -- �s�b�L���O��
            OR (lt_consolid_qty             <> u_head_consolid_qty_tab(ln_update_cnt)   ) -- ���ڐ�
            OR (lt_order_type               <> u_head_order_type_tab(ln_update_cnt)     ) -- ��\�^�C�v
            OR (lt_weight_capacity_class    <> u_head_wigh_cpcty_cls_tab(ln_update_cnt) ) -- �d�ʗe�ϋ敪
          THEN
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
            IF (gv_debug_flg = gv_debug_on) THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�^���w�b�_�A�h�I�� DELETE');
            END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
            -- �폜�pPL/SQL�\ �����C���N�������g
            ln_delete_cnt   := ln_delete_cnt + 1;
            -- �z��No
            d_head_deliv_no_tab(ln_delete_cnt)  := gt_carriers_schedule_tab(ln_index).delivery_no ;
--
-- ##### 20081226 Ver.1.18 �{��#323�Ή��i���O�Ή��j START #####
          -- ���ѕύX�ɂ��폜 ���O�o�͗p�̈�i�[
          gn_delete_data_idx := gn_delete_data_idx + 1;
-- ##### 20081229 Ver.1.19 �{��#882�Ή� START #####
--          gt_delete_data_msg(gn_delete_data_idx) :=  d_head_deliv_no_tab(ln_delete_cnt);
          gt_delete_data_msg(gn_delete_data_idx) :=  u_head_deliv_no_tab(ln_update_cnt)     || '  ' ;  -- �z��No
          gt_delete_data_msg(gn_delete_data_idx) :=  gt_delete_data_msg(gn_delete_data_idx) || u_head_deliv_cmpny_cd_tab(ln_update_cnt) || '  ' ; -- �^���Ǝ�
          gt_delete_data_msg(gn_delete_data_idx) :=  gt_delete_data_msg(gn_delete_data_idx) || TO_CHAR(u_head_ship_date_tab(ln_update_cnt),'YYYY/MM/DD'); -- �o�ד�
-- ##### 20081229 Ver.1.19 �{��#882�Ή� END   #####
-- ##### 20081226 Ver.1.18 �{��#323�Ή��i���O�Ή��j END   #####
--
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
          END IF;
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
--
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
/*****
          END IF;
*****/
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
--
        END IF;
--
      -- *******************************************************************************************
      -- ��L�ȊO�i�`�[�Ȃ��z�ԁi���[�t�����ȊO�j
      -- *******************************************************************************************
      ELSE
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F$$$$$ �`�[�Ȃ��z�ԁi���[�t�����ȊO�j�I $$$$$');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�z��No�F' || gt_carriers_schedule_tab(ln_index).delivery_no);
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
--
        -- **************************************************
        -- ***  �z�������A�h�I���}�X�^���o
        -- **************************************************
        -- ��\�z����R�[�h�敪�ϊ�
        xxwip_common3_pkg.change_code_division(
          gt_carriers_schedule_tab(ln_index).code_division, -- ��\�z����R�[�h�敪
          lv_code_division,                                 -- �R�[�h�敪�i�^���p�j
          lv_errbuf,
          lv_retcode,
          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- �z�������A�h�I���}�X�^���o
        xxwip_common3_pkg.get_delivery_distance(
          gt_carriers_schedule_tab(ln_index).prod_class,            -- ���i�敪
          gt_carriers_schedule_tab(ln_index).delivery_company_code, -- �^���Ǝ�
          gt_carriers_schedule_tab(ln_index).whs_code,              -- �o�ɑq��
          lv_code_division ,                                        -- �R�[�h�敪
          gt_carriers_schedule_tab(ln_index).shipping_address_code, -- �z����R�[�h
          gt_carriers_schedule_tab(ln_index).judgement_date,        -- ���f��
          lr_delivery_distance_tab,                                 -- �z�������A�h�I���}�X�^���R�[�h
          lv_errbuf,
          lv_retcode,
          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F$ �z�������A�h�I���}�X�^���o $');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�ԗ�����    �F'|| TO_CHAR(lr_delivery_distance_tab.post_distance));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F��������    �F'|| TO_CHAR(lr_delivery_distance_tab.small_distance));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F���ڊ��������F'|| TO_CHAR(lr_delivery_distance_tab.consolid_add_distance));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F���ۋ���    �F'|| TO_CHAR(lr_delivery_distance_tab.actual_distance));
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- **************************************************
        -- ***  �^���A�h�I���}�X�^���o
        -- **************************************************
        -- �d�ʎZ�o�i0�ɂĒ��o�j
        ln_weight := 0;
-- ##### 20090209 Ver.1.22 �{��#1107�Ή� START #####
        -- �����ݒ�
        -- �����敪���u�����v�̏ꍇ
        IF (gt_carriers_schedule_tab(ln_index).small_amount_class   = gv_small_sum_yes) THEN
          ln_distance := lr_delivery_distance_tab.small_distance;
        -- �����敪���u�ԗ��v�̏ꍇ
        ELSE
          ln_distance := lr_delivery_distance_tab.post_distance;
        END IF;
-- ##### 20090209 Ver.1.22 �{��#1107�Ή� END   #####
--
        xxwip_common3_pkg.get_delivery_charges(
          gv_pay,                                                   -- �x�������敪
          gt_carriers_schedule_tab(ln_index).prod_class,            -- ���i�敪
          gt_carriers_schedule_tab(ln_index).delivery_company_code, -- �^���Ǝ�
          gt_carriers_schedule_tab(ln_index).dellivary_classe,      -- �z���敪
-- ##### 20090209 Ver.1.22 �{��#1107�Ή� START #####
--          lr_delivery_distance_tab.post_distance,                   -- �^�������i�ԗ������j
          ln_distance,                                              -- �^�������i�ԗ������j
-- ##### 20090209 Ver.1.22 �{��#1107�Ή� END   #####
          ln_weight,                                                -- �d�ʁi0�ɂāj
          gt_carriers_schedule_tab(ln_index).judgement_date,        -- ���f��
          lr_delivery_charges_tab,                                  -- �^���A�h�I�����R�[�h
          lv_errbuf,
          lv_retcode,
          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F$ �^���A�h�I���}�X�^���o $');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�^����        �F'|| TO_CHAR(lr_delivery_charges_tab.shipping_expenses));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F���[�t���ڊ����F'|| TO_CHAR(lr_delivery_charges_tab.leaf_consolid_add));
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
--
        -- **************************************************
        -- ***  �^���w�b�_�A�h�I�����o
        -- **************************************************
        -- ���݃t���O������
        ln_deliv_flg := gv_ktg_yes;
--
        BEGIN
          SELECT  xd.delivery_no        -- �z��No
                , xd.many_rate          -- ������
                , xd.charged_amount     -- �������z
                , xd.defined_flag       -- �x���m��敪
                , xd.return_flag        -- �x���m���
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
                , xd.delivery_company_code      -- �^���Ǝ�
                , xd.delivery_no                -- �z��No
                , xd.payments_judgment_classe   -- �x�����f�敪
                , xd.ship_date                  -- �o�ɓ�
                , xd.arrival_date               -- ������
                , xd.judgement_date             -- ���f��
                , xd.goods_classe               -- ���i�敪
                , xd.mixed_code                 -- ���ڋ敪
                , xd.contract_rate              -- �_��^��
                , xd.balance                    -- ���z
                , xd.total_amount               -- ���v
                , xd.distance                   -- �Œ�����
                , xd.delivery_classe            -- �z���敪
                , xd.whs_code                   -- ��\�o�ɑq�ɃR�[�h
                , xd.code_division              -- ��\�z����R�[�h�敪
                , xd.shipping_address_code      -- ��\�z����R�[�h
                , xd.qty1                       -- ���P
                , xd.delivery_weight1           -- �d�ʂP
                , xd.consolid_surcharge         -- ���ڊ������z
                , xd.actual_distance            -- �Œ����ۋ���
                , xd.picking_charge             -- �s�b�L���O��
                , xd.consolid_qty               -- ���ڐ�
                , xd.order_type                 -- ��\�^�C�v
                , xd.weight_capacity_class      -- �d�ʗe�ϋ敪
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
          INTO    lv_delivery_no
                , lv_many_rate
                , lv_charged_amount
                , lv_defined_flag
                , lv_return_flag
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
                , lt_delivery_company_code      -- �^���Ǝ�
                , lt_delivery_no                -- �z��No
                , lt_payments_judgment_classe   -- �x�����f�敪
                , lt_ship_date                  -- �o�ɓ�
                , lt_arrival_date               -- ������
                , lt_judgement_date             -- ���f��
                , lt_goods_classe               -- ���i�敪
                , lt_mixed_code                 -- ���ڋ敪
                , lt_contract_rate              -- �_��^��
                , lt_balance                    -- ���z
                , lt_total_amount               -- ���v
                , lt_distance                   -- �Œ�����
                , lt_delivery_classe            -- �z���敪
                , lt_whs_code                   -- ��\�o�ɑq�ɃR�[�h
                , lt_code_division              -- ��\�z����R�[�h�敪
                , lt_shipping_address_code      -- ��\�z����R�[�h
                , lt_qty1                       -- ���P
                , lt_delivery_weight1           -- �d�ʂP
                , lt_consolid_surcharge         -- ���ڊ������z
                , lt_actual_distance            -- �Œ����ۋ���
                , lt_picking_charge             -- �s�b�L���O��
                , lt_consolid_qty               -- ���ڐ�
                , lt_order_type                 -- ��\�^�C�v
                , lt_weight_capacity_class      -- �d�ʗe�ϋ敪
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
          FROM   xxwip_deliverys      xd      -- �^���w�b�_�A�h�I��
          WHERE  xd.delivery_no = gt_carriers_schedule_tab(ln_index).delivery_no -- �z��No
          AND    xd.p_b_classe = gv_pay ;                           -- �x�������敪�i�x���j
        EXCEPTION
          WHEN NO_DATA_FOUND THEN   -- *** �f�[�^�擾�G���[ ***
            -- ���݃t���O Y ��ݒ�
            ln_deliv_flg := gv_ktg_no;
--
          WHEN TOO_MANY_ROWS THEN   -- *** �f�[�^�����擾�G���[ ***
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                  gv_xxcmn_msg_toomny,
                                                  gv_tkn_table,
                                                  gv_deliverys,
                                                  gv_tkn_key,
                                                  gv_pay || ',' ||
                                                  gt_carriers_schedule_tab(ln_index).delivery_no);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
        IF (gv_debug_flg = gv_debug_on) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F$ �^���w�b�_�A�h�I�� $�F' || ln_deliv_flg);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�z��No      �F'|| lv_delivery_no);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F������      �F'|| TO_CHAR(lv_many_rate));
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�x���m��敪�F'|| lv_defined_flag);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�x���m���  �F'|| lv_return_flag);
        END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- �^���w�b�_�A�h�I���Ƀf�[�^�����݂��Ȃ��ꍇ
        IF (ln_deliv_flg = gv_ktg_no) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�^���w�b�_�A�h�I�� INSERT');
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- **************************************************
          -- ***  �`�[�Ȃ��z�ԁi���[�t�����ȊO�j�o�^
          -- **************************************************
          -- �o�^�pPL/SQL�\ ����
          ln_insert_cnt  := ln_insert_cnt + 1;
--
          -- �^���Ǝ�
          i_head_deliv_cmpny_cd_tab(ln_insert_cnt) := 
                            gt_carriers_schedule_tab(ln_index).delivery_company_code ;
          -- �z��No
          i_head_deliv_no_tab(ln_insert_cnt)       := 
                            gt_carriers_schedule_tab(ln_index).delivery_no ;
          -- �����No
          i_head_invoice_no_tab(ln_insert_cnt)     := 
                            gt_carriers_schedule_tab(ln_index).slip_number ;
          -- �x�������敪
          i_head_p_b_classe_tab(ln_insert_cnt)     := gv_pay ;
          -- �x�����f�敪
          i_head_pay_judg_cls_tab(ln_insert_cnt)   := 
                            gt_carriers_schedule_tab(ln_index).payments_judgment_classe ;
          -- �o�ɓ�
          i_head_ship_date_tab(ln_insert_cnt)      := gt_carriers_schedule_tab(ln_index).ship_date ;
          -- ������
          i_head_arrival_date_tab(ln_insert_cnt)   := 
                            gt_carriers_schedule_tab(ln_index).arrival_date ;
          -- �񍐓�
          i_head_report_date_tab(ln_insert_cnt)    := NULL ;
          -- ���f��
          i_head_judg_date_tab(ln_insert_cnt)      := 
                            gt_carriers_schedule_tab(ln_index).judgement_date ;
          -- ���i�敪
          i_head_goods_cls_tab(ln_insert_cnt)      := 
                            gt_carriers_schedule_tab(ln_index).prod_class ;
          -- ���ڋ敪
          i_head_mixed_cd_tab(ln_insert_cnt)       := 
                            gt_carriers_schedule_tab(ln_index).mixed_code  ;
          i_head_charg_amount_tab(ln_insert_cnt)   := NULL ;  -- �����^��
--
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
/*****
          i_head_contract_rate_tab(ln_insert_cnt)  := 0 ;     -- �_��^��
          i_head_balance_tab(ln_insert_cnt)        := 0 ;     -- ���z
          i_head_total_amount_tab(ln_insert_cnt)   := 0 ;     -- ���v
*****/
          -- �_��^���i�d��=0�ɂĉ^����o�j
          i_head_contract_rate_tab(ln_insert_cnt)  := lr_delivery_charges_tab.shipping_expenses;
--
          -- ���z�i���v �~ -1�j
          i_head_balance_tab(ln_insert_cnt)        := i_head_contract_rate_tab(ln_insert_cnt) * -1 ;
          -- ���v�i�^����j
          i_head_total_amount_tab(ln_insert_cnt)   := i_head_contract_rate_tab(ln_insert_cnt) ;
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
--
          i_head_many_rate_tab(ln_insert_cnt)      := NULL ;  -- ������
--
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
--          i_head_distance_tab(ln_insert_cnt)       := 0 ;     -- �Œ�����
-- ##### 20090209 Ver.1.22 �{��#1107�Ή� START #####
          -- �Œ������i�ԗ����� or ���������j
--          i_head_distance_tab(ln_insert_cnt)       := lr_delivery_distance_tab.post_distance ;
          i_head_distance_tab(ln_insert_cnt) := ln_distance;
-- ##### 20090209 Ver.1.22 �{��#1107�Ή� END   #####

-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
--
          -- �z���敪
          i_head_deliv_cls_tab(ln_insert_cnt)      := 
                            gt_carriers_schedule_tab(ln_index).dellivary_classe ;
          -- ��\�o�ɑq�ɃR�[�h
          i_head_whs_cd_tab(ln_insert_cnt)         := 
                            gt_carriers_schedule_tab(ln_index).whs_code;
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
/*****
          xxwip_common3_pkg.change_code_division(
            gt_carriers_schedule_tab(ln_index).code_division,
            i_head_cd_dvsn_tab(ln_insert_cnt),
            lv_errbuf,
            lv_retcode,
            lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
*****/
          -- ��\�z����R�[�h�敪
          i_head_cd_dvsn_tab(ln_insert_cnt) := lv_code_division;
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
--
          -- ��\�z����R�[�h
          i_head_ship_addr_cd_tab(ln_insert_cnt) := 
                            gt_carriers_schedule_tab(ln_index).shipping_address_code;
--
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
--          i_head_qty1_tab(ln_insert_cnt)           := 0 ;           -- ���P
          -- ���P�i��������ݒ�j
          i_head_qty1_tab(ln_insert_cnt)           := gt_carriers_schedule_tab(ln_index).small_quantity ;
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
--
          i_head_qty2_tab(ln_insert_cnt)           := NULL ;        -- ���Q
--
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
--          i_head_deliv_wght1_tab(ln_insert_cnt)    := 0 ;           -- �d�ʂP
          i_head_deliv_wght1_tab(ln_insert_cnt)    := ln_weight ;           -- �d�ʂP
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
--
          i_head_deliv_wght2_tab(ln_insert_cnt)    := NULL ;        -- �d�ʂQ
          i_head_cnsld_srhrg_tab(ln_insert_cnt)    := 0 ;           -- ���ڊ������z
--
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
--          i_head_actual_ditnc_tab(ln_insert_cnt)   := 0 ;           -- �Œ����ۋ���
          -- �Œ����ۋ���
          i_head_actual_ditnc_tab(ln_insert_cnt)   := lr_delivery_distance_tab.actual_distance ;
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
--
          i_head_cong_chrg_tab(ln_insert_cnt)      := NULL ;        -- �ʍs��
          i_head_pick_charge_tab(ln_insert_cnt)    := 0 ;           -- �s�b�L���O��
          i_head_consolid_qty_tab(ln_insert_cnt)   := 0 ;           -- ���ڐ�
          -- ��\�^�C�v
          i_head_order_type_tab(ln_insert_cnt)     := gt_carriers_schedule_tab(ln_index).transaction_type ;
          -- �d�ʗe�ϋ敪
          i_head_wigh_cpcty_cls_tab(ln_insert_cnt) := 
                            gt_carriers_schedule_tab(ln_index).weight_capacity_class ;
          i_head_out_cont_tab(ln_insert_cnt)       := NULL ;        -- �_��O�敪
          i_head_output_flag_tab(ln_insert_cnt)    := gv_ktg_yes ;  -- ���ً敪
          i_head_defined_flag_tab(ln_insert_cnt)   := gv_ktg_no  ;  -- �x���m��敪
          i_head_return_flag_tab(ln_insert_cnt)    := gv_ktg_no  ;  -- �x���m���
          i_head_fm_upd_flg_tab(ln_insert_cnt)     := gv_ktg_no  ;  -- ��ʍX�V�L���敪
          i_head_trans_lcton_tab(ln_insert_cnt)    := NULL ;        -- �U�֐�
          i_head_out_up_cnt_tab(ln_insert_cnt)     := 0 ;           -- �O���ƎҕύX��
          i_head_description_tab(ln_insert_cnt)    := NULL ;        -- �^���E�v
          -- �z�ԃ^�C�v�i�`�[�Ȃ��z�ԁi���[�t�����ȊO�j�j
          i_head_dispatch_type_tab(ln_insert_cnt) := gv_carcan_target_n;
--
        -- �^���w�b�_�A�h�I���Ƀf�[�^�����݂���ꍇ
        ELSE
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�^���w�b�_�A�h�I�� UPDATE��DELETE');
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- **************************************************
          -- ***  �`�[�Ȃ��z�ԁi���[�t�����ȊO�j�X�V
          -- **************************************************
          -- �X�V�pPL/SQL�\ ����
          ln_update_cnt   := ln_update_cnt + 1;
--
          -- �^���Ǝ�
          u_head_deliv_cmpny_cd_tab(ln_update_cnt) := 
                                gt_carriers_schedule_tab(ln_index).delivery_company_code ;
          -- �z��No
          u_head_deliv_no_tab(ln_update_cnt)       := 
                                gt_carriers_schedule_tab(ln_index).delivery_no ;
          -- �����No
          u_head_invoice_no_tab(ln_update_cnt)     := 
                                gt_carriers_schedule_tab(ln_index).slip_number ;
          -- �x�����f�敪
          u_head_pay_judg_cls_tab(ln_update_cnt)   := 
                                gt_carriers_schedule_tab(ln_index).payments_judgment_classe ;
          -- �o�ɓ�
          u_head_ship_date_tab(ln_update_cnt)      := 
                                gt_carriers_schedule_tab(ln_index).ship_date ;
          -- ������
          u_head_arrival_date_tab(ln_update_cnt)   := 
                                gt_carriers_schedule_tab(ln_index).arrival_date ;
          -- ���f��
          u_head_judg_date_tab(ln_update_cnt)      := 
                                gt_carriers_schedule_tab(ln_index).judgement_date ;
          -- ���i�敪
          u_head_goods_cls_tab(ln_update_cnt)      := 
                                gt_carriers_schedule_tab(ln_index).prod_class ;
          -- ���ڋ敪
          u_head_mixed_cd_tab(ln_update_cnt)       := 
                                gt_carriers_schedule_tab(ln_index).mixed_code ;
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
/*****
          u_head_contract_rate_tab(ln_update_cnt)  := 0 ;    -- �_��^��
          -- ���z�i�������z �| �������j
          u_head_balance_tab(ln_update_cnt)        := NVL(lv_charged_amount, 0) - NVL(lv_many_rate, 0) ;
          u_head_total_amount_tab(ln_update_cnt)   := NVL(lv_many_rate, 0) ;    -- ���v
*****/
          -- �_��^���i�d��=0�ɂĉ^����o�j
          u_head_contract_rate_tab(ln_update_cnt)  := lr_delivery_charges_tab.shipping_expenses ;
--
          -- ���v�i�^���� + �������j
          u_head_total_amount_tab(ln_update_cnt)   := lr_delivery_charges_tab.shipping_expenses +
                                                      NVL(lv_many_rate, 0) ;
--
          -- ���z�i�������z �| ���v�j
          u_head_balance_tab(ln_update_cnt)        := NVL(lv_charged_amount, 0) - 
                                                      u_head_total_amount_tab(ln_update_cnt) ;
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
--
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
--          u_head_distance_tab(ln_update_cnt)       := 0 ;    -- �Œ�����
-- ##### 20090209 Ver.1.22 �{��#1107�Ή� START #####
          -- �Œ������i�ԗ����� or ���������j
--          u_head_distance_tab(ln_update_cnt)       := lr_delivery_distance_tab.post_distance  ;
          u_head_distance_tab(ln_update_cnt) := ln_distance;
-- ##### 20090209 Ver.1.22 �{��#1107�Ή� END   #####
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
          -- �z���敪
          u_head_deliv_cls_tab(ln_update_cnt)      := 
                            gt_carriers_schedule_tab(ln_index).dellivary_classe ;
          -- ��\�o�ɑq�ɃR�[�h
          u_head_whs_cd_tab(ln_update_cnt)         := gt_carriers_schedule_tab(ln_index).whs_code;
--
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
/*****
          xxwip_common3_pkg.change_code_division(
            gt_carriers_schedule_tab(ln_index).code_division,
            u_head_cd_dvsn_tab(ln_update_cnt),
            lv_errbuf,
            lv_retcode,
            lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
*****/
          -- ��\�z����R�[�h�敪
          u_head_cd_dvsn_tab(ln_update_cnt) := lv_code_division;
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
--
          -- ��\�z����R�[�h
          u_head_ship_addr_cd_tab(ln_update_cnt) :=
                            gt_carriers_schedule_tab(ln_index).shipping_address_code;
--
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
--          u_head_qty1_tab(ln_update_cnt)           := 0 ;    -- ���P
--          u_head_deliv_wght1_tab(ln_update_cnt)    := 0 ;    -- �d�ʂP
          -- ���P
          u_head_qty1_tab(ln_update_cnt)           := gt_carriers_schedule_tab(ln_index).small_quantity ;
          -- �d�ʂP
          u_head_deliv_wght1_tab(ln_update_cnt)    := ln_weight ;
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
--
          u_head_cnsld_srhrg_tab(ln_update_cnt)    := 0 ;    -- ���ڊ������z
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
--          u_head_actual_ditnc_tab(ln_update_cnt)   := 0 ;    -- �Œ����ۋ���
          -- �Œ����ۋ���
          u_head_actual_ditnc_tab(ln_update_cnt)   := lr_delivery_distance_tab.actual_distance ;
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
          u_head_pick_charge_tab(ln_update_cnt)    := 0 ;    -- �s�b�L���O��
          u_head_consolid_qty_tab(ln_update_cnt)   := 0 ;    -- ���ڐ�
          -- ��\�^�C�v
          u_head_order_type_tab(ln_update_cnt)     := gt_carriers_schedule_tab(ln_index).transaction_type ;
          -- �d�ʗe�ϋ敪
          u_head_wigh_cpcty_cls_tab(ln_update_cnt) := 
                            gt_carriers_schedule_tab(ln_index).weight_capacity_class ;
          u_head_out_cont_tab(ln_update_cnt)       := NULL ; -- �_��O�敪
          u_head_trans_lcton_tab(ln_update_cnt)    := NULL ; -- �U�֐�
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
/*****
          u_head_output_flag_tab(ln_update_cnt)    := gv_ktg_yes;       -- ���ً敪
          u_head_defined_flag_tab(ln_update_cnt)   := gv_ktg_no;        -- �x���m��敪
*****/
          -- ���ً敪
          IF (u_head_balance_tab(ln_update_cnt) <> 0 ) THEN
            u_head_output_flag_tab(ln_update_cnt)  := gv_ktg_yes;
          ELSE
            u_head_output_flag_tab(ln_update_cnt)  := gv_ktg_no;
          END IF;
--
          -- �x���m��敪
          --   �����^�� IS NULL �̏ꍇ
          IF (lv_charged_amount IS NULL ) THEN
            u_head_defined_flag_tab(ln_update_cnt)   := gv_ktg_no;
--
          -- ���ً敪 = Y �̏ꍇ
          ELSIF  (u_head_output_flag_tab(ln_update_cnt)  = gv_ktg_yes) THEN
            u_head_defined_flag_tab(ln_update_cnt)   := gv_ktg_no;
--
          -- ���ً敪 = N �̏ꍇ
          ELSE
            u_head_defined_flag_tab(ln_update_cnt)   := gv_ktg_yes;
          END IF;
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
--
-- ##### 20080805 Ver.1.5 ST���O�m�F��Q START #####
--          u_head_return_flag_tab(ln_update_cnt)    := lv_return_flag ;  -- �x���m���
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
--          IF (lv_defined_flag = gv_ktg_yes) THEN
          -- ���̎x���m��敪 �� Y �̏ꍇ
          IF  (lv_defined_flag = gv_ktg_yes) THEN
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
            u_head_return_flag_tab(ln_update_cnt)    := gv_ktg_yes ;  -- �x���m���
--
          -- ��L�ȊO�̏ꍇ
          ELSE
            u_head_return_flag_tab(ln_update_cnt)    := gv_ktg_no ;  -- �x���m���
          END IF;
-- ##### 20080805 Ver.1.5 ST���O�m�F��Q END   #####
--
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
          -- �����f�[�^�폜�����̒ǉ�
          IF   (lt_delivery_company_code    <> u_head_deliv_cmpny_cd_tab(ln_update_cnt) ) -- �^���Ǝ�
            OR (lt_delivery_no              <> u_head_deliv_no_tab(ln_update_cnt)       ) -- �z��No
            OR (lt_payments_judgment_classe <> u_head_pay_judg_cls_tab(ln_update_cnt)   ) -- �x�����f�敪
            OR (lt_ship_date                <> u_head_ship_date_tab(ln_update_cnt)      ) -- �o�ɓ�
            OR (lt_arrival_date             <> u_head_arrival_date_tab(ln_update_cnt)   ) -- ������
            OR (lt_judgement_date           <> u_head_judg_date_tab(ln_update_cnt)      ) -- ���f��
            OR (lt_goods_classe             <> u_head_goods_cls_tab(ln_update_cnt)      ) -- ���i�敪
            OR (lt_mixed_code               <> u_head_mixed_cd_tab(ln_update_cnt)       ) -- ���ڋ敪
            OR (lt_contract_rate            <> u_head_contract_rate_tab(ln_update_cnt)  ) -- �_��^��
            OR (lt_balance                  <> u_head_balance_tab(ln_update_cnt)        ) -- ���z
            OR (lt_total_amount             <> u_head_total_amount_tab(ln_update_cnt)   ) -- ���v
            OR (lt_distance                 <> u_head_distance_tab(ln_update_cnt)       ) -- �Œ�����
            OR (lt_delivery_classe          <> u_head_deliv_cls_tab(ln_update_cnt)      ) -- �z���敪
            OR (lt_whs_code                 <> u_head_whs_cd_tab(ln_update_cnt)         ) -- ��\�o�ɑq�ɃR�[�h
            OR (lt_code_division            <> u_head_cd_dvsn_tab(ln_update_cnt)        ) -- ��\�z����R�[�h�敪
            OR (lt_shipping_address_code    <> u_head_ship_addr_cd_tab(ln_update_cnt)   ) -- ��\�z����R�[�h
            OR (lt_qty1                     <> u_head_qty1_tab(ln_update_cnt)           ) -- ���P
            OR (lt_delivery_weight1         <> u_head_deliv_wght1_tab(ln_update_cnt)    ) -- �d�ʂP
            OR (lt_consolid_surcharge       <> u_head_cnsld_srhrg_tab(ln_update_cnt)    ) -- ���ڊ������z
            OR (lt_actual_distance          <> u_head_actual_ditnc_tab(ln_update_cnt)   ) -- �Œ����ۋ���
            OR (lt_picking_charge           <> u_head_pick_charge_tab(ln_update_cnt)    ) -- �s�b�L���O��
            OR (lt_consolid_qty             <> u_head_consolid_qty_tab(ln_update_cnt)   ) -- ���ڐ�
            OR (lt_order_type               <> u_head_order_type_tab(ln_update_cnt)     ) -- ��\�^�C�v
            OR (lt_weight_capacity_class    <> u_head_wigh_cpcty_cls_tab(ln_update_cnt) ) -- �d�ʗe�ϋ敪
          THEN
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
            IF (gv_debug_flg = gv_debug_on) THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�^���w�b�_�A�h�I�� DELETE');
            END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
            -- **************************************************
            -- ** �X�V�ΏۂƂȂ����z��No�͂̐������͑S�č폜�Ώ�
            -- **************************************************
            -- �폜�pPL/SQL�\ �����C���N�������g
            ln_delete_cnt   := ln_delete_cnt + 1;
            -- �z��No
            d_head_deliv_no_tab(ln_delete_cnt)  := gt_carriers_schedule_tab(ln_index).delivery_no ;
--
-- ##### 20081226 Ver.1.18 �{��#323�Ή��i���O�Ή��j START #####
          -- ���ѕύX�ɂ��폜 ���O�o�͗p�̈�i�[
          gn_delete_data_idx := gn_delete_data_idx + 1;
-- ##### 20081229 Ver.1.19 �{��#882�Ή� START #####
--          gt_delete_data_msg(gn_delete_data_idx) :=  d_head_deliv_no_tab(ln_delete_cnt);
          gt_delete_data_msg(gn_delete_data_idx) :=  u_head_deliv_no_tab(ln_update_cnt)     || '  ' ;  -- �z��No
          gt_delete_data_msg(gn_delete_data_idx) :=  gt_delete_data_msg(gn_delete_data_idx) || u_head_deliv_cmpny_cd_tab(ln_update_cnt) || '  ' ; -- �^���Ǝ�
          gt_delete_data_msg(gn_delete_data_idx) :=  gt_delete_data_msg(gn_delete_data_idx) || TO_CHAR(u_head_ship_date_tab(ln_update_cnt),'YYYY/MM/DD'); -- �o�ד�
-- ##### 20081229 Ver.1.19 �{��#882�Ή� END   #####
-- ##### 20081226 Ver.1.18 �{��#323�Ή��i���O�Ή��j END   #####
--
-- ##### 20081224 Ver.1.17 �{��#323�Ή� START #####
          END IF;
-- ##### 20081224 Ver.1.17 �{��#323�Ή� END   #####
--
        END IF;
--
      END IF;
--
    END LOOP deliv_loop;
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
  END set_carri_deliv_head;
--
  /**********************************************************************************
   * Procedure Name   : set_carri_deliv_head
   * Description      : �z�Ԃ̂݉^���w�b�_�A�h�I��PL/SQL�\�i�[(A-32)
   ***********************************************************************************/
/***** ��������v���V�[�W���ۂ��ƃR�����g�A�E�g *****
  PROCEDURE set_carri_deliv_head(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_carri_deliv_head'; -- �v���O������
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
    lv_delivery_no      xxwip_deliverys.delivery_no%TYPE;   -- �z��No
    lv_output_flag      xxwip_deliverys.output_flag%TYPE;   -- ������
    lv_defined_flag     xxwip_deliverys.defined_flag%TYPE;  -- �x���m��敪
    lv_return_flag      xxwip_deliverys.return_flag%TYPE;   -- �x���m���
--
    ln_order_flg        VARCHAR2(1);    -- �󒍃w�b�_�A�h�I�� ���݃t���O Y:�L N:��
    ln_move_flg         VARCHAR2(1);    -- �󒍖��׃A�h�I��   ���݃t���O Y:�L N:��
    ln_deliv_flg        VARCHAR2(1);    -- �^���w�b�_�A�h�I�� ���݃t���O Y:�L N:��
--
    ln_order_cnt        NUMBER;   -- �󒍃w�b�_�A�h�I�� ����
    ln_move_cnt         NUMBER;   -- �󒍖��׃A�h�I��   ����
--
    ln_insert_cnt   NUMBER;  -- �o�^�pPL/SQL�\ ����
    ln_update_cnt   NUMBER;  -- �X�V�pPL/SQL�\ ����
    ln_delete_cnt   NUMBER;  -- �폜�pPL/SQL�\ ����
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
    -- ����������
    ln_insert_cnt   := i_head_deliv_no_tab.COUNT;
    ln_update_cnt   := u_head_deliv_no_tab.COUNT;
    ln_delete_cnt   := d_head_deliv_no_tab.COUNT;
--
    -- �Ώۃf�[�^���̏ꍇ
    IF (gt_carriers_schedule_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<deliv_loop>>
    FOR ln_index IN  gt_carriers_schedule_tab.FIRST.. gt_carriers_schedule_tab.LAST LOOP
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F$$$$$$$$$$ �z�Ԕz���v�� ���݊m�F $$$$$$$$$$�F' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�^���Ǝ� �F' || gt_carriers_schedule_tab(ln_index).delivery_company_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�z��No   �F' || gt_carriers_schedule_tab(ln_index).delivery_no);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- **************************************************
      -- ***  �󒍃w�b�_�A�h�I�� ���݊m�F
      -- **************************************************
      -- �ϐ�������
      ln_order_cnt := 0;
--
      SELECT  COUNT(xoha.delivery_no)   -- �z��No
      INTO    ln_order_cnt
      FROM   xxwsh_order_headers_all  xoha  -- �󒍃w�b�_�A�h�I��
      WHERE  xoha.delivery_no = gt_carriers_schedule_tab(ln_index).delivery_no; -- �z��No
--
      IF (ln_order_cnt = 0) THEN
        ln_deliv_flg := gv_ktg_no;
      ELSE
        ln_deliv_flg := gv_ktg_yes;
      END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F$$$$$ �󒍃w�b�_ ���݊m�F $$$$$�F' || ln_deliv_flg);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- **************************************************
      -- ***  �ړ��˗�/�w���w�b�_�A�h�I�� ���݊m�F
      -- **************************************************
      -- �ϐ�������
      ln_move_cnt := 0;
--
      SELECT  COUNT(xmrih.delivery_no)            -- �z��No
      INTO    ln_move_cnt
      FROM   xxinv_mov_req_instr_headers  xmrih   -- �ړ��˗�/�w���w�b�_�A�h�I��
      WHERE  xmrih.delivery_no = gt_carriers_schedule_tab(ln_index).delivery_no; -- �z��No
--
      IF (ln_move_cnt = 0) THEN
        ln_move_flg := gv_ktg_no;
      ELSE
        ln_move_flg := gv_ktg_yes;
      END IF;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F$$$$$ �ړ��w�b�_ ���݊m�F $$$$$�F' || ln_move_flg);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
      -- �󒍃w�b�_�A�h�I���A�ړ��˗�/�w���w�b�_�A�h�I���ɑ��݂��Ȃ��ꍇ
      IF ((ln_deliv_flg = gv_ktg_no) AND (ln_deliv_flg = gv_ktg_no)) THEN
--
        -- **************************************************
        -- ***  �^���w�b�_�A�h�I�����o
        -- **************************************************
        -- ���݃t���O������
        ln_deliv_flg := gv_ktg_yes;
--
        BEGIN
          SELECT  xd.delivery_no        -- �z��No
                , xd.output_flag        -- ������
                , xd.defined_flag       -- �x���m��敪
                , xd.return_flag        -- �x���m���
          INTO    lv_delivery_no
                , lv_output_flag
                , lv_defined_flag
                , lv_return_flag
          FROM   xxwip_deliverys      xd      -- �^���w�b�_�A�h�I��
          WHERE  xd.delivery_no = gt_carriers_schedule_tab(ln_index).delivery_no -- �z��No
          AND    xd.p_b_classe = gv_pay ;                           -- �x�������敪�i�x���j
        EXCEPTION
          WHEN NO_DATA_FOUND THEN   -- *** �f�[�^�擾�G���[ ***
            -- ���݃t���O Y ��ݒ�
            ln_deliv_flg := gv_ktg_no;
--
          WHEN TOO_MANY_ROWS THEN   -- *** �f�[�^�����擾�G���[ ***
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                  gv_xxcmn_msg_toomny,
                                                  gv_tkn_table,
                                                  gv_deliverys,
                                                  gv_tkn_key,
                                                  gv_pay || ',' ||
                                                  gt_carriers_schedule_tab(ln_index).delivery_no);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F$$$$$ �^���w�b�_�A�h�I�� $$$$$�F' || ln_deliv_flg);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�z��No      �F'|| lv_delivery_no);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F������      �F'|| TO_CHAR(lv_output_flag));
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�x���m��敪�F'|| lv_defined_flag);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�x���m���  �F'|| lv_return_flag);
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- **************************************************
        -- ***  �^���w�b�_�A�h�I���Ƀf�[�^�����݂��Ȃ��ꍇ
        -- **************************************************
        IF (ln_deliv_flg = gv_ktg_no) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�^���w�b�_�A�h�I�� INSERT');
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- �o�^�pPL/SQL�\ ����
          ln_insert_cnt  := ln_insert_cnt + 1;
--
          -- �^���Ǝ�
          i_head_deliv_cmpny_cd_tab(ln_insert_cnt) := 
                            gt_carriers_schedule_tab(ln_index).delivery_company_code ;
          -- �z��No
          i_head_deliv_no_tab(ln_insert_cnt)       := 
                            gt_carriers_schedule_tab(ln_index).delivery_no ;
          -- �����No
          i_head_invoice_no_tab(ln_insert_cnt)     := NULL ;
          -- �x�������敪
          i_head_p_b_classe_tab(ln_insert_cnt)     := gv_pay ;
          -- �x�����f�敪
          i_head_pay_judg_cls_tab(ln_insert_cnt)   := 
                            gt_carriers_schedule_tab(ln_index).payments_judgment_classe ;
          -- �o�ɓ�
          i_head_ship_date_tab(ln_insert_cnt)      := gt_carriers_schedule_tab(ln_index).ship_date ;
          -- ������
          i_head_arrival_date_tab(ln_insert_cnt)   := 
                            gt_carriers_schedule_tab(ln_index).arrival_date ;
          -- �񍐓�
          i_head_report_date_tab(ln_insert_cnt)    := NULL ;
          -- ���f��
          i_head_judg_date_tab(ln_insert_cnt)      := 
                            gt_carriers_schedule_tab(ln_index).judgement_date ;
          i_head_goods_cls_tab(ln_insert_cnt)      := NULL ;  -- ���i�敪
          -- ���ڋ敪
          i_head_mixed_cd_tab(ln_insert_cnt)       := 
                            gt_carriers_schedule_tab(ln_index).mixed_code  ;
          i_head_charg_amount_tab(ln_insert_cnt)   := NULL ;  -- �����^��
          i_head_contract_rate_tab(ln_insert_cnt)  := 0 ;     -- �_��^��
          i_head_balance_tab(ln_insert_cnt)        := 0 ;     -- ���z
          i_head_total_amount_tab(ln_insert_cnt)   := 0 ;     -- ���v
          i_head_many_rate_tab(ln_insert_cnt)      := NULL ;  -- ������
          i_head_distance_tab(ln_insert_cnt)       := 0 ;     -- �Œ�����
          -- �z���敪
          i_head_deliv_cls_tab(ln_insert_cnt)      := 
                            gt_carriers_schedule_tab(ln_index).dellivary_classe ;
          -- ��\�o�ɑq�ɃR�[�h
          i_head_whs_cd_tab(ln_insert_cnt)         := 
                            gt_carriers_schedule_tab(ln_index).whs_code;
          -- ��\�z����R�[�h�敪
          xxwip_common3_pkg.change_code_division(
            gt_carriers_schedule_tab(ln_index).code_division,
            i_head_cd_dvsn_tab(ln_insert_cnt),
            lv_errbuf,
            lv_retcode,
            lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          -- ��\�z����R�[�h
          i_head_ship_addr_cd_tab(ln_insert_cnt) := 
                            gt_carriers_schedule_tab(ln_index).shipping_address_code;
          i_head_qty1_tab(ln_insert_cnt)           := 0 ;           -- ���P
          i_head_qty2_tab(ln_insert_cnt)           := NULL ;        -- ���Q
          i_head_deliv_wght1_tab(ln_insert_cnt)    := 0 ;           -- �d�ʂP
          i_head_deliv_wght2_tab(ln_insert_cnt)    := NULL ;        -- �d�ʂQ
          i_head_cnsld_srhrg_tab(ln_insert_cnt)    := 0 ;           -- ���ڊ������z
          i_head_actual_ditnc_tab(ln_insert_cnt)   := 0 ;           -- �Œ����ۋ���
          i_head_cong_chrg_tab(ln_insert_cnt)      := NULL ;        -- �ʍs��
          i_head_pick_charge_tab(ln_insert_cnt)    := 0 ;           -- �s�b�L���O��
          i_head_consolid_qty_tab(ln_insert_cnt)   := 0 ;           -- ���ڐ�
          i_head_order_type_tab(ln_insert_cnt)     := NULL ;        -- ��\�^�C�v
          -- �d�ʗe�ϋ敪
          i_head_wigh_cpcty_cls_tab(ln_insert_cnt) := 
                            gt_carriers_schedule_tab(ln_index).weight_capacity_class ;
          i_head_out_cont_tab(ln_insert_cnt)       := NULL ;        -- �_��O�敪
          i_head_output_flag_tab(ln_insert_cnt)    := gv_ktg_yes ;  -- ���ً敪
          i_head_defined_flag_tab(ln_insert_cnt)   := gv_ktg_no  ;  -- �x���m��敪
          i_head_return_flag_tab(ln_insert_cnt)    := gv_ktg_no  ;  -- �x���m���
          i_head_fm_upd_flg_tab(ln_insert_cnt)     := gv_ktg_no  ;  -- ��ʍX�V�L���敪
          i_head_trans_lcton_tab(ln_insert_cnt)    := NULL ;        -- �U�֐�
          i_head_out_up_cnt_tab(ln_insert_cnt)     := 0 ;           -- �O���ƎҕύX��
          i_head_description_tab(ln_insert_cnt)    := NULL ;        -- �^���E�v
--
        -- **************************************************
        -- ***  �^���w�b�_�A�h�I���Ƀf�[�^�����݂���ꍇ
        -- **************************************************
        ELSE
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_carri_deliv_head�F�^���w�b�_�A�h�I�� UPDATE��DELETE');
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          -- �X�V�pPL/SQL�\ ����
          ln_update_cnt   := ln_update_cnt + 1;
--
          -- �^���Ǝ�
          u_head_deliv_cmpny_cd_tab(ln_update_cnt) := 
                                gt_carriers_schedule_tab(ln_index).delivery_company_code ;
          -- �z��No
          u_head_deliv_no_tab(ln_update_cnt)       := 
                                gt_carriers_schedule_tab(ln_index).delivery_no ;
          u_head_invoice_no_tab(ln_update_cnt)     := NULL ; -- �����No
          -- �x�����f�敪
          u_head_pay_judg_cls_tab(ln_update_cnt)   := 
                                gt_carriers_schedule_tab(ln_index).payments_judgment_classe ;
          -- �o�ɓ�
          u_head_ship_date_tab(ln_update_cnt)      := 
                                gt_carriers_schedule_tab(ln_index).ship_date ;
          -- ������
          u_head_arrival_date_tab(ln_update_cnt)   := 
                                gt_carriers_schedule_tab(ln_index).arrival_date ;
          -- ���f��
          u_head_judg_date_tab(ln_update_cnt)      := 
                                gt_carriers_schedule_tab(ln_index).judgement_date ;
          u_head_goods_cls_tab(ln_update_cnt)      := NULL ; -- ���i�敪
          -- ���ڋ敪
          u_head_mixed_cd_tab(ln_update_cnt)       := 
                                gt_carriers_schedule_tab(ln_index).mixed_code ;
          u_head_contract_rate_tab(ln_update_cnt)  := 0 ;    -- �_��^��
          u_head_balance_tab(ln_update_cnt)        := 0 ;    -- ���z
          u_head_total_amount_tab(ln_update_cnt)   := 0 ;    -- ���v
          u_head_distance_tab(ln_update_cnt)       := 0 ;    -- �Œ�����
          -- �z���敪
          u_head_deliv_cls_tab(ln_update_cnt)      := 
                            gt_carriers_schedule_tab(ln_index).dellivary_classe ;
          -- ��\�o�ɑq�ɃR�[�h
          u_head_whs_cd_tab(ln_update_cnt)         := gt_carriers_schedule_tab(ln_index).whs_code;
--
          -- ��\�z����R�[�h
          xxwip_common3_pkg.change_code_division(
            gt_carriers_schedule_tab(ln_index).code_division,
            u_head_cd_dvsn_tab(ln_update_cnt),
            lv_errbuf,
            lv_retcode,
            lv_errmsg);
          -- ��\�z����R�[�h
          u_head_ship_addr_cd_tab(ln_update_cnt) :=
                            gt_carriers_schedule_tab(ln_index).shipping_address_code;
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          u_head_qty1_tab(ln_update_cnt)           := 0 ;    -- ���P
          u_head_deliv_wght1_tab(ln_update_cnt)    := 0 ;    -- �d�ʂP
          u_head_cnsld_srhrg_tab(ln_update_cnt)    := 0 ;    -- ���ڊ������z
          u_head_actual_ditnc_tab(ln_update_cnt)   := 0 ;    -- �Œ����ۋ���
          u_head_pick_charge_tab(ln_update_cnt)    := 0 ;    -- �s�b�L���O��
          u_head_consolid_qty_tab(ln_update_cnt)   := 0 ;    -- ���ڐ�
          u_head_order_type_tab(ln_update_cnt)     := NULL ; -- ��\�^�C�v
          -- �d�ʗe�ϋ敪
          u_head_wigh_cpcty_cls_tab(ln_update_cnt) := 
                            gt_carriers_schedule_tab(ln_index).weight_capacity_class ;
          u_head_out_cont_tab(ln_update_cnt)       := NULL ; -- �_��O�敪
          u_head_trans_lcton_tab(ln_update_cnt)    := NULL ; -- �U�֐�
          u_head_output_flag_tab(ln_update_cnt)    := gv_ktg_yes;       -- ���ً敪
          u_head_defined_flag_tab(ln_update_cnt)   := gv_ktg_no;        -- �x���m��敪
          u_head_return_flag_tab(ln_update_cnt)    := lv_return_flag ;  -- �x���m���
--
          -- �X�V�ΏۂƂȂ����z��No�͂̐������͑S�č폜�Ώ�
          -- �폜�pPL/SQL�\ �����C���N�������g
          ln_delete_cnt   := ln_delete_cnt + 1;
          -- �z��No
          d_head_deliv_no_tab(ln_delete_cnt)  := gt_deliv_line_tab(ln_index).delivery_no ;
--
        END IF;
--
      END IF;
--
    END LOOP deliv_loop;
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
  END set_carri_deliv_head;
***** �����܂Ńv���V�[�W���ۂ��ƃR�����g�A�E�g*****/

-- ##### 20080717 Ver.1.5 �ύX�v��96,98 END   #####
--
  /**********************************************************************************
   * Procedure Name   : insert_deliv_head
   * Description      : �^���w�b�_�A�h�I���ꊇ�o�^(A-33)
   ***********************************************************************************/
  PROCEDURE insert_deliv_head(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_deliv_head'; -- �v���O������
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
    IF (i_head_deliv_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * �^���w�b�_�A�h�I�� �o�^
      -- **************************************************
      FORALL ln_index IN i_head_deliv_no_tab.FIRST .. i_head_deliv_no_tab.LAST
        INSERT INTO xxwip_deliverys
        ( deliverys_header_id         -- �^���w�b�_�[�A�h�I��ID
        , delivery_company_code       -- �^���Ǝ�
        , delivery_no                 -- �z��No
        , invoice_no                  -- �����No
        , p_b_classe                  -- �x�������敪
        , payments_judgment_classe    -- �x�����f�敪
        , ship_date                   -- �o�ɓ�
        , arrival_date                -- ������
        , report_date                 -- �񍐓�
        , judgement_date              -- ���f��
        , goods_classe                -- ���i�敪
        , mixed_code                  -- ���ڋ敪
        , charged_amount              -- �����^��
        , contract_rate               -- �_��^��
        , balance                     -- ���z
        , total_amount                -- ���v
        , many_rate                   -- ������
        , distance                    -- �Œ�����
        , delivery_classe             -- �z���敪
        , whs_code                    -- ��\�o�ɑq�ɃR�[�h
        , code_division               -- ��\�z����R�[�h�敪
        , shipping_address_code       -- ��\�z����R�[�h
        , qty1                        -- ���P
        , qty2                        -- ���Q
        , delivery_weight1            -- �d�ʂP
        , delivery_weight2            -- �d�ʂQ
        , consolid_surcharge          -- ���ڊ������z
        , actual_distance             -- �Œ����ۋ���
        , congestion_charge           -- �ʍs��
        , picking_charge              -- �s�b�L���O��
        , consolid_qty                -- ���ڐ�
        , order_type                  -- ��\�^�C�v
        , weight_capacity_class       -- �d�ʗe�ϋ敪
        , outside_contract            -- �_��O�敪
        , output_flag                 -- ���ً敪
        , defined_flag                -- �x���m��敪
        , return_flag                 -- �x���m���
        , form_update_flag            -- ��ʍX�V�L���敪
        , transfer_location           -- �U�֐�
        , outside_up_count            -- �O���ƎҕύX��
        , description                 -- �^���E�v
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 START #####
        , dispatch_type               -- �z�ԃ^�C�v
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 END   #####
        , created_by                  -- �쐬��
        , creation_date               -- �쐬��
        , last_updated_by             -- �ŏI�X�V��
        , last_update_date            -- �ŏI�X�V��
        , last_update_login           -- �ŏI�X�V���O�C��
        , request_id                  -- �v��ID
        , program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                  -- �R���J�����g�E�v���O����ID
        , program_update_date         -- �v���O�����X�V��
        ) VALUES (
          xxwip_deliverys_id_s1.NEXTVAL         -- �^���w�b�_�[�A�h�I��ID
        , i_head_deliv_cmpny_cd_tab(ln_index)   -- �^���Ǝ�
        , i_head_deliv_no_tab(ln_index)         -- �z��No
        , i_head_invoice_no_tab(ln_index)       -- �����No
        , i_head_p_b_classe_tab(ln_index)       -- �x�������敪
        , i_head_pay_judg_cls_tab(ln_index)     -- �x�����f�敪
        , i_head_ship_date_tab(ln_index)        -- �o�ɓ�
        , i_head_arrival_date_tab(ln_index)     -- ������
        , i_head_report_date_tab(ln_index)      -- �񍐓�
        , i_head_judg_date_tab(ln_index)        -- ���f��
        , i_head_goods_cls_tab(ln_index)        -- ���i�敪
        , i_head_mixed_cd_tab(ln_index)         -- ���ڋ敪
        , i_head_charg_amount_tab(ln_index)     -- �����^��
        , i_head_contract_rate_tab(ln_index)    -- �_��^��
        , i_head_balance_tab(ln_index)          -- ���z
        , i_head_total_amount_tab(ln_index)     -- ���v
        , i_head_many_rate_tab(ln_index)        -- ������
        , i_head_distance_tab(ln_index)         -- �Œ�����
        , i_head_deliv_cls_tab(ln_index)        -- �z���敪
        , i_head_whs_cd_tab(ln_index)           -- ��\�o�ɑq�ɃR�[�h
        , i_head_cd_dvsn_tab(ln_index)          -- ��\�z����R�[�h�敪
        , i_head_ship_addr_cd_tab(ln_index)     -- ��\�z����R�[�h
        , i_head_qty1_tab(ln_index)             -- ���P
        , i_head_qty2_tab(ln_index)             -- ���Q
        , i_head_deliv_wght1_tab(ln_index)      -- �d�ʂP
        , i_head_deliv_wght2_tab(ln_index)      -- �d�ʂQ
        , i_head_cnsld_srhrg_tab(ln_index)      -- ���ڊ������z
        , i_head_actual_ditnc_tab(ln_index)     -- �Œ����ۋ���
        , i_head_cong_chrg_tab(ln_index)        -- �ʍs��
        , i_head_pick_charge_tab(ln_index)      -- �s�b�L���O��
        , i_head_consolid_qty_tab(ln_index)     -- ���ڐ�
        , i_head_order_type_tab(ln_index)       -- ��\�^�C�v
        , i_head_wigh_cpcty_cls_tab(ln_index)   -- �d�ʗe�ϋ敪
        , i_head_out_cont_tab(ln_index)         -- �_��O�敪
        , i_head_output_flag_tab(ln_index)      -- ���ً敪
        , i_head_defined_flag_tab(ln_index)     -- �x���m��敪
        , i_head_return_flag_tab(ln_index)      -- �x���m���
        , i_head_fm_upd_flg_tab(ln_index)       -- ��ʍX�V�L���敪
        , i_head_trans_lcton_tab(ln_index)      -- �U�֐�
        , i_head_out_up_cnt_tab(ln_index)       -- �O���ƎҕύX��
        , i_head_description_tab(ln_index)      -- �^���E�v
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 START #####
        , i_head_dispatch_type_tab(ln_index)    -- �z�ԃ^�C�v
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 END   #####
        , gn_user_id                            -- �쐬��
        , gd_sysdate                            -- �쐬��
        , gn_user_id                            -- �ŏI�X�V��
        , gd_sysdate                            -- �ŏI�X�V��
        , gn_login_id                           -- �ŏI�X�V���O�C��
        , gn_conc_request_id                    -- �v��ID
        , gn_prog_appl_id                       -- �ݶ��āE��۸��сE���ع����ID
        , gn_conc_program_id                    -- �R���J�����g�E�v���O����ID
        , gd_sysdate);                          -- �v���O�����X�V��
--
      -- **************************************************
      -- �����ݒ�
      -- **************************************************
      gn_deliv_ins_cnt := gn_deliv_ins_cnt + SQL%ROWCOUNT;
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
  END insert_deliv_head;
--
  /**********************************************************************************
   * Procedure Name   : update_deliv_head
   * Description      : �^���w�b�_�A�h�I���ꊇ�X�V(A-34)
   ***********************************************************************************/
  PROCEDURE update_deliv_head(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_deliv_head'; -- �v���O������
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
    IF (u_head_deliv_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * �^���w�b�_�A�h�I�� �X�V
      -- **************************************************
      FORALL ln_index IN u_head_deliv_no_tab.FIRST .. u_head_deliv_no_tab.LAST
        UPDATE xxwip_deliverys            -- �^���w�b�_�A�h�I��
        SET     delivery_company_code     = u_head_deliv_cmpny_cd_tab(ln_index)-- �^���Ǝ�
              , delivery_no               = u_head_deliv_no_tab(ln_index)      -- �z��No
              , invoice_no                = u_head_invoice_no_tab(ln_index)    -- �����No
              , payments_judgment_classe  = u_head_pay_judg_cls_tab(ln_index)  -- �x�����f�敪
              , ship_date                 = u_head_ship_date_tab(ln_index)     -- �o�ɓ�
              , arrival_date              = u_head_arrival_date_tab(ln_index)  -- ������
              , judgement_date            = u_head_judg_date_tab(ln_index)     -- ���f��
              , goods_classe              = u_head_goods_cls_tab(ln_index)     -- ���i�敪
              , mixed_code                = u_head_mixed_cd_tab(ln_index)      -- ���ڋ敪
              , contract_rate             = u_head_contract_rate_tab(ln_index) -- �_��^��
              , balance                   = u_head_balance_tab(ln_index)       -- ���z
              , total_amount              = u_head_total_amount_tab(ln_index)  -- ���v
              , distance                  = u_head_distance_tab(ln_index)      -- �Œ�����
              , delivery_classe           = u_head_deliv_cls_tab(ln_index)     -- �z���敪
              , whs_code                  = u_head_whs_cd_tab(ln_index)        -- ��\�o�ɑq�ɃR�[�h
              , code_division             = u_head_cd_dvsn_tab(ln_index)       -- ��\�z����R�[�h�敪
              , shipping_address_code     = u_head_ship_addr_cd_tab(ln_index)  -- ��\�z����R�[�h
              , qty1                      = u_head_qty1_tab(ln_index)          -- ���P
              , delivery_weight1          = u_head_deliv_wght1_tab(ln_index)   -- �d�ʂP
              , consolid_surcharge        = u_head_cnsld_srhrg_tab(ln_index)   -- ���ڊ������z
              , actual_distance           = u_head_actual_ditnc_tab(ln_index)  -- �Œ����ۋ���
              , picking_charge            = u_head_pick_charge_tab(ln_index)   -- �s�b�L���O��
              , consolid_qty              = u_head_consolid_qty_tab(ln_index)  -- ���ڐ�
              , order_type                = u_head_order_type_tab(ln_index)    -- ��\�^�C�v
              , weight_capacity_class     = u_head_wigh_cpcty_cls_tab(ln_index)-- �d�ʗe�ϋ敪
              , outside_contract          = u_head_out_cont_tab(ln_index)      -- �_��O�敪
              , transfer_location         = u_head_trans_lcton_tab(ln_index)   -- �U�֐�
              , output_flag               = u_head_output_flag_tab(ln_index)   -- ���ً敪
              , defined_flag              = u_head_defined_flag_tab(ln_index)  -- �x���m��敪
              , return_flag               = u_head_return_flag_tab(ln_index)   -- �x���m���
              , last_updated_by           = gn_user_id                 -- �ŏI�X�V��
              , last_update_date          = gd_sysdate                 -- �ŏI�X�V��
              , last_update_login         = gn_login_id                -- �ŏI�X�V���O�C��
              , request_id                = gn_conc_request_id         -- �v��ID
              , program_application_id    = gn_prog_appl_id            -- �ݶ��āE��۸��сE���ع����ID
              , program_id                = gn_conc_program_id         -- �R���J�����g�E�v���O����ID
              , program_update_date       = gd_sysdate                 -- �v���O�����X�V��
        WHERE   delivery_no = u_head_deliv_no_tab(ln_index)       -- �z��No
        AND     p_b_classe  = gv_pay;                             -- �x�������敪
--
      -- **************************************************
      -- �����ݒ�
      -- **************************************************
      gn_deliv_ins_cnt := gn_deliv_ins_cnt + SQL%ROWCOUNT;
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
  END update_deliv_head;
--
  /**********************************************************************************
   * Procedure Name   : delete_deliv_head
   * Description      : �^���w�b�_�A�h�I���ꊇ�폜(A-35)
   ***********************************************************************************/
  PROCEDURE delete_deliv_head(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_deliv_head'; -- �v���O������
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
    IF (d_head_deliv_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * �^���w�b�_�A�h�I�� �폜
      -- **************************************************
      FORALL ln_index IN d_head_deliv_no_tab.FIRST .. d_head_deliv_no_tab.LAST
        DELETE FROM  xxwip_deliverys  -- �^���w�b�_�A�h�I��
        WHERE   delivery_no = d_head_deliv_no_tab(ln_index) -- �z��No
        AND     p_b_classe  = gv_claim;                     -- �x�������敪�i�����j
--
      -- **************************************************
      -- �����ݒ�
      -- **************************************************
      gn_deliv_del_cnt := gn_deliv_del_cnt + SQL%ROWCOUNT;
--
    END IF;
--
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 START #####
    IF (d_slip_head_deliv_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * �^���w�b�_�A�h�I�� �폜�i�`�[�Ȃ��z�� �x���E�������Ώہj
      -- **************************************************
      FORALL ln_index IN d_slip_head_deliv_no_tab.FIRST .. d_slip_head_deliv_no_tab.LAST
        DELETE FROM  xxwip_deliverys  -- �^���w�b�_�A�h�I��
        WHERE   delivery_no = d_slip_head_deliv_no_tab(ln_index); -- �z��No
--
      -- **************************************************
      -- �����ݒ�
      -- **************************************************
-- ##### 20081226 Ver.1.18 �{��#323�Ή��i���O�Ή��j START #####
-- �����͒ǉ����Ȃ�
--      gn_deliv_del_cnt := gn_deliv_del_cnt + SQL%ROWCOUNT;
-- ##### 20081226 Ver.1.18 �{��#323�Ή��i���O�Ή��j END   #####
--
    END IF;
--
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 END   #####
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
  END delete_deliv_head;
--
  /**********************************************************************************
   * Procedure Name   : update_deliv_cntl
   * Description      : �^���v�Z�R���g���[���X�V����(A-36)
   ***********************************************************************************/
  PROCEDURE update_deliv_cntl(
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
      WHERE  xdc.concurrent_no          = gv_con_no_deliv;
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
  END update_deliv_cntl;
--
  /**********************************************************************************
   * Procedure Name   : get_exch_deliv_line
   * Description      : ���։^�����׃A�h�I�����o(A-37)
   ***********************************************************************************/
  PROCEDURE get_exch_deliv_line(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_exch_deliv_line'; -- �v���O������
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
    -- �^�����׃A�h�I�� ���o
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
/***** �擾SQL�ύX
    SELECT    xdl.request_no                      -- �˗�No
            , xdl.small_lot_class                 -- ���[�t�����敪
            , xdl.goods_classe                    -- ���i�敪
            , xdl.weight_capacity_class           -- �d�ʗe�ϋ敪
            , xdl.qty                             -- ��
            , xdl.delivery_weight                 -- �d��
            , xdl.mixed_code                      -- ���ڋ敪
            , NVL(xdd.post_distance, 0)           -- �z�������F�ԗ�����
            , NVL(xdd.small_distance, 0)          -- �z�������F��������
            , NVL(xdd.consolid_add_distance, 0)   -- �z�������F���ڋ���
            , NVL(xdd.actual_distance, 0)         -- �z�������F���ۋ���
            , NVL(xdc.small_weight, 0)      -- �^���ƎҁF�����d��
    BULK COLLECT INTO gt_exch_deliv_line_tab
    FROM  xxwip_delivery_lines        xdl,      -- �^�����׃A�h�I��
          xxwip_delivery_distance     xdd,      -- �z�������A�h�I���}�X�^
          xxwip_delivery_company      xdc       -- �^���p�^���Ǝ҃A�h�I���}�X�^
    WHERE xdl.judgement_date >= gd_target_date                        -- ���f�� >= ����
    AND   xdl.goods_classe            = xdd.goods_classe(+)           -- �z�������F���i�敪
    AND   xdl.delivery_company_code   = xdd.delivery_company_code(+)  -- �z�������F�^���Ǝ�
    AND   xdl.whs_code                = xdd.origin_shipment(+)        -- �z�������F�o�ɑq��
    AND   xdl.code_division           = xdd.code_division(+)          -- �z�������F�R�[�h�敪
    AND   xdl.shipping_address_code   = xdd.shipping_address_code(+)  -- �z�������F�z����R�[�h
    AND   TRUNC(xdl.judgement_date)  >= xdd.start_date_active(+)      -- �z�������F�K�p�J�n��
    AND   TRUNC(xdl.judgement_date)  <= xdd.end_date_active(+)        -- �z�������F�K�p�I����
    AND   xdl.goods_classe            = xdc.goods_classe(+)           -- �^���ƎҁF���i�敪
    AND   xdl.delivery_company_code   = xdc.delivery_company_code(+)  -- �^���ƎҁF�^���Ǝ�
    AND   TRUNC(xdl.judgement_date)   >= xdc.start_date_active(+)     -- �^���ƎҁF�K�p�J�n��
    AND   TRUNC(xdl.judgement_date)  <= xdc.end_date_active(+)        -- �^���ƎҁF�K�p�I����
    ORDER BY xdl.request_no;
*****/
    SELECT    xdl.request_no                    request_no            -- �˗�No
            , xdl.small_lot_class               small_lot_class       -- ���[�t�����敪
            , xdl.goods_classe                  goods_classe          -- ���i�敪
            , xdl.weight_capacity_class         weight_capacity_class -- �d�ʗe�ϋ敪
            , xdl.qty                           qty                   -- ��
            , xdl.delivery_weight               delivery_weight       -- �d��
            , xdl.mixed_code                    mixed_code            -- ���ڋ敪
            , xdl.judgement_date                judgement_date        -- ���f��
            , xdl.distance                      distance              -- ����
            , xdl.actual_distance               xdl_actual_distance   -- ���ۋ���
            , xdl.dellivary_classe              dellivary_classe      -- �z���敪
            , xdd.change_flg                    distance_chk          -- �z�������t���O�i1:�Ώۂ��� 0:�ΏۂȂ��j
            , xdc.pay_change_flg                company_chk           -- �^���Ǝ҃t���O�i1:�Ώۂ��� 0:�ΏۂȂ��j
            , xdd.post_distance                 post_distance         -- �z�������F�ԗ�����
            , xdd.small_distance                small_distance        -- �z�������F��������
            , xdd.consolid_add_distance         consolid_add_distance -- �z�������F���ڋ���
            , xdd.actual_distance               actual_distance       -- �z�������F���ۋ���
            , xdc.small_weight                  small_weight          -- �^���ƎҁF�����d��
    BULK COLLECT INTO gt_exch_deliv_line_tab
    FROM
          (
            -- *** �^�����׃A�h�I���|�z�������}�X�^ ***
            SELECT  xdl.request_no                        -- �˗�No
                  , xdl.judgement_date                    -- ���f��
                  , xdl.goods_classe                      -- ���i�敪
                  , xdl.delivery_company_code             -- �^���Ǝ�
                  , xdl.whs_code                          -- �o�ɑq��
                  , xdl.code_division                     -- �R�[�h�敪
                  , xdl.shipping_address_code             -- �z����R�[�h
            FROM  xxwip_delivery_lines        xdl     -- �^�����׃A�h�I��
                , xxwip_delivery_distance     xdd     -- �z�������A�h�I���}�X�^
            WHERE xdl.judgement_date         >= gd_target_date                -- ���f�� >= ����
            AND   xdl.goods_classe            = xdd.goods_classe              -- �z�������F���i�敪
            AND   xdl.delivery_company_code   = xdd.delivery_company_code     -- �z�������F�^���Ǝ�
            AND   xdl.whs_code                = xdd.origin_shipment           -- �z�������F�o�ɑq��
            AND   xdl.code_division           = xdd.code_division             -- �z�������F�R�[�h�敪
            AND   xdl.shipping_address_code   = xdd.shipping_address_code     -- �z�������F�z����R�[�h
            AND   TRUNC(xdl.judgement_date)  >= xdd.start_date_active         -- �z�������F�K�p�J�n��
            AND   TRUNC(xdl.judgement_date)  <= xdd.end_date_active           -- �z�������F�K�p�I����
            AND   change_flg                  = gv_target_y                   -- �x���ύX�t���O
            UNION
            -- *** �^�����׃A�h�I���|�^���p�^���Ǝ҃}�X�^ ***
            SELECT  xdl.request_no                        -- �˗�No
                  , xdl.judgement_date                    -- ���f��
                  , xdl.goods_classe                      -- ���i�敪
                  , xdl.delivery_company_code             -- �^���Ǝ�
                  , xdl.whs_code                          -- �o�ɑq��
                  , xdl.code_division                     -- �R�[�h�敪
                  , xdl.shipping_address_code             -- �z����R�[�h
            FROM  xxwip_delivery_lines        xdl     -- �^�����׃A�h�I��
                , xxwip_delivery_company      xdc     -- �^���p�^���Ǝ҃A�h�I���}�X�^
            WHERE xdl.judgement_date         >= gd_target_date                -- ���f�� >= ����
            AND   xdl.goods_classe            = xdc.goods_classe              -- �^���ƎҁF���i�敪
            AND   xdl.delivery_company_code   = xdc.delivery_company_code     -- �^���ƎҁF�^���Ǝ�
            AND   TRUNC(xdl.judgement_date)  >= xdc.start_date_active         -- �^���ƎҁF�K�p�J�n��
            AND   TRUNC(xdl.judgement_date)  <= xdc.end_date_active           -- �^���ƎҁF�K�p�I����
            AND   pay_change_flg              = gv_target_y                   -- �x���ύX�t���O
          ) xd_req
          , xxwip_delivery_lines        xdl     -- �^�����׃A�h�I��
          , xxwip_delivery_company      xdc     -- �^���p�^���Ǝ҃A�h�I���}�X�^
          , xxwip_delivery_distance     xdd     -- �z�������A�h�I���}�X�^
    WHERE xd_req.request_no              = xdl.request_no                -- �˗�No
    AND   xd_req.goods_classe            = xdd.goods_classe(+)           -- �z�������F���i�敪
    AND   xd_req.delivery_company_code   = xdd.delivery_company_code(+)  -- �z�������F�^���Ǝ�
    AND   xd_req.whs_code                = xdd.origin_shipment(+)        -- �z�������F�o�ɑq��
    AND   xd_req.code_division           = xdd.code_division(+)          -- �z�������F�R�[�h�敪
    AND   xd_req.shipping_address_code   = xdd.shipping_address_code(+)  -- �z�������F�z����R�[�h
    AND   TRUNC(xd_req.judgement_date)  >= xdd.start_date_active(+)      -- �z�������F�K�p�J�n��
    AND   TRUNC(xd_req.judgement_date)  <= xdd.end_date_active(+)        -- �z�������F�K�p�I����
    AND   xd_req.goods_classe            = xdc.goods_classe(+)           -- �^���ƎҁF���i�敪
    AND   xd_req.delivery_company_code   = xdc.delivery_company_code(+)  -- �^���ƎҁF�^���Ǝ�
    AND   TRUNC(xd_req.judgement_date)   >= xdc.start_date_active(+)     -- �^���ƎҁF�K�p�J�n��
    AND   TRUNC(xd_req.judgement_date)  <= xdc.end_date_active(+)        -- �^���ƎҁF�K�p�I����
    ORDER BY xd_req.request_no;
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_line�F���։^�����׃A�h�I�����o�F' || TO_CHAR(gt_exch_deliv_line_tab.COUNT));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
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
  END get_exch_deliv_line;
--
  /**********************************************************************************
   * Procedure Name   : set_exch_deliv_line
   * Description      : ���։^�����׃A�h�I��PL/SQL�\�i�[(A-38)
   ***********************************************************************************/
  PROCEDURE set_exch_deliv_line(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_exch_deliv_line'; -- �v���O������
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
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
    lr_ship_method_tab        xxwip_common3_pkg.ship_method_rec;        -- �z���敪
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
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
    -- �Ώۃf�[�^���̏ꍇ
    IF (gt_exch_deliv_line_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<deliv_line_loop>>
    FOR ln_index IN  gt_exch_deliv_line_tab.FIRST.. gt_exch_deliv_line_tab.LAST LOOP
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line�F%%%%%%%%%% ���� �^�����׃A�h�I�� %%%%%%%%%%�F' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line�F�˗�No�F' || gt_exch_deliv_line_tab(ln_index).request_no);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
      -- **************************************************
      -- ***  �z���敪���擾
      -- **************************************************
      xxwip_common3_pkg.get_ship_method(
        gt_exch_deliv_line_tab(ln_index).dellivary_classe,  -- �z���敪
        gt_exch_deliv_line_tab(ln_index).judgement_date,    -- ���f��
        lr_ship_method_tab,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
--
      -- *** �˗�No ***
      ue_line_request_no_tab(ln_index)    := gt_exch_deliv_line_tab(ln_index).request_no ;
--
      -- *** ���� ***
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
      -- �z�������}�X�^�����֑Ώۂ̏ꍇ
      IF (gt_exch_deliv_line_tab(ln_index).distance_chk = gv_target_y) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line�F%%% �z�������}�X�^ ���֑Ώ� %%%�F' || TO_CHAR(ln_index));
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
        -- ���[�t�����敪 = Y �̏ꍇ
        IF (gt_exch_deliv_line_tab(ln_index).small_lot_class = gv_ktg_yes) THEN
          -- ����������ݒ�
          ue_line_ditnc_tab(ln_index)  := gt_exch_deliv_line_tab(ln_index).small_distance ;
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
/***** �����ύX�ׁ̈A�R�����g�A�E�g
        -- ���i�敪 �� ���[�t   ���� 
        -- ���i�敪 �� �h�����N ���A���ڋ敪 ���� ���� �̏ꍇ
        ELSIF (
                  (gt_exch_deliv_line_tab(ln_index).goods_classe = gv_prod_class_lef)
                OR    
                  ((gt_exch_deliv_line_tab(ln_index).goods_classe = gv_prod_class_drk)
                  AND (gt_exch_deliv_line_tab(ln_index).mixed_code <> gv_target_y))
              ) THEN
          -- �ԗ�������ݒ�
          ue_line_ditnc_tab(ln_index)  := gt_exch_deliv_line_tab(ln_index).post_distance ;
--
        -- ��L�ȊO�̏ꍇ
        ELSE
--
-- ##### 20081027 Ver.1.10 ����#436�Ή� START #####
        -- �ԗ������i���ׂ͍��ڊ������������Z���Ȃ��j
--        ue_line_ditnc_tab(ln_index)  := gt_exch_deliv_line_tab(ln_index).post_distance +
--                                        gt_exch_deliv_line_tab(ln_index).consolid_add_distance;
          ue_line_ditnc_tab(ln_index)  := gt_exch_deliv_line_tab(ln_index).post_distance;
-- ##### 20081027 Ver.1.10 ����#436�Ή� END   #####
--
*****/
        -- ��L�ȊO�̏ꍇ
        ELSE
            -- �����敪���u�����v�̏ꍇ
            IF (lr_ship_method_tab.small_amount_class = gv_small_sum_yes) THEN
              -- ����������ݒ�
              ue_line_ditnc_tab(ln_index) := gt_exch_deliv_line_tab(ln_index).small_distance;
--
            -- �����敪���u�ԗ��v�̏ꍇ
            ELSE
              -- �ԗ��ċ�����ݒ�
              ue_line_ditnc_tab(ln_index) := gt_exch_deliv_line_tab(ln_index).post_distance;
            END IF;
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
        END IF;
--
        -- *** ���ۋ��� ***
        ue_line_actual_dstnc_tab(ln_index)  := gt_exch_deliv_line_tab(ln_index).actual_distance ;
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
      -- �z�������}�X�^�����֑ΏۊO�̏ꍇ�A�ݒ肳��Ă��邻�̂܂܂̒l��ݒ�
      ELSE
        -- ����
        ue_line_ditnc_tab(ln_index)         := gt_exch_deliv_line_tab(ln_index).distance;
        -- ���ۋ���
        ue_line_actual_dstnc_tab(ln_index)  := gt_exch_deliv_line_tab(ln_index).xdl_actual_distance;
--
      END IF;
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
      -- �^���Ǝ҃}�X�^�����֑Ώۂ̏ꍇ
      IF (gt_exch_deliv_line_tab(ln_index).company_chk = gv_target_y) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line�F%%% �^���Ǝ҃}�X�^ ���֑Ώ� %%%�F' || TO_CHAR(ln_index));
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
        -- *** �d�� ***
        -- ���[�t�����敪 = Y �A���A�d�ʗe�ϋ敪=�e�� �̏ꍇ
        IF (gt_exch_deliv_line_tab(ln_index).small_lot_class = gv_ktg_yes) THEN
          -- �� �~ �����d��
          ue_line_deliv_weight_tab(ln_index) := gt_exch_deliv_line_tab(ln_index).qty *
                                                gt_exch_deliv_line_tab(ln_index).small_weight;
        ELSE
          -- �d��
          ue_line_deliv_weight_tab(ln_index) := gt_exch_deliv_line_tab(ln_index).delivery_weight;
        END IF;
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
      -- �^���Ǝ҃}�X�^�����֑ΏۊO�̏ꍇ�A�ݒ肳��Ă��邻�̂܂܂̒l��ݒ�
      ELSE
        -- �d��
        ue_line_deliv_weight_tab(ln_index) := gt_exch_deliv_line_tab(ln_index).delivery_weight;
      END IF;
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line�F�˗�No        �F' || gt_exch_deliv_line_tab(ln_index).request_no           );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line�F���[�t�����敪�F' || gt_exch_deliv_line_tab(ln_index).small_lot_class      );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line�F���i�敪      �F' || gt_exch_deliv_line_tab(ln_index).goods_classe         );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line�F�d�ʗe�ϋ敪  �F' || gt_exch_deliv_line_tab(ln_index).weight_capacity_class);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line�F��          �F' || gt_exch_deliv_line_tab(ln_index).qty                  );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line�F�d��          �F' || gt_exch_deliv_line_tab(ln_index).delivery_weight      );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line�F���ڋ敪      �F' || gt_exch_deliv_line_tab(ln_index).mixed_code           );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line�F����          �F' || gt_exch_deliv_line_tab(ln_index). distance            );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line�F���ۋ���      �F' || gt_exch_deliv_line_tab(ln_index).xdl_actual_distance  );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line�F�z�������t���O�F' || gt_exch_deliv_line_tab(ln_index).distance_chk         );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line�F�^���Ǝ҃t���O�F' || gt_exch_deliv_line_tab(ln_index).company_chk          );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line�F�z�F�ԗ�����  �F' || gt_exch_deliv_line_tab(ln_index).post_distance        );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line�F�z�F��������  �F' || gt_exch_deliv_line_tab(ln_index).small_distance       );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line�F�z�F���ڋ���  �F' || gt_exch_deliv_line_tab(ln_index).consolid_add_distance);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line�F�z�F���ۋ���  �F' || gt_exch_deliv_line_tab(ln_index).actual_distance      );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_line�F�^�F�����d��  �F' || gt_exch_deliv_line_tab(ln_index).small_weight         );
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
    END LOOP deliv_line_loop;
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
  END set_exch_deliv_line;
--
  /**********************************************************************************
   * Procedure Name   : update_exch_deliv_line
   * Description      : ���։^�����׃A�h�I���ꊇ�X�V(A-39)
   ***********************************************************************************/
  PROCEDURE update_exch_deliv_line(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_exch_deliv_line'; -- �v���O������
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
    IF (ue_line_request_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * �^�����׃A�h�I�� �X�V
      -- **************************************************
      FORALL ln_index IN ue_line_request_no_tab.FIRST .. ue_line_request_no_tab.LAST
      UPDATE xxwip_delivery_lines       -- �^�����׃A�h�I��
        SET     distance                  = ue_line_ditnc_tab(ln_index)         -- ����
              , actual_distance           = ue_line_actual_dstnc_tab(ln_index)  -- ���ۋ���
              , delivery_weight           = ue_line_deliv_weight_tab(ln_index)  -- �d��
              , last_updated_by           = gn_user_id                 -- �ŏI�X�V��
              , last_update_date          = gd_sysdate                 -- �ŏI�X�V��
              , last_update_login         = gn_login_id                -- �ŏI�X�V���O�C��
              , request_id                = gn_conc_request_id         -- �v��ID
              , program_application_id    = gn_prog_appl_id            -- �ݶ��āE��۸��сE���ع����ID
              , program_id                = gn_conc_program_id         -- �R���J�����g�E�v���O����ID
              , program_update_date       = gd_sysdate                 -- �v���O�����X�V��
        WHERE  request_no = ue_line_request_no_tab(ln_index);           -- �˗�No
--
      -- **************************************************
      -- �����ݒ�
      -- **************************************************
      gn_deliv_line_ins_cnt := gn_deliv_line_ins_cnt + SQL%ROWCOUNT;
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
  END update_exch_deliv_line;
--
  /**********************************************************************************
   * Procedure Name   : get_exch_delino
   * Description      : ���։^�����׃A�h�I���Ώ۔z��No���o(A-40)
   ***********************************************************************************/
  PROCEDURE get_exch_delino(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_exch_delino'; -- �v���O������
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
    -- �^�����׃A�h�I�� �z��No���o
    BEGIN
      SELECT  xdl.delivery_no             -- �z��No
            , MAX(xdl.distance)           -- �Œ�����
            , NULL                        -- ���ۋ���
            , SUM(xdl.delivery_weight)    -- �d��
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
            , NULL                        -- �����No
            , NULL                        -- �x�����f�敪
            , NULL                        -- �o�ɓ�
            , NULL                        -- ���ɓ�
            , NULL                        -- ���f��
            , NULL                        -- ���ڋ敪
            , NULL                        -- �z���敪
            , NULL                        -- �o�ɑq�ɃR�[�h
            , NULL                        -- �z����R�[�h�敪
            , NULL                        -- �z����R�[�h
            , NULL                        -- �^�C�v
            , NULL                        -- �_��O�敪
            , NULL                        -- �U�֐�
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
      BULK COLLECT INTO gt_exch_delivno_line_tab
      FROM   xxwip_delivery_lines    xdl                -- �^�����׃A�h�I��
      WHERE  xdl.judgement_date >= gd_target_date       -- ���f�� >= ���ߓ�
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
      -- ���ׂ̐􂢑ւ������őΏۂƂȂ����˗�No�݂̂�{�����̑ΏۂƂ���
      AND    EXISTS (SELECT 'x'
                     FROM   xxwip_delivery_lines xdl_ex
                     WHERE  xdl_ex.delivery_no      = xdl.delivery_no -- �z��No
                     AND    xdl_ex.last_update_date = gd_sysdate      -- �ŏI�X�V���i���א��֎��ɍX�V�������́j
                    )
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
      GROUP BY xdl.delivery_no                          -- �z��No�i�W��j
      ORDER BY xdl.delivery_no;                         -- �z��No�i�����j
    EXCEPTION
      WHEN NO_DATA_FOUND THEN   -- *** �f�[�^�擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                              gv_xxcmn_msg_notfnd,
                                              gv_tkn_table,
                                              gv_delivery_lines,
                                              gv_tkn_key,
                                              TO_CHAR(gd_target_date,'YYYY/MM/DD HH24:MI:SS'));
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN TOO_MANY_ROWS THEN   -- *** �f�[�^�����擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                              gv_xxcmn_msg_toomny,
                                              gv_tkn_table,
                                              gv_delivery_lines,
                                              gv_tkn_key,
                                              TO_CHAR(gd_target_date,'YYYY/MM/DD HH24:MI:SS'));
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_delino�F���։^�����׃A�h�I���Ώ۔z��No���o' || TO_CHAR(gt_exch_delivno_line_tab.COUNT));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
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
  END get_exch_delino;
--
  /**********************************************************************************
   * Procedure Name   : get_exch_deliv_line_h
   * Description      : ���։^�����׃A�h�I�����o(A-41)
   ***********************************************************************************/
  PROCEDURE get_exch_deliv_line_h(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_exch_deliv_line_h'; -- �v���O������
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
    -- �Ώۃf�[�^���̏ꍇ
    IF (gt_exch_delivno_line_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<delivno_loop>>
    FOR ln_index IN  gt_exch_delivno_line_tab.FIRST.. gt_exch_delivno_line_tab.LAST LOOP
--
      -- **************************************************
      -- * �^�����׃A�h�I�� ���o
      -- **************************************************
      BEGIN
-- ##### 20080715 Ver.1.4 ST��Q#455�Ή� START #####
--        SELECT  xdl.actual_distance     -- ���ۋ���
--        INTO    gt_exch_delivno_line_tab(ln_index).actual_distance
--        FROM    xxwip_delivery_lines    xdl        -- �^�����׃A�h�I��
--        WHERE   xdl.delivery_no = gt_exch_delivno_line_tab(ln_index).delivery_no  -- �z��No
--        AND     xdl.distance    = gt_exch_delivno_line_tab(ln_index).distance;    -- ����
--      -- �Œ������Ɠ������^�����׃A�h�I���̎��ۋ����擾
        -- ���ꃌ�R�[�h�����݂���ꍇ��
        SELECT  max_deliv_line.actual_distance                      -- ���ۋ���
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
              , max_deliv_line.invoice_no                           -- �����No
              , max_deliv_line.payments_judgment_classe             -- �x�����f�敪
              , max_deliv_line.ship_date                            -- �o�ɓ�
              , max_deliv_line.arrival_date                         -- ���ɓ�
              , max_deliv_line.judgement_date                       -- ���f��
              , max_deliv_line.mixed_code                           -- ���ڋ敪
              , max_deliv_line.dellivary_classe                     -- �z���敪
              , max_deliv_line.whs_code                             -- �o�ɑq�ɃR�[�h
              , max_deliv_line.code_division                        -- �z����R�[�h�敪
              , max_deliv_line.shipping_address_code                -- �z����R�[�h
              , max_deliv_line.order_type                           -- �^�C�v
              , max_deliv_line.outside_contract                     -- �_��O�敪
              , max_deliv_line.transfer_location                    -- �U�֐�
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
        INTO    gt_exch_delivno_line_tab(ln_index).actual_distance
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
              , gt_exch_delivno_line_tab(ln_index).invoice_no               -- �����No
              , gt_exch_delivno_line_tab(ln_index).payments_judgment_classe -- �x�����f�敪
              , gt_exch_delivno_line_tab(ln_index).ship_date                -- �o�ɓ�
              , gt_exch_delivno_line_tab(ln_index).arrival_date             -- ���ɓ�
              , gt_exch_delivno_line_tab(ln_index).judgement_date           -- ���f��
              , gt_exch_delivno_line_tab(ln_index).mixed_code               -- ���ڋ敪
              , gt_exch_delivno_line_tab(ln_index).dellivary_classe         -- �z���敪
              , gt_exch_delivno_line_tab(ln_index).whs_code                 -- �o�ɑq�ɃR�[�h
              , gt_exch_delivno_line_tab(ln_index).code_division            -- �z����R�[�h�敪
              , gt_exch_delivno_line_tab(ln_index).shipping_address_code    -- �z����R�[�h
              , gt_exch_delivno_line_tab(ln_index).order_type               -- �^�C�v
              , gt_exch_delivno_line_tab(ln_index).outside_contract         -- �_��O�敪
              , gt_exch_delivno_line_tab(ln_index).transfer_location        -- �U�֐�
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
        FROM
          (
            SELECT  xdl.actual_distance           -- ���ۋ���
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
                  , xdl.invoice_no                -- �����No
                  , xdl.payments_judgment_classe  -- �x�����f�敪
                  , xdl.ship_date                 -- �o�ɓ�
                  , xdl.arrival_date              -- ���ɓ�
                  , xdl.judgement_date            -- ���f��
                  , xdl.mixed_code                -- ���ڋ敪
                  , xdl.dellivary_classe          -- �z���敪
                  , xdl.whs_code                  -- �o�ɑq�ɃR�[�h
                  , xdl.code_division             -- �z����R�[�h�敪
                  , xdl.shipping_address_code     -- �z����R�[�h
                  , xdl.order_type                -- �^�C�v
                  , xdl.outside_contract          -- �_��O�敪
                  , xdl.transfer_location         -- �U�֐�
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
            FROM    xxwip_delivery_lines    xdl                                       -- �^�����׃A�h�I��
            WHERE   xdl.delivery_no = gt_exch_delivno_line_tab(ln_index).delivery_no  -- �z��No
            AND     xdl.distance    = gt_exch_delivno_line_tab(ln_index).distance     -- ����
            ORDER BY xdl.request_no                                                   -- �˗�No�i�����j
          ) max_deliv_line
        WHERE ROWNUM = 1;
-- ##### 20080715 Ver.1.4 ST��Q#455�Ή� END   #####
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   -- *** �f�[�^�擾�G���[ ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                gv_xxcmn_msg_notfnd,
                                                gv_tkn_table,
                                                gv_delivery_lines,
                                                gv_tkn_key,
                                                gt_exch_delivno_line_tab(ln_index).delivery_no
                                                || ',' ||
                                                gt_exch_delivno_line_tab(ln_index).distance);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
        WHEN TOO_MANY_ROWS THEN   -- *** �f�[�^�����擾�G���[ ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn,
                                                gv_xxcmn_msg_toomny,
                                                gv_tkn_table,
                                                gv_delivery_lines,
                                                gv_tkn_key,
                                                gt_exch_delivno_line_tab(ln_index).delivery_no
                                                || ',' ||
                                                gt_exch_delivno_line_tab(ln_index).distance);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
    END LOOP delivno_loop;
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
  END get_exch_deliv_line_h;
--
  /**********************************************************************************
   * Procedure Name   : set_exch_deliv_line
   * Description      : ���։^���w�b�_�A�h�I�����׍��ڍX�V�pPL/SQL�\�i�[(A-42)
   ***********************************************************************************/
  PROCEDURE set_exch_deliv_head_h(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_exch_deliv_head_h'; -- �v���O������
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
    -- �Ώۃf�[�^���̏ꍇ
    IF (gt_exch_delivno_line_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<deliv_line_loop>>
    FOR ln_index IN  gt_exch_delivno_line_tab.FIRST.. gt_exch_delivno_line_tab.LAST LOOP
--
      -- �z��No
      ue_head_deliv_no_tab(ln_index)      := gt_exch_delivno_line_tab(ln_index).delivery_no;
      -- �Œ�����
      ue_head_distance_tab(ln_index)      := gt_exch_delivno_line_tab(ln_index).distance;
      -- �d�ʂP
      ue_head_deliv_wght1_tab(ln_index)   := gt_exch_delivno_line_tab(ln_index).delivery_weight;
      -- �Œ����ۋ���
      ue_head_actual_ditnc_tab(ln_index)  := gt_exch_delivno_line_tab(ln_index).actual_distance;
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
      -- �����No
      ue_head_invoice_no_tab(ln_index)    := gt_exch_delivno_line_tab(ln_index).invoice_no;
      -- �x�����f�敪
      ue_head_pay_judg_cls_tab(ln_index)  := gt_exch_delivno_line_tab(ln_index).payments_judgment_classe;
      -- �o�ɓ�
      ue_head_ship_date_tab(ln_index)     := gt_exch_delivno_line_tab(ln_index).ship_date;
      -- ���ɓ�
      ue_head_arrival_date_tab(ln_index)  := gt_exch_delivno_line_tab(ln_index).arrival_date;
      -- ���f��
      ue_head_judg_date_tab(ln_index)     := gt_exch_delivno_line_tab(ln_index).judgement_date;
      -- ���ڋ敪
      ue_head_mixed_cd_tab(ln_index)      := gt_exch_delivno_line_tab(ln_index).mixed_code;
      -- �z���敪
      ue_head_deliv_cls_tab(ln_index)     := gt_exch_delivno_line_tab(ln_index).dellivary_classe;
      -- �o�ɑq�ɃR�[�h
      ue_head_whs_cd_tab(ln_index)        := gt_exch_delivno_line_tab(ln_index).whs_code;
      -- �z����R�[�h�敪
      ue_head_cd_dvsn_tab(ln_index)       := gt_exch_delivno_line_tab(ln_index).code_division;
      -- �z����R�[�h
      ue_head_ship_addr_cd_tab(ln_index)  := gt_exch_delivno_line_tab(ln_index).shipping_address_code;
      -- �^�C�v
      ue_head_order_type_tab(ln_index)    := gt_exch_delivno_line_tab(ln_index).order_type;
      -- �_��O�敪
      ue_head_out_cont_tab(ln_index)      := gt_exch_delivno_line_tab(ln_index).outside_contract;
      -- �U�֐�
      ue_head_trans_lcton_tab(ln_index)   := gt_exch_delivno_line_tab(ln_index).transfer_location;
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h�F%%%%%%%%%% ���։^���w�b�_�A�h�I�����׍��� %%%%%%%%%%�F' || TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h�F�z��No          �F' || gt_exch_delivno_line_tab(ln_index).delivery_no);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h�F����            �F' || gt_exch_delivno_line_tab(ln_index).distance);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h�F���ۋ���        �F' || gt_exch_delivno_line_tab(ln_index).actual_distance);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h�F�d��            �F' || gt_exch_delivno_line_tab(ln_index).delivery_weight);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h�F�����No        �F' || gt_exch_delivno_line_tab(ln_index).invoice_no);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h�F�x�����f�敪    �F' || gt_exch_delivno_line_tab(ln_index).payments_judgment_classe );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h�F�o�ɓ�          �F' || gt_exch_delivno_line_tab(ln_index).ship_date);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h�F���ɓ�          �F' || gt_exch_delivno_line_tab(ln_index).arrival_date);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h�F���f��          �F' || gt_exch_delivno_line_tab(ln_index).judgement_date);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h�F���ڋ敪        �F' || gt_exch_delivno_line_tab(ln_index).mixed_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h�F�z���敪        �F' || gt_exch_delivno_line_tab(ln_index).dellivary_classe);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h�F�o�ɑq�ɃR�[�h  �F' || gt_exch_delivno_line_tab(ln_index).whs_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h�F�z����R�[�h�敪�F' || gt_exch_delivno_line_tab(ln_index).code_division);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h�F�z����R�[�h    �F' || gt_exch_delivno_line_tab(ln_index).shipping_address_code);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h�F�^�C�v          �F' || gt_exch_delivno_line_tab(ln_index).order_type);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h�F�_��O�敪      �F' || gt_exch_delivno_line_tab(ln_index).outside_contract);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_head_h�F�U�֐�          �F' || gt_exch_delivno_line_tab(ln_index).transfer_location);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
    END LOOP deliv_line_loop;
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
  END set_exch_deliv_head_h;
--
  /**********************************************************************************
   * Procedure Name   : update_exch_deliv_head_h
   * Description      : ���։^���w�b�_�A�h�I�����׍��ڈꊇ�X�V(A-43)
   ***********************************************************************************/
  PROCEDURE update_exch_deliv_head_h(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_exch_deliv_head_h'; -- �v���O������
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
    -- **************************************************
    -- * �^���w�b�_�A�h�I�� �X�V
    -- **************************************************
    FORALL ln_index IN ue_head_deliv_no_tab.FIRST .. ue_head_deliv_no_tab.LAST
      UPDATE xxwip_deliverys          -- �^���w�b�_�A�h�I��
      SET     distance                  = ue_head_distance_tab(ln_index)       -- �Œ�����
            , delivery_weight1          = ue_head_deliv_wght1_tab(ln_index)    -- �d�ʂP
            , actual_distance           = ue_head_actual_ditnc_tab(ln_index)   -- �Œ����ۋ���
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
            , invoice_no                = ue_head_invoice_no_tab(ln_index)     -- �����No
            , payments_judgment_classe  = ue_head_pay_judg_cls_tab(ln_index)   -- �x�����f�敪
            , ship_date                 = ue_head_ship_date_tab(ln_index)      -- �o�ɓ�
            , arrival_date              = ue_head_arrival_date_tab(ln_index)   -- ���ɓ�
            , judgement_date            = ue_head_judg_date_tab(ln_index)      -- ���f��
            , mixed_code                = ue_head_mixed_cd_tab(ln_index)       -- ���ڋ敪
            , delivery_classe           = ue_head_deliv_cls_tab(ln_index)      -- �z���敪
            , whs_code                  = ue_head_whs_cd_tab(ln_index)         -- �o�ɑq�ɃR�[�h
            , code_division             = ue_head_cd_dvsn_tab(ln_index)        -- �z����R�[�h�敪
            , shipping_address_code     = ue_head_ship_addr_cd_tab(ln_index)   -- �z����R�[�h
            , order_type                = ue_head_order_type_tab(ln_index)     -- �^�C�v
            , outside_contract          = ue_head_out_cont_tab(ln_index)       -- �_��O�敪
            , transfer_location         = ue_head_trans_lcton_tab(ln_index)    -- �U�֐�
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
            , last_updated_by           = gn_user_id                  -- �ŏI�X�V��
            , last_update_date          = gd_sysdate                  -- �ŏI�X�V��
            , last_update_login         = gn_login_id                 -- �ŏI�X�V���O�C��
            , request_id                = gn_conc_request_id          -- �v��ID
            , program_application_id    = gn_prog_appl_id             -- �ݶ��āE��۸��сE���ع����ID
            , program_id                = gn_conc_program_id          -- �R���J�����g�E�v���O����ID
            , program_update_date       = gd_sysdate                  -- �v���O�����X�V��
      WHERE  delivery_no = ue_head_deliv_no_tab(ln_index)             -- �z��No
      AND    p_b_classe  = gv_pay ;                                   -- �x�������敪�i�x���j
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
  END update_exch_deliv_head_h;
--
  /**********************************************************************************
   * Procedure Name   : get_exch_deliv_head
   * Description      : ���։^���w�b�_�A�h�I�����o(A-44)
   ***********************************************************************************/
  PROCEDURE get_exch_deliv_head(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_exch_deliv_head'; -- �v���O������
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
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
/***** SQL������
    -- �^���w�b�_�A�h�I�� ���o
    SELECT    xd.delivery_company_code  -- �^���Ǝ�
            , xd.delivery_no            -- �z��No
            , xd.p_b_classe             -- �x�������敪
            , xd.judgement_date         -- ���f��
            , xd.goods_classe           -- ���i�敪
            , xd.mixed_code             -- ���ڋ敪
            , xd.charged_amount         -- �����^��
            , xd.many_rate              -- ������
            , xd.distance               -- �Œ�����
            , xd.delivery_classe        -- �z���敪
            , xd.qty1                   -- ���P
            , xd.delivery_weight1       -- �d�ʂP
            , xd.consolid_surcharge     -- ���ڊ������z
            , xd.consolid_qty           -- ���ڐ�
            , xd.output_flag            -- ���ً敪
            , xd.defined_flag           -- �x���m��敪
            , xd.return_flag            -- �x���m���
            , NVL(xdec.pay_picking_amount, 0) -- �^���ƎҁF�x���s�b�L���O�P��
            , NULL                            -- �^���F�^����
            , NULL                            -- �^���F���[�t���ڊ���
--2008/08/04 Add 
            , xd.actual_distance        -- �Œ����ۋ���
            , xd.whs_code               -- ��\�o�ɑq�ɃR�[�h
            , xd.code_division          -- ��\�z����R�[�h�敪
            , xd.shipping_address_code  -- ��\�z����R�[�h
            , xd.dispatch_type          -- �z�ԃ^�C�v
--2008/08/04 Add ��
    BULK COLLECT INTO gt_exch_deliv_tab
    FROM  xxwip_deliverys         xd,   -- �^���w�b�_�A�h�I��
          xxwip_delivery_company  xdec  -- �^���p�^���Ǝ҃A�h�I���}�X�^
    WHERE xd.p_b_classe = gv_pay                      -- �x�������敪�i�x���j
    AND   xd.judgement_date >= gd_target_date         -- ���f�� >= ���ߓ�
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 START #####
--    AND   xd.goods_classe IS NOT NULL                 -- ���i�敪
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
***** �`�[�Ȃ��z�Ԃ͑S�čČv�Z�ΏۂƂ���
    AND   xd.dispatch_type          IN (gv_car_normal, gv_carcan_target_y)  -- �z�ԃ^�C�v
                                                                            --   1�F�ʏ�z��
                                                                            --   2�F�`�[�Ȃ��z�ԁi���[�t�����j
*****
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 END   #####
    AND   xd.goods_classe           = xdec.goods_classe(+)          -- ���i�敪
    AND   xd.delivery_company_code  = xdec.delivery_company_code(+) -- �^���Ǝ�
    AND   TRUNC(xd.judgement_date) >= xdec.start_date_active(+)     -- �K�p�J�n��
    AND   TRUNC(xd.judgement_date) <= xdec.end_date_active(+)       -- �K�p�I����
    ORDER BY delivery_no;
*****/
    -- �^���w�b�_�A�h�I�� ���o
    SELECT    xd.delivery_company_code  -- �^���Ǝ�
            , xd.delivery_no            -- �z��No
            , xd.p_b_classe             -- �x�������敪
            , xd.ship_date              -- �o�ɓ�
            , xd.judgement_date         -- ���f��
            , xd.goods_classe           -- ���i�敪
            , xd.mixed_code             -- ���ڋ敪
            , xd.charged_amount         -- �����^��
            , xd.many_rate              -- ������
            , xd.distance               -- �Œ�����
            , xd.delivery_classe        -- �z���敪
            , xd.qty1                   -- ���P
            , xd.delivery_weight1       -- �d�ʂP
            , xd.consolid_surcharge     -- ���ڊ������z
            , xd.consolid_qty           -- ���ڐ�
            , xd.output_flag            -- ���ً敪
            , xd.defined_flag           -- �x���m��敪
            , xd.return_flag            -- �x���m���
            , xd.actual_distance        -- �Œ����ۋ���
            , xd.whs_code               -- ��\�o�ɑq�ɃR�[�h
            , xd.code_division          -- ��\�z����R�[�h�敪
            , xd.shipping_address_code  -- ��\�z����R�[�h
            , xd.dispatch_type          -- �z�ԃ^�C�v
            , xd.picking_charge         -- �x���s�b�L���O��
            , xd.contract_rate          -- �_��^��
            , xd.last_update_date       -- �ŏI�X�V��
            , NULL                      -- �^���F�x���s�b�L���O�P��
            , NULL                      -- �^���F�x���ύX�t���O
            , NULL                      -- �z���敪�F�����敪
            , NULL                      -- �z���F�ԗ�����
            , NULL                      -- �z���F��������
            , NULL                      -- �z���F���ڋ���
            , NULL                      -- �z���F���ۋ���
            , NULL                      -- �z���F�ύX�t���O
            , NULL                      -- �^���F�^����
            , NULL                      -- �^���F���[�t���ڊ���
            , NULL                      -- �^���F�^���ύX�t���O
            , NULL                      -- �^���F���ڕύX�t���O
    BULK COLLECT INTO gt_exch_deliv_tab
    FROM  xxwip_deliverys         xd    -- �^���w�b�_�A�h�I��
    WHERE xd.p_b_classe = gv_pay                      -- �x�������敪�i�x���j
    AND   xd.judgement_date >= gd_target_date         -- ���f�� >= ���ߓ�
    ORDER BY delivery_no;
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
    IF (gv_debug_flg = gv_debug_on) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_head�F���։^���w�b�_�A�h�I�����o�F' || TO_CHAR(gt_exch_deliv_tab.COUNT));
    END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
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
  END get_exch_deliv_head;
--
  /**********************************************************************************
   * Procedure Name   : get_exch_deliv_charg
   * Description      : ���։^���A�h�I���}�X�^���o(A-45)
   ***********************************************************************************/
  PROCEDURE get_exch_deliv_charg(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_exch_deliv_charg'; -- �v���O������
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
    lr_delivery_charges_tab   xxwip_common3_pkg.delivery_charges_rec;   -- �^��
--2008/08/04 Add ��
    lr_delivery_distance_tab  xxwip_common3_pkg.delivery_distance_rec;  -- �z������
--2008/08/04 Add ��
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
    lr_delivery_company_tab   xxwip_common3_pkg.delivery_company_rec;   -- �^���p�^���Ǝ�
    lr_ship_method_tab        xxwip_common3_pkg.ship_method_rec;        -- �z���敪
--
    lt_actual_distance        xxwip_delivery_lines.actual_distance%TYPE;-- �Œ����ۋ���
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
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
    -- �Ώۃf�[�^���̏ꍇ
    IF (gt_exch_deliv_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<deliv_loop>>
    FOR ln_index IN  gt_exch_deliv_tab.FIRST.. gt_exch_deliv_tab.LAST LOOP
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
      -- **************************************************
      -- ***  �^���p�^���Ǝ҃A�h�I���}�X�^���o
      -- **************************************************
      xxwip_common3_pkg.get_delivery_company(
        gt_exch_deliv_tab(ln_index).goods_classe,           -- ���i�敪
        gt_exch_deliv_tab(ln_index).delivery_company_code,  -- �^���Ǝ�
        gt_exch_deliv_tab(ln_index).judgement_date,         -- ���f��
        lr_delivery_company_tab,                            -- �^���p�^���Ǝ҃��R�[�h
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ***** �x���s�b�L���O�P���ݒ� *****
      gt_exch_deliv_tab(ln_index).pay_picking_amount  := lr_delivery_company_tab.pay_picking_amount;
      -- ***** �x���ύX�t���O *****
      gt_exch_deliv_tab(ln_index).pay_change_flg      := lr_delivery_company_tab.pay_change_flg;
--
      -- **************************************************
      -- ***  �z���敪���擾
      -- **************************************************
      xxwip_common3_pkg.get_ship_method(
        gt_exch_deliv_tab(ln_index).delivery_classe,  -- �z���敪
        gt_exch_deliv_tab(ln_index).judgement_date,   -- ���f��
        lr_ship_method_tab,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ***** �����敪 *****
      gt_exch_deliv_tab(ln_index).small_amount_class  := lr_ship_method_tab.small_amount_class;
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
--
--2008/08/04 Add ��
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
--      IF (gt_exch_deliv_tab(ln_index).dispatch_type = gv_carcan_target_y) THEN
-- ##### 20081027 Ver.1.10 ����#436�Ή� START #####
      -- �S�ẴP�[�X�ɂ����Ď擾������
--      IF (gt_exch_deliv_tab(ln_index).dispatch_type IN (gv_carcan_target_y, 
--                                                        gv_carcan_target_n)) THEN
-- ##### 20081027 Ver.1.10 ����#436�Ή� END   #####
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
      -- **************************************************
      -- ***  �z�������A�h�I���}�X�^���o
      -- **************************************************
      xxwip_common3_pkg.get_delivery_distance(
        gt_exch_deliv_tab(ln_index).goods_classe,           -- ���i�敪
        gt_exch_deliv_tab(ln_index).delivery_company_code,  -- �^���Ǝ�
        gt_exch_deliv_tab(ln_index).whs_code,               -- �o�ɑq��
        gt_exch_deliv_tab(ln_index).code_division,          -- �R�[�h�敪
        gt_exch_deliv_tab(ln_index).shipping_address_code,  -- �z����R�[�h
        gt_exch_deliv_tab(ln_index).judgement_date,         -- ���f��
        lr_delivery_distance_tab,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
/***** �����֌W�Ȃ��ݒ肷��悤�ɏC��
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
--        gt_exch_deliv_tab(ln_index).distance        := lr_delivery_distance_tab.small_distance;
        -- �`�[�Ȃ��z�ԁi���[�t�����j�̏ꍇ
        IF (gt_exch_deliv_tab(ln_index).dispatch_type = gv_carcan_target_y) THEN
          -- ����������ݒ�
          gt_exch_deliv_tab(ln_index).distance        := lr_delivery_distance_tab.small_distance;
--
        -- �`�[�Ȃ��z�ԁi���[�t�����ȊO�j�̏ꍇ
-- ##### 20081027 Ver.1.10 ����#436�Ή� START #####
--        ELSE
        ELSIF (gt_exch_deliv_tab(ln_index).dispatch_type = gv_carcan_target_n) THEN
-- ##### 20081027 Ver.1.10 ����#436�Ή� END   #####
          -- �ԗ�������ݒ�
          gt_exch_deliv_tab(ln_index).distance        := lr_delivery_distance_tab.post_distance;
--
-- ##### 20081027 Ver.1.10 ����#436�Ή� START #####
        -- �ʏ�z�Ԃ̏ꍇ
        ELSIF (gt_exch_deliv_tab(ln_index).dispatch_type = gv_car_normal) THEN
          -- ���i�敪���u�h�����N�v�����ڋ敪���u���ځv�̏ꍇ
          IF ((gt_exch_deliv_tab(ln_index).goods_classe = gv_prod_class_drk )
            AND (gt_exch_deliv_tab(ln_index).mixed_code = gv_target_y )) THEN
--
            -- �ԗ������{���ڊ�������
            gt_exch_deliv_tab(ln_index).distance := lr_delivery_distance_tab.post_distance +
                                                    lr_delivery_distance_tab.consolid_add_distance ;
          END IF;
--
          -- ��L�Őݒ肵�������ȊO�͊��ɐݒ肳��Ă���Œ������ōX�V����
-- ##### 20081027 Ver.1.10 ����#436�Ή� END   #####
--
        END IF;
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
        -- �Œ����ۋ���
        gt_exch_deliv_tab(ln_index).actual_distance := lr_delivery_distance_tab.actual_distance;
-- ##### 20081027 Ver.1.10 ����#436�Ή� START #####
--      END IF;
-- ##### 20081027 Ver.1.10 ����#436�Ή� END   #####
--2008/08/04 Add ��
*****/
      -- ***** �ԗ����� *****
      gt_exch_deliv_tab(ln_index).post_distance         := lr_delivery_distance_tab.post_distance;
      -- ***** �������� *****
      gt_exch_deliv_tab(ln_index).small_distance        := lr_delivery_distance_tab.small_distance;
      -- ***** ���ڋ��� *****
      gt_exch_deliv_tab(ln_index).consolid_add_distance := lr_delivery_distance_tab.consolid_add_distance;
      -- ***** ���ۋ��� *****
      gt_exch_deliv_tab(ln_index).actual_distance       := lr_delivery_distance_tab.actual_distance;
      -- ***** �ύX�t���O *****
      gt_exch_deliv_tab(ln_index).distance_change_flg   := lr_delivery_distance_tab.change_flg;
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
--
      -- **************************************************
      -- * �^���A�h�I���}�X�^���o
      -- **************************************************
      -- ���i�敪 = �u�h�����N�v���A���ڋ敪 = �u���ځv�̏ꍇ
      IF  ((gt_exch_deliv_tab(ln_index).goods_classe = gv_prod_class_drk)
        AND(gt_exch_deliv_tab(ln_index).mixed_code   = gv_target_y      )) THEN
        -- �ԗ������{���ڊ�������
        lt_actual_distance := gt_exch_deliv_tab(ln_index).post_distance +
                                                gt_exch_deliv_tab(ln_index).consolid_add_distance;
      ELSE
--
        -- �`�[�Ȃ��z�ԁi���[�t�����j�̏ꍇ
        IF (gt_exch_deliv_tab(ln_index).dispatch_type = gv_carcan_target_y) THEN
          lt_actual_distance := gt_exch_deliv_tab(ln_index).distance;
--
        -- �`�[�Ȃ��z�ԁi���[�t�����ȊO�j�̏ꍇ
        ELSIF (gt_exch_deliv_tab(ln_index).dispatch_type = gv_carcan_target_n) THEN
--
          -- �����敪 =�u�����v�̏ꍇ
          IF (gt_exch_deliv_tab(ln_index).small_amount_class = gv_small_sum_yes) THEN
            -- ����������ݒ�
            lt_actual_distance := gt_exch_deliv_tab(ln_index).small_distance;
--
          -- �����敪 =�u�ԗ��v�̏ꍇ
          ELSE
            -- �ԗ�������ݒ�
            lt_actual_distance := gt_exch_deliv_tab(ln_index).post_distance;
          END IF;
--
        -- �ʏ�z�Ԃ̏ꍇ
        ELSE
          -- �ύX���ׁ̈A�擾�����Œ�������ݒ�
          lt_actual_distance := gt_exch_deliv_tab(ln_index).distance;
        END IF;
      END IF;
--
      xxwip_common3_pkg.get_delivery_charges(
        gt_exch_deliv_tab(ln_index).p_b_classe,             -- �x�������敪
        gt_exch_deliv_tab(ln_index).goods_classe,           -- ���i�敪
        gt_exch_deliv_tab(ln_index).delivery_company_code,  -- �^���Ǝ�
        gt_exch_deliv_tab(ln_index).delivery_classe,        -- �z���敪
        lt_actual_distance,                                 -- �^������
        gt_exch_deliv_tab(ln_index).delivery_weight1,       -- �d��
        gt_exch_deliv_tab(ln_index).judgement_date,         -- ���f��
        lr_delivery_charges_tab,                            -- �^���A�h�I�����R�[�h
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- *** �^���� ***
      gt_exch_deliv_tab(ln_index).shipping_expenses := lr_delivery_charges_tab.shipping_expenses;
      -- *** ���[�t���ڊ��� ***
      gt_exch_deliv_tab(ln_index).leaf_consolid_add := lr_delivery_charges_tab.leaf_consolid_add;
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
      -- *** �^���E�ύX�t���O ***
      gt_exch_deliv_tab(ln_index).charg_shp_change_flg := lr_delivery_charges_tab.shipping_change_flg;
      -- *** ���ځE�ύX�t���O ***
      gt_exch_deliv_tab(ln_index).charg_lrf_change_flg := lr_delivery_charges_tab.leaf_change_flg;
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        -- �^���ƎҁA�z�������A�^���}�X�^�̕ύX�t���O��'1'�̏ꍇ��PL/SQL�\�֊i�[����
        IF  (( gt_exch_deliv_tab(ln_index).pay_change_flg       = gv_target_y )
          OR ( gt_exch_deliv_tab(ln_index).distance_change_flg  = gv_target_y )
          OR ( gt_exch_deliv_tab(ln_index).charg_shp_change_flg = gv_target_y )
          OR ( gt_exch_deliv_tab(ln_index).charg_lrf_change_flg = gv_target_y )) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg�F********** ���։^���A�h�I���}�X�^���o(�Ώۂ̂�) **********�F'|| TO_CHAR(ln_index));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg�F�^���ƎҁF' || gt_exch_deliv_tab(ln_index).delivery_company_code);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg�F�z��No  �F' || gt_exch_deliv_tab(ln_index).delivery_no);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg�F�x���s�b�L���O�P���F' || gt_exch_deliv_tab(ln_index).pay_picking_amount);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg�F�x���ύX�t���O    �F' || gt_exch_deliv_tab(ln_index).pay_change_flg);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg�F�����敪          �F' || gt_exch_deliv_tab(ln_index).small_amount_class);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg�F�ԗ�����          �F' || gt_exch_deliv_tab(ln_index).post_distance);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg�F��������          �F' || gt_exch_deliv_tab(ln_index).small_distance);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg�F���ڋ���          �F' || gt_exch_deliv_tab(ln_index).consolid_add_distance);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg�F���ۋ���          �F' || gt_exch_deliv_tab(ln_index).actual_distance);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg�F���� �ύX�t���O   �F' || gt_exch_deliv_tab(ln_index).distance_change_flg);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg�F�^����            �F' || gt_exch_deliv_tab(ln_index).shipping_expenses);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg�F���[�t���ڊ���    �F' || gt_exch_deliv_tab(ln_index).leaf_consolid_add);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg�F�^�� �ύX�t���O   �F' || gt_exch_deliv_tab(ln_index).charg_shp_change_flg);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'get_exch_deliv_charg�F���� �ύX�t���O   �F' || gt_exch_deliv_tab(ln_index).charg_lrf_change_flg);
        END IF;
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
    END LOOP deliv_loop;
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
  END get_exch_deliv_charg;
--
  /**********************************************************************************
   * Procedure Name   : set_exch_deliv_hate
   * Description      : ���։^���w�b�_�A�h�I��PL/SQL�\�i�[(A-46)
   ***********************************************************************************/
  PROCEDURE set_exch_deliv_hate(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_exch_deliv_hate'; -- �v���O������
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
    ln_delete_cnt   NUMBER;       -- �폜����
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
    ln_target_cnt   NUMBER;       -- ���֑Ώی���
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
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
    -- �ϐ�������
    ln_delete_cnt := 0 ;
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
    ln_target_cnt := 0 ;
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
--
    -- �Ώۃf�[�^���̏ꍇ
    IF (gt_exch_deliv_tab.COUNT = 0) THEN
      RETURN;
    END IF;
--
    <<deliv_loop>>
    FOR ln_index IN  gt_exch_deliv_tab.FIRST.. gt_exch_deliv_tab.LAST LOOP
--
      -- **************************************************
      -- * �X�V�pPL/SQL�\ �ݒ�
      -- **************************************************
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
/***** PL/SQL�\�i�[�����S�ʕύX�̈׃R�����g�A�E�g
      -- �z��No
      ueh_head_deliv_no_tab(ln_index)       := gt_exch_deliv_tab(ln_index).delivery_no ;
      -- �_��^��
      ueh_head_contract_rate_tab(ln_index)  := gt_exch_deliv_tab(ln_index).shipping_expenses ;
--
      -- *** ���ڊ������z ***
      -- ���i�敪 = ���[�t�A���A���ڋ敪 = ���� �̏ꍇ
      IF ((gt_exch_deliv_tab(ln_index).goods_classe = gv_prod_class_lef )
        AND (gt_exch_deliv_tab(ln_index).mixed_code = gv_target_y)) THEN
        -- ���[�t���ڊ��� �~ ���ڐ�
        ueh_head_cnsld_srhrg_tab(ln_index)  := gt_exch_deliv_tab(ln_index).leaf_consolid_add *
                                                  gt_exch_deliv_tab(ln_index).consolid_qty;
      ELSE
        -- ���ڊ������z
        ueh_head_cnsld_srhrg_tab(ln_index)  := gt_exch_deliv_tab(ln_index).consolid_surcharge;
      END IF;
--
      -- *** �s�b�L���O�� ***
      -- �� �~ �x���s�b�L���O�P��
-- ##### 20080715 Ver.1.3 ST��Q#452�Ή� START #####
--      ueh_head_pick_charge_tab(ln_index)  := ROUND(gt_exch_deliv_tab(ln_index).qty1 *
--                                              gt_exch_deliv_tab(ln_index).pay_picking_amount);
      ueh_head_pick_charge_tab(ln_index)  := CEIL(gt_exch_deliv_tab(ln_index).qty1 *
                                              gt_exch_deliv_tab(ln_index).pay_picking_amount);
-- ##### 20080715 Ver.1.3 ST��Q#452�Ή� END   #####
--
      -- *** ���v ***
      -- �_��^���{���ڊ������z�{�s�b�L���O���{������
      ueh_head_total_amount_tab(ln_index) :=  gt_exch_deliv_tab(ln_index).shipping_expenses +
-- ##### 20081107 Ver.1.12 ����#584�Ή� START #####
--                                              gt_exch_deliv_tab(ln_index).consolid_surcharge +
                                              ueh_head_cnsld_srhrg_tab(ln_index) +
-- ##### 20081107 Ver.1.12 ����#584�Ή� END   #####
                                              ueh_head_pick_charge_tab(ln_index) +
                                              NVL(gt_exch_deliv_tab(ln_index).many_rate,0);
--
      -- *** ���z ***
      -- �����^���|���v
      ueh_head_balance_tab(ln_index)  :=  NVL(gt_exch_deliv_tab(ln_index).charged_amount, 0) -
                                            ueh_head_total_amount_tab(ln_index);
--
      -- *** ���ً敪 ***
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
*****
      -- �����^�� = NULL�̏ꍇ
      IF (gt_exch_deliv_tab(ln_index).charged_amount IS NULL) THEN
        -- Y ��ݒ�
        ueh_head_output_flag_tab(ln_index) := gv_ktg_yes ;
--
      -- �����^�� <> NULL�A���A���z = 0�ꍇ
      ELSIF ((gt_exch_deliv_tab(ln_index).charged_amount IS NOT NULL)
        AND  (ueh_head_balance_tab(ln_index) = 0)) THEN
        -- N ��ݒ�
        ueh_head_output_flag_tab(ln_index) := gv_ktg_no ;
--
      -- ��L�ȊO�̏ꍇ
      ELSE
        -- Y ��ݒ�
        ueh_head_output_flag_tab(ln_index) := gv_ktg_yes ;
      END IF;
*****
      -- ���z���O�̏ꍇ
      IF (ueh_head_balance_tab(ln_index) <> 0) THEN
        ueh_head_output_flag_tab(ln_index) := gv_ktg_yes ;
      -- ���z���O�̏ꍇ
      ELSE
        ueh_head_output_flag_tab(ln_index) := gv_ktg_no ;
      END IF;
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
--
      -- *** �x���m��敪 ***
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
*****
      -- ���ً敪 = N �̏ꍇ
      IF (ueh_head_output_flag_tab(ln_index) = gv_ktg_no) THEN
        ueh_head_defined_flag_tab(ln_index) :=  gv_ktg_yes;
--
      -- ���ً敪 = Y �̏ꍇ
      ELSE
        ueh_head_defined_flag_tab(ln_index) :=  gv_ktg_no;
      END IF;
*****
      -- �������z��NULL
      IF (gt_exch_deliv_tab(ln_index).charged_amount IS NULL) THEN
        ueh_head_defined_flag_tab(ln_index) :=  gv_ktg_no;
      -- ���ً敪��YES
      ELSIF (ueh_head_output_flag_tab(ln_index) = gv_ktg_yes) THEN
        ueh_head_defined_flag_tab(ln_index) :=  gv_ktg_no;
      -- ���ً敪��NO
      ELSE
        ueh_head_defined_flag_tab(ln_index) :=  gv_ktg_yes;
      END IF;
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
--
      -- *** �x���m��� ***
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� START #####
*****
      -- ���̎x���m��敪 = Y ���� �ݒ肷��x���m��敪 = N �̏ꍇ
      IF ((gt_exch_deliv_tab(ln_index).defined_flag = gv_ktg_yes )
        AND (ueh_head_defined_flag_tab(ln_index) = gv_ktg_no)) THEN
        -- Y ��ݒ�
        ueh_head_return_flag_tab(ln_index)  := gv_ktg_yes ;
--
      -- ��L�ȊO�̏ꍇ
      ELSE
        -- N ��ݒ�
        ueh_head_return_flag_tab(ln_index)  := gv_ktg_no ;
      END IF;
*****
      -- ���̎x���m��敪 = Y �̏ꍇ
      IF (gt_exch_deliv_tab(ln_index).defined_flag = gv_ktg_yes ) THEN
        ueh_head_return_flag_tab(ln_index)  := gv_ktg_yes ;
      -- ���̎x���m��敪 = N �̏ꍇ
      ELSE
        ueh_head_return_flag_tab(ln_index)  := gv_ktg_no ;
      END IF;
-- ##### 20080912 Ver.1.8 TE080�w�E����15�Ή� �敪�ݒ茩���Ή� END   #####
--
--2008/08/04 Add ��
      ueh_head_distance_type_tab(ln_index)     := gt_exch_deliv_tab(ln_index).distance;
      ueh_head_actual_ditnc_type_tab(ln_index) := gt_exch_deliv_tab(ln_index).actual_distance;
--2008/08/04 Add ��
--
      -- **************************************************
      -- * �폜�pPL/SQL�\ �ݒ�
      -- **************************************************
      -- ���ً敪 = Y �̏ꍇ
      IF (ueh_head_output_flag_tab(ln_index) = gv_ktg_yes) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_hate�F********** ���� �폜�pPL/SQL�\ �ݒ� **********�F'|| TO_CHAR(ln_index));
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_hate�F�z��No�F' || gt_exch_deliv_tab(ln_index).delivery_no);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        --�폜�p PL/SQL�\�ɐݒ�
        ln_delete_cnt := ln_delete_cnt + 1;
        deh_head_deliv_no_tab(ln_delete_cnt) := gt_exch_deliv_tab(ln_index).delivery_no;
      END IF;
--
*****/
      -- �^���ƎҁA�z�������A�^���}�X�^�̕ύX�t���O��'1'�̏ꍇ��PL/SQL�\�֊i�[����
      IF  (( gt_exch_deliv_tab(ln_index).pay_change_flg      = gv_target_y )
        OR ( gt_exch_deliv_tab(ln_index).distance_change_flg = gv_target_y )
        OR ( gt_exch_deliv_tab(ln_index).charg_shp_change_flg = gv_target_y )
        OR ( gt_exch_deliv_tab(ln_index).charg_lrf_change_flg = gv_target_y )) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
      IF (gv_debug_flg = gv_debug_on) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_hate�F���֑Ώ�  �z��No�F' || gt_exch_deliv_tab(ln_index).delivery_no);
      END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
        -- �Ώی��� �J�E���gUP
        ln_target_cnt := ln_target_cnt + 1;
--
        -- ***** �z��No *****
        ueh_head_deliv_no_tab(ln_target_cnt) := gt_exch_deliv_tab(ln_index).delivery_no ;
--
        -- ***** �x���s�b�L���O�� *****
        -- �^���p�^���Ǝ҃}�X�^ �x���ύX�t���O = '1'�̏ꍇ
        IF (gt_exch_deliv_tab(ln_index).pay_change_flg = gv_target_y) THEN
          -- �� �~ �x���s�b�L���O�P��
          ueh_head_pick_charge_tab(ln_target_cnt)  := CEIL(gt_exch_deliv_tab(ln_index).qty1 *
                                                      gt_exch_deliv_tab(ln_index).pay_picking_amount);
--
        -- �^���p�^���Ǝ҃}�X�^ �x���ύX�t���O = '1'�ȊO�̏ꍇ
        ELSE
          -- �擾�����A�x���s�b�L���O����ݒ�
          ueh_head_pick_charge_tab(ln_target_cnt)  := gt_exch_deliv_tab(ln_index).picking_charge;
        END IF;
--
--
        -- ***** �����E���ۋ��� *****
        -- �z�������}�X�^ �ύX�t���O = '1'�̏ꍇ
        IF  ((gt_exch_deliv_tab(ln_index).distance_change_flg = gv_target_y)
          OR (gt_exch_deliv_tab(ln_index).last_update_date    = gd_sysdate )) THEN
--
          -- �`�[�Ȃ��z�ԁi���[�t�����j�̏ꍇ
          IF (gt_exch_deliv_tab(ln_index).dispatch_type = gv_carcan_target_y) THEN
            -- ����������ݒ�
            ueh_head_distance_type_tab(ln_target_cnt) := gt_exch_deliv_tab(ln_index).small_distance;
--
          -- �`�[�Ȃ��z�ԁi���[�t�����ȊO�j�̏ꍇ
          ELSIF (gt_exch_deliv_tab(ln_index).dispatch_type = gv_carcan_target_n) THEN
--
            -- �����敪 = �u�����v �̏ꍇ
            IF (gt_exch_deliv_tab(ln_index).small_amount_class = gv_small_sum_yes ) THEN
              -- ����������ݒ�
              ueh_head_distance_type_tab(ln_target_cnt) := gt_exch_deliv_tab(ln_index).small_distance;
--
            -- �����敪 = �u�ԗ��v �̏ꍇ
            ELSE
              -- �ԗ�������ݒ�
              ueh_head_distance_type_tab(ln_target_cnt) := gt_exch_deliv_tab(ln_index).post_distance;
            END IF;
--
            -- �ԗ�������ݒ�
            ueh_head_distance_type_tab(ln_target_cnt) := gt_exch_deliv_tab(ln_index).post_distance;
--
          -- �ʏ�z�Ԃ̏ꍇ
          ELSIF (gt_exch_deliv_tab(ln_index).dispatch_type = gv_car_normal) THEN
--
            -- ���i�敪 = �u�h�����N�v���A���ڋ敪 = �u���ځv�̏ꍇ
            IF ((gt_exch_deliv_tab(ln_index).goods_classe = gv_prod_class_drk)
             AND(gt_exch_deliv_tab(ln_index).mixed_code   = gv_target_y      )) THEN
              -- �ԗ������{���ڊ�������
              ueh_head_distance_type_tab(ln_target_cnt) := gt_exch_deliv_tab(ln_index).post_distance +
                                                      gt_exch_deliv_tab(ln_index).consolid_add_distance;
            ELSE
              -- �ύX���ׁ̈A�擾�����Œ�������ݒ�
              ueh_head_distance_type_tab(ln_target_cnt) := gt_exch_deliv_tab(ln_index).distance;
            END IF;
--
          END IF;
          -- ���ۋ�����ݒ�
          ueh_head_actual_ditnc_type_tab(ln_target_cnt) := gt_exch_deliv_tab(ln_index).dis_actual_distance;
--
        -- �z�������}�X�^ �ύX�t���O = '1'�ȊO�̏ꍇ
        ELSE
          -- �ύX���ׁ̈A�擾�����Œ������A���ۍŒ�������ݒ�
          ueh_head_distance_type_tab(ln_target_cnt)     := gt_exch_deliv_tab(ln_index).distance;
          ueh_head_actual_ditnc_type_tab(ln_target_cnt) := gt_exch_deliv_tab(ln_index).actual_distance;
        END IF;
--
--
        -- ***** �_��^���E���ڊ������z *****
        -- �z�������}�X�^ �ύX�t���O = '1'
        --   ���́A�^���}�X�^ �^���ύX�t���O�E���ڕύX�t���O = '1'�A
        --   ���́A�ŏI�X�V�������׍X�V���������Ɠ����ꍇ
        IF  ((gt_exch_deliv_tab(ln_index).distance_change_flg   = gv_target_y)
          OR (gt_exch_deliv_tab(ln_index).charg_shp_change_flg  = gv_target_y)
          OR (gt_exch_deliv_tab(ln_index).charg_lrf_change_flg  = gv_target_y)
          OR (gt_exch_deliv_tab(ln_index).last_update_date      = gd_sysdate )) THEN
--
          --    �z�������}�X�^ �ύX�t���O = '1' 
          -- or �^���ύX�t���O = '1' �̏ꍇ
          -- or �^�����׍X�V�Ώۂ̏ꍇ
          IF  ((gt_exch_deliv_tab(ln_index).distance_change_flg   = gv_target_y)
            OR (gt_exch_deliv_tab(ln_index).charg_shp_change_flg  = gv_target_y) 
            OR (gt_exch_deliv_tab(ln_index).last_update_date      = gd_sysdate )) THEN
            -- �_��^��
            ueh_head_contract_rate_tab(ln_target_cnt)  := gt_exch_deliv_tab(ln_index).shipping_expenses ;
          ELSE
            -- �ύX���ׁ̈A�擾�����_��^����ݒ�
            ueh_head_contract_rate_tab(ln_target_cnt)  := gt_exch_deliv_tab(ln_index).contract_rate ;
          END IF;
--
          -- ���ڕύX�t���O = '1' �̏ꍇ
          IF (( gt_exch_deliv_tab(ln_index).charg_lrf_change_flg  = gv_target_y)
            OR (gt_exch_deliv_tab(ln_index).last_update_date      = gd_sysdate )) THEN
            -- ���i�敪 = ���[�t�A���A���ڋ敪 = ���� �̏ꍇ
            IF  (( gt_exch_deliv_tab(ln_index).goods_classe = gv_prod_class_lef )
              AND (gt_exch_deliv_tab(ln_index).mixed_code = gv_target_y         )) THEN
              -- ���[�t���ڊ��� �~ ���ڐ�
              ueh_head_cnsld_srhrg_tab(ln_target_cnt)  := gt_exch_deliv_tab(ln_index).leaf_consolid_add *
                                                          gt_exch_deliv_tab(ln_index).consolid_qty;
            ELSE
              -- ���[�t���ڈȊO�ׁ̈A�擾�������ڊ������z��ݒ�
              ueh_head_cnsld_srhrg_tab(ln_target_cnt)  := gt_exch_deliv_tab(ln_index).consolid_surcharge;
            END IF;
          ELSE
            -- �ύX���ׁ̈A�擾�������ڊ������z��ݒ�
            ueh_head_cnsld_srhrg_tab(ln_target_cnt)  := gt_exch_deliv_tab(ln_index).consolid_surcharge;
          END IF;
--
        -- �^���}�X�^ �ύX�t���O = '1'�ȊO�̏ꍇ
        ELSE
          -- �ύX���ׁ̈A�擾�����_��^����ݒ�
          ueh_head_contract_rate_tab(ln_target_cnt)  := gt_exch_deliv_tab(ln_index).contract_rate ;
          -- �ύX���ׁ̈A�擾�������ڊ������z��ݒ�
          ueh_head_cnsld_srhrg_tab(ln_target_cnt)  := gt_exch_deliv_tab(ln_index).consolid_surcharge;
        END IF;
--
--
        -- ***** ���v *****
        -- �_��^�� + ���ڊ������z + �x���s�b�L���O�� + ������
        ueh_head_total_amount_tab(ln_target_cnt) :=  ueh_head_contract_rate_tab(ln_target_cnt) +
                                                ueh_head_cnsld_srhrg_tab(ln_target_cnt) +
                                                ueh_head_pick_charge_tab(ln_target_cnt) +
                                                NVL(gt_exch_deliv_tab(ln_index).many_rate,0);
--
        -- *** ���z ***
        -- �����^�� �| ���v
        ueh_head_balance_tab(ln_target_cnt)  :=  NVL(gt_exch_deliv_tab(ln_index).charged_amount, 0) -
                                            ueh_head_total_amount_tab(ln_target_cnt);
--
        -- *** ���ً敪 ***
        -- ���z���O�̏ꍇ
        IF (ueh_head_balance_tab(ln_target_cnt) <> 0) THEN
          ueh_head_output_flag_tab(ln_target_cnt) := gv_ktg_yes ;
        -- ���z���O�̏ꍇ
        ELSE
          ueh_head_output_flag_tab(ln_target_cnt) := gv_ktg_no ;
        END IF;
--
        -- *** �x���m��敪 ***
        -- �������z = NULL �̏ꍇ
        IF (gt_exch_deliv_tab(ln_index).charged_amount IS NULL) THEN
          ueh_head_defined_flag_tab(ln_target_cnt) :=  gv_ktg_no;
        -- ���ً敪 = YES �̏ꍇ
        ELSIF (ueh_head_output_flag_tab(ln_target_cnt) = gv_ktg_yes) THEN
          ueh_head_defined_flag_tab(ln_target_cnt) :=  gv_ktg_no;
        -- ���ً敪 = NO �̏ꍇ
        ELSE
          ueh_head_defined_flag_tab(ln_target_cnt) :=  gv_ktg_yes;
        END IF;
--
        -- *** �x���m��� ***
        ueh_head_return_flag_tab(ln_target_cnt)  := gv_ktg_no ;
--
        -- **************************************************
        -- * �폜�pPL/SQL�\ �ݒ�
        -- **************************************************
        -- ���ً敪 = Y �̏ꍇ
        IF (ueh_head_output_flag_tab(ln_target_cnt) = gv_ktg_yes) THEN
--
--<><><><><><><><><><><><><><><><><> DEBUG START <><><><><><><><><><><><><><><><><><><><><><><>
          IF (gv_debug_flg = gv_debug_on) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'set_exch_deliv_hate�F*** ���� �폜�pPL/SQL�\ �ݒ� �F'|| TO_CHAR(ln_index) || '�z��No�F' || gt_exch_deliv_tab(ln_index).delivery_no);
          END IF;
--<><><><><><><><><><><><><><><><><> DEBUG END   <><><><><><><><><><><><><><><><><><><><><><><>
--
          --�폜�p PL/SQL�\�ɐݒ�
          ln_delete_cnt := ln_delete_cnt + 1;
          deh_head_deliv_no_tab(ln_delete_cnt) := gt_exch_deliv_tab(ln_index).delivery_no;

          -- ���ѕύX�ɂ��폜 ���O�o�͗p�̈�i�[
          gn_delete_data_idx := gn_delete_data_idx + 1;
          gt_delete_data_msg(gn_delete_data_idx) :=  gt_exch_deliv_tab(ln_index).delivery_no     || '  ' ;  -- �z��No
          gt_delete_data_msg(gn_delete_data_idx) :=  gt_delete_data_msg(gn_delete_data_idx) || gt_exch_deliv_tab(ln_index).delivery_company_code || '  ' ; -- �^���Ǝ�
          gt_delete_data_msg(gn_delete_data_idx) :=  gt_delete_data_msg(gn_delete_data_idx) || TO_CHAR(gt_exch_deliv_tab(ln_index).ship_date, 'YYYY/MM/DD'); -- �o�ד�
--
        END IF;
--
      END IF;
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
    END LOOP deliv_loop;
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
  END set_exch_deliv_hate;
--
  /**********************************************************************************
   * Procedure Name   : update_exch_deliv_head
   * Description      : ���։^���A�h�I���}�X�^�ꊇ�X�V(A-47)
   ***********************************************************************************/
  PROCEDURE update_exch_deliv_head(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_exch_deliv_head'; -- �v���O������
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
    IF (ueh_head_deliv_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * �^���w�b�_�A�h�I�� �X�V
      -- **************************************************
      FORALL ln_index IN ueh_head_deliv_no_tab.FIRST .. ueh_head_deliv_no_tab.LAST
      UPDATE xxwip_deliverys            -- �^���w�b�_�A�h�I��
        SET     contract_rate           = ueh_head_contract_rate_tab(ln_index)-- �_��^��
              , balance                 = ueh_head_balance_tab(ln_index)      -- ���z
              , total_amount            = ueh_head_total_amount_tab(ln_index) -- ���v
              , consolid_surcharge      = ueh_head_cnsld_srhrg_tab(ln_index)  -- ���ڊ������z
              , picking_charge          = ueh_head_pick_charge_tab(ln_index)  -- �s�b�L���O��
              , output_flag             = ueh_head_output_flag_tab(ln_index)  -- ���ً敪
              , defined_flag            = ueh_head_defined_flag_tab(ln_index) -- �x���m��敪
              , return_flag             = ueh_head_return_flag_tab(ln_index)  -- �x���m���
--2008/08/04 Add ��
              , distance                = ueh_head_distance_type_tab(ln_index)     -- �Œ�����
              , actual_distance         = ueh_head_actual_ditnc_type_tab(ln_index) -- �Œ����ۋ���
--2008/08/04 Add ��
              , last_updated_by         = gn_user_id                 -- �ŏI�X�V��
              , last_update_date        = gd_sysdate                 -- �ŏI�X�V��
              , last_update_login       = gn_login_id                -- �ŏI�X�V���O�C��
              , request_id              = gn_conc_request_id         -- �v��ID
              , program_application_id  = gn_prog_appl_id            -- �ݶ��āE��۸��сE���ع����ID
              , program_id              = gn_conc_program_id         -- �R���J�����g�E�v���O����ID
              , program_update_date     = gd_sysdate                 -- �v���O�����X�V��
        WHERE   delivery_no = ueh_head_deliv_no_tab(ln_index)        -- �z��No
        AND     p_b_classe  = gv_pay;                                -- �x�������敪
--
      -- **************************************************
      -- �����ݒ�
      -- **************************************************
      gn_deliv_ins_cnt := gn_deliv_ins_cnt + SQL%ROWCOUNT;
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
  END update_exch_deliv_head;
--
  /**********************************************************************************
   * Procedure Name   : delete_exch_deliv_head
   * Description      : ���։^���A�h�I���}�X�^�ꊇ�폜(A-48)
   ***********************************************************************************/
  PROCEDURE delete_exch_deliv_head(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_exch_deliv_head'; -- �v���O������
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
    IF (deh_head_deliv_no_tab.COUNT <> 0) THEN
--
      -- **************************************************
      -- * �^���w�b�_�A�h�I�� �폜
      -- **************************************************
      FORALL ln_index IN deh_head_deliv_no_tab.FIRST .. deh_head_deliv_no_tab.LAST
      DELETE FROM  xxwip_deliverys  -- �^���w�b�_�A�h�I��
        WHERE   delivery_no = deh_head_deliv_no_tab(ln_index) -- �z��No
        AND     p_b_classe  = gv_claim;                       -- �x�������敪�i�����j
--
      -- **************************************************
      -- �����ݒ�
      -- **************************************************
      gn_deliv_del_cnt := gn_deliv_del_cnt + SQL%ROWCOUNT;
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
  END delete_exch_deliv_head;
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
--
  /**********************************************************************************
   * Procedure Name   : delete_exch_deliv_mst
   * Description      : ���։^���}�X�^�ꊇ�X�V
   ***********************************************************************************/
  PROCEDURE delete_exch_deliv_mst(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_exch_deliv_mst'; -- �v���O������
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
    --
    -- ���֊�����A�e�}�X�^�̃t���O��'0'�ɍX�V����
    --
--
    --�^���p�^���Ǝ҃}�X�^
      UPDATE xxwip_delivery_company
      SET    pay_change_flg          = gv_target_n                -- �x���ύX�t���O�iN�j
           , last_updated_by         = gn_user_id                 -- �ŏI�X�V��
           , last_update_date        = gd_sysdate                 -- �ŏI�X�V��
           , last_update_login       = gn_login_id                -- �ŏI�X�V���O�C��
           , request_id              = gn_conc_request_id         -- �v��ID
           , program_application_id  = gn_prog_appl_id            -- �ݶ��āE��۸��сE���ع����ID
           , program_id              = gn_conc_program_id         -- �R���J�����g�E�v���O����ID
           , program_update_date     = gd_sysdate                 -- �v���O�����X�V��
      WHERE  pay_change_flg = gv_target_y   -- �x���ύX�t���O
      ;
--
    -- �z�������}�X�^
      UPDATE  xxwip_delivery_distance
      SET     change_flg              = gv_target_n                -- �ύX�t���O�iN�j
            , last_updated_by         = gn_user_id                 -- �ŏI�X�V��
            , last_update_date        = gd_sysdate                 -- �ŏI�X�V��
            , last_update_login       = gn_login_id                -- �ŏI�X�V���O�C��
            , request_id              = gn_conc_request_id         -- �v��ID
            , program_application_id  = gn_prog_appl_id            -- �ݶ��āE��۸��сE���ع����ID
            , program_id              = gn_conc_program_id         -- �R���J�����g�E�v���O����ID
            , program_update_date     = gd_sysdate                 -- �v���O�����X�V��
      WHERE   change_flg = gv_target_y      -- �ύX�t���O
      ;
--
    -- �^���}�X�^
      UPDATE  xxwip_delivery_charges
      SET     change_flg = gv_target_n                             -- �ύX�t���O�iN�j
            , last_updated_by         = gn_user_id                 -- �ŏI�X�V��
            , last_update_date        = gd_sysdate                 -- �ŏI�X�V��
            , last_update_login       = gn_login_id                -- �ŏI�X�V���O�C��
            , request_id              = gn_conc_request_id         -- �v��ID
            , program_application_id  = gn_prog_appl_id            -- �ݶ��āE��۸��сE���ع����ID
            , program_id              = gn_conc_program_id         -- �R���J�����g�E�v���O����ID
            , program_update_date     = gd_sysdate                 -- �v���O�����X�V��
      WHERE   change_flg = gv_target_y      -- �ύX�t���O�iY�j
      AND     p_b_classe = gv_pay           -- �x�������敪:�x��
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
  END delete_exch_deliv_mst;
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
--
-- ##### 20081210 Ver.1.16 �{��#401�Ή� START #####
  /**********************************************************************************
   * Procedure Name   : delete_deli_cleaning
   * Description      : �z�ԑg���폜
   ***********************************************************************************/
  PROCEDURE delete_deli_cleaning(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_deli_cleaning'; -- �v���O������
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
      -- **************************************************
      -- * �ʏ�z�ԁA���A�^���w�b�_�ɑ��݂��āA
      -- *            �^�����ׂɑ��݂��Ȃ��z��No���폜
      -- **************************************************
      DELETE FROM  xxwip_deliverys xd        -- �^���w�b�_�A�h�I��
        WHERE  xd.dispatch_type = gv_car_normal  -- �ʏ�z��
        AND    NOT EXISTS (SELECT 'x'
                           FROM   xxwip_delivery_lines xdl
                           WHERE  xd.delivery_no = xdl.delivery_no);
--
      -- **************************************************
      -- �����ݒ�
      -- **************************************************
-- ##### 20081229 Ver.1.19 �{��#882�Ή� START #####
-- �z�ԑg���ɂ��폜�����̓J�E���g���Ȃ�
--      gn_deliv_del_cnt := gn_deliv_del_cnt + SQL%ROWCOUNT;
-- ##### 20081229 Ver.1.19 �{��#882�Ή� END   #####
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
  END delete_deli_cleaning;
--
-- ##### 20081210 Ver.1.16 �{��#401�Ή� END   #####
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_exchange_type  IN         VARCHAR2,     -- �􂢑ւ��敪
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
    -- ���b�N�擾(A-4)
    -- =========================================
    get_deliv_lock(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ���֋敪 = N �̏ꍇ
    IF (iv_exchange_type = gv_ktg_no) THEN
--
      -- =========================================
      -- �󒍎��я�񒊏o(A-5)
      -- =========================================
      get_order(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �󒍊֘A��񒊏o(A-6)
      -- =========================================
      get_order_other(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �󒍖��׃A�h�I�����o(A-9)
      -- =========================================
      get_order_line(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �󒍉^�����׃A�h�I��PL/SQL�\�i�[(A-13)
      -- =========================================
      set_order_deliv_line(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �ړ����я�񒊏o(A-14)
      -- =========================================
      get_move(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �ړ��֘A��񒊏o
      -- =========================================
      get_move_other(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �ړ����׃A�h�I�����o(A-18)
      -- =========================================
      get_move_line(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �ړ��^�����׃A�h�I��PL/SQL�\�i�[(A-22)
      -- =========================================
      set_move_deliv_line(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �^�����׃A�h�I���ꊇ�o�^(A-23)
      -- =========================================
      insert_deliv_line(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �^�����׃A�h�I���ꊇ�Čv�Z�X�V(A-24)
      -- =========================================
      update_deliv_line_calc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �^�����׃A�h�I���ꊇ�K�p�X�V(A-25)
      -- =========================================
      update_deliv_line_desc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 START #####
      -- =========================================
      -- �z�ԉ����Ώۈ˗�No���o(A-25-1)
      -- =========================================
      get_carcan_req_no(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �z�ԉ����f�[�^�����݂���ꍇ�̂�
      IF (gt_carcan_info_tab.COUNT <> 0) THEN
        -- =========================================
        -- �z�ԉ����z��No���o(A-25-2)
        -- =========================================
        get_carcan_deliv_no(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
        -- =========================================
        -- �z�ԉ����˗�No�폜(A-25-3)
        -- =========================================
        delete_carcan_req_no(
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =========================================
        -- �z�ԉ����z��No���݊m�F(A-25-4)
        -- =========================================
        check_carcan_deliv_no(
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =========================================
        -- �z�ԉ����^�����׃A�h�I���X�V(A-25-5)
        -- =========================================
        update_carcan_deliv_line(
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =========================================
        -- �z�ԉ����^���w�b�_�A�h�I���폜(A-25-6)
        -- =========================================
        delete_carcan_deliv_head(
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
-- ##### 20080717 Ver.1.5 �ύX�v��96,98 END   #####
--
      -- =========================================
      -- �^�����׃A�h�I���Ώ۔z��No���o(A-26)
      -- =========================================
      get_delinov_line_desc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �^�����׃A�h�I�����o(A-27)
      -- =========================================
      get_deliv_line(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �^���w�b�_�A�h�I��PL/SQL�\�i�[(A-30)
      -- =========================================
      set_deliv_head(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �z�Ԕz���v�撊�o(A-31)
      -- =========================================
      get_carriers_schedule(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �z�Ԃ̂݉^���w�b�_�A�h�I��PL/SQL�\�i�[(A-32)
      -- =========================================
      set_carri_deliv_head(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �^���w�b�_�A�h�I���ꊇ�o�^(A-33)
      -- =========================================
      insert_deliv_head(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �^���w�b�_�A�h�I���ꊇ�X�V(A-34)
      -- =========================================
      update_deliv_head(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- �^���w�b�_�A�h�I���ꊇ�폜(A-35)
      -- =========================================
      delete_deliv_head(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
-- ##### 20081210 Ver.1.16 �{��#401�Ή� START #####
      -- =========================================
      -- �z�ԑg���폜
      -- =========================================
      delete_deli_cleaning(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
-- ##### 20081210 Ver.1.16 �{��#401�Ή� END   #####
--
      -- =========================================
      -- �^���v�Z�R���g���[���X�V����(A-36)
      -- =========================================
      update_deliv_cntl(
        iv_exchange_type,  -- �􂢑ւ��敪
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    -- ���֋敪 = Y �̏ꍇ
    ELSE
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
--
      -- =========================================
      -- ���b�N�擾�i�^���֘A�}�X�^�j
      -- =========================================
      get_delivmst_lock(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
--
      -- =========================================
      -- ���։^�����׃A�h�I�����o(A-37)
      -- =========================================
      get_exch_deliv_line(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- ���։^�����׃A�h�I��PL/SQL�\�i�[(A-38)
      -- =========================================
      set_exch_deliv_line(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- ���։^�����׃A�h�I���ꊇ�X�V(A-39)
      -- =========================================
      update_exch_deliv_line(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- ���։^�����׃A�h�I���Ώ۔z��No���o(A-40)
      -- =========================================
      get_exch_delino(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- ���։^�����׃A�h�I�����o(A-41)
      -- =========================================
      get_exch_deliv_line_h(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- ���։^���w�b�_�A�h�I�����׍��ڍX�V�pPL/SQL�\�i�[(A-42)
      -- =========================================
      set_exch_deliv_head_h(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- ���։^���w�b�_�A�h�I�����׍��ڈꊇ�X�V(A-43)
      -- =========================================
      update_exch_deliv_head_h(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- ���։^���w�b�_�A�h�I�����o(A-44)
      -- =========================================
      get_exch_deliv_head(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- ���։^���A�h�I���}�X�^���o(A-45)
      -- =========================================
      get_exch_deliv_charg(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- ���։^���w�b�_�A�h�I��PL/SQL�\�i�[(A-46)
      -- =========================================
      set_exch_deliv_hate(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- ���։^���A�h�I���}�X�^�ꊇ�X�V(A-47)
      -- =========================================
      update_exch_deliv_head(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- ���։^���A�h�I���}�X�^�ꊇ�폜(A-48)
      -- =========================================
      delete_exch_deliv_head(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� start *----------*
--
      -- =========================================
      -- ���։^���}�X�^�ꊇ�X�V
      -- =========================================
      delete_exch_deliv_mst(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
-- *----------* 2009/04/07 Ver.1.23 �{��#432�Ή� end   *----------*
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
    iv_exchange_type  IN         VARCHAR2       --   �r���ւ��敪
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
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MM:SS'));
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
    -- ���b�Z�[�W�o��(C-16)
    -- =========================================
--
    -- �^���w�b�_�A�h�I�������������b�Z�[�W
    lv_message := xxcmn_common_pkg.get_msg(gv_xxwip_msg_kbn, gv_xxwip_msg_deliv_ins);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- ���������o��
    lv_message := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn, gv_xxcmn_msg_okcnt,
                                           gv_tkn_cnt,
                                           TO_CHAR(gn_deliv_ins_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- �^�����׃A�h�I�������������b�Z�[�W
    lv_message := xxcmn_common_pkg.get_msg(gv_xxwip_msg_kbn, gv_xxwip_msg_deliv_line);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- ���������o��
    lv_message := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn, gv_xxcmn_msg_okcnt,
                                           gv_tkn_cnt,
                                           TO_CHAR(gn_deliv_line_ins_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- �^���w�b�_�����폜�������b�Z�[�W
    lv_message := xxcmn_common_pkg.get_msg(gv_xxwip_msg_kbn, gv_xxwip_msg_deliv_del);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- ���������o��
    lv_message := xxcmn_common_pkg.get_msg(gv_xxcmn_msg_kbn, gv_xxcmn_msg_okcnt,
                                           gv_tkn_cnt,
                                           TO_CHAR(gn_deliv_del_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
-- ##### 20081226 Ver.1.18 �{��#323�Ή��i���O�Ή��j START #####
    -- �폜�f�[�^ ���O�o��
    IF ( gn_delete_data_idx <> 0 ) THEN
--
      -- �^�C�g���\��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '' ) ;          -- ��s
-- ##### 20081229 Ver.1.19 �{��#882�Ή� START #####
--      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�폜�z��No          ') ;
--      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '--------------------') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�z��No        �^��  ����       ') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '-------------------------------') ;
-- ##### 20081229 Ver.1.19 �{��#882�Ή� END   #####
--
      FOR i IN 1..gn_delete_data_idx LOOP
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gt_delete_data_msg(i)) ;
      END LOOP ;
--
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '' ) ;          -- ��s
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;  -- ��؂蕶����o��
--
    END IF;
-- ##### 20081226 Ver.1.18 �{��#323�Ή��i���O�Ή��j END   #####
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
END xxwip730001c;
/
