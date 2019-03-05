CREATE OR REPLACE PACKAGE XXCSM002A19C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2019. All rights reserved.
 *
 * Package Name     : XXCSM002A19C(spec)
 * Description      : �N�ԏ��i�v��_�E�����[�h
 * MD.050           : �N�ԏ��i�v��_�E�����[�h MD050_CSM_002_A19
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
 *  2019/02/08    1.0   Y.Sasaki         �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_output_kbn   IN   VARCHAR2,         -- 1.�o�͋敪
    iv_location_cd  IN   VARCHAR2,         -- 2.���_
    iv_plan_year    IN   VARCHAR2,         -- 3.�N�x
    iv_item_group_3 IN   VARCHAR2,         -- 4.���i�Q3
    iv_output_data  IN   VARCHAR2          -- 5.�o�͒l
  );
END XXCSM002A19C;
/
