CREATE OR REPLACE PACKAGE XXCOS011A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS011A02C (spec)
 * Description      : SQL-LOADER�ɂ����EDI�݌ɏ�񃏁[�N�e�[�u���Ɏ捞�܂ꂽEDI�݌ɏ��f�[�^��
 *                     EDI�݌ɏ��e�[�u���ɂ��ꂼ��o�^���܂��B
 * MD.050           : �݌ɏ��f�[�^�捞�iMD050_COS_011_A02�j
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
 *  2008/12/29    1.0   K.Watanabe      �V�K�쐬
 *  2009/02/17    1.1   K.Kiriu         [COS_062]JAN�R�[�h�G���[���̃��b�Z�[�W���C��
 *                                      [COS_080]�`�[�v�̏C��
 *                                      [COS_081]�I���X�e�[�^�X�ɂ�鏈������̏C��
 *                                      [COS_088]�G���[�A�x�����ݎ��̏I���ݒ�̏C��
 *                                      [COS_089]�G���[���̐��팏���ݒ�̏C��
 *                                      [COS_090]�ڋq�i�ڂ̎擾���W�b�N�C��
 *  2009/05/19    1.2   T.Kitajima      [T1_0242]�i�ڎ擾���AOPM�i�ڃ}�X�^.�����i�����j�J�n�������ǉ�
 *                                      [T1_0243]�i�ڎ擾���A�q�i�ڑΏۊO�����ǉ�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,     --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,     --   �G���[�R�[�h     #�Œ�#
    iv_file_name      IN VARCHAR2,     --   �C���^�t�F�[�X�t�@�C����
    iv_run_class      IN VARCHAR2,     --   ���s�敪�F�u0:�V�K�v�u1:�Ď��s�v
    iv_edi_chain_code IN VARCHAR2      --   EDI�`�F�[���X�R�[�h
  );
END XXCOS011A02C;
/
