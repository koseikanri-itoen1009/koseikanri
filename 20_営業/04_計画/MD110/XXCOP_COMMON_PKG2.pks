create or replace PACKAGE XXCOP_COMMON_PKG2
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP_COMMON_PKG(spec)
 * Description      : ���ʊ֐��p�b�P�[�W2(�v��)
 * MD.050           : ���ʊ֐�    MD070_IPO_COP
 * Version          : 2.4
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- -------------------------------------------------------
 * get_item_info             10.�i�ڏ��擾����
 * get_num_of_shipped        11.�N�x�����ʏo�׎��ю擾
 * get_num_of_forecast       12.�o�ח\���擾����
 * get_stock_plan            13.���ɗ\��擾����
 * get_onhand_qty            14.�莝�݌Ɏ擾����
 * get_deliv_lead_time       15.�z�����[�h�^�C���擾����
 * get_working_days          16.�ғ������擾����
 * upd_assignment            17.�����Z�b�gAPI�N��
 * get_loct_info             18.�q�ɏ��擾����
 * get_critical_date_f       19.�N�x��������擾����
 * get_delivery_unit         20.�z���P�ʎ擾����
 * get_receipt_date          21.�����擾����
 * get_shipment_date         22.�o�ד��擾����(�p�~�\��)
 * get_item_category_f       23.�i�ڃJ�e�S���擾
 * get_last_arrival_date_f   24.�ŏI���ɓ��擾
 * get_last_purchase_date_f  25.�ŏI�w�����擾
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0                   �V�K�쐬
 *  2009/04/08    1.1  SCS.Kikuchi      T1_0272,T1_0279,T1_0282,T1_0284�Ή�
 *  2009/05/08    1.2  SCS.Kikuchi      T1_0918,T1_0919�Ή�
 *  2009/07/23    1.3  SCS.Fukada       0000670�Ή�(���ʉۑ�FI_E_479)
 *  2009/08/24    2.0  SCS.Fukada       0000669�Ή�(���ʉۑ�FI_E_479)�A�ύX�����폜
 *  2009/12/01    2.1  SCS.Goto         I_E_479_020 �A�v��PT�Ή�
 *  2009/12/01    2.4  SCS.Goto         I_E_479_022 �����Z�b�gAPI�N���C��
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
    id_target_date             IN  DATE        -- �Ώۓ��t
   ,in_organization_id         IN  NUMBER      -- �g�DID
   ,in_inventory_item_id       IN  NUMBER      -- �݌ɕi��ID
   ,on_item_id                 OUT NUMBER      -- OPM�i��ID
   ,ov_item_no                 OUT VARCHAR2    -- �i�ڃR�[�h
   ,ov_item_name               OUT VARCHAR2    -- �i�ږ���
   ,on_num_of_case             OUT NUMBER      -- �P�[�X����
   ,on_palette_max_cs_qty      OUT NUMBER      -- �z��
   ,on_palette_max_step_qty    OUT NUMBER      -- �i��
   ,ov_errbuf                  OUT VARCHAR2    -- �G���[�E���b�Z�[�W
   ,ov_retcode                 OUT VARCHAR2    -- ���^�[���E�R�[�h
   ,ov_errmsg                  OUT VARCHAR2);  -- ���[�U�[�E�G���[�E���b�Z�[�W
  /**********************************************************************************
   * Procedure Name   : get_shipment_result
   * Description      : �o�׎��ю擾
   ***********************************************************************************/
  PROCEDURE get_shipment_result(
    in_deliver_from_id         IN  NUMBER      -- OPM�ۊǏꏊID
   ,in_item_id                 IN  NUMBER      -- OPM�i��ID
   ,id_shipment_date_from      IN  DATE        -- �o�׎��ъ���FROM
   ,id_shipment_date_to        IN  DATE        -- �o�׎��ъ���TO
   ,iv_freshness_condition     IN  VARCHAR2    -- �N�x����
--20091201_Ver2.1_I_E_479_020_SCS.Goto_ADD_START
   ,in_inventory_item_id       IN  NUMBER      -- INV�i��ID
--20091201_Ver2.1_I_E_479_020_SCS.Goto_ADD_END
   ,on_shipped_quantity        OUT NUMBER      -- �o�׎��ѐ�
   ,ov_errbuf                  OUT VARCHAR2    -- �G���[�E���b�Z�[�W
   ,ov_retcode                 OUT VARCHAR2    -- ���^�[���E�R�[�h
   ,ov_errmsg                  OUT VARCHAR2);  -- ���[�U�[�E�G���[�E���b�Z�[�W
  /**********************************************************************************
   * Procedure Name   : get_num_of_shipped
   * Description      : �N�x�����ʏo�׎��ю擾
   ***********************************************************************************/
  PROCEDURE get_num_of_shipped(
    in_deliver_from_id         IN  NUMBER      -- OPM�ۊǏꏊID
   ,in_item_id                 IN  NUMBER      -- OPM�i��ID
   ,id_shipment_date_from      IN  DATE        -- �o�׎��ъ���FROM
   ,id_shipment_date_to        IN  DATE        -- �o�׎��ъ���TO
   ,iv_freshness_condition     IN  VARCHAR2    -- �N�x����
--20091201_Ver2.1_I_E_479_020_SCS.Goto_ADD_START
   ,in_inventory_item_id       IN  NUMBER      -- INV�i��ID
--20091201_Ver2.1_I_E_479_020_SCS.Goto_ADD_END
   ,on_shipped_quantity        OUT NUMBER      -- �o�׎��ѐ�
   ,ov_errbuf                  OUT VARCHAR2    -- �G���[�E���b�Z�[�W
   ,ov_retcode                 OUT VARCHAR2    -- ���^�[���E�R�[�h
   ,ov_errmsg                  OUT VARCHAR2);  -- ���[�U�[�E�G���[�E���b�Z�[�W
  /**********************************************************************************
   * Procedure Name   : get_num_of_forecast
   * Description      : �o�ח\���擾����
   ***********************************************************************************/
--  PROCEDURE get_num_of_forecast(
--    in_organization_id         IN  NUMBER
--   ,in_inventory_item_id       IN  NUMBER
--   ,id_plan_date_from          IN  DATE
--   ,id_plan_date_to            IN  DATE
--   ,on_quantity                OUT NUMBER
--   ,ov_errbuf                  OUT VARCHAR2    -- �G���[�E���b�Z�[�W
--   ,ov_retcode                 OUT VARCHAR2    -- ���^�[���E�R�[�h
--   ,ov_errmsg                  OUT VARCHAR2);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  PROCEDURE get_num_of_forecast(
    in_organization_id   IN  NUMBER       -- �݌ɑg�DID
   ,in_inventory_item_id IN  NUMBER       -- �݌ɕi��ID
   ,id_plan_date_from    IN  DATE         -- �o�ח\���擾����FROM
   ,id_plan_date_to      IN  DATE         -- �o�ח\���擾����TO
   ,in_loct_id           IN  NUMBER       -- OPM�ۊǏꏊID
   ,on_quantity          OUT  NUMBER      -- �o�ח\������
   ,ov_errbuf            OUT  VARCHAR2    -- �G���[�E���b�Z�[�W
   ,ov_retcode           OUT  VARCHAR2    -- ���^�[���E�R�[�h
   ,ov_errmsg            OUT  VARCHAR2);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  /**********************************************************************************
   * Procedure Name   : get_stock_plan
   * Description      : ���ɗ\��擾����
   ***********************************************************************************/
  PROCEDURE get_stock_plan(
    in_loct_id                 IN  NUMBER      -- �ۊǏꏊID
   ,in_item_id                 IN  NUMBER      -- �i��ID
   ,id_plan_date_from          IN  DATE        -- �v�����From
   ,id_plan_date_to            IN  DATE        -- �v�����To
   ,on_quantity                OUT NUMBER      -- �v�搔
   ,ov_errbuf                  OUT VARCHAR2    -- �G���[�o�b�t�@
   ,ov_retcode                 OUT VARCHAR2    -- �G���[�E���b�Z�[�W
   ,ov_errmsg                  OUT VARCHAR2);  -- ���^�[���E�R�[�h
  /**********************************************************************************
   * Procedure Name   : get_onhand_qty
   * Description      : �莝�݌Ɏ擾����
   ***********************************************************************************/
  PROCEDURE get_onhand_qty(
    in_loct_id                 IN  NUMBER      -- �ۊǏꏊID
   ,in_item_id                 IN  NUMBER      -- �i��ID
   ,id_target_date             IN  DATE        -- �Ώۓ��t
   ,id_allocated_date          IN  DATE        -- �����ϓ�
   ,on_quantity                OUT NUMBER      -- �莝�݌ɐ���
   ,ov_errbuf                  OUT VARCHAR2    -- �G���[�E���b�Z�[�W          
   ,ov_retcode                 OUT VARCHAR2    -- ���^�[���E�R�[�h            
   ,ov_errmsg                  OUT VARCHAR2);  -- ���[�U�[�E�G���[�E���b�Z�[�W
  /**********************************************************************************
   * Procedure Name   : get_deliv_lead_time
   * Description      : �z�����[�h�^�C���擾����
   ***********************************************************************************/
  PROCEDURE get_deliv_lead_time(
    id_target_date             IN  DATE        -- �Ώۓ��t
   ,iv_from_loct_code          IN  VARCHAR2    -- �o�וۊǑq�ɃR�[�h
   ,iv_to_loct_code            IN  VARCHAR2    -- ����ۊǑq�ɃR�[�h
   ,on_delivery_lt             OUT NUMBER      -- ���[�h�^�C��(��)
   ,ov_errbuf                  OUT VARCHAR2    -- �G���[�E���b�Z�[�W
   ,ov_retcode                 OUT VARCHAR2    -- ���^�[���E�R�[�h
   ,ov_errmsg                  OUT VARCHAR2);  -- ���[�U�[�E�G���[�E���b�Z�[�W
  /**********************************************************************************
   * Procedure Name   : get_working_days
   * Description      : �ғ������擾����
   ***********************************************************************************/
  PROCEDURE get_working_days(
    iv_calendar_code           IN  VARCHAR2    -- �����J�����_�R�[�h
   ,in_organization_id         IN  NUMBER      -- �g�DID
   ,in_loct_id                 IN  NUMBER      -- �ۊǑq��ID
   ,id_from_date               IN  DATE        -- ��_���t
   ,id_to_date                 IN  DATE        -- �I�_���t
   ,on_working_days            OUT NUMBER      -- �ғ���
   ,ov_errbuf                  OUT VARCHAR2    -- �G���[�E���b�Z�[�W
   ,ov_retcode                 OUT VARCHAR2    -- ���^�[���E�R�[�h
   ,ov_errmsg                  OUT VARCHAR2);  -- ���[�U�[�E�G���[�E���b�Z�[�W
  /**********************************************************************************
   * Procedure Name   : upd_assignment
   * Description      : �ړ��˗��E�����Z�b�gAPI�N��
   ***********************************************************************************/
  PROCEDURE upd_assignment(
    iv_mov_num                 IN  VARCHAR2    -- �ړ��w�b�_ID
   ,iv_process_type            IN  VARCHAR2    -- �����敪(0�F���Z�A1�F���Z)
   ,ov_errbuf                  OUT VARCHAR2    -- �G���[�E���b�Z�[�W
   ,ov_retcode                 OUT VARCHAR2    -- ���^�[���E�R�[�h
   ,ov_errmsg                  OUT VARCHAR2);  -- ���[�U�[�E�G���[�E���b�Z�[�W
  /**********************************************************************************
   * Procedure Name   : get_loct_info
   * Description      : �q�ɏ��擾����
   ***********************************************************************************/
  PROCEDURE get_loct_info(
    id_target_date             IN  DATE        -- �Ώۓ��t
   ,in_organization_id         IN  NUMBER      -- �g�DID
   ,ov_organization_code       OUT VARCHAR2    -- �g�D�R�[�h
   ,ov_organization_name       OUT VARCHAR2    -- �g�D����
   ,on_loct_id                 OUT NUMBER      -- �ۊǑq��ID
   ,ov_loct_code               OUT VARCHAR2    -- �ۊǑq�ɃR�[�h
   ,ov_loct_name               OUT VARCHAR2    -- �ۊǑq�ɖ���
   ,ov_calendar_code           OUT VARCHAR2    -- �J�����_�R�[�h
   ,ov_errbuf                  OUT VARCHAR2    -- �G���[�E���b�Z�[�W
   ,ov_retcode                 OUT VARCHAR2    -- ���^�[���E�R�[�h
   ,ov_errmsg                  OUT VARCHAR2);  -- ���[�U�[�E�G���[�E���b�Z�[�W
  /**********************************************************************************
   * Procedure Name   : get_critical_date_f
   * Description      : �N�x��������擾����
   ***********************************************************************************/
  FUNCTION get_critical_date_f(
     iv_freshness_class        IN VARCHAR2     -- �N�x��������
    ,in_freshness_check_value  IN NUMBER       -- �N�x�����`�F�b�N�l
    ,in_freshness_adjust_value IN NUMBER       -- �N�x���������l
    ,in_max_stock_days         IN NUMBER       -- �ő�݌ɓ���
    ,in_freshness_buffer_days  IN NUMBER       -- �N�x�����o�b�t�@����
    ,id_manufacture_date       IN DATE         -- �����N����
    ,id_expiration_date        IN DATE         -- �ܖ�����
  ) RETURN DATE;
  /**********************************************************************************
   * Procedure Name   : get_delivery_unit
   * Description      : �z���P�ʎ擾����
   ***********************************************************************************/
  PROCEDURE get_delivery_unit(
     in_shipping_pace          IN  NUMBER      -- �o�׃y�[�X
    ,in_palette_max_cs_qty     IN  NUMBER      -- �z��
    ,in_palette_max_step_qty   IN  NUMBER      -- �i��
    ,ov_unit_delivery          OUT VARCHAR2    -- �z���P��
    ,ov_errbuf                 OUT VARCHAR2    -- �G���[�E���b�Z�[�W
    ,ov_retcode                OUT VARCHAR2    -- ���^�[���E�R�[�h
    ,ov_errmsg                 OUT VARCHAR2);  -- ���[�U�[�E�G���[�E���b�Z�[�W
  /**********************************************************************************
   * Function Name   : get_receipt_date
   * Description      : �����擾����
   ***********************************************************************************/
  PROCEDURE get_receipt_date(
    iv_calendar_code           IN  VARCHAR2    -- �����J�����_�R�[�h
   ,in_organization_id         IN  NUMBER      -- �g�DID
   ,in_loct_id                 IN  NUMBER      -- �ۊǑq��ID
   ,id_shipment_date           IN  DATE        -- �o�ד�
   ,in_lead_time               IN  NUMBER      -- �z�����[�h�^�C��
   ,od_receipt_date            OUT DATE        -- ����
   ,ov_errbuf                  OUT VARCHAR2    -- �G���[�E���b�Z�[�W
   ,ov_retcode                 OUT VARCHAR2    -- ���^�[���E�R�[�h
   ,ov_errmsg                  OUT VARCHAR2);  -- ���[�U�[�E�G���[�E���b�Z�[�W
  /**********************************************************************************
   * Function Name   : get_shipment_date
   * Description      : �o�ד��擾����
   ***********************************************************************************/
  PROCEDURE get_shipment_date(
    iv_calendar_code           IN  VARCHAR2    -- �����J�����_�R�[�h
   ,in_organization_id         IN  NUMBER      -- �g�DID
   ,in_loct_id                 IN  NUMBER      -- �ۊǑq��ID
   ,id_receipt_date            IN  DATE        -- ����
   ,in_lead_time               IN  NUMBER      -- �z�����[�h�^�C��
   ,od_shipment_date           OUT DATE        -- �o�ד�
   ,ov_errbuf                  OUT VARCHAR2    -- �G���[�E���b�Z�[�W
   ,ov_retcode                 OUT VARCHAR2    -- ���^�[���E�R�[�h
   ,ov_errmsg                  OUT VARCHAR2);  -- ���[�U�[�E�G���[�E���b�Z�[�W
  /**********************************************************************************
   * Function Name   : get_item_category_f
   * Description      : �i�ڃJ�e�S���擾
   ***********************************************************************************/
  FUNCTION get_item_category_f(
     iv_category_set           IN  VARCHAR2    -- �i�ڃJ�e�S����
    ,in_item_id                IN  NUMBER      -- �i��ID
  ) RETURN VARCHAR2;
  /**********************************************************************************
   * Function Name   : get_last_arrival_date_f
   * Description      : �ŏI���ɓ��擾
   ***********************************************************************************/
  FUNCTION get_last_arrival_date_f(
    in_rcpt_loct_id            IN  NUMBER      -- �ړ���ۊǑq��ID
   ,in_ship_loct_id            IN  NUMBER      -- �ړ����ۊǑq��ID
   ,in_item_id                 IN  NUMBER      -- �i��ID
  ) RETURN DATE;
  /**********************************************************************************
   * Function Name   : get_last_purchase_date_f
   * Description      : �ŏI�w�����擾
   ***********************************************************************************/
  FUNCTION get_last_purchase_date_f(
    in_loct_id              IN     NUMBER,     --   �ۊǑq��ID
    in_item_id              IN     NUMBER      --   �i��ID
  ) RETURN DATE;
--
END XXCOP_COMMON_PKG2;
/
