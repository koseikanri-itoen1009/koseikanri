CREATE OR REPLACE PACKAGE APPS.XXCSO019A11C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A11C(spec)
 * Description      : �w�肳�ꂽ���_CD�E��������ɁA�������Ă���c�ƈ����A����ɑ΂���
 *                    �L�����Ԓ��̒S���ڋq�̃f�[�^���擾���ACSV�`���ŏo�̓t�@�C���ɏo�͂��܂��B
 * MD.050           : MD050_CSO_019_A11_�S���c�ƈ��ꗗ�f�[�^�o��
 *
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        �������� (A-1)
 *  output_csv_rec              �o�̓t�@�C���ւ̃f�[�^�o�� (A-3)
 *  submain                     ���C�������v���V�[�W��
 *                                  �S���c�ƈ��f�[�^���o (A-2)
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                                  �I������ (A-4)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010-03-19    1.0   Kazuyo.Hosoi     �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2         --   �G���[���b�Z�[�W #�Œ�#
   ,retcode             OUT NOCOPY VARCHAR2         --   �G���[�R�[�h     #�Œ�#
   ,iv_base_code        IN         VARCHAR2         --   ���_�R�[�h
   ,iv_standard_date    IN         VARCHAR2         --   ���(1�F���� / 2�F����)
  );
END XXCSO019A11C;
/
