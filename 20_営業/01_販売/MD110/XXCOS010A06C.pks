CREATE OR REPLACE PACKAGE APPS.XXCOS010A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS010A06C(spec)
 * Description      : �󒍃C���|�[�g�G���[���m
 * MD.050           : MD050_COS_010_A06_�󒍃C���|�[�g�G���[���m
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  main                   ���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/07/06    1.0   K.Satomura       �V�K�쐬
 *****************************************************************************************/
  --
  --���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf               OUT NOCOPY VARCHAR2 -- �G���[���b�Z�[�W #�Œ�#
    ,retcode              OUT NOCOPY VARCHAR2 -- �G���[�R�[�h     #�Œ�#
    ,iv_order_source_name IN         VARCHAR2 -- �󒍃\�[�X����
  );
  --
END XXCOS010A06C;
/
