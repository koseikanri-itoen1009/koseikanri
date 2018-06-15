CREATE OR REPLACE PACKAGE XXCOS_COMMON3_PKG
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCOS_COMMON3_PKG(spec)
 * Description      : ���ʊ֐��p�b�P�[�W3(�̔�)
 * MD.070           : ���ʊ֐�    MD070_IPO_COS
 * Version          : 1.1
 *
 * Program List
 * --------------------------- ------ ---------- -----------------------------------------
 *  Name                        Type   Return     Description
 * --------------------------- ------ ---------- -----------------------------------------
 *  process_order               P                 oe_order_pub.process_order�̃p�b�P�[�W�֐�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/04/18    1.0   H.Sasaki         �V�K�쐬
 *  2018/06/12    1.1   H.Sasaki         �P���̎����X�V����[E_�{�ғ�_14886]
 *
 *****************************************************************************************/
--
  /**********************************************************************************
   * Procedure Name   : process_order
   * Description      : oe_order_pub.process_order�̃p�b�P�[�W�֐�
   ***********************************************************************************/
  PROCEDURE process_order(
      iv_upd_status_booked    IN  VARCHAR2                                              --  �X�e�[�^�X�X�V�t���O�i�L���j
    , iv_upd_request_date     IN  VARCHAR2                                              --  �����X�V�t���O
--  2018/06/12 V1.1 Added START
    , iv_upd_item_code        IN  VARCHAR2                                              --  �i�ڍX�V�t���O
--  2018/06/12 V1.1 Added END
    , it_header_id            IN  oe_order_headers_all.header_id%TYPE                   --  �w�b�_ID
    , it_line_id              IN  oe_order_lines_all.line_id%TYPE                       --  ����ID
    , it_inventory_item_id    IN  oe_order_lines_all.inventory_item_id%TYPE             --  �i��ID
    , it_ordered_quantity     IN  oe_order_lines_all.ordered_quantity%TYPE              --  �󒍐���
    , it_reason_code          IN  oe_reasons.reason_code%TYPE                           --  ���R�R�[�h
    , it_request_date         IN  oe_order_lines_all.request_date%TYPE                  --  �[�i�\���
    , it_subinv_code          IN  oe_order_lines_all.subinventory%TYPE                  --  �ۊǏꏊ
    , ov_errbuf               OUT NOCOPY VARCHAR2                                       --  �G���[�E���b�Z�[�W�G���[       #�Œ�#
    , ov_retcode              OUT NOCOPY VARCHAR2                                       --  ���^�[���E�R�[�h               #�Œ�#
    , ov_errmsg               OUT NOCOPY VARCHAR2                                       --  ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
  );
--
END XXCOS_COMMON3_PKG;
/
