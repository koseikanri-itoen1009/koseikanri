CREATE OR REPLACE PACKAGE xxinv530002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv530002c(spec)
 * Description      : HHT�I���f�[�^IF�v���O����
 * MD.050           : �I�� T_MD050_BPO_530
 * MD.070           : HHT�I���f�[�^IF�v���O����(53B) T_MD070_BPO_53B
 * Version          : 1.7
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
 *  2009/02/09    1.6   A.Shiina         �C��(�{�ԏ�Q#1117�Ή��F�݌ɃN���[�Y�`�F�b�N�ǉ�)
 *  2009/02/09    1.7   A.Shiina         �C��(�{�ԏ�Q#1129�Ή��F�p�����[�^�ǉ�)
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
-- 2009/02/09 v1.7 UPDATE START
--     ,retcode               OUT    VARCHAR2);       --   �G���[�R�[�h
     ,retcode               OUT    VARCHAR2       --   �G���[�R�[�h
     ,iv_report_post_code   IN     VARCHAR2    -- �񍐕���
     ,iv_whse_code          IN     VARCHAR2    -- �q�ɃR�[�h
     ,iv_item_type          IN     VARCHAR2    -- �i�ڋ敪
     );
-- 2009/02/09 v1.7 UPDATE END
--
END xxinv530002c;
/
