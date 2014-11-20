CREATE OR REPLACE PACKAGE xxinv530002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv530002c(spec)
 * Description      : HHT�I���f�[�^IF�v���O����
 * MD.050           : �I�� T_MD050_BPO_530
 * MD.070           : HHT�I���f�[�^IF�v���O����(53B) T_MD070_BPO_53B
 * Version          : 1.5
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
 *  2008/03/06    1.0   T.Endou          main �V�K�쐬
 *  2008/12/06    1.5   T.Miyata         �C��(�{�ԏ�Q#510�Ή��F���t�͕ϊ����Ĕ�r)
 *
 *****************************************************************************************/
--
  -- 2008/12/06 Add Start T.Miyata �{�ԏ�Q#510�Ή�
  FUNCTION fnc_check_date(
    iv_date IN VARCHAR2
    ) RETURN VARCHAR2;
  -- 2008/12/06 Add End T.Miyata �{�ԏ�Q#510�Ή�
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf                OUT    VARCHAR2         --   �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2);       --   �G���[�R�[�h
--
END xxinv530002c;
/
