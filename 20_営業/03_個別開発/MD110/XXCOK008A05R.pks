CREATE OR REPLACE PACKAGE XXCOK008A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK008A05R(spec)
 * Description      : �v���̔��s��ʂ���A����U�֊����`�F�b�N���X�g�𒠕[�ɏo�͂��܂��B
 * MD.050           : ����U�֊����`�F�b�N���X�g MD050_COK_008_A05
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
 *  2008/10/23    1.0   T.Abe            �V�K�쐬
 *  2009/03/25    1.1   S.Kayahara       �ŏI�s�ɃX���b�V���ǉ�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                    OUT VARCHAR2         -- �G���[���b�Z�[�W
   ,retcode                   OUT VARCHAR2         -- �G���[�R�[�h
   ,iv_selling_from_base_code IN  VARCHAR2         -- ����U�֌����_�R�[�h
   ,iv_selling_from_cust_code IN  VARCHAR2         -- ����U�֌��ڋq�R�[�h
   ,iv_selling_to_base_code   IN  VARCHAR2         -- ����U�֐拒�_�R�[�h
  );
END XXCOK008A05R;
/
