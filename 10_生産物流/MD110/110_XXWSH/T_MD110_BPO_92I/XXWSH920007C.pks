CREATE OR REPLACE PACKAGE XXWSH920007C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920007C(spec)
 * Description      : ���Y����(�����A�z��)
 * MD.050           : �o�ׁE����/�z�ԁF���Y�������ʁi�o�ׁE�ړ��������j T_MD050_BPO_920
 * MD.070           : �o�ׁE����/�z�ԁF���Y�������ʁi�o�ׁE�ړ��������j T_MD070_BPO92I
 * Version          : 1.5
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 * main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/20   1.0   SCS �k����        �V�K�쐬
 *  2008/12/01   1.2   SCS �{�c          ���b�N�Ή�
 *  2008/12/20   1.3   SCS �k����        �{�ԏ�Q#738
 *  2009/01/19   1.4   SCS �쑺          �{�ԏ�Q#1038
 *  2009/01/27   1.5   SCS ��r          �{�ԏ�Q#332�Ή��i�����F�o�Ɍ��s���Ή��j
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf                OUT NOCOPY   VARCHAR2         -- �G���[���b�Z�[�W #�Œ�#
   , retcode               OUT NOCOPY   VARCHAR2         -- �G���[�R�[�h     #�Œ�#
   , iv_item_class         IN           VARCHAR2         -- ���i�敪
   , iv_action_type        IN           VARCHAR2         -- �������
   , iv_block1             IN           VARCHAR2         -- �u���b�N�P
   , iv_block2             IN           VARCHAR2         -- �u���b�N�Q
   , iv_block3             IN           VARCHAR2         -- �u���b�N�R
   , iv_deliver_from_id    IN           VARCHAR2         -- �o�Ɍ�
   , iv_deliver_type       IN           VARCHAR2         -- �o�Ɍ`��
   , iv_deliver_date_from  IN           VARCHAR2         -- �o�ɓ�From
   , iv_deliver_date_to    IN           VARCHAR2         -- �o�ɓ�To
  );
END XXWSH920007C;
/
