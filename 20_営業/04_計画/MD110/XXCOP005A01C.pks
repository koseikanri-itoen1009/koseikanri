create or replace PACKAGE XXCOP005A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP005A01C(spec)
 * Description      : �H��o�׌v��
 * MD.050           : �H��o�׌v�� MD050_COP_005_A01
 * Version          : 1.6
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
 *  2008/12/02    1.00 SCS �F�c�k��     main�V�K�쐬
 *  2009/02/25    1.1   SCS Uda          �����e�X�g�d�l�ύX�i������QNo.014�j
 *  2009/04/07    1.2   SCS Uda          �V�X�e���e�X�g��Q�Ή��iT1_0277�AT1_0278�AT1_0280�AT1_0281�AT1_0368�j
 *  2009/04/14    1.3   SCS Uda          �V�X�e���e�X�g��Q�Ή��iT1_0542�j
 *  2009/04/21    1.4   SCS Uda          �V�X�e���e�X�g��Q�Ή��iT1_0722�j
 *  2009/04/28    1.5   SCS Uda          �V�X�e���e�X�g��Q�Ή��iT1_0845�AT1_0847�j
 *  2009/05/20    1.6   SCS Uda          �V�X�e���e�X�g��Q�Ή��iT1_1096�j
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf           OUT VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode          OUT VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_plan_type     IN  VARCHAR2,         --   1.�v��敪
    iv_pace_from     IN  VARCHAR2,         --   2.�o�׃y�[�X(����)����FROM
    iv_pace_to       IN  VARCHAR2,         --   3.�o�׃y�[�X�i���сj����TO
    iv_forcast_type  IN  VARCHAR2          --   4.�o�ח\������
   );
END XXCOP005A01C;
