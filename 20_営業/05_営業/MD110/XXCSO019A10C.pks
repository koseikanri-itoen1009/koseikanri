CREATE OR REPLACE PACKAGE APPS.XXCSO019A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A10C(spec)
 * Description      : �K�┄��v��Ǘ��\�i�������s�̒��[�j�p�ɃT�}���e�[�u�����쐬���܂��B
 * MD.050           :  MD050_CSO_019_A10_�K�┄��v��Ǘ��W�v�o�b�`
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
 *  2009-01-13    1.0   Tomoko.Mori      �V�K�쐬
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2          --   �G���[���b�Z�[�W #�Œ�#
   ,retcode       OUT NOCOPY VARCHAR2          --   �G���[�R�[�h     #�Œ�#
  );
END XXCSO019A10C;
/
