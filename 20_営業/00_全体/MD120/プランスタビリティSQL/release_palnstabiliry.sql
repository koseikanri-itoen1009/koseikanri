Rem /*****************************************************************************************
Rem  * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
Rem  *
Rem  * Package Name     : release_palnstabiliry
Rem  * Description      : �A�E�g���C�������[�X�p�X�N���v�g
Rem  *                    �i�v�����X�^�r���e�B�ɂ����s�v��Œ艻�@�\�j
Rem  * MD.050           : 
Rem  * Version          : 1.2
Rem  *
Rem  * Change Record
Rem  * ------------- ----- ---------------- -------------------------------------------------
Rem  *  Date          Ver.  Editor           Description
Rem  * ------------- ----- ---------------- -------------------------------------------------
Rem  *  2009/09/17    1.0   SCS D.Toyata     �V�K�쐬
Rem  *  2009/09/30    1.1   SCS K.Kanada     �p�����[�^�ǉ��i�J�e�S�� / �t�@�C���p�X�j
Rem  *  2009/10/22    1.2   SCS K.Kanada     �X�N���v�g��
Rem  *
Rem  *****************************************************************************************/

set serveroutput on
set autocommit off
set echo off
set termout off
set heading off
set pagesize 0
set linesize 10000

prompt
prompt Enter Infomation for Release Planstability 
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt Original SQL File     : &&orig_file
prompt
prompt SQL File for HINT     : &&hint_file
prompt
prompt Outline Name          : &&orig_ol_name
prompt
prompt Outline Name for HINT : &&hint_ol_name
prompt
prompt Category Name         : &&orig_category
prompt

--
--  Set up binds

variable iv_file_nohints     varchar2(100)
variable iv_file_hints       varchar2(100)
variable iv_org_ol_name      varchar2(30)
variable iv_hint_ol_name     varchar2(30)
variable iv_ol_category      varchar2(30)

BEGIN
  :iv_file_nohints  := '&orig_file' ;
  :iv_file_hints    := '&hint_file' ;
  :iv_org_ol_name   := '&orig_ol_name' ;
  :iv_hint_ol_name  := '&hint_ol_name' ;
  :iv_ol_category   := '&orig_category' ;
END ;
/

ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY/MM/DD HH24:MI:SS' ;

whenever sqlerror exit;
set termout on

