CREATE OR REPLACE PACKAGE XXCOI001A02R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI001A02R(spec)
 * Description      : �w�肳�ꂽ�����ɕR�Â����Ɋm�F���̃��X�g���o�͂��܂��B
 * MD.050           : ���ɖ��m�F���X�g MD050_COI_001_A02 
 * Version          : 1.0
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
 *  2008/12/08    1.0   S.Moriyama       main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
       errbuf        OUT VARCHAR2                                     --   �G���[���b�Z�[�W #�Œ�#
     , retcode       OUT VARCHAR2                                     --   �G���[�R�[�h     #�Œ�#
     , iv_base_code   IN VARCHAR2                                     --   1.���_�R�[�h
     , iv_output_type IN VARCHAR2                                     --   2.�o�͋敪
     , iv_date_from   IN VARCHAR2                                     --   3.�o�͓��t�i���j
     , iv_date_to     IN VARCHAR2                                     --   4.�o�͓��t�i���j
  );
END XXCOI001A02R;
/
