CREATE OR REPLACE PACKAGE xxwip750001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip750001c(spec)
 * Description      : �U�։^�����X�V
 * MD.050           : �^���v�Z�i�U�ցj T_MD050_BPO_750
 * MD.070           : �U�։^�����X�V T_MD070_BPO_75C
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  submain              ���C�������v���V�[�W��
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/29    1.0  Oracle �a�c ��P  ����쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT    VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode           OUT    VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
    iv_exchange_type  IN     VARCHAR2          -- �r���ւ��敪
  );
END xxwip750001c;
/
