CREATE OR REPLACE PACKAGE XXCOI010A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI010A03C(spec)
 * Description      : VD�R�����}�X�^HHT�A�g
 * MD.050           : VD�R�����}�X�^HHT�A�g MD050_COI_010_A03
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
 *  2008/12/02    1.0   T.Nakamura       �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf              OUT    VARCHAR2          --   �G���[���b�Z�[�W #�Œ�#
    , retcode             OUT    VARCHAR2          --   �G���[�R�[�h     #�Œ�#
    , iv_night_exec_flag  IN     VARCHAR2          --   ��Ԏ��s�t���O
  );
END XXCOI010A03C;
/
