CREATE OR REPLACE PACKAGE XXCOS010A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS010A05R(spec)
 * Description      : �󒍃G���[���X�g
 * MD.050           : �󒍃G���[���X�g MD050_COS_010_A05
 * Version          : 1.2
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
 *  2008/12/17    1.0   K.Kumamoto       �V�K�쐬
 *  2009/02/13    1.1   M.Yamaki         [COS_072]�G���[���X�g��ʃR�[�h�̑Ή�
 *  2009/02/24    1.2   T.Nakamura       [COS_133]���b�Z�[�W�o�́A���O�o�͂ւ̏o�͓��e�̒ǉ��E�C��
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2         --   �G���[���b�Z�[�W #�Œ�#
   ,retcode       OUT    VARCHAR2         --   �G���[�R�[�h     #�Œ�#
   ,iv_err_list_type IN     VARCHAR2      --   �G���[���X�g���
  );
END XXCOS010A05R;
/
