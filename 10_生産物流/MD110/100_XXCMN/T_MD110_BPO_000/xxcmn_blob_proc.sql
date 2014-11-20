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
 * Description            : ワークフロー用ファイル読み取り関数
 * MD.070(CMD.050)        : なし
 * Version                : 1.0
 * 前提:
 * このプロシージャはdocument_idにディレクトリオブジェクト名
 * とファイル名が,を区切り文字とした文字列で渡されることを想定しています。
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/03/05   1.0   ORACLE           新規作成
 *
 *****************************************************************************************/
--
  lv_dir            VARCHAR2(1000);   -- ディレクトリ
  lv_filename       VARCHAR2(200);    -- ファイル名
  ln_pos            NUMBER;           -- 区切り文字位置
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
  -- 区切り文字の位置を特定
  ln_pos  := INSTR(document_id,',');
--
  -- ディレクトリ名格納
  lv_dir  :=  SUBSTR(document_id,1,ln_pos - 1 );
--
  -- ファイル名格納
  lv_filename :=  SUBSTR(document_id,ln_pos + 1);
--
  -- BFILE作成
  h_bfile := BFILENAME( lv_dir, lv_filename);
  DBMS_LOB.FILEOPEN(h_bfile, DBMS_LOB.FILE_READONLY);
--
  -- ファイルサイズをチェック
  lv_amount := DBMS_LOB.GETLENGTH(h_bfile);
--
  -- ファイルが空でない場合はファイルを読み込む
  IF(lv_amount <> 0) THEN
    -- ファイルを一時BLOBへ読み込み
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
  -- ダウンロードされる時用の設定
  document_type := 'text/csv; name=' || lv_filename;
--
EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('LOBDOC_PKG', 'bdoc', document_id, display_type);
    RAISE;
END xxcmn_blob_proc;
/
