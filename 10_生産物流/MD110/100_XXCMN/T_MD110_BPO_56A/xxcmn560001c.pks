CREATE OR REPLACE PACKAGE xxcmn560001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn560001c(spec)
 * Description      : �g���[�T�r���e�B
 * MD.050           : �g���[�T�r���e�B T_MD050_BPO_560
 * MD.070           : �g���[�T�r���e�B T_MD070_BPO_56A
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
 *  2008/01/08    1.0   ORACLE �⍲�q��  main�V�K�쐬
 *
 *****************************************************************************************/
--
  -- �R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf          OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode         OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_item_code    IN     VARCHAR2,         -- 1.�i�ڃR�[�h
    iv_lot_no       IN     VARCHAR2,         -- 2.���b�gNo
    iv_out_control  IN     VARCHAR2          -- 3.�o�͐���
  );
END xxcmn560001c;
/
