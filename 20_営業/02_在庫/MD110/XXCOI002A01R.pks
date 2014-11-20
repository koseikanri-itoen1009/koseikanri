CREATE OR REPLACE PACKAGE XXCOI002A01R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI002A01R(spec)
 * Description      : �q�֓`�[
 * MD.050           : �q�֓`�[ MD050_COI_002_A01
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
 *  2008/11/12    1.0   K.Nakamura       main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf          OUT    VARCHAR2,      --   �G���[���b�Z�[�W #�Œ�#
    retcode         OUT    VARCHAR2,      --   �G���[�R�[�h     #�Œ�#
    iv_org_code     IN     VARCHAR2,      --   1.�݌ɑg�D
    iv_inout_div    IN     VARCHAR2,      --   2.���o�ɋ敪
    iv_date_from    IN     VARCHAR2,      --   3.���t�iFrom�j
    iv_date_to      IN     VARCHAR2,      --   4.���t�iTo�j
    iv_kyoten_from  IN     VARCHAR2,      --   5.�o�Ɍ����_
    iv_dummy        IN     VARCHAR2,      --   ���͐���p�_�~�[�l
    iv_kyoten_to    IN     VARCHAR2       --   6.���ɐ拒�_
  );
END XXCOI002A01R;
/
