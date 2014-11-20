CREATE OR REPLACE PACKAGE XXCOS004A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS004A06C (spec)
 * Description      : �����u�c�|���쐬
 * MD.050           : �����u�c�|���쐬 MD050_COS_004_A06
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
 *  2009/01/06    1.0   K.Kakishita      �V�K�쐬
 *  2009/02/03    1.1   T.Kitajima       [COS_009]�x���I�����Ƀ��b�Z�[�W���\������Ȃ�
 *  2009/02/04    1.2   K.Kakishita      [COS_012]���z�v�Z���̊|�����}�X�^�|���łȂ�
 *  2009/02/04    1.3   K.Kakishita      [COS_018]������s�̏ꍇ�A�����v�Z���ߓ��R�̎擾�~�X
 *  2009/02/06    1.4   K.Kakishita      [COS_037]AR����^�C�v�}�X�^�̒��o�����ɉc�ƒP�ʂ�ǉ�
 *  2009/02/20    1.5   K.Kakishita      �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/03/19    1.6   T.Kitajima       [T1_0098]�ۊǏꏊ���o�����C��
 *  2009/04/13    1.7   N.Maeda          [T1_0496]VD�R�����ʎ����񖾍ׂ̐��ʎg�p��
 *                                                  ��VD�R�����ʎ����񖾍ׂ̕�[���֕ύX
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_regular_any_class      IN      VARCHAR2,         -- 1.��������敪
    iv_base_code              IN      VARCHAR2,         -- 2.���_�R�[�h
    iv_customer_number        IN      VARCHAR2          -- 3.�ڋq�R�[�h
  );
END XXCOS004A06C;
/
