CREATE OR REPLACE PACKAGE APPS.XXCMM002A15C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 *
 * Package Name     : XXCMM002A15C(spec)
 * Description      : �]�ƈ����i�Ǘ��ҁA���F�Ҕ͈́j�����ɁA�]�ƈ��}�X�^���X�V���܂��B
 * MD.050           : �Ǘ��ҁ^���F�Ҕ͈̓A�b�v���[�h (MD050_CMM_002_A15)
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
 *  2024/08/30    1.0   M.Akachi         �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf            OUT    VARCHAR2       -- �G���[���b�Z�[�W #�Œ�#
    ,retcode           OUT    VARCHAR2       -- �G���[�R�[�h     #�Œ�#
    ,in_get_file_id    IN     NUMBER         -- �t�@�C��ID
    ,iv_get_format_pat IN     VARCHAR2       -- �t�H�[�}�b�g�p�^�[��
  );
END XXCMM002A15C;
/
