CREATE OR REPLACE PACKAGE XXCSO010A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO010A04C(spec)
 * Description      : �����̔��@�ݒu�_����o�^/�X�V��ʁA�_�񏑌�����ʂ���
 *                    �����̔��@�ݒu�_�񏑂𒠕[�ɏo�͂��܂��B
 * MD.050           : MD050_CSO_010_A04_�����̔��@�ݒu�_��PDF�t�@�C���쐬
 *                    
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
 *  2009-02-03    1.0   Kichi.Cho        �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf               OUT NOCOPY VARCHAR2          -- �G���[���b�Z�[�W #�Œ�#
   ,retcode              OUT NOCOPY VARCHAR2          -- �G���[�R�[�h     #�Œ�#
   ,in_contract_mng_id   IN         NUMBER            -- �����̔��@�ݒu�_��ID
  );
END XXCSO010A04C;
/