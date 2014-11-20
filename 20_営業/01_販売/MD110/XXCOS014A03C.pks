CREATE OR REPLACE PACKAGE XXCOS014A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A03C (spec)
 * Description      : �[�i�m����f�[�^�쐬(EDI)
 * MD.050           : �[�i�m����f�[�^�쐬(EDI) MD050_COS_014_A03 
 * Version          : 1.9
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
 *  2008/12/22    1.0   H.Noda           �V�K�쐬
 *  2009/02/12    1.1   T.Nakamura       [��QCOS_061] ���b�Z�[�W�o�́A���O�o�͂ւ̏o�͓��e�̒ǉ��E�C��
 *  2009/02/13    1.2   T.Nakamura       [��QCOS_065] ���O�o�̓v���V�[�W��out_line�̖�����
 *  2009/02/16    1.3   T.Nakamura       [��QCOS_079] �v���t�@�C���ǉ��A�J�[�\��cur_data_record�̉��C��
 *  2009/02/17    1.4   T.Nakamura       [��QCOS_094] CSV�o�͍��ڂ̏C��
 *  2009/02/19    1.5   T.Nakamura       [��QCOS_109] ���O�o�͂ɃG���[���b�Z�[�W���o�͓�
 *  2009/02/20    1.6   T.Nakamura       [��QCOS_110] �t�b�^���R�[�h�쐬�������s���̃G���[�n���h�����O��ǉ�
 *  2009/04/02    1.7   T.Kitajima       [T1_0114] �[�i���_���擾���@�ύX
 *  2009/04/27    1.8   K.Kiriu          [T1_0112] �P�ʍ��ړ��e�s���Ή�
 *  2009/06/16    1.9   T.Kitajima       [T1_1348] �sNo�̌��������ύX
 *  2009/06/16    1.9   T.Kitajima       [T1_1358] ��ԓ����敪0��00,1��01,2��02
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_file_name                 IN     VARCHAR2,  --  1.�t�@�C����
    iv_chain_code                IN     VARCHAR2,  --  2.�`�F�[���X�R�[�h
    iv_report_code               IN     VARCHAR2,  --  3.���[�R�[�h
    in_user_id                   IN     NUMBER,    --  4.���[�UID
    iv_chain_name                IN     VARCHAR2,  --  5.�`�F�[���X��
    iv_store_code                IN     VARCHAR2,  --  6.�X�܃R�[�h
    iv_base_code                 IN     VARCHAR2,  --  7.���_�R�[�h
    iv_base_name                 IN     VARCHAR2,  --  8.���_��
    iv_data_type_code            IN     VARCHAR2,  --  9.���[��ʃR�[�h
    iv_ebs_business_series_code  IN     VARCHAR2,  -- 10.�Ɩ��n��R�[�h
    iv_info_div                  IN     VARCHAR2,  -- 11.���敪
    iv_report_name               IN     VARCHAR2,  -- 12.���[�l��
    iv_shop_delivery_date_from   IN     VARCHAR2,  -- 13.�X�ܔ[�i��(FROM�j
    iv_shop_delivery_date_to     IN     VARCHAR2   -- 14.�X�ܔ[�i���iTO�j
  );
END XXCOS014A03C;
/
