CREATE OR REPLACE PACKAGE APPS.XXCOS005A09C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS005A09C (spec)
 * Description      : CSV�f�[�^�A�b�v���[�h�i�ڋq�i�ځj
 * MD.050           : CSV�f�[�^�A�b�v���[�h�i�ڋq�i�ځj MD050_COS_005_A09
 * Version          : 2.0
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
 *  2008/12/24    1.0   T.Miyashita      �V�K�쐬
 *  2009/2/3      1.1   K.Atsushiba      COS_002�Ή� ���ڃ`�F�b�N�Ōڋq�i�ړE�v�A�����P�ʁA�o�׌��ۊǏꏊ��K�{����
 *                                                   �C�ӂɕύX�B
 *                                       COS_006�Ή� �����P�ʂ�NULL�̏ꍇ�A�u�{�v��ݒ�B
 *                                       COS_007�Ή� �ۊǏꏊ��NULL�̏ꍇ�A�}�X�^���݃`�F�b�N�����Ȃ��悤�ɏC���B
 *  2009/2/17     1.4   T.Miyashita      get_msg�̃p�b�P�[�W���C��
 *  2009/2/20     1.5   T.Miyashita      �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/03/25    1.6   S.Kayahara       �ŏI�s�ɃX���b�V���ǉ�
 *  2009/07/01    1.7   T.Tominaga       [0000137]Interval,Max_wait��FND_PROFILE���擾
 *  2009/09/10    1.8   N.Maeda          [0001326]�ڋq�i�ڑ��ݎQ�Əd���`�F�b�N�̏C��
 *  2010/01/07    1.9   M.Sano           [E_�{�ғ�_00739]�w�肵���`�F�[���X�ȊO�͕ۊǏꏊ��ݒ肵�Ȃ��悤�ɏC��
 *                                       [E_�{�ғ�_00740]�q�i�ڃR�[�h�`�F�b�N�̒ǉ�
 *  2010/02/03    2.0   T.Nakano         [E_�{�ғ�_01155]�P�ʕs���G���[�ǉ��C��
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT NOCOPY VARCHAR2, -- �G���[���b�Z�[�W #�Œ�#
    retcode           OUT NOCOPY VARCHAR2, -- �G���[�R�[�h     #�Œ�#
    in_get_file_id    IN  NUMBER,   -- 1.<file_id>
    iv_get_format_pat IN  VARCHAR2  -- 2.<�t�H�[�}�b�g�p�^�[��>
  );
--
END XXCOS005A09C;
/
