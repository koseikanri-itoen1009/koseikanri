CREATE OR REPLACE PACKAGE XXCOK014A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A03C(spec)
 * Description      : �̎�c���v�Z����
 * MD.050           : �̔��萔���i���̋@�j�̎x���\��z�i�����c���j���v�Z MD050_COK_014_A03
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
 *  2009/01/13    1.0   A.Yano           �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf          OUT    VARCHAR2         -- �G���[���b�Z�[�W
    ,retcode         OUT    VARCHAR2         -- �G���[�R�[�h
    ,iv_process_date IN     VARCHAR2         -- �Ɩ��������t
  );
END XXCOK014A03C;
/
