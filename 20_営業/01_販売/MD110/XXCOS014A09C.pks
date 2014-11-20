CREATE OR REPLACE PACKAGE APPS.XXCOS014A09C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A09C (spec)
 * Description      : �S�ݓX�����f�[�^�쐬 
 * MD.050           : �S�ݓX�����f�[�^�쐬 MD050_COS_014_A09
 * Version          : 1.5
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
 *  2009/02/18    1.0   H.Noda           �V�K�쐬
 *  2009/03/18    1.1   Y.Tsubomatsu     [��QCOS_156] �p�����[�^�̌��g��(���[�R�[�h,���[�l��)
 *  2009/03/19    1.2   Y.Tsubomatsu     [��QCOS_158] �p�����[�^�̕ҏW(�S�ݓX�R�[�h,�S�ݓX�X�܃R�[�h,�}��)
 *  2009/04/17    1.3   T.Kitajima       [T1_0375] �G���[���b�Z�[�W�󒍔ԍ��C��(�`�[�ԍ�����No)
 *  2009/09/07    1.4   N.Maeda          [0000403] �}�Ԃ̔C�Ӊ��ɔ����}�Ԗ��̃��[�v�����ǉ�
 *  2009/11/05    1.5   N.Maeda          [E_T4_00123]�ЃR�[�h�Z�b�g���e�C��
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
    iv_dept_code                 IN     VARCHAR2,  --  5.�S�ݓX�R�[�h
    iv_dept_name                 IN     VARCHAR2,  --  6.�S�ݓX��
    iv_dept_store_code           IN     VARCHAR2,  --  7.�S�ݓX�X�܃R�[�h
    iv_edaban                    IN     VARCHAR2,  --  8.�}��
    iv_base_code                 IN     VARCHAR2,  --  9.���_�R�[�h
    iv_base_name                 IN     VARCHAR2,  -- 10.���_��
    iv_data_type_code            IN     VARCHAR2,  -- 11.���[��ʃR�[�h
    iv_ebs_business_series_code  IN     VARCHAR2,  -- 12.�Ɩ��n��R�[�h
    iv_report_name               IN     VARCHAR2,  -- 13.���[�l��
    iv_shop_delivery_date_from   IN     VARCHAR2,  -- 14.�X�ܔ[�i��(FROM�j
    iv_shop_delivery_date_to     IN     VARCHAR2,  -- 15.�X�ܔ[�i���iTO�j
    iv_publish_div               IN     VARCHAR2,  -- 16.�[�i�����s�敪
    in_publish_flag_seq          IN     NUMBER     -- 17.�[�i�����s�t���O����
  );
END XXCOS014A09C;
/
