create or replace PACKAGE XXCOI009A03R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI009A03R(spec)
 * Description      : �H����ɖ��׃��X�g
 * MD.050           : �H����ɖ��׃��X�g MD050_COI_009_A03
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
 *  2008/10/31    1.0  SCS.Tsuboi         main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_year_month IN     VARCHAR2,         --   1.�N��
    iv_in_kyoten  IN     VARCHAR2,         --   2.���ɋ��_
    iv_item_ctgr  IN     VARCHAR2,         --   3.�i�ڃJ�e�S��
    iv_output_dpt IN     VARCHAR2          --   4.���[�o�͏ꏊ
  );
END XXCOI009A03R;
/
