CREATE OR REPLACE PACKAGE xxwsh420001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH420001C(spec)
 * Description      : �o�׈˗�/�o�׎��э쐬����
 * MD.050           : �o�׎��� T_MD050_BPO_420
 * MD.070           : �o�׈˗��o�׎��э쐬���� T_MD070_BPO_42A
 * Version          : 1.3
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/24    1.0   Oracle �k���� ���v ����쐬
 *  2008/05/14    1.1   Oracle �{�c ���j   MD050�w�E������No56���f
 *  2008/05/19    1.2   Oracle �{�c ���j   �˗�No��TO_NUMBER���p�~
 *  2008/05/22    1.3   Oracle �{�c ���j   �󒍖��׍쐬���̒P��NULL�Ή�
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf          OUT NOCOPY VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode         OUT NOCOPY VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_block        IN VARCHAR2,                 --   �u���b�N
    iv_deliver_from IN VARCHAR2,                 --   �o�׌�
    iv_request_no   IN VARCHAR2);                --   �˗�No
END xxwsh420001c;
/
