CREATE OR REPLACE PACKAGE XXCOS001A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS001A01C (spec)
 * Description      : �[�i�f�[�^�̎捞���s��
 * MD.050           : HHT�[�i�f�[�^�捞 (MD050_COS_001_A01)
 * Version          : 1.4
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
 *  2008/11/18    1.0   S.Miyakoshi      �V�K�쐬
 *  2009/02/03    1.1   S.Miyakoshi      [COS_003]�S�ݓXHHT�敪�ύX�ɑΉ�
 *                                       [COS_004]�G���[���X�g�ւ̘A�g�f�[�^�̕s������ɑΉ�
 *  2009/02/05    1.2   S.Miyakoshi      [COS_034]�i��ID�̒��o���ڂ�ύX
 *  2009/02/20    1.3   S.Miyakoshi      �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/02/26    1.4   S.Miyakoshi      �]�ƈ��̗����Ǘ��Ή�(xxcos_rs_info_v)
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_mode       IN     VARCHAR2          --   �N�����[�h�i1:���� or 2:��ԁj
  );
END XXCOS001A01C;
/
