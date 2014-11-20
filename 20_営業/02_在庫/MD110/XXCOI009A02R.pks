create or replace PACKAGE XXCOI009A02R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI009A02R(spec)
 * Description      : �q�֏o�ɖ��׃��X�g
 * MD.050           : �q�֏o�ɖ��׃��X�g MD050_COI_009_A02
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
 *  2008/12/04    1.0  SCS.Tsuboi         main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf               OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode              OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_transaction_type  IN     VARCHAR2,         --   1.����^�C�v
    iv_year_month        IN     VARCHAR2,         --   2.�N��
    iv_day               IN     VARCHAR2,         --   3.��
    iv_out_kyoten        IN     VARCHAR2,         --   4.�o�ɋ��_
    iv_output_dpt        IN     VARCHAR2          --   5.���[�o�͏ꏊ
  );
END XXCOI009A02R;
/
