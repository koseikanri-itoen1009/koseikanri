create or replace PACKAGE xxwsh_common910_pkg_pt
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh_common910_pkg_pt(spec)
 * Description      : ���Y�������ʁi�o�ׁE�ړ��`�F�b�N�j
 * MD.050           : ���Y�������ʁi�o�ׁE�ړ��`�F�b�N�jT_MD050_BPO_910
 * MD.070           : �Ȃ�
 * Version          : 1.39
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  calc_total_value       P         B.�ύڌ����`�F�b�N(���v�l�Z�o)
 *  calc_load_efficiency   P         C.�ύڌ����`�F�b�N(�ύڌ����Z�o)
 *  check_lot_reversal     P         D.���b�g�t�]�h�~�`�F�b�N
 *  check_lot_reversal2    P         D.���b�g�t�]�h�~�`�F�b�N(�˗�No�w�肠��)
 *  check_fresh_condition  P         E.�N�x�����`�F�b�N
 *  get_fresh_pass_date    P         E.�N�x�������i�������擾
 *  calc_lead_time         P         F.���[�h�^�C���Z�o
 *  check_shipping_judgment
 *                         P         G.�o�׉ۃ`�F�b�N
 *
 * Change Record
 * ------------ ----- ---------------- -------------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -------------------------------------------------
 *  2016/11/25   1.39  SCSK  �ː��a�K   [�[�i�N�x�Ǘ�����] E_�{�ғ�_09591�Ή�
 *  2016/11/28                          ��L�Ή�PT�p���W���[��
 *****************************************************************************************/
--
-- 2008/10/06 H.Itou Del Start �����e�X�g�w�E240
--  -- �ύڌ����`�F�b�N(���v�l�Z�o)
--  PROCEDURE calc_total_value(
--    iv_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE,                       -- 1.�i�ڃR�[�h
--    in_quantity                   IN  NUMBER,                                              -- 2.����
--    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 3.���^�[���R�[�h
--    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 4.�G���[���b�Z�[�W�R�[�h
--    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 5.�G���[���b�Z�[�W
--    on_sum_weight                 OUT NOCOPY NUMBER,                                       -- 6.���v�d��
--    on_sum_capacity               OUT NOCOPY NUMBER,                                       -- 7.���v�e��
--    on_sum_pallet_weight          OUT NOCOPY NUMBER                                        -- 8.���v�p���b�g�d��
--    );
-- 2008/10/06 H.Itou Del End
--
-- 2008/10/06 H.Itou Add Start �����e�X�g�w�E240��l����
  -- �ύڌ����`�F�b�N(���v�l�Z�o)
  PROCEDURE calc_total_value(
    iv_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE,                       -- 1.�i�ڃR�[�h
    in_quantity                   IN  NUMBER,                                              -- 2.����
    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 3.���^�[���R�[�h
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 4.�G���[���b�Z�[�W�R�[�h
    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 5.�G���[���b�Z�[�W
    on_sum_weight                 OUT NOCOPY NUMBER,                                       -- 6.���v�d��
    on_sum_capacity               OUT NOCOPY NUMBER,                                       -- 7.���v�e��
    on_sum_pallet_weight          OUT NOCOPY NUMBER,                                       -- 8.���v�p���b�g�d��
    id_standard_date              IN  DATE                                                 -- 9.���(�K�p�����)
    );
-- 2008/10/06 H.Itou Add End
--
-- 2008/11/12 H.Itou Add Start �����e�X�g�w�E311 �w��/���ы敪����
  -- �ύڌ����`�F�b�N(���v�l�Z�o)
  PROCEDURE calc_total_value(
    iv_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE,                       -- 1.�i�ڃR�[�h
    in_quantity                   IN  NUMBER,                                              -- 2.����
    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 3.���^�[���R�[�h
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 4.�G���[���b�Z�[�W�R�[�h
    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 5.�G���[���b�Z�[�W
    on_sum_weight                 OUT NOCOPY NUMBER,                                       -- 6.���v�d��
    on_sum_capacity               OUT NOCOPY NUMBER,                                       -- 7.���v�e��
    on_sum_pallet_weight          OUT NOCOPY NUMBER,                                       -- 8.���v�p���b�g�d��
    id_standard_date              IN  DATE,                                                -- 9.���(�K�p�����)
    iv_mode                       IN  VARCHAR2                                             -- 10.�w��/���ы敪 1:�w�� 2:����
    );
-- 2008/11/12 H.Itou Add End
--
  -- �ύڌ����`�F�b�N(�ύڌ����Z�o)
  PROCEDURE calc_load_efficiency(
    in_sum_weight                 IN  NUMBER,                                              -- 1.���v�d��
    in_sum_capacity               IN  NUMBER,                                              -- 2.���v�e��
    iv_code_class1                IN  xxcmn_ship_methods.code_class1%TYPE,                 -- 3.�R�[�h�敪�P
    iv_entering_despatching_code1 IN  xxcmn_ship_methods.entering_despatching_code1%TYPE,  -- 4.���o�ɏꏊ�R�[�h�P
    iv_code_class2                IN  xxcmn_ship_methods.code_class2%TYPE,                 -- 5.�R�[�h�敪�Q
    iv_entering_despatching_code2 IN  xxcmn_ship_methods.entering_despatching_code2%TYPE,  -- 6.���o�ɏꏊ�R�[�h�Q
    iv_ship_method                IN  xxcmn_ship_methods.ship_method%TYPE,                 -- 7.�o�ו��@
    iv_prod_class                 IN  xxcmn_item_categories_v.segment1%TYPE,               -- 8.���i�敪
    iv_auto_process_type          IN  VARCHAR2,                                            -- 9.�����z�ԑΏۋ敪
    id_standard_date              IN  DATE  DEFAULT SYSDATE,                               -- 10.���(�K�p�����)
    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 11.���^�[���R�[�h
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 12.�G���[���b�Z�[�W�R�[�h
    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 13.�G���[���b�Z�[�W
    ov_loading_over_class         OUT NOCOPY VARCHAR2,                                     -- 14.�ύڃI�[�o�[�敪
    ov_ship_methods               OUT NOCOPY xxcmn_ship_methods.ship_method%TYPE,          -- 15.�o�ו��@
    on_load_efficiency_weight     OUT NOCOPY NUMBER,                                       -- 16.�d�ʐύڌ���
    on_load_efficiency_capacity   OUT NOCOPY NUMBER,                                       -- 17.�e�ϐύڌ���
    ov_mixed_ship_method          OUT NOCOPY VARCHAR2);                                    -- 18.���ڔz���敪
--
  -- ���b�g�t�]�h�~�`�F�b�N
  PROCEDURE check_lot_reversal(
    iv_lot_biz_class              IN  VARCHAR2,                                            -- 1.���b�g�t�]�������
    iv_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE,                       -- 2.�i�ڃR�[�h
    iv_lot_no                     IN  ic_lots_mst.lot_no%TYPE,                             -- 3.���b�gNo
    iv_move_to_id                 IN  NUMBER,                                              -- 4.�z����ID/�����T�C�gID/���ɐ�ID
    iv_arrival_date               IN  DATE,                                                -- 5.����
    id_standard_date              IN  DATE  DEFAULT SYSDATE,                               -- 6.���(�K�p�����)
    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 7.���^�[���R�[�h
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 8.�G���[���b�Z�[�W�R�[�h
    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 9.�G���[���b�Z�[�W
    on_result                     OUT NOCOPY NUMBER,                                       -- 10.��������
    on_reversal_date              OUT NOCOPY DATE);                                        -- 11.�t�]���t
--
-- 2009/01/22 H.Itou Add Start �{��#1000�Ή�
  -- ���b�g�t�]�h�~�`�F�b�N(�˗�No�w�肠��)
  PROCEDURE check_lot_reversal2(
    iv_lot_biz_class              IN  VARCHAR2,                                            -- 1.���b�g�t�]�������
    iv_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE,                       -- 2.�i�ڃR�[�h
    iv_lot_no                     IN  ic_lots_mst.lot_no%TYPE,                             -- 3.���b�gNo
    iv_move_to_id                 IN  NUMBER,                                              -- 4.�z����ID/�����T�C�gID/���ɐ�ID
    iv_arrival_date               IN  DATE,                                                -- 5.����
    id_standard_date              IN  DATE  DEFAULT SYSDATE,                               -- 6.���(�K�p�����)
    iv_request_no                 IN  xxwsh_order_headers_all.request_no%TYPE,             -- 7.�˗�No
    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 8.���^�[���R�[�h
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 9.�G���[���b�Z�[�W�R�[�h
    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 10.�G���[���b�Z�[�W
    on_result                     OUT NOCOPY NUMBER,                                       -- 11.��������
    on_reversal_date              OUT NOCOPY DATE);                                        -- 12.�t�]���t
-- 2009/01/22 H.Itou Add End
  -- �N�x�����`�F�b�N
  PROCEDURE check_fresh_condition(
    iv_move_to_id                 IN  NUMBER,                                              -- 1.�z����ID
    iv_lot_id                     IN  ic_lots_mst.lot_id%TYPE,                             -- 2.���b�gId
    iv_arrival_date               IN  DATE,                                                -- 3.���ד�
    id_standard_date              IN  DATE  DEFAULT SYSDATE,                               -- 4.���(�K�p�����)
    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 5.���^�[���R�[�h
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 6.�G���[���b�Z�[�W�R�[�h
    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 7.�G���[���b�Z�[�W
    on_result                     OUT NOCOPY NUMBER,                                       -- 8.��������
    od_standard_date              OUT NOCOPY DATE                                          -- 9.����t
  );
--
-- 2009/01/23 H.Itou Add Start �{��#936�Ή�
   -- �N�x�������i�������擾
  PROCEDURE get_fresh_pass_date(
    it_move_to_id                 IN  NUMBER                         -- 1.�z����
   ,it_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE  -- 2.�i�ڃR�[�h
   ,id_arrival_date               IN  DATE                           -- 3.���ח\���
   ,id_standard_date              IN  DATE   DEFAULT SYSDATE         -- 4.���(�K�p�����)
   ,od_manufacture_date           OUT NOCOPY DATE                    -- 5.�N�x�������i������
   ,ov_retcode                    OUT NOCOPY VARCHAR2                -- 6.���^�[���R�[�h
   ,ov_errmsg                     OUT NOCOPY VARCHAR2                -- 8.�G���[���b�Z�[�W
  );
-- 2009/01/23 H.Itou Add End
--
  -- ���[�h�^�C���Z�o
  PROCEDURE calc_lead_time(
    iv_code_class1                IN  xxcmn_ship_methods.code_class1%TYPE,                 -- 1.�R�[�h�敪FROM
    iv_entering_despatching_code1 IN  xxcmn_ship_methods.entering_despatching_code1%TYPE,  -- 2.���o�ɏꏊ�R�[�hFROM
    iv_code_class2                IN  xxcmn_ship_methods.code_class2%TYPE,                 -- 3.�R�[�h�敪TO
    iv_entering_despatching_code2 IN  xxcmn_ship_methods.entering_despatching_code2%TYPE,  -- 4.���o�ɏꏊ�R�[�hTO
    iv_prod_class                 IN  xxcmn_item_categories_v.segment1%TYPE,               -- 5.���i�敪
    in_transaction_type_id        IN  xxwsh_oe_transaction_types_v.transaction_type_id%type, -- 6.�o�Ɍ`��ID
    id_standard_date              IN  DATE  DEFAULT SYSDATE,                               -- 7.���(�K�p�����)
    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 8.���^�[���R�[�h
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 9.�G���[���b�Z�[�W�R�[�h
    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 10.�G���[���b�Z�[�W
    on_lead_time                  OUT NOCOPY NUMBER,                                       -- 11.���Y����LT�^����ύXLT
    on_delivery_lt                OUT NOCOPY NUMBER                                        -- 12.�z��LT
  );
--
  -- �o�׉ۃ`�F�b�N
  PROCEDURE check_shipping_judgment(
    iv_check_class                IN  VARCHAR2,                                            -- 1.�`�F�b�N���@�敪
    iv_base_cd                    IN  VARCHAR2,                                            -- 2.���_CD
    in_item_id                    IN  xxcmn_item_mst_v.inventory_item_id%TYPE,             -- 3.�i��ID
    in_amount                     IN  NUMBER,                                              -- 4.����
    id_date                       IN  DATE,                                                -- 5.�Ώۓ��t
    in_deliver_from_id            IN  NUMBER,                                              -- 6.�o�׌�ID
    iv_request_no                 IN  VARCHAR2,                                            -- 7.�˗�No
    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 8.���^�[���R�[�h
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 9.�G���[���b�Z�[�W�R�[�h
    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 10.�G���[���b�Z�[�W
    on_result                     OUT NOCOPY NUMBER                                        -- 11.��������
  );
--
END xxwsh_common910_pkg_pt;
/
