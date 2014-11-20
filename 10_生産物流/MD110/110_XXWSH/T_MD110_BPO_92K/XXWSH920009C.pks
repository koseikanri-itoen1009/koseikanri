create or replace
PACKAGE XXWSH920009C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920009C(spec)
 * Description      : ���������������b�N�Ή�
 * MD.050           : 
 * MD.070           : 
 * Version          : 0.9
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 ���C���֐�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/01   1.0   T.MIYATA        ����쐬
 *
 *****************************************************************************************/
--
  -- ���C���֐�
  PROCEDURE main(
      errbuf                OUT NOCOPY  VARCHAR2         --   �G���[���b�Z�[�W
     ,retcode               OUT NOCOPY   VARCHAR2         --   �G���[�R�[�h
     ,iv_item_class         IN     VARCHAR2         -- 1.���i�敪
     ,iv_action_type        IN     VARCHAR2         -- 2.�������
     ,iv_block1             IN     VARCHAR2         -- 3.�u���b�N�P
     ,iv_block2             IN     VARCHAR2         -- 4.�u���b�N�Q
     ,iv_block3             IN     VARCHAR2         -- 5.�u���b�N�R
     ,iv_deliver_from_id    IN     VARCHAR2         -- 6.�o�Ɍ�
     ,iv_deliver_type       IN     VARCHAR2         -- 7.�o�Ɍ`��
     ,iv_deliver_date_from  IN     VARCHAR2         -- 8.�o�ɓ�From
     ,iv_deliver_date_to    IN     VARCHAR2         -- 9.�o�ɓ�To
    );
END XXWSH920009C;
/
