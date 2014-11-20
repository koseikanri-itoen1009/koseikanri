CREATE OR REPLACE PACKAGE APPS.XXCOS_COMMON2_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : XXCOS_COMMON2_PKG(spec)
 * Description            : 
 * MD.070                 : MD070_IPO_COS_���ʊ֐�
 * Version                : 1.10
 *
 * Program List
 *  --------------------          ---- ----- --------------------------------------------------
 *   Name                         Type  Ret   Description
 *  --------------------          ---- ----- --------------------------------------------------
 *  get_unit_price                  F  NUMBER   �P���擾�֐�
 *  conv_ebs_cust_code              P           �ڋq�R�[�h�ϊ��iEDI��EBS)
 *  conv_edi_cust_code              P           �ڋq�R�[�h�ϊ��iEBS��EDI)
 *  conv_ebs_item_code              P           �i�ڃR�[�h�ϊ��iEDI��EBS)
 *  conv_edi_item_code              P           �i�ڃR�[�h�ϊ��iEBS��EDI)
 *  get_layout_info                 P           ���C�A�E�g��`���擾
 *  makeup_data_record              P           �f�[�^���R�[�h�ҏW
 *  convert_quantity                P           EDI���[�������ʊ��Z�֐�
 *  get_deliv_slip_flag             F           �[�i�����s�t���O�擾�֐�
 *  get_deliv_slip_flag_area        F           �[�i�����s�t���O�S�̎擾�֐�
 *  get_salesrep_id                 P           �S���c�ƈ��擾�֐�
 *  get_reason_code                 F           ���R�R�[�h�擾�֐�
 *  get_reason_data                 P           ���R�R�[�h�}�X�^�f�[�^�擾�֐�
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/11/27    1.0  SCS              �V�K�쐬
 *  2009/02/24    1.1  H.Fujimoto       �����s�No.129
 *  2009/03/11    1.2  K.Kumamoto       I_E_048(�S�ݓX�����)�P�̃e�X�g��Q�Ή� (SPEC�C��)
 *  2009/03/31    1.3  T.Kitajima       [T1_0026]makeup_data_record��NUMBER,DATE�ҏW�ύX
 *  2009/04/16    1.4  T.Kitajima       [T1_0543]conv_edi_item_code �P�[�XJAN�AJAN�R�[�hNULL�Ή�
 *  2009/06/23    1.5  K.Kiriu          [T1_1359]EDI���[�������ʊ��Z�֐��̒ǉ�
 *  2009/10/02    1.6  M.Sano           [0001156]�ڋq�i�ڒ��o�����ǉ�
 *                                      [0001344]�ڋq�i�ڌ����G���[,JAN�R�[�h�����G���[�̃p�����[�^�ǉ�
 *  2010/04/15    1.7  Y.Goto           [E_�{�ғ�_01719]�S���c�ƈ��擾�֐��ǉ�
 *  2010/07/12    1.8  S.Niki           [E_�{�ғ�_02637]�i�ڃR�[�h�ϊ��iEBS��EDI)�p�����[�^�ǉ�
 *  2011/04/26    1.9  K.kiriu          [E_�{�ғ�_07182]�[�i�\��f�[�^�쐬�����x���Ή�
 *                                      [E_�{�ғ�_07218]�[�i�\��v���[�t���X�g�쐬�����x���Ή�
 *  2011/09/07    1.10 K.kiriu          [E_�{�ғ�_07906]���ʂa�l�r�Ή�
 *
 *****************************************************************************************/
--
--###############################  ���ʃG���A��`  START  ###################################
--
  --���C�A�E�g��`���i�[�p���R�[�h�^�C�v
  TYPE g_record_layout IS RECORD(
               lookup_code                             VARCHAR2(4)
              ,meaning                                 VARCHAR2(30)
              ,description                             VARCHAR2(40)
              ,attribute1                              VARCHAR2(7)
              ,attribute2                              VARCHAR2(10)
              );
  --���C�A�E�g��`���i�[�p�e�[�u���^�C�v
  TYPE g_record_layout_ttype IS TABLE OF g_record_layout INDEX BY BINARY_INTEGER;
  --
  --�t�@�C���o�͏��i�[�p�e�[�u���^�C�v
/* 2011/09/07 Ver1.10 Mod Start */
--  TYPE g_layout_ttype        IS TABLE OF varchar2(1000)   INDEX BY VARCHAR2(100);
  TYPE g_layout_ttype        IS TABLE OF varchar2(2000)   INDEX BY VARCHAR2(100);
/* 2011/09/07 Ver1.10 MOd End   */
  --
  --���C�A�E�g�敪��`
  gv_layout_class_order                       CONSTANT VARCHAR2(1) := '0';    --�󒍌n
  gv_layout_class_stock                       CONSTANT VARCHAR2(1) := '1';    --�݌�
/* 2011/09/07 Ver1.10 Add Start */
  gv_layout_class_order2                      CONSTANT VARCHAR2(1) := '2';    --�󒍌n(���ʂa�l�r�ȊO)
/* 2011/09/07 Ver1.10 Add End   */
  --�t�@�C���`����`
  gv_file_type_fix                            CONSTANT VARCHAR2(1) := '0';    --�Œ蒷
  gv_file_type_variable                       CONSTANT VARCHAR2(1) := '1';    --�ϒ�
--
--###############################  ���ʃG���A��`  E N D  ###################################
--
  /************************************************************************
   * Function Name   : get_unit_price
   * Description     : �P���擾�֐�
   ************************************************************************/
  FUNCTION get_unit_price(
     in_inventory_item_id      IN           NUMBER                           -- Disc�i��ID
    ,in_price_list_header_id   IN           NUMBER                           -- ���i�\�w�b�_ID
    ,iv_uom_code               IN           VARCHAR2                         -- �P�ʃR�[�h
  ) RETURN  NUMBER;
--
  /************************************************************************
   * Procedure Name  : conv_ebs_cust_code
   * Description     : �ڋq�R�[�h�ϊ��iEDI��EBS)
   ************************************************************************/
  PROCEDURE conv_ebs_cust_code(
               iv_edi_chain_code                   IN  VARCHAR2 DEFAULT NULL  --EDI�`�F�[���X�R�[�h
              ,iv_store_code                       IN  VARCHAR2 DEFAULT NULL  --�X�R�[�h
              ,ov_account_number                   OUT NOCOPY VARCHAR2        --�ڋq�R�[�h
              ,ov_errbuf                           OUT NOCOPY VARCHAR2        --�G���[�E���b�Z�[�W�G���[       #�Œ�#
              ,ov_retcode                          OUT NOCOPY VARCHAR2        --���^�[���E�R�[�h               #�Œ�#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2        --���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
              );
  --
--
  /************************************************************************
   * Procedure Name  : conv_edi_item_code
   * Description     : �i�ڃR�[�h�ϊ��iEBS��EDI)
   ************************************************************************/
  PROCEDURE conv_edi_item_code(
               iv_edi_chain_code                   IN  VARCHAR2 DEFAULT NULL  --EDI�`�F�[���X�R�[�h
              ,iv_item_code                        IN  VARCHAR2 DEFAULT NULL  --�i�ڃR�[�h
              ,iv_organization_id                  IN  VARCHAR2 DEFAULT NULL  --�݌ɑg�DID
              ,iv_uom_code                         IN  VARCHAR2 DEFAULT NULL  --�P�ʃR�[�h
              ,ov_product_code2                    OUT NOCOPY VARCHAR2        --���i�R�[�h�Q
              ,ov_jan_code                         OUT NOCOPY VARCHAR2        --JAN�R�[�h
              ,ov_case_jan_code                    OUT NOCOPY VARCHAR2        --�P�[�XJAN�R�[�h
/* 2010/07/12 Ver1.8 Add Start */
              ,ov_err_flag                         OUT NOCOPY VARCHAR2        --�G���[���
/* 2010/07/12 Ver1.8 Add End */
              ,ov_errbuf                           OUT NOCOPY VARCHAR2        --�G���[�E���b�Z�[�W�G���[       #�Œ�#
              ,ov_retcode                          OUT NOCOPY VARCHAR2        --���^�[���E�R�[�h               #�Œ�#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2        --���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
              );
  --
--
  --���C�A�E�g��`���擾
  PROCEDURE get_layout_info(
               iv_file_type                        IN  VARCHAR2 DEFAULT NULL  --�t�@�C���`��
              ,iv_layout_class                     IN  VARCHAR2 DEFAULT NULL  --���C�A�E�g�敪
              ,ov_data_type_table                  OUT NOCOPY g_record_layout_ttype  --���C�A�E�g��`���
              ,ov_csv_header                       OUT NOCOPY VARCHAR2        --CSV�w�b�_
              ,ov_errbuf                           OUT NOCOPY VARCHAR2        --�G���[�E���b�Z�[�W�G���[       #�Œ�#
              ,ov_retcode                          OUT NOCOPY VARCHAR2        --���^�[���E�R�[�h               #�Œ�#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2        --���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
              );
  --
--
  --�f�[�^���R�[�h�ҏW
  PROCEDURE makeup_data_record(
               iv_edit_data                        IN  g_layout_ttype         --�o�̓f�[�^
              ,iv_file_type                        IN  VARCHAR2 DEFAULT NULL  --�t�@�C���`��
              ,iv_data_type_table                  IN  g_record_layout_ttype  --�ҏW�O���R�[�h�^���
              ,iv_record_type                      IN  VARCHAR2 DEFAULT NULL  --���R�[�h���ʎq
              ,ov_data_record                      OUT NOCOPY VARCHAR2        --�f�[�^���R�[�h
              ,ov_errbuf                           OUT NOCOPY VARCHAR2        --�G���[�E���b�Z�[�W�G���[       #�Œ�#
              ,ov_retcode                          OUT NOCOPY VARCHAR2        --���^�[���E�R�[�h               #�Œ�#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2        --���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
              );
  --
--
  /************************************************************************
   * Function Name   : convert_quantity
   * Description     : EDI���[�������ʊ��Z�֐�
   ************************************************************************/
  PROCEDURE convert_quantity(
               iv_uom_code                         IN  VARCHAR2  DEFAULT NULL  --�P�ʃR�[�h
              ,in_case_qty                         IN  NUMBER    DEFAULT NULL  --�P�[�X����
              ,in_ball_qty                         IN  NUMBER    DEFAULT NULL  --�{�[������
              ,in_sum_indv_order_qty               IN  NUMBER    DEFAULT NULL  --��������(���v�E�o��)
              ,in_sum_shipping_qty                 IN  NUMBER    DEFAULT NULL  --�o�א���(���v�E�o��)
              ,on_indv_shipping_qty                OUT NOCOPY NUMBER           --�o�א���(�o��)
              ,on_case_shipping_qty                OUT NOCOPY NUMBER           --�o�א���(�P�[�X)
              ,on_ball_shipping_qty                OUT NOCOPY NUMBER           --�o�א���(�{�[��)
              ,on_indv_stockout_qty                OUT NOCOPY NUMBER           --���i����(�o��)
              ,on_case_stockout_qty                OUT NOCOPY NUMBER           --���i����(�P�[�X)
              ,on_ball_stockout_qty                OUT NOCOPY NUMBER           --���i����(�{�[��)
              ,on_sum_stockout_qty                 OUT NOCOPY NUMBER           --���i����(���v�E�o��)
              ,ov_errbuf                           OUT NOCOPY VARCHAR2         --�G���[�E���b�Z�[�W�G���[       #�Œ�#
              ,ov_retcode                          OUT NOCOPY VARCHAR2         --���^�[���E�R�[�h               #�Œ�#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2         --���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
  );
  --
--
  --�[�i�����s�t���O�擾�֐�
  FUNCTION get_deliv_slip_flag(
               iv_publish_sequence                 IN  NUMBER   DEFAULT NULL  --�[�i�����s�t���O�ݒ菇��
              ,iv_publish_area                     IN  VARCHAR2 DEFAULT NULL  --�[�i�����s�t���O�G���A
           )
    RETURN VARCHAR2;
  --
--
  --�[�i�����s�t���O�S�̎擾�֐�
  FUNCTION get_deliv_slip_flag_area(
               iv_publish_sequence                 IN  NUMBER   DEFAULT NULL  --�[�i�����s�t���O�ݒ菇��
              ,iv_publish_area                     IN  VARCHAR2 DEFAULT NULL  --�[�i�����s�t���O�G���A
              ,iv_publish_flag                     IN  VARCHAR2 DEFAULT NULL  --�[�i�����s�t���O
              )
    RETURN VARCHAR2;
  --
--
  /************************************************************************
   * Function Name   : get_salesrep_id
   * Description     : �S���c�ƈ��擾�֐�
   ************************************************************************/
  PROCEDURE get_salesrep_id(
               iv_account_number                   IN  VARCHAR2  DEFAULT NULL  --�ڋq�R�[�h
              ,id_target_date                      IN  DATE      DEFAULT NULL  --���
              ,in_org_id                           IN  NUMBER    DEFAULT NULL  --�c�ƒP��ID
              ,on_salesrep_id                      OUT NOCOPY NUMBER           --�S���c�ƈ�ID
              ,ov_employee_number                  OUT NOCOPY VARCHAR2         --�ŏ�ʎҏ]�ƈ��ԍ�
              ,ov_errbuf                           OUT NOCOPY VARCHAR2         --�G���[�E���b�Z�[�W�G���[       #�Œ�#
              ,ov_retcode                          OUT NOCOPY VARCHAR2         --���^�[���E�R�[�h               #�Œ�#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2         --���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
  );
  --
/* 2011/04/26 Ver1.9 Add Start */
  /************************************************************************
   * Function Name   : get_reason_code
   * Description     : ���R�R�[�h�擾�֐�
   ************************************************************************/
  FUNCTION get_reason_code(
               in_line_id                          IN  NUMBER                  --�󒍖���ID
           )
    RETURN VARCHAR2;
  --
  /************************************************************************
   * Procedure Name  : get_reason_data
   * Description     : ���R�R�[�h�}�X�^�f�[�^�擾�֐�
   ************************************************************************/
  PROCEDURE get_reason_data(
               in_line_id                          IN  NUMBER                  --�󒍖���ID
              ,on_reason_id                        OUT NOCOPY NUMBER           --���R�R�[�h�}�X�^����ID
              ,ov_reason_code                      OUT NOCOPY VARCHAR2         --���R�R�[�h
              ,ov_select_flag                      OUT NOCOPY VARCHAR2         --�I���\�t���O
              ,ov_errbuf                           OUT NOCOPY VARCHAR2         --�G���[�E���b�Z�[�W�G���[       #�Œ�#
              ,ov_retcode                          OUT NOCOPY VARCHAR2         --���^�[���E�R�[�h               #�Œ�#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2         --���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
  );
/* 2011/04/26 Ver1.9 Add End   */
--
END XXCOS_COMMON2_PKG;
/
