CREATE OR REPLACE PACKAGE XXCMM005A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM005A04C(spec)
 * Description      : �����}�X�^IF�o�́i���̋@�Ǘ��j
 * MD.050           : �����}�X�^IF�o�́i���̋@�Ǘ��j MD050_CMM_005_A04
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
 *  2009/02/12    1.0   Masayuki.Sano    �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                OUT    VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode               OUT    VARCHAR2,        --   �G���[�R�[�h     #�Œ�#
    iv_update_from        IN     VARCHAR2,        --   1.�ŏI�X�V��(FROM)
    iv_update_to          IN     VARCHAR2         --   2.�ŏI�X�V��(TO)
  );
END XXCMM005A04C;
/
