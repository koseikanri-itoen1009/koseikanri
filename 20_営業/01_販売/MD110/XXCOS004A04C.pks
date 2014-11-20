CREATE OR REPLACE PACKAGE XXCOS004A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS004A04C (spec)
 * Description      : ����VD�[�i�f�[�^�쐬
 * MD.050           : ����VD�[�i�f�[�^�쐬 MD050_COS_004_A04
 * Version          : 1.8
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
 *  2009/1/14    1.0   T.Miyashita      �V�K�쐬
 *  2009/02/04   1.1   T.miyashita       [COS_013]INV��v���Ԏ擾�s�
 *  2009/02/04   1.2   T.miyashita       [COS_017]��P���ƐŔ���P���̕s�
 *  2009/02/04   1.3   T.miyashita       [COS_024]�̔����z�̕s�
 *  2009/02/04   1.4   T.miyashita       [COS_028]�쐬���敪�̕s�
 *  2009/02/19   1.5   T.miyashita       [COS_091]�K��E�L���̌����̎捞�R��Ή�
 *  2009/02/20   1.6   T.Miyashita       �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/02/23   1.7   T.Miyashita       [COS_116]�[�i���Z�b�g�s�
 *  2009/02/23   1.8   T.Miyashita       [COS_122]�c�ƒS�����R�[�h�Z�b�g�s�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf             OUT NOCOPY VARCHAR2, -- �G���[���b�Z�[�W #�Œ�#
    retcode            OUT NOCOPY VARCHAR2, -- �G���[�R�[�h     #�Œ�#
    iv_exec_div        IN  VARCHAR2,        -- 1.��������敪
    iv_base_code       IN  VARCHAR2,        -- 2.���_�R�[�h
    iv_customer_number IN  VARCHAR2         -- 3.�ڋq�R�[�h
  );
--
END XXCOS004A04C;
/
