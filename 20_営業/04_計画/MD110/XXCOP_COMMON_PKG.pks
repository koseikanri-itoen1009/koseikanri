CREATE OR REPLACE PACKAGE XXCOP_COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP_COMMON_PKG(spec)
 * Description      : ���ʊ֐��p�b�P�[�W(�v��)
 * MD.050           : ���ʊ֐�    MD070_IPO_COP
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- -------------------------------------------------------
 *  get_charge_base_code     01.�S�����_�擾�֐�
 *  get_case_quantity        02.�P�[�X�����Z�֐�
 *  delete_upload_table      03.�t�@�C���A�b�v���[�h�e�[�u���f�[�^�폜����
 *  chk_date_format          04.���t�^�`�F�b�N�֐�
 *  chk_number_format        05.���l�^�`�F�b�N�֐�
 *  put_debug_message        06.�f�o�b�O���b�Z�[�W�o�͊֐�
 *  char_delim_partition     07.�f���~�^���������֐�
 *  get_upload_table_info    08.�t�@�C���A�b�v���[�h�e�[�u�����擾
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/04    1.0                   �V�K�쐬
 *  2009/03/25    1.1   S.Kayahara      �ŏI�s�ɃX���b�V���ǉ�
 *
 *****************************************************************************************/
--
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^
  -- ===============================
  TYPE g_char_ttype IS TABLE OF VARCHAR2(256)   INDEX BY BINARY_INTEGER;    -- �f���~�^�����i�[�p
--
/************************************************************************
 * Function Name   : get_charge_base_code
 * Description     : ���[�U�ɕR�Â����_�R�[�h���擾����
 ************************************************************************/
  FUNCTION get_charge_base_code
  ( in_user_id      IN NUMBER             -- ���[�U�[ID
  , id_target_date  IN DATE               -- �Ώۓ�
  )
  RETURN VARCHAR2;                        -- ���_�R�[�h
/************************************************************************
 * Function Name   : get_case_quantity
 * Description     : �i�ڃR�[�h�A����(�i�ڂ̊�P�ʂƂ���j���A
 *                   OPM�i�ڃ}�X�^���Q�Ƃ��A�P�[�X��������P�[�X�����Z�o����
 ************************************************************************/
  PROCEDURE get_case_quantity
  ( iv_item_no                IN  VARCHAR2       -- �i�ڃR�[�h
  , in_individual_quantity    IN  NUMBER         -- �o������
  , in_trunc_digits           IN  NUMBER         -- �؎̂Č���
  , on_case_quantity          OUT NUMBER         -- �P�[�X����
  , ov_retcode                OUT VARCHAR2       -- ���^�[���R�[�h
  , ov_errbuf                 OUT VARCHAR2       -- �G���[�E���b�Z�[�W
  , ov_errmsg                 OUT VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
;
/************************************************************************
 * Procedure Name  : delete_upload_table
 * Description     : �t�@�C���A�b�v���[�h�C���^�[�t�F�[�X�e�[�u����
 *                   �f�[�^���폜����
 ************************************************************************/
  PROCEDURE delete_upload_table
  ( in_file_id    IN  NUMBER          -- �t�@�C���h�c
  , ov_retcode    OUT VARCHAR2        -- ���^�[���R�[�h
  , ov_errbuf     OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_errmsg     OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
/************************************************************************
 * Procedure Name  : chk_date_format
 * Description     : ���t�^�`�F�b�N�֐�
 ************************************************************************/
  FUNCTION chk_date_format
  ( iv_value      IN  VARCHAR2        -- ������
  , iv_format     IN  VARCHAR2        -- ����
  )
  RETURN BOOLEAN;
/************************************************************************
 * Procedure Name  : chk_number_format
 * Description     : ���l�^�`�F�b�N�֐�
 ************************************************************************/
  FUNCTION chk_number_format
  ( iv_value      IN  VARCHAR2        -- ������
  )
  RETURN BOOLEAN;
/************************************************************************
 * Procedure Name  : put_debug_message
 * Description     : �f�o�b�O���b�Z�[�W�o�͊֐�
 ************************************************************************/
  PROCEDURE put_debug_message(
    iv_value       IN      VARCHAR2     -- ������
  , iov_debug_mode IN OUT  VARCHAR2     -- �f�o�b�O���[�h
  );
/************************************************************************
 * Procedure Name  : char_delim_partition
 * Description     : �f���~�^���������֐�
 ************************************************************************/
  PROCEDURE char_delim_partition(
    iv_char       IN  VARCHAR2        -- �Ώە�����
  , iv_delim      IN  VARCHAR2        -- �f���~�^
  , o_char_tab    OUT g_char_ttype    -- ��������
  , ov_retcode    OUT VARCHAR2        -- ���^�[���R�[�h
  , ov_errbuf     OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_errmsg     OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
/************************************************************************
 * Procedure Name  : get_upload_table_info
 * Description     : �t�@�C���A�b�v���[�h�e�[�u�����擾
 ************************************************************************/
  PROCEDURE get_upload_table_info(
    in_file_id     IN  NUMBER          -- �t�@�C��ID
  , iv_format      IN  VARCHAR2        -- �t�H�[�}�b�g�p�^�[��
  , ov_upload_name OUT VARCHAR2        -- �t�@�C���A�b�v���[�h����
  , ov_file_name   OUT VARCHAR2        -- �t�@�C����
  , od_upload_date OUT DATE            -- �A�b�v���[�h����
  , ov_retcode     OUT VARCHAR2        -- ���^�[���R�[�h
  , ov_errbuf      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_errmsg      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
END XXCOP_COMMON_PKG;
/
