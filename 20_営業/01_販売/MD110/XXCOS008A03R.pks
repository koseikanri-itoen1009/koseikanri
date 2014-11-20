CREATE OR REPLACE PACKAGE XXCOS008A03R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS008A03R (spec)
 * Description      : �����󒍗�O�f�[�^���X�g
 * MD.050           : �����󒍗�O�f�[�^���X�g MD050_COS_008_A03
 * Version          : 1.3
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
 *  2008/12/10    1.0   T.Miyata         �V�K�쐬
 *  2009/02/16    1.1   SCS K.NAKAMURA   [COS_002] g,mg����kg�ւ̒P�ʊ��Z�̕s��Ή�
 *  2009/02/19    1.2   K.Atsushiba      get_msg�̃p�b�P�[�W���C��
 *  2009/04/10    1.3   T.Kitajima       [T1_0381]�o�׈˗����̐���0�f�[�^���O
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_base_code  IN     VARCHAR2          --   1.���_�R�[�h
  );
END XXCOS008A03R;
/
