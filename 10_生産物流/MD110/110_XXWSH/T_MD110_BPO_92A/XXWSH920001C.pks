CREATE OR REPLACE PACKAGE XXWSH920001C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920001C(spec)
 * Description      : ���Y����(�����A�z��)
 * MD.050           : �o�ׁE����/�z�ԁF���Y�������ʁi�o�ׁE�ړ��������j T_MD050_BPO_920
 * MD.070           : �o�ׁE����/�z�ԁF���Y�������ʁi�o�ׁE�ړ��������j T_MD070_BPO92A
 * Version          : 1.11
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
 *  2008/03/12   1.0   Oracle �y�c ��   ����쐬
 *  2008/04/23   1.1   Oracle �y�c ��   �����ύX�v��63,65�Ή�
 *  2008/05/30   1.2   Oracle �k���� ���v �����e�X�g�s��Ή�
 *  2008/05/31   1.3   Oracle �k���� ���v �����e�X�g�s��Ή�
 *  2008/06/02   1.4   Oracle �k���� ���v �����e�X�g�s��Ή�
 *  2008/06/05   1.5   Oracle �k���� ���v �����e�X�g�s��Ή�
 *  2008/06/12   1.6   Oracle �k���� ���v �����e�X�g�s��Ή�
 *  2008/07/15   1.7   Oracle �k���� ���v ST#449�Ή�
 *  2008/07/16   1.8   Oracle �k���� ���v �ύX�v��#93�Ή�
 *  2008/07/25   1.9   Oracle �k���� ���v �����e�X�g�s��C��
 *  2008/09/08   1.10  Oracle �Ŗ� ���\   PT 6-1_28 �w�E44 �Ή�
 *  2008/09/10   1.11  Oracle �Ŗ� ���\   PT 6-1_28 �w�E44 �C��
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                OUT NOCOPY   VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode               OUT NOCOPY   VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
    iv_item_class         IN           VARCHAR2,         -- ���i�敪
    iv_action_type        IN           VARCHAR2,         -- �������
    iv_block1             IN           VARCHAR2,         -- �u���b�N�P
    iv_block2             IN           VARCHAR2,         -- �u���b�N�Q
    iv_block3             IN           VARCHAR2,         -- �u���b�N�R
    iv_deliver_from_id    IN           VARCHAR2,           -- �o�Ɍ�
    iv_deliver_type       IN           VARCHAR2,           -- �o�Ɍ`��
    iv_deliver_date_from  IN           VARCHAR2,         -- �o�ɓ�From
    iv_deliver_date_to    IN           VARCHAR2          -- �o�ɓ�To
  );
END XXWSH920001C;
/
