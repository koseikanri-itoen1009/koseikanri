CREATE OR REPLACE PACKAGE BODY xxwsh_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxwsh_common_pkg(BODY)
 * Description            : ���ʊ֐�(BODY)
 * MD.070(CMD.050)        : �Ȃ�
 * Version                : 1.22
 *
 * Program List
 *  --------------------   ---- ----- --------------------------------------------------
 *   Name                  Type  Ret   Description
 *  --------------------   ---- ----- --------------------------------------------------
 *  get_max_ship_method     F   NUM   �ő�z���敪�Z�o�֐�
 *  get_oprtn_day           F   NUM   �ғ����Z�o�֐�
 *  get_same_request_number F   NUM   ����˗�No�����֐�
 *  convert_request_number  F   NUM   �˗�No�R���o�[�g�֐�
 *  get_max_pallet_qty      F   NUM   �ő�p���b�g�����Z�o�֐�
 *  check_tightening_status F   NUM   ���߃X�e�[�^�X�`�F�b�N�֐�
 *  update_line_items       F   NUM   �d�ʗe�Ϗ������X�V�֐�
 *  cancel_reserve          F   NUM   ���������֐�
 *  cancel_careers_schedule F   NUM   �z�ԉ����֐�
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/02/01   1.0   Oracle �Ŗ����\  �V�K�쐬
 *  2008/05/16   1.1   Oracle �Ŗ����\  [�z�ԉ����֐�]3.�z�ԉ����ۃ`�F�b�N(�ړ�)��
 *                                      �ϐ�gt_chk_move_tbl�̕ϐ����Ⴂ���C��
 *  2008/05/20   1.2   Oracle �Γn���a  [�˗�No�R���o�[�g�֐�]
 *                                      �W���̃e�[�u�����A�h�I��View�ɕύX
 *  2008/05/21   1.3   Oracle �Ŗ����\  �����ύX�v��#111�Ή�
 *  2008/05/23   1.4   Oracle �Γn���a  [����˗�No�����֐�]
 *  2008/05/29   1.5   Oracle �Ŗ����\  [�d�ʗe�Ϗ������X�V�֐�]�����̖��ׂɑΉ�
 *  2008/06/03   1.6   Oracle �k�������v [�z�ԉ����֐�]440�s����O#45�Ή�
 *                                       ���ьv��ς������͎��ѐ��ʂ����͂���Ă���ꍇ��
 *                                       �֘A���ڍX�V���������s��������I������悤�ɏC��
 *  2008/06/03   1.7   Oracle �㌴���D  �����ύX�v��#80�Ή�[���߃X�e�[�^�X�`�F�b�N�֐�]
 *                                      �p�����[�^�u���_�v�̒ǉ� ���������C��
 *  2008/06/03   1.8   Oracle �㌴���D  [�z�ԉ����֐�]440�s����O#44�Ή�
 *                                      �L���x����'�o�׎��ьv���'�X�e�[�^�X��'08'�ɏC��
 *  2008/06/04   1.9   Oracle �R�{���v  [�d�ʗe�Ϗ������X�V�֐�]440�s����O#61�Ή�
 *  2008/06/26   1.10  Oracle �k�������v �G���[���̃��b�Z�[�W��SQLERRM��ǉ�
 *  2008/06/27   1.11  Oracle �Ŗ����\  [���������֐�]�Ɩ���ʈړ��̏ꍇ�A
 *                                      ���ׂɕR�t���������b�g�ɑΉ�
 *  2008/06/30   1.12  Oracle �Ŗ����\  [�ő�z���敪�Z�o�֐�]�ő�z���敪���o���̏����C��
 *  2008/07/02   1.13  Oracle ���c����  [���߃X�e�[�^�X�`�F�b�N�֐�]���_�E���_�J�e�S�����ɖ����͎��A
 *                                      ������ߏ�������s���̑Ή�(ST�s��Ή�#366)
 *  2008/07/04   1.13  Oracle �k�������v[���߃X�e�[�^�X�`�F�b�N�֐�]���_�J�e�S��=0��ALL�Ƃ���
 *                                      �����悤�ɏC���B
 *                                      ST#320�s��Ή�
 *  2008/07/09   1.14  Oracle �F�{�a�Y  [�d�ʗe�Ϗ������X�V�֐�] ST��Q#430�Ή�
 *  2008/07/11   1.15  Oracle ���c����  [�ő�z���敪�Z�o�֐�]�ύX�v���Ή�#95
 *  2008/07/11   1.16  Oracle ���c����  [�ő�p���b�g�����Z�o�֐�]�ύX�v���Ή�#95
 *  2008/08/04   1.17  Oracle �ɓ��ЂƂ�[�ő�z���敪�Z�o�֐�][�ő�p���b�g�����Z�o�֐�]
 *                                       �R�[�h�敪2 = 4,11�̏ꍇ�A���o�ɏꏊ�R�[�h2 = ZZZZ�Ō�������B
 *  2008/08/07   1.18  Oracle �ɓ��ЂƂ�[�d�ʗe�Ϗ������X�V�֐�]
 *                                       �����ۑ�#32   ����������o�ד��� > 0�̏ꍇ�ɏo�ד����Ōv�Z����悤�ɕύX
 *                                       �ύX�v��#166  ������������גP�ʂŐ؂�グ�ďW�v����悤�ɕύX
 *                                       �ύX�v��##173 �d�ʐύڌ���/�e�ϐύڌ�������^���敪�u1�v�̎��A�������Ŏ擾����悤�ɕύX
 *                                                     �^���敪�u1�v�̎�����d�ʐύڌ���/�e�ϐύڌ���  �����Ŏ擾�����l�ɍX�V
 *                                                     �^���敪�u1�v�łȂ�������d�ʐύڌ���/�e�ϐύڌ���/��{�d��/��{�e��/�z���敪 NULL�ɍX�V
 *                                                     ��ɍX�V����ύڏd�ʍ��v/�ύڗe�ύ��v/�p���b�g���v����/������
 *  2008/08/11   1.19  Oracle �ɓ��ЂƂ�[����˗�No�����֐�]�ύX�v��#174 ���ьv��ϋ敪Y�̃f�[�^��1�����Ȃ��ꍇ�́A�G���[��Ԃ��B
 *  2008/08/20   1.20  Oracle �k�������v[�z�ԉ����֐�] T_3_569�Ή�   �^���敪�ݒ莞�Ɋe�w�b�_�ɍő�z���敪�A��{�d�ʁA��{�e�ς�ݒ肷��悤�ɕύX
 *                                                     TE_080_400�w�ENo77�Ή� �󒍃w�b�_�̍��ڌ�No���N���A���Ȃ��悤�ɕύX
 *                                                     �J���C�Â��Ή� ���_�z�Ԃ���������������Ȃ������C��
 *                                                                    �̈�܂����ō��ڂ����ꍇ�ɐ�������������Ȃ������C��
 *                                                                    �z�ԉ������̃G���[���b�Z�[�W���������o�͂���Ȃ������C��
 *  2008/08/28   1.21  Oracle �ɓ��ЂƂ�[�z�ԉ����֐�] PT 1-2_8 �w�E#32�Ή�
 *  2008/09/02   1.22  Oracle �k�������v[�z�ԉ����֐�] �����e�X�g���s��Ή�
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
  no_data                   EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gn_status_normal CONSTANT NUMBER := 0;
  gn_status_error  CONSTANT NUMBER := 1;
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxwsh_common_pkg'; -- �p�b�P�[�W��
--
--add start 1.14
  gv_freight_charge_yes CONSTANT VARCHAR2(1) := '1';
--add end 1.14
-- 2008/08/04 Add H.Itou Start
  -- �R�[�h�敪
  code_class_whse       CONSTANT VARCHAR2(10) := '4';  -- �q��
  code_class_ship       CONSTANT VARCHAR2(10) := '9';  -- �o��
  code_class_supply     CONSTANT VARCHAR2(10) := '11'; -- �x��
-- 2008/08/04 Add H.Itou End
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �ړ��˗�/�w���̃��R�[�h�^
  TYPE mov_req_instr_rec IS RECORD(
    mov_line_id             xxinv_mov_req_instr_lines.mov_line_id%TYPE,
    ship_to_locat_id        xxinv_mov_req_instr_headers.ship_to_locat_id%TYPE,
    schedule_arrival_date   xxinv_mov_req_instr_headers.schedule_arrival_date%TYPE,
    item_short_name         xxcmn_item_mst2_v.item_short_name%TYPE,
    description             mtl_item_locations.description%TYPE
  );
  -- �z�ԉ����ۃ`�F�b�N(�o��)�̃��R�[�h�^
  TYPE chk_ship_rec IS RECORD(
    order_header_id   xxwsh_order_headers_all.order_header_id%TYPE,
    req_status        xxwsh_order_headers_all.req_status%TYPE,
    request_no        xxwsh_order_headers_all.request_no%TYPE,
    notif_status      xxwsh_order_headers_all.notif_status%TYPE,
    prev_notif_status xxwsh_order_headers_all.prev_notif_status%TYPE,
    shipped_quantity  xxwsh_order_lines_all.shipped_quantity%TYPE,
    ship_to_quantity  xxwsh_order_lines_all.ship_to_quantity%TYPE,
-- Ver1.20 M.Hokkanji START
    shipping_method_code        xxwsh_order_headers_all.shipping_method_code%TYPE,
    prod_class                  xxwsh_order_headers_all.prod_class%TYPE,
    based_weight                xxwsh_order_headers_all.based_weight%TYPE,
    based_capacity              xxwsh_order_headers_all.based_capacity%TYPE,
    weight_capacity_class       xxwsh_order_headers_all.weight_capacity_class%TYPE,
    deliver_from                xxwsh_order_headers_all.deliver_from%TYPE,
    deliver_to                  xxwsh_order_headers_all.deliver_to%TYPE,
    schedule_ship_date          xxwsh_order_headers_all.schedule_ship_date%TYPE,
    sum_weight                  xxwsh_order_headers_all.sum_weight%TYPE,
    sum_capacity                xxwsh_order_headers_all.sum_capacity%TYPE,
    sum_pallet_weight           xxwsh_order_headers_all.sum_pallet_weight%TYPE,
    freight_charge_class        xxwsh_order_headers_all.freight_charge_class%TYPE,
    loading_efficiency_weight   xxwsh_order_headers_all.loading_efficiency_weight%TYPE,
    loading_efficiency_capacity xxwsh_order_headers_all.loading_efficiency_capacity%TYPE
-- Ver1.20 M.Hokkanji END
  );
  -- �z�ԉ����ۃ`�F�b�N(�x��)�̃��R�[�h�^
  TYPE chk_supply_rec IS RECORD(
    order_header_id   xxwsh_order_headers_all.order_header_id%TYPE,
    req_status        xxwsh_order_headers_all.req_status%TYPE,
    request_no        xxwsh_order_headers_all.request_no%TYPE,
    notif_status      xxwsh_order_headers_all.notif_status%TYPE,
    prev_notif_status xxwsh_order_headers_all.prev_notif_status%TYPE,
    shipped_quantity  xxwsh_order_lines_all.shipped_quantity%TYPE,
    ship_to_quantity  xxwsh_order_lines_all.ship_to_quantity%TYPE,
-- Ver1.20 M.Hokkanji START
    shipping_method_code        xxwsh_order_headers_all.shipping_method_code%TYPE,
    prod_class                  xxwsh_order_headers_all.prod_class%TYPE,
    based_weight                xxwsh_order_headers_all.based_weight%TYPE,
    based_capacity              xxwsh_order_headers_all.based_capacity%TYPE,
    weight_capacity_class       xxwsh_order_headers_all.weight_capacity_class%TYPE,
    deliver_from                xxwsh_order_headers_all.deliver_from%TYPE,
    vendor_site_code            xxwsh_order_headers_all.vendor_site_code%TYPE,
    schedule_ship_date          xxwsh_order_headers_all.schedule_ship_date%TYPE,
    sum_weight                  xxwsh_order_headers_all.sum_weight%TYPE,
    sum_capacity                xxwsh_order_headers_all.sum_capacity%TYPE,
    freight_charge_class        xxwsh_order_headers_all.freight_charge_class%TYPE,
    loading_efficiency_weight   xxwsh_order_headers_all.loading_efficiency_weight%TYPE,
    loading_efficiency_capacity xxwsh_order_headers_all.loading_efficiency_capacity%TYPE
-- Ver1.20 M.Hokkanji END
  );
  -- �z�ԉ����ۃ`�F�b�N(�ړ�)�̃��R�[�h�^
  TYPE chk_move_rec IS RECORD(
    mov_hdr_id                    xxinv_mov_req_instr_headers.mov_hdr_id%TYPE,
    status                        xxinv_mov_req_instr_headers.status%TYPE,
    mov_num                       xxinv_mov_req_instr_headers.mov_num%TYPE,
    notif_status                  xxinv_mov_req_instr_headers.notif_status%TYPE,
    prev_notif_status             xxinv_mov_req_instr_headers.prev_notif_status%TYPE,
    shipped_quantity              xxinv_mov_req_instr_lines.shipped_quantity%TYPE,
    ship_to_quantity              xxinv_mov_req_instr_lines.ship_to_quantity%TYPE,
-- Ver1.20 M.Hokkanji START
    shipping_method_code          xxinv_mov_req_instr_headers.shipping_method_code%TYPE,
    item_class                    xxinv_mov_req_instr_headers.item_class%TYPE,
    based_weight                  xxinv_mov_req_instr_headers.based_weight%TYPE,
    based_capacity                xxinv_mov_req_instr_headers.based_capacity%TYPE,
    weight_capacity_class         xxinv_mov_req_instr_headers.weight_capacity_class%TYPE,
    shipped_locat_code            xxinv_mov_req_instr_headers.shipped_locat_code%TYPE,
    ship_to_locat_code            xxinv_mov_req_instr_headers.ship_to_locat_code%TYPE,
    schedule_ship_date            xxinv_mov_req_instr_headers.schedule_ship_date%TYPE,
    sum_weight                    xxinv_mov_req_instr_headers.sum_weight%TYPE,
    sum_capacity                  xxinv_mov_req_instr_headers.sum_capacity%TYPE,
    sum_pallet_weight             xxinv_mov_req_instr_headers.sum_pallet_weight%TYPE,
    freight_charge_class          xxinv_mov_req_instr_headers.freight_charge_class%TYPE,
    loading_efficiency_weight     xxinv_mov_req_instr_headers.loading_efficiency_weight%TYPE,
    loading_efficiency_capacity   xxinv_mov_req_instr_headers.loading_efficiency_capacity%TYPE
-- Ver1.20 M.Hokkanji END
  );
  -- �d�ʗe�Ϗ������X�V(�o��)�̃��R�[�h�^
  TYPE ship_rec IS RECORD(
    shipped_quantity    xxwsh_order_lines_all.shipped_quantity%TYPE,
    shipping_item_code  xxwsh_order_lines_all.shipping_item_code%TYPE,
    conv_unit           xxcmn_item_mst_v.conv_unit%TYPE,
    num_of_cases        xxcmn_item_mst_v.num_of_cases%TYPE,
    num_of_deliver      xxcmn_item_mst_v.num_of_deliver%TYPE,
    order_line_id       xxwsh_order_lines_all.order_line_id%TYPE
  );
  -- �d�ʗe�Ϗ������X�V(�x��)�̃��R�[�h�^
  TYPE supply_rec IS RECORD(
    shipping_item_code  xxwsh_order_lines_all.shipping_item_code%TYPE,
    shipped_quantity    xxwsh_order_lines_all.shipped_quantity%TYPE,
    order_line_id       xxwsh_order_lines_all.order_line_id%TYPE
  );
  -- �d�ʗe�Ϗ������X�V(�ړ�)�̃��R�[�h�^
  TYPE move_rec IS RECORD(
    shipped_quantity    xxinv_mov_req_instr_lines.shipped_quantity%TYPE,
    item_code           xxinv_mov_req_instr_lines.item_code%TYPE,
    conv_unit           xxcmn_item_mst_v.conv_unit%TYPE,
    num_of_cases        xxcmn_item_mst_v.num_of_cases%TYPE,
    num_of_deliver      xxcmn_item_mst_v.num_of_deliver%TYPE,
    mov_line_id         xxinv_mov_req_instr_lines.mov_line_id%TYPE
  );
  -- ���׍X�V���ڂ̃��R�[�h�^
  TYPE update_rec IS RECORD(
    update_weight                 NUMBER,
    update_capacity               NUMBER,
    update_pallet_weight          NUMBER,
    update_line_id                NUMBER
  );
--
  -- �ړ��˗�/�w���̃e�[�u���^
  TYPE mov_req_instr_tbl IS
    TABLE OF mov_req_instr_rec INDEX BY PLS_INTEGER;
  -- �󒍖��׃A�h�I��ID
  TYPE order_line_id_tbl IS
    TABLE OF xxwsh_order_lines_all.order_line_id%TYPE INDEX BY PLS_INTEGER;
  -- �ړ�����ID
  TYPE mov_line_id_tbl IS
    TABLE OF xxinv_mov_req_instr_lines.mov_line_id%TYPE INDEX BY PLS_INTEGER;
  -- ���ɐ�ID
  TYPE ship_to_locat_id_tbl IS
    TABLE OF xxinv_mov_req_instr_headers.ship_to_locat_id%TYPE INDEX BY PLS_INTEGER;
  -- ���ѐ���
  TYPE schedule_arrival_date_tbl IS
    TABLE OF xxinv_mov_req_instr_headers.schedule_arrival_date%TYPE INDEX BY PLS_INTEGER;
  -- �i���E����
  TYPE item_short_name_tbl IS
    TABLE OF xxcmn_item_mst2_v.item_short_name%TYPE INDEX BY PLS_INTEGER;
  -- �ۊǏꏊ��
  TYPE description_tbl IS
    TABLE OF mtl_item_locations.description%TYPE INDEX BY PLS_INTEGER;
  -- ���b�g�ڍ�ID
  TYPE mov_lot_dtl_id_tbl IS
    TABLE OF xxinv_mov_lot_details.mov_lot_dtl_id%TYPE INDEX BY PLS_INTEGER;
  -- ���b�gID
  TYPE lot_id_tbl IS
    TABLE OF xxinv_mov_lot_details.lot_id%TYPE INDEX BY PLS_INTEGER;
  -- OPM�i��ID
  TYPE item_id_tbl IS
    TABLE OF xxinv_mov_lot_details.item_id%TYPE INDEX BY PLS_INTEGER;
  -- ���ѐ���
  TYPE actual_quantity_tbl IS
    TABLE OF xxinv_mov_lot_details.actual_quantity%TYPE INDEX BY PLS_INTEGER;
  -- ���b�gNo
  TYPE lot_no_tbl IS
    TABLE OF xxinv_mov_lot_details.lot_no%TYPE INDEX BY PLS_INTEGER;
--
  -- �z�ԉ����ۃ`�F�b�N(�o��)
  TYPE chk_ship_tbl IS
    TABLE OF chk_ship_rec INDEX BY PLS_INTEGER;
--
  -- �z�ԉ����ۃ`�F�b�N(�x��)
  TYPE chk_supply_tbl IS
    TABLE OF chk_supply_rec INDEX BY PLS_INTEGER;
--
  -- �z�ԉ����ۃ`�F�b�N(�ړ�)
  TYPE chk_move_tbl IS
    TABLE OF chk_move_rec INDEX BY PLS_INTEGER;
--
  -- �d�ʗe�Ϗ������X�V(�o��)�̃e�[�u���^
  TYPE get_ship_tbl IS
    TABLE OF ship_rec INDEX BY PLS_INTEGER;
--
  -- �d�ʗe�Ϗ������X�V(�x��)�̃e�[�u���^
  TYPE get_supply_tbl IS
    TABLE OF supply_rec INDEX BY PLS_INTEGER;
--
  -- �d�ʗe�Ϗ������X�V(�ړ�)�̃e�[�u���^
  TYPE get_move_tbl IS
    TABLE OF move_rec INDEX BY PLS_INTEGER;
--
  -- ���׍X�V���ڂ̃e�[�u���^
  TYPE get_update_tbl IS
    TABLE OF update_rec INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_mov_req_instr_tbl            mov_req_instr_tbl;         -- �ړ��˗�/�w���̌����z��
  gt_order_line_id_tbl            order_line_id_tbl;         -- �󒍖��׃A�h�I��ID
  gt_mov_line_id_tbl              mov_line_id_tbl;           -- �ړ�����ID
  gt_ship_to_locat_id_tbl         ship_to_locat_id_tbl;      -- ���ɐ�ID
  gt_schedule_arrival_date_tbl    schedule_arrival_date_tbl; -- ���ɗ\���
  gt_item_short_name_tbl          item_short_name_tbl;       -- �E�v
  gt_description_tbl              description_tbl;           -- �ۊǏꏊ
  gt_mov_lot_dtl_id_tbl           mov_lot_dtl_id_tbl;        -- ���b�g�ڍ�ID
  gt_lot_id_tbl                   lot_id_tbl;                -- ���b�gID
  gt_item_id_tbl                  item_id_tbl;               -- OPM�i��ID
  gt_actual_quantity_tbl          actual_quantity_tbl;       -- ���ѐ���
  gt_lot_no_tbl                   lot_no_tbl;                -- ���b�gNo
  gt_chk_ship_tbl                 chk_ship_tbl;              -- �z�ԉ����ۃ`�F�b�N(�o��)
  gt_chk_supply_tbl               chk_supply_tbl;            -- �z�ԉ����ۃ`�F�b�N(�x��)
  gt_chk_move_tbl                 chk_move_tbl;              -- �z�ԉ����ۃ`�F�b�N(�ړ�)
--
  /**********************************************************************************
   * Function Name    : get_max_ship_method
   * Description      : �ő�z���敪�Z�o�֐�
   ***********************************************************************************/
  FUNCTION get_max_ship_method(
    -- 1.�R�[�h�敪�P
    iv_code_class1                IN  xxcmn_ship_methods.code_class1%TYPE,
    -- 2.���o�ɏꏊ�R�[�h�P
    iv_entering_despatching_code1 IN  xxcmn_ship_methods.entering_despatching_code1%TYPE,
    -- 3.�R�[�h�敪�Q
    iv_code_class2                IN  xxcmn_ship_methods.code_class2%TYPE,
    -- 4.���o�ɏꏊ�R�[�h�Q
    iv_entering_despatching_code2 IN  xxcmn_ship_methods.entering_despatching_code2%TYPE,
    -- 5.���i�敪
    iv_prod_class                 IN  xxcmn_item_categories_v.segment1%TYPE,
    -- 6.�d�ʗe�ϋ敪
    iv_weight_capacity_class      IN  VARCHAR2,
    -- 7.�����z�ԑΏۋ敪
    iv_auto_process_type          IN  VARCHAR2,
    -- 8.���(�K�p�����)
    id_standard_date              IN  DATE,
    -- 9.�ő�z���敪
    ov_max_ship_methods           OUT xxcmn_ship_methods.ship_method%TYPE,
    -- 10.�h�����N�ύڏd��
    on_drink_deadweight           OUT xxcmn_ship_methods.drink_deadweight%TYPE,
    -- 11.���[�t�ύڏd��
    on_leaf_deadweight            OUT xxcmn_ship_methods.leaf_deadweight%TYPE,
    -- 12.�h�����N�ύڗe��
    on_drink_loading_capacity     OUT xxcmn_ship_methods.drink_loading_capacity%TYPE,
    -- 13.���[�t�ύڗe��
    on_leaf_loading_capacity      OUT xxcmn_ship_methods.leaf_loading_capacity%TYPE,
    -- 14.�p���b�g�ő喇��
    on_palette_max_qty            OUT xxcmn_ship_methods.palette_max_qty%TYPE)
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'get_max_ship_method';    --�v���O������
    cv_object                 CONSTANT VARCHAR2(1)   := '1';                      --�Ώ�
    cv_leaf                   CONSTANT VARCHAR2(1)   := '1';                      --���[�t
    cv_drink                  CONSTANT VARCHAR2(1)   := '2';                      --�h�����N
    cv_weight                 CONSTANT VARCHAR2(1)   := '1';                      --�d��
    cv_capacity               CONSTANT VARCHAR2(1)   := '2';                      --�e��
    cv_deliver_to             CONSTANT VARCHAR2(1)   := '9';                      --�z����
    cv_base                   CONSTANT VARCHAR2(1)   := '1';                      --���_
    cv_all_4                  CONSTANT VARCHAR2(4)   := 'ZZZZ';                   --2008/07/11 �ύX�v���Ή�#95
    cv_all_9                  CONSTANT VARCHAR2(9)   := 'ZZZZZZZZZ';              --2008/07/11 �ύX�v���Ή�#95
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ld_standard_date      DATE;                                                   --���
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    -- �K�{���̓p�����[�^�`�F�b�N
    IF ((iv_code_class1                 IS NULL) OR
         (iv_entering_despatching_code1 IS NULL) OR
         (iv_code_class2                IS NULL) OR
         (iv_entering_despatching_code2 IS NULL) OR
         ((iv_prod_class                IS NULL) OR
           (iv_prod_class               NOT IN (cv_leaf, cv_drink))) OR
         ((iv_weight_capacity_class     IS NULL) OR
           (iv_weight_capacity_class    NOT IN (cv_weight, cv_capacity))) OR
         ((iv_auto_process_type         IS NOT NULL) AND
           (iv_auto_process_type        <> cv_object))) THEN
      RETURN gn_status_error;
    END IF;
--
    -- �u���(�K�p�����)�v���w�肳��Ȃ��ꍇ�̓V�X�e�����t
    IF ( id_standard_date IS NULL) THEN
      ld_standard_date := TRUNC(SYSDATE);
    ELSE
      ld_standard_date := TRUNC(id_standard_date);
    END IF;
--
    -------- 1. �q��(�ʃR�[�h)�|�z����(�ʃR�[�h) -------------------
    BEGIN
      SELECT xdlv2.ship_method,
             xdlv2.drink_deadweight,
             xdlv2.leaf_deadweight,
             xdlv2.drink_loading_capacity,
             xdlv2.leaf_loading_capacity,
             xdlv2.palette_max_qty
      INTO   ov_max_ship_methods,
             on_drink_deadweight,
             on_leaf_deadweight,
             on_drink_loading_capacity,
             on_leaf_loading_capacity,
             on_palette_max_qty
      FROM   (SELECT xdlv2.ship_methods_id,
                     MAX(xdlv2.ship_method)
                       OVER(PARTITION BY
                         xdlv2.code_class1,
                         xdlv2.entering_despatching_code1,
                         xdlv2.code_class2,
                         xdlv2.entering_despatching_code2
                       ) max_ship
             FROM    xxcmn_delivery_lt2_v xdlv2,
                     xxwsh_ship_method2_v xsmv2
             WHERE   (CASE
                       -- �h�����N�ύڏd��
                       WHEN ((iv_prod_class             =  cv_drink) AND
                              (iv_weight_capacity_class =  cv_weight)) THEN
                         xdlv2.drink_deadweight
                       -- ���[�t�ύڏd��
                       WHEN ((iv_prod_class             =  cv_leaf) AND
                              (iv_weight_capacity_class =  cv_weight)) THEN
                         xdlv2.leaf_deadweight
                       -- �h�����N�ύڗe��
                       WHEN ((iv_prod_class             =  cv_drink) AND
                              (iv_weight_capacity_class =  cv_capacity)) THEN
                         xdlv2.drink_loading_capacity
                       -- ���[�t�ύڗe��
                       WHEN ((iv_prod_class             =  cv_leaf) AND
                              (iv_weight_capacity_class =  cv_capacity)) THEN
                         xdlv2.leaf_loading_capacity
                     END) > 0
             -- �R�[�h�敪�P
             AND     xdlv2.code_class1                  =  iv_code_class1
             -- ���o�ɏꏊ�R�[�h�P
             AND     xdlv2.entering_despatching_code1   =  iv_entering_despatching_code1  --��
             -- �R�[�h�敪�Q
             AND     xdlv2.code_class2                  =  iv_code_class2
             -- ���o�ɏꏊ�R�[�h�Q
             AND     xdlv2.entering_despatching_code2   =  iv_entering_despatching_code2  --��
             -- �K�p�J�n��(�z��L/T)
             AND     ((xdlv2.lt_start_date_active       <= ld_standard_date) OR
                       (xdlv2.lt_start_date_active      IS NULL))
             -- �K�p�I����(�z��L/T)
             AND     ((xdlv2.lt_end_date_active         >= ld_standard_date) OR
                       (xdlv2.lt_end_date_active        IS NULL))
             -- �K�p�J�n��(�o�ו��@)
             AND     ((xdlv2.sm_start_date_active       <= ld_standard_date) OR
                       (xdlv2.sm_start_date_active      IS NULL))
             -- �K�p�I����(�o�ו��@)
             AND     ((xdlv2.sm_end_date_active         >= ld_standard_date) OR
                       (xdlv2.sm_end_date_active        IS NULL))
             -- ���ڋ敪
             AND     ((xsmv2.mixed_class                <> cv_object) OR
                       (xsmv2.mixed_class               IS NULL))
             -- �����z�ԑΏۋ敪
             AND     ((iv_auto_process_type             IS NULL) OR
                       (xsmv2.auto_process_type         =  cv_object))
             -- �L���J�n��
             AND     ((xsmv2.start_date_active          <= ld_standard_date) OR
                       (xsmv2.start_date_active         IS NULL))
             -- �L���I����
             AND     ((xsmv2.end_date_active            >= ld_standard_date) OR
                       (xsmv2.end_date_active           IS NULL))
             AND     xdlv2.ship_method                  =  xsmv2.ship_method_code
             ) max_ship_method,
             xxcmn_delivery_lt2_v xdlv2
      -- �K�p�J�n��(�z��L/T)
      WHERE  ((xdlv2.lt_start_date_active               <= ld_standard_date) OR
               (xdlv2.lt_start_date_active              IS NULL))
      -- �K�p�I����(�z��L/T)
      AND    ((xdlv2.lt_end_date_active                 >= ld_standard_date) OR
               (xdlv2.lt_end_date_active                IS NULL))
      -- �K�p�J�n��(�o�ו��@)
      AND    ((xdlv2.sm_start_date_active               <= ld_standard_date) OR
               (xdlv2.sm_start_date_active              IS NULL))
      -- �K�p�I����(�o�ו��@)
      AND    ((xdlv2.sm_end_date_active                 >= ld_standard_date) OR
               (xdlv2.sm_end_date_active                IS NULL))
      AND    max_ship_method.ship_methods_id            =  xdlv2.ship_methods_id
      AND    max_ship_method.max_ship                   =  xdlv2.ship_method;
--
    ------------- 2008/07/11 �ύX�v���Ή�#95 ADD START --------------------------------------
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
-- 2008/08/04 Del H.Itou Start
--        IF (iv_code_class2 <> cv_deliver_to) THEN  -- �R�[�h�敪�Q<>�u9:�z���v�̏ꍇ�͍Č������Ȃ�
--          RAISE no_data;
--        END IF;
-- 2008/08/04 Del H.Itou End
--
        ---------- 2. �q��(ALL�l)�|�z����(�ʃR�[�h) -------------------------------
        BEGIN
          SELECT xdlv2.ship_method,
                 xdlv2.drink_deadweight,
                 xdlv2.leaf_deadweight,
                 xdlv2.drink_loading_capacity,
                 xdlv2.leaf_loading_capacity,
                 xdlv2.palette_max_qty
          INTO   ov_max_ship_methods,
                 on_drink_deadweight,
                 on_leaf_deadweight,
                 on_drink_loading_capacity,
                 on_leaf_loading_capacity,
                 on_palette_max_qty
          FROM   (SELECT xdlv2.ship_methods_id,
                         MAX(xdlv2.ship_method)
                           OVER(PARTITION BY
                             xdlv2.code_class1,
                             xdlv2.entering_despatching_code1,
                             xdlv2.code_class2,
                             xdlv2.entering_despatching_code2
                           ) max_ship
                 FROM    xxcmn_delivery_lt2_v xdlv2,
                         xxwsh_ship_method2_v xsmv2
                 WHERE   (CASE
                           -- �h�����N�ύڏd��
                           WHEN ((iv_prod_class             =  cv_drink) AND
                                  (iv_weight_capacity_class =  cv_weight)) THEN
                             xdlv2.drink_deadweight
                           -- ���[�t�ύڏd��
                           WHEN ((iv_prod_class             =  cv_leaf) AND
                                  (iv_weight_capacity_class =  cv_weight)) THEN
                             xdlv2.leaf_deadweight
                           -- �h�����N�ύڗe��
                           WHEN ((iv_prod_class             =  cv_drink) AND
                                  (iv_weight_capacity_class =  cv_capacity)) THEN
                             xdlv2.drink_loading_capacity
                           -- ���[�t�ύڗe��
                           WHEN ((iv_prod_class             =  cv_leaf) AND
                                  (iv_weight_capacity_class =  cv_capacity)) THEN
                             xdlv2.leaf_loading_capacity
                         END) > 0
                 -- �R�[�h�敪�P
                 AND     xdlv2.code_class1                  =  iv_code_class1
                 -- ���o�ɏꏊ�R�[�h�P
                 AND     xdlv2.entering_despatching_code1   =  cv_all_4     --ALL'Z'
                 -- �R�[�h�敪�Q
                 AND     xdlv2.code_class2                  =  iv_code_class2
                 -- ���o�ɏꏊ�R�[�h�Q
                 AND     xdlv2.entering_despatching_code2   =  iv_entering_despatching_code2  --��
                 -- �K�p�J�n��(�z��L/T)
                 AND     ((xdlv2.lt_start_date_active       <= ld_standard_date) OR
                           (xdlv2.lt_start_date_active      IS NULL))
                 -- �K�p�I����(�z��L/T)
                 AND     ((xdlv2.lt_end_date_active         >= ld_standard_date) OR
                           (xdlv2.lt_end_date_active        IS NULL))
                 -- �K�p�J�n��(�o�ו��@)
                 AND     ((xdlv2.sm_start_date_active       <= ld_standard_date) OR
                           (xdlv2.sm_start_date_active      IS NULL))
                 -- �K�p�I����(�o�ו��@)
                 AND     ((xdlv2.sm_end_date_active         >= ld_standard_date) OR
                           (xdlv2.sm_end_date_active        IS NULL))
                 -- ���ڋ敪
                 AND     ((xsmv2.mixed_class                <> cv_object) OR
                           (xsmv2.mixed_class               IS NULL))
                 -- �����z�ԑΏۋ敪
                 AND     ((iv_auto_process_type             IS NULL) OR
                           (xsmv2.auto_process_type         =  cv_object))
                 -- �L���J�n��
                 AND     ((xsmv2.start_date_active          <= ld_standard_date) OR
                           (xsmv2.start_date_active         IS NULL))
                 -- �L���I����
                 AND     ((xsmv2.end_date_active            >= ld_standard_date) OR
                           (xsmv2.end_date_active           IS NULL))
                 AND     xdlv2.ship_method                  =  xsmv2.ship_method_code
                 ) max_ship_method,
                 xxcmn_delivery_lt2_v xdlv2
          -- �K�p�J�n��(�z��L/T)
          WHERE  ((xdlv2.lt_start_date_active               <= ld_standard_date) OR
                   (xdlv2.lt_start_date_active              IS NULL))
          -- �K�p�I����(�z��L/T)
          AND    ((xdlv2.lt_end_date_active                 >= ld_standard_date) OR
                   (xdlv2.lt_end_date_active                IS NULL))
          -- �K�p�J�n��(�o�ו��@)
          AND    ((xdlv2.sm_start_date_active               <= ld_standard_date) OR
                   (xdlv2.sm_start_date_active              IS NULL))
          -- �K�p�I����(�o�ו��@)
          AND    ((xdlv2.sm_end_date_active                 >= ld_standard_date) OR
                   (xdlv2.sm_end_date_active                IS NULL))
          AND    max_ship_method.ship_methods_id            =  xdlv2.ship_methods_id
          AND    max_ship_method.max_ship                   =  xdlv2.ship_method;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ------------- 3. �q��(�ʃR�[�h)�|�z����(ALL�l) -----------------------------
            BEGIN
              SELECT xdlv2.ship_method,
                     xdlv2.drink_deadweight,
                     xdlv2.leaf_deadweight,
                     xdlv2.drink_loading_capacity,
                     xdlv2.leaf_loading_capacity,
                     xdlv2.palette_max_qty
              INTO   ov_max_ship_methods,
                     on_drink_deadweight,
                     on_leaf_deadweight,
                     on_drink_loading_capacity,
                     on_leaf_loading_capacity,
                     on_palette_max_qty
              FROM   (SELECT xdlv2.ship_methods_id,
                             MAX(xdlv2.ship_method)
                               OVER(PARTITION BY
                                 xdlv2.code_class1,
                                 xdlv2.entering_despatching_code1,
                                 xdlv2.code_class2,
                                 xdlv2.entering_despatching_code2
                               ) max_ship
                     FROM    xxcmn_delivery_lt2_v xdlv2,
                             xxwsh_ship_method2_v xsmv2
                     WHERE   (CASE
                               -- �h�����N�ύڏd��
                               WHEN ((iv_prod_class             =  cv_drink) AND
                                      (iv_weight_capacity_class =  cv_weight)) THEN
                                 xdlv2.drink_deadweight
                               -- ���[�t�ύڏd��
                               WHEN ((iv_prod_class             =  cv_leaf) AND
                                      (iv_weight_capacity_class =  cv_weight)) THEN
                                 xdlv2.leaf_deadweight
                               -- �h�����N�ύڗe��
                               WHEN ((iv_prod_class             =  cv_drink) AND
                                      (iv_weight_capacity_class =  cv_capacity)) THEN
                                 xdlv2.drink_loading_capacity
                               -- ���[�t�ύڗe��
                               WHEN ((iv_prod_class             =  cv_leaf) AND
                                      (iv_weight_capacity_class =  cv_capacity)) THEN
                                 xdlv2.leaf_loading_capacity
                             END) > 0
                     -- �R�[�h�敪�P
                     AND     xdlv2.code_class1                  =  iv_code_class1
                     -- ���o�ɏꏊ�R�[�h�P
                     AND     xdlv2.entering_despatching_code1   =  iv_entering_despatching_code1    --��
                     -- �R�[�h�敪�Q
                     AND     xdlv2.code_class2                  =  iv_code_class2
-- 2008/08/04 Mod H.Itou Start
                     -- ���o�ɏꏊ�R�[�h�Q
                       -- �R�[�h�敪��9:�o�ׂ̏ꍇ�AZZZZZZZZZ
                     AND   (((iv_code_class2                     = code_class_ship)
                         AND (xdlv2.entering_despatching_code2   = cv_all_9))          --ALL'Z'
                       -- �R�[�h�敪��4:�z���� OR 11:�x�� �̏ꍇ�AZZZZ
                       OR   ((iv_code_class2                     IN (code_class_whse, code_class_supply))
                         AND (xdlv2.entering_despatching_code2   = cv_all_4)))         --ALL'Z'
--                     AND     xdlv2.entering_despatching_code2   =  cv_all_9          --ALL'Z'
-- 2008/08/04 Mod H.Itou End
                     -- �K�p�J�n��(�z��L/T)
                     AND     ((xdlv2.lt_start_date_active       <= ld_standard_date) OR
                               (xdlv2.lt_start_date_active      IS NULL))
                     -- �K�p�I����(�z��L/T)
                     AND     ((xdlv2.lt_end_date_active         >= ld_standard_date) OR
                               (xdlv2.lt_end_date_active        IS NULL))
                     -- �K�p�J�n��(�o�ו��@)
                     AND     ((xdlv2.sm_start_date_active       <= ld_standard_date) OR
                               (xdlv2.sm_start_date_active      IS NULL))
                     -- �K�p�I����(�o�ו��@)
                     AND     ((xdlv2.sm_end_date_active         >= ld_standard_date) OR
                               (xdlv2.sm_end_date_active        IS NULL))
                     -- ���ڋ敪
                     AND     ((xsmv2.mixed_class                <> cv_object) OR
                               (xsmv2.mixed_class               IS NULL))
                     -- �����z�ԑΏۋ敪
                     AND     ((iv_auto_process_type             IS NULL) OR
                               (xsmv2.auto_process_type         =  cv_object))
                     -- �L���J�n��
                     AND     ((xsmv2.start_date_active          <= ld_standard_date) OR
                               (xsmv2.start_date_active         IS NULL))
                     -- �L���I����
                     AND     ((xsmv2.end_date_active            >= ld_standard_date) OR
                               (xsmv2.end_date_active           IS NULL))
                     AND     xdlv2.ship_method                  =  xsmv2.ship_method_code
                     ) max_ship_method,
                     xxcmn_delivery_lt2_v xdlv2
              -- �K�p�J�n��(�z��L/T)
              WHERE  ((xdlv2.lt_start_date_active               <= ld_standard_date) OR
                       (xdlv2.lt_start_date_active              IS NULL))
              -- �K�p�I����(�z��L/T)
              AND    ((xdlv2.lt_end_date_active                 >= ld_standard_date) OR
                       (xdlv2.lt_end_date_active                IS NULL))
              -- �K�p�J�n��(�o�ו��@)
              AND    ((xdlv2.sm_start_date_active               <= ld_standard_date) OR
                       (xdlv2.sm_start_date_active              IS NULL))
              -- �K�p�I����(�o�ו��@)
              AND    ((xdlv2.sm_end_date_active                 >= ld_standard_date) OR
                       (xdlv2.sm_end_date_active                IS NULL))
              AND    max_ship_method.ship_methods_id            =  xdlv2.ship_methods_id
              AND    max_ship_method.max_ship                   =  xdlv2.ship_method;
--
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                ----------- 4. �q��(ALL�l)�|�z����(ALL�l) -------------------------------
                BEGIN
                  SELECT xdlv2.ship_method,
                         xdlv2.drink_deadweight,
                         xdlv2.leaf_deadweight,
                         xdlv2.drink_loading_capacity,
                         xdlv2.leaf_loading_capacity,
                         xdlv2.palette_max_qty
                  INTO   ov_max_ship_methods,
                         on_drink_deadweight,
                         on_leaf_deadweight,
                         on_drink_loading_capacity,
                         on_leaf_loading_capacity,
                         on_palette_max_qty
                  FROM   (SELECT xdlv2.ship_methods_id,
                                 MAX(xdlv2.ship_method)
                                   OVER(PARTITION BY
                                     xdlv2.code_class1,
                                     xdlv2.entering_despatching_code1,
                                     xdlv2.code_class2,
                                     xdlv2.entering_despatching_code2
                                   ) max_ship
                         FROM    xxcmn_delivery_lt2_v xdlv2,
                                 xxwsh_ship_method2_v xsmv2
                         WHERE   (CASE
                                   -- �h�����N�ύڏd��
                                   WHEN ((iv_prod_class             =  cv_drink) AND
                                          (iv_weight_capacity_class =  cv_weight)) THEN
                                     xdlv2.drink_deadweight
                                   -- ���[�t�ύڏd��
                                   WHEN ((iv_prod_class             =  cv_leaf) AND
                                          (iv_weight_capacity_class =  cv_weight)) THEN
                                     xdlv2.leaf_deadweight
                                   -- �h�����N�ύڗe��
                                   WHEN ((iv_prod_class             =  cv_drink) AND
                                          (iv_weight_capacity_class =  cv_capacity)) THEN
                                     xdlv2.drink_loading_capacity
                                   -- ���[�t�ύڗe��
                                   WHEN ((iv_prod_class             =  cv_leaf) AND
                                          (iv_weight_capacity_class =  cv_capacity)) THEN
                                     xdlv2.leaf_loading_capacity
                                 END) > 0
                         -- �R�[�h�敪�P
                         AND     xdlv2.code_class1                  =  iv_code_class1
                         -- ���o�ɏꏊ�R�[�h�P
                         AND     xdlv2.entering_despatching_code1   =  cv_all_4          --ALL'Z'
                         -- �R�[�h�敪�Q
                         AND     xdlv2.code_class2                  =  iv_code_class2
-- 2008/08/04 Mod H.Itou Start
                     -- ���o�ɏꏊ�R�[�h�Q
                       -- �R�[�h�敪��9:�o�ׂ̏ꍇ�AZZZZZZZZZ
                     AND   (((iv_code_class2                     = code_class_ship)
                         AND (xdlv2.entering_despatching_code2   = cv_all_9))          --ALL'Z'
                       -- �R�[�h�敪��4:�z���� OR 11:�x�� �̏ꍇ�AZZZZ
                       OR   ((iv_code_class2                     IN (code_class_whse, code_class_supply))
                         AND (xdlv2.entering_despatching_code2   = cv_all_4)))         --ALL'Z'
--                     AND     xdlv2.entering_despatching_code2   =  cv_all_9          --ALL'Z'
-- 2008/08/04 Mod H.Itou End
                         -- �K�p�J�n��(�z��L/T)
                         AND     ((xdlv2.lt_start_date_active       <= ld_standard_date) OR
                                   (xdlv2.lt_start_date_active      IS NULL))
                         -- �K�p�I����(�z��L/T)
                         AND     ((xdlv2.lt_end_date_active         >= ld_standard_date) OR
                                   (xdlv2.lt_end_date_active        IS NULL))
                         -- �K�p�J�n��(�o�ו��@)
                         AND     ((xdlv2.sm_start_date_active       <= ld_standard_date) OR
                                   (xdlv2.sm_start_date_active      IS NULL))
                         -- �K�p�I����(�o�ו��@)
                         AND     ((xdlv2.sm_end_date_active         >= ld_standard_date) OR
                                   (xdlv2.sm_end_date_active        IS NULL))
                         -- ���ڋ敪
                         AND     ((xsmv2.mixed_class                <> cv_object) OR
                                   (xsmv2.mixed_class               IS NULL))
                         -- �����z�ԑΏۋ敪
                         AND     ((iv_auto_process_type             IS NULL) OR
                                   (xsmv2.auto_process_type         =  cv_object))
                         -- �L���J�n��
                         AND     ((xsmv2.start_date_active          <= ld_standard_date) OR
                                   (xsmv2.start_date_active         IS NULL))
                         -- �L���I����
                         AND     ((xsmv2.end_date_active            >= ld_standard_date) OR
                                   (xsmv2.end_date_active           IS NULL))
                         AND     xdlv2.ship_method                  =  xsmv2.ship_method_code
                         ) max_ship_method,
                         xxcmn_delivery_lt2_v xdlv2
                  -- �K�p�J�n��(�z��L/T)
                  WHERE  ((xdlv2.lt_start_date_active               <= ld_standard_date) OR
                           (xdlv2.lt_start_date_active              IS NULL))
                  -- �K�p�I����(�z��L/T)
                  AND    ((xdlv2.lt_end_date_active                 >= ld_standard_date) OR
                           (xdlv2.lt_end_date_active                IS NULL))
                  -- �K�p�J�n��(�o�ו��@)
                  AND    ((xdlv2.sm_start_date_active               <= ld_standard_date) OR
                           (xdlv2.sm_start_date_active              IS NULL))
                  -- �K�p�I����(�o�ו��@)
                  AND    ((xdlv2.sm_end_date_active                 >= ld_standard_date) OR
                           (xdlv2.sm_end_date_active                IS NULL))
                  AND    max_ship_method.ship_methods_id            =  xdlv2.ship_methods_id
                  AND    max_ship_method.max_ship                   =  xdlv2.ship_method;
--
                --------- ��L1.����4.�ŎQ�Ƃ��ĊY���Ȃ��̏ꍇ -------------------
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    RAISE no_data;
--
                END;  -- 4.
            END;  -- 3.
        END;  -- 2.
    ----------- 2008/07/11 �ύX�v���Ή�#95 ADD END ------------------------------------
--
    /*----- 2008/07/11 �ύX�v���Ή�#95 DEL START -------------------------------------
    EXCEPTION 
      WHEN NO_DATA_FOUND THEN
--
      -- ��R�[�h�敪2����z����̏ꍇ
      IF (iv_code_class2 = cv_deliver_to) THEN
        BEGIN
          SELECT xdlv2.ship_method,
                 xdlv2.drink_deadweight,
                 xdlv2.leaf_deadweight,
                 xdlv2.drink_loading_capacity,
                 xdlv2.leaf_loading_capacity,
                 xdlv2.palette_max_qty
          INTO   ov_max_ship_methods,
                 on_drink_deadweight,
                 on_leaf_deadweight,
                 on_drink_loading_capacity,
                 on_leaf_loading_capacity,
                 on_palette_max_qty
          FROM   (SELECT xdlv2.ship_methods_id,
                         MAX(xdlv2.ship_method)
                           OVER(PARTITION BY
                             xdlv2.code_class1,
                             xdlv2.entering_despatching_code1,
                             xdlv2.code_class2,
                             xdlv2.entering_despatching_code2
                           ) max_ship
                 FROM    xxcmn_delivery_lt2_v xdlv2,
                         xxwsh_ship_method2_v xsmv2
                 WHERE   (CASE
                           -- �h�����N�ύڏd��
                           WHEN ((iv_prod_class             =  cv_drink) AND
                                  (iv_weight_capacity_class =  cv_weight)) THEN
                             xdlv2.drink_deadweight
                           -- ���[�t�ύڏd��
                           WHEN ((iv_prod_class             =  cv_leaf) AND
                                  (iv_weight_capacity_class =  cv_weight)) THEN
                             xdlv2.leaf_deadweight
                           -- �h�����N�ύڗe��
                           WHEN ((iv_prod_class             =  cv_drink) AND
                                  (iv_weight_capacity_class =  cv_capacity)) THEN
                             xdlv2.drink_loading_capacity
                           -- ���[�t�ύڗe��
                           WHEN ((iv_prod_class             =  cv_leaf) AND
                                  (iv_weight_capacity_class =  cv_capacity)) THEN
                             xdlv2.leaf_loading_capacity
                         END) > 0
                 -- �R�[�h�敪�P
                 AND     xdlv2.code_class1                  =  iv_code_class1
                 -- ���o�ɏꏊ�R�[�h�P
                 AND     xdlv2.entering_despatching_code1   =  iv_entering_despatching_code1
                 -- �R�[�h�敪�Q
                 AND     xdlv2.code_class2                  =  cv_base
                 -- ���o�ɏꏊ�R�[�h�Q
                 AND     xdlv2.entering_despatching_code2   =
                           (SELECT  xcas2.base_code
                           FROM     xxcmn_cust_acct_sites2_v   xcas2
                           WHERE    xcas2.ship_to_no           =  iv_entering_despatching_code2
                           AND      ((xcas2.start_date_active  <= ld_standard_date) OR
                                      (xcas2.start_date_active IS NULL))
                           AND      ((xcas2.end_date_active    >= ld_standard_date) OR
                                      (xcas2.end_date_active   IS NULL)))
                 -- �K�p�J�n��(�z��L/T)
                 AND     ((xdlv2.lt_start_date_active       <= ld_standard_date) OR
                           (xdlv2.lt_start_date_active      IS NULL))
                 -- �K�p�I����(�z��L/T)
                 AND     ((xdlv2.lt_end_date_active         >= ld_standard_date) OR
                           (xdlv2.lt_end_date_active        IS NULL))
                 -- �K�p�J�n��(�o�ו��@)
                 AND     ((xdlv2.sm_start_date_active       <= ld_standard_date) OR
                           (xdlv2.sm_start_date_active      IS NULL))
                 -- �K�p�I����(�o�ו��@)
                 AND     ((xdlv2.sm_end_date_active         >= ld_standard_date) OR
                           (xdlv2.sm_end_date_active        IS NULL))
                 -- ���ڋ敪
                 AND     ((xsmv2.mixed_class                <> cv_object) OR
                           (xsmv2.mixed_class               IS NULL))
                 -- �����z�ԑΏۋ敪
                 AND     ((iv_auto_process_type             IS NULL) OR
                           (xsmv2.auto_process_type         =  cv_object))
                 -- �L���J�n��
                 AND     ((xsmv2.start_date_active          <= ld_standard_date) OR
                           (xsmv2.start_date_active         IS NULL))
                 -- �L���I����
                 AND     ((xsmv2.end_date_active            >= ld_standard_date) OR
                           (xsmv2.end_date_active           IS NULL))
                 AND     xdlv2.ship_method                  =  xsmv2.ship_method_code
                 ) max_ship_method,
                 xxcmn_delivery_lt2_v xdlv2
          -- �K�p�J�n��(�z��L/T)
          WHERE  ((xdlv2.lt_start_date_active               <= ld_standard_date) OR
                   (xdlv2.lt_start_date_active              IS NULL))
          -- �K�p�I����(�z��L/T)
          AND    ((xdlv2.lt_end_date_active                 >= ld_standard_date) OR
                   (xdlv2.lt_end_date_active                IS NULL))
          -- �K�p�J�n��(�o�ו��@)
          AND    ((xdlv2.sm_start_date_active               <= ld_standard_date) OR
                   (xdlv2.sm_start_date_active              IS NULL))
          -- �K�p�I����(�o�ו��@)
          AND    ((xdlv2.sm_end_date_active                 >= ld_standard_date) OR
                   (xdlv2.sm_end_date_active                IS NULL))
          AND    max_ship_method.ship_methods_id            =  xdlv2.ship_methods_id
          AND    max_ship_method.max_ship                   =  xdlv2.ship_method;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            RAISE no_data;
--
        END;
--
      ELSE
        RAISE no_data;
--
      END IF;
      ---------- 2008/07/11 �ύX�v���Ή�#95 DEL END ---------------------------------*/
--
    END;  -- 1.
--
    RETURN gn_status_normal;
--
  EXCEPTION
--
    WHEN no_data THEN
      RETURN gn_status_error;
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_max_ship_method;
--
  /**********************************************************************************
   * Function Name    : get_oprtn_day
   * Description      : �ғ����Z�o�֐�
   ***********************************************************************************/
  FUNCTION get_oprtn_day(
    id_date             IN  DATE,         -- ���t
    iv_whse_code        IN  VARCHAR2,     -- �ۊǑq�ɃR�[�h
    iv_deliver_to_code  IN  VARCHAR2,     -- �z����R�[�h
    in_lead_time        IN  NUMBER,       -- ���[�h�^�C��
    iv_prod_class       IN  VARCHAR2,     -- ���i�敪
    od_oprtn_day        OUT NOCOPY DATE)  -- �ғ������t
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_oprtn_day';  --�v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_leaf       CONSTANT VARCHAR2(1)   := '1';              -- ���[�t
    cv_drink      CONSTANT VARCHAR2(1)   := '2';              -- �h�����N
    cn_active     CONSTANT NUMBER        := 0;
--
    -- *** ���[�J���ϐ� ***
    lv_calender_cd    VARCHAR2(100);    -- �J�����_�[�R�[�h
    ld_date           DATE;             -- �`�F�b�N���t
    ln_days           NUMBER;           -- �`�F�b�N����
    ln_check_flag     NUMBER;           -- �`�F�b�N�t���O
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    -- ���[�J���ϐ�������
    lv_calender_cd  := NULL;      -- �J�����_�[�R�[�h
    ld_date         := id_date;   -- �`�F�b�N���t
    ln_days         := 0;         -- �`�F�b�N����
    ln_check_flag   := NULL;      -- �`�F�b�N�t���O
--
    -- **************************************************
    -- *** �p�����[�^�`�F�b�N
    -- **************************************************
    -- �u���t�v�`�F�b�N
    IF (id_date IS NULL) THEN
      RETURN gn_status_error;
    END IF;
--
    -- �u�ۊǑq�ɃR�[�h�v�Ɓu�z����R�[�h�v�̗�����NULL�A
    -- ���́A������NOT NULL�̏ꍇ�̓G���[
    IF (((iv_whse_code IS NULL) AND (iv_deliver_to_code IS NULL)) 
       OR ((iv_whse_code IS NOT NULL) AND (iv_deliver_to_code IS NOT NULL))) THEN
      RETURN gn_status_error;
    END IF;
--
    -- �u���[�h�^�C���v�`�F�b�N
    IF ((in_lead_time IS NULL) OR (in_lead_time < 0)) THEN
      RETURN gn_status_error;
    END IF;
--
    -- �u���i�敪�v�`�F�b�N
    IF ((iv_prod_class IS NULL) OR (iv_prod_class NOT IN (cv_leaf, cv_drink))) THEN
      RETURN gn_status_error;
    END IF;
--
    -- **************************************************
    -- *** �J�����_�[�R�[�h�擾
    -- **************************************************
    -- �J�����_�R�[�h�擾�֐����ĂсA�����J�����_�w�b�_�ɑ��݂���J�����_�R�[�h�̏ꍇ�A�擾����
    BEGIN
      SELECT  msh.calendar_no
      INTO    lv_calender_cd
      FROM    mr_shcl_hdr   msh,
              mr_shcl_dtl   msd
      WHERE   msh.calendar_id   = msd.calendar_id
      AND     msd.delete_mark   = cn_active
      AND     msh.calendar_no   = xxcmn_common_pkg.get_calender_cd(iv_whse_code,
                                                                 iv_deliver_to_code,
                                                                 iv_prod_class)
      AND     ROWNUM            = 1
      ;
--
    -- �J�����_�R�[�h���擾�ł��Ȃ������ꍇ�́A�G���[
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN gn_status_error;
--
    END;
--
    -- **************************************************
    -- *** ���[�v����
    -- **************************************************
    -- �`�F�b�N�����̒l�����[�h�^�C�����傫���Ȃ�܂Ń��[�v
    <<oprtn_day_loop>>
    WHILE (ln_days <= in_lead_time) LOOP
      -- �ғ����`�F�b�N�֐����Ăяo��
      ln_check_flag := xxcmn_common_pkg.check_oprtn_day(ld_date,
                                                        lv_calender_cd);
      -- �`�F�b�N�t���O���ғ����̏ꍇ
      IF (ln_check_flag = 0) THEN
        od_oprtn_day := ld_date;
        ln_days      := ln_days + 1;
      END IF;
      ld_date := ld_date - 1;
    END LOOP oprtn_day_loop;
--
    RETURN gv_status_normal;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_oprtn_day;
--
  /**********************************************************************************
   * Function Name    : get_same_request_number
   * Description      : ����˗�No�����֐�
   ***********************************************************************************/
  FUNCTION get_same_request_number(
    iv_request_no         IN  xxwsh_order_headers_all.request_no%TYPE,      -- 1.�˗�No
    on_same_request_count OUT NUMBER,                                       -- 2.����˗�No����
    on_order_header_id    OUT xxwsh_order_headers_all.order_header_id%TYPE) -- 3.����˗�No�̎󒍃w�b�_�A�h�I��ID
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'get_same_order_number'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_cancel           CONSTANT VARCHAR2(2)   := '99';                    --���
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    -- ���̓p�����[�^�`�F�b�N
    IF ( iv_request_no IS NULL ) THEN
      RETURN gn_status_error;
    END IF;
--
    -- ����˗�No�̌����J�E���g
    SELECT COUNT(1)
    INTO   on_same_request_count
    FROM   xxwsh_order_headers_all  xoha
    WHERE  xoha.req_status  <> cv_cancel
    AND    xoha.request_no  =  iv_request_no
    ;
--
    IF (on_same_request_count > 1)
    THEN
--
      BEGIN
        -- ����˗�No�̎󒍃w�b�_�A�h�I��ID�擾
        SELECT MAX(xoha.order_header_id)
        INTO   on_order_header_id
        FROM   (SELECT xoha.order_header_id,
                       MAX(xoha.last_update_date)
                         OVER(PARTITION BY
                           xoha.request_no
                         )  max_date
               FROM    xxwsh_order_headers_all  xoha
               WHERE   xoha.req_status             IN ('04', '08')  --�o��(04)�Ǝx��(08)���ьv���
               AND     NVL(xoha.latest_external_flag, 'N')   <> 'Y'
               AND     NVL(xoha.actual_confirm_class, 'N')   =  'Y'
               AND     xoha.request_no             =  iv_request_no
               )  max_order_headers,
               xxwsh_order_headers_all  xoha
        WHERE  max_order_headers.order_header_id   =  xoha.order_header_id
        AND    max_order_headers.max_date          =  xoha.last_update_date
        ;
--
-- 2008/08/11 H.Itou Add Start  �ύX�v��#174 �󒍃w�b�_ID���擾�ł��Ȃ��ꍇ�̓G���[��Ԃ��B
      IF (on_order_header_id IS NULL) THEN
        RETURN gn_status_error;
      END IF;
-- 2008/08/11 H.Itou Add End
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
-- 2008/08/11 H.Itou Mod Start  �ύX�v��#174 ���ьv��ϋ敪��Y�̃f�[�^���Ȃ��ꍇ�̓G���[��Ԃ��B
--          NULL;
          RETURN gn_status_error;
-- 2008/08/11 H.Itou Mod End
--
      END;
--
    ELSIF (on_same_request_count = 1) THEN
--
      SELECT xoha.order_header_id
      INTO   on_order_header_id
      FROM   xxwsh_order_headers_all  xoha
      WHERE  xoha.req_status  <> cv_cancel
      AND    xoha.request_no  =  iv_request_no
      ;
--
    ELSE
      -- �w�肵���˗�No�͑��݂��܂���B
      RETURN gn_status_error;
    END IF;
    RETURN gn_status_normal;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);      
--
--###################################  �Œ蕔 END   #########################################
--
  END get_same_request_number;
--
--
  /**********************************************************************************
   * Function Name    : convert_request_number
   * Description      : �˗�No�R���o�[�g�֐�
   ***********************************************************************************/
  FUNCTION convert_request_number(
    iv_conv_div             IN  VARCHAR2,                                -- 1.�ϊ��敪
    iv_pre_conv_request_no  IN  VARCHAR2,                                -- 2.�ϊ��O�˗�No
    ov_aft_conv_request_no  OUT xxwsh_order_headers_all.request_no%TYPE) -- 3.�ϊ���˗�No
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'convert_request_number'; --�v���O������
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �����񒷃`�F�b�N�萔
    cn_nine_chars   CONSTANT NUMBER      := 9;   --  9����
    cn_twelve_chars CONSTANT NUMBER      := 12;  -- 12����
    -- �⊮������
    cn_supplement_chars CONSTANT VARCHAR2(3) := '000';  -- 000
--
    -- *** ���[�J���ϐ� ***
    lv_wsh_or_base_code VARCHAR2(4);
    ln_mast_count1      NUMBER;
    ln_mast_count2      NUMBER;
    ld_date_char        DATE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    -- ���̓p�����[�^�`�F�b�N
    IF (( iv_conv_div IS NULL ) OR ( iv_pre_conv_request_no IS NULL )) THEN
      RETURN gn_status_error;
    END IF;
    --
    -- �ϊ��敪�̃`�F�b�N
    -- �ϊ��敪-> 1�F���_�����InBound�p�A2�F���_�ւ�OutBound�p
    IF    ( iv_conv_div = '1' ) THEN
      -- [���_�����Inbound]
      -- �ϊ��O�˗�No�`�F�b�N(9��)
      IF ( LENGTHB( iv_pre_conv_request_no ) = cn_nine_chars ) THEN
        -- 9����12���ɕϊ�
        ov_aft_conv_request_no :=
          SUBSTR( iv_pre_conv_request_no, 1 , 4 )
          || cn_supplement_chars
          || SUBSTR( iv_pre_conv_request_no, 5 , 5 );
      ELSE
        RETURN gn_status_error;
      END IF;
    --
    ELSIF ( iv_conv_div = '2' ) THEN
      -- [���_�ւ�Outbound]
      -- �ϊ��O�˗�No�`�F�b�N(12��)
      IF ( LENGTHB( iv_pre_conv_request_no ) = cn_twelve_chars ) THEN
        -- �ϊ��O�˗�No�̐擪4�������擾
        lv_wsh_or_base_code := SUBSTR( iv_pre_conv_request_no, 1 , 4 );
        -- �ڋq�}�X�^�`�F�b�N
        SELECT COUNT(1)
        INTO   ln_mast_count1
--        FROM   hz_parties       hp,
--               hz_cust_accounts hca
        FROM   xxcmn_parties2_v       hp,
               xxcmn_cust_accounts2_v hca
        WHERE  lv_wsh_or_base_code  = hp.party_number
               AND
               hp.party_id          = hca.party_id
        ;
        -- OPM�ۊǏꏊ�}�X�^�`�F�b�N
        SELECT COUNT(1)
        INTO   ln_mast_count2
        FROM   xxcmn_item_locations_v xilv
        WHERE  lv_wsh_or_base_code  = xilv.segment1
        ;
        -- ���ꂩ�̃}�X�^�ɑ��݂������H
        IF (( ln_mast_count1 > 0 ) OR (ln_mast_count2 > 0 )) THEN
          -- 9���ϊ�
          ov_aft_conv_request_no :=
            SUBSTR( iv_pre_conv_request_no, 1 , 4 )
            || SUBSTR( iv_pre_conv_request_no, 8 , 5 );          
        ELSE
          --�擪4���N���`�F�b�N(�N���łȂ��ꍇ�̓G���[)
          BEGIN
            SELECT TO_DATE(SUBSTR( iv_pre_conv_request_no, 1 , 4 ),'YYMM')
            INTO   ld_date_char
            FROM   DUAL;
          EXCEPTION
            WHEN OTHERS THEN
              RETURN gn_status_error;
          END;
          -- 9���ϊ�
          ov_aft_conv_request_no :=
            SUBSTR( iv_pre_conv_request_no, 3 , 2 )
            || SUBSTR( iv_pre_conv_request_no, 6 , 7 );
--
        END IF;
      ELSE
        RETURN gn_status_error;
      END IF;
    ELSE
      RETURN gn_status_error;
    END IF;
--
    RETURN gn_status_normal;
--
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END convert_request_number;
--
--
  /**********************************************************************************
   * Function Name    : get_max_pallet_qty
   * Description      : �ő�p���b�g�����Z�o�֐�
   ***********************************************************************************/
  FUNCTION get_max_pallet_qty(
    iv_code_class1                IN  xxcmn_ship_methods.code_class1%TYPE,                 -- 1.�R�[�h�敪�P
    iv_entering_despatching_code1 IN  xxcmn_ship_methods.entering_despatching_code1%TYPE,  -- 2.���o�ɏꏊ�R�[�h�P
    iv_code_class2                IN  xxcmn_ship_methods.code_class2%TYPE,                 -- 3.�R�[�h�敪�Q
    iv_entering_despatching_code2 IN  xxcmn_ship_methods.entering_despatching_code2%TYPE,  -- 4.���o�ɏꏊ�R�[�h�Q
    id_standard_date              IN  DATE,                                                -- 5.���(�K�p�����)
    iv_ship_methods               IN  xxcmn_ship_methods.ship_method%TYPE,                 -- 6.�z���敪
    on_drink_deadweight           OUT xxcmn_ship_methods.drink_deadweight%TYPE,            -- 7.�h�����N�ύڏd��
    on_leaf_deadweight            OUT xxcmn_ship_methods.leaf_deadweight%TYPE,             -- 8.���[�t�ύڏd��
    on_drink_loading_capacity     OUT xxcmn_ship_methods.drink_loading_capacity%TYPE,      -- 9.�h�����N�ύڗe��
    on_leaf_loading_capacity      OUT xxcmn_ship_methods.leaf_loading_capacity%TYPE,       -- 10.���[�t�ύڗe��
    on_palette_max_qty            OUT xxcmn_ship_methods.palette_max_qty%TYPE)             -- 11.�p���b�g�ő喇��
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_max_pallet_qty'; --�v���O������
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_deliver_to CONSTANT VARCHAR2(1)   := '9';                  --�z����
    cv_base       CONSTANT VARCHAR2(1)   := '1';                  --���_
    cv_all_4      CONSTANT VARCHAR2(4)   := 'ZZZZ';               --2008/07/11 �ύX�v���Ή�#95
    cv_all_9      CONSTANT VARCHAR2(9)   := 'ZZZZZZZZZ';          --2008/07/11 �ύX�v���Ή�#95
--
    -- *** ���[�J���ϐ� ***
    ld_standard_date DATE;                                        --���
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    -- �K�{���̓p�����[�^�`�F�b�N
    IF (  ( iv_code_class1                IS NULL ) 
       OR ( iv_entering_despatching_code1 IS NULL )
       OR ( iv_code_class2                IS NULL )
       OR ( iv_entering_despatching_code2 IS NULL )
       OR ( iv_ship_methods               IS NULL )) THEN
      RETURN gn_status_error;
    END IF;
--
    -- �u���(�K�p�����)�v���w�肳��Ȃ��ꍇ�̓V�X�e�����t
    IF ( id_standard_date IS NULL) THEN
      ld_standard_date := TRUNC(SYSDATE);
    ELSE
      ld_standard_date := TRUNC(id_standard_date);
    END IF;
--
    ------------ 1. �q��(�ʃR�[�h)�|�z����(�ʃR�[�h) --------------------------
    BEGIN
      SELECT
        xdlv2.drink_deadweight,                                             -- �h�����N�ύڏd��
        xdlv2.leaf_deadweight,                                              -- ���[�t�ύڏd��
        xdlv2.drink_loading_capacity,                                       -- �h�����N�ύڗe��
        xdlv2.leaf_loading_capacity,                                        -- ���[�t�ύڗe��
        xdlv2.palette_max_qty                                               -- �p���b�g�ő喇��
      INTO
        on_drink_deadweight,
        on_leaf_deadweight,
        on_drink_loading_capacity,
        on_leaf_loading_capacity,
        on_palette_max_qty
      FROM
        xxcmn_delivery_lt2_v  xdlv2
      WHERE
        xdlv2.code_class1                 =  iv_code_class1                 -- �R�[�h�敪�P
        AND
        xdlv2.entering_despatching_code1  =  iv_entering_despatching_code1  -- ���o�ɏꏊ�R�[�h�P�i�ʁj
        AND
        xdlv2.code_class2                 =  iv_code_class2                 -- �R�[�h�敪�Q
        AND
        xdlv2.entering_despatching_code2  =  iv_entering_despatching_code2  -- ���o�ɏꏊ�R�[�h�Q�i�ʁj
        AND
        xdlv2.lt_start_date_active       <=  ld_standard_date               -- �K�p�J�n��(�z��L/T)
        AND
        xdlv2.lt_end_date_active         >=  ld_standard_date               -- �K�p�I����(�z��L/T)
        AND
        xdlv2.ship_method                 =  iv_ship_methods                -- �o�ו��@
        AND
        xdlv2.sm_start_date_active       <=  ld_standard_date               -- �K�p�J�n��(�o�ו��@)
        AND
        xdlv2.sm_end_date_active         >=  ld_standard_date ;             -- �K�p�I����(�o�ו��@)
--
    ------------- 2008/07/11 �ύX�v���Ή�#95 ADD START --------------------------------------
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
-- 2008/08/04 Del H.Itou Start
--        IF (iv_code_class2 <> cv_deliver_to) THEN  -- �R�[�h�敪�Q<>�u9:�z���v�̏ꍇ�͍Č������Ȃ�
--          RAISE no_data;
--        END IF;
-- 2008/08/04 Del H.Itou End
--
        --------------- 2. �q��(ALL�l)�|�z����(�ʃR�[�h) --------------------------
        BEGIN
          SELECT
            xdlv2.drink_deadweight,                                             -- �h�����N�ύڏd��
            xdlv2.leaf_deadweight,                                              -- ���[�t�ύڏd��
            xdlv2.drink_loading_capacity,                                       -- �h�����N�ύڗe��
            xdlv2.leaf_loading_capacity,                                        -- ���[�t�ύڗe��
            xdlv2.palette_max_qty                                               -- �p���b�g�ő喇��
          INTO
            on_drink_deadweight,
            on_leaf_deadweight,
            on_drink_loading_capacity,
            on_leaf_loading_capacity,
            on_palette_max_qty
          FROM
            xxcmn_delivery_lt2_v  xdlv2
          WHERE
            xdlv2.code_class1                 =  iv_code_class1                 -- �R�[�h�敪�P
            AND
            xdlv2.entering_despatching_code1  =  cv_all_4                       -- ���o�ɏꏊ�R�[�h�P�iALL'Z'�j
            AND
            xdlv2.code_class2                 =  iv_code_class2                 -- �R�[�h�敪�Q
            AND
            xdlv2.entering_despatching_code2  =  iv_entering_despatching_code2  -- ���o�ɏꏊ�R�[�h�Q�i�ʁj
            AND
            xdlv2.lt_start_date_active       <=  ld_standard_date               -- �K�p�J�n��(�z��L/T)
            AND
            xdlv2.lt_end_date_active         >=  ld_standard_date               -- �K�p�I����(�z��L/T)
            AND
            xdlv2.ship_method                 =  iv_ship_methods                -- �o�ו��@
            AND
            xdlv2.sm_start_date_active       <=  ld_standard_date               -- �K�p�J�n��(�o�ו��@)
            AND
            xdlv2.sm_end_date_active         >=  ld_standard_date ;             -- �K�p�I����(�o�ו��@)
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -------------- 3. �q��(�ʃR�[�h)�|�z����(ALL�l) ------------------------
            BEGIN
              SELECT
                xdlv2.drink_deadweight,                                             -- �h�����N�ύڏd��
                xdlv2.leaf_deadweight,                                              -- ���[�t�ύڏd��
                xdlv2.drink_loading_capacity,                                       -- �h�����N�ύڗe��
                xdlv2.leaf_loading_capacity,                                        -- ���[�t�ύڗe��
                xdlv2.palette_max_qty                                               -- �p���b�g�ő喇��
              INTO
                on_drink_deadweight,
                on_leaf_deadweight,
                on_drink_loading_capacity,
                on_leaf_loading_capacity,
                on_palette_max_qty
              FROM
                xxcmn_delivery_lt2_v  xdlv2
              WHERE
                xdlv2.code_class1                 =  iv_code_class1                 -- �R�[�h�敪�P
                AND
                xdlv2.entering_despatching_code1  =  iv_entering_despatching_code1  -- ���o�ɏꏊ�R�[�h�P�i�ʁj
                AND
                xdlv2.code_class2                 =  iv_code_class2                 -- �R�[�h�敪�Q
-- 2008/08/04 Mod H.Itou Start
                -- ���o�ɏꏊ�R�[�h�Q
                AND
                  -- �R�[�h�敪��9:�o�ׂ̏ꍇ�AZZZZZZZZZ
                      (((iv_code_class2                     = code_class_ship)
                    AND (xdlv2.entering_despatching_code2   = cv_all_9))          --ALL'Z'
                  -- �R�[�h�敪��4:�z���� OR 11:�x�� �̏ꍇ�AZZZZ
                  OR   ((iv_code_class2                     IN (code_class_whse, code_class_supply))
                    AND (xdlv2.entering_despatching_code2   = cv_all_4)))         --ALL'Z'
--                AND
--                xdlv2.entering_despatching_code2  =  cv_all_9                       -- ���o�ɏꏊ�R�[�h�Q�iALL'Z'�j
-- 2008/08/04 Mod H.Itou End
                AND
                xdlv2.lt_start_date_active       <=  ld_standard_date               -- �K�p�J�n��(�z��L/T)
                AND
                xdlv2.lt_end_date_active         >=  ld_standard_date               -- �K�p�I����(�z��L/T)
                AND
                xdlv2.ship_method                 =  iv_ship_methods                -- �o�ו��@
                AND
                xdlv2.sm_start_date_active       <=  ld_standard_date               -- �K�p�J�n��(�o�ו��@)
                AND
                xdlv2.sm_end_date_active         >=  ld_standard_date ;             -- �K�p�I����(�o�ו��@)
--
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -------------- 4. �q��(ALL�l)�|�z����(ALL�l) ---------------------------
                BEGIN
                  SELECT
                    xdlv2.drink_deadweight,                                             -- �h�����N�ύڏd��
                    xdlv2.leaf_deadweight,                                              -- ���[�t�ύڏd��
                    xdlv2.drink_loading_capacity,                                       -- �h�����N�ύڗe��
                    xdlv2.leaf_loading_capacity,                                        -- ���[�t�ύڗe��
                    xdlv2.palette_max_qty                                               -- �p���b�g�ő喇��
                  INTO
                    on_drink_deadweight,
                    on_leaf_deadweight,
                    on_drink_loading_capacity,
                    on_leaf_loading_capacity,
                    on_palette_max_qty
                  FROM
                    xxcmn_delivery_lt2_v  xdlv2
                  WHERE
                    xdlv2.code_class1                 =  iv_code_class1                 -- �R�[�h�敪�P
                    AND
                    xdlv2.entering_despatching_code1  =  cv_all_4                       -- ���o�ɏꏊ�R�[�h�P�iALL'Z'�j
                    AND
                    xdlv2.code_class2                 =  iv_code_class2                 -- �R�[�h�敪�Q
-- 2008/08/04 Mod H.Itou Start
                -- ���o�ɏꏊ�R�[�h�Q
                AND
                  -- �R�[�h�敪��9:�o�ׂ̏ꍇ�AZZZZZZZZZ
                      (((iv_code_class2                     = code_class_ship)
                    AND (xdlv2.entering_despatching_code2   = cv_all_9))          --ALL'Z'
                  -- �R�[�h�敪��4:�z���� OR 11:�x�� �̏ꍇ�AZZZZ
                  OR   ((iv_code_class2                     IN (code_class_whse, code_class_supply))
                    AND (xdlv2.entering_despatching_code2   = cv_all_4)))         --ALL'Z'
--                AND
--                xdlv2.entering_despatching_code2  =  cv_all_9                       -- ���o�ɏꏊ�R�[�h�Q�iALL'Z'�j
-- 2008/08/04 Mod H.Itou End
                    AND
                    xdlv2.lt_start_date_active       <=  ld_standard_date               -- �K�p�J�n��(�z��L/T)
                    AND
                    xdlv2.lt_end_date_active         >=  ld_standard_date               -- �K�p�I����(�z��L/T)
                    AND
                    xdlv2.ship_method                 =  iv_ship_methods                -- �o�ו��@
                    AND
                    xdlv2.sm_start_date_active       <=  ld_standard_date               -- �K�p�J�n��(�o�ו��@)
                    AND
                    xdlv2.sm_end_date_active         >=  ld_standard_date ;             -- �K�p�I����(�o�ו��@)
--
                -------------- ��L1.����4.�ŎQ�Ƃ��ĊY���Ȃ��̏ꍇ ---------------------
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    RAISE no_data;
--
                END;  -- 4.
            END;  -- 3.
        END;  -- 2.
    ----------- 2008/07/11 �ύX�v���Ή�#95 ADD END ------------------------------------
--
    /*----- 2008/07/11 �ύX�v���Ή�#95 DEL START -------------------------------------
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
--
      IF (iv_code_class2 = cv_deliver_to) THEN
        BEGIN
          SELECT
            xdlv2.drink_deadweight,                                             -- �h�����N�ύڏd��
            xdlv2.leaf_deadweight,                                              -- ���[�t�ύڏd��
            xdlv2.drink_loading_capacity,                                       -- �h�����N�ύڗe��
            xdlv2.leaf_loading_capacity,                                        -- ���[�t�ύڗe��
            xdlv2.palette_max_qty                                               -- �p���b�g�ő喇��
          INTO
            on_drink_deadweight,
            on_leaf_deadweight,
            on_drink_loading_capacity,
            on_leaf_loading_capacity,
            on_palette_max_qty
          FROM
            xxcmn_delivery_lt2_v  xdlv2
          WHERE
            xdlv2.code_class1                 =  iv_code_class1                 -- �R�[�h�敪�P
            AND
            xdlv2.entering_despatching_code1  =  iv_entering_despatching_code1  -- ���o�ɏꏊ�R�[�h�P
            AND
            xdlv2.code_class2                 =  cv_base                        -- �R�[�h�敪�Q
            AND
            xdlv2.entering_despatching_code2  =
              (SELECT  xcas2.base_code
              FROM    xxcmn_cust_acct_sites2_v  xcas2
              WHERE   xcas2.ship_to_no         = iv_entering_despatching_code2
              AND     xcas2.start_date_active <= id_standard_date
              AND     xcas2.end_date_active   >= id_standard_date)              -- ���o�ɏꏊ�R�[�h�Q
            AND
            xdlv2.lt_start_date_active       <=  ld_standard_date               -- �K�p�J�n��(�z��L/T)
            AND
            xdlv2.lt_end_date_active         >=  ld_standard_date               -- �K�p�I����(�z��L/T)
            AND
            xdlv2.ship_method                 =  iv_ship_methods                -- �o�ו��@
            AND
            xdlv2.sm_start_date_active       <=  ld_standard_date               -- �K�p�J�n��(�o�ו��@)
            AND
            xdlv2.sm_end_date_active         >=  ld_standard_date;              -- �K�p�I����(�o�ו��@)
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            RAISE no_data;
--
        END;
--
      ELSE
        RAISE no_data;
--
      END IF;
      ---------- 2008/07/11 �ύX�v���Ή�#95 DEL END ---------------------------------*/
--
    END;  --1.
--
    RETURN gn_status_normal;
--
  EXCEPTION
--
    WHEN no_data THEN
      RETURN gn_status_error;
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_max_pallet_qty;
--
  /**********************************************************************************
   * Function Name    : check_tightening_status
   * Description      : ���߃X�e�[�^�X�`�F�b�N�֐�
   ***********************************************************************************/
  FUNCTION check_tightening_status(
    -- 1.�󒍃^�C�vID
    in_order_type_id          IN  xxwsh_tightening_control.order_type_id%TYPE,
    -- 2.�o�׌��ۊǏꏊ
    iv_deliver_from           IN  xxwsh_tightening_control.deliver_from%TYPE,
    -- 3.���_
    iv_sales_branch           IN  xxwsh_tightening_control.sales_branch%TYPE,
    -- 4.���_�J�e�S��
    iv_sales_branch_category  IN  xxwsh_tightening_control.sales_branch_category%TYPE,
    -- 5.���Y����LT
    in_lead_time_day          IN  xxwsh_tightening_control.lead_time_day%TYPE,
    -- 6.�o�ɓ�
    id_ship_date              IN  xxwsh_tightening_control.schedule_ship_date%TYPE,
    -- 7.���i�敪
    iv_prod_class             IN  xxwsh_tightening_control.prod_class%TYPE)
    RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'check_tightening_status'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cn_all                CONSTANT NUMBER        := -999;                      -- ALL(���l����)
    cv_all                CONSTANT VARCHAR2(3)   := 'ALL';                     -- ALL(��������)
    cv_yes                CONSTANT VARCHAR2(1)   := 'Y';                       -- YES
    cv_no                 CONSTANT VARCHAR2(1)   := 'N';                       -- NO
    cv_close              CONSTANT VARCHAR2(1)   := '1';                       -- ����
    cv_cancel             CONSTANT VARCHAR2(1)   := '2';                       -- ����
    cv_inside_err         CONSTANT VARCHAR2(2)   := '-1';                      -- �����G���[
    cv_close_proc_n_enfo  CONSTANT VARCHAR2(1)   := '1';                       -- ���ߏ��������{
    cv_first_close_fin    CONSTANT VARCHAR2(1)   := '2';                       -- ������ߍ�
    cv_close_cancel       CONSTANT VARCHAR2(1)   := '3';                       -- ���߉���
    cv_re_close_fin       CONSTANT VARCHAR2(1)   := '4';                       -- �Ē��ߍ�
    cv_customer_class_code_1 CONSTANT VARCHAR2(1)   := '1';                    -- �ڋq�敪�F1
    cv_prod_class_1       CONSTANT VARCHAR2(1)   := '1';                       -- ���i�敪�F1
    cv_prod_class_2       CONSTANT VARCHAR2(1)   := '2';                       -- ���i�敪�F2
    cv_sales_branch_category_0 CONSTANT VARCHAR2(1)   := '0';                    -- ���_�J�e�S���F0
--
    -- *** ���[�J���ϐ� ***
    ln_count                  NUMBER;            -- �J�E���g����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    BEGIN
      -- ���߉�����ԃ`�F�b�N
      -- �p�����[�^�u���_�v�����͂��ꂽ�ꍇ
      IF ((iv_sales_branch IS NOT NULL) AND (iv_sales_branch <> 'ALL')) THEN
        -- �u���_�v����сA�u���_�v�ɕR�t���u���_�J�e�S���v�ŉ������R�[�h������      
        SELECT  COUNT(*)
        INTO    ln_count
        FROM    xxwsh_tightening_control  xtc
               ,xxcmn_cust_accounts2_v    xcav
        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
        AND     xtc.sales_branch          IN (NVL(iv_sales_branch, cv_all), cv_all)
        AND     DECODE(xtc.sales_branch_category,NULL,cv_all
                                                ,xtc.sales_branch_category)
                                          IN (DECODE(xtc.prod_class
                                                     , cv_prod_class_2, xcav.drink_base_category
                                                     , cv_prod_class_1, xcav.leaf_base_category)
                                              ,cv_all)
        AND     xtc.lead_time_day         =  in_lead_time_day
        AND     xtc.schedule_ship_date    =  id_ship_date
        AND     xtc.prod_class            =  iv_prod_class
        AND     xtc.base_record_class     =  cv_no
        AND     xtc.tighten_release_class =  cv_cancel
        AND     xcav.party_number         =  iv_sales_branch
        AND     xcav.start_date_active    <= id_ship_date
        AND     xcav.end_date_active      >= id_ship_date
        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        -- ���v����f�[�^������΢���߉������Ԃ�
-- Ver1.13 Start
--        IF (ln_count = 1) THEN
        IF (ln_count > 0) THEN
          RETURN cv_close_cancel;
        -- �������R�[�h�擾���ꂽ�ꍇ�͢�����G���[���Ԃ�
--        ELSIF (ln_count > 1) THEN
--          RETURN cv_inside_err;
        END IF;
-- Ver1.13 End
--
      -- �p3�����[�^�u���_�J�e�S���v�����͂��ꂽ�ꍇ
-- Ver1.13 Start
      ELSIF ((iv_sales_branch_category IS NOT NULL)
        AND (iv_sales_branch_category <> 'ALL'
          AND iv_sales_branch_category <> cv_sales_branch_category_0)) THEN
--      ELSIF ((iv_sales_branch_category IS NOT NULL) AND (iv_sales_branch_category <> 'ALL')) THEN
-- Ver1.13 End
--      ELSIF (iv_sales_branch_category IS NOT NULL) THEN
        -- �u���_�J�e�S���v����сA�u���_�J�e�S���v�ɕR�t���S�Ắu���_�v�ŉ������R�[�h������
        SELECT  COUNT(*)
        INTO    ln_count
        FROM    xxwsh_tightening_control  xtc
               ,xxcmn_cust_accounts2_v    xcav
        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
        AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
        AND     xtc.lead_time_day         =  in_lead_time_day
        AND     xtc.schedule_ship_date    =  id_ship_date
        AND     xtc.prod_class            =  iv_prod_class
        AND     xtc.base_record_class     =  cv_no
        AND     xtc.tighten_release_class =  cv_cancel
        AND     xtc.sales_branch          IN (xcav.party_number, cv_all)
        AND     iv_sales_branch_category
                                          IN (DECODE(iv_prod_class
                                 , cv_prod_class_2, xcav.drink_base_category
                                 , cv_prod_class_1, xcav.leaf_base_category)
                                 ,cv_all)
        AND     xcav.start_date_active    <= id_ship_date
        AND     xcav.end_date_active      >= id_ship_date
        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        -- ���v����f�[�^��1���ł�����΢���߉������Ԃ�
        IF (ln_count > 0) THEN
          RETURN cv_close_cancel;
        END IF;
--
      -- �p�����[�^�u���_�v����сu���_�J�e�S���v��'ALL'�̏ꍇ
-- Ver1.13 Start
      ELSIF (NVL(iv_sales_branch,cv_all) = cv_all)
        AND (NVL(iv_sales_branch_category,cv_all) IN (cv_all,cv_sales_branch_category_0)) THEN
--      ELSIF (iv_sales_branch = cv_all) AND (iv_sales_branch_category = cv_all) THEN
-- Ver1.13 End
        SELECT  COUNT(*)
        INTO    ln_count
        FROM    xxwsh_tightening_control  xtc
-- Ver1.13 Start
-- �g�p���Ă��Ȃ��e�[�u���̂��ߍ폜
--               ,xxcmn_cust_accounts2_v    xcav
-- Ver1.13 End
        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
        AND     xtc.lead_time_day         =  in_lead_time_day
        AND     xtc.schedule_ship_date    =  id_ship_date
        AND     xtc.prod_class            =  iv_prod_class
        AND     xtc.base_record_class     =  cv_no
        AND     xtc.tighten_release_class =  cv_cancel;
--
        -- ���v����f�[�^��1���ł�����΢���߉������Ԃ�
        IF (ln_count > 0) THEN
          RETURN cv_close_cancel;
        END IF;
      END IF;
--
      -- �Ē��ߏ�ԃ`�F�b�N
      -- �p�����[�^�u���_�v�����͂��ꂽ�ꍇ
--      IF (iv_sales_branch IS NOT NULL) THEN
      IF ((iv_sales_branch IS NOT NULL) AND (iv_sales_branch <> 'ALL')) THEN
        -- �u���_�v����сA�u���_�v�ɕR�t���u���_�J�e�S���v�ŉ������R�[�h������
        SELECT  COUNT(*)
        INTO    ln_count
        FROM    xxwsh_tightening_control  xtc
               ,xxcmn_cust_accounts2_v    xcav
        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
        AND     xtc.sales_branch          IN (NVL(iv_sales_branch, cv_all), cv_all)
        AND     DECODE(xtc.sales_branch_category,NULL,cv_all
                                                ,xtc.sales_branch_category)
                                          IN (DECODE(xtc.prod_class
                                                     , cv_prod_class_2, xcav.drink_base_category
                                                     , cv_prod_class_1, xcav.leaf_base_category)
                                              ,cv_all)
        AND     xtc.lead_time_day         =  in_lead_time_day
        AND     xtc.schedule_ship_date    =  id_ship_date
        AND     xtc.prod_class            =  iv_prod_class
        AND     xtc.base_record_class     =  cv_no
        AND     xtc.tighten_release_class =  cv_close
        AND     xcav.party_number         =  iv_sales_branch
        AND     xcav.start_date_active    <= id_ship_date
        AND     xcav.end_date_active      >= id_ship_date
        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        -- ���v����f�[�^������΢�Ē��ߍςݣ��Ԃ�
-- Ver1.13 Start
--        IF (ln_count = 1) THEN
        IF (ln_count > 0) THEN
          RETURN cv_re_close_fin;
        -- �������R�[�h�擾���ꂽ�ꍇ�͢�����G���[���Ԃ�
--        ELSIF (ln_count > 1) THEN
--          RETURN cv_inside_err;
        END IF;
-- Ver1.13 End
--
      -- �p�����[�^�u���_�J�e�S���v�����͂��ꂽ�ꍇ
-- Ver1.13 Start
      ELSIF ((iv_sales_branch_category IS NOT NULL)
        AND (iv_sales_branch_category <> 'ALL'
          AND iv_sales_branch_category <> cv_sales_branch_category_0)) THEN
--      ELSIF ((iv_sales_branch_category IS NOT NULL) AND (iv_sales_branch_category <> 'ALL')) THEN
-- Ver1.13 End
--      ELSIF (iv_sales_branch_category IS NOT NULL) THEN
        -- �u���_�J�e�S���v����сA�u���_�J�e�S���v�ɕR�t���S�Ắu���_�v�ŉ������R�[�h������
        SELECT  COUNT(*)
        INTO    ln_count
        FROM    xxwsh_tightening_control  xtc
               ,xxcmn_cust_accounts2_v    xcav
        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
        AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
        AND     xtc.lead_time_day         =  in_lead_time_day
        AND     xtc.schedule_ship_date    =  id_ship_date
        AND     xtc.prod_class            =  iv_prod_class
        AND     xtc.base_record_class     =  cv_no
        AND     xtc.tighten_release_class =  cv_close
        AND     xtc.sales_branch          IN (xcav.party_number, cv_all)
        AND     iv_sales_branch_category
                                          IN (DECODE(iv_prod_class
                                 , cv_prod_class_2, xcav.drink_base_category
                                 , cv_prod_class_1, xcav.leaf_base_category)
                                 ,cv_all)
        AND     xcav.start_date_active    <= id_ship_date
        AND     xcav.end_date_active      >= id_ship_date
        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        -- ���v����f�[�^��1���ł�����΢�Ē��ߍςݣ��Ԃ�
        IF (ln_count > 0) THEN
          RETURN cv_re_close_fin;
        END IF;
--
      -- �p�����[�^�u���_�v����сu���_�J�e�S���v��'ALL'�̏ꍇ
-- Ver1.13 Start
      ELSIF (NVL(iv_sales_branch,cv_all) = cv_all)
        AND (NVL(iv_sales_branch_category,cv_all) IN (cv_all,cv_sales_branch_category_0)) THEN
--      ELSIF (iv_sales_branch = cv_all) AND (iv_sales_branch_category = cv_all) THEN
-- Ver1.13 End
        SELECT  COUNT(*)
        INTO    ln_count
        FROM    xxwsh_tightening_control  xtc
        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
        AND     xtc.lead_time_day         =  in_lead_time_day
        AND     xtc.schedule_ship_date    =  id_ship_date
        AND     xtc.prod_class            =  iv_prod_class
        AND     xtc.base_record_class     =  cv_no
        AND     xtc.tighten_release_class =  cv_close;
--
        -- ���v����f�[�^��1���ł�����΢�Ē��ߍςݣ��Ԃ�
        IF (ln_count > 0) THEN
          RETURN cv_re_close_fin;
        END IF;
      END IF;
--
      -- ������ߏ�ԃ`�F�b�N
      -- �p�����[�^�u���_�v�����͂��ꂽ�ꍇ
      IF ((iv_sales_branch IS NOT NULL) AND (iv_sales_branch <> 'ALL')) THEN
        -- �u���_�v����сA�u���_�v�ɕR�t���u���_�J�e�S���v�ŉ������R�[�h������
        SELECT  COUNT(*)
        INTO    ln_count
        FROM    xxwsh_tightening_control  xtc
               ,xxcmn_cust_accounts2_v    xcav
        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
        AND     xtc.sales_branch          IN (NVL(iv_sales_branch, cv_all), cv_all)
        AND     DECODE(xtc.sales_branch_category,NULL,cv_all
                                                ,xtc.sales_branch_category)
                                          IN (DECODE(xtc.prod_class
                                                     , cv_prod_class_2, xcav.drink_base_category
                                                     , cv_prod_class_1, xcav.leaf_base_category)
                                              ,cv_all)
        AND     xtc.lead_time_day         =  in_lead_time_day
        AND     xtc.schedule_ship_date    =  id_ship_date
        AND     xtc.prod_class            =  iv_prod_class
        AND     xtc.base_record_class     =  cv_yes
        AND     xtc.tighten_release_class =  cv_close
        AND     xcav.party_number         =  iv_sales_branch
        AND     xcav.start_date_active    <= id_ship_date
        AND     xcav.end_date_active      >= id_ship_date
        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        -- ���v����f�[�^������΢������ߍϣ��Ԃ�
-- Ver1.13 Start
--        IF (ln_count = 1) THEN
        IF (ln_count > 0) THEN
          RETURN cv_first_close_fin;
        -- �������R�[�h�擾���ꂽ�ꍇ�͢�����G���[���Ԃ�
--        ELSIF (ln_count > 1) THEN
--          RETURN cv_inside_err;
        END IF;
-- Ver1.13 End
--
      -- �p�����[�^�u���_�J�e�S���v�����͂��ꂽ�ꍇ
-- Ver1.13 Start
      ELSIF ((iv_sales_branch_category IS NOT NULL)
        AND (iv_sales_branch_category <> 'ALL'
          AND iv_sales_branch_category <> cv_sales_branch_category_0)) THEN
--      ELSIF ((iv_sales_branch_category IS NOT NULL) AND (iv_sales_branch_category <> 'ALL')) THEN
-- Ver1.13 End
        -- �u���_�J�e�S���v����сA�u���_�J�e�S���v�ɕR�t���S�Ắu���_�v�ŉ������R�[�h������
        SELECT  COUNT(*)
        INTO    ln_count
        FROM    xxwsh_tightening_control  xtc
               ,xxcmn_cust_accounts2_v    xcav
        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
        AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
        AND     xtc.lead_time_day         =  in_lead_time_day
        AND     xtc.schedule_ship_date    =  id_ship_date
        AND     xtc.prod_class            =  iv_prod_class
        AND     xtc.base_record_class     =  cv_yes
        AND     xtc.tighten_release_class =  cv_close
        AND     xtc.sales_branch          IN (xcav.party_number, cv_all)
        AND     iv_sales_branch_category
                                          IN (DECODE(iv_prod_class
                                 , cv_prod_class_2, xcav.drink_base_category
                                 , cv_prod_class_1, xcav.leaf_base_category)
                                 ,cv_all)
        AND     xcav.start_date_active    <= id_ship_date
        AND     xcav.end_date_active      >= id_ship_date
        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        -- ���v����f�[�^��1���ł�����΢������ߍϣ��Ԃ�
        IF (ln_count > 0) THEN
          RETURN cv_first_close_fin;
        END IF;
--
      -- �p�����[�^�u���_�v����сu���_�J�e�S���v��'ALL'�̏ꍇ
-- Ver1.13 Start
      ELSIF (NVL(iv_sales_branch,cv_all) = cv_all)
        AND (NVL(iv_sales_branch_category,cv_all) IN (cv_all,cv_sales_branch_category_0)) THEN
--V1.13 mod      ELSIF (iv_sales_branch = cv_all) AND (iv_sales_branch_category = cv_all) THEN
--      ELSIF (NVL(iv_sales_branch, cv_all) = cv_all) AND (NVL(iv_sales_branch_category, cv_all) = cv_all) THEN
-- Ver1.13 End
        SELECT  COUNT(*)
        INTO    ln_count
        FROM    xxwsh_tightening_control  xtc
        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
        AND     xtc.lead_time_day         =  in_lead_time_day
        AND     xtc.schedule_ship_date    =  id_ship_date
        AND     xtc.prod_class            =  iv_prod_class
        AND     xtc.base_record_class     =  cv_yes
        AND     xtc.tighten_release_class =  cv_close;
--
        -- ���v����f�[�^��1���ł�����΢������ߍϣ��Ԃ�
        IF (ln_count > 0) THEN
          RETURN cv_first_close_fin;
        END IF;
      END IF;
--
      -- ���v����f�[�^���Ȃ��ꍇ�͢���ߏ��������{���Ԃ�
      RETURN cv_close_proc_n_enfo;
--
    EXCEPTION
      -- ���̑��̗�O���ɂ͢�����G���[���Ԃ�
      WHEN OTHERS THEN
        RETURN cv_inside_err;
    END;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END check_tightening_status;
--
  /**********************************************************************************
   * Function Name    : update_line_items
   * Description      : �d�ʗe�Ϗ������X�V�֐�
   ***********************************************************************************/
  FUNCTION update_line_items(
    iv_biz_type             IN  VARCHAR2,                                -- 1.�Ɩ����
    iv_request_no           IN  VARCHAR2)                                -- 2.�˗�No/�ړ��ԍ�
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_line_items'; --�v���O������
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_ship_req             CONSTANT VARCHAR2(1)   := '1';                   -- �o�׈˗�
    cv_supply_req           CONSTANT VARCHAR2(1)   := '2';                   -- �x���˗�
    cv_move_req             CONSTANT VARCHAR2(1)   := '3';                   -- �ړ��w��
    cv_flag_yes             CONSTANT VARCHAR2(1)   := 'Y';                   -- YES
    cv_flag_no              CONSTANT VARCHAR2(1)   := 'N';                   -- NO
    cv_ship                 CONSTANT VARCHAR2(1)   := '1';                   -- �o��
    cv_supply               CONSTANT VARCHAR2(1)   := '2';                   -- �x��
    cv_move                 CONSTANT VARCHAR2(1)   := '3';                   -- �ړ�
    cv_shiped_confirm       CONSTANT VARCHAR2(2)   := '04';                  -- �o�׎��ьv���
    cv_shiped_confirm_prov  CONSTANT VARCHAR2(2)   := '08';                 -- �o�׎��ьv���(�x��)
    cv_shiped_report        CONSTANT VARCHAR2(2)   := '04';                  -- �o�ɕ񍐗L
    cv_delivery_report      CONSTANT VARCHAR2(2)   := '06';                  -- ���o�ɕ񍐗L
    cv_include              CONSTANT VARCHAR2(1)   := '1';                   -- �Ώ�
    cv_whse                 CONSTANT VARCHAR2(1)   := '4';                   -- �q��
    cv_deliver_to           CONSTANT VARCHAR2(1)   := '9';                   -- �z����
    cv_supply_to            CONSTANT VARCHAR2(2)   := '11';                  -- �x����
    cv_product              CONSTANT VARCHAR2(1)   := '1';                   -- ���i
    cv_colon                CONSTANT VARCHAR2(1)   := ':';                   -- �R����
    cv_log_level            CONSTANT VARCHAR2(1)   := '6';                   -- ���O���x��
    cv_msg_kbn              CONSTANT VARCHAR2(5)   := 'XXWSH';               -- �o��
    cv_xoha                 CONSTANT VARCHAR2(100) := '�󒍃w�b�_�A�h�I��';
    cv_xola                 CONSTANT VARCHAR2(100) := '�󒍖��׃A�h�I��';
    cv_mrih                 CONSTANT VARCHAR2(100) := '�ړ��˗�/�w���w�b�_(�A�h�I��)';
    cv_mril                 CONSTANT VARCHAR2(100) := '�ړ��˗�/�w������(�A�h�I��)';
    cv_xcs                  CONSTANT VARCHAR2(100) := '�z�Ԕz���v��(�A�h�I��)';
    cv_small_sum_class      CONSTANT VARCHAR2(100) := '�����敪';
    cv_carriers_info        CONSTANT VARCHAR2(100) := '�z�Ԋ���';
    cv_order_lines_item_mst CONSTANT VARCHAR2(100) := '�󒍖��׃A�h�I���OPM�i�ڃ}�X�^';
    cv_mov_lines_item_mst   CONSTANT VARCHAR2(100) := '�ړ��˗�/�w������(�A�h�I��)�OPM�i�ڃ}�X�^';
    cv_order_mov_headers    CONSTANT VARCHAR2(100)
      := '�󒍃w�b�_�A�h�I����ړ��˗�/�w������(�A�h�I��)';
    cv_type_ship            CONSTANT VARCHAR2(10)  := '�o��';
    cv_type_supply          CONSTANT VARCHAR2(10)  := '�x��';
    cv_type_move            CONSTANT VARCHAR2(10)  := '�ړ�';
    cv_request_no           CONSTANT VARCHAR2(10)  := '�˗�No';
    cv_move_no              CONSTANT VARCHAR2(10)  := '�ړ��ԍ�';
    cv_tkn_table            CONSTANT VARCHAR2(20)  := 'TABLE';               -- TABLE
    cv_tkn_api_name         CONSTANT VARCHAR2(20)  := 'API_NAME';            -- API_NAME
    cv_tkn_type             CONSTANT VARCHAR2(20)  := 'TYPE';                -- TYPE
    cv_tkn_no_type          CONSTANT VARCHAR2(20)  := 'NO_TYPE';             -- NO_TYPE
    cv_tkn_request_no       CONSTANT VARCHAR2(20)  := 'REQUEST_NO';          -- REQUEST_NO
    cv_tkn_def_line_num     CONSTANT VARCHAR2(20)  := 'DEFAULT_LINE_NUMBER'; -- DEFAULT_LINE_NUMBER
    cv_tkn_err_msg          CONSTANT VARCHAR2(20)  := 'ERR_MSG';             -- ERR_MSG
    cv_para_err             CONSTANT VARCHAR2(100) := 'APP-XXWSH-10012';     -- ���̓p�����[�^�G���[
    cv_get_err              CONSTANT VARCHAR2(100) := 'APP-XXWSH-10013';     -- �擾�G���[
    cv_api_err              CONSTANT VARCHAR2(100) := 'APP-XXWSH-10014';     -- API���s�G���[
    cv_update_err           CONSTANT VARCHAR2(100) := 'APP-XXWSH-10015';     -- �X�V�G���[
    cv_get_carry_err        CONSTANT VARCHAR2(100) := 'APP-XXWSH-10016';     -- �擾�G���[(�z��)
    cv_api_carry_err        CONSTANT VARCHAR2(100) := 'APP-XXWSH-10017';     -- API���s�G���[(�z��)
    cv_update_carry_err     CONSTANT VARCHAR2(100) := 'APP-XXWSH-10018';     -- �X�V�G���[(�z��)
    cv_api_xoha             CONSTANT VARCHAR2(100) := '�󒍃w�b�_�A�h�I�����獀�ڂ��擾';
    cv_api_xola             CONSTANT VARCHAR2(100) := '�󒍖��׃A�h�I�����獀�ڂ��擾';
    cv_api_mrih             CONSTANT VARCHAR2(100) := '�ړ��˗�/�w���w�b�_(�A�h�I��)���獀�ڂ��擾';
    cv_api_mril             CONSTANT VARCHAR2(100) := '�ړ��˗�/�w������(�A�h�I��)���獀�ڂ��擾';
    cv_api_xcs              CONSTANT VARCHAR2(100) := '�z�Ԕz���v��i�A�h�I���j���獀�ڂ��擾';
    cv_api_xoha_im          CONSTANT VARCHAR2(100)
      := '�󒍖��׃A�h�I���AOPM�i�ڃ}�X�^���獀�ڂ��擾';
    cv_api_mril_im          CONSTANT VARCHAR2(100)
      := '�ړ��˗�/�w������(�A�h�I��)�AOPM�i�ڃ}�X�^���獀�ڂ��擾';
    cv_api_xoha_mrih        CONSTANT VARCHAR2(100)
      := '�󒍃w�b�_�A�h�I���A�ړ��˗�/�w������(�A�h�I��)���獀�ڂ��擾';
    cv_api_small_sum_class  CONSTANT VARCHAR2(30)  := '�����敪�̎擾';
    cv_api_carriers_info    CONSTANT VARCHAR2(30)  := '�z�Ԋ���̎擾';
    cv_api_calc_total_value CONSTANT VARCHAR2(100) := '�ύڌ����`�F�b�N(���v�l�Z�o)';
    cv_api_weight           CONSTANT VARCHAR2(100) := '�d�ʐύڌ����Z�o';
    cv_api_capacity         CONSTANT VARCHAR2(100) := '�e�ϐύڌ����Z�o';
    cv_api_lock             CONSTANT VARCHAR2(100) := '���b�N����';
    cv_api_update_line_item CONSTANT VARCHAR2(100) := '�d�ʗe�Ϗ������X�V�֐�';
--
    -- *** ���[�J���ϐ� ***
    ln_pallet_waight                NUMBER;                     -- �p���b�g�d��
    lv_small_sum_class              VARCHAR2(1);                -- �����敪
    ld_date                         DATE;                       -- ���
    lv_syohin_class                 VARCHAR2(2);                -- ���i�敪
    lv_except_msg                   VARCHAR2(200);              -- �G���[���b�Z�[�W
    ln_counter                      NUMBER;                     -- �J�E���g�ϐ�
    lv_tkn_biz_type                 VARCHAR2(100);              -- �g�[�N��_�Ɩ����
    lv_tkn_request_no               VARCHAR2(100);              -- �g�[�N��_�˗�No/�ړ��ԍ�
    -- �󒍃w�b�_�A�h�I��
    lv_req_status                   VARCHAR2(2);                -- �X�e�[�^�X
    lv_result_shipping_method_code  VARCHAR2(2);                -- �z���敪_����
    lv_result_deliver_to            VARCHAR2(9);                -- �o�א�_����
    lv_deliver_from                 VARCHAR2(4);                -- �o�׌��ۊǏꏊ
    lv_delivery_no                  VARCHAR2(12);               -- �z��No
    ln_order_header_id              NUMBER;                     -- �󒍃w�b�_�A�h�I��ID
    ld_shipped_date                 DATE;                       -- �o�ד�
    lv_prod_class                   VARCHAR2(2);                -- ���i�敪
    ln_real_pallet_quantity         NUMBER;                     -- �p���b�g���і���
    lv_vendor_site_code             VARCHAR2(100);              -- �����T�C�g
--add start 1.14
    lv_freight_charge_class         xxwsh_order_headers_all.freight_charge_class%TYPE; --�^���敪
--add end 1.14
    -- �󒍖��׃A�h�I��
    ln_shipped_quantity             NUMBER;                     -- �o�׎��ѐ���
    lv_shipping_item_code           VARCHAR2(7);                -- �o�וi��
    lv_conv_unit                    VARCHAR2(240);              -- ���o�Ɋ��Z�P��
    lv_num_of_cases                 VARCHAR2(240);              -- �P�[�X����
    lv_num_of_deliver               VARCHAR2(240);              -- �o�ד���
    ln_order_line_id                NUMBER;                     -- �󒍖��׃A�h�I��ID
    -- �ړ��˗�/�w���w�b�_(�A�h�I��)
    lv_status                       VARCHAR2(100);              -- �X�e�[�^�X
    lv_actual_shipping_method_code  VARCHAR2(100);              -- �z���敪
    ln_mov_hdr_id                   NUMBER;                     -- �ړ��w�b�_ID
    lv_shipped_locat_code           VARCHAR2(100);              -- �o�Ɍ��ۊǏꏊ
    lv_ship_to_locat_code           VARCHAR2(100);              -- ���ɐ�ۊǏꏊ
    lv_product_flg                  VARCHAR2(100);              -- ���i���ʋ敪
    ld_actual_ship_date             DATE;                       -- �o�Ɏ��ѓ�
    lv_item_class                   VARCHAR2(2);                -- ���i�敪
    ln_out_pallet_qty               NUMBER;                     -- �p���b�g�����i�o�j
    -- �ړ��˗�/�w������(�A�h�I��)
    lv_item_code                    VARCHAR2(100);              -- �i��
    ln_mov_line_id                  NUMBER;                     -- �ړ�����ID
    -- ���ʊ֐���ύڌ����`�F�b�N�OUT�p�����[�^
    lv_retcode                      VARCHAR2(1);                -- ���^�[���R�[�h
    lv_errmsg_code                  VARCHAR2(100);              -- �G���[���b�Z�[�W�R�[�h
    lv_errmsg                       VARCHAR2(100);              -- �G���[���b�Z�[�W
    lv_loading_over_class           VARCHAR2(100);              -- �ύڃI�[�o�[�敪
    lv_ship_methods                 VARCHAR2(100);              -- �o�ו��@
    ln_load_efficiency_weight       NUMBER;                     -- �d�ʐύڌ���
    ln_load_efficiency_capacity     NUMBER;                     -- �e�ϐύڌ���
    lv_mixed_ship_method            VARCHAR2(100);              -- ���ڔz���敪
    -- ���v�l
    ln_sum_weight                   NUMBER;                     -- ���v�d��
    ln_sum_capacity                 NUMBER;                     -- ���v�e��
    ln_sum_pallet_weight            NUMBER;                     -- ���v�p���b�g�d��
    -- �z�Ԕz���v��X�V
    lv_default_line_number          VARCHAR2(100);              -- �����No
    lv_process_class                VARCHAR2(100);              -- �������
    lv_attribute1                   VARCHAR2(100);              -- �o�׎x���敪
    -- �w�b�_�X�V����
    ln_update_sum_weight            NUMBER;                     -- �ύڏd�ʍ��v
    ln_update_sum_capacity          NUMBER;                     -- �ύڗe�ύ��v
    ln_update_sum_pallet_weight     NUMBER;                     -- ���v�p���b�g�d��
    ln_update_small_quantity        NUMBER;                     -- ������
    ln_update_load_effi_weight      NUMBER;                     -- �d�ʐύڌ���
    ln_update_load_effi_capacity    NUMBER;                     -- �e�ϐύڌ���
    -- ���׍X�V����
    lv_update_delivery_no           VARCHAR2(12);               -- �z��No
    ln_update_weight                NUMBER;                     -- �d��
    ln_update_capacity              NUMBER;                     -- �e��
    ln_update_pallet_weight         NUMBER;                     -- �p���b�g�d��
    ln_update_order_line_id         NUMBER;                     -- ����ID
    ln_update_mov_line_id           NUMBER;                     -- �ړ�����ID
    -- WHO�J����
    ln_user_id                      NUMBER;                     -- ���O�C�����Ă��郆�[�U�[��ID�擾
    ln_login_id                     NUMBER;                     -- �ŏI�X�V���O�C��
    ln_conc_request_id              NUMBER;                     -- �v��ID
    ln_prog_appl_id                 NUMBER;                     -- �v���O�����E�A�v���P�[�V����ID
    ln_conc_program_id              NUMBER;                     -- �v���O����ID
    ld_sysdate                      DATE;                       -- �V�X�e�����ݓ��t
    -- �e�[�u���ϐ�
    lt_ship_tab                     get_ship_tbl;               -- �o��
    lt_supply_tab                   get_supply_tbl;             -- �x��
    lt_move_tab                     get_move_tbl;               -- �ړ�
    lt_update_tbl                   get_update_tbl;             -- ���׍X�V����
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �o�׃J�[�\��
    CURSOR  ship_cur IS
      --SELECT  xola.shipped_quantity,                    -- �o�׎��ѐ���
      SELECT  NVL(xola.shipped_quantity, 0) AS shipped_quantity, -- �o�׎��ѐ���
              xola.shipping_item_code,                  -- �o�וi��
              ximv.conv_unit,                           -- ���o�Ɋ��Z�P��
              ximv.num_of_cases,                        -- �P�[�X����
              ximv.num_of_deliver,                      -- �o�ד���
              xola.order_line_id                        -- �󒍖��׃A�h�I��ID
      FROM    xxwsh_order_lines_all         xola,       -- �󒍖��׃A�h�I��
              xxcmn_item_mst_v              ximv        -- OPM�i�ڏ��VIEW
      WHERE   xola.order_header_id              =  ln_order_header_id
      AND     NVL(xola.delete_flag, cv_flag_no) <> cv_flag_yes
      AND     ximv.item_no                      =  xola.shipping_item_code
      FOR UPDATE OF xola.order_line_id NOWAIT;
--
    -- �x���J�[�\��
    CURSOR  supply_cur IS
      SELECT  xola.shipping_item_code,                  -- �o�וi��
              --xola.shipped_quantity,                    -- �o�׎��ѐ���
              NVL(xola.shipped_quantity, 0) AS shipped_quantity, -- �o�׎��ѐ���
              xola.order_line_id                        -- �󒍖��׃A�h�I��ID
      FROM    xxwsh_order_lines_all         xola        -- �󒍖��׃A�h�I��
      WHERE   xola.order_header_id              =  ln_order_header_id
      AND     NVL(xola.delete_flag, cv_flag_no) <> cv_flag_yes
      FOR UPDATE OF xola.order_line_id NOWAIT;
--
    -- �ړ��J�[�\��
    CURSOR  move_cur IS
      --SELECT  mril.shipped_quantity,                    -- �o�Ɏ��ѐ���
      SELECT  NVL(mril.shipped_quantity, 0) AS shipped_quantity, -- �o�Ɏ��ѐ���
              mril.item_code,                           -- �i��
              ximv.conv_unit,                           -- ���o�Ɋ��Z�P��
              ximv.num_of_cases,                        -- �P�[�X����
              ximv.num_of_deliver,                      -- �o�ד���
              mril.mov_line_id                          -- �ړ�����ID
      FROM    xxinv_mov_req_instr_lines     mril,       -- �ړ��˗�/�w������(�A�h�I��)
              xxcmn_item_mst_v              ximv        -- OPM�i�ڏ��VIEW
      WHERE   mril.mov_hdr_id               =  ln_mov_hdr_id
      AND     mril.delete_flg               <> cv_flag_yes
      AND     ximv.item_no                  =  mril.item_code
      FOR UPDATE OF mril.mov_line_id NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    lock_expt                  EXCEPTION;  -- ���b�N�擾��O
--
    PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ���b�N�擾��O
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    -- �v���t�@�C���擾
    ln_pallet_waight := TO_NUMBER(FND_PROFILE.VALUE('XXWSH_PALLET_WEIGHT')); -- �p���b�g�d��
--
    -- ���̓p�����[�^�`�F�b�N
    IF (( iv_biz_type IS NULL ) OR ( iv_request_no IS NULL )) THEN
      lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_para_err);
      FND_LOG.STRING(cv_log_level, gv_pkg_name
                    || cv_colon
                    || cv_prg_name, lv_except_msg);
      RETURN gn_status_error;
--
    END IF;
--
    -- �g�[�N���̒l��ݒ�
    IF (iv_biz_type = cv_ship) THEN
      lv_tkn_biz_type   := cv_type_ship;
      lv_tkn_request_no := cv_request_no;
    ELSIF (iv_biz_type = cv_supply) THEN
      lv_tkn_biz_type   := cv_type_supply;
      lv_tkn_request_no := cv_request_no;
    ELSIF (iv_biz_type = cv_move) THEN
      lv_tkn_biz_type   := cv_type_move;
      lv_tkn_request_no := cv_move_no;
    END IF;
--
    -- WHO�J�������擾
    ln_user_id           := FND_GLOBAL.USER_ID;           -- ���O�C�����Ă��郆�[�U�[��ID�擾
    ln_login_id          := FND_GLOBAL.LOGIN_ID;          -- �ŏI�X�V���O�C��
    ln_conc_request_id   := FND_GLOBAL.CONC_REQUEST_ID;   -- �v��ID
    ln_prog_appl_id      := FND_GLOBAL.PROG_APPL_ID;      -- �v���O�����E�A�v���P�[�V����ID
    ln_conc_program_id   := FND_GLOBAL.CONC_PROGRAM_ID;   -- �v���O����ID
    ld_sysdate           := SYSDATE;                      -- �V�X�e�����ݓ��t
--
    -- �Z�[�u�|�C���g���擾���܂�
    SAVEPOINT advance_sp;
--
    -- **************************************************
    -- *** 1.�Ɩ���ʂ��o�ׂ̏ꍇ
    -- **************************************************
    IF (iv_biz_type = cv_ship) THEN
--
      BEGIN
--
        BEGIN
          -- (1)�󒍃w�b�_�A�h�I�����獀�ڂ��擾
          -- ���b�N���擾����
          SELECT  xoha.req_status,                      -- �X�e�[�^�X
                  --xoha.result_shipping_method_code,     -- �z���敪_����
                  NVL(xoha.result_shipping_method_code,
                      xoha.shipping_method_code),       -- �z���敪_���сANULL�̂Ƃ��́A�z���敪���擾
                  --xoha.result_deliver_to,               -- �o�א�_����
                  NVL(xoha.result_deliver_to,
                      xoha.deliver_to),                 -- �o�א�_���сANULL�̂Ƃ��́A�o�א���擾
                  xoha.deliver_from,                    -- �o�׌��ۊǏꏊ
                  xoha.delivery_no,                     -- �z��No
                  xoha.order_header_id,                 -- �󒍃w�b�_�A�h�I��ID
                  --xoha.shipped_date,                    -- �o�ד�
                  NVL(xoha.shipped_date,
                      xoha.schedule_ship_date),         -- �o�ד��ANULL�̂Ƃ��́A�o�ח\������擾
                  xoha.prod_class,                      -- ���i�敪
                  --xoha.real_pallet_quantity             -- �p���b�g���і���
                  NVL(xoha.real_pallet_quantity, 0)     -- �p���b�g���і����ANULL�̂Ƃ��́A0��ݒ�
--add start 1.14
                 ,freight_charge_class                  -- �^���敪
--add end 1.14
          INTO    lv_req_status,
                  lv_result_shipping_method_code,
                  lv_result_deliver_to,
                  lv_deliver_from,
                  lv_delivery_no,
                  ln_order_header_id,
                  ld_shipped_date,
                  lv_prod_class,
                  ln_real_pallet_quantity
--add start 1.14
                 ,lv_freight_charge_class
--add end 1.14
          FROM    xxwsh_order_headers_all       xoha,       -- �󒍃w�b�_�A�h�I��
                  xxwsh_oe_transaction_types2_v ott2        -- �󒍃^�C�v���VIEW
          WHERE   xoha.request_no                             =  iv_request_no
          AND     xoha.order_type_id                          =  ott2.transaction_type_id
          AND     ott2.shipping_shikyu_class                  =  cv_ship_req
          AND     NVL(xoha.latest_external_flag, cv_flag_no)  =  cv_flag_yes
          --AND     ott2.start_date_active  <= xoha.shipped_date
          --AND     xoha.shipped_date       <= NVL(ott2.end_date_active, xoha.shipped_date)
          AND     ott2.start_date_active  <= NVL(xoha.shipped_date, xoha.schedule_ship_date)
          AND     NVL(xoha.shipped_date, xoha.schedule_ship_date)
                                                             <= NVL(ott2.end_date_active, NVL(xoha.shipped_date, xoha.schedule_ship_date))
          FOR UPDATE OF xoha.order_header_id NOWAIT;
--
        EXCEPTION
          -- �擾�ł��Ȃ������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN NO_DATA_FOUND THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_err,
                                                      cv_tkn_table, cv_xoha,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level, gv_pkg_name
                          || cv_colon
                          || cv_prg_name, lv_except_msg);
            RETURN gn_status_error;
--
          -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN OTHERS THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                  cv_tkn_api_name, cv_api_xoha,
                                                  cv_tkn_type, lv_tkn_biz_type,
                                                  cv_tkn_no_type, lv_tkn_request_no,
                                                  cv_tkn_request_no, iv_request_no,
                                                  cv_tkn_err_msg, SQLERRM);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
          RETURN gn_status_error;
--
        END;
--
        -- �擾�����X�e�[�^�X����o�׎��ьv��ϣ�ȊO�̏ꍇ�͕Ԃ�l��0�F����OR�ΏۊO��Ԃ��I��
        IF (lv_req_status <> cv_shiped_confirm) THEN
          RETURN gn_status_normal;
        END IF;
--
        -- �擾�����z��No��z�Ԕz���v��X�V���ڂƂ��ăZ�b�g
        lv_update_delivery_no := lv_delivery_no;
--
--add start 1.14
        IF lv_freight_charge_class = gv_freight_charge_yes THEN
--add end 1.14
          BEGIN
            -- (2)�擾�����z���敪_���т����ƂɃN�C�b�N�R�[�h�XXCMN_SHIP_METHOD����珬���敪���擾
            SELECT  xsm2.small_amount_class
            INTO    lv_small_sum_class
            FROM    xxwsh_ship_method2_v    xsm2
            WHERE   xsm2.ship_method_code   =  lv_result_shipping_method_code
            AND     xsm2.start_date_active  <= ld_shipped_date
            AND     ld_shipped_date         <= NVL(xsm2.end_date_active, ld_shipped_date);
--
          EXCEPTION
            -- �擾�ł��Ȃ������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
            WHEN NO_DATA_FOUND THEN
              lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_err,
                                                    cv_tkn_table, cv_small_sum_class,
                                                    cv_tkn_type, lv_tkn_biz_type,
                                                    cv_tkn_no_type, lv_tkn_request_no,
                                                    cv_tkn_request_no, iv_request_no);
              FND_LOG.STRING(cv_log_level,gv_pkg_name
                            || cv_colon
                            || cv_prg_name,lv_except_msg);
              RETURN gn_status_error;
--
            -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
            WHEN OTHERS THEN
              lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                    cv_tkn_api_name, cv_api_xoha_im,
                                                    cv_tkn_type, lv_tkn_biz_type,
                                                    cv_tkn_no_type, lv_tkn_request_no,
                                                    cv_tkn_request_no, iv_request_no,
                                                    cv_tkn_err_msg, SQLERRM);
              FND_LOG.STRING(cv_log_level,gv_pkg_name
                            || cv_colon
                            || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          END;
--add start 1.14
        END IF;
--add end 1.14
--
        BEGIN
        -- �J�E���g�ϐ��̏�����
        ln_counter := 0;
--
          -- (3)�󒍖��׃A�h�I���AOPM�i�ڃ}�X�^���獀�ڂ��擾
          -- ���b�N���擾����
          <<ship_loop>>
          FOR get_ship_data IN ship_cur LOOP
            lt_ship_tab(ln_counter).shipped_quantity    := get_ship_data.shipped_quantity;
            lt_ship_tab(ln_counter).shipping_item_code  := get_ship_data.shipping_item_code;
            lt_ship_tab(ln_counter).conv_unit           := get_ship_data.conv_unit;
            lt_ship_tab(ln_counter).num_of_cases        := get_ship_data.num_of_cases;
            lt_ship_tab(ln_counter).num_of_deliver      := get_ship_data.num_of_deliver;
            lt_ship_tab(ln_counter).order_line_id       := get_ship_data.order_line_id;
--
            -- (4)���ʊ֐���ύڌ����`�F�b�N(���v�l�Z�o)����Ăяo��
            xxwsh_common910_pkg.calc_total_value(
              lt_ship_tab(ln_counter).shipping_item_code, -- �o�וi��
              lt_ship_tab(ln_counter).shipped_quantity,   -- �o�׎��ѐ���
              lv_retcode,                                 -- ���^�[���R�[�h
              lv_errmsg_code,                             -- �G���[���b�Z�[�W�R�[�h
              lv_errmsg,                                  -- �G���[���b�Z�[�W
              ln_sum_weight,                              -- ���v�d��
              ln_sum_capacity,                            -- ���v�e��
              ln_sum_pallet_weight);                      -- ���v�p���b�g�d��
--
            -- ���^�[���R�[�h��'1'(�ُ�)�̏ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
            IF (lv_retcode = gn_status_error) THEN
              lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                        cv_tkn_api_name, cv_api_calc_total_value,
                                                        cv_tkn_type, lv_tkn_biz_type,
                                                        cv_tkn_no_type, lv_tkn_request_no,
                                                        cv_tkn_request_no, iv_request_no,
                                                        cv_tkn_err_msg, lv_errmsg);
              FND_LOG.STRING(cv_log_level,gv_pkg_name
                            || cv_colon
                            || cv_prg_name,lv_except_msg);
              RETURN gn_status_error;
--
            -- ���펞�͍X�V���ڂɒl��ǉ�
            ELSE
-- 2008/08/07 H.Itou Add Start �ύX�v��#173 �ύڏd�ʍ��v�E�ύڗe�ύ��v��NULL�ɂȂ�Ȃ��悤�ɁANVL����B
              ln_sum_weight        := NVL(ln_sum_weight, 0);       -- ���v�d��
              ln_sum_capacity      := NVL(ln_sum_capacity, 0);     -- ���v�e��
              ln_sum_pallet_weight := NVL(ln_sum_pallet_weight, 0);-- ���v�p���b�g��
-- 2008/08/07 H.Itou Add End
              -- �y���׍X�V���ځz
              lt_update_tbl(ln_counter).update_weight            :=  ln_sum_weight;
              lt_update_tbl(ln_counter).update_capacity          :=  ln_sum_capacity;
              lt_update_tbl(ln_counter).update_pallet_weight     :=  ln_sum_pallet_weight;
              lt_update_tbl(ln_counter).update_line_id :=  lt_ship_tab(ln_counter).order_line_id;
--
              --�y�w�b�_�X�V���ځz
              ln_update_sum_weight        :=  NVL(ln_update_sum_weight, 0)        + ln_sum_weight;
              ln_update_sum_capacity      :=  NVL(ln_update_sum_capacity, 0)      + ln_sum_capacity;
              ln_update_sum_pallet_weight :=  NVL(ln_update_sum_pallet_weight, 0)
                                              + (ln_real_pallet_quantity * ln_pallet_waight);
--
              -- �@(3)�Ŏ擾�����o�׎��ѐ��ʂ�0�̏ꍇ
              IF (lt_ship_tab(ln_counter).shipped_quantity = 0) THEN
                NULL;
--
              -- �A(3)�Ŏ擾�����o�ד������ݒ肳��Ă���ꍇ
-- 2008/08/07 H.Itou Mod Start �����ۑ�#32 �o�ד��� > 0 �ɏ����ύX�B
--              ELSIF (lt_ship_tab(ln_counter).num_of_deliver IS NOT NULL) THEN
              ELSIF (lt_ship_tab(ln_counter).num_of_deliver > 0 ) THEN
-- 2008/08/07 H.Itou Mod End
                ln_update_small_quantity := NVL(ln_update_small_quantity, 0)
-- 2008/08/07 H.Itou Mod Start �ύX�v��#166 ���גP�ʂŐ����ɐ؂�グ�A���v����B
--                                            + (ROUND(lt_ship_tab(ln_counter).shipped_quantity
                                            + (CEIL(lt_ship_tab(ln_counter).shipped_quantity
-- 2008/08/07 H.Itou Mod End
                                            / lt_ship_tab(ln_counter).num_of_deliver));
--
              -- �B(3)�Ŏ擾�����P�[�X�������ݒ肳��Ă���ꍇ
-- 2008/08/07 H.Itou Mod Start �����ۑ�#32 ���o�Ɋ��Z�P�� IS NOT NULL �ɏ����ύX�B
--              ELSIF (lt_ship_tab(ln_counter).num_of_cases IS NOT NULL) THEN
              ELSIF (lt_ship_tab(ln_counter).conv_unit IS NOT NULL) THEN
-- 2008/08/07 H.Itou Mod End
                ln_update_small_quantity := NVL(ln_update_small_quantity, 0)
-- 2008/08/07 H.Itou Mod Start �ύX�v��#166 ���גP�ʂŐ����ɐ؂�グ�A���v����B
--                                            + (ROUND(lt_ship_tab(ln_counter).shipped_quantity
                                            + (CEIL(lt_ship_tab(ln_counter).shipped_quantity
-- 2008/08/07 H.Itou Mod End
                                            / lt_ship_tab(ln_counter).num_of_cases));
--
              -- �C������̏����ɂ����Ă͂܂�Ȃ��ꍇ
              ELSE
                ln_update_small_quantity  := NVL(ln_update_small_quantity, 0)
-- 2008/08/07 H.Itou Mod Start �ύX�v��#166 ���גP�ʂŐ����ɐ؂�グ�A���v����B
--                                             + lt_ship_tab(ln_counter).shipped_quantity;
                                             + CEIL(lt_ship_tab(ln_counter).shipped_quantity);
-- 2008/08/07 H.Itou Mod End
--
              END IF;
--
            END IF;
--
            -- �J�E���g�ϐ����C���N�������g
            ln_counter := ln_counter + 1;
--
          END LOOP ship_loop;
--
        EXCEPTION
          -- �擾�ł��Ȃ������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN NO_DATA_FOUND THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_err,
                                                      cv_tkn_table, cv_order_lines_item_mst,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN OTHERS THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                  cv_tkn_api_name, cv_order_lines_item_mst,
                                                  cv_tkn_type, lv_tkn_biz_type,
                                                  cv_tkn_no_type, lv_tkn_request_no,
                                                  cv_tkn_request_no, iv_request_no,
                                                  cv_tkn_err_msg, SQLERRM);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
        -- �ϐ�������
        lv_retcode      :=NULL;   -- ���^�[���R�[�h
        lv_errmsg_code  :=NULL;   -- �G���[���b�Z�[�W�R�[�h
        lv_errmsg       :=NULL;   -- �G���[���b�Z�[�W
--
-- 2008/08/07 H.Itou Mod Start �ύX�v��#173 �ύڌ����Z�o�����́A�z��No�ł͂Ȃ��A�^���敪�Ŕ���
        -- (5)(1)�Ŕz��No���ݒ肳��Ă���ꍇ�A���ʊ֐���ύڌ����`�F�b�N(�ύڌ����Z�o)����Ăяo��
--mod start 1.14
----        IF (lv_update_delivery_no IS NOT NULL) THEN
--        IF (lv_update_delivery_no IS NOT NULL 
--        AND lv_freight_charge_class = gv_freight_charge_yes) THEN
        -- �^���敪�u1�v�̏ꍇ
        IF (lv_freight_charge_class = gv_freight_charge_yes) THEN
--mod end 1.14
-- 2008/08/07 H.Itou Mod End
-- 2008/08/07 H.Itou Del Start �ύX�v��#173 �d�ʐύڌ����Z�o�͐ύڍ��v�d�ʂ̒l�Ɋւ�炸�Z�o����B
--          -- ���v�d�ʂ��ݒ肳��Ă���ꍇ
--          IF (ln_update_sum_weight > 0) THEN
-- 2008/08/07 H.Itou Del End
          -- �d�ʐύڌ����Z�o
          xxwsh_common910_pkg.calc_load_efficiency(
            (CASE
              -- �@(2)�Ŏ擾���������敪����Ώۣ�̏ꍇ
              WHEN (lv_small_sum_class = cv_include) THEN
                ln_update_sum_weight
              -- �A(2)�Ŏ擾���������敪����Ώۣ�ȊO�̏ꍇ
              ELSE
                ln_update_sum_weight + NVL(ln_update_sum_pallet_weight, 0)
            END),                                     -- 1.���v�d��
            NULL,                                     -- 2.���v�e��
            cv_whse,                                  -- 3.�R�[�h�敪�P
            lv_deliver_from,                          -- 4.���o�ɏꏊ�R�[�h�P
            cv_deliver_to,                            -- 5.�R�[�h�敪�Q
            lv_result_deliver_to,                     -- 6.���o�ɏꏊ�R�[�h�Q
            lv_result_shipping_method_code,           -- 7.�o�ו��@
            lv_prod_class,                            -- 8.���i�敪
            NULL,                                     -- 9.�����z�ԑΏۋ敪
            ld_shipped_date,                          -- 10.���(�K�p�����)
            lv_retcode,                               -- 11.���^�[���R�[�h
            lv_errmsg_code,                           -- 12.�G���[���b�Z�[�W�R�[�h
            lv_errmsg,                                -- 13.�G���[���b�Z�[�W
            lv_loading_over_class,                    -- 14.�ύڃI�[�o�[�敪
            lv_ship_methods,                          -- 15.�o�ו��@
            ln_load_efficiency_weight,                -- 16.�d�ʐύڌ���
            ln_load_efficiency_capacity,              -- 17.�e�ϐύڌ���
            lv_mixed_ship_method);                    -- 18.���ڔz���敪
--
          -- ���^�[���R�[�h��'1'(�ُ�)�̏ꍇ�͕Ԃ�l��1�F�G���[��Ԃ��I��
          IF (lv_retcode = gn_status_error) THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                      cv_tkn_api_name, cv_api_weight,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_err_msg, lv_errmsg);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          END IF;
--
          -- �擾�����d�ʐύڌ������w�b�_�X�V�p���ڂɃZ�b�g
          ln_update_load_effi_weight := ln_load_efficiency_weight;
--
-- 2008/08/07 H.Itou Del Start �ύX�v��#173 �d�ʐύڌ����Z�o�͐ύڍ��v�d�ʂ̒l�Ɋւ�炸�Z�o����B
--          END IF;
-- 2008/08/07 H.Itou Del End
--
-- 2008/08/07 H.Itou Del Start �ύX�v��#173 �e�ϐύڌ����Z�o�͐ύڍ��v�e�ς̒l�Ɋւ�炸�Z�o����B
--          -- ���v�e�ς��ݒ肳��Ă���ꍇ
--          IF (ln_update_sum_capacity > 0) THEN
-- 2008/08/07 H.Itou Del End
          -- �e�ϐύڌ����Z�o
          xxwsh_common910_pkg.calc_load_efficiency(
            NULL,                                     -- 1.���v�d��
            ln_update_sum_capacity,                   -- 2.���v�e��
            cv_whse,                                  -- 3.�R�[�h�敪�P
            lv_deliver_from,                          -- 4.���o�ɏꏊ�R�[�h�P
            cv_deliver_to,                            -- 5.�R�[�h�敪�Q
            lv_result_deliver_to,                     -- 6.���o�ɏꏊ�R�[�h�Q
            lv_result_shipping_method_code,           -- 7.�o�ו��@
            lv_prod_class,                            -- 8.���i�敪
            NULL,                                     -- 9.�����z�ԑΏۋ敪
            ld_shipped_date,                          -- 10.���(�K�p�����)
            lv_retcode,                               -- 11.���^�[���R�[�h
            lv_errmsg_code,                           -- 12.�G���[���b�Z�[�W�R�[�h
            lv_errmsg,                                -- 13.�G���[���b�Z�[�W
            lv_loading_over_class,                    -- 14.�ύڃI�[�o�[�敪
            lv_ship_methods,                          -- 15.�o�ו��@
            ln_load_efficiency_weight,                -- 16.�d�ʐύڌ���
            ln_load_efficiency_capacity,              -- 17.�e�ϐύڌ���
            lv_mixed_ship_method);                    -- 18.���ڔz���敪
--
          -- ���^�[���R�[�h��'1'(�ُ�)�̏ꍇ�͕Ԃ�l��1�F�G���[��Ԃ��I��
          IF (lv_retcode = gn_status_error) THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                      cv_tkn_api_name, cv_api_capacity,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_err_msg, lv_errmsg);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          END IF;
--
          -- �擾�����e�ϐύڌ������w�b�_�X�V�p���ڂɃZ�b�g
          ln_update_load_effi_capacity := ln_load_efficiency_capacity;
--
-- 2008/08/07 H.Itou Del Start �ύX�v��#173 �e�ϐύڌ����Z�o�͐ύڍ��v�d�ʂ̒l�Ɋւ�炸�Z�o����B
--          END IF;
-- 2008/08/07 H.Itou Del End
--  
        END IF;
--
        BEGIN
          <<order_lines_update_loop>>
          FOR i IN lt_update_tbl.FIRST .. lt_update_tbl.LAST LOOP
            -- (6)�󒍖��׃A�h�I���𖾍׍X�V���ڂɓo�^����Ă�����e�ōX�V
            UPDATE  xxwsh_order_lines_all           xola            -- �󒍖��׃A�h�I��
            SET     xola.weight                   =  lt_update_tbl(i).update_weight,
                    xola.capacity                 =  lt_update_tbl(i).update_capacity,
                    xola.pallet_weight            =  lt_update_tbl(i).update_pallet_weight,
                    xola.last_updated_by          =  ln_user_id,
                    xola.last_update_date         =  ld_sysdate,
                    xola.last_update_login        =  ln_login_id,
                    xola.request_id               =  ln_conc_request_id,
                    xola.program_application_id   =  ln_prog_appl_id,
                    xola.program_id               =  ln_conc_program_id,
                    xola.program_update_date      =  ld_sysdate
            WHERE   xola.order_line_id            =  lt_update_tbl(i).update_line_id;
--
          END LOOP order_lines_update_loop;
--
        EXCEPTION
          -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN OTHERS THEN
            -- �Z�[�u�|�C���g�փ��[���o�b�N
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_update_err,
                                                      cv_tkn_table, cv_xola,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
        BEGIN
          -- (7)�󒍃w�b�_�A�h�I�����w�b�_�X�V���ڂɓo�^����Ă�����e�ōX�V
          UPDATE  xxwsh_order_headers_all         xoha            -- �󒍃w�b�_�A�h�I��
-- 2008/08/07 H.Itou Mod Start �ύX�v��#173 �^�ύڏd�ʍ��v�A�ύڗe�ύ��v�́A�^���敪�̏��������ɍX�V
----mod start 1.14
--          -- �ύڏd�ʍ��v
--          SET     xoha.sum_weight         = ln_update_sum_weight,
--          -- �ύڗe�ύ��v
--                  xoha.sum_capacity       = ln_update_sum_capacity,
--          -- �ύڏd�ʍ��v
--          SET     xoha.sum_weight         = 
--                   (CASE
--                     WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
--                       ln_update_sum_weight
--                     ELSE
--                       xoha.sum_weight
--                    END),
--          -- �ύڗe�ύ��v
--                  xoha.sum_capacity       =
--                   (CASE
--                     WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
--                       ln_update_sum_capacity
--                     ELSE
--                       xoha.sum_capacity
--                    END),
----mod end 1.14
          -- �ύڏd�ʍ��v
          SET     xoha.sum_weight         = ln_update_sum_weight,
          -- �ύڗe�ύ��v
                  xoha.sum_capacity       = ln_update_sum_capacity,
-- 2008/08/07 H.Itou Mod End
          -- ���v�p���b�g�d��
                  xoha.sum_pallet_weight  = ln_update_sum_pallet_weight,
          -- ������
                  xoha.small_quantity     = ln_update_small_quantity,
          -- �d�ʐύڌ���
                  xoha.loading_efficiency_weight =
                   (CASE
-- 2008/08/07 H.Itou Mod Start �ύX�v��#173
----mod start 1.14
----                     WHEN (lv_update_delivery_no IS NOT NULL) THEN
--                     WHEN (lv_update_delivery_no IS NOT NULL OR lv_freight_charge_class = gv_freight_charge_yes) THEN
----mod end 1.14
--                       ln_update_load_effi_weight
--                     ELSE
--                       xoha.loading_efficiency_weight
                     -- �^���敪�u1�v�̏ꍇ�A�����Ŏ擾�����l���X�V
                     WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                       ln_update_load_effi_weight
--
                     -- ��L�ȊO�̏ꍇ�ANULL���X�V
                     ELSE
                       NULL
-- 2008/08/07 H.Itou Mod End
                   END),
          -- �e�ϐύڌ���
                  xoha.loading_efficiency_capacity  =
                   (CASE
-- 2008/08/07 H.Itou Mod Start �ύX�v��#173
----mod start 1.14
----                     WHEN (lv_update_delivery_no IS NOT NULL) THEN
--                     WHEN (lv_update_delivery_no IS NOT NULL OR lv_freight_charge_class = gv_freight_charge_yes) THEN
----mod end 1.14
--                       ln_update_load_effi_capacity
--                     ELSE
--                       xoha.loading_efficiency_capacity
                     -- �^���敪�u1�v�̏ꍇ�A�����Ŏ擾�����l���X�V
                     WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                       ln_update_load_effi_capacity
                     -- ��L�ȊO�̏ꍇ�ANULL���X�V
                     ELSE
                       NULL
-- 2008/08/07 H.Itou Mod End
                   END),
-- 2008/08/07 H.Itou Add Start �ύX�v��#173
          -- ��{�d��
                  xoha.based_weight =
                    (CASE
                       -- �^���敪�u1�v�̏ꍇ�A�X�V���Ȃ��i���݂̒l�ōX�V�j
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         xoha.based_weight
                       -- ��L�ȊO�̏ꍇ�ANULL���X�V
                       ELSE
                         NULL
                     END),
          -- ��{�e��
                  xoha.based_capacity =
                    (CASE
                       -- �^���敪�u1�v�̏ꍇ�A�X�V���Ȃ��i���݂̒l�ōX�V�j
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         xoha.based_capacity
                       -- ��L�ȊO�̏ꍇ�ANULL���X�V
                       ELSE
                         NULL
                     END),
          -- �z���敪
                  xoha.shipping_method_code =
                    (CASE
                       -- �^���敪�u1�v�̏ꍇ�A�X�V���Ȃ��i���݂̒l�ōX�V�j
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         xoha.shipping_method_code
                       -- ��L�ȊO�̏ꍇ�ANULL���X�V
                       ELSE
                         NULL
                     END),
          -- �z���敪_����
                  xoha.result_shipping_method_code =
                    (CASE
                       -- �^���敪�u1�v�̏ꍇ�A�X�V���Ȃ��i���݂̒l�ōX�V�j
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         xoha.result_shipping_method_code
                       -- ��L�ȊO�̏ꍇ�ANULL���X�V
                       ELSE
                         NULL
                     END),
-- 2008/08/07 H.Itou Add End
                  xoha.last_updated_by           =  ln_user_id,
                  xoha.last_update_date          =  ld_sysdate,
                  xoha.last_update_login         =  ln_login_id,
                  xoha.request_id                =  ln_conc_request_id,
                  xoha.program_application_id    =  ln_prog_appl_id,
                  xoha.program_id                =  ln_conc_program_id,
                  xoha.program_update_date       =  ld_sysdate
          WHERE   xoha.order_header_id           =  ln_order_header_id;
--
        EXCEPTION
          -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN OTHERS THEN
            -- �Z�[�u�|�C���g�փ��[���o�b�N
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_update_err,
                                                      cv_tkn_table, cv_xoha,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
      EXCEPTION
        -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
        WHEN OTHERS THEN
          lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                    cv_tkn_api_name, cv_api_update_line_item,
                                                    cv_tkn_type, lv_tkn_biz_type,
                                                    cv_tkn_no_type, lv_tkn_request_no,
                                                    cv_tkn_request_no, iv_request_no,
                                                    cv_tkn_err_msg, SQLERRM);
          FND_LOG.STRING(cv_log_level,gv_pkg_name
                        || cv_colon
                        || cv_prg_name,lv_except_msg);
        RETURN gn_status_error;
--
      END;
--
    -- **************************************************
    -- *** 2.�Ɩ���ʂ��x���̏ꍇ
    -- **************************************************
    ELSIF (iv_biz_type = cv_supply) THEN
--
      BEGIN
--
        BEGIN
          -- (1)�󒍃w�b�_�A�h�I�����獀�ڂ��擾
          -- ���b�N���擾����
          SELECT  xoha.req_status,                      -- �X�e�[�^�X
                  --xoha.result_shipping_method_code,     -- �z���敪_����
                  NVL(xoha.result_shipping_method_code,
                      xoha.shipping_method_code),       -- �z���敪_���сANULL�̂Ƃ��́A�z���敪���擾
                  xoha.vendor_site_code,                -- �����T�C�g
                  xoha.deliver_from,                    -- �o�׌��ۊǏꏊ
                  xoha.delivery_no,                     -- �z��No
                  xoha.order_header_id,                 -- �󒍃w�b�_�A�h�I��ID
                  --xoha.shipped_date,                    -- �o�ד�
                  NVL(xoha.shipped_date,
                      xoha.schedule_ship_date),         -- �o�ד��ANULL�̂Ƃ��́A�o�ח\������擾
                  xoha.prod_class                       -- ���i�敪
-- 2008/08/07 H.Itou Add Start �ύX�v��#173 �^���敪�擾�ǉ�
                 ,xoha.freight_charge_class             -- �^���敪
-- 2008/08/07 H.Itou Add End
          INTO    lv_req_status,
                  lv_result_shipping_method_code,
                  lv_result_deliver_to,
                  lv_deliver_from,
                  lv_delivery_no,
                  ln_order_header_id,
                  ld_shipped_date,
                  lv_prod_class
-- 2008/08/07 H.Itou Add Start �ύX�v��#173 �^���敪�擾�ǉ�
                 ,lv_freight_charge_class
-- 2008/08/07 H.Itou Add End
          FROM    xxwsh_order_headers_all       xoha,       -- �󒍃w�b�_�A�h�I��
                  xxwsh_oe_transaction_types2_v ott2        -- �󒍃^�C�v���VIEW
          WHERE   xoha.request_no                             =  iv_request_no
          AND     xoha.order_type_id                          =  ott2.transaction_type_id
          AND     ott2.shipping_shikyu_class                  =  cv_supply_req
          AND     NVL(xoha.latest_external_flag, cv_flag_no)  =  cv_flag_yes
          --AND     ott2.start_date_active  <= xoha.shipped_date
          --AND     xoha.shipped_date       <= NVL(ott2.end_date_active, xoha.shipped_date)
          AND     ott2.start_date_active  <= NVL(xoha.shipped_date, xoha.schedule_ship_date)
          AND     NVL(xoha.shipped_date, xoha.schedule_ship_date)
                                                             <= NVL(ott2.end_date_active, NVL(xoha.shipped_date, xoha.schedule_ship_date))
          FOR UPDATE OF xoha.order_header_id NOWAIT;
--
        EXCEPTION
          -- �擾�ł��Ȃ������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN NO_DATA_FOUND THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_err,
                                                      cv_tkn_table, cv_xoha,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN OTHERS THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                      cv_tkn_api_name, cv_api_xoha,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_err_msg, SQLERRM);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
          RETURN gn_status_error;
--
        END;
--
        -- �擾�����X�e�[�^�X����o�׎��ьv��ϣ�ȊO�̏ꍇ�͕Ԃ�l��0�F����OR�ΏۊO��Ԃ��I��
        IF (lv_req_status <> cv_shiped_confirm_prov) THEN
          RETURN gn_status_normal;
--
        END IF;
--
        -- �擾�����z��No��z�Ԕz���v��X�V���ڂƂ��ăZ�b�g
        lv_update_delivery_no := lv_delivery_no;
--
        BEGIN
        -- �J�E���g�ϐ��̏�����
        ln_counter := 0;
--
          -- (2)�󒍖��׃A�h�I�����獀�ڂ��擾
          -- ���b�N���擾����
          <<supply_loop>>
          FOR get_supply_data IN supply_cur LOOP
            lt_supply_tab(ln_counter).shipping_item_code := get_supply_data.shipping_item_code;
            lt_supply_tab(ln_counter).shipped_quantity   := get_supply_data.shipped_quantity;
            lt_supply_tab(ln_counter).order_line_id      := get_supply_data.order_line_id;
--
            -- (3)���ʊ֐���ύڌ����`�F�b�N(���v�l�Z�o)����Ăяo��
            xxwsh_common910_pkg.calc_total_value(
              lt_supply_tab(ln_counter).shipping_item_code,   -- �o�וi��
              lt_supply_tab(ln_counter).shipped_quantity,     -- �o�׎��ѐ���
              lv_retcode,              -- ���^�[���R�[�h
              lv_errmsg_code,          -- �G���[���b�Z�[�W�R�[�h
              lv_errmsg,               -- �G���[���b�Z�[�W
              ln_sum_weight,           -- ���v�d��
              ln_sum_capacity,         -- ���v�e��
              ln_sum_pallet_weight);   -- ���v�p���b�g�d��
--
            -- ���^�[���R�[�h��'1'(�ُ�)�̏ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
            IF (lv_retcode = gn_status_error) THEN
              lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                        cv_tkn_api_name, cv_api_calc_total_value,
                                                        cv_tkn_type, lv_tkn_biz_type,
                                                        cv_tkn_no_type, lv_tkn_request_no,
                                                        cv_tkn_request_no, iv_request_no,
                                                        cv_tkn_err_msg, lv_errmsg);
              FND_LOG.STRING(cv_log_level,gv_pkg_name
                            || cv_colon
                            || cv_prg_name,lv_except_msg);
              RETURN gn_status_error;
--
            -- ���펞�͍X�V���ڂɒl��ǉ�
            ELSE
-- 2008/08/07 H.Itou Add Start �ύX�v��#173 �ύڏd�ʍ��v�E�ύڗe�ύ��v��NULL�ɂȂ�Ȃ��悤�ɁANVL����B
              ln_sum_weight        := NVL(ln_sum_weight, 0);       -- ���v�d��
              ln_sum_capacity      := NVL(ln_sum_capacity, 0);     -- ���v�e��
              ln_sum_pallet_weight := NVL(ln_sum_pallet_weight, 0);-- ���v�p���b�g��
-- 2008/08/07 H.Itou Add End
              -- �y���׍X�V���ځz
              lt_update_tbl(ln_counter).update_weight            :=  ln_sum_weight;
              lt_update_tbl(ln_counter).update_capacity          :=  ln_sum_capacity;
              lt_update_tbl(ln_counter).update_line_id :=  lt_supply_tab(ln_counter).order_line_id;
--
              --�y�w�b�_�X�V���ځz
              ln_update_sum_weight    := NVL(ln_update_sum_weight, 0)   + ln_sum_weight;
              ln_update_sum_capacity  := NVL(ln_update_sum_capacity, 0) + ln_sum_capacity;
--
            END IF;
--
          -- �J�E���g�ϐ����C���N�������g
          ln_counter := ln_counter + 1;
--
          END LOOP supply_loop;
--
        EXCEPTION
          -- �擾�ł��Ȃ������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN NO_DATA_FOUND THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_err,
                                                      cv_tkn_table, cv_xola,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN OTHERS THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                      cv_tkn_api_name, cv_api_xola,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_err_msg, SQLERRM);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
          RETURN gn_status_error;
--
        END;
--
        -- �ϐ�������
        lv_retcode      :=NULL;   -- ���^�[���R�[�h
        lv_errmsg_code  :=NULL;   -- �G���[���b�Z�[�W�R�[�h
        lv_errmsg       :=NULL;   -- �G���[���b�Z�[�W
--
-- 2008/08/07 H.Itou Mod Start �ύX�v��#173 �ύڌ����Z�o�����́A�z��No�ł͂Ȃ��A�^���敪�Ŕ���
--        -- (4)(1)�Ŕz��No���ݒ肳��Ă���ꍇ�A���ʊ֐���ύڌ����`�F�b�N(�ύڌ����Z�o)����Ăяo��
--        IF (lv_update_delivery_no IS NOT NULL) THEN
        -- �^���敪�u1�v�̏ꍇ
        IF (lv_freight_charge_class = gv_freight_charge_yes) THEN
-- 2008/08/07 H.Itou Mod End
-- 2008/08/07 H.Itou Del Start �ύX�v��#173 �d�ʐύڌ����Z�o�͐ύڍ��v�d�ʂ̒l�Ɋւ�炸�Z�o����B
--          -- ���v�d�ʂ��ݒ肳��Ă���ꍇ
--          IF (ln_update_sum_weight > 0) THEN
-- 2008/08/07 H.Itou Del End
          -- �d�ʐύڌ����Z�o
          xxwsh_common910_pkg.calc_load_efficiency(
            ln_update_sum_weight,                     -- 1.���v�d��
            NULL,                                     -- 2.���v�e��
            cv_whse,                                  -- 3.�R�[�h�敪�P
            lv_deliver_from,                          -- 4.���o�ɏꏊ�R�[�h�P
            cv_supply_to,                             -- 5.�R�[�h�敪�Q
            lv_result_deliver_to,                     -- 6.���o�ɏꏊ�R�[�h�Q
            lv_result_shipping_method_code,           -- 7.�o�ו��@
            lv_prod_class,                            -- 8.���i�敪
            NULL,                                     -- 9.�����z�ԑΏۋ敪
            ld_shipped_date,                          -- 10.���(�K�p�����)
            lv_retcode,                               -- 11.���^�[���R�[�h
            lv_errmsg_code,                           -- 12.�G���[���b�Z�[�W�R�[�h
            lv_errmsg,                                -- 13.�G���[���b�Z�[�W
            lv_loading_over_class,                    -- 14.�ύڃI�[�o�[�敪
            lv_ship_methods,                          -- 15.�o�ו��@
            ln_load_efficiency_weight,                -- 16.�d�ʐύڌ���
            ln_load_efficiency_capacity,              -- 17.�e�ϐύڌ���
            lv_mixed_ship_method);                    -- 18.���ڔz���敪
--
          -- ���^�[���R�[�h��'1'(�ُ�)�̏ꍇ�͕Ԃ�l��1�F�G���[��Ԃ��I��
          IF (lv_retcode = gn_status_error) THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                      cv_tkn_api_name, cv_api_weight,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_err_msg, lv_errmsg);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          END IF;
--
          -- �擾�����d�ʐύڌ������w�b�_�X�V�p���ڂɃZ�b�g
          ln_update_load_effi_weight := ln_load_efficiency_weight;
--
-- 2008/08/07 H.Itou Del Start �ύX�v��#173 �d�ʐύڌ����Z�o�͐ύڍ��v�d�ʂ̒l�Ɋւ�炸�Z�o����B
--          END IF;
-- 2008/08/07 H.Itou Del End
--
-- 2008/08/07 H.Itou Del Start �ύX�v��#173 �e�ϐύڌ����Z�o�͐ύڍ��v�e�ς̒l�Ɋւ�炸�Z�o����B
--           -- ���v�e�ς��ݒ肳��Ă���ꍇ
--        IF (ln_update_sum_capacity > 0) THEN
-- 2008/08/07 H.Itou Del End
          -- �e�ϐύڌ����Z�o
          xxwsh_common910_pkg.calc_load_efficiency(
            NULL,                                     -- 1.���v�d��
            ln_update_sum_capacity,                   -- 2.���v�e��
            cv_whse,                                  -- 3.�R�[�h�敪�P
            lv_deliver_from,                          -- 4.���o�ɏꏊ�R�[�h�P
            cv_supply_to,                             -- 5.�R�[�h�敪�Q
            lv_result_deliver_to,                     -- 6.���o�ɏꏊ�R�[�h�Q
            lv_result_shipping_method_code,           -- 7.�o�ו��@
            lv_prod_class,                            -- 8.���i�敪
            NULL,                                     -- 9.�����z�ԑΏۋ敪
            ld_shipped_date,                          -- 10.���(�K�p�����)
            lv_retcode,                               -- 11.���^�[���R�[�h
            lv_errmsg_code,                           -- 12.�G���[���b�Z�[�W�R�[�h
            lv_errmsg,                                -- 13.�G���[���b�Z�[�W
            lv_loading_over_class,                    -- 14.�ύڃI�[�o�[�敪
            lv_ship_methods,                          -- 15.�o�ו��@
            ln_load_efficiency_weight,                -- 16.�d�ʐύڌ���
            ln_load_efficiency_capacity,              -- 17.�e�ϐύڌ���
            lv_mixed_ship_method);                    -- 18.���ڔz���敪
--
          -- ���^�[���R�[�h��'1'(�ُ�)�̏ꍇ�͕Ԃ�l��1�F�G���[��Ԃ��I��
          IF (lv_retcode = gn_status_error) THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                      cv_tkn_api_name, cv_api_capacity,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_err_msg, lv_errmsg);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
          RETURN gn_status_error;
--
          END IF;
--
          -- �擾�����e�ϐύڌ������w�b�_�X�V�p���ڂɃZ�b�g
          ln_update_load_effi_capacity := ln_load_efficiency_capacity;
--
        END IF;
--
-- 2008/08/07 H.Itou Del Start �ύX�v��#173 �e�ϐύڌ����Z�o�͐ύڍ��v�e�ς̒l�Ɋւ�炸�Z�o����B
--        END IF;
-- 2008/08/07 H.Itou Del End
--
        BEGIN
          <<order_lines_update_loop>>
          FOR i IN lt_update_tbl.FIRST .. lt_update_tbl.LAST LOOP
            -- (5)�󒍖��׃A�h�I�����X�V���ڂɓo�^����Ă�����e�ōX�V
            UPDATE  xxwsh_order_lines_all           xola            -- �󒍖��׃A�h�I��
            SET     xola.weight                   =  lt_update_tbl(i).update_weight,
                    xola.capacity                 =  lt_update_tbl(i).update_capacity,
                    xola.last_updated_by          =  ln_user_id,
                    xola.last_update_date         =  ld_sysdate,
                    xola.last_update_login        =  ln_login_id,
                    xola.request_id               =  ln_conc_request_id,
                    xola.program_application_id   =  ln_prog_appl_id,
                    xola.program_id               =  ln_conc_program_id,
                    xola.program_update_date      =  ld_sysdate
            WHERE   xola.order_line_id            =  lt_update_tbl(i).update_line_id;
--
          END LOOP order_lines_update_loop;
--
        EXCEPTION
          -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN OTHERS THEN
            -- �Z�[�u�|�C���g�փ��[���o�b�N
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_update_err,
                                                      cv_tkn_table, cv_xola,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
        BEGIN
          -- (6)�󒍃w�b�_�A�h�I�����w�b�_�X�V���ڂɓo�^����Ă�����e�ōX�V
          UPDATE  xxwsh_order_headers_all         xoha            -- �󒍃w�b�_�A�h�I��
          -- �ύڏd�ʍ��v
          SET     xoha.sum_weight                 = ln_update_sum_weight,
          -- �ύڗe�ύ��v
                  xoha.sum_capacity               = ln_update_sum_capacity,
          -- �d�ʐύڌ���
                  xoha.loading_efficiency_weight  =
                   (CASE
-- 2008/08/07 H.Itou Mod Start �ύX�v��#173
--                     WHEN (lv_update_delivery_no IS NOT NULL) THEN
--                       ln_update_load_effi_weight
--                     ELSE
--                       xoha.loading_efficiency_weight
                     -- �^���敪�u1�v�̏ꍇ�A�����Ŏ擾�����l���X�V
                     WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                       ln_update_load_effi_weight
                     -- ��L�ȊO�̏ꍇ�ANULL���X�V
                     ELSE
                       NULL
-- 2008/08/07 H.Itou Mod End
                   END),
          -- �e�ϐύڌ���
                  xoha.loading_efficiency_capacity  =
                   (CASE
-- 2008/08/07 H.Itou Mod Start �ύX�v��#173
--                     WHEN (lv_update_delivery_no IS NOT NULL) THEN
--                       ln_update_load_effi_capacity
--                     ELSE
--                       xoha.loading_efficiency_capacity
                     -- �^���敪�u1�v�̏ꍇ�A�����Ŏ擾�����l���X�V
                     WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                       ln_update_load_effi_capacity
                     -- ��L�ȊO�̏ꍇ�ANULL���X�V
                     ELSE
                       NULL
-- 2008/08/07 H.Itou Mod End
                   END),
-- 2008/08/07 H.Itou Add Start �ύX�v��#173
          -- ��{�d��
                  xoha.based_weight =
                    (CASE
                       -- �^���敪�u1�v�̏ꍇ�A�X�V���Ȃ��i���݂̒l�ōX�V�j
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         xoha.based_weight
                       -- ��L�ȊO�̏ꍇ�ANULL���X�V
                       ELSE
                         NULL
                     END),
          -- ��{�e��
                  xoha.based_capacity =
                    (CASE
                       -- �^���敪�u1�v�̏ꍇ�A�X�V���Ȃ��i���݂̒l�ōX�V�j
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         xoha.based_capacity
                       -- ��L�ȊO�̏ꍇ�ANULL���X�V
                       ELSE
                         NULL
                     END),
          -- �z���敪
                  xoha.shipping_method_code =
                    (CASE
                       -- �^���敪�u1�v�̏ꍇ�A�X�V���Ȃ��i���݂̒l�ōX�V�j
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         xoha.shipping_method_code
                       -- ��L�ȊO�̏ꍇ�ANULL���X�V
                       ELSE
                         NULL
                     END),
          -- �z���敪_����
                  xoha.result_shipping_method_code =
                    (CASE
                       -- �^���敪�u1�v�̏ꍇ�A�X�V���Ȃ��i���݂̒l�ōX�V�j
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         xoha.result_shipping_method_code
                       -- ��L�ȊO�̏ꍇ�ANULL���X�V
                       ELSE
                         NULL
                     END),
-- 2008/08/07 H.Itou Add End
                  xoha.last_updated_by           =  ln_user_id,
                  xoha.last_update_date          =  ld_sysdate,
                  xoha.last_update_login         =  ln_login_id,
                  xoha.request_id                =  ln_conc_request_id,
                  xoha.program_application_id    =  ln_prog_appl_id,
                  xoha.program_id                =  ln_conc_program_id,
                  xoha.program_update_date       =  ld_sysdate
          WHERE   xoha.order_header_id           =  ln_order_header_id;
--
        EXCEPTION
          -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN OTHERS THEN
            -- �Z�[�u�|�C���g�փ��[���o�b�N
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_update_err,
                                                      cv_tkn_table, cv_xoha,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
      EXCEPTION
        -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
        WHEN OTHERS THEN
          lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                    cv_tkn_api_name, cv_api_update_line_item,
                                                    cv_tkn_type, lv_tkn_biz_type,
                                                    cv_tkn_no_type, lv_tkn_request_no,
                                                    cv_tkn_request_no, iv_request_no,
                                                    cv_tkn_err_msg, SQLERRM);
          FND_LOG.STRING(cv_log_level,gv_pkg_name
                        || cv_colon
                        || cv_prg_name,lv_except_msg);
        RETURN gn_status_error;
--
      END;
--
    -- **************************************************
    -- *** 3.�Ɩ���ʂ��ړ��̏ꍇ
    -- **************************************************
    ELSIF (iv_biz_type = cv_move) THEN
--
      BEGIN
--
        BEGIN
          -- (1)�ړ��˗�/�w���w�b�_(�A�h�I��)���獀�ڂ��擾
          -- ���b�N���擾����
          SELECT  mrih.status,                            -- �X�e�[�^�X
                  --mrih.actual_shipping_method_code,       -- �z���敪_����
                  NVL(mrih.actual_shipping_method_code,
                      mrih.shipping_method_code),         -- �z���敪_���сANULL�̂Ƃ��́A�z���敪���擾
                  mrih.delivery_no,                       -- �z��No
                  mrih.mov_hdr_id,                        -- �ړ��w�b�_ID
                  mrih.shipped_locat_code,                -- �o�Ɍ��ۊǏꏊ
                  mrih.ship_to_locat_code,                -- ���ɐ�ۊǏꏊ
                  mrih.product_flg,                       -- ���i���ʋ敪
                  --mrih.actual_ship_date,                  -- �o�Ɏ��ѓ�
                  NVL(mrih.actual_ship_date,
                      mrih.schedule_ship_date),           -- �o�Ɏ��ѓ��ANULL�̂Ƃ��́A�o�ɗ\������擾
                  mrih.item_class,                        -- ���i�敪
                  --mrih.out_pallet_qty                     -- �p���b�g�����i�o�j
                  NVL(mrih.out_pallet_qty, 0)             -- �p���b�g�����i�o�j�ANULL�̂Ƃ��́A0��ݒ�
-- 2008/08/07 H.Itou Add Start �ύX�v��#173 �^���敪�擾�ǉ�
                 ,mrih.freight_charge_class               -- �^���敪
-- 2008/08/07 H.Itou Add End
          INTO    lv_status,
                  lv_actual_shipping_method_code,
                  lv_delivery_no,
                  ln_mov_hdr_id,
                  lv_shipped_locat_code,
                  lv_ship_to_locat_code,
                  lv_product_flg,
                  ld_actual_ship_date,
                  lv_item_class,
                  ln_out_pallet_qty
-- 2008/08/07 H.Itou Add Start �ύX�v��#173 �^���敪�擾�ǉ�
                 ,lv_freight_charge_class
-- 2008/08/07 H.Itou Add End
          FROM    xxinv_mov_req_instr_headers      mrih   -- �ړ��˗�/�w���w�b�_(�A�h�I��)
          WHERE   mrih.mov_num             =    iv_request_no
          FOR UPDATE OF mrih.mov_hdr_id NOWAIT;
--
        EXCEPTION
          -- �擾�ł��Ȃ������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN NO_DATA_FOUND THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_err,
                                                      cv_tkn_table, cv_mrih,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN OTHERS THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                      cv_tkn_api_name, cv_api_mrih,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_err_msg, SQLERRM);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
        -- �擾�����X�e�[�^�X����o�ɕ񍐗L��A����o�ɕ񍐗L��ȊO�̏ꍇ��
        -- �Ԃ�l��0�F����OR�ΏۊO��Ԃ��I��
        IF (lv_status NOT IN (cv_shiped_report, cv_delivery_report)) THEN
          RETURN gn_status_normal;
        END IF;
--
        -- �擾�����z��No��z�Ԕz���v��X�V���ڂƂ��ăZ�b�g
        lv_update_delivery_no := lv_delivery_no;
--
        BEGIN
        -- �J�E���g�ϐ��̏�����
        ln_counter := 0;
--
          -- (3)�ړ��˗�/�w������(�A�h�I��)�AOPM�i�ڃ}�X�^���獀�ڂ��擾
          -- ���b�N���擾����
          <<move_loop>>
          FOR get_move_data IN move_cur LOOP
            lt_move_tab(ln_counter).shipped_quantity := get_move_data.shipped_quantity;
            lt_move_tab(ln_counter).item_code        := get_move_data.item_code;
            lt_move_tab(ln_counter).conv_unit        := get_move_data.conv_unit;
            lt_move_tab(ln_counter).num_of_cases     := get_move_data.num_of_cases;
            lt_move_tab(ln_counter).num_of_deliver   := get_move_data.num_of_deliver;
            lt_move_tab(ln_counter).mov_line_id      := get_move_data.mov_line_id;
--
            -- (4)���ʊ֐���ύڌ����`�F�b�N(���v�l�Z�o)����Ăяo��
            xxwsh_common910_pkg.calc_total_value(
              lt_move_tab(ln_counter).item_code,        -- �i��
              lt_move_tab(ln_counter).shipped_quantity, -- �o�׎��ѐ���
              lv_retcode,                               -- ���^�[���R�[�h
              lv_errmsg_code,                           -- �G���[���b�Z�[�W�R�[�h
              lv_errmsg,                                -- �G���[���b�Z�[�W
              ln_sum_weight,                            -- ���v�d��
              ln_sum_capacity,                          -- ���v�e��
              ln_sum_pallet_weight);                    -- ���v�p���b�g�d��
--
            -- ���^�[���R�[�h��'1'(�ُ�)�̏ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
            IF (lv_retcode = gn_status_error) THEN
              lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                        cv_tkn_api_name, cv_api_calc_total_value,
                                                        cv_tkn_type, lv_tkn_biz_type,
                                                        cv_tkn_no_type, lv_tkn_request_no,
                                                        cv_tkn_request_no, iv_request_no,
                                                        cv_tkn_err_msg, lv_errmsg);
              FND_LOG.STRING(cv_log_level,gv_pkg_name
                            || cv_colon
                            || cv_prg_name,lv_except_msg);
              RETURN gn_status_error;
--
            -- ���펞�͍X�V���ڂɒl��ǉ�
            ELSE
-- 2008/08/07 H.Itou Add Start �ύX�v��#173 �ύڏd�ʍ��v�E�ύڗe�ύ��v��NULL�ɂȂ�Ȃ��悤�ɁANVL����B
              ln_sum_weight        := NVL(ln_sum_weight, 0);       -- ���v�d��
              ln_sum_capacity      := NVL(ln_sum_capacity, 0);     -- ���v�e��
              ln_sum_pallet_weight := NVL(ln_sum_pallet_weight, 0);-- ���v�p���b�g��
-- 2008/08/07 H.Itou Add End
              -- �y���׍X�V���ځz
              lt_update_tbl(ln_counter).update_weight         :=  ln_sum_weight;
              lt_update_tbl(ln_counter).update_capacity       :=  ln_sum_capacity;
              lt_update_tbl(ln_counter).update_pallet_weight  :=  ln_sum_pallet_weight;
              lt_update_tbl(ln_counter).update_line_id :=  lt_move_tab(ln_counter).mov_line_id;
--
              --�y�w�b�_�X�V���ځz
              ln_update_sum_weight        :=  NVL(ln_update_sum_weight, 0)   + ln_sum_weight;
              ln_update_sum_capacity      :=  NVL(ln_update_sum_capacity, 0) + ln_sum_capacity;
              ln_update_sum_pallet_weight :=  NVL(ln_update_sum_pallet_weight, 0)
                                              + (ln_out_pallet_qty * ln_pallet_waight);
--
              -- �@(1)�Ŏ擾�������i���ʋ敪������i��ȊO�̏ꍇ
              IF (lv_product_flg <> cv_product) THEN
                NULL;
--
              -- �A(3)�Ŏ擾�����o�Ɏ��ѐ��ʂ�0�̏ꍇ
              ELSIF (lt_move_tab(ln_counter).shipped_quantity = 0) THEN
                ln_update_small_quantity  :=  NVL(ln_update_small_quantity, 0)
                                              + lt_move_tab(ln_counter).shipped_quantity;
--
              -- �B(3)�Ŏ擾�����o�ד������ݒ肳��Ă���ꍇ
-- 2008/08/07 H.Itou Mod Start �����ۑ�#32 �o�ד��� > 0 �ɏ����ύX�B
--              ELSIF (lt_move_tab(ln_counter).num_of_deliver IS NOT NULL) THEN
              ELSIF (lt_move_tab(ln_counter).num_of_deliver > 0 ) THEN
-- 2008/08/07 H.Itou Mod End
                ln_update_small_quantity  :=  NVL(ln_update_small_quantity, 0)
-- 2008/08/07 H.Itou Mod Start �ύX�v��#166 ���גP�ʂŐ����ɐ؂�グ�A���v����B
--                                              + ROUND(lt_move_tab(ln_counter).shipped_quantity
                                              + CEIL(lt_move_tab(ln_counter).shipped_quantity
-- 2008/08/07 H.Itou Mod End
                                              / lt_move_tab(ln_counter).num_of_deliver);
--
-- 2008/08/07 H.Itou Mod Start �����ۑ�#32 ���o�Ɋ��Z�P�� IS NOT NULL �ɏ����ύX�B
              -- �C(3)�Ŏ擾�����P�[�X�������ݒ肳��Ă���ꍇ
--              ELSIF (lt_move_tab(ln_counter).num_of_cases IS NOT NULL) THEN
              ELSIF (lt_move_tab(ln_counter).conv_unit IS NOT NULL) THEN
-- 2008/08/07 H.Itou Mod End
                ln_update_small_quantity  :=  NVL(ln_update_small_quantity, 0)
-- 2008/08/07 H.Itou Mod Start �ύX�v��#166 ���גP�ʂŐ����ɐ؂�グ�A���v����B
--                                              + ROUND(lt_move_tab(ln_counter).shipped_quantity
                                              + CEIL(lt_move_tab(ln_counter).shipped_quantity
-- 2008/08/07 H.Itou Mod End
                                              / lt_move_tab(ln_counter).num_of_cases);
--
              -- �D������̏����ɂ����Ă͂܂�Ȃ��ꍇ
              ELSE
                ln_update_small_quantity  :=  NVL(ln_update_small_quantity, 0)
-- 2008/08/07 H.Itou Mod Start �ύX�v��#166 ���גP�ʂŐ����ɐ؂�グ�A���v����B
--                                              + lt_move_tab(ln_counter).shipped_quantity;
                                             + CEIL(lt_move_tab(ln_counter).shipped_quantity);
-- 2008/08/07 H.Itou Mod End
--
              END IF;
--
            END IF;
--
            -- �J�E���g�ϐ����C���N�������g
            ln_counter := ln_counter + 1;
--
          END LOOP move_loop;
--
        EXCEPTION
          -- �擾�ł��Ȃ������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN NO_DATA_FOUND THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_err,
                                                      cv_tkn_table, cv_mov_lines_item_mst,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN OTHERS THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                      cv_tkn_api_name, cv_api_mril_im,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_err_msg, SQLERRM);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
          RETURN gn_status_error;
--
        END;
--
        -- �ϐ�������
        lv_retcode      :=NULL;   -- ���^�[���R�[�h
        lv_errmsg_code  :=NULL;   -- �G���[���b�Z�[�W�R�[�h
        lv_errmsg       :=NULL;   -- �G���[���b�Z�[�W
--
-- 2008/08/07 H.Itou Mod Start �ύX�v��#173 �ύڌ����Z�o�����́A�z��No�ł͂Ȃ��A�^���敪�Ŕ���
--        -- (5)(1)�Ŕz��No���ݒ肳��Ă���ꍇ�A���ʊ֐���ύڌ����`�F�b�N(�ύڌ����Z�o)����Ăяo��
--        IF (lv_update_delivery_no IS NOT NULL) THEN
        -- �^���敪�u1�v�̏ꍇ
        IF (lv_freight_charge_class = gv_freight_charge_yes) THEN
-- 2008/08/07 H.Itou Mod End
-- 2008/08/07 H.Itou Del Start �ύX�v��#173 �d�ʐύڌ����Z�o�͐ύڍ��v�d�ʂ̒l�Ɋւ�炸�Z�o����B
--          -- ���v�d�ʂ��ݒ肳��Ă���ꍇ
--          IF (ln_update_sum_weight > 0) THEN
-- 2008/08/07 H.Itou Del End
--
          BEGIN
            -- �擾�����z���敪_���т����ƂɃN�C�b�N�R�[�h�XXCMN_SHIP_METHOD����珬���敪���擾
            SELECT  xsm2.small_amount_class
            INTO    lv_small_sum_class
            FROM    xxwsh_ship_method2_v    xsm2
            WHERE   xsm2.ship_method_code   =  lv_actual_shipping_method_code
            AND     xsm2.start_date_active  <= ld_actual_ship_date
            AND     ld_actual_ship_date     <= NVL(xsm2.end_date_active, ld_actual_ship_date);
--
          EXCEPTION
            -- �擾�ł��Ȃ������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
            WHEN NO_DATA_FOUND THEN
              lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_err,
                                                        cv_tkn_table, cv_small_sum_class,
                                                        cv_tkn_type, lv_tkn_biz_type,
                                                        cv_tkn_no_type, lv_tkn_request_no,
                                                        cv_tkn_request_no, iv_request_no);
              FND_LOG.STRING(cv_log_level,gv_pkg_name
                            || cv_colon
                            || cv_prg_name,lv_except_msg);
              RETURN gn_status_error;
--
            -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
            WHEN OTHERS THEN
              lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                        cv_tkn_api_name, cv_api_small_sum_class,
                                                        cv_tkn_type, lv_tkn_biz_type,
                                                        cv_tkn_no_type, lv_tkn_request_no,
                                                        cv_tkn_request_no, iv_request_no,
                                                        cv_tkn_err_msg, SQLERRM);
              FND_LOG.STRING(cv_log_level,gv_pkg_name
                            || cv_colon
                            || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          END;
--
          -- �d�ʐύڌ����Z�o
          xxwsh_common910_pkg.calc_load_efficiency(
            (CASE
              -- �@(2)�Ŏ擾���������敪����Ώۣ�̏ꍇ
              WHEN (lv_small_sum_class = cv_include) THEN
                ln_update_sum_weight
              -- �A(2)�Ŏ擾���������敪����Ώۣ�ȊO�̏ꍇ
              ELSE
                ln_update_sum_weight + NVL(ln_update_sum_pallet_weight, 0)
            END),                                     -- 1.���v�d��
            NULL,                                     -- 2.���v�e��
            cv_whse,                                  -- 3.�R�[�h�敪�P
            lv_shipped_locat_code,                    -- 4.���o�ɏꏊ�R�[�h�P
            cv_whse,                                  -- 5.�R�[�h�敪�Q
            lv_ship_to_locat_code,                    -- 6.���o�ɏꏊ�R�[�h�Q
            lv_actual_shipping_method_code,           -- 7.�o�ו��@
            lv_item_class,                            -- 8.���i�敪
            NULL,                                     -- 9.�����z�ԑΏۋ敪
            ld_actual_ship_date,                      -- 10.���(�K�p�����)
            lv_retcode,                               -- 11.���^�[���R�[�h
            lv_errmsg_code,                           -- 12.�G���[���b�Z�[�W�R�[�h
            lv_errmsg,                                -- 13.�G���[���b�Z�[�W
            lv_loading_over_class,                    -- 14.�ύڃI�[�o�[�敪
            lv_ship_methods,                          -- 15.�o�ו��@
            ln_load_efficiency_weight,                -- 16.�d�ʐύڌ���
            ln_load_efficiency_capacity,              -- 17.�e�ϐύڌ���
            lv_mixed_ship_method);                    -- 18.���ڔz���敪
--
          -- ���^�[���R�[�h��'1'(�ُ�)�̏ꍇ�͕Ԃ�l��1�F�G���[��Ԃ��I��
          IF (lv_retcode = gn_status_error) THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                      cv_tkn_api_name, cv_api_weight,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_err_msg, lv_errmsg);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          END IF;
--
          -- �擾�����d�ʐύڌ������w�b�_�X�V�p���ڂɃZ�b�g
          ln_update_load_effi_weight := ln_load_efficiency_weight;
--
-- 2008/08/07 H.Itou Del Start �ύX�v��#173 �d�ʐύڌ����Z�o�͐ύڍ��v�d�ʂ̒l�Ɋւ�炸�Z�o����B
--          END IF;
-- 2008/08/07 H.Itou Del End
--
-- 2008/08/07 H.Itou Del Start �ύX�v��#173 �e�ϐύڌ����Z�o�͐ύڍ��v�e�ς̒l�Ɋւ�炸�Z�o����B
--          -- ���v�e�ς��ݒ肳��Ă���ꍇ
--          IF (ln_update_sum_capacity > 0) THEN
-- 2008/08/07 H.Itou Del End
          -- �e�ϐύڌ����Z�o
          xxwsh_common910_pkg.calc_load_efficiency(
            NULL,                                     -- 1.���v�d��
            ln_update_sum_capacity,                   -- 2.���v�e��
            cv_whse,                                  -- 3.�R�[�h�敪�P
            lv_shipped_locat_code,                    -- 4.���o�ɏꏊ�R�[�h�P
            cv_whse,                                  -- 5.�R�[�h�敪�Q
            lv_ship_to_locat_code,                    -- 6.���o�ɏꏊ�R�[�h�Q
            lv_actual_shipping_method_code,           -- 7.�o�ו��@
            lv_item_class,                            -- 8.���i�敪
            NULL,                                     -- 9.�����z�ԑΏۋ敪
            ld_actual_ship_date,                      -- 10.���(�K�p�����)
            lv_retcode,                               -- 11.���^�[���R�[�h
            lv_errmsg_code,                           -- 12.�G���[���b�Z�[�W�R�[�h
            lv_errmsg,                                -- 13.�G���[���b�Z�[�W
            lv_loading_over_class,                    -- 14.�ύڃI�[�o�[�敪
            lv_ship_methods,                          -- 15.�o�ו��@
            ln_load_efficiency_weight,                -- 16.�d�ʐύڌ���
            ln_load_efficiency_capacity,              -- 17.�e�ϐύڌ���
            lv_mixed_ship_method);                    -- 18.���ڔz���敪
--
          -- ���^�[���R�[�h��'1'(�ُ�)�̏ꍇ�͕Ԃ�l��1�F�G���[��Ԃ��I��
          IF (lv_retcode = gn_status_error) THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                      cv_tkn_api_name, cv_api_capacity,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_err_msg, lv_errmsg);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          END IF;
--
          -- �擾�����e�ϐύڌ������w�b�_�X�V�p���ڂɃZ�b�g
          ln_update_load_effi_capacity := ln_load_efficiency_capacity;
--
-- 2008/08/07 H.Itou Del Start �ύX�v��#173 �e�ϐύڌ����Z�o�͐ύڍ��v�e�ς̒l�Ɋւ�炸�Z�o����B
--          END IF;
-- 2008/08/07 H.Itou Del End
--
        END IF;
--
        BEGIN
          <<mov_lines_update_loop>>
          FOR i IN lt_update_tbl.FIRST .. lt_update_tbl.LAST LOOP
            -- (6)�ړ��˗�/�w������(�A�h�I��)�𖾍׍X�V���ڂɓo�^����Ă�����e�ōX�V
            UPDATE  xxinv_mov_req_instr_lines       mril            -- �ړ��˗�/�w������(�A�h�I��)
            SET     mril.weight                   =  lt_update_tbl(i).update_weight,
                    mril.capacity                 =  lt_update_tbl(i).update_capacity,
                    mril.pallet_weight            =  lt_update_tbl(i).update_pallet_weight,
                    mril.last_updated_by          =  ln_user_id,
                    mril.last_update_date         =  ld_sysdate,
                    mril.last_update_login        =  ln_login_id,
                    mril.request_id               =  ln_conc_request_id,
                    mril.program_application_id   =  ln_prog_appl_id,
                    mril.program_id               =  ln_conc_program_id,
                    mril.program_update_date      =  ld_sysdate
            WHERE   mril.mov_line_id              =  lt_update_tbl(i).update_line_id;
--
          END LOOP mov_lines_update_loop;
--
        EXCEPTION
          -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN OTHERS THEN
            -- �Z�[�u�|�C���g�փ��[���o�b�N
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_update_err,
                                                      cv_tkn_table, cv_mril,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
        BEGIN
          -- (7)�ړ��˗�/�w���w�b�_(�A�h�I��)���w�b�_�X�V���ڂɓo�^����Ă�����e�ōX�V
          UPDATE  xxinv_mov_req_instr_headers       mrih            -- �ړ��˗�/�w���w�b�_(�A�h�I��)
          -- �ύڏd�ʍ��v
          SET     mrih.sum_weight         = ln_update_sum_weight,
          -- �ύڗe�ύ��v
                  mrih.sum_capacity       = ln_update_sum_capacity,
          -- ���v�p���b�g�d��
                  mrih.sum_pallet_weight  = ln_update_sum_pallet_weight,
          -- ������
                  mrih.small_quantity    =
                   (CASE
                     WHEN (lv_product_flg = cv_product) THEN
                       ln_update_small_quantity
                     ELSE
                       mrih.small_quantity
                   END),
          -- �d�ʐύڌ���
                  mrih.loading_efficiency_weight =
                   (CASE
-- 2008/08/07 H.Itou Mod Start �ύX�v��#173
--                     WHEN (lv_update_delivery_no IS NOT NULL) THEN
--                       ln_update_load_effi_weight
--                     ELSE
--                       mrih.loading_efficiency_weight
                     -- �^���敪�u1�v�̏ꍇ�A�����Ŏ擾�����l���X�V
                     WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                       ln_update_load_effi_weight
                     -- ��L�ȊO�̏ꍇ�ANULL���X�V
                     ELSE
                       NULL
-- 2008/08/07 H.Itou Mod End
                   END),
          -- �e�ϐύڌ���
                  mrih.loading_efficiency_capacity  =
                   (CASE
-- 2008/08/07 H.Itou Mod Start �ύX�v��#173
--                     WHEN (lv_update_delivery_no IS NOT NULL) THEN
--                       ln_update_load_effi_capacity
--                     ELSE
--                       mrih.loading_efficiency_capacity
                     -- �^���敪�u1�v�̏ꍇ�A�����Ŏ擾�����l���X�V
                     WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                       ln_update_load_effi_capacity
                     -- ��L�ȊO�̏ꍇ�ANULL���X�V
                     ELSE
                       NULL
-- 2008/08/07 H.Itou Mod End
                   END),
-- 2008/08/07 H.Itou Add Start �ύX�v��#173
          -- ��{�d��
                  mrih.based_weight =
                    (CASE
                       -- �^���敪�u1�v�̏ꍇ�A�X�V���Ȃ��i���݂̒l�ōX�V�j
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         mrih.based_weight
                       -- ��L�ȊO�̏ꍇ�ANULL���X�V
                       ELSE
                         NULL
                     END),
          -- ��{�e��
                  mrih.based_capacity =
                    (CASE
                       -- �^���敪�u1�v�̏ꍇ�A�X�V���Ȃ��i���݂̒l�ōX�V�j
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         mrih.based_capacity
                       -- ��L�ȊO�̏ꍇ�ANULL���X�V
                       ELSE
                         NULL
                     END),
          -- �z���敪
                  mrih.shipping_method_code =
                    (CASE
                       -- �^���敪�u1�v�̏ꍇ�A�X�V���Ȃ��i���݂̒l�ōX�V�j
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         mrih.shipping_method_code
                       -- ��L�ȊO�̏ꍇ�ANULL���X�V
                       ELSE
                         NULL
                     END),
          -- �z���敪_����
                  mrih.actual_shipping_method_code =
                    (CASE
                       -- �^���敪�u1�v�̏ꍇ�A�X�V���Ȃ��i���݂̒l�ōX�V�j
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         mrih.actual_shipping_method_code
                       -- ��L�ȊO�̏ꍇ�ANULL���X�V
                       ELSE
                         NULL
                     END),
-- 2008/08/07 H.Itou Add End
                  mrih.last_updated_by           =  ln_user_id,
                  mrih.last_update_date          =  ld_sysdate,
                  mrih.last_update_login         =  ln_login_id,
                  mrih.request_id                =  ln_conc_request_id,
                  mrih.program_application_id    =  ln_prog_appl_id,
                  mrih.program_id                =  ln_conc_program_id,
                  mrih.program_update_date       =  ld_sysdate
          WHERE   mrih.mov_hdr_id                =  ln_mov_hdr_id;
--
        EXCEPTION
          -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN OTHERS THEN
            -- �Z�[�u�|�C���g�փ��[���o�b�N
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_update_err,
                                                      cv_tkn_table, cv_mrih,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
      EXCEPTION
        -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
        WHEN OTHERS THEN
          lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                    cv_tkn_api_name, cv_api_update_line_item,
                                                    cv_tkn_type, lv_tkn_biz_type,
                                                    cv_tkn_no_type, lv_tkn_request_no,
                                                    cv_tkn_request_no, iv_request_no,
                                                    cv_tkn_err_msg, SQLERRM);
          FND_LOG.STRING(cv_log_level,gv_pkg_name
                        || cv_colon
                        || cv_prg_name,lv_except_msg);
        RETURN gn_status_error;
--
      END;
--
    END IF;
--
    -- **************************************************
    -- *** 4.�z�Ԕz���v��X�V
    -- **************************************************
    -- �ϐ�������
    lv_result_shipping_method_code      := NULL;   -- �z���敪_����
    lv_result_deliver_to                := NULL;   -- �o�א�_����
    lv_deliver_from                     := NULL;   -- �o�׌��ۊǏꏊ
    lv_small_sum_class                  := NULL;   -- �����敪
    ln_sum_weight                       := NULL;   -- ���v�d��
    ln_sum_capacity                     := NULL;   -- ���v�e��
    ln_sum_pallet_weight                := NULL;   -- ���v�p���b�g�d��
--
    -- ��L1.�`3.�̏����Ŕz�Ԕz���v��X�V����.�z��No���ݒ肳��Ă���ꍇ
    IF (lv_update_delivery_no IS NOT NULL) THEN
--
      BEGIN
--
        BEGIN
          -- (1)�z�Ԕz���v��i�A�h�I���j����z���敪_���сA�����No���擾
          -- ���b�N���擾����
          --SELECT  xcs.result_shipping_method_code,      -- �z���敪_����
          SELECT  NVL(xcs.result_shipping_method_code,
                      xcs.delivery_type),               -- �z���敪_���сANULL�̂Ƃ��́A�z���敪
                  xcs.default_line_number               -- �����No
          INTO    lv_result_shipping_method_code,
                  lv_default_line_number
          FROM    xxwsh_carriers_schedule    xcs         -- �z�Ԕz���v��i�A�h�I���j
          WHERE   xcs.delivery_no         =  lv_update_delivery_no
          FOR UPDATE OF xcs.transaction_id NOWAIT;
--
        EXCEPTION
          -- �擾�ł��Ȃ������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN NO_DATA_FOUND THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_carry_err,
                                                      cv_tkn_table, cv_xcs,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN OTHERS THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_carry_err,
                                                      cv_tkn_api_name, cv_api_xcs,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
          RETURN gn_status_error;
--
        END;
--
        BEGIN
          -- (2)�ύڌ����Z�o�ɕK�v�ȍ��ڂ��擾
          SELECT  xoha.vendor_site_code,                  -- �����T�C�g
                  xoha.deliver_from,                      -- �o�׌��ۊǏꏊ
                  --xoha.result_deliver_to,                 -- �o�א�_����
                  NVL(xoha.result_deliver_to,
                      xoha.deliver_to),                   -- �o�א�_���сANULL�̂Ƃ��́A�o�א���擾
                  xott.shipping_shikyu_class,             -- �o�׎x���敪
                  --xoha.shipped_date,                      -- �o�ד�
                  NVL(xoha.shipped_date,
                      xoha.schedule_ship_date),           -- �o�ד��ANULL�̂Ƃ��́A�o�ח\������擾
                  xoha.prod_class                         -- ���i�敪
          INTO    lv_vendor_site_code,
                  lv_deliver_from,
                  lv_result_deliver_to,
                  lv_attribute1,
                  ld_date,
                  lv_syohin_class
          FROM    xxwsh_order_headers_all       xoha,       -- �󒍃w�b�_�A�h�I��
                  xxwsh_oe_transaction_types_v  xott        -- �󒍃^�C�v���VIEW
          WHERE   xoha.request_no                             =  lv_default_line_number
          AND     xoha.order_type_id                          =  xott.transaction_type_id
          AND     NVL(xoha.latest_external_flag, cv_flag_no)  =  cv_flag_yes;
--
          -- ��L�����Ŏ擾�ł����ꍇ�A������ʂ��Z�b�g
          -- �@�o�׎x���敪����o�׈˗���̏ꍇ
          IF (lv_attribute1 = cv_ship_req) THEN
            lv_process_class := cv_ship;
          -- �A�o�׎x���敪����x���˗���̏ꍇ
          ELSIF (lv_attribute1 = cv_supply_req) THEN
            lv_process_class := cv_supply;
          END IF;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            BEGIN
              -- ��L�����Ŏ擾�ł��Ȃ������ꍇ�A�ύڌ����Z�o�ɕK�v�ȍ��ڂ��擾
              SELECT  mrih.shipped_locat_code,                -- �o�Ɍ��ۊǏꏊ
                      mrih.ship_to_locat_code,                -- ���ɐ�ۊǏꏊ
                      --mrih.actual_ship_date,                  -- �o�Ɏ��ѓ�
                      NVL(mrih.actual_ship_date,
                          mrih.schedule_ship_date),           -- �o�Ɏ��ѓ��ANULL�̂Ƃ��́A�o�ɗ\������擾
                      mrih.item_class                         -- ���i�敪
              INTO    lv_shipped_locat_code,
                      lv_ship_to_locat_code,
                      ld_date,
                      lv_syohin_class
              FROM    xxinv_mov_req_instr_headers      mrih   -- �ړ��˗�/�w���w�b�_(�A�h�I��)
              WHERE   mrih.mov_num                =  lv_default_line_number;
--
              -- ��L�����Ŏ擾�ł����ꍇ�A������ʂɢ�ړ�����Z�b�g
                lv_process_class := cv_move;
--
            EXCEPTION
              -- �擾�ł��Ȃ������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
              WHEN NO_DATA_FOUND THEN
                -- �Z�[�u�|�C���g�փ��[���o�b�N
                ROLLBACK TO advance_sp;
                lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_carry_err,
                                                      cv_tkn_table, cv_carriers_info,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number);
                FND_LOG.STRING(cv_log_level,gv_pkg_name
                              || cv_colon
                              || cv_prg_name,lv_except_msg);
                RETURN gn_status_error;
--
              -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
              WHEN OTHERS THEN
                -- �Z�[�u�|�C���g�փ��[���o�b�N
                ROLLBACK TO advance_sp;
                lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_carry_err,
                                                      cv_tkn_api_name, cv_api_carriers_info,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number);
                FND_LOG.STRING(cv_log_level,gv_pkg_name
                              || cv_colon
                              || cv_prg_name,lv_except_msg);
                RETURN gn_status_error;
--
            END;
--
          -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN OTHERS THEN
            -- �Z�[�u�|�C���g�փ��[���o�b�N
            ROLLBACK TO advance_sp;
                lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_carry_err,
                                                      cv_tkn_api_name, cv_api_carriers_info,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
        BEGIN
          -- (3)�擾�����z���敪_���т����ƂɃN�C�b�N�R�[�h�XXCMN_SHIP_METHOD����珬���敪���擾
          SELECT  xsm2.small_amount_class
          INTO    lv_small_sum_class
          FROM    xxwsh_ship_method2_v    xsm2
          WHERE   xsm2.ship_method_code   =  lv_result_shipping_method_code
          AND     xsm2.start_date_active  <= ld_date
          AND     ld_date                 <= NVL(xsm2.end_date_active, ld_date);
--
        EXCEPTION
          -- �擾�ł��Ȃ������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN NO_DATA_FOUND THEN
            -- �Z�[�u�|�C���g�փ��[���o�b�N
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_carry_err,
                                                      cv_tkn_table, cv_small_sum_class,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN OTHERS THEN
            -- �Z�[�u�|�C���g�փ��[���o�b�N
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_carry_err,
                                                      cv_tkn_api_name, cv_api_small_sum_class,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
        BEGIN
          -- (4)�e�w�b�_�̐ύڏd�ʍ��v�A�ύڗe�ύ��v�A���v�p���b�g�d�ʂ̍��v�l���擾
          SELECT  SUM(xomh.sum_weight),
                  SUM(xomh.sum_capacity),
                  SUM(xomh.sum_pallet_weight)
          INTO    ln_sum_weight,
                  ln_sum_capacity,
                  ln_sum_pallet_weight
          FROM
            ((SELECT xoha.sum_weight,
                    xoha.sum_capacity,
                    xoha.sum_pallet_weight
            FROM    xxwsh_order_headers_all         xoha
            WHERE   xoha.delivery_no                            =  lv_update_delivery_no
            AND     NVL(xoha.latest_external_flag, cv_flag_no)  =  cv_flag_yes)
            UNION ALL
            (SELECT mrih.sum_weight,
                    mrih.sum_capacity,
                    mrih.sum_pallet_weight
            FROM    xxinv_mov_req_instr_headers     mrih
            WHERE   mrih.delivery_no            =  lv_update_delivery_no)) xomh;
--
        EXCEPTION
          -- �擾�ł��Ȃ������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN NO_DATA_FOUND THEN
            -- �Z�[�u�|�C���g�փ��[���o�b�N
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_carry_err,
                                                      cv_tkn_table, cv_order_mov_headers,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN OTHERS THEN
            -- �Z�[�u�|�C���g�փ��[���o�b�N
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_carry_err,
                                                      cv_tkn_api_name, cv_api_xoha_mrih,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
        -- (5)�z�Ԕz���v��X�V���ڂ��Z�b�g
        -- �ύڏd�ʍ��v
        -- �@(3)�Ŏ擾���������敪����Ώۣ�̏ꍇ
        IF (lv_small_sum_class = cv_include) THEN
          ln_update_weight := ln_sum_weight;
        -- �A(3)�Ŏ擾���������敪����Ώۣ�ȊO�̏ꍇ
        ELSE
          ln_update_weight := ln_sum_weight + ln_sum_pallet_weight;
        END IF;
--
        -- �ύڗe�ύ��v
        ln_update_capacity := ln_sum_capacity;
--
        -- �ϐ�������
        lv_retcode      :=NULL;   -- ���^�[���R�[�h
        lv_errmsg_code  :=NULL;   -- �G���[���b�Z�[�W�R�[�h
        lv_errmsg       :=NULL;   -- �G���[���b�Z�[�W
--
        -- (6)���ʊ֐���ύڌ����`�F�b�N(�ύڌ����Z�o)����Ăяo��
        -- ���v�d�ʂ��ݒ肳��Ă���ꍇ
        IF (ln_sum_weight IS NOT NULL) THEN
          -- �@�d�ʐύڌ����Z�o
          xxwsh_common910_pkg.calc_load_efficiency(
            ln_sum_weight,                         -- 1.���v�d��
            NULL,                                  -- 2.���v�e��
            cv_whse,                               -- 3.�R�[�h�敪�P
            (CASE
              -- �@(2)�Ŏ擾����������ʂ��o�ׂ������͎x���̏ꍇ
              WHEN (lv_process_class IN (cv_ship_req, cv_supply_req)) THEN
                lv_deliver_from
              -- �A(2)�Ŏ擾����������ʂ��ړ��̏ꍇ
              WHEN (lv_process_class = cv_move_req) THEN
                lv_shipped_locat_code
            END),                                     -- 4.���o�ɏꏊ�R�[�h�P
            (CASE
              -- �@(2)�Ŏ擾����������ʂ��o�ׂ̏ꍇ
              WHEN (lv_process_class = cv_ship_req) THEN
                cv_deliver_to
              -- �A(2)�Ŏ擾����������ʂ��x���̏ꍇ
              WHEN (lv_process_class = cv_supply_req) THEN
                cv_supply_to
              -- �B(2)�Ŏ擾����������ʂ��ړ��̏ꍇ
              WHEN (lv_process_class = cv_move_req) THEN
                cv_whse
            END),                                     -- 5.�R�[�h�敪�Q
            (CASE
              -- �@(2)�Ŏ擾����������ʂ��o�ׂ̏ꍇ
              WHEN (lv_process_class = cv_ship_req) THEN
                lv_result_deliver_to
              -- �A(2)�Ŏ擾����������ʂ��x���̏ꍇ
              WHEN (lv_process_class = cv_supply_req) THEN
                lv_vendor_site_code
              -- �B(2)�Ŏ擾����������ʂ��ړ��̏ꍇ
              WHEN (lv_process_class = cv_move_req) THEN
                lv_ship_to_locat_code
            END),                                     -- 6.���o�ɏꏊ�R�[�h�Q
            lv_result_shipping_method_code,           -- 7.�o�ו��@
            lv_syohin_class,                          -- 8.���i�敪
            NULL,                                     -- 9.�����z�ԑΏۋ敪
            ld_date,                                  -- 10.���(�K�p�����)
            lv_retcode,                               -- 11.���^�[���R�[�h
            lv_errmsg_code,                           -- 12.�G���[���b�Z�[�W�R�[�h
            lv_errmsg,                                -- 13.�G���[���b�Z�[�W
            lv_loading_over_class,                    -- 14.�ύڃI�[�o�[�敪
            lv_ship_methods,                          -- 15.�o�ו��@
            ln_load_efficiency_weight,                -- 16.�d�ʐύڌ���
            ln_load_efficiency_capacity,              -- 17.�e�ϐύڌ���
            lv_mixed_ship_method);                    -- 18.���ڔz���敪
--
          -- ���^�[���R�[�h��'1'(�ُ�)�̏ꍇ�͕Ԃ�l��1�F�G���[��Ԃ��I��
          IF (lv_retcode = gn_status_error) THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_carry_err,
                                                      cv_tkn_api_name, cv_api_weight,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number,
                                                      cv_tkn_err_msg, lv_errmsg);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          END IF;
--
          -- �擾�����d�ʐύڌ������w�b�_�X�V�p���ڂɃZ�b�g
          ln_update_load_effi_weight := ln_load_efficiency_weight;
--
        END IF;
--
        -- ���v�e�ς��ݒ肳��Ă���ꍇ
        IF (ln_sum_capacity > 0) THEN
          -- �A�e�ϐύڌ����Z�o
          xxwsh_common910_pkg.calc_load_efficiency(
            NULL,                                     -- 1.���v�d��
            ln_sum_capacity,                          -- 2.���v�e��
            cv_whse,                                  -- 3.�R�[�h�敪�P
            (CASE
              -- �@(2)�Ŏ擾����������ʂ��o�ׂ������͎x���̏ꍇ
              WHEN (lv_process_class IN (cv_ship_req, cv_supply_req)) THEN
                lv_deliver_from
              -- �A(2)�Ŏ擾����������ʂ��ړ��̏ꍇ
              WHEN (lv_process_class = cv_move_req) THEN
                lv_shipped_locat_code
            END),                                     -- 4.���o�ɏꏊ�R�[�h�P
            (CASE
              -- �@(2)�Ŏ擾����������ʂ��o�ׂ̏ꍇ
              WHEN (lv_process_class = cv_ship_req) THEN
                cv_deliver_to
              -- �A(2)�Ŏ擾����������ʂ��x���̏ꍇ
              WHEN (lv_process_class = cv_supply_req) THEN
                cv_supply_to
              -- �B(2)�Ŏ擾����������ʂ��ړ��̏ꍇ
              WHEN (lv_process_class = cv_move_req) THEN
                cv_whse
            END),                                     -- 5.�R�[�h�敪�Q
            (CASE
              -- �@(2)�Ŏ擾����������ʂ��o�ׂ̏ꍇ
              WHEN (lv_process_class = cv_ship_req) THEN
                lv_result_deliver_to
              -- �A(2)�Ŏ擾����������ʂ��x���̏ꍇ
              WHEN (lv_process_class = cv_supply_req) THEN
                lv_vendor_site_code
              -- �B(2)�Ŏ擾����������ʂ��ړ��̏ꍇ
              WHEN (lv_process_class = cv_move_req) THEN
                lv_ship_to_locat_code
            END),                                     -- 6.���o�ɏꏊ�R�[�h�Q
            lv_result_shipping_method_code,           -- 7.�o�ו��@
            lv_syohin_class,                          -- 8.���i�敪
            NULL,                                     -- 9.�����z�ԑΏۋ敪
            ld_date,                                  -- 10.���(�K�p�����)
            lv_retcode,                               -- 11.���^�[���R�[�h
            lv_errmsg_code,                           -- 12.�G���[���b�Z�[�W�R�[�h
            lv_errmsg,                                -- 13.�G���[���b�Z�[�W
            lv_loading_over_class,                    -- 14.�ύڃI�[�o�[�敪
            lv_ship_methods,                          -- 15.�o�ו��@
            ln_load_efficiency_weight,                -- 16.�d�ʐύڌ���
            ln_load_efficiency_capacity,              -- 17.�e�ϐύڌ���
            lv_mixed_ship_method);                    -- 18.���ڔz���敪
--
          -- ���^�[���R�[�h��'1'(�ُ�)�̏ꍇ�͕Ԃ�l��1�F�G���[��Ԃ��I��
          IF (lv_retcode = gn_status_error) THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_carry_err,
                                                      cv_tkn_api_name, cv_api_capacity,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number,
                                                      cv_tkn_err_msg, lv_errmsg);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          END IF;
--
          -- �擾�����e�ϐύڌ������w�b�_�X�V�p���ڂɃZ�b�g
          ln_update_load_effi_capacity := ln_load_efficiency_capacity;
--
        END IF;
--
        BEGIN
          -- (7)�z�Ԕz���v��(�A�h�I��)���X�V���ڂɓo�^����Ă�����e�ōX�V
          UPDATE  xxwsh_carriers_schedule       xcs         -- �z�Ԕz���v��i�A�h�I���j
          SET     xcs.sum_loading_weight          =  ln_update_weight,             -- �ύڏd�ʍ��v
                  xcs.sum_loading_capacity        =  ln_update_capacity,           -- �ύڗe�ύ��v
                  xcs.loading_efficiency_weight   =  ln_update_load_effi_weight,   -- �d�ʐύڌ���
                  xcs.loading_efficiency_capacity =  ln_update_load_effi_capacity, -- �e�ϐύڌ���
                  xcs.last_updated_by             =  ln_user_id,
                  xcs.last_update_date            =  ld_sysdate,
                  xcs.last_update_login           =  ln_login_id,
                  xcs.request_id                  =  ln_conc_request_id,
                  xcs.program_application_id      =  ln_prog_appl_id,
                  xcs.program_id                  =  ln_conc_program_id,
                  xcs.program_update_date         =  ld_sysdate
          WHERE   xcs.delivery_no                 =  lv_update_delivery_no;
--
        EXCEPTION
          -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
          WHEN OTHERS THEN
            -- �Z�[�u�|�C���g�փ��[���o�b�N
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_update_carry_err,
                                                      cv_tkn_table, cv_xcs,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
      EXCEPTION
        -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
        WHEN OTHERS THEN
          lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_carry_err,
                                                    cv_tkn_api_name, cv_api_update_line_item,
                                                    cv_tkn_type, lv_tkn_biz_type,
                                                    cv_tkn_no_type, lv_tkn_request_no,
                                                    cv_tkn_request_no, iv_request_no,
                                                    cv_tkn_def_line_num, lv_default_line_number);
          FND_LOG.STRING(cv_log_level,gv_pkg_name
                        || cv_colon
                        || cv_prg_name,lv_except_msg);
        RETURN gn_status_error;
--
      END;
--
    END IF;
--
    RETURN gn_status_normal;
--
  EXCEPTION
    -- ���b�N�����G���[
    WHEN lock_expt THEN
      -- �Z�[�u�|�C���g�փ��[���o�b�N
      ROLLBACK TO advance_sp;
      lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                cv_tkn_api_name, cv_api_lock,
                                                cv_tkn_type, lv_tkn_biz_type,
                                                cv_tkn_no_type, lv_tkn_request_no,
                                                cv_tkn_request_no, iv_request_no,
                                                cv_tkn_err_msg, SQLERRM);
      FND_LOG.STRING(cv_log_level,gv_pkg_name
                    || cv_colon
                    || cv_prg_name,lv_except_msg);
      -- �Ԃ�l��1�F�����G���[��Ԃ��I��
      RETURN gn_status_error;
--
    -- ���̑��̗�O�����������ꍇ�͕Ԃ�l��1�F�����G���[��Ԃ��I��
    WHEN OTHERS THEN
      -- �Z�[�u�|�C���g�փ��[���o�b�N
      ROLLBACK TO advance_sp;
      lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                cv_tkn_api_name, cv_api_update_line_item,
                                                cv_tkn_type, lv_tkn_biz_type,
                                                cv_tkn_no_type, lv_tkn_request_no,
                                                cv_tkn_request_no, iv_request_no,
                                                cv_tkn_err_msg, SQLERRM);
      FND_LOG.STRING(cv_log_level,gv_pkg_name
                    || cv_colon
                    || cv_prg_name,lv_except_msg);
      RETURN gn_status_error;
--
--###############################  �Œ��O������ START   ###################################
--
--    WHEN OTHERS THEN
--      RAISE_APPLICATION_ERROR
--        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END update_line_items;
--
  /**********************************************************************************
   * Function Name    : cancel_reserve
   * Description      : ���������֐�
   ***********************************************************************************/
  FUNCTION cancel_reserve(
    iv_biz_type             IN         VARCHAR2,                              -- 1.�Ɩ����
    iv_request_no           IN         VARCHAR2,                              -- 2.�˗�No/�ړ��ԍ�
    in_line_id              IN         NUMBER,                                -- 3.����ID
    ov_errmsg               OUT NOCOPY VARCHAR2)                              -- 4.�G���[���b�Z�[�W
    RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'cancel_reserve';  -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_yes            CONSTANT VARCHAR2(1)   := 'Y';               -- YES
    cv_flag_no             CONSTANT VARCHAR2(1)   := 'N';               -- NO
    cv_enc_cancel_err      CONSTANT VARCHAR2(2)   := '-1';              -- �����������s
    cv_compl               CONSTANT VARCHAR2(1)   := '0';               -- ����
    cv_para_check_err      CONSTANT VARCHAR2(1)   := '1';               -- �p�����[�^�`�F�b�N�G���[
    cv_enc_cancel_nodata   CONSTANT VARCHAR2(1)   := '2';               -- ���������f�[�^����
    cv_ship                CONSTANT VARCHAR2(1)   := '1';               -- �o��
    cv_supply              CONSTANT VARCHAR2(1)   := '2';               -- �x��
    cv_move                CONSTANT VARCHAR2(1)   := '3';               -- �ړ�
    cv_ship_req            CONSTANT VARCHAR2(1)   := '1';               -- �o�׈˗�
    cv_supply_req          CONSTANT VARCHAR2(1)   := '2';               -- �x���˗�
    cv_cate_order          CONSTANT VARCHAR2(10)  := 'ORDER';           -- ��
    cv_cate_return         CONSTANT VARCHAR2(10)  := 'RETURN';          -- �ԕi
    cv_auto_enc            CONSTANT VARCHAR2(2)   := '10';              -- ��������
    cv_ship_req_type       CONSTANT VARCHAR2(2)   := '10';              -- �o�׈˗�
    cv_supply_instr_type   CONSTANT VARCHAR2(2)   := '30';              -- �x���w��
    cv_move_type           CONSTANT VARCHAR2(2)   := '20';              -- �ړ�
    cv_instr_rec_type      CONSTANT VARCHAR2(2)   := '10';              -- �w��
    cv_app_name_xxcmn      CONSTANT VARCHAR2(5)   := 'XXCMN';           -- �A�v���P�[�V�����Z�k��
    cv_app_name_xxwsh      CONSTANT VARCHAR2(5)   := 'XXWSH';           -- �A�v���P�[�V�����Z�k��
    cv_msg_para_err        CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10001'; -- �p�����[�^�w��s��
    cv_msg_object_nodata   CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10002'; -- �Ώۃf�[�^����
    cv_msg_xmld_del_err    CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10003'; -- �ړ����b�g�ڍ׍폜���s
    cv_msg_xola_update_err CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10004'; -- �󒍖��׃A�h�I���X�V���s
    cv_msg_supply_chk_warn CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10111'; -- �������̌����`�F�b�N�x��
    cv_msg_mril_update_err CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10005'; -- �ړ��˗�/�w�����׍X�V���s
    cv_msg_lock_err        CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10006'; -- ���b�N�����G���[
--
    -- *** ���[�J���ϐ� ***
    ln_can_enc_qty                NUMBER;           -- �����\��
    ln_user_id                    NUMBER;           -- ���O�C�����Ă��郆�[�U�[��ID�擾
    ln_login_id                   NUMBER;           -- �ŏI�X�V���O�C��
    ln_conc_request_id            NUMBER;           -- �v��ID
    ln_prog_appl_id               NUMBER;           -- �v���O�����E�A�v���P�[�V����ID
    ln_conc_program_id            NUMBER;           -- �v���O����ID
    ld_sysdate                    DATE;             -- �V�X�e�����ݓ��t
    TYPE dummy_tble IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    ln_dummy                      dummy_tble;       -- ���b�N�p�_�~�[�ϐ�
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    lock_expt                  EXCEPTION;  -- ���b�N�擾��O
--
    PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ���b�N�擾��O
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    -- ���̓p�����[�^�`�F�b�N
    IF ((iv_biz_type  IS NULL) OR
       (iv_request_no IS NULL)) THEN
         -- �p�����[�^�w��s��
         ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_para_err);
         RETURN cv_enc_cancel_err;                        -- �����������s
    END IF;
--
    -- WHO�J�������擾
    ln_user_id           := FND_GLOBAL.USER_ID;           -- ���O�C�����Ă��郆�[�U�[��ID�擾
    ln_login_id          := FND_GLOBAL.LOGIN_ID;          -- �ŏI�X�V���O�C��
    ln_conc_request_id   := FND_GLOBAL.CONC_REQUEST_ID;   -- �v��ID
    ln_prog_appl_id      := FND_GLOBAL.PROG_APPL_ID;      -- �v���O�����E�A�v���P�[�V����ID
    ln_conc_program_id   := FND_GLOBAL.CONC_PROGRAM_ID;   -- �v���O����ID
    ld_sysdate           := SYSDATE;                      -- �V�X�e�����ݓ��t
--
    -- �Z�[�u�|�C���g���擾���܂�
    SAVEPOINT advance_sp;
--
    -- **************************************************
    -- *** �Ɩ���ʂ��o�ׂ̏ꍇ
    -- **************************************************
    IF (iv_biz_type = cv_ship) THEN
      -- �����������s���܂�
      SELECT xola.order_line_id                             -- �󒍖��׃A�h�I��ID
      BULK COLLECT INTO
             gt_order_line_id_tbl
      FROM   xxwsh_order_headers_all            xoha,       -- �󒍃w�b�_�A�h�I��
             xxwsh_order_lines_all              xola,       -- �󒍖��׃A�h�I��
             xxwsh_oe_transaction_types_v       xott        -- �󒍃^�C�v���VIEW
      WHERE  xoha.request_no                            =  iv_request_no
      AND    xoha.order_type_id                         =  xott.transaction_type_id
      AND    xott.shipping_shikyu_class                 =  cv_ship_req
      AND    xott.order_category_code                   =  cv_cate_order
      AND    NVL(xoha.latest_external_flag, cv_flag_no) =  cv_flag_yes
      AND    xoha.order_header_id                       =  xola.order_header_id
      AND    NVL(xola.delete_flag, cv_flag_no)          =  cv_flag_no
      AND    xola.order_line_id                         =  NVL(in_line_id, xola.order_line_id)
      AND    xola.automanual_reserve_class              =  cv_auto_enc
      FOR UPDATE OF xola.order_line_id NOWAIT;
--
      -- �擾�ł��Ȃ��ꍇ�̓G���[
      IF (gt_order_line_id_tbl.COUNT = 0) THEN
        -- �Ώۃf�[�^����
        ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_object_nodata);
        RETURN cv_enc_cancel_nodata;                    -- ���������f�[�^����
      END IF;
--
      <<gt_order_line_id_tbl_loop>>
      FOR i IN gt_order_line_id_tbl.FIRST .. gt_order_line_id_tbl.LAST LOOP
        BEGIN
          -- ���b�N�������s���܂�
          SELECT xmld.mov_lot_dtl_id
          BULK COLLECT INTO ln_dummy
          FROM   xxinv_mov_lot_details          xmld        -- �ړ����b�g�ڍ�(�A�h�I��)
          WHERE  xmld.mov_line_id               =  gt_order_line_id_tbl(i)
          AND    xmld.document_type_code        =  cv_ship_req_type
          AND    xmld.record_type_code          =  cv_instr_rec_type
          FOR UPDATE OF xmld.mov_lot_dtl_id NOWAIT;
--
          -- �폜�������s���܂�
          DELETE
          FROM   xxinv_mov_lot_details          xmld        -- �ړ����b�g�ڍ�(�A�h�I��)
          WHERE  xmld.mov_line_id               =  gt_order_line_id_tbl(i)
          AND    xmld.document_type_code        =  cv_ship_req_type
          AND    xmld.record_type_code          =  cv_instr_rec_type;
--
        EXCEPTION
          WHEN lock_expt THEN
            -- ���b�N�����G���[
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_lock_err);
            ROLLBACK TO advance_sp;                   -- �G���[�̏ꍇ�̓Z�[�u�|�C���g�Ƀ��[���o�b�N
            RETURN cv_enc_cancel_err;                 -- �����������s
--
          WHEN OTHERS THEN
            -- �ړ����b�g�ڍ�(�A�h�I��)�폜���s
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_xmld_del_err);
            ROLLBACK TO advance_sp;                   -- �G���[�̏ꍇ�̓Z�[�u�|�C���g�Ƀ��[���o�b�N
            RETURN cv_enc_cancel_err;                 -- �����������s
--
        END;
--
        BEGIN
          -- �X�V�������s���܂�
          UPDATE xxwsh_order_lines_all              xola        -- �󒍖��׃A�h�I��
          SET    xola.reserved_quantity             =  NULL,    -- ������
                 xola.automanual_reserve_class      =  NULL,    -- �����蓮�����敪
                 xola.last_updated_by               =  ln_user_id,
                 xola.last_update_date              =  ld_sysdate,
                 xola.last_update_login             =  ln_login_id,
                 xola.request_id                    =  ln_conc_request_id,
                 xola.program_application_id        =  ln_prog_appl_id,
                 xola.program_id                    =  ln_conc_program_id,
                 xola.program_update_date           =  ld_sysdate
          WHERE  xola.order_line_id                 =  gt_order_line_id_tbl(i)
          AND    NVL(xola.delete_flag, cv_flag_no)  =  cv_flag_no;
--
        EXCEPTION
          -- �G���[�̏ꍇ�̓Z�[�u�|�C���g�Ƀ��[���o�b�N
          WHEN OTHERS THEN
            -- �󒍖��׃A�h�I���X�V���s
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_xola_update_err);
            ROLLBACK TO advance_sp;
            RETURN cv_enc_cancel_err;                       -- �����������s
--
        END;
--
      END LOOP gt_order_line_id_tbl_loop;
--
      -- ����I���̏ꍇ
      RETURN cv_compl;
--
    -- **************************************************
    -- *** �Ɩ���ʂ��x���̏ꍇ
    -- **************************************************
    ELSIF (iv_biz_type = cv_supply) THEN
      -- �����������s���܂�
      SELECT xola.order_line_id                             -- �󒍖��׃A�h�I��ID
      BULK COLLECT INTO
             gt_order_line_id_tbl
      FROM   xxwsh_order_headers_all            xoha,       -- �󒍃w�b�_�A�h�I��
             xxwsh_order_lines_all              xola,       -- �󒍖��׃A�h�I��
             xxwsh_oe_transaction_types_v       xott        -- �󒍃^�C�v���VIEW
      WHERE  xoha.request_no                            =  iv_request_no
      AND    xoha.order_type_id                         =  xott.transaction_type_id
      AND    xott.shipping_shikyu_class                 =  cv_supply_req
      AND    xott.order_category_code                   =  cv_cate_order
      AND    NVL(xoha.latest_external_flag, cv_flag_no) =  cv_flag_yes
      AND    xoha.order_header_id                       =  xola.order_header_id
      AND    NVL(xola.delete_flag, cv_flag_no)          =  cv_flag_no
      AND    xola.order_line_id                         =  NVL(in_line_id, xola.order_line_id)
      AND    xola.automanual_reserve_class              =  cv_auto_enc
      FOR UPDATE OF xola.order_line_id NOWAIT;
--
      -- �擾�ł��Ȃ��ꍇ�̓G���[
      IF (gt_order_line_id_tbl.COUNT = 0) THEN
        -- �Ώۃf�[�^����
        ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_object_nodata);
        RETURN cv_enc_cancel_nodata;                    -- ���������f�[�^����
      END IF;
--
      <<gt_order_line_id_tbl_loop>>
      FOR i IN gt_order_line_id_tbl.FIRST .. gt_order_line_id_tbl.LAST LOOP
        BEGIN
          -- ���b�N�������s���܂�
          SELECT xmld.mov_lot_dtl_id
          BULK COLLECT INTO ln_dummy
          FROM   xxinv_mov_lot_details          xmld              -- �ړ����b�g�ڍ�(�A�h�I��)
          WHERE  xmld.mov_line_id               =  gt_order_line_id_tbl(i)
          AND    xmld.document_type_code        =  cv_supply_instr_type
          AND    xmld.record_type_code          =  cv_instr_rec_type
          FOR UPDATE OF xmld.mov_lot_dtl_id NOWAIT;
--
          -- �폜�������s���܂�
          DELETE
          FROM   xxinv_mov_lot_details          xmld              -- �ړ����b�g�ڍ�(�A�h�I��)
          WHERE  xmld.mov_line_id               =  gt_order_line_id_tbl(i)
          AND    xmld.document_type_code        =  cv_supply_instr_type
          AND    xmld.record_type_code          =  cv_instr_rec_type;
--
        EXCEPTION
          WHEN lock_expt THEN
            -- ���b�N�����G���[
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_lock_err);
            ROLLBACK TO advance_sp;                   -- �G���[�̏ꍇ�̓Z�[�u�|�C���g�Ƀ��[���o�b�N
            RETURN cv_enc_cancel_err;                 -- �����������s
--
          WHEN OTHERS THEN
            -- �ړ����b�g�ڍ�(�A�h�I��)�폜���s
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_xmld_del_err);
            ROLLBACK TO advance_sp;                   -- �G���[�̏ꍇ�̓Z�[�u�|�C���g�Ƀ��[���o�b�N
            RETURN cv_enc_cancel_err;                 -- �����������s
--
        END;
--
        BEGIN
          -- �X�V�������s���܂�
          UPDATE xxwsh_order_lines_all              xola              -- �󒍖��׃A�h�I��
          SET    xola.reserved_quantity             =  NULL,          -- ������
                 xola.automanual_reserve_class      =  NULL,          -- �����蓮�����敪
                 xola.last_updated_by               =  ln_user_id,
                 xola.last_update_date              =  ld_sysdate,
                 xola.last_update_login             =  ln_login_id,
                 xola.request_id                    =  ln_conc_request_id,
                 xola.program_application_id        =  ln_prog_appl_id,
                 xola.program_id                    =  ln_conc_program_id,
                 xola.program_update_date           =  ld_sysdate
          WHERE  xola.order_line_id                 =  gt_order_line_id_tbl(i)
          AND    NVL(xola.delete_flag, cv_flag_no)  =  cv_flag_no;
--
        EXCEPTION
          -- �G���[�̏ꍇ�̓Z�[�u�|�C���g�Ƀ��[���o�b�N
          WHEN OTHERS THEN
            -- �󒍖��׃A�h�I���X�V���s
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_xola_update_err);
            ROLLBACK TO advance_sp;
            RETURN cv_enc_cancel_err;                             -- �����������s
--
        END;
--
      END LOOP gt_order_line_id_tbl_loop;
--
      -- ����I���̏ꍇ
      RETURN cv_compl;
--
    -- **************************************************
    -- *** �Ɩ���ʂ��ړ��̏ꍇ
    -- **************************************************
    ELSIF (iv_biz_type = cv_move) THEN
      -- �����������s���܂�
      SELECT mril.mov_line_id,                                  -- �ړ�����ID
             mrih.ship_to_locat_id,                             -- ���ɐ�ID
             mrih.schedule_arrival_date,                        -- ���ɗ\���
             xim2.item_short_name,                              -- �i���E����
             xilv.description                                   -- �ۊǏꏊ��
      BULK COLLECT INTO
             gt_mov_req_instr_tbl
      FROM   xxinv_mov_req_instr_headers      mrih,             -- �ړ��˗�/�w���w�b�_(�A�h�I��)
             xxinv_mov_req_instr_lines        mril,             -- �ړ��˗�/�w������(�A�h�I��)
             xxcmn_item_mst2_v                xim2,             -- OPM�i�ڏ��VIEW2
             xxcmn_item_locations_v           xilv              -- OPM�ۊǏꏊ���VIEW
      WHERE  mrih.mov_num                     =  iv_request_no
      AND    mrih.mov_hdr_id                  =  mril.mov_hdr_id
      AND    NVL(mril.delete_flg, cv_flag_no) =  cv_flag_no
      AND    mril.mov_line_id                 =  NVL(in_line_id, mril.mov_line_id)
      AND    mril.automanual_reserve_class    =  cv_auto_enc
      AND    mril.item_id                     =  xim2.item_id
      AND    xim2.start_date_active           <= mrih.schedule_ship_date
      AND    mrih.schedule_ship_date          <= NVL(xim2.end_date_active, mrih.schedule_ship_date)
      AND    mrih.shipped_locat_id            =  xilv.inventory_location_id
      FOR UPDATE OF mril.mov_line_id NOWAIT;
--
      -- �擾�ł��Ȃ��ꍇ�̓G���[
      IF (gt_mov_req_instr_tbl.COUNT = 0) THEN
        -- �Ώۃf�[�^����
        ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_object_nodata);
        RETURN cv_enc_cancel_nodata;                    -- ���������f�[�^����
      END IF;
--
      <<gt_mov_req_instr_tbl_loop>>
      FOR i IN gt_mov_req_instr_tbl.FIRST .. gt_mov_req_instr_tbl.LAST LOOP
        gt_mov_line_id_tbl(i)           := gt_mov_req_instr_tbl(i).mov_line_id;
        gt_ship_to_locat_id_tbl(i)      := gt_mov_req_instr_tbl(i).ship_to_locat_id;
        gt_schedule_arrival_date_tbl(i) := gt_mov_req_instr_tbl(i).schedule_arrival_date;
        gt_item_short_name_tbl(i)       := gt_mov_req_instr_tbl(i).item_short_name;
        gt_description_tbl(i)           := gt_mov_req_instr_tbl(i).description;
--
        BEGIN
          -- �����������s���܂�
          SELECT xmld.mov_lot_dtl_id,                             -- ���b�g�ڍ�ID
                  xmld.lot_id,                                     -- ���b�gID
                  xmld.item_id,                                    -- OPM�i��ID
                  xmld.actual_quantity,                            -- ���ѐ���
                  xmld.lot_no                                      -- ���b�gNo
          BULK COLLECT INTO gt_mov_lot_dtl_id_tbl,
                  gt_lot_id_tbl,
                  gt_item_id_tbl,
                  gt_actual_quantity_tbl,
                  gt_lot_no_tbl
          FROM   xxinv_mov_lot_details          xmld              -- �ړ����b�g�ڍ�(�A�h�I��)
          WHERE  xmld.mov_line_id               =  gt_mov_line_id_tbl(i)
          AND    xmld.document_type_code        =  cv_move_type
          AND    xmld.record_type_code          =  cv_instr_rec_type
          FOR UPDATE OF xmld.mov_lot_dtl_id NOWAIT;
--
          <<gt_mov_lot_dtl_id_tbl_loop>>
          FOR j IN gt_mov_lot_dtl_id_tbl.FIRST .. gt_mov_lot_dtl_id_tbl.LAST LOOP
            -- ���ʊ֐�(�����\���Z�oAPI)�̌Ăяo��
            ln_can_enc_qty := xxcmn_common_pkg.get_can_enc_qty(gt_ship_to_locat_id_tbl(j),
                                                               gt_item_id_tbl(j),
                                                               gt_lot_id_tbl(j),
                                                               gt_schedule_arrival_date_tbl(j));
--
            IF ((ln_can_enc_qty - gt_actual_quantity_tbl(i)) < 0) THEN
              -- �������̌����`�F�b�N���[�j���O
              ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,
                                                    cv_msg_supply_chk_warn,
                                                    'LOCATION',
                                                    gt_description_tbl(i),
                                                    'ITEM',
                                                    gt_item_short_name_tbl(i),
                                                    'LOT',
                                                    gt_lot_no_tbl(i));
              ROLLBACK TO advance_sp;
              RETURN cv_enc_cancel_err;                             -- ���������f�[�^����
            END IF;
--
            -- �폜�������s���܂�
            DELETE
            FROM   xxinv_mov_lot_details          xmld              -- �ړ����b�g�ڍ�(�A�h�I��)
            WHERE  xmld.mov_lot_dtl_id            =  gt_mov_lot_dtl_id_tbl(j);
--
          END LOOP gt_mov_lot_dtl_id_tbl_loop;
--
        EXCEPTION
          WHEN lock_expt THEN
            -- ���b�N�����G���[
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_lock_err);
            ROLLBACK TO advance_sp;                 -- �G���[�̏ꍇ�̓Z�[�u�|�C���g�Ƀ��[���o�b�N
            RETURN cv_enc_cancel_err;                 -- �����������s
--
            WHEN OTHERS THEN
              -- �ړ����b�g�ڍ�(�A�h�I��)�폜���s
              ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_xmld_del_err);
              ROLLBACK TO advance_sp;                 -- �G���[�̏ꍇ�̓Z�[�u�|�C���g�Ƀ��[���o�b�N
              RETURN cv_enc_cancel_err;                 -- �����������s
--
        END;
--
        BEGIN
          -- �X�V�������s���܂�
          UPDATE xxinv_mov_req_instr_lines      mril              -- �ړ��˗�/�w������(�A�h�I��)
          SET    mril.reserved_quantity         =  NULL,          -- ������
                 mril.automanual_reserve_class  =  NULL,          -- �����蓮�����敪
                 mril.last_updated_by           =  ln_user_id,
                 mril.last_update_date          =  ld_sysdate,
                 mril.last_update_login         =  ln_login_id,
                 mril.request_id                =  ln_conc_request_id,
                 mril.program_application_id    =  ln_prog_appl_id,
                 mril.program_id                =  ln_conc_program_id,
                 mril.program_update_date       =  ld_sysdate
          WHERE  mril.mov_line_id               =  gt_mov_line_id_tbl(i);
--
        EXCEPTION
          -- �G���[�̏ꍇ�̓Z�[�u�|�C���g�Ƀ��[���o�b�N
          WHEN OTHERS THEN
            -- �ړ��˗�/�w������(�A�h�I��)�X�V���s
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_mril_update_err);
            ROLLBACK TO advance_sp;
            RETURN cv_enc_cancel_err;                             -- �����������s
--
        END;
--
      END LOOP gt_mov_req_instr_tbl_loop;
--
      -- ����I���̏ꍇ
      RETURN cv_compl;
--
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN
      -- ���b�N�����G���[
      ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_lock_err);
      ROLLBACK TO advance_sp;
      RETURN cv_enc_cancel_err;                             -- �����������s
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END cancel_reserve;
--
  /**********************************************************************************
   * Function Name    : 
   
   * Description      : �z�ԉ����֐�
   ***********************************************************************************/
  FUNCTION cancel_careers_schedule(
    iv_biz_type             IN         VARCHAR2,                              -- 1.�Ɩ����
    iv_request_no           IN         VARCHAR2,                              -- 2.�˗�No/�ړ��ԍ�
    ov_errmsg               OUT NOCOPY VARCHAR2)                              -- 3.�G���[���b�Z�[�W
    RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'cancel_careers_schedule';  -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_career_cancel_err   CONSTANT VARCHAR2(2)   := '-1';               -- �z�ԉ������s
    cv_compl               CONSTANT VARCHAR2(1)   := '0';                -- ����
    cv_para_check_err      CONSTANT VARCHAR2(1)   := '1';                -- �p�����[�^�`�F�b�N�G���[
    cv_flag_yes            CONSTANT VARCHAR2(1)   := 'Y';                -- YES
    cv_flag_no             CONSTANT VARCHAR2(1)   := 'N';                -- NO
    cv_new                 CONSTANT VARCHAR2(1)   := 'N';                -- �V�K
    cv_amend               CONSTANT VARCHAR2(1)   := 'M';                -- �C��
    cv_ship                CONSTANT VARCHAR2(1)   := '1';                -- �o��
    cv_supply              CONSTANT VARCHAR2(1)   := '2';                -- �x��
    cv_move                CONSTANT VARCHAR2(1)   := '3';                -- �ړ�
    cv_ship_req            CONSTANT VARCHAR2(1)   := '1';                -- �o�׈˗�
    cv_supply_req          CONSTANT VARCHAR2(1)   := '2';                -- �x���˗�
    cv_cate_order          CONSTANT VARCHAR2(10)  := 'ORDER';            -- ��
    cv_app_name_xxwsh      CONSTANT VARCHAR2(5)   := 'XXWSH';            -- �A�v���P�[�V�����Z�k��
    cv_tkn_request_no      CONSTANT VARCHAR2(10)  := 'REQUEST_NO';       -- �g�[�N����
    cv_msg_para_err        CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10001';  -- �p�����[�^�w��s��
    cv_msg_lock_err        CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10006';  -- ���b�N�����G���[
    cv_msg_del_req_instr   CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10007';  -- �˗�/�w�������G���[
    cv_msg_up_req_instr    CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10008';  -- �˗�/�w���X�V�G���[
    cv_msg_ship_err        CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10009';  -- �o�׈˗��G���[
    cv_msg_supply_err      CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10010';  -- �x���˗��G���[
    cv_msg_move_err        CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10011';  -- �ړ��w���G���[
    cv_msg_new_modify_err  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10019';  -- �V�K�C���敪�G���[
-- Ver1.20 M.Hokkanji START
    cv_msg_ship_max_err    CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10020';  -- �o�׈˗��G���[(���ʊ֐�)
    cv_msg_supply_max_err  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10021';  -- �x���˗��G���[(���ʊ֐�)
    cv_msg_move_max_err    CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10022';  -- �ړ��w���G���[(���ʊ֐�)
    cv_tkn_program         CONSTANT VARCHAR2(15)  := 'PROGRAM';          -- �g�[�N����
-- Ver1.20 M.Hokkanji END
    cv_tightening          CONSTANT VARCHAR2(2)   := '03';               -- ���ߍς�
    cv_adjustment          CONSTANT VARCHAR2(2)   := '03';               -- ������
    cv_received            CONSTANT VARCHAR2(2)   := '07';               -- ��̍ς�
    cv_deci_noti           CONSTANT VARCHAR2(3)   := '40';               -- �m��ʒm��
    cv_not_noti            CONSTANT VARCHAR2(3)   := '10';               -- ���ʒm
    cv_re_noti             CONSTANT VARCHAR2(3)   := '20';               -- �Ēʒm�v
    cv_msg_com             CONSTANT VARCHAR2(1)   := ',';                -- �J���}
    --
    cv_tkn_biz_type        CONSTANT VARCHAR2(30)  := 'BIZ_TYPE';         -- �������
    cv_tkn_ship_char       CONSTANT VARCHAR2(30)  := '�o�׈˗�No';       -- �o�׈˗�No
    cv_tkn_supl_char       CONSTANT VARCHAR2(30)  := '�x���˗�No';       -- �x���˗�No
    cv_tkn_move_char       CONSTANT VARCHAR2(30)  := '�ړ��ԍ�';         -- �ړ��ԍ�
-- Ver1.20 M.Hokkanji START
    cv_code_kbn_mov        CONSTANT VARCHAR2(1)   := '4';                -- �ړ�
    cv_code_kbn_ship       CONSTANT VARCHAR2(1)   := '9';                -- �o��
    cv_code_kbn_supply     CONSTANT VARCHAR2(2)   := '11';               -- �x��
    cv_prod_class_1        CONSTANT VARCHAR2(1)   := '1';                -- ���i�敪�F1
    cv_prod_class_2        CONSTANT VARCHAR2(1)   := '2';                -- ���i�敪�F2
    cv_tkn_max_char        CONSTANT VARCHAR2(30)  := '�ő�z���敪�̎擾';     -- �g�[�N���u�ő�z���敪�v
    cv_tkn_small_char      CONSTANT VARCHAR2(30)  := '�����敪�̎擾';         -- �g�[�N���u�����敪�v
    cv_tkn_weight_char     CONSTANT VARCHAR2(30)  := '�ύڌ���(�d��)�̎擾';   -- �g�[�N���u�ύڌ���(�d��)�v
    cv_tkn_cap_char        CONSTANT VARCHAR2(30)  := '�ύڌ���(�e��)�̎擾';   -- �g�[�N���u�ύڌ���(�e��)�v
    cv_include             CONSTANT VARCHAR2(1)   := '1';                -- �����敪(�Ώ�)
-- Ver1.20 M.Hokkanji END
--
    cv_tkn_req_mov_no      CONSTANT VARCHAR2(30)  := 'REQ_MOV';          -- �˗�No/�ړ��ԍ�
--
    -- *** ���[�J���ϐ� ***
    lv_status               VARCHAR2(2);              -- �X�e�[�^�X
    lv_delivery_no          VARCHAR2(12);             -- �z��No
    ln_shipped_quantity     NUMBER;                   -- �o�׎��ѐ���
    ln_ship_to_quantity     NUMBER;                   -- ���Ɏ��ѐ���
    ln_no_count             NUMBER;                   -- �z�ԉ����s�J�E���g
    ln_data_count           NUMBER;                   -- �f�[�^���݃J�E���g
    lv_msg_ship_err         VARCHAR2(500);            -- ���[�U�[�G���[���b�Z�[�W(�o��)
    lv_msg_supply_err       VARCHAR2(500);            -- ���[�U�[�G���[���b�Z�[�W(�x��)
    lv_msg_move_err         VARCHAR2(500);            -- ���[�U�[�G���[���b�Z�[�W(�ړ�)
-- Ver1.20 M.Hokkanji START
    lv_msg_ship_max_err     VARCHAR2(500);            -- ���[�U�[�G���[���b�Z�[�W(�o��)(�ő�z���敪)
    lv_msg_supply_max_err   VARCHAR2(500);            -- ���[�U�[�G���[���b�Z�[�W(�x��)(�ő�z���敪)
    lv_msg_move_max_err     VARCHAR2(500);            -- ���[�U�[�G���[���b�Z�[�W(�ړ�)(�ő�z���敪)
    lv_msg_ship_small_err   VARCHAR2(500);            -- ���[�U�[�G���[���b�Z�[�W(�o��)(�����敪)
    lv_msg_move_small_err   VARCHAR2(500);            -- ���[�U�[�G���[���b�Z�[�W(�ړ�)(�����敪)
    lv_msg_ship_wei_err     VARCHAR2(500);            -- ���[�U�[�G���[���b�Z�[�W(�o��)(�ύڌ���(�d��))
    lv_msg_supply_wei_err   VARCHAR2(500);            -- ���[�U�[�G���[���b�Z�[�W(�x��)(�ύڌ���(�d��))
    lv_msg_move_wei_err     VARCHAR2(500);            -- ���[�U�[�G���[���b�Z�[�W(�ړ�)(�ύڌ���(�d��))
    lv_msg_ship_cap_err     VARCHAR2(500);            -- ���[�U�[�G���[���b�Z�[�W(�o��)(�ύڌ���(�e��))
    lv_msg_supply_cap_err   VARCHAR2(500);            -- ���[�U�[�G���[���b�Z�[�W(�x��)(�ύڌ���(�e��))
    lv_msg_move_cap_err     VARCHAR2(500);            -- ���[�U�[�G���[���b�Z�[�W(�ړ�)(�ύڌ���(�e��))
    lv_err_chek             VARCHAR2(1);              -- �G���[�p���`�F�b�N�p�̃t���O
-- Ver1.20 M.Hokkanji END
    ln_user_id              NUMBER;                   -- ���O�C�����Ă��郆�[�U�[��ID�擾
    ln_login_id             NUMBER;                   -- �ŏI�X�V���O�C��
    ln_conc_request_id      NUMBER;                   -- �v��ID
    ln_prog_appl_id         NUMBER;                   -- �v���O�����E�A�v���P�[�V����ID
    ln_conc_program_id      NUMBER;                   -- �v���O����ID
    ld_sysdate              DATE;                     -- �V�X�e�����ݓ��t
    ln_dummy                NUMBER;                   -- ���b�N�p�_�~�[�ϐ�
    --
    lv_new_modify_flg       VARCHAR2(1);              -- �V�K�C���t���O
-- Ver1.20 M.Hokkanji START
    lt_max_ship_methods             xxcmn_ship_methods.ship_method%TYPE;            -- �ő�z���敪
    lt_drink_deadweight             xxcmn_ship_methods.drink_deadweight%TYPE;       -- �h�����N�ύڏd��
    lt_leaf_deadweight              xxcmn_ship_methods.leaf_deadweight%TYPE;        -- ���[�t�ύڏd��
    lt_drink_loading_capacity       xxcmn_ship_methods.drink_loading_capacity%TYPE; -- �h�����N�ύڗe��
    lt_leaf_loading_capacity        xxcmn_ship_methods.leaf_loading_capacity%TYPE;  -- ���[�t�ύڗe��
    lt_palette_max_qty              xxcmn_ship_methods.palette_max_qty%TYPE;        -- �p���b�g�ő喇��
    ln_ret_code                     NUMBER;                                         -- ���^�[���R�[�h
    -- �����敪�擾�p�ϐ�
    lv_small_sum_class              VARCHAR2(1);                                    -- �����敪
    -- ���ʊ֐���ύڌ����`�F�b�N�OUT�p�����[�^
    lv_retcode                      VARCHAR2(1);                                    -- ���^�[���R�[�h
    lv_errmsg_code                  VARCHAR2(100);                                  -- �G���[���b�Z�[�W�R�[�h
    lv_errmsg                       VARCHAR2(100);                                  -- �G���[���b�Z�[�W
    lv_loading_over_class           VARCHAR2(100);                                  -- �ύڃI�[�o�[�敪
    lv_ship_methods                 VARCHAR2(100);                                  -- �o�ו��@
    ln_load_efficiency_weight       NUMBER;                                         -- �d�ʐύڌ���
    ln_load_efficiency_capacity     NUMBER;                                         -- �e�ϐύڌ���
    lv_mixed_ship_method            VARCHAR2(100);                                  -- ���ڔz���敪
    ln_sum_weight                   NUMBER;                                         -- ���v�d��
    ln_sum_capacity                 NUMBER;                                         -- ���v�e��
-- Ver1.20 M.Hokkanji END
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    lock_expt                  EXCEPTION;  -- ���b�N�擾��O
--
    PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ���b�N�擾��O
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    -- �J�E���g�ϐ�������
    ln_no_count   := 0;
    ln_data_count := 0;
--
    -- WHO�J�������擾
    ln_user_id           := FND_GLOBAL.USER_ID;           -- ���O�C�����Ă��郆�[�U�[��ID�擾
    ln_login_id          := FND_GLOBAL.LOGIN_ID;          -- �ŏI�X�V���O�C��
    ln_conc_request_id   := FND_GLOBAL.CONC_REQUEST_ID;   -- �v��ID
    ln_prog_appl_id      := FND_GLOBAL.PROG_APPL_ID;      -- �v���O�����E�A�v���P�[�V����ID
    ln_conc_program_id   := FND_GLOBAL.CONC_PROGRAM_ID;   -- �v���O����ID
    ld_sysdate           := SYSDATE;                      -- �V�X�e�����ݓ��t
--
    -- **************************************************
    -- *** 0.�p�����[�^�`�F�b�N����
    -- **************************************************
    IF ((iv_biz_type  IS NULL) OR
       (iv_biz_type NOT IN (cv_ship, cv_supply, cv_move)) OR
       (iv_request_no IS NULL)) THEN
         -- �p�����[�^�w��s��
         ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_para_err);
         RETURN cv_para_check_err;                          -- �p�����[�^�`�F�b�N�G���[
    END IF;
--
    -- **************************************************
    -- *** 1.�z�ԍς݃`�F�b�N����
    -- **************************************************
    -- �o�׈˗��̃`�F�b�N
    -- �����������s���A���b�N���擾���܂��B
    IF (iv_biz_type = cv_ship) THEN
      SELECT xoha.req_status,                               -- �X�e�[�^�X
-- Ver1.20 M.Hokkanji Start
--             xoha.delivery_no                               -- �z��No
             NVL(xoha.delivery_no,xoha.mixed_no)              -- �z��No/���ڌ�No
-- Ver1.20 M.Hokkanji End
      INTO   lv_status,
             lv_delivery_no
      FROM   xxwsh_order_headers_all            xoha,       -- �󒍃w�b�_�A�h�I��
             xxwsh_oe_transaction_types2_v       xott        -- �󒍃^�C�v���VIEW
      WHERE  xoha.request_no                            =  iv_request_no
      AND    xoha.order_type_id                         =  xott.transaction_type_id
      AND    xott.shipping_shikyu_class                 =  cv_ship_req
      AND    xott.order_category_code                   =  cv_cate_order
      AND    xott.start_date_active                     <=  trunc( xoha.schedule_ship_date )
      AND    NVL(xott.end_date_active,to_date('99991231','YYYYMMDD')) 
                                                        >= trunc( xoha.schedule_ship_date )
      AND    NVL(xoha.latest_external_flag, cv_flag_no) =  cv_flag_yes
      FOR UPDATE NOWAIT;
--
    -- �x���˗��̃`�F�b�N
    -- �����������s���A���b�N���擾���܂��B
    ELSIF (iv_biz_type = cv_supply) THEN
      SELECT xoha.req_status,                               -- �X�e�[�^�X
             xoha.delivery_no                               -- �z��No
      INTO   lv_status,
             lv_delivery_no
      FROM   xxwsh_order_headers_all            xoha,       -- �󒍃w�b�_�A�h�I��
             xxwsh_oe_transaction_types2_v       xott        -- �󒍃^�C�v���VIEW
      WHERE  xoha.request_no                            =  iv_request_no
      AND    xoha.order_type_id                         =  xott.transaction_type_id
      AND    xott.shipping_shikyu_class                 =  cv_supply_req
      AND    xott.order_category_code                   =  cv_cate_order
      AND    xott.start_date_active                     <= trunc( xoha.schedule_ship_date )
      AND    NVL(xott.end_date_active,to_date('99991231','YYYYMMDD')) 
                                                        >= trunc( xoha.schedule_ship_date )
      AND    NVL(xoha.latest_external_flag, cv_flag_no) =  cv_flag_yes
      FOR UPDATE NOWAIT;
--
    -- �ړ��w���̃`�F�b�N
    -- �����������s���A���b�N���擾���܂��B
    ELSIF (iv_biz_type = cv_move) THEN
      SELECT mrih.status,                                   -- �X�e�[�^�X
             mrih.delivery_no                               -- �z��No
      INTO   lv_status,
             lv_delivery_no
      FROM   xxinv_mov_req_instr_headers        mrih        -- �ړ��˗�/�w���w�b�_(�A�h�I��)
      WHERE  mrih.mov_num                       =  iv_request_no
      FOR UPDATE NOWAIT;
--
    END IF;
--
    -- **************************************************
    -- *** 2.�z�ԉ����ۃ`�F�b�N(�o��)
    -- **************************************************
    SELECT xoha.order_header_id,                          -- �󒍃w�b�_�A�h�I��ID
           xoha.req_status,                               -- �X�e�[�^�X
           xoha.request_no,
           xoha.notif_status,
           xoha.prev_notif_status,
           xola.shipped_quantity,                         -- �o�׎��ѐ���
           xola.ship_to_quantity,                         -- ���Ɏ��ю��ѐ���
-- Ver1.20 M.Hokkanji START
           xoha.shipping_method_code,                     -- �z���敪
           xoha.prod_class,                               -- ���i�敪
           xoha.based_weight,                             -- ��{�d��
           xoha.based_capacity,                           -- ��{�e��
           xoha.weight_capacity_class,                    -- �d�ʗe�ϋ敪
           xoha.deliver_from,                             -- �o�׌�
           xoha.deliver_to,                               -- �z����
           xoha.schedule_ship_date,                       -- �o�ɗ\���
           xoha.sum_weight,                               -- �ύڏd�ʍ��v
           xoha.sum_capacity,                             -- �ύڗe�ύ��v
           xoha.sum_pallet_weight,                        -- ���v�p���b�g�d��
           xoha.freight_charge_class,                     -- �^���敪
           xoha.loading_efficiency_weight,                -- �ύڗ�(�d��)
           xoha.loading_efficiency_capacity               -- �ύڗ�(�e��)
-- Ver1.20 M.Hokkanji END
    BULK COLLECT INTO
           gt_chk_ship_tbl
    FROM   xxwsh_order_headers_all            xoha,       -- �󒍃w�b�_�A�h�I��
           xxwsh_order_lines_all              xola,       -- �󒍖��׃A�h�I��
           xxwsh_oe_transaction_types2_v       xott        -- �󒍃^�C�v���VIEW
    WHERE  (((iv_biz_type = cv_ship) AND (lv_delivery_no IS NULL) AND
             (xoha.request_no = iv_request_no))
    OR     (((iv_biz_type <> cv_ship) OR
           ((iv_biz_type = cv_ship) AND (lv_delivery_no IS NOT NULL))) AND
-- Ver1.20 M.Hokkanji START
             (NVL(xoha.delivery_no,xoha.mixed_no) = lv_delivery_no)))
--             (xoha.delivery_no = lv_delivery_no)))
-- Ver1.20 M.Hokkanji End
    AND    xoha.order_type_id                         =  xott.transaction_type_id
    AND    xoha.order_header_id                       =  xola.order_header_id
    AND    NVL(xola.delete_flag, cv_flag_no)          =  cv_flag_no
    AND    xott.shipping_shikyu_class                 =  cv_ship_req
    AND    xott.order_category_code                   =  cv_cate_order
    AND    xott.start_date_active                     <= trunc( xoha.schedule_ship_date )
    AND    NVL(xott.end_date_active,to_date('99991231','YYYYMMDD')) 
                                                      >= trunc( xoha.schedule_ship_date )
    AND    NVL(xoha.latest_external_flag, cv_flag_no) =  cv_flag_yes
    ORDER BY xoha.order_header_id;
    IF (gt_chk_ship_tbl.COUNT > 0) THEN
      -- �f�[�^�����݂���ꍇ�̓J�E���g
      ln_data_count := ln_data_count + 1;
      -- �擾�������R�[�h�̕��������[�v
      <<gt_chk_ship_tbl_loop>>
      FOR i IN gt_chk_ship_tbl.FIRST .. gt_chk_ship_tbl.LAST LOOP
--
        -- �X�e�[�^�X������͒������_�m�裢���ߍςݣ�ŏo�׎��ѐ��ʂ�NULL�łȂ��f�[�^�͔z�ԉ����s��
        IF ((gt_chk_ship_tbl(i).req_status <= cv_tightening) AND
             (gt_chk_ship_tbl(i).shipped_quantity IS NOT NULL)) THEN
          ln_no_count := ln_no_count + 1;
-- Ver1.20 M.Hokkanji START
          IF (lv_msg_ship_err IS NULL) THEN
            lv_msg_ship_err := gt_chk_ship_tbl(i).request_no;
          ELSE
            lv_msg_ship_err := lv_msg_ship_err
                               || cv_msg_com
                               || gt_chk_ship_tbl(i).request_no;
-- Ver1.20 M.Hokkanji END
          END IF;
--
        -- �X�e�[�^�X����o�׎��ьv��ϣ������̃f�[�^�͔z�ԉ����s��
        ELSIF (gt_chk_ship_tbl(i).req_status > cv_tightening) THEN
          IF (lv_msg_ship_err IS NULL) THEN
-- Ver1.20 M.Hokkanji START
--            lv_msg_ship_err := iv_request_no;
            lv_msg_ship_err := gt_chk_ship_tbl(i).request_no;
-- Ver1.20 M.Hokkanji END
          ELSE
-- Ver1.20 M.Hokkanji START
            lv_msg_ship_err := lv_msg_ship_err
                               || cv_msg_com
                               || gt_chk_ship_tbl(i).request_no;
--                               || iv_request_no;
-- Ver1.20 M.Hokkanji END
          END IF;
          ln_no_count     := ln_no_count + 1;
--
-- Ver1.20 M.Hokkanji START
        ELSE
          -- �^���敪��1�̏ꍇ�̂ݎ擾�����z���敪�A��{�d�ʁA��{�e�ρA�ύڗ�(�d��)�A�ύڗ�(�e��)���X�V
          IF (gt_chk_ship_tbl(i).freight_charge_class = gv_freight_charge_yes) THEN
            lv_err_chek := '0'; -- �G���[�`�F�b�N�t���O�������l�ɖ߂�
            -- �ő�z���敪�擾
            ln_ret_code := get_max_ship_method(
                             iv_code_class1                => cv_code_kbn_mov,
                             iv_entering_despatching_code1 => gt_chk_ship_tbl(i).deliver_from,
                             iv_code_class2                => cv_code_kbn_ship,
                             iv_entering_despatching_code2 => gt_chk_ship_tbl(i).deliver_to,
                             iv_prod_class                 => gt_chk_ship_tbl(i).prod_class,
                             iv_weight_capacity_class      => gt_chk_ship_tbl(i).weight_capacity_class,
                             iv_auto_process_type          => NULL,
                             id_standard_date              => gt_chk_ship_tbl(i).schedule_ship_date,
                             ov_max_ship_methods           => lt_max_ship_methods,
                             on_drink_deadweight           => lt_drink_deadweight,
                             on_leaf_deadweight            => lt_leaf_deadweight,
                             on_drink_loading_capacity     => lt_drink_loading_capacity,
                             on_leaf_loading_capacity      => lt_leaf_loading_capacity,
                             on_palette_max_qty            => lt_palette_max_qty);
            IF (ln_ret_code <> gn_status_normal) THEN
              IF (lv_msg_ship_max_err IS NULL) THEN
                lv_msg_ship_max_err := gt_chk_ship_tbl(i).request_no;
              ELSE
                lv_msg_ship_max_err := lv_msg_ship_max_err
                                   || cv_msg_com
                                   || gt_chk_ship_tbl(i).request_no;
              END IF;
              ln_no_count     := ln_no_count + 1;
              lv_err_chek     := '1';
            ELSE
              -- ���i�敪���h�����N�̏ꍇ
              IF (gt_chk_ship_tbl(i).prod_class = cv_prod_class_2) THEN
                gt_chk_ship_tbl(i).based_weight       := lt_drink_deadweight;
                gt_chk_ship_tbl(i).based_capacity     := lt_drink_loading_capacity;
              ELSE
                gt_chk_ship_tbl(i).based_weight       := lt_drink_deadweight;
                gt_chk_ship_tbl(i).based_capacity     := lt_drink_loading_capacity;
              END IF;
              gt_chk_ship_tbl(i).shipping_method_code := lt_max_ship_methods;
            END IF;
--
            -- �ő�z���敪�̎擾�ɐ������Ă���ꍇ
            IF (lv_err_chek = '0') THEN
              BEGIN
--
                -- �擾�����z���敪�����ƂɃN�C�b�N�R�[�h�XXCMN_SHIP_METHOD����珬���敪���擾
                SELECT  xsm2.small_amount_class
                  INTO  lv_small_sum_class
                  FROM  xxwsh_ship_method2_v    xsm2
                 WHERE  xsm2.ship_method_code   =  gt_chk_ship_tbl(i).shipping_method_code
                   AND  xsm2.start_date_active  <= gt_chk_ship_tbl(i).schedule_ship_date
                   AND  gt_chk_ship_tbl(i).schedule_ship_date <= NVL(xsm2.end_date_active,
                                                                     gt_chk_ship_tbl(i).schedule_ship_date);
--
              EXCEPTION
                WHEN OTHERS THEN
                  IF (lv_msg_ship_small_err IS NULL) THEN
                    lv_msg_ship_small_err := gt_chk_ship_tbl(i).request_no;
                  ELSE
                    lv_msg_ship_small_err := lv_msg_ship_small_err
                                           || cv_msg_com
                                           || gt_chk_ship_tbl(i).request_no;
                  END IF;
                  ln_no_count     := ln_no_count + 1;
                  lv_err_chek     := '1';
              END;
            END IF;
--
            -- �ő�z���敪�A�����敪�̎擾�ɐ������Ă���ꍇ
            IF (lv_err_chek = '0') THEN
              IF (lv_small_sum_class = cv_include) THEN
                ln_sum_weight := gt_chk_ship_tbl(i).sum_weight;
              ELSE
                ln_sum_weight := gt_chk_ship_tbl(i).sum_weight + NVL(gt_chk_ship_tbl(i).sum_pallet_weight,0);
              END IF;
              --�ύڌ���(�d��)���擾
              xxwsh_common910_pkg.calc_load_efficiency(
                in_sum_weight                 => ln_sum_weight,                             -- 1.���v�d��
                in_sum_capacity               =>  NULL,                                     -- 2.���v�e��
                iv_code_class1                =>  cv_code_kbn_mov,                          -- 3.�R�[�h�敪�P
                iv_entering_despatching_code1 =>  gt_chk_ship_tbl(i).deliver_from,          -- 4.���o�ɏꏊ�R�[�h�P
                iv_code_class2                =>  cv_code_kbn_ship,                         -- 5.�R�[�h�敪�Q
                iv_entering_despatching_code2 =>  gt_chk_ship_tbl(i).deliver_to,            -- 6.���o�ɏꏊ�R�[�h�Q
                iv_ship_method                =>  gt_chk_ship_tbl(i).shipping_method_code,  -- 7.�o�ו��@
                iv_prod_class                 =>  gt_chk_ship_tbl(i).prod_class,            -- 8.���i�敪
                iv_auto_process_type          =>  NULL,                                     -- 9.�����z�ԑΏۋ敪
                id_standard_date              =>  gt_chk_ship_tbl(i).schedule_ship_date,    -- 10.���(�K�p�����)
                ov_retcode                    =>  lv_retcode,                               -- 11.���^�[���R�[�h
                ov_errmsg_code                =>  lv_errmsg_code,                           -- 12.�G���[���b�Z�[�W�R�[�h
                ov_errmsg                     =>  lv_errmsg,                                -- 13.�G���[���b�Z�[�W
                ov_loading_over_class         =>  lv_loading_over_class,                    -- 14.�ύڃI�[�o�[�敪
                ov_ship_methods               =>  lv_ship_methods,                          -- 15.�o�ו��@
                on_load_efficiency_weight     =>  ln_load_efficiency_weight,                -- 16.�d�ʐύڌ���
                on_load_efficiency_capacity   =>  ln_load_efficiency_capacity,              -- 17.�e�ϐύڌ���
                ov_mixed_ship_method          =>  lv_mixed_ship_method);                    -- 18.���ڔz���敪
--
              -- ���^�[���R�[�h��'1'(�ُ�)�̏ꍇ�̓G���[���Z�b�g
              IF (lv_retcode = gn_status_error) THEN
                IF (lv_msg_ship_wei_err IS NULL) THEN
                  lv_msg_ship_wei_err := gt_chk_ship_tbl(i).request_no;
                ELSE
                  lv_msg_ship_wei_err := lv_msg_ship_wei_err
                                           || cv_msg_com
                                           || gt_chk_ship_tbl(i).request_no;
                END IF;
                ln_no_count     := ln_no_count + 1;
                lv_err_chek     := '1';
              ELSE
                -- �ُ�ł͂Ȃ��ꍇ�ύڗ�(�d��)���Z�b�g
                gt_chk_ship_tbl(i).loading_efficiency_weight := ln_load_efficiency_weight;
--
              END IF;
              --�ύڌ���(�e��)���擾
              xxwsh_common910_pkg.calc_load_efficiency(
                in_sum_weight                 =>  NULL,                                     -- 1.���v�d��
                in_sum_capacity               =>  gt_chk_ship_tbl(i).sum_capacity,          -- 2.���v�e��
                iv_code_class1                =>  cv_code_kbn_mov,                          -- 3.�R�[�h�敪�P
                iv_entering_despatching_code1 =>  gt_chk_ship_tbl(i).deliver_from,          -- 4.���o�ɏꏊ�R�[�h�P
                iv_code_class2                =>  cv_code_kbn_ship,                         -- 5.�R�[�h�敪�Q
                iv_entering_despatching_code2 =>  gt_chk_ship_tbl(i).deliver_to,            -- 6.���o�ɏꏊ�R�[�h�Q
                iv_ship_method                =>  gt_chk_ship_tbl(i).shipping_method_code,  -- 7.�o�ו��@
                iv_prod_class                 =>  gt_chk_ship_tbl(i).prod_class,            -- 8.���i�敪
                iv_auto_process_type          =>  NULL,                                     -- 9.�����z�ԑΏۋ敪
                id_standard_date              =>  gt_chk_ship_tbl(i).schedule_ship_date,    -- 10.���(�K�p�����)
                ov_retcode                    =>  lv_retcode,                               -- 11.���^�[���R�[�h
                ov_errmsg_code                =>  lv_errmsg_code,                           -- 12.�G���[���b�Z�[�W�R�[�h
                ov_errmsg                     =>  lv_errmsg,                                -- 13.�G���[���b�Z�[�W
                ov_loading_over_class         =>  lv_loading_over_class,                    -- 14.�ύڃI�[�o�[�敪
                ov_ship_methods               =>  lv_ship_methods,                          -- 15.�o�ו��@
                on_load_efficiency_weight     =>  ln_load_efficiency_weight,                -- 16.�d�ʐύڌ���
                on_load_efficiency_capacity   =>  ln_load_efficiency_capacity,              -- 17.�e�ϐύڌ���
                ov_mixed_ship_method          =>  lv_mixed_ship_method);                    -- 18.���ڔz���敪
--
              -- ���^�[���R�[�h��'1'(�ُ�)�̏ꍇ�̓G���[���Z�b�g
              IF (lv_retcode = gn_status_error) THEN
                IF (lv_msg_ship_cap_err IS NULL) THEN
                  lv_msg_ship_cap_err := gt_chk_ship_tbl(i).request_no;
                ELSE
                  lv_msg_ship_cap_err := lv_msg_ship_cap_err
                                           || cv_msg_com
                                           || gt_chk_ship_tbl(i).request_no;
                END IF;
                ln_no_count     := ln_no_count + 1;
                lv_err_chek     := '1';
              ELSE
                -- �ُ�ł͂Ȃ��ꍇ�ύڗ�(�e��)���Z�b�g
                gt_chk_ship_tbl(i).loading_efficiency_capacity := ln_load_efficiency_capacity;
--
              END IF;
--
            END IF;
--
          END IF;
-- Ver1.20 M.Hokkanji END
        END IF;
--
      END LOOP gt_chk_ship_tbl_loop;
--
    END IF;
--
    -- **************************************************
    -- *** 3.�z�ԉ����ۃ`�F�b�N(�ړ�)
    -- **************************************************
    SELECT mrih.mov_hdr_id,                               -- �ړ��w�b�_ID
           mrih.status,                                   -- �X�e�[�^�X
           mrih.mov_num,
           mrih.notif_status,
           mrih.prev_notif_status,
-- 2008/08/28 H.Itou Mod Start PT 1-2_8 �w�E#32
--           mril.shipped_quantity,                         -- �o�Ɏ��ѐ���
           mrih.shipped_quantity,                         -- �o�Ɏ��ѐ���
--           mril.ship_to_quantity                          -- ���Ɏ��ѐ���
           mrih.ship_to_quantity,                         -- ���Ɏ��ѐ���
-- 2008/08/28 H.Itou Mod End
-- Ver1.20 M.Hokkanji START
           mrih.shipping_method_code,                     -- �z���敪
           mrih.item_class,                               -- ���i�敪
           mrih.based_weight,                             -- ��{�d��
           mrih.based_capacity,                           -- ��{�e��
           mrih.weight_capacity_class,                    -- �d�ʗe�ϋ敪
           mrih.shipped_locat_code,                       -- �o�Ɍ�
           mrih.ship_to_locat_code,                       -- ���ɐ�
           mrih.schedule_ship_date,                       -- �o�ɗ\���
           mrih.sum_weight,                               -- �ύڏd�ʍ��v
           mrih.sum_capacity,                             -- �ύڗe�ύ��v
           mrih.sum_pallet_weight,                        -- ���v�p���b�g�d��
           mrih.freight_charge_class,                     -- �^���敪
           mrih.loading_efficiency_weight,                -- �ύڗ�(�d��)
           mrih.loading_efficiency_capacity               -- �ύڗ�(�e��)
-- Ver1.20 M.Hokkanji END
    BULK COLLECT INTO
           gt_chk_move_tbl
-- 2008/08/28 H.Itou Mod Start PT 1-2_8 �w�E#32 OR�傪�����INDEX���g���Ȃ����߁AUNION ALL����B
--    FROM   xxinv_mov_req_instr_headers        mrih,       -- �ړ��˗�/�w���w�b�_(�A�h�I��)
--           xxinv_mov_req_instr_lines          mril        -- �ړ��˗�/�w������(�A�h�I��)
--    WHERE  (((iv_biz_type = cv_move) AND (lv_delivery_no IS NULL) AND
--             (mrih.mov_num = iv_request_no))
--    OR     (((iv_biz_type <> cv_move) OR
--           ((iv_biz_type = cv_move) AND (lv_delivery_no IS NOT NULL))) AND
--             (mrih.delivery_no = lv_delivery_no)))
--    AND    mrih.mov_hdr_id                    =  mril.mov_hdr_id
    FROM  (SELECT mrih1.mov_hdr_id                   mov_hdr_id                   -- �ړ��w�b�_ID
                 ,mrih1.status                       status                       -- �X�e�[�^�X
                 ,mrih1.mov_num                      mov_num                      -- �ړ��ԍ�
                 ,mrih1.notif_status                 notif_status                 -- �ʒm�X�e�[�^�X
                 ,mrih1.prev_notif_status            prev_notif_status            -- �O��ʒm�X�e�[�^�X
                 ,mril.shipped_quantity              shipped_quantity             -- �o�Ɏ��ѐ���
                 ,mril.ship_to_quantity              ship_to_quantity             -- ���Ɏ��ѐ���
                 ,mrih1.shipping_method_code         shipping_method_code         -- �z���敪
                 ,mrih1.item_class                   item_class                   -- ���i�敪
                 ,mrih1.based_weight                 based_weight                 -- ��{�d��
                 ,mrih1.based_capacity               based_capacity               -- ��{�e��
                 ,mrih1.weight_capacity_class        weight_capacity_class        -- �d�ʗe�ϋ敪
                 ,mrih1.shipped_locat_code           shipped_locat_code           -- �o�Ɍ�
                 ,mrih1.ship_to_locat_code           ship_to_locat_code           -- ���ɐ�
                 ,mrih1.schedule_ship_date           schedule_ship_date           -- �o�ɗ\���
                 ,mrih1.sum_weight                   sum_weight                   -- �ύڏd�ʍ��v
                 ,mrih1.sum_capacity                 sum_capacity                 -- �ύڗe�ύ��v
                 ,mrih1.sum_pallet_weight            sum_pallet_weight            -- ���v�p���b�g�d��
                 ,mrih1.freight_charge_class         freight_charge_class         -- �^���敪
                 ,mrih1.loading_efficiency_weight    loading_efficiency_weight    -- �ύڗ�(�d��)
                 ,mrih1.loading_efficiency_capacity  loading_efficiency_capacity  -- �ύڗ�(�e��)
           FROM   xxinv_mov_req_instr_headers        mrih1                        -- �ړ��˗�/�w���w�b�_(�A�h�I��)
                 ,xxinv_mov_req_instr_lines          mril                         -- �ړ��˗�/�w������(�A�h�I��)
           WHERE  iv_biz_type      = cv_move
           AND    lv_delivery_no  IS NULL
           AND    mrih1.mov_num    = iv_request_no
           AND    mrih1.mov_hdr_id = mril.mov_hdr_id
           ----------------------
           UNION ALL
           ----------------------
           SELECT mrih1.mov_hdr_id                   mov_hdr_id                   -- �ړ��w�b�_ID
                 ,mrih1.status                       status                       -- �X�e�[�^�X
                 ,mrih1.mov_num                      mov_num                      -- �ړ��ԍ�
                 ,mrih1.notif_status                 notif_status                 -- �ʒm�X�e�[�^�X
                 ,mrih1.prev_notif_status            prev_notif_status            -- �O��ʒm�X�e�[�^�X
                 ,mril.shipped_quantity              shipped_quantity             -- �o�Ɏ��ѐ���
                 ,mril.ship_to_quantity              ship_to_quantity             -- ���Ɏ��ѐ���
                 ,mrih1.shipping_method_code         shipping_method_code         -- �z���敪
                 ,mrih1.item_class                   item_class                   -- ���i�敪
                 ,mrih1.based_weight                 based_weight                 -- ��{�d��
                 ,mrih1.based_capacity               based_capacity               -- ��{�e��
                 ,mrih1.weight_capacity_class        weight_capacity_class        -- �d�ʗe�ϋ敪
                 ,mrih1.shipped_locat_code           shipped_locat_code           -- �o�Ɍ�
                 ,mrih1.ship_to_locat_code           ship_to_locat_code           -- ���ɐ�
                 ,mrih1.schedule_ship_date           schedule_ship_date           -- �o�ɗ\���
                 ,mrih1.sum_weight                   sum_weight                   -- �ύڏd�ʍ��v
                 ,mrih1.sum_capacity                 sum_capacity                 -- �ύڗe�ύ��v
                 ,mrih1.sum_pallet_weight            sum_pallet_weight            -- ���v�p���b�g�d��
                 ,mrih1.freight_charge_class         freight_charge_class         -- �^���敪
                 ,mrih1.loading_efficiency_weight    loading_efficiency_weight    -- �ύڗ�(�d��)
                 ,mrih1.loading_efficiency_capacity  loading_efficiency_capacity  -- �ύڗ�(�e��)
           FROM   xxinv_mov_req_instr_headers        mrih1                        -- �ړ��˗�/�w���w�b�_(�A�h�I��)
                 ,xxinv_mov_req_instr_lines          mril                         -- �ړ��˗�/�w������(�A�h�I��)
           WHERE ((iv_biz_type         <> cv_move)
             OR   ((iv_biz_type         = cv_move)
               AND (lv_delivery_no IS NOT NULL)))
           AND    mrih1.delivery_no     = lv_delivery_no
           AND    mrih1.mov_hdr_id      = mril.mov_hdr_id
           ) mrih
-- 2008/08/28 H.Itou Mod End
    ORDER BY mrih.mov_hdr_id;
--
    IF (gt_chk_move_tbl.COUNT > 0) THEN
      -- �f�[�^�����݂���ꍇ�̓J�E���g
      ln_data_count := ln_data_count + 1;
      -- �擾�������R�[�h�̕��������[�v
      <<gt_chk_move_tbl_loop>>
      FOR i IN gt_chk_move_tbl.FIRST .. gt_chk_move_tbl.LAST LOOP
--
        -- �X�e�[�^�X����˗������˗��ϣ���������ŁA
        -- �o�Ɏ��ѐ��ʂ܂��͓��Ɏ��ѐ��ʂ�NULL�łȂ��f�[�^�͔z�ԉ����s��
        IF ((gt_chk_move_tbl(i).status <= cv_adjustment) AND
             ((gt_chk_move_tbl(i).shipped_quantity IS NOT NULL) OR
             (gt_chk_move_tbl(i).ship_to_quantity IS NOT NULL))) THEN
          ln_no_count := ln_no_count + 1;
-- Ver1.20 M.Hokkanji START
          IF (lv_msg_move_err IS NULL) THEN
            lv_msg_move_err := gt_chk_move_tbl(i).mov_num;
          ELSE
            lv_msg_move_err := lv_msg_move_err
                               || cv_msg_com
                               || gt_chk_move_tbl(i).mov_num;
          END IF;
-- Ver1.20 M.Hokkanji END
--
        -- �X�e�[�^�X����o�׎��ьv��ϣ������̃f�[�^�͔z�ԉ����s��
        ELSIF (gt_chk_move_tbl(i).status > cv_adjustment) THEN
          IF (lv_msg_move_err IS NULL) THEN
-- Ver1.20 M.Hokkanji START
            lv_msg_move_err := gt_chk_move_tbl(i).mov_num;
--            lv_msg_move_err := iv_request_no;
-- Ver1.20 M.Hokkanji END
          ELSE
-- Ver1.20 M.Hokkanji START
            lv_msg_move_err := lv_msg_move_err
                               || cv_msg_com
                               || gt_chk_move_tbl(i).mov_num;
--                               || iv_request_no;
-- Ver1.20 M.Hokkanji END
          END IF;
          ln_no_count     := ln_no_count + 1;
-- Ver1.20 M.Hokkanji START
        ELSE
          -- �^���敪��1�̏ꍇ�̂ݎ擾�����z���敪�A��{�d�ʁA��{�e�ρA�ύڗ�(�d��)�A�ύڗ�(�e��)���X�V
          IF (gt_chk_move_tbl(i).freight_charge_class = gv_freight_charge_yes) THEN
            lv_err_chek := '0'; -- �G���[�`�F�b�N�t���O�������l�ɖ߂�
            -- �ő�z���敪�擾
            ln_ret_code := get_max_ship_method(
                             iv_code_class1                => cv_code_kbn_mov,
                             iv_entering_despatching_code1 => gt_chk_move_tbl(i).shipped_locat_code,
                             iv_code_class2                => cv_code_kbn_mov,
                             iv_entering_despatching_code2 => gt_chk_move_tbl(i).ship_to_locat_code,
                             iv_prod_class                 => gt_chk_move_tbl(i).item_class,
                             iv_weight_capacity_class      => gt_chk_move_tbl(i).weight_capacity_class,
                             iv_auto_process_type          => NULL,
                             id_standard_date              => gt_chk_move_tbl(i).schedule_ship_date,
                             ov_max_ship_methods           => lt_max_ship_methods,
                             on_drink_deadweight           => lt_drink_deadweight,
                             on_leaf_deadweight            => lt_leaf_deadweight,
                             on_drink_loading_capacity     => lt_drink_loading_capacity,
                             on_leaf_loading_capacity      => lt_leaf_loading_capacity,
                             on_palette_max_qty            => lt_palette_max_qty);
            IF (ln_ret_code <> gn_status_normal) THEN
              IF (lv_msg_move_max_err IS NULL) THEN
                lv_msg_move_max_err := gt_chk_move_tbl(i).mov_num;
              ELSE
                lv_msg_move_max_err := lv_msg_move_max_err
                                   || cv_msg_com
                                   || gt_chk_move_tbl(i).mov_num;
              END IF;
              ln_no_count     := ln_no_count + 1;
              lv_err_chek     := '1';
            ELSE
              -- ���i�敪���h�����N�̏ꍇ
              IF (gt_chk_move_tbl(i).item_class = cv_prod_class_2) THEN
                gt_chk_move_tbl(i).based_weight       := lt_drink_deadweight;
                gt_chk_move_tbl(i).based_capacity     := lt_drink_loading_capacity;
              ELSE
                gt_chk_move_tbl(i).based_weight       := lt_drink_deadweight;
                gt_chk_move_tbl(i).based_capacity     := lt_drink_loading_capacity;
              END IF;
              gt_chk_move_tbl(i).shipping_method_code := lt_max_ship_methods;
            END IF;
--
            -- �ő�z���敪�̎擾�ɐ������Ă���ꍇ
            IF (lv_err_chek = '0') THEN
              BEGIN
--
                -- �擾�����z���敪�����ƂɃN�C�b�N�R�[�h�XXCMN_SHIP_METHOD����珬���敪���擾
                SELECT  xsm2.small_amount_class
                  INTO  lv_small_sum_class
                  FROM  xxwsh_ship_method2_v    xsm2
                 WHERE  xsm2.ship_method_code   =  gt_chk_move_tbl(i).shipping_method_code
                   AND  xsm2.start_date_active  <= gt_chk_move_tbl(i).schedule_ship_date
                   AND  gt_chk_move_tbl(i).schedule_ship_date <= NVL(xsm2.end_date_active,
                                                                     gt_chk_move_tbl(i).schedule_ship_date);
--
              EXCEPTION
                WHEN OTHERS THEN
                  IF (lv_msg_move_small_err IS NULL) THEN
                    lv_msg_move_small_err := gt_chk_move_tbl(i).mov_num;
                  ELSE
                    lv_msg_move_small_err := lv_msg_move_small_err
                                           || cv_msg_com
                                           || gt_chk_move_tbl(i).mov_num;
                  END IF;
                  ln_no_count     := ln_no_count + 1;
                  lv_err_chek     := '1';
              END;
            END IF;
--
            -- �ő�z���敪�A�����敪�̎擾�ɐ������Ă���ꍇ
            IF (lv_err_chek = '0') THEN
              IF (lv_small_sum_class = cv_include) THEN
-- Ver1.22 M.Hokkanji START
--                ln_sum_weight := gt_chk_ship_tbl(i).sum_weight;
                ln_sum_weight := gt_chk_move_tbl(i).sum_weight;
-- Ver1.22 M.Hokkanji END
              ELSE
-- Ver1.22 M.Hokkanji START
--                ln_sum_weight := gt_chk_ship_tbl(i).sum_weight + NVL(gt_chk_ship_tbl(i).sum_pallet_weight,0);
                ln_sum_weight := gt_chk_move_tbl(i).sum_weight + NVL(gt_chk_move_tbl(i).sum_pallet_weight,0);
-- Ver1.22 M.Hokkanji END
              END IF;
              --�ύڌ���(�d��)���擾
              xxwsh_common910_pkg.calc_load_efficiency(
                in_sum_weight                 =>  ln_sum_weight,                            -- 1.���v�d��
                in_sum_capacity               =>  NULL,                                     -- 2.���v�e��
                iv_code_class1                =>  cv_code_kbn_mov,                          -- 3.�R�[�h�敪�P
                iv_entering_despatching_code1 =>  gt_chk_move_tbl(i).shipped_locat_code,    -- 4.���o�ɏꏊ�R�[�h�P
                iv_code_class2                =>  cv_code_kbn_mov,                          -- 5.�R�[�h�敪�Q
                iv_entering_despatching_code2 =>  gt_chk_move_tbl(i).ship_to_locat_code,    -- 6.���o�ɏꏊ�R�[�h�Q
                iv_ship_method                =>  gt_chk_move_tbl(i).shipping_method_code,  -- 7.�o�ו��@
                iv_prod_class                 =>  gt_chk_move_tbl(i).item_class,            -- 8.���i�敪
                iv_auto_process_type          =>  NULL,                                     -- 9.�����z�ԑΏۋ敪
                id_standard_date              =>  gt_chk_move_tbl(i).schedule_ship_date,    -- 10.���(�K�p�����)
                ov_retcode                    =>  lv_retcode,                               -- 11.���^�[���R�[�h
                ov_errmsg_code                =>  lv_errmsg_code,                           -- 12.�G���[���b�Z�[�W�R�[�h
                ov_errmsg                     =>  lv_errmsg,                                -- 13.�G���[���b�Z�[�W
                ov_loading_over_class         =>  lv_loading_over_class,                    -- 14.�ύڃI�[�o�[�敪
                ov_ship_methods               =>  lv_ship_methods,                          -- 15.�o�ו��@
                on_load_efficiency_weight     =>  ln_load_efficiency_weight,                -- 16.�d�ʐύڌ���
                on_load_efficiency_capacity   =>  ln_load_efficiency_capacity,              -- 17.�e�ϐύڌ���
                ov_mixed_ship_method          =>  lv_mixed_ship_method);                    -- 18.���ڔz���敪
--
              -- ���^�[���R�[�h��'1'(�ُ�)�̏ꍇ�̓G���[���Z�b�g
              IF (lv_retcode = gn_status_error) THEN
                IF (lv_msg_move_wei_err IS NULL) THEN
                  lv_msg_move_wei_err := gt_chk_move_tbl(i).mov_num;
                ELSE
                  lv_msg_move_wei_err := lv_msg_move_wei_err
                                           || cv_msg_com
                                           || gt_chk_move_tbl(i).mov_num;
                END IF;
                ln_no_count     := ln_no_count + 1;
                lv_err_chek     := '1';
              ELSE
                -- �ُ�ł͂Ȃ��ꍇ�ύڗ�(�d��)���Z�b�g
                gt_chk_move_tbl(i).loading_efficiency_weight := ln_load_efficiency_weight;
--
              END IF;
              --�ύڌ���(�e��)���擾
              xxwsh_common910_pkg.calc_load_efficiency(
                in_sum_weight                 =>  NULL,                                     -- 1.���v�d��
                in_sum_capacity               =>  gt_chk_move_tbl(i).sum_capacity,          -- 2.���v�e��
                iv_code_class1                =>  cv_code_kbn_mov,                          -- 3.�R�[�h�敪�P
                iv_entering_despatching_code1 =>  gt_chk_move_tbl(i).shipped_locat_code,    -- 4.���o�ɏꏊ�R�[�h�P
                iv_code_class2                =>  cv_code_kbn_mov,                          -- 5.�R�[�h�敪�Q
                iv_entering_despatching_code2 =>  gt_chk_move_tbl(i).ship_to_locat_code,    -- 6.���o�ɏꏊ�R�[�h�Q
                iv_ship_method                =>  gt_chk_move_tbl(i).shipping_method_code,  -- 7.�o�ו��@
                iv_prod_class                 =>  gt_chk_move_tbl(i).item_class,            -- 8.���i�敪
                iv_auto_process_type          =>  NULL,                                     -- 9.�����z�ԑΏۋ敪
                id_standard_date              =>  gt_chk_move_tbl(i).schedule_ship_date,    -- 10.���(�K�p�����)
                ov_retcode                    =>  lv_retcode,                               -- 11.���^�[���R�[�h
                ov_errmsg_code                =>  lv_errmsg_code,                           -- 12.�G���[���b�Z�[�W�R�[�h
                ov_errmsg                     =>  lv_errmsg,                                -- 13.�G���[���b�Z�[�W
                ov_loading_over_class         =>  lv_loading_over_class,                    -- 14.�ύڃI�[�o�[�敪
                ov_ship_methods               =>  lv_ship_methods,                          -- 15.�o�ו��@
                on_load_efficiency_weight     =>  ln_load_efficiency_weight,                -- 16.�d�ʐύڌ���
                on_load_efficiency_capacity   =>  ln_load_efficiency_capacity,              -- 17.�e�ϐύڌ���
                ov_mixed_ship_method          =>  lv_mixed_ship_method);                    -- 18.���ڔz���敪
--
              -- ���^�[���R�[�h��'1'(�ُ�)�̏ꍇ�̓G���[���Z�b�g
              IF (lv_retcode = gn_status_error) THEN
                IF (lv_msg_move_cap_err IS NULL) THEN
                  lv_msg_move_cap_err := gt_chk_move_tbl(i).mov_num;
                ELSE
                  lv_msg_move_cap_err := lv_msg_move_cap_err
                                           || cv_msg_com
                                           || gt_chk_move_tbl(i).mov_num;
                END IF;
                ln_no_count     := ln_no_count + 1;
                lv_err_chek     := '1';
              ELSE
                -- �ُ�ł͂Ȃ��ꍇ�ύڗ�(�e��)���Z�b�g
                gt_chk_move_tbl(i).loading_efficiency_capacity := ln_load_efficiency_capacity;
--
              END IF;
--
            END IF;
--
          END IF;
-- Ver1.20 M.Hokkanji END
        END IF;
--
      END LOOP gt_chk_move_tbl_loop;
--
    END IF;
--
    -- **************************************************
    -- *** 4.�z�ԉ����ۃ`�F�b�N(�x��)
    -- **************************************************
    SELECT xoha.order_header_id,                          -- �󒍃w�b�_�A�h�I��ID
           xoha.req_status,                               -- �X�e�[�^�X
           xoha.request_no,
           xoha.notif_status,
           xoha.prev_notif_status,
           xola.shipped_quantity,                         -- �o�׎��ѐ���
           xola.ship_to_quantity,                         -- ���Ɏ��ю��ѐ���
-- Ver1.20 M.Hokkanji START
           xoha.shipping_method_code,                     -- �z���敪
           xoha.prod_class,                               -- ���i�敪
           xoha.based_weight,                             -- ��{�d��
           xoha.based_capacity,                           -- ��{�e��
           xoha.weight_capacity_class,                    -- �d�ʗe�ϋ敪
           xoha.deliver_from,                             -- �o�׌�
           xoha.vendor_site_code,                         -- �����T�C�g
           xoha.schedule_ship_date,                       -- �o�ɗ\���
           xoha.sum_weight,                               -- �ύڏd�ʍ��v
           xoha.sum_capacity,                             -- �ύڗe�ύ��v
           xoha.freight_charge_class,                     -- �^���敪
           xoha.loading_efficiency_weight,                -- �ύڗ�(�d��)
           xoha.loading_efficiency_capacity               -- �ύڗ�(�e��)
-- Ver1.20 M.Hokkanji END
    BULK COLLECT INTO
           gt_chk_supply_tbl
    FROM   xxwsh_order_headers_all            xoha,       -- �󒍃w�b�_�A�h�I��
           xxwsh_order_lines_all              xola,       -- �󒍖��׃A�h�I��
           xxwsh_oe_transaction_types2_v       xott        -- �󒍃^�C�v���VIEW
    WHERE  (((iv_biz_type = cv_supply) AND (lv_delivery_no IS NULL) AND
             (xoha.request_no = iv_request_no))
    OR     (((iv_biz_type <> cv_supply) OR
           ((iv_biz_type = cv_supply) AND (lv_delivery_no IS NOT NULL))) AND
             (xoha.delivery_no = lv_delivery_no)))
    AND    xoha.order_type_id                         =  xott.transaction_type_id
    AND    xoha.order_header_id                       =  xola.order_header_id
    AND    NVL(xola.delete_flag, cv_flag_no)          =  cv_flag_no
    AND    xott.shipping_shikyu_class                 =  cv_supply_req
    AND    xott.order_category_code                   =  cv_cate_order
    AND    xott.start_date_active                     <= trunc( xoha.schedule_ship_date )
    AND    NVL(xott.end_date_active,to_date('99991231','YYYYMMDD')) 
                                                      >= trunc( xoha.schedule_ship_date )
    AND    NVL(xoha.latest_external_flag, cv_flag_no) =  cv_flag_yes
    ORDER BY xoha.order_header_id;
--
    IF (gt_chk_supply_tbl.COUNT > 0) THEN
      -- �f�[�^�����݂���ꍇ�̓J�E���g
      ln_data_count := ln_data_count + 1;
      -- �擾�������R�[�h�̕��������[�v
      <<gt_chk_supply_tbl_loop>>
      FOR i IN gt_chk_supply_tbl.FIRST .. gt_chk_supply_tbl.LAST LOOP
--
        -- �X�e�[�^�X������͒������͍ϣ���̍ϣ�ŁA
        -- �o�׎��ѐ��ʂ܂��͓��Ɏ��ѐ��ʂ�NULL�łȂ��f�[�^�͔z�ԉ����s��
        IF ((gt_chk_supply_tbl(i).req_status <= cv_received) AND
             ((gt_chk_supply_tbl(i).shipped_quantity IS NOT NULL) OR
             (gt_chk_supply_tbl(i).ship_to_quantity IS NOT NULL))) THEN
          ln_no_count := ln_no_count + 1;
-- Ver1.20 M.Hokkanji START
          IF (lv_msg_supply_err IS NULL) THEN
            lv_msg_supply_err := gt_chk_supply_tbl(i).request_no;
          ELSE
            lv_msg_supply_err := lv_msg_supply_err
                                 || cv_msg_com
                                 || gt_chk_supply_tbl(i).request_no;
          END IF;
-- Ver1.20 M.Hokkanji END
--
        -- �X�e�[�^�X����o�׎��ьv��ϣ������̃f�[�^�͔z�ԉ����s��
        ELSIF (gt_chk_supply_tbl(i).req_status > cv_received) THEN
          IF (lv_msg_supply_err IS NULL) THEN
-- Ver1.20 M.Hokkanji START
--            lv_msg_supply_err := iv_request_no;
            lv_msg_supply_err := gt_chk_supply_tbl(i).request_no;
-- Ver1.20 M.Hokkanji END
          ELSE
-- Ver1.20 M.Hokkanji START
            lv_msg_supply_err := lv_msg_supply_err
                                 || cv_msg_com
                                 || gt_chk_supply_tbl(i).request_no;
--                                 || iv_request_no;
          END IF;
-- Ver1.20 M.Hokkanji END
          ln_no_count       := ln_no_count + 1;
--
-- Ver1.20 M.Hokkanji START
        ELSE
          -- �^���敪��1�̏ꍇ�̂ݎ擾�����z���敪�A��{�d�ʁA��{�e�ρA�ύڗ�(�d��)�A�ύڗ�(�e��)���X�V
          IF (gt_chk_supply_tbl(i).freight_charge_class = gv_freight_charge_yes) THEN
            lv_err_chek := '0'; -- �G���[�`�F�b�N�t���O�������l�ɖ߂�
            -- �ő�z���敪�擾
            ln_ret_code := get_max_ship_method(
                             iv_code_class1                => cv_code_kbn_mov,
                             iv_entering_despatching_code1 => gt_chk_supply_tbl(i).deliver_from,
                             iv_code_class2                => cv_code_kbn_supply,
                             iv_entering_despatching_code2 => gt_chk_supply_tbl(i).vendor_site_code,
                             iv_prod_class                 => gt_chk_supply_tbl(i).prod_class,
                             iv_weight_capacity_class      => gt_chk_supply_tbl(i).weight_capacity_class,
                             iv_auto_process_type          => NULL,
                             id_standard_date              => gt_chk_supply_tbl(i).schedule_ship_date,
                             ov_max_ship_methods           => lt_max_ship_methods,
                             on_drink_deadweight           => lt_drink_deadweight,
                             on_leaf_deadweight            => lt_leaf_deadweight,
                             on_drink_loading_capacity     => lt_drink_loading_capacity,
                             on_leaf_loading_capacity      => lt_leaf_loading_capacity,
                             on_palette_max_qty            => lt_palette_max_qty);
            IF (ln_ret_code <> gn_status_normal) THEN
              IF (lv_msg_supply_max_err IS NULL) THEN
                lv_msg_supply_max_err := gt_chk_supply_tbl(i).request_no;
              ELSE
                lv_msg_supply_max_err := lv_msg_supply_max_err
                                   || cv_msg_com
                                   || gt_chk_supply_tbl(i).request_no;
              END IF;
              ln_no_count     := ln_no_count + 1;
              lv_err_chek     := '1';
            ELSE
              -- ���i�敪���h�����N�̏ꍇ
              IF (gt_chk_supply_tbl(i).prod_class = cv_prod_class_2) THEN
                gt_chk_supply_tbl(i).based_weight       := lt_drink_deadweight;
                gt_chk_supply_tbl(i).based_capacity     := lt_drink_loading_capacity;
              ELSE
                gt_chk_supply_tbl(i).based_weight       := lt_drink_deadweight;
                gt_chk_supply_tbl(i).based_capacity     := lt_drink_loading_capacity;
              END IF;
              gt_chk_supply_tbl(i).shipping_method_code := lt_max_ship_methods;
            END IF;
--
            -- �ő�z���敪�̎擾�ɐ������Ă���ꍇ
            IF (lv_err_chek = '0') THEN
              --�ύڌ���(�d��)���擾
              xxwsh_common910_pkg.calc_load_efficiency(
                in_sum_weight                 =>  gt_chk_supply_tbl(i).sum_weight,          -- 1.���v�d��
                in_sum_capacity               =>  NULL,                                     -- 2.���v�e��
                iv_code_class1                =>  cv_code_kbn_mov,                          -- 3.�R�[�h�敪�P
                iv_entering_despatching_code1 =>  gt_chk_supply_tbl(i).deliver_from,        -- 4.���o�ɏꏊ�R�[�h�P
                iv_code_class2                =>  cv_code_kbn_supply,                       -- 5.�R�[�h�敪�Q
                iv_entering_despatching_code2 =>  gt_chk_supply_tbl(i).vendor_site_code,    -- 6.���o�ɏꏊ�R�[�h�Q
                iv_ship_method                =>  gt_chk_supply_tbl(i).shipping_method_code, -- 7.�o�ו��@
                iv_prod_class                 =>  gt_chk_supply_tbl(i).prod_class,          -- 8.���i�敪
                iv_auto_process_type          =>  NULL,                                     -- 9.�����z�ԑΏۋ敪
                id_standard_date              =>  gt_chk_supply_tbl(i).schedule_ship_date,    -- 10.���(�K�p�����)
                ov_retcode                    =>  lv_retcode,                               -- 11.���^�[���R�[�h
                ov_errmsg_code                =>  lv_errmsg_code,                           -- 12.�G���[���b�Z�[�W�R�[�h
                ov_errmsg                     =>  lv_errmsg,                                -- 13.�G���[���b�Z�[�W
                ov_loading_over_class         =>  lv_loading_over_class,                    -- 14.�ύڃI�[�o�[�敪
                ov_ship_methods               =>  lv_ship_methods,                          -- 15.�o�ו��@
                on_load_efficiency_weight     =>  ln_load_efficiency_weight,                -- 16.�d�ʐύڌ���
                on_load_efficiency_capacity   =>  ln_load_efficiency_capacity,              -- 17.�e�ϐύڌ���
                ov_mixed_ship_method          =>  lv_mixed_ship_method);                    -- 18.���ڔz���敪
--
              -- ���^�[���R�[�h��'1'(�ُ�)�̏ꍇ�̓G���[���Z�b�g
              IF (lv_retcode = gn_status_error) THEN
                IF (lv_msg_supply_wei_err IS NULL) THEN
                  lv_msg_supply_wei_err := gt_chk_supply_tbl(i).request_no;
                ELSE
                  lv_msg_supply_wei_err := lv_msg_supply_wei_err
                                           || cv_msg_com
                                           || gt_chk_supply_tbl(i).request_no;
                END IF;
                ln_no_count     := ln_no_count + 1;
                lv_err_chek     := '1';
              ELSE
                -- �ُ�ł͂Ȃ��ꍇ�ύڗ�(�d��)���Z�b�g
                gt_chk_supply_tbl(i).loading_efficiency_weight := ln_load_efficiency_weight;
--
              END IF;
              --�ύڌ���(�e��)���擾
              xxwsh_common910_pkg.calc_load_efficiency(
                in_sum_weight                 =>  NULL,                                     -- 1.���v�d��
                in_sum_capacity               =>  gt_chk_supply_tbl(i).sum_capacity,        -- 2.���v�e��
                iv_code_class1                =>  cv_code_kbn_mov,                          -- 3.�R�[�h�敪�P
                iv_entering_despatching_code1 =>  gt_chk_supply_tbl(i).deliver_from,        -- 4.���o�ɏꏊ�R�[�h�P
                iv_code_class2                =>  cv_code_kbn_supply,                       -- 5.�R�[�h�敪�Q
                iv_entering_despatching_code2 =>  gt_chk_supply_tbl(i).vendor_site_code,    -- 6.���o�ɏꏊ�R�[�h�Q
                iv_ship_method                =>  gt_chk_supply_tbl(i).shipping_method_code,  -- 7.�o�ו��@
                iv_prod_class                 =>  gt_chk_supply_tbl(i).prod_class,          -- 8.���i�敪
                iv_auto_process_type          =>  NULL,                                     -- 9.�����z�ԑΏۋ敪
                id_standard_date              =>  gt_chk_supply_tbl(i).schedule_ship_date,    -- 10.���(�K�p�����)
                ov_retcode                    =>  lv_retcode,                               -- 11.���^�[���R�[�h
                ov_errmsg_code                =>  lv_errmsg_code,                           -- 12.�G���[���b�Z�[�W�R�[�h
                ov_errmsg                     =>  lv_errmsg,                                -- 13.�G���[���b�Z�[�W
                ov_loading_over_class         =>  lv_loading_over_class,                    -- 14.�ύڃI�[�o�[�敪
                ov_ship_methods               =>  lv_ship_methods,                          -- 15.�o�ו��@
                on_load_efficiency_weight     =>  ln_load_efficiency_weight,                -- 16.�d�ʐύڌ���
                on_load_efficiency_capacity   =>  ln_load_efficiency_capacity,              -- 17.�e�ϐύڌ���
                ov_mixed_ship_method          =>  lv_mixed_ship_method);                    -- 18.���ڔz���敪
--
              -- ���^�[���R�[�h��'1'(�ُ�)�̏ꍇ�̓G���[���Z�b�g
              IF (lv_retcode = gn_status_error) THEN
                IF (lv_msg_supply_cap_err IS NULL) THEN
                  lv_msg_supply_cap_err := gt_chk_supply_tbl(i).request_no;
                ELSE
                  lv_msg_supply_cap_err := lv_msg_supply_cap_err
                                           || cv_msg_com
                                           || gt_chk_supply_tbl(i).request_no;
                END IF;
                ln_no_count     := ln_no_count + 1;
                lv_err_chek     := '1';
              ELSE
                -- �ُ�ł͂Ȃ��ꍇ�ύڗ�(�e��)���Z�b�g
                gt_chk_supply_tbl(i).loading_efficiency_capacity := ln_load_efficiency_capacity;
--
              END IF;
--
            END IF;
--
          END IF;
-- Ver1.20 M.Hokkanji END
        END IF;
--
      END LOOP gt_chk_supply_tbl_loop;
--
    END IF;
--
    -- **************************************************
    -- *** 5.�z�ԉ�������
    -- **************************************************
    IF (lv_delivery_no IS NOT NULL) THEN
--
      -- �z�ԉ����s�̃f�[�^�����݂���ꍇ�̓G���[
      IF (ln_no_count > 0) THEN
        -- 2.�z�ԉ����ۃ`�F�b�N(�o��)�ŃG���[���b�Z�[�W���o�͂��ꂽ�ꍇ
        IF (lv_msg_ship_err IS NOT NULL) THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                cv_msg_ship_err,
                                                cv_tkn_request_no,
                                                lv_msg_ship_err);
        END IF;
--
        -- 2.�z�ԉ����ۃ`�F�b�N(�ړ�)�ŃG���[���b�Z�[�W���o�͂��ꂽ�ꍇ
        IF ((lv_msg_move_err IS NOT NULL) AND (ov_errmsg IS NULL)) THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_move_err,
                                                   cv_tkn_request_no,
                                                   lv_msg_move_err);
--
        ELSIF ((lv_msg_move_err IS NOT NULL) AND (ov_errmsg IS NOT NULL))THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_move_err,
                                                   cv_tkn_request_no,
                                                   lv_msg_move_err);
        END IF;
--
        -- 2.�z�ԉ����ۃ`�F�b�N(�x��)�ŃG���[���b�Z�[�W���o�͂��ꂽ�ꍇ
        IF ((lv_msg_supply_err IS NOT NULL) AND (ov_errmsg IS NULL))THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_supply_err,
                                                   cv_tkn_request_no,
                                                   lv_msg_supply_err);
--
        ELSIF ((lv_msg_supply_err IS NOT NULL) AND (ov_errmsg IS NOT NULL))THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_supply_err,
                                                   cv_tkn_request_no,
                                                   lv_msg_supply_err);
        END IF;
-- Ver1.20 M.Hokkanji START
        -- �o�׍ő�z���敪�G���[
        IF ((lv_msg_ship_max_err IS NOT NULL) AND (ov_errmsg IS NULL))THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_ship_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_max_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_ship_max_err);
--
        ELSIF ((lv_msg_ship_max_err IS NOT NULL) AND (ov_errmsg IS NOT NULL))THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_ship_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_max_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_ship_max_err);
        END IF;
        -- �o�׏����敪�G���[
        IF ((lv_msg_ship_small_err IS NOT NULL) AND (ov_errmsg IS NULL))THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_ship_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_small_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_ship_small_err);
--
        ELSIF ((lv_msg_ship_small_err IS NOT NULL) AND (ov_errmsg IS NOT NULL))THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_ship_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_small_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_ship_small_err);
        END IF;
        -- �o�אύڌ���(�d��)�G���[
        IF ((lv_msg_ship_wei_err IS NOT NULL) AND (ov_errmsg IS NULL))THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_ship_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_weight_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_ship_wei_err);
--
        ELSIF ((lv_msg_ship_wei_err IS NOT NULL) AND (ov_errmsg IS NOT NULL))THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_ship_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_weight_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_ship_wei_err);
        END IF;
        -- �o�אύڌ���(�e��)�G���[
        IF ((lv_msg_ship_cap_err IS NOT NULL) AND (ov_errmsg IS NULL))THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_ship_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_cap_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_ship_cap_err);
--
        ELSIF ((lv_msg_ship_cap_err IS NOT NULL) AND (ov_errmsg IS NOT NULL))THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_ship_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_cap_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_ship_cap_err);
        END IF;
        -- �x���ő�z���敪�G���[
        IF ((lv_msg_supply_max_err IS NOT NULL) AND (ov_errmsg IS NULL))THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_supply_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_max_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_supply_max_err);
--
        ELSIF ((lv_msg_supply_max_err IS NOT NULL) AND (ov_errmsg IS NOT NULL))THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_supply_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_max_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_supply_max_err);
        END IF;
        -- �x���ύڌ���(�d��)�G���[
        IF ((lv_msg_supply_wei_err IS NOT NULL) AND (ov_errmsg IS NULL))THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_supply_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_weight_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_supply_wei_err);
--
        ELSIF ((lv_msg_supply_wei_err IS NOT NULL) AND (ov_errmsg IS NOT NULL))THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_supply_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_weight_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_supply_wei_err);
        END IF;
        -- �x���ύڌ���(�e��)�G���[
        IF ((lv_msg_supply_cap_err IS NOT NULL) AND (ov_errmsg IS NULL))THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_supply_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_cap_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_supply_cap_err);
--
        ELSIF ((lv_msg_supply_cap_err IS NOT NULL) AND (ov_errmsg IS NOT NULL))THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_supply_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_cap_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_supply_cap_err);
        END IF;
        -- �ړ��ő�z���敪�G���[
        IF ((lv_msg_move_max_err IS NOT NULL) AND (ov_errmsg IS NULL))THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_move_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_max_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_move_max_err);
--
        ELSIF ((lv_msg_move_max_err IS NOT NULL) AND (ov_errmsg IS NOT NULL))THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_move_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_max_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_move_max_err);
        END IF;
        -- �ړ������敪�G���[
        IF ((lv_msg_move_small_err IS NOT NULL) AND (ov_errmsg IS NULL))THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_move_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_small_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_move_small_err);
--
        ELSIF ((lv_msg_move_small_err IS NOT NULL) AND (ov_errmsg IS NOT NULL))THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_move_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_small_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_move_small_err);
        END IF;
        -- �ړ��ύڌ���(�d��)�G���[
        IF ((lv_msg_move_wei_err IS NOT NULL) AND (ov_errmsg IS NULL))THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_move_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_weight_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_move_wei_err);
--
        ELSIF ((lv_msg_move_wei_err IS NOT NULL) AND (ov_errmsg IS NOT NULL))THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_move_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_weight_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_move_wei_err);
        END IF;
        -- �ړ��ύڌ���(�e��)�G���[
        IF ((lv_msg_move_cap_err IS NOT NULL) AND (ov_errmsg IS NULL))THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_move_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_cap_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_move_cap_err);
--
        ELSIF ((lv_msg_move_cap_err IS NOT NULL) AND (ov_errmsg IS NOT NULL))THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_move_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_cap_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_move_cap_err);
        END IF;
-- Ver1.20 M.Hokkanji END
--
        RETURN cv_career_cancel_err;
--
      -- �Ώۂ̃f�[�^�����݂��Ȃ��ꍇ�̓G���[
      ELSIF (ln_data_count <= 0) THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_del_req_instr);
        RETURN cv_career_cancel_err;
--
      END IF;
--
      IF (gt_chk_ship_tbl.COUNT > 0) THEN
        -- �擾�������R�[�h�̕��������[�v
        <<gt_chk_ship_tbl_loop>>
        FOR i IN gt_chk_ship_tbl.FIRST .. gt_chk_ship_tbl.LAST LOOP
--
          -- �󒍃w�b�_�A�h�I��ID���O�̃��R�[�h�Ɠ����łȂ��ꍇ
          IF ((i = gt_chk_ship_tbl.FIRST) OR
             (gt_chk_ship_tbl(i).order_header_id
               <> gt_chk_ship_tbl(i - 1).order_header_id)) THEN
            -- �󒍃w�b�_�A�h�I���X�V����
            UPDATE xxwsh_order_headers_all            xoha          -- �󒍃w�b�_�A�h�I��
            SET    xoha.prev_delivery_no              =                     -- �O��z��No
                   (CASE
                     WHEN xoha.notif_status = cv_deci_noti THEN
                       xoha.delivery_no
                     ELSE
                       xoha.prev_delivery_no
                   END),
                   xoha.delivery_no                   =  NULL,              -- �z��No
                   xoha.mixed_ratio                   =  NULL,              -- ���ڗ�
-- Ver1.20 M.Hokkanji START
                   xoha.shipping_method_code          =  gt_chk_ship_tbl(i).shipping_method_code, -- �z���敪
                   xoha.based_weight                  =  gt_chk_ship_tbl(i).based_weight, -- ��{�d��
                   xoha.based_capacity                =  gt_chk_ship_tbl(i).based_capacity, -- ��{�e��
                   xoha.loading_efficiency_weight     =  gt_chk_ship_tbl(i).loading_efficiency_weight, -- �ύڌ���(�d��)
                   xoha.loading_efficiency_capacity   =  gt_chk_ship_tbl(i).loading_efficiency_capacity, -- �ύڌ���(�e��)
--                   xoha.mixed_no                      =  NULL,              -- ���ڌ�No
-- Ver1.20 M.Hokkanji END
                   xoha.last_updated_by               =  ln_user_id,
                   xoha.last_update_date              =  ld_sysdate,
                   xoha.last_update_login             =  ln_login_id,
                   xoha.request_id                    =  ln_conc_request_id,
                   xoha.program_application_id        =  ln_prog_appl_id,
                   xoha.program_id                    =  ln_conc_program_id,
                   xoha.program_update_date           =  ld_sysdate
            WHERE  xoha.order_header_id               =  gt_chk_ship_tbl(i).order_header_id;
--
          END IF;
--
        END LOOP gt_chk_ship_tbl_loop;
--
-- Ver1.20 M.Hokkanji START
--      ELSIF (gt_chk_supply_tbl.COUNT > 0) THEN
      END IF;
      IF (gt_chk_supply_tbl.COUNT > 0) THEN
-- Ver1.20 M.Hokkanji END
        -- �擾�������R�[�h�̕��������[�v
        <<gt_chk_supply_tbl_loop>>
        FOR i IN gt_chk_supply_tbl.FIRST .. gt_chk_supply_tbl.LAST LOOP
--
          -- �󒍃w�b�_�A�h�I��ID���O�̃��R�[�h�Ɠ����łȂ��ꍇ
          IF ((i = gt_chk_supply_tbl.FIRST) OR
             (gt_chk_supply_tbl(i).order_header_id
               <> gt_chk_supply_tbl(i - 1).order_header_id)) THEN
            -- �󒍃w�b�_�A�h�I���X�V����
            UPDATE xxwsh_order_headers_all            xoha          -- �󒍃w�b�_�A�h�I��
            SET    xoha.prev_delivery_no              =                     -- �O��z��No
                   (CASE
                     WHEN (xoha.notif_status = cv_deci_noti) THEN
                       xoha.delivery_no
                     ELSE
                       xoha.prev_delivery_no
                   END),
                   xoha.delivery_no                   =  NULL,              -- �z��No
                   xoha.mixed_ratio                   =  NULL,              -- ���ڗ�
-- Ver1.20 M.Hokkanji START
                   xoha.shipping_method_code          =  gt_chk_supply_tbl(i).shipping_method_code, -- �z���敪
                   xoha.based_weight                  =  gt_chk_supply_tbl(i).based_weight, -- ��{�d��
                   xoha.based_capacity                =  gt_chk_supply_tbl(i).based_capacity, -- ��{�e��
                   xoha.loading_efficiency_weight     =  gt_chk_supply_tbl(i).loading_efficiency_weight, -- �ύڌ���(�d��)
                   xoha.loading_efficiency_capacity   =  gt_chk_supply_tbl(i).loading_efficiency_capacity, -- �ύڌ���(�e��)
--                   xoha.mixed_no                      =  NULL,              -- ���ڌ�No
-- Ver1.20 M.Hokkanji END
                   xoha.last_updated_by               =  ln_user_id,
                   xoha.last_update_date              =  ld_sysdate,
                   xoha.last_update_login             =  ln_login_id,
                   xoha.request_id                    =  ln_conc_request_id,
                   xoha.program_application_id        =  ln_prog_appl_id,
                   xoha.program_id                    =  ln_conc_program_id,
                   xoha.program_update_date           =  ld_sysdate
            WHERE  xoha.order_header_id               =  gt_chk_supply_tbl(i).order_header_id;
--
          END IF;
--
        END LOOP gt_chk_supply_tbl_loop;
--
-- Ver1.20 M.Hokkanji START
        END IF;
        IF (gt_chk_move_tbl.COUNT > 0) THEN
--      ELSIF (gt_chk_move_tbl.COUNT > 0) THEN
-- Ver1.20 M.Hokkanji END
        -- �擾�������R�[�h�̕��������[�v
        <<gt_chk_move_tbl_loop>>
        FOR i IN gt_chk_move_tbl.FIRST .. gt_chk_move_tbl.LAST LOOP
--
          -- �ړ��w�b�_ID���O�̃��R�[�h�Ɠ����łȂ��ꍇ
          IF ((i = gt_chk_move_tbl.FIRST) OR
             (gt_chk_move_tbl(i).mov_hdr_id
               <> gt_chk_move_tbl(i - 1).mov_hdr_id)) THEN
            -- �ړ��˗�/�w���w�b�_(�A�h�I��)�X�V����
            UPDATE xxinv_mov_req_instr_headers        mrih     -- �ړ��˗�/�w���w�b�_(�A�h�I��)
            SET    mrih.prev_delivery_no              =                     -- �O��z��No
                   (CASE
                     WHEN (mrih.notif_status = cv_deci_noti) THEN
                       mrih.delivery_no
                     ELSE
                       mrih.prev_delivery_no
                   END),
                   mrih.delivery_no                   =  NULL,              -- �z��No
                   mrih.mixed_ratio                   =  NULL,              -- ���ڗ�
-- Ver1.20 M.Hokkanji START
                   mrih.shipping_method_code          =  gt_chk_move_tbl(i).shipping_method_code, -- �z���敪
                   mrih.based_weight                  =  gt_chk_move_tbl(i).based_weight, -- ��{�d��
                   mrih.based_capacity                =  gt_chk_move_tbl(i).based_capacity, -- ��{�e��
                   mrih.loading_efficiency_weight     =  gt_chk_move_tbl(i).loading_efficiency_weight, -- �ύڌ���(�d��)
                   mrih.loading_efficiency_capacity   =  gt_chk_move_tbl(i).loading_efficiency_capacity, -- �ύڌ���(�e��)
--                   xoha.mixed_no                      =  NULL,              -- ���ڌ�No
-- Ver1.20 M.Hokkanji END
                   mrih.last_updated_by               =  ln_user_id,
                   mrih.last_update_date              =  ld_sysdate,
                   mrih.last_update_login             =  ln_login_id,
                   mrih.request_id                    =  ln_conc_request_id,
                   mrih.program_application_id        =  ln_prog_appl_id,
                   mrih.program_id                    =  ln_conc_program_id,
                   mrih.program_update_date           =  ld_sysdate
            WHERE  mrih.mov_hdr_id                    =  gt_chk_move_tbl(i).mov_hdr_id;
--
          END IF;
--
        END LOOP gt_chk_move_tbl_loop;
--
      END IF;
--
-- Ver1.22 M.Hokkanji START
      BEGIN
-- Ver1.22 M.Hokkanji END
        -- �z�Ԕz���v��(�A�h�I��)���b�N����
        SELECT xcs.transaction_id
        INTO   ln_dummy
        FROM   xxwsh_carriers_schedule        xcs              -- �z�Ԕz���v��(�A�h�I��)
        WHERE  xcs.delivery_no                = lv_delivery_no
        FOR UPDATE NOWAIT;
--
        -- �z�Ԕz���v��(�A�h�I��)�폜����
        DELETE
        FROM   xxwsh_carriers_schedule        xcs              -- �z�Ԕz���v��(�A�h�I��)
        WHERE  xcs.delivery_no                = lv_delivery_no;
-- Ver1.22 M.Hokkanji START
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL; -- �Ώۃf�[�^���Ȃ��ꍇ�̓G���[�Ƃ��Ȃ�
      END;
-- Ver1.22 M.Hokkanji END
--
--
    -- �z��No���ݒ肳��Ă��Ȃ��ꍇ
    ELSE
      -- �z�ԉ����s�̃f�[�^�����݂���ꍇ�͊֘A���ڍX�V�������s�킸����I������B
      IF (ln_no_count > 0) THEN
        -- ����I��
        RETURN cv_compl;
      END IF;
    END IF;
--
    -- **************************************************
    -- *** 6.�֘A���ڍX�V����
    -- **************************************************
    -- �Ώۂ̃f�[�^�����݂��Ȃ��ꍇ�̓G���[
    IF (ln_data_count <= 0) THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_up_req_instr);
      RETURN cv_career_cancel_err;
    END IF;
--
    IF (gt_chk_ship_tbl.COUNT > 0) THEN
      -- �擾�������R�[�h�̕��������[�v
      <<gt_chk_ship_tbl_loop>>
      FOR i IN gt_chk_ship_tbl.FIRST .. gt_chk_ship_tbl.LAST LOOP
--
        -- �󒍃w�b�_�A�h�I��ID���O�̃��R�[�h�Ɠ����łȂ��ꍇ
        IF ((i = gt_chk_ship_tbl.FIRST) OR
             (gt_chk_ship_tbl(i).order_header_id
               <> gt_chk_ship_tbl(i - 1).order_header_id)) THEN
--
          -- �V�K�C���t���O
          IF ( gt_chk_ship_tbl(i).notif_status = cv_deci_noti ) THEN
            --�ʒm�X�e�[�^�X���m��ʒm�� �̏ꍇ�F�C��
            lv_new_modify_flg := cv_amend;
          ELSIF (( gt_chk_ship_tbl(i).prev_notif_status = cv_deci_noti ) 
            AND  ( gt_chk_ship_tbl(i).notif_status      = cv_re_noti )) THEN
            --�O��ʒm�X�e�[�^�X���m��ʒm�� ����
            --  �ʒm�X�e�[�^�X���Ēʒm�v�̏ꍇ�F�C��
            lv_new_modify_flg := cv_amend;
          ELSIF ( gt_chk_ship_tbl(i).notif_status = cv_not_noti ) THEN
            --�ʒm�X�e�[�^�X�����ʒm�̏ꍇ�F�V�K
            lv_new_modify_flg := cv_new;
          ELSE
            --��L�ȊO�̓G���[
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_new_modify_err,
                                                  cv_tkn_biz_type,   cv_tkn_ship_char,
                                                  cv_tkn_req_mov_no, gt_chk_ship_tbl(i).request_no
                                                  );
            RETURN cv_career_cancel_err;                          -- �V�K�C���t���O�G���[
          END IF;
--
--
          -- �󒍃w�b�_�A�h�I���X�V����
          UPDATE xxwsh_order_headers_all            xoha          -- �󒍃w�b�_�A�h�I��
          SET    xoha.prev_notif_status             =             -- �O��ʒm�X�e�[�^�X
                 (CASE                                                    -- �ǉ�
                   WHEN (xoha.notif_status = cv_deci_noti) THEN           -- �ǉ�
                     xoha.notif_status                                    -- �ǉ�
                   ELSE                                                   -- �ǉ�
                     xoha.prev_notif_status                               -- �ǉ�
                 END),                                                    -- �ǉ�
                 xoha.notif_status                  =                     -- �ʒm�X�e�[�^�X
                 (CASE
                   WHEN (xoha.notif_status = cv_deci_noti) THEN
                     cv_re_noti
                   --WHEN (xoha.notif_status = cv_not_noti) THEN
                   --  cv_not_noti
                   ELSE                                                   -- �ǉ�
                     xoha.notif_status                                    -- �ǉ�
                 END),
                 xoha.notif_date                    =  NULL,              -- �m��ʒm���{����
                 --xoha.new_modify_flg                =                     -- �V�K�C���t���O
                 --(CASE
                 --  WHEN (xoha.notif_status = cv_deci_noti) THEN
                 --    cv_amend
                 --  WHEN ((xoha.prev_notif_status = cv_deci_noti) AND
                 --         (xoha.notif_status = cv_re_noti)) THEN
                 --    cv_amend
                 --  WHEN (xoha.notif_status = cv_not_noti) THEN
                 --    cv_new
                 --END),
                 xoha.new_modify_flg                =  lv_new_modify_flg,    -- �V�K�C���t���O
                 xoha.last_updated_by               =  ln_user_id,
                 xoha.last_update_date              =  ld_sysdate,
                 xoha.last_update_login             =  ln_login_id,
                 xoha.request_id                    =  ln_conc_request_id,
                 xoha.program_application_id        =  ln_prog_appl_id,
                 xoha.program_id                    =  ln_conc_program_id,
                 xoha.program_update_date           =  ld_sysdate
          WHERE  xoha.order_header_id               =  gt_chk_ship_tbl(i).order_header_id;
--
        END IF;
--
      END LOOP gt_chk_ship_tbl_loop;
--
-- Ver1.20 M.Hokkanji START
      END IF;
      IF (gt_chk_supply_tbl.COUNT > 0) THEN
--    ELSIF (gt_chk_supply_tbl.COUNT > 0) THEN
-- Ver1.20 M.Hokkanji END
      -- �擾�������R�[�h�̕��������[�v
      <<gt_chk_supply_tbl_loop>>
      FOR i IN gt_chk_supply_tbl.FIRST .. gt_chk_supply_tbl.LAST LOOP
--
        -- �󒍃w�b�_�A�h�I��ID���O�̃��R�[�h�Ɠ����łȂ��ꍇ
        IF ((i = gt_chk_supply_tbl.FIRST) OR
             (gt_chk_supply_tbl(i).order_header_id
               <> gt_chk_supply_tbl(i - 1).order_header_id)) THEN
--
          -- �V�K�C���t���O
          IF ( gt_chk_supply_tbl(i).notif_status = cv_deci_noti ) THEN
            --�ʒm�X�e�[�^�X���m��ʒm�� �̏ꍇ�F�C��
            lv_new_modify_flg := cv_amend;
          ELSIF (( gt_chk_supply_tbl(i).prev_notif_status = cv_deci_noti ) 
            AND  ( gt_chk_supply_tbl(i).notif_status      = cv_re_noti )) THEN
            --�O��ʒm�X�e�[�^�X���m��ʒm�� ����
            --  �ʒm�X�e�[�^�X���Ēʒm�v�̏ꍇ�F�C��
            lv_new_modify_flg := cv_amend;
          ELSIF ( gt_chk_supply_tbl(i).notif_status = cv_not_noti ) THEN
            --�ʒm�X�e�[�^�X�����ʒm�̏ꍇ�F�V�K
            lv_new_modify_flg := cv_new;
          ELSE
            --��L�ȊO�̓G���[
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_new_modify_err,
                                                  cv_tkn_biz_type,   cv_tkn_supl_char,
                                                  cv_tkn_req_mov_no, gt_chk_supply_tbl(i).request_no
                                                  );
            RETURN cv_career_cancel_err;                          -- �V�K�C���t���O�G���[
          END IF;
--
--
          -- �󒍃w�b�_�A�h�I���X�V����
          UPDATE xxwsh_order_headers_all            xoha          -- �󒍃w�b�_�A�h�I��
          SET    xoha.prev_notif_status             =             -- �O��ʒm�X�e�[�^�X
                 (CASE                                                    -- �ǉ�
                   WHEN (xoha.notif_status = cv_deci_noti) THEN           -- �ǉ�
                     xoha.notif_status                                    -- �ǉ�
                   ELSE                                                   -- �ǉ�
                     xoha.prev_notif_status                               -- �ǉ�
                 END),                                                    -- �ǉ�
                 xoha.notif_status                  =                     -- �ʒm�X�e�[�^�X
                 (CASE
                   WHEN (xoha.notif_status = cv_deci_noti) THEN
                     cv_re_noti
                   --WHEN (xoha.notif_status = cv_not_noti) THEN
                   --  cv_not_noti
                   ELSE                                                   -- �ǉ�
                     xoha.notif_status                                    -- �ǉ�
                 END),
                 xoha.notif_date                    =  NULL,              -- �m��ʒm���{����
                 --xoha.new_modify_flg                =                     -- �V�K�C���t���O
                 --(CASE
                 --  WHEN (xoha.notif_status = cv_deci_noti) THEN
                 --    cv_amend
                 --  WHEN ((xoha.prev_notif_status = cv_deci_noti) AND
                 --         (xoha.notif_status = cv_re_noti)) THEN
                 --    cv_amend
                 --  WHEN (xoha.notif_status = cv_not_noti) THEN
                 --    cv_new
                 --END),
                 xoha.new_modify_flg                =  lv_new_modify_flg,    -- �V�K�C���t���O
                 xoha.last_updated_by               =  ln_user_id,
                 xoha.last_update_date              =  ld_sysdate,
                 xoha.last_update_login             =  ln_login_id,
                 xoha.request_id                    =  ln_conc_request_id,
                 xoha.program_application_id        =  ln_prog_appl_id,
                 xoha.program_id                    =  ln_conc_program_id,
                 xoha.program_update_date           =  ld_sysdate
          WHERE  xoha.order_header_id               =  gt_chk_supply_tbl(i).order_header_id;
--
        END IF;
--
      END LOOP gt_chk_supply_tbl_loop;
--
-- Ver1.20 M.Hokkanji START
      END IF;
      IF (gt_chk_move_tbl.COUNT > 0) THEN
--    ELSIF (gt_chk_move_tbl.COUNT > 0) THEN
-- Ver1.20 M.Hokkanji END
      -- �擾�������R�[�h�̕��������[�v
      <<gt_chk_move_tbl_loop>>
      FOR i IN gt_chk_move_tbl.FIRST .. gt_chk_move_tbl.LAST LOOP
--
        -- �ړ��w�b�_ID���O�̃��R�[�h�Ɠ����łȂ��ꍇ
        IF ((i = gt_chk_move_tbl.FIRST) OR
             (gt_chk_move_tbl(i).mov_hdr_id
               <> gt_chk_move_tbl(i - 1).mov_hdr_id)) THEN
--
          -- �V�K�C���t���O
          IF ( gt_chk_move_tbl(i).notif_status = cv_deci_noti ) THEN
            --�ʒm�X�e�[�^�X���m��ʒm�� �̏ꍇ�F�C��
            lv_new_modify_flg := cv_amend;
          ELSIF (( gt_chk_move_tbl(i).prev_notif_status = cv_deci_noti ) 
            AND  ( gt_chk_move_tbl(i).notif_status      = cv_re_noti )) THEN
            --�O��ʒm�X�e�[�^�X���m��ʒm�� ����
            --  �ʒm�X�e�[�^�X���Ēʒm�v�̏ꍇ�F�C��
            lv_new_modify_flg := cv_amend;
          ELSIF ( gt_chk_move_tbl(i).notif_status = cv_not_noti ) THEN
            --�ʒm�X�e�[�^�X�����ʒm�̏ꍇ�F�V�K
            lv_new_modify_flg := cv_new;
          ELSE
            --��L�ȊO�̓G���[
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_new_modify_err,
                                                  cv_tkn_biz_type,   cv_tkn_move_char,
                                                  cv_tkn_req_mov_no, gt_chk_move_tbl(i).mov_num
                                                  );
            RETURN cv_career_cancel_err;                          -- �V�K�C���t���O�G���[
          END IF;
--
          -- �ړ��˗�/�w���w�b�_(�A�h�I��)�X�V����
          UPDATE xxinv_mov_req_instr_headers        mrih       -- �ړ��˗�/�w���w�b�_(�A�h�I��)
          --SET    mrih.prev_notif_status             =  mrih.notif_status, -- �O��ʒm�X�e�[�^�X
          --       mrih.notif_status                  =                     -- �ʒm�X�e�[�^�X
          --       (CASE
          --         WHEN (mrih.notif_status = cv_deci_noti) THEN
          --           cv_re_noti
          --         WHEN (mrih.notif_status = cv_not_noti) THEN
          --           cv_not_noti
          --       END),
          SET    mrih.prev_notif_status             =             -- �O��ʒm�X�e�[�^�X
                 (CASE                                                    -- �ǉ�
                   WHEN (mrih.notif_status = cv_deci_noti) THEN           -- �ǉ�
                     mrih.notif_status                                    -- �ǉ�
                   ELSE                                                   -- �ǉ�
                     mrih.prev_notif_status                               -- �ǉ�
                 END),                                                    -- �ǉ�
                 mrih.notif_status                  =                     -- �ʒm�X�e�[�^�X
                 (CASE
                   WHEN (mrih.notif_status = cv_deci_noti) THEN
                     cv_re_noti
                   ELSE                                                   -- �ǉ�
                     mrih.notif_status                                    -- �ǉ�
                 END),
                 mrih.notif_date                    =  NULL,              -- �m��ʒm���{����
                 --mrih.new_modify_flg                =                     -- �V�K�C���t���O
                 --(CASE
                 --  WHEN (mrih.notif_status = cv_deci_noti) THEN
                 --    cv_amend
                 --  WHEN ((mrih.prev_notif_status = cv_deci_noti) AND
                 --         (mrih.notif_status = cv_re_noti)) THEN
                 --    cv_amend
                 --  WHEN (mrih.notif_status = cv_not_noti) THEN
                 --    cv_new
                 --END),
                 mrih.new_modify_flg                =  lv_new_modify_flg,    -- �V�K�C���t���O
                 mrih.last_updated_by               =  ln_user_id,
                 mrih.last_update_date              =  ld_sysdate,
                 mrih.last_update_login             =  ln_login_id,
                 mrih.request_id                    =  ln_conc_request_id,
                 mrih.program_application_id        =  ln_prog_appl_id,
                 mrih.program_id                    =  ln_conc_program_id,
                 mrih.program_update_date           =  ld_sysdate
          WHERE  mrih.mov_hdr_id                    =  gt_chk_move_tbl(i).mov_hdr_id;
--
        END IF;
--
      END LOOP gt_chk_move_tbl_loop;
--
    END IF;
--
    -- ����I��
    RETURN cv_compl;
--
  EXCEPTION 
    WHEN lock_expt THEN
      -- ���b�N�����G���[
      ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_lock_err);
      RETURN cv_career_cancel_err;                             -- �z�ԉ������s
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END cancel_careers_schedule;
--
END xxwsh_common_pkg;
/
