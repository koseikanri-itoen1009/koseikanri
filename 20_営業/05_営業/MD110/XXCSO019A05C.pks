CREATE OR REPLACE PACKAGE APPS.XXCSO019A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A05C(spec)
 * Description      : �v���̔��s��ʂ���A�K�┄��v��Ǘ��\�𒠕[�ɏo�͂��܂��B
 * MD.050           : MD050_CSO_019_A05_�K�┄��v��Ǘ��\_Draft2.0A
 * Version          : 1.0
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  
 * submain              
 * main                  �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-05    1.0   Seirin.Kin        �V�K�쐬
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
 *
 *****************************************************************************************/
 --
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT NOCOPY VARCHAR2          -- �G���[���b�Z�[�W #�Œ�#
   ,retcode           OUT NOCOPY VARCHAR2          -- �G���[�R�[�h     #�Œ�#
   ,iv_year_month     IN         VARCHAR2          -- ��N��
   ,iv_report_type    IN         VARCHAR2          -- ���[���
   ,iv_base_code      IN         VARCHAR2          -- ���_�R�[�h
  );
END XXCSO019A05C;
/
