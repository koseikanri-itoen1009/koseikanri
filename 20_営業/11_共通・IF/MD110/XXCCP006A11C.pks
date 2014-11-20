CREATE OR REPLACE PACKAGE XXCCP006A11C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP006A11C(spec)
 * Description      : �V�K�|�C���g�X�V����
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
 *  2012/10/16    1.0   K.Onotuska          [E_�{�ғ�_10052]�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_file_id    IN     VARCHAR2,         -- 1.�t�@�C��ID
    iv_fmt_ptn    IN     VARCHAR2          -- 2.�t�H�[�}�b�g�p�^�[��
  );
END XXCCP006A11C;
/
