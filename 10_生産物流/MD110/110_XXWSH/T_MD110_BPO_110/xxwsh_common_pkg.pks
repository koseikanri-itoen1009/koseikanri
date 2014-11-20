CREATE OR REPLACE PACKAGE xxwsh_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwsh_common_pkg(SPEC)
 * Description            : ���ʊ֐�(SPEC)
 * MD.070(CMD.050)        : �Ȃ�
 * Version                : 1.23
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
 *  2008/08/20   1.20  Oracle �k�������v[�z�ԉ����֐�] T_3_569�Ή�   �e�w�b�_�ɍő�z���敪�A��{�d�ʁA��{�e�ς�ݒ肷��悤�ɕύX
 *                                                     TE_080_400�w�ENo77�Ή� �󒍃w�b�_�̍��ڌ�No���N���A���Ȃ��悤�ɕύX
 *                                                     �J���C�Â��Ή� ���_�z�Ԃ���������������Ȃ������C��
 *                                                                    �̈�܂����ō��ڂ����ꍇ�ɐ�������������Ȃ������C��
 *                                                                    �z�ԉ������̃G���[���b�Z�[�W���������o�͂���Ȃ������C��
 *  2008/08/28   1.21  Oracle �ɓ��ЂƂ�[�z�ԉ����֐�] PT 1-2_8 �w�E#32�Ή�
 *  2008/09/02   1.22  Oracle �k�������v[�z�ԉ����֐�] �����e�X�g���s��Ή�
 *  2008/09/03   1.23  Oracle �͖�D�q  [���������֐�] �����e�X�g�s��Ή� �ړ��F�������ׁE�������b�g�����Ή�
 *****************************************************************************************/
--
  -- ===============================
  -- �O���[�o���^
  -- ===============================
--
  -- ===============================
  -- �v���V�[�W������уt�@���N�V����
  -- ===============================
--
  -- �ő�z���敪�Z�o�֐�
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
    RETURN NUMBER;
--
  -- �ғ����Z�o�֐�
  FUNCTION get_oprtn_day(
    id_date             IN  DATE,         -- ���t
    iv_whse_code        IN  VARCHAR2,     -- �ۊǑq�ɃR�[�h
    iv_deliver_to_code  IN  VARCHAR2,     -- �z����R�[�h
    in_lead_time        IN  NUMBER,       -- ���[�h�^�C��
    iv_prod_class       IN  VARCHAR2,     -- ���i�敪
    od_oprtn_day        OUT NOCOPY DATE)  -- �ғ������t
    RETURN NUMBER;
--
  -- ����˗�No�����֐�
  FUNCTION get_same_request_number(
    iv_request_no          IN  xxwsh_order_headers_all.request_no%TYPE,       -- 1.�˗�No
    on_same_request_count  OUT NUMBER,                                        -- 2.����˗�No����
    on_order_header_id     OUT xxwsh_order_headers_all.ORDER_HEADER_ID%TYPE)  -- 3.����˗�No�̎󒍃w�b�_�A�h�I��ID
    RETURN NUMBER;
--
  -- �˗�No�R���o�[�g�֐�
  FUNCTION convert_request_number(
    iv_conv_div             IN  VARCHAR2,                                     -- 1.�ϊ��敪
    iv_pre_conv_request_no  IN  VARCHAR2,                                     -- 2.�ϊ��O�˗�No
    ov_aft_conv_request_no  OUT xxwsh_order_headers_all.request_no%TYPE)      -- 3.�ϊ���˗�No
    RETURN NUMBER;
--
  -- �ő�p���b�g�����Z�o�֐�
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
    RETURN NUMBER;
--
  -- ���߃X�e�[�^�X�`�F�b�N�֐�
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
    RETURN VARCHAR2;
--
  -- �d�ʗe�Ϗ������X�V�֐�
  FUNCTION update_line_items(
    iv_biz_type             IN  VARCHAR2,                                     -- 1.�Ɩ����
    iv_request_no           IN  VARCHAR2)                                     -- 2.�˗�No/�ړ��ԍ�
    RETURN NUMBER;
--
  -- ���������֐�
  FUNCTION cancel_reserve(
    iv_biz_type             IN         VARCHAR2,                              -- 1.�Ɩ����
    iv_request_no           IN         VARCHAR2,                              -- 2.�˗�No/�ړ��ԍ�
    in_line_id              IN         NUMBER,                                -- 3.����ID
    ov_errmsg               OUT NOCOPY VARCHAR2)                              -- 4.�G���[���b�Z�[�W
    RETURN VARCHAR2;
--
  -- �z�ԉ����֐�
  FUNCTION cancel_careers_schedule(
    iv_biz_type             IN         VARCHAR2,                              -- 1.�Ɩ����
    iv_request_no           IN         VARCHAR2,                              -- 2.�˗�No/�ړ��ԍ�
    ov_errmsg               OUT NOCOPY VARCHAR2)                              -- 3.�G���[���b�Z�[�W
    RETURN VARCHAR2;
--
END xxwsh_common_pkg;
/
