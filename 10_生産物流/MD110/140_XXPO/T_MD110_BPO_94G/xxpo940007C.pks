CREATE OR REPLACE PACKAGE xxpo940007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo940007c(spec)
 * Description      : ���b�g�������̃A�b�v���[�h
 * MD.050           : �����I�����C�� T_MD050_BPO_940
 * MD.070           : ���b�g�������̃A�b�v���[�h T_MD070_BPO_94G
 * Version          : 1.3
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2008/06/17    1.0   N.yoshida          main�V�K�쐬
 *  2008/07/08    1.1   Oracle �R����_    I_S_192�Ή�
 *  2008/07/15    1.2   Oracle �g�c�Ď�    �f�[�^�o�^�֐����ύX
 *  2008/08/18    1.3   Oracle �ɓ��ЂƂ�  T_TE080_BPO_400 �w�E1 �X�V���̓`�F�b�N���Ȃ�
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf          OUT NOCOPY VARCHAR2,     --   �G���[���b�Z�[�W #�Œ�#
    retcode         OUT NOCOPY VARCHAR2,     --   �G���[�R�[�h     #�Œ�#
    in_file_id      IN     VARCHAR2,         --   �t�@�C���h�c
    in_file_format  IN     VARCHAR2          --   �t�H�[�}�b�g�p�^�[��
  );
END xxpo940007c;
/
