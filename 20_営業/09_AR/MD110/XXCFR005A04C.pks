CREATE OR REPLACE PACKAGE XXCFR005A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR005A04C(spec)
 * Description      : ���b�N�{�b�N�X��������
 * MD.050           : MD050_CFR_005_A04_���b�N�{�b�N�X��������
 * MD.070           : MD050_CFR_005_A04_���b�N�{�b�N�X��������
 * Version          : 1.00
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
 *  2010/10/15    1.00 SCS �A�� �^���l  ����쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                OUT NOCOPY VARCHAR2,  -- �G���[���b�Z�[�W #�Œ�#
    retcode               OUT NOCOPY VARCHAR2,  -- �G���[�R�[�h     #�Œ�#
    iv_fb_file_name       IN         VARCHAR2,  -- FB�t�@�C����
    iv_table_insert_flag  IN         VARCHAR2   -- ���[�N�e�[�u���쐬�t���O
  );
END XXCFR005A04C;
/
