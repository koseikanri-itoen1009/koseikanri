CREATE OR REPLACE PACKAGE XXCOS_COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS_COMMON_PKG(spec)
 * Description      : ���ʊ֐��p�b�P�[�W(�̔�)
 * MD.070           : ���ʊ֐�    MD070_IPO_COS
 * Version          : 1.0
 *
 * Program List
 * --------------------------- ------ ---------- -----------------------------------------
 *  Name                        Type   Return     Description
 * --------------------------- ------ ---------- -----------------------------------------
 *  get_key_info                P                 �L�[���ҏW
 *  get_uom_cnv                 P                 �P�ʊ��Z�擾
 *  get_delivered_from          P                 �[�i�`�Ԏ擾
 *  get_sales_calendar_code     P                 �̔��p�J�����_�[�R�[�h�擾
 *  check_sales_operation_day   F      NUMBER     �̔��p�ғ����`�F�b�N
 *  get_period_year             P                 ���N�x��v���Ԏ擾
 *  get_account_period          P                 ��v���ԏ��擾
 *  get_specific_master         F      VARCHAR2   ����}�X�^�擾(�N�C�b�N�R�[�h)
 *  
 * Change Record
 * ------------- ----- ---------------- --------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- --------------------------------------------------
 *  2008/11/21    1.0   SCS              �V�K�쐬
 *
 ****************************************************************************************/
--
  /************************************************************************
   * Procedure Name  : makeup_key_info
   * Description     : �L�[���ҏW
   ************************************************************************/
  PROCEDURE makeup_key_info(
    iv_item_name1             IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P
    iv_item_name2             IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂Q
    iv_item_name3             IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂R
    iv_item_name4             IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂S
    iv_item_name5             IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂T
    iv_item_name6             IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂U
    iv_item_name7             IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂V
    iv_item_name8             IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂W
    iv_item_name9             IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂X
    iv_item_name10            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P�O
    iv_item_name11            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P�P
    iv_item_name12            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P�Q
    iv_item_name13            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P�R
    iv_item_name14            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P�S
    iv_item_name15            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P�T
    iv_item_name16            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P�U
    iv_item_name17            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P�V
    iv_item_name18            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P�W
    iv_item_name19            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂P�X
    iv_item_name20            IN            VARCHAR2  DEFAULT NULL,         -- ���ږ��̂Q�O
    iv_data_value1            IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P
    iv_data_value2            IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�Q
    iv_data_value3            IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�R
    iv_data_value4            IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�S
    iv_data_value5            IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�T
    iv_data_value6            IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�U
    iv_data_value7            IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�V
    iv_data_value8            IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�W
    iv_data_value9            IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�X
    iv_data_value10           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P�O
    iv_data_value11           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P�P
    iv_data_value12           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P�Q
    iv_data_value13           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P�R
    iv_data_value14           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P�S
    iv_data_value15           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P�T
    iv_data_value16           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P�U
    iv_data_value17           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P�V
    iv_data_value18           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P�W
    iv_data_value19           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�P�X
    iv_data_value20           IN            VARCHAR2  DEFAULT NULL,         -- �f�[�^�̒l�Q�O
    ov_key_info               OUT    NOCOPY VARCHAR2,                       -- �L�[���
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- ���^�[���E�R�[�h               #�Œ�#
    ov_errmsg                 OUT    NOCOPY VARCHAR2                        -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
  );
--
  /************************************************************************
   * Procedure Name  : get_uom_cnv
   * Description     : �P�ʊ��Z�擾
   ************************************************************************/
  PROCEDURE get_uom_cnv(
    iv_before_uom_code        IN            VARCHAR2,                       -- ���Z�O�P�ʃR�[�h
    in_before_quantity        IN            NUMBER,                         -- ���Z�O����
    iov_item_code             IN OUT NOCOPY VARCHAR2,                       -- �i�ڃR�[�h
    iov_organization_code     IN OUT NOCOPY VARCHAR2,                       -- �݌ɑg�D�R�[�h
    ion_inventory_item_id     IN OUT        NUMBER,                         -- �i�ڂh�c
    ion_organization_id       IN OUT        NUMBER,                         -- �݌ɑg�D�h�c
    iov_after_uom_code        IN OUT NOCOPY VARCHAR2,                       -- ���Z��P�ʃR�[�h
    on_after_quantity         OUT    NOCOPY NUMBER,                         -- ���Z�㐔��
    on_content                OUT    NOCOPY NUMBER,                         -- ����
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- ���^�[���E�R�[�h               #�Œ�#
    ov_errmsg                 OUT    NOCOPY VARCHAR2                        -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
  );
--
  /************************************************************************
   * Procedure Name  : get_delivered_from
   * Description     : �[�i�`�Ԏ擾
   ************************************************************************/
  PROCEDURE get_delivered_from(
    iv_subinventory_code      IN            VARCHAR2,                       -- �ۊǏꏊ�R�[�h
    iv_sales_base_code        IN            VARCHAR2,                       -- ���㋒�_�R�[�h,
    iv_ship_base_code         IN            VARCHAR2,                       -- �o�׋��_�R�[�h,
    iov_organization_code     IN OUT NOCOPY VARCHAR2,                       -- �݌ɑg�D�R�[�h
    ion_organization_id       IN OUT        NUMBER,                         -- �݌ɑg�D�h�c
    ov_delivered_from         OUT    NOCOPY VARCHAR2,                       -- �[�i�`��
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- ���^�[���E�R�[�h               #�Œ�#
    ov_errmsg                 OUT    NOCOPY VARCHAR2                        -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
  );
--
  /************************************************************************
   * Procedure Name  : get_sales_calendar_code
   * Description     : �̔��p�J�����_�R�[�h�擾
   ************************************************************************/
  PROCEDURE get_sales_calendar_code(
    iov_organization_code     IN OUT NOCOPY VARCHAR2,                       -- �݌ɑg�D�R�[�h
    ion_organization_id       IN OUT        NUMBER,                         -- �݌ɑg�D�h�c
    ov_calendar_code          OUT    NOCOPY VARCHAR2,                       -- �J�����_�R�[�h
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- ���^�[���E�R�[�h               #�Œ�#
    ov_errmsg                 OUT    NOCOPY VARCHAR2                        -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
  );
--
  /************************************************************************
   * Function Name   : check_sales_oprtn_day
   * Description     : �̔��p�ғ����`�F�b�N
   ************************************************************************/
  FUNCTION check_sales_oprtn_day(
    id_check_target_date      IN            DATE,                           -- �`�F�b�N�Ώۓ��t
    iv_calendar_code          IN            VARCHAR2                        -- �J�����_�R�[�h
  ) RETURN  NUMBER;
--
  /************************************************************************
   * Procedure Name  : get_period_year
   * Description     : ���N�x��v���Ԏ擾
   ************************************************************************/
  PROCEDURE get_period_year(
    id_base_date              IN            DATE,                           --   ���
    od_start_date             OUT    NOCOPY DATE,                           --   ���N�x��v�J�n��
    od_end_date               OUT    NOCOPY DATE,                           --   ���N�x��v�I����
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- ���^�[���E�R�[�h               #�Œ�#
    ov_errmsg                 OUT    NOCOPY VARCHAR2                        -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
  );
--
  /************************************************************************
   * Procedure Name  : get_account_period
   * Description     : ��v���ԏ��擾
   ************************************************************************/
  PROCEDURE get_account_period(
    iv_account_period         IN            VARCHAR2,                       -- ��v�敪
    id_base_date              IN            DATE,                           -- ���
    ov_status                 OUT    NOCOPY VARCHAR2,                       -- �X�e�[�^�X
    od_start_date             OUT    NOCOPY DATE,                           -- ��v(FROM)
    od_end_date               OUT    NOCOPY DATE,                           -- ��v(TO)
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- ���^�[���E�R�[�h               #�Œ�#
    ov_errmsg                 OUT    NOCOPY VARCHAR2                        -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
  );
--
  /************************************************************************
   * Function Name   : get_specific_master
   * Description     : ����}�X�^�擾(�N�C�b�N�R�[�h)
   ************************************************************************/
  FUNCTION get_specific_master(
    it_lookup_type            IN            fnd_lookup_types.lookup_type%TYPE, -- ���b�N�A�b�v�^�C�v
    it_lookup_code            IN            fnd_lookup_values.lookup_code%TYPE -- ���b�N�A�b�v�R�[�h
  ) RETURN  VARCHAR2;
--
END XXCOS_COMMON_PKG;
/
