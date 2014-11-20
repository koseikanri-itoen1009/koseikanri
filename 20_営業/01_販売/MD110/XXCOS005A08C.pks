CREATE OR REPLACE PACKAGE APPS.XXCOS005A08C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS005A08C (spec)
 * Description      : CSV�t�@�C���̎󒍎捞
 * MD.050           : CSV�t�@�C���̎󒍎捞 MD050_COS_005_A08_
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
 *  2008/11/25    1.0   S.Kitaura        �V�K�쐬
 *  2009/2/3      1.1   K.Atsushiba      COS_001 �Ή�
 *                                         �E(A-7)5.�[�i���ғ����`�F�b�N�̉ғ������o�֐��̃p�����[�^�u�ۊǑq�ɃR�[�h�v
 *                                           ��NULL�A�u���[�h�^�C���v��0�ɏC���B
 *                                         �E(A-7)7.�o�ח\����Z�o�̉ғ������o�֐��̃p�����[�^�u�ۊǑq�ɃR�[�h�v��
 *                                           NULL�ɏC���B
 *  2009/2/3      1.2   T.Miyata         COS_008,010 �Ή�
 *                                         �E�u2-1.�i�ڃA�h�I���}�X�^�̃`�F�b�N�v
 *                                              Disc�i�ڂ�Disc�i�ڃA�h�I���̌�����������
 *                                         �E�uset_order_data    �f�[�^�ݒ菈���v
 *                                              ���ۂ̏ꍇ�̒P�ʂ�NULL�˃v���t�@�C������擾�����P��(CS)�֏C��
 *                                         �E�uset_order_data    �f�[�^�ݒ菈���v
 *                                              �v�����Ɏ󒍓��ł͂Ȃ��[�i����ݒ�
 *                                         �E�uset_order_data    �f�[�^�ݒ菈���v
 *                                              �w�b�_�C���ׂ̃R���e�L�X�g�Ɋe�󒍃^�C�v��ݒ�
 *  2009/02/19    1.3   T.kitajima       �󒍃C���|�[�g�Ăяo���Ή�
 *                                       get_msg�̃p�b�P�[�W���C��
 *  2009/2/20     1.4   T.Miyashita      �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/04/06    1.5   T.Kitajima       [T1_0313]�z����ԍ��̃f�[�^�^�C��
 *                                       [T1_0314]�o�׌��ۊǏꏊ�擾�C��
 *  2009/05/19    1.6   T.Kitajima       [T1_0242]�i�ڎ擾���AOPM�i�ڃ}�X�^.�����i�����j�J�n�������ǉ�
 *                                       [T1_0243]�i�ڎ擾���A�q�i�ڑΏۊO�����ǉ�
 *  2009/07/10    1.7   T.Tominaga       [0000137]Interval,Max_wait��FND_PROFILE���擾
 *  2009/07/14    1.8   T.Miyata         [0000478]�ڋq���ݒn�̒��o�����ɗL���t���O��ǉ�
 *  2009/07/15    1.9   T.Miyata         [0000066]�N������R���J�����g��ύX�F�󒍃C���|�[�g�ˎ󒍃C���|�[�g�G���[���m
 *  2009/07/17    1.10  K.Kiriu          [0000469]�I�[�_�[No�f�[�^�^�s���Ή�
 *  2009/07/21    1.11  T.Miyata         [0000478�w�E�Ή�]TOO_MANY_ROWS��O�擾
 *  2009/08/21    1.12  M.Sano           [0000302]JAN�R�[�h����̕i�ڎ擾���ڋq�i�ڌo�R�ɕύX
 *  2009/10/30    1.13  N.Maeda          [0001113]XXCMN_CUST_ACCT_SITES2_V�̍i���ݎ���OU�ؑ֏�����ǉ�(org_id)
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT VARCHAR2, -- �G���[���b�Z�[�W #�Œ�#
    retcode           OUT VARCHAR2, -- �G���[�R�[�h     #�Œ�#
    in_get_file_id    IN  NUMBER,   -- 1.<file_id>
    iv_get_format_pat IN  VARCHAR2  -- 2.<�t�H�[�}�b�g�p�^�[��>
  );
--
END XXCOS005A08C;
/
