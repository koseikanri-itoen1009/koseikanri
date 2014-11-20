create or replace
PACKAGE XXCOS014A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A10C(spec)
 * Description      : �a���VD�[�i�`�[�f�[�^�쐬
 * MD.050           : �a���VD�[�i�`�[�f�[�^�쐬 (MD050_COS_014_A10)
 * Version          : 1.2
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
 *  2009/03/06    1.0   S.Nakanishi      main�V�K�쐬
 *  2009/03/19    1.1   S.Nakanishi      ��QNo.159�Ή�
 *  2009/04/30    1.2   T.Miyata         [T1_0891]�ŏI�s��[/]�t�^
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                      OUT VARCHAR2,       -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                     OUT VARCHAR2,       -- ���^�[���E�R�[�h    --# �Œ� #
    iv_file_name                IN VARCHAR2,        -- 1.�t�@�C����
    iv_chain_code               IN VARCHAR2,        -- 2.�`�F�[���X�R�[�h
    iv_report_code              IN VARCHAR2,        -- 3.���[�R�[�h
    in_user_id                  IN NUMBER,          -- 4.���[�U�[ID
    iv_base_code                IN VARCHAR2,        -- 5.���_�R�[�h
    iv_base_name                IN VARCHAR2,        -- 6.���_��
    iv_chain_name               IN VARCHAR2,        -- 7.�`�F�[���X��
    iv_report_type_code         IN VARCHAR2,        -- 8.���[��ʃR�[�h
    iv_ebs_business_series_code IN VARCHAR2,        -- 9.�Ɩ��n��R�[�h
    iv_report_mode              IN VARCHAR2,        --10.���[�l��
    in_group_id                 IN NUMBER           --11.�O���[�vID
  );
  --
END XXCOS014A10C;
/
