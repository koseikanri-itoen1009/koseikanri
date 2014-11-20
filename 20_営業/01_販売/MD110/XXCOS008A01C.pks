CREATE OR REPLACE PACKAGE XXCOS008A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS008A01C(spec)
 * Description      : �H�꒼���o�׈˗�IF�쐬���s��
 * MD.050           : �H�꒼���o�׈˗�IF�쐬 MD050_COS_008_A01
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
 *  2008/12/25    1.0   K.Atsushiba      �V�K�쐬
 *  2009/02/05    1.1   K.Atsushiba      COS_035�Ή�  �o�׈˗�I/F�w�b�_�[�̈˗��敪�Ɂu4�v��ݒ�B
 *  2009/02/18    1.2   K.Atsushiba      get_msg�̃p�b�P�[�W���C��
 *  2009/02/23    1.3   K.Atsushiba      �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf           OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode          OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_base_code     IN     VARCHAR2,         -- 1.���_�R�[�h
    iv_order_number  IN     VARCHAR2          -- 2.�󒍔ԍ�
  );
END XXCOS008A01C;
/
