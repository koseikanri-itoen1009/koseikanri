CREATE OR REPLACE PACKAGE XXCOS008A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS008A01C(spec)
 * Description      : �H�꒼���o�׈˗�IF�쐬���s��
 * MD.050           : �H�꒼���o�׈˗�IF�쐬 MD050_COS_008_A01
 * Version          : 1.7
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
 *  2009/04/06    1.4   T.Kitajima       [T1_0175]�o�׈˗�No�̔ԃ��[���ύX[9]��[97]
 *  2009/04/16    1.5   T.Kitajima       [T1_0609]�o�׈˗�No�̔ԃ��[���ύX[97]��[98]
 *  2009/05/15    1.6   S.Tomita         [T1_1004]���Y����S�ւ�UO�ؑ�/�߂��A[�ڋq��������̎����쐬]�@�\�ďo�Ή�
 *  2009/05/26    1.7   T.Kitajima       [T1_0457]�đ��Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf           OUT    VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode          OUT    VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
--****************************** 2009/05/26 1.7 T.Kitajima MOD START ******************************--
--    iv_base_code     IN     VARCHAR2,         -- 1.���_�R�[�h
--    iv_order_number  IN     VARCHAR2          -- 2.�󒍔ԍ�
    iv_send_flg      IN     VARCHAR2,         -- 1.�V�K/�đ��敪
    iv_base_code     IN     VARCHAR2,         -- 2.���_�R�[�h
    iv_order_number  IN     VARCHAR2          -- 3.�󒍔ԍ�
--****************************** 2009/05/26 1.7 T.Kitajima MOD  END  ******************************--
  );
END XXCOS008A01C;
/
