CREATE OR REPLACE PACKAGE XXCOK001A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK001A03C_pks(spec)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : �A�h�I���F�ڋq�ڍs����I/F�t�@�C���쐬 �̔����� MD050_COK_001_A03
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
 *  2008/10/31    1.0   K.Suenaga        �V�K�쐬
 *  2009/02/02    1.1   K.Suenaga        [��QCOK_001] ��o�b�`�Ή�(�p�����[�^�ǉ�)
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf  OUT VARCHAR2           -- �G���[�E���b�Z�[�W
  , retcode OUT VARCHAR2           -- �G���[�R�[�h
  , iv_process_flag IN VARCHAR2      -- ���͍��ڂ̋N���敪�p�����[�^
  );
END XXCOK001A03C;
/