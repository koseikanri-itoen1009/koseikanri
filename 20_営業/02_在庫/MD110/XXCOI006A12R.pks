CREATE OR REPLACE PACKAGE XXCOI006A12R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A12R(spec)
 * Description      : �p�����[�^�œ��͂��ꂽ�N������уe�i���g�i�g�g�s�^�p�Ȃ��̕ۊǏꏊ�j
 *                    �����Ɍ����݌Ɏ󕥕\�ɑ��݂���i�ڋy�сA�莝�����ʂɑ��݂���i�ڂ̈�
 *                    �����쐬���܂��B
 * MD.050           : ���i���n�I���[    MD050_COI_006_A12
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
 *  2008/12/15    1.0   Sai.u            main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf             OUT VARCHAR2,     -- �G���[���b�Z�[�W #�Œ�#
    retcode            OUT VARCHAR2,     -- �G���[�R�[�h     #�Œ�#
    iv_practice_month  IN  VARCHAR2,     -- �N��
    iv_tenant          IN  VARCHAR2      -- �e�i���g
  );
END XXCOI006A12R;
/
