CREATE OR REPLACE PACKAGE XXCOK014A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A02C(spec)
 * Description      : �̔��萔���i���̋@�j�̌v�Z���ʂ����n�V�X�e����
 *                    �A�g����C���^�[�t�F�[�X�t�@�C�����쐬���܂�
 * MD.050           : ���n�V�X�e��IF�t�@�C���쐬-�����ʔ̎�̋�  MD050_COK_014_A02
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
 *  2008/11/19    1.0   T.Abe            �V�K�쐬
 *  2009/03/25    1.1   S.Kayahara       �ŏI�s�ɃX���b�V���ǉ�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf           OUT VARCHAR2         -- �G���[���b�Z�[�W
   ,retcode          OUT VARCHAR2         -- �G���[�R�[�h
   ,iv_business_date IN  VARCHAR2         -- �Ɩ����t
  );
END XXCOK014A02C;
/
