CREATE OR REPLACE PACKAGE XXCOP004A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A04R(spec)
 * Description      : ����v��`�F�b�N���X�g�o�̓��[�N�o�^
 * MD.050           : ����v��`�F�b�N���X�g MD050_COP_004_A04
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
 *  2008/11/03    1.0  SCS.Kikuchi       main�V�K�쐬
 *  2009/03/03    1.1  SCS.Kikuchi       SVF�����Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_target_month     IN  VARCHAR2,         -- 1.�Ώ۔N��
    iv_prod_class_code  IN  VARCHAR2,         -- 2.���i�敪
    iv_base_code        IN  VARCHAR2,         -- 3.���_
    iv_whse_code        IN  VARCHAR2          -- 4.�o�׊Ǘ���
   );
END XXCOP004A04R;
/
