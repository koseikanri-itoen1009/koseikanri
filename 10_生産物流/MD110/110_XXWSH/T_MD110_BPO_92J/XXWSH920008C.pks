CREATE OR REPLACE PACKAGE XXWSH920008C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920008C_2(spec)
 * Description      : ���Y����(�����A�z��)
 * MD.050           : �o�ׁE����/�z�ԁF���Y�������ʁi�o�ׁE�ړ��������j T_MD050_BPO_920
 * MD.070           : �o�ׁE����/�z�ԁF���Y�������ʁi�o�ׁE�ړ��������j T_MD070_BPO_92J
 * Version          : 1.10
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
 *  2008/11/20   1.0   SCS�k����         ����쐬
 *  2008/11/28   1.1   SCS�k����         �{�ԏ�Q246�Ή�
 *  2008/11/29   1.2   SCS�{�c           ���b�N�Ή�
 *  2008/12/02   1.3   SCS��r           �{�ԏ�Q#251�Ή��i�����ǉ�) 
 *  2008/12/15   1.4   SCS�ɓ�           �{�ԏ�Q#645�Ή��iD4���v�� S4������ �\���������ѓ��ɕύX�j
 *  2008/12/19   1.5   SCS�ɓ�           �{�ԏ�Q#648�Ή��iI5���і���݌ɐ� I6 ���і���݌ɐ� ���o���ڂ����ѐ��|�O�񐔂ɕύX�j
 *  2008/12/25   1.6   SCS�k�������v     �{�ԏ�Q#859�Ή� (���O�̃I�[�o�[�t���[�ɂ��R���J�����g�G���[�ƂȂ邽�ߗ]���ȃ��O���o�͂��Ȃ��悤�ɕύX)
 *  2009/01/19   1.7   SCS��r           �{�ԏ�Q#949�Ή��iPT�Ή��j
 *  2009/01/26   1.8   SCS��r           �{�ԏ�Q#936�Ή��i�N�x�����E���b�g�t�]PT�Ή��j
 *                                       �{�ԏ�Q#332�Ή��i�����F�o�Ɍ��s���Ή��j
 *  2009/01/28   1.9   SCS�ɓ�           �{�ԏ�Q#1028�Ή��i�p�����[�^�Ɏw�������ǉ��j
 *  2009/03/17   1.10  SCS�k����         �{�ԏ�Q#1323�Ή�
 *  2009/10/16   1.11  SCS����           �{�ԏ�Q#1611�Ή� 
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
   , iv_item_code          IN           VARCHAR2         -- �e�i�ڃR�[�h
-- 2009/01/28 H.Itou Add Start �{�ԏ�Q#1028�Ή�
   , iv_instruction_dept   IN           VARCHAR2         -- �w������
-- 2009/01/28 H.Itou Add End
     );
--
END XXWSH920008C;
/
