CREATE OR REPLACE PACKAGE XXCSM002A18C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCSM002A18C(spec)
 * Description      : �A�b�v���[�h�t�@�C������P�i�ʂ̔N�ԏ��i�v��f�[�^�̐􂢑ւ�
 * MD.050           : �N�ԏ��i�v��P�i�ʃA�b�v���[�h MD050_CSM_002_A18
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �N�ԏ��i�v��P�i�ʃA�b�v���[�h
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/11/20    1.0   K.Nara           �V�K�쐬
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf     OUT VARCHAR2 -- �G���[���b�Z�[�W
    ,retcode    OUT VARCHAR2 -- �G���[�R�[�h
    ,iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    ,iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g
  );
END XXCSM002A18C;
/
