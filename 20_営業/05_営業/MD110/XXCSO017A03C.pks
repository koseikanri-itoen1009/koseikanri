CREATE OR REPLACE PACKAGE XXCSO017A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO017A03C(spec)
 * Description      : �̔���p���ϓ��͉�ʂ���A���ϔԍ��A�Ŗ��Ɍ��Ϗ���
 *                    ���[�ɏo�͂��܂��B
 * MD.050           : MD050_CSO_017_A03_���Ϗ��i�̔���p�jPDF�o��
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
 *  2009-01-06    1.0   Kazuyo.Hosoi     �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2          --   �G���[���b�Z�[�W #�Œ�#
   ,retcode       OUT NOCOPY VARCHAR2          --   �G���[�R�[�h     #�Œ�#
   ,in_qt_hdr_id  IN  NUMBER                   --   ���σw�b�_�[ID
  );
END XXCSO017A03C;
/
