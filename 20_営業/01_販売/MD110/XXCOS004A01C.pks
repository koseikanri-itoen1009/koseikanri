CREATE OR REPLACE PACKAGE XXCOS004A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS004A01C (spec)
 * Description      : �X�ܕʊ|���쐬
 * MD.050           : �X�ܕʊ|���쐬 MD050_COS_004_A01
 * Version          : 1.1
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
 *  2009/01/19    1.0   T.kitajima       �V�K�쐬
 *  2009/02/06    1.1   K.Kakishita      [COS_036]AR����^�C�v�}�X�^�̒��o�����ɉc�ƒP�ʂ�ǉ�
 *  2009/02/10    1.2   T.kitajima       [COS_057]�ڋq�敪�i�荞�ݏ����s���Ή�(�d�l�R��)
 *  2009/02/17    1.3   T.kitajima       get_msg�̃p�b�P�[�W���C��
 *  2009/02/24    1.4   T.kitajima       �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_base_code              IN      VARCHAR2,         -- 1.���_�R�[�h
    iv_customer_number        IN      VARCHAR2          -- 2.�ڋq�R�[�h
  );
END XXCOS004A01C;
/
