CREATE OR REPLACE PACKAGE APPS.XXCOS011A11C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS011A11C (spec)
 * Description      : �ʏ��i�̔����тd�c�h�f�[�^�쐬
 * MD.050           : �ʏ��i�̔����тd�c�h�f�[�^�쐬 MD050_COS_011_A11
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
 *  2011/02/25    1.0   Oukou            �V�K�쐬
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_act_mode   IN     VARCHAR2,         --   1.���s�敪�i�쐬/����/�đ��M�j
    iv_date       IN     VARCHAR2          --   2.�Ɩ����t/���M��
  );
--
END XXCOS011A11C;
/

