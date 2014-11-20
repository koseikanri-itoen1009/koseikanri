CREATE OR REPLACE PACKAGE XXCOI006A21C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A21C(spec)
 * Description      : �I�����ʍ쐬
 * MD.050           : HHT�I�����ʃf�[�^�捞 <MD050_COI_A21>
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
 *  2009/01/15    1.0   N.Abe            �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT   VARCHAR2,      --   �G���[���b�Z�[�W #�Œ�#
    retcode           OUT   VARCHAR2,      --   �G���[�R�[�h     #�Œ�#
    iv_file_id        IN    VARCHAR2,      -- 1.FILE_ID
    iv_format_pattern IN    VARCHAR2       -- 2.�t�H�[�}�b�g�p�^�[��
  );
END XXCOI006A21C;
/
