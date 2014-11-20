CREATE OR REPLACE PACKAGE XXCOI009A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI009A05R(body)
 * Description      : �����u�c���i�ʃ`�F�b�N���X�g
 * MD.050           : �����u�c���i�ʃ`�F�b�N���X�g <MD050_XXCOI_009_A05>
 * Version          : V1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/03/02    1.0   H.Sasaki         ���ō쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf            OUT VARCHAR2        --   �G���[���b�Z�[�W #�Œ�#
    , retcode           OUT VARCHAR2        --   �G���[�R�[�h     #�Œ�#
    , iv_base_code      IN  VARCHAR2        --  ���_�R�[�h
    , iv_date_from      IN  VARCHAR2        --  �o�͊���(FROM)
    , iv_date_to        IN  VARCHAR2        --  �o�͊���(TO)
    , iv_conclusion_day IN  VARCHAR2        --  ���ߓ�
    , iv_customer_code  IN  VARCHAR2        --  �ڋq�R�[�h
  );
END XXCOI009A05R;
/
