CREATE OR REPLACE PACKAGE XXCOS004A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS004A02C (spec)
 * Description      : ���i�ʔ���v�Z
 * MD.050           : ���i�ʔ���v�Z MD050_COS_004_A02
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
 *  2008/12/10    1.0   T.kitajima       �V�K�쐬
 *  2009/02/05    1.1   T.miyashita      [COS_022]�P�ʊ��Z�̕s�
 *  2009/02/05    1.2   T.kitajima       [COS_023]�ԍ��t���O�ݒ�s�(�d�l�R��)
 *  2009/02/10    1.3   T.kitajima       [COS_041]�[�i�`�[�敪(1:�[�i)�ݒ�(�d�l�R��)
 *  2009/02/10    1.4   T.kitajima       [COS_047]�������ׂ̔[�i/��P��(�d�l�R��)
 *  2009/02/19    1.5   T.kitajima       �[�i�`�ԋ敪 ���C���q�ɑΉ�
 *  2009/02/24    1.6   T.kitajima       �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf             OUT NOCOPY VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode            OUT NOCOPY VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
    iv_exec_div        IN         VARCHAR2,         -- 1.��������敪
    iv_base_code       IN         VARCHAR2,         -- 2.���_�R�[�h
    iv_customer_number IN         VARCHAR2          -- 3.�ڋq�R�[�h
  );
END XXCOS004A02C;
/
