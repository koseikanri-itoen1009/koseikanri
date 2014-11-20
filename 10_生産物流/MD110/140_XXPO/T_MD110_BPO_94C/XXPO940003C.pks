CREATE OR REPLACE PACKAGE xxpo940003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo940003c(spec)
 * Description      : ���b�g�݌ɏ�񒊏o����
 * MD.050           : ���Y��������                  T_MD050_BPO_940
 * MD.070           : ���b�g�݌ɏ�񒊏o����        T_MD070_BPO_94C
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
 *  2008/07/01    1.0   Oracle �勴 �F�Y ����쐬
 *  2008/08/01    1.1   Oracle �g�c �Ď� ST�s��Ή�&PT�Ή�
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                  OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                 OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h    --# �Œ� #
    iv_wf_ope_div        IN            VARCHAR2,  --  1.�����敪          (�K�{)
    iv_wf_class          IN            VARCHAR2,  --  2.�Ώ�              (�K�{)
    iv_wf_notification   IN            VARCHAR2,  --  3.����              (�K�{)
    iv_prod_class        IN            VARCHAR2,  --  4.���i�敪          (�K�{)
    iv_item_class        IN            VARCHAR2,  --  5.�i�ڋ敪          (�K�{)
    iv_frequent_whse_div IN            VARCHAR2,  --  6.��\�q�ɋ敪      (�C��)
    iv_whse              IN            VARCHAR2,  --  7.�q��              (�C��)
    iv_vendor_id         IN            VARCHAR2,  --  8.�����            (�C��)
    iv_item_no           IN            VARCHAR2,  --  9.�i��              (�C��)
    iv_lot_no            IN            VARCHAR2,  -- 10.���b�g            (�C��)
    iv_Manufacture_date  IN            VARCHAR2,  -- 11.������            (�C��)
    iv_expiration_date   IN            VARCHAR2,  -- 12.�ܖ�����          (�C��)
    iv_uniqe_sign        IN            VARCHAR2,  -- 13.�ŗL�L��          (�C��)
    iv_mf_factory        IN            VARCHAR2,  -- 14.�����H��          (�C��)
    iv_mf_lot            IN            VARCHAR2,  -- 15.�������b�g        (�C��)
    iv_home              IN            VARCHAR2,  -- 16.�Y�n              (�C��)
    iv_r1                IN            VARCHAR2,  -- 17.R1                (�C��)
    iv_r2                IN            VARCHAR2,  -- 18.R2                (�C��)
    iv_sec_class         IN            VARCHAR2   -- 19.�Z�L�����e�B�敪  (�K�{)
    );
END xxpo940003c;
/
