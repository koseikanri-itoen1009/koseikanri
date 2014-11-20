CREATE OR REPLACE PROCEDURE xxcmn_blob_proc(
  document_id      IN VARCHAR2
 ,display_type     IN VARCHAR2
 ,document         IN OUT BLOB
 ,document_type    IN OUT VARCHAR2)
IS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Proc Name           : xxcmn_blob_proc
 * Description            : ���[�N�t���[�p�t�@�C���ǂݎ��֐�
 * MD.070(CMD.050)        : �Ȃ�
 * Version                : 1.0
 * �O��:
 * ���̃v���V�[�W����document_id�Ƀf�B���N�g���I�u�W�F�N�g��
 * �ƃt�@�C������,����؂蕶���Ƃ���������œn����邱�Ƃ�z�肵�Ă��܂��B
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/03/05   1.0   ORACLE           �V�K�쐬
 *
 *****************************************************************************************/
--
  lv_dir            VARCHAR2(1000);   -- �f�B���N�g��
  lv_filename       VARCHAR2(200);    -- �t�@�C����
  ln_pos            NUMBER;           -- ��؂蕶���ʒu
--
  h_bfile           BFILE;
  ln_dest_offset    INTEGER;
  ln_src_offset     INTEGER;
--
  lv_content_type   VARCHAR2(100);
--
  lv_amount         INTEGER;
--
BEGIN
--
  -- ��؂蕶���̈ʒu�����
  ln_pos  := INSTR(document_id,',');
--
  -- �f�B���N�g�����i�[
  lv_dir  :=  SUBSTR(document_id,1,ln_pos - 1 );
--
  -- �t�@�C�����i�[
  lv_filename :=  SUBSTR(document_id,ln_pos + 1);
--
  -- BFILE�쐬
  h_bfile := BFILENAME( lv_dir, lv_filename);
  DBMS_LOB.FILEOPEN(h_bfile, DBMS_LOB.FILE_READONLY);
--
  -- �t�@�C���T�C�Y���`�F�b�N
  lv_amount := DBMS_LOB.GETLENGTH(h_bfile);
--
  -- �t�@�C������łȂ��ꍇ�̓t�@�C����ǂݍ���
  IF(lv_amount <> 0) THEN
    -- �t�@�C�����ꎞBLOB�֓ǂݍ���
    ln_dest_offset := 1;
    ln_src_offset  := 1;
    DBMS_LOB.LOADBLOBFROMFILE(
      document,
      h_bfile,
      DBMS_LOB.LOBMAXSIZE,
      ln_dest_offset,
      ln_src_offset
    );
  END IF;
  DBMS_LOB.CLOSE(h_bfile);
--
  -- �_�E�����[�h����鎞�p�̐ݒ�
  document_type := 'text/csv; name=' || lv_filename;
--
EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('LOBDOC_PKG', 'bdoc', document_id, display_type);
    RAISE;
END xxcmn_blob_proc;
/
