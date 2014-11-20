create or replace PACKAGE XXCMM005A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM005A03C(spec)
 * Description      : ���_�}�X�^IF�o�́iHHT�j
 * MD.050           : ���_�}�X�^IF�o�́iHHT�j MD050_CMM_005_A03
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
 *  2009/02/03    1.0   Masayuki.Sano    main�V�K�쐬
 *  2009/03/09    1.1   Yutaka.Kuboshima �t�@�C���o�͐�̃v���t�@�C���̕ύX
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
END XXCMM005A03C;
/
