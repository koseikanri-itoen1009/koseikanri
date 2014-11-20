CREATE OR REPLACE PACKAGE XXCOI006A17R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A17R(spec)
 * Description      : �󕥎c���\�i���_�ʌv�j
 * MD.050           : �󕥎c���\�i���_�ʌv�j <MD050_XXCOI_006_A17>
 * Version          : V1.0
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
 *  2008/11/13    1.0   H.Sasaki         ���ō쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT    VARCHAR2,        -- �G���[���b�Z�[�W #�Œ�#
    retcode           OUT    VARCHAR2,        -- �G���[�R�[�h     #�Œ�#
    iv_reception_date IN  VARCHAR2,           -- 1.�󕥔N��
    iv_cost_type      IN  VARCHAR2            -- 2.�����敪
  );
END XXCOI006A17R;
/
