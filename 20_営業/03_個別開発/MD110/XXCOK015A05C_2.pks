CREATE OR REPLACE PACKAGE XXCOK015A05C_2
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK015A05C_2(spec)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : EDI�V�X�e���ɂăC���t�H�}�[�g�Ђ֑��M����x���ē����p�f�[�^�t�@�C���쐬
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
 *  2021/04/01    1.0   T.Nishikawa      �V�K�쐬
 *
 *****************************************************************************************/
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf          OUT VARCHAR2
   ,retcode         OUT VARCHAR2
   ,iv_tax_div      IN  VARCHAR2          -- 1.�ŋ敪
   ,iv_proc_div     IN  VARCHAR2          -- 2.�����敪
   ,iv_target_div   IN  VARCHAR2          -- 3.�Ώۋ敪
  );
END XXCOK015A05C_2;
/
