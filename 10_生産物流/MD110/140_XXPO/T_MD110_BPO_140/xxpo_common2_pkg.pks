CREATE OR REPLACE PACKAGE xxpo_common2_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxpo_common2_pkg(SPEC)
 * Description            : ���ʊ֐�(�L���x���p)(SPEC)
 * MD.070(CMD.050)        : �Ȃ�
 * Version                : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  update_order_data         F    N     �S�����o�� ���o�Ɏ��ѓo�^����
 *  get_unit_price            F    N     ���i�\�P���擾����
 *  update_order_unit_price   P    -     �󒍖��׃A�h�I���P���X�V����
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/03/12   1.0   D.Nihei         �V�K�쐬
 *
 *****************************************************************************************/
--
  -- �S�����o�� ���o�Ɏ��ѓo�^����
  FUNCTION update_order_data(
    in_order_header_id    IN  NUMBER         -- �󒍃w�b�_�A�h�I��ID
   ,iv_record_type_code   IN  VARCHAR2       -- ���R�[�h�^�C�v(20�F�o�Ɏ��сA30�F���Ɏ���)
   ,id_actual_date        IN  DATE           -- ���ѓ�(���ɓ��E�o�ɓ�)
   ,in_created_by         IN  NUMBER         -- �쐬��
   ,id_creation_date      IN  DATE           -- �쐬��
   ,in_last_updated_by    IN  NUMBER         -- �ŏI�X�V��
   ,id_last_update_date   IN  DATE           -- �ŏI�X�V��
   ,in_last_update_login  IN  NUMBER         -- �ŏI�X�V���O�C��
  ) 
  RETURN NUMBER;
--
  -- ���i�\�P���擾����
  FUNCTION get_unit_price(
    in_inventory_item_id  IN  NUMBER         -- INV�i��ID
   ,iv_list_id_vendor     IN  VARCHAR2       -- �����ʉ��i�\ID
   ,iv_list_id_represent  IN  VARCHAR2       -- ��\���i�\ID
   ,id_arrival_date       IN  DATE           -- �K�p��(���ɓ�)
  )
  RETURN NUMBER;
--
  -- �󒍖��׃A�h�I���P���X�V����
  PROCEDURE update_order_unit_price(
    in_order_header_id    IN  xxwsh_order_lines_all.order_header_id%TYPE     -- �󒍃w�b�_�A�h�I��ID
   ,iv_list_id_vendor     IN  VARCHAR2                                       -- �����ʉ��i�\ID
   ,iv_list_id_represent  IN  VARCHAR2                                       -- ��\���i�\ID
   ,id_arrival_date       IN  xxwsh_order_headers_all.arrival_date%TYPE      -- �K�p��(���ɓ�)
   ,iv_return_flag        IN  VARCHAR2                                       -- �ԕi�t���O
   ,iv_item_class_code    IN  xxcmn_item_categories2_v.segment1%TYPE         -- �i�ڋ敪
   ,iv_item_no            IN  xxcmn_item_categories2_v.item_no%TYPE          -- OPM�i�ڃR�[�h
   ,ov_retcode            OUT NOCOPY VARCHAR2                                -- �G���[�R�[�h
   ,ov_errmsg             OUT NOCOPY VARCHAR2                                -- �G���[���b�Z�[�W
   ,ov_system_msg         OUT NOCOPY VARCHAR2                                -- �V�X�e�����b�Z�[�W
  );
--
END xxpo_common2_pkg;
/
