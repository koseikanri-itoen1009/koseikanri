CREATE OR REPLACE PACKAGE XXCMM002A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM002A06C(spec)
 * Description      : �Ј��}�X�^IF�o��(HHT)
 * MD.050           : �Ј��}�X�^IF�o��(HHT) MD050_CMM_002_A06
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/09    1.0   SCS ���� �M�q    ����쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_date_from  IN     VARCHAR2,         --   1.�ŏI�X�V��(�J�n)
    iv_date_to    IN     VARCHAR2          --   2.�ŏI�X�V��(�I��)
  );
END XXCMM002A06C;
/
