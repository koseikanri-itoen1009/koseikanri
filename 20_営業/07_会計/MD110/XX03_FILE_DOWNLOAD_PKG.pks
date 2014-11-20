CREATE OR REPLACE PACKAGE xx03_file_download_pkg
AS
/*****************************************************************************************
 * 
 * Copyright(c) Oracle Corporation Japan, 2005. All rights reserved.
 *
 * Package Name           : xx03_file_download_pkg(spec)
 * Description            : �_�E�����[�h����t�@�C����BFILE�I�u�W�F�N�g��p�ӂ��܂��B
 * MD.070                 : �_�E�����[�h�t�@�C���ۑ� xxxx_MD070_DCC_401_001
 * Version                : 11.5.10.1.5
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *   prepare_file         P          �_�E�����[�h����t�@�C����BFILE�I�u�W�F�N�g���쐬���܂��B
 *
 * Change Record
 *  ------------- ------------- ------------ -----------------------------------------
 *   Date          Ver.          Editor       Description
 *  ------------- ------------- ------------ -----------------------------------------
 *   2005/10/05    11.5.10.1.5   S.Morisawa   �V�K�쐬
 *
 *****************************************************************************************/
--
-- �_�E�����[�h����t�@�C����BFILE�I�u�W�F�N�g��p�ӂ���B
  PROCEDURE prepare_file(
     iv_file_name IN  VARCHAR2    -- 1.BFILE�I�u�W�F�N�g�̎w���t�@�C����
    ,ov_errbuf    OUT VARCHAR2    -- (�Œ�)�G���[�E���b�Z�[�W
    ,ov_retcode   OUT VARCHAR2    -- (�Œ�)���^�[���E�R�[�h
    ,ov_errmsg    OUT VARCHAR2    -- (�Œ�)���[�U�[�E�G���[�E���b�Z�[�W
  );
--
END xx03_file_download_pkg;
/
