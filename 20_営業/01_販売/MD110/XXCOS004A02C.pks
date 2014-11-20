CREATE OR REPLACE PACKAGE XXCOS004A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS004A02C (spec)
 * Description      : ���i�ʔ���v�Z
 * MD.050           : ���i�ʔ���v�Z MD050_COS_004_A02
 * Version          : 1.13
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
 *  2009/02/24    1.6   T.kitajima       �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/03/30    1.7   T.kitajima       [T1_0189]�̔����і���.�[�i���הԍ��̍̔ԕ��@�ύX
 *  2009/04/20    1.8   T.kitajima       [T1_0657]�f�[�^�擾0���G���[���x���I����
 *  2009/04/28    1.9   N.Maeda          [T1_0769]���ʌn�A���z�n�̎Z�o���@�̏C��
 *  2009/05/07    1.10  T.kitajima       [T1_0888]�[�i���_�擾���@�ύX
 *                                       [T1_0714]�݌ɕi�ڐ���0���O�Ή�
 *  2009/05/26    1.11  T.kitajima       [T1_1217]�P���l�̌ܓ�
 *  2009/06/09    1.12  T.kitajima       [T1_1371]�s���b�N
 *  2009/06/10    1.12  T.kitajima       [T1_1412]�[�i�`�[�ԍ��擾�����ύX
 *  2009/06/11    1.13  T.kitajima       [T1_1415]�[�i�`�[�ԍ��擾�����ύX
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
