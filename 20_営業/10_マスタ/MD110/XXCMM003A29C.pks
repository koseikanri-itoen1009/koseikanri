CREATE OR REPLACE PACKAGE XXCMM003A29C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A29C(spec)
 * Description      : �ڋq�ꊇ�X�V
 * MD.050           : MD050_CMM_003_A29_�ڋq�ꊇ�X�V
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
 *  2009/01/20    1.0   ���� �S��        �V�K�쐬
 *  2009/03/24    1.1   Yutaka.Kuboshima �S�p���p�`�F�b�N������ǉ�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W���i�ڋq�ꊇ�X�V�j
  PROCEDURE main(
    errbuf                    OUT    VARCHAR2,     --�G���[���b�Z�[�W #�Œ�#
    retcode                   OUT    VARCHAR2,     --�G���[�R�[�h     #�Œ�#
    iv_file_id                IN     VARCHAR2,     --�t�@�C��ID
    iv_format_pattern         IN     VARCHAR2      --�t�@�C���t�H�[�}�b�g
  );
END XXCMM003A29C;
/
