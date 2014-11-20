CREATE OR REPLACE PACKAGE APPS.XXCOP006A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP006A01C(spec)
 * Description      : �����v��
 * MD.050           : �����v�� MD050_COP_006_A01
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
 *  2009/01/19    1.0   Y.Goto           �V�K�쐬
 *  2009/04/07    1.1   Y.Goto           T1_0273,T1_0274,T1_0289,T1_0366,T1_0367�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf           OUT    VARCHAR2,   --   �G���[���b�Z�[�W #�Œ�#
    retcode          OUT    VARCHAR2,   --   �G���[�R�[�h     #�Œ�#
    iv_plan_type     IN     VARCHAR2,   -- 1.�v��敪
    iv_shipment_from IN     VARCHAR2,   -- 2.�o�׃y�[�X�v�����(FROM)
    iv_shipment_to   IN     VARCHAR2,   -- 3.�o�׃y�[�X�v�����(TO)
    iv_forcast_type  IN     VARCHAR2    -- 4.�o�ח\���敪
  );
END XXCOP006A01C;
/
