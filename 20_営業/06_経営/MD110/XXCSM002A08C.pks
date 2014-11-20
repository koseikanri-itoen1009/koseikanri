CREATE OR REPLACE PACKAGE XXCSM002A08C AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A08C(spec)
 * Description      : ���ʏ��i�v��(�c�ƌ���)�`�F�b�N���X�g�o��
 * MD.050           : ���ʏ��i�v��(�c�ƌ���)�`�F�b�N���X�g�o�� MD050_CSM_002_A08
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 *
 *  main                �y�R���J�����g���s�t�@�C���o�^�v���V�[�W���z
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/15    1.0   S.son        �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                 OUT    NOCOPY VARCHAR2,         --   �G���[���b�Z�[�W
    retcode                OUT    NOCOPY VARCHAR2,         --   �G���[�R�[�h
    iv_subject_year        IN     VARCHAR2,                --   �Ώ۔N�x
    iv_location_cd         IN     VARCHAR2,                --   ���_�R�[�h
    iv_hierarchy_level     IN     VARCHAR2                 --   �K�w
  );
END XXCSM002A08C;
/
