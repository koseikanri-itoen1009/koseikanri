CREATE OR REPLACE PACKAGE XXCOS005A08C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS005A08C (spec)
 * Description      : CSV�t�@�C���̎󒍎捞
 * MD.050           : CSV�t�@�C���̎󒍎捞 MD050_COS_005_A08_
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
