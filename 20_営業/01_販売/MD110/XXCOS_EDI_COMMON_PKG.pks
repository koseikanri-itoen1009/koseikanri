CREATE OR REPLACE PACKAGE xxcos_edi_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcos_edi_common_pkg(spec)
 * Description            :
 * MD.070                 : MD070_IPO_COS_���ʊ֐�
 * Version                : 1.1
 *
 * Program List
 *  ----------------------------- ---- ----- -----------------------------------------
 *   Name                         Type  Ret   Description
 *  ----------------------------- ---- ----- -----------------------------------------
 *  edi_manual_order_acquisition  P          EDI�󒍎���͕��捞
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/11/26   1.0   H.Fujimoto       �V�K�쐬
 *  2009/03/03   1.1   H.Fujimoto       �����s�No152
 *****************************************************************************************/
 --
  -- EDI�󒍎���͕��捞
  PROCEDURE edi_manual_order_acquisition(
               iv_edi_chain_code           IN VARCHAR2  DEFAULT NULL  -- EDI�`�F�[���X�R�[�h
              ,iv_edi_forward_number       IN VARCHAR2  DEFAULT NULL  -- EDI�`���ǔ�
              ,id_shop_delivery_date_from  IN DATE      DEFAULT NULL  -- �X�ܔ[�i��(From)
              ,id_shop_delivery_date_to    IN DATE      DEFAULT NULL  -- �X�ܔ[�i��(To)
              ,iv_regular_ar_sale_class    IN VARCHAR2  DEFAULT NULL  -- ��ԓ����敪
              ,iv_area_code                IN VARCHAR2  DEFAULT NULL  -- �n��R�[�h
              ,id_center_delivery_date     IN DATE      DEFAULT NULL  -- �Z���^�[�[�i��
              ,in_organization_id          IN NUMBER    DEFAULT NULL  -- �݌ɑg�DID
              ,ov_errbuf                   OUT NOCOPY VARCHAR2        -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,ov_retcode                  OUT NOCOPY VARCHAR2        -- ���^�[���E�R�[�h             --# �Œ� #
              ,ov_errmsg                   OUT NOCOPY VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
 --
END xxcos_edi_common_pkg;
/
