CREATE OR REPLACE PACKAGE BODY xx03_file_download_pkg
AS
/*****************************************************************************************
 * 
 * Copyright(c) Oracle Corporation Japan, 2005. All rights reserved.
 *
 * Package Name           : xx03_file_download_pkg(body)
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
 *   2009/09/09    11.5.10.1.6   K.Shirasuna  E_T3_00509�FRAC�\���Ή�
 *
 *****************************************************************************************/
--
  /**********************************************************************************
   * Procedure Name   : PREPARE_FILE
   * Description      : �_�E�����[�h����t�@�C����BFILE�I�u�W�F�N�g���쐬���܂��B
   ***********************************************************************************/
  PROCEDURE PREPARE_FILE(
     iv_file_name IN  VARCHAR2     -- 1.�t�@�C���p�X
    ,ov_errbuf    OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode   OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg    OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
        PRAGMA AUTONOMOUS_TRANSACTION;  --�����g�����U�N�V������
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_download_pkg.prepare_file'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--################################  �Œ蕔 END   ###############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- PDF�t�@�C�����i�[����f�B���N�g����I�u�W�F�N�g
    cv_pdf_directory_object CONSTANT VARCHAR2(30) := 'XX03_PDF_DIR';
    -- OUT�t�@�C�����i�[����f�B���N�g���E�I�u�W�F�N�g
    cv_out_directory_object CONSTANT VARCHAR2(30) := 'XX03_OUTFILE_DIR';
-- 2009/09/09_ADD_start-11.5.10.1.6---------------------------------------------
-- �f�B���N�g���p�X�̓��ꉻ(RAC�\���Ή�)
    cv_msg_kbn_cfo          CONSTANT VARCHAR2(5)  := 'XXCFO';            -- �A�h�I���F��v�E�A�h�I���̈�̃A�v���P�[�V�����Z�k��
    cv_msg_00001            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001'; -- �v���t�@�C���擾�G���[���b�Z�[�W
    cv_tkn_prof             CONSTANT VARCHAR2(20) := 'PROF_NAME';        -- �g�[�N���F�v���t�@�C����
    --
    cv_rac_db1              CONSTANT VARCHAR2(30) := 'XXCFO1_RAC_DB1';   -- 1���@�f�B���N�g�����v���t�@�C����
    cv_rac_db2              CONSTANT VARCHAR2(30) := 'XXCFO1_RAC_DB2';   -- 2���@�f�B���N�g�����v���t�@�C����
    cv_rac_db3              CONSTANT VARCHAR2(30) := 'XXCFO1_RAC_DB3';   -- 3���@�f�B���N�g�����v���t�@�C����
-- 2009/09/09_ADD_end-11.5.10.1.6-----------------------------------------------
--
    -- *** ���[�J���ϐ� ***
    -- ���̓t�@�C���p�X�̃f�B���N�g����
    lv_directory ALL_DIRECTORIES.DIRECTORY_PATH%TYPE;
    -- ���̓t�@�C���p�X�̃t�@�C������
    lv_file ALL_DIRECTORIES.DIRECTORY_PATH%TYPE;
    -- PDF�t�@�C�����u����Ă���f�B���N�g��
    lv_pdf_directory ALL_DIRECTORIES.DIRECTORY_PATH%TYPE;
    -- OUT�t�@�C�����u����Ă���f�B���N�g��
    lv_out_directory ALL_DIRECTORIES.DIRECTORY_PATH%TYPE;
    -- ���ۂɎg�p����f�B���N�g���E�I�u�W�F�N�g��
    lv_directory_object_to_use ALL_DIRECTORIES.DIRECTORY_NAME%TYPE;
-- 2009/09/09_ADD_start-11.5.10.1.6---------------------------------------------
-- �f�B���N�g���p�X�̓��ꉻ(RAC�\���Ή�)
    -- 1���@�f�B���N�g�����v���t�@�C��
    lv_rac_db1 VARCHAR2(100);
    -- 2���@�f�B���N�g�����v���t�@�C��
    lv_rac_db2 VARCHAR2(100);
    -- 3���@�f�B���N�g�����v���t�@�C��
    lv_rac_db3 VARCHAR2(100);
-- 2009/09/09_ADD_end-11.5.10.1.6-----------------------------------------------
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    out_of_directory_expt  EXCEPTION; -- �_�E�����[�h�\�ȃf�B���N�g�����O��Ă���B
    illegal_file_name_expt EXCEPTION; -- �t�@�C�������s���ł���B
-- 2009/09/09_ADD_start-11.5.10.1.6---------------------------------------------
    api_expt               EXCEPTION; -- ���ʊ֐���O
-- 2009/09/09_ADD_end-11.5.10.1.6-----------------------------------------------
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
-- 2009/09/09_ADD_start-11.5.10.1.6---------------------------------------------
--
    -- �v���t�@�C������DB�f�B���N�g�������擾
    lv_rac_db1 := FND_PROFILE.VALUE(cv_rac_db1); -- 1���@
    -- �擾�G���[��
    IF (lv_rac_db1 IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(cv_msg_kbn_cfo    -- �A�v���P�[�V�����Z�k��
                                                   ,cv_msg_00001      -- �v���t�@�C���擾�G���[
                                                   ,cv_tkn_prof       -- �g�[�N���F�v���t�@�C����
                                                   ,xxcfr_common_pkg.get_user_profile_name(cv_rac_db1))
                                                                      -- GL��v����ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE api_expt;
    END IF;
    --
    -- �v���t�@�C������DB�f�B���N�g�������擾
    lv_rac_db2 := FND_PROFILE.VALUE(cv_rac_db2); -- 2���@
    -- �擾�G���[��
    IF (lv_rac_db2 IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(cv_msg_kbn_cfo    -- �A�v���P�[�V�����Z�k��
                                                   ,cv_msg_00001      -- �v���t�@�C���擾�G���[
                                                   ,cv_tkn_prof       -- �g�[�N���F�v���t�@�C����
                                                   ,xxcfr_common_pkg.get_user_profile_name(cv_rac_db2))
                                                                      -- GL��v����ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE api_expt;
    END IF;
    --
    lv_rac_db3 := FND_PROFILE.VALUE(cv_rac_db3); -- 3���@
    -- �擾�G���[��
    IF (lv_rac_db3 IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(cv_msg_kbn_cfo    -- �A�v���P�[�V�����Z�k��
                                                   ,cv_msg_00001      -- �v���t�@�C���擾�G���[
                                                   ,cv_tkn_prof       -- �g�[�N���F�v���t�@�C����
                                                   ,xxcfr_common_pkg.get_user_profile_name(cv_rac_db3))
                                                                      -- GL��v����ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE api_expt;
    END IF;
    --
--
-- 2009/09/09_ADD_end-11.5.10.1.6-----------------------------------------------
-- PDF�����݂���f�B���N�g�����擾�B
--
    SELECT
      RTRIM(ad.DIRECTORY_PATH, '/')
    INTO
      lv_pdf_directory
    FROM
      sys.ALL_DIRECTORIES ad
    WHERE
      ad.DIRECTORY_NAME=cv_pdf_directory_object;
--
-- OUT�����݂���f�B���N�g�����擾�B
--
    SELECT
      RTRIM(ad.DIRECTORY_PATH, '/')
    INTO
      lv_out_directory
    FROM
      sys.ALL_DIRECTORIES ad
    WHERE
      ad.DIRECTORY_NAME=cv_out_directory_object;
--
-- �p�X������
--
    lv_file := SUBSTR(iv_file_name, INSTR(iv_file_name, '/', -1, 1) + 1);
    lv_directory := SUBSTR(iv_file_name, 1,INSTR(iv_file_name, '/', -1, 1)-1);
--
-- 2009/09/09_ADD_start-11.5.10.1.6---------------------------------------------
-- �f�B���N�g���p�X�̓��ꉻ(RAC�\���Ή�)
    IF (INSTR(lv_directory, lv_rac_db1) > 0) THEN     -- 1���@
      NULL;
    ELSIF (INSTR(lv_directory, lv_rac_db2) > 0) THEN -- 2���@
      lv_directory := REPLACE(lv_directory, lv_rac_db2, lv_rac_db1);
    ELSIF (INSTR(lv_directory, lv_rac_db3) > 0) THEN -- 3���@
      lv_directory := REPLACE(lv_directory, lv_rac_db3, lv_rac_db1);
    ELSE
      NULL;
    END IF;
-- 2009/09/09_ADD_end-11.5.10.1.6-----------------------------------------------
-- �t�@�C�������`�F�b�N
--
    IF (lv_file IS NULL OR lv_file = '') THEN
      lv_errmsg := xx00_message_pkg.get_msg('XX03','APP-XX03-14147');
      lv_errbuf := lv_errmsg;
      RAISE illegal_file_name_expt;
    END IF;
--
-- �f�B���N�g�����`�F�b�N���āA�g�p����f�B���N�g���E�I�u�W�F�N�g������B
--
    IF (lv_directory = lv_pdf_directory) THEN
      lv_directory_object_to_use := cv_pdf_directory_object;
    ELSIF (lv_directory = lv_out_directory) THEN
      lv_directory_object_to_use := cv_out_directory_object;
    ELSE
      lv_errmsg := xx00_message_pkg.get_msg('XX03','APP-XX03-14146');
      lv_errbuf := lv_errmsg;
      RAISE out_of_directory_expt;
    END IF;
--
-- ���Ƀ��R�[�h�����݂���ꍇ�͈�U�폜�B
--
    DELETE FROM xx03_download_file_pool
    WHERE full_file_name = iv_file_name;
--
-- �V�������R�[�h���쐻�B
--
    INSERT INTO xx03_download_file_pool(
       full_file_name
      ,file_data
      ,created_by
      ,creation_date
      ,last_updated_by
      ,last_update_date
      ,last_update_login
      ,request_id
      ,program_application_id
      ,program_id
      ,program_update_date
    )VALUES(
       iv_file_name
      ,BFILENAME(lv_directory_object_to_use,lv_file)
      ,xx00_global_pkg.user_id
      ,xx00_date_pkg.get_system_datetime_f
      ,xx00_global_pkg.user_id
      ,xx00_date_pkg.get_system_datetime_f
      ,xx00_global_pkg. login_id
      ,xx00_global_pkg.conc_request_id
      ,xx00_global_pkg.prog_appl_id
      ,xx00_global_pkg.conc_program_id
      ,xx00_date_pkg.get_system_datetime_f
    );
--
    COMMIT;
--
  EXCEPTION
    WHEN out_of_directory_expt THEN                --*** �_�E�����[�h�ΏۊO�̃f�B���N�g�����w�肳��Ă���B ***
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# �C�� #
      ROLLBACK;
      RETURN;
    WHEN illegal_file_name_expt THEN               --*** �t�@�C�������s���ł���B ***--
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# �C�� #
      ROLLBACK;
      RETURN;
-- 2009/09/09_ADD_start-11.5.10.1.6---------------------------------------------
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
      ROLLBACK;
      RETURN;
-- 2009/09/09_ADD_end-11.5.10.1.6-----------------------------------------------
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END prepare_file;
END xx03_file_download_pkg;
/
