create or replace PACKAGE XXCOI002A04R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI002A04R(spec)
 * Description      : ���i�p�p�`�[
 * MD.050           : ���i�p�p�`�[ MD050_COI_002_A04
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
 *  2012/09/05    1.0   K.Furuyama       main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf               OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode              OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_year_month        IN     VARCHAR2,         --   1.�N��
    iv_day               IN     VARCHAR2,         --   2.��
    iv_kyoten            IN     VARCHAR2,         --   3.���_
    iv_output_dpt        IN     VARCHAR2          --   4.���[�o�͏ꏊ
  );
END XXCOI002A04R;
/
