CREATE OR REPLACE PACKAGE XXCOS011A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS011A10C (spec)
 * Description      : ���ɗ\��f�[�^�̒��o���s��
 * MD.050           : ���ɗ\��f�[�^���o (MD050_COS_011_A10)
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
 *  2008/12/02    1.0   K.Kiriu         �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf             OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode            OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_to_s_code       IN     VARCHAR2,         --   1.������ۊǏꏊ
    iv_edi_c_code      IN     VARCHAR2,         --   2.EDI�`�F�[���X�R�[�h
    iv_request_number  IN     VARCHAR2          --   3.�ړ��I�[�_�[�ԍ�
  );
END XXCOS011A10C;
/
