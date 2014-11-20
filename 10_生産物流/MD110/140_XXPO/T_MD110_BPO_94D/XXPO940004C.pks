CREATE OR REPLACE PACKAGE xxpo940004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO940004C(spec)
 * Description      : �d���E�L���E�ړ���񒊏o����
 * MD.050           : ���Y��������                  T_MD050_BPO_940
 * MD.070           : �d���E�L���E�ړ���񒊏o����  T_MD070_BPO_94D
 * Version          : 1.0
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
 *  2008/06/10    1.0   Oracle �R�� ��_ ����쐬
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                  OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                 OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h    --# �Œ� #
    iv_wf_ope_div        IN            VARCHAR2,  --  1.�����敪          (�K�{)
    iv_wf_class          IN            VARCHAR2,  --  2.�Ώ�              (�K�{)
    iv_wf_notification   IN            VARCHAR2,  --  3.����              (�K�{)
    iv_data_class        IN            VARCHAR2,  --  4.�f�[�^���        (�K�{)
    iv_ship_no_from      IN            VARCHAR2,  --  5.�z��No.FROM       (�C��)
    iv_ship_no_to        IN            VARCHAR2,  --  6.�z��No.TO         (�C��)
    iv_req_no_from       IN            VARCHAR2,  --  7.�˗�No.FROM       (�C��)
    iv_req_no_to         IN            VARCHAR2,  --  8.�˗�No.TO         (�C��)
    iv_vendor_code       IN            VARCHAR2,  --  9.�����            (�C��)
    iv_mediation         IN            VARCHAR2,  -- 10.������            (�C��)
    iv_location_code     IN            VARCHAR2,  -- 11.�o�ɑq��          (�C��)
    iv_arvl_code         IN            VARCHAR2,  -- 12.���ɑq��          (�C��)
    iv_vendor_site_code  IN            VARCHAR2,  -- 13.�z����            (�C��)
    iv_carrier_code      IN            VARCHAR2,  -- 14.�^���Ǝ�          (�C��)
    iv_ship_date_from    IN            VARCHAR2,  -- 15.�[����/�o�ɓ�FROM (�K�{)
    iv_ship_date_to      IN            VARCHAR2,  -- 16.�[����/�o�ɓ�TO   (�K�{)
    iv_arrival_date_from IN            VARCHAR2,  -- 17.���ɓ�FROM        (�C��)
    iv_arrival_date_to   IN            VARCHAR2,  -- 18.���ɓ�TO          (�C��)
    iv_instruction_dept  IN            VARCHAR2,  -- 19.�w������          (�C��)
    iv_item_no           IN            VARCHAR2,  -- 20.�i��              (�C��)
    iv_update_time_from  IN            VARCHAR2,  -- 21.�X�V����FROM      (�C��)
    iv_update_time_to    IN            VARCHAR2,  -- 22.�X�V����TO        (�C��)
    iv_prod_class        IN            VARCHAR2,  -- 23.���i�敪          (�C��)
    iv_item_class        IN            VARCHAR2,  -- 24.�i�ڋ敪          (�C��)
    iv_sec_class         IN            VARCHAR2   -- 25.�Z�L�����e�B�敪  (�K�{)
    );
END xxpo940004c;
/
