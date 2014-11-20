create or replace PACKAGE XXCOP_COMMON_PKG2
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP_COMMON_PKG(spec)
 * Description      : ���ʊ֐��p�b�P�[�W2(�v��)
 * MD.050           : ���ʊ֐�    MD070_IPO_COP
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- -------------------------------------------------------
 * get_item_info             10.�i�ڏ��擾����
 * get_org_info              11.�g�D���擾����
 * get_num_of_shipped        12.�o�׎��ю擾����
 * get_num_of_forcast        13.�o�ח\���擾����
 * get_stock_plan            14.���ɗ\��擾����
 * get_onhand_qty            15.�莝�݌Ɏ擾����
 * get_deliv_lead_time       16.�z�����[�h�^�C���擾����
 * get_unit_delivery         17.�z���P�ʎ擾����
 * get_working_days          18.�ғ������擾����
 * chk_item_exists           19.�݌ɕi�ڃ`�F�b�N
 * get_scheduled_trans       20.���o�ɗ\��擾����
 * upd_assignment            21.�ړ��˗��E�����Z�b�gAPI�N��
 * get_loct_info             22.�q�ɏ��擾����
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0                   �V�K�쐬
 *
 *****************************************************************************************/
--
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^
  -- ===============================
  TYPE g_char_ttype IS TABLE OF VARCHAR2(256)   INDEX BY BINARY_INTEGER;    -- �x�����b�Z�[�W
  /**********************************************************************************
   * Procedure Name   : get_item_info
   * Description      : �i�ڏ��擾����
   ***********************************************************************************/
  PROCEDURE get_item_info(
    in_inventory_item_id IN  NUMBER,
    on_item_id           OUT  NUMBER,
    ov_item_no           OUT  VARCHAR2,
    ov_item_name         OUT  VARCHAR2,
    ov_prod_class_code   OUT  VARCHAR2,
    on_num_of_case       OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT  VARCHAR2);    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  /**********************************************************************************
   * Procedure Name   : get_org_info
   * Description      : �g�D���擾����
   ***********************************************************************************/
  PROCEDURE get_org_info(
    in_organization_id   IN  NUMBER,
    ov_organization_code OUT  VARCHAR2,
    ov_whse_name         OUT  VARCHAR2,
    ov_errbuf            OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT  VARCHAR2);    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  /**********************************************************************************
   * Procedure Name   : get_num_of_shipped
   * Description      : �o�׎��ю擾����
   ***********************************************************************************/
  PROCEDURE get_num_of_shipped(
    iv_organization_code IN  VARCHAR2,
    iv_item_no           IN  VARCHAR2,
    id_plan_date_from    IN  DATE,
    id_plan_date_to      IN  DATE,
    on_quantity          OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT  VARCHAR2);    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  /**********************************************************************************
   * Procedure Name   : get_num_of_forcast
   * Description      : �o�ח\���擾����
   ***********************************************************************************/
  PROCEDURE get_num_of_forcast(
    in_organization_id   IN  NUMBER,
    in_inventory_item_id IN  NUMBER,
    id_plan_date_from    IN  DATE,
    id_plan_date_to      IN  DATE,
    on_quantity          OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT  VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT  VARCHAR2);   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  /**********************************************************************************
   * Procedure Name   : get_stock_plan
   * Description      : ���ɗ\��擾����
   ***********************************************************************************/
  PROCEDURE get_stock_plan(
    in_organization_id   IN  NUMBER,
    iv_item_no           IN  VARCHAR2,
    id_plan_date_from    IN  DATE,
    id_plan_date_to      IN  DATE,
    on_quantity          OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT  VARCHAR2);    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  /**********************************************************************************
   * Procedure Name   : get_onhand_qty
   * Description      : �莝�݌Ɏ擾����
   ***********************************************************************************/
  PROCEDURE get_onhand_qty(
    iv_organization_code IN  VARCHAR2,
    in_item_id           IN  NUMBER,
    on_quantity          OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT  VARCHAR2);    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  /**********************************************************************************
   * Procedure Name   : get_deliv_lead_time
   * Description      : �z�����[�h�^�C���擾����
   ***********************************************************************************/
  PROCEDURE get_deliv_lead_time(
    iv_from_org_code     IN  VARCHAR2,
    iv_to_org_code       IN  VARCHAR2,
    id_product_date      IN  DATE,
    on_delivery_lt       OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT  VARCHAR2);    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  /**********************************************************************************
   * Procedure Name   : get_unit_delivery
   * Description      : �z���P�ʎ擾����
   ***********************************************************************************/
  PROCEDURE get_unit_delivery(
    in_item_id           IN  NUMBER,
    id_ship_date         IN  DATE,
    on_palette_max_cs_qty        OUT  NUMBER,
    on_palette_max_step_qty    OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT  VARCHAR2);    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  /**********************************************************************************
   * Procedure Name   : get_working_days
   * Description      : �ғ������擾����
   ***********************************************************************************/
  PROCEDURE get_working_days(
    in_organization_id   IN  NUMBER,
    id_from_date     IN     DATE,           --   ��_���t
    id_to_date       IN     DATE,           --   �I�_���t
    on_working_days  OUT    NUMBER,
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
  /**********************************************************************************
   * Procedure Name   : chk_item_exists
   * Description      : �݌ɕi�ڃ`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_item_exists(
    in_inventory_item_id IN  NUMBER,
    in_organization_id   IN  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT  VARCHAR2);
  /**********************************************************************************
   * Procedure Name   : get_scheduled_trans
   * Description      : ���o�ɗ\��擾����
   ***********************************************************************************/
  PROCEDURE get_scheduled_trans(
    in_organization_id   IN  NUMBER,
    iv_item_no           IN  VARCHAR2,
    id_date_from         IN  DATE,
    id_date_to           IN  DATE,
    on_quantity          OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT  VARCHAR2);    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  /**********************************************************************************
   * Procedure Name   : upd_assignment
   * Description      : �ړ��˗��E�����Z�b�gAPI�N��
   ***********************************************************************************/
  PROCEDURE upd_assignment(
    iv_ship_to_locat_code   IN  VARCHAR2,     -- ���ɐ�
    iv_item_code            IN  VARCHAR2,     -- �i��
    in_quantity             IN  NUMBER,       -- �ړ���(0�ȏ�:���Z�A0����:���Z)
    iv_design_prod_date     IN  VARCHAR2,     -- �w�萻����
    iv_sche_arriv_date      IN  VARCHAR2,     -- ����
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2);    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  /**********************************************************************************
   * Procedure Name   : get_loct_info
   * Description      : �q�ɏ��擾����
   ***********************************************************************************/
  PROCEDURE get_loct_info(
    iv_organization_code    IN  VARCHAR2,     -- �g�D�R�[�h
    ov_loct_code            OUT VARCHAR2,     -- �q�ɃR�[�h
    ov_loct_name            OUT VARCHAR2,     -- �q�ɖ�
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2);    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
END XXCOP_COMMON_PKG2;
/