DECLARE
  -- ===============================
  -- �Œ胍�[�J���萔
  -- ===============================
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
--
--#####################################  �Œ蕔 END   #############################################
--
  -- ===============================
  -- ���[�U�[�錾��
  -- ===============================
  -- *** ���[�J���萔 ***
  cv_directory               CONSTANT VARCHAR2(100) := 'XX03_PDF_DIR';
  -- *** ���[�J���ϐ� ***
  lv_debug_step              VARCHAR2(5) ;
  lv_file_nohints            VARCHAR2(100);
  lv_file_hints              VARCHAR2(100);
  lv_org_ol_name             VARCHAR2(30);
  lv_hint_ol_name            VARCHAR2(30);
  lv_ol_category             VARCHAR2(30);
  lv_sql_file                utl_file.file_type;
  lv_exec_sql_nohints        VARCHAR2(20000);
  lv_exec_sql_hints          VARCHAR2(20000);
  buffer                     VARCHAR2(1000);
  rec_outline                dba_outlines%rowtype ;
--
BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
--
--#####################################  �Œ蕔 END   #############################################
--
  --
  dbms_output.put_line(chr(13)) ;
  lv_debug_step := '0.0' ;
  --
  -- ***************************************
  -- ***        �������̋L�q             ***
  -- ***       ���ʊ֐��̌Ăяo��        ***
  -- ***************************************
  -- �p�����[�^��ϐ��ɐݒ�
  lv_file_nohints    := :iv_file_nohints  ;
  lv_file_hints      := :iv_file_hints    ;
  lv_org_ol_name     := :iv_org_ol_name   ;
  lv_hint_ol_name    := :iv_hint_ol_name  ;
  lv_ol_category     := :iv_ol_category   ;
--
  -- ***************************************
  -- ***    �A�E�g���C���쐬�i��SQL�j    ***
  -- ***************************************
  -- �q���g��Ȃ�
  lv_debug_step := '1.1' ;
  lv_exec_sql_nohints := 'CREATE OR REPLACE OUTLINE '||lv_org_ol_name||' FOR CATEGORY '||lv_ol_category||' ON ';
  --
  -- �t�@�C���I�[�v��
  lv_debug_step := '1.2' ;
  lv_sql_file         := utl_file.fopen(cv_directory,lv_file_nohints,'r');
  --
  -- �t�@�C���ǂݍ��݁A�y��SQL���s
  lv_debug_step := '1.3' ;
  LOOP
    BEGIN
      utl_file.get_line(lv_sql_file,buffer);
      -- SQL�ɒǋL
      lv_exec_sql_nohints := lv_exec_sql_nohints || ' ' || buffer;
    EXCEPTION
      -- �t�@�C�����Ō�܂œǂݍ��񂾂烋�[�v�I��
      WHEN NO_DATA_FOUND THEN
        EXIT;
    END;
    IF (buffer IS NULL OR buffer = '') THEN
      EXIT;
    END IF;
  END LOOP;
  --
  lv_debug_step := '1.4' ;
  utl_file.fclose(lv_sql_file);
  --
  lv_debug_step := '1.5' ;
  dbms_output.put_line('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
  dbms_output.put_line(lv_exec_sql_nohints);
  dbms_output.put_line('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
  -- SQL�̎��s
  execute immediate lv_exec_sql_nohints;
  --
  lv_debug_step := '1.6' ;
  --
--
  -- ***************************************
  -- *** �A�E�g���C���쐬�i�q���g��t���j***
  -- ***************************************
  -- �q���g�傠��
  lv_debug_step := '2.1' ;
  lv_exec_sql_hints := 'CREATE OR REPLACE PRIVATE OUTLINE ' || lv_hint_ol_name || ' ON ';
  --
  -- �t�@�C���I�[�v��
  lv_debug_step := '2.2' ;
  lv_sql_file       := utl_file.fopen(cv_directory,lv_file_hints,'r');
  --
  -- �t�@�C���ǂݍ��݁A�y��SQL���s
  lv_debug_step := '2.3' ;
  LOOP
    BEGIN
      utl_file.get_line(lv_sql_file,buffer);
      -- SQL�ɒǋL
      lv_exec_sql_hints := lv_exec_sql_hints || ' ' || buffer;
    EXCEPTION
      -- �t�@�C�����Ō�܂œǂݍ��񂾂烋�[�v�I��
      WHEN NO_DATA_FOUND THEN
        EXIT;
    END;
    IF (buffer IS NULL OR buffer = '') THEN
      EXIT;
    END IF;
  END LOOP;
  --
  lv_debug_step := '2.4' ;
  utl_file.fclose(lv_sql_file);
  --
  lv_debug_step := '2.5' ;
  dbms_output.put_line('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
  dbms_output.put_line(lv_exec_sql_hints);
  dbms_output.put_line('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
  -- SQL�̎��s
  execute immediate lv_exec_sql_hints;
--
  lv_debug_step := '2.6' ;
--
  -- ***************************************
  -- ***   �A�E�g���C���q���g�̒u������  ***
  -- ***************************************
  lv_debug_step := '3.1' ;
  delete 
  from   outln.ol$hints
  where  OL_NAME = lv_org_ol_name
  ;
  lv_debug_step := '3.2' ;
  delete 
  from   outln.ol$nodes
  where  OL_NAME = lv_org_ol_name
  ;
  lv_debug_step := '3.3' ;
  insert into outln.ol$hints
  select *
  from   ol$hints
  where  OL_NAME = lv_hint_ol_name
  ;
  lv_debug_step := '3.4' ;
  update outln.ol$hints
  set    OL_NAME = lv_org_ol_name
  where  OL_NAME = lv_hint_ol_name
  ;
  lv_debug_step := '3.5' ;
  insert into outln.ol$nodes
  select *
  from   ol$nodes
  where  OL_NAME = lv_hint_ol_name
  ;
  lv_debug_step := '3.6' ;
  update outln.ol$nodes
  set    OL_NAME = lv_org_ol_name
  where  OL_NAME = lv_hint_ol_name
  ;
--
  lv_debug_step := '3.7' ;
  SELECT  *
  INTO    rec_outline
  FROM    dba_outlines
  WHERE   NAME = lv_org_ol_name
  ;
--
  lv_debug_step := '3.8' ;
  dbms_output.put_line(chr(13)) ;
  dbms_output.put_line('Outline Release Complete') ;
  dbms_output.put_line('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~') ;
  dbms_output.put_line('Outline Name  : ' || rec_outline.NAME);
  dbms_output.put_line('Category Name : ' || rec_outline.CATEGORY);
  dbms_output.put_line('Timestamp     : ' || rec_outline.TIMESTAMP);
  dbms_output.put_line('Enabled       : ' || rec_outline.ENABLED);
--
  commit;
--  rollback ;
--
EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
  -- *** OTHERS��O�n���h�� ***
  WHEN OTHERS THEN
    dbms_output.put_line(chr(13)) ;
    dbms_output.put_line('ERROR <-- step:' || lv_debug_step ) ;
    dbms_output.put_line('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~') ;
    dbms_output.put_line(SQLERRM);
    rollback ;
--
--#####################################  �Œ蕔 END   #############################################
--
END ;
/
--
-- End of file
