CREATE OR REPLACE PACKAGE XXCOS014A01C   --��<package_name>�͑啶���ŋL�q���ĉ������B
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A01C (spec)
 * Description      : ���[�T�[�o�ɂĔ[�i��(EDI�ȊO)�f�[�^���o�͂��邽�߂ɑΏۂƂȂ�
 *                    �[�i��(EDI�ȊO)�f�[�^���������A���[�T�[�o�����̃f�[�^���쐬���܂��B
 * MD.050           : �[�i���f�[�^�쐬(MD050_COS_014_A01)
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
 *  2008/12/25    1.0   M.Takano         �V�K�쐬
 *  2009/02/12    1.1   T.Nakamura       [��QCOS_061] ���b�Z�[�W�o�́A���O�o�͂ւ̏o�͓��e�̒ǉ��E�C��
 *  2009/02/13    1.2   T.Nakamura       [��QCOS_065] ���O�o�̓v���V�[�W��out_line�̖�����
 *                                       [��QCOS_079] �v���t�@�C���ǉ��A�J�[�\��cur_data_record�̉��C��
 *  2009/02/19    1.3   T.Nakamura       [��QCOS_109] ���O�o�͂ɃG���[���b�Z�[�W���o�͓�
 *  2009/02/20    1.4   T.Nakamura       [��QCOS_110] �t�b�^���R�[�h�쐬�������s���̃G���[�n���h�����O��ǉ�
 *  2009/03/12    1.5   T.kitajima       [T1_0033] �d��/�e�ϘA�g
 *  2009/04/02    1.6   T.kitajima       [T1_0114] �[�i���_���擾���@�ύX
 *  2009/04/13    1.7   T.kitajima       [T1_0264] ���[�l���`�F�[���X�R�[�h�ǉ��Ή�
 *  2009/04/27    1.8   K.Kiriu          [T1_0112] �P�ʍ��ړ��e�s���Ή�
 *  2009/05/15    1.9   M.Sano           [T1_0983] �`�F�[���X�w�莞�̔[�i���_�擾�C��
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf           OUT NOCOPY VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode          OUT NOCOPY VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_file_name                IN     VARCHAR2,  --  1.�t�@�C����
    iv_chain_code               IN     VARCHAR2,  --  2.�`�F�[���X�R�[�h
    iv_report_code              IN     VARCHAR2,  --  3.���[�R�[�h
    in_user_id                  IN     NUMBER,    --  4.���[�UID
    iv_chain_name               IN     VARCHAR2,  --  5.�`�F�[���X��
    iv_store_code               IN     VARCHAR2,  --  6.�X�܃R�[�h
    iv_cust_code                IN     VARCHAR2,  --  7.�ڋq�R�[�h
    iv_base_code                IN     VARCHAR2,  --  8.���_�R�[�h
    iv_base_name                IN     VARCHAR2,  --  9.���_��
    iv_data_type_code           IN     VARCHAR2,  -- 10.���[��ʃR�[�h
    iv_ebs_business_series_code IN     VARCHAR2,  -- 11.�Ɩ��n��R�[�h
    iv_report_name              IN     VARCHAR2,  -- 12.���[�l��
    iv_shop_delivery_date_from  IN     VARCHAR2,  -- 13.�X�ܔ[�i��(FROM�j
    iv_shop_delivery_date_to    IN     VARCHAR2,  -- 14.�X�ܔ[�i���iTO�j
    iv_publish_div              IN     VARCHAR2,  -- 15.�[�i�����s�敪
--******************************************* 2009/04/13 1.7 T.Kitajima ADD START *************************************
--    in_publish_flag_seq         IN     NUMBER     -- 16.�[�i�����s�t���O����
    in_publish_flag_seq         IN     NUMBER,    -- 16.�[�i�����s�t���O����
    iv_ssm_store_code           IN     VARCHAR2   -- 17.���[�l���`�F�[���X�R�[�h
--******************************************* 2009/04/13 1.7 T.Kitajima ADD  END  *************************************
  );
END XXCOS014A01C;
/
