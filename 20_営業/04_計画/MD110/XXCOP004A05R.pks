CREATE OR REPLACE PACKAGE XXCOP004A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A05R(spec)
 * Description      : ����v�旧�ĕ\�o�̓��[�N�o�^
 * MD.050           : ����v�旧�ĕ\ MD050_COP_004_A05
 * Version          : 1.2
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
 *  2008/12/29    1.0  SCS.Kikuchi       main�V�K�쐬
 *  2009/03/04    1.1  SCS.Kikuchi       SVF�����Ή�
 *  2009/04/28    1.2  SCS.Kikuchi       T1_0645,T1_0838�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf              OUT VARCHAR2,      --   �G���[���b�Z�[�W #�Œ�#
    retcode             OUT VARCHAR2,      --   �G���[�R�[�h     #�Œ�#
    iv_prod_class_code  IN  VARCHAR2,      -- 2.���i�敪
    iv_base_code        IN  VARCHAR2       -- 3.���_
   );
END XXCOP004A05R;
/
