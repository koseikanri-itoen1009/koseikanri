CREATE OR REPLACE PACKAGE XXCOS014A11C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A11C (spec)
 * Description      : ���ɗ\��f�[�^�̍쐬���s��
 * MD.050           : ���ɗ\����f�[�^�쐬 (MD050_COS_014_A11)
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
 *  2009/03/16    1.0   K.Kiriu          �V�K�쐬
 *  2009/07/01    1.1   K.Kiriu          [T1_1359]���ʊ��Z�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                OUT    VARCHAR2,  --    �G���[���b�Z�[�W #�Œ�#
    retcode               OUT    VARCHAR2,  --    �G���[�R�[�h     #�Œ�#
    iv_file_name          IN     VARCHAR2,  --  1.�t�@�C����
    iv_chain_code         IN     VARCHAR2,  --  2.�`�F�[���X�R�[�h
    iv_report_code        IN     VARCHAR2,  --  3.���[�R�[�h
    iv_user_id            IN     VARCHAR2,  --  4.���[�UID
    iv_chain_name         IN     VARCHAR2,  --  5.�`�F�[���X��
    iv_store_code         IN     VARCHAR2,  --  6.�X�܃R�[�h
    iv_base_code          IN     VARCHAR2,  --  7.���_�R�[�h
    iv_base_name          IN     VARCHAR2,  --  8.���_��
    iv_data_type_code     IN     VARCHAR2,  --  9.���[��ʃR�[�h
    iv_oprtn_series_code  IN     VARCHAR2,  -- 10.�Ɩ��n��R�[�h
    iv_report_name        IN     VARCHAR2,  -- 11.���[�l��
    iv_to_subinv_code     IN     VARCHAR2,  -- 12.������ۊǏꏊ�R�[�h
    iv_center_code        IN     VARCHAR2,  -- 13.�Z���^�[�R�[�h
    iv_invoice_number     IN     VARCHAR2,  -- 14.�`�[�ԍ�
    iv_sch_ship_date_from IN     VARCHAR2,  -- 15.�o�ח\���FROM
    iv_sch_ship_date_to   IN     VARCHAR2,  -- 16.�o�ח\���TO
    iv_sch_arrv_date_from IN     VARCHAR2,  -- 17.���ɗ\���FROM
    iv_sch_arrv_date_to   IN     VARCHAR2,  -- 18.���ɗ\���TO
    iv_move_order_number  IN     VARCHAR2,  -- 19.�ړ��I�[�_�[�ԍ�
    iv_edi_send_flag      IN     VARCHAR2   -- 20.EDI���M��
  );
END XXCOS014A11C;
/
