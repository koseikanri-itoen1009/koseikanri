CREATE OR REPLACE PACKAGE xxwsh_common910_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh_common910_pkg(spec)
 * Description      : ���Y�������ʁi�o�ׁE�ړ��`�F�b�N�j
 * MD.050           : ���Y�������ʁi�o�ׁE�ړ��`�F�b�N�jT_MD050_BPO_910
 * MD.070           : �Ȃ�
 * Version          : 1.14
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  calc_total_value       P         B.�ύڌ����`�F�b�N(���v�l�Z�o)
 *  calc_load_efficiency   P         C.�ύڌ����`�F�b�N(�ύڌ����Z�o)
 *  check_lot_reversal     P         D.���b�g�t�]�h�~�`�F�b�N
 *  check_fresh_condition  P         E.�N�x�����`�F�b�N
 *  calc_lead_time         P         F.���[�h�^�C���Z�o
 *  check_shipping_judgment
 *                         P         G.�o�׉ۃ`�F�b�N
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/13    1.0   ORACLE�Γn���a   �V�K�쐬
 *  2008/05/19    1.1   ORACLE�Γn���a   ���b�Z�[�W�C��
 *  2008/05/23    1.2   ORACLE�k�������v �N�x�����`�F�b�N��OTHERS��O�����R�[�h��
 *                                       global_api_others_expt�ɕύX
 *                                       �N�x�����`�F�b�N�̓��̓p�����[�^�����b�gNo����
 *                                       ���b�gID�ɕύX
 *  2008/05/24    1.3   ORACLE�k�������v �N�x�����`�F�b�N�̑N�x�����敪�̃G���[�`�F�b�N��
 *                                       NULL�̏ꍇ��ǉ��B
 *                                       �N�x�����敪����ʂ̏ꍇ�A�ܖ��������Z�b�g�����
 *                                       ���Ȃ��ꍇ�A�G���[�Ƃ���悤�ɏC��
 *  2008/05/28   1.4   ORACLE�Γn���a   [���b�g�t�]�h�~�`�F�b�N]
 *                                      �ړ����b�g�ڍׂ̃��R�[�h�^�C�v�l���C��
 *  2008/05/30   1.5   ORACLE�Ŗ����\   �����ύX�v��#116�Ή�
 *  2008/06/02   1.6   ORACLE�Γn���a   [�o�׉ۃ`�F�b�N] �t�H�[�L���X�g�̒��o�����ύX
 *                                      [�ύڌ����`�F�b�N(�ύڌ����Z�o)]���o��������
 *  2008/06/13   1.7   ORACLE�Γn���a   [���b�g�t�]�h�~�`�F�b�N] �ړ��w���̒���������ύX
 *  2008/06/19   1.8   ORACLE�R����_   �����ύX�v��No143�Ή�
 *  2008/06/26   1.9   ORACLE�Γn���a   [�o�׉ۃ`�F�b�N] �ړ��w���̒���������ύX
 *  2008/07/08   1.10  ORACLE�Ŗ����\   [�o�׉ۃ`�F�b�N] ST�s�#405�Ή�
 *  2008/07/14   1.11  ORACLE���c����   [�ύڌ����`�F�b�N(�ύڌ����Z�o)] �ύX�v���Ή�#95
 *  2008/07/17   1.12  ORACLE���c����   [�ύڌ����`�F�b�N(�ύڌ����Z�o)] �ύX�v���Ή�#95�̃o�O�Ή�
 *  2008/07/30   1.13  ORACLE���R�m��   [�o�׉ۃ`�F�b�N]�����ύX�v��#182�Ή�
 *  2008/08/04   1.14  ORACLE�ɓ��ЂƂ� [�ύڌ����`�F�b�N(�ύڌ����Z�o)] �ύX�v���Ή�#95�̃o�O�Ή�
 *  2008/08/06   1.14  ORACLE�ɓ��ЂƂ� [�ύڌ����`�F�b�N(�ύڌ����Z�o)] �ύX�v���Ή�#164�Ή�
 *****************************************************************************************/
--
--
  -- �ύڌ����`�F�b�N(���v�l�Z�o)
  PROCEDURE calc_total_value(
    iv_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE,                       -- 1.�i�ڃR�[�h
    in_quantity                   IN  NUMBER,                                              -- 2.����
    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 3.���^�[���R�[�h
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 4.�G���[���b�Z�[�W�R�[�h
    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 5.�G���[���b�Z�[�W
    on_sum_weight                 OUT NOCOPY NUMBER,                                       -- 6.���v�d��
    on_sum_capacity               OUT NOCOPY NUMBER,                                       -- 7.���v�e��
    on_sum_pallet_weight          OUT NOCOPY NUMBER);                                      -- 8.���v�p���b�g�d��
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
END xxwsh_common910_pkg;
/
