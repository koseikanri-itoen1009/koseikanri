CREATE OR REPLACE PACKAGE xxpo_common925_pkg 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo_common925_pkg(spec)
 * Description      : ���ʊ֐�
 * MD.050/070       : �x���w������̔��������쐬 Issue1.0  (T_MD050_BPO_925)
 * Version          : 1.9
 *
 * Program List
 * ---------------------- ------------------------------------------------------------
 *  Name                   Description
 * ---------------------- ------------------------------------------------------------
 *  auto_purchase_orders   �x���w������̔��������쐬
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/12    1.0   M.Imazeki        �V�K�쐬
 *  2008/05/01    1.1   I.Higa           �w�E�����C��
 *                                        �EPO_HEADERS_INTERFACE�̐ݒ�l��ύX
 *                                        �EPO_LINES_INTERFACE�̐ݒ�l��ύX
 *  2008/05/07    1.2   M.Imazeki        �������쐬����(create_reserve_data)�ǉ�
 *  2008/05/22    1.3   Y.Majikina       �����w�b�_��Attribute1�ɐݒ�l��ύX
 *                                       �����w�b�_�i�A�h�I���j�ւ̓o�^��ǉ�
 *  2008/06/16    1.4   I.Higa           �w�E�����C��
 *                                        �E�]�ƈ��ԍ��̌^��NUMBER�^����TYPE�^�֕ύX
 *                                        �E�w�b�_�E�v�Ɏ󒍃w�b�_�A�h�I���̏o�׎w����ݒ�
 *  2008/07/03    1.5   I.Higa           ���ɗ\���(���ח\���)�𔭒��̔[�����ɂ��Ă��邪
 *                                       �o�ɗ\����𔭒��̔[�����Ƃ���悤�ɕύX����B
 *  2008/12/02    1.6   Y.Suzuki         PLSQL�\�������v���V�[�W���̒ǉ�
 *  2008/12/02    1.7   T.Yoshimoto      �{�ԏ�Q#377�Ή�
 *  2009/01/05    1.8   D.Nihei          �{�ԏ�Q#861�Ή�
 *  2009/02/25    1.9   D.Nihei          �{�ԏ�Q#1131�Ή�
 *****************************************************************************************/
--
  -- �x���w������̔��������쐬
  PROCEDURE auto_purchase_orders
    (
      iv_request_no         IN          VARCHAR2         --   01 : �˗�No
     ,ov_retcode            OUT NOCOPY  VARCHAR2         --  ���^�[���E�R�[�h
     ,on_batch_id           OUT NOCOPY  NUMBER           --  �o�b�`ID
     ,ov_errmsg_code        OUT NOCOPY  VARCHAR2         --  �G���[�E���b�Z�[�W�E�R�[�h
     ,ov_errmsg             OUT NOCOPY  VARCHAR2         --  ���[�U�[�E�G���[�E���b�Z�[�W
    ) ;
--
END xxpo_common925_pkg;
/
