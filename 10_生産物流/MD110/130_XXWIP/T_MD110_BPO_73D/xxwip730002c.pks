CREATE OR REPLACE PACKAGE xxwip730002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWIP730002C(SPEC)
 * Description      : �^���X�V
 * MD.050           : �^���v�Z�i�g�����U�N�V�����j T_MD050_BPO_733
 * MD.070           : �^���X�V T_MD070_BPO_73D
 * Version          : 1.0
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
 *  2008/04/03    1.0  Oracle ���� �~    ���ō쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf             OUT  NOCOPY VARCHAR2  --   �G���[���b�Z�[�W #�Œ�#
   ,retcode            OUT  NOCOPY VARCHAR2  --   �G���[�R�[�h     #�Œ�#
   ,iv_exchange_type   IN          VARCHAR2  --   ���֋敪
   );
END xxwip730002c;
/
