CREATE OR REPLACE PACKAGE xxinv450001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv450001c(body)
 * Description      : ���ьv��σt���O�X�V����
 * MD.050           : ���ьv��σt���O�X�V T_MD050_BPO_450
 * MD.070           : ���ьv��σt���O�X�V����(45A)
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ----------------------------------------------------------
 *  Name                      Description
 * ------------------------- ----------------------------------------------------------
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/03/01    1.0   H.Itou           �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf               OUT VARCHAR2      --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode              OUT VARCHAR2      --   ���^�[���E�R�[�h    --# �Œ� #
   ,iv_date_from         IN  VARCHAR2      --   �X�V���t(FROM)
   ,iv_date_to           IN  VARCHAR2      --   �X�V���t(TO)
  );
--
END xxinv450001c;
/
