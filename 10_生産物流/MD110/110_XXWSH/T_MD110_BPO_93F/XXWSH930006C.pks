CREATE OR REPLACE PACKAGE xxwsh930006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH930006C(spec)
 * Description      : �C���^�t�F�[�X�f�[�^�폜����
 * MD.050           : ���Y��������                  T_MD050_BPO_935
 * MD.070           : �C���^�t�F�[�X�f�[�^�폜����  T_MD070_BPO_93F
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
 *  2008/04/22    1.0   Oracle �R�� ��_ ����쐬
 *  2008/12/12    1.1   Oracle ���c ���� �{�ԏ�Q#702�Ή�
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode             OUT NOCOPY VARCHAR2,        --   �G���[�R�[�h     #�Œ�#
    iv_location_code IN            VARCHAR2,        -- 1.�񍐕���         #�K�{#
    iv_eos_data_type IN            VARCHAR2,        -- 2.EOS�f�[�^���    #�K�{#
    iv_order_ref     IN            VARCHAR2         -- 3.�˗���/�ړ���    #�C��#
  );
END xxwsh930006c;
/
