CREATE OR REPLACE PACKAGE xxpo_common925_pkg 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo_common925_pkg(spec)
 * Description      : ���ʊ֐�
 * MD.050/070       : �x���w������̔��������쐬 Issue1.0  (T_MD050_BPO_925)
 * Version          : 1.0
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
 *
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
