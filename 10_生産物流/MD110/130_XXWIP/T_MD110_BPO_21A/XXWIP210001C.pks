CREATE OR REPLACE PACKAGE xxwip210001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip210001c(spec)
 * Description      : ���Y�o�b�`�ꊇ�N���[�Y����
 * MD.050           : ���Y�N���[�Y T_MD050_BPO_210
 * MD.070           : ���Y�o�b�`�ꊇ�N���[�Y����(21A) T_MD070_BPO_21A
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
 *  2007/11/12    1.0   H.Itou           main �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf               OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode              OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_product_date_from IN  VARCHAR2,      -- 1.���Y���iFROM�j
    iv_product_date_to   IN  VARCHAR2,      -- 2.���Y���iTO�j
    iv_plant_code        IN  VARCHAR2       -- 3.�v�����g�R�[�h
  );
--
END xxwip210001c;
/
