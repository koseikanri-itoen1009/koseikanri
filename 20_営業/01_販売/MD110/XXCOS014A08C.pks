CREATE OR REPLACE PACKAGE XXCOS014A08C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A08C(spec)
 * Description      : CSV�f�[�^�A�b�v���[�h(�l����`�Ǘ��䒠)
 * MD.050           : CSV�f�[�^�A�b�v���[�h(�l����`�Ǘ��䒠)(MD050_COS_014_A08) 
 * Version          : 1.1
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
 *  2009/01/13    1.0   T.Oura           �V�K�쐬
 *  2009/02/12    1.1   T.Nakamura       [��QCOS_061] ���b�Z�[�W�o�́A���O�o�͂ւ̏o�͓��e�̒ǉ��E�C��
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    in_file_id    IN     NUMBER,           --   �t�@�C��ID
    iv_format     IN     VARCHAR2          --   �t�H�[�}�b�g�p�^�[��
  );
END XXCOS014A08C;
/
