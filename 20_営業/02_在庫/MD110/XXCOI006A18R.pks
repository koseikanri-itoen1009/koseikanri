CREATE OR REPLACE PACKAGE XXCOI006A18R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A18R(spec)
 * Description      : ���o���ו\�i���_�ʁE���v�j
 * MD.050           : ���o���ו\�i���_�ʁE���v�j <MD050_XXCOI_006_A18>
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
 *  2008/12/11    1.0   Y.Kobayashi      ���ō쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT    VARCHAR2,        -- �G���[���b�Z�[�W #�Œ�#
    retcode           OUT    VARCHAR2,        -- �G���[�R�[�h     #�Œ�#
    iv_output_kbn     IN     VARCHAR2,        -- 1.�o�͋敪
    iv_reception_date IN     VARCHAR2,        -- 2.�󕥔N��
    iv_cost_type      IN     VARCHAR2,        -- 3.�����敪
    iv_base_code      IN     VARCHAR2         -- 4.���_�R�[�h
  );
END XXCOI006A18R;
/
