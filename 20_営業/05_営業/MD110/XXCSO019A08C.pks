CREATE OR REPLACE PACKAGE APPS.XXCSO019A08C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A08C(spec)
 * Description      : �v���̔��s��ʂ���A�c�ƈ����ƂɎw������܂ތ���1���`�w����܂�
 *                    �K����т̖����ڋq��\�����܂��B
 * MD.050           : MD050_CSO_019_A08_���K��ڋq�ꗗ�\
 * Version          : 1.2
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
 *  2009-02-12    1.0   Ryo.Oikawa       �V�K�쐬
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
 *  2017-01-17    1.2   Yasuhiro.Shoji   E_�{�ғ�_13985�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2          --   �G���[���b�Z�[�W #�Œ�#
   ,retcode       OUT NOCOPY VARCHAR2          --   �G���[�R�[�h     #�Œ�#
   ,iv_current_date  IN  VARCHAR2              --   ���
-- Ver1.2 add start
   ,iv_vd_output_div IN  VARCHAR2              --   �o�͋敪
-- Ver1.2 add end
  );
END XXCSO019A08C;
/
