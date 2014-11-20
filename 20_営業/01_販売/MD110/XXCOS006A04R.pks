CREATE OR REPLACE PACKAGE XXCOS006A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS006A04R (spec)
 * Description      : �o�׈˗���
 * MD.050           : �o�׈˗��� MD050_COS_006_A04
 * Version          : 1.1
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
 *  2008/11/04    1.0   K.Kakishita      �V�K�쐬
 *  2009/02/26    1.1   K.Kakishita      ���[�R���J�����g�N����̃��[�N�e�[�u���폜������
 *                                       �R�����g�����O���B
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_ship_from_subinv_code  IN      VARCHAR2,         -- 1.�o�׌��q��
    iv_ordered_date_from      IN      VARCHAR2,         -- 2.�󒍓��iFrom�j
    iv_ordered_date_to        IN      VARCHAR2          -- 3.�󒍓��iTo�j
  );
END XXCOS006A04R;
/
