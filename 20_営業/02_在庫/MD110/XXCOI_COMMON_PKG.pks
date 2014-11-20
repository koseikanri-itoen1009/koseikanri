CREATE OR REPLACE PACKAGE XXCOI_COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI_COMMON_PKG(spec)
 * Description      : ���ʊ֐��p�b�P�[�W(�݌�)
 * MD.070           : ���ʊ֐�    MD070_IPO_COI
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- -------------------------------------------------------
 *  ORG_ACCT_PERIOD_CHK        �݌ɉ�v���ԃ`�F�b�N
 *  GET_ORGANIZATION_ID        �݌ɑg�DID�擾
 *  GET_BELONGING_BASE         �������_�R�[�h�擾1
 *  GET_BASE_CODE              �������_�R�[�h�擾2
 *  GET_MEANING                LOOKUP���擾
 *  GET_CMPNT_COST             �W�������擾
 *  GET_DISCRETE_COST          �c�ƌ����擾
 *  GET_TRANSACTION_TYPE_ID    ����^�C�vID�擾
 *  GET_ITEM_INFO              �i�ڏ��擾1
 *  GET_ITEM_CODE              �i�ڏ��擾2
 *  GET_UOM_DISABLE_INFO       �P�ʖ��������擾
 *  GET_SUBINVENTORY_INFO1     �ۊǏꏊ���擾1
 *  GET_SUBINVENTORY_INFO2     �ۊǏꏊ���擾2
 *  GET_MANAGE_DEPT_F          �Ǘ��۔��ʃt���O�擾
 *  GET_LOOKUP_VALUES          �N�C�b�N�R�[�h�}�X�^���擾
 *  CONVERT_WHOUSE_SUBINV_CODE HHT�ۊǏꏊ�R�[�h�ϊ� �q�ɕۊǏꏊ�R�[�h�ϊ�
 *  CONVERT_EMP_SUBINV_CODE    HHT�ۊǏꏊ�R�[�h�ϊ� �c�ƎԕۊǏꏊ�R�[�h�ϊ�
 *  CONVERT_CUST_SUBINV_CODE   HHT�ۊǏꏊ�R�[�h�ϊ� �a����ۊǏꏊ�R�[�h�ϊ�
 *  CONVERT_BASE_SUBINV_CODE   HHT�ۊǏꏊ�R�[�h�ϊ� ���C���q�ɕۊǏꏊ�R�[�h�ϊ�
 *  CHECK_CUST_STATUS          HHT�ۊǏꏊ�R�[�h�ϊ� �ڋq�X�e�[�^�X�`�F�b�N
 *  CONVERT_SUBINV_CODE        HHT�ۊǏꏊ�R�[�h�ϊ�
 *  GET_DISPOSITION_ID         ����Ȗڕʖ�ID�擾
 *  ADD_HHT_ERR_LIST_DATA      HHT���捞�G���[�o��
 *  GET_DISPOSITION_ID_2       ����Ȗڕʖ�ID�擾2
 *  GET_ITEM_INFO2             �i�ڏ��擾(�i��ID�A�P�ʃR�[�h)
 * 
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/23    1.0   T.Nishikawa      �V�K�쐬
 *  2009/03/24    1.1   S.Kayahara       �ŏI�s��/�ǉ�
 *
 *****************************************************************************************/
--
/************************************************************************
 * Function Name   : ORG_ACCT_PERIOD_CHK
 * Description     : �Ώۓ��ɑΉ�����݌ɉ�v���Ԃ��I�[�v�����Ă��邩��
 *                   �`�F�b�N����B
 ************************************************************************/
  PROCEDURE org_acct_period_chk(
    in_organization_id IN  NUMBER             -- �݌ɑg�DID
   ,id_target_date     IN  DATE               -- �Ώۓ�
   ,ob_chk_result      OUT BOOLEAN            -- �`�F�b�N����
   ,ov_errbuf          OUT VARCHAR2           -- �G���[���b�Z�[�W
   ,ov_retcode         OUT VARCHAR2           -- ���^�[���E�R�[�h(0:����A2:�G���[)
   ,ov_errmsg          OUT VARCHAR2           -- ���[�U�[�E�G���[���b�Z�[�W
  );
/************************************************************************
 * Function Name   : GET_ORGANIZATION_ID
 * Description     : �̔������̈�̍݌ɑg�DID���擾����B
 ************************************************************************/
  FUNCTION get_organization_id(
    iv_organization_code IN VARCHAR2
  ) RETURN NUMBER;
/************************************************************************
 * Procedure Name  : GET_BELONGING_BASE
 * Description     : ���O�C�����[�U�[�ɕR�t���������_�R�[�h���擾����B
 ************************************************************************/
  PROCEDURE get_belonging_base(
    in_user_id        IN  NUMBER              -- ���[�U�[ID
   ,id_target_date    IN  DATE                -- �Ώۓ�
   ,ov_base_code      OUT VARCHAR2            -- ���_�R�[�h
   ,ov_errbuf         OUT VARCHAR2            -- �G���[���b�Z�[�W
   ,ov_retcode        OUT VARCHAR2            -- ���^�[���E�R�[�h(0:����A2:�G���[)
   ,ov_errmsg         OUT VARCHAR2            -- ���[�U�[�E�G���[���b�Z�[�W
  );
/************************************************************************
 * Function Name   : GET_BASE_CODE
 * Description     : �������_�R�[�h�擾�̃t�@���N�V�����@�\�B
 ************************************************************************/
  FUNCTION get_base_code(
    in_user_id        IN  NUMBER              -- ���[�U�[ID
   ,id_target_date    IN  DATE                -- �Ώۓ�
  ) RETURN VARCHAR2;
/************************************************************************
 * Function Name   : GET_MEANING
 * Description     : �N�C�b�N�R�[�h�̎Q�ƃ^�C�v�E�Q�ƃR�[�h�̓��e���擾����B
 ************************************************************************/
  FUNCTION get_meaning(
    iv_lookup_type    IN  VARCHAR2            -- �Q�ƃ^�C�v
   ,iv_lookup_code    IN  VARCHAR2            -- �Q�ƃR�[�h
  ) RETURN VARCHAR2;
/************************************************************************
 * Procedure Name  : GET_CMPNT_COST
 * Description     : �i��ID�����ɕW���������擾���܂��B
 ************************************************************************/
  PROCEDURE get_cmpnt_cost(
    in_item_id        IN  NUMBER              -- �i��ID
   ,in_org_id         IN  NUMBER              -- �g�DID
   ,id_period_date    IN  DATE                -- �Ώۓ�
   ,ov_cmpnt_cost     OUT VARCHAR2            -- �W������
   ,ov_errbuf         OUT VARCHAR2            -- �G���[���b�Z�[�W
   ,ov_retcode        OUT VARCHAR2            -- ���^�[���E�R�[�h(0:����A2:�G���[)
   ,ov_errmsg         OUT VARCHAR2            -- ���[�U�[�E�G���[���b�Z�[�W
  );
/************************************************************************
 * Procedure Name  : GET_DISCRETE_COST
 * Description     : �i��ID�����Ɋm��ς݂̉c�ƌ������擾���܂��B
 ************************************************************************/
  PROCEDURE get_discrete_cost(
    in_item_id        IN  NUMBER              -- �i��ID
   ,in_org_id         IN  NUMBER              -- �g�DID
   ,id_target_date    IN  DATE                -- �Ώۓ�
   ,ov_discrete_cost  OUT VARCHAR2            -- �c�ƌ���
   ,ov_errbuf         OUT VARCHAR2            -- �G���[���b�Z�[�W
   ,ov_retcode        OUT VARCHAR2            -- ���^�[���E�R�[�h(0:����A2:�G���[)
   ,ov_errmsg         OUT VARCHAR2            -- ���[�U�[�E�G���[���b�Z�[�W
  );
/************************************************************************
 * Function Name   : GET_TRANSACTION_TYPE_ID
 * Description     : ����^�C�v�������ƂɁA����^�C�vID���擾
 ************************************************************************/
  FUNCTION  get_transaction_type_id(
    iv_transaction_type_name IN VARCHAR2     -- ����^�C�v��
  ) RETURN NUMBER;
/************************************************************************
 * Function Name   : GET_ITEM_CODE
 * Description     : �i��ID�����Ƃɕi�ڃR�[�h���擾����B
 ************************************************************************/
  FUNCTION get_item_code(
    in_item_id    IN NUMBER
   ,in_org_id     IN NUMBER
  ) RETURN VARCHAR2;
--
/************************************************************************
 * Procedure Name  : get_item_info
 * Description     : �i�ڃ`�F�b�N�Ɏg�p����i�ڕt�������擾���܂��B
 ************************************************************************/
  PROCEDURE get_item_info(
    ov_errbuf               OUT VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode              OUT VARCHAR2   -- 2.���^�[���E�R�[�h
   ,ov_errmsg               OUT VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_item_code            IN  VARCHAR2   -- 4.�i�ڃR�[�h
   ,in_org_id               IN  NUMBER     -- 5.�݌ɑg�DID
   ,ov_item_status          OUT VARCHAR2   -- 6.�i�ڃX�e�[�^�X
   ,ov_cust_order_flg       OUT VARCHAR2   -- 7.�ڋq�󒍉\�t���O
   ,ov_transaction_enable   OUT VARCHAR2   -- 8.����\
   ,ov_stock_enabled_flg    OUT VARCHAR2   -- 9.�݌ɕۗL�\�t���O
   ,ov_return_enable        OUT VARCHAR2   -- 10.�ԕi�\
   ,ov_sales_class          OUT VARCHAR2   -- 11.����Ώۋ敪
   ,ov_primary_unit         OUT VARCHAR2   -- 12.��P��
  );
/************************************************************************
 * Procedure Name  : get_item_info2
 * Description     : �i�ڃ`�F�b�N�Ɏg�p����i�ڕt�������擾���܂��B
 ************************************************************************/
  PROCEDURE get_item_info2(
    ov_errbuf               OUT VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode              OUT VARCHAR2   -- 2.���^�[���E�R�[�h
   ,ov_errmsg               OUT VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_item_code            IN  VARCHAR2   -- 4.�i�ڃR�[�h
   ,in_org_id               IN  NUMBER     -- 5.�݌ɑg�DID
   ,ov_item_status          OUT VARCHAR2   -- 6.�i�ڃX�e�[�^�X
   ,ov_cust_order_flg       OUT VARCHAR2   -- 7.�ڋq�󒍉\�t���O
   ,ov_transaction_enable   OUT VARCHAR2   -- 8.����\
   ,ov_stock_enabled_flg    OUT VARCHAR2   -- 9.�݌ɕۗL�\�t���O
   ,ov_return_enable        OUT VARCHAR2   -- 10.�ԕi�\
   ,ov_sales_class          OUT VARCHAR2   -- 11.����Ώۋ敪
   ,ov_primary_unit         OUT VARCHAR2   -- 12.��P��
   ,on_inventory_item_id    OUT NUMBER     -- 13.�i��ID
   ,ov_primary_uom_code     OUT VARCHAR2   -- 14.��P�ʃR�[�h
  );
--
/************************************************************************
 * Procedure Name  : get_uom_disable_info
 * Description     : �P�ʃ}�X�^���P�ʂ̖��������擾���܂��B
 ************************************************************************/
  PROCEDURE get_uom_disable_info(
    ov_errbuf         OUT VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode        OUT VARCHAR2   -- 2.���^�[���E�R�[�h
   ,ov_errmsg         OUT VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_unit_code      IN  VARCHAR2   -- 4.�P�ʃR�[�h
   ,od_disable_date   OUT DATE       -- 5.������
  );
--
/************************************************************************
 * Procedure Name  : get_subinventory_info1
 * Description     : �ۊǏꏊ�}�X�^���A���_�R�[�h�E�q�ɃR�[�h�����
 *                   �ۊǏꏊ�R�[�h�Ɩ��������擾���܂��B
 ************************************************************************/
  PROCEDURE get_subinventory_info1(
    ov_errbuf         OUT VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode        OUT VARCHAR2   -- 2.���^�[���E�R�[�h
   ,ov_errmsg         OUT VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_base_code      IN  VARCHAR2   -- 4.���_�R�[�h
   ,iv_whse_code      IN  VARCHAR2   -- 5.�q�ɃR�[�h
   ,ov_sec_inv_nm     OUT VARCHAR2   -- 6.�ۊǏꏊ�R�[�h
   ,od_disable_date   OUT DATE       -- 7.������
  );
--
/************************************************************************
 * Procedure Name  : get_subinventory_info2
 * Description     : �ۊǏꏊ�}�X�^���A���_�R�[�h�E�X�܃R�[�h�����
 *                   �ۊǏꏊ�R�[�h�Ɩ��������擾���܂��B
 ************************************************************************/
  PROCEDURE get_subinventory_info2(
    ov_errbuf         OUT VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode        OUT VARCHAR2   -- 2.���^�[���E�R�[�h
   ,ov_errmsg         OUT VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_base_code      IN  VARCHAR2   -- 4.���_�R�[�h
   ,iv_shop_code      IN  VARCHAR2   -- 5.�X�܃R�[�h
   ,ov_sec_inv_nm     OUT VARCHAR2   -- 6.�ۊǏꏊ�R�[�h
   ,od_disable_date   OUT DATE       -- 7.������
  );
--
/************************************************************************
 * Function Name   : GET_MANAGE_DEPT_F
 * Description     : �����_���Ǘ��ۂ��P�Ƌ��_�Ȃ̂��𔻕ʂ���t���O���擾����B
 *                   �߂�l�F0�i�P�Ƌ��_�j�A1�i�Ǘ��ہj
 ************************************************************************/
  FUNCTION get_manage_dept_f(
    iv_base_code   IN   VARCHAR2   -- 1.���_�R�[�h
  ) RETURN NUMBER;   -- �Ǘ��۔��ʃt���O
--
/************************************************************************
 * Function Name   : get_lookup_values
 * Description     : �N�C�b�N�R�[�h�}�X�^�̊e���ڒl�����R�[�h�^�Ŏ擾����B
 ************************************************************************/
  TYPE lookup_rec IS RECORD(
     meaning      fnd_lookup_values.meaning%TYPE
    ,description  fnd_lookup_values.description%TYPE
    ,attribute1   fnd_lookup_values.attribute1%TYPE
    ,attribute2   fnd_lookup_values.attribute2%TYPE
    ,attribute3   fnd_lookup_values.attribute3%TYPE
    ,attribute4   fnd_lookup_values.attribute4%TYPE
    ,attribute5   fnd_lookup_values.attribute5%TYPE
    ,attribute6   fnd_lookup_values.attribute6%TYPE
    ,attribute7   fnd_lookup_values.attribute7%TYPE
    ,attribute8   fnd_lookup_values.attribute8%TYPE
    ,attribute9   fnd_lookup_values.attribute9%TYPE
    ,attribute10  fnd_lookup_values.attribute10%TYPE
    ,attribute11  fnd_lookup_values.attribute11%TYPE
    ,attribute12  fnd_lookup_values.attribute12%TYPE
    ,attribute13  fnd_lookup_values.attribute13%TYPE
    ,attribute14  fnd_lookup_values.attribute14%TYPE
    ,attribute15  fnd_lookup_values.attribute15%TYPE
  );
  --
  FUNCTION get_lookup_values(
    iv_lookup_type    IN  VARCHAR2
   ,iv_lookup_code    IN  VARCHAR2
   ,id_enabled_date   IN  DATE  DEFAULT SYSDATE
  ) RETURN lookup_rec;
/************************************************************************
 * Procedure Name  : CONVERT_WHOUSE_SUBINV_CODE
 * Description     : HHT�ۊǏꏊ�R�[�h�ϊ� �q�ɕۊǏꏊ�R�[�h�ϊ�
 ************************************************************************/
  PROCEDURE convert_whouse_subinv_code(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_base_code                    IN         VARCHAR2   -- 4.���_�R�[�h
   ,iv_warehouse_code               IN         VARCHAR2   -- 5.�q�ɃR�[�h
   ,in_organization_id              IN         NUMBER     -- 6.�݌ɑg�DID
   ,ov_subinv_code                  OUT NOCOPY VARCHAR2   -- 7.�ۊǏꏊ�R�[�h
   ,ov_base_code                    OUT NOCOPY VARCHAR2   -- 8.���_�R�[�h
   ,ov_subinv_div                   OUT NOCOPY VARCHAR2   -- 9.�ۊǏꏊ�敪
  );
/************************************************************************
 * Procedure Name  : CONVERT_EMP_SUBINV_CODE
 * Description     : HHT�ۊǏꏊ�R�[�h�ϊ� �c�ƎԕۊǏꏊ�R�[�h�ϊ�
 ************************************************************************/
  PROCEDURE convert_emp_subinv_code(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_base_code                    IN         VARCHAR2   -- 4.���_�R�[�h
   ,iv_employee_number              IN         VARCHAR2   -- 5.�]�ƈ��R�[�h
   ,id_transaction_date             IN         DATE       -- 6.�`�[���t
   ,in_organization_id              IN         NUMBER     -- 7.�݌ɑg�DID
   ,ov_subinv_code                  OUT NOCOPY VARCHAR2   -- 8.�ۊǏꏊ�R�[�h
   ,ov_base_code                    OUT NOCOPY VARCHAR2   -- 9.���_�R�[�h
   ,ov_subinv_div                   OUT NOCOPY VARCHAR2   -- 10.�ۊǏꏊ�敪
  );
/************************************************************************
 * Procedure Name  : CONVERT_CUST_SUBINV_CODE
 * Description     : HHT�ۊǏꏊ�R�[�h�ϊ� �a����ۊǏꏊ�R�[�h�ϊ�
 ************************************************************************/
  PROCEDURE convert_cust_subinv_code(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_base_code                    IN         VARCHAR2   -- 4.���_�R�[�h
   ,iv_cust_code                    IN         VARCHAR2   -- 5.�ڋq�R�[�h
   ,id_transaction_date             IN         DATE       -- 6.�`�[���t
   ,in_organization_id              IN         NUMBER     -- 7.�݌ɑg�DID
   ,iv_record_type                  IN         VARCHAR2   -- 8.���R�[�h���
   ,iv_hht_form_flag                IN         VARCHAR2   -- 9.HHT������͉�ʃt���O
   ,ov_subinv_code                  OUT NOCOPY VARCHAR2   --10.�ۊǏꏊ�R�[�h
   ,ov_base_code                    OUT NOCOPY VARCHAR2   --11.���_�R�[�h
   ,ov_subinv_div                   OUT NOCOPY VARCHAR2   --12.�ۊǏꏊ��敪
   ,ov_business_low_type            OUT NOCOPY VARCHAR2   --13.�Ƒԏ�����
  );
/************************************************************************
 * Procedure Name  : CONVERT_BASE_SUBINV_CODE
 * Description     : HHT�ۊǏꏊ�R�[�h�ϊ� ���C���q�ɕۊǏꏊ�R�[�h�ϊ�
 ************************************************************************/
   PROCEDURE convert_base_subinv_code(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_dept_code                    IN         VARCHAR2   -- 4.���_�R�[�h
   ,in_organization_id              IN         NUMBER     -- 5.�݌ɑg�DID
   ,ov_subinv_code                  OUT NOCOPY VARCHAR2   -- 6.�ۊǏꏊ�R�[�h
   ,ov_base_code                    OUT NOCOPY VARCHAR2   -- 7.���_�R�[�h
   ,ov_subinv_div                   OUT NOCOPY VARCHAR2   -- 8.�ۊǏꏊ�ϊ��敪
  );
/************************************************************************
 * Procedure Name  : CHECK_CUST_STATUS
 * Description     : HHT�ۊǏꏊ�R�[�h�ϊ� �ڋq�X�e�[�^�X�`�F�b�N
 ************************************************************************/
  PROCEDURE check_cust_status(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_cust_code                    IN         VARCHAR2   -- 4.�ڋq�R�[�h
  );
/************************************************************************
 * Procedure Name  : CONVERT_SUBINV_CODE
 * Description     : HHT�ۊǏꏊ�R�[�h�ϊ�
 ************************************************************************/
  PROCEDURE convert_subinv_code(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.�G���[���b�Z�[�W
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.���^�[���E�R�[�h(1:����A2:�G���[)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.���[�U�[�E�G���[���b�Z�[�W
   ,iv_record_type                  IN         VARCHAR2   -- 4.���R�[�h���
   ,iv_invoice_type                 IN         VARCHAR2   -- 5.�`�[�敪
   ,iv_department_flag              IN         VARCHAR2   -- 6.�S�ݓX�t���O
   ,iv_base_code                    IN         VARCHAR2   -- 7.���_�R�[�h
   ,iv_outside_code                 IN         VARCHAR2   -- 8.�o�ɑ��R�[�h
   ,iv_inside_code                  IN         VARCHAR2   -- 9.���ɑ��R�[�h
   ,id_transaction_date             IN         DATE       -- 10.�����
   ,in_organization_id              IN         NUMBER     -- 11.�݌ɑg�DID
   ,iv_hht_form_flag                IN         VARCHAR2   -- 12.HHT������͉�ʃt���O
   ,ov_outside_subinv_code          OUT NOCOPY VARCHAR2   -- 13.�o�ɑ��ۊǏꏊ�R�[�h
   ,ov_inside_subinv_code           OUT NOCOPY VARCHAR2   -- 14.���ɑ��ۊǏꏊ�R�[�h
   ,ov_outside_base_code            OUT NOCOPY VARCHAR2   -- 15.�o�ɑ����_�R�[�h
   ,ov_inside_base_code             OUT NOCOPY VARCHAR2   -- 16.���ɑ����_�R�[�h
   ,ov_outside_subinv_code_conv     OUT NOCOPY VARCHAR2   -- 17.�o�ɑ��ۊǏꏊ�ϊ��敪
   ,ov_inside_subinv_code_conv      OUT NOCOPY VARCHAR2   -- 18.���ɑ��ۊǏꏊ�ϊ��敪
   ,ov_outside_business_low_type    OUT NOCOPY VARCHAR2   -- 19.�o�ɑ��Ƒԏ�����
   ,ov_inside_business_low_type     OUT NOCOPY VARCHAR2   -- 20.���ɑ��Ƒԏ�����
   ,ov_outside_cust_code            OUT NOCOPY VARCHAR2   -- 21.�o�ɑ��ڋq�R�[�h
   ,ov_inside_cust_code             OUT NOCOPY VARCHAR2   -- 22.���ɑ��ڋq�R�[�h
   ,ov_hht_program_div              OUT NOCOPY VARCHAR2   -- 23.���o�ɃW���[�i�������敪
   ,ov_item_convert_div             OUT NOCOPY VARCHAR2   -- 24.���i�U�֋敪
   ,ov_stock_uncheck_list_div       OUT NOCOPY VARCHAR2   -- 25.���ɖ��m�F���X�g�Ώۋ敪
   ,ov_stock_balance_list_div       OUT NOCOPY VARCHAR2   -- 26.���ɍ��يm�F���X�g�Ώۋ敪
   ,ov_consume_vd_flag              OUT NOCOPY VARCHAR2   -- 27.����VD��[�Ώۃt���O
   ,ov_outside_subinv_div           OUT NOCOPY VARCHAR2   -- 28.�o�ɑ��ۊǏꏊ�敪
   ,ov_inside_subinv_div            OUT NOCOPY VARCHAR2   -- 29.���ɑ��ۊǏꏊ�敪
  );
--
/************************************************************************
 * Function Name   : GET_DISPOSITION_ID
 * Description     : ����Ȗڕʖ�������쐬����ۂɕK�v�ƂȂ�
 *                   ����Ȗڕʖ�ID���擾���܂��B�L�������肠��B
 ************************************************************************/
  FUNCTION get_disposition_id(
    iv_inv_account_kbn        IN VARCHAR2   -- 1.���o�Ɋ���敪
   ,iv_dept_code              IN VARCHAR2   -- 2.����R�[�h
   ,in_organization_id        IN NUMBER     -- 3.�݌ɑg�DID
  ) RETURN NUMBER;                          -- ����Ȗڕʖ�ID
--
/************************************************************************
 * Procedure Name  : ADD_HHT_ERR_LIST_DATA
 * Description     : HHT�f�[�^(���o�ɁE�I��)�捞�̍ۂɃG���[�ƂȂ���
 *                   ���R�[�h�����ƂɁAHHT�G���[���X�g���[�ɕK�v��
 *                   �f�[�^��HHT�G���[���X�g���[���[�N�e�[�u���ɒǉ����܂��B
 ************************************************************************/
  PROCEDURE add_hht_err_list_data(
    ov_errbuf                 OUT VARCHAR2   -- 1.�G���[�E���b�Z�[�W
   ,ov_retcode                OUT VARCHAR2   -- 2.���^�[���E�R�[�h
   ,ov_errmsg                 OUT VARCHAR2   -- 3.���[�U�[�E�G���[�E���b�Z�[�W
   ,iv_base_code              IN  VARCHAR2   -- 4.���_�R�[�h
   ,iv_origin_shipment        IN  VARCHAR2   -- 5.�o�ɑ��R�[�h
   ,iv_data_name              IN  VARCHAR2   -- 6.�f�[�^����
   ,id_transaction_date       IN  DATE       -- 7.�����
   ,iv_entry_number           IN  VARCHAR2   -- 8.�`�[NO
   ,iv_party_num              IN  VARCHAR2   -- 9.���ɑ��R�[�h
   ,iv_performance_by_code    IN  VARCHAR2   -- 10.�c�ƈ��R�[�h
   ,iv_item_code              IN  VARCHAR2   -- 11.�i�ڃR�[�h
   ,iv_error_message          IN  VARCHAR2   -- 12.�G���[���e
  );
--
/************************************************************************
 * Function Name   : GET_DISPOSITION_ID_2
 * Description     : ����Ȗڕʖ�������쐬����ۂɕK�v�ƂȂ�
 *                   ����Ȗڕʖ�ID���擾���܂��B�L��������Ȃ��B
 ************************************************************************/
  FUNCTION get_disposition_id_2(
    iv_inv_account_kbn        IN VARCHAR2   -- 1.���o�Ɋ���敪
   ,iv_dept_code              IN VARCHAR2   -- 2.����R�[�h
   ,in_organization_id        IN NUMBER     -- 3.�݌ɑg�DID
  ) RETURN NUMBER;                          -- ����Ȗڕʖ�ID
--
END XXCOI_COMMON_PKG;
/
