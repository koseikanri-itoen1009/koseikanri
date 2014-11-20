CREATE OR REPLACE PACKAGE XXCOS_TASK_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS_TASK_PKG(spec)
 * Description      : ���ʊ֐��p�b�P�[�W(�̔�)
 * MD.070           : ���ʊ֐�    MD070_IPO_COS
 * Version          : 1.3
 *
 * Program List
 * --------------------------- ------ ---------- -----------------------------------------
 *  Name                        Type   Return     Description
 * --------------------------- ------ ---------- -----------------------------------------
 *  task_entry                  P                 �K��E�L�����ѓo�^
 *  
 * Change Record
 * ------------- ----- ---------------- --------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- --------------------------------------------------
 *  2008/12/12    1.0   T.kitajima       �V�K�쐬
 *  2009/02/18    1.1   T.kitajima       [COS_091]����VD�Ή�
 *  2009/05/18    1.2   T.kitajima       [T1_0652]������񎞂̓o�^���\�[�X�ԍ��K�{����
 *  2009/11/24    1.3   S.Miyakoshi      TASK�f�[�^�擾���̓��t�̏����ύX
 *
 ****************************************************************************************/
--
  /************************************************************************
   * Procedure Name  : task_entry
   * Description     : �K��E�L�����ѓo�^
   ************************************************************************/
  PROCEDURE task_entry(
               ov_errbuf          OUT NOCOPY  VARCHAR2                --�G���[���b�Z�[�W
              ,ov_retcode         OUT NOCOPY  VARCHAR2                --���^�[���R�[�h
              ,ov_errmsg          OUT NOCOPY  VARCHAR2                --���[�U�[�E�G���[�E���b�Z�[�W
              ,in_resource_id     IN          NUMBER    DEFAULT NULL  --���\�[�XID
              ,in_party_id        IN          NUMBER    DEFAULT NULL  --�p�[�e�BID
              ,iv_party_name      IN          VARCHAR2  DEFAULT NULL  --�p�[�e�B����
              ,id_visit_date      IN          DATE      DEFAULT NULL  --�K�����
              ,iv_description     IN          VARCHAR2  DEFAULT NULL  --�ڍד��e
              ,in_sales_amount    IN          NUMBER    DEFAULT NULL  --������z(2008/12/12 �ǉ�)
              ,iv_input_division  IN          VARCHAR2  DEFAULT NULL  --���͋敪(2008/12/17 �ǉ�)
              ,iv_entry_class     IN          VARCHAR2  DEFAULT NULL  --�c�e�e�P�Q�i�o�^�敪�j
              ,iv_source_no       IN          VARCHAR2  DEFAULT NULL  --�c�e�e�P�R�i�o�^���\�[�X�ԍ��j
              ,iv_customer_status IN          VARCHAR2  DEFAULT NULL  --�c�e�e�P�S�i�ڋq�X�e�[�^�X�j
              );
  --
END XXCOS_TASK_PKG;
/
