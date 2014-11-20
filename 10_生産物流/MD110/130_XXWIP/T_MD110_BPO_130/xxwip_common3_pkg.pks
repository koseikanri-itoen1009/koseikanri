create or replace PACKAGE xxwip_common3_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwip_common3_pkg(SPEC)
 * Description            : ���ʊ֐�(XXWIP)(SPEC)
 * MD.070(CMD.050)        : �Ȃ�
 * Version                : 1.4
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  check_lastmonth_close   P        �O���^������`�F�b�N
 *  get_ship_method         P        �z���敪���VIEW���o
 *  get_delivery_distance   P        �z�������A�h�I���}�X�^���o 
 *  get_delivery_company    P        �^���p�^���Ǝ҃A�h�I���}�X�^���o
 *  get_delivery_charges    P        �^���A�h�I���}�X�^���o
 *  get_deliverys_ctrl      P        �^���v�Z�p�R���g���[�����o
 *  update_deliverys_ctrl   P        �^���v�Z�p�R���g���[���X�V
 *  change_code_division    P        �^���R�[�h�敪�ϊ�
 *  deliv_rcv_ship_conv_qty F   NUM  �^�����o�Ɋ��Z�֐�
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/02/20  1.0    M.Nomura        �V�K�쐬
 *  2008/03/18  1.1    M.Nomura        �^���v�Z�p �ǉ�
 *  2008/07/17  1.2    M.Nomura        �ύX�v��#96�A#98�Ή��E�����ۑ�32�Ή�
 *  2008/10/01  1.3    Y.Kawano        �����ύX#220,T_S_500�Ή�
 *  2008/11/27  1.4    D.Nihei         �{�ԏ�Q#173�Ή�
 *
 *****************************************************************************************/
--
--
  -- ===============================
  -- �O���[�o���^
  -- ===============================
--
  -- **************************************************
  -- �z���敪���VIEW���o
  -- **************************************************
  -- �z���敪���VIEW�擾�pPL/SQL�\�^
  TYPE ship_method_rec IS RECORD(
      small_amount_class  xxwsh_ship_method2_v.small_amount_class%TYPE -- �����敪
    , mixed_class         xxwsh_ship_method2_v.mixed_class%TYPE        -- ���ڋ敪
  );
--
  -- **************************************************
  -- �z�������A�h�I���}�X�^���o
  -- **************************************************
  -- �z�������A�h�I���}�X�^���o�擾�pPL/SQL�\�^
  TYPE delivery_distance_rec IS RECORD(
      post_distance         xxwip_delivery_distance.post_distance%TYPE          -- �ԗ�����
    , small_distance        xxwip_delivery_distance.small_distance%TYPE         -- ��������
    , consolid_add_distance xxwip_delivery_distance.consolid_add_distance%TYPE  -- ���ڊ�������
    , actual_distance       xxwip_delivery_distance.actual_distance%TYPE        -- ���ۋ���
  );
--
  -- **************************************************
  -- �^���p�^���Ǝ҃A�h�I���}�X�^���o
  -- **************************************************
  -- �^���p�^���Ǝ҃A�h�I���}�X�^���o�擾�pPL/SQL�\�^
  TYPE delivery_company_rec IS RECORD(
      small_weight          xxwip_delivery_company.small_weight%TYPE         -- �����d��
    , pay_picking_amount    xxwip_delivery_company.pay_picking_amount%TYPE   -- �x���s�b�L���O�P��
    , bill_picking_amount   xxwip_delivery_company.bill_picking_amount%TYPE  -- �����s�b�L���O�P��
  );
--
  -- **************************************************
  -- �^���A�h�I���}�X�^���o
  -- **************************************************
  -- �^���A�h�I���}�X�^���o�擾�pPL/SQL�\�^
  TYPE delivery_charges_rec IS RECORD(
      shipping_expenses   xxwip_delivery_charges.shipping_expenses%TYPE   -- �^����
    , leaf_consolid_add   xxwip_delivery_charges.leaf_consolid_add%TYPE   -- ���[�t���ڊ���
  );
--
  -- ********** ���� �萔 **********
--
  -- ===============================
  -- �v���V�[�W������уt�@���N�V����
  -- ===============================
--
  -- �O���^������`�F�b�N
  PROCEDURE check_lastmonth_close(
    ov_close_type   OUT NOCOPY VARCHAR2,           -- ���ߋ敪�iY�F���ߑO�AN�F���ߌ�j
    ov_errbuf       OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2);   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �z���敪���VIEW���o
  PROCEDURE get_ship_method(
    iv_ship_method_code IN  xxwsh_ship_method2_v.ship_method_code%TYPE,           -- �z���敪
    id_target_date      IN  DATE,                                                 -- ���f��
    or_dlvry_dstn       OUT ship_method_rec,                                      -- �z���敪���R�[�h
    ov_errbuf           OUT NOCOPY  VARCHAR2,    -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode          OUT NOCOPY  VARCHAR2,    -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg           OUT NOCOPY  VARCHAR2);   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
--
  -- �z�������A�h�I���}�X�^���o
  PROCEDURE get_delivery_distance(
    iv_goods_classe           IN  xxwip_delivery_distance.goods_classe%TYPE,          -- ���i�敪
    iv_delivery_company_code  IN  xxwip_delivery_distance.delivery_company_code%TYPE, -- �^���Ǝ�
    iv_origin_shipment        IN  xxwip_delivery_distance.origin_shipment%TYPE,       -- �o�ɑq��
    iv_code_division          IN  xxwip_delivery_distance.code_division%TYPE,         -- �R�[�h�敪
    iv_shipping_address_code  IN  xxwip_delivery_distance.shipping_address_code%TYPE, -- �z����R�[�h
    id_target_date            IN  DATE,                                               -- ���f��
    or_delivery_distance      OUT delivery_distance_rec,                              -- �z���������R�[�h
    ov_errbuf                 OUT NOCOPY  VARCHAR2,    -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode                OUT NOCOPY  VARCHAR2,    -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg                 OUT NOCOPY  VARCHAR2);   -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
--
  -- �^���p�^���Ǝ҃A�h�I���}�X�^���o
  PROCEDURE get_delivery_company(
    iv_goods_classe           IN  xxwip_delivery_company.goods_classe%TYPE,           -- ���i�敪
    iv_delivery_company_code  IN  xxwip_delivery_company.delivery_company_code%TYPE,  -- �^���Ǝ�
    id_target_date            IN  DATE,                                               -- ���f��
    or_delivery_company       OUT delivery_company_rec,                               -- �^���p�^���Ǝ҃��R�[�h
    ov_errbuf                 OUT NOCOPY  VARCHAR2,    -- �G���[�E���b�Z�[�W          --# �Œ� #
    ov_retcode                OUT NOCOPY  VARCHAR2,    -- ���^�[���E�R�[�h            --# �Œ� #
    ov_errmsg                 OUT NOCOPY  VARCHAR2);   -- ���[�U�[�E�G���[�E���b�Z�[�W--# �Œ� #
--
  -- �^���A�h�I���}�X�^���o
  PROCEDURE get_delivery_charges(
    iv_p_b_classe               IN  xxwip_delivery_charges.p_b_classe%TYPE,             -- �x�������敪
    iv_goods_classe             IN  xxwip_delivery_charges.goods_classe%TYPE,           -- ���i�敪
    iv_delivery_company_code    IN  xxwip_delivery_charges.delivery_company_code%TYPE,  -- �^���Ǝ�
    iv_shipping_address_classe  IN  xxwip_delivery_charges.shipping_address_classe%TYPE,-- �z���敪
    iv_delivery_distance        IN  xxwip_delivery_charges.delivery_distance%TYPE,      -- �^������
    iv_delivery_weight          IN  xxwip_delivery_charges.delivery_weight%TYPE,        -- �d��
    id_target_date              IN  DATE,                                               -- ���f��
    or_delivery_charges         OUT delivery_charges_rec,                               -- �^���A�h�I�����R�[�h
    ov_errbuf                   OUT NOCOPY  VARCHAR2,    -- �G���[�E���b�Z�[�W          --# �Œ� #
    ov_retcode                  OUT NOCOPY  VARCHAR2,    -- ���^�[���E�R�[�h            --# �Œ� #
    ov_errmsg                   OUT NOCOPY  VARCHAR2);   -- ���[�U�[�E�G���[�E���b�Z�[�W--# �Œ� #
--
  -- �^���R�[�h�敪�ϊ�
  PROCEDURE change_code_division(
    iv_deliver_to_code_class  IN  xxwsh_carriers_schedule.deliver_to_code_class%TYPE, -- �z����R�[�h�敪
    od_code_division          OUT xxwip_delivery_distance.code_division%TYPE,         -- �R�[�h�敪�i�^���p�j
    ov_errbuf                 OUT NOCOPY  VARCHAR2,    -- �G���[�E���b�Z�[�W          --# �Œ� #
    ov_retcode                OUT NOCOPY  VARCHAR2,    -- ���^�[���E�R�[�h            --# �Œ� #
    ov_errmsg                 OUT NOCOPY  VARCHAR2);   -- ���[�U�[�E�G���[�E���b�Z�[�W--# �Œ� #
--
  -- �^�����o�Ɋ��Z�֐�
  FUNCTION deliv_rcv_ship_conv_qty(
    in_item_cd    IN VARCHAR2,          -- �i�ڃR�[�h
    in_qty        IN NUMBER)            -- �ϊ��Ώۂ̐���
    RETURN NUMBER;                      -- �ϊ����ʂ̐���
--
END xxwip_common3_pkg;
/
